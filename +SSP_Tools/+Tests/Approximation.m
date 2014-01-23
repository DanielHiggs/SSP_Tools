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
			p.addParamValue('cfl', []);
			p.parse(varargin{:});
			
			obj.t = p.Results.t;
			obj.problem = p.Results.problem;
			
			if ~isempty(p.Results.cfl)
				obj.dt = p.Results.cfl*min(diff(obj.problem.x));
			else
				obj.dt = p.Results.dt;
			end

			
			obj.name = 'Simple Approximation';

			
		end

		function run(obj)
			% Run the test and print out the results.
			obj.verbose = true;
			problem = obj.run_test();
		end 
		
		function results = run_test(obj)
		
			% We can't go backwards with our approximation,
			% so raise an error if we're asked to approximate
			% a value of t that's less than where we're currently
			% at.
			
			if isa(obj.problem, 'SSP_Tools.TestProblems.ODE')
				obj.problem.setup_problem();
			end
			
			obj.problem.approximate(obj.t, 'dt', obj.dt, 'verbose', @obj.log);
			
			results = obj.problem;
			
		end
		
		function [status, files] = save(obj, prefix)
		% Save all of our data 
			
			files = {};
			status = 0;
			
		end
		
		function [status, variables] = import(obj)
		% Import test results into current workspace
			assignin('base', 'problem', obj.problem);
			variables = struct('name', 'problem', 'description', 'Problem Object');
			status = 0;
		end
		
		function parameters = get_parameters(obj)
			
			parameters = {};
			                           			
			parameters{end+1} = struct('keyword', 'problem',...
			                           'name', 'Example Problem',...
			                           'longname', 'Fully-formed Example Problem',...
			                           'type', 'full_problem',...
			                           'options', struct('type', 'SSP_Tools.TestProblems.TestProblem'),...
			                           'default', []);
			                           
			parameters{end+1} = struct('keyword', 't',...
			                           'name', 't',...
			                           'longname', 'Value of t to approximate to',...
			                           'type', 'double',...
			                           'options', [],...
			                           'default', 1.0);
		
			parameters{end+1} = struct('keyword', 'timestep',...
			                           'name', 'timestep',...
			                           'longname', 'Options For Time Step Configuration',...
			                           'type', 'function_defined',...
			                           'options', @obj.get_parameters_dt, ...,...
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
				parameter_desc = struct();
				parameter_desc.keyword = 'dt';
				parameter_desc.name = 'dt';
				parameter_desc.longname = 'dt';
				parameter_desc.type = 'double';
				parameter_desc.options = [];
				parameter_desc.default = 0.01;
				out_parameters = [];			
			end
		end
		
		function commands = get_commands(obj)
		% Return a structure containing information about the
		% commands supported by this class.
			commands = struct('name', 'import');
		end
	
	end

end