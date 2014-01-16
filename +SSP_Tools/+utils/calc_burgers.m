function [x_out, u_out] = calc_burgers(x,t,u0,uu, varargin)
	
	u_out = zeros(size(uu));

	for i=1:length(u_out)
		func = @(u) u - u0(x(i) - u*t);
		u_out(i) = fzero(func, uu(i), optimset('Display', 'off', 'tolFun', 1e-20));
	end
		
	x_out = x;
end



