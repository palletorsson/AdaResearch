# Spatial Voronoi

Ground plane divided into Voronoi cells — drifting seed points determine cell types that apply status effects to the player.

## Behavior

Extends `Area3D`. Spatial-partitioning sequence hazard.

- ~8 seed points drift slowly across the ground
- Each cell has a danger type: SAFE, DAMAGE, SLOW, HEAL
- Player's nearest seed determines which cell they occupy
- Seeds periodically shuffle their danger types
- Thin cylinder edges mark approximate cell boundaries

## Files

| File | Purpose |
|------|---------|
| `spatial_voronoi.gd` | Main script — seed management, nearest-neighbor lookup, effects |
| `spatial_voronoi.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction
