# Artifact: Dark Sphere

> A simple dark sphere used as an atmospheric and geometric reference. Its silhouette, rotation, and low-emission surface make nearby shifts in scale, position, and lighting easier to perceive. Because it changes very little itself, it stabilizes the viewer's sense of what other transformed objects are doing. It functions as a neutral anchor.

## Context

**Category:** procedural | **Complexity:** intermediate
**Tags:** reference, atmosphere, sphere, scale_marker, lighting, geometry, procedural | **Themes:** grammar, l_systems, procedural

A simple dark sphere used as an atmospheric and geometric reference. Its silhouette, rotation, and low-emission surface make nearby shifts in scale, position, and lighting easier to perceive. Because it changes very little itself, it stabilizes the viewer's sense of what other transformed objects are doing. It functions as a neutral anchor.

## Design

- **Visual:** material: unlit, animation: transform
- **Scale:** [1.0, 1.0, 1.0] (compact)

## Architecture

| | |
|---|---|
| **File** | `commons/artifacts/dark_sphere/dark_sphere.gd` (145 lines) |
| **Scene** | `res://commons/artifacts/dark_sphere/dark_sphere.tscn` |
| **Registry** | `lsystems.json` |
| **Class** | `DarkSphere` extends `Node3D` |
| **Pattern** | procedural |

### Exports

| Name | Type | Default |
|------|------|---------|
| `display_size` | float | 0.5 |
| `sphere_radius` | float | 0.35 |
| `float_height` | float | 0.25 |
| `rotation_speed` | float | 0.15 |
| `pulse_speed` | float | 1.2 |
| `pulse_min` | float | 0.05 |
| `pulse_max` | float | 0.35 |
| `albedo_color` | Color | Color(0.08, 0.04, 0.12) |
| `emission_color` | Color | Color(0.18, 0.08, 0.28) |

### Key Methods

- `_ready()`
- `_process(delta: float)`
- `_create_sphere()`
- `_create_halo_ring()`
- `apply_grid_config(config_data: Dictionary)`

### Grid Config

Accepts: `albedo_color`, `display_size`, `emission_color`, `float_height`, `pulse_speed`, `rotation_speed`, `sphere_radius`

## Curriculum Position

### Sequences

- **Array Tutorial Sequence** (array_tutorial) -- map: Array_Patterns
- **Array Tutorial Sequence** (array_tutorial) -- map: Tutorial_Single
- **Array Tutorial Sequence** (array_tutorial) -- map: Tutorial_Row
- **Array Tutorial Sequence** (array_tutorial) -- map: Tutorial_2D_Build
- **Array Tutorial Sequence** (array_tutorial) -- map: Tutorial_3D
- **Array Tutorial Sequence** (array_tutorial) -- map: Tutorial_Pattern
- **Array Tutorial Sequence** (array_tutorial) -- map: Tutorial_Disco
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Inventory
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Affordances
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Arrays_as_Probes
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Constraints
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Chair
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Sculpture
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Dome
- **Cellular Automata: Local Rules, Global Patterns** (cellularautomata) -- map: CA_Introduction
- **Cellular Automata: Local Rules, Global Patterns** (cellularautomata) -- map: CA_ElementaryRules
- **Cellular Automata: Local Rules, Global Patterns** (cellularautomata) -- map: CA_GameOfLife
- **Cellular Automata: Local Rules, Global Patterns** (cellularautomata) -- map: CA_BeyondBinary
- **Cellular Automata: Local Rules, Global Patterns** (cellularautomata) -- map: CA_ExpandingSpace
- **Color: Perception, Not Physics** (color) -- map: Color_Nails
- **Color: Perception, Not Physics** (color) -- map: Color_Grid_Pallet
- **Color: Perception, Not Physics** (color) -- map: Color_Rainbow
- **Color: Perception, Not Physics** (color) -- map: Color_Pillar
- **Color: Perception, Not Physics** (color) -- map: Color_Paint
- **Color: Perception, Not Physics** (color) -- map: Color_Walls
- **Color: Perception, Not Physics** (color) -- map: Color_Flashlight
- **Constraint Solvers: Rules Become Worlds** (constraint_solvers) -- map: ProceduralGenerationWfcDungeonGenerator
- **Vectors & Forces: From Direction to Dynamics** (forces) -- map: VectorFoundations
- **Vectors & Forces: From Direction to Dynamics** (forces) -- map: VectorOperations
- **Vectors & Forces: From Direction to Dynamics** (forces) -- map: VectorApplied
- **Vectors & Forces: From Direction to Dynamics** (forces) -- map: VectorAdvanced
- **Vectors & Forces: From Direction to Dynamics** (forces) -- map: ForcesComposition
- **Vectors & Forces: From Direction to Dynamics** (forces) -- map: ForcesFoundations
- **Vectors & Forces: From Direction to Dynamics** (forces) -- map: ForcesSystems
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_Recursion
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_RecursiveTrees
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_CantorSet
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_KochSierpinski
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_MengerSponge
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_GoldenSpiral
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_JuliaSet
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_MandelbrotSet
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_Synthesis
- **Fractals: Infinite Within Finite** (fractals) -- map: Fractal_CrossSequence
- **L-Systems: Rules Grow Structure** (lsystems) -- map: LSystems_Grammar_Lab
- **L-Systems: Rules Grow Structure** (lsystems) -- map: LSystems_Architecture
- **L-Systems: Rules Grow Structure** (lsystems) -- map: LSystems_Competition
- **Noise: Entropy with Memory** (noise) -- map: Random_Noise_Types
- **Noise: Entropy with Memory** (noise) -- map: Noise_Columns
- **Noise: Entropy with Memory** (noise) -- map: Noise_One
- **Noise: Entropy with Memory** (noise) -- map: Noise_Voxel
- **Noise: Entropy with Memory** (noise) -- map: Noise_6_Wall
- **Noise: Entropy with Memory** (noise) -- map: Noise_Inside_Noise
- **Noise: Entropy with Memory** (noise) -- map: Noise_Space_10
- **Noise: Entropy with Memory** (noise) -- map: Noise_Perlin_Simplex
- **Noise: Entropy with Memory** (noise) -- map: Lab_Path
- **Particle Systems** (particles) -- map: Particles_SingleAndArrays
- **Particle Systems** (particles) -- map: Particles_Emitters
- **Particle Systems** (particles) -- map: Particles_Forces
- **Particle Systems** (particles) -- map: Particles_LifetimeAndTypes
- **Particle Systems** (particles) -- map: Particles_Collision
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_01_Shaping
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_02_Colors
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_03_Shapes
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_04_Matrices
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_05_Patterns
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_06_Random
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_07_Noise
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_08_CellularNoise
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_09_FBM
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_10_ReactionDiffusion
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_11_QueerRubber
- **Shaders & Patterns: The Book of Shaders** (patterngeneration) -- map: Shader_12_PinkExtravaganza
- **Physics Simulation: The Engine Behind Reality** (physicssimulation) -- map: PhysicsSimulation_Vector_Fields
- **Primitives: Points Build Worlds** (primitives) -- map: Point_One
- **Primitives: Points Build Worlds** (primitives) -- map: Point_Lines
- **Primitives: Points Build Worlds** (primitives) -- map: Point_Trace
- **Primitives: Points Build Worlds** (primitives) -- map: Point_Line_Grid
- **Primitives: Points Build Worlds** (primitives) -- map: Point_Triangle
- **Primitives: Points Build Worlds** (primitives) -- map: Point_Triangle_Context
- **Primitives: Points Build Worlds** (primitives) -- map: Primitives_Polythedra
- **Primitives: Points Build Worlds** (primitives) -- map: Point_Animatedcube
- **Primitives: Points Build Worlds** (primitives) -- map: Primitives_Ignorance
- **Primitives: Points Build Worlds** (primitives) -- map: Primitives_Portals
- **Primitives: Points Build Worlds** (primitives) -- map: Primitives_Melencolia
- **Procedural Generation: Rules Build Worlds** (proceduralgeneration) -- map: PG_Percolation_Network
- **Procedural Generation (All Maps)** (proceduralgeneration_all) -- map: ProceduralGenerationMarchingCubesInsideCave
- **Procedural Generation (All Maps)** (proceduralgeneration_all) -- map: ProceduralGenerationMarchingCubesVovelNoise
- **Procedural Generation (All Maps)** (proceduralgeneration_all) -- map: ProceduralGenerationWfcDungeonGenerator
- **QFEP Laboratory: The Formula Made Interactive** (qfeplaboratory) -- map: QFEP_F_Term
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Definition
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Remove
- **Randomness: Freedom from Pattern** (randomness) -- map: Randomness_10_PRINT_Algorithm
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Cubes
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Rotate_Random_XYZ
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Walk
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Gaussian
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Mushrooms
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Space_Geometry
- **Randomness: Freedom from Pattern** (randomness) -- map: Randomness_Examples_of_Randomness
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Pheromone
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Space
- **Unused Artifacts Test** (testmaps) -- map: Point_Zero
- **Transformation: What Stays the Same When Everything Changes** (transformation) -- map: Trans_Introduction
- **Transformation: What Stays the Same When Everything Changes** (transformation) -- map: Trans_Translation
- **Transformation: What Stays the Same When Everything Changes** (transformation) -- map: Trans_AxisDecomposition
- **Transformation: What Stays the Same When Everything Changes** (transformation) -- map: Trans_Rotation
- **Transformation: What Stays the Same When Everything Changes** (transformation) -- map: Trans_RotationSpectacle
- **Transformation: What Stays the Same When Everything Changes** (transformation) -- map: Trans_Scale
- **Unused** (unused) -- map: Dialectic_Automation
- **Unused** (unused) -- map: Directionality_Examples
- **Unused** (unused) -- map: oscillation_1
- **Unused** (unused) -- map: oscillation_2
- **Unused** (unused) -- map: oscillation_3
- **Unused** (unused) -- map: oscillation_4
- **Unused** (unused) -- map: oscillation_5
- **Unused** (unused) -- map: oscillation_6
- **Unused** (unused) -- map: oscillation_7
- **Unused** (unused) -- map: Pattern_Generation_One
- **Unused** (unused) -- map: Pattern_Generation_Two
- **Unused** (unused) -- map: Pattern_Generation_Three
- **Unused** (unused) -- map: Pattern_Generation_Six
- **Unused** (unused) -- map: Pattern_Generation_Seven
- **Unused** (unused) -- map: Primitives_2
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_Intro
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_Pendulum
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_Sine_Space
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_Unit_Circle
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_3D_Wave_Propagation
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_Effect_Sound
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: Wavefunctions_Bernini
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_John_Cage
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_AirMusic
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: Wavefunctions_Sky_Stairs
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_TrigWalkingPath
- **Wavefunctions: Everything Oscillates** (wavefunctions) -- map: WaveFunctions_Synthesis_Lab

### Map Placements

| Map | Cell | Config |
|-----|------|--------|
| _Example_Branch | [6,2] | `-` |
| _Example_Island | [5,2] | `-` |
| _Example_Linear | [6,2] | `-` |
| Array_Patterns | [4,5] | `-` |
| AutoGenTest | [3,3] | `-` |
| Bricolage_Affordances | [5,6] | `-` |
| Bricolage_Arrays_as_Probes | [5,7] | `-` |
| Bricolage_Chair | [5,5] | `-` |
| Bricolage_Constraints | [5,6] | `-` |
| Bricolage_Dome | [9,7] | `-` |
| Bricolage_Inventory | [6,5] | `-` |
| Bricolage_Sculpture | [5,6] | `-` |
| CA_BeyondBinary | [2,3] | `-` |
| CA_ElementaryRules | [4,2] | `-` |
| CA_ExpandingSpace | [2,2] | `-` |
| CA_GameOfLife | [5,4] | `-` |
| CA_Introduction | [2,3] | `-` |
| Color_Context | [3,7] | `-` |
| Color_Flashlight | [5,4] | `-` |
| Color_Grabbable | [3,3] | `-` |
| ... | ... | +187 more |

## Verification

- [ ] Run scene directly
- [ ] Place in map, check interaction
- [ ] Capture screenshot

---
*Generated by generate_artifact_plans.py on 2026-04-15*
