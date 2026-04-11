# Gradient Descent Landscape

A 3D loss surface with a ball that rolls downhill via gradient descent, teaching how optimization algorithms navigate error landscapes by following the negative gradient toward local minima.

## How It Works

The loss function combines a quadratic bowl with three Gaussian dips (creating local minima) and a sinusoidal ridge for visual interest. A triangulated ImmediateMesh surface is colored by height: green at low loss, yellow at mid, and red at high loss. Each time step, the ball computes the gradient via finite differences and takes a step proportional to the learning rate in the negative gradient direction. The ball leaves a trail of blue breadcrumb spheres showing its descent path. Convergence is declared when the gradient magnitude drops below a threshold.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `surface_size` | float | `0.7` |
| `grid_resolution` | int | `32` |
| `learning_rate` | float | `0.08` |
| `step_interval` | float | `0.12` |

## Features

- 3D loss surface with multiple local minima and a saddle ridge
- Ball follows gradient descent with configurable learning rate
- Blue breadcrumb trail showing optimization path history
- VR control panel with learning rate slider and reset button
- Live display of loss value, gradient magnitude, convergence status, and step count
- Random restart positions in the outer region of the domain

## Files

- `gradient_descent_landscape.gd` -- Main script
- `gradient_descent_landscape.tscn` -- Scene file
