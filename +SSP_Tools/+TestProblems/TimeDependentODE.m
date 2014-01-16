classdef TimeDependentODE < SSP_Tools.TestProblems.ODE

	properties
	end
	
	methods
	
		function obj = TimeDependentODE(varargin)
		
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:});
			
			params = p.Unmatched;
			params.name = 'Time Dependent ODE y''=\epsilon(t)y^2  \epsilon(t) = 1e-9*t/5   0 > t > 5; 1.e-9 + (1-1.e-9)*(t-5)/5 O.W.';
			params.initial_condition = 1.0;
			params.initial_time = 0.0;
			
			obj = obj@SSP_Tools.TestProblems.ODE(params);			
			obj.setup_problem();
		
		end
		
		function yp = y_p(obj,y,t)
			if t > 0 & t < 5
				epsilon = 1.e-9*t/5;
			else
				epsilon = 1.e-9 + (1-1.e-9)*(t-5)/5;
			end
			
			yp = epsilon*y.^2;
		end
		
		function y_exact = get_exact_solution(obj)
%  			ode_params = odeset('AbsTol', 1e-16, 'RelTol', 1e-8);
			[t_out, y_exact] = ode23s( @(y,t) obj.y_p(t,y), obj.t, obj.initial_condition);%, ode_params);
			y_exact = y_exact';
		end
		
		function parameters = get_parameters(obj)
		
			parameters = {};
			
			parameters{end+1} = struct('keyword', 'epsilon', ...
			                           'name', 'Epsilon Parameter', ...
			                           'type', 'double', ...
			                           'options', [], ...
			                           'default', 0.1 );
			
			parameters{end+1} = struct('keyword', 'integrator', ...
			                       'name', 'Time Stepping Integrator', ...
			                       'type', 'SSP_Tools.Integrators.Integrator',...
			                       'options', [], ...
			                       'default', [] );
		
			parameters = [ parameters{:} ];
		
		end	
		
		
	end

end