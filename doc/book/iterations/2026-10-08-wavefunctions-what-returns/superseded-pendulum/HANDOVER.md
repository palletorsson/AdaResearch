# Wavefunctions — next teaching pass

8 October 2026. User moved on from the Form Finding rethink. Existing twelve-hall order retained. Form Finding drafts remain paused; do not republish their proposed tutorials or layout without renewed direction.

## Completed

- Canonical `WaveFunctions_Intro/tutorial.md`: complete PointBody pendulum reconstruction, declared museum host and prior class, model and units, hand release, prediction, independent two-instance exercise.
- Canonical `WaveFunctions_Intro/final.md`: preserves the returning-place/different-direction encounter; code moved into tutorial; removes the automatic headset-rate claim and the claim that a clock-driven object has no state.
- Native Godot test: 28 checks on code extracted from the published tutorial. Two deliberate faults rejected. The first attempt loaded the XR-dependent class too early under `--script`; test harness now loads it after project autoloads start. Final run contains no script errors.
- Actual museum: 17 placement, signal, floor, clear approach and capture checks. No new permanent artifact placement. Student model is temporarily mounted at hall-local `(6.3, 0, 16.5)`, upright, unit scale.
- Printed source matches `doc/book/studies/wavefunctions-lineage/01_return.gd`; it imports the unchanged Forces `point_body.gd` and restores the familiar black material locally. No `$` scene lookups.
- Paired reading and route review: `index.html`, `parallel.html`, `ROUTE.md`. Execution-plan Intro row updated; decision remains draft for author review. Eleven later rows remain plans.

## Next — WaveFunctions_Pendulum

Carry the new bob into a timestamped record. Reuse Trace's list and neighbour connections; add named position/time fields, explicit sampling intervals, age-based placement and bounded history. Preserve the original record when displaying age along Z. Distinguish a requested interval from the physics ticks on which sampling actually occurs. Do not equate physics rate with screen/headset refresh.

Source: `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`; installed primary token `PendulumWave`. Read canonical tutorial/final and current hall choice before writing. Current text is fragment-based; reflection has strong writing but still contains the refresh/physics-rate conflation. Preserve its close reading while correcting that claim.

## Boundaries and unfinished validation

No fresh independent ghost-student reconstruction, human-learning observation or tracked-headset test in this Wavefunctions pass. The native study and integration harness are teacher-authored tests; do not relabel them as independent learner evidence.

The museum logs an existing blocked authored entry and uses a safe fallback; the entire twelve-hall passage is not certified. The route plan calls out later mismatches: Sine Space wall versus tray, coupling versus a prescribed radial field, twisted geometry versus whole-object rotation, chance vocabulary versus microphone claims, obsolete stair/path proposals. These are pending review, not fixed by this pass.

The installed artifact's logic and all twelve map layouts remain unchanged. The student example deliberately preserves per-physics-tick damping of 0.995; it is not a timestep-independent physical simulator. Its point radius and 0.75-metre pendulum length differ from the installed artifact's smaller bob and 0.6-metre length. Its sampled side-change counter can miss an exact-zero sample; the tutorial names that limit.

## Repeat the checks

From repository root:

```powershell
python -X utf8 tools/publish_wavefunctions_opening.py
python -X utf8 tools/test_wavefunctions_opening.py
python -X utf8 tools/capture_wavefunctions_lessons.py after WaveFunctions_Intro
python -X utf8 tools/publish_wavefunctions_opening.py
```

The publisher updates the canonical Intro tutorial and reflection from its authored source. Edit that source as well when changing the lesson, so regeneration does not overwrite a correction. Capture runner uses isolated museum output paths. Source snapshots and hashes are in `before/`. Review `student-test.json`, `mutation-tests.json`, and `after/WaveFunctions_Intro/report.json` with their logs, not just process exit status.
