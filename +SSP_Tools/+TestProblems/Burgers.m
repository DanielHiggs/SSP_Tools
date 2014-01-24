classdef Burgers < SSP_Tools.TestProblems.PDE

	properties
	end
	
	methods
		function obj = Burgers(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:})
			
			params = p.Unmatched;
			params.name = 'Burgers Equation u_t + (1/2*u^2)_x = 0';

			if ~isfield(params, 'domain')
				params.domain = [0, 1];
			end
			
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
				func = @(u) u - obj.uinit(obj.x(i) + obj.fp(u, obj.x)*t);
				u_exact(i) = fzero(func, obj.u(i), optimset('Display', 'off', 'TolFun', 1e-16, 'TolX', 1e-16));
			end
		end

		function fp = fp(obj, u, x);
			fp = u;
		end
		
		function em = em(obj, u)
			em = max(abs(obj.fp(u, obj.x)));
		end		
			
	end


	
	methods(Static)
		
		function flux = fflux(u, t)
			flux = -0.5*u.^2;
		end
		
	end

end