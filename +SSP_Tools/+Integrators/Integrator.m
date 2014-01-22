classdef Integrator < handle
% Integrator.m
% 
% This is the base class for all numerical time-stepping methods in the SSP_Tools
% package. It provides a simple external interface for communicating with a time-
% stepping method along with basic support mechanisms for evaluating the 
% 
% 
% 
%	
	properties
	
		name;			% Name of time-stepping method.
		order;		% Theoretical order of convergence
		stages;     % Number of stages
		steps;      % Number of steps
		r;				% Theoretical SSP max(dt)
		verbose;

		log;
		
	end
	
	properties(SetObservable)
		yPrimeFunc;      % Function providing y'(y,t)
		
		yInFunc;         % Function which maps y into a column vector.
		                 %
		                 % All of these time-stepping methods assume that they're
		                 % operating on a system of ODEs represented as a single column
		                 % vector. For PDEs, this is obtained using the Method of Lines. 
		                 %
		                 % For cases where the PDE is non-trivial (a system of PDEs, a 
		                 % multi-dimensional domain) this function maps however the dependent
		                 % variable is stored into a column vector so that it can be processed
		                 % by a time-stepping method.
		                 % 
		                 % If not supplied, this does nothing.
		                 % 
		
		yOutFunc;        % Function which maps y from a column vector to it's original form
		                 %
		                 % This is a function that produces the inverse of yInFunc. It's 
		                 % used to reshape a column vector into whatever shape the data exists
		                 % in external to the time-stepping method.
		                 % 
		                 % If not supplied, this does nothing.
		                 %  
		                 
		solver;          % An instance of SSP_Tools.utils.MatlabSolver or some other
		                 % object that has the same interface
		                 % 
		                 % Implicit time-stepping methods require a solver, and using our own
		                 % object to interface with fsolve gives us the chance to catch
		                 % an error if the optimization toolkit isn't installed, or develop
		                 % our own solver to replace fsolve.
		                 % 
		                 % This is only set if it's needed. Explicit methods don't touch it.
		                 %
		                  
		ProblemObject;   % A reverse reference to the SSP_Tools.TestProblems.TestProblem
		                 % instance that links to this object.
		                 % 
		                 % This is things get a little messy. Some integrators might want to
		                 % have a little more control over the problem they're solving. An example
		                 % may be found in the MSRK integrator which has the option of using an
		                 % exact solution if it's available to intially obtain values for 
		                 % it's multistep method.
		                 % 
		                 % Most time-stepping methods won't need this, and it's empty by default.
		                 % 
	end
	
	methods

		function obj = Integrator(varargin)
			% 
			% Integrator('yPrimeFunc', <function> [,'yInFunc', <function>, 'yOutFunc', <function>])
			% 
			% Construct a Integrator object.
			% 
			% yPrimeFunc should be a function handle that defines the right hand side of
			% y'(u,t) = f(u,t). This is the function that will be called whenever the
			% time-stepping method needs a derivative, and it should accept column vectors
			% and return column vectors. If the method uses stacked-column vectors to
			% represent multiple stages, this function should know what to do with them.
			% 
			% yPrimeFunc can also be an array of function handles for methods that require 
			% more than one available way to compute y' such as Downwind Runge-Kutta Methods
			% for Partial Differential Equations.
			% 
			% yInFunc is a function f(y) which maps the variable y into a column vector. This is so
			% that all of our numerical methods can be written to operate on a system of ODEs while
			% still supporting multidimensional PDEs and systems of PDEs. If left unspecified, this
			% will default to a one-to-one mapping f(y) = y;
			% 
			% yOutfunc is a function f(y) which reverses the mapping performed by yInFunc. This is called
			% by step() just prior to returning the value of y to whatever called it. If left unspecified,
			% this will default to a one-to-one mapping f(y) = y;
			% 
			% Additional parameters will get passed to the init() method. This is where children
			% of this class parse their child-specific parameters.
			% 
			import utils.*;
			
			p = inputParser;
			p.KeepUnmatched = true;			
			addParamValue(p, 'yInFunc', []);
			addParamValue(p, 'yOutFunc', []);
			addParamValue(p, 'yPrimeFunc', @obj.ErrorNoyPrime );
			addParamValue(p, 'Problem', []);
			addParamValue(p, 'log', []);
			p.parse(varargin{:});
			options = p.Results;

			if ~isempty(p.Results.log)
				obj.log = p.Results.log;
			end
			
			% Set yPrimeFunc
			obj.setyPrimeFunc(p.Results.yPrimeFunc);
			 
			% Set yInFunc
			obj.yInFunc = p.Results.yInFunc;
			if isempty(obj.yInFunc)
				obj.yInFunc = @(y) y;
			end
			
			% Set yOutFunc
			obj.yOutFunc = p.Results.yOutFunc;
			if isempty(obj.yOutFunc)
				obj.yOutFunc = @(y) y;
			end
			
			% If we were supplied with it, note our ProblemObject
			obj.ProblemObject = p.Results.Problem;
			

		end
		
		function [y_next, exitcode, msg] = step(obj, y, t, dt)
			% Return an approximation of u^{n+1} given u^n at 
			% t^n + dt. This is a wrapper for NumericalMehthod.advance()
			% which is implemented by children of NumericalMethod.
			
			% Start our timer
			% methodTimer = tic();
			
			% Whatever y is, transform it into a column vector.
			y = obj.yInFunc(y);
			
			% Pass everything on to the child's advance() method.
			[y_next, exitcode, msg] = obj.advance(y, t, dt);
			
			% Return y to whatever it was when we got it.
			y_next = obj.yOutFunc(y_next);
			
			% Get the time it took to step forward and store it in obj.stats
			% obj.stats.stepTime = toc(methodTimer);
			
		end
		
		function setyPrimeFunc(obj, yPrimeFunc)
			% yPrimeFunc(y,t) is a function that provides the value of 
			% y' for given values of y and t.
			if isa(yPrimeFunc, 'function_handle')
				obj.yPrimeFunc = yPrimeFunc;
			else
				error('yPrimeFunc not a function handle');
			end
		end
		
		function warn(obj, varargin)
		% Raise a warning due to dangerous behavior
		%
		% MATLAB's warning system leaves much to be desired because it can't be trapped, nor
		% can the output be captured and output later, so we're going to roll our own here.
		%
		% warn(varargin) raises a warning. Input follows MATLAB's warning() function.
		% if obj.warnings is 'off', the warning will immediately be output to the console
		% otherwise the output string is stored in obj.warnings as a cell array.
		% 
		% warnings = warn() returns all the strings in obj.warnings
		%		
			if isempty(obj.log)
				warning(varargin{:});
			else
				warning_msg = sprintf('%s - %s', varargin{1}, sprintf(varargin{2}, varargin{3:end}));
				obj.log('%s\n', warning_msg);
			end
		end
		
		
		function clone = copy(obj)
		% Make a copy of an Integrator object
		% 
		% This function provides a basic deep copy for objects of
		% this class. Integrator objects may hold state, so it's
		% important to have a copy() that does the right thing and
		% assembles a new, independent object.
		% 
			meta = metaclass(obj);
			clone = eval([ meta.Name, '()' ]);
			
			ignored_fields = {'ProblemObject', 'warnings'};
			
			props = fieldnames(obj);
			for i=1:numel(props)
				if ~any( strcmp(props{i}, ignored_fields) )
					clone.(props{i}) = obj.(props{i});
				end
			end
			
			% This is probably the safest thing to do for now...
			clone.ProblemObject = [];
			
		end
	end	
	
	
	
	methods(Static)
	
		function err = ErrorNoyPrime(varargin)
			error('yPrime not specified');
		end
	end
	
end
		
	