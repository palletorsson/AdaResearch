# Bifurcation Walkway

Displays the bifurcation diagram of the logistic map (x_next = r * x * (1-x)), showing how a simple deterministic equation transitions from stable fixed points through period doubling cascades into chaos as the parameter r increases.

## How It Works

For each value of r across the horizontal axis, the logistic map is iterated from x=0.5 for 200 warmup steps (discarding transients), then the next 50 values are plotted as points on a vertical display panel. The result reveals the classic bifurcation structure: a single stable value that splits into 2, then 4, then 8 attractors before dissolving into chaos, with windows of periodic order appearing within the chaotic regime. VR sliders control the r range, and preset buttons zoom into the full view, chaos region, or bifurcation onset. Points are rendered as MultiMesh spheres with brightness increasing in chaotic regions.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_width` | float | `2.0` |
| `display_height` | float | `1.5` |
| `r_min` | float | `2.5` |
| `r_max` | float | `4.0` |
| `samples_per_r` | int | `100` |
| `r_steps` | int | `400` |
| `warmup_iterations` | int | `200` |
| `show_iterations` | int | `50` |
| `point_color` | Color | `Color(0.2, 0.8, 1.0)` |
| `background_color` | Color | `Color(0.02, 0.02, 0.04)` |
| `frame_color` | Color | `Color(0.15, 0.15, 0.2)` |

## Features

- Up to 20,000 MultiMesh point instances with density-based brightness
- VR sliders for r_min and r_max range control
- Preset buttons: FULL (0.5-4.0), CHAOS (3.5-4.0), BIFUR (2.8-3.6)
- Framed vertical display panel with axis labels
- Keyboard controls for panning, zooming, and preset selection
- Real-time diagram regeneration on parameter change

## Files

- `bifurcation_walkway.gd` -- Main script
- `bifurcation_walkway.tscn` -- Scene file
