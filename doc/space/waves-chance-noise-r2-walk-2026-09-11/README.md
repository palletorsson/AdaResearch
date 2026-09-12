# Waves, Randomness and Noise — batch R2 archive: Random_Walk (2026-09-11)

Fable 5.1, the next hall on Astra's route after Random_Remove. One hall: **Random_Walk**, the route's fourth Randomness hall.

## What is here

- `before/` — byte copies taken before the first edit: `random_walk_terrarium.gd` (identical to HEAD; HEAD's copy kept as `random_walk_terrarium.HEAD.gd`), `random_walk_terrarium.tscn` (unchanged), the map (the working tree's — the 10 September recovery's `w` ring, `2` platforms and `wall_height 3`, another hand's uncommitted edit — and HEAD's as `map_data.HEAD.json`), its ten texts including the untracked `final.md` of 8 September, `nature_layer.json`, and `GridInteractablesComponent.gd` (the shared grid component, for its config-key whitelist).
- `before_sha256.txt` / `after_sha256.txt` — hashes before and after; the after list adds the field notes, the two probes, the three tools, the report, the handback and the handoff.
- `.gdignore` — so the archived scripts never compete with the live ones for a class name.

## Structure

The arena's seventy-two `0` cells (2..10 × 2..10) became `1`, and (4,1) `3` became `1`. The museum lays floor only on `1` and read the arena as holes; the grid walked it as ground half a metre below the strip. The `w` perimeter, the ring of `2` platforms (41 cells), the `3` post at (8,1), `wall_height 3`, `gate_depth_rows 0` and the two teleporter `0` cells are as the recovery left them. Under `map_info.museum`: `sculpture_clear_rects` [[3,1,7,5]] (cells 3–6 × 1–4; the far edge is exclusive) and `artifact_placement: "map"`.

## Placement

`random_walk_terrarium:180:-0.3` at (4,1) → `random_walk_terrarium:90#stand:logbook` at (4,1) (the front to the door strip, on the floor). `random_walk_collection:90` (5,1) → (3,7). `lab_room#…` (8,3) → (9,4), `signage_sub` and both annotations rewritten. `random_walk_128` (6,6) → `random_walk_128:0:0:0.2` (3,4). `pixel_cloud:90` (12,1) → `pixel_cloud:90:0:0.5#walk_seed:101` (11,1); `pixel_cloud:270` (0,11) → `…:270:0:0.5#walk_seed:102` (1,11); `pixel_cloud:90` (12,11) → `…:90:0:0.5#walk_seed:103` (11,11). Unchanged: `dark_sphere` (5,7), `random_walk_leash` (8,8), `catalyst_pickup` (6,10), `catalyst_prompter_box` (2,0), `catalyst_vent` (9,0).

## The artifact

`random_walk_terrarium.gd` gained the opt-in `stand:logbook` (the wing, its readout and its three buttons, a body round the case), `follow_one`, a `seed` alias, `_trail_colour`, the API (`set_walk_seed`, `new_seed`, `set_follow_one`, `walker_positions`, `logbook_lines`, `get_logbook_state`), and one fix to shipped behaviour: the keypad's RESET, connected as a zero-argument method to a one-argument signal, now relays through `_on_reset_pressed`. `GridInteractablesComponent.gd` gained `"walk_seed"` in `CONFIG_PARAM_NAMES`.

## Reversal

Copy the `before/` files back over their originals (the terrarium script, the map, the texts, the grid component); delete `field_notes.md`, the two probes, the report, the R2 batch file and the handoff; remove the `walk` line from `tools/run_wcn_probe.sh`, `walk` from `tools/port_wcn_probes_live.py` and the Random_Walk row from `tools/check_wcn_w1_source_review.py`.

## Runtime

Both lanes ran on 2026-09-11, 16:21–16:57: a survey run showed the void and the sealed door; six bare runs and two live runs led to bare 106 / 0 and live 112 / 0, both exit 0, no leak warning, the engine log's only script errors the lab room's own (`lab_room.gd:725`). Godot was free throughout; the runner refused nothing; nothing was terminated.
