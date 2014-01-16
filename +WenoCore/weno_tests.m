function weno_tests(varargin)

	disp('fooo')
	method = weno_headers();
	
	% Speed Test
	function avg_time = test_speed(n, wenofcn, gp)
		x = linspace(-1, 1, n);
		dx = x(2) - x(1);
		u = sin(pi*x);
		u_gp = [ u(end-gp:end-1), u, u(2:gp+1) ];
		
		f = @(u) u;
		em = 1.0;
		
		avg_time = 0;
		
		for i=1:10
			iter_time = tic();
			wenofcn(dx, u_gp, f, 1.0, 1e-16, 2);
			iter_time = toc(iter_time);
			avg_time = ((avg_time * (i-1)) + iter_time) / i;
		end
	end
	
	weno_methods = fieldnames(method);
	
	for i=1:numel(weno_methods)
		kernel = method.weno_methods{i}.kernel;
		gp = method.weno_methods{i}.gp;
		
		wenofcn = @(dx, u, f, em, epsilon, p) weno_basic(dx, u, f, em, epsilon, p, kernel, gp);
		
		test_speed(11, wenofnc, gp)
	end

	

end