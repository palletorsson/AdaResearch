# Recursion Spiral

Fibonacci spiral of self-similar sphere nodes — destroying a parent destroys all children.

## Behavior

Extends `Node3D`. Recursive emergence sequence hazard.

- Spawns children recursively at golden-angle intervals (137.5°)
- Each child is 0.618x parent size, up to depth 5
- Destroying a parent destroys all its descendants
- Contact damage proportional to 1/depth (larger nodes hurt more)
- Nodes pulse with emission based on depth level

## Files

| File | Purpose |
|------|---------|
| `recursion_spiral.gd` | Main script — recursive spawning, golden ratio geometry |
| `recursion_spiral.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction
