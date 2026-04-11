# Glass Divider

A frosted glass shader that teaches **screen-space effects, refraction simulation, and post-process blur**. Applied to flat panels in a room-divider scene, the shader reads from the screen texture behind the glass and distorts it with value noise, creating a realistic frosted or etched glass look that obscures what is behind it while still allowing light and color through.

## How It Works

1. **Noise distortion** -- A 2D value noise function (`vnoise`) generates a smooth random field. Its gradient is computed via finite differences and used to offset the screen-space UV coordinates, simulating the way real frosted glass bends light through micro-surface irregularities.

2. **Depth-aware fade** -- The depth texture is sampled to determine how far behind-the-glass geometry is. Distortion strength is attenuated for distant objects using a power-curve falloff, preventing excessive warping of the background.

3. **Directional blur** -- A 4-tap directional blur (up, down, left, right) is applied to the distorted screen sample. The blur radius is specified in pixels and weighted by a strength uniform. This softens the image seen through the glass.

4. **Glass tint** -- The final blurred color is multiplied by a tint color and brightness value, allowing warm, cool, or colored glass effects. Alpha from the tint controls overall transparency.

5. **Render mode** -- `blend_mix`, `cull_disabled`, and `depth_prepass_alpha` ensure the glass works correctly from both sides and blends properly with the scene.

## Parameters

| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `glass_tint` | vec4 | `(0.92, 0.98, 1.0, 0.96)` | Color and alpha of the glass |
| `brightness` | float | 1.0 | Multiplier on the final color |
| `roughness` | float | 0.55 | PBR roughness of the glass surface |
| `metallic` | float | 0.0 | PBR metallic value |
| `specular` | float | 0.5 | Specular reflection intensity |
| `use_noise` | bool | true | Enable noise-based distortion |
| `noise_scale` | float | 40.0 | Frequency of the noise pattern |
| `noise_speed` | float | 0.15 | Animation speed (scrolling noise) |
| `noise_strength` | float | 0.8 | Distortion magnitude |
| `blur_enable` | bool | true | Enable directional blur |
| `blur_radius_px` | float | 2.5 | Blur sample offset in pixels |
| `blur_strength` | float | 1.0 | Weight of blur samples |
| `depth_fade` | float | 0.8 | Depth-based distortion attenuation |

## Features

- Screen-space refraction -- reads from `hint_screen_texture` and `hint_depth_texture`.
- Value noise with gradient computation for physically-motivated distortion directions.
- Depth-aware distortion falloff prevents artifacts on distant geometry.
- 4-direction blur with configurable radius and strength.
- Fully configurable tint, brightness, and PBR surface properties.
- Double-sided rendering (`cull_disabled`) so the glass looks correct from both sides.
- Scene includes multiple divider panels with different glass variants for comparison.

## Files

| File | Purpose |
|------|---------|
| `frostglass.gdshader` | Frosted glass shader with noise distortion, blur, and depth fade |
| `glassdivider.tscn` | Demo scene with office divider panels, stands, and multiple glass materials |
