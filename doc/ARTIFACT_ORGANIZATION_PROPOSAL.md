# Artifact Organization Proposal

## Current State
- **691 artifacts** in flat `grid_artifacts.json`
- No hierarchy, hard to discover
- Mixes primitives, algorithms, tools, and content

## Proposed Hierarchy

Organize by **pedagogical layer** matching the curriculum:

```
artifacts/
├── 01_primitives/         # Building blocks (Euclid → Hilbert)
│   ├── points/            # point, static_point, grab_sphere_point, vectorpoint, draw_dot
│   ├── lines/             # line, cross_lines, parallel_lines, grid_lines, grab_line
│   ├── triangles/         # triangle, pythagorean_triangle, righttriangle
│   ├── polygons/          # quad, plane, hexagon
│   ├── solids/            # cube, sphere, cylinder, prism, torus, capsule
│   ├── platonic/          # tetrahedron, octahedron, dodecahedron, icosahedron
│   └── combines/          # combine_primitives, combine_torus, etc.
│
├── 02_vectors/            # Motion and direction
│   ├── basics/            # VectorBasics, VectorAddition, VectorSubtraction
│   ├── operations/        # VectorDotProduct, VectorCrossProduct, VectorProjection
│   ├── applications/      # VectorForces, VectorMotion, VectorTorque
│   └── fields/            # VectorFieldFlow, vector_field
│
├── 03_transformations/    # Euclid → Klein
│   ├── translation/       # sliding_door, elevator_platform, translation_demo
│   ├── rotation/          # rotating_cube, spin, rotation_oscillation_cube
│   ├── scale/             # scale_me, scalable_wood_cube
│   └── combined/          # geometric_transformations, transformation_cube
│
├── 04_forces/             # Newton → Friston
│   ├── gravity/           # bouncing_ball, falling_cube, gravity_gun
│   ├── attraction/        # single_attractor, multiple_attractors, n_body
│   ├── springs/           # spring_mass_system, spring_network, pendulum
│   └── fields/            # force_fields, magnetic_simulation
│
├── 05_wavefunctions/      # Fourier → QFEP
│   ├── oscillation/       # OscillatingWave, coupled_oscillator_lattice
│   ├── harmonics/         # SphericalHarmonics, HarmonicBuilder, fourier_transform
│   ├── waves/             # wave_propagation_3d, standing_waves, wave_interference
│   ├── synthesis/         # additive_synthesis, fm_synthesis, granular_synthesis
│   └── lissajous/         # lissajous_curves, Lissajous3D
│
├── 06_randomness/         # Turing → Entropy
│   ├── distributions/     # randompoints_gaussian, randompoints_uniform, probability_sphere
│   ├── noise/             # perlin_noise, simplex_noise, value_noise, blue_noise
│   ├── walks/             # random_walk_128, walk_random, crystal_random_walk
│   ├── generators/        # random_object_spawner, random_transformations
│   └── visualization/     # entropy_visualization, distribution_visualization
│
├── 07_cellular_automata/  # Wolfram → Langton
│   ├── elementary/        # rule_30_110, elementary_ca_vr, cellular_automata_1d
│   ├── 2d/                # game_of_life, hexagon_ca, cellular_automata_2d
│   ├── 3d/                # cellular_automata_3d, CA_sphere, ca_columns
│   ├── continuous/        # reaction_diffusion, slime_mold
│   └── special/           # crack_propagation, dendrite_growth, disease_spread
│
├── 08_fractals/           # Mandelbrot → Self-similarity
│   ├── classic/           # mandelbrot_set, julia_set, koch_curve
│   ├── 3d/                # sierpinski_pyramid, menger_sponge, koch_curve_3d
│   ├── trees/             # recursive_tree, lsystem_tree, stochastic_tree
│   └── space_filling/     # Hilbert3D, cantor_set
│
├── 09_procedural/         # Algorithms → Emergence
│   ├── grammars/          # context_free_grammars, markov_chains
│   ├── lsystems/          # lsystem_dungeon, tree_generation
│   ├── wfc/               # wave_function_collapse, WFC3DGenerator
│   ├── voronoi/           # voronoi_diagrams, voronoi_space, delaunay
│   ├── isosurfaces/       # marching_cubes, metaballs, gyroid
│   └── mazes/             # maze_generation, maze_generator
│
├── 10_physics/            # Newton → Soft bodies
│   ├── rigid_body/        # rigid_body, falling_boxes, collision_detection
│   ├── soft_body/         # cloth_simulation, soft_bodies, softbody_gallery
│   ├── particles/         # particle_systems, boid_flocking, ant_colony
│   ├── fluids/            # fluid_simulation, liquid_simulation
│   └── constraints/       # pendulum, chain, bridge, hinges
│
├── 11_graphs/             # Euler → Networks
│   ├── basics/            # graphspace, KonigsbergBridge
│   ├── algorithms/        # pathfinding, mst_visualization, force_directed
│   ├── 3d/                # graphspace3d, network_analysis
│   └── flow/              # networkflow3d, push_relabel
│
├── 12_ml/                 # Turing → Learning
│   ├── neural_networks/   # neural_networks_vr, convolutional_neural_networks
│   ├── generative/        # gans_vr, variational_autoencoders
│   ├── evolution/         # evolutionary_algorithms, GeneticProgramming
│   └── visualization/     # gradient_descent, explainable_ai
│
├── 13_qfep/               # QFEP Framework artifacts
│   ├── parameters/        # lambda_slider, phi_slider
│   ├── visualizers/       # qfep_formula_3d, qfep_oscilloscope, entropy_meter
│   ├── reactors/          # qfep_reactor, edge_detector, phase_cube
│   ├── patterns/          # turing_pattern, edge_core, chaos_particles
│   └── states/            # ordered_grid, dissolving_form, complexity_pattern
│
├── 14_foundations/        # Gamwell → Philosophy of Math
│   ├── paradoxes/         # godel_statement_plaque, russell_set_box
│   ├── representation/    # magritte_pipe
│   ├── impossible/        # escher_staircase
│   ├── paraconsistent/    # florensky_sphere
│   └── chaos/             # bifurcation_diagram
│
├── 15_tools/              # Interactive tools
│   ├── drawing/           # SDFDrawTool, VRBrush, drawing_paper, drawing_pen
│   ├── measurement/       # laser_measure, magnifying_glass, grab_stick_scanner
│   ├── building/          # blockbuilderentity, line_builder_3d, cable_builder
│   ├── display/           # clipboard, code_display, info_display, text_display
│   └── audio/             # step_sequencer, SoundBoxes, spectral_analyzer
│
├── 16_puzzles/            # Educational puzzles
│   ├── assembly/          # chair_assembly_puzzle, lab_assembly_puzzle
│   ├── pattern/           # pattern_tile_puzzle, rotation_match_puzzle
│   ├── snap/              # snap_tetrahedron_puzzle, snap_octahedron_puzzle
│   └── balance/           # balance_puzzle
│
├── 17_environments/       # Spaces and worlds
│   ├── caves/             # rhizome_cave_system, marching_cubes_cave_gallery
│   ├── galleries/         # softbody_gallery, modernistchairgallery, Shader_Gallery
│   ├── organic/           # organic_space, AnickaYiLab, mushrooms
│   └── abstract/          # noise_space, fractal_space, tesseract_net_space
│
└── 18_system/             # Infrastructure
    ├── player/            # player_presence_indicator, player_trace, player_position
    ├── navigation/        # portal, menu, level_entrance
    ├── display/           # cctv, monitors, score_display
    └── debug/             # frame_counter, memory_display, draw_calls_display
```

## QFEP Mapping

| Layer | QFEP Component | Gamwell Chapter |
|-------|----------------|-----------------|
| primitives | F (axioms) | Ch 1-2: Euclid |
| transformations | F (invariants) | Ch 7: Symmetry |
| wavefunctions | F ↔ E oscillation | Ch 8: Bauhaus |
| randomness | E(S) (entropy) | Ch 10: Turing |
| cellular_automata | λ parameter | Ch 12: Complexity |
| qfep | Full framework | All |
| foundations | Edges & paradoxes | Ch 3-6, 9, 13 |

## Implementation Options

### Option 1: Folder-based (Physical)
Actually move scene files into categorized folders.
- **Pro**: Clear organization
- **Con**: Massive refactor, breaks existing references

### Option 2: Registry-based (Virtual)
Keep files where they are, add category metadata to `grid_artifacts.json`.
```json
{
  "point": {
    "name": "Point",
    "category": "primitives/points",
    "tags": ["primitive", "0d", "foundation"],
    "scene": "res://commons/primitives/point/point.tscn"
  }
}
```
- **Pro**: No file moves, backwards compatible
- **Con**: Metadata maintenance

### Option 3: Category Registry (Recommended)
Create `category_registry.json` that maps categories to artifact lists:
```json
{
  "primitives": {
    "points": ["point", "static_point", "grab_sphere_point", ...],
    "lines": ["line", "cross_lines", "parallel_lines", ...]
  },
  "qfep": {
    "parameters": ["lambda_slider", "phi_slider"],
    "visualizers": ["qfep_formula_3d", "entropy_meter", ...]
  }
}
```
- **Pro**: Single source of truth for categories, easy to update
- **Con**: Two files to maintain

## Immediate Actions

1. **Create `category_registry.json`** with top-level categories
2. **Tag existing artifacts** by adding `category` and `tags` fields
3. **Build category browser** in game to discover artifacts by type
4. **Document each category** with what it teaches and where it fits in curriculum

## Priority Categories to Define

1. **primitives/** — Foundation for everything
2. **qfep/** — The unifying framework  
3. **foundations/** — Philosophy of math (Gamwell)
4. **randomness/** — Entropy and emergence
5. **wavefunctions/** — Oscillation and sound

These five cover the core pedagogical arc.
