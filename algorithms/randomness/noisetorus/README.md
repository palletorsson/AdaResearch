# Noise Torus

A torus mesh with animated noise displacement and rainbow coloring, creating a continuously morphing donut-shaped form. The scene uses a dedicated torus noise shader with high-frequency settings, plus a secondary prism mesh with the planet noise shader, creating a two-object noise composition.

This artifact teaches how **noise displacement on a torus** produces fundamentally different visual patterns than on a sphere or flat surface. The torus topology -- with its inner and outer radii, its hole, and its periodic surface -- creates unique folding and interference patterns when displaced by noise. Topology shapes the expression of randomness.

## How It Works

1. **Torus Mesh**: A `TorusMesh` with inner radius 1.127 is scaled to 1.835x, creating a substantial donut shape. The torus topology provides a surface that wraps in two directions, producing distinct noise patterns compared to a sphere.

2. **Torus Noise Shader**: The `noiseTorus.gdshader` is functionally identical to `noisePlanet2.gdshader` -- both use the same 2D hash-based noise for vertex displacement and HSV-to-RGB rainbow fragment coloring. The key difference is in the shader parameters applied in the scene:
   - `noise_scale = 3.575` -- moderately high frequency
   - `noise_speed = 0.935` -- fast animation
   - `elongation_factor = 3.71` -- strong vertical stretching
   - `hue_shift_speed = 0.725` -- rapid rainbow cycling

3. **Secondary Object**: A prism mesh is placed above the torus using the `noisePlanet2.gdshader` with different settings (`noise_scale = 14.255`, fine detail), adding a contrasting noise-displaced geometric form to the composition.

4. **Animation**: Both shaders animate via TIME-offset noise coordinates and cycling hue values, producing continuous morphing and color shifting.

## Parameters

**Torus shader uniforms (set in the scene):**

| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `noise_scale` | float | 3.575 | Frequency of noise displacement on the torus |
| `height_multiplier` | float | 0.2 | Amplitude of vertex displacement |
| `noise_speed` | float | 0.935 | Speed of noise drift (fast) |
| `elongation_factor` | float | 3.71 | Vertical stretch before noise evaluation |
| `hue_shift_speed` | float | 0.725 | Speed of rainbow hue cycling (fast) |

**Prism shader uniforms:**

| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `noise_scale` | float | 14.255 | High-frequency noise for fine detail |
| `noise_speed` | float | 0.05 | Slow animation drift |
| `elongation_factor` | float | 2.0 | Moderate vertical stretch |

## Features

- Noise-displaced torus demonstrating topology-dependent noise patterns
- Fast noise animation and rapid rainbow cycling for dynamic visuals
- Strong vertical elongation creating dramatic deformation
- Secondary prism mesh with high-frequency noise for compositional contrast
- Two distinct noise shaders applied in one scene
- Self-illuminated via noise-modulated emission
- Double-sided rendering (cull disabled)

## Files

| File | Description |
|------|-------------|
| `noisetorus.tscn` | Scene file -- torus mesh with torus shader, prism mesh with planet shader, Camera3D |

**Shared shaders:**
- `commons/resourses/shaders/noiseTorus.gdshader` -- torus noise displacement
- `commons/resourses/shaders/noisePlanet2.gdshader` -- planet noise displacement (used on prism)
