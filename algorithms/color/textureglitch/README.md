# Texture Glitch

A layered texture system that generates eight distinct glitch art effects through procedural pixel manipulation, teaching how digital image corruption techniques (datamosh, bit crush, pixel sort) work at the buffer level.

## How It Works

The system creates eight objects in a grid, each running a different glitch algorithm. Every object is composed of multiple semi-transparent texture layers stacked with slight depth offsets. Each layer's pixel buffer is regenerated procedurally at a configurable frame rate. The eight glitch types are: Datamosh (motion-shifted noise), Chromatic Split (per-channel RGB separation), Digital Decay (noise-based corruption), Buffer Cascade (traveling wave distortion), Pixel Sort (brightness-threshold reordering), Bit Crush (reduced bit-depth quantization), Memory Leak (expanding corruption spots), and Quantum Glitch (superposition of two wave states with probabilistic collapse). Layers animate independently with position offsets, rotation, and pulsing emission. An optimized variant uses a custom GLSL shader (`glitch.gdshader`) to move all pattern computation to the GPU.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `num_layers` | int | 4 |
| `texture_size` | int | 128 |
| `layer_depth_spacing` | float | 0.03 |
| `animation_speed` | float | 1.0 |
| `enable_layer_separation` | bool | true |
| `separation_strength` | float | 0.1 |
| `glitch_intensity` | float | 0.8 |
| `update_frequency` | float | 30.0 |
| `corruption_chance` | float | 0.1 |

## Features

- Eight distinct glitch algorithms running simultaneously
- Multi-layer compositing with blend modes (mix, add)
- CPU-based procedural texture generation at configurable FPS
- GPU-optimized variant via custom GLSL shader
- Layer explosion and chromatic separation trigger effects
- Animated camera orbit and dynamic accent lighting

## Files

- `textureglitch.gd` -- CPU-based layered texture system
- `texture_glitch_optimized.gd` -- GPU shader-based optimized variant
- `textureglitch.tscn` -- Scene file
- `glitch.gdshader` -- GLSL shader for GPU-accelerated glitch patterns
