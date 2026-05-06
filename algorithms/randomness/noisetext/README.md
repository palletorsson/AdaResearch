# Noise Text

A `TextMesh` displaying the text "ADA RESEARCH" with its surface displaced and colored by animated noise, turning flat typography into a living, undulating 3D form. The same noise shader used by the Noise Sphere is applied here, demonstrating that noise displacement works on any mesh geometry -- not just spheres.

This artifact teaches that **noise as a universal deformation tool** applies equally to any surface. The same displacement function that creates planet-like terrain on a sphere produces organic rippling across letterforms. The concept being taught is domain independence -- noise functions do not care about the shape they deform.

## How It Works

1. **TextMesh Geometry**: Godot's `TextMesh` generates 3D geometry from the text string "ADA RESEARCH". This mesh has vertices distributed across the letter surfaces, which the shader can displace.

2. **Vertex Displacement**: The `noisePlanet2.gdshader` evaluates 2D noise at each vertex (using X and Z coordinates scaled by `noise_scale`). With `noise_scale = 0.5`, the displacement is low-frequency relative to the text geometry, creating broad undulating waves across the letters.

3. **Elongation**: The `elongation_factor` of 2.0 stretches the geometry vertically before noise evaluation, creating taller, more dramatic deformation along the Y axis.

4. **Rainbow Coloring**: The same animated HSV-to-RGB rainbow cycling colors each fragment based on its noise value, producing a shimmering multicolored text surface.

5. **Camera**: The scene includes a `Camera3D` positioned above and looking down at the text at a slight angle.

## Parameters

**Shader uniforms (set in the scene):**

| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `noise_scale` | float | 0.5 | Frequency of the noise pattern (low = broad waves) |
| `height_multiplier` | float | 0.2 | Amplitude of vertex displacement along normals |
| `noise_speed` | float | 0.05 | Speed of noise animation drift |
| `elongation_factor` | float | 2.0 | Vertical stretch factor before noise evaluation |
| `hue_shift_speed` | float | 0.05 | Speed of rainbow hue cycling |

## Features

- Noise displacement applied to 3D text geometry
- Low-frequency noise creates broad undulating waves across letterforms
- Animated HSV rainbow coloring synchronized with displacement
- Vertical elongation stretches deformation for dramatic effect
- Demonstrates that noise displacement is geometry-agnostic
- Self-illuminated via noise-modulated emission

## Files

| File | Description |
|------|-------------|
| `noisetext.tscn` | Scene file -- TextMesh with noise displacement shader, Camera3D |

**Shared shader:** `commons/resourses/shaders/noisePlanet2.gdshader`
