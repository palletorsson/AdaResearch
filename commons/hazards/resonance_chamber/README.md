# Resonance Chamber

Transparent chamber with standing-wave bars — damage occurs at harmonic node positions that shift with frequency.

## Behavior

Extends `Area3D`. Procedural audio sequence hazard.

- Rectangular frame contains horizontal bars at standing-wave node positions
- Player takes damage when overlapping with node bars
- Frequency changes periodically, shifting all node positions
- Visual markers indicate current harmonic pattern

## Files

| File | Purpose |
|------|---------|
| `resonance_chamber.gd` | Main script — frequency cycling, node position calculation |
| `resonance_chamber.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction
