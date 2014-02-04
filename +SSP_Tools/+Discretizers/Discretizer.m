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
		
		function repr_struct = get_repr(obj)
			% Get a machine readable representation of this
			% class
			
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			repr_struct.name = obj.name;

		end
		
		function id_string = repr(obj)
		% Return a structure containing information about the
		% commands supported by this class.

			repr_struct = obj.get_repr();
			
			% First include the default repr values
			id_fmt = '< %s%%s >';
			
			id_string = sprintf(id_fmt, repr_struct.Class );
	
			for field={'Class', 'name'}
				field=field{1};
				repr_struct = rmfield(repr_struct, field);
			end
			
			% Add any additional fields to the id_string by iterating over 
			% the ones that are still left in the structure.
			additional_fields = ' :';
			addn_fields = fieldnames(repr_struct);
			for k=1:numel(addn_fields)
				field = addn_fields{k};
				if ~isempty(repr_struct.(field))
					% Try to get the formatting of the data correct.
					if isnumeric(repr_struct.(field))
						fmt = '%g';
					else
						fmt = '%s';
					end	
					additional_fields = [ additional_fields, ' ', sprintf(['%s=', fmt], field, repr_struct.(field)) ];
				end
			end
			
			if numel(additional_fields) > 2
				id_string = sprintf(id_string, additional_fields);
			else
				id_string = sprintf(id_string, '');
			end
			
		end
		
	end

end