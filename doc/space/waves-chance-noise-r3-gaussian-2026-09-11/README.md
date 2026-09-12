# Waves, Randomness and Noise — batch R3 archive: Random_Gaussian (2026-09-11)

Fable 5.1, the next hall on Astra's route after Random_Walk. One hall: **Random_Gaussian**, the route's fifth Randomness hall.

## What is here

- `before/` — byte copies taken before the first edit: `distribution_sampler.gd` (identical to HEAD; HEAD's copy kept as `distribution_sampler.HEAD.gd`), `distribution_sampler.tscn` (unchanged), the map (the working tree's — the 10 September recovery's `museum` block and compact rows, another hand's uncommitted edit — and HEAD's as `map_data.HEAD.json`), its ten texts including the untracked `final.md` of 8 September, and `nature_layer.json`.
- `before_sha256.txt` / `after_sha256.txt` — hashes before and after; the after list adds the field notes, the two probes, the four tools, the report, the handback and the handoff.
- `.gdignore` — so the archived scripts never compete with the live ones for a class name.

## Structure

Rows 14–20 became `1` floor (73 cells: rows 14–15 between the `5`/`6` walls, rows 16–20 wall to wall). The museum lays floor only on `1` and read the south half as holes; the grid walked it as ground half a metre below the north hall. The `wp` wedge at (10,12), which bridged that step in the grid lane, is removed with it. The teleporter's cell (10,3) stays `0` (the grid's rule for a teleporter) and the museum floors it through `museum.floor_cells: [[10,3]]` (12 September). The `w` perimeter, the recovery's nineteen `2` platforms, the `3`–`6` side walls, `wall_height 3` and `gate_depth_rows 0` are as the recovery left them. Under `map_info.museum`: `sculpture_clear_rects` [[9,16,13,21]] (cells 9–12 × 16–20; the far edge is exclusive), `floor_cells` [[10,3]] and `artifact_placement: "map"`.

## Placement

`distribution_sampler:180:0.5:1` (11,19) → `distribution_sampler:180#stand:cabinet` (11,19) (on the floor, in its cabinet, the front north). `random_bell_curve` (10,14) → `random_bell_curve:0:0:0.3` (3,17). `gaussian_random` (10,18) → (10,15). `galton_board:180:1:4` (8,20) → `galton_board:180:0:1.5` (9,20). Unchanged: `distribution_comparator:0:-0.5` (5,18), `dark_sphere` (7,10), `GaussianBlurCircle:0:-0.5` (11,8), `GaussianPaintSplatter:180:1.5` (8,6), `GaussianBlurShader:180:1` (3,2).

## The artifact

`distribution_sampler.gd` gained the opt-in `stand:cabinet` (the cabinet with its body, the lifted display, the shoulder with the keypad and the stand panel BATCH · PAUSE / NEW SEED · BINS, the housed readout, the ghost frames at the expected count per bin, a named seed), `batch_size`, a `seed` alias and `batch` config key, bookkeeping on every path (landed values kept, draws and folds counted through `_fit`, the clamp the display always applied), `bin_probabilities` / `expected_counts` (Φ by Abramowitz–Stegun 7.1.26), `batch`, `set_running`, `new_seed`, `set_sample_seed`, `set_bins`, `cycle_bins`, `in_flight`, `readout_lines`, `landed_values`, `get_stand_state`. No returned value of the shipped path changes.

## Also changed (12 September)

`commons/scenes/endless_museum.gd` (`_derive_map_row`) and `tools/em_map_halls.py`: the `museum.floor_cells` key, gated on the key's presence. `commons/data/book/randomness.json`: the `random gaussian` pearl's hero is `distribution_sampler`.

## Reversal

Copy the `before/` files back over their originals (the sampler script, the map, the texts); delete `field_notes.md`, the two probes, the report, the R3 batch file, the handoff, `tools/build_wcn_captures_page.py`, the guide's `runtime-captures.html` and `images/*.jpg`; remove the `gauss` line from `tools/run_wcn_probe.sh`, `gaussian` from `tools/port_wcn_probes_live.py` and the Random_Gaussian row from `tools/check_wcn_w1_source_review.py`.

## Runtime

Both lanes ran on 2026-09-11, 22:32–22:55: a survey run showed the void, the terrain over everything and the sunken keypad; four bare runs and two live runs led to bare 100 / 0 and live 106 / 0, both exit 0, no script error, no signal error, no leak warning. Godot was free throughout; the runner refused nothing; nothing was terminated.
