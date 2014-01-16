classdef ConvectionReactionU < SSP_Tools.TestProblems.ConvectionReactionPDE

	properties
	end
	
	methods
		function obj = ConvectionReactionU(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:})
			
			params = p.Unmatched;
			params.name = 'Convection-Reaction Equation u_t + \xi_1(0.5u)_x = \xi_2u';
			params.domain = [-1, 1];
			params.data_file = 'ConvectionReactionU.mat';
			params.initial_condition = @(x) sin(pi*x);
			
			obj = obj@SSP_Tools.TestProblems.ConvectionReactionPDE(params)
		end
	end
	
	methods(Static)
		function flux = fflux(u)
			flux = -0.5*u.^2;
		end
		
		function source = fsource(u)
			source = u;
		end
		
		function em = em(u)
			em = max(abs(u));
		end
		
	end

end