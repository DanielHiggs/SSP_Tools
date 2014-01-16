classdef Advection < SSP_Tools.TestProblems.PDE

	properties
		
		a;
		% Wavespeed/Direction Coefficient
		
	end
	
	methods
		function obj = Advection(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('a', []);
			p.parse(varargin{:})
				
			params = p.Unmatched;
			params.name = 'Advection Equation u_t - a*u_x = 0';

			obj = obj@SSP_Tools.TestProblems.PDE(params);
			
			obj.a = p.Results.a;
			
			if isempty(obj.a)
				a_str = 'a';
			else
				a_str = sprintf('%g', obj.a);
			end			
			obj.name = sprintf('Advection Equation u_t - %s*u_x = 0', a_str);

		end
		
		function u_exact = get_exact_solution(obj, varargin)
			if length(varargin) > 0
				t = varargin{1};
			else
				t = obj.t;
			end
			
			u_exact = obj.uinit(obj.x - obj.a*t)';		
		end
		
		function parameters = get_parameters(obj)
			parameters = get_parameters@SSP_Tools.TestProblems.PDE(obj);
			
			local_parameters = struct('keyword', 'a', ...
			                          'name', 'Wavespeed Coefficient', ...
			                          'type', 'double',...
			                          'options', [], ...
			                          'default', 1 );
			                          
			parameters = [ local_parameters, parameters ];
		
		end

		function flux = fflux(obj, u, t);
			flux = obj.a*u;
		end
		
	end
	
	methods(Static)

		function em = em(u, t);
			em = 1.0;
		end
	end

end