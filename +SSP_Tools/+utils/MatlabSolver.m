% SSP_Tools.utils.MatlabSolver
%
% This class provides an abstraction interface to MATLAB's fsolve command.
% This way we can universally tinker with the solver's options without having to
% change all the code that uses the solver.
% 
% As a bonus, we can also keep track of some interesting information about how
% well the solver worked without having to edit all the code that uses the solver.
% 

classdef MatlabSolver < handle
	properties
	runtimes = [];       % Runtime for each call to the solver.
	iterations = [];     % Number of iterations for each call.
	funcCount = [];      % Number of function evaluations for each call.
		
	end
	
	methods
		function obj = MatlabSolver(varargin)

		
			% Return a MatlabSolver object.
			if exist('fsolve') == 2
				true;
			else
				msg = sprintf(['\n', ...
				              'ERROR: No Non-linear Solver Detected.\n\n', ...
				              'We can''t find MATLAB''s fsolve() command which is needed\n', ...
				              'to use this implicit method.\n']);
				error(msg);
			end
				   
		end
		
		function [x, fval, exitflag, output] = call(obj, func, x0, varargin)
			% Overload MATLAB's call function.
			%
			% Calls to SolverInterface objects will behave exactly like calls to
			% MATLAB's fsolve command and everything it does should be transparent to
			% the caller.
			
			[x,fval,exitflag,output] = fsolve(func, x0, optimset('Display', 'off', 'MaxIter', 1000, 'MaxFunEvals', 1e10) );
		end
		
	end
end