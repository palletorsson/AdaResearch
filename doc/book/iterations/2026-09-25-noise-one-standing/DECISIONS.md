# Noise One — standing recipients

25 September 2026. A spatial improvement to an existing comparison, with a small manuscript revision.

## What changed

- Upright pair: centre 1.40 m, holders rotated +90 degrees around local X. Mesh and sample marker share the holder. The display mounts reach into the lower tubes. The shader, field functions, sampling points, clock and controls are unchanged; legacy single-ring mode is unchanged.
- Entrance clearance: two floor rows inserted after the entrance boundary. Noise_One grows from 13×11 to 13×13. Every old layer row remains at its corresponding shifted address. Torus (5,4), basin (5,7), orb (8,10). The clear rectangle includes the new standing approach.
- Book: two prose paragraphs change. The opening reflects the upright display; the coordinate paragraph distinguishes local XZ from the room-facing orientation. One stable native museum figure added. All code, other prose, questions and anchors retained.
- Current placement notes and implementation notes updated. Registry description and QFEP interpretation corrected without altering its roles or legacy runtime behaviour. The inherited one-hour wrap is not described as a proven seamless loop.

## Preserved

The full terrain generator, staging script, scene resources, torus shader and scene are byte-for-byte unchanged. Existing basin contributions, independent orb and all room utilities remain. All sequence content, order and artifact-role lists are unchanged.

The core list contains only noisetorus, while older companion descriptions name all three works as primary. Automatic approval review rejected the proposed addition of dark_sphere to the core primary list, citing the author's instruction that it is generally secondary legacy material. That mutation never executed. We completed the work with roles preserved, updating only the current map/text hashes and review reference. A separate curatorial decision can resolve the pre-existing mismatch; no automatic promotion was needed for this scene improvement.

## Evidence

48 native checks, five controlled CharacterBody routes, two floor rays and 86 publication/preservation checks passed. Native button events operate the existing controls. Both upright holders preserve the six analytic marker offsets; sight rays to both ring centres are clear from the approach. Field and relief stay fixed through REMAP, amplitude leaves field value fixed, frequency changes it, and full cycles restore settings. All four terrain modes have one matching triangle collider; SUM restores the complete original vertex array. The orb clock advances while the pair clock is held.

Before/after staging captures use t=2 seconds, sample zero, and the same camera relative to the artifact. The artifact and camera move two metres into the room because the rows were inserted. Clipped/remapped captures select the first negative value among the six addresses at t=2 (index 1, approximately −0.1666) and keep the camera and clock fixed. The visual comparison is declared and reproducible, not a live learner observation. Native HUD/crosshair retained.

Two transient filesystem write errors were checked and retried without damaged files. The approval rejection above was separate from these I/O errors. The accepted native run has no script/shader compile errors; other engine warnings remain in verification.json.

## Limits and next step

No headset, learner, continuous-gameplay or Quest performance acceptance. No live bake/save replacement, commit or frozen export. Rebuild the hall to use the source map layout. Next: Noise_Voxel, carrying the question of encoding into cell occupancy. Inspect its existing material before adding another artifact.
