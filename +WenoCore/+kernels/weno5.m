function [wp, is_values] = weno5(u_values, u_idx, n, epsilon, p)

	persistent stencil_mapping;
	persistent local_flux_values;

	% Coefficients for the interpolant of each stencil
	stencil_coeffs = [ 2./6., -7./6., 11./6.;
                     -1./6.,  5./6., 2./6.; 
                      2./6.,  5./6., -1./6. ]';
	
	% Weights representing the ideal linear combination of stencils
	ideal_weights = [ 1./10., 6./10., 3./10. ];
      
	m = 3;
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
		window = (j-2:j+2)';
		
		% Get the corresponding function values.
		u = u_values(window);
		
		ISp(1) = 13.0/12.0*(u(1)-2.0*u(2)+u(3))^2 + 0.25*(u(1)-4.0*u(2)+3.0*u(3))^2;
		ISp(2) = 13.0/12.0*(u(2)-2.0*u(3)+u(4))^2 + 0.25*(u(2)-u(4))^2;
		ISp(3) = 13.0/12.0*(u(3)-2.0*u(4)+u(5))^2 + 0.25*(3.0*u(3)-4.0*u(4)+u(5))^2;
	
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