# Noise Field

10x10 grid of tiles driven by FastNoiseLite — tile height and color shift based on scrolling noise values.

## Behavior

Extends `Area3D`. Noise sequence hazard.

- 10x10 tile grid with per-tile height and color driven by SIMPLEX_SMOOTH noise
- Noise offset scrolls over time, creating a shifting danger landscape
- Tiles above damage threshold transition from green (safe) to red (danger)
- Player standing on red tiles takes accumulated damage

## Files

| File | Purpose |
|------|---------|
| `noise_field.gd` | Main script — FastNoiseLite sampling, tile updates, damage |
| `noise_field.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction
