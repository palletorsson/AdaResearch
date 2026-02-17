## Playable Spine Path (Live Status)

Generated from `commons/maps/curriculum_spine.json` + sequence JSON files.
Sequence membership is explicit from each sequence JSON `maps[]`; map-name prefixes are ignored.
Artifact suggestions are metadata-curated from registry fields (`map_sequences`/`sequence`/`category`/`dev_category`/`tags`).

| # | Sequence | Phase | Declared | Existing | Missing | First Map | Suggested Artifacts |
|---|---|---|---:|---:|---:|---|---|
| 1 | `primitives` | `F_order` | 12 | 12 | 0 | `Point_One` | `Random_Rotate_Random_XYZ`, `attachable_wood_cube`, `binary_table`, `index_visualizer` |
| 2 | `transformation` | `F_order` | 6 | 6 | 0 | `Trans_Intro` | `transformation_workbench`, `transform_matrix_cube`, `vector_translation_demo`, `vector_addition_demo` |
| 3 | `color` | `F_order` | 12 | 12 | 0 | `Color_Nails` | `shader_02_colors`, `ball_dropper` |
| 4 | `forces` | `oscillation` | 10 | 10 | 0 | `Forces_1` | `force_field_visualizer`, `orbital_mechanics_demo`, `surreal_kinetic_sculpture`, `vector_joint_playground` |
| 5 | `array_tutorial` | `F_order` | 8 | 8 | 0 | `Tutorial_Single` | - |
| 6 | `wavefunctions` | `oscillation` | 12 | 12 | 0 | `WaveFunctions_Intro` | `coupled_pendulums`, `living_paper_fourier`, `living_paper_heat`, `living_paper_lissajous` |
| 7 | `randomness` | `E_entropy` | 13 | 13 | 0 | `Random_Definition` | `monte_carlo_estimator`, `distribution_sampler`, `random_walk_terrarium`, `grid3d_entropy` |
| 8 | `noise` | `E_entropy` | 11 | 11 | 0 | `Random_Noise_Types` | `flow_field_painter`, `perlin_terrain_sculptor`, `living_paper_noise_octaves`, `living_paper_perlin` |
| 9 | `cellularautomata` | `E_entropy` | 12 | 12 | 0 | `CA_1` | `ca_rule_explorer`, `game_of_life_petri`, `grid2d_brians_brain`, `grid2d_life` |
| 10 | `fractals` | `lambda_edge` | 14 | 14 | 0 | `Fractals_1` | `julia_set_explorer`, `mandelbrot_dive`, `living_paper_julia`, `living_paper_koch` |
| 11 | `lsystems` | `lambda_edge` | 11 | 11 | 0 | `LSystems_Hilbert3D` | `living_paper_dragon`, `living_paper_fern`, `living_paper_tree`, `lsystem_editor` |
| 12 | `proceduralgeneration` | `lambda_edge` | 18 | 18 | 0 | `ProceduralGeneration_Two` | `grid3d`, `pixel_cloud`, `plane_manipulator`, `ten_print_maze_3d` |
| 13 | `morphogenesis` | `integration` | 2 | 2 | 0 | `ProceduralGeneration_Reaction_Diffusion_Systems` | `turing_pattern_generator`, `shader_10_reactiondiffusion` |
| 14 | `swarmintelligence` | `integration` | 7 | 7 | 0 | `SwarmIntelligence_PhysarumColony` | `boids_aquarium`, `pheromone_terrain` |
| 15 | `softbodies` | `integration` | 8 | 8 | 0 | `SoftBodies_Carusell` | `jelly_cube`, `jelly_variants` |
| 16 | `machinelearning` | `integration` | 16 | 16 | 0 | `MachineLearning_Evolving_Creatures` | `living_paper_kmeans`, `profile_gradient_descent`, `transformation_workbench` |
| 17 | `foundationscrisis` | `synthesis` | 7 | 7 | 0 | `Euclid_Parallel` | `euclid_postulates_plaque`, `escher_staircase`, `florensky_sphere`, `godel_statement_plaque` |
| 18 | `qfeplaboratory` | `synthesis` | 8 | 8 | 0 | `QFEP_Introduction` | `bifurcation_walkway`, `chaos_particles`, `complexity_pattern`, `crystal_cluster` |
| 19 | `speculativecomputation` | `synthesis` | 5 | 5 | 0 | `SpeculativeComputation_Evolutionary_Algorithms` | `ca_rule_explorer` |
| 20 | `criticalalgorithms` | `synthesis` | 6 | 6 | 0 | `CriticalAlgorithms_Algorithmic_Misframing` | `bias_visualizer`, `bar_array_prime_sieve`, `mass_spring_damper` |
| 21 | `graphtheory` | `integration` | 14 | 14 | 0 | `GraphTheory_Network_Analysis` | `grid3d`, `grid3d_bfs`, `grid3d_dfs`, `grid3d_force_directed` |

Use `python tools/spine_map_workbench.py scaffold --sequence <id> --map <Map_Name> --update-sequence` to add missing spine maps quickly.
