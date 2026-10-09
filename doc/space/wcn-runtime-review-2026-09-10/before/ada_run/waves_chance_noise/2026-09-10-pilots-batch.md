# Batch handback to Astra — the three pilots

Model and date: Fable 5.1 (claude-fable-5-1), 2026-09-10.

Rooms and scope: WaveFunctions_Intro, Random_Definition, Noise_Perlin_Simplex — each encounter and its final.md together, per `doc/research/waves-chance-noise/HANDOFF.md`, on Palle's instruction ("Start with the three pilots… preserving the recovered grid structure").

Baseline revision / dirty files preserved: HEAD `aeddf7e2b`; 1,677 dirty paths at 13:11 (994 untracked, 662 modified) recorded in `ada_run/waves_chance_noise/_baseline/`. Nothing committed. Every file I changed that carried another session's uncommitted work still carries it: `endless_museum.gd`, `GridInteractablesComponent.gd` and the twelve wave maps (the recovery session), the three finals (the 2026-09-08 writer run), `artifact_roles.json` and `spine_artifact_order.json` (see "derived data" below). Exact before-copies: `doc/space/waves-chance-noise-pilots-2026-09-10/before/`; per-room `before/` under `ada_run/waves_chance_noise/<MAP>/`.

Status: **source corrected — runtime acceptance pending**. Source-verified; runtime probes written and **not run** (three to four Godot instances held the `user://` lock all day and the project forbids a second); headset not walked.

Per-room reports: [WaveFunctions_Intro](WaveFunctions_Intro/report.md) · [Random_Definition](Random_Definition/report.md) · [Noise_Perlin_Simplex](Noise_Perlin_Simplex/report.md). Field notes beside each final. Structure archive and decisions: `doc/space/waves-chance-noise-pilots-2026-09-10/README.md`.

## Original Fable decisions (superseded by the Astra review below)

1. **One museum line, and it is core behaviour.** `endless_museum.gd` ~10898: the transplant's necklace-hand lookup now carries the authored exemption line 8204 already had, so map-authored halls build from their maps (map_authored.json's own contract). Random_Definition was live-claimed by a 15-bead 2026-08-21 stamp and nothing done to its map would have shown; six other randomness halls carry live stamps and will re-layout from their maps on the next museum run. The stamps are untouched. Palle was told of this class on 2026-09-09 (boolean_tunnel); the pilot needed it.
2. **A structural change in Noise_Perlin_Simplex.** The basin was floored and three piers removed (walk 1/89 → 149/195); `noise_terrain` (100 m footprint, formerly the floor) is out of the hall. Archived; reversible.
3. **Four names added to the grid's `CONFIG_PARAM_NAMES`** (`seed`, `octaves`, `offset`, `contrast_seed`) so numeric tokens are values, not rotations; `octaves` was already documented as a placement in SimplexNoise.gd and was being misread.

## Original Fable source evidence

| check | Intro | Random_Definition | Noise_Perlin_Simplex |
|---|---|---|---|
| gdparse (all changed scripts) | parses | parses | parses |
| pathfinder | OK 133/286 | OK 218/286 | OK 149/195 (was 1/89) |
| check_map_tokens | 0 unresolved | 0 unresolved | 0 unresolved |
| final_tags (grammar + TS parity) | 3 regions / 1 tagged | 3 / 1 | 4 / 2 |
| cite_gate (book quotes in rewritten files) | HELD | — | HELD |
| code excerpts verbatim in source | 4 + 2 lines | 7 + 3 | 10 + 2 |
| final length | 681 words | 566 | 694 |
| /api/compose-docs serves the new final (stale: []) | yes, 681 words | yes, 566 | yes, 694 |
| runtime probe | written, not run | written, not run | written, not run |
| headset | no | no | no |

Museum-progress and thread pages return 200 for all three; `/api/spine-roles` reflects the maps live (Noise no longer lists `noise_terrain`).

Known unrelated red: `check_dna_declarations.py` exits 4 on four tokens outside this scope; `final_tags --check` reports a stale tag in `Tutorial_Single`; `check_wave_platform_recovery.py` now asserts `WaveFunctions_Intro: unplanned source change` because it requires the map to equal the recovery's output byte for byte — any post-recovery edit trips it and its original snapshot check needs separating from a persistent geometry check (resolved in the Astra review).

Derived data: `build_spine_artifact_order.py` was run without `--check` and rewrote `commons/data/spine_artifact_order.json` (already dirty at baseline; derived; the 4,901-line diff is the corpus catching up, not these rooms). `museum_necklace.py --check` reports `museum_order_effective.json` matches its sources; it was not touched. `artifact_roles.json` was already dirty (another session's 2026-09-08 promotions) and was not edited; `noise_terrain` keeps a stale secondary entry for Noise_Perlin_Simplex there.

## Code paths quoted in Fable’s pre-review finals (source / function / hash)

- Intro: `control_pendulum.gd` `_physics_process` (4 lines, resonance branch omitted and said so) and `_on_bob_dropped` (2 lines) — `27b116495b6c`.
- Random_Definition: `seed_replay_demo.gd` `_regenerate` (7 lines, reduced) and the extra-draw guard (3 lines) — `e34afc5038c2`.
- Noise: `NoiseVisualizer.gd` `_noise_type_for` (complete) — `4c26dca315f4`; `SimplexVisualizer.gd` `generate_noise_at` — `8ed9b91846ed`.

## Reusable methods proposed by Fable (runtime proof pending)

- **A seed you can name** (R6): seed_replay_demo (REPLAY/RANDOM/+1 DRAW, artifact-local RNG) and the noise pair (declared seed, REGEN records, REPLAY restores). Two rooms, two implementations, no shared code yet.
- **A readout beside the phenomenon** (R2): the pendulum's signed label and crossing count; the noise readouts naming the basis from the generator and the value at two coordinates. Same contract, local code.
- **One variable at a time** (R1): +1 DRAW (procedure), one FREQ slider (one side), one larger release (amplitude).

## To run when Godot is free (commands corrected by Astra)

```
python tools/godot_watchdog.py --expect=ada_run/waves_chance_noise/WaveFunctions_Intro/probe_intro.json -- C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_intro.gd -- --capture
python tools/godot_watchdog.py --expect=ada_run/waves_chance_noise/Random_Definition/probe_random_definition.json -- C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_random_definition.gd -- --capture
python tools/godot_watchdog.py --expect=ada_run/waves_chance_noise/Noise_Perlin_Simplex/probe_noise_pair.json -- C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_noise_pair.gd -- --capture
```

One at a time. Each writes its JSON and PNG under `ada_run/waves_chance_noise/<MAP>/` and exits non-zero on any failed check.

## Astra review — 2026-09-10

Accepted observations: the three proposed experiments form a useful progression through returning state, repeatable draws and controlled field comparison. Source agreement is established; observed runtime outcomes are not yet accepted.

Corrections made after independent inspection: release tangent/frame, pre-ready seed configuration, noise sample addresses, explicit matched settings/finish, generator readouts, REPLAY after slider changes, three-map placement opt-in, role/book cleanup, prose and targeted probes. Full review: `doc/book/handoffs/astra-wcn-pilot-review-2026-09-10.md`.

Remaining work: run the corrected probes serially when the existing Godot process has closed; inspect their captures, then verify tracked-hand reach and controls. Use the rendered commands above for PNGs; for logic-only runs replace `--rendering-method gl_compatibility` with `--headless` and omit `-- --capture`. Automated rendered runs must hide their windows.

Status after review: **source corrected — runtime acceptance pending**. The earlier tables describe Fable’s pre-review checks. Current source evidence: `ada_run/waves_chance_noise/astra-source-checks.json`.


## Runtime pass — 2026-09-10, late afternoon (Fable)

The three pilot probes ran, one at a time, rendered under the watchdog with the window off-screen (`tools/run_wcn_probe.sh`). Results and fixes, in full in each room's `field_notes.md` and `report.md`:

- **WaveFunctions_Intro** — 22 checks, 0 failures; the release path is NOT TESTABLE from a SceneTree probe: `grab_sphere.gd` names `TextManager` and XR Tools' `pickable.gd` names `XRToolsUserSettings` at compile time, both fail to compile without the autoloads, and `control_pendulum._create_grabbable_bob` aborts before `add_child` (engine.log line 1370). The shipped game compiles them. Measured: the reference, the readout, the autonomous swing's alternating crossings, the swing envelope and release positions clear of collision. `museum.sculpture_clear_rects` added.
- **Random_Definition** — 25 checks, 0 failures after two fixes: the seed demo now stands on a table (`#stand:table`, panel at 1.01 m instead of 0.16 m), the dark sphere left the visitor's spot. The `random_butterflies` swarm fills the capture with white spheres; noted, not changed.
- **Noise_Perlin_Simplex** — 51 checks, 0 failures (the probe's east-corridor cast had met the hall's gate, which stands four rows in because the map declares no `gate_depth_rows`; it now starts behind it); fixes: frequency 10 (at 1 both fields were flat slabs), FREQ slider 1..20, the scenes' 2D overlays hidden when embedded, `sculpture_clear_rects` keeping museum plinths out of the aisle.

Status: **source corrected and probe-checked on desktop; headset and tracked-hand verification pending; Astra's review pending.**
