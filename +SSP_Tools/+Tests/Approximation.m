classdef Approximation < SSP_Tools.Tests.Test

	properties
	
		% The time to approximate
		t;
		
		dt;
		%
	
		% The problem object
		problem = [];

		% File (or directory) where our plots will go

		
	end
  
	methods
		
		function obj = Approximation(varargin)
			obj = obj@SSP_Tools.Tests.Test(varargin{:});
			p = inputParser;
			p.addParamValue('problem', []);
			p.addParamValue('t', []);
			p.addParamValue('dt', []);
			p.parse(varargin{:});
			
			obj.t = p.Results.t;
			obj.dt = p.Results.dt;
			obj.problem = p.Results.problem;
			
			obj.name = 'Simple Approximation';

			
		end

		function run(obj)
			% Run the test and print out the results.
			obj.verbose = true;
			obj.run_test();
		end 
		
		function run_test(obj)
		
			% We can't go backwards with our approximation,
			% so raise an error if we're asked to approximate
			% a value of t that's less than where we're currently
			% at.
			
			obj.problem.setup_problem();			
			obj.problem.approximate(obj.t, 'dt', obj.dt, 'verbose', @obj.log);
			
			t = obj.problem.t(end);
			y_comp = obj.problem.y(end);
			y_exact = obj.problem.get_exact_solution();
			y_exact = y_exact(end);
			y_error = abs(y_comp - y_exact);

			obj.print('Problem: %s\n', obj.problem.name);
			obj.print('Time Stepping Method: %s, dt=%g\n', obj.problem.integrator.name, obj.problem.dt);
			obj.print('y(%g)=%g, exact=%g (%6.5g)', t, y_comp, y_exact(end), y_error);
			
		end
		
		function [status, files] = save(obj, prefix)
		% Save all of our data 
			
			files = {};
			
			if exist(prefix, 'dir')
				% the directory already exists
				status = 1;
				return
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
			
			% Save a plot
			plotfile = [prefix, '/', sprintf('%s_solution.eps', prefix) ];
			fig = obj.problem.plot();
			figure(fig);
			print(plotfile, '-depsc2'),
			close(fig);
			files{end+1} = resultsfile;
			
			status = 0;
		end
		
		
		function parameters = get_parameters(obj)
			
			parameters = {};
			                           			
			parameters{end+1} = struct('keyword', 'problem',...
			                           'name', 'Example Problem',...
			                           'longname', 'Fully-formed Example Problem',...
			                           'type', 'full_problem',...
			                           'options', struct('type', 'SSP_Tools.TestProblems.ODE'),...
			                           'default', []);
			                           
			parameters{end+1} = struct('keyword', 't',...
			                           'name', 't',...
			                           'longname', 'Value of t to approximate to',...
			                           'type', 'double',...
			                           'options', [],...
			                           'default', 1.0);
		
			parameters{end+1} = struct('keyword', 'dt',...
			                           'name', 'dt',...
			                           'longname', 'Step Size',...
			                           'type', 'double',...
			                           'options', [],...
			                           'default', 0.1);
		
			parameters = [ parameters{:}];
		end
	
	end

end