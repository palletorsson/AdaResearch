# Foucault Pendulum

Simulates a Foucault pendulum to demonstrate how Earth's rotation causes the swing plane of a free-hanging pendulum to precess, producing characteristic rosette trail patterns on a canvas below.

## How It Works

The pendulum follows simple harmonic motion with the equation theta'' = -(g/L)*sin(theta). Earth's rotation is modeled by advancing the swing direction at a precession rate of omega * sin(latitude), so the effect is strongest at the poles and vanishes at the equator. A rotating reference ring shows the Earth frame while the pendulum swings in inertial space. An electromagnetic drive maintains swing amplitude, and optional grabbable gravity spheres around the perimeter apply inverse-square perturbations to the bob, distorting the trail pattern in real time.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `pendulum_length` | float | `8.0` |
| `cone_radius` | float | `0.08` |
| `cone_height` | float | `0.25` |
| `wire_thickness` | float | `0.008` |
| `initial_amplitude` | float | `0.4` |
| `initial_direction` | float | `0.0` |
| `tip_hover_height` | float | `0.02` |
| `gravity` | float | `9.81` |
| `damping` | float | `0.0002` |
| `earth_rotation_rate` | float | `0.05` |
| `latitude` | float | `45.0` |
| `drive_enabled` | bool | `true` |
| `target_amplitude` | float | `0.4` |
| `drive_strength` | float | `0.02` |
| `gravity_spheres_enabled` | bool | `true` |
| `num_gravity_spheres` | int | `8` |
| `sphere_gravity_strength` | float | `0.5` |
| `sphere_radius` | float | `0.25` |
| `sphere_influence_radius` | float | `2.0` |
| `sphere_color` | Color | `(0.6, 0.3, 0.9)` |
| `canvas_size` | float | `6.0` |
| `canvas_color` | Color | `(0.95, 0.93, 0.88)` |
| `show_frame` | bool | `true` |
| `sine_modulation_enabled` | bool | `false` |
| `sine_modulation_amplitude` | float | `0.08` |
| `sine_modulation_frequency` | float | `0.3` |
| `marker_color` | Color | `(0.08, 0.06, 0.04)` |
| `marker_width` | float | `0.02` |
| `max_trail_points` | int | `8000` |
| `draw_height` | float | `0.01` |

## Features

- Latitude-dependent precession rate with real-time rosette trail drawing
- Electromagnetic drive to maintain swing amplitude indefinitely
- Interactive gravity spheres (grabbable in VR) that perturb the pendulum path
- Rotating Earth reference ring with compass markers
- Optional sine-wave modulation for Foucault-inspired pattern variation
- Debug visuals showing tip position and raycast to canvas

## Files

- `foucault_pendulum.gd` -- Main script
- `foucault_pendulum.tscn` -- Scene file
