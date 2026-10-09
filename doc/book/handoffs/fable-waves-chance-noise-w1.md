# Handoff — Waves, Randomness and Noise, batch W1 (Fable 5.1, 2026-09-10)

**Next assignment from Astra, 11 September:** [W2 completion](fable-wcn-w2-completion.md). Read that brief with the [revised book voice](fable-final-discovery-voice.md). The dated incoming handoff below is preserved; completed book hero/line changes and earlier sequencing instructions are superseded.

Status: **probe-checked under project startup with actual desktop input (second runtime pass, evening) — awaiting Astra's review, the pendulum's corrected rerun (Godot editor open), and a headset walk.** Nothing committed. The sections below record the afternoon pass; the evening pass is the section that follows them.

Read first: `doc/research/waves-chance-noise/NEXT_BATCH.md` (the brief), `doc/book/handoffs/astra-wcn-w1-review-2026-09-10.md` and `astra-wcn-pilot-review-2026-09-10.md` (Astra's reviews, all corrections kept), `ada_run/waves_chance_noise/2026-09-10-w1-batch.md` and `2026-09-10-pilots-batch.md` (handbacks with runtime sections appended), the five room reports beside them, and each room's `field_notes.md` (a dated runtime section at the end).

## Second runtime pass — evening (after Astra's runtime-evidence review)

Follow-up worked: `doc/book/handoffs/fable-wcn-runtime-followup.md`. Handback: `ada_run/waves_chance_noise/2026-09-10-w1-batch.md` (second runtime pass section), `2026-09-10-pilots-batch.md`, the five room reports and field notes (dated sections).

| hall | live run (project startup, autoloads present) | actual desktop input, through the rig's pointer |
|---|---|---|
| WaveFunctions_Intro | 28 / 0, `passed`, `release_exercised true` | carry tried and recorded — not a pickup |
| Random_Definition | 27 / 0, re-staged at (8,11) beside the entropy cloud | RANDOM clicked, seed 168 → 426 |
| Noise_Perlin_Simplex | 54 / 0 | REGEN clicked; the aisle walked |
| WaveFunctions_Pendulum | 56 / 0 (20:37; completed 2026-09-11 07:36 with every capture by its intended camera) | COARSE clicked; the walkway walked; museum streaming free → rebuild |
| WaveFunctions_Sine_Space | 61 / 0 | FREEZE toggled twice; the passage walked |
| `sculpture_clear_rects` regression | 5 / 0 | — |

New pieces: `commons/testing/probe_live.gd` + `.tscn` (the launcher), `tools/port_wcn_probes_live.py` (SceneTree probe → Node port; regenerate after every probe edit), `commons/testing/wcn_desktop_driver.gd` (the project's desktop rig, its pointer, `Input.parse_input_event`, pose logging), `commons/testing/probe_wcn_clear_rects.gd`, `tools/run_wcn_probe.sh <name> live` (process inventory; refuses beside a live instance or on a failed query), `tools/check_wcn_w1_source_review.py` (`curation_delta`, `runtime_status` over every room). Harness lessons, also in memory: the rig must not be a child of the tree root (it redirects to the Lab); the museum walker's one-second camera guard must be stopped before photographing from another camera; the port refuses a bare `root.`; captures settle on a timer, not `frame_post_draw`.

Pick up: the pendulum rerun and the four refreshes ran on 2026-09-11 at 07:35–07:38 under the current sources (all green; the pendulum's captures drawn by the intended cameras, nothing on the walkway). What remains: Astra's review of the second pass; a headset walk. Effect Sound is W2 (`fable-waves-chance-noise-w2.md`, `fable-wcn-w2-completion.md`).

## Outcome of the runtime pass

| hall | probe | result |
|---|---|---|
| WaveFunctions_Intro | 22 checks | 0 failures; the release path is NOT TESTABLE from a SceneTree probe (XR Tools pickable + grab_sphere name autoloads at compile time) |
| Random_Definition | 25 | 0 failures after the demo went onto a table and the dark sphere moved |
| Noise_Perlin_Simplex | 51 | 0 failures (frequency 10, overlays hidden, plinths cleared; the last cast rerouted behind the hall's gate) |
| WaveFunctions_Pendulum | 50 | 0 failures; nothing severed once Foucault went to half scale and the dot plotter moved |
| WaveFunctions_Sine_Space | 57 | 0 failures; the corridor now builds floor-at-origin, 7 m, with a floor slab collider |
| reload / unload / two instances | 24 | 0 failures, 0 orphans |

Captures are under `ada_run/waves_chance_noise/<MAP>/probe_*.png` (Pendulum ×2, Sine ×5, one each for the pilots).

## How to run them again

`bash tools/run_wcn_probe.sh intro|random|noise|pendulum|sine` — one at a time, rendered, window parked off-screen, under the watchdog with a 180 s grace (the JSON is written only at the end). For the engine's own errors add `--log-file <path>` to a headless run; the watchdog swallows Godot's output. PID 2780 is a hung headless probe from 2026-09-09 (`probe_zero_controllers.gd`), not a session; it holds no lock and the runner ignores it by its command line. Do not terminate it without its owner.

## Pick up here

1. Astra: review the placements changed after the runs (both W1 maps and Random/Noise; `check_wcn_w1_source_review.py` now reports the maps against its old baseline) and the one museum edit (`sculpture_clear_rects` read for map-authored halls, beside the `artifact_placement` opt-in).
2. ~~The Intro pendulum's grab and release through the desktop lane~~ — done in the second pass under project startup (28 / 0, release exercised through the pickable's signals); the tracked-hand release is the headset lane.
3. Headset: the pendulum panel (1.19 m, east post) and plate (1.45 m); the corridor's panel and plate above the platform cell at the west mouth; the plush walls at 8 rows; the seed demo's table; the noise panels at 1.37 m; the `random_butterflies` swarm's density in the Random hall.
4. Decisions that are Palle's: the removed `colorballs` and `sine_space_explanation` in Sine Space; Foucault at half scale; the corridor's floor slab collider; what to commit.
5. After the review: WaveFunctions_Effect_Sound is next and was explicitly not started.

## What the runs taught (also in memory)

- The museum's map-authored lane does not ground a body whose geometry is built in `_ready`; the corridor stood two metres into the floor. Build the deck at the origin.
- A wide body with no collider is a venue in the walk map and the museum will deal a sculpture plinth into it; a thin floor collider makes the passage the body's own ground. `museum.sculpture_clear_rects` keeps plinths off an authored floor (now read for map-authored halls too).
- A SceneTree probe cannot exercise any XR Tools pickable: the addon names an autoload at compile time. Use `--log-file` to see the compile errors; the watchdog hides them.
- The museum's severance verdict comes from the collider AABB, unclamped: a 7 m Foucault rig sealed the door row; a 2 m plotter sealed the only wedge onto the stage.
- The recovered halls' `gate_depth_rows: 0` put the gate at the doorway; a hall without the key (Noise) has its gate four rows in, and a probe route must start behind it.

## Files

Changed in this pass: `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd` + `.tscn`; `algorithms/randomness/seed_replay/seed_replay_demo.gd`; `algorithms/randomness/simplexnoise/SimplexNoise.gd`, `algorithms/randomness/perlinnoise/PerlinNoise.gd`; `commons/scenes/endless_museum.gd` (one gated block); the five maps (`museum.sculpture_clear_rects`, placements); the five probes; `commons/testing/probe_wcn_w1_reload.gd`, `probe_wcn_intro_bob_diag.gd` (new); `tools/run_wcn_probe.sh` (new); Sine Space final, tutorial, summary, blurb, intent, technical; Noise technical; five field notes; five room reports; two batch reports; this handoff. Before-copies: `doc/space/waves-chance-noise-w1-2026-09-10/` (Fable) and `doc/space/wcn-w1-review-2026-09-10/` (Astra).
