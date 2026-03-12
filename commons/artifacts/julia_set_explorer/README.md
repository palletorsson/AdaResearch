# Julia Set Explorer

A GPU-accelerated Julia set fractal rendered on a table surface with interactive controls for the complex parameter c. This teaches the relationship between Julia sets and the Mandelbrot set -- each point in the Mandelbrot set defines a connected Julia set.

## How It Works

A fragment shader performs the escape-time iteration z = z^2 + c for every pixel, where each pixel's UV coordinate maps to a starting z value and c is held constant across the image. Smooth coloring is achieved through a normalized iteration count with log-log smoothing to eliminate color banding. The shader runs entirely on the GPU, providing real-time feedback as the c parameter changes. Six famous preset Julia sets (Dendrite, San Marco, Rabbit, Spiral, Dragon, Douady Rabbit) offer starting points for exploration.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `table_size` | float | 1.0 |
| `max_iterations` | int | 100 |
| `c_real` | float | -0.7 |
| `c_imag` | float | 0.27015 |
| `zoom` | float | 1.0 |
| `color_scheme` | int | 0 (Classic) |

## Features

- GPU shader-based rendering for real-time fractal computation
- Two VR sliders for adjusting c_real and c_imag independently
- Six preset buttons for famous Julia set configurations
- Five color palettes: Classic, Fire, Ocean, Neon, Grayscale
- Keyboard controls for parameter adjustment and preset selection
- Info label showing current c value and matching preset name
- Smooth iteration coloring to eliminate banding artifacts

## Files

- `julia_set_explorer.gd` -- Main script
- `julia_set_explorer.tscn` -- Scene file
