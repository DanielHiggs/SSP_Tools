classdef Discretizer < handle

	properties
		
		% This is the function f(u)_x we're approximating the 
		% spatial derivative of.
		f = [];
		
		% This is the flux-splitting parameter. It should be a function
		% that returns f'(u)
		em = [];
		
		% The method's order of accuracy.
		order = [];
		
		% Currently unused attributes for enfourcing boundary conditions
		left_boundary = [];
		right_boundary = [];
		
		% This is a human-readable name for our spatial method
		name = [];
		
	end
	
	methods
	
		function obj = Discretizer(varargin)
			p = inputParser();
			p.KeepUnmatched = true;
			p.addParamValue('f', []);
			p.parse(varargin{:});
			
			if ~isempty(p.Results.f)
				obj.f = p.Results.f;
			end			
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
		
		function name = get.name(obj)
		% MATLAB won't let subclasses define getter methods for properties that
		% are defined in their parents. In order for WenoCore to have a getter
		% method attached to the 'name' property, we have to define it here and
		% delegate the actual getting to an additional method that can be
		% overridden in WenoCore.
		% 
		
			% Call the overridden method.
			name = obj.get_name();
			
			% If the overridden method returns empty, it means
			% we should just return the value of obj.name which
			% obj.get_name() can't access without recursively calling
			% *this* function because MATLAB is stupid.
			if isempty(name)
				name = obj.name;
			end
			
		end
		
		function name = get_name(obj)
		% Return a null array for classes that don't want to override get_name()
			name = [];
		end
		
		
	end

end