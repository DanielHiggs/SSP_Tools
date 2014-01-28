classdef SSPRK < SSP_Tools.Integrators.Integrator
	properties
		
		explicitMethod = [];
		alpha = [];
		beta = [];
		c = [];
		S = [];
		v = [];
		
		kron_products = [];
		coefficient_directory = [];
		
	end
	
	methods
		function obj = SSPRK(varargin)
			obj = obj@SSP_Tools.Integrators.Integrator(varargin{:});
			
			p = inputParser;
			p.KeepUnmatched = true;
			addOptional(p,'coefficients', false);
			addOptional(p,'alpha', []);
			addOptional(p,'beta', []);
			addOptional(p,'v', []);
			addOptional(p,'p', []);
			addOptional(p,'name', []);
			p.parse(varargin{:});
			
			% Set the coefficient directory
			package_path = mfilename('fullpath');
			dir_seps = strfind(package_path, '/');
			package_path = package_path(1:dir_seps(end-1));
			obj.coefficient_directory = [package_path, 'Method Coefficients/Runge-Kutta (Shu-Osher Form)'];
			
			
			% Load the coefficients if specified.
			if isstr(p.Results.coefficients)
				coeffFile = p.Results.coefficients;
				parameters = load(coeffFile);
				coeffFileName = coeffFile(max(strfind(coeffFile, '/'))+1:end);
				obj.name = ['SSP Runge-Kutta',' ',coeffFileName ];
			elseif ~isempty(p.Results.alpha) && ~isempty(p.Results.beta)
				parameters.alpha = p.Results.alpha;
				parameters.beta = p.Results.beta;
				parameters.v = p.Results.v;
				parameters.p = p.Results.p;
				obj.name = p.Results.name;
			end
			
			if exist('parameters')
				obj.stages = size(parameters.alpha,2);
				
				if obj.isModifiedShuOsher(parameters)
					obj.alpha = parameters.alpha;
					obj.beta = parameters.beta;
					obj.v = parameters.v;	
				else
					m = size(obj.alpha,1);
					obj.alpha = [ zeros(1,obj.stages); parameters.alpha];
					obj.alpha = [ zeros(m, 1), obj.alpha ];
					obj.alpha(2,1) = 1.0;
					
					obj.beta = [ zeros(1,obj.stages); parameters.beta ];
					obj.beta = [ zeros(m, 1), obj.beta ];
					
					obj.v = [1; zeros(obj.stages,1)];
				end
			end
			
			
			if ~isempty(obj.alpha) & ~isempty(obj.beta) & ~isempty(obj.v)
				obj.alpha = sparse(obj.alpha);
				obj.beta = sparse(obj.beta);
				obj.v = sparse(obj.v);
			
				X=eye(obj.stages)-obj.alpha(1:end-1,:);
				A=X\obj.beta(1:end-1,:);
				b=obj.beta(end,:)+obj.alpha(end,:)*A; b=b';
				obj.c=sum(A,2)';
			
				if obj.isExplicitMethod()
					true;
				else
					obj.solver = SSP_Tools.utils.MatlabSolver();
				end
			end
		end
		
		function t = isModifiedShuOsher(obj,ssp_parameters)
			if isfield(ssp_parameters, 'v')
				t = true;
			else
				t = false;
			end
		end
		
		function t = isExplicitMethod(obj)
			
			if isempty(obj.explicitMethod)
			
				
				t = true;
				matrices = { obj.alpha, obj.beta };
				for j=1:length(matrices)
					matrix = matrices{j};
					i = 0;
					while true
						diagonal = diag(matrix, i);
						if isempty(diagonal)
							break;
						end
						
						if all(diagonal == 0)
							i=i+1;
							continue;
						else
							obj.explicitMethod = false;
							t = false;
							return;
						end
					end
				end
				obj.explicitMethod = true;
			else
				t = obj.explicitMethod;
			end
		end
		
		
		function [u_next,varargout] = advance(obj,u,t,dt)
			
			n = length(u);
			s = size(obj.alpha, 2);
			
			if isempty(obj.kron_products)
				obj.kron_products.ALPHA = kron(obj.alpha, eye(n));
				obj.kron_products.BETA = kron(obj.beta, eye(n));
				obj.kron_products.V = kron(eye(n), obj.v);
			end
			
			ALPHA = obj.kron_products.ALPHA;
			BETA = obj.kron_products.BETA;
			V = obj.kron_products.V;
			
			
			if obj.isExplicitMethod()
				% The method we have is explicit. Solve accordingly.
				y = zeros(s*length(u), 1);
				yp = zeros(size(y));
				for i=1:s
					block = (i-1)*n+1:i*n;
					y(block) = obj.v(i)*u + ALPHA(block,1:block(1)-1)*y(1:block(1)-1) + dt*BETA(block,1:block(1)-1)*yp(1:block(1)-1);
					yp(block) = obj.yPrimeFunc(y(block),t);
				end

				block = s*n+1:(s+1)*n;
				u_next = obj.v(s+1)*u + ALPHA(block,:)*y + dt*BETA(block,:)*yp;

			else
				% The method we have is implicit. Solve accordingly.
				u_next = obj.implicitMethod(u, t, dt);
			end
			

		
			% Return whatever extra information we want to view.
			
			varargout{1} = 1;
			varargout{2} = '';	
			
		end	
		
		
		function u_next = implicitMethod(obj, u, t, dt)
		
			n = length(u);
			
			ALPHA = kron(obj.alpha(1:end-1,:), eye(n));
			BETA = kron(obj.beta(1:end-1,:), eye(n));
			V = kron(obj.v(1:end-1), eye(n));

			s = size(obj.alpha, 2);
						
			function res = func(k)
				
				% Evaluate y' for all the stages
				yp = zeros(size(u));
				for i=1:s
					block = (i-1)*n+1:i*n;
					yp(block) = obj.yPrimeFunc(k(block),t);
				end
				res = k - V*u - ALPHA*k - dt*BETA*yp;

			end
			
			u_guess = [ u; zeros((s-1)*n, 1) ];
			K = obj.solver.call(@func, u_guess);
			
			ALPHAe = kron( obj.alpha(end,:), eye(n));
			BETAe = kron( obj.beta(end,:), eye(n));
			
			% Evaluate y' for all the stages
			yp = zeros(size(u));
			for i=1:s
				block = (i-1)*n+1:i*n;
				yp(block) = obj.yPrimeFunc(K(block),t);
			end
			
			u_next = obj.v(end)*u + ALPHAe*K + dt*BETAe*yp;
			u_next = u_next';
			
		end	
		
		function clone = copy(obj)
			meta = metaclass(obj);
			clone = eval([ meta.Name, '()' ]);
			
			ignored_fields = {'kron_products'};
			
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
			coefficient_parameter.name = 'Coefficient File';
			coefficient_parameter.type = 'file_list';
			if ~isempty(obj.coefficient_directory) & exist(obj.coefficient_directory, 'dir')
				files = dir([obj.coefficient_directory, '/*.mat']);
				coefficient_parameter.options = struct( 'path', obj.coefficient_directory,...
				                                        'files', {{files.name}});
			else
				coefficient_parameter.options = [];
			end
			
			coefficient_parameter.default = [];
			
			parameters{end+1} = coefficient_parameter;
			
			parameters = [ parameters{:} ];
			
		end
		
		function repr_struct = get_repr(obj)
			% Get a machine readable representation of this
			% class
			
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			repr_struct.Name = obj.name;
			
%  			if ~isempty(obj.file)
%  				[status, md5sum] = system(['md5 -q ', sprintf('"%s"', obj.file)]);
%  				repr_struct.Md5 = md5sum;
%  			else
%  				repr_struct.Md5 = [];
%  			end
			
			
		end
		
		function id_string = repr(obj)
			% Provide a textual representation of the object
			% that a human can use to identify it
			
			repr_struct = obj.get_repr();
			
			id_fmt = '< %s: %s >';
			id_string = sprintf(id_fmt, repr_struct.Class, ...
			                            repr_struct.Name );
			
		end
		
		
		
	end
end