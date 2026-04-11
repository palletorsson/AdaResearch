# Mandelbrot Dive

A GPU-accelerated Mandelbrot set rendered on a table surface with VR controls for zooming, panning, and palette selection. This teaches the escape-time algorithm for complex dynamics -- iterating z = z^2 + c to determine which points in the complex plane remain bounded.

## How It Works

A fragment shader maps each pixel to a point c in the complex plane and iterates z = z^2 + c starting from z = 0. If |z| exceeds 2 (the escape radius), the point is colored based on how many iterations it took to escape, using log-log smoothing for continuous color bands. Points that never escape within the iteration limit are colored black and belong to the Mandelbrot set. An auto-zoom mode smoothly animates toward Seahorse Valley, automatically increasing iteration depth as zoom increases to maintain detail at deeper magnifications.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `table_size` | float | 1.0 |
| `max_iterations` | int | 100 |
| `zoom` | float | 1.0 |
| `center_x` | float | -0.5 |
| `center_y` | float | 0.0 |
| `color_scheme` | int | 0 (Classic) |
| `auto_zoom` | bool | false |
| `zoom_speed` | float | 0.5 |
| `zoom_target_x` | float | -0.7436... |
| `zoom_target_y` | float | 0.1318... |

## Features

- GPU shader-based rendering for real-time fractal computation
- VR sliders for logarithmic zoom control and palette selection
- Four push buttons: zoom in, zoom out, auto-dive toggle, and reset
- Five color palettes: Classic, Fire, Ocean, Neon, Grayscale
- Auto-zoom dive mode targeting Seahorse Valley with adaptive iteration depth
- Keyboard controls for pan (WASD), zoom (+/-), palette (1-5), and reset (R)
- Smooth iteration coloring via log-log normalization
- Info label showing current zoom level and active palette

## Files

- `mandelbrot_dive.gd` -- Main script
- `mandelbrot_dive.tscn` -- Scene file
