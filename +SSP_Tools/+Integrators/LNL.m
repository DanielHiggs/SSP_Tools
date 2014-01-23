classdef LNL < SSP_Tools.Integrators.RK

	properties
	end
	
	methods
	
		function obj = LNL(varargin)
			obj = obj@SSP_Tools.Integrators.RK(varargin{:});

			% Set the coefficient directory
			package_path = mfilename('fullpath');
			dir_seps = strfind(package_path, '/');
			package_path = package_path(1:dir_seps(end-1));
			obj.coefficient_directory = [package_path, 'Method Coefficients/LNL Methods (LNL)'];
			
			% All LNL methods are single step methods
			obj.steps = 1;
			
		end
		
	end
	

end