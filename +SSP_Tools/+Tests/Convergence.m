classdef Convergence < SSP_Tools.Tests.Test

	properties
	
		% A vector of the refinements we're testing
		t = [];
		refinements = [];
		problem_template = [];
		completed_problems = [];
	end
	
	methods

		function obj = Convergence(varargin)
			obj = obj@SSP_Tools.Tests.Test(varargin{:});
		
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('refinements', []);
			p.addParamValue('t', []);
			p.addParamValue('problem', []);
			p.parse(varargin{:});
			
			verbose = false;
			
			obj.t = p.Results.t;
			obj.refinements = p.Results.refinements;
			obj.problem_template = p.Results.problem;
			
			% Pass in our logging function to the problem.
			obj.problem_template.log = @obj.log;
			
		end
		
		function run(obj)
			% Run the test and print out the results.
			obj.verbose = true;
			obj.run_test();
		end
		
		function commands = get_commands(obj)
		% Return a structure containing information about the
		% commands supported by this class.
			commands = struct('name', {'import', 'save'});
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
				obj = SSP_Tools.Tests.ConvergencePDE(varargin{:});
			elseif isa(problem, 'SSP_Tools.TestProblems.ODE')
				obj = SSP_Tools.Tests.ConvergenceODE(varargin{:});
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