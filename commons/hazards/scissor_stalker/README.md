# Scissor Stalker

Spider-like enemy with Hoberman scissor linkage legs that extend to 3x their compact length.

## Behavior

Extends `CharacterBody3D`. State machine: **COMPACT → STALK → POUNCE → ATTACK → RETRACT**

- 6 legs with 3 scissor linkage units each
- Compact form for stealth, extended form for attack
- Legs raise body height proportionally as they extend
- Uses `ScissorLinkage` helper class for mechanical joint behavior

## Files

| File | Purpose |
|------|---------|
| `scissor_stalker.gd` | Main script — state machine, leg coordination |
| `scissor_linkage.gd` | Scissor linkage joint math helper |
| `scissor_stalker.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction
