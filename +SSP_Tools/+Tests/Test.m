classdef Test < handle
% This is the parent class for all numerical tests.

	properties
		
		name;
		% A nice human-readable name for the test to be used in reports
		
		output_buffer = {};
		report_buffer = {};
		% These cell array are where log() and print() store all their
		% output for repeated/delayed printing to the console.
		
		results;
		% This should be a structure which will contain the machine-readable
		% results of the numerical test. 
		
		verbose = false;
		
	end


	methods
		
		function obj = Test(varargin)
			true;
		end
		
		function run(varargin)
		% An interactive hook for starting this test. This function should call
		% run_test() after setting the 'verbose' parameter to true.
			error('Not Implemented')
		end
		
		function output = run_test(varargin)
		% A non-interactive hook for starting this test. This function should execute
		% whatever numerical test is being performed. 
			error('Not Implemented')
		end
		
		function parameters = get_parameters(obj)
		% Return a structure array containing information about the various
		% parameters used to initialize this test. This function is called
		% by various factory classes and is used to populate a user-interface
		% with configuration options for this class.
			error('Not Implemented');
		end
		
		function log(obj, varargin)
		% Print a given string to the output buffer. If the test
		% is being run verbosely, also print it to the console.
		% 
		% This should be used for information that's nice to see
		% when a test is running but which can be safely ignored if
		% the test is running non-interactively. 
			string = sprintf(varargin{:});
			
			if string(end) == 13
				% skip storing this kind of output
			else
				obj.output_buffer{end+1} = string;
			end
			
			if obj.verbose
				fprintf(string);
			end
		end
		
		function repr_str = repr(obj)
			objclass = metaclass(obj);
			repr_str = sprintf('< %s >', objclass.Name);
		end
		
		function print(obj, varargin)
		% Print a given string to the report buffer. If the test
		% is being run verbosely, also print it to the console.
		
			string = sprintf(varargin{:});
			obj.report_buffer{end+1} = string;
			obj.log(varargin{:});
			
		end
		
		function save(obj, filename, varargin)
		% Save all relevant data from the test including any logs or
		% plots that may have been produced. filename should be the base
		% name for all of the files produced, and if it ends with a '/' 
		% it should be treated as a directory.
			error('Not Implemented');
		end
		
	end

end