classdef RK7 < SSP_Tools.Integrators.RK
	methods
		function obj = RK7(varargin)
			obj = obj@SSP_Tools.Integrators.RK(varargin{:});			
			
			obj.name = 'Fehlberg 7th Order Runge-Kutta';
			
			obj.order = 7;
			obj.steps = 1;
			obj.stages = 7;
			obj.r = 0;
			
			A = zeros(10, 10);
			
			A(2,1) = 2/33;
			
			A(3,2) = 4/33;
			
			A(4,1) = 1/22;
			A(4,3) = 3/22;
			
			A(5,1) = 43/64;
			A(5,3) = -165/64;
			A(5,4) = 77/32;
			
			A(6,1) = -2383/486;
			A(6,3) = 1067/54;
			A(6,4) = -26312/1701;
			A(6,5) = 2176/1701;
			
			A(7,1) = 10077/4802;
			A(7,3) = -5643/686;
			A(7,4) = 116259/16807;
			A(7,5) = -6240/16807;
			A(7,6) = 1053/2401;
			
			A(8,1) = -733/176;
			A(8,3) = 141/8;
			A(8,4) = -335763/23296;
			A(8,5) = 216/77;
			A(8,6) = -4617/2816;
			A(8,7) = 7203/9152;
			
			A(9,1) = 15/352;
			A(9,4) = -5445/46592;
			A(9,5) = 18/77;
			A(9,6) = -1215/5632;
			A(9,7) = 1029/18304;
			
			A(10,1) = -1833/352;
			A(10,3) = 141/8;
			A(10,4) = -51237/3584;
			A(10,5) = 18/7;
			A(10,6) = -729/512;
			A(10,7) = 1029/1408;
			A(10,9) = 1.0;
			
			obj.alpha = A;
			
			
			obj.c = [0, 2/33, 4/33, 2/11, 1/2, 2/3, 6/7, 1, 0, 1];
			
			% These coefficients provide the sixth order embedded method.
			%b6 = [77/1440, 0, 0, 1771561/6289920, 32/105, 243/2560, 16807/74880, 11/270, 0, 0];
			
			obj.b = [ 11/864, 0, 0, 1771561/6289920, 32/105, 243/2560, 16807/74880, 0, 11/270, 11/270];
		end
		
		function m = getM(obj)
			m = 4;
		end
		
		function parameters = get_parameters(obj)
			
			parameters = [];
			
		end
		
		
	end
end