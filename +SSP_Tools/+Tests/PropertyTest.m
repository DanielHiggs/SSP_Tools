classdef PropertyTest < handle

	properties
		results;
	end
	
	methods

		function obj = PropertyTest(varargin)
			% If we're initialized with no arguments, start an interative
			% session. If we received any arguments, pass those
			% arguments along to the the run_test() method.
			if nargin == 0
				obj.interactive();
			else
				obj.run_test(varargin{:});
			end
		end
		
		function [varargout] = start_test(varargin{:})
			results.time = clock()
			nOut = nargout(@obj.run_test);
			test_results = cell(1,nOut);
			[test_results{1:nOut}] = obj.run_test(varargin{:});
			varargout = test_results;
		end
		
		
		
		
		function ProblemPrototype = selectProblem(obj, varargin)

			Profiles = SSP_Tools.ProfileConfig();

			if length(varargin) == 1
				selection = varargin{1};
			else
				availableProblems = Profiles.listProfiles('PDE');
			
				% Print a menu displaying the available example problems
				fprintf('Available Problems:\n');
				obj.printMenu(availableProblems);
			
				% Let the user select a problem
				problemNum = input('Select Example Problem: ');
				problemName = availableProblems{problemNum};
				selection = { 'type', 'PDE', 'name', problemName };
			end
			
			[problemClass, problemArgs] = Profiles.select(selection{:});
			ProblemPrototype = SSP_Tools.Prototype(problemClass, problemArgs);
		end
		
		function Object = initializeObject(obj, options)
			if length(options) == 1 & SSP_Tools.Prototype.isprototype(options)
				Object = options.build();
			else
				if strcmp(options{1}, 'type')
					% We have the makings of a Problemtype object
					Profiles = SSP_Tools.ProfileConfig();
					Object = Profiles.load( options{:} );
				else
					% We're instantiating some other class
					Object = SSP_Tools.utils.instantiate(options{:});
				end
			end
		end
		
		function SpaceMethodPrototype = selectSpaceMethod(obj, varargin)
		
			p = inputParser;
			addParamValue(p, 'ProblemSelection', []);
			p.parse(varargin{:});
			ProblemSelection = p.Results.ProblemSelection;
			
			if strcmp( class(ProblemSelection), 'SSP_Tools.Prototype') & ...
			         strcmp(ProblemSelection.classname, 'SSP_Tools.ProblemTypes.PDE2d')
				fprintf('Select a Spatial Discretization For the X-Direction\n');
				SpaceMethodPrototype.x = obj.selectASpaceMethod();
				fprintf('Select a Spatial Discretization For the Y-Direction\n');
				SpaceMethodPrototype.y = obj.selectASpaceMethod();
			else
				SpaceMethodPrototype = obj.selectASpaceMethod();
			end	
		end
		
		function SpaceMethodPrototype = selectASpaceMethod(obj)
			% Select and Instantiate an Object Implementing A Spatial Discretization Scheme.
			%
			% The first input argument is a string containing the name of the class
			% which implements the desired Spatial Discretization Method. Following
			% that are name-value pairs corresponding to the arguments recognized
			% by the constructor method of that class.
			% 
			% If the function is invoked without any arguments, it will interactively
			% ask the user for them. 
			% 
			% The function has two return values. The first is the instantiated object
			% for the Spatial Discretization Scheme, while the second is a cell array 
			% containing the arguments used to construct that argument.
			% 
			
			SpaceMethods = SSP_Tools.SpaceMethodConfig();
			availableSpaceMethods = SpaceMethods.list();
			
			fprintf('Available Spatial Discretization Methods\n');
			obj.printMenu( availableSpaceMethods );
			
			spaceMethodNum = input('Select Spatial Discretization: ');
			spaceMethodName = availableSpaceMethods(spaceMethodNum);
			spaceMethodProfile = SpaceMethods.spaceMethods(spaceMethodNum);
			methodArgs = struct();
			
			if ~isempty(spaceMethodProfile.args)
				methodArgNames = fieldnames(spaceMethodProfile.args);
				if ~isempty(methodArgNames)
					fprintf('This method has optional parameters.\n');
					fprintf('Input new values or press enter to\n');
					fprintf('keep the default value\n');
				end
									
				for i=1:length(methodArgNames)
					if spaceMethodProfile.args.(methodArgNames{i}).editable == true
						queryStr = sprintf('%s - %s [%3.2e]: ', methodArgNames{i}, spaceMethodProfile.args.(methodArgNames{i}).name, spaceMethodProfile.args.(methodArgNames{i}).value);
						argValue = input(queryStr);
						if isempty(argValue)
							argValue = spaceMethodProfile.args.(methodArgNames{i}).value;
						end
						methodArgs.(methodArgNames{i}) = argValue;
					end
				end
			end
			
			methodArgs = SSP_Tools.utils.estruct2cell(methodArgs);
			SpaceMethodPrototype = SpaceMethods.select( spaceMethodName, methodArgs{:} );
%  			methodClass = spaceMethodProfile.class;
%  			methodArgs = methodArgs;
			
%  			SpaceMethodPrototype = SSP_Tools.Prototype(methodClass, methodArgs);
		end
		
		function [Supervisor, selection] = selectSupervisor(obj, varargin)
				
			if length(varargin) == 1
				selection = varargin{:};
			else
				selection = varargin;
			end
			
			p = inputParser;
			p.KeepUnmatched = true;
			addParamValue(p, 'type', []);
			p.parse(selection{:});

			if isempty(p.Results.type)
				Supervisor = [];
				selection = [];
			elseif strcmp(p.Results.type, 'TVD')
				arguments = SSP_Tools.utils.estruct2cell(p.Unmatched);
				Supervisor = TVD_Supervisor( arguments{:} );
				selection = { 'type', 'TVD' }
				selection = { selection{:}, arguments{:} };
			end
		end
		
		
		function TimeMethodPrototype = selectTimeMethod(obj, varargin)
			% Select and Instantiate an Object Implementing A Time-Stepping Method.
			%
			% The first input argument is a string containing the name of the class
			% which implements the desired Time-Stepping Method. Following
			% that are name-value pairs corresponding to the arguments recognized
			% by the constructor method of that class.
			% 
			% If the function is invoked without any arguments, it will interactively
			% ask the user for them. The keyword 'overriddenDefaults' may be used to
			% suppress certain arguments from being obtained interactively by the user.
			% When passed along with a structure containg fieldnames corresponding to 
			% parameters recognized by the Time Stepping Method class's constructor, 
			% this function will take those values instead of asking the user for them.
			% 
			% The function has two return values. The first is the instantiated object
			% for the Spatial Discretization Scheme, while the second is a cell array 
			% containing the arguments used to construct that argument.
			% 
			Methods = SSP_Tools.TimeMethodConfig('dir', [pwd, '/Method Coefficients']);
			
			p = inputParser;
			addParamValue(p, 'overriddenDefaults', []);
			% Sometimes we might want to force interactive-mode to use certain
			% defaults.
			% 
			% overriddenDefaults is a structure that contains the fieldnames
			% of options used by our timestepping method and corresponding values
			% to use as the default parameters for those values.
			% 
			
			p.parse(varargin{:});
			
			% Some method options can be overridden. The parameter 'forceNewDefault'
			% accepts a cell array of name/value pairs of TimeMethod options to override.
			overriddenDefaults = p.Results.overriddenDefaults;
			
			fprintf('Available Method Profiles\n');
			availableMethods = Methods.list();
			obj.printMenu(availableMethods);
			methodNum = input('Select Method Profile: ');
			methodName = availableMethods{methodNum};
			methodProfile = Methods.timeMethods(methodNum);
			methodClass = methodProfile.class;
			methodArgs = struct();
			
			[availableCoefficients, coefficientFiles] = Methods.listMethods(methodName);
			if ~isempty(availableCoefficients)
				% Select sub-method
				fprintf('Available Methods:\n');
				obj.printMenu(availableCoefficients);
				coefficientNum = input('Select Coefficients: ');
				methodArgs.coefficients = coefficientFiles{coefficientNum};
			end

			% Get the list of arguments, but remove 'coefficients'
			% because we've already dealt with those
			if ~isempty(methodProfile.args)
				methodArgNames = fieldnames(methodProfile.args);
				methodArgNames(strmatch('coefficients', methodArgNames, 'exact')) = [];
				
				for i=1:length(methodArgNames)
					
					% If we're overriding the default value, use the overridden default. 
					% Otherwise, take the default from the profile.
					if isfield(overriddenDefaults, methodArgNames{i})
						defaultValue = overriddenDefaults.(methodArgNames{i});
					else
						defaultValue = methodProfile.args.(methodArgNames{i}).value;
					end
					
					
					if iscell(defaultValue)
						defaultValueStr = SSP_Tools.utils.cell2str(defaultValue);
					else
						defaultValueStr = SSP_Tools.utils.any2str(defaultValue);
					end
					queryStr = sprintf('Enter value for %s argument [%s]', methodProfile.args.(methodArgNames{i}).name, defaultValueStr);
					argValue = input(queryStr);
					if isempty(argValue)
						argValue = defaultValue;
					end
					methodArgs.(methodArgNames{i}) = argValue;
				end
			
				methodClass = methodProfile.class;
				methodArgs = methodArgs;
			end
			
			TimeMethodPrototype = SSP_Tools.Prototype(methodClass, methodArgs);
		end
	
		function cfl = selectCFL(obj)
			cfl = input('Enter CFL condition [0.4]: ');
			if isempty(cfl)
				cfl = 0.4;
			end
		end
		
		function plotbool = selectPlot(obj)
			plotbool = input('Plot? 1:Yes, 0:No [1]: ');
			if isempty(plotbool)
				plotbool = 1;
			end
		end
		
		function cflinc = selectCFLinc(obj)
			cflinc = input('Enter CFL increment [0.1]: ');
			if isempty(cflinc)
				cflinc = 0.1;
			end
		end
		
		
		function N = selectN(obj)
			N = input('Enter number of grid points [50]: ');
			if isempty(N)
				N = 50;
			end
		end
		
		function Ns = selectNs(obj)
			Ns = input('Enter a vector of grid points [default]: ');
			if isempty(Ns)
				Ns = [11, 21, 31, 41, 51, 61, 71, 81, 91, 101];
			end
		end
		
		
		function Tend = selectTend(obj)
			Tend = input('Enter T_final [1.0]: ');
			if isempty(Tend)
				Tend = 1.0;
			end
		end

		function printMenu(obj, menuOptions)
			for i=1:length(menuOptions)
				fprintf('\t[%i] %s\n', i, menuOptions{i});
			end
		end
		
		
	end
		
end