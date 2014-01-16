function obj = instantiate(class, varargin)
	% This is a generic constructor method for MATLAB. Unlike Python, MATLAB
	% doesn't let us store references to classes in variables, so instantiating
	% objects must be done explicitly. 
	% 
	% Here we cheat using the eval() function. class is a string specifying the
	% class we want to create an object from, and varargin contains a list of 
	% parameters to sent to the constructor function.
	% 

	obj = eval([ class, '( varargin{:} )']);

end