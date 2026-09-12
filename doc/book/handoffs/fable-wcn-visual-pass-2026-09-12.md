# Handback — the visual pass over the twelve Waves / Randomness / Noise halls (Fable 5.1, 2026-09-12)

Assignment: `doc/research/waves-chance-noise/VISUAL_IMPROVEMENTS.md` (Astra's illustrated review, `visual-review.html`, 86 images from an isolated serial rerun of the twelve halls; Palle: "check this if true and keep going"). Return: one consequential improvement per room, matched before/after views, changed files, targeted checks, the four runtime flags investigated.

**Before/after, room by room:** [visual-pass.html](http://localhost:3003/research/waves-chance-noise/visual-pass.html) (built by `tools/build_wcn_visual_pass.py`: Astra's featured captures beside the same probe views after the change, 46 pairs). The captures page is rebuilt on the same runs.

## The four runtime flags — reproduced, and what they were

| flag | reproduced with the real probe | cause | repair |
|---|---|---|---|
| WaveFunctions_Effect_Sound: 1 failed assertion ("a listener within 3 m wakes the sculptor's tone") | no — 94 / 0 in my lane | the museum walker's 1 s camera guard reclaimed the CURRENT camera, which is the listener the check moves: "[em-cam] the view drifted to another camera — reclaimed for the walker" is the line before the FAIL in her engine log | the check stops the guard's timers before moving the listener and gives the wake a few frames; nothing suppressed |
| Random_Walk: 1 failed assertion ("RESET reaches the walk too (steps 21 → 0)") | no — 112 / 0 | the bare instance ticked once on its own between its build and `set_process(false)`, so an exact `steps == 20` read 21 on her frame boundary; RESET did reach the walk (→ 0) | the check asserts what it claims (steps > 0 → 0) instead of the incidental count |
| WaveFunctions_AirMusic: exit 3221225477 after the report | yes — exit 127 / a C++ backtrace in every run, before this pass | `FMPianoSynth` (through `air_music_display_case`) queued a WorkerThreadPool task per note and never RELEASED the completed ones (a task is released only by `wait_for_task_completion`); the pool crashed the engine at exit | every tracked id is waited, completed or not (`commons/audio/systems/air_points/FMPianoSynth.gd`); `commons/testing/probe_wcn_shutdown.gd` bisected it in nine-second runs (`--mode=synth_only` crashed, `bus_only` and `players_only` exited 0) and clears it now; the hall exits 0 with no backtrace |
| WaveFunctions_Synthesis_Lab: exit 3221225477 after the report | yes | the same: the hall carries `air_music_display_case` at (1,2) | the same; the hall exits 0 with no backtrace |

## The rooms

Every room was rerun in the live lane (project startup, the desktop rig pressing the controls) after its change; the numbers are the last run of each.

| room | the improvement | checks |
|---|---|---|
| WaveFunctions_Intro | under `reference:plumb`: a dark matte slate 0.30 m behind the swing plane (behind the trace plot too), and the state label made a cased readout beside the pivot, out of the swing, at font 24 | 31 / 0 |
| WaveFunctions_Pendulum | the "obstructing panel" was the probe camera standing inside the lab table's footprint; the primary frame is a real standing view from the east wall (80° lens) plus a controls close-up; the sampler panel turned to face the east walkway on the outer side of its post; deep teal marks on a dark runner under the record; the two "holes" were the map's `0` cells (2,8) and (7,18), floored in the museum by `museum.floor_cells`; the walkway rect widened to x 11 (a dealt plinth had landed on the walkway once the deal changed). The lab table stays at (9,9): at (2,10) it sealed the west aisle | 61 / 0 |
| WaveFunctions_Sine_Space | the readout is four short lines on a 0.95 × 0.36 m plate; a dark threshold strip across each mouth of the passage | 64 / 0 |
| WaveFunctions_Effect_Sound | the readout and the AUDITION panel lean low (40°) in front of the carrier and modulator desks at 0.66 m — below the hand space, off the line between the balls; the scope lowered 0.28 m so the balls and all four lanes share the operating view. A first cut put them outboard on floor stems and blocked the audition floor beside the desks (0.32 of the way): withdrawn | 97 / 0 |
| WaveFunctions_AirMusic | the striker's cradle at the table's left end, the striker lying front to back beside the first bar, the row free; a pale rail along the playable edge, a dark kerb along the back; the return home in three legs (up, across, down — a straight return swept the tip through the bars between); rects over both aisles; the shutdown crash fixed at its source | 57 / 0, exit 0 |
| WaveFunctions_Synthesis_Lab | the red geometry was `sine_hallway/hallway_scene.gd` built at its own size (a sixty-metre tunnel of 0.4 m tubes swinging 2.5 m) as the synthesis stand's hero at (10,4): it fits the slab now when its parent is a synthesis stand (a 3 m miniature, same waves per metre; measured 0.52 × 0.16 × 3.05 m at x 10.3–10.8); `coloredlines:0:1:0.05` at (5,4) removed from this map — its `setup_scene()` dresses the current camera (the visitor's) in a dark sky and fog, and the file is another hand's mid-edit (forum 260912-uf0uo); the corridor rect `[7,3,7,11]` had protected nothing (exclusive far edge) and the bench rect stopped a row short of the operator's spot — `[7,3,8,12]`, `[2,2,6,7]`; the shutdown crash fixed at its source | 98 / 0, exit 0 |
| Random_Definition | the panel scaled 1.5 for its labels; a cased action line at its foot names the last action, the seed and whether the two grids agree cell for cell (`RANDOM · seed 454 · grids equal`, `+1 DRAW on · … · grids differ`) | 29 / 0 |
| Random_Entropy | the first forty draws stand again on the desk's front at four times the tile, in the ribbon's colours draw for draw, as drawn and staying while the ribbon sorts, under a caption saying so; the desk's approach rect widened one cell (it was written for an inclusive edge) | 143 / 0 |
| Random_Remove | the control panel off the tray to its right, turned to the visitor; the status and legend cased on a post at the tray's left; the probe's REMOVE ONE reach is a step and a lean (1.65 m) rather than a lean. The fixture is another hand's, extended in R1b — forum 260912-uf0uo | 79 / 0 |
| Random_Walk | a dark backboard behind the tank under the logbook stand; the followed bead twice the size of the dimmed ones | 114 / 0 |
| Random_Gaussian | a headline (font 21) over the six lines: the law, N, the bins, the clipped count and the edge bins (`UNIFORM · N 231 · 30 bins · clipped 0 · edges 6|11`); the shipped side plate off under the cabinet (its n, μ, σ are line four) | 109 / 0 |
| Random_Mushrooms | the disc numbers at 3.3 cm; the shown template's disc wears a torus in the highlight's colour and moves with SHOW; saturated highlights (magenta for the template, deep blue, green, violet, dark grey for the kinds); 6 cm pins | 84 / 0 |

Texts kept aligned where the staging changed: Random_Mushrooms (final, summary, technical), WaveFunctions_AirMusic (final, technical), WaveFunctions_Effect_Sound (technical), WaveFunctions_Pendulum (final, "teal"); every hall's `field_notes.md` carries a dated entry.

## Two things learned about the museum, worth more than any one room

1. **Dealt plinths land somewhere else on every build.** Four of the pass's reruns failed on a walk that a previous run had passed, each time a dream body on a plinth on a route no `sculpture_clear_rects` entry covered. Three rects were also one cell short because the far edge is exclusive (`[7,3,7,11]` in Synthesis Lab covered no cell at all; the probes' own plinth checks read the edge as inclusive). A probe's walk route is a claim about the map's rects, not about luck.
2. **A map edited while its hall is running rebuilds the hall under the probe.** The museum re-reads a map-authored hall live; one Pendulum run died with "Cannot call method 'call' on a previously freed instance" because I widened its rect while it ran (exit 124). Edit maps between runs.

## Not done, said plainly

- Effect Sound's overview "crowded with backs of displays": untouched (the secondary racks are where the map has them).
- AirMusic's "competing titles above" are the museum's showing cards and other bodies' labels: untouched.
- Sine Space's panel keeps its place at the west mouth; the entrance/exit now reads from the thresholds, not from a moved panel.
- Random_Entropy's "upper labels and buttons to a shared readable contrast": the shipped meter's labels are as R1's follow-up left them.
- The Effect Sound readout plate, read from the rig's own low front view, is cut at its left edge by the desk; from the standing spot it reads whole (the readout capture).
- No listener, no headset, no person at any control: every number here is a desktop probe's.
- The visual-pass page's before-images are Astra's own captures (`images/visual-*.png`, untracked in the repo like the rest of her guide); the page is published with them.

## Files

Artifacts: `commons/audio/systems/air_points/FMPianoSynth.gd`, `algorithms/wavefunctions/sine_hallway/hallway_scene.gd`, `commons/artifacts/control_pendulum/control_pendulum.gd`, `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`, `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd`, `algorithms/wavefunctions/mariocontrol/DualBallFMController.gd`, `algorithms/wavefunctions/resonance/ResonatingMetallophone.gd`, `algorithms/randomness/seed_replay/seed_replay_demo.gd`, `commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd`, `algorithms/randomness/remove_random_fixture.gd`, `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd`, `commons/artifacts/distribution_sampler/distribution_sampler.gd`, `algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd`. Maps: WaveFunctions_Pendulum, WaveFunctions_Synthesis_Lab, WaveFunctions_AirMusic, Random_Entropy. Probes: the twelve `probe_wcn_*.gd` and their live ports; new `commons/testing/probe_wcn_shutdown.gd`. Tools: new `tools/build_wcn_visual_pass.py`. Guide: `visual-pass.html`, `images/after-*.jpg`, the captures page rebuilt. Texts and field notes as above.

Committed in two commits so that what stands on earlier, unaccepted work can be told apart: one with the seven rooms whose files carry only this pass (plus the synth's crash fix and the tools), one with the five W1–W3 rooms — whose artifact and map files also carry the W1–W3 staging of 10–11 September (handed back then, not yet accepted) — stated in that commit's message and revertable as one.
