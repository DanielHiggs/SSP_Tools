function u_x = weno_basic(dx, u, t, f, em, epsilon, p, wenokernel, gp)
	
	% Split the numerical flux into positive and negative components
	fu = f(u, t);
	u_em = 0.5*em*u;
	fp = 0.5*fu + u_em;
	fm = 0.5*fu - u_em;

	Wp = zeros(length(u));
	Wm = zeros(length(u));
	WP = zeros(length(u));
	WM = zeros(length(u));
	
	% Compute the upwind interpolation
	Wp(gp-1:length(fp)-gp,:) = wenokernel(fp, gp-1:length(fp)-gp , length(u), epsilon, p);
	% Compute the downwind interpolation
	Wm(length(fp)-gp+1:-1:gp-1,end:-1:1) = wenokernel(fm(end:-1:1), gp-1:length(fp)-gp+1 , length(u), epsilon, p);

	for i=(gp+1:length(u)-gp)
		WP(i,:) = -(Wp(i,:) - Wp(i-1,:))/dx;
		WM(i,:) = -(Wm(i,:) - Wm(i-1,:))/dx;
	end

	u_x = WP*fp' + WM*fm';
	u_x = u_x(gp+1:length(u)-gp);

end