function y = matlabSolve( objfun, tRange, y0, solver )
	warning('off', 'MATLAB:odearguments:RelTolIncrease');
%  	fprintf('Warning! No Exact Solution! Comparing Against Numeric Solution\n');
	opt = odeset('RelTol', 1e-14, 'AbsTol', 1e-14);
	[t, y] = solver(objfun, tRange, y0, opt);
	y = y(end,:)';
end