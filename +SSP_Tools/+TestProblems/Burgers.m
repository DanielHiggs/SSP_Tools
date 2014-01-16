classdef Burgers < SSP_Tools.TestProblems.PDE

	properties
	end
	
	methods
		function obj = Burgers(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:})
			
			params = p.Unmatched;
			params.name = 'Burgers Equation u_t - (1/2*u)_x = 0';

			if ~isfield(params, 'domain')
				params.domain = [-1, 1];
			end
			
			obj = obj@SSP_Tools.TestProblems.PDE(params);
		end
		
		function u_exact = get_exact_solution(obj)
			u_out = zeros(size(obj.u));
			for i=1:numel(obj.x)
				func = @(u) u - obj.uinit(obj.x(i) - u*obj.t);
				u_out(i) = fzero(func, obj.u(i), optimset('Display', 'off', 'tolFun', 1e-20));
			end
			u_exact = u_out;
		end
	end
	
	methods(Static)
		
		function flux = fflux(u, t)
			flux = 0.5*u.^2;
		end
		
		function em = em(u, t)
			em = max(abs(u));
		end
		
	end

end