
Overview
========

``SSP_Tools`` is an object-oriented framework where numerical methods and example problems are
implemented as classes that must be instantiated as objects before they can be used. There are three 
main class hierarchies in ``SSP_Tools`` that support the approximation the differential equations: 
Discretizers, Integrators, and TestProblems.

In addition to these are the Tests and Reports hierarchies. Within the Tests hierarchy are classes implementing
common tests that may be performed on the numerical methods, and Reports hierachry contains classes
which describe various reports which apply those tests to multiple methods for easy comparisons.

Finally, there is the Factories hierachy which includes support classes for using the ``SSP_Tools``
from within an interactive shell.

Integrators
-----------

``Integrator`` objects implement time-stepping methods that numerically solve ordinary differential equations
or systems of ordinary differential equations of the form :math:`y'=f(y)`.

All ``Integrator`` objects require at least three things at initialization: 

.. code-block:: matlab

	yp = @(y) y;
	dudt = SSP_Tools.Integrators.RK3('yPrimeFunc', yp);

	y = 1.0
	t = 0.0;
	dt = 0.1;
	
	for i=1:100
		y = dudt.step(y, t, dt);
		t = t + dt;
	end
	

Discretizers
------------

``Discretizer`` objects implement spatial discretization schemes which approximate the spatial derivative
and use the method of lines to transform a Partial Differential Equation of the form :math:`u_t = f(u)_x` 
into a system of Ordinary Differential Equations :math:`y'=L(u)` that may then be solved using 
an ``Integrator`` object. 

The following example links a first-order finite difference method in space with SSP(3,3) in time to 
solve the advection equation :math:`u_t = a{u_x}` where :math:`a = 1.0` over an equally-spaced grid 
of 101 points on the domain :math:`[-1,1]` with :math:`u(x,0) = sin(pi*x)` using 
stepsize :math:`\Delta{t} = 0.2*\Delta{x}`.

.. code-block:: matlab

	x = linspace(-1, 1, 31);
	u = sin(pi*x);
	t = 0.0;
	
	dx = min(diff(x));
	dt = 0.2*dx;
	
	u_x = @(u) u;
	dudx = SSP_Tools.Discretizers.FD('f', u_x, 'em', 1.0);
	
	yp = @(u,t) dudx.L(x,u,t);
	dudt = SSP_Tools.Integrators.RK3('yPrimeFunc', yp);
	
	for i=1:100
		u = dudt.step(u, t, dt);
		t = t + dt;
	end

TestProblems
------------

``TestProblem`` objects describe common example problems and abstract away much of the logistics of configuring
the numerical methods used to solve them. 

The following example solves the Dalquist Equation :math:`y' = y` with the initial condition :math:`y(0) = 1.0`
using SSP(3,3).

.. code-block:: matlab

	dudt = SSP_Tools.Integrators.RK3('yPrimeFunc', yp);
	Problem = SSP_Tools.TestProblems.Dalquist('integrator', dudt);
	
	dt = 0.1;
	
	for i=1:100
		Problem.step(y, t, dt);
	end
	
	y = Problem.y;
	t = Problem.t;

They also provide an simpler interface for obtaining an approximate solution at a given value
of :math:`t`. The following code performs the same approximation as the previous code, but hides
the time-stepping loop.
	
.. code-block:: matlab

	dudt = SSP_Tools.Integrators.RK3('yPrimeFunc', yp);
	Problem = SSP_Tools.TestProblems.Dalquist('integrator', dudt);
		
	Problem.approximate(1.0, 'dt', 0.1);
	
	y = Problem.y;
	t = Problem.t;

In some cases, ``TestProblem`` classes also can provide an exact, analytic solution.

.. code-block:: matlab

	dudt = SSP_Tools.Integrators.RK3('yPrimeFunc', yp);
	Problem = SSP_Tools.TestProblems.Dalquist('integrator', dudt);
		
	Problem.approximate(1.0, 'dt', 0.1);
	
	y_apprx = Problem.y;
	y_exact = Problem.get_exact_solution();
	
	t = Problem.t;

There are also ``TestProblem`` classes for Partial Differential Equations. The following example 
pairs a first-order finite difference method in space with SSP(3,3) in time to solve the advection
equation :math:`u_t = a{u_x}` where :math:`a = 1.0` over an equally-spaced grid of 101 points on 
the domain :math:`[-1,1]` with :math:`u(x,0) = sin(pi*x)` using stepsize :math:`\Delta{t} = 0.2*\Delta{x}`.

.. code-block:: matlab

	dudx = SSP_Tools.Discretizers.FD();
	dudt = SSP_Tools.Integrators.RK3();
	
	Problem = SSP_Tools.TestProblems.Advection('a', 1.0, ...
	                                           'discretizer', dudx, ...
	                                           'integrator', dudt, ...
	                                           'N', 101, ...
	                                           'domain', [-1,1], ...
	                                           'initial_condition', 'sinewave' );
	
	Problem.approximate(1.0, 'cfl', 0.2);
	
	u = Problem.u;
	t = Problem.t;
	
This code does the same approximation, but steps forward in time using a stepsize :math:`\Delta{t} = 0.001`.

.. code-block:: matlab

	dudx = SSP_Tools.Discretizers.FD();
	dudt = SSP_Tools.Integrators.RK3();
	
	Problem = SSP_Tools.TestProblems.Advection('a', 1.0, ...
	                                           'discretizer', dudx, ...
	                                           'integrator', dudt, ...
	                                           'N', 101, ...
	                                           'domain', [-1,1], ...
	                                           'initial_condition', 'sinewave' );
	
	Problem.approximate(1.0, 'dt', 0.001);
	
	u = Problem.u;
	t = Problem.t;
