classdef PointwiseConvergencePDE < SSP_Tools.Tests.PointwiseConvergence

	methods
	
		function obj = ConvergencePDE(varargin)
			obj = obj@SSP_Tools.Tests.Convergence(varargin{:})
		end

		function run_test(obj, varargin)
			% If there's only one grid refinement in obj.refinements,
			% only refine in time.
			if numel(obj.refinements) == 1
				obj.refine_time_only(varargin{:});
			else
				obj.refine_time_and_space(varargin{:});
			end
			
			
			
			
		end
		
		
		function refine_time_and_space(obj, varargin)
			% Run the test.
			
			p = inputParser;
			p.addParamValue('verbose', []);
			p.parse(varargin{:});
			
			results = {};
			completed_problems = {};
			
			for i=1:numel(obj.refinements)
				
				if p.Results.verbose
					fprintf('Testing %i\n', obj.refinements(i));
				end
				
				n = obj.refinements(i);
				problem = obj.problem_template.copy();
				problem.setup_problem(n);
			
				dx = min(diff(problem.x));
				dt = 0.2*min(diff(problem.x));
				problem.approximate(obj.t, 'dt', dt, 'verbose', p.Results.verbose);
				l2error = problem.error_norm(2);
				
				results{end+1} = struct('N', n,...
				                        'dt', dt,...
				                        'dx', dx,...
				                        'u', problem.u,...
				                        'x', problem.x,...
				                        'pointwise', problem.calculate_error(),...
				                        'l2error', l2error);
				
				completed_problems{end+1} = problem;
			end
			
			results = [ results{:} ];
			
			for i=2:numel(results)
				refinement = log10(results(i).dt / results(i-1).dt);
				results(i).l2order  = log10( results(i).l2error / results(i-1).l2error) / refinement;
			end
			
			obj.results = results;
			obj.completed_problems = [ completed_problems{:} ];
		end
		
		function refine_time_only(obj, varargin)
			% Run the test.
			
			p = inputParser;
			p.addParamValue('verbose', []);
			p.parse(varargin{:});
			
			results = {};
			completed_problems = {};
			
			% To refine in time, we're going to assume a default minimum number of timesteps
			% dictated by dt = 0.2*dx and refine by adding 30% more time steps at each stage.
			x = linspace(obj.problem_template.domain(1), obj.problem_template.domain(2), obj.refinements+1);
			dx = min(diff(x));
			dt = 0.2*dx;
			n_steps = obj.t / dt;
			refinements = n_steps + ( n_steps*0.3*(0:10) );
			
			for i=1:numel(refinements)
				
				n = obj.refinements(1);
				problem = obj.problem_template.copy();
				problem.setup_problem(n);
			
				dx = min(diff(problem.x));
				dt = obj.t/refinements(i);
				
				if p.Results.verbose
					fprintf('Testing %i dt=%g\n', n, dt);
				end
				
				problem.approximate(obj.t, 'dt', dt, 'verbose', p.Results.verbose);
				l2error = problem.error_norm(2);
				
				results{end+1} = struct('N', n,...
				                        'dt', dt,...
				                        'dx', dx,...
				                        'u', problem.u,...
				                        'x', problem.x,...
				                        'pointwise', problem.calculate_error(),...
				                        'l2error', l2error);
				
				completed_problems{end+1} = problem;
			end
			
			results = [ results{:} ];
			
			for i=2:numel(results)
				refinement = log10(results(i).dt / results(i-1).dt);
				results(i).l2order  = log10( results(i).l2error / results(i-1).l2error) / refinement;
			end
			
			obj.results = results;
			obj.completed_problems = [ completed_problems{:} ];
		end

		
		function output = print_results(obj)
			% Print the results
			
			if isempty(obj.results)
				obj.run_test();
			end
			
			output = {};
			
			for i=1:numel(obj.results)
				if i==1
					output{end+1} = sprintf('%3i | %8g | %8g | -', obj.results(i).N, obj.results(i).dt, obj.results(i).l2error);
				else
					output{end+1} = sprintf('%3i | %8g | %8g | %2g', obj.results(i).N, obj.results(i).dt, obj.results(i).l2error, obj.results(i).l2order);
				end
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
		
		
	
	end



end