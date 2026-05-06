# Pipe Dream

A 3D recreation of the classic Windows Pipes screensaver — a single pipe grows through space, randomly changing direction at each joint.

## QFEP Connection

The pipe is a **random walk in 3D** with constrained choices (6 cardinal directions, no backtracking). Each turn is pure entropy (E), but the pipe itself is structure (F) — a continuous, connected form emerging from random decisions. The result: unexpected complexity from trivial rules.

## How It Works

```
1. Start at origin, facing FORWARD
2. Every turn_interval seconds:
   a. Extend pipe segment in current direction
   b. Add spherical joint at corner
   c. Pick new random direction (not current or reverse)
3. Repeat until max_segments reached
```

The direction constraint (no continuing straight, no 180° turns) ensures the pipe always turns, creating the characteristic meandering path.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `pipe_radius` | 0.1 | Thickness of pipe segments |
| `segment_length` | 1.0 | Length of each straight section |
| `turn_interval` | 0.1 | Seconds between new segments |
| `max_segments` | 100 | Total segments before stopping |
| `color` | Cyan | Pipe color (emissive glow) |

## Visual Style

- **Metallic pipes** with emission glow
- **Spherical joints** at corners (slightly larger, darkened)
- **Real-time growth** — watch it build

## Files

| File | Purpose |
|------|---------|
| `pipe_dream.tscn` | Scene root |
| `PipeDream.gd` | Growth logic |

## Usage

```gdscript
var pipes = preload("res://algorithms/randomness/pipedream/pipe_dream.tscn").instantiate()
pipes.max_segments = 200
pipes.turn_interval = 0.05  # Faster growth
pipes.color = Color.MAGENTA
add_child(pipes)
```

## VR Experience

Watch the pipe grow in real-time, filling 3D space with an intricate network. The metallic glow and spherical joints give it a retro-futuristic aesthetic. Position yourself inside the growing structure for an immersive view.

## History

The original Windows 3D Pipes screensaver (1994) became iconic for its hypnotic, ever-growing complexity. This implementation captures the core algorithm while adding modern material effects.

## See Also

- `pixel_cloud/` — Self-avoiding random walk as voxel sculpture
- `randomwalk/` — Various random walk implementations
