# Kresling Spire

Kresling origami sniper tower that twists from compact disc to tall tower to fire projectiles.

## Behavior

Extends `CharacterBody3D`. State machine: **DISC → RISE → AIM → FIRE → COLLAPSE → RELOCATE**

- Compact disc form for mobility
- Twists and extends into tall tower form for sniping
- Fires `fire_bolt` projectiles at detected player (detection radius 14.0)
- Collapses back to disc to relocate after firing
- Uses `KreslingGeometry` helper for folding/unfolding mesh

## Files

| File | Purpose |
|------|---------|
| `kresling_spire.gd` | Main script — state machine, aiming, firing |
| `kresling_geometry.gd` | Geometry helper — Kresling fold math |
| `kresling_spire.tscn` | Scene |

## Signals

- `fired_projectile(position, direction)` — On projectile launch
- `enemy_destroyed` — On destruction
