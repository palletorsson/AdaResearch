# Random Point

A minimal artifact that places a single grabbable point at a random position on the XY plane. The point displays its coordinates as a live-updating label, and in VR it can be picked up and repositioned within a bounded area. This is the simplest possible demonstration of random sampling in 2D space.

## Concept Taught

Before understanding distributions, random walks, or stochastic processes, learners need to grasp the most basic unit of randomness: a single random sample. This artifact teaches what it means to draw one random point from a uniform distribution over a 2D region. The coordinate label makes the abstract concept of "(x, y) drawn from [-0.8, 0.8] x [-0.8, 0.8]" concrete and visible. The VR interaction adds a physical dimension -- learners can move the point and see its coordinates update, building intuition about coordinate systems and bounded regions.

## How It Works

1. **Point instantiation** -- On `_ready()`, the script loads the `grab_sphere_point_with_color.tscn` scene from the commons primitives library and instantiates a single grabbable point.
2. **Random placement** -- The point's X and Y coordinates are drawn from `randf_range(-area_half_extent, area_half_extent)`. The Z coordinate is fixed at 0.0, constraining the point to the XY plane.
3. **Coordinate label** -- A `Label3D` child named "XYLabel" is created (or found if it exists) and positioned above the point. It displays the point's coordinates formatted as `(x.xx, y.yy)` and uses billboard mode to always face the viewer. The label scale is set to 0.1 for readability.
4. **VR drop handling** -- When the point is dropped in VR (via the `dropped` signal), its position is clamped back within the `area_half_extent` bounds and the Z coordinate is reset to 0.0.
5. **Continuous boundary enforcement** -- In `_process()`, the point's position is checked every frame and clamped to the bounded region, preventing it from being dragged outside the valid area. The label updates whenever clamping occurs.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `area_half_extent` | float | 0.8 | Half-width of the valid placement region on each axis |

## Features

- Single random point on the XY plane
- Live-updating coordinate label with billboard rendering
- VR-grabbable via the shared grab sphere primitive
- Continuous boundary clamping keeps the point within bounds
- Z-axis locked to 0.0 for clean 2D visualization
- Minimal design focuses attention on the core concept

## Files

| File | Description |
|------|-------------|
| `randompoint.gd` | Main script -- point placement, label updates, boundary clamping |
| `randompoint.tscn` | Scene file |
