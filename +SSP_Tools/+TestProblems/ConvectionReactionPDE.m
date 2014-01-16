classdef ConvectionReactionPDE < SSP_Tools.TestProblems.PDE

	properties		
		
		fsource = @(u) u;
		
		% Store our domain and dependent variables
  		xi_1 = [];
		xi_2 = [];
		
	end
	
	properties(GetAccess = 'private', SetAccess = 'private')
		
		% Sometimes we might nest objects of this type (See get_exact_solution() )
		% so it's important that we know whether this is the case.
		is_nested = false;
		
	end
	

	methods
	
		function obj = ConvectionReactionPDE(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('xi_1', []);
			p.addParamValue('xi_2', []);
			p.parse(varargin{:});
			
			params = p.Unmatched;
			obj = obj@SSP_Tools.TestProblems.PDE(params);
		
			% Initialize our xi
			if ~isempty(p.Results.xi_1) & ~isempty(p.Results.xi_2)
				obj.set_xi(p.Results.xi_1, p.Results.xi_2);
			end

		end


		
		function set_xi(obj, xi_1, xi_2)
			obj.xi_1 = xi_1;
			obj.xi_2 = xi_2;
		end
		
		function setup_problem(obj, N)
			% Initialize our computational domain.
			obj.x = linspace(obj.domain(1), obj.domain(2), N + 1);
		
			% Get the initial condition    
			obj.u = obj.uinit(obj.x)';
			obj.t = 0.0;
			
			% MATLAB is stupid. We need to do this again otherwise
			% copies of this object will still try to use the 
			% integrator attached to this object.
			obj.set_integrator(obj.integrator);
		end
		
		function set_discretizer(obj, discretizer)
			% Initializes the discretizer. Right now this only
			% accepts an SSP_Tools.SpaceMethod object, but this
			% behavior can easily be changed.
			discretizer.f = @obj.fflux;
			discretizer.em = @obj.em;
			discretizer.left_boundary = obj.left_boundary;
			discretizer.right_boundary = obj.right_boundary;
			obj.discretizer = discretizer;
		end
		
		function set_integrator(obj, integrator)
			% Initializes the integrator for the general solution
			% to the homogeneous PDE. 
			integrator.yPrimeFunc = @(u,t) obj.RHS(u,t);
			integrator.yInFunc = @(u) u;
			integrator.yOutFunc = @(u) u;
			obj.integrator = integrator;
		end

		function step(obj, dt)
			% Step forward to t_{n+1} = t_{n} + dt
			
			u_next = obj.integrator.step(obj.u, obj.t, dt);
			obj.u = u_next;
			obj.t = obj.t + dt;
			
		end
		
		function RHS = RHS(obj, u,t)
			tmp_discretizer = obj.discretizer;
			u_x = obj.discretize(u, t, @tmp_discretizer.L);
			u_source = obj.fsource(u);
			RHS = obj.xi_1*u_x + obj.xi_2*u_source;
		end
		
		function pointwise_error = calculate_error(obj)
			% Obtain an exact solution either by looking it
			% up in our precomputed solutions database, or 
			% calculating it.
			
			% Try the database first
			u_exact = obj.get_exact_solution();
			if isempty(u_exact)
				% The database is empty, compute it.
%  				error('No exact solution present')
				obj.calculate_exact_solution();
				u_exact = obj.hires_problem.u;
			end

			pointwise_error = abs(obj.u - u_exact);
			
		end
		
		function u = get_approximation(obj)
			u = obj.u;
		end
		
		function key = create_database_key(obj, x, t)
			% Create a record for the database lookup. The database
			% is indexed by the domain values and by the value of t.
			record = struct();
			record.x = x;
			record.t = t;
			record.xi_1 = obj.xi_1;
			record.xi_2 = obj.xi_2;
			key = SSP_Tools.utils.DataHash(record);
		end
		
		function u = get_exact_solution(obj)
			% Fetch a precomputed exact solution from the data file.
			
			% Create the database if it doesn't already exist.
			if isempty(obj.exact_data)
				obj.exact_data = containers.Map;
			end
			
			% This will become true if there's any point
			% in the domain we don't have an exact solution for
			need_to_compute = true;
			u = zeros(numel(obj.x),1);
			
			% Create an index.		
%  			for i=1:numel(obj.x)
%  				key = obj.create_database_key(obj.x(i), obj.t);
%  				
%  				% Do we have a value for this point in the database?
%  				if obj.exact_data.isKey(key)
%  					fprintf('Found value for x=%f, t=%f, xi_1=%f, xi_2=%f\n', obj.x(i), obj.t, obj.xi_1, obj.xi_2);
%  					data = obj.exact_data(key);
%  					u(i) = data.u;
%  				else
%  					fprintf('Missing value for x=%f, t=%f, xi_1=%f, xi_2=%f\n', obj.x(i), obj.t, obj.xi_1, obj.xi_2);
%  					need_to_compute = true;
%  					break
%  				end
%  			end
			
			% If we have to, compute the solution and save all the data.
			if need_to_compute
				obj.calculate_exact_solution();
				u = obj.hires_problem.u;
				all_points = obj.hires_problem.export()
				
				for i=1:numel(obj.x)
					datapoint = all_points;
					datapoint.x = all_points.x(i);
					datapoint.u = all_points.u(i);
					key = obj.create_database_key(obj.x(i), obj.t);
					fprintf('Saving data for x=%f\n', obj.x(i))
					obj.exact_data(key) = datapoint;
				end
				
				data = obj.exact_data;
				save(obj.data_file, 'data');
			end
			
		end
		
		function status = save_exact_solution(obj)
			% Save the exact solution to disk to avoid
			% recomputing it for this grid and this value of t
			
			% Create an index 
			key = obj.create_database_key(obj.hires_problem.x, obj.hires_problem.t)
			if obj.exact_data.isKey(key)
				error('Solution has already been saved');
			else
				fprintf('Saving Data');
				obj.exact_data(key) = obj.export();
				data = obj.exact_data;
				save(obj.data_file, 'data');
			end
		end
		
		function calculate_exact_solution(obj)
			% Calculate the exact solution at time t
			
			% We don't have an exact solution for this problem, so
			% we're going to nest another object of this type
			% and configure it to perform a higher-order approximation.
			%
			% If this is the first time calling get_exact_solution()
			% make a copy of the current object and configure it
			% with our very best discretizer and integrator.
			% 
			if isempty(obj.hires_problem) & obj.is_nested == false
				obj.hires_problem = obj.copy();
				
				% Configure the numerical methods for this approximation
				dudx = SSP_Tools.Discretizers.WenoCore('kernel', 'WENO15');
				dudt = SSP_Tools.Integrators.ODE45();
				obj.hires_problem.set_discretizer(dudx);
				obj.hires_problem.set_integrator(dudt);
				obj.hires_problem.is_nested = true;
			elseif obj.is_nested == true
				% This is to catch the unlikely situation we're somoene
				% calls obj.hires_problem.calculate_exact_solution()
				% so we don't nest another instance.
				error('Too many turtles');
			end
			
			% To save work, we only calculate an exact solution
			% starting from the last time we were called. Check
			% to see how much obj.t has passed since then.
			time_difference = obj.t - obj.hires_problem.t;
			dx = obj.hires_problem.x(2) - obj.hires_problem.x(1);
			dt = 0.2*dx;
			
			% How many steps of length dt are there between obj.hires_problem.t
			% and obj.t?
			n_dt = floor(time_difference / dt);
			
			% Step forward.
			for k=1:n_dt
				t_remaining = obj.t - obj.hires_problem.t;
				if t_remaining < dt
					obj.hires_problem.step(t_remaining);
				else
					obj.hires_problem.step(dt);
				end
			end
		end
		
%  		function data = export(obj)
%  			% Export information about the problem, what we're doing with it
%  			% and what approximation we obtained in an independent format.
%  			%
%  			data.x = obj.x;
%  			data.u = obj.u;
%  			data.t = obj.t;
%  			data.fflux = func2str(obj.fflux);
%  			data.fsource = func2str(obj.fsource);
%  			
%  			% 'integrator' can be plain old function handle, so 
%  			% as always we have to treat this differently.
%  			if ~isa(obj.integrator, 'function_handle')
%  				data.integrator = obj.integrator.get_repr();
%  			else
%  				data.integrator = func2str(obj.integrator);
%  			end
%  			data.integrator = obj.integrator.get_repr();
%  			data.discretizer = obj.discretizer.get_repr();
%  			data.date = datestr(now);
%  		end
		
		
		function norm_error = error_norm(obj, norm_type)
			
			% Get the pointwise error
			pointwise_error = obj.calculate_error();

			% For convenience, create a norm function
			f = @(v) norm(v, norm_type);
			
			% And our scaling function
			if norm_type == 1
				mu = @(v) f(v) / length(v);
			elseif norm_type == 2
				mu = @(v) f(v) / sqrt(length(v));
			elseif isinf(norm_type)
				mu = @(v) f(v);
			else
				error('Invalid norm selection')
			end
		
			norm_error = mu(pointwise_error);
		end
	
		function parameters = get_parameters(obj)
		
			parameters = {};

			parameters{end+1} = struct('keyword', 'xi_1', ...
			                       'name', 'Contribution of flux term', ...
			                       'type', 'double', ...
			                       'options', [], ...
			                       'default', 1.0 );
			
			parameters{end+1} = struct('keyword', 'xi_2', ...
			                           'name', 'Contribution of source term', ...
			                           'type', 'double', ...
			                           'options', [], ...
			                           'default', 1.0 );
			
			parameters{end+1} = struct('keyword', 'discretizer', ...
			                       'name', 'Flux Discretizer', ...
			                       'type', 'SSP_Tools.Discretizers.Discretizer', ...
			                       'options', [], ...
			                       'default', [] );
			
			parameters{end+1} = struct('keyword', 'integrator', ...
			                       'name', 'Integrator for General Problem', ...
			                       'type', 'SSP_Tools.Integrators.Integrator',...
			                       'options', [], ...
			                       'default', [] );
			                       
			parameters{end+1} = struct('keyword', 'N', ...
			                       'name', 'Number of Gridpoints', ...
			                       'type', 'double',...
			                       'options', [], ...
			                       'default', 50 );
			
			parameters = [ parameters{:} ];
		
		end
		
		
	end
end