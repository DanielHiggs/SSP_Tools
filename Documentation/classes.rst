
Classes
=======

.. toctree::
	:maxdepth: 4
	:hidden:
	
	self


SSP_Tools.Integrators
---------------------

RK3
+++

RK4
+++

RK5
+++

RK6
+++

RK7
+++

RK
++

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

