classdef RK5 < SSP_Tools.Integrators.RK
	methods
		function obj = RK5(varargin)
			obj = obj@SSP_Tools.Integrators.RK(varargin{:});
			
			name = '5th Order Runge-Kutta';
			obj.alpha = [       0.0,         0.0,        0.0,      0.0,         0.0,    0.0, 0.0; 
			                1/5,         0.0,        0.0,      0.0,         0.0,    0.0, 0.0;
			               3/40,        9/40,        0.0,      0.0,         0.0,    0.0, 0.0;
			              44/45,      -56/15,       32/9,      0.0,         0.0,    0.0, 0.0;
			         19372/6561, -25360/2187, 64448/6561, -212/729,         0.0,    0.0, 0.0;
			          9017/3168,     -355/33, 46732/5247,   49/176, -5103/18656,    0.0, 0.0;
			             35/384,           0,   500/1113,  125/192, -2187/6784,   11/84, 0.0];
			         
			obj.b = [    35/384, 0,   500/1113, 125/192,    -2187/6784,    11/84,    0; ];
			
			obj.c = [ 0, 1/5, 3/10, 4/5, 8/9, 1, 1];

			obj.order = 5;
			obj.steps = 1;
			obj.r = 0;
		end
		
		function parameters = get_parameters(obj)
			
			parameters = [];
			
		end
		
	end
end