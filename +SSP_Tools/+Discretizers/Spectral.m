classdef Spectral < SSP_Tools.Discretizers.Discretizer
%
% This class implements a basic spectral method based on fourier collocation.
%
	properties
		ghost_points;
		gp = 0;
		name = 'Spectral Fourier Collocation Method';
		
		f = [];
		order = inf;
		
		left_boundary = [];
		right_boundary = [];
		
		Dp = [];
		Dm = [];
	end
	methods 
		function obj = Spectral(varargin)
			obj = obj@SSP_Tools.Discretizers.Discretizer(varargin{:});
		end
		
		function [u_plus, u_minus] = split_flux(obj, x, u, t)
			% Split the flux into positive and negative components
			% using a Lax-Freidrichs flux-splitting scheme.
			
			% Calculate em
			em = obj.em(u);
			
			fu = obj.f(u, t);
			u_em = 0.5*em*u;
			u_plus = 0.5*fu + u_em;
			u_minus = 0.5*fu - u_em;
		end

		function u_x = L(obj,x,u,t)
		% Obtain an approximation for f(u)_x
			n = length(x);
			
			x_mult = 2*pi/(x(end)-x(1));
			
			m = n-1;

			if (mod(m,2) ~= 0)
				error('Domain must have an even number of points')
			end
	
			x_diffs = diff(x);
			if any( (x_diffs - x_diffs(1)) > 1e-15 )
				error('Domian must be an evenly spaced grid')
			end
			
			x_map = linspace(0, 2*pi, n);
			xp = x_map(2:end);
			xm = x_map(1:end-1);
			
			if isempty(obj.Dp) & isempty(obj.Dm)
				Dp = zeros(m);
				Dm = zeros(m);
				for i=1:m
					for j=1:m
						if i ~= j
							Dp(i,j) = 1/2 * (-1)^(i+j) * cot((xp(i) - xp(j))/2);
							Dm(i,j) = 1/2 * (-1)^(i+j) * cot((xm(i) - xm(j))/2);
						else
							Dp(i,j) = 0;
							Dm(i,j) = 0;
						end
					end
				end
				
				obj.Dp = Dp;
				obj.Dm = Dm;
			else
				Dp = obj.Dp;
				Dm = obj.Dm;
			end
				
				
			% Flux splitting
			[fp,fm] = obj.split_flux(x, u, t);
			
			% Lop off the duplicate point from periodic boundary conditions
			fp = fp(2:end);
			fm = fm(1:end-1);
			
			Lp = -Dp*fp';
			Lp = [ Lp(end); Lp ];
			
			Lm = -Dm*fm';
			Lm = [ Lm; Lm(1) ];
			
			
			
			u_x = x_mult*(Lp + Lm)';
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

		function repr_struct = get_repr(obj)
			repr_struct = struct();
			
			% Get the name of our class
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
		
		end
		
		function id_string = repr(obj)
			% Provide a textual representation of the object
			% that a human can use to identify it
			
			repr_struct = obj.get_repr();
			
			id_fmt = '< %s >';
			
			id_string = sprintf(id_fmt, repr_struct.Class );
		end
		
	end	
end