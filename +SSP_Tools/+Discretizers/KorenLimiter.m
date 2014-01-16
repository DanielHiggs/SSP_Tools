classdef KorenLimiter < SSP_Tools.Discretizers.Discretizer

	properties
	
		% name
		name = 'First order finite difference method';
	
		f = [];
	
		% Differentiation matrix
		D = []
		
		% Ghost points
		gp = 1;
		
		order = 1;
		
		left_boundary = [];
		right_boundary = [];
	
	end
	
	methods
		function obj = KorenLimiter(varargin)
			obj = obj@SSP_Tools.Discretizers.Discretizer(varargin{:});
		end
		
		function make_diff_matrix(obj, x, order)
			% Construct a first-order central difference operator matrix.
			if isempty(obj.D)
			
				dx = min(diff(x));
				grid_size = length(x) + 2*obj.gp;
				
				obj.D = (-eye(grid_size) + diag(ones(1, grid_size-1), 1))/dx;
			end
		end
		
		function [u_plus, u_minus] = split_flux(obj, x, u, t)
			% Split the flux into positive and negative components
			% using a Lax-Freidrichs flux-splitting scheme.
			
			% Calculate em
			if isa(obj.em, 'function_handle')
				em = obj.em(u, t);
			else
				em = obj.em;
			end
			
			fu = obj.f(u, t);
			u_em = 0.5*em*u;
			u_plus = 0.5*fu + u_em;
			u_minus = 0.5*fu - u_em;
		end
		
		function L = upwind_approx(obj, x, u, t)
		
			fHCL = obj.f;
			dx = max(diff(x));
			
			ujp1 = u([2:end,2]);      % u_{j+1}
			ujm1 = u([end-1,1:end-1]);  % u_{j-1}
			
			%th = (u - ujm1) ./ (ujp1 - u);
			if (1==1)
				th = zeros(size(u));
				for i=1:length(u);
					if(ujp1(i) - u(i) == 0)
						th(i) = 1e6;
					else
					th(i) = (u(i) - ujm1(i)) ./ (ujp1(i) - u(i));
					end
				end
			end
			limiter = max(0, ...
					min(2, min(2/3 + 1/3*th, 2*th)) );
			%limiter
			ujph = u + 1/2*limiter .* (ujp1 - u);  % u_{j+1/2}
			
%  			Fjph = fHCL(t,ujph); 
			Fjph = fHCL(ujph, t);
			
			%Fjph = fHCL(t,u);
			
			up = -1/dx * ( Fjph - Fjph([end-1,1:end-1]) );
			
			L=up';
		end
		
		function u_x = L(obj, x, u, t)
			% Obtain an approximation of the derivative u_x
			
			% Append the ghost points
			u_gp = [ u(end-obj.gp:end-1), u, u(2:obj.gp+1) ];
			
			[u_plus, u_minus] = obj.split_flux(x, u_gp, t);
			
			if isempty(obj.D)
				obj.make_diff_matrix(x, 1)
			end
			
			upwind_flux = obj.upwind_approx(x, u_minus(end:-1:1)', t)';
			upwind_flux = upwind_flux(end:-1:1);
			downwind_flux = obj.upwind_approx(x, u_plus', t)';

			u_x = upwind_flux + downwind_flux;
			u_x = u_x(obj.gp+1:end-obj.gp)';
		end
			
		
		function parameters = get_parameters(obj)
			parameters = [];
		end
		
		function repr_struct = get_repr(obj)
			repr_struct = struct();
			
			% Get the name of our class
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			
			% Get the name of our method
			repr_struct.Name = obj.name;
			
		end
		
		function id_string = repr(obj)
			% Provide a textual representation of the object
			% that a human can use to identify it
			
			repr_struct = obj.get_repr();
			
			id_fmt = '< %s >';
			
			id_string = sprintf(id_fmt, repr_struct.Class );
		end
		
		
		function clone = copy(obj)
			meta = metaclass(obj);
			clone = eval([ meta.Name, '()' ]);
			
			ignored_fields = {'dx'};
			
			props = fieldnames(obj);
			for i=1:numel(props)
				if ~any( strcmp(props{i}, ignored_fields) )
					clone.(props{i}) = obj.(props{i});
				end
			end
		end
		
		
	end
	


end