classdef TestProblem < handle
	% This class defines the basic interface for all
	% test problems, be they PDE, ODE, or some specialized
	% version of either.
	% 
	
	properties
		name;
		
		
		% This is a function that will be called in place of fprintf
		% whenever information needs to be output to the console. By
		% default it's fprintf
		log = @fprintf;
		
	end
	
	methods
		function obj = TestProblem(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('log', []);
			p.parse(varargin{:});
			
			if ~isempty(p.Results.log)
				obj.log = p.Results.log;
			end
		end
	
		function approximate(obj, t, varargin)
			% Approximate the problem at the specified value of t
			% where t > t_now
			error('Not Implemented')
		end
		
		function step(obj, dt)
			% Starting with the current value of the problem at t_now,
			% step the approximation forward to t_next = t_now + dt;
			error('Not Implemented')
		end
		
		function get_domain(obj, varargin)
			% Return the problem's domain
			error('Not Implemented')
		end
		
		function get_approximation(obj)
			% Return the current value of the approximation
			% at t=t_now
			error('Not Implemented')
		end
		
		function get_exact_solution(obj)
			% Return the exact solution at t=t_now
			error('Not Implemented')
		end
		
		function pointwise_error = get_error(obj)
			% Return the pointwise error of the approximation
			% at t=t_now
			error('Not Implemented')
		end
		
		function clone = copy(obj)
			% Return a copy of this object reset to the initial
			% conditions.
			error('Not Implemented')
		end
		
		function data = export(obj)
			% Return a structure containing a representation of
			% the current state of this object and all of its
			% compontnets.
			error('Not Implemented')
		end
		
		function plot(obj)
			% Plot the current solution at t=t_now
			% with or without the exaxct solution
			error('Not Implemented')
		end
		
		function id_string = repr(obj)
			% Return a one line text string identification of this object
			error('Not Implemented')
		end
		
		function repr_struct = get_repr(obj)
			% Return a matlab structure representation of this object.
			error('Not Implemented')
		end
	end
end