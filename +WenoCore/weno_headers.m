function varargout = weno_headers(varargin)
%
% Return a structure containing information about the various
% weno functions available within this package
%
	method.weno5.kernel = @kernels.weno5;
	method.weno5.gp = 4;

	method.weno9.kernel = @kernels.weno9;
	method.weno9.gp = 6;

	method.weno11.kernel = @kernels.weno11;
	method.weno11.gp = 7;

	method.weno13.kernel = @kernels.weno13;
	method.weno13.gp = 8;

	method.weno15.kernel = @kernels.weno15;
	method.weno15.gp = 9;
	
	varargout{1} = method;
	
end