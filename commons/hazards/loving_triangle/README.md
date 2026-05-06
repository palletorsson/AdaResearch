# Loving Triangle

Non-hostile companion entity that dances with the Becoming Catalyst — triangles as atoms of 3D worlds.

## Behavior

Extends `CharacterBody3D`. Not an enemy — not destructible.

State machine: **DORMANT → AWARE → CURIOUS → DANCING → RESONATING → HARMONIZED → RESTING**

- Bond forms through geometric response alone (no combat)
- Responds to Becoming Catalyst modes with visual/motion changes
- Proximity detection radius 12.0
- Orbital animation around the player during DANCING state
- Tier/progression tracking as bond deepens

## Files

| File | Purpose |
|------|---------|
| `loving_triangle.gd` | Main script — state machine, proximity detection, bond tracking |
| `triangle_visual.gd` | Visual effects — mesh, emission, animation |
| `triangle_responses.gd` | Mode-specific response behaviors |
| `loving_triangle.tscn` | Scene |

## Signals

- `state_changed(new_state)` — On state transition
- `mode_response(mode_id)` — On Catalyst mode interaction
- `tier_changed(new_tier)` — On bond progression
- `harmonized()` — On reaching full harmony
