# Waves, Randomness and Noise — batch R4 archive: Random_Mushrooms (2026-09-12)

Fable 5.1, the next hall on Astra's route after Random_Gaussian. One hall: **Random_Mushrooms**, the route's sixth Randomness hall.

## What is here

- `before/` — byte copies taken before the first edit: `mushrooms.gd` (identical to HEAD; HEAD's copy kept as `mushrooms.HEAD.gd`), `mushrooms.tscn` (unchanged), the map (the working tree's — the 10 September recovery's `museum` block, compact rows and interior spawn, another hand's uncommitted edit — and HEAD's as `map_data.HEAD.json`), its eight texts and `nature_layer.json`.
- `before_sha256.txt` / `after_sha256.txt` — hashes before and after; the after list adds the field notes, the two probes, the report, the handback and the handoff, and the tools that gained a row.
- `.gdignore` — so the archived script never competes with the live one for a class name.

## Structure

Unchanged: the 13 × 13 grid as the 10 September recovery left it (seven `2` platform cells along x 11, the explicit `w` border, the interior spawn at (1,1)), `wall_height 3`, `gate_depth_rows 0`. Under `map_info.museum`: `artifact_placement: "map"`, `sculpture_clear_rects [[3,1,10,12]]` (cells 3–9 × 1–11; the far edge is exclusive) and `floor_cells [[8,12]]` (the teleporter's void cell floored in the museum; the grid keeps its `0`).

## Placement

`mushrooms` (4,6) → `mushrooms:180#stand:specimen#size:6` (6,7): a six-metre bed with its specimen table at the north edge facing the door. `dark_sphere` (5,5) → (10,2). `bubbles_random:0:-0.5:1.0` (5,6) → (10,4). `bubble_particles:0:-0.5` (6,6) → (10,9). `reaction_diffusion_intro:0:-0.5` (6,8) → (9,11). `random_number_book_page_collection:0:1` (5,12, a wall cell) → (10,7). The old layout was the ten-metre meadow over everything, with the dealt lane sliding and shrinking every body.

## The artifact

`mushrooms.gd` gained: every draw of the build through `_rf()` / `_ri()` (the shipped default falls through to the global stream, same call, same order); `population_seed`, `size_variation`, `max_glow_lights`, `bed_lift`, `stand` (`none | specimen`); bookkeeping on every path (candidates requested, rejected positions, `template` / `kind` / `group` metadata, ring and cluster records, lit lights); a real `apply_grid_config` (`size`, `count`, `density`, `seed`, `stand`); `regrow`, `new_seed`, `set_population_seed`, `set_size_variation`, `show_template`, `cycle_show`, `set_kind`, `cycle_kind`, `instances`, `ground_signature`, `readout_lines`, `highlighted_count`, `get_specimen_state`; the opt-in specimen table (the bed lifted and kerbed, six type specimens, the housed plate, the highlight rings and pins, SHOW · KIND · SIZE / REGROW · NEW SEED); `_exit_tree` frees the templates (fifty-one objects leaked at exit before). No returned value of the shipped path changes.

## Reversal

Copy the `before/` files back over their originals (the meadow script, the map, the texts); delete `field_notes.md`, the two probes, the report, the R4 batch file, the handoff; remove the `mush` line from `tools/run_wcn_probe.sh`, `mushrooms` from `tools/port_wcn_probes_live.py`, the Random_Mushrooms row from `tools/check_wcn_w1_source_review.py` and the Random_Mushrooms entry from `tools/build_wcn_captures_page.py`; rebuild the captures page.

## Runtime

See the end of `commons/maps/Random_Mushrooms/field_notes.md`: a survey run (09:12), two bare runs (09:43: 75 / 3, the probe's own ten-metre expectations; 09:47: 75 / 0) and the live run, all on 2026-09-12 in the morning. The runner refused nothing; another session's Godot held the lock for four minutes before the first run and was waited out; nothing was terminated.
