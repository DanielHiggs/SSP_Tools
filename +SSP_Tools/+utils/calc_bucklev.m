function [x_out, u_out] = calc_bucklev(x,t,u0,uu, varargin)
	
%  	if length(varargin) == 1
%  		x_out = varargin{1};
%  	else
%  		x_out = x;
%  	end
%  	
%  	
%  	if length(x) ~= length(x_out) && x(1) == x_out(1) && x(end) == x_out(end)
%  		PP = spline(x,uu);
%  		uu = ppval(PP, x_out);
%  	else
%  		x(1)
%  		x(end)
%  		x_out(1)
%  		x_out(end)
%  		error('foo');
%  	end
	
	
	x_out = x;
	u_out = zeros(size(uu));

	% This is with a = 1/3

	a = @(u) (6*u.*(1-u))./(4*u.^2-2*u+1).^2;

	for i=1:length(u_out)
		func = @(u) u - u0(x_out(i) - a(u)*t);
		u_out(i) = fzero(func, uu(i), optimset('Display', 'off', 'TolFun', 1e-16, 'TolX', 1e-16));
	end
		
end



