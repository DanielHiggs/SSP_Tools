classdef ImplicitMidpoint < SSP_Tools.Integrators.RK
	methods
		function obj = ImplicitMidpoint(varargin)
			obj = obj@SSP_Tools.Integrators.RK(varargin{:});			

			name = 'Implicit Midpoint';
			obj.alpha = [1/2];
			obj.b = [1.0];
			obj.c = [1/2];
			obj.order = 2;

		end
		
		function parameters = get_parameters(obj)
			
			parameters = [];
			
		end
		
		
	end
end
