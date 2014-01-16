classdef LinearODE < SSP_Tools.TestProblems.ODE

	properties
	end
	
	methods
	
		function obj = LinearODE(varargin)
		
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:});
			
			params = p.Unmatched;
			params.name = 'Linear ODE System';
			params.initial_condition = [4/3*exp(1); 0];
			params.initial_time = 0.0;
			
			obj = obj@SSP_Tools.TestProblems.ODE(params);
		
			obj.setup_problem();
		
		end
		
		function y_exact = get_exact_solution(obj, varargin)
			f = @(t) [2/3*exp(1)*(exp(-t)+exp(-19*t));exp(1)*(exp(-t)-exp(-19*t))];
			
			if length(varargin) > 0
				t = varargin{1};
				y_exact = f(t);
			else
				t = obj.t;
				y_exact = zeros(size(obj.y));
				for i=1:size(obj.y,2)
					y_exact(:,i) = f(obj.t(i));
				end
			end
		end
		
	end
	
	methods(Static)
	
		function yp = y_p(y,t)
			yp = [-10*y(1)+6*y(2);13.5*y(1)-10*y(2)];
		end
		
	end
	


end