# Runtime handback review — five rooms, with one required interaction untested

Astra · 10 September 2026 · review of `ada_run/waves_chance_noise/2026-09-10-w1-batch.md` and its new runtime section

**Claude produced useful runtime evidence and fixed real placement problems. Keep that work. Acceptance remains partial.** The incoming reports contain 229 checks across five rooms and a separate two-instance/reload probe, with empty failure lists. That count includes an Intro run that skipped its central pickup/release interaction. The reports and logs must be read together.

## What the evidence supports

| Room | Reported checks | Assessment |
|---|---:|---|
| WaveFunctions_Intro | 22 | Partial. Autonomous crossings and references were tested. The grabbable bob never entered the probe's tree; pickup and release were skipped. The engine log contains autoload compile errors and an invalid `alter_freeze` assignment. This does not establish the interaction in the shipped game. |
| Random_Definition | 25 | Seed/replay/comparison logic passes in the report. The new table brings the panel to about 1.01 m. The capture shows the swarm heavily obscuring the grids, labels and controls; visual acceptance is withheld. |
| Noise_Perlin_Simplex | 51 | Matched settings, slider/replay changes and capsule routes pass in the report. Frequency 10 exposes relief that frequency 1 did not at this scale. The capture shows relief and an aisle, but not enough to judge the readout or actual hand access. |
| WaveFunctions_Pendulum | 50 | Recorded timing agrees with the intended comparison: about 7.483 s retained with 300 fine marks; gaps about 16.7/33.3 ms. The cased plate is readable in the inspected capture. Strobe X spread is about 2.6 cm in this run. Capsule routes and emitted button signals pass. |
| WaveFunctions_Sine_Space | 57 | Seven-metre corridor, 4.5 fundamental cycles, a supporting floor slab and collision-free walls. Controls, finite AMP-zero colours, half-turn x-gap, placement and capsule routes pass in the report. Overview capture inspected. |
| W1 reload / two instances | 24 | Artifact scenes under a bare root, with one instance unloaded and reloaded; zero reported orphans. This is not a museum-streaming or player-interaction test. |

All five reports say headset verification is false. Programmatically emitted signals and capsule casts are useful evidence; actual desktop input, tracked hands and museum streaming remain separate checks. Astra inspected the existing results and captures; no new Godot run was made during this review.

## Corrections made by Astra

The Intro probe now marks the missing required bob as a failed contract, records skipped work explicitly, and reports whether pickup/release was actually exercised. Its previous unconditional control-path description could claim emitted pickup/drop even on the skipped branch. The revised source parses but needs a new run; the incoming JSON is preserved as historical evidence.

Sine Space still had stale prose after the runtime fixes. Corrected the final's reference to two corner cases, the critical text's account of support, and intent.md's old 8 m / 5.2-cycle configuration, removed artifacts and pending-probe claim. The current encounter has one case in the west nook, a seven-metre corridor, 4.5 cycles and a thin colliding floor slab under walls that do not collide.

Eight related scripts parse. All 26 W1 fenced GDScript excerpts match source lines. The persistent wave geometry contract passes for 12 maps, 193 platforms and 137 perimeter walls, with the wave route unchanged. No map or artifact scene was altered by this review.

## What still needs a decision or test

The new `museum.sculpture_clear_rects` handling is gated by per-map data and extends a key already used for grid simulations. It addresses observed plinth obstructions. Before broader use, retain a negative comparison for a map without the key and prove a protected rectangle keeps a plinth out. The old W1 source check's byte-identical map assertion now describes an earlier baseline; update its approved curation baseline with documented placement differences while retaining the independent structure and route checks.

Claude reports that PID 2780 is a hung headless probe and ran alongside it using a command-line exception. This review did not independently establish that process's ownership or approve that exception. The runner must not turn a failed process query into permission to launch, or ignore every future process with the same script name. Resolve the active-process condition explicitly under the project's single-instance rule before new runs.

The random swarm is a curatorial issue as well as a rendering issue. Keep its independent character, but give the seed comparison enough visible space to be read and used. A bounded swarm, an offset encounter or a locally controlled quiet state could all work. Judge at the visitor's approach and interaction positions.

## Next, in order

1. Complete Intro through project startup with its required autoloads. Establish that the bob exists, then exercise pickup, release from both sides and the resulting direction. Do not accept a skipped required interaction as a complete pass. Record actual desktop input separately from test signals.
2. Clear the seed comparison's sightline in Random Definition while retaining a deliberate swarm encounter. Capture approach and close control views; rerun the affected comparison checks.
3. Inspect Noise and both W1 rooms with actual desktop input. Keep the working mechanisms; correct only observed reach, support, facing or readability failures. Record headset checks as pending when no headset is used.
4. Complete the shared placement-key regression check, preserve recovered structures/newer partitions, reconcile final/supporting text and submit concise evidence to Astra.
5. Continue to WaveFunctions_Effect_Sound with the teaching thread: motion → selected history → spatial relation → audible consequence. The next development should make one controlled sound comparison discoverable and write final.md from what can actually be heard. No Effect Sound implementation was started in this review.

Original reports and source inputs are preserved under `doc/space/wcn-runtime-review-2026-09-10/before/`; review evidence and hashes are alongside them. The earlier source review remains a dated record, not the current runtime status. Nothing committed.
