classdef RK3 < SSP_Tools.Integrators.Integrator
%
% Third order SSP Runge-Kutta Method
%
	
	methods
		function obj = RK3(varargin)
			obj	= obj@SSP_Tools.Integrators.Integrator(varargin{:});
			obj.name = 'RK3';
			obj.order = 3;
			obj.r = 1.0;
		end
	
		function [y_next,varargout] = advance(obj, y, t, dt)
			
			k1 = y + dt*obj.yPrimeFunc(y,t);
			k2 = 0.75*y + 0.25*(k1 + dt*obj.yPrimeFunc(k1,t + dt));
			k3 = (y + 2.0*(k2+dt*obj.yPrimeFunc(k2,t + 1/2*dt)))/3.0;

			y_next = k3;
			
			varargout{1} = 1;
			varargout{2} = ' ';
		end
		
		function repr_struct = get_repr(obj)
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			
		end
		
		function id_string = repr(obj)
			
			repr_struct = obj.get_repr();
			
			id_fmt = '< %s >';
			id_string = sprintf(id_fmt, repr_struct.Class);
		end
		
		function parameters = get_parameters(obj)
			parameters = [];
		end
		
		
	end
end