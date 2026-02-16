## Sequence Contract Audit

Checks explicit `maps[]` ownership only; map-name similarities are informational hints and never auto-assigned.

| Metric | Count |
|---|---:|
| `total_sequences` | 46 |
| `declared_entries` | 396 |
| `declared_unique_maps` | 383 |
| `map_folders_with_data` | 529 |
| `duplicate_entries_within_sequence` | 0 |
| `duplicates_across_sequences` | 13 |
| `missing_declared_maps` | 0 |
| `undeclared_map_folders` | 146 |
| `undeclared_prefix_hints` | 61 |
| `cross_sequence_prefix_hints` | 27 |

### duplicates_across_sequences

- `CA_1` declared in `cellular_automata_showcase` (commons/maps/map_progression.json), `cellularautomata` (commons/maps/sequences/cellularautomata.json)
- `CA_2` declared in `cellular_automata_showcase` (commons/maps/map_progression.json), `cellularautomata` (commons/maps/sequences/cellularautomata.json)
- `CA_3` declared in `cellular_automata_showcase` (commons/maps/map_progression.json), `cellularautomata` (commons/maps/sequences/cellularautomata.json)
- `CA_4` declared in `cellular_automata_showcase` (commons/maps/map_progression.json), `cellularautomata` (commons/maps/sequences/cellularautomata.json)
- `CA_5` declared in `cellular_automata_showcase` (commons/maps/map_progression.json), `cellularautomata` (commons/maps/sequences/cellularautomata.json)
- `CA_6` declared in `cellular_automata_showcase` (commons/maps/map_progression.json), `cellularautomata` (commons/maps/sequences/cellularautomata.json)
- `CA_7` declared in `cellular_automata_showcase` (commons/maps/map_progression.json), `cellularautomata` (commons/maps/sequences/cellularautomata.json)
- `CA_8` declared in `cellular_automata_showcase` (commons/maps/map_progression.json), `cellularautomata` (commons/maps/sequences/cellularautomata.json)
- `Escher_Impossible` declared in `artmathematics` (commons/maps/sequences/artmathematics.json), `foundationscrisis` (commons/maps/sequences/foundationscrisis.json)
- `Structure_Examples_VoxelGrammar_Principles` declared in `testmaps` (commons/maps/sequences/testmaps.json), `transformation` (commons/maps/sequences/transformation.json)
- `Tutorial_Disco` declared in `array_tutorial` (commons/maps/sequences/array_tutorial.json), `tutorial_progression` (commons/maps/map_progression.json)
- `Tutorial_Row` declared in `array_tutorial` (commons/maps/sequences/array_tutorial.json), `tutorial_progression` (commons/maps/map_progression.json)
- `Tutorial_Single` declared in `array_tutorial` (commons/maps/sequences/array_tutorial.json), `tutorial_progression` (commons/maps/map_progression.json)

### undeclared_map_folders

- `Base` has `map_data.json` but is not in any sequence `maps[]`
- `Dialectic_Automation` has `map_data.json` but is not in any sequence `maps[]`
- `Directionality_Examples` has `map_data.json` but is not in any sequence `maps[]`
- `gridagent_puzzle01_copy` has `map_data.json` but is not in any sequence `maps[]`
- `gridagent_puzzle02_translate` has `map_data.json` but is not in any sequence `maps[]`
- `gridagent_puzzle03_rotate` has `map_data.json` but is not in any sequence `maps[]`
- `InfoBoards_Example` has `map_data.json` but is not in any sequence `maps[]`
- `Joints_1` has `map_data.json` but is not in any sequence `maps[]`
- `Joints_2` has `map_data.json` but is not in any sequence `maps[]`
- `Joints_3` has `map_data.json` but is not in any sequence `maps[]`
- `Joints_4` has `map_data.json` but is not in any sequence `maps[]`
- `Joints_5` has `map_data.json` but is not in any sequence `maps[]`
- `Joints_6` has `map_data.json` but is not in any sequence `maps[]`
- `Joints_7` has `map_data.json` but is not in any sequence `maps[]`
- `Lab` has `map_data.json` but is not in any sequence `maps[]`
- `lsystem` has `map_data.json` but is not in any sequence `maps[]`
- `One_Adapt_1` has `map_data.json` but is not in any sequence `maps[]`
- `One_Adapt_2` has `map_data.json` but is not in any sequence `maps[]`
- `One_Adapt_3` has `map_data.json` but is not in any sequence `maps[]`
- `One_Adapt_4` has `map_data.json` but is not in any sequence `maps[]`
- `One_Adapt_5` has `map_data.json` but is not in any sequence `maps[]`
- `One_Adapt_6` has `map_data.json` but is not in any sequence `maps[]`
- `One_Adapt_7` has `map_data.json` but is not in any sequence `maps[]`
- `oscillation_1` has `map_data.json` but is not in any sequence `maps[]`
- `oscillation_2` has `map_data.json` but is not in any sequence `maps[]`
- `oscillation_3` has `map_data.json` but is not in any sequence `maps[]`
- `oscillation_4` has `map_data.json` but is not in any sequence `maps[]`
- `oscillation_5` has `map_data.json` but is not in any sequence `maps[]`
- `oscillation_6` has `map_data.json` but is not in any sequence `maps[]`
- `oscillation_7` has `map_data.json` but is not in any sequence `maps[]`

### undeclared_prefix_hints (info only)

- `lsystem` looks related to `lsystems`(8)
- `Pattern_Generation_Five` looks related to `patterngeneration`(8)
- `Pattern_Generation_Four` looks related to `patterngeneration`(8)
- `Pattern_Generation_One` looks related to `patterngeneration`(8)
- `Pattern_Generation_Seven` looks related to `patterngeneration`(8)
- `Pattern_Generation_Six` looks related to `patterngeneration`(8)
- `Pattern_Generation_Three` looks related to `patterngeneration`(8)
- `Pattern_Generation_Two` looks related to `patterngeneration`(8)
- `PatternGeneration_Diffusion_Limited_Aggregation_DLA` looks related to `patterngeneration`(8)
- `PatternGeneration_Narrative_Generation` looks related to `patterngeneration`(8)
- `PatternGeneration_Penrose_Tilings` looks related to `patterngeneration`(8)
- `PatternGeneration_Typography_Generation` looks related to `patterngeneration`(8)
- `PatternGeneration_Wang_Tiles` looks related to `patterngeneration`(8)
- `PhysicsSimulation_Bouncing_Ball_Physics` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Cloth_Simulation` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Collision_Detection` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Constraints` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Finite_Element_Method_FEM` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Fluid_Simulation_SPH` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Force_Fields` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Mass_Spring_Damper` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Newton_s_Laws` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Numerical_Integration` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Particle_Systems` looks related to `particles`(8), `physicssimulation`(8)
- `PhysicsSimulation_Rigid_Body_Dynamics` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Spring_Mass_Systems` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Three_Body_Problem` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Vector_Fields` looks related to `physicssimulation`(8)
- `PhysicsSimulation_Verlet_Integration` looks related to `physicssimulation`(8)
- `Primitives_2` looks related to `primitives`(8)

### cross_sequence_prefix_hints (info only)

- `ProceduralGenerationBooleanPatterns` owned by `constraint_solvers`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationNetSpace` owned by `higher_dimensions`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationPortals` owned by `higher_dimensions`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationSixteenCellNet` owned by `higher_dimensions`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationTesseractErrorTunnel` owned by `higher_dimensions`; also name-matches `proceduralgeneration`(8)
- `ProceduralGenerationWfcDungeonGenerator` owned by `constraint_solvers`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Delaunay_Triangulation` owned by `spatial_partitioning`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_MarchingCave` owned by `isosurfaces`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_MarchingGallery` owned by `isosurfaces`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Marching_Cubes_Algorithm` owned by `isosurfaces`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Markov_Chains` owned by `grammar_systems`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_N_grams` owned by `grammar_systems`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Poisson_Disk_Sampling` owned by `spatial_partitioning`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Reaction_Diffusion_Systems` owned by `morphogenesis`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Space_Partitioning` owned by `spatial_partitioning`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Voronoi_Diagrams` owned by `spatial_partitioning`; also name-matches `proceduralgeneration`(8)
- `ProceduralGeneration_Wave_Function_Collapse` owned by `constraint_solvers`; also name-matches `proceduralgeneration`(8)
- `RecursiveEmergence_Cellular_Automata_1D` owned by `recursiveemergence`; also name-matches `cellularautomata`(8)
- `RecursiveEmergence_Cellular_Automata_2D` owned by `recursiveemergence`; also name-matches `cellularautomata`(8)
- `RecursiveEmergence_Cellular_Automata_3D` owned by `recursiveemergence`; also name-matches `cellularautomata`(8)
- `SearchPathfinding_Particle_Swarm_Optimization` owned by `searchpathfinding`; also name-matches `particles`(8)
- `Shader_02_Colors` owned by `patterngeneration`; also name-matches `color`(8)
- `Shader_07_Noise` owned by `patterngeneration`; also name-matches `noise`(8)
- `Shader_08_CellularNoise` owned by `patterngeneration`; also name-matches `noise`(8)
- `SpeculativeComputation_Queer_Morphological_Systems` owned by `speculativecomputation`; also name-matches `lsystems`(8)
- `SwarmIntelligence_Particle_Swarm_Optimization` owned by `swarmintelligence`; also name-matches `particles`(8)
- `VectorForces` owned by `vectors`; also name-matches `forces`(8)
