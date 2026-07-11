# Catalyst Foe + Vent (VR mirror of /editor catalyst loop)

A two-piece system that brings the editor's tower-defense game into VR.

## What it does

- **CatalystVent** — a tall grey pillar that emits foes at `emit_interval_s` until `wave_size` is reached, then goes quiet.
- **CatalystFoe** — a CharacterBody3D that walks one cell every `step_period_s` seconds toward the player. When the catalyst projectile (any mode) hits it, it phase-shifts to FRIEND state, takes the projectile's hue, and starts walking toward the nearest other foe to convert it on contact.

This mirrors the editor's `e:RATE:WAVE` token + click-to-turn loop but driven by VR catalyst projectiles.

## Hit contract

Reuses `hit_by_projectile(color: Color)` — the same method `catalyst_target` uses. So **every existing catalyst mode** (primitives, transformation, chromatic, forces, waveform, chaos, fractal, cellular, branching, swarm) automatically transforms foes when their projectile lands. No mode changes required.

## Wiring into a map

`map_data.json` interactables layer:

```json
"interactables": [
  ["catalyst_vent", " ", " "],
  [" ", " ", "catalyst_foe"]
]
```

Or with config:

```json
"catalyst_vent:0:0:emit_interval_s=1.5:wave_size=10"
```

The grid composer calls `apply_grid_config({...})` so the vent / foe pick up the values.

## Behavior

- FOE chases the player. On contact (cell occupancy), emits `caught_player` signal — caller decides what happens (typically: respawn the player at spawn).
- FRIEND chases the nearest other FOE. On contact, calls that foe's `hit_by_projectile()` → chain reaction.
- Grid step is naive (axis-aligned, no BFS) — VR levels are usually open enough for this. Switch to nav-mesh later if needed.

## Files

| File | Role |
|---|---|
| `catalyst_foe.gd` / `.tscn` | The body + state machine |
| `catalyst_vent.gd` / `.tscn` | The spawner + visual pillar |

## Editor parallel

The editor at `/editor` paints `e:RATE:WAVE` utility tokens. This system answers the same primitives in VR:

- `e:` (utility token) ↔ `catalyst_vent` (interactable)
- L-click in editor ↔ trigger-fire the bracelet in VR
- Per-sequence kind dropdown ↔ active catalyst mode (transformation, chromatic, etc.)

## Per-mode friend kinds

Every catalyst mode now maps to a distinct friend kind (`MODE_BY_ID` in `catalyst_foe.gd`):
GOO (primitives), TRANSPORT (transformation), SWARM (forces/swarm/chaos), DRAINFRIEND (cellular),
CHROMA (chromatic), WAVE (waveform — slow-pulses nearby foes), FRACTAL (fractal — split conversion),
BRANCH (branching). Each kind gets its own friend hue and a small badge mesh; GOO stays badge-less.

## What's not yet wired
- **soft_stages.json** auto-detection by sequence — the foe accepts an `initial_state` config but doesn't yet read its sequence's `enemies.kind`.
- **Win/lose narrative banners** in VR — the editor has them; VR maps would need a small HUD or an end-of-sequence chamber transition.
- **Vent visualization in /editor** is the inverse — but the existing `e:` token + grey pillar already mirrors this.
