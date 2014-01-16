classdef Vanderpol < SSP_Tools.TestProblems.ODE

	properties
		epsilon = [];
	end
	
	methods
	
		function obj = Vanderpol(varargin)
		
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('epsilon', []);
			p.parse(varargin{:});
			
			params = p.Unmatched;
			params.name = 'Vanderpol y''=2y';
			params.initial_condition = [0.5; 0];
			params.initial_time = 0.0;
			
			obj = obj@SSP_Tools.TestProblems.ODE(params);
			
			if ~isempty(p.Results.epsilon)
				obj.epsilon = p.Results.epsilon;
			end
			
			obj.setup_problem();
		
		end
		
		function yp = y_p(obj, y,t)
			yp = [y(2);obj.epsilon*((1-(y(1))^2)*y(2))-y(1)];
		end
		
		function y_exact = get_exact_solution(obj, varargin)
		
			if length(varargin) > 0
				t = varargin{1};
				tspan = [obj.domain, t];
			else
				tspan = obj.t;
			end
					
			ode_params = odeset('AbsTol', 1e-14, 'RelTol', 1e-13);
			[t_out, y_exact] = ode45( @(y,t) obj.y_p(t,y), tspan, obj.initial_condition, ode_params);
			y_exact = y_exact';
			
			if length(varargin) > 0
				y_exact = y_exact(:,end);
			end
		end
		
		function repr_struct = get_repr(obj)
			% Get a machine readable representation of this
			% class
			
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			repr_struct.IC = obj.y(:,1);
			repr_struct.t0 = obj.t(1);
			repr_struct.t = obj.t(end);
			repr_struct.epsilon = obj.epsilon;
		end
		
		function id_string = repr(obj)
			
			repr_struct = obj.get_repr();
			id_fmt = '< %s: y(%g)=%s epsilon=%g t=%g >';
			
			ic_string = sprintf('[ %s]', sprintf('%3.2f ', repr_struct.IC));
			
			id_string = sprintf(id_fmt, repr_struct.Class, ...
			                            repr_struct.t0, ...
			                            ic_string, ...
			                            repr_struct.epsilon, ...
			                            repr_struct.t );
		
		end
		
		function parameters = get_parameters(obj)
		
			parameters = {};
			
			parameters{end+1} = struct('keyword', 'epsilon', ...
			                           'name', 'Epsilon Parameter', ...
			                           'type', 'double', ...
			                           'options', [], ...
			                           'default', 0.1 );
			
			parameters{end+1} = struct('keyword', 'integrator', ...
			                       'name', 'Time Stepping Integrator', ...
			                       'type', 'SSP_Tools.Integrators.Integrator',...
			                       'options', [], ...
			                       'default', [] );
		
			parameters = [ parameters{:} ];
		
		end	
		
		
	end

end