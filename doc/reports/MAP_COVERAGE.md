# Map Coverage Report

Joining spine map placements against `ARTIFACT_DOC_INDEX.json`.

- Maps scanned: **179**
- Maps with perfect coverage (score = 1.0): **145**
- Maps with no load-bearing placements: **2**
- Average coverage score: **94.1%**
  (documented-or-mentioned / load-bearing)
- Average doc-only coverage: **90.9%**

## Placement totals

- Load-bearing placements across all maps: **764**
- Documented placements: **695**
- Undocumented placements (placeholder / none): **69**
- Placements mentioned by backtick in any text: **301**
- Silent reinforcement (documented, not mentioned): **417**
- Silent undocumented (not documented, not mentioned — concerning): **46**
- Text orphans (backticked but not placed): **22**
- Unregistered placed tokens: **63**

## Maps with incomplete coverage (worst first)

| Map | Placed | Documented | Mentioned | Silent-undoc | Score |
|---|---:|---:|---:|---:|---:|
| PG_Sculpted_Forms | 3 | 0 | 0 | 3 | 0% |
| PG_Space_Colonization | 1 | 0 | 0 | 1 | 0% |
| SoftBodies_Playground_of_Joy | 3 | 1 | 0 | 2 | 33% |
| Fractal_GoldenSpiral | 2 | 1 | 0 | 1 | 50% |
| PG_Genetic_Evolution | 2 | 1 | 0 | 1 | 50% |
| PG_Branching_Growth | 2 | 1 | 0 | 1 | 50% |
| PG_Caves_Mazes | 2 | 1 | 0 | 1 | 50% |
| PG_Mirrored_Patterns | 2 | 1 | 0 | 1 | 50% |
| ProceduralGeneration_Reaction_Diffusion_Systems | 2 | 1 | 0 | 1 | 50% |
| Trans_Scale | 5 | 3 | 0 | 2 | 60% |
| Primitives_Portals | 3 | 2 | 1 | 1 | 67% |
| WaveFunctions_John_Cage | 3 | 2 | 0 | 1 | 67% |
| Fractal_JuliaSet | 3 | 2 | 0 | 1 | 67% |
| ML_Evolution | 7 | 5 | 0 | 2 | 71% |
| WaveFunctions_Intro | 15 | 11 | 5 | 4 | 73% |
| Color_Nails | 8 | 6 | 0 | 2 | 75% |
| Primitives_Polythedra | 4 | 3 | 1 | 1 | 75% |
| Random_Rotate_Random_XYZ | 4 | 3 | 3 | 1 | 75% |
| SoftBodies_Obsticals | 4 | 3 | 0 | 1 | 75% |
| WaveFunctions_Unit_Circle | 5 | 4 | 3 | 1 | 80% |
| WaveFunctions_TrigWalkingPath | 5 | 4 | 0 | 1 | 80% |
| Random_Walk | 5 | 4 | 4 | 1 | 80% |
| Fractal_CrossSequence | 5 | 4 | 0 | 1 | 80% |
| Point_Triangle | 6 | 5 | 3 | 1 | 83% |
| Trans_AxisDecomposition | 6 | 5 | 0 | 1 | 83% |
| ForcesArena | 16 | 14 | 0 | 2 | 88% |
| ForcesComposition | 8 | 7 | 0 | 1 | 88% |
| Random_Gaussian | 8 | 6 | 5 | 1 | 88% |
| Fractal_Synthesis | 9 | 8 | 0 | 1 | 89% |
| WaveFunctions_Effect_Sound | 20 | 18 | 7 | 2 | 90% |
| Primitives_Melencolia | 10 | 8 | 8 | 1 | 90% |
| Primitives_Ignorance | 21 | 16 | 12 | 2 | 90% |
| Point_Lines | 15 | 12 | 8 | 1 | 93% |
| WaveFunctions_Synthesis_Lab | 22 | 20 | 10 | 1 | 96% |

## Maps with text orphans — text backticks artifacts not placed (22)

- **Point_Triangle_Context** → `quad_line_puzzle`
- **Trans_Introduction** → `origin`
- **Trans_Translation** → `origin`
- **Chamber_Transformation** → `miura_crawler`
- **Chamber_Color** → `kaleidocycle_enemy`
- **Chamber_Forces** → `kresling_spire`
- **Chamber_Waves** → `waterbomb_enemy`
- **Randomness_10_PRINT_Algorithm** → `Shader_Gallery`
- **Chamber_Random** → `octapod_crawler`
- **Noise_Perlin_Simplex** → `configurable_portal`
- **Chamber_CA** → `lifeform_walker`
- **Chamber_Fractals** → `fractal_hydra`
- **LSystems_Living** → `AnimatedTree`
- **Chamber_LSystems** → `branching_vine`
- **Chamber_ProcGen** → `bricoleur_golem`
- **Chamber_SoftBodies** → `spring_hopper`
- **Chamber_Swarm** → `swarm_hive`
- **Chamber_ML** → `gradient_hunter`
- **Escher_Impossible** → `bifurcation_diagram`
- **Chamber_Foundations** → `paradox_stalker`
- **QFEP_E_Term** → `entropy_jar`
- **Chamber_QFEP** → `qfep_calibrator`

## Maps with unregistered placed tokens (38)

- **Point_Triangle_Context** → `quad_line_puzzle#fillhole`
- **Trans_Translation** → `pickup_gate#pickups`
- **Trans_AxisDecomposition** → `pickup_gate#pickups`
- **Trans_Rotation** → `pickup_gate#pickups`
- **Trans_Scale** → `clipboard#vr_scale_controls`
- **Trans_Pit** → `grower_block#min`, `pusher_block#axis`
- **Chamber_Transformation** → `becoming_catalyst#start_mode`, `proximity_spawner#type`
- **Chamber_Color** → `becoming_catalyst#start_mode`, `proximity_spawner#type`
- **VectorFoundations** → `becoming_catalyst#start_mode`, `catalyst_target#shape`
- **VectorOperations** → `catalyst_target#shape`, `proximity_spawner#type`
- **VectorApplied** → `catalyst_target#shape`, `proximity_spawner#type`
- **VectorAdvanced** → `catalyst_target#shape`, `proximity_spawner#type`
- **ForcesFoundations** → `catalyst_target#shape`, `proximity_spawner#type`
- **ForcesComposition** → `catalyst_target#shape`, `proximity_spawner#type`
- **ForcesSystems** → `catalyst_target#shape`, `proximity_spawner#type`
- **ForcesChaos** → `catalyst_target#shape`, `proximity_spawner#type`
- **ForcesArena** → `catalyst_target#shape`, `proximity_spawner#type`
- **Chamber_Forces** → `becoming_catalyst#start_mode`, `proximity_spawner#type`
- **Tutorial_Disco** → `standalone_disco#width`
- **Chamber_Arrays** → `proximity_spawner#type`
- **WaveFunctions_Effect_Sound** → `AudioContr#config`, `GlassRack#config`, `MarioSoundController#mode`
- **Chamber_Waves** → `becoming_catalyst#start_mode`, `proximity_spawner#type`
- **Random_Definition** → `clipboard#prng_axioms`
- **Randomness_10_PRINT_Algorithm** → `clipboard#ten_print_axioms`
- **Random_Pheromone** → `clipboard#pheromone_axioms`, `clipboard#queer_energy`
- **Random_Game** → `armadillo_eggling#roll_speed`, `cube_projectile_spawner#mode`, `origami_droideka#roll_speed`
- **Chamber_Random** → `becoming_catalyst#start_mode`, `proximity_spawner#type`
- **Noise_Perlin_Simplex** → `configurable_portal#dest_map`
- **Chamber_CA** → `becoming_catalyst#start_mode`, `proximity_spawner#type`
- **Fractal_GoldenSpiral** → `fibonacci_terrain#preset`, `golden_rectangle#preset`
