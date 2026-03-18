# Fetish Torus

Parametric dual-torus primitive with fluid shader-driven color effects. A fluid-colored torus rotates alongside a mirror-black torus tilted at a configurable angle, demonstrating how fragment shaders create animated color patterns on curved parametric surfaces.

## Concept Taught

**Parametric surfaces and shader-driven animation.** A torus is defined by its major radius (center-to-tube) and minor radius (tube thickness). The fluid shader uses time-based sine/cosine functions to cycle colors across the UV space, showing how fragment shaders transform static geometry into dynamic visual experiences. The dual-torus mode contrasts a fluid-colored surface with a mirror-black one to highlight material properties.

## How It Works

1. `_ready()` procedurally creates one or two `TorusMesh` instances based on `dual_torus`.
2. The fluid torus gets an inline `ShaderMaterial` that cycles RGB channels at configurable speeds, blending inner and outer colors via a UV-distance gradient.
3. The black-shine torus uses a `StandardMaterial3D` with zero roughness and full metallic for mirror-like reflections.
4. Each frame, both tori rotate at different speeds and axes, creating an interlocking visual.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `major_radius` | float | 1.0 | Distance from torus center to tube center |
| `minor_radius` | float | 0.4 | Radius of the tube cross-section |
| `ring_count` | int | 48 | Subdivisions around the torus ring |
| `segment_count` | int | 24 | Subdivisions around the tube |
| `rotation_speed` | float | 0.3 | Base rotation speed (rad/s) |
| `inner_color_speed` | float | 0.5 | Shader inner color cycle speed |
| `outer_color_speed` | float | 0.7 | Shader outer color cycle speed |
| `gradient_spread` | float | 0.5 | UV gradient width for color blending |
| `surface_metallic` | float | 0.5 | Metallic amount for the fluid shader |
| `surface_roughness` | float | 0.2 | Roughness amount for the fluid shader |
| `dual_torus` | bool | true | Enable the second mirror-black torus |
| `second_torus_tilt` | float | 75.0 | X-axis tilt of the second torus (degrees) |

## Files

| File | Description |
|------|-------------|
| `fetishtorus.gd` | Main script: procedural torus creation, fluid shader, animation |
| `fetishtorus.tscn` | Minimal scene wrapping the script |
| `fetishtorus.gdshader` | Original fluid color shader (now inlined in script) |
| `blackshine.gdshader` | Original black-shine shader (now replaced by StandardMaterial3D) |
