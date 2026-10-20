# Lava wall iteration / 14 October 2026

Palle requested a version of Cloudflare's lamp wall and a practical framing of randomness. Built `lava_entropy_wall`, installed in `Random_Definition` at `(11,6)`, facing 270 degrees. The first attempted position `(11,7)` crossed the room partition; the rendered inspection prompted the move and a narrower comparison-card layout. The original seed bench, journey and independently positioned instruments remain unchanged.

This apparatus is a deterministic virtual model with an explicitly synthetic sensor. It is not a fluid solver, a physical TRNG or a cryptographic service. A separately labelled Godot Crypto input changes the model seed. Replaying its stored receipt does not resample the source. Cloudflare's physical camera observations and mixed entropy system are the inspiration, not a claim about this virtual model's capabilities.

Source: [Cloudflare technical account](https://blog.cloudflare.com/lavarand-in-production-the-nitty-gritty-technical-details/). Palle's photograph informed the shelf and lamp design; no photo was installed as a simulated live camera feed.

## Evidence

- `model.json` / `model.log`: **24/24** native artifact and record checks, including repeatability, single-condition changes, corrupted-record rejection, interaction signals, keep/load and a fresh instance restoring both comparison cards. JSON integer/float conversion initially broke validation; numeric comparison and full-precision output fixed it.
- `museum.json` / `museum.log`: **16/16** real-hall checks, including existing artifact presence, floor support, reachable button height, actual button-area event, animation, preservation and two render captures. Final run: `ada_run/encounter_pilot/Random_Definition/lava-wall-03`. No script errors in these runs. The shared rack buttons emit an existing Jolt solver-bias warning; no headset/performance claim is made.
- `reconstruction.json` and `saved-reconstruction.json`: independent Python implementation reproduces all **4608 sensor bytes**, full SHA-256, reduced seed, body state and 48 outputs for baseline and changed heat. This is a second implementation, not a human reconstruction trial.
- `comparison.json`: an actual kept baseline/capture pair from the museum run. Seed 435 and tick 300 held; heat changes from 100 to 110. **1266/4608 pixels and 48/48 outputs differ.** This is an observed computational difference, not evidence of extra entropy or participant understanding.
- `registration.json` and the two `*-change.diff` files: only one map slot and its artifact count changed relative to this turn's starting snapshot. All earlier registry entries and placements preserved. Ordinary registry/map data make the installation available to the web editor's existing artifact pipeline.
- `lava-wall.png` and `lava-controls.png`: final desktop rendering. Browser inspection was rejected by the browser tool's URL policy; no workaround was attempted. Browser UI visibility/interactions remain unverified for this addition.
- Refreshed course inventory and ZIP comparison: no missing registered artifacts/scenes or stale source receipts. The broader plan validator reports **60/61**, with an existing unresolved `WRITING_PILOT.md` link to absent `writing_pilot.json`. That unrelated writing pilot is not created or fabricated by this iteration.

## Research return

The [new tutorial](../../experiments/random-definition/lava-wall-001/tutorial.md) specifies the experiment cycle and includes a complete reconstruction program. The [provisional final text](../../experiments/random-definition/lava-wall-001/final.md) asks who can predict a result, given which observations and purpose. Either text can initiate a revision. Their local task plan keeps visitor observation, independent human reconstruction, headset assessment and the evidence-driven next revision open.

Next useful observation: does a visitor mistake a changed hash for proof of more randomness? Have them predict before revealing a changed capture, then explain which missing information would help. If this is unhelpful, record that result and revise the apparatus. No cross-hall transfer or physical-camera source is claimed.
