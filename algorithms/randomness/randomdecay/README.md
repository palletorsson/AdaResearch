# Random Decay

Visualizes radioactive-style random decay on a grid of objects. Each element has an independent probability of decaying per frame, demonstrating how deterministic statistical distributions emerge from per-element randomness.

## How It Works

A grid of 3D objects (prisms) is created at startup. Each frame, surviving elements are tested against a decay probability — those that "decay" are removed or visually marked. The result shows the characteristic exponential decay curve emerging from individual random events, connecting to half-life concepts from nuclear physics.

A MultiMesh variant (`random_decay_multimesh.gd`) uses `MultiMeshInstance3D` for efficient rendering of large grids.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `grid_size` | 9×9 | Grid dimensions |
| `spacing` | 0.021 | Distance between elements |
| `offset` | 0.085 | Grid offset |

## Files

- `scripts/random_decay_manger.gd` — Grid creation and per-frame decay logic.
- `scripts/random_decay_multimesh.gd` — MultiMesh variant for large grids.
- `scenes/random_decay_multimesh.tscn` — MultiMesh scene.
- `scenes/random_decay_objects.tscn` — Standard object scene.
