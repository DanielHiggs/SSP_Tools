
Classes
=======

.. toctree::
	:maxdepth: 4
	:hidden:
	

SSP_Tools.Integrators
---------------------

.. mat:class:: SSP_Tools.Integrators.Integrator

	Parent class for all Single- and Multistep Integration Methods for ODEs.
	
	.. mat:method:: Integrator('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])
	
		Construct an :mat:class:`SSP_Tools.Integrators.Integrator` object.
		
		``yPrimeFunc`` ODE function. Callback that accepts a single vector argument containing the current
		function values :math:`y` and returns a single vector containing the value of :math:`y'`. 
		
		``yInFunc`` (optional) Pre-processing function. Callback that accepts a single argument containing
		function values :math:`y` in any format and returns them as a stacked column vector. See :mat:attr:`yInFunc`
		for a complete description.
		
		``yOutFunc`` (optional) Post-processing function. Callback that accepts a single argument containing
		the values of :math:`y` as a stacked column vector and returns them in whatever format is desired. This
		callback should perform the inverse of ``yInFunc``. See :mat:attr:`yOutFunc` for a complete discussion.
	
		``Problem`` (optional) :mat:class:`SSP_Tools.TestProblems.TestProblem` object. Some specialized 
		integration routines might need additional information/control over the problem. See :mat:attr:`ProblemObject`
		for more information.
	
		``log`` (optional) Logging callback. The ``Integrator`` object may elect to provide useful warnings
		or information to the console via :mat:func:`fprintf` while it is running. If this callback is provided
		that output can be redirected to a different function that could include it in an overall logging 
		facility. The callback should have the same signature as :mat:func:`sprintf`. 
		
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
		
	All descendents of this class have the following public methods
	
	.. mat:method:: step(y,t,dt)
	
		Starting with the initial value `y` at current time `t`, integrate to time `t+dt` and return the new
		value of :math:`y(t+\Delta{t})`. 
		
		This may be placed within a loop to step an ODE or PDE forward.
		
		By default, `y` is a column vector, and the function returns a single column vector, though it is 
		possible to provide it in any shape or format provided that :mat:attr:`yInFunc` and :mat:attr:`yOutFunc` 
		have been set with callbacks to appropriate routines to reformat `y` into a column vector and transform 
		the integrated output back to whatever 'native' format `y` was originally in. See Using 2d Domains. 
		
		`t` must be a scalar number. It is up to whatever is calling :mat:meth:`step`
		to provide a value of `t` that fits the current problem, and no protection is provided against :mat:meth:`step`
		being called with a value of `t` that is less than what it was previously called with.
		
		This is a public wrapper for the private :mat:meth:`advance` method that performs the actual integration.
		
	.. mat:method:: copy()
	
		Return a new copy of the ``Integrator`` object minus any stateful information.
		
		This can be used to get an exact copy of the object for use in integrating a different problem.
		
	.. mat:method:: repr()
	
		Return a formatted text string representation of the object containing information about the 
		current `Integrator` and the parameters it was configured with. 
		
	.. mat:method:: get_parameters()
	
		Return an ordered structure array describing the method-specific arguments needed by the constructor.
		
		========  =====================================================
		field     description
		========  =====================================================
		keyword   The name of the argument received by the constructor
		type      The type of argument that's expected
		name      A shorthand name for the argument
		longname  A longer description of the argument
		options   Some options governing the selection of arguments
		default   A sensible default value for the argument
		========  =====================================================
		
		For a full discussion about writing a user interface for ``SSP_Tools``, see
		TestSuite 

	All ``Integrator`` objects also have the these private methods:
		
	.. mat:attribute:: log(varargin)
	
		A logging function called whenever the method needs to print diagnostic information to the console.
		The signature of this function matches those of :mat:func:`sprintf`. 
		
	.. mat:attribute:: yPrimeFunc(y,t)
	
		Called whenever the right hand side of the ordinary differential equation  or system of equations 
		:math:`y'=f(y,t)` needs to be evaluated. `y` is a column vector of values and `t` is a scalar.
	
	.. mat:attribute:: yInFunc(y)
	
		Optional pre-processing function to reformat the `y` passed to :mat:meth:`step` into a stacked column vector prior to being 
		passed to :mat:meth:`advance`. 
		
		This function is intended for situations where the function values may exist in a format or shape
		that is not a single column vector such as a two-dimensional PDE where `y` might be stored in a matrix.
		
		See Using 2d Domains
		
	.. mat:attribute:: yOutFunc(y)
	
		Optional post-processing function to reformat the stacked column vector returned by :mat:meth:`advance`
		into the desired format to be returned by :mat:meth:`step`.
		
		This function is intended for situations where the function values may exist in a format or shape
		that is not a single column vector such as a two-dimensional PDE where `y` might be stored in a matrix.
	
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
		

		
	All descendents of this class have the following semi-private methods
	
	.. mat:method:: warn(varargin)
	
		Raise a warning that the method has done something that could affect accuracy or performance.
		
		:mat:class:`SSP_Tools.Integrators.MSRK` methods will do this to notify the user in situations where the stepsize (dt)
		has changed.
		
	.. mat:method:: advance(y, t, dt)
	
		Perform the actual integration to calculate an approximation of :math:`y(t+\Delta{t})`.
		
		This method is undefined in the parent class and left for descendents to implement.

RK3
+++

.. class:: SSP_Tools.Integrators.RK3

	Third order SSP Runge-Kutta method. Synonymous with SSP(3,3).
	
	This class is a descendent of :mat:class:`SSP_Tools.Integrators.Integrator`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: RK3('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])
	
		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Integrators.Integrator`
	
	Unlike the other classes implementing specific Runge-Kutta methods, this is a simple class that is 
	**not** a descendent of :mat:class:`SSP_Tools.Integrators.RK` and may be used as a quick reference for 
	how Integrators may be written.
	

RK
++

.. class:: SSP_Tools.Integrators.RK

	Parent class for implementing generic Runge-Kutta methods.
	
	This class is a descendent of :mat:class:`SSP_Tools.Integrators.Integrator`. For a full description
	of object attributes and methods see the documentation for the parent class.
	
	This class has two constructors: 
	
	.. mat:method:: RK(name, <>, 'A', <>, 'B', <>, 'C', <>, 'yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>)
	
		Initialize an RK object from Butcher Tableau coefficients provided by the parameters `A`, `B`, and `C`.
		The `name` parameter sets the :mat:attr:`name` attribute of the object.
		
	.. mat:method:: RK('coefficients', <file>, 'yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>)
	
		Initialize an RK object from Butcher Tableau coefficients stored in `file` which has `A`, `B`, `C` and
		`name` are saved within. 
		
	See :mat:class:`SSP_Tools.Integrators.Integrator` for a complete description of these constructors' parameters.

	.. note::
	
		Neither of these constructors set :mat:attr:`SSP_Tools.Integrators.Integrator.r`. If the SSP coefficient
		`r` is known, the attribute needs to be set after the object has been created.
		
	
	In addition to those provided by :mat:class:`SSP_Tools.Integrators.Integrator`, this class has the following
	attributes:
	
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
	
		When :mat:meth:`advance` is first called, the :math:`A`, :math:`B`, and :math:`C` vectors from the
		Butcher Tableau are used to form the kronnecker products :math:`A \otimes I`, :math:`B \otimes I`, and 
		:math:`C \otimes I` where :math:`I` is a sparse :math:`(n\times{n})` identity matrix and 
		:math:`n = length(y)`. The resulting matrices are stored as a structure in :mat:attr:`kron_products` 
		and are not recomputed on successive calls to :mat:meth:`advance`.
		
		This allows for more straightforward vectorized operations when computing the :math:`k_i` stage values,
		especially if `y` represents a system of ODEs derived from a discretization of a PDE or the
		Runge-Kutta method is implicit. 
		
		Because the size of the matrices contained in :mat:attr:`kron_products` depends on the system
		of ODEs being integrated, it is considered to be a stateful variable is is not copied when 
		:mat:meth:`copy` is called on this object.
		
	
RK4
+++

.. class:: SSP_Tools.Integrators.RK4

	Classical fourth order Runge-Kutta method. Descendent of :mat:class:`SSP_Tools.Integrators.RK`.

	This class is a descendent of :mat:class:`SSP_Tools.Integrators.RK`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: RK4 ('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Integrators.Integrator`

RK5
+++

.. class:: SSP_Tools.Integrators.RK5

	Classical fourth order Runge-Kutta method. Descendent of :mat:class:`SSP_Tools.Integrators.RK`.

	This class is a descendent of :mat:class:`SSP_Tools.Integrators.RK`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: RK5 ('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Integrators.Integrator`
RK6
+++

.. class:: SSP_Tools.Integrators.RK6

	Classical fourth order Runge-Kutta method. Descendent of :mat:class:`SSP_Tools.Integrators.RK`.

	This class is a descendent of :mat:class:`SSP_Tools.Integrators.RK`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: RK6 ('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Integrators.Integrator`

RK7
+++

.. class:: SSP_Tools.Integrators.RK7

	Classical fourth order Runge-Kutta method. Descendent of :mat:class:`SSP_Tools.Integrators.RK`.

	This class is a descendent of :mat:class:`SSP_Tools.Integrators.RK`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: RK7 ('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Integrators.Integrator`
RK8
+++

.. class:: SSP_Tools.Integrators.RK8

	Classical fourth order Runge-Kutta method. Descendent of :mat:class:`SSP_Tools.Integrators.RK`.

	This class is a descendent of :mat:class:`SSP_Tools.Integrators.RK`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: RK8 ('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Integrators.Integrator`

		
SSPRK
+++++

.. class:: SSP_Tools.Integrators.SSPRK

	Parent class for implementing SSP Runge-Kutta methods in Shu-Osher form.
	
	This class is a descendent of :mat:class:`SSP_Tools.Integrators.Integrator`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	This class has two constructors

	.. mat:method:: SSPRK('name', <>, 'alpha', <>, 'beta', <>, 'v', <>, 'yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

		Initialize an SSPRK object from Butcher Tableau coefficients provided by the parameters `alpha`, `beta`,
		and `v`. The `name` parameter sets the :mat:attr:`name` attribute of the object.
	
	.. mat:method:: SSPRK('coefficients', <>, 'yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

		Initialize an RK object from Shu-Osher coefficients stored in `file` which has `alpha`, `beta`,
		`v`, and `name` are saved within. 
		
		If `coefficients` is provided as just a filename without any associated path, the file will be loaded from
		the directory specified by :mat:attr:`coefficient_directory`. 
		
	In addition to the attributes defined by it's parent :mat:class:`SSP_Tools.Integrators.Integrator`, this class
	has the following attributes:
	
	.. mat:attribute:: alpha
	
	.. mat:attribute:: beta
	
	.. mat:attribute:: v
	
	.. mat:attribute:: kron_products
	
		When :mat:meth:`advance` is first called, the :math:`\alpha`, :math:`\beta`, and :math:`v` vectors given in
		Shu-Osher form are used to form the kronnecker products :math:`\alpha \otimes I`, :math:`\beta \otimes I`, and 
		:math:`v \otimes I` where :math:`I` is a sparse :math:`(n\times{n})` identity matrix and 
		:math:`n = length(y)`. The resulting matrices are stored as a structure in :mat:attr:`kron_products` 
		and are not recomputed on successive calls to :mat:meth:`advance`.
		
		This allows for more straightforward vectorized operations when computing the :math:`k_i` stage values,
		especially if `y` represents a system of ODEs derived from a discretization of a PDE or the
		Runge-Kutta method is implicit. 
		
		Because the size of the matrices contained in :mat:attr:`kron_products` depends on the system
		of ODEs being integrated, it is considered to be a stateful variable is is not copied when 
		:mat:meth:`copy` is called on this object.
	
	.. mat:attribute:: coefficient_directory 
	
		Path to directory in the ``SSP_Tools`` package containing coefficients for Runge-Kutta methods in
		Shu-Osher form.

SSP104
++++++

.. mat:class:: SSP_Tools.Integrators.SSP104

	Ten stage, fourth order SSP Runge-Kutta method SSP(10,4). Descendent of :mat:class:`SSP_Tools.Integrators.SSPRK`.
	
	.. mat:method:: SSP104('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Integrators.Integrator`
	
ODE23S
++++++

.. mat:class:: SSP_Tools.Integrators.ODE23S

	Wrapper class for using MATLAB's :mat:func:`ode23s` solver.
	
	.. mat:method:: ODE23s('RelTol', <>, 'AbsTol', <>, 'yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])
	
	In addition to the attributes defined by it's parent :mat:class:`SSP_Tools.Integrators.Integrator`, this class
	has the following attributes:
	
	.. mat:attribute: ode_opts
	
		A structure containing options to pass to :mat:func:`ode23s`. Similar in nature to the one produced
		by :mat:func:`odeset`. 

ODE45
+++++

.. mat:class:: SSP_Tools.Integrators.ODE45

	Wrapper class for using MATLAB's :mat:func:`ode45` solver.
	
	.. mat:method:: ODE54('RelTol', <>, 'AbsTol', <>, 'yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])
	
	In addition to the attributes defined by it's parent :mat:class:`SSP_Tools.Integrators.Integrator`, this class
	has the following attributes:
	
	.. mat:attribute: ode_opts
	
		A structure containing options to pass to :mat:func:`ode54`. Similar in nature to the one produced
		by :mat:func:`odeset`. 


BackwardEuler
+++++++++++++

LNL
+++

.. class:: SSP_Tools.Integrators.LNL

	Linear/Non-Linear SSP Methods. Descendent of :mat:class:`SSP_Tools.Integrators.SSPRK`.

	This class is a descendent of :mat:class:`SSP_Tools.Integrators.SSPRK`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: LNL ('yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>])

		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Integrators.SSPRK`

MSRK
++++

.. class:: SSP_Tools.Integrators.MSRK

	Multistep Multistage Runge-Kutta Methods
	
	This class has two constructors:
	
		.. mat:method:: MSRK( 'A', <>, 'B', <>, 'Ahat', <>, 'Bhat', <>, 'theta', <>, 'D', <>, 'initial_integrator', <>, 'mini_dt_type', <>, 'mini_dt_c', <>, 'yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>]) 

				`A`, `Ahat`, `B`, `Bhat`, `theta`, and `D` contain the coefficients used to specify the specific 
				MSRK method to initialize.
				
				Because these are multistep methods, they are not self-starting and they require an additional 
				:mat:class:`SSP_Tools.Integrators.Integrator` object. This object is specified using the
				`initial_integrator` argument. For convenience, the strings 'RK3' and 'RK4' may specified to
				automatically create and use :mat:class:`SSP_Tools.Integrators.RK3` and 
				:mat:class:`SSP_Tools.Integrators.RK4` objects. In addition, `initial_integrator` may be specified
				as a function handle which provides the exact solution :math:`y(t)` as a single column vector. If
				`Problem` has been provided with an :mat:class:`SSP_Tools.TestProblems.TestProblem`, `initial_integrator`
				may be set to 'use-exact' which will automatically obtain the exact solution from the `TestProblem` object.
				
				If `initial_integrator` doesn't return an exact solution, it's own timestepping must be configured.
				`mini_dt_type` determines what type of timestepping to use when priming the MSRK method. There are
				currently two options:
				
				==============  =====================
				`mini_dt_type`  description
				==============  =====================
				'compatible'    mini_dt = c*dt.^(p/3)
				'fraction'      mini_dt = c*dt
				==============  =====================
				
				Regardless of which option is selected, the :math:`c` parameter is specified by `mini_dt_c`. 
				
				
		.. mat:method:: MSRK( 'coefficients', <>,  'initial_integrator', <>, 'mini_dt_type', <>, 'mini_dt_c', <>, 'yPrimeFunc', <>, ['yInFunc', <>, 'yOutFunc', <>, 'Problem', <>, 'log', <>]) 


SSP_Tools.Discretizers
----------------------

.. note::

	Due to the limited needs of the research driving the development of ``SSP_Tools``, support for 
	spatial discretization methods isn't as developed as it should be. Right now, all schemes assume
	periodic boundaries where x(1) == x(end). Future releases of ``SSP_Tools`` may correct this.

.. class:: SSP_Tools.Discretizers.Discretizer

	Parent class for all spatial discretization methods in ``SSP_Tools``.
	
	.. mat:method:: Discretizer('f', <>, 'em', <>)
	
		`f` is a callback that evaluates the :math:`f(u)` part of :math:`f(u)_x`.
		
		`em` is another callback that evaluates the value of :math:`f'(u)`.
	
	.. method:: L(x,u)
	
		Return an approximation of :math:`f(u)_x` over the domain `x` using the function values `u`. 
		
		`x` is a one-dimensional domain of evenly-spaced gridpoints represented by a row vector.
		
		`u` is a column vector of the corresponding function values at those gridpoints.
	
	.. method:: copy

		Return a new copy of the ``Discretizer`` object minus any stateful information.
		
		This can be used to get an exact copy of the object for use in discretizing a different problem.
		
	.. method:: repr
	
		Return a formatted text string representation of the object containing information about the 
		current `Discretizer` and the parameters it was configured with. 	
	
	.. method:: get_parameters
	
		Return an ordered structure array describing the method-specific arguments needed by the constructor.



FiniteDifference
++++++++++++++++

.. class:: SSP_Tools.Discretizers.FiniteDifference

	First order finite difference method.
	
	This class is a descendent of :mat:class:`SSP_Tools.Discretizers.Discretizer`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: FiniteDifference('f', <>, 'em', <>)
	
		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Discretizers.Discretizer`


KorenLimiter
++++++++++++

.. class:: SSP_Tools.Discretizers.KorenLimiter

	Second order centered difference with Koren Limiter
	
	This class is a descendent of :mat:class:`SSP_Tools.Discretizers.Discretizer`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: KorenLimiter('f', <>, 'em', <>)
	
		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Discretizers.Discretizer`

Spectral
++++++++

.. class:: SSP_Tools.Discretizers.Spectral

	Spectral Fourier Collocation Method
	
	This class is a descendent of :mat:class:`SSP_Tools.Discretizers.Discretizer`. For a full description
	of object attributes, and methods see the documentation for the parent class.
	
	.. mat:method:: Spectral('f', <>, 'em', <>)
	
		This class takes no additional constructor arguments than those required by 
		:mat:meth:`SSP_Tools.Discretizers.Discretizer`


WenoCore
++++++++

.. class:: SSP_Tools.Discretizers.WenoCore

	Wrapper class for the WenoCore routines.
	
	.. method:: WenoCore('f', <>, 'em', <>, 'kernel', <>[, 'weno_fcn', <>, 'epsilon', <>, 'p'])
	
		Initialize a WenoCore object.
		
		`epsilon` is the WENO shape parameter. Defaults to 1e-16.
		
		`p` is the other WENO shape parameter. Defaults to 2.
		
		`kernel` selects which WENO kernel to use. Currently the options are 'WENO5', 'WENO9', 'WENO11', 'WENO13'
		and 'WENO15'.
		
		`weno_fcn` optionally chooses the WENO routine that's used, though the default @WenoCore.weno_basic


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

