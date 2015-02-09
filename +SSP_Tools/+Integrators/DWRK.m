classdef DWRK < SSP_Tools.Integrators.Integrator
% NO SUPPORT FOR TIME DEPENDENT PROBLEMS
properties
		
		file=[];
		alpha_plus = [];
		alpha_minus = [];
		V = [];
		
		yDownwindFunc = [];
	end
	
	methods
		function obj = DWRK(varargin)
			obj = obj@SSP_Tools.Integrators.Integrator(varargin{:});
		
			p = inputParser;
			p.KeepUnmatched = true;
			addParamValue(p,'coefficients', false);
			addParamValue(p,'alpha_plus', []);
			addParamValue(p,'alpha_minus', []);
			addParamValue(p,'v', []);
			addParamValue(p,'r', []);
			addParamValue(p,'name', []);
			
			p.parse(varargin{:});
			
			% Load the coefficients if specified.
			if isstr(p.Results.coefficients)
				coeffFile = p.Results.coefficients;
				parameters = load(coeffFile);
				obj.file = coeffFile;
				
				if isfield(parameters, 'alpha_plus') && isfield(parameters, 'alpha_minus') && ...
				   isfield(parameters, 'V') && isfield(parameters, 'r')
					obj.alpha_plus = parameters.alpha_plus;
					obj.alpha_minus = parameters.alpha_minus;
					obj.V = parameters.V;
					obj.r = parameters.r;
				else				
					beta = [];
					r = [];
					if isfield(parameters, 'beta') && isfield(parameters, 'r')
						beta = parameters.beta;
						r = parameters.r;
					elseif isfield(parameters, 'X') && isfield(parameters, 'P')
						[r,beta] = obj.makeBetaR(parameters.X, parameters.s);
					elseif isfield(parameters, 'x') && isfield(parameters, 'p')
						[r, beta] = obj.makeBetaR(parameters.x, parameters.s);
					end
					
					[alpha_plus, alpha_minus] = obj.makeAlpha(beta, r);
					V = obj.makeV(alpha_plus, alpha_minus);
					
					obj.alpha_plus = alpha_plus;
					obj.alpha_minus = alpha_minus;
					obj.V = V;
					obj.r = r;
				end
				coeffFileName = coeffFile(max(strfind(coeffFile, '/'))+1:end);
				obj.name = ['Downwinded Runge-Kutta',' ',coeffFileName ];
			
			elseif ~isempty(p.Results.alpha_plus) && ~isempty(p.Results.alpha_minus)
				obj.alpha_plus = p.Results.alpha_plus;
				obj.alpha_minus = p.Results.alpha_minus
				obj.V = p.Results.V;
				obj.r = p.Results.r;
				obj.name = p.Results.name;
				obj.yDownwindFunc = p.Results.yDownwindFunc;
			end
			
			obj.solver = SSP_Tools.utils.MatlabSolver();
			obj.addlistener('ProblemObject', 'PostSet', @obj.setupDownwinding);
			
		end 
		
		
		function setupDownwinding(obj, source, event)
			% We need a "Downwinded" discretization. The easiest way of
			% getting this is to clone our upwind discretizer and flip
			% the function.
			if strcmp(source.Name, 'ProblemObject') & ~isempty(obj.ProblemObject)
				upwind_discretizer = obj.ProblemObject.getDiscretizer();
				f_downwind = @(varargin) -upwind_discretizer.f(varargin{:});
				downwind_discretizer = upwind_discretizer.copy();
				downwind_discretizer.f = f_downwind;
				obj.yDownwindFunc = @(u,t) obj.ProblemObject.discretize(u,t, @downwind_discretizer.L);
			end
		end
		
		
		function [u_next,varargout] = advance(obj, u, t, dt)
			n = length(u);
			m = size(obj.alpha_plus,1); 
						
			% Perform the implicit steps
			
			V  = kron(obj.V, eye(n));
            %keyboard
			
% 			ALPHA_PLUS = kron(obj.alpha_plus(1:end-1,:),   eye(n));
% 			ALPHA_MINUS = kron(obj.alpha_minus(1:end-1,:), eye(n));
			ALPHA_PLUS = kron(obj.alpha_plus,   eye(n));
			ALPHA_MINUS = kron(obj.alpha_minus, eye(n));            						
			function res = func(k)	
				upwind = k + dt/obj.r*obj.yPrimeFunc(k,t);
				downwind = k + dt/obj.r*(obj.yDownwindFunc(k,t));


%  				upwind = k + dt/obj.r*obj.dudx.L(x,k);
%  				downwind = k + dt/obj.r*(obj.dudx.Ld(x,k));

				res = k - V*u ...
						- ALPHA_PLUS*upwind ...
						- ALPHA_MINUS*downwind;
			end

			% Initial guess vector for the implicit solver. The first block
			% is the current vector-value of u. The other blocks are all zeros.
			% This seems to work best.
			%u_guess = [ u; repmat( zeros(n,1), m-2, 1) ];
            u_guess = [ u; repmat( zeros(n,1), m-1, 1) ];

            %keyboard
			
			% Call the implicit solver.
			[K,FVAL,EXITFLAG,OUTPUT] = obj.solver.call(@func, u_guess);
			if EXITFLAG ~= 1
				u_next = u;
				varargout{1} = EXITFLAG;
				varargout{2} = OUTPUT.message;
				return
			end



			% Perform the final explicit step.
			
% 			ALPHA_PLUSe = kron( obj.alpha_plus(end,:), speye(n));
% 			ALPHA_MINUSe = kron( obj.alpha_minus(end,:), speye(n));
% 			
% 			upwind_explicit = K + dt/obj.r*obj.yPrimeFunc(K,t);
% 			downwind_explicit = K + dt/obj.r*obj.yDownwindFunc(K,t);
%             
%             keyboard
% 			
% 			u_next = ALPHA_PLUSe*upwind_explicit + ALPHA_MINUSe*downwind_explicit;
            s = size(obj.alpha_minus,1);
            u_next = K((s-1)*length(u)+1:end);

%  			UN = obj.alpha_plus(end,:)';
%  			U_NEXT = kron( UN, eye(n));
%  			u_next = K*U_NEXT;



			% Return whatever extra information we want to view.
			
			varargout{1} = 1;
			varargout{2} = sprintf('Iter: %i, fEval %i', OUTPUT.iterations, OUTPUT.funcCount);
			
			
		end	
		
		function [r,beta] = makeBetaR(obj, x, s)
			r = -x(end);
			
			n = s;
			length(x);
			m = floor((length(x) - 1) / s);
			beta = reshape(x(1:end-1),m,n);
		end
		
		function [alpha_plus, alpha_minus] = makeAlpha(obj,beta, r)
            
            % first pad zeros to the last column
            beta = [beta zeros(size(beta,1),1)];
			beta_plus = beta;
			beta_plus(beta<0) = 0;
			
			beta_minus = beta;
			beta_minus(beta>0) = 0;
			
			alpha_plus = abs(r.* beta_plus);
			alpha_minus = abs(r.* beta_minus);
		end
		
		function V = makeV(obj, alpha_plus, alpha_minus)
			V = 1 - (sum(alpha_plus,2) + sum(alpha_minus,2));
			%V = V(1:end-1);
		end
		
		function parameters = get_parameters(obj)
		
			% Set the coefficient directory
			package_path = mfilename('fullpath');
			dir_seps = strfind(package_path, '/');
			package_path = package_path(1:dir_seps(end-1));
			coefficient_directory = [package_path, 'Method Coefficients/Downwinded Runge-Kutta'];
		
			parameters = {};
			coefficient_parameter.keyword = 'coefficients';
			coefficient_parameter.name = 'Coefficient File';
			coefficient_parameter.type = 'file_list';
			if ~isempty(coefficient_directory) & exist(coefficient_directory, 'dir')
				files = dir([coefficient_directory, '/*.mat']);
				coefficient_parameter.options = struct( 'path', coefficient_directory,...
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
			repr_struct.File = obj.file;
			
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
			
			id_fmt = '< %s: %s %s >';
			id_string = sprintf(id_fmt, repr_struct.Class, ...
			                            repr_struct.Name, ...
			                            repr_struct.File );			
		end
		
		
	end
end