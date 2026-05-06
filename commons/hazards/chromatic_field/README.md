# Chromatic Field

Three overlapping colored spheres (RGB) that rotate independently and deal damage based on dominant hue.

## Behavior

Extends `Area3D`. Environmental hazard teaching color mixing and perception.

- 3 mesh spheres (red, green, blue) rotate on independent axes
- Hue cycles via HSV animation (hue_cycle_speed 0.15)
- Damage per second: 8.0, field radius: 2.0
- Disk underlay marks the hazard zone

## Files

| File | Purpose |
|------|---------|
| `chromatic_field.gd` | Main script — sphere rotation, hue cycling, damage |
| `chromatic_field.tscn` | Scene |

## Signals

- `enemy_destroyed` — Emitted on destruction
