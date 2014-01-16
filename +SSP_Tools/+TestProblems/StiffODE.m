classdef StiffODE < SSP_Tools.TestProblems.ODE

	properties
	end
	
	methods
	
		function obj = StiffODE(varargin)
		
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:});
			
			params = p.Unmatched;
			params.name = 'Stiff System';
			params.initial_condition = [0; 1; 1];
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
			[t_out, y_exact] = ode23s( @(y,t) obj.y_p(t,y), tspan, obj.initial_condition, ode_params);
			y_exact = y_exact';
			
			if length(varargin) > 0
				y_exact = y_exact(:,end);
			end
		end
	end
	
	methods(Static)
		
		function yp = y_p(y, t)
			yp = [-0.013*y(2)-1000*y(1)*y(2)-2500*y(1)*y(3);-0.013*y(2)-1000*y(1)*y(2);-2500*y(1)*y(3)];
		end
	end
	


end