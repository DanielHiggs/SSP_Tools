classdef FiniteDifference < SSP_Tools.Discretizers.Discretizer

	properties
	
		% Differentiation matrix
		D = []
		
		% Ghost points
		gp = 1;		
		
	end
	
	methods
		function obj = FiniteDifference(varargin)
			obj = obj@SSP_Tools.Discretizers.Discretizer(varargin{:});
			
			obj.name = 'First order finite difference method';
			obj.order = 1;
			
		end
		
		function make_diff_matrix(obj, x, order)
			% Construct a first-order central difference operator matrix.
			if isempty(obj.D)
			
				dx = min(diff(x));
				grid_size = length(x) + 2*obj.gp;
				
				obj.D = (-speye(grid_size) + diag(ones(1, grid_size-1), 1))/dx;
			end
		end
		
		function [u_plus, u_minus] = split_flux(obj, x, u, t)
			% Split the flux into positive and negative components
			% using a Lax-Freidrichs flux-splitting scheme.
			
			% Calculate em
			em = obj.em(u);
			
			fu = obj.f(u);
			u_em = 0.5*em*u;
			u_plus = 0.5*fu + u_em;
			u_minus = 0.5*fu - u_em;
		end
		
		function u_x = L(obj, x, u, t)
			% Obtain an approximation of the derivative u_x
			
			% Append the ghost points
			u_gp = [ u(end-obj.gp:end-1), u, u(2:obj.gp+1) ];
			
			[u_plus, u_minus] = obj.split_flux(x, u_gp, t);
			
			if isempty(obj.D)
				obj.make_diff_matrix(x, 1)
			end
			
			upwind_flux = -obj.D'*u_minus(end:-1:1)';
			upwind_flux = upwind_flux(end:-1:1);
			downwind_flux = obj.D'*u_plus';
			
			u_x = upwind_flux + downwind_flux;
			u_x = u_x(obj.gp+1:end-obj.gp)';
		end
			
		
		function parameters = get_parameters(obj)
			parameters = [];
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

		function fdcoeffF(order)
				% Based on the program "weights" in 
				%   B. Fornberg, "Calculation of weights in finite difference formulas",
				%   SIAM Review 40 (1998), pp. 685-691.
				% From  http://www.amath.washington.edu/~rjl/fdmbook/  (2007)


				n = length(x);
				if k >= n
				   error('*** length(x) must be larger than k')
				   end

				m = k;   % change to m=n-1 if you want to compute coefficients for all
						 % possible derivatives.  Then modify to output all of C.
				c1 = 1;
				c4 = x(1) - xbar;
				C = zeros(n-1,m+1);
				C(1,1) = 1;
				for i=1:n-1
				  i1 = i+1;
				  mn = min(i,m);
				  c2 = 1;
				  c5 = c4;
				  c4 = x(i1) - xbar;
				  for j=0:i-1
					j1 = j+1;
					c3 = x(i1) - x(j1);
					c2 = c2*c3;
					if j==i-1
					  for s=mn:-1:1
						s1 = s+1;
						C(i1,s1) = c1*(s*C(i1-1,s1-1) - c5*C(i1-1,s1))/c2;
						end
					  C(i1,1) = -c1*c5*C(i1-1,1)/c2;
					  end
					for s=mn:-1:1
					  s1 = s+1;
					  C(j1,s1) = (c4*C(j1,s1) - s*C(j1,s1-1))/c3;
					  end
					C(j1,1) = c4*C(j1,1)/c3;
					end
				  c1 = c2;
				  end

				c = C(:,end)';            % last column of c gives desired row vector
		end
		
		
	end
end
