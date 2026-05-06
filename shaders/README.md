# Shaders

> Visual effects and material shaders

## Overview

Custom shaders for algorithm visualizations, VR effects, and material rendering. Written in Godot's shader language (GLSL-like).

## Categories

### Noise Shaders
- Perlin, Simplex, Worley noise
- Fractal Brownian motion (fBm)
- Domain warping

### Procedural Materials
- Terrain texturing
- Organic patterns
- Crystalline structures

### Visual Effects
- Glow and bloom
- Displacement
- Color manipulation

### VR-Specific
- Comfort vignette
- Depth effects
- Performance-optimized variants

## Usage

### In Scenes

```gdscript
var material = ShaderMaterial.new()
material.shader = preload("res://shaders/noise/perlin_3d.gdshader")
material.set_shader_parameter("scale", 4.0)
mesh_instance.material_override = material
```

### Common Parameters

Most shaders expose:
- `scale` — Pattern scale/frequency
- `speed` — Animation speed
- `color_a`, `color_b` — Color range
- `time` — Animation time (often auto-updated)

## File Conventions

```
shaders/
├── noise/           # Noise generation
├── materials/       # Surface materials
├── effects/         # Post-processing
├── vr/              # VR-specific
└── includes/        # Shared functions
```

## Performance Notes

- VR requires 90fps × 2 eyes — optimize aggressively
- Use `hint_` qualifiers for texture sampling
- Avoid branching where possible
- Consider LOD variants for complex shaders
