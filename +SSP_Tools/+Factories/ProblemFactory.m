classdef ProblemFactory < handle

	properties
		available_problems = [];
	end
	
	methods
	
		function obj = ProblemFactory(varargin)
			ignored_classes = { 'SSP_Tools.TestProblems.TestProblem',...
			                    'SSP_Tools.TestProblems.PDE',...
			                    'SSP_Tools.TestProblems.ConvectionReactionPDE',...
			                    'SSP_Tools.TestProblems.ODE' };
			                    
			package_info = meta.package.fromName('SSP_Tools.TestProblems');
			problem_info = struct();
			
			% Query each package by instantiating it and examining some properties
			for i=1:numel(package_info.Classes)
				class_name = package_info.Classes{i}.Name;
				if ~strcmp(ignored_classes, class_name)
					method_obj = eval([class_name, '()']);

					% Build a record of some useful properties that any
					% GUI or user interface might like to know...
					dot_idx = strfind(class_name, '.');
					problem_info.name = class_name(dot_idx(end)+1:end);
					problem_info.longname = method_obj.name;
					problem_info.class = class_name;
					problem_info.parameters = method_obj.get_parameters();
					problem_info.ancestors = SSP_Tools.Factories.ProblemFactory.ancestors(class_name);
					
					obj.available_problems{end+1} = problem_info;
				end
			end
			
			% Alphabatize the list
			first_letters = [];
			for i=1:numel(obj.available_problems)
				first_letters(end+1) = obj.available_problems{i}.name(1);
			end
			[~, sorted_indices] = sort(first_letters);
			obj.available_problems = [obj.available_problems{sorted_indices}];
		end

		function mapping = list(obj, varargin)
			% Return an indexed list of available methods suitable
			% for a text-based UI
			
			p = inputParser;
			p.addParamValue('category', []);
			p.parse(varargin{:});
			
			mapping = [];
			l_id = 1;
			for i=1:numel(obj.available_problems)
				fmt = '[%i] %s\n';
				if cell2mat(strfind(obj.available_problems(i).ancestors, p.Results.category))
					fprintf(fmt, l_id, obj.available_problems(i).longname);
					mapping(end+1) = i;
					l_id = l_id + 1;
				end
			end
		end
		
		function query(obj, class)
			
			idx = find(strcmp({obj.available_problems.class}, class));
			
			if ~isempty(idx)
			
				problem = obj.available_problems(idx);
				fprintf('\nListing parameters for: %s()\n\n', problem.class);
				for i=1:numel(problem.parameters)
					fprintf('%s (%s) - %s\n', problem.parameters(i).keyword,...
					                          problem.parameters(i).type,...
					                          problem.parameters(i).name );
				end
				fprintf('\n\n');
			end
			
		
		end
		
		
		function method = select(obj, varargin)
			% Select and configure a method
			
			p = inputParser;
			p.addParamValue('type', []);
			p.addParamValue('ignored_parameters', {});
			p.parse(varargin{:});
			
			ignored_parameters = p.Results.ignored_parameters;
			
			% Print a list of available problem families
			problem_categories = struct('name', {'ODE', 'PDE'},...
			                            'class', {'SSP_Tools.TestProblems.ODE', 'SSP_Tools.TestProblems.PDE'});
			if ~isempty(p.Results.type)
				category = p.Results.type;
			else
				for i=1:numel(problem_categories)
					fmt = '[%i] %s\n';
					fprintf(fmt, i, problem_categories(i).name);
				end
				n = input('Select a problem category: ');
				category = problem_categories(n).class;
			end

			
			% Print a list of available methods
			mapping = obj.list('category', category);
			n = input('Select a test problem: ');
			method = obj.available_problems(mapping(n));
			
			fprintf('Configuration options\n\n');
			
			init = struct();
			for i=1:numel(method.parameters)
				
				keyword = method.parameters(i).keyword;
				parameter_name = method.parameters(i).name;
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
				elseif strcmp(type_value, 'SSP_Tools.Discretizers.Discretizer')
					% We need a Discretizer
					factory = SSP_Tools.Factories.DiscretizerFactory();
					fprintf('\n\nConfigure %s:\n', parameter_name);
					init.(keyword) = factory.select();
				elseif strcmp(type_value, 'SSP_Tools.Integrators.Integrator')
					factory = SSP_Tools.Factories.IntegratorFactory();
					fprintf('\n\nConfigure %s\n', parameter_name);
					init.(keyword) = factory.select();
				elseif strcmp(type_value, 'domain')
					for dom_idx=1:numel(options)
						fprintf('[%i] %s\n', dom_idx, options(dom_idx).name);
					end
					dom_idx = input('Selection: ');
					init.(keyword) = options(dom_idx).value;
				elseif strcmp(type_value, 'initial_condition')
					fprintf('\n\nSelect Initial Condition:\n');
					for ic_idx=1:numel(options)
						fprintf('[%i] %s\n', ic_idx, options(ic_idx).longname);
					end
					ic_idx = input('Selection: ');
					init.(keyword) = options(ic_idx).function;
					init.domain = options(ic_idx).domain;
				end
			end
			method = feval(method.class, init);
		end 

		function [class_name, arg_string, dependent_vars] = select_initstring(obj, varargin)
			% This function will print out 
			
			p = inputParser;
			p.addParamValue('type', []);
			p.addParamValue('ignored_parameters', {});
			p.parse(varargin{:});
			
			ignored_parameters = p.Results.ignored_parameters;
			
			% Print a list of available methods
			obj.list();
			n = input('Select a test problem: ');
			method = obj.available_problems(n);
			
			fprintf('Configuration options\n\n');
			
			init = struct();
			
			class_name = method.class;
			dependent_vars = {};
			arg_string = '';
			
			init_string = '';
			for i=1:numel(method.parameters)
				
				keyword = method.parameters(i).keyword;
				parameter_name = method.parameters(i).name;
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
					value = input(query_string); 
					if isempty(value)
						value = method.parameters(i).default;
					end

					arg_string = [arg_string, sprintf('''%s'', %g', keyword, value)];

					
				elseif strcmp(type_value, 'SSP_Tools.Discretizers.Discretizer')
					% We need a Discretizer
					factory = SSP_Tools.Factories.DiscretizerFactory();
					fprintf('\n\nConfigure %s:\n', parameter_name);
					dependent_vars{end+1} = sprintf('%s = %s', keyword, factory.select_initstring());
					arg_string = [arg_string, sprintf('''%s'', %s', keyword, keyword)];
				elseif strcmp(type_value, 'SSP_Tools.Integrators.Integrator')
					factory = SSP_Tools.Factories.IntegratorFactory();
					fprintf('\n\nConfigure %s\n', parameter_name);
					dependent_vars{end+1} = sprintf('%s = %s', keyword, factory.select_initstring());
					arg_string = [arg_string, sprintf('''%s'', %s', keyword, keyword)];
				elseif strcmp(type_value, 'initial_condition')
					fprintf('\n\nSelect Initial Condition:\n');
					for ic_idx=1:numel(options)
						fprintf('[%i] %s\n', ic_idx, options(ic_idx).longname);
					end
					ic_idx = input('Selection: ');
					arg_string = [arg_string, sprintf('''%s'', %s', keyword, func2str(options(ic_idx).function))]
				end
				
				if i < numel(method.parameters)
					arg_string = [arg_string, ', '];
				end
				
			end
		end 
		
		function print_initstring(obj)
			
			[class_name, arg_string, dependent_vars] = obj.select_initstring;
			
			fprintf(['\n\n\nThe following MATLAB code will initialize\n', ...
			         'the selected solvers and problem. Copy and\n', ...
			         'paste it into your script but BE SURE TO\n', ...
			         'CHECK THAT ALL THE NUMERIC VALUES ARE CORRECT\n\n\n'] )
			for i=1:numel(dependent_vars)
				fprintf('%s;\n', dependent_vars{i});
			end
			fprintf('\n\nproblem = %s(%s);\n', class_name, arg_string);
		
		end
		
	end
	
	methods(Static)
	
	   function list = ancestors(class)
			% Get a list of ancestors for a class.
			list = {};
			meta = meta.class.fromName(class);
			parents = meta.SuperClasses;
			for p=1:numel(parents)
				list = [parents{p}.Name, SSP_Tools.Factories.ProblemFactory.ancestors(parents{p}.Name)];
			end
		end
	end
	

end