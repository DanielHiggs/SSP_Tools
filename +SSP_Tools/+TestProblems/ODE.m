classdef ODE < SSP_Tools.TestProblems.TestProblem

	properties		
		
		% What's the initial condition? This should be a function
		% uinit(x) that returns a value of u at t=0 for every
		% x given to it. 
		initial_condition = [];
		
		% Domain
		domain = [];
		
		% We'll also need a TimeMethod object that will be used to 
		% solve the resulting system of ODEs and get the general solution
		% to the homogeneous ODE.
		integrator = [];
		
		% Store our domain and dependent variables
		t = [];
		dt = [];
		y = [];
		
		% For problems where we have no closed-form solution, we substitute
		% an ODE object that is configured to perform a much higher accuracy
		% approximation
		hires_problem = [];
		
		% A MATLAB datafile for storing/retreiving exact solutions
		data_file = [];
		exact_data = [];
		
	end
	
	properties(GetAccess = 'private', SetAccess = 'private')
		
		% Sometimes we might nest objects of this type (See get_exact_solution() )
		% so it's important that we know whether this is the case.
		is_nested = false;
		
	end
	

	methods
	
		function obj = ODE(varargin)
			obj = obj@SSP_Tools.TestProblems.TestProblem(varargin{:});

			p = inputParser;
			p.addParamValue('name', []);
			p.addParamValue('initial_condition', []);
			p.addParamValue('initial_time', []);
			p.addParamValue('integrator', []);
			p.parse(varargin{:});
			
			obj.name = p.Results.name;
			obj.y = p.Results.initial_condition;
			obj.initial_condition = p.Results.initial_condition;
			obj.domain = p.Results.initial_time;
			
			% Initialize the integrator for the general solution
			if ~isempty(p.Results.integrator)
				obj.set_integrator(p.Results.integrator);
			end
			
			% Load the datafile, if it exists
			package_path = mfilename('fullpath');
			dir_seps = strfind(package_path, '/');
			package_path = package_path(1:dir_seps(end));
			if ~isempty(obj.data_file)
				obj.data_file = [package_path, 'data/', obj.data_file];
				if exist(obj.data_file, 'file')
					loaded_data = load(obj.data_file);
					obj.exact_data = loaded_data.data;
				end
			else
				obj.exact_data = containers.Map;
			end
			
		end
		
		function setup_problem(obj)
			% MATLAB is stupid. We need to do this again otherwise
			% copies of this object will still try to use the 
			% integrator attached to this object.
			obj.y = obj.initial_condition;
			obj.t = obj.domain(1);
			obj.set_integrator(obj.integrator)
			
		end

		function set_integrator(obj, integrator)
			% Initializes the integrator for the general solution
			% to the homogeneous ODE. 
			integrator.yPrimeFunc = @obj.y_p;
			integrator.yInFunc = @(u) u;
			integrator.yOutFunc = @(u) u;
			integrator.ProblemObject = obj;
			integrator.log = obj.log;
			obj.integrator = integrator;
		end
		
		function step(obj, dt)

			% Approximate the homogenous equation u_t = -f(u)_x
			y_next = obj.integrator.step(obj.y(:,end), obj.t(end), dt);
			obj.y(:,end+1) = y_next;
			obj.t(end+1) = obj.t(end) + dt;
			
		end
		
		function approximate(obj, t, varargin)
			% Approximate the solution at t= by stepping in
			% increments of dt
			
			p = inputParser;
			p.addParamValue('dt', []);
			p.addParamValue('tolT', []);
			p.parse(varargin{:});
			
			if ~isempty(p.Results.dt)
				dt = p.Results.dt;
			else
				dt = 1/1000*(t - obj.t);
			end
			
			if ~isempty(p.Results.tolT)
				tolT = p.Results.tolT;
			else
				tolT = 1e-16;
			end
			
			
			% Record what timestep we used for reporting purposes
			obj.dt = dt;
			t_remaining = abs(obj.t(end) - t);
			while t_remaining > tolT
				if t_remaining < dt
					obj.step(t_remaining);
				else
					obj.step(dt);
				end
				
				t_remaining = t - obj.t(end);
				print_buffer = sprintf('[%s] Approximating T=%4.2g %3.2f Complete', datestr(now, 13),...
					                                                                    obj.t(end),...
					                                                                    obj.t(end)/t*100);
				obj.log('%s\r', print_buffer)
				
			end 
			
			print_buffer = repmat(' ', 1, length(print_buffer));
			obj.log('%s\r', print_buffer);

		end
		
		function y = get_approximation(obj)
			y = obj.y;
		end
		
		function fig = plot(obj)
			% Plots the current value of u
			fig = figure();
			plot(obj.t, obj.y, 'b')
			hold all
			plot(obj.t, obj.get_exact_solution(), 'r');
			title( sprintf('%s - %s', obj.name, obj.integrator.name));
			legend( {'Computed', 'Exact'});
		end

		function pointwise_error = calculate_error(obj)
			% Calculate the pointwise error 
			
			y_exact = obj.get_exact_solution();
			pointwise_error = abs(obj.y - y_exact);
		end
		
		function y = get_exact_solution(obj)
			% Get an exact solution
			error('Not Implemented');
			y = [];
		end
		
		function clone = copy(obj)
			% Construct a copy of this object.
			% 
			meta = metaclass(obj);
			clone = eval([ meta.Name, '()' ]);
			clone.setup_problem();
			
			ignored_fields = {'y', 't' };
			copied_fields = {'integrator'};
			
			props = fieldnames(obj);
			for i=1:numel(props)
			
				ignored_fields = { 'integrator' };
			
				if any(strcmp(props{i}, ignored_fields) )
					% skip
				else
					% Copy the values
					clone.(props{i}) = obj.(props{i});
				end
				
				% Copy the integrator
				clone.set_integrator(obj.integrator.copy());
				
			end
		end
		
		function data = export(obj)
			% Export information about the problem, what we're doing with it
			% and what approximation we obtained in an independent format.
			%
			data.y = obj.y;
			data.t = obj.t;
			data.y_p = func2str(obj.y_p);
			data.initial_condition = obj.y(:,1);
			data.integrator = obj.integrator.get_repr();
			data.date = datestr(now);
		end
%  
		function repr_struct = get_repr(obj)
			% Get a machine readable representation of this
			% class
			
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			repr_struct.IC = obj.y(:,1);
			repr_struct.t0 = obj.t(1);
			repr_struct.t = obj.t(end);
		end
		
		function id_string = repr(obj)
			
			repr_struct = obj.get_repr();
			id_fmt = '< %s: y(%g)=%s t=%g >';
			
			ic_string = sprintf('[ %s]', sprintf('%3.2f ', repr_struct.IC));
			
			id_string = sprintf(id_fmt, repr_struct.Class, ...
			                            repr_struct.t0, ...
			                            ic_string, ...
			                            repr_struct.t );
		
		end
	
		function parameters = get_parameters(obj)
		
			parameters = {};
			
			
			parameters{end+1} = struct('keyword', 'integrator', ...
			                       'name', 'Time Stepping Integrator', ...
			                       'type', 'SSP_Tools.Integrators.Integrator',...
			                       'options', [], ...
			                       'default', [] );
		
			parameters = [ parameters{:} ];
		
		end	
	end
end