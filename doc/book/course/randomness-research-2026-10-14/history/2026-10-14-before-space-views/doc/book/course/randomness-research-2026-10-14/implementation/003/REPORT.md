# Seed-bench 001: first scripted cycle

The 48-value RGB/mean-height study runs beside the existing seed instrument in Random_Definition. It retains exact values and provenance, changes only height, keeps an independent copy, exports/imports it and replays in a fresh Godot process. See [observations](../../../../experiments/random-definition/seed-bench-001/observations.md) and [evidence.json](evidence.json).

| Check | Result | Limit |
| --- | --- | --- |
| Native cycle | 46/46 | Godot 4.6 on this machine |
| Fresh-process replay | 3/3 | Stored values; no new acquisition |
| Printed reconstruction | 46/46 | Extraction by Codex, not a human learner |
| Deliberate faults | 4/4 detected | Aliasing, switch mutation, wrong mean, non-atomic import |
| Rendered museum probe | 10/10 | Scripted point signal and dispatched Godot keyboard events |
| Launcher smoke | Passed; museum camera retained | Short startup check |
| Human / independent reconstruction / physical VR | Not tested | Remain completion gates |
| Performance / cross-hall transfer | Not tested / not applicable | Local bounded study |

The failed importer and decimal mismatch remain in the evidence. The repair adds exact float bytes, validates the complete record before accepting it, and stores seed/state as strings. Malformed, oversized, incompatible and inconsistent records leave current and kept copies unchanged. Snapshots of final source and printed code live under `evidence/sources/`; museum host inputs are separately hashed. Early failing source versions were not snapshotted.

The mean collapses channel order: invented red and green triples share height. That expected result is a concrete question for the human encounter. The tutorial gained a complete companion continuation; the final was retained with reasons. Expansion is provisionally deferred. The full human research loop is incomplete.

From the repository run `python doc/book/experiments/random-definition/seed-bench-001/launch.py`. F1/F2 compare; F3 keeps; F4 replays; F5 exports; F6 imports; F7 clears the memory copy; F8 acquires the next deterministic seed. The launcher uses the probe tool's new `--prepare-only` option to isolate outputs and borrows the museum walker. The installed route and live hall prose stay untouched.

Re-run checks with `python -X utf8 doc/book/course/randomness-research-2026-10-14/implementation/003/run_checks.py --tag NEW-LOWERCASE-TAG --printed --faults` (replace the tag with lowercase letters, digits or hyphens). Existing run folders are never overwritten.

Local captures are in `ada_run/encounter_pilot/Random_Definition/seed-bench-001-input-fixed/`, excluded from Git under repository image policy. Existing museum warnings are preserved in `evidence/museum-input-fixed.log`: registry notices, Compatibility-renderer feature limits and a blocked authored entry's safe fallback. These scoped checks do not establish sustained performance or a general museum health result.

## Human-requested board revision

The current apparatus uses one compact board with rectangular hand/pointer buttons and CLOSE/reopen. The updated museum probe passes **18/18** checks, including actual overlap at an outer cap edge and the board-only saved-result cycle. Native/printed checks remain 46 each; fresh replay 3. Earlier run receipts are retained and marked superseded; current source snapshots are in `evidence/vr-board-sources/`. Current local captures are under `ada_run/encounter_pilot/Random_Definition/seed-bench-001-vr-board/`. See [the human return and limits](../../../../experiments/random-definition/seed-bench-001/VR_BOARD.md).

## Human-directed fixed-bottom bars

The current recipe narrows the cube/bar gutter to 1.5 cm and uses 4-16 cm bars with bottoms fixed at 8 cm. Button spacing remains unchanged. Native and printed checks pass 52/52 each, fresh replay 3/3 and museum 20/20; all five deliberate faults are detected, including drifting bottoms. Legacy replay keeps the original floating recipe; selecting a current mode explicitly forks it. Current source receipts are in `evidence/anchored-bars-sources.json`. See [the decision and arithmetic](../../../../experiments/random-definition/seed-bench-001/ANCHORED_BARS.md). The image shows closer bars can obscure rear cells; that remains a question for the encounter. Physical VR, independent reconstruction and sustained performance remain untested.

## Filled trays

The follow-up widens cells to fill 90% of each tray width while retaining the narrow gutters and prior heights. Native/printed checks pass 58 each, fresh replay 3 and museum 21; all five faults are detected. Source snapshots: `evidence/filled-trays-sources.json`. Both previous layouts remain replayable.
