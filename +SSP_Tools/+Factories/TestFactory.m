classdef TestFactory < handle

	properties
		available_tests = [];
	end
	
	methods
	
		function obj = TestFactory(varargin)
			ignored_classes = {'SSP_Tools.Tests.Test', ...
			                   'SSP_Tools.Tests.PointwiseConvergence',...
			                   'SSP_Tools.Tests.PropertyTest',...
			                   'SSP_Tools.Tests.Convergence' };
			package_info = meta.package.fromName('SSP_Tools.Tests');
			test_info = struct();
			
			% Query each package by instantiating it and examining some properties
			for i=1:numel(package_info.Classes)
				class_name = package_info.Classes{i}.Name;
				if ~strcmp(ignored_classes, class_name)
					method_obj = eval([class_name, '()']);

					% Build a record of some useful properties that any
					% GUI or user interface might like to know...
					dot_idx = strfind(class_name, '.');
					test_info.name = class_name(dot_idx(end)+1:end);
					test_info.longname = method_obj.name;
					test_info.class = class_name;
					test_info.parameters = method_obj.get_parameters();
					
					obj.available_tests{end+1} = test_info;
				end
			end
			obj.available_tests = [obj.available_tests{:}];
		end
		
		function list = list(obj)
			% Return an indexed list of available methods suitable
			% for a text-based UI
			for i=1:numel(obj.available_tests)
				fmt = '[%i] %s\n';
				fprintf(fmt, i, obj.available_tests(i).longname);
			end
		end
		
		function method = select(obj, varargin)
			% Select and configure a method
			
			p = inputParser;
			p.addParamValue('name', []);
			p.addParamValue('ignored_parameters', {});
			p.parse(varargin{:});
			
			ignored_parameters = p.Results.ignored_parameters;
			
			if isempty(p.Results.name)
				% Print a list of available methods
				% And interactively select one.
				obj.list();
				n = input('Select a Test: ');
				method = obj.available_tests(n);
			else
				% Select a test by comparing p.Results.name against
				% the 'name' field of obj.available_tests and 
				% select the one that matches.
				name_cmp = strcmp({obj.available_tests.name}, p.Results.name);
				if name_cmp > 1
					error('More than one test found');
				else
					n = find(name_cmp);
					method = obj.available_tests(n);
				end
			end

			
			fprintf('Configuration options\n\n');
			
			init_params = struct();

			for i=1:numel(method.parameters)
				
				keyword = method.parameters(i).keyword;
				type = method.parameters(i).type;
				
				if strcmp(keyword, ignored_parameters)
					% If we've been asked to ignore a parameter
					% (as is sometimes convenient when creating a
					% prototype) skip it.
					continue
				end
								
				if strcmp(type, 'function_defined')
				% If the parameter is of this type, the actual parameter is defined by
				% calling a function with whatever parameters we currently have defined.
				% This is so one parameter can be dependent on another even if they're not
				% very tightly grouped.
					parameter_function = method.parameters(i).options;
					while true
						[parameter_desc, additional_params] = parameter_function(additional_params, init_params);
						if isempty(parameter_desc)
							break
						else
							new_params = obj.parse_parameter(parameter_desc);
							
							% Merge them into our parameters
							fields = fieldnames(new_params);
							for in=1:numel(fields)
								additional_params.(fields{in}) = new_params.(fields{in});
							end
						end
					end
				else
					parameter_desc = method.parameters(i);
					additional_params = obj.parse_parameter(parameter_desc);
				end
				
				% Now we add the parameter(s)/value(s) to the struct that will be used
				% to intitialize the SSP_Tools.Integrators.Integrator object.
				fields = fieldnames(additional_params);
				for in=1:numel(fields)
					init_params.(fields{in}) = additional_params.(fields{in});
				end
			end
			
			method = feval(method.class, init_params);
		end 

		function init = parse_parameter(obj, parameter)
		% This function parses information about a method's parameter and
		% provides the user with the appropriate prompts for setting
		% that parameter. It returns a structure.
		
			init = struct();
		
			keyword = parameter.keyword;
			parameter_name = parameter.name;
			parameter_desc = parameter.longname;
			default_value = parameter.default;
			type = parameter.type; 
			options = parameter.options;

			if strcmp(type, 'double')
				query_string = sprintf('%s %s [%g]:', parameter_desc, ...
																	keyword, ...
																	default_value );
				init.(keyword) = input(query_string); 
				if isempty(init.(keyword))
					init.(keyword) = default_value;
				end
			elseif strcmp(type, 'string')
				query_string = sprintf('%s %s [%s]:', parameter_desc, ...
																	keyword, ...
																	default_value );
				init.(keyword) = input(query_string); 
				if isempty(init.(keyword))
					init.(keyword) = default_value;
				end
			elseif strcmp(type, 'directory')
				init.(keyword) = SSP_Tools.utils.SelectFile(parameter_desc, ...
				                                            'type', 'dir', ...
				                                            'default', default_value );
			elseif strcmp(type, 'integer')
				query_string = sprintf('%s %s [%d]:', parameter_desc, ...
																	keyword, ...
																	default_value );
				init.(keyword) = input(query_string); 
				if isempty(init.(keyword))
					init.(keyword) = default_value;
				end
			elseif strcmp(type, 'vector')
				query_string = sprintf('%s %s:', parameter_desc, ...
															keyword );
				init.(keyword) = input(query_string); 
				if isempty(init.(keyword))
					init.(keyword) = default_value;
				end
			elseif strcmp(type, 'option_list')
				fprintf('\n\nSelect %s:\n', parameter_desc);
				for idx=1:numel(options)
					fprintf('[%i] %s\n', idx, options(idx).name);
				end
				idx = input('Selection: ');
				init.(keyword) = options(idx).value;
				if isempty(init.(keyword))
					init.(keyword) = default_value;
				end
			elseif strcmp(type, 'problem')
				factory = SSP_Tools.Factories.ProblemFactory();
				init.(keyword) = factory.select('type', options.type,...
															'ignored_parameters', options.ignored_parameters );
			elseif strcmp(type, 'full_problem')
				factory = SSP_Tools.Factories.ProblemFactory();
				init.(keyword) = factory.select('type', options.type );
			end
		end
		
	end


end