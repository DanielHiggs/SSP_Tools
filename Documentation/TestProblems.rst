

.. mat:module:: SSP_Tools.TestProblems

This module includes all the available test problems.


.. mat:class:: SSP_Tools.TestProblems.TestProblem

	This is the parent class for all the example problems in ``SSP_Tools``. It defines
	a basic interface that allows you to easily obtain approximations using a variety
	of numerical schemes.

	This is just a subset of available routines. Individual problems may extend this 
	interface with additional functions that perform tasks specific to that that
	problem. However, any script that exclusively calls these functions is garanteed to
	work with any problem whether it is an ODE or PDE.
	
	.. mat:method:: approximate(t, varargin)
		
		:param dt: time step increment
		:type dt: double
		:rtype: none
		
		Approximate the solution of the example problem at time `t`. 
		
		If no additional arguments are provided, the value of :math:`\Delta{t}` used 
		to step the approximation forward will be determined by the problem using sensible
		defaults.
		
		If a value is specified for `dt`, that value will be taken as :math:`\Delta{t}`.
		
	.. mat:method:: step(dt)
		
		Approximate the solution of the example problem at time :math:`t+\Delta{t}`
	
	.. mat:method:: get_domain(varargin)
	
		Returns the domain of the function.

	.. mat:method:: get_approximation(varargin)
	
		Returns the approximation of the example problem at the current time.
	
	.. mat:method:: get_exact_solution(varargin)
	
		Returns the exact solution of the example problem at the current time.
	
	.. mat:method:: get_error()
	
		Returns the pointwise error of the approximation at the current time.
	
	.. mat:method:: plot(varargin)
		
		:param with_exact: If true, overlay the exact solution
		:type with_exact: boolean
	
		Return a plot of the approximation at the current time. 
		
		This is a convenience function for quickly plotting solutions 
		without having to worry about the type of problem or the shape
		of the domain.
	
	.. mat:method:: copy()
	
		Return a copy of the example problem object regressed to its initial state.
	
	.. mat:method:: export(varargin)
	
		Return a MATLAB data structure containing a platform independent
		representation of this object suitable for archiving to disk.
	
	.. mat:method:: repr()

		Return a string representation of this object.
	
	.. mat:method:: get_repr()

		Return a MATLAB data structure representation of this object.
		

Ordinary Differential Equations
-------------------------------
		
.. mat:class:: SSP_Tools.TestProblems.ODE(varargs)
	
	Base class for all test problems that are Ordinary Differential Equations.
	
	.. mat:attribute:: y_p
	
		A MATLAB function handle that represents the right hand side of the ODE equation (or system
		of equations) as :math:`y'(y,t)=` y_p(y,t)
	
	.. mat:attribute:: initial_condition
	
		The value of :math:`y(t_0)` . This can either be a scalar value or a vector-value in the case
		of systems of ODE equations.
	
	.. mat:attribute:: domain
	
		Contains the intial value of :math:`t_0` where the initial condition is valid.
	
	.. mat:attribute:: integrator
	
		An `SSP_Tools.Integrators.Integrator` object that will perform the time-stepping necessary
		for approximating the solution at :math:`t>t_0`.
	
	.. mat:attribute:: t
	
		Current value of the independent variable :math:`t`
	
	.. mat:attribute:: y
	
		Current value of the dependent variable :math:`y`
		
	.. mat:attribute:: data_file 
	
		File where difficult computations are cached to disk.
	
	.. mat:attribute:: exact_data

		containers.Map object containing the solutions to difficult computations.
		
		
Partial Differential Equations
------------------------------
		
		
.. mat:class:: SSP_Tools.TestProblems.AdvectionLeftToRight(varargs)

.. mat:class:: SSP_Tools.TestProblems.AdvectionRightToLeft(varargs)

.. mat:class:: SSP_Tools.TestProblems.AdvectionLeftToRight(varargs)

.. mat:class:: SSP_Tools.TestProblems.AdvectionLeftToRight(varargs)

.. mat:class:: SSP_Tools.TestProblems.AdvectionLeftToRight(varargs)

.. mat:class:: SSP_Tools.TestProblems.AdvectionLeftToRight(varargs)




	
