# Torus Cylinder

Animated 3D transformation demonstration pairing a continuously rotating torus with a sinusoidally oscillating cylinder. An ImmediateMesh motion trail traces the cylinder's path, making the sine wave visible in space.

## Concept Taught

**Rotation, periodic translation, and optional scale pulsing** are the fundamental animated transformations. The torus demonstrates constant angular velocity around the Y-axis, the cylinder demonstrates simple harmonic motion, and the motion trail shows the accumulated trajectory as a fading line strip. Together they show how per-frame transform updates create dynamic scenes.

## How It Works

1. `_ready()` procedurally creates a `TorusMesh` and a `CylinderMesh` with configurable sizes and colors.
2. Each frame, the torus rotates by `delta * torus_rotation_speed` and optionally pulses its scale.
3. The cylinder's Y-position follows `sin(time * cylinder_osc_speed) * cylinder_osc_range`.
4. When `show_trail` is enabled, the cylinder's position is recorded and drawn as a fading `PRIMITIVE_LINE_STRIP` using ImmediateMesh with per-vertex alpha for a fade-in effect.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `torus_rotation_speed` | float | 0.5 | Torus Y-rotation speed (rad/s) |
| `torus_scale_pulse` | float | 0.0 | Scale breathing amplitude (0 = off) |
| `torus_scale_pulse_speed` | float | 1.0 | Scale breathing frequency |
| `torus_color` | Color | pink | Torus material color |
| `torus_radius` | float | 1.0 | Torus outer size factor |
| `cylinder_osc_speed` | float | 1.5 | Oscillation frequency multiplier |
| `cylinder_osc_range` | float | 1.5 | Peak vertical amplitude |
| `cylinder_color` | Color | purple | Cylinder material color |
| `cylinder_radius` | float | 0.3 | Cylinder top radius |
| `cylinder_height` | float | 1.2 | Cylinder height |
| `show_trail` | bool | true | Draw the motion trail |
| `trail_length` | int | 120 | Number of trail sample points |
| `trail_color` | Color | light blue | Trail line color with alpha |

## Files

| File | Description |
|------|-------------|
| `toruscylinder.gd` | Main script: mesh creation, animation, ImmediateMesh trail |
| `toruscylinder.tscn` | Minimal scene wrapping the script |
