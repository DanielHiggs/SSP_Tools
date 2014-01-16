classdef Dalquist < SSP_Tools.TestProblems.ODE

	properties
	end
	
	methods
	
		function obj = Dalquist(varargin)
		
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:});
			
			params = p.Unmatched;
			params.name = 'dalquist y''=2y';
			params.initial_condition = 1.0;
			params.initial_time = 0.0;
			
			obj = obj@SSP_Tools.TestProblems.ODE(params);
			
			obj.setup_problem();
		end
		
		function y_exact = get_exact_solution(obj, varargin)
		
			f = @(t) exp(2*t);
		
			if length(varargin) > 0
				t = varargin{1};
				y_exact = f(t);
			else
				t = obj.t;
				y_exact = zeros(size(obj.y));
				for i=1:numel(obj.y)
					y_exact(i) = f(obj.t(i));
				end
			end
		

		end
	end
	
	methods(Static)
		
		function yp = y_p(y, t)
			yp = 2.*y;
		end
	end
	


end