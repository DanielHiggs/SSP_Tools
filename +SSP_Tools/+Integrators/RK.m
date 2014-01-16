classdef RK < SSP_Tools.Integrators.Integrator
%
% Class: RK
% 
% This class provides a generic implementation of explicit and implicit
% Runge-Kutta methods.
% 
% None of the methods in this class are public. All of the public methods
% are defined in NumericalMethod.m
% 
% Configuration keywords:
% 
%     coefficients          filename of a MATLAB datafile containing the
%                           method coefficients in Butcher form. [string]
% 
	properties
		alpha = [];
		b = [];
		c = [];
		isExplicit = [];   
		
		kron_products = [];
		
		% File (if provided) containing the coefficients used
		% to construct the method.
		file = [];
		
		% This directory contains MATLAB data files specifying the above
		% coefficients.
		coefficient_directory = [];
		
	end
		
	methods
		
		function obj = RK(varargin)

			obj = obj@SSP_Tools.Integrators.Integrator(varargin{:});

			p = inputParser;
			p.KeepUnmatched = true;
			addParamValue(p,'coefficients', false);
			addParamValue(p,'A', []);
			addParamValue(p,'B', []);
			addParamValue(p,'C', []);
			addParamValue(p,'name', []);
			p.parse(varargin{:});

			
			% Load the coefficients if specified.
			if isstr(p.Results.coefficients)
				% A coefficients file has been specified. Try to load
				% the appropriate coefficients from this file.
				obj.file = p.Results.coefficients;
				
				parameters = load(obj.file);
				
				if isfield(parameters, 'A')
					obj.alpha = parameters.A;
				else
					error('A coefficient not found');
				end
				
				if isfield(parameters, 'B')
					obj.b = parameters.B;
				else
					error('B coefficient not found');
				end
				
				if isfield(parameters, 'C')
					obj.c = parameters.C;
				else
					obj.c = sum(obj.alpha, 2);
				end
				
				path_cutoff = strfind(obj.file, '/');
				if ~isempty(path_cutoff)
					obj.name = obj.file(path_cutoff(end)+1:end);
				else
					obj.name = obj.file;
				end
				
			elseif ~isempty(p.Results.A) && ~isempty(p.Results.B)
				obj.alpha = p.Results.A;
				obj.b = p.Results.B;
				obj.c = p.Results.C;
				obj.name = p.Results.name;
			end

			% Check if the method is explicit
			if obj.isExplicitMethod()
				obj.isExplicit = true;
			else
				obj.solver = SSP_Tools.utils.MatlabSolver();
			end
		end
		
		function [y_next, varargout] = advance(obj,y,t,dt)
			%
			% Advance the numerical solution u(x,t) to u(x,t+dt)
			% 
			% This method is automatically called by the step() method in the
			% NumericalMethod class. 
			% 
			
			n = length(y);
			s = size(obj.alpha,1);
			
			if isempty(obj.kron_products)
			
				alpha = sparse(obj.alpha);
				b = sparse(obj.b);
				v = sparse(ones(size(alpha,1),1 ));
			
				obj.kron_products.ALPHA = kron(alpha, speye(n));
				obj.kron_products.B = kron(b, speye(n));
				obj.kron_products.V = kron(v, speye(n));
			end
			
			ALPHA = obj.kron_products.ALPHA;
			B = obj.kron_products.B;
			V = obj.kron_products.V;
			
			T = t;
			
			if obj.isExplicitMethod()
				% The method we have is explicit. Solve accordingly.
				k = zeros(s*n, 1);
				kP = zeros(s*n, 1);
				for i=1:s
					block = (i-1)*n+1:i*n;
					k(block) = y + dt*ALPHA(block,1:block(end))*kP(1:block(end));
					kP(block) = obj.yPrimeFunc(k(block), t + dt*obj.c(i) );
				end
				block = s*n+1:(s+1)*n;
				y_next = y + dt.*(B*kP);
				
				varargout{1} = 1;
				varargout{2} = ' ';
			else
				% The method is implicit
				f =  @(k) k - (V*y) - dt*ALPHA*obj.yPrimeFunc(k,t);
				y0 = [y; repmat(zeros(n,1), size(alpha,1)-1,1)];
				[k,FVAL,EXITFLAG,OUTPUT] = obj.solver.call(f, y0);
	
				if EXITFLAG ~= 1
					y_next = y;
					varargout{1} = EXITFLAG;
					varargout{2} = OUTPUT.message;
					return
				end

				y_next = y + dt*(B*obj.yPrimeFunc(k,t));
				varargout{1} = 1;
				varargout{2} = sprintf('Iter: %i, fEval %i', OUTPUT.iterations, OUTPUT.funcCount);
			end
			

		end

		function clone = copy(obj)
			meta = metaclass(obj);
			clone = eval([ meta.Name, '()' ]);
			
			ignored_fields = {'kron_products'};
			
			props = fieldnames(obj);
			for i=1:numel(props)
				if ~any( strcmp(props{i}, ignored_fields) )
					clone.(props{i}) = obj.(props{i});
				end
			end
		end
		
		function parameters = get_parameters(obj)
		
			parameters = {};
			coefficient_parameter.keyword = 'coefficients';
			coefficient_parameter.name = 'Coefficient File';
			coefficient_parameter.type = 'file_list';
			if ~isempty(obj.coefficient_directory) & exist(obj.coefficient_directory, 'dir')
				files = dir([obj.coefficient_directory, '/*.mat']);
				coefficient_parameter.options = struct( 'path', obj.coefficient_directory,...
				                                        'files', {{files.name}});
			else
				coefficient_parameter.options = [];
			end
			
			coefficient_parameter.default = [];
			
			parameters{end+1} = coefficient_parameter;
			
			parameters = [ parameters{:} ];
			
		end
		
		function repr_struct = get_repr(obj)
			% Get a machine readable representation of this
			% class
			
			objclass = metaclass(obj);
			repr_struct.Class = objclass.Name;
			
			repr_struct.A = obj.alpha;
			repr_struct.B = obj.b;
			repr_struct.C = obj.c;
			
			repr_struct.Name = obj.name;
			
			repr_struct.File = obj.file;
			
			if ~isempty(obj.file)
				[status, md5sum] = system(['md5 -q ', sprintf('"%s"', obj.file)]);
				repr_struct.Md5 = md5sum;
			else
				repr_struct.Md5 = [];
			end
			
			
		end
		
		function id_string = repr(obj)
			% Provide a textual representation of the object
			% that a human can use to identify it
			
			repr_struct = obj.get_repr();
			
			id_fmt = '< %s: %s >';
			id_string = sprintf(id_fmt, repr_struct.Class, ...
			                            repr_struct.Name );
			
		end
		
		function t = isExplicitMethod(obj)
			%
			% Check whether the method is explicit.
			% 
			% Returns true if the Runge-Kutta method is explicit and caches the
			% result in obj.isExplicit. Successive calls will forego the test
			% and return the result stored in this variable.
			%
			
			if ~isempty(obj.isExplicit) && obj.isExplicit == true
				t = true;
				return
			end
			
			
			% Exception for forward euler
			if length(obj.alpha) == 1 & obj.alpha == 0
				t = true;
				return
			end
			
			
			t = true;
			i = 0;
			while true
				diagonal = diag(obj.alpha, i);
				if isempty(diagonal)
					break;
				end
				
				if all(diagonal == 0)
					i=i+1;
					continue;
				else
					t = false;
					return;
				end
			end
		end
	end
end