classdef MSRK < SSP_Tools.Integrators.Integrator
	properties
		cheat = false;
		coefficient_directory = [];
		
		file = [];
		
		%%% These variables contain the coefficients which define the method. They
		%%% are divided into two groups--those that are used in the calculation of
		%%% the Runge-Kutta stages, and those that are used in the final linear
		%%% combination to determine the value of y(t+dt).
		
		% Coefficients for calculating RK stage values
		D = [];     % values for the linear combination of previous steps
		Ahat = [];  % values for the linear combination of y' at previous steps
		A = [];     % values for the linear combination of previous RK stages
		
		% Coefficients for calculating y(t+dt)
		theta = []; % values for the linear combination of previous steps
		Bhat = [];  % values for the linear combination of y' at previous steps
		B = [];     % values for the linear combination of RK stages
		
		c = [];		% The abscissas for evaluating the function at the RK stages.
		
		p = [];
		% This indicates the order of the method. It comes from the code that
		% Zack's been using to search for these methods, hence the label 'p'. 
		
		%%% As this is a multistep method, this class implicitly "remembers"
		%%% previous steps as columns in the following two variables. Both are
		%%% treated as circular queues. As new steps are added, unneeded steps
		%%% removed.
		
		U = [];
		% Stores the value of the function at previous steps.
		
		FU = [];
		% Stores the value of y' evaluated at previous steps. This saves
		% computation.
	
		kron_products = []
		% In order to handle cases where length(u) > 1, we need kronnecker products
		% for the coefficient matricies theta, A, B, and Bhat. These kronnecker products
		% depend on knowing the value of length(u) which we don't until RKMS.advance() has
		% been called. In order to prevent these from being created at every call to
		% RKMS.advance() we cache them here. 
		
		initial_integrator;
		% Since this is a multistep method, we need another time-stepping method to
		% approximate the initial n steps. This is a string containing the fully-qualified
		% name of a class that will be instantiated to provide that method.
		
		mini_dt_type;
		% Options for how initial_integrator is going to step forward in time to 
		% to approximate the initial n steps.
		
		mini_dt_c; 
		
		method_primed = false;
		% While false all calls to advance() will be handled by initial_integrator
		% Once the initial n steps have been taken, this becomes true and the MSRK
		% method is used to calculate all successive calls. 
		
		Trel = [];
		% Used in our miniature time-stepping
		
		TrelEnd;
		% Used in our miniature time-stepping
		
		last_dt;
		% Since this is a multistep method, we need to ensure that it's always
		% advanced by the same dt. This will be checked and a warning will be
		% raised if the requested step differs from the previous step.
		
		
		
	end
	
	methods
		function obj = MSRK(varargin)
			obj = obj@SSP_Tools.Integrators.Integrator(varargin{:});
			
			import utils.*;

			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('initial_integrator', []);
			p.addParamValue('mini_dt_type', []);
			p.addParamValue('mini_dt_c', []);
			p.addParamValue('coefficients', false);
			p.addParamValue('A', [])
			p.addParamValue('B', [])
			p.addParamValue('Ahat', []);
			p.addParamValue('Bhat', []);
			p.addParamValue('theta', []);
			p.addParamValue('D', []);
			p.parse(varargin{:});
				
			% Set the coefficient directory
			package_path = mfilename('fullpath');
			dir_seps = strfind(package_path, '/');
			package_path = package_path(1:dir_seps(end-1));
			obj.coefficient_directory = [package_path, 'Method Coefficients/Multistep Multistage (MSRK)'];
		
			% Load the coefficients if specified.
			parameters = [];
			if isstr(p.Results.coefficients) & ~isempty(p.Results.coefficients)
			
				if p.Results.coefficients(1) == '/'
					coeffFile = p.Results.coefficients;
				else
					coeffFile = [ obj.coefficient_directory, '/', sprintf('%s.mat', p.Results.coefficients) ];
					
					if ~exist(coeffFile, 'file')
						coeffFile = [ obj.coefficient_directory, '/', sprintf('%sT2.mat', p.Results.coefficients) ];
					end
				end
			
				obj.file = coeffFile;
				parameters = load(coeffFile);
				obj.A = parameters.A;
				obj.B = parameters.B;
				obj.Ahat = parameters.Ahat;
				obj.Bhat = parameters.Bhat;
				obj.theta = parameters.theta;
				obj.D = parameters.D;
				obj.p = parameters.p;
				obj.r = parameters.r;
				coeffFileName = coeffFile(max(strfind(coeffFile, '/'))+1:end);
				obj.name = ['MSRK',' ',coeffFileName ];
			elseif ~isempty(p.Results.A) && ~isempty(p.Results.B)
				obj.A = p.Results.A;
				obj.B = p.Results.B;
				obj.Ahat = p.Results.Ahat;
				obj.Bhat = p.Results.Bhat;
				obj.theta = p.Results.theta;
				obj.D = p.Results.D;
				obj.name = p.Results.name;
			end
			
			% Recreate all of these matrices as sparse matrices.
			if ~all(cellfun(@isempty, {obj.A, obj.B, obj.theta, obj.Bhat}))
				obj.A = sparse(obj.A);
				obj.B = sparse(obj.B);
				obj.theta = sparse(obj.theta);
				obj.Bhat = sparse(obj.Bhat);
			end
			
			% D usually comes to us missing its top line which should be all
			% zeros. Append the top line.
			if ~isempty(obj.D)
				topline = zeros(1, size(obj.D,2));
				topline(end) = 1;
				obj.D = [ topline; obj.D ];
			end
			
			% Note how many stages and steps we have.
			if ~isempty(obj.B) & ~isempty(obj.theta)
				obj.stages = length(obj.B);
				obj.steps = length(obj.theta);
			end
			
			% Construct the values for the abscissas
			if ~isempty(obj.Ahat) & ~isempty(obj.A)
				Anew=[obj.Ahat,obj.A];
				es=ones(obj.steps-1+obj.stages,1);
				ll = [obj.steps-1:-1:0]';
				obj.c=(Anew*es-obj.D*ll)';
			end
						
			if isempty(p.Results.initial_integrator) | strcmp(p.Results.initial_integrator, 'RK3')
				obj.initial_integrator = SSP_Tools.Integrators.RK3();
				obj.initial_integrator.yInFunc = obj.yInFunc;
			elseif strcmp(p.Results.initial_integrator, 'RK4')
				obj.initial_integrator = SSP_Tools.Integrators.RK4()
				obj.initial_integrator.yInFunc = obj.yInFunc;
			else
				obj.initial_integrator = p.Results.initial_integrator;
			end
			
			
			if ~isempty(p.Results.mini_dt_type)
				obj.mini_dt_type = p.Results.mini_dt_type;
			end
			
			if ~isempty(p.Results.mini_dt_c)
				obj.mini_dt_c = p.Results.mini_dt_c;
			end
			
			

			
			% We need to listen for when yPrimeFunc changes so we can update
			% the corresponding property in obj.initial_integrator.
			addlistener(obj,'yPrimeFunc','PostSet',@obj.handlePropEvents);
			
		end

		
				
		function [u_next,varargout] = advance(obj, u, t, dt)

			import utils.*;
			
			% If we're called for the first time. Save dt. Otherwise
			% compare the requested time step and raise a warning if
			% they differ
			if isempty(obj.last_dt)
				obj.last_dt = dt;
			elseif abs(dt - obj.last_dt) > 1e-14
				obj.warn('SSP_Tools:StepSizeChanged', 'Advanced with inconsistent stepsize %g-%g (%g)\nPotential Increase in error', obj.last_dt, dt, abs(obj.last_dt - dt));
			end
			
			
			% If we already have enough steps, remove the oldest step.
			if size(obj.U,2) == obj.steps
				obj.U = obj.U(:,2:end);
				obj.FU = obj.FU(:,2:end);
			end
			
			% Add the current value of y and y' to the list of steps.
			obj.U(:,end+1) = u;
			obj.FU(:,end+1) = obj.yPrimeFunc(u,t);
			
			% Priming the pump
			% We use an explicit RK3 method to take tiny steps forward in time
			% until we have the necesary history to use the multistep method.
			if obj.method_primed ~= true
				u_next = obj.step_with_priming_method(u,t,dt);
			else				
				% We have a sufficient number of previous steps to use the MSRK method
				u_next = obj.step_with_msrk(u, t, dt);
			end

			% Return whatever extra information we want to view.			
			varargout{1} = 1;
			varargout{2} = '';	
			
		end	
		
		function u_next = step_with_priming_method(obj, u, t, dt)
		
			% Set our relative time variables to keep track of the mini-steps
			% we're going to take between t and t+dt
			obj.Trel = t;	
			obj.TrelEnd = obj.Trel+dt;
						
			if strcmp(obj.initial_integrator, 'use-exact')
				% Use exact solution
				u = obj.ProblemObject.get_exact_solution(t+dt);
			elseif isa(obj.initial_integrator, 'function_handle')
				u = obj.initial_integrator(t+dt);
			elseif isa(obj.initial_integrator, 'SSP_Tools.Integrators.Integrator')
				% Use another integrator to obtain the first few steps
				if strcmp(obj.mini_dt_type, 'compatible')
					% FIXTHIS: THIS SHOULD BE CHANGED TO OBJ.R OF PRIMING METHOD
	  				if obj.order <= 3
	  					mini_dt = dt
	  				else
					%CHRIS CHANGED THIS
						c = obj.mini_dt_c;
						mini_dt = c*dt.^(obj.p/3.);
					end
				elseif strcmp(obj.mini_dt_type, 'fraction')
					c = obj.mini_dt_c;
					mini_dt = dt/c;
				end
				
				% Step forward in time.
				TrelOrig = obj.Trel;
				while obj.Trel < obj.TrelEnd
					if mini_dt > obj.TrelEnd-obj.Trel
						mini_dt = obj.TrelEnd-obj.Trel;
					end
					
					[u,msg] = obj.initial_integrator.step(u, obj.Trel, mini_dt);
					obj.Trel = obj.Trel + mini_dt;
				end
			end
			
			u_next = u;
			
			if size(obj.U,2) >= obj.steps-1
				% We have enough previous approximations recorded to
				% satisfy the multistep method.
				obj.method_primed = true;
			end	
		end

		function u_next = step_with_msrk(obj, u, t, dt)
	
			stage_size = length(u);
			Y = zeros(stage_size*obj.stages, 1);
			
			% In order to handle the situation where length(u) > 1, we need
			% some kronnecker products. Since these only depend on length(u)
			% we compute them once then cache them in an instance variable.
			if isempty(obj.kron_products)
				%fprintf('%s Making Kronnecker Products \n', SSP_Tools.utils.time_stamp())
				obj.kron_products.A = kron(obj.A, speye(length(u)));
				obj.kron_products.THETA = kron(obj.theta, speye(length(u)));
				obj.kron_products.BHAT = kron([obj.Bhat, 0], speye(length(u)));
				obj.kron_products.B = kron(obj.B, speye(length(u)));					
			end
			
			A = obj.kron_products.A;
			B = obj.kron_products.B;
			BHAT = obj.kron_products.BHAT;
			THETA = obj.kron_products.THETA;
			Ahat = [ obj.Ahat, zeros( size(obj.Ahat,1), obj.steps-size(obj.Ahat,2))];
			
			
			FY = zeros(size(Y));
			
			for i=1:obj.stages
				block = (i-1)*length(u)+1:i*length(u);
				lincombSteps = bsxfun(@times, obj.D(i,:), obj.U);
				lincombFusteps = bsxfun(@times,Ahat(i,:),obj.FU);

				if (i > 1)
					lincombFustages = A(block,1:block(end))*FY(1:block(end));
				else
					lincombFustages = zeros(size(lincombSteps));
				end
					
				Y(block) = sum([lincombSteps, dt*lincombFusteps, dt*lincombFustages], 2);
				FY(block) = obj.yPrimeFunc(Y(block),t + obj.c(i));
			end
			
			Ustacked = obj.U(:);
			Ystacked = Y(:);
			
			Uapprox = obj.FU(:);
			Yapprox = FY(:);
			
			u_next = (THETA*Ustacked + dt.*(BHAT*Uapprox) + dt.*(B*Yapprox));
		end

		function clone = copy(obj)
			meta = metaclass(obj);
			clone = eval([ meta.Name, '()' ]);
			
			ignored_fields = {'U', 'FU', 'kron_products'};
			
			props = fieldnames(obj);
			for i=1:numel(props)
				if ~any( strcmp(props{i}, ignored_fields) )
					clone.(props{i}) = obj.(props{i});
				end
			end
		end
		
		function parameters = get_parameters(obj)
		
			parameters = {};
			coefficient_parameter.keyword = 'coefficients';
			coefficient_parameter.name = 'coefficients';
			coefficient_parameter.longname = 'Coefficient File';
			coefficient_parameter.type = 'file_list';
			coefficient_parameter.options = [];
			coefficient_parameter.default = [];
			if ~isempty(obj.coefficient_directory) & exist(obj.coefficient_directory, 'dir')
				files = dir([obj.coefficient_directory, '/*.mat']);
				coefficient_parameter.options = struct( 'path', obj.coefficient_directory,...
				                                        'files', {{files.name}});
			else
				coefficient_parameter.options = [];
			end
			coefficient_parameter.default = [];
			
			parameters{end+1} = coefficient_parameter;

			parameters{end+1} = struct('keyword', 'priming methods', ...
			                           'type', 'function_defined', ...
			                           'name', 'Priming Method Setup', ...
			                           'longname', 'Options for Multistep Configuration', ...
			                           'options', @obj.get_parameters_multistep, ...
			                           'default', [] );
			
			parameters = [ parameters{:} ];
			
		end
		
		function [parameter_desc, out_parameters] = get_parameters_multistep(obj, in_parameters, all_parameters)
		% This function allows us to apply a little logic to the kinds of parameters
		% seen by a factory method. The factory method keeps calling this function with
		% the set of keyword parameters it controls until an empty array is returned.
		%
		% This function manages 'initial_integrator', 'mini_dt_type', and 'mini_dt_c'
		%
		
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('initial_integrator', []);
			p.addParamValue('mini_dt_type', []);
			p.addParamValue('mini_dt_c', []);
			p.parse(in_parameters);
			
			initial_integrator = p.Results.initial_integrator;
			mini_dt_type = p.Results.mini_dt_type;
			mini_dt_c = p.Results.mini_dt_c;
			
			if isempty(initial_integrator) & isempty(mini_dt_type) & isempty(mini_dt_c)
				% First call, all fields are empty, return this
				
				initial_integrators = {};
				initial_integrators{end+1} = struct('name', 'use-exact', ...
																'longname', 'Use exact solution', ...
																'unneeded', {{'mini_dt_type', 'mini_dt_c'}});
																
				initial_integrators{end+1} = struct('name', 'RK3', ...
																'longname', 'RK3', ...
																'unneeded', []);
																
				initial_integrators{end+1} = struct('name', 'RK4', ...
																'longname', 'RK4', ...
																'unneeded', []);
				
				parameter_desc = struct('keyword', 'initial_integrator', ...
										'type', 'list', ...
										'name', 'initial_integrator', ...
										'longname', 'Initial Integration Method', ...
										'options', [initial_integrators{:}], ...
										'default', 'use-exact' );
				out_parameters = [];
				return
			end
			
			if strcmp(initial_integrator, 'use-exact')
				% We selected an exact value
				parameter_desc = [];
				out_parameters = in_parameters;
				return
			elseif ~isempty(initial_integrator) & isempty(mini_dt_type) & isempty(mini_dt_c)
					ministep_options = {};
					ministep_options{end+1} = struct('name', 'compatible', ...
																'longname', 'compatible c*dt.^(p/3)');
					
					ministep_options{end+1} = struct('name', 'fraction', ...
																'longname', 'fractional c*dt' );
					ministep_options = [ministep_options{:}];
																
					parameter_desc = struct('keyword',  'mini_dt_type', ...
											'type', 'list', ...
											'name', 'mini_dt_type', ...
											'longname', 'Initial Integrator dt step type', ...
											'options', ministep_options, ...
											'default', 'compatible' );
					out_parameters = in_parameters;
					return                       
			elseif ~isempty(initial_integrator) & ~isempty(mini_dt_type) & isempty(mini_dt_c)
					parameter_desc = struct('keyword', 'mini_dt_c', ...
											'type', 'double', ...
											'name', 'mini_dt_c', ...
											'longname', 'c', ...
											'options', [], ...
											'default', 1.0 );
					out_parameters = in_parameters;
					return
			elseif ~isempty(initial_integrator) & ~isempty(mini_dt_type) & ~isempty(mini_dt_c)
				% All three parameters have been set
				out_parameters = in_parameters;
				parameter_desc = [];
				return
			end
		end
			

			
		
		function repr_struct = get_repr(obj)
			% Get a machine readable representation of this
			% class
			
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;			
			repr_struct.Name = obj.name;
			repr_struct.File = obj.file;
			
			if isa(obj.initial_integrator, 'SSP_Tools.Integrators.Integrator')
				repr_struct.Init_Method = obj.initial_integrator.name;
				
			else
				repr_struct.Init_Method = obj.initial_integrator;
			end
			
			if ~isempty(obj.file)
				[status, md5sum] = system(['md5 -q ', sprintf('"%s"', obj.file)]);
				repr_struct.Md5 = md5sum;
			else
				repr_struct.Md5 = [];
			end
			
			
		end
		
		function id_string = repr(obj)
			% Provide a textual representation of the object
			% that a human can use to identify it
			
			repr_struct = obj.get_repr();
			
			if isa(obj.initial_integrator, 'SSP_Tools.Integrators.Integrator')
				priming_str = sprintf('priming=%s mini_dt_type=%s, mini_dt_c=%f', obj.initial_integrator.name, ...
				                                                          obj.mini_dt_type, ...
				                                                          obj.mini_dt_c );
			else
				priming_str = sprintf('priming=%s', obj.initial_integrator);
			end
				
			
			
			id_fmt = '< %s: %s %s >';
			id_string = sprintf(id_fmt, repr_struct.Class, ...
			                            repr_struct.Name, ...
			                            priming_str);
			
		end
	
		function handlePropEvents(obj, src,evnt)
				switch src.Name % switch on the property name
					case 'yPrimeFunc'
						if isa(obj.initial_integrator, 'SSP_Tools.Integrators.Integrator');
							obj.initial_integrator.yPrimeFunc = obj.yPrimeFunc;
						end
						
					case 'PropTwo'
					% PropTwo has triggered an event
						...
				end
			end
	end
	
end