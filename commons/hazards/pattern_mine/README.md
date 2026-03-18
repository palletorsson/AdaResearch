# Pattern Mine

Minefield with SDF (Signed Distance Field) contour rings — proximity to mines triggers detonation.

## Behavior

Extends `Area3D`. Pattern generation sequence hazard.

- 8 sphere mines arranged in a spatial pattern
- 3 concentric torus rings per mine show distance contours
- SDF proximity detection: entering inner radius triggers detonation with damage
- Mines respawn after cooldown, creating a repeating spatial pattern

## Files

| File | Purpose |
|------|---------|
| `pattern_mine.gd` | Main script — mine layout, SDF detection, respawn |
| `pattern_mine.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction
