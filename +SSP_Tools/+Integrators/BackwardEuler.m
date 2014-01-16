classdef BackwardEuler < SSP_Tools.Integrators.RK
	methods
		function obj = BackwardEuler(varargin)
			obj = obj@SSP_Tools.Integrators.RK(varargin{:});			

			name = 'Backwards Euler';
			obj.alpha = [1.0];
			obj.b = [1.0];
			obj.c = [1.0];
			obj.order = 1;

		end
		
		function parameters = get_parameters(obj)
			
			parameters = [];
			
		end
		
		
	end
end
