# Catalyst Test Maps

10 small arenas, **one per catalyst projectile mode**. Mirrors the
auto-research matrix lab in `commons/testing/catalyst_matrix_lab.gd`,
which validates that every mode lands a transformation on a fresh foe.

Each map pre-arms the bracelet with one specific mode so the player can
shoot immediately and feel that mode in isolation. Teleporters chain in
order, and the last loops back to the first for a continuous walk-
through.

Generate / regenerate (encyclopedia must be running on :3003):

    python tools/generate_catalyst_test_maps.py

(Saves through the encyclopedia API so the JSON lands in compact-rows
format.)

## Matrix

| # | Map                          | Catalyst mode    | Resulting foe_mode | Notes |
|---|------------------------------|------------------|--------------------|-------|
| 01 | `Catalyst_01_Primitives`     | primitives       | GOO            | Bouncy white sphere, slow. Baseline loop. |
| 02 | `Catalyst_02_Transformation` | transformation   | **TRANSPORT**  | Purple beam — friend pushes peer away. |
| 03 | `Catalyst_03_Chromatic`      | chromatic        | GOO            | Orange RGB pulse. |
| 04 | `Catalyst_04_Forces`         | forces           | **SWARM**      | Blue physics-driven, faster wave. |
| 05 | `Catalyst_05_Waveform`       | waveform         | GOO            | Pink sine-wave projectile. |
| 06 | `Catalyst_06_Chaos`          | chaos            | **SWARM**      | Red turbulent shot. **Two vents.** |
| 07 | `Catalyst_07_Cellular`       | cellular         | **DRAINFRIEND**| Green entropic — caught player drags a friend back. |
| 08 | `Catalyst_08_Fractal`        | fractal          | GOO            | Purple split-and-recurse. |
| 09 | `Catalyst_09_Branching`      | branching        | GOO            | Green tree-spreading. |
| 10 | `Catalyst_10_Swarm`          | swarm            | **SWARM**      | Yellow boid cluster. **Two vents flanking.** |

The four `foe_mode` outcomes (GOO / TRANSPORT / SWARM / DRAINFRIEND) are
defined by the `MODE_BY_ID` dict in `commons/hazards/catalyst_foe/catalyst_foe.gd`.
GOO is the default — primitives, chromatic, waveform, fractal, branching
all dispatch as goo (peer infection). The other three result in
distinct friend behaviors.

## How to test in VR

1. Run the project in Godot
2. Load `Catalyst_01_Primitives` (or any map in the chain)
3. Spawn at (1,1) — walk to the height-2 plinth at (2,2)
4. The bracelet is already pre-armed with that map's mode and in
   `shooting_only` mode (no voxel placement)
5. Press trigger to shoot — vent emits foes from the centre after a
   3-second start delay
6. Walk to the corner teleporter to advance to the next mode
7. Foes deal **10% damage** on contact. Player respawns via
   `GameManager._handle_player_death()` (see `DeathEffect` autoload)

## How to test in `/editor`

1. Open `http://localhost:3003/editor`
2. Sidebar → load any `Catalyst_*` map
3. ▶ Play → click anywhere to start
4. The kind dropdown defaults to *goo*. The map's catalyst mode controls
   which foe_mode is applied at runtime in VR; the editor's preview
   uses the dropdown for now (a future iteration could read
   `interactables` and hint the dropdown automatically).
5. L-click foes to turn them.

## Authoring notes

Each map is a 12×10 open-floor arena:

- spawn at (1, 1)
- pedestal at (2, 2) on a height-2 plinth
- vent at (5, 6) — Chaos and Swarm get a second vent at (5, 9) and (7, 8)
- teleporter at (8, 10) targeting the next map (Swarm → Primitives)

Token grammar in `interactables`:

    becoming_catalyst#shooting_only:true#start_mode:<mode>#active_mode:<mode>
    catalyst_vent:0:0#emit_interval_s:2.0#wave_size:5#start_delay_s:3.0

Position separators use `:`, config keys use `#`. See
`_parse_config_token` in `commons/grid/GridInteractablesComponent.gd`.

## Auto-research

The matrix lab validates every mode in CI-style headless runs:

    "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --xr-mode off --headless \
      --script res://commons/testing/catalyst_matrix_lab.gd

Outputs:

- `user://catalyst_matrix/results.md` — visual matrix doc
- `user://catalyst_matrix/results.json` — raw per-mode data
- `user://catalyst_matrix/<mode>_before.png` / `<mode>_after.png`

Use `--no-window` instead of `--headless` if you want the screenshots
to render with a real GPU.
