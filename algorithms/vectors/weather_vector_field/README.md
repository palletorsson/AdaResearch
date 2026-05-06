# Weather Vector Field

An applied vector addition artifact where two grabbable wind vectors combine to produce a resultant, visualized across a 6x6 grid of display arrows. Rain particles fall under gravity plus wind, their diagonal paths demonstrating force superposition. High- and low-pressure zones drift across the field, perturbing the local wind. The artifact teaches **vector addition and force superposition** through a weather metaphor.

## Concept Taught

**Vector addition** is the operation of combining two vectors component-by-component: `R = A + B`. In the weather context, two wind currents sum to a single resultant wind. **Force superposition** extends this to show that an object's motion (rain) is governed by the sum of all forces acting on it -- gravity pulling down and wind pushing sideways. The rain's diagonal trajectory makes the vector sum physically visible.

## How It Works

1. Extends `vector_scene_base.gd` for shared vector spawning, material caching, and info panel creation.
2. Two grabbable wind vectors (`Wind A` in cyan, `Wind B` in magenta) share a common origin. A non-grabbable yellow resultant arrow computes `A + B` every frame.
3. A **parallelogram construction** is drawn with dotted lines: from the tip of A to A+B (copy of B) and from the tip of B to A+B (copy of A), with floating labels.
4. A 6x6 grid of small arrows shows the wind field. Each arrow samples the local wind at its position using `_wind_at()`, which adds base wind (A+B) plus perturbation from pressure zones.
5. **Rain particles** (25 small spheres) integrate velocity each frame: `force = gravity + wind_at(position)`. When a particle falls below ground or drifts too far, it respawns randomly above the field.
6. **Pressure zones** -- a blue high-pressure sphere pushes outward, a red low-pressure sphere pulls inward. Both drift slowly over time.
7. A **decomposition display** at one corner shows three arrows (wind, gravity, trajectory) to explicitly visualize `F_rain = wind + gravity`.
8. Four weather presets (Trade Winds, Crosswinds, Opposing Winds, Updraft) snap the vectors to characteristic configurations.
9. VR push buttons cycle modes, toggle the grid, and reset. Sliders adjust gravity strength and pressure intensity.

## Parameters

Key constants and variables (not `@export`, configured via code and VR controls):

| Variable | Default | Description |
|----------|---------|-------------|
| `GRID_SIZE` | `6` | Grid arrows per side (6x6 = 36 arrows) |
| `GRID_SPACING` | `0.7` | World-space distance between grid arrows |
| `PARTICLE_COUNT` | `25` | Number of rain particle spheres |
| `gravity_strength` | `1.0` | Downward gravitational acceleration |
| `pressure_intensity` | `0.5` | Strength of pressure zone perturbation |
| `current_mode` | `0` | Active weather preset index |

## Features

- Two grabbable wind vectors with real-time resultant computation.
- Parallelogram rule visualized with dotted MultiMesh lines and floating copy labels.
- 6x6 wind field grid with arrows color-coded by magnitude (blue to yellow to red).
- Rain particle simulation with gravity + wind force integration.
- Drifting high/low pressure zones that locally perturb the wind field.
- Decomposition display showing wind + gravity = trajectory.
- Four weather presets switchable by button or keyboard.
- VR controls: push buttons (mode, grid toggle, reset) and sliders (gravity, pressure).
- Extends `vector_scene_base.gd` for shared material and vector utilities.

## Files

- `weather_vector_field.gd` -- Main script: wind vectors, grid arrows, rain simulation, pressure zones, VR controls.
- `weather_vector_field.tscn` -- Scene file.
