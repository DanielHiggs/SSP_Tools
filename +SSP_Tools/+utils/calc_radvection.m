function [x_out, u_out] = calc_advection(x,t,u0,uu, varargin)
	%
	% Calculates the exact solution of the advection equation
	%
	% Parameters:
	%              x          domain of solution
	%              t          time-of-solution
	%              u0         initial value (function handle)
	%              uu         estimate of solution (for compatibility purposes)
	
	if length(varargin) > 0
		x_out = varargin{1};
	else
		x_out = x;
	end

	u_out = u0(mod(x_out+t,1));

end