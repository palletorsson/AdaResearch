# Project Spine & World Map Report

Date: 2026-02-07

## Sources Reviewed
- `doc/TAXONOMY.md`
- `commons/maps/curriculum_spine.json`
- `commons/maps/map_progression.json`
- `commons/maps/sequences/*.json`
- `commons/scenes/world_map/WorldMapDataProvider.gd`
- `commons/scenes/world_map/WorldMapOverview3D.gd`

## Spine Status (Definition + Data Flow)
The spine is defined in `commons/maps/curriculum_spine.json` as an 18-sequence, ordered path across QFEP phases. The world map pulls this spine data via `WorldMapDataProvider._ensure_spine_loaded()` and merges it with live progression data from `MapProgressionManager` (maps completed/unlocked).

**Spine order and phase (from curriculum_spine.json):**
-  1. `primitives` (F_order) ? Foundation - points, lines, planes, and basic vectors
-  2. `transformations` (F_order) ? Invariants - dot/cross products enable rotation
-  3. `wavefunctions` (oscillation) ? F ↔ E oscillation - sine creates curves
-  4. `forces` (oscillation) ? Newton's laws - vectors become physics
-  5. `randomness` (E_entropy) ? Disorder as creative force
-  6. `noise` (E_entropy) ? Structured randomness - Perlin, flow fields
-  7. `cellularautomata` (E_entropy) ? Simple rules → complex behavior
-  8. `fractals` (lambda_edge) ? Self-similarity, infinite detail
-  9. `lsystems` (lambda_edge) ? Generative grammars
- 10. `proceduralgeneration` (lambda_edge) ? WFC, Markov, emergence from rules
- 11. `morphogenesis` (integration) ? Turing patterns - order from chaos
- 12. `swarmintelligence` (integration) ? Collective behavior, stigmergy
- 13. `softbodies` (integration) ? Deformable matter, cloth, fluid
- 14. `machinelearning` (integration) ? Learning systems, neural networks
- 15. `foundationscrisis` (synthesis) ? Gödel, Russell - limits of formal systems
- 16. `qfeplaboratory` (synthesis) ? The complete QFEP formula embodied
- 17. `speculativecomputation` (synthesis) ? Queer futures, non-normative algorithms
- 18. `criticalalgorithms` (synthesis) ? Ethics of computation, algorithmic bias

## World Map (Back of Taxonomy) ? How It Works
- `WorldMapDataProvider.gd` is the bridge between taxonomy and progression. It loads spine/phase data from `curriculum_spine.json`, optional cross-references from `fractal_index.json`, and live completion from `MapProgressionManager`.
- Sequences and their map lists come from `MapProgressionManager`, which loads `commons/maps/map_progression.json` plus any `commons/maps/sequences/*.json` files.
- World map layout is a **metro map**: the spine is the main vertical trunk, branches fan out left/right at unlock points, and stations are sequences. The QFEP phase colors are used for line styling.
- `WorldMapOverview3D.gd` renders the 2D UI as a tablet in VR via a SubViewport and emits `sequence_selected` events.

## Spine Sequence Maps (Current Data)
Below are the map lists currently wired into the spine sequences (from `commons/maps/sequences/*.json` or `map_progression.json`).

### `primitives` (F_order)
Source: `commons\maps\sequences\primitives.json`
Maps (24):
- Point_Zero
- Point_One
- Point_Line
- Point_Lines
- Point_Line_Context
- Point_Context
- Point_Trace
- Point_Line_Grid
- Point_Triangle
- Point_Triangle_Context
- Point_Animatedcube
- Primitives_1
- Primitives_2
- Primitives_4
- Primitives_Ignorance
- Primitives_Irregular
- Primitives_Portals
- Primitives_Melencolia
- Primitives_Platonic
- Primitives_Torus
- Primitives_Godot
- Primitives_Tron_Grid_Navigation
- Primitives_Useful
- Primitives_Load

### `transformations` (F_order)
Source: `commons\maps\sequences\transformations.json`
Maps (11):
- VectorBasics
- Trans_Translate_1
- VectorAddition
- Trans_Translate_2
- VectorSubtraction
- Trans_Rotation_1
- VectorDotProduct
- Trans_Rotation_2
- VectorCrossProduct
- Trans_Scale
- VectorProjectionReflection

### `wavefunctions` (oscillation)
Source: `commons\maps\sequences\wavefunctions.json`
Maps (18):
- WaveFunctions_Intro
- WaveFunctions_Pendulum
- WaveFunctions_Sine_Space
- WaveFunctions_Unit_Circle
- WaveFunctions_3D_Wave_Propagation
- WaveFunctions_Effect_Sound
- WaveFunctions_Effect_Sound
- Wavefunctions_Bernini
- WaveFunctions_John_Cage
- WaveFunctions_AirMusic
- Wavefunctions_Cables
- Wavefunctions_ColoredLinesVRCorridor
- Wavefunctions_Colors
- Wavefunctions_Form_Slide
- WaveFunctions_Fourier_Form
- Wavefunctions_Sky_Stairs
- WaveFunctions_TrigWalkingPath
- WaveFunctions_Synthesis_Lab

### `forces` (oscillation)
Source: `commons\maps\sequences\forces.json`
Maps (14):
- VectorForces
- VectorMotion
- VectorThrowing
- VectorTorque
- Forces_Drone_Game
- Forces_Destruct
- Forces_1
- Forces_2
- Forces_3
- Forces_4
- Forces_5
- Forces_6
- Forces_7
- Forces_8

### `randomness` (E_entropy)
Source: `commons\maps\sequences\randomness.json`
Maps (23):
- Random_Definition
- Randomness_10_PRINT_Algorithm
- Random_Noise_Types
- Random_Cubes
- Random_Rotate_Random_XYZ
- Random_Walk
- Random_Gaussian
- Random_Random_Bell_Curve
- Random_Pheromone
- Random_Mushrooms
- Random_Space_Geometry
- Randomness_Examples_of_Randomness
- Random_Space
- Randomness_Digital_Materiality_Glitch
- Randomness_Distribution_Visualization
- Randomness_Random_Transformations
- Randomness_TRNG_vs_PRNG
- Random_Game
- Random_Plane
- Random_Points
- Random_Random_Over_Z
- Random_Remove
- Random_Rotate_Random_Y

### `noise` (E_entropy)
Source: `commons\maps\sequences\noise.json`
Maps (11):
- Noise_Columns
- Noise_One
- Noise_Voxel
- Noise_6_Wall
- Noise_Inside_Noise
- Noise_Volume
- Noise_Space_10
- Noise_Functions
- Noise_Perlin_Simplex
- Noise_Blue
- VectorFieldFlow

### `cellularautomata` (E_entropy)
Source: `commons\maps\sequences\cellularautomata.json`
Maps (12):
- CA_1
- CA_2
- CA_3
- CA_4
- CA_5
- CA_6
- CA_7
- CA_8
- CA_9
- CA_10
- CA_11
- CA_12

### `fractals` (lambda_edge)
Source: `commons\maps\sequences\fractals.json`
Maps (14):
- Fractals_1
- Fractals_2
- Fractals_3
- Fractals_4
- Fractals_5
- Fractals_6
- Fractals_7
- Fractals_8
- Fractals_9
- Fractals_10
- Fractals_11
- Fractals_12
- Fractals_13
- Fractals_14

### `lsystems` (lambda_edge)
Source: `commons\maps\sequences\lsystems.json`
Maps (12):
- LSystems_Hilbert3D
- LSystems_CityGenerator
- LSystems_Context_Free_Grammars_CFG
- LSystems_Different_Grammar_Types
- LSystems_Shape_Grammars
- LSystems_Stochastic_L_Systems
- LSystems_Tree_L_Systems
- LSystems_AnimatedTree
- LSystems_ContextSensitiveTree
- LSystems_Context_Free_Grammars_CFG
- LSystems_Tree_L_Systems
- LSystems_ForestCompetition

### `proceduralgeneration` (lambda_edge)
Source: `commons\maps\sequences\proceduralgeneration.json`
Maps (18):
- ProceduralGeneration_Two
- ProceduralGeneration_Three
- ProceduralGeneration_Four
- ProceduralGeneration_Five
- ProceduralGeneration_Seven
- ProceduralGeneration_Eight
- ProceduralGeneration_Ten
- ProceduralGeneration_Eleven
- ProceduralGeneration_17
- ProceduralGeneration_21
- ProceduralGeneration_BranchingGrowthAlgorithm
- ProceduralGeneration_CaveRandomWalk
- ProceduralGeneration_CubeMound
- ProceduralGeneration_Dome
- ProceduralGeneration_Genetic_Algorithms
- ProceduralGeneration_Genetic_Programming
- ProceduralGeneration_Maze
- ProceduralGeneration_Space_Colonization_Algorithms

### `morphogenesis` (integration)
Source: `commons\maps\sequences\morphogenesis.json`
Maps (2):
- ProceduralGeneration_Reaction_Diffusion_Systems
- Topology_Entropy_Morphogenesis

### `swarmintelligence` (integration)
Source: `commons\maps\sequences\swarmintelligence.json`
Maps (7):
- SwarmIntelligence_PhysarumColony
- SwarmIntelligence_FlowFeilds
- SwarmIntelligence_Boids_Algorithm
- SwarmIntelligence_Agent_Based_Modeling_ABM
- SwarmIntelligence_Ant_Colony_Optimization
- SwarmIntelligence_Particle_Swarm_Optimization
- SwarmIntelligence_Swarm_Intelligence_Algorithms

### `softbodies` (integration)
Source: `commons\maps\sequences\softbodies.json`
Maps (8):
- SoftBodies_Carusell
- SoftBodies_Obsticals
- SoftBodies_Obsticals_Part2
- SoftBodies_Obsticals_Part3
- SoftBodies_Cloth_Physics
- SoftBodies_Soft_Body_Deformation
- SoftBodies_Playground_of_Joy
- SoftBodies_Affect_Theory_Visualization

### `machinelearning` (integration)
Source: `commons\maps\sequences\machinelearning.json`
Maps (18):
- MachineLearning_Evolving_Creatures
- MachineLearning_Evolving_Flowers
- MachineLearning_Random_Walker_Machine
- MachineLearning_Neural_Networks
- MachineLearning_Convolutional_Neural_Networks_CNNs
- MachineLearning_Recurrent_Neural_Networks_RNNs
- MachineLearning_LSTMs
- MachineLearning_Transformers
- MachineLearning_Generative_Adversarial_Networks_GANs
- MachineLearning_Variational_Autoencoders_VAEs
- MachineLearning_Clustering_Algorithms
- MachineLearning_Dimensionality_Reduction
- MachineLearning_Transfer_Learning
- MachineLearning_Fine_tuning
- MachineLearning_Explainable_AI_XAI
- MachineLearning_Recommendation_Systems
- MachineLearning_Classification_Algorithms
- MachineLearning_Attention_Mechanisms

### `foundationscrisis` (synthesis)
Source: `commons\maps\sequences\foundationscrisis.json`
Maps (8):
- Euclid_Parallel
- NonEuclidean_Spaces
- Russell_Paradox
- Godel_Incompleteness
- Escher_Impossible
- Brouwer_Intuitionism
- Florensky_Paraconsistent
- Crisis_Synthesis

### `qfeplaboratory` (synthesis)
Source: `commons\maps\sequences\qfeplaboratory.json`
Maps (8):
- QFEP_Introduction
- QFEP_F_Term
- QFEP_E_Term
- QFEP_Lambda_Spectrum
- QFEP_Phi_Term
- QFEP_Edge_Of_Chaos
- QFEP_Sandbox
- QFEP_Synthesis

### `speculativecomputation` (synthesis)
Source: `commons\maps\sequences\speculativecomputation.json`
Maps (5):
- SpeculativeComputation_Evolutionary_Algorithms
- SpeculativeComputation_Queer_Cyborg_Subjectivity
- SpeculativeComputation_Queer_Morphological_Systems
- SpeculativeComputation_Ontological_Uncertainty
- SpeculativeComputation_Rhizome_Network

### `criticalalgorithms` (synthesis)
Source: `commons\maps\sequences\criticalalgorithms.json`
Maps (6):
- CriticalAlgorithms_Algorithmic_Misframing
- CriticalAlgorithms_Societal_Impact
- CriticalAlgorithms_Ethics_in_AI
- CriticalAlgorithms_Algorithmic_Bias_Visualization
- CriticalAlgorithms_Surveillance_Systems
- CriticalAlgorithms_Attention_Economy

## Gaps / Cleanup Opportunities
- `commons/maps/sequences/wavefunctions.json` is **not valid JSON** (trailing commas + duplicate entry). `WorldMapDataProvider` uses `MapProgressionManager` which relies on JSON parse; this file will fail strict JSON parsing. Fixing this will stabilize the world map feed.
- Duplicate map names detected in spine sequences:
  - `wavefunctions`: `WaveFunctions_Effect_Sound` appears twice.
  - `lsystems`: `LSystems_Context_Free_Grammars_CFG` and `LSystems_Tree_L_Systems` appear twice.
- Naming drift: taxonomy mentions `transformation` (singular) while spine uses `transformations` (plural) and both `transformation.json` and `transformations.json` exist. Consider converging to one canonical sequence id.
- Progress state (completed/unlocked) is user-save dependent (`user://map_progress.json`) so the world map?s visible stations depend on runtime save data, not static files.

## Summary
The spine is defined and wired: `curriculum_spine.json` provides the ordered QFEP path, and the world map consumes it through `WorldMapDataProvider`. The back-of-taxonomy map lists live in `commons/maps/sequences/*.json` (with a fallback from `map_progression.json`). The main improvement needed now is JSON hygiene for `wavefunctions.json` and de-duplication of maps in `wavefunctions` and `lsystems`, plus deciding on one canonical id for the transformations sequence.
