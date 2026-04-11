# Vertical Block Animator

A shader-driven animated pattern of vertical blocks with randomized heights, positions, and gaps that freezes into a unique random configuration after a timeout. This artifact teaches the concept of **pseudo-random functions in shaders** -- how a deterministic hash function (`fract(sin(dot(...)))`) can generate apparently random values on the GPU, and how seeding that function with time creates animation while seeding with a fixed value creates a frozen random pattern.

## How It Works

### VerticalBlockAnimator.gd -- Script Controller

1. Loads and applies the `SquareWavePattern.gdshader` to a MeshInstance3D.
2. After `auto_stop_seconds` (default 20), the animation freezes:
   - `time_scale` is set to 0.0 (stops time progression).
   - `custom_time` is set to a random value between 1000 and 10000, freezing the shader at a unique random pattern.

### SquareWavePattern.gdshader -- GPU Pattern Generator

1. **Pseudo-random function** -- Uses the classic shader hash: `fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453)`. This maps any 2D coordinate to a deterministic but unpredictable float in [0, 1].

2. **Time quantization** -- `seed_time = floor(TIME * time_scale)` creates discrete time steps, causing the pattern to jump between random configurations rather than smoothly animating.

3. **Segment generation** -- UV coordinates are mapped to a virtual resolution (default 1024x256). The X axis is divided into segments of `segment_width` pixels. For each segment:
   - A random gap offset is computed (5--15 pixels).
   - A random block height is computed (20 to full height).
   - A random Y position is computed for the block.

4. **Rendering** -- Each pixel checks whether it falls inside a colored block or in a gap/background area. Blocks render as `block_color` (default orange), gaps as `background_color` (default light gray).

5. **Freezing** -- When `custom_time` is set to a positive value, it overrides the built-in `TIME`, locking the pattern at whatever the hash function produces for that value.

## Parameters

### VerticalBlockAnimator.gd

| Parameter | Default | Description |
|-----------|---------|-------------|
| `auto_stop_seconds` | 20.0 | Seconds before freezing (0 = never) |

### SquareWavePattern.gdshader (Uniforms)

| Uniform | Default | Description |
|---------|---------|-------------|
| `time_scale` | 0.2 | Speed of pattern changes (0 = frozen) |
| `segment_width` | 20.0 | Pixel width of each vertical segment |
| `background_color` | (0.8, 0.8, 0.8) | Color of gaps/background |
| `block_color` | (1.0, 0.3, 0.0) | Color of blocks (orange) |
| `custom_time` | -1.0 | Override time (-1 = use engine TIME) |
| `virtual_resolution` | (1024, 256) | Logical pixel grid size |

## Features

- GPU-based pseudo-random pattern generation (no CPU particle overhead)
- Deterministic hash function for reproducible patterns from any seed
- Time-quantized animation creating discrete pattern jumps
- Freeze-to-random mechanism: stop animation at a unique configuration
- Virtual resolution for consistent appearance across mesh sizes
- Per-segment random height, position, and gap width

## Files

| File | Description |
|------|-------------|
| `VerticalBlockAnimator.gd` | Script that applies shader and handles auto-freeze |
| `SquareWavePattern.gdshader` | Spatial shader generating randomized vertical block patterns |
| `vertical_block_animator.tscn` | Single animator scene |
| `vertical_block_animator_collection.tscn` | Collection of multiple animators |
