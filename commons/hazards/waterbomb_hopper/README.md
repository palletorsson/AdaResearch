# Waterbomb Hopper

Bouncing origami waterbomb tessellation enemy with squash-and-stretch deformation.

## Behavior

Extends `CharacterBody3D`. State machine: **PATROL → DETECT → CHASE → STUNNED**

- Waterbomb base shape built from triangular ImmediateMesh faces
- Bouncing animation with squash-and-stretch deformation
- Patrols a rectangular path
- Can be stunned temporarily
- Emission color for visual feedback

## Files

| File | Purpose |
|------|---------|
| `waterbomb_hopper.gd` | Main script — geometry generation, bounce animation, patrol |
| `waterbomb_hopper.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction
