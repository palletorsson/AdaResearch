# Isosurface Trap

Metaball scalar field hazard — charge points drift toward the player, causing the isosurface boundary to bulge.

## Behavior

Extends `Area3D`. Isosurfaces sequence hazard.

- ~6 charge points define a scalar field (sum of strength/distance)
- Charges drift toward the player, deforming the field boundary
- Ring of indicator spheres marks the isosurface boundary
- Damage proportional to scalar field value at player position

## Files

| File | Purpose |
|------|---------|
| `isosurface_trap.gd` | Main script — scalar field sampling, charge drift, boundary visualization |
| `isosurface_trap.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction
