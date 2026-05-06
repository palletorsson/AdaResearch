# Artifact Placement Plan

Derived from the 19 curriculum audits. Tracks what's been placed, what still needs placing, and the reasoning behind each placement decision.

## Placement principle

Each artifact goes into the map whose **concept it serves**. Not just "an empty cell exists" \u2014 the placement must follow the red thread of both the map and the sequence. When the @identity block of an artifact declares which map it belongs to, trust it.

## Placed this session

| Artifact | Target map | Reasoning |
|---|---|---|
| `example_2_1_forces_vr` | `ForcesFoundations` (row 9 col 14) | Newton's F=ma \u2014 the map's titular law. Also added missing registry entry. |
| `example_2_2_forces_mass_variation_vr` | `ForcesFoundations` (row 9 col 16) | Mass as a force parameter; sits between 2_1 and 2_3 on the Newton ladder. |
| `coupled_oscillator_lattice` | `WaveFunctions_3D_Wave_Propagation` (row 13 col 8) | Coupled oscillators are the mechanical substrate of wave propagation \u2014 belongs here, not in an unused lab. |
| `topological_sort` | `GT_Connectivity` (row 5 col 8) | The map's own description names this artifact. It was placed in a standalone gallery instead. |
| `karger_algorithm` | `GT_Flow` (row 4 col 5) | Randomized min-cut belongs in the Flow map, not in a gallery clone. |
| `ContextFreeGrammars` | `LSystems_Grammars_And_Curves` (row 11 col 2) + new registry entry | Formal grammars = the theoretical parent of L-systems. Was flagged missing by audit; both script and scene existed on disk. |

## Verified already placed correctly (audit outdated)

These were flagged as "unplaced" in the audits but are actually in their proper maps:

| Artifact | Placed in | Notes |
|---|---|---|
| `box_counting_dimension` | `Fractal_KochSierpinski` | @identity correctly predicts placement |
| `SimultaneousContrast` | `Color_Context` | Dedicated perception map exists |
| `MetamerismLab` | `Color_Context` | Same |
| `wave_interference_3d` | `WaveFunctions_Effect_Sound` | |
| `beat_frequency_demo` | `WaveFunctions_TrigWalkingPath` | |
| `stigmergy_grid` | `Gallery_SwarmIntelligence` | Should arguably move to a spine map, but placed |
| `grammar_provenance` | `LSystems_Grammar_Lab` | Critical-theory layer present |
| `hilbert_hotel` | `Gallery_Foundations` | Outside spine but placed |

## Still unplaced (priority order)

### High priority (fills documented gap)

| Artifact | Suggested target | Reason |
|---|---|---|
| `standing_waves` | `WaveFunctions_Sine_Space` or `WaveFunctions_Synthesis_Lab` | Standing wave = fixed boundary conditions, pedagogical climax of sine understanding |
| `pendulum_slap` | `WaveFunctions_Pendulum` | Already has pendulum map \u2014 this adds interaction |
| `soft_trampoline` | `SoftBodies_Soft_Body_Deformation` | Trampoline = restoring force = softbody |
| `squishy_ball_pit` | `SoftBodies_Obsticals` or new bodies map | |
| `softbody_gallery_part1/3` | `SoftBodies_Obsticals` | Natural home |
| `array_rotate`, `array_scale`, `array_transform_staircase` | NEW map `Array_Transforms` | Audit recommends creating a bridge map for array-as-operand |
| `glass_planes_2_5d`, `mondrian_grid` | `Array_Patterns` | 2.5D patterns belong in patterns map |

### Medium priority (needs new map)

| Artifact | Suggested target | Reason |
|---|---|---|
| `curl_noise_particles`, `noise_mixer` | NEW map `Noise_Vector_Fields` | Vector field objective is currently unanchored |
| `VectorFieldFlow` | Same | Declared in noise.json but no map home |

### Low priority (consider deprecation or minor placement)

| Artifact | Status | Suggested action |
|---|---|---|
| `lattice_gas_automata/` | Orphan folder | Wire into `CA_SoftRules` or archive |
| `noc_ch07/` | Orphan folder | Same |
| `self_organizing_patterns` | Listed in PSO map but only has plan doc, no scene | Build it or remove reference |

## Transformation sequence: needs major rework

The transformation audit identified four artifacts parked in Trans_Introduction that should move:
- `matrix_4x4_viewer`
- `homogeneous_coordinates`
- `rotation_gimbal`
- `transform_composition`

Target: `Trans_Composition` (folder exists at `commons/maps/Trans_Composition/map_data.json` but is not in the sequence's `maps[]` array).

**This is a bigger change** \u2014 requires:
1. Add `Trans_Composition` to sequence JSON
2. Move the 4 artifacts from Trans_Introduction to Trans_Composition
3. Verify Trans_Introduction still has appropriate opening artifacts
4. Update sequence metadata

Left for a dedicated session.

## Map ordering fixes needed (separate from placement)

From audits:
- **wavefunctions**: Swap `Sine_Space` and `Unit_Circle` \u2014 origin before spatialization
- **array_tutorial**: Patterns-first ordering contradicts the dimension ladder
- **cellularautomata**: JSON lists `Intro \u2192 ElementaryRules \u2192 GameOfLife` but intents describe `Intro \u2192 Life \u2192 ElementaryRules`
- **swarmintelligence**: Physarum opens too radically; should come later after learner has swarm vocabulary

Map ordering changes need user signoff \u2014 they affect player progression, not just teaching material.

## Next placement session should:

1. Do the transformation rework (Trans_Composition activation)
2. Place standing_waves + softbody orphans
3. Create `Array_Transforms` bridge map and move transform-array artifacts there
4. Create `Noise_Vector_Fields` map and place curl_noise/noise_mixer

## Validation status

After this session's placements: **500/500 maps pass pathfinder**. No structural regressions.
