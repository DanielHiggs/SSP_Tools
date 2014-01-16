classdef ODE23S < SSP_Tools.Integrators.Integrator

	properties
	
		% Options for MATLAB's ODE solver
		ode_opts = []
	end

	methods
		function obj = ODE23S(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.addParamValue('AbsTol', []);
			p.addParamValue('RelTol', []);
			p.parse(varargin{:});
			obj	= obj@SSP_Tools.Integrators.Integrator(p.Unmatched);
			
			obj.name = 'Matlab''s ODE23S';
			obj.order = 5;
			
			obj.ode_opts = struct();
			if ~isempty(p.Results.AbsTol)
				obj.ode_opts.AbsTol = p.Results.AbsTol;
			end
			
			if ~isempty(p.Results.RelTol)
				obj.ode_opts.RelTol = p.Results.RelTol;
			end
			
			if obj.verbose
				obj.ode_opts.OutputFcn = @SSP_Tools.Integrators.ODE45.print_output;
			end
			
		end
	
		function [u_next,varargout] = advance(obj,u,t,dt)
			odefun = @(t,uu) obj.yPrimeFunc(uu,t);
			[t_, u_] = ode23s(odefun, [t,t+dt], u, odeset(obj.ode_opts));
			u_ = u_(end,:);
			u_next = u_';
			
			varargout{1} = 1;
			varargout{2} = ' ';
		end
		
		function repr_struct = get_repr(obj)
			% Get a machine-parsable representation of
			% this object
		
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			repr_struct.Options = obj.ode_opts;
		end
		
		function id_string = repr(obj)
			% Get a string-based representation of
			% this object
		
			repr_struct = obj.get_repr();
			
			opt_string = '';
			opt_fields = fieldnames(repr_struct.Options);
			for i=1:numel(opt_fields)
					field = opt_fields{i};
					value = repr_struct.Options.(field);
				if ~isempty(value)
					if isnumeric(value)
						opt_string = [ opt_string, sprintf('%s=%f ', field, value) ];
					elseif ischar(value)
						opt_string = [ opt_string, sprintf('%s=%s ', field, value) ];
					end
				end
			end
			
			id_fmt = '< %s : %s >';
			id_string = sprintf(id_fmt, repr_struct.Class, ...
			                            opt_string);
		end
		
		function parameters = get_parameters(obj)
			
			parameters = {};
			
			parameters{end+1} = struct( 'keyword', 'AbsTol', ...
			                            'name', 'Absolute Tolerance', ...
			                            'type', 'double', ...
			                            'options', [], ...
			                            'default', 1e-16 );
			
			parameters{end+1} = struct( 'keyword', 'RelTol', ...
			                            'name', 'Relative Tolerance', ...
			                            'type', 'double', ...
			                            'options', [], ...
			                            'default', 1e-16);
			                            
			parameters = [ parameters{:} ];
			
		end
		
	end
	
	methods(Static)
		function status = print_output(t, y, flag)
			fprintf('Calculating T=%3.2g\r', t);
			status = 0;
		end
	end
end