# Batch 25: twenty museum maps, four workers, independent review

Palle explicitly approved asking Claude to transfer twenty maps with multiple agents, with Codex reviewing the results. You are the Claude coordinator. Use four parallel worker agents, five maps each. Confirm whether you can actually launch these workers; do not report parallel delegation if unavailable. No new assignment beyond these twenty maps.

## Ownership

Skeletons, source inventories, catalog entries and playable registrations already exist. Do NOT rerun preparation or overwrite existing trials. `batch.json` is authoritative for map order and counts.

| Worker | Owned trial folders | Maps | Placements |
| --- | --- | --- | --- |
| A | `commons/void/trials/randomness_04/` | Random_Cubes, Random_Rotate_Random_XYZ, Random_Walk, Random_Gaussian, Random_Mushrooms | 75 |
| B | `commons/void/trials/randomness_05/` | Random_Space_Geometry, Randomness_Examples_of_Randomness, Random_Pheromone, Random_Space, Random_Game | 26 |
| C | `commons/void/trials/noise_02/` | Noise_One, Noise_Voxel, Noise_6_Wall, Noise_Inside_Noise, Noise_Cellular | 17 |
| D | `commons/void/trials/noise_03/` and `commons/void/trials/cellularautomata_02/` | Noise_Box, Noise_Space_10, Noise_Perlin_Simplex, Lab_Path; CA_GameOfLife | 16 |

Worker D's first four maps belong to noise_03 floors 1-4; Game of Life is cellularautomata_02 floor 1. Lab_Path remains an optional trial; do not change the main spine or curated tower. Workers may write only their assigned trial folders. Their placement scripts belong inside those folders, not shared tools. Unique per-trial adapters are allowed, but no edits to original artifact scenes/scripts, maps, texts or the shared runtime.

Claude coordinator owns this batch's `STATUS.json`, `GPU_SLOT.json` and worker status aggregation, and the native/export/editor job queue. Codex owns shared registration, floor_content.gd, shared adapters, probe library, schema, web app and shared tool changes. Narrow requests go in the affected trial's REQUESTS.md and are summarised in batch STATUS.json. Do not silently make a shared fix in a worker. Exporter's normal line_parts.json output and each owned public/void-trials/<trial> directory are permitted, serially.

## Transfer contract

Preserve every inventoried source occurrence, its identity, scene, config, scale, token height and supported interactions. Read the source code as well as map_data.json. A live em_plan difference should be reported, not silently substituted. Keep the 42 x 32 m floor, six-metre storeys, original pillars and two 5 x 6 m shafts. No walls/ceiling added by default, no shrinking exhibits to hide fit problems, no aesthetic curation, no chapter/final.md rewrites. Move placements for basic access and honest fit; document unavoidable external extent, inter-floor protrusion, missing support and source-empty dependencies.

Every occurrence must remain an independent lab-editor object. Source-empty utilities need an honest labelled marker through the existing mechanism, not invented functionality. Do not say a source demonstration is an actual solver. Keep Desktop and VR on the same rooms/layout. Preserve scene-exported properties if a trial-only adapter swaps a script. Adapters must remain correct when the placement moves/rotates and at a negative floor elevation.

## Efficient tests and queue

Read `doc/void-transfer/GODOT_TESTING_FOR_AGENTS.md`, `tools/probes/void_transfer_probe.gd`, and the recent wavefunctions_05/randomness_03 probes and handoffs. Use input_aim_camera, input_grab_preflight, input_grab and input_tip_to, not fresh ad-hoc aim loops. Label real input versus API/static assertions. Add focused diagnostics for risky interactions. Parse/source checks first; diagnose one failure before repeating the full run. A source audit is not proof of interaction or fit.

Workers prepare source audits, placement, probes and static dependency review in parallel. Only the Claude coordinator launches native/export/editor jobs, ONE AT A TIME, on trials a worker has marked ready. This avoids five competing native queues, shared export races and noisy duplicate runs. Existing native/export runners take the OS lock in tools/void_native_slot.py before staging; never delete ada_run/void-native.lock. Batch GPU_SLOT is a note, not the mutex. No manual unguarded Godot launches, global audio/device changes, or UI focus automation during input tests. Do not recursively scan or delete ada_run/void-trial-runtime (junctions).

For each trial: source audit; focused diagnostic if needed; full native desktop + synthetic XR acceptance; GLB export; editor save/reload test. Use existing runners, correct trial ID, and bounded timeouts. Read logs and assert generated meshes, full bounds, shaft/pillar/arrival clearance, neighbour-floor residency and actual control outcomes. Capture inside-tower screenshots and inspect them. Do not treat placeholder markers, untouched input paths, or a passing animation as a tested interaction. Physical headset remains untested.

If a five-map trial exceeds the suite's existing timeout, report the slow stage with evidence to Codex; do not raise timeouts or split/redefine acceptance silently. Archive failed logs. Repeat successful suites only after relevant changes, failure or a specific review concern. Worker A has more occurrences, but counts do not mean all 55 dice need duplicate input scenarios: verify all identities/configs and sample distinct behaviours meaningfully.

## Rolling handoff and review

Write batch STATUS.json as soon as workers launch: actual agent IDs/names, ownership, state, current job and shared requests. Update at meaningful transitions. As soon as the FIRST group of five has a reviewable placement/probe and source audit, mark it ready_for_codex_review; do not wait for all twenty. Other groups may continue independent work. Codex will inspect the first group early and review every group after completion; none are accepted merely by worker self-report.

Each trial delivers HANDOFF.md, STATUS.json, transfer-status.json, probe.gd and evidence. Keep handoff compact: source count/hash and scale/height comparison; placement/action/evidence/fit/dependency/remaining table; exact changed files; command results; screenshots and measured bounds; untested claims. Preserve failed evidence. Include a concise delta from source, not a diary of every attempt.

When finished, release GPU_SLOT and report all twenty map states, editor URLs, exact evidence and unresolved issues. Do not start curation or texts. Do not mark Codex acceptance yourself.
