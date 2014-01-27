
Classes
=======

.. toctree::
	:maxdepth: 4
	:hidden:
	
	self


SSP_Tools.Integrators
---------------------

.. mat:class:: SSP_Tools.Integrators.Integrator('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

	Parent class for all Single- and Multistep Integration Methods for ODEs.

	:param callback yPrimeFunc(y): Function returning the value of :math:`y'=f(x)`
	:param callback yInFunc(y): Pre-processing function
	:param callback yOutFunc(y): Post-processing function
	:param Problem: Problem object
	:type Problem: SSP_Tools.TestProblems.TestProblem
	:param callback log(str): Logging function
	
	
	All descendents of this class have the following public attributes:
	
	.. mat:attribute:: name
	
		A descriptive name of the method including the values of any significant parameters it may have.

	.. mat:attribute:: order
	
		An integer value describing the linear order of the method.
	
	.. mat:attribute:: steps
	
		An integer value describing the number of steps used by the method. By convention, Runge-Kutta methods
		are single step methods.
	
	.. mat:attribute:: stages
	
		An integer value describing the number of stages used by the method. By convention, Multistep methods are
		are single stage methods.
	
	.. mat:attribute:: r
	
		The theoretical Strong Stablilty Preserving coefficient of the method. Empty if not applicable. 
		
	All descendents of this class have the following semi-private attributes
	
	.. mat:attribute:: log(str)
	
		A logging function called whenever the method needs to print diagnostic information to the console.
		
	.. mat:attribute:: yPrimeFunc(y,t)
	
		Called whenever the right hand side of the ordinary differential equation  or system of equations 
		:math:`y'=f(y,t)` needs to be evaluated. `y` is a column vector of values and `t` is a scalar.
	
	.. mat:attribute:: yInFunc(y)
	
		Optional pre-processing function. Called prior to integration with the function values `y`.
		
		This function is intended for situations where the function values may exist in a format or shape
		that is not a single column vector such as a two-dimensional PDE where `y` might be stored in a matrix.
		In that scenerio, `yInFunc` might be used to reshape `y` into a stacked column vector. 
		
	.. mat:attribute:: yOutFunc(y)
	
		Optional post-processing function. Called after integration with the function values `y` provided as a
		single column vector.
		
		This function is intended for situations where the function values may exist in a format or shape
		that is not a single column vector such as a two-dimensional PDE where `y` might be stored in a matrix.
		In that scenerio, `yOutFunc` might perform the inverse of `yInFunc` and reshape the stacked column
		vector into whatever native form `y` exists in outside of this class.
	
	.. mat:attribute:: solver
	
		SSP_Tools.utils.Solver object. Used by methods that need to perform an implicit solve.
	
	.. mat:attribute:: ProblemObject
	
		SSP_Tools.TestProblems.TestProblem object. Used by methods that need greater access and information
		about the problem they're integrating. 
		
		Under normal circumstances, an Integrator object only works with a PDE after it has been transformed into
		an ODE system using the Method of Lines and has no knowledge or control over the spatial discretization.
		However, some clever methods may need to know what's going on in space. The easiest way to do this
		(for now) is to allow for a backreference to a TestProblem object. 
		
		Currently, the only method that uses this is SSP_Tools.Integrators.DWRK which needs access to 
		the discretizer in order to obtain a downwinded approximation of the spatial derivative.
		
	All descendents of this class have the following public methods
	
	.. mat:method:: step(y,t,dt)
	
		Starting with the initial value `y` at time `t`, integrate to time `t+dt`
		
	.. mat:method:: copy()
	
		Return a nearly exact copy of the Integrator object minus any stateful information.
		
	All descendents of this class have the following semi-private methods
	
	.. mat:method:: warn(varargin)
	
		Raise a warning that the method has done something that could affect accuracy or performance.
		
		:mat:class:`SSP_Tools.Integrators.MSRK` methods will do this to notify the user in situations where the stepsize (dt)
		has changed.

RK3
+++

.. class:: SSP_Tools.Integrators.RK3('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

	Third order SSP Runge-Kutta Method. Also known as SSP(3,3).
	
	This is a simple class that is NOT a descendent of :mat:class:`SSP_Tools.Integrators.RK` and may be used
	as a quick reference for how Integrators may be written.
	
	See :mat:class:`SSP_Tools.Integrators.Integrator` for a description of the constructor's parameters.

RK
++

.. class:: SSP_Tools.Integrators.RK

	Class implementing generic Runge-Kutta methods.
	
	This class has two constructors: 
	
	.. mat:method:: RK(name, <desc>, 'A', <mat>, 'B', <vec>, 'C', <vec>)
	
		Initialize an RK object from Butcher Tableau coefficients provided by the parameters `A`, `B`, and `C`.
		The `name` parameter sets the :mat:attribute:`name` attribute of the object.
	
	.. mat:method:: RK('coefficients', <file>)
	
		Initialize an RK object from Butcher Tableau coefficients stored in `file` which has `A`, `B`, `C` and
		`name` are saved within. 
		
	See :mat:class:`SSP_Tools.Integrators.Integrator` for a complete description of these constructors' parameters.
	
	Attributes
	
	.. mat:attribute:: alpha
	
		The matrix part of a Butcher Tableau containing the :math:`a_{ij}` coefficients. 
		This matrix is lower-triangular if the method is explicit.
	
	.. mat:attribute:: b
	
		The vector part of a Butcher Tableau containing the :math:`b_i` coefficients.
	
	.. mat:attribute:: c
	
		The vector part of a Butcher Tableau containing the :math:`c_i` coefficients.
	
	.. mat:attribute:: isExplicit
	
		`true` if the Runge-Kutta method is explicit. `false` otherwise.
	
	.. mat:attribute:: kron_products
	
		When :mat:meth:`advance` is first called, the `A`, `B`, and `C` coefficient vectors are replaced
		by the kronnecker products :math:`A \otimes I`, :math:`B \otimes I`, and :math:`C \otimes I` where 
		:math:`I` is a sparse :math:`(n\times{n})` identity matrix and :math:`n = length(y)`. The resulting
		matrices are stored as a structure in :mat:attr:`kron_products` and are not recomputed on successive
		calls to :mat:meth:`advance`.
		
		This allows for more straightforward vectorized operations when computing the :math:`k_i` values,
		especially if `y` represents a system of ODEs derived from a discretization of a PDE or the
		Runge-Kutta method is implicit. 
		
		:mat:attr:`kron_products` is considered a stateful variable and thus not copied when 
		:mat:meth:`copy` is called on this object.
	
	.. mat:method:: advance(y, t, dt)
		
		This method is called by :mat:meth:`SSP_Tools.Integrators.Integrator.step`
		
		Starting with an initial condition `y(t)`, compute an approximation of the ODE at `y(t+dt)`.
		
		
	
		
	
RK4
+++

.. class:: SSP_Tools.Integrators.RK4('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

	Classical fourth order Runge-Kutta method. Descendent of :mat:class:`SSP_Tools.Integrators.RK`.

	See :mat:class:`SSP_Tools.Integrators.Integrator` for a description of the constructor's parameters.

RK5
+++

.. class:: SSP_Tools.Integrators.RK5('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

	Fifth order Runge-Kutta method. Non-SSP.

	See :mat:class:`SSP_Tools.Integrators.Integrator` for a description of the constructor's parameters.

RK6
+++

.. class:: SSP_Tools.Integrators.RK6('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

	Sixth order Runge-Kutta method. Non-SSP.

	See :mat:class:`SSP_Tools.Integrators.Integrator` for a description of the constructor's parameters.


RK7
+++

.. class:: SSP_Tools.Integrators.RK7('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

	Seventh order Runge-Kutta method. Non-SSP.

	See :mat:class:`SSP_Tools.Integrators.Integrator` for a description of the constructor's parameters.

RK8
+++

.. class:: SSP_Tools.Integrators.RK7('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

	Eighth order Runge-Kutta method. Non-SSP.

	See :mat:class:`SSP_Tools.Integrators.Integrator` for a description of the constructor's parameters.

SSPRK
+++++

ODE23S
++++++

ODE45
+++++

SSP104
++++++

BackwardEuler
+++++++++++++

LNL
+++

MSRK
++++


SSP_Tools.Discretizers
----------------------

FiniteDifference
++++++++++++++++

KorenLimiter
++++++++++++

Spectral
++++++++

WenoCore
++++++++


SSP_Tools.TestProblems
----------------------

.. mat:class:: SSP_Tools.TestProblems.TestProblem




.. mat:class:: SSP_Tools.TestProblems.ODE

.. mat:method:: step(dt)

	Advance the `ODE` by a single time step of `dt`.

.. mat:method:: approximate( t, 'dt'=<float>, ['tolT'=1e-15] )

	Advance the `ODE` to to within `tolT` of `t` using increments of `dt`.

.. mat:class:: SSP_Tools.TestProblems.PDE

.. mat:method:: step(dt)

	Advance the `PDE` by a single time step of `dt`.


.. mat:method:: approximate( t, ['dt'|'cfl'=0.2], ['tolT'=1e-15] )

	Advance the `PDE` to within `tolT` of `t`.
	
	If both `dt` and `cfl` are unspecified, the approximation will be performed using steps 
	of size :math:`\Delta{t}=0.2\Delta{x}`. 

Dalquist
++++++++

LinearODE
+++++++++

NonLinearODE
++++++++++++

StiffODE
++++++++

Vanderpol
+++++++++

Advection
+++++++++

BuckleyLeverett
+++++++++++++++

Burgers
+++++++

SSP_Tools.Tests
---------------

Approximation
+++++++++++++

ConvergenceODE
++++++++++++++

ConvergencePDE
++++++++++++++

Positivity
++++++++++

SSP
+++

Animation
+++++++++


SSP_Tools.Factories
-------------------

IntegratorFactory
+++++++++++++++++

ProblemFactory
++++++++++++++

TestFactory
+++++++++++

