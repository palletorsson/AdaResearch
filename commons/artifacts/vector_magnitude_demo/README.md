# Vector Magnitude Demo

An interactive visualization of vector magnitude (length), showing how a vector's length is computed from its x, y, and z components using the Pythagorean theorem in three dimensions: |V| = sqrt(x^2 + y^2 + z^2).

## How It Works

A main vector V is drawn in cyan, and its three axis-aligned components (Vx, Vy, Vz) are displayed as fainter red, green, and blue arrows decomposing V along each coordinate axis. An info panel shows the step-by-step magnitude calculation, from the component values through the sum of squares to the final square root. A VR slider scales the vector's length along a fixed direction, letting users observe how the magnitude formula changes as the vector grows or shrinks.

## Features

- Cyan main vector with RGB-colored component decomposition arrows
- Step-by-step magnitude formula display (V, squared components, sum, root)
- Floating magnitude label at the vector's midpoint
- VR slider to scale the vector length (0 to 2x)
- Extends the shared vector_scene_base for consistent coordinate axes and styling
- Cached node references for efficient per-frame updates

## Files

- `vector_magnitude_demo.gd` -- Main script
- `vector_magnitude_demo.tscn` -- Scene file
