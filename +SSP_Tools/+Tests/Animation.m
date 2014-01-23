classdef Animation < handle

	properties
	
		% A vector of the refinements we're testing
		t = [];
		dt = [];
		directory = [];
		problem = [];
		verbose = [];
		
		name = 'Animation';
	
	end
	
	methods

		function obj = Animation(varargin)
			p = inputParser;
			p.addParamValue('directory', []);
			p.addParamValue('t', []);
			p.addParamValue('dt', []);
			p.addParamValue('cfl', []);
			p.addParamValue('problem', []);
			p.parse(varargin{:});
			
			verbose = false;

			obj.problem = p.Results.problem;
			obj.t = p.Results.t;
			obj.directory = p.Results.directory;
			
			if ~isempty(p.Results.cfl)
				obj.dt = p.Results.cfl*min(diff(obj.problem.x));
			else
				obj.dt = p.Results.dt;
			end
			
		end
		
		function run(obj)
			% Run the test and print out the results.
			
			obj.verbose = true;
			
			if isempty(obj.dt)
				dt = 0.2*min(diff(obj.problem.x));
			else
				dt = obj.dt;
			end
			
			step_count = 0;
			
			plot_path = [pwd, '/', obj.directory];
			
			
			while obj.t - obj.problem.t > 1e-16
				if obj.t - obj.problem.t > dt
					dt_step = dt;
				else
					dt_step = obj.t - obj.problem.t;
				end
				
				if obj.verbose
					fprintf('Approximating T=%g\r', obj.problem.t);
				end
				obj.problem.step(dt_step);
				
				plot(obj.problem.x, obj.problem.u, 'LineWidth', 2);
				hold all
				plot(obj.problem.x, obj.problem.get_exact_solution(), 'r', 'LineWidth', 2);
				hold off
				title( sprintf('%s %s T=%f', obj.problem.discretizer.name, obj.problem.integrator.name, obj.problem.t));
				
				legend({ 'Approximation', 'Exact'});
				
				file_name = sprintf('/plot-%04d.png', step_count);
				print([plot_path, file_name], '-dpng');
				
				step_count = step_count + 1;
				
			end
		end 
		
		function parameters = get_parameters(obj)
			
			parameters = {};
			
			parameters{end+1} = struct('keyword', 'directory',...
			                           'name', 'directory',...
			                           'longname', 'Directory to store images in',...
			                           'type', 'string',...
			                           'options', [],...
			                           'default', 'plots');
			                           
			parameters{end+1} = struct('keyword', 't',...
			                           'name', 't',...
			                           'longname', 'Value of t to approximate to',...
			                           'type', 'double',...
			                           'options', [],...
			                           'default', 1.0);

			parameters{end+1} = struct('keyword', 'problem',...
			                           'name', 'Example Problem',...
			                           'longname', 'Fully-formed Example Problem',...
			                           'type', 'full_problem',...
			                           'options', struct('type', 'SSP_Tools.TestProblems.PDE'),...
			                           'default', []);
			
			parameters{end+1} = struct('keyword', 'dt',...
			                           'name', 'dt',...
			                           'type', 'function_defined', ...
			                           'longname', 'Options for timesteping',...
			                           'options', @obj.get_parameters_dt, ...
			                           'default', []);
		
		
			parameters = [ parameters{:}];
		end
		
		function [parameter_desc, out_parameters] = get_parameters_dt(obj, in_parameters, all_parameters)
		% This function provides dynamic configuration parameters for kinds of timestepping available
		% given the type of problem being used. It's meant to be called iteratively in a parameter
		% definition of the type 'function_defined'. The first time it's called it returns a dummy
		% parameter asking whether the timestepping should be in terms of dt or cfl. Subsequent calls
		% will return valid parameters for dt or cfl.
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('dt', [])
			p.addParamValue('cfl', [])
			p.addParamValue('dt_cfl_selection', []);
			p.parse(in_parameters);
			
			dt = p.Results.dt;
			cfl = p.Results.cfl;
			dt_cfl_selection = p.Results.dt_cfl_selection;
			
			dt_or_cfl_options = [ struct('name', 'dt', 'value', 'dt'), struct('name', 'cfl', 'value', 'cfl') ];
			
			if ~isempty(dt) | ~isempty(cfl)
				parameter_desc = [];
				out_parameters = in_parameters;
				return
			end
			
			if isa(all_parameters.problem, 'SSP_Tools.TestProblems.PDE')
				% We've already selected a PDE
				if isempty(dt_cfl_selection)
					% Ask whether it should be a dt or CFLs by returning a dummy
					% parameter. 
					parameter_desc = struct();
					parameter_desc.keyword = 'dt_cfl_selection';
					parameter_desc.name = 'dt_or_cfl';
					parameter_desc.longname = 'Time Stepping Type';
					parameter_desc.type = 'option_list';
					parameter_desc.options = dt_or_cfl_options;
					parameter_desc.default = [];
					out_parameters = [];
				elseif strcmp(dt_cfl_selection, 'dt')
					parameter_desc = struct();
					parameter_desc.keyword = 'dt';
					parameter_desc.name = 'dt';
					parameter_desc.longname = 'dt';
					parameter_desc.type = 'double';
					parameter_desc.options = [];
					parameter_desc.default = 0.01;
					out_parameters = [];
				elseif strcmp(dt_cfl_selection, 'cfl')
					parameter_desc = struct();
					parameter_desc.keyword = 'cfl';
					parameter_desc.name = 'cfl';
					parameter_desc.longname = 'cfl c*dx';
					parameter_desc.type = 'double';
					parameter_desc.options = [];
					parameter_desc.default = 0.2;
					out_parameters = [];
				end
			elseif isa(all_parameters.problem, 'SSP_Tools.TestProblems.ODE')
				error('ODE Problems Not Supported')
			end
		end
		
		function commands = get_commands(obj)
		% Return a structure containing information about the
		% commands supported by this class.
			commands = struct();
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
				obj = SSP_Tools.Tests.Animation(varargin{:});
			else
				error('Test not valid for selected problem');
			end
		end
	
	end
			
end
		
		
%  
%  		function interactive(obj)
%  		
%  			settings.problemSelection = obj.selectProblem();
%  			settings.N = obj.selectNs();
%  			settings.spaceMethodSelection = obj.selectSpaceMethod('ProblemSelection', settings.problemSelection);
%  			settings.timeMethodSelection = obj.selectTimeMethod();
%  			settings.cfl = obj.selectCFL();
%  			settings.Tend = obj.selectTend();
%  			settings.plot = obj.selectPlot();
%  			settings.verbose = true;
%  
%  
%  			testTime = tic();
%  			[Errors, Approximations] = obj.start_test(settings);
%  			testTime = toc(testTime);
%  			cellfun(@(line) fprintf('%s', line), obj.makeErrorTable(Errors, Approximations));
%  			fprintf('%s Test Completed In %f seconds\n', SSP_Tools.utils.time_stamp(), testTime);
%  
%  			format long;
%  			fprintf('L2 Error');
%  			[Errors.l2]'
%  			
%  			fprintf('L2 Order');
%  			[Errors.l2order]'
%  
%  		end
%  
%  		function ErrorReport = makeErrorTable(obj, Errors, Approximations)
%  		
%  			ErrorReport = {};
%  		
%  			ErrorReport{end+1} = sprintf('Convergence Table For %s\n', Approximations(1).TimeMethod.name);
%  			ErrorReport{end+1} = sprintf('----------------------------------------\n');
%  			ErrorReport{end+1} = sprintf('%3s | %8s | %8s || %-8s | %-8s | %-8s | %-8s | %5s\n', 'N', 'cfl', 't', 'dt', 'L1 Error', 'L2 Error', 'L00Error', 'Order');
%  
%  			for i=1:length(Errors)
%  				ErrorData = Errors(i);
%  				error_columns = sprintf('| %4.2e ', [ErrorData.dt, ErrorData.l1, ErrorData.l2, ErrorData.linf]);
%  				ErrorReport{end+1} = sprintf('%s\n', sprintf('%3i| %3f | %3f |%s| %3.2f | %7s', ErrorData.N, ErrorData.cfl, ErrorData.T, error_columns, ErrorData.l2order, ' '));
%  			end	
%  		end
%  
%  		
%  		function [Errors, Approximations] = run_test(obj, varargin)
%  			% Test the order of convergence for a specified combination of a
%  			% time-stepping method and a spatial discretization scheme on a
%  			% selected test problem. If this function is called without any 
%  			% arguments, it will interactively ask the user for them.
%  			%
%  			% Parameters:
%  			% 
%  			% ProblemSelection
%  			%    A cell array of valid parameter-value pairs for obj.selectProblem()
%  			%    that specify a requested test problem.
%  			% 
%  			% SpaceMethodSelection
%  			%    A cell array of valid parameter-value pairs for obj.selectSpaceMethod()
%  			%    that specify the requested spatial discretization method and its
%  			%    configuration parameters
%  			% 
%  			% TimeMethodSelection
%  			%    A cell array of valid parameter-value pairs for obj.selectTimeMethod()
%  			%    that specify the requested time-stepping method and it's configuration
%  			%    parameters.
%  			% 
%  			% cfl
%  			%    The requested CFL condition. This is the fraction of the spatial
%  			%    grid-spacing to use as the time-stepping increment. If the parameter
%  			%    dt is provided, it takes precedence over cfl.
%  			% 
%  			% N
%  			%    Array of grid resolutions to test. The problem will be approximated
%  			%    over an evenly-spaced grid of points for every value in N. If N is
%  			%    omitted, the default values will be used.
%  			% 
%  			% Tend
%  			%    Value of T to approximate a solution to. 
%  			% 
%  			% verbose
%  			%    If true, information will be outputted to the console during the
%  			%    approximation
%  			% 
%  			% plot
%  			%    If true, a the approximation will be plotted in realtime.
%  			%
%  			
%  			
%  			Ns = [11, 21, 31, 41, 51, 61, 71, 81, 91, 101];
%  			CFLs = [0.4, 0.2, 0.15, 0.1, 0.5];
%  		
%  			% If we're not provided with any arguments, we go interactively
%  			% ask the console for them.
%  			p = inputParser;
%  			addParamValue(p, 'ProblemSelection', []);
%  			addParamValue(p, 'SpaceMethodSelection', []);
%  			addParamValue(p, 'TimeMethodSelection', []);
%  			addParamValue(p, 'cfl', []);
%  			addParamValue(p, 'N', Ns);
%  			addParamValue(p, 'Tend', 1.0);
%  			addParamValue(p, 'verbose', true);
%  			addParamValue(p, 'plot', false);
%  			p.parse(varargin{:});
%  			problemSelection = p.Results.ProblemSelection;
%  			spaceMethodSelection = p.Results.SpaceMethodSelection;
%  			timeMethodSelection = p.Results.TimeMethodSelection;
%  			cfl = p.Results.cfl;
%  			Ns = p.Results.N;
%  			Tend = p.Results.Tend;
%  			plotting = p.Results.plot;
%  			verbose = p.Results.verbose;
%  	
%  			NumRefinements = length(Ns);	
%  			Approximations = cell(NumRefinements, 1);
%  			Errors = cell(NumRefinements, 1);
%  			for i=1:NumRefinements
%  				N = Ns(i);
%  				
%  				Problem = obj.initializeObject(problemSelection);
%  				
%  				% Get the SpaceMethod object. If spaceMethodPrototype is a structure,
%  				% build an object for each field in the structure. The fieldnames correspond
%  				% to different discretizations provided by the Problem object.
%  				if isstruct(spaceMethodSelection)
%  					SpaceMethod = structfun( @(selection) obj.initializeObject(selection), spaceMethodSelection, 'UniformOutput', false);
%  				else
%  					SpaceMethod = obj.initializeObject(spaceMethodSelection);
%  				end
%  							
%  				Problem.endTime = Tend;
%  				Problem.setSpaceMethod(SpaceMethod);
%  				Problem.setRefinement(N);
%  				Problem.setCFL(cfl);
%  				
%  				TimeMethod = obj.initializeObject(timeMethodSelection);
%  				Supervisor = [];
%  			
%  				if verbose
%  					fprintf('%s Testing N=%i dt=%g\n', SSP_Tools.utils.time_stamp(), N, max(diff(Problem.t)))
%  				end
%  			
%  				Approximations{i} = SSP_Tools.Approximation(   'Problem', Problem,...
%  																'TimeMethod', TimeMethod,...
%  																'SpaceMethod', SpaceMethod,...
%  																'Supervisor', Supervisor,...
%  																'verbose', verbose,...
%  																'plot', plotting)';
%  				% Compile the error information.
%  				Error           = struct();
%  				Error.N         = Approximations{i}.Problem.Domain.N;
%  				Error.cfl       = cfl;
%  				Error.pointwise = abs(Approximations{i}.yExact - Approximations{i}.y);
%  				Error.l1        = Problem.scaledNorm(Error.pointwise, 1);
%  				Error.l2        = Problem.scaledNorm(Error.pointwise, 2);
%  				Error.linf      = Problem.scaledNorm(Error.pointwise, inf);
%  				Error.dt        = Approximations{i}.dt;
%  				Error.T         = Approximations{i}.t(end);
%  				Errors{i}       = Error;
%  
%  			end
%  			
%  			Approximations = [Approximations{:}];
%  			Errors = [Errors{:}];
%  			
%  			for i=2:NumRefinements
%  					refinement = log10( Errors(i).dt / Errors(i-1).dt);
%  					Errors(i).l1order = log10( Errors(i).l1 / Errors(i-1).l1) / refinement;
%  					Errors(i).l2order = log10( Errors(i).l2 / Errors(i-1).l2) / refinement;
%  					Errors(i).linforder = log10( Errors(i).linf / Errors(i-1).linf) / refinement;
%  			end
%  
%  		end

%  %  	end
%  end