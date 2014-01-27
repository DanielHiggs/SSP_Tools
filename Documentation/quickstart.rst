

Quickstart
==========

``SSP_Tools`` includes an interactive shell that quickly allows some operations and tests to be
performed on the various numerical methods and example problems included in the toolkit. This
interactive shell may be invoked by running `TestSuite.m` from the MATLAB interpreter.


.. code-block:: none

	[1] Animation
	[2] Simple Approximation
	[3] Convergence Test - ODE
	[4] Convergence Test - PDE
	[5] Positivity Test
	[6] SSP Test
	Select a Test: 
	

Animation
---------




Approximation
-------------

Convergence Test - ODE
----------------------

Convergence Test - PDE
----------------------

.. code-block:: none
`
	Select Type of refinement:
	[1] Refine in time and Space
	[2] Refine in time only
	[3] Refine in space only
	Selection: 

.. code-block:: none

	Vector of refinements, e.g. [10,30,80] refinements:

.. code-block:: none

	Value of t to approximate to t [1]:

.. code-block:: none
	
	[1] Advection Equation u_t - a*u_x = 0
	[2] Buckley-Leverett Equation
	[3] Burgers Equation u_t - (1/2*u)_x = 0
	[4] Convection-Advection Equation u_t +  u_x +  (0.5*u^2)_x = 0
	[5] Convection-Reaction Equation u_t + \xi_1(0.5u)_x = \xi_2u
	[6] Convection-Reaction Equation u_t + \xi_1u_x = \xi_2u^2
	[7] Time Dependent PDE u_t = e(t) u.^2
	Select a test problem: 

	Wavespeed Coefficient a [1]:

	Select Initial Condition:
	[1] sin(pi*x)
	[2] 1/4 + sin(pi*x)
	[3] Squarewave  1.0 (x<=0.5)
	[4] Step Function [-1,1]
	[5] Elevated Sinwave [-1, 1] u(0) = 1 + sin(pi*x)
	Selection: 

	Configure Flux Discretizer:
	[1] FiniteDifference
	[2] KorenLimiter
	[3] Spectral
	[4] WenoCore
	Select a discretizer:

	Configuration options

	[1] weno5
	[2] weno9
	[3] weno11
	[4] weno13
	[5] weno15
	Weno Kernel kernel [weno5]:

	smoothness parameter epsilon [1e-16]:

	other smoothness parameter p [2]:

	Configure Integrator for General Problem
	[1] BackwardEuler
	[2] LNL
	[3] MSRK
	[4] ODE23S
	[5] ODE45
	[6] RK3
	[7] RK4
	[8] RK5
	[9] RK7
	[10] RK8
	[11] SSP104
	[12] SSPRK
	Select an integrator: 

Now that the problem and numerical methods have been configured, the test will run.
	
.. code-block:: none
	
	PDE Convergence Test
	Problem: < SSP_Tools.TestProblems.Advection: @(x)sin(pi*x) [-1, 1] t= >
	Time Stepping Method: < SSP_Tools.Integrators.RK3 >
	Spatial Discretization: < SSP_Tools.Discretizers.WenoCore: call=@WenoCore.weno_basic kernel=@WenoCore.kernels.weno5 epsilon=1e-16 p=2 >

	Testing 10
	Testing 20                                     
	Testing 30                                     
	Testing 40                                     
	Testing 50                                     
	Testing 60                                     
	Testing 70                                     
	Testing 80                                     
	Testing 90                                     
	Testing 100                                    
	Convergence Test Results                       
	Problem: Advection Equation u_t - 1*u_x = 0 u(x,0)=@(x)sin(pi*x) T=1.000000
	Spatial Discretization: WENO5 epsilon=1e-16 p=2
	Time-Stepping Method: RK3
	----------------------------------------------------
		N |     dt |    L1Error |   L1Order |   L2Error |   L2Order | LinfError | LinfOrder |
	10 | 0.0400 |   1.60e-02 |         - |  1.78e-02 |         - |  2.97e-02 |         - | 
	20 | 0.0200 |   7.51e-04 |      4.42 |  8.78e-04 |      4.34 |  1.48e-03 |      4.32 | 
	30 | 0.0133 |   9.85e-05 |      5.01 |  1.18e-04 |      4.94 |  2.07e-04 |      4.85 | 
	40 | 0.0100 |   2.45e-05 |      4.84 |  2.89e-05 |      4.90 |  4.95e-05 |      4.97 | 
	50 | 0.0080 |   8.50e-06 |      4.74 |  9.90e-06 |      4.81 |  1.75e-05 |      4.67 | 
	60 | 0.0067 |   3.65e-06 |      4.63 |  4.20e-06 |      4.70 |  7.37e-06 |      4.73 | 
	70 | 0.0057 |   1.82e-06 |      4.52 |  2.08e-06 |      4.58 |  3.54e-06 |      4.76 | 
	80 | 0.0050 |   1.01e-06 |      4.41 |  1.14e-06 |      4.46 |  1.97e-06 |      4.39 | 
	90 | 0.0044 |   6.07e-07 |      4.31 |  6.86e-07 |      4.35 |  1.15e-06 |      4.60 | 
	100 | 0.0040 |   3.90e-07 |      4.20 |  4.39e-07 |      4.24 |  7.34e-07 |      4.22 |

Positivity Test
---------------

SSP Test
--------

