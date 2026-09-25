# Uncommitted code the revised halls run on

Generated 24 September 2026. For each hall: every placed token is resolved through `commons/artifacts/registry/*.json` to its scene. The scene's script and scene references, and one level of `load`/`preload` from those scripts, are then checked against `git status`.

This is a **lower bound**: scripts mounted by a computed path, and new files inside untracked directories, can be missed. "This block" means the file carries this block's change, and possibly another session's edits as well (see INTEGRATION.md section 9).

Committing a hall's `final.md` without its row here ships a chapter that describes an encounter HEAD does not build.

| hall | other sessions' uncommitted files | this block |
|---|---|---|
| Random_Definition | `algorithms/randomness/seed_replay/seed_replay_demo.gd` | - |
| Random_Entropy | `commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd` | - |
| Random_Remove | - | `commons/artifacts/randomness_space/removal_arena.gd` |
| Randomness_10_PRINT_Algorithm | `algorithms/randomness/generative/tenprintantmaze/ten_print_maze.gd`<br>`commons/artifacts/science_screen/science_screen.gd` | - |
| Random_Cubes | - | `algorithms/randomness/coin_toss/coin_toss.gd`<br>`algorithms/randomness/dice_throw/dice_throw.gd` |
| Random_Rotate_Random_XYZ | - | `algorithms/randomness/RandomRotateRandomXYZ/RandomRotateRandomXYZ.gd`<br>`algorithms/randomness/randomdecay/scripts/random_decay_multimesh.gd` |
| Random_Walk | `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd` | - |
| Random_Gaussian | `commons/artifacts/distribution_sampler/distribution_sampler.gd` | - |
| Random_Mushrooms | `algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd` | - |
| Random_Space_Geometry | `algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd` | - |
| Randomness_Examples_of_Randomness | `algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd`<br>`algorithms/randomness/proceduralrandomness/movementbased/scenes/pollock2d/paint_dripping_2d.gd`<br>`algorithms/randomness/proceduralrandomness/movementbased/scenes/pollock2d/paint_dripping_2d.tscn`<br>`algorithms/randomness/proceduralrandomness/particlerandomness/extrem_randomness.gd` | - |
| Random_Pheromone | `algorithms/randomness/pheromone_terrain/pheromone_terrain.gd` | - |
| Random_Space | `commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd` | `commons/artifacts/noise_mixer/noise_mixer.gd` |
| Random_Game | - | `commons/artifacts/randomness_space/removal_arena.gd` |
| Random_Noise_Types | `algorithms/randomness/randompoint/randompoint.gd`<br>`algorithms/randomness/randompoints/randompoints.gd`<br>`algorithms/randomness/whitenoise/noise_spectrum_3d.gd`<br>`algorithms/randomness/whitenoise/white_noise_spectrum.gd` | - |
| Noise_Columns | `algorithms/proceduralgeneration/hybrid_complex/berninicolumns/MeltingBerniniColumns.gd` | - |
| Noise_One | `algorithms/randomness/noiselayers/noiselayers.tscn`<br>`algorithms/randomness/noisetorus/noisetorus.gd` | - |
| Noise_Voxel | `algorithms/randomness/voxelnoise/voxelnoise.gd`<br>`commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd`<br>`commons/artifacts/science_screen/science_screen.gd` | - |
| Noise_6_Wall | `algorithms/randomness/shadernoisespace/QueerNoiseShader.gdshader`<br>`algorithms/randomness/shadernoisespace/WallNoiseShader.gdshader`<br>`algorithms/randomness/shadernoisespace/noiseroom.gd` | - |
| Noise_Inside_Noise | `algorithms/randomness/noisesphere/noisesphere.gd` | - |
| Noise_Space_10 | `commons/context/walkgrids/NoiseSpace.gd` | - |
| Noise_Perlin_Simplex | `algorithms/randomness/perlinnoise/PerlinNoise.gd`<br>`algorithms/randomness/simplexnoise/SimplexNoise.gd` | - |
| Lab_Path | - | - |
| CA_Introduction | `algorithms/cellularautomata/ca_showcase/disease_spread_ca.gd`<br>`commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd` | `algorithms/cellularautomata/ca_showcase/LineNetworkCA.gd` |
| CA_ElementaryRules | `algorithms/cellularautomata/cellular_automata_3d/CellularAutomata3D_Flexible.gd` | - |
| CA_GameOfLife | `algorithms/cellularautomata/ca_bridge/ca_bridge.gd`<br>`algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirror_cellular_texture_for_3d.gd`<br>`algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirror_cellular_texture_for_3d.tscn`<br>`algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirrored_cellular_automata.gd`<br>`commons/artifacts/lab_room/lab_room.gd` | - |
| CA_BeyondBinary | `algorithms/cellularautomata/cellular_automata_3d/CellularAutomata3D_Flexible.gd`<br>`commons/artifacts/game_of_life_petri/game_of_life_petri.gd`<br>`commons/artifacts/science_screen/science_screen.gd` | - |
| CA_ExpandingSpace | `algorithms/cellularautomata/cellular_automata_3d_tree/CellularAutomata3DTree.gd`<br>`algorithms/cellularautomata/living_architecture/decaying_bridge.gd` | - |
| CA_SoftRules | `commons/artifacts/rd_artifact/rd_artifact.gd`<br>`commons/artifacts/the_clockmaker_of_rules/the_clockmaker_of_rules.gd` | - |
| CA_AgentsCircuits | `algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd`<br>`commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd` | - |
| CA_EdgeOfChaos | `algorithms/cellularautomata/ca_showcase/disease_spread_ca.gd`<br>`algorithms/cellularautomata/ca_showcase/self_organization_ca.gd`<br>`algorithms/cellularautomata/volumetric_fog/volumetric_fog_ca.gd` | - |

30 of 31 halls place at least one work whose code is uncommitted.
