# Catalyst Vent / Foe — Tuning Cheatsheet

All knobs you can twist per-placement, with sensible defaults.

## Token grammar

Two equivalent forms — both end up calling `apply_grid_config({...})`
on the spawned node.

### Vent (interactables layer)

```
catalyst_vent:0:0:emit_interval_s=2.0:wave_size=5:start_delay_s=3.0:damage_percent=10
```

`<lookup_name>:<rotation>:<y_offset>[:k=v[:k=v...]]`

### Vent shorthand (utilities layer, editor-painted)

```
e:RATE:WAVE:DELAY
```

Translated by `CatalystVentScanner` → equivalent to the above.
Examples:

| Token       | Meaning                                |
|-------------|----------------------------------------|
| `e`         | rate=2s · wave=5 · delay=3s · damage=10% |
| `e:1.5`     | rate=1.5s, others default              |
| `e:1.5:10`  | rate=1.5s, wave=10                     |
| `e:1.5:10:0`| rate=1.5s, wave=10, **no warmup**      |

## Vent tunables

| Key                | Default | Meaning |
|--------------------|---------|---------|
| `emit_interval_s`  | 2.0     | Seconds between emissions after warmup ends |
| `wave_size`        | 5       | Max foes this vent will emit before going quiet |
| `start_delay_s`    | 3.0     | Warmup pause before the FIRST emission. Lets the player pick up the bracelet, get oriented |
| `pillar_height`    | 4.0     | Visual only — how tall the marker pillar is |

## Foe tunables (per-emit defaults)

If you place a *direct* `catalyst_foe:0:0:k=v` instead of letting a vent
spawn it, these apply to that single foe. Vents spawn foes with their
script defaults; future iteration could pass per-vent foe overrides.

| Key                  | Default | Meaning |
|----------------------|---------|---------|
| `step_period_s`      | 0.7     | Seconds per cell of walking |
| `contact_radius`     | 0.6     | Distance threshold for "touched" |
| `damage_percent`     | 10.0    | % of GameManager.max_player_health inflicted on contact |
| `damage_cooldown_s`  | 0.6     | Min seconds between damage applications (anti-spam) |
| `initial_state`      | "foe"   | Start as `foe` (default) or `friend` for testing |

## Per-sequence kind dispatch (no token needed)

The catalyst projectile's mode (transformation, swarm, cellular, …)
selects the **friend behavior** at hit time — see `MODE_BY_ID` in
`catalyst_foe.gd`. To bias a whole map, place vents and let players
fire the matching bracelet mode. To force a specific kind in
`/editor`, use the dropdown in the Play tab's catalyst HUD.

## Common patterns

### Onboarding map (gentle)
```
catalyst_vent:0:0:emit_interval_s=4.0:wave_size=3:start_delay_s=8.0
```
8s warmup, slow rate, only 3 foes — for first-time players.

### Pressure test (siege)
```
catalyst_vent:0:0:emit_interval_s=0.7:wave_size=20:start_delay_s=0
```
No warmup, fast rate, big wave — feels like a swarm.

### Final boss (high damage)
```
catalyst_vent:0:0:emit_interval_s=1.5:wave_size=10:start_delay_s=2:damage_percent=25
```
4 catches → death.

### Background ambient (low pressure)
```
catalyst_vent:0:0:emit_interval_s=10.0:wave_size=3:start_delay_s=15.0
```
For maps where catalyst is incidental — one foe every 10 seconds, only 3.

## Where these get applied

1. **Vent's `_physics_process`** reads `start_delay_s` first, then
   switches to `emit_interval_s`. Stops at `wave_size`.
2. **Foe's `_physics_process`** uses `step_period_s` for walking.
3. **Foe's player-contact** uses `damage_percent` + `damage_cooldown_s`.
4. **Foe's `hit_by_catalyst_mode`** uses the projectile's mode_id to
   pick the friend behavior (goo / transport / swarm / drainfriend).

## Editing existing maps

To tune a map without regenerating:

1. Open the map in `/editor`
2. Compose tab → click the catalyst_vent artifact → inspector shows tokens
3. Or edit `commons/maps/<name>/map_data.json` directly and look for
   `catalyst_vent:0:0:...` — append/edit the `:k=v` parts. Save through
   the editor (so compact-rows format is preserved).

## Test map references

The test maps were reorganised on 2026-05-04 to mirror the auto-research
matrix lab (`commons/testing/catalyst_matrix_lab.gd`). One map per
catalyst projectile mode, chained via teleporter back to `01_Primitives`:

| Map                          | Mode pre-armed   | Tunable variation |
|------------------------------|------------------|--------------------|
| `Catalyst_01_Primitives`     | primitives       | baseline goo, slow bouncy ball |
| `Catalyst_02_Transformation` | transformation   | `emit_interval_s=2.5` (transport — pushes peers) |
| `Catalyst_03_Chromatic`      | chromatic        | RGB pulse projectile |
| `Catalyst_04_Forces`         | forces           | `emit_interval_s=1.5` `wave_size=6` (faster swarm) |
| `Catalyst_05_Waveform`       | waveform         | sine-wave projectile |
| `Catalyst_06_Chaos`          | chaos            | **two vents** (one fast, one slow) |
| `Catalyst_07_Cellular`       | cellular         | drainfriend behavior on contact |
| `Catalyst_08_Fractal`        | fractal          | split-and-recurse projectile |
| `Catalyst_09_Branching`      | branching        | tree-spreading projectile |
| `Catalyst_10_Swarm`          | swarm            | **two vents** flanking pedestal |

All test maps regenerate via (encyclopedia must be running on :3003):

    python tools/generate_catalyst_test_maps.py

The teleporter chain is wired automatically by the generator — Swarm
loops back to Primitives so a continuous test run cycles through every
mode without leaving the catalyst sequence.
