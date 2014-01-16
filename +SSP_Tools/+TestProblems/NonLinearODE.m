classdef NonLinearODE < SSP_Tools.TestProblems.ODE

	properties
	end
	
	methods
	
		function obj = NonLinearODE(varargin)
		
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:});
			
			params = p.Unmatched;
			params.name = 'Nonlinear ODE System';
			params.initial_condition = [1.5; 1];
			params.initial_time = 0.0;
			
			obj = obj@SSP_Tools.TestProblems.ODE(params);
			
			obj.setup_problem();
		
		end
		
		function y_exact = get_exact_solution(obj, varargin)
		
			if length(varargin) > 0
				t = varargin{1};
				tspan = [obj.domain, t];
			else
				tspan = obj.t;
			end
		
			ode_params = odeset('AbsTol', 1e-16);
			[t_out, y_exact] = ode45( @(y,t) obj.y_p(t,y), tspan, obj.initial_condition, ode_params);
			y_exact = y_exact';
			
			if length(varargin) > 0
				y_exact = y_exact(:,end);
			end
			
		end
	end

	methods(Static)
	
		function yp = y_p(y,t)
			yp = [y(2).*(13-y(1).^2-y(2).^2);12-y(1).*(13-y(1).^2-y(2).^2)];
		end
	
	end

end