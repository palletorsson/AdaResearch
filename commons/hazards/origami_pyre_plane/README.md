# Origami Pyre Plane

Lethal floor hazard — a flat origami rectangle that smolders with paper-fire while cycling through affine transformations.

## Behavior

Extends `Node3D`. Transformation sequence hazard.

- Flat rectangle beneath transport cubes
- Crease edges glow orange while cycling: SCALE → ROTATE → TRANSLATE
- Preserves rectangular identity throughout transformations
- Instant kill on player contact
- Ember particles and parchment coloring
- ImmediateMesh for crease line visualization

## Files

| File | Purpose |
|------|---------|
| `origami_pyre_plane.gd` | Main script — affine cycle, crease glow, damage |
| `origami_pyre_plane.tscn` | Scene |

## Signals

- `player_killed(player)` — On lethal contact
