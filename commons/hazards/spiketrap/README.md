# Spike Trap

Ground spikes that emerge with a warning phase when the player falls or steps on them.

## Behavior

Extends `Area3D`. State machine: **IDLE → WARNING → EMERGING → ACTIVE → RETRACTING → COOLDOWN**

- Configurable spike count and height
- Triggers on fall (velocity threshold) or proximity detection
- Visual and audio warnings before spikes emerge
- Damage dealt during ACTIVE state

## Files

| File | Purpose |
|------|---------|
| `spiketrap.gd` | Main script — state machine, trigger detection, spike animation |

## Signals

- `spike_trap_triggered()` — On activation
- `spike_damage_dealt()` — On damage
- `trap_state_changed()` — On state transition
