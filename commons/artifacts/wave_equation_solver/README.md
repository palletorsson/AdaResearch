# Wave Equation Solver

Simulates the 2D wave equation on a clamped membrane, producing visible ripples like a struck drumhead. Teaches partial differential equations, finite difference methods, and the Courant stability condition for numerical wave propagation.

## How It Works

The membrane is discretized on a square grid. At each timestep the solver computes the finite difference approximation of the wave equation u_tt = c^2 (u_xx + u_yy), updating each interior grid point using the standard central-difference stencil with a viscous damping term. Boundary cells are fixed at zero (clamped edges). The simulation runs multiple sub-steps per frame to maintain numerical stability, enforcing the CFL condition (Courant number < 1/sqrt(2)). The displacement field is rendered as an ImmediateMesh surface with vertex colors interpolated between blue (positive), red (negative), and dark (zero). A Gaussian pulse seeds the initial disturbance.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `membrane_size` | float | 0.8 |
| `grid_res` | int | 48 |
| `height_scale` | float | 0.15 |
| `wave_speed` | float | 2.0 |
| `damping` | float | 0.002 |
| `initial_amplitude` | float | 1.0 |
| `initial_sigma` | float | 0.08 |

## Features

- Real-time PDE integration with sub-stepping for numerical stability
- Vertex-colored ImmediateMesh surface showing displacement as a 3D membrane
- VR sliders for damping and wave speed
- Strike button to add a new Gaussian pulse at a random position
- Reset button to restore the initial state
- Info label showing the PDE formula, current wave speed, damping, and peak displacement
- Wooden frame around the membrane edges representing clamped boundary conditions

## Files

- `wave_equation_solver.gd` -- Main script
- `wave_equation_solver.tscn` -- Scene file
