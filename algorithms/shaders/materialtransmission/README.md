# Material Transmission -- Glass, Crystal, and Refraction

A collection of transparent and translucent objects demonstrating three approaches to **light transmission in real-time rendering**: physically-based refraction, simple glass approximation, and crystal internal reflection. The artifact teaches how light bends when passing through transparent materials (refraction via Snell's law), how Fresnel equations govern the balance between reflection and transmission at surfaces, and how screen-space techniques can approximate these effects on the GPU.

## How It Works

The scene creates 8 geometric objects (spheres, boxes, cylinders, tori, prisms) arranged in a ring, each assigned one of three custom shader types on a rotating basis:

### Advanced Transmission Shader
Samples the screen texture with a UV offset computed from the refracted ray direction (based on index of refraction). Depth-based thickness falloff modulates transmission intensity. Fresnel controls the blend between refracted background color and surface reflection. The result is physically-motivated glass with colored transmission tinting.

### Simple Glass Shader
Uses a rim-lighting approximation where the rim power controls how transparent the center vs. edges appear. No screen-space refraction -- just view-angle-dependent alpha with specular highlights. Lightweight and performant.

### Crystal Shader
Simulates internal reflections with faceted normal perturbation (sine-based distortion of the surface normal). A sparkle effect generates glints at positions where three sine waves align. Time-animated for continuous prismatic shimmering.

All objects rotate and float gently. Material transmission parameters pulse subtly over time for dynamic visual variation.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `object_count` | int | 8 | Number of transparent objects |
| `transmission_strength` | float | 1.0 | Global transmission/transparency amount |
| `refraction_intensity` | float | 0.3 | Refraction UV offset strength |
| `animation_speed` | float | 1.0 | Rotation and floating speed |

## Features

- Three distinct transmission shader techniques (advanced, simple, crystal)
- Screen-space refraction via `hint_screen_texture` sampling
- Depth-based thickness falloff for volumetric glass appearance
- Fresnel-controlled reflection/transmission blend
- Crystal facet simulation with sparkle glints
- Configurable IOR (index of refraction) per object
- Preset system for quick material configuration (subtle, dramatic, crystal_clear)
- Dynamic transmission parameter pulsing

## Files

- `materialstransmission.gd` -- Scene construction, three inline shader definitions, animation system
