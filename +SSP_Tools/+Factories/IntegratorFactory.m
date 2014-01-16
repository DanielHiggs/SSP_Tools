classdef IntegratorFactory < handle

	properties
		available_integrators;
	end
	
	methods
	
		function obj = IntegratorFactory(varargin)
		
			ignored_classes = { 'SSP_Tools.Integrators.RK', ...
			                    'SSP_Tools.Integrators.DWRK', ...
			                    'SSP_Tools.Integrators.Integrator' };
			
			package_info = meta.package.fromName('SSP_Tools.Integrators');
			
			integrator_info = struct();
			
			% Query each package by instantiating it and examining some properties
			for i=1:numel(package_info.Classes)
				class_name = package_info.Classes{i}.Name;
				if ~strcmp(ignored_classes, class_name)
					method_obj = eval([class_name, '()']);

					% Build a record of some useful properties that any
					% GUI or user interface might like to know...
					dot_idx = strfind(class_name, '.');
					integrator_info.name = class_name(dot_idx(end)+1:end);
					integrator_info.longname = [];
					integrator_info.class = class_name;
					integrator_info.order = method_obj.order;
					integrator_info.parameters = method_obj.get_parameters();
					
					obj.available_integrators{end+1} = integrator_info;
				end
			end
			obj.available_integrators = [obj.available_integrators{:}];
		end
	
		function list = list(obj)
			% Return an indexed list of available methods suitable
			% for a text-based UI
			for i=1:numel(obj.available_integrators)
				fmt = '[%i] %s\n';
				fprintf(fmt, i, obj.available_integrators(i).name);
			end
		end
		
		function query(obj, class)
			
			idx = find(strcmp({obj.available_integrators.class}, class));
			
			if ~isempty(idx)
			
				integrator = obj.available_integrators(idx);
				fprintf('\nListing parameters for: %s()\n\n', integrator.class);
				for i=1:numel(integrator.parameters)
					fprintf('%s (%s) - %s\n', integrator.parameters(i).keyword,...
					                          integrator.parameters(i).type,...
					                          integrator.parameters(i).name );
				end
				fprintf('\n\n');
			end
		end
		
		function [class_name, init_params] = interactive_select(obj, varargin)
			% Select and configure a method
			
			% Print a list of available methods
			obj.list();
			n = input('Select an integrator: ');
			method = obj.available_integrators(n);
			class_name = method.class;
			
			fprintf('Configuration options\n\n');
			
			init_params = struct();
			
			unneeded_parameters = {};
			
			for i=1:numel(method.parameters)			

				keyword = method.parameters(i).keyword;
				
				if iscell(keyword)
					% We're dealing with a group of parameters whose presence is
					% controlled by a function we're provided.
					
					additional_params = struct();
					for keyword_in_group=keyword
						additional_params = setfield(additional_params, keyword_in_group{:}, []);
					end
					
					parameter_function = method.parameters(i).options;
					
					while true
						parameter_desc = parameter_function(additional_params);
						if isempty(parameter_desc)
							break
						else
							new_params = parse_parameter(parameter_desc);
							
							% Merge them into our parameters
							fields = fieldnames(new_params);
							for in=1:numel(fields)
								additional_params.(fields{in}) = new_params.(fields{in});
							end
						end
					end
				elseif any(strcmp(unneeded_parameters, keyword))
					continue;
				else
					parameter_desc = method.parameters(i);
					additional_params = parse_parameter(parameter_desc);
				end
				
				% Now we add the parameter(s)/value(s) to the struct that will be used
				% to intitialize the SSP_Tools.Integrators.Integrator object.
				fields = fieldnames(additional_params);
				for in=1:numel(fields)
					init_params.(fields{in}) = additional_params.(fields{in});
				end				
			end
			
			function init = parse_parameter(parameter)
			% This function parses information about a method's parameter and
			% provides the user with the appropriate prompts for setting
			% that parameter. It returns a structure.
			
				init = struct();
			
				keyword = parameter.keyword;
				parameter_name = parameter.name;
				default_value = parameter.default;
				type = parameter.type; 
				options = parameter.options;
				
				if strcmp(type, 'text')
					query_string = sprintf('%s %s [%s]:', parameter_name, ...
																		keyword, ...
																		default_value );
					init.(keyword) = input(query_string); 
					if isempty(init.(keyword))
						init.(keyword) = method.parameters(i).default;
					end
				elseif strcmp(type, 'double')
					query_string = sprintf('%s %s [%g]:', parameter_name, ...
																	  keyword, ...
																 	  default_value );
					init.(keyword) = input(query_string); 
					if isempty(init.(keyword))
						init.(keyword) = method.parameters(i).default;
					end
				elseif strcmp(type, 'file_list')
					fprintf('\nSelect %s:\n', parameter_name);
					for j=1:numel(options.files)
						fprintf('[%i] %s\n', j, options.files{j});
					end
					n_coeff = input('Select Coefficient File: ');
					init.(keyword) = [ options.path, '/', options.files{n_coeff}];
					
				elseif strcmp(type, 'list')
					for j=1:numel(options)
						fprintf('[%i] %s\n', j, options(j).longname);
					end
					n_selection = input(sprintf('Select %s [%s]: ', parameter_name, default_value));
					init.(keyword) = [ options(n_selection).name];
					
					if isfield(options(n_selection), 'unneeded') & ~isempty(options(n_selection).unneeded)
						unneeded_parameters = [unneeded_parameters, options(n_selection).unneeded];
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