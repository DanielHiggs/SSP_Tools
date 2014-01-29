classdef WenoCore < SSP_Tools.Discretizers.Discretizer
% This class provides an interface between the SSP_Tools and WenoCore packages
% 
	properties
		
		% This is the corresponding kernel function in WenoCore
		% we're calling
		kernel = [];
		
		% This is the weno function we're calling. For now this is always
		% WenoCore.weno_basic(), but at a later date this might be a
		% different function that might perform weno approximations in
		% parallel.
		weno_fcn = [];
		
		% The number of ghost points needed.
		gp = [];
		
		% A cached copy of the grid-spacing
		dx = [];
		
		% Epsilon parameter.
		epsilon = [];
		
		% p parameter.
		p = [];
				

	end
		
	methods
		
		function obj = WenoCore(varargin)
			obj = obj@SSP_Tools.Discretizers.Discretizer(varargin{:});
			
			p = inputParser;
			p.addParamValue('em', []);
			p.addParamValue('epsilon', 1e-16);
			p.addParamValue('p', 2);
			p.addParamValue('kernel', []);
			p.addParamValue('weno_fcn', @WenoCore.weno_basic);
			p.parse(varargin{:});
			
			obj.epsilon = p.Results.epsilon;
			obj.p = p.Results.p;
			
			if ~isempty(p.Results.em)
				obj.em = p.Results.em;
			end
			
			if ~isempty(p.Results.kernel)
				obj.select_kernel(p.Results.kernel);
			end
			
			if ~isempty(p.Results.weno_fcn)
				obj.select_weno(p.Results.weno_fcn);
			end
			
			obj.name = sprintf('WENO%d', obj.order);
			
		end
		
		function select_weno(obj, weno_fcn)
			obj.weno_fcn = weno_fcn;
		end
		
		function select_kernel(obj, kernel)
			% This function selects which of the WENO routines in
			% the WenoCore package we're using.
			
			kernel = upper(kernel);
			
			if strcmp(kernel, 'WENO5')
				obj.kernel = @WenoCore.kernels.weno5;
				obj.gp = 4;
				obj.order = 5;
			elseif strcmp(kernel, 'WENO9')
				obj.kernel = @WenoCore.kernels.weno9;
				obj.gp = 6;
				obj.order = 9;
			elseif strcmp(kernel, 'WENO11')
				obj.kernel = @WenoCore.kernels.weno11;
				obj.gp = 7;
				obj.order = 11;
			elseif strcmp(kernel, 'WENO13')
				obj.kernel = @WenoCore.kernels.weno13;
				obj.gp = 8;
				obj.order = 13;
			elseif strcmp(kernel, 'WENO15')
				obj.kernel = @WenoCore.kernels.weno15;
				obj.gp = 9;
				obj.order = 15;
			else
				error('Unknown Kernel Specified');
			end
		end
		
		
		function u_x = L(obj, x, u, t)
		
			% If we don't know the grid spacing, get the grid spacing
			if isempty(obj.dx)
				obj.dx = x(2) - x(1);
			end
			
			% Calculate em
			em = obj.em(u);
		
			% Append ghost points
			u_gp = [ u(end-obj.gp:end-1), u, u(2:obj.gp+1) ];
			u_x = obj.weno_fcn(obj.dx, u_gp, t, obj.f, em, obj.epsilon, obj.p, obj.kernel, obj.gp)';
			
		end
		
		
		function clone = copy(obj)
			meta = metaclass(obj);
			clone = eval([ meta.Name, '()' ]);
			
			ignored_fields = {'dx'};
			
			props = fieldnames(obj);
			for i=1:numel(props)
				if ~any( strcmp(props{i}, ignored_fields) )
					clone.(props{i}) = obj.(props{i});
				end
			end
		end
		
		function repr_struct = get_repr(obj)
			repr_struct = struct();
			
			% Get the name of our class
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			
			% Get the kernel function
			repr_struct.Kernel = ['@', func2str(obj.kernel)];
			
			% Get the weno function
			repr_struct.WenoFunction = ['@', func2str(obj.weno_fcn)];
			
			repr_struct.Epsilon = obj.epsilon;
			repr_struct.P = obj.p;
			
		end
		
		function parameters = get_parameters(obj)
			% Return a structure array of parameters accepted by this
			% class so that user-interfaces might be informed.
			
			package_info = meta.package.fromName('WenoCore.kernels');
			available_kernels = {};
			for i=1:numel(package_info.Functions)
				kernel_name = package_info.Functions{i}.Name;
				
				% Assume that weno kernels are 'wenoX' or 'wenoXX' where
				% X and XX refer to their order
				kernel_order = str2num(kernel_name(5:end));
				available_kernels{end+1} = struct('name', kernel_name, ...
				                                  'order', kernel_order );
			end
			
			available_kernels = [available_kernels{:}];
			
			parameters = {};
			
			parameters{end+1} = struct('keyword', 'kernel', ...
			                           'name', 'Weno Kernel', ...
			                           'description', 'Describes the weno method', ...
			                           'type', 'kernel-list', ...
			                           'options', {available_kernels}, ...
			                           'default', 'weno5' );
			
			parameters{end+1} = struct('keyword', 'epsilon', ...
			                           'name', 'smoothness parameter', ...
			                           'description', 'WENO methods use epsilon to prevent a divide-by-zero', ...
			                           'type', 'double', ...
			                           'options', [], ...
			                           'default', 1e-16 );
			
			parameters{end+1} = struct('keyword', 'p', ...
			                           'name', 'other smoothness parameter', ...
			                           'description', 'blah blah blah', ...
			                           'type', 'double', ...
			                           'options', [], ...
			                           'default', 2 );
			                           
			                           
			parameters = [parameters{:}];
		end
		
		function id_string = repr(obj)
			% Provide a textual representation of the object
			% that a human can use to identify it
			
			repr_struct = obj.get_repr();
			
			id_fmt = '< %s: call=%s kernel=%s epsilon=%g p=%i >';
			
			id_string = sprintf(id_fmt, repr_struct.Class, ...
			                            repr_struct.WenoFunction, ...
			                            repr_struct.Kernel, ...
			                            repr_struct.Epsilon, ...
			                            repr_struct.P);
		end
		
		
		function name = get_name(obj)
			repr = obj.get_repr();
			
			kernel_name = regexp(repr.Kernel, 'kernels\.(.*)', 'tokens');
			kernel_name = kernel_name{1};
			kernel_name = upper(kernel_name{1});
			name = sprintf('%s epsilon=%g p=%d', kernel_name, repr.Epsilon, repr.P);
		end
	end
	
end