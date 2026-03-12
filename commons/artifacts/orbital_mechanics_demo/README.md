# Orbital Mechanics Demo

Simulates gravitational orbits around a central planet, demonstrating Kepler's laws and the relationship between velocity, orbital shape, and energy. Teaches how a satellite in perpetual free-fall traces elliptical, parabolic, or hyperbolic trajectories depending on its speed.

## How It Works

A satellite orbits a central mass under Newtonian gravity using Velocity Verlet integration. The gravitational acceleration a = -GM/r^2 * r_hat is computed each physics frame, producing stable orbits without the energy drift of simpler Euler methods. The orbital energy E = v^2/2 - GM/r determines the trajectory type: negative energy yields a bound ellipse, near-zero a parabola, and positive a hyperbolic escape. VR preset buttons set the satellite to circular, elliptical, escape, or decay orbits by adjusting the initial tangential velocity relative to the circular orbital speed.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `central_mass` | float | 1.0 |
| `gravitational_constant` | float | 0.5 |
| `initial_radius` | float | 0.3 |
| `initial_velocity` | float | 0.0 |
| `planet_radius` | float | 0.08 |
| `satellite_radius` | float | 0.02 |
| `trail_length` | int | 200 |
| `time_scale` | float | 1.0 |
| `color_planet` | Color | (0.3, 0.5, 1.0) |
| `color_satellite` | Color | (1.0, 0.8, 0.3) |
| `color_orbit` | Color | (0.4, 0.4, 0.5, 0.5) |
| `color_velocity` | Color | (0.3, 1.0, 0.4) |

## Features

- Velocity Verlet integration for energy-conserving orbital simulation
- Four orbit presets: Circular, Ellipse, Escape, and Decay
- Real-time velocity arrow showing direction and magnitude
- Fading orbit trail rendered with ImmediateMesh
- Live info display showing radius, velocity, orbital energy, type, and angular momentum
- Time scale slider (0.1x to 5.0x)
- Automatic crash and escape detection with orbit reset

## Files

- `orbital_mechanics_demo.gd` — Main script
- `orbital_mechanics_demo.tscn` — Scene file
