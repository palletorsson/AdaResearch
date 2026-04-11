# Constraint Web

5x5 tile grid implementing constraint satisfaction — stepping on tiles collapses their color domain and propagates constraints to neighbors.

## Behavior

Extends `Area3D`. Teaches CSP (Constraint Satisfaction Problem) solving.

- 25 tiles start in superposition, flickering between 4 domain colors (R, B, G, Y)
- Stepping on a tile collapses it to one color
- Adjacent tiles propagate arc-consistency constraints (no same-color neighbors)
- Empty domain = explosion dealing 20.0 damage
- Flicker speed 6.0, propagation delay 0.3s

## Files

| File | Purpose |
|------|---------|
| `constraint_web.gd` | Main script — CSP logic, domain propagation, tile grid |
| `constraint_web.tscn` | Scene |

## Key State

- `_tile_domains` — Remaining valid colors per tile
- `_tile_collapsed` / `_tile_assigned` — Collapse tracking
- `_propagation_queue` — Pending constraint propagation
