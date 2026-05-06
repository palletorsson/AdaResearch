# Perception Altering Environment

A VR environment that teaches **sensory perception, cognitive distortion, and the subjective nature of experience**. The player walks through colored spatial regions, each of which alters a different dimension of their perception -- color, spatial wobble, movement direction, gravity orientation, or spatial geometry. The experience demonstrates that perception is not a passive recording of reality but an active, distortable process.

## How It Works

1. **Grid floor** -- A large plane with a custom shader draws minor and major grid lines. The shader accepts `wobble_amount`, `color_shift`, and `spatial_distortion` uniforms that are driven in real time by the distortion regions the player enters.

2. **Distortion regions** -- Five translucent `CSGBox3D` zones are placed around the environment, each with an `Area3D` trigger. When the player's body enters a region, its type and intensity are recorded; when the player exits, the effect is removed. Multiple regions can stack.

3. **Perception phases** -- Five continuously advancing phase accumulators (color, wobble, spatial, direction, gravity) drive sinusoidal modulations. Each frame:
   - Active region intensities are multiplied by the global `effect_intensity`.
   - Color shift modulates the grid shader's hue blending.
   - Wobble displaces grid vertices via sine waves on X and Z.
   - Spatial distortion warps UV coordinates radially from the center.
   - Direction shift rotates the XR controller orientation (requires integration with the locomotion system).
   - Gravity distortion tilts the XR camera's Z rotation, creating a visual lean.

4. **Inline fallback shader** -- If no external shader file is found, the script generates a complete spatial shader with grid rendering, vertex wobble, spatial warping, and color-shifting logic.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `environment_size` | Vector3 | `(30, 8, 30)` | Dimensions of the playable area |
| `grid_size` | float | 1.0 | Spacing of minor grid lines |
| `effect_intensity` | float | 1.0 | Global multiplier for all distortion effects |
| `speed_multiplier` | float | 1.0 | Rate at which phase accumulators advance |
| `color_shift_speed` | float | 0.2 | Speed of color phase cycling |
| `wobble_frequency` | float | 0.5 | Speed of wobble phase cycling |
| `distortion_regions` | Array[NodePath] | `[]` | Optional external region nodes |
| `max_color_shift` | float | 0.3 | Maximum hue shift amplitude |
| `max_wobble_amount` | float | 0.1 | Maximum vertex wobble displacement |
| `max_spatial_distortion` | float | 0.2 | Maximum UV warp strength |
| `max_direction_shift` | float | 45.0 | Maximum controller rotation in degrees |
| `direction_shift_smoothness` | float | 0.5 | Smoothing factor for direction changes |
| `enable_gravity_distortion` | bool | true | Whether gravity tilt is active |
| `max_gravity_angle` | float | 15.0 | Maximum camera tilt in degrees |

## Features

- Five distinct distortion types: color shifting, visual wobble, spatial warping, movement direction rotation, and gravity tilt.
- Region-based activation -- effects only engage when the player physically enters a zone.
- Stacking -- overlapping regions combine their effects.
- Full inline shader fallback with grid rendering, vertex displacement, and UV warping.
- XR-aware -- finds the `XROrigin3D`, camera, and controllers for VR integration.
- Fog and directional lighting create an atmospheric base environment.
- Instruction billboard label explains each colored zone to the player.

## Files

| File | Purpose |
|------|---------|
| `perception_altering.gd` | Main scene script -- environment setup, distortion regions, shader driving, XR integration |
