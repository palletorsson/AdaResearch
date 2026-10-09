# Waves, Randomness and Noise — batch W1 archive (2026-09-10)

Fable 5.1, working from `doc/research/waves-chance-noise/NEXT_BATCH.md`. Two halls: **WaveFunctions_Pendulum**, then **WaveFunctions_Sine_Space**.

## What is here

- `before/` — byte copies of every file I changed, taken before the first edit: the two maps and their eight texts each, `PendulumWave.gd`/`.tscn`, `SineWallCorridor.gd`/`sine_wall_corridor.tscn`, the book chapter `book_wavefunctions.json`. `before_sha256.txt` is their manifest; `after_sha256.txt` the manifest of the changed sources.
- The baseline of the whole tree: `ada_run/waves_chance_noise/_baseline_w1/` (HEAD `aeddf7e2b`, 1,748 dirty paths at the start).

## Structure

No structure or utility cell was moved in either map. Both keep the recovery contract of `doc/space/wave-platform-recovery-2026-09-10/` (interior `2` = 1 m platform, perimeter `w`, `museum.wall_height: 3`, `gate_depth_rows: 0`); `tools/check_wave_platform_recovery.py` passes after the edits (12 maps, 193 platforms, 137 walls, route unchanged). Each map gained `museum.artifact_placement: "map"`, Astra's opt-in from the pilot review.

## Pre-museum layouts consulted

- Pendulum: `c47be1717` (11×19, no `w` ring) had `PendulumWave:90` at (0,6) with nothing west of it; the museum's `w` ring (d7a9dbd15) put a wall where its record recedes. Moved to (6,11):180.
- Sine Space: `c47be1717` (13×30) had the corridor at (6,2):90 across the first rows and a fully void basin with `tc:7:y:auto`; the bridge at x=10 is the museum's (8d49b4d37). The corridor moved to (6,4):90, along the antechamber, mouths clear.

## Reversal

Copy the `before/` files back over their originals; nothing else was written outside `ada_run/waves_chance_noise/`, the two probe files, the LOD tree entries and the plan directory (rebuilt by `tools/build_waves_chance_noise_plan.py`).

## Runtime pass, later the same day

After Astra's W1 review the five probes ran (see `ada_run/waves_chance_noise/2026-09-10-w1-batch.md`, runtime section). Placements changed from what was seen: Foucault to half scale at (10,3) and the dot plotter to (4,17) in Pendulum; the corridor to 7 m with a floor-slab collider, the corner case to (1,1), the second case and the three colour balls removed in Sine Space; the seed demo onto a table and the dark sphere moved in Random; frequency 10 in Noise; `museum.sculpture_clear_rects` in all five maps. Manifest of the sources after that pass: `after_runtime_sha256.txt`. Structure and utilities of every map still untouched (`check_wave_platform_recovery.py`: 12 maps, 193 platforms, 137 walls, route unchanged).

## Second runtime pass, evening (after Astra's runtime-evidence review)

The five probes ran again under project startup (`commons/testing/probe_live.tscn`, autoloads present) with actual desktop input through the project's desktop rig; the pendulum's corrected rerun is pending while the Godot editor holds the project. `after_second_pass_sha256.txt` hashes the files as they stand after this pass (the runtime manifest's files plus the launcher, the driver, the ports, the clear-rects probe, the port and checker tools and the five field notes). Account: `ada_run/waves_chance_noise/2026-09-10-w1-batch.md`, second runtime pass section.
