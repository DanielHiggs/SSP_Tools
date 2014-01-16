classdef DiscretizerFactory < handle

	properties
		available_discretizers = {};
	end
	
	methods
	
		function obj = DiscretizerFactory(varargin)

			ignored_classes = { 'SSP_Tools.Discretizers.Discretizer' };
		
			package_info = meta.package.fromName('SSP_Tools.Discretizers');
			
			discretizer_info = struct();
			
			% Query each package by instantiating it and examining some properties
			for i=1:numel(package_info.Classes)
				class_name = package_info.Classes{i}.Name;
				if ~strcmp(ignored_classes, class_name)
					method_obj = eval([class_name, '()']);

					% Build a record of some useful properties that any
					% GUI or user interface might like to know...
					dot_idx = strfind(class_name, '.');
					discretizer_info.name = class_name(dot_idx(end)+1:end);
					discretizer_info.longname = [];
					discretizer_info.class = class_name;
					discretizer_info.order = method_obj.order;
					discretizer_info.parameters = method_obj.get_parameters();
					
					obj.available_discretizers{end+1} = discretizer_info;
				end
			end
			
			% Sort the methods by their order of accuracy
			obj.available_discretizers = [ obj.available_discretizers{:} ];
%  			[~, idx] = sort( [obj.available_discretizers.order] );
%  			obj.available_discretizers = obj.available_discretizers(idx);

		end
		
		function list = list(obj)
			% Return an indexed list of available methods suitable
			% for a text-based UI
			for i=1:numel(obj.available_discretizers)
				fmt = '[%i] %s\n';
				fprintf(fmt, i, obj.available_discretizers(i).name);
			end
		end
		
		function query(obj, class)
			
			idx = find(strcmp({obj.available_discretizers.class}, class));
			
			if ~isempty(idx)
			
				discretizer = obj.available_discretizers(idx);
				fprintf('\nListing parameters for: %s()\n\n', discretizer.class);
				for i=1:numel(discretizer.parameters)
					fprintf('%s (%s) - %s\n', discretizer.parameters(i).keyword,...
					                          discretizer.parameters(i).type,...
					                          discretizer.parameters(i).name );
				end
				fprintf('\n\n');
			end
		end
		
		function [class_name, init] = interactive_select(obj)
			% Select and configure a method
			
			% Print a list of available methods
			obj.list();
			n = input('Select a discretizer: ');
			method = obj.available_discretizers(n);
			class_name = method.class;
			
			fprintf('Configuration options\n\n');
			
			init = struct();
			for i=1:numel(method.parameters)
				
				keyword = method.parameters(i).keyword;
				parameter_name = method.parameters(i).name;
				default_value = method.parameters(i).default;
				options = method.parameters(i).options;

				if strcmp(method.parameters(i).type, 'double')				
					query_string = sprintf('%s %s [%g]:', parameter_name, ...
					                                      keyword, ...
					                                      default_value );
					init.(keyword) = input(query_string);
					if isempty(init.(keyword)) & ~isempty(method.parameters(i).default);
						init.(keyword) = method.parameters(i).default;
					end
				elseif strcmp(method.parameters(i).type, 'kernel-list')
					
					% Sort the available kernels by their order
					[~, sort_idx] = sort([options.order]);
					options = options(sort_idx);
					
					% Print out a list
					for opt_idx=1:numel(options)
						fprintf('[%i] %s\n', opt_idx, options(opt_idx).name);
					end
					query_string = sprintf('%s %s [%s]:', parameter_name, ...
					                                      keyword, ...
					                                      default_value );
					
					kernel_idx = input(query_string);
					if ~isempty(kernel_idx)
						init.(keyword) = upper(options(kernel_idx).name);
					else
						init.(keyword) = upper(options(1).filename)
					end
				end
			end
		end 

		function method = select(obj, varargin)
			% Interactively select a fully-formed method
			[class_name, init] = obj.interactive_select(varargin{:});
			method = feval(class_name, init);
		end
		
		function init_string = select_initstring(obj, varargin)
			% Interactively select the init string needed
			% to initialize a method
			[class_name, init] = obj.interactive_select(varargin{:});
			
			arg_string = '';
			fields = fieldnames(init);
			for j=1:numel(fields)
				if ischar(init.(fields{j}))
					arg_string = [arg_string, sprintf('''%s'', ''%s''', fields{j}, init.(fields{j})) ];
				elseif isnumeric(init.(fields{j}))
					arg_string = [arg_string, sprintf('''%s'', %g', fields{j}, init.(fields{j})) ];
				end
				
				if j < numel(fields)
					arg_string = [arg_string, ', '];
				end
			end
			
			init_string = sprintf('%s(%s)', class_name, arg_string);
		end
		
	end
end