# Spring Demo

An interactive spring-mass system demonstrating Hooke's Law (F = -kx) with damping. VR sliders control spring constant, mass, and damping coefficient, letting learners observe how these parameters affect oscillation frequency, amplitude, and decay.

## How It Works

Each physics frame computes the net force as F = -kx - cv (spring restoring force plus velocity-proportional damping), then derives acceleration via Newton's second law (a = F/m). Euler integration updates velocity and position. The spring visual is drawn as a coil using ImmediateMesh line strips, with coil spacing that contracts and expands based on the mass displacement. The force arrow scales and flips direction based on the current spring force. A phase-space trail records (position, velocity) pairs for potential visualization. Labels display live values including the natural period T = 2*pi/sqrt(k/m).

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `stiffness_slider_path` | NodePath | "ControlPanel/StiffnessSlider" |
| `mass_slider_path` | NodePath | "ControlPanel/MassSlider" |
| `damping_slider_path` | NodePath | "ControlPanel/DampingSlider" |

## Features

- Real-time Hooke's Law simulation with damped harmonic motion
- VR sliders for spring constant (k), mass (m), and damping (c)
- Procedural spring coil visual with tension-based coloring
- Force arrow indicating magnitude and direction of restoring force
- Live readout of k, m, c, displacement, velocity, force, and period
- Phase-space trail for position vs. velocity analysis
- Public API: `pull_and_release()`, `get_natural_frequency()`, `get_period()`, `is_underdamped()`

## Files

- `spring_demo.gd` -- Main script
- `spring_demo.tscn` -- Scene file
