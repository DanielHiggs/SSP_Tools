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
			p.addParamValue('ignored_parameters', {});
			p.parse(varargin{:});
			
			ignored_parameters = p.Results.ignored_parameters;
			
			% Print a list of available methods
			obj.list();
			n = input('Select a Test: ');
			method = obj.available_tests(n);
			
			fprintf('Configuration options\n\n');
			
			init = struct();
			for i=1:numel(method.parameters)
				
				keyword = method.parameters(i).keyword;
				parameter_name = method.parameters(i).longname;
				default_value = method.parameters(i).default;
				options = method.parameters(i).options;
				type_value = method.parameters(i).type;
				
				if strcmp(keyword, ignored_parameters)
					% If we've been asked to ignore a parameter
					% (as is sometimes convenient when creating a
					% prototype) skip it.
					continue
				end
				

				if strcmp(type_value, 'double')
					query_string = sprintf('%s %s [%g]:', parameter_name, ...
																		keyword, ...
																		default_value );
					init.(keyword) = input(query_string); 
					if isempty(init.(keyword))
						init.(keyword) = method.parameters(i).default;
					end
				elseif strcmp(type_value, 'string')
					query_string = sprintf('%s %s [%s]:', parameter_name, ...
																     keyword, ...
																     default_value );
					init.(keyword) = input(query_string); 
					if isempty(init.(keyword))
						init.(keyword) = method.parameters(i).default;
					end
				elseif strcmp(type_value, 'integer')
					query_string = sprintf('%s %s [%d]:', parameter_name, ...
																     keyword, ...
																     default_value );
					init.(keyword) = input(query_string); 
					if isempty(init.(keyword))
						init.(keyword) = method.parameters(i).default;
					end
				elseif strcmp(type_value, 'vector')
					query_string = sprintf('%s %s:', parameter_name, ...
																keyword );
					init.(keyword) = input(query_string); 
					if isempty(init.(keyword))
						init.(keyword) = method.parameters(i).default;
					end
				elseif strcmp(type_value, 'option_list')
					fprintf('\n\nSelect %s:\n', parameter_name);
					for idx=1:numel(options)
						fprintf('[%i] %s\n', idx, options(idx).name);
					end
					idx = input('Selection: ');
					init.(keyword) = options(idx).value;
					if isempty(init.(keyword))
						init.(keyword) = default_value;
					end
				elseif strcmp(type_value, 'problem')
					factory = SSP_Tools.Factories.ProblemFactory();
					init.(keyword) = factory.select('type', options.type,...
					                                'ignored_parameters', options.ignored_parameters );
				elseif strcmp(type_value, 'full_problem')
					factory = SSP_Tools.Factories.ProblemFactory();
					init.(keyword) = factory.select('type', options.type );
				end
			end
			
			method = feval(method.class, init);
		end 
		
		
	end


end