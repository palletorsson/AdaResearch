# Minimal Glitch

A self-contained glitch art demo that applies six different bit-manipulation color effects to a grid of cubes, teaching how low-level binary operations (XOR, bit shifting, bit crushing) produce visual patterns.

## How It Works

The script creates a 5x3 grid of cubes and cycles each cube through one of six glitch algorithms every frame. Bit crushing reduces color precision by quantizing to fewer bits. XOR patterns compute exclusive-or between integer position coordinates to create fractal-like grids. RGB channel shifting uses bitwise shift operators to offset color channels. Digital corruption randomly flips bits in a value to simulate data errors. Binary noise generates pseudo-random colors via large prime multiplications modulo 256. Chromatic glitch smoothly shifts red and blue channels in opposite directions. Together, these effects demonstrate how the same mathematical operations that underlie data corruption can be harnessed as creative tools.

## Features

- Six distinct glitch algorithms running simultaneously
- No external dependencies -- fully self-contained scene
- Real-time per-frame color computation
- Demonstrates XOR, bit shift, quantization, and pseudo-random techniques

## Files

- `minimalglitch.gd` -- Main script
- `minimalglitch.tscn` -- Scene file
