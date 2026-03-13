# Noise Sphere

A large sphere with its surface displaced and colored by animated 2D noise, creating an organic, pulsating planet-like object. The noise shader deforms the sphere's vertices along their normals and applies a cycling rainbow hue, producing a constantly shifting alien world.

This artifact teaches how **noise-driven vertex displacement** transforms a simple geometric primitive into a complex organic form. The sphere's surface is entirely defined by a noise function evaluated at each vertex -- the same noise value that pushes the vertex outward also determines its color intensity. Structure and appearance are unified through a single noise field.

## How It Works

1. **Vertex Displacement**: In the vertex shader, each vertex position is fed into a 2D hash-based noise function (using the vertex's X and Z coordinates scaled by `noise_scale`). The resulting noise value displaces the vertex outward along its normal by `height_multiplier`, creating bumps and valleys across the sphere surface.

2. **Time Animation**: The noise input coordinates are offset by `TIME * noise_speed`, causing the displacement pattern to continuously drift. The TIME value is wrapped with `mod(TIME, 3600.0)` to prevent floating-point precision loss during long sessions.

3. **Rainbow Coloring**: In the fragment shader, the same noise function is evaluated at the same animated coordinates. A hue value cycles over time via `hue_shift_speed`, converting HSV to RGB to produce a smoothly cycling rainbow. The noise value modulates the brightness, so peaks glow brightly while valleys are darker.

4. **Emission**: The fragment emits light at half the albedo intensity, giving the sphere a self-illuminated appearance without external lighting.

5. **Mesh Configuration**: The scene uses a high-resolution `SphereMesh` (128 radial segments, 64 rings) with `flip_faces = true`, allowing the effect to be viewed from inside as well. The mesh is scaled to a radius of approximately 30 units, creating a large environmental object.

## Parameters

**Shader uniforms (set in the scene):**

| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `noise_scale` | float | 48.39 | Frequency of the noise displacement pattern |
| `height_multiplier` | float | 0.2 | Amplitude of vertex displacement along normals |
| `noise_speed` | float | 0.05 | Speed of noise animation drift |
| `elongation_factor` | float | 1.0 | Vertical stretch applied to vertex Y before noise |
| `hue_shift_speed` | float | 0.05 | Speed of the rainbow hue cycling |

## Features

- Procedural vertex displacement using 2D hash-based noise
- Animated noise drift with floating-point precision protection via TIME wrapping
- HSV-to-RGB rainbow color cycling synchronized with displacement
- Noise-modulated emission for self-illumination
- High-resolution sphere mesh (128 x 64) for smooth displacement
- Flipped faces for interior viewing (environment sphere)
- Shared shader (`noisePlanet2.gdshader`) reusable across multiple noise artifacts

## Files

| File | Description |
|------|-------------|
| `noisesphere.tscn` | Scene file -- large sphere with noise displacement shader material |

**Shared shader:** `commons/resourses/shaders/noisePlanet2.gdshader`
