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

	wrap = @(x) 2.0*( x/2.0 - floor(x/2.0 - 1/2)) - 2.0;

	u_out = u0(wrap(x_out-t));




end