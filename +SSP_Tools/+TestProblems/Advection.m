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
		
		function fp = fp(obj, u, x);
			fp = obj.a;
		end
	
		function em = em(obj, u);
			em = max(abs(obj.fp(u, obj.x)));
		end
		
		function repr_struct = get_repr(obj)
			% Get a machine readable representation of this
			% class
			repr_struct = get_repr@SSP_Tools.TestProblems.PDE(obj);
			repr_struct.a = obj.a;
		end		
		
	end
	
	methods(Static)


	end

end