# Pollock 2D -- Action Painting Simulation

A two-part simulation of Jackson Pollock's action painting technique, combining a 2D pixel-level paint engine with a 3D presentation frame and animated brush cursor. This artifact teaches the concept of **gesture-based randomness** -- how randomized direction changes, splatter probabilities, and drip patterns along flowing lines can procedurally recreate the structured chaos of abstract expressionist painting.

## How It Works

### paint_dripping_2d.gd -- 2D Paint Engine

1. **Canvas** -- Creates an `Image` of configurable size, filled with a beige background color.

2. **Lines** -- Each line starts at a random position with a random direction. At each step:
   - The direction rotates by a random angle (controlled by `line_curviness`).
   - A circle is drawn at each point along the path to form a thick stroke.
   - Width varies randomly (0.8--1.2x) for organic thickness variation.
   - 10% of points along the line spawn additional drip circles.
   - Lines bounce off canvas edges instead of clipping.

3. **Drips** -- Circles drawn at random positions. Each has a `splatter_chance` probability of spawning 1--10 secondary splatter drops radiating outward.

4. **Color palette** -- Six Pollock-inspired colors: black, dark gray, white, brown, deep blue, and dark red.

5. **Continuous painting** -- A timer adds new strokes at `paint_interval` seconds. Paint intensity (number of drips and lines per interval) ramps up over `paint_buildup_duration` seconds using linear interpolation, simulating a painting session that grows denser over time.

6. **Stroke signal** -- Each completed line emits a `stroke_path_generated` signal with the path, color, width, and duration for the 3D brush cursor to follow.

### pollock_painting_in_3d.gd -- 3D Presentation Frame

1. **SubViewport rendering** -- The 2D painting runs inside a SubViewport. A Sprite3D displays the viewport texture with configurable `pixel_size`.

2. **Frame construction** -- A backing panel and decorative frame are built from QuadMesh instances positioned behind and around the painting.

3. **Floor layout** -- When `place_on_floor` is true, the sprite is rotated to lie flat (like a canvas on a studio floor).

4. **Brush cursor** -- A small sphere mesh hovers above the painting surface. When the 2D engine emits a stroke path, the cursor's position is animated along the corresponding world-space trajectory using a Tween, with the brush color matching the current stroke.

5. **Coordinate mapping** -- `_canvas_pixel_to_world()` converts 2D pixel coordinates to 3D world positions relative to the Sprite3D transform.

## Parameters

### paint_dripping_2d.gd

| Parameter | Default | Description |
|-----------|---------|-------------|
| `canvas_size` | (1200, 800) | Pixel dimensions of the canvas |
| `background_color` | Beige | Canvas background color |
| `min_drip_size` / `max_drip_size` | 1.0 / 15.0 | Drip circle radius range |
| `drip_count` | 50 | Initial drip count |
| `splatter_chance` | 0.3 | Probability of splatter per drip |
| `max_splatter_count` | 10 | Max splatter drops per drip |
| `min_line_width` / `max_line_width` | 0.8 / 6.0 | Stroke width range |
| `line_segment_length` | 10.0 | Distance per line step |
| `line_curviness` | 0.3 | Max direction change per step |
| `line_count` | 20 | Initial line count |
| `min_line_points` / `max_line_points` | 10 / 100 | Points per line range |
| `paint_interval` | 4.0 | Seconds between new stroke batches |
| `initial_paint_ratio` | 0.15 | Starting density fraction |
| `paint_buildup_duration` | 80.0 | Seconds to reach full density |

### pollock_painting_in_3d.gd

| Parameter | Default | Description |
|-----------|---------|-------------|
| `pixel_size` | 0.0035 | World units per pixel |
| `frame_margin` | 0.14 | Frame border width |
| `frame_depth` | 0.02 | Frame offset depth |
| `frame_color` | Dark brown | Frame material color |
| `backing_color` | Off-white | Backing panel color |
| `place_on_floor` | true | Lay painting flat on floor |
| `simulate_brush_motion` | true | Enable animated brush cursor |
| `brush_radius` | 0.045 | Brush cursor sphere radius |
| `brush_hover_height` | 0.055 | Brush height above canvas |

## Features

- Pixel-level painting on an Image with circle and line primitives
- Direction-based line flow with edge bouncing
- Splatter probability and radial scatter for organic drip patterns
- Gradual paint buildup over time with intensity ramping
- SubViewport-to-Sprite3D rendering pipeline
- Tween-based brush cursor animation synchronized to stroke paths
- Signal-driven coordination between 2D and 3D components

## Files

| File | Description |
|------|-------------|
| `paint_dripping_2d.gd` | 2D pixel-level Pollock painting engine |
| `pollock_painting_in_3d.gd` | 3D frame, SubViewport display, and brush cursor |
| `paint_dripping_2d.tscn` | Scene file for the 2D painting node |
| `PollockPaintingIn3d.tscn` | Scene file for the 3D framed presentation |
