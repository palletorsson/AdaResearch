# Time Limit

Countdown timer UI that restarts the level when time runs out.

## Behavior

Extends `Control`. Time pressure system.

- Displays countdown with color transitions: white (normal) → yellow (warning) → red (critical)
- Audio ticks and timeout sound
- Auto-restart with fade-out on expiry
- Integration with game manager for level reload

## Files

| File | Purpose |
|------|---------|
| `timelimit.gd` | Main script — timer, UI, color transitions |

## Signals

- `time_warning()` / `time_critical()` / `time_expired()`
- `countdown_tick()` — Per-second tick

## Key Methods

- `reset_timer()` / `pause_timer()` / `resume_timer()`
