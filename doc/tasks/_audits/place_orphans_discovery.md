# Place Orphans Discovery

Discovery pass completed on 2026-04-17 for the `place_orphans` goal.

## `place_orphans.001` `standing_waves`

Artifact:
- Scene: `algorithms/wavefunctions/standing_waves/standing_waves.tscn`
- Registry: `commons/artifacts/registry/wavefunctions.json`

Known current refs:
- `commons/maps/TestMap_Unused_26/map_data.json`
- `commons/maps/WaveFunctions_Unused/map_data.json`

Target map:
- `commons/maps/WaveFunctions_Sine_Space/map_data.json`
- `python tools/map_pathfinder.py check WaveFunctions_Sine_Space` returns OK, but there is a warning about an unreachable teleport.
- `show` output reveals the lower void column already hosts unreachable decorative artifacts; placement should stay on the reachable upper walkway.

Interpretation:
- This is a real placement task, not a build task.
- Registry already exists; the work is selecting a concept-matching reachable slot in `WaveFunctions_Sine_Space`.

## `place_orphans.002` `pendulum_slap`

Artifact:
- Scene: `algorithms/softbodies/slap_test/pendulum_slap.tscn`
- Registry: `commons/artifacts/registry/soft_bodies.json`

Known current refs:
- `commons/maps/SoftBodies_Obsticals_Part1/map_data.json`

Target map:
- `commons/maps/WaveFunctions_Pendulum/map_data.json`
- `python tools/map_pathfinder.py check WaveFunctions_Pendulum` returns OK.

Interpretation:
- This is a cross-sequence placement: soft body artifact into a wavefunctions map.
- The target map already has pendulum-adjacent anchors (`PendulumWave`, `foucault_pendulum`), so placement should be near the pendulum teaching cluster, not just any empty tile.

## `place_orphans.003` `soft_trampoline`

Artifact:
- Scene: `algorithms/softbodies/advanced_concepts/soft_trampoline.tscn`
- Registry: `commons/artifacts/registry/soft_bodies.json`

Known current refs:
- `commons/maps/Gallery_PhysicsSimulation/map_data.json`

Target map:
- `commons/maps/SoftBodies_Soft_Body_Deformation/map_data.json`
- `python tools/map_pathfinder.py check SoftBodies_Soft_Body_Deformation` returns OK.

Interpretation:
- This is a real placement task, not a build task.
- The target map currently centers on `jelly_cube` and `softmill`; trampoline should reinforce restoring force / deformation, not duplicate unrelated gallery content.

## `place_orphans.004` `curl_noise_particles` and `noise_mixer`

Artifacts:
- `commons/artifacts/curl_noise_particles/curl_noise_particles.tscn`
- `commons/artifacts/noise_mixer/noise_mixer.tscn`
- Both registered in `commons/artifacts/registry/randomness.json`

Known current refs:
- `curl_noise_particles` appears in `commons/maps/Random_Space_Geometry/map_data.json`
- `noise_mixer` appears in `commons/maps/Gallery_Randomness/map_data.json` and `commons/maps/Random_Space/map_data.json`

Audit direction:
- `doc/curriculum_audit/noise.md` says the vector-field learning objective is currently unanchored.
- `doc/curriculum_audit/_placement_plan.md` explicitly recommends a **new** map: `Noise_Vector_Fields`
- Same placement-plan section also points to `VectorFieldFlow` as a third natural resident of that map.

Interpretation:
- This is not a simple “choose Noise_One or Noise_Voxel” placement.
- Discovery strongly favors creating a new map `commons/maps/Noise_Vector_Fields/` and then inserting it into `commons/maps/sequences/noise.json`.

## `place_orphans.005` transformation matrix cluster

Artifacts:
- `matrix_4x4_viewer`
- `homogeneous_coordinates`
- `rotation_gimbal`
- `transform_composition`

Registry:
- `commons/artifacts/registry/transforms.json`

Current source placements in `commons/maps/Trans_Introduction/map_data.json`:
- `matrix_4x4_viewer` at `(5,6)`
- `homogeneous_coordinates` at `(2,8)`
- `rotation_gimbal` at `(8,8)`
- `transform_composition` at `(2,12)`

Target map:
- `commons/maps/Trans_Composition/map_data.json` exists
- `python tools/map_pathfinder.py check Trans_Introduction Trans_Composition` returns OK with one warn-level teleport issue in `Trans_Composition`
- `Trans_Composition` is **not** listed in `commons/maps/sequences/transformation.json`

Audit direction:
- `doc/curriculum_audit/transformation.md` treats `Trans_Composition` as the natural home for this algebra/composition layer.
- The same audit notes `Trans_Pit` and `Chamber_Transformation` are also missing from `content[]` and `artifact_groups[]`.

Interpretation:
- This is bigger than “move four artifacts”.
- It is a sequence-manifest activation task: add `Trans_Composition` to `transformation.json`, then move the matrix cluster into that map, then reconcile `content[]` and `artifact_groups[]`.

## `place_orphans.006` `Point_Polygon`

Current state:
- `commons/maps/Point_Polygon/map_data.json` does not exist
- `commons/maps/sequences/primitives.json` does not reference `Point_Polygon`
- `doc/curriculum_audit/primitives.md` treats `Point_Polygon` as a missing map in the ideal conceptual sequence

Artifact state:
- No obvious dedicated n-gon / polygon primitive artifact was found in registry or scene search
- This is not a simple placement of an existing orphan

Interpretation:
- This is a sequence-expansion + artifact-build task, not an orphan-placement task.

## `place_orphans.007` `Point_Circle`

Current state:
- `commons/maps/Point_Circle/map_data.json` does not exist
- `commons/maps/sequences/primitives.json` does not reference `Point_Circle`

Artifact state:
- No dedicated circle teaching artifact was found in the registry search

Interpretation:
- This is a follow-on build task after polygon, not a placement task.

## `place_orphans.008` `Point_Coordinate_System`

Current state:
- `commons/maps/Point_Coordinate_System/map_data.json` does not exist
- `commons/maps/sequences/primitives.json` does not reference `Point_Coordinate_System`

Artifact state:
- `CoordinateSystem3M` already exists:
  - Scene: `algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn`
  - Registry: `commons/artifacts/registry/vectors.json`
- It is already placed in:
  - `commons/maps/Point_One/map_data.json`
  - `commons/maps/Point_Zero/map_data.json`

Interpretation:
- This is **not** an artifact-build task.
- It is a map-creation + sequence-insertion task using an existing artifact, with an additional design choice about whether `CoordinateSystem3M` should be duplicated or relocated from earlier maps.
