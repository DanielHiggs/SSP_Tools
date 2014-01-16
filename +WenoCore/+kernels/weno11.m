function [wp, is_values] = weno11(u_values, u_idx, n, epsilon, p)

	persistent stencil_mapping;
	persistent local_flux_values;
	
	% Coefficients for the interpolant of each stencil
	stencil_coeffs = [ -10/60,  62/60, -163/60, 237/60, -213/60, 147/60;
                        2/60, -13/60,   37/60, -63/60,   87/60,  10/60;
                       -1/60,   7/60,  -23/60,  57/60,   22/60,  -2/60;
                        1/60,  -8/60,   37/60,  37/60,   -8/60,   1/60;
                       -2/60,  22/60,   57/60, -23/60,    7/60,  -1/60;
                       10/60,  87/60,  -63/60,  37/60,  -13/60,   2/60 ]';
	
	% Weights representing the ideal linear combination of stencils
	ideal_weights =  [ 1/462, 30/462, 150/462, 200/462, 75/462, 6/462 ];
      
	m = 6;
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
		window = (j-5:j+5)';
		
		% Get the corresponding function values.
		u = u_values(window);
		
		ISp(1) =  u(1) * (1152561*u(1) - 12950184*u(2) + 29442256*u(3) - 33918804*u(4)  ...
             + 19834350*u(5) - 4712740*u(6) )  ...
             + u(2) * (36480687*u(2) - 166461044*u(3)  ...
             + 192596472*u(4) - 113206788*u(5) + 27060170*u(6) )  ...
             + u(3) * (190757572*u(3) - 444003904*u(4) + 262901672*u(5) - 63394124*u(6) ) ...
             + u(4) * (260445372*u(4) - 311771244*u(5) + 76206736*u(6) ) ...
             + u(5) * (94851237*u(5) - 47460464*u(6) ) + 6150211*u(6)^2;

		ISp(2) = u(2) * (271779*u(2) - 3015728*u(3) + 6694608*u(4) - 7408908*u(5) + 4067018*u(6)  ...
             - 880548*u(7) ) + u(3) * (8449957*u(3) - 37913324*u(4) + 42405032*u(5)  ...
             - 23510468*u(6) + 5134574*u(7) ) + u(4) * (43093692*u(4) - 97838784*u(5)  ...
             + 55053752*u(6) - 12183636*u(7) ) + u(5) * (56662212*u(5) - 65224244*u(6)  ...
             + 14742480*u(7) ) + u(6) * (19365967*u(6) - 9117992*u(7) ) + 1152561*u(7)^2;

		ISp(3) = u(3) * (139633*u(3) - 1429976*u(4) + 2863984*u(5) - 2792660*u(6) + 1325006*u(7)  ...
             - 245620*u(8) ) + u(4) * (3824847*u(4) - 15880404*u(5) + 15929912*u(6)  ...
             - 7727988*u(7) + 1458762*u(8) ) + u(5) * (17195652*u(5) - 35817664*u(6)  ...
             + 17905032*u(7) - 3462252*u(8) ) + u(6) * (19510972*u(6) - 20427884*u(7)  ...
             + 4086352*u(8) ) + u(7) * (5653317*u(7) - 2380800*u(8) ) + 271779*u(8)^2;

		ISp(4) = u(4) * (271779*u(4) - 2380800*u(5) + 4086352*u(6) - 3462252*u(7) + 1458762*u(8)  ...
             - 245620*u(9) ) + u(5) * (5653317*u(5) - 20427884*u(6) + 17905032*u(7)  ...
             - 7727988*u(8) + 1325006*u(9) ) + u(6) * (19510972*u(6) - 35817664*u(7)  ...
             + 15929912*u(8) - 2792660*u(9) ) + u(7) * (17195652*u(7) - 15880404*u(8)  ...
             + 2863984*u(9) ) + u(8) * (3824847*u(8) - 1429976*u(9) ) + 139633*u(9)^2;

		ISp(5) = u(5) * (1152561*u(5) - 9117992*u(6) + 14742480*u(7) - 12183636*u(8)  ...
             + 5134574*u(9) - 880548*u(10) ) + u(6) * (19365967*u(6) - 65224244*u(7)   ...
             + 55053752*u(8) - 23510468*u(9) + 4067018*u(10) )   ...
             + u(7) * (56662212*u(7) - 97838784*u(8) + 42405032*u(9) - 7408908*u(10) )   ...
             + u(8) * (43093692*u(8) - 37913324*u(9) + 6694608*u(10) )   ...
             + u(9) * (8449957*u(9) - 3015728*u(10) ) + 271779*u(10)^2;

		ISp(6) = u(6) * (6150211*u(6) -47460464*u(7) + 76206736*u(8) - 63394124*u(9) + 27060170*u(10)   ...
             - 4712740*u(11) ) + u(7) * (94851237*u(7) - 311771244*u(8) + 262901672*u(9)   ...
             - 113206788*u(10) + 19834350*u(11) ) + u(8) * (260445372*u(8) - 444003904*u(9)   ...
             + 192596472*u(10) - 33918804*u(11) ) + u(9) * (190757572*u(9) - 166461044*u(10)   ...
             + 29442256*u(11) ) + u(10) * (36480687*u(10) - 12950184*u(11) ) + 1152561*u(11)^2;
	
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