classdef PDE < SSP_Tools.TestProblems.TestProblem

	properties		
	
		domain = [];
		
		% What's happening at the boundaries. For now these will just
		% be 'periodic'
		left_boundary = 'periodic';
		right_boundary = 'periodic';
		
		% What's the initial condition? This should be a function
		% uinit(x) that returns a value of u at t=0 for every
		% x given to it. By default, let this be a simple sinewave.
		uinit = [];

		% We'll need a SpaceMethod object that will be used to discretize
		% the flux term in the homogeneous PDE.
		discretizer = [];
		
		% We'll also need a TimeMethod object that will be used to 
		% solve the resulting system of ODEs and get the general solution
		% to the homogeneous PDE.
		integrator = [];
		
		% Store our domain and dependent variables
		x = [];
		u = [];
		t = [];
		dt = [];
		
		% A ConvectionReactionPDE object for calculating a very high accuracy
		% numerical approximation as a stand-in for an exact solution.
		hires_problem = [];
		
		% A MATLAB datafile for storing/retreiving exact solutions
		data_file = [];
		exact_data = [];
		
	end
	
	properties(GetAccess = 'private', SetAccess = 'private')
		
		% Sometimes we might nest objects of this type (See get_exact_solution() )
		% so it's important that we know whether this is the case.
		is_nested = false;
		
	end
	

	methods
	
		function obj = PDE(varargin)
			obj = obj@SSP_Tools.TestProblems.TestProblem(varargin{:});
			
			p = inputParser;
			p.addParamValue('name', []);
			p.addParamValue('domain', []);
			p.addParamValue('initial_condition', []);
			p.addParamValue('discretizer', []);
			p.addParamValue('integrator', []);
			p.addParamValue('data_file', []);
			p.addParamValue('N', []);
			p.parse(varargin{:});
			
			obj.name = p.Results.name;
			
			% Check to see if we've been passed the name of an initial
			% condition known to obj.get_available_initial_conds() or 
			% if we've just been passed a function handle
			if isa(p.Results.initial_condition, 'function_handle')
				obj.uinit = p.Results.initial_condition;
				obj.domain = p.Results.domain;
			elseif isa(p.Results.initial_condition, 'char')
				available_conditions = obj.get_available_initial_conds();
				names = {available_conditions.name};
				ic_idx = find(strcmp(names, p.Results.initial_condition));
				obj.uinit = available_conditions(ic_idx).function;
				obj.domain = available_conditions(ic_idx).domain;
			else
				obj.uinit = [];
			end
				
				
			obj.data_file = p.Results.data_file;
			
			% Initialize our flux discretizer
			if ~isempty(p.Results.discretizer)
				obj.set_discretizer(p.Results.discretizer);
			end
			
			% Initialize the integrator for the general solution
			if ~isempty(p.Results.integrator)
				obj.set_integrator(p.Results.integrator);
			end

			% Load the datafile, if it exists
			if ~isempty(obj.data_file)
				obj.load_datafile();
			end
			
			% If we've been given the number of gridpoints to use, 
			% initialize the problem
			if ~isempty(p.Results.N) & ~isempty(obj.domain) ...
			                         & ~isempty(p.Results.integrator) ...
			                         & ~isempty(p.Results.discretizer)
			                         
				obj.setup_problem(p.Results.N);
			end
			
			
		end
		
		function set.data_file(obj, file)
			% Load the datafile, if it exists
			
			if isempty(obj.data_file) & ~isempty(file)
				package_path = mfilename('fullpath');
				dir_seps = strfind(package_path, '/');
				package_path = package_path(1:dir_seps(end));
				obj.data_file = [package_path, 'data/', file];
				if exist(obj.data_file)
					loaded_data = load(obj.data_file);
					obj.exact_data = loaded_data.data;
				else
					obj.exact_data = containers.Map();
				end 
			end
		end
		
		function load_datafile(obj)
			% Load the datafile
			package_path = mfilename('fullpath');
			dir_seps = strfind(package_path, '/');
			package_path = package_path(1:dir_seps(end));
			obj.data_file = [package_path, 'data/', obj.data_file];
			if exist(obj.data_file, 'file')
				loaded_data = load(obj.data_file);
				obj.exact_data = loaded_data.data;
			end
		end
		
		
		
		
		function setup_problem(obj, N)
			% Initialize our computational domain.
			obj.x = linspace(obj.domain(1), obj.domain(2), N + 1);
		
			% Get the initial condition    
			obj.u = obj.uinit(obj.x)';
			obj.t = 0.0;
			
			% MATLAB is stupid. We need to do this again otherwise
			% copies of this object will still try to use the 
			% integrator attached to this object.
			obj.set_integrator(obj.integrator);
			
		end
		
		function set_discretizer(obj, discretizer)
			% Initializes the discretizer. Right now this only
			% accepts an SSP_Tools.SpaceMethod object, but this
			% behavior can easily be changed.
			discretizer.f = @obj.fflux;
			discretizer.em = @obj.em;
			discretizer.left_boundary = obj.left_boundary;
			discretizer.right_boundary = obj.right_boundary;
			obj.discretizer = discretizer;
		end
		
		function set_integrator(obj, integrator)
			% Initializes the integrator for the general solution
			% to the homogeneous PDE. 
			tmp_discretizer = obj.discretizer;
			integrator.yPrimeFunc = @(u,t) obj.discretize(u, t, @tmp_discretizer.L);
			integrator.yInFunc = @(u) u;
			integrator.yOutFunc = @(u) u;
			integrator.ProblemObject = obj;
			integrator.log = obj.log;
			obj.integrator = integrator;
		end
		
		function step(obj, dt)
			
			% Approximate the homogenous equation u_t = -f(u)_x
			u_next = obj.integrator.step(obj.u, obj.t, dt);
			
			obj.u = u_next;
			obj.t = obj.t + dt;
			
		end
		
		function approximate(obj, t, varargin)
			% Approximate the solution at t= by stepping in
			% increments of dt
			
			p = inputParser;
			p.addParamValue('dt', []);
			p.addParamValue('cfl', []);
			p.addParamValue('tolT', []);
			p.addParamValue('verbose', []);
			p.parse(varargin{:});
			
			% We can't have BOTH a dt and a cfl specified
			if ~isempty(p.Results.dt) & ~isempty(p.Results.cfl)
				error('Specify dt or cfl but not both!');
			end
			
			if ~isempty(p.Results.dt)
				dt = p.Results.dt;
			elseif ~isempty(p.Results.cfl)
				dt = p.Results.cfl * min(diff(obj.x));
			else
				dt = 0.2*min(diff(obj.x));
			end
			
			if ~isempty(p.Results.tolT)
				tolT = p.Results.tolT;
			else
				tolT = 1e-16;
			end
			
			% Record what timestep we used for reporting purposes
			obj.dt = dt;
			t_remaining = abs(obj.t - t);
			while t_remaining > tolT
			
				if t_remaining < dt
					obj.step(t_remaining);
				else
					obj.step(dt);
				end
				t_remaining = t - obj.t;
				
				print_buffer = sprintf('[%s] Approximating T=%4.2g %3.2f Complete', datestr(now, 13),...
					                                                                    obj.t,...
					                                                                    obj.t/t*100);
				obj.log('%s\r', print_buffer)
				
			end 
			
			print_buffer = repmat(' ', 1, length(print_buffer));
			obj.log('%s\r', print_buffer);
			
			% GOTCHA: We'll force obj.t = t because
			% some solvers (ODE45) will go into an
			% infinite loop if we try to step by 1e-16
			obj.t = t;
			
		end
		
		function plot(obj)
			% Plots the current value of u
			plot(obj.x, obj.u)
			title( sprintf('T=%f', obj.t));
		end
		
		function u_x = discretize(obj, u, t, disc_func)
			% Discretize the domain with sampled function values u at time t
			% using the discretization function disc_func. If u is a stacked column
			% vector representing multiple blocks, discretize each block independently
			
			nu = length(u);
			nx = numel(obj.x);
			if nu == nx
				u_x = disc_func(obj.x, u', t)';
			else
				nblocks = nu/nx;
				u = reshape(u, nx, nblocks);
				u_x = zeros(size(u));
				for i=1:nblocks
					u_x(:,i) = disc_func(obj.x, u(:,i)', t)';
				end
				
				u_x = reshape(u_x, nu, 1);
			end
		end
		
		function pointwise_error = calculate_error(obj)
			% Obtain an exact solution either by looking it
			% up in our precomputed solutions database, or 
			% calculating it.
			
			% Try the database first
			u_exact = obj.get_exact_solution();
			if isempty(u_exact)
				% The database is empty, compute it.
				error('No exact solution present')
				obj.calculate_exact_solution(obj.t);
				u_exact = obj.hires_problem.u;
			end
			
			pointwise_error = abs(obj.u - u_exact);
			
		end
		
		function u = get_exact_solution(obj)
			% Fetch a precomputed exact solution from the data file.
			
			% Create a record for the database lookup. The database
			% is indexed by the domain and by the value of t.
			record = struct();
			record.x = obj.x;
			record.t = obj.t;
			key = SSP_Tools.utils.DataHash(record);
			
			if obj.exact_data.isKey(key)
				data = obj.exact_data(key);
				u = data.u;
			else
				u = [];
			end
			
		end
		
		function clone = copy(obj)
			% Construct a copy of this object.
			% 
			meta = metaclass(obj);
			clone = eval([ meta.Name, '()' ]);
			
			ignored_fields = {'integrator', 'discretizer', 'u', 't' };
			
			props = fieldnames(obj);
			for i=1:numel(props)
			
				if any(strcmp(props{i}, ignored_fields) )
					% skip
				else
					% Copy the values
					clone.(props{i}) = obj.(props{i});
				end
			end
			
			% Copy the discretizer
			clone.set_discretizer(obj.discretizer.copy());
			
			% Copy the integrator
			clone.set_integrator(obj.integrator.copy());
			clone.setup_problem(numel(obj.x) - 1);
		end
		
		function data = export(obj)
			% Export information about the problem, what we're doing with it
			% and what approximation we obtained in an independent format.
			%
			data.x = obj.x;
			data.u = obj.u;
			data.t = obj.t;
			data.name = obj.name;
			data.integrator = obj.integrator.get_repr();
			data.discretizer = obj.discretizer.get_repr();
			data.date = datestr(now);
		end
		
		function u = get_approximation(obj)
			u = obj.u;
		end
		
		function norm_error = error_norm(obj, norm_type)
			
			% Get the pointwise error
			pointwise_error = obj.calculate_error();

			% For convenience, create a norm function
			f = @(v) norm(v, norm_type);
			
			% And our scaling function
			if norm_type == 1
				mu = @(v) f(v) / length(v);
			elseif norm_type == 2
				mu = @(v) f(v) / sqrt(length(v));
			elseif isinf(norm_type)
				mu = @(v) f(v);
			else
				error('Invalid norm selection')
			end
		
			norm_error = mu(pointwise_error);
		end
		
		function repr_struct = get_repr(obj)
			% Get a machine readable representation of this
			% class
			
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			repr_struct.IC = func2str(obj.uinit);
			repr_struct.Domain = [obj.domain(1), obj.domain(end)];
			repr_struct.t = obj.t;
		end
		
		function id_string = repr(obj)
			
			repr_struct = obj.get_repr();
			id_fmt = '< %s: %s [%g, %g] t=%g >';
			id_string = sprintf(id_fmt, repr_struct.Class, ...
			                            repr_struct.IC, ...
			                            repr_struct.Domain(1), repr_struct.Domain(2),...
			                            repr_struct.t );
		
		end
	
		function parameters = get_parameters(obj)
			
			parameters = {};

%  			parameters{end+1} = struct('keyword', 'domain', ...
%  			                           'name', 'domain', ...
%  			                           'type', 'domain', ...
%  			                           'options', obj.get_available_domains(), ...
%  			                           'default', [-1, 1]);
			
			parameters{end+1} = struct('keyword', 'initial_condition', ...
								'name', 'Initial Condition', ...
								'type', 'initial_condition', ...
								'options', obj.get_available_initial_conds(),...
								'default', 'Sinewave' );
								
			parameters{end+1} = struct('keyword', 'discretizer', ...
			                       'name', 'Flux Discretizer', ...
			                       'type', 'SSP_Tools.Discretizers.Discretizer', ...
			                       'options', [], ...
			                       'default', [] );
			
			parameters{end+1} = struct('keyword', 'integrator', ...
			                       'name', 'Integrator for General Problem', ...
			                       'type', 'SSP_Tools.Integrators.Integrator',...
			                       'options', [], ...
			                       'default', [] );
			                             
			parameters{end+1} = struct('keyword', 'N', ...
			                       'name', 'Number of points in space', ...
			                       'type', 'double',...
			                       'options', [], ...
			                       'default', 50 );
		
			parameters = [ parameters{:} ];
		
		end
		
		function parameters = get_available_domains(obj)
		
			parameters = {};
			
			parameters{end+1} = struct('name', '[-1, 1]', 'value', [-1, 1]);
			parameters{end+1} = struct('name', '[0, 1]', 'value', [0, 1]);
			parameters = [parameters{:}];
		
		end
		function parameters = get_available_initial_conds(obj)
			% Return a structure of available initial conditions
			% for use in configuring the problem
			
			parameters = {};
			parameters{end+1} = struct('name', 'sinewave', ...
			                           'longname', 'sin(pi*x)', ...
			                           'function', @(x) sin(pi*x), ...
			                           'domain', [-1, 1] );
			parameters{end+1} = struct('name', 'elevated_sinewave', ...
			                           'longname', '1/4 + sin(pi*x)', ...
			                           'function', @(x) 1./4. + sin(pi*x), ...
			                           'domain', [-1, 1] );
			parameters{end+1} = struct('name', 'sin2pix', ...
			                           'longname', 'sin(2*pi*x)', ...
			                           'function', @(x) sin(2*pi*x), ...
			                           'domain', [0, 1]);
			                           
			function u = stepfcn(x)
				x = x - floor(x);
				u = zeros(size(x));
				u(x >= 0.5) = 1.0;
				u(1) = u(end);
			end
			
			parameters{end+1} = struct('name', 'stepfunction', ...
			                           'longname', 'Squarewave  1.0 (x<=0.5)', ...
			                           'function', @stepfcn, ...
			                           'domain', [0, 1] );
			parameters{end+1} = struct('name', 'stepfunction2', ...
			                           'longname', 'Step Function [-1,1]', ...
			                           'function', @(x)0.5*((x-floor(x))>=0.5), ...
			                           'domain', [-1, 1] );
			parameters{end+1} = struct('name', 'all_positive_sinewave', ...
			                           'longname', 'Elevated Sinwave [-1, 1] u(0) = 1 + sin(pi*x)', ...
			                           'function', @(x)1 + sin(pi*x), ...
			                           'domain', [-1, 1]);
		
			parameters = [ parameters{:} ];
		end
		
		function Discretizer = getDiscretizer(obj)
			% Return a reference to the discretizer object.
			% This function is provided to allow Integrator objects
			% to have some control over how discretizations are performed
			
			Discretizer = obj.discretizer;
		end
		
		
		
	end
end