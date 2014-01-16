classdef Discretizer < handle

	properties
		
		% This is the flux-splitting parameter. It can either be
		% a scalar or a function em(u).
		em = [];
	end
	
	methods
	
		function obj = Discretizer(varargin)
			true;
		end
		
		function u_x = L(obj, x, u)
			error('Not Implemented');
		end
		
		function clone = copy(obj)
			error('Not Implemented');
		end
		
		function repr_struct = get_repr(obj)
			error('Not Implemented');
		end
		
		function id_string = repr(obj)
			error('Not Implemented');
		end
		
		function parameters = get_parameters(obj)
			error('Not Implemented');
		end		
		
		
	end

end