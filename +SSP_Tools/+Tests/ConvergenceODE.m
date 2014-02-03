classdef ConvergenceODE < SSP_Tools.Tests.Convergence

	methods
		
		function obj = ConvergenceODE(varargin)
			obj = obj@SSP_Tools.Tests.Convergence(varargin{:});
			obj.name = 'Convergence Test - ODE';
		end
	
		function results = run_test(obj, varargin)
			% Run the test.			
			results = {};
			completed_problems = {};
		
			obj.log('\n\nODE Convergence Test\n');
			obj.log('Test: %s\n', obj.repr());
			obj.log('Problem: %s\n', obj.problem_template.repr());
			obj.log('Time Stepping Method: %s\n', obj.problem_template.integrator.repr());
			obj.log('\n');
		
			% Loop through each refinement
			for i=1:numel(obj.refinements)
				obj.log('Testing %i\n', obj.refinements(i));
			
				% Initialize a new TestProblem object from our template
				n = obj.refinements(i);
				problem = obj.problem_template.copy();
				problem.setup_problem();
				
				% Figure out our stepsize
				dt = (obj.t - problem.domain(1)) / n;
				
				% Get an approximation for the problem at the desired value of t
				problem.approximate(obj.t, 'dt', dt, 'tolT', 1e-13);
				
				% Get the error
				pointwise_error = problem.calculate_error();
				
				% Record the results
				results{end+1} = struct('N', n,...
				                        't', problem.t(end), ...
				                        'dt', dt,...
				                        'error', pointwise_error, ...
				                        'problem', problem.repr(), ...
				                        'integrator', problem.integrator.repr() );
				
				% Save the TestProblem object
				completed_problems{end+1} = problem;
			end
			
			results = [ results{:} ];
			
			for i=2:numel(results)			
				refinement = log10(results(i).dt ./ results(i-1).dt);
				results(i).order  = log10( results(i).error(:,end)./ results(i-1).error(:,end)) / refinement;
			end
			
			obj.results = results;
			obj.completed_problems = [ completed_problems{:} ];
			
			cellfun(@(line) obj.log('%s\n', line), obj.format_results());
			
		end
	
		function fig = plot(obj, varargin)
			
			p = inputParser;
			p.addParamValue('filename', []);
			p.parse(varargin{:});
		
			fig = figure();
			legend_text = {};
			
			
			for i=1:numel(obj.completed_problems)
				problem = obj.completed_problems(i);
				plot(problem.t, problem.y, 'LineWidth', 2);
				legend_text{end+1} = sprintf('N=%i', numel(problem.t));
				hold all
			end
			
			if ~isempty(p.Results.filename)
				[pathstr,name,ext] = fileparts(p.Results.filename);
				if strcmp(ext, '.eps')
					fileformat = '-depsc2';
				else
					fileformat = ['-d', ext(2:end)];
				end
				print(p.Results.filename, fileformat);
			end
		end
	
		function fig = plot_pointwise_error(obj, varargin)
			
			disp('foooooooo')
			
			p = inputParser;
			p.addParamValue('filename', []);
			p.parse(varargin{:});
		
			fig = figure();
			legend_text = {};
			
			for i=1:numel(obj.completed_problems)
				problem = obj.completed_problems(i);
				semilogy(problem.t, problem.calculate_error(), 'LineWidth', 2);
				legend_text{end+1} = sprintf('N=%i', numel(problem.t));
				hold all
			end
			
			title('Error')
			legend(legend_text)
			
			if ~isempty(p.Results.filename)
				[pathstr,name,ext] = fileparts(p.Results.filename);
				if strcmp(ext, '.eps')
					fileformat = '-depsc2';
				else
					fileformat = ['-d', ext(2:end)];
				end
				print(p.Results.filename, fileformat);
			end
		end
	
		function output = format_results(obj)
			% Print the results
			
			if isempty(obj.results)
				obj.run_test();
			end
			
			output = {};
			
			ic_string = sprintf('[ %s]', sprintf('%3.2f ', obj.problem_template.y));
			output{end+1} = sprintf('\nConvergence Test Results');
			output{end+1} = sprintf('Problem: %s y(0)=%s T=%f', obj.problem_template.name, ic_string, obj.t);
			output{end+1} = sprintf('Method: %s', obj.problem_template.integrator.name );
			output{end+1} = sprintf('----------------------------------------------------');
			
			error_format = '%8g';
			order_format = '%4.2f';
			
			table_headings = {}; 
			
			for i=1:numel(obj.results(1).error(:,end))
				table_headings{end+1} = sprintf(' %8s | %6s |', sprintf('y%d Error', i), 'order');
			end
			
			output{end+1} = sprintf('%4s | %6s | %6s | %s', 'N', 'T', 'dt', [table_headings{:}]);
			
			for i=1:numel(obj.results)
				
				error_data = obj.results(i).error(:,end);
				error_strings = arrayfun( @(err) sprintf('%3.2e', err), error_data, 'UniformOutput', false);

				if i==1
					order_strings = arrayfun(@(ord) sprintf('-'), error_data, 'UniformOutput', false);
				else
					order_strings = arrayfun(@(ord) sprintf('%4.2f', ord), obj.results(i).order, 'UniformOutput', false);
				end
				
				table_data = cellfun( @(err, ord) sprintf(' %8s | %6s |', err, ord), error_strings, order_strings, 'UniformOutput', false);
				
				output{end+1} = sprintf('%4d | %6.4f | %6.4f | %s', obj.results(i).N, obj.results(i).t, obj.results(i).dt, [table_data{:}]);
				
			end
			
		end		
		
		function [status, variables] = import(obj)
		% Import test results into current workspace
			assignin('base', 'results', obj.results);
			assignin('base', 'problems', obj.completed_problems);

			variables = struct('name', {'results', 'problems'},... 
			                   'description', {'Test results', 'Problem Objects'} );
			status = 0;
		end
		
		function [status, files] = save(obj, prefix)
		% Save all of our data 
			
			files = {};
			
			if ~exist(prefix, 'dir')
				% the directory doesn't exist
				mkdir(prefix);
			end
				
			mkdir('./', prefix);
			
			% Save the log
			logfile = [prefix, '/', sprintf('%s_log.txt', prefix) ]
			fid = fopen(logfile, 'w');
			cellfun(@(line) fprintf(fid, line), obj.output_buffer);
			fclose(fid);
			files{end+1} = logfile;
			
			% Save the results
			resultsfile = [prefix, '/', sprintf('%s_results.txt', prefix) ];
			fid = fopen(resultsfile, 'w');
			cellfun(@(line) fprintf(fid, line), obj.report_buffer);
			fclose(fid);
			files{end+1} = resultsfile;
			
			status = 0;
		end
		
		
		
		function parameters = get_parameters(obj)
			
			parameters = {};
			
			parameters{end+1} = struct('keyword', 'refinements',...
			                           'name', 'refinements',...
			                           'longname', 'Vector of refinements, e.g. [10,30,80]',...
			                           'type', 'vector',...
			                           'options', [],...
			                           'default', [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]);
			                           
			parameters{end+1} = struct('keyword', 't',...
			                           'name', 't',...
			                           'longname', 'Value of t to approximate to',...
			                           'type', 'double',...
			                           'options', [],...
			                           'default', 1.0);
			
			parameters{end+1} = struct('keyword', 'problem',...
			                           'name', 'Example Problem',...
			                           'longname', 'Fully-formed Example Problem',...
			                           'type', 'problem',...
			                           'options', struct('type', 'SSP_Tools.TestProblems.ODE', ...
			                                             'ignored_parameters', 'N' ),...
			                           'default', []);
		
			parameters = [ parameters{:}];
		end
	
		function commands = get_commands(obj)
		% Return a structure containing information about the
		% commands supported by this class.
			commands = struct('name', {'import', 'save'});
		end
	
	end

end