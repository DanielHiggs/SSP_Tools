classdef ConvectionReactionUsquared < SSP_Tools.TestProblems.ConvectionReactionPDE

	properties
	end
	
	methods
		function obj = ConvectionReactionUsquared(varargin)
			p = inputParser;
			p.KeepUnmatched = true;
			p.parse(varargin{:})
			
			params = p.Unmatched;
			params.name = 'Convection-Reaction Equation u_t + \xi_1u_x = \xi_2u^2';
			params.domain = [-1, 1];
			params.data_file = 'ConvectionReactionUsquared.mat';
			params.initial_condition = @(x) sin(pi*x);
			
			obj = obj@SSP_Tools.TestProblems.ConvectionReactionPDE(params)
		end
	end

	methods(Static)
		function flux = fflux(u)
			flux = -u;
		end
		
		function source = fsource(u)
			source = u.^2;
		end
		
		function em = em(u)
			em = max(abs(u));
		end
		
	end

end