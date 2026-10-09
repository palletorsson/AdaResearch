# Optional composition: an author-made feasibility response

This helper records the existing `presence.gd` study's inputs and replays them through its unchanged `evolve` function. It is one possible response to the optional task, not the student's required solution. The required tutorial still prints its complete original code.

The record is in memory. Each committed update keeps a simulation-space position and a Boolean saying whether the held point contributes. Repeated positions remain separate: a pause lasts several updates. The beginning, starting tick, SYNC/SCAN and REVERSE settings are retained. This does not serialize a file or measure wall-clock time.

## Use in an experimental copy

The host, PointBody and full `presence.gd` already exist in the museum lesson. Pass that study node explicitly to this helper. Call `begin(study)` after preparing the beginning. Route the experiment's external STEP action to `take_step(study)` instead of directly to `study.step()`. Do not put `take_step` inside `step`: that would recurse. Begin another record after resetting, editing the initial field or changing update settings. Do not advance the study outside the recorder during a recording.

Call `replay(study)` to restore the recorded beginning and apply the stored inputs without sampling the current hand. It returns independent field snapshots, then redraws the final field and its support. Replay is an immediate calculation; a paced animation would be another choice. It does not reproduce a physical body's path or make the tabletop study into a walkable bridge.

## Reproduce the author test

From the AdaResearch repository root, run `python -X utf8 tools/test_ca_composition_replay.py`. The runner currently names the local Godot 4.6 executable explicitly; adjust that path on another machine. This review ZIP is not the museum project. Copies of the probe and runner are in `verification/` for inspection; their working repository locations remain `tools/probes/ca_composition_replay.gd` and `tools/test_ca_composition_replay.py`.

Thirteen fresh native Godot checks passed. A prescribed path generates 80 updates; every one of the 80 cells matches at every replayed update (6,400 values). Counterexamples remove pauses or ignore absence; both change the result. Other checks cover rotated host coordinates, independent snapshots, support redraw, schedule restoration and the existing 300-update cap.

This establishes executable feasibility for one author-made response. It is not an independent ghost-student result, a live improvised walk, a Quest performance test or evidence that the encounter is artistically successful.
