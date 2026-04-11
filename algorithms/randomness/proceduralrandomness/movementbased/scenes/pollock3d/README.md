# Pollock 3D -- Three-Dimensional Action Painting

A real-time 3D paint simulation where strokes are built from flattened spheres ("splats") placed along randomized curves with viscosity-based drip and splatter physics. This artifact teaches the concept of **randomness constrained by physical simulation** -- how combining random control points with viscosity parameters (thin, medium, thick) produces drip patterns that feel physically plausible while remaining procedurally generated.

## How It Works

1. **Canvas** -- A PlaneMesh rotated to face the camera serves as the painting surface. A `paint_container` Node3D holds all generated splats.

2. **Stroke generation** -- A timer triggers new strokes at `stroke_interval` seconds (up to `max_active_strokes` concurrent):
   - A random start point is chosen within the canvas bounds.
   - A random viscosity type is selected (Thin, Medium, or Thick), each with different `drip_speed`, `spread_factor`, `color_opacity`, and `gravity_effect`.
   - 3--8 control points are generated with random angles and distances, biased downward by the viscosity's gravity effect.
   - A Curve3D is built from the control points.

3. **Stroke animation** -- Each frame advances the stroke's progress along its curve:
   - New splats (flattened spheres) are placed at sampled positions.
   - Width tapers toward the end of the stroke using a squared falloff.
   - **Drips** -- When the curve tangent points downward, there is a probability of spawning a drip: a mini-curve descending from the stroke with shrinking splat sizes.
   - **Splatters** -- Random satellite splats are scattered around the main stroke, with count and distance scaled by the viscosity's spread factor.

4. **Viscosity types**:
   - **Thin** -- Fast drip speed (2.0), wide spread (1.5x), slight transparency, strong gravity.
   - **Medium** -- Balanced parameters (1.0x across the board).
   - **Thick** -- Slow drip speed (0.6), narrow spread (0.7x), full opacity, weak gravity.

5. **Splat limiting** -- A rolling window of `max_splats` (default 5000) prevents unbounded node growth. When the limit is exceeded, the oldest splats are freed.

6. **Interaction** -- Pressing Space clears all paint and resets.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `max_splats` | 5000 | Maximum splat nodes before oldest are removed |
| `canvas_size` | (10, 6) | Canvas dimensions in world units |
| `max_line_width` | 0.35 | Maximum stroke width |
| `stroke_interval` | 0.5 | Seconds between new strokes |
| `stroke_duration` | 1.5 | Base duration of each stroke |
| `max_active_strokes` | 3 | Maximum concurrent animated strokes |

## Features

- Three viscosity presets with physically motivated parameters
- Curve3D-based stroke paths with random control points and gravity bias
- Tangent-aware drip generation on downward-sloping strokes
- Radial splatter scatter scaled by viscosity spread factor
- Rolling window splat limit for memory management
- Flattened sphere splats (Z-scaled to 0.3) for paint-like appearance
- Real-time continuous painting with concurrent stroke animation

## Files

| File | Description |
|------|-------------|
| `pollock_3d.gd` | 3D action painting engine with viscosity simulation |
| `pollock_3d.tscn` | Scene file for the 3D painting system |
