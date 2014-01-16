classdef SSP104 < SSP_Tools.Integrators.SSPRK
	methods
		function obj = SSP104(varargin)

			package_path = mfilename('fullpath');
         dir_seps = strfind(package_path, '/');
         package_path = package_path(1:dir_seps(end-1));
         coefficients = [package_path, 'Method Coefficients/Runge-Kutta (Shu-Osher Form)/SSPRK10-4.mat'];
			obj = obj@SSP_Tools.Integrators.SSPRK('coefficients', coefficients, varargin{:});			

			obj.name = 'SSP(10,4)';
			
			obj.order = 4;
			obj.r = 6;
		end
		
		function m = getM(obj)
			m = 4;
		end
		
		function parameters = get_parameters(obj)
			
			parameters = [];
			
		end
		
		
	end
end