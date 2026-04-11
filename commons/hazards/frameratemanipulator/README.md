# Framerate Manipulator

Meta-hazard that manipulates game FPS as a gameplay mechanic.

## Behavior

Extends `Node3D`. 5 chaos modes:

1. **SUBTLE_DEGRADATION** — Gradual FPS drop
2. **RANDOM_SPIKES** — Sudden lag spikes
3. **PROGRESSIVE_SLOWDOWN** — Steadily decreasing performance
4. **CHAOTIC_SWINGS** — Wild FPS oscillations
5. **MALICIOUS_FREEZE** — Temporary screen freezes

FPS range 10–120, spike intensity 0.3, frame drop chance 0.1.

## Files

| File | Purpose |
|------|---------|
| `frameratemanipulator.gd` | Main script — FPS control, lag injection, visual glitches |

## Signals

- `fps_changed` — On FPS target change
- `lag_spike_started` / `screen_freeze_started`
- `performance_degraded` / `entity_detected`
