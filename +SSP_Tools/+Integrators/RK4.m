classdef RK4 < SSP_Tools.Integrators.RK
	methods
		function obj = RK4(varargin)
			obj = obj@SSP_Tools.Integrators.RK(varargin{:});			

			obj.name = 'Classic 4th Order Runge-Kutta';
			obj.alpha = [0.0, 0.0, 0.0, 0.0; 
			         0.5, 0.0, 0.0, 0.0;
			         0.0, 0.5, 0.0, 0.0;
			         0.0, 0.0, 1.0, 0.0 ];
			         
			obj.b = [1/6, 1/3, 1/3, 1/6];
			
			obj.c = [ 0, 1/2, 1/2, 1];
			
			obj.order = 4;
			obj.steps = 1;
			obj.r = 0;
		end
		
		function m = getM(obj)
			m = 4;
		end
		
		function parameters = get_parameters(obj)
			
			parameters = [];
			
		end
		
		
	end
end