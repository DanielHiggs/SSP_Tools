classdef BuckleyLeverett < SSP_Tools.TestProblems.PDE

	properties
	end
	
	methods
		function obj = BuckleyLeverett(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:})
			
			params = p.Unmatched;
			params.name = 'Buckley-Leverett Equation';

			if ~isfield(params, 'domain')
				params.domain = [0, 1];
			end
			
			f = @(x) (x-floor(x))>=0.5;
			params.initial_condition = @(x) 0.5*f(x);
			
			obj = obj@SSP_Tools.TestProblems.PDE(params);
		end
		
		function u_exact = get_exact_solution(obj, varargin)

			if length(varargin) > 0
				t = varargin{1};
			else
				t = obj.t;
			end
		
			u_exact = zeros(size(obj.u));

			for i=1:length(u_exact)
				func = @(u) u - obj.uinit(obj.x(i) - obj.fp(u, obj.x)*t);
				u_exact(i) = fzero(func, obj.u(i), optimset('Display', 'off', 'TolFun', 1e-16, 'TolX', 1e-16));
			end
		end
		
		function fp = fp(obj, u, x);
			% This is with a = 1/3
			fp = (6*u.*(1-u))./(4*u.^2-2*u+1).^2;
		end
		
		function em = em(obj, u)
			em = max(abs(obj.fp(u, obj.x)));
		end
		
		function parameters = get_parameters(obj)
		
			parameters = {};
			
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
			                       'name', 'Number of Gridpoints', ...
			                       'type', 'double',...
			                       'options', [], ...
			                       'default', 50 );
			
			parameters = [ parameters{:} ];
		
		end
	end
	
	methods(Static)
	
		function flux = fflux(u, t)
			flux = u.^2./(u.^2+1.0/3.0*(1-u).^2);
		end	
	end
	

end