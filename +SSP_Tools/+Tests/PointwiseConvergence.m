classdef PointwiseConvergence < SSP_Tools.Tests.Convergence

	properties
		output_file
	end
	
	methods

		function obj = PointwiseConvergence(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('plot_file', []);
			p.parse(varargin{:});
			obj = obj@SSP_Tools.Tests.Convergence(p.Unmatched)
			
			obj.output_file = p.Results.plot_file;
			obj.name = 'Pointwise Convergence Plot';
			
		end
		
		function run(obj)
			% Run the test and print out the results.
			obj.run_test('verbose', true);
			
			output = obj.print_results();
			cellfun(@(line) fprintf('%s\n', line), output);
			
		end 
		
		function parameters = get_parameters(obj)
			
			parent_parameters = get_parameters@SSP_Tools.Tests.Convergence();
			
			local_parameters = {};
			
			local_parameters{end+1} = struct('keyword', 'plot_file',...
			                           'name', 'File',...
			                           'longname', 'Output Plot File Name',...
			                           'type', 'string',...
			                           'options', [],...
			                           'default', 'plot.eps');
		
			parameters = [local_parameters{:}, parent_parameters ];
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
				obj = SSP_Tools.Tests.PointwiseConvergencePDE(varargin{:});
			else
				error('Test not valid for selected problem');
			end
		end
	
	end		
end