# W1: a record, then a passage

Astra review · 10 September 2026 · WaveFunctions_Pendulum and WaveFunctions_Sine_Space

**Keep and build on this work. Source corrections complete; runtime acceptance pending.** Claude/Fable developed two recognisable encounters and wrote from them. The pendulum now gives a visitor a finite, countable history with controls; the corridor offers a controlled comparison between pinching and bending together. The book heroes match the primary artifacts. The recovered map structures and current route remain intact.

## What the review changed

- **Pendulum timing:** FINE requests 25 ms, but a 60 Hz physics clock records at alternating gaps of about 16.7 and 33.3 ms. The cased display now names the target, actual gap range and physics step. Keep this seam visible: it is material for the book. Three hundred positions span 299 intervals; their oldest age also includes the wait since the newest sample. The text now says roughly 7.5 seconds and describes the strobe as nearly aligned.
- **Sine phase:** the caller supplied the running phase and the layer expression added it again. Removed the second addition. At 0.35 rad/s the complete pattern now repeats in about 17.95 seconds. This correction affects other animated users of the shared script too; their intended speed needs checking. Static instances at phase zero are unchanged.
- **Flat walls:** AMP zero previously divided zero by zero in the vertex colour calculation. The normalisation now remains finite at zero amplitude.
- **What width means:** the corridor readout says `x-gap`. Half a turn gives constant separation along local X at matching Z; that is not a measurement of shortest clearance around a bend. Three spatial frequencies sharing one phase also drift at different speeds; running them and walking a frozen surface are different transformations.
- **Probe validity:** pendulum crossings now use the pendulum's local origin rather than the hall origin. RESET is checked against advancement of the physics clock rather than a tautology. Both probes select their artifact inside the actual segment. Added tests for nonzero phase, finite colours at AMP zero and target/actual sample timing; refreshed readout expectations.
- **Conflicting texts:** the old technical and critical passages still described a damped pendulum, repeatability claims and a walkable sine floor above newer appended sections. Reconciled both rooms around their actual configured primaries. Updated final, tutorial, summary, blurb and intent where necessary, plus book lines and their critical-note citations. Previous versions are archived.

## Decisions retained

`PendulumWave` remains the pendulum hero; `sine_wall_corridor` remains the corridor hero. Both retain map-controlled placement. These follow the existing agreement that primaries are the book's artifacts.

Keep the current corridor contract: animated visible surfaces around a stable museum deck, with wall collision off. The visitor can compare following the apparent passage with passing through a crest. The book states this directly. A future collidable corridor needs its own walk-map and clearance work; switching collision on is not an isolated aesthetic change.

The placements, museum structure, utilities, basin, bridge and route were not changed by this review. Claude's facing choices, panel reach and physical clearance still require observation.

## Evidence and its limits

`python tools/check_wcn_w1_source_review.py` passes: four GDScripts parse, 26 fenced GDScript excerpts match source lines, both map files match the review baseline, phase is applied once at 30 combinations of position and phase, half-turn cancellation holds, and AMP zero gives a finite colour value. The same arithmetic check detects the old phase error (maximum sampled displacement error about 0.455 m).

An independent Python model at 60 Hz gives 300 fine marks with an oldest age about 7.483 s, actual gaps of 16.7–33.3 ms, 50 coarse marks at the sampled observation, and three strobe marks with about 1.2 cm X spread. This supports the numerical wording; it is **not execution of the Godot scene**. Correctly centred crossing counts give 118 marks per swing where the former probe returns no crossing.

`python tools/check_wave_platform_recovery.py` passes: 12 maps, 193 interior platforms, 137 perimeter walls; route unchanged. Building the guide verifies the primary/book sets. Exact code-line checks establish provenance, not teaching quality or engine compilation.

Godot PID 2780 remained running during review. Following the project's single-instance rule, no second instance was launched and no process was terminated. No new runtime captures, desktop interaction or headset evidence is claimed. Nothing was committed.

## Next actionable work

1. Once the existing Godot session is closed by its owner, run the three pilot probes, then the pendulum and sine-space probes, **one at a time** with the watchdog. Commands are in `2026-09-10-pilots-batch.md` and `2026-09-10-w1-batch.md` under `ada_run/waves_chance_noise/`.
2. Inspect the captures and actual controls: approach, panel reach, readout legibility, complete swing and history lane, corridor mouths, support and exit. Check the explanation cases and seismograph face the visitor.
3. Check reset/reload/unload and two nearby instances; then walk the interactions in a headset. Programmatically emitted button signals are separate evidence from a hand using the panel.
4. Correct observed failures and enter evidence in the W1 handback before marking the rooms accepted. The next development hall is WaveFunctions_Effect_Sound; W2 has not started in this review.

The red thread now has a specific seam at each step: Intro distinguishes position from state; Pendulum distinguishes motion from its selected record; Sine Space distinguishes a visible boundary from the route and measurement assigned to it; Effect Sound can ask what another sampling system makes audible. That is a useful basis for the next hall.

## Reusable lessons

A housed readout should print the realised measurement as well as the requested setting. Define each measurement's coordinate frame and metric. Test a changing parameter away from its default; phase zero concealed the double-phase bug. A room review must remove contradictory old claims throughout the supporting texts, not just append a correction. Carry these lessons into later maps when the same condition occurs; do not bulk rewrite unrelated artifacts.

Source/arithmetic evidence: `ada_run/waves_chance_noise/astra-w1-source-checks.json`. Before files, hashes and review evidence: `doc/space/wcn-w1-review-2026-09-10/`. Claude's original before/after archive remains at `doc/space/waves-chance-noise-w1-2026-09-10/`.
