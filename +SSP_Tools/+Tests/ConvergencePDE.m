classdef ConvergencePDE < SSP_Tools.Tests.Convergence

	properties
		refinement_type = [];
		cfl = [];
	end

	methods
	
		function obj = ConvergencePDE(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('refinement_type', []);
			p.addParamValue('cfl', []);
			p.parse(varargin{:});
			
			obj = obj@SSP_Tools.Tests.Convergence(p.Unmatched)
			obj.name = 'Convergence Test - PDE';
			
			obj.refinement_type = p.Results.refinement_type;
			
			if ~isempty(p.Results.cfl)
				obj.cfl = p.Results.cfl;
			else
				obj.cfl = 0.2;
			end
			
		end

		function run_test(obj, varargin)
			% If there's only one grid refinement in obj.refinements,
			% only refine in time.
			if strcmp(obj.refinement_type, 'time')
				obj.refine_time_only(varargin{:});
			elseif strcmp(obj.refinement_type, 'time_space')
				obj.refine_time_and_space(varargin{:});
			end
			
			cellfun(@(line) obj.print('%s\n', line), obj.format_results());
			
		end
		
		
		function refine_time_and_space(obj, varargin)
			% Run the test.
			
			results = {};
			completed_problems = {};
			
			obj.log('PDE Convergence Test\n');
			obj.log('Problem: %s\n', obj.problem_template.repr());
			obj.log('Time Stepping Method: %s\n', obj.problem_template.integrator.repr());
			obj.log('Spatial Discretization: %s\n', obj.problem_template.discretizer.repr());
			obj.log('\n');
			
			for i=1:numel(obj.refinements)
				
				obj.log('Testing %i\n', obj.refinements(i));
				
				n = obj.refinements(i);
				problem = obj.problem_template.copy();
				problem.setup_problem(n);
			
				dx = min(diff(problem.x));
				dt = obj.cfl*min(diff(problem.x));
				problem.approximate(obj.t, 'dt', dt, 'tolT', 1e-12);
				l1error = problem.error_norm(1);
				l2error = problem.error_norm(2);
				linferror = problem.error_norm(inf);
				
				results{end+1} = struct('N', n,...
				                        'dt', dt,...
				                        'dx', dx,...
				                        'u', problem.u,...
				                        'x', problem.x,...
				                        't', problem.t,...
				                        'exact', problem.get_exact_solution(), ...
				                        'pointwise', problem.calculate_error(),...
				                        'l1error', l1error,...
				                        'l2error', l2error,...
				                        'linferror', linferror, ...
				                        'problem', problem.repr(), ...
				                        'integrator', problem.integrator.repr(), ...
				                        'discretizer', problem.discretizer.repr() );
				                        
				
				completed_problems{end+1} = problem;
			end
			
			results = [ results{:} ];
			
			for i=2:numel(results)
				refinement = log10(results(i).dt / results(i-1).dt);
				results(i).l2order  = log10( results(i).l2error / results(i-1).l2error) / refinement;
				results(i).l1order  = log10( results(i).l1error / results(i-1).l1error) / refinement;
				results(i).linforder  = log10( results(i).linferror / results(i-1).linferror) / refinement;
			end
			
			obj.results = results;
			obj.completed_problems = [ completed_problems{:} ];
		end
		
		function refine_time_only(obj, varargin)
			% Run the test.
			
			results = {};
			completed_problems = {};
			
			obj.log('ODE Convergence Test\n');
			obj.log('Problem: %s\n', obj.problem_template.repr());
			obj.log('Time Stepping Method: %s\n', obj.problem_template.integrator.repr());
			obj.log('Spatial Discretization: %s\n', obj.problem_template.discretizer.repr());
			obj.log('\n');
			
			for i=1:numel(obj.refinements)
				
				n = 100;
				dt = obj.refinements(i);
				
				problem = obj.problem_template.copy();
				problem.setup_problem(n);
				
				obj.log('Testing %i dt=%g\n', n, dt);
				
				problem.approximate(obj.t, 'dt', dt, 'verbose', false);
				l1error = problem.error_norm(1);
				l2error = problem.error_norm(2);
				linferror = problem.error_norm(inf);
				dx = min(diff(problem.x));
				
				results{end+1} = struct('N', n,...
				                        'dt', dt,...
				                        'dx', dx,...
				                        'u', problem.u,...
				                        'x', problem.x,...
				                        't', problem.t,...
				                        'exact', problem.get_exact_solution(), ...
				                        'pointwise', problem.calculate_error(),...
				                        'l1error', l1error,...
				                        'l2error', l2error,...
				                        'linferror', linferror);
				
				completed_problems{end+1} = problem;
			end
			
			results = [ results{:} ];
			
			for i=2:numel(results)
				refinement = log10(results(i).dt / results(i-1).dt);
				results(i).l2order  = log10( results(i).l2error / results(i-1).l2error) / refinement;
				results(i).l1order  = log10( results(i).l1error / results(i-1).l1error) / refinement;
				results(i).linforder  = log10( results(i).linferror / results(i-1).linferror) / refinement;
			end
			
			obj.results = results;
			obj.completed_problems = [ completed_problems{:} ];
		end

		
		function output = format_results(obj)
			% Print the results
			
			if isempty(obj.results)
				obj.run_test();
			end
			
			output = {};
			
			output{end+1} = sprintf('Convergence Test Results');
			output{end+1} = sprintf('Problem: %s u(x,0)=%s [%d, %d] T=%f', obj.problem_template.name, func2str(obj.problem_template.uinit), obj.problem_template.domain(1), obj.problem_template.domain(2), obj.t);
			output{end+1} = sprintf('Spatial Discretization: %s', obj.problem_template.discretizer.name);
			output{end+1} = sprintf('Time-Stepping Method: %s', obj.problem_template.integrator.name );
			output{end+1} = sprintf('----------------------------------------------------');
			
			error_names = { 'L1', 'L2', 'Linf' };
			error_headings = cellfun( @(err_name) sprintf(' %4sError | %4sOrder |', err_name, err_name), error_names, 'UniformOutput', false);
			
			output{end+1} = sprintf('%4s | %6s | %s', 'N', 'dt', [error_headings{:}]);

			
			for i=1:numel(obj.results)
			
				l1error = obj.results(i).l1error;
				l1order = obj.results(i).l1order;
				
				l2error = obj.results(i).l2error;
				l2order = obj.results(i).l2order;
				
				linferror = obj.results(i).linferror;
				linforder = obj.results(i).linforder;
				
				error_strings = arrayfun(@(err) sprintf('%3.2e', err), [l1error, l2error, linferror], 'UniformOutput', false);
				
				if i==1
					order_strings = arrayfun( @(err) sprintf('-'), [l1error, l2error, linferror], 'UniformOutput', false);
				else
					order_strings = arrayfun( @(err) sprintf('%4.2f', err), [l1order, l2order, linforder], 'UniformOutput', false);
				end
				
				table_data = cellfun( @(err, ord) sprintf(' %9s | %9s |', err, ord), error_strings, order_strings, 'UniformOutput', false);
				output{end+1} = sprintf('%4d | %6.4f | %s ', obj.results(i).N, obj.results(i).dt, [ table_data{:} ]);
				
			end
		end
		
		function fig = plot(obj, varargin)
			
			p = inputParser;
			p.addParamValue('filename', []);
			p.parse(varargin{:});
		
			fig = figure();
			legend_text = {};
			
			
			for i=1:numel(obj.completed_problems)
				problem = obj.completed_problems(i);
				plot(problem.x, problem.u, 'LineWidth', 2);
				legend_text{end+1} = sprintf('N=%i', numel(problem.x));
				hold all;
			end
			
			legend(legend_text);
			title( sprintf('%s', obj.problem_template.name ));
			                                      
			
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
		
		function plot_pointwise_error(obj, varargin)
		
			p = inputParser;
			p.addParamValue('filename', []);
			p.parse(varargin{:});
			
			if ~isempty(obj.results)
				figure()
				
				legend_titles = {};
				for i=1:numel(obj.results)
					x = obj.results(i).x;
					pointwise_error = obj.results(i).pointwise;
					semilogy(x, pointwise_error, 'LineWidth', 2)
					legend_titles{end+1} = sprintf('N=%i', obj.results(i).N);
					hold all
				end
			end
			
			title('Pointwise Error');
			legend(legend_titles);
			
			if ~isempty(p.Results.filename)
				print('foo.eps', '-depsc2');
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
			
			refinement_opts = {};
			refinement_opts{end+1} = struct('name', 'Refine in time and Space', ...
			                                'value', 'time_space');
			refinement_opts{end+1} = struct('name', 'Refine in time only', ...
			                                'value', 'time');
			refinement_opts{end+1} = struct('name', 'Refine in space only', ...
			                                'value', 'space');
			
			refinement_opts = [ refinement_opts{:} ];
			
			parameters{end+1} = struct('keyword', 'refinement_type', ...
			                           'name', 'refinement_type', ...
			                           'longname', 'Type of refinement',...
			                           'type', 'option_list', ...
			                           'options', refinement_opts,...
			                           'default', 'time_space');
			
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
			                           'options', struct('type', 'SSP_Tools.TestProblems.PDE', ...
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