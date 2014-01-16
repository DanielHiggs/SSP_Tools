function [wp, is_values] = weno9(u_values, u_idx, n, epsilon, p)

	persistent stencil_mapping;
	persistent local_flux_values;
	
	% Coefficients for the interpolant of each stencil
	stencil_coeffs = [  1/5, -21/20, 137/60, -163/60, 137/60;
                     -1/20, 17/60, -43/60, 77/60, 1/5;
                      1/30, -13/60, 47/60, 9/20, -1/20;
                     -1/20, 9/20, 47/60, -13/60, 1/30;
                       1/5, 77/60, -43/60, 17/60, -1/20;]';
	
	% Weights representing the ideal linear combination of stencils
	ideal_weights = [1/126, 10/63, 10/21, 20/63, 5/126];
      
	m = 5;
	u_values = u_values';
	n_points = numel(u_idx);
	
	% Initialize the transposed flux-interpolation matrix.
	%
	wp = zeros(n, n_points);
	%
	% Normally it would be an (n_points x n) sized matrix, with each row 
	% interpolating the flux at x_{i-1/2} using function values at our 
	% grid points, but it's more efficient to construct it column-wise 
	% than row-wise, so we'll be operating on the transpose.
	% 
	
	% Initialize Smoothness Measurements
	ISp = zeros(1,m);
	nonlinear_values = zeros(m,m);

	% Generate stencil indices
	%
	stencils = zeros(m,m);
	stencils(:,1) = (1:m)';
	for i=2:m
		stencils(:,i) = stencils(:,i-1) + 1;
	end
	%
	% 'stencils' is an (m x m) matrix where each column contains the
	% relative indices (1;2;3..., 2,3,4....) for each stencil. 
	% 
	
	% 'local_flux_values' is a matrix used to collect the local flux
	% interpolation values so that they can easily be summed and
	% incorporated into a row of the global flux interpolation matrix.
	if isempty(local_flux_values)
		local_flux_values = zeros(m+(m-1));
		for i=1:m
			stencil_mapping(:, i) = sub2ind(size(local_flux_values), i*ones(1,m), (1:m)+(i-1));
		end
	end
	
	% Define a local index for our points
	j_absidx = 1;
	% 
	% 'j_absidx' references the local index of function values in 'u_values'
	% for constructing rows in the flux interpolation matrix.
	
	for j=u_idx
	
		% Get the global indices of the current point.
		window = (j-4:j+4)';
		
		% Get the corresponding function values.
		u = u_values(window);
		
		ISp(1) = u(1) *(22658*u(1) - 208501*u(2) + 364863*u(3) - 288007*u(4) + 86329*u(5) ) ...
				+ u(2) *(482963*u(2) - 1704396*u(3) + 1358458*u(4) - 411487*u(5) ) ...
				+ u(3) *(1521393*u(3) - 2462076*u(4) + 758823*u(5) ) ...
				+ u(4) *(1020563*u(4) - 649501*u(5) ) + 107918*u(5)^2;
		ISp(2) = u(2) *(6908*u(2) - 60871*u(3) + 99213*u(4) - 70237*u(5) + 18079*u(6) ) ...
				+ u(3) *(138563*u(3) - 464976*u(4) + 337018*u(5) - 88297*u(6) ) ...
				+ u(4) *(406293*u(4) - 611976*u(5) + 165153*u(6) ) ...
				+ u(5) *(242723*u(5) - 140251*u(6) ) + 22658*u(6)^2;
		ISp(3) = u(3) *(6908*u(3) - 51001*u(4) + 67923*u(5) - 38947*u(6) + 8209*u(7) ) ...
				+ u(4) *(104963*u(4) - 299076*u(5) + 179098*u(6) - 38947*u(7) ) ...
				+ u(5) *(231153*u(5) - 299076*u(6) + 67923*u(7) ) ...
				+ u(6) *(104963*u(6) - 51001*u(7) ) + 6908*u(7)^2;
		ISp(4) = u(4) *(22658*u(4) - 140251*u(5) + 165153*u(6) - 88297*u(7) + 18079*u(8) ) ...
				+ u(5) *(242723*u(5) - 611976*u(6) + 337018*u(7) - 70237*u(8) ) ...
				+ u(6) *(406293*u(6) - 464976*u(7) + 99213*u(8) ) ...
				+ u(7) *(138563*u(7) - 60871*u(8) ) + 6908*u(8)^2;
		ISp(5) = u(5) *(107918*u(5) - 649501*u(6) + 758823*u(7) - 411487*u(8) + 86329*u(9) ) ...
				+ u(6) *(1020563*u(6) - 2462076*u(7) + 1358458*u(8) - 288007*u(9) ) ...
				+ u(7) *(1521393*u(7) - 1704396*u(8) + 364863*u(9) ) ...
				+ u(8) *(482963*u(8) - 208501*u(9) ) + 22658*u(9)^2;
	
		% Calculate the normalized weights of each stencil.
		ISp = ideal_weights ./ (ISp + epsilon).^p;
		ISp = ISp ./ norm(ISp,1);
		%
		% norm(x,1) is noticably faster than sum(x) but
		% it should be noted that their results can differ
		% by what's hopefully just an insignificant rounding
		% error. If this is a problem, replace with:
		%
  		% IS = IS / sum(IS);  
  		% 

		% Apply those weights to each stencil.
		interp_coeffs = bsxfun(@times, stencil_coeffs, ISp);

		% Map global indices into our local stencils
		window_indices = window(stencils);
		
		% Update the global flux-interpolation matrix with our local stencils
		local_flux_values(stencil_mapping) = interp_coeffs;
		
		% Update the global flux-interpolation matrix
		wp(window_indices(1):window_indices(end), j_absidx) = sum(local_flux_values);

		% Move on to the next row of the global flux-interpolation matrix.
		j_absidx = j_absidx + 1;
	end
	
	% Return a correctly-transposed matrix.
	wp = wp';
end