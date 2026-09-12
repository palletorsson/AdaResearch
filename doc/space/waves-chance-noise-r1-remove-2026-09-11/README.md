# Waves, Randomness and Noise — batch R1b archive: Random_Remove (2026-09-11)

Fable 5.1, from Astra's R1 follow-up ("Next development hall: Random_Remove"). One hall: **Random_Remove**, the route's third Randomness hall.

## What is here

- `before/` — byte copies taken before the first edit: `RemoveRandom.gd` (the working tree's, modified and uncommitted since 8 September by another hand, and HEAD's as `RemoveRandom.HEAD.gd`), `remove_random_fixture.gd` (untracked, that hand's), `remove_random.tscn` (unchanged in the end), the map (the working tree's — the recovery's `wall_height` and `#local_grid:true` — and HEAD's as `map_data.HEAD.json`), its nine texts and `nature_layer.json`.
- `before_sha256.txt` / `after_sha256.txt` — hashes before and after; the after list adds the field notes, the two probes, the three tools, the report, the handback and the handoff.
- `.gdignore` — so the archived scripts never compete with the live ones for a class name.

## Structure

No structure or utility cell was moved. Under `map_info.museum`, beside the recovery's `wall_height` 3: `sculpture_clear_rects` [[3,4,10,11]] (cells 3–9 × 4–10 protected; the rect's far edge is exclusive) and `artifact_placement: "map"`.

## Placement

`remove_random:90#local_grid:true` at (6,7), unchanged. Nothing moved.

## The artifact

`RemoveRandom.gd` gained an opt-in replay (`replay_on_reset`, default off — the shipped placements keep their stream), `run_seed`, `removal_log`, `initial_eligible`, `new_seed()` and these in `get_state()`; the fixture turns the replay on, names five-digit seeds on the status, gains NEW SEED and says when the set is exhausted. The bench itself (pedestal, board, cubes, plates, numerals, labels, panel) is the 8 September hand's, kept.

## Reversal

Copy the `before/` files back over their originals (the two scripts, the map, the texts); delete `field_notes.md`, the two probes, the report, the R1b batch file and the handoff; remove the `remove` line from `tools/run_wcn_probe.sh`, `remove` from `tools/port_wcn_probes_live.py` and the Random_Remove row from `tools/check_wcn_w1_source_review.py`.

## Runtime

Both lanes ran on 2026-09-11, 15:28–15:37, in the gaps between another session's museum autopilot runs (the runner refused beside each; nothing terminated): bare 72 / 0, live 77 / 0 at the third pair, both exit 0, no script errors, no shutdown leak warning in this hall.
