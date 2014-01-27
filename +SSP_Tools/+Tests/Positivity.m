classdef Positivity < SSP_Tools.Tests.Test
% This class describes a test of the SSP property
%
	properties
	
		problem_template = [];
		% An SSP_Tools.TestProblems.TestProblem object to serve as a template
		
		tolerance = [];
		% The allowable increase in TV without violating TVD
		
		completed_problems = [];
		% Where we put SSP_Tools.TestProblems.TestProblem objects after we've run them.
		
		n = [];
		% Number of grid points.
		
	end
	
	methods
		function obj = Positivity(varargin)
			obj = obj@SSP_Tools.Tests.Test(varargin{:});
			
			p = inputParser;
			p.addParamValue('problem', []);
			p.addParamValue('N', []);
			p.parse(varargin{:});
			
			verbose = false;
			
			obj.name = 'Positivity Test';
			obj.problem_template = p.Results.problem;
			obj.n = p.Results.N;
		end
		
		function results = run(obj, varargin)
			obj.verbose = true;
			results = obj.run_test(varargin{:});
			cellfun( @(line) fprintf('%s'), obj.report_buffer);
		end
		
		function results = run_test(obj, varargin)
			% Run the test.

			results = {};
			completed_problems = {};

			dt_test_value = 1e-3;
			dt_test_increment = 1e-3;
			initial_t_end = 1/8;
			
			obj.log('Positivity Test\n');
			obj.log('Problem: %s\n', obj.problem_template.repr());
			obj.log('Time Stepping Method: %s\n', obj.problem_template.integrator.repr());
			obj.log('Spatial Discretization: %s\n', obj.problem_template.discretizer.repr());
			obj.log('\n');
			
			
			while dt_test_increment > 1e-6

				n_steps = 0;

				problem = obj.problem_template.copy();
				problem.setup_problem(obj.n);

				dt = dt_test_value + dt_test_increment;	
				obj.log('--Testing dt=%g\n', dt);
				
				% For multistep methods, we don't want to start testing
				% the total variation of whatever method is doing the
				% priming. Get the number of steps from the method and
				% set the skip value
				if any(strcmp(properties(problem.integrator), 'steps'))
					skip = problem.integrator.steps-1;
				else
					skip = 0;
				end
				
				% The value of dt we're testing, multiplied by the number of 
				% steps used by the method may exceed t_end. If so,
				% extend t_end so that we can get a few good steps before we hit
				% it, but no so much that we're calling it good prematurely.
				if initial_t_end / dt_test_value < skip
					t_end = dt_test_value * (4 + skip);
					obj.log('Skip value (%d*dt) greater than t_end=%f\n', skip, initial_t_end)
					obj.log('Extending t_end %f->%f\n', initial_t_end, t_end)
					runaway_error = true;
				else
					t_end = initial_t_end;
				end
				
				t_rem = t_end;
				
				while t_rem > 1e-16
					if t_rem < dt
						dt_step = t_rem;
					else
						dt_step = dt;
					end
					
					problem.step(dt_step);
					n_steps = n_steps + 1;
					t_rem = t_end - problem.t;		
					
					min_value = min(problem.u);
					if min_value < -1e-13 & n_steps > skip
						break
					else
						true;
					end
					
				end

				if t_rem > 1e-16
					% POS was violated
					
					obj.log('---POS Violated after %d steps t=%f (%e)\n', n_steps, problem.t, min_value)
					obj.log('   L2 error at time of violation: %g\n', problem.error_norm(2));
					obj.log('   Refining dt search increment %g', dt_test_increment);
					dt_test_increment = dt_test_increment / 10;
					obj.log('->%g\n', dt_test_increment);
					
			%  						 
				else
					% POS was preserved
					obj.log('---POS Preserved\n')
					dt_test_value = dt;
				end
			end

			results = struct('max_dt', dt_test_value, ...,
			                 's', problem.integrator.stages, ...
			                 'k', problem.integrator.steps, ...
			                 'p', problem.integrator.order, ...
			                 'dx', min(diff(problem.x)), ...
			                 'r', problem.integrator.r );
			obj.results = results;
			obj.print('Largest Max dt=%f\n', dt_test_value);
			obj.print('Theoretial Max dt=%f\n\n', obj.problem_template.integrator.r/100);
			
		end
		
		function parameters = get_parameters(obj)
			
			parameters = {};
			
			parameters{end+1} = struct('keyword', 'N', ...
			                           'name', 'Number of Gridpoints', ...
			                           'longname', 'Number of gridpoints', ...
			                           'type', 'double',...
			                           'options', [], ...
			                           'default', 100 );
			                       
			parameters{end+1} = struct('keyword', 'problem',...
			                           'name', 'PDE Problem',...
			                           'longname', 'Fully-formed Example Problem',...
			                           'type', 'problem',...
			                           'options', struct('type', 'SSP_Tools.TestProblems.PDE', ...
			                                             'ignored_parameters', 'N' ) ,...
			                           'default', []);
		
			parameters = [ parameters{:}];
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
		
		function commands = get_commands(obj)
		% Return a structure containing information about the
		% commands supported by this class.
			commands = struct('name', {'import'});
		end
		
	end
	
	methods(Static)
	
function obj = for_problem(varargin)
			% Because we might have problem-specific code, this
			% half-witted constructor will return the appropriate
			% subclass when passed an SSP_Tools.TestProblem.* object
			
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('problem', []);
			p.parse(varargin{:});
			
			problem = p.Results.problem;
			
			if isa(problem, 'SSP_Tools.TestProblems.PDE')
				obj = SSP_Tools.Tests.Positivity(varargin{:});
			else
				error('Test not valid for selected problem');
			end
		end
	
	end

	
	

end