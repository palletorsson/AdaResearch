# Map Rules Report

**50 sequences, 478 maps: 246 OK, 194 fail, 38 missing**

| Sequence | OK | Fail | Missing | Total |
|----------|----|------|---------|-------|
| OK advancedlaboratory | 0 | 0 | 0 | 0 |
| FAIL array_tutorial | 4 | 3 | 0 | 7 |
| FAIL artmathematics | 8 | 1 | 0 | 9 |
| FAIL biological_growth | 0 | 4 | 0 | 4 |
| OK bricolage | 7 | 0 | 0 | 7 |
| FAIL cellularautomata | 10 | 2 | 0 | 12 |
| OK color | 7 | 0 | 0 | 7 |
| OK computationalgeometry | 11 | 0 | 0 | 11 |
| FAIL constraint_solvers | 0 | 3 | 0 | 3 |
| OK criticalalgorithms | 0 | 0 | 0 | 0 |
| OK datastructures | 12 | 0 | 0 | 12 |
| FAIL devexamples | 0 | 6 | 0 | 6 |
| FAIL forces | 22 | 2 | 0 | 24 |
| FAIL foundationscrisis | 6 | 1 | 0 | 7 |
| FAIL fractals | 11 | 3 | 0 | 14 |
| FAIL grammar_systems | 0 | 3 | 0 | 3 |
| OK graphtheory | 8 | 0 | 0 | 8 |
| FAIL higher_dimensions | 0 | 4 | 0 | 4 |
| FAIL isosurfaces | 9 | 7 | 0 | 16 |
| OK joints | 7 | 0 | 0 | 7 |
| FAIL lab | 0 | 1 | 38 | 39 |
| FAIL lsystems | 0 | 7 | 0 | 7 |
| FAIL machinelearning | 3 | 5 | 0 | 8 |
| FAIL meshes | 0 | 4 | 0 | 4 |
| OK morphogenesis | 0 | 0 | 0 | 0 |
| FAIL noise | 4 | 5 | 0 | 9 |
| OK particles | 5 | 0 | 0 | 5 |
| FAIL patterngeneration | 17 | 1 | 0 | 18 |
| FAIL physicssimulation | 16 | 5 | 0 | 21 |
| OK postfoundationscrisis | 3 | 0 | 0 | 3 |
| FAIL primitives | 6 | 5 | 0 | 11 |
| FAIL proceduralaudio | 0 | 8 | 0 | 8 |
| FAIL proceduralgeneration | 6 | 1 | 0 | 7 |
| FAIL proceduralgeneration_all | 0 | 42 | 0 | 42 |
| FAIL qfeplaboratory | 0 | 8 | 0 | 8 |
| FAIL randomness | 8 | 5 | 0 | 13 |
| OK recursiveemergence | 11 | 0 | 0 | 11 |
| OK resourcemanagement | 0 | 0 | 0 | 0 |
| OK searchpathfinding | 0 | 0 | 0 | 0 |
| FAIL softbodies | 7 | 2 | 0 | 9 |
| FAIL spatial_partitioning | 0 | 4 | 0 | 4 |
| OK speculativecomputation | 0 | 0 | 0 | 0 |
| FAIL structure | 14 | 2 | 0 | 16 |
| FAIL swarmintelligence | 0 | 7 | 0 | 7 |
| OK templats | 4 | 0 | 0 | 4 |
| FAIL testmaps | 0 | 22 | 0 | 22 |
| FAIL transformation | 2 | 4 | 0 | 6 |
| FAIL unused | 14 | 9 | 0 | 23 |
| OK vectors | 0 | 0 | 0 | 0 |
| FAIL wavefunctions | 4 | 8 | 0 | 12 |

---

## advancedlaboratory — "Advanced Laboratory" (0 maps: 0 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|

## array_tutorial — "Array Tutorial Sequence" (7 maps: 4 OK, 3 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Array_Patterns | FAIL | R4: Artifact 'dark_sphere' at (5,4) h=1 unreachable; R5: Teleport at (8,9) has height 1, must be 0 (void) |
| Tutorial_Single | OK |  |
| Tutorial_Row | OK |  |
| Tutorial_2D_Build | FAIL | R4: Artifact 'dark_sphere' at (3,7) h=4 unreachable; R4: Artifact 'gridagent' at (1,21) h=0 unreachable [on; R4: Artifact 'xyz_coordinates' at (7,22) h=0 unreachab |
| Tutorial_3D | OK |  |
| Tutorial_Pattern | OK |  |
| Tutorial_Disco | FAIL | R4: Artifact 'standalone_disco' at (8,7) h=0 unreachab; R4: Artifact 'dark_sphere' at (4,8) h=0 unreachable [o |

### Fix Instructions

**Array_Patterns**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Array_Patterns`
  Manual: Artifact 'dark_sphere' at (5,4) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**Tutorial_2D_Build**
  Manual: Artifact 'dark_sphere' at (3,7) h=4 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'gridagent' at (1,21) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'xyz_coordinates' at (7,22) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Tutorial_Disco**
  Manual: Artifact 'standalone_disco' at (8,7) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (4,8) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

## artmathematics — "Art & Mathematics: Visual Philosophy" (9 maps: 8 OK, 1 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Escher_Impossible | FAIL | R3: Teleport at (6,10) is NOT reachable from spawn; R4: Artifact 'escher_staircase' at (0,4) h=4 unreachab; R4: Artifact 'penrose_triangle' at (10,7) h=3 unreacha; R4: Artifact 'magritte_pipe' at (5,10) h=3 unreachable |
| Escher_Tessellation | OK |  |
| Magritte_Pipe | OK |  |
| Magritte_Windows | OK |  |
| Rodchenko_Monochrome | OK |  |
| Judd_Minimalism | OK |  |
| Dark_Room_Paradox | OK |  |
| Art_Synthesis | OK |  |
| MathArt_Cultural_History | OK |  |

### Fix Instructions

**Escher_Impossible**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'escher_staircase' at (0,4) h=4 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'penrose_triangle' at (10,7) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'magritte_pipe' at (5,10) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

## biological_growth — "Biological Growth: Life Finds a Way" (4 maps: 0 OK, 4 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| BG_Slime_Mold | FAIL | R4: Artifact 'slimemold' at (4,4) h=0 unreachable [on ; R5: Teleport at (9,9) has height 1, must be 0 (void) |
| BG_Mushroom_Growth | FAIL | R5: Teleport at (9,9) has height 1, must be 0 (void) |
| BG_Crack_Propagation | FAIL | R5: Teleport at (8,8) has height 1, must be 0 (void) |
| BG_Tree_Forms | FAIL | R4: Artifact 'tree_gen' at (4,4) h=0 unreachable [on V; R5: Teleport at (9,9) has height 1, must be 0 (void) |

### Fix Instructions

**BG_Slime_Mold**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix BG_Slime_Mold`
  Manual: Artifact 'slimemold' at (4,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (9,9) — no structure row at z=10 to catch player

**BG_Mushroom_Growth**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix BG_Mushroom_Growth`
  Note: Teleport at (9,9) — no structure row at z=10 to catch player

**BG_Crack_Propagation**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix BG_Crack_Propagation`
  Note: Teleport at (8,8) — no structure row at z=9 to catch player

**BG_Tree_Forms**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix BG_Tree_Forms`
  Manual: Artifact 'tree_gen' at (4,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (9,9) — no structure row at z=10 to catch player

## bricolage — "Bricolage: From Parts to Structures" (7 maps: 7 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Bricolage_Inventory | OK |  |
| Bricolage_Affordances | OK |  |
| Bricolage_Arrays_as_Probes | OK |  |
| Bricolage_Constraints | OK |  |
| Bricolage_Chair | OK |  |
| Bricolage_Sculpture | OK |  |
| Bricolage_Dome | OK |  |

## cellularautomata — "Cellular Automata: Local Rules, Global Patterns" (12 maps: 10 OK, 2 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| CA_1 | OK |  |
| CA_2 | OK |  |
| CA_3 | OK |  |
| CA_4 | FAIL | R3: Teleport at (6,0) is NOT reachable from spawn; R4: Artifact 'dark_sphere' at (3,2) h=0 unreachable [o; R4: Artifact 'hexagon_ca_vr' at (3,3) h=0 unreachable ; R4: Artifact 'ca_growth_network' at (2,4) h=0 unreacha; R5: Teleport at (6,0) has height 3, must be 0 (void) |
| CA_5 | OK |  |
| CA_6 | OK |  |
| CA_7 | OK |  |
| CA_8 | OK |  |
| CA_9 | OK |  |
| CA_10 | OK |  |
| CA_12 | FAIL | R3: Teleport at (5,6) is NOT reachable from spawn; R4: Artifact 'ca_screen' at (2,2) h=0 unreachable [on ; R4: Artifact 'self_organization_ca' at (4,2) h=0 unrea; R4: Artifact 'disease_spread_ca' at (6,2) h=0 unreacha; R4: Artifact 'volumetric_fog_ca' at (3,3) h=0 unreacha |
| CA_11 | OK |  |

### Fix Instructions

**CA_4**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix CA_4`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'dark_sphere' at (3,2) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'hexagon_ca_vr' at (3,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'ca_growth_network' at (2,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**CA_12**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'ca_screen' at (2,2) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'self_organization_ca' at (4,2) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'disease_spread_ca' at (6,2) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'volumetric_fog_ca' at (3,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

## color — "Color: Perception, Not Physics" (7 maps: 7 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Color_Nails | OK |  |
| Color_Grid_Pallet | OK |  |
| Color_Rainbow | OK |  |
| Color_Pillar | OK |  |
| Color_Paint | OK |  |
| Color_Walls | OK |  |
| Color_Flashlight | OK |  |

## computationalgeometry — "Computational Geometry" (11 maps: 11 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Geometric_1 | OK |  |
| Geometric_2 | OK |  |
| Geometric_3 | OK |  |
| ComputationalGeometry_Medial_Axis_Transform | OK |  |
| ComputationalGeometry_Distance_Fields_SDF | OK |  |
| ComputationalGeometry_Morphological_Operations | OK |  |
| ComputationalGeometry_Closest_Pair_Problem | OK |  |
| ComputationalGeometry_Line_Intersection | OK |  |
| ComputationalGeometry_Point_in_Polygon | OK |  |
| ComputationalGeometry_Convex_Hull_Algorithms | OK |  |
| ComputationalGeometry_Euclidean_Distance_Transform | OK |  |

## constraint_solvers — "Constraint Solvers: Rules Become Worlds" (3 maps: 0 OK, 3 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| ProceduralGeneration_Wave_Function_Collapse | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationWfcDungeonGenerator | FAIL | R5: Teleport at (2,1) has height 1, must be 0 (void) |
| ProceduralGenerationBooleanPatterns | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |

### Fix Instructions

**ProceduralGeneration_Wave_Function_Collapse**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Wave_Function_Collapse`

**ProceduralGenerationWfcDungeonGenerator**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationWfcDungeonGenerator`

**ProceduralGenerationBooleanPatterns**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationBooleanPatterns`

## criticalalgorithms — "Critical Algorithms" (0 maps: 0 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|

## datastructures — "Data Structures" (12 maps: 12 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| DataStructures_Linked_Lists | OK |  |
| DataStructures_Trees | OK |  |
| DataStructures_Hash_Maps | OK |  |
| DataStructures_Heap_Operations | OK |  |
| DataStructures_Graph_Structures | OK |  |
| DataStructures_Union_Find_Disjoint_Set | OK |  |
| DataStructures_Trie_Operations | OK |  |
| DataStructures_Segment_Tree | OK |  |
| DataStructures_Fenwick_Tree_Binary_Indexed_Tree | OK |  |
| DataStructures_Suffix_Array_Tree | OK |  |
| DataStructures_BSP_Trees | OK |  |
| DataStructures_Quadtrees_Octrees | OK |  |

## devexamples — "Dev Examples" (6 maps: 0 OK, 6 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| gridagent_puzzle01_copy | FAIL | R4: Artifact 'gridagent' at (4,4) h=1 unreachable; R5: Teleport at (8,7) has height 1, must be 0 (void) |
| gridagent_puzzle02_translate | FAIL | R4: Artifact 'gridagent' at (5,4) h=0 unreachable [on ; R5: Teleport at (10,7) has height 1, must be 0 (void) |
| gridagent_puzzle03_rotate | FAIL | R4: Artifact 'gridagent' at (5,5) h=1 unreachable; R5: Teleport at (10,9) has height 1, must be 0 (void) |
| InfoBoards_Example | FAIL | R5: Teleport at (2,6) has height 1, must be 0 (void) |
| Structure_Examples | FAIL | R4: Artifact 'light_sphere' at (13,3) h=1 unreachable; R4: Artifact 'crystal_ball' at (3,9) h=1 unreachable; R4: Artifact 'spectrum_display' at (19,9) h=0 unreacha |
| Structure_Examples_VoxelGrammar_Principles | FAIL | R4: Artifact 'cube_scene' at (10,2) h=3 unreachable; R4: Artifact 'probability_sphere' at (27,21) h=1 unrea |

### Fix Instructions

**gridagent_puzzle01_copy**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix gridagent_puzzle01_copy`
  Manual: Artifact 'gridagent' at (4,4) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**gridagent_puzzle02_translate**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix gridagent_puzzle02_translate`
  Manual: Artifact 'gridagent' at (5,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**gridagent_puzzle03_rotate**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix gridagent_puzzle03_rotate`
  Manual: Artifact 'gridagent' at (5,5) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**InfoBoards_Example**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix InfoBoards_Example`
  Note: Teleport at (2,6) — no structure row at z=7 to catch player

**Structure_Examples**
  Manual: Artifact 'light_sphere' at (13,3) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'crystal_ball' at (3,9) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'spectrum_display' at (19,9) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 2 teleports ((0,3), (16,24)) — normal case is 1

**Structure_Examples_VoxelGrammar_Principles**
  Manual: Artifact 'cube_scene' at (10,2) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'probability_sphere' at (27,21) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 2 teleports ((3,18), (32,30)) — normal case is 1

## forces — "Vectors & Forces: From Direction to Dynamics" (24 maps: 22 OK, 2 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| VectorBasics | OK |  |
| VectorSubtraction | OK |  |
| VectorCrossProduct | OK |  |
| VectorProjectionReflection | OK |  |
| Vectors_1 | FAIL | R4: Artifact 'example_1_2_bouncing_ball_with_vectors_v |
| VectorFieldFlow | OK |  |
| VectorForces | OK |  |
| VectorMotion | OK |  |
| Vectors_5 | OK |  |
| Vectors_6 | OK |  |
| VectorWorkbench | FAIL | R5: Teleport at (5,10) has height 1, must be 0 (void) |
| Forces_1 | OK |  |
| Forces_2 | OK |  |
| Forces_3 | OK |  |
| Forces_4 | OK |  |
| Forces_5 | OK |  |
| Forces_6 | OK |  |
| Forces_7 | OK |  |
| Forces_8 | OK |  |
| VectorThrowing | OK |  |
| VectorTorque | OK |  |
| Forces_Drone_Game | OK |  |
| Forces_Destruct | OK |  |
| Vector_Exhibition | OK |  |

### Fix Instructions

**Vectors_1**
  Manual: Artifact 'example_1_2_bouncing_ball_with_vectors_vr' at (0,7) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**VectorWorkbench**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix VectorWorkbench`
  Note: Teleport at (5,10) — no structure row at z=11 to catch player

## foundationscrisis — "Foundations Crisis: The Limits of Formalization" (7 maps: 6 OK, 1 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Euclid_Parallel | OK |  |
| NonEuclidean_Spaces | OK |  |
| Russell_Paradox | OK |  |
| Godel_Incompleteness | OK |  |
| Brouwer_Intuitionism | OK |  |
| Florensky_Paraconsistent | OK |  |
| Crisis_Synthesis | FAIL | R4: Artifact 'qfep_formula_3d' at (8,8) h=3 unreachabl |

### Fix Instructions

**Crisis_Synthesis**
  Manual: Artifact 'qfep_formula_3d' at (8,8) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

## fractals — "Fractals: Infinite Within Finite" (14 maps: 11 OK, 3 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Fractals_1 | FAIL | R4: Artifact 'recursive_boolean_cube' at (1,10) h=0 un; R4: Artifact 'example_8_3_recursion_circles_vr' at (4,; R4: Artifact 'fibonacci_pagoda' at (2,12) h=0 unreacha |
| Fractals_2 | FAIL | R5: Teleport at (13,11) has height 1, must be 0 (void) |
| Fractals_3 | OK |  |
| Fractals_4 | OK |  |
| Fractals_5 | OK |  |
| Fractals_6 | FAIL | R3: Teleport at (6,6) is NOT reachable from spawn; R4: Artifact 'menger_sponge' at (6,5) h=0 unreachable ; R4: Artifact 'dark_sphere' at (6,6) h=1 unreachable; R5: Teleport at (6,6) has height 1, must be 0 (void) |
| Fractals_7 | OK |  |
| Fractals_8 | OK |  |
| Fractals_9 | OK |  |
| Fractals_10 | OK |  |
| Fractals_11 | OK |  |
| Fractals_12 | OK |  |
| Fractals_13 | OK |  |
| Fractals_14 | OK |  |

### Fix Instructions

**Fractals_1**
  Manual: Artifact 'recursive_boolean_cube' at (1,10) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'example_8_3_recursion_circles_vr' at (4,10) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'fibonacci_pagoda' at (2,12) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Fractals_2**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Fractals_2`
  Note: Teleport at (13,11) — no structure row at z=12 to catch player

**Fractals_6**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Fractals_6`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'menger_sponge' at (6,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (6,6) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 2 teleports ((6,6), (11,11)) — normal case is 1

## grammar_systems — "Grammar Systems: Rules Generate Structure" (3 maps: 0 OK, 3 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| ProceduralGeneration_Markov_Chains | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_N_grams | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| Voxel_Grammar | FAIL | R5: Teleport at (4,10) has height 1, must be 0 (void) |

### Fix Instructions

**ProceduralGeneration_Markov_Chains**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Markov_Chains`

**ProceduralGeneration_N_grams**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_N_grams`

**Voxel_Grammar**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Voxel_Grammar`
  Note: Teleport at (4,10) — no structure row at z=11 to catch player

## graphtheory — "Graph Theory: Connections Define Structure" (8 maps: 8 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| GT_Foundations | OK |  |
| GT_Layout | OK |  |
| GT_Pathfinding | OK |  |
| GT_Network_Analysis | OK |  |
| GT_Connectivity | OK |  |
| GT_Spanning_Trees | OK |  |
| GT_Flow | OK |  |
| GT_Matching | OK |  |

## higher_dimensions — "Higher Dimensions: Beyond 3D" (4 maps: 0 OK, 4 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| ProceduralGenerationTesseractErrorTunnel | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationSixteenCellNet | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationNetSpace | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationPortals | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |

### Fix Instructions

**ProceduralGenerationTesseractErrorTunnel**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationTesseractErrorTunnel`

**ProceduralGenerationSixteenCellNet**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationSixteenCellNet`

**ProceduralGenerationNetSpace**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationNetSpace`

**ProceduralGenerationPortals**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationPortals`

## isosurfaces — "Isosurfaces: Implicit to Explicit" (16 maps: 9 OK, 7 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| ISO_Voxel_Cave_Struct | FAIL | R3: Teleport at (2,0) is NOT reachable from spawn; R3: Teleport at (6,0) is NOT reachable from spawn; R5: Teleport at (2,0) has height 2, must be 0 (void); R5: Teleport at (6,0) has height 2, must be 0 (void) |
| ISO_Showcase_2 | OK |  |
| ISO_Showcase_3 | OK |  |
| ISO_Showcase_4 | OK |  |
| ISO_Showcase_5 | OK |  |
| ISO_Showcase_6 | OK |  |
| ISO_Showcase_7 | OK |  |
| ISO_Showcase_8 | OK |  |
| ISO_Showcase_9 | OK |  |
| ISO_Showcase_10 | FAIL | R3: Teleport at (2,0) is NOT reachable from spawn; R5: Teleport at (2,0) has height 2, must be 0 (void) |
| ISO_Showcase_11 | OK |  |
| ISO_Marching_Gyroid | FAIL | R5: Teleport at (12,12) has height 1, must be 0 (void) |
| ProceduralGeneration_MarchingCave | FAIL | R5: Teleport at (12,12) has height 1, must be 0 (void) |
| ProceduralGenerationMarchingcubesPortalLandscape | FAIL | R5: Teleport at (12,12) has height 1, must be 0 (void) |
| ISO_Metaballs | FAIL | R5: Teleport at (12,12) has height 1, must be 0 (void) |
| ISO_Implicit_Modeling | FAIL | R5: Teleport at (12,12) has height 1, must be 0 (void) |

### Fix Instructions

**ISO_Voxel_Cave_Struct**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ISO_Voxel_Cave_Struct`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Note: Map has 3 teleports ((2,0), (6,0), (11,8)) — normal case is 1

**ISO_Showcase_10**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ISO_Showcase_10`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Note: Map has 2 teleports ((2,0), (11,8)) — normal case is 1

**ISO_Marching_Gyroid**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ISO_Marching_Gyroid`

**ProceduralGeneration_MarchingCave**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_MarchingCave`

**ProceduralGenerationMarchingcubesPortalLandscape**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationMarchingcubesPortalLandscape`

**ISO_Metaballs**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ISO_Metaballs`

**ISO_Implicit_Modeling**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ISO_Implicit_Modeling`

## joints — "Joints" (7 maps: 7 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Joints_1 | OK |  |
| Joints_2 | OK |  |
| Joints_3 | OK |  |
| Joints_4 | OK |  |
| Joints_5 | OK |  |
| Joints_6 | OK |  |
| Joints_7 | OK |  |

## lab — "Lab Evolution States" (39 maps: 0 OK, 1 fail, 38 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Lab | FAIL | R3: Teleport at (3,2) is NOT reachable from spawn; R3: Teleport at (2,4) is NOT reachable from spawn; R4: Artifact 'living_paper' at (2,2) h=2 unreachable; R4: Artifact 'cube_lines' at (2,4) h=0 unreachable [on; R4: Artifact 'light_sphere' at (3,4) h=1 unreachable; R4: Artifact 'vr_component_demo' at (4,4) h=1 unreacha |
| Lab/map_data_init | -- MISSING | map_data.json not found |
| Lab/map_data_one | -- MISSING | map_data.json not found |
| Lab/map_data_one_back | -- MISSING | map_data.json not found |
| Lab/map_data_back | -- MISSING | map_data.json not found |
| Lab/map_data_post_primitives | -- MISSING | map_data.json not found |
| Lab/map_data_post_transformation | -- MISSING | map_data.json not found |
| Lab/map_data_post_color | -- MISSING | map_data.json not found |
| Lab/map_data_post_forces | -- MISSING | map_data.json not found |
| Lab/map_data_post_array_tutorial | -- MISSING | map_data.json not found |
| Lab/map_data_post_wavefunctions | -- MISSING | map_data.json not found |
| Lab/map_data_post_randomness | -- MISSING | map_data.json not found |
| Lab/map_data_post_noise | -- MISSING | map_data.json not found |
| Lab/map_data_post_cellularautomata | -- MISSING | map_data.json not found |
| Lab/map_data_post_fractals | -- MISSING | map_data.json not found |
| Lab/map_data_post_lsystems | -- MISSING | map_data.json not found |
| Lab/map_data_post_proceduralgeneration | -- MISSING | map_data.json not found |
| Lab/map_data_post_softbodies | -- MISSING | map_data.json not found |
| Lab/map_data_post_swarmintelligence | -- MISSING | map_data.json not found |
| Lab/map_data_post_morphogenesis | -- MISSING | map_data.json not found |
| Lab/map_data_post_machinelearning | -- MISSING | map_data.json not found |
| Lab/map_data_post_foundationscrisis | -- MISSING | map_data.json not found |
| Lab/map_data_post_qfeplaboratory | -- MISSING | map_data.json not found |
| Lab/map_data_post_vectors | -- MISSING | map_data.json not found |
| Lab/map_data_post_physicssimulation | -- MISSING | map_data.json not found |
| Lab/map_data_post_datastructures | -- MISSING | map_data.json not found |
| Lab/map_data_post_searchpathfinding | -- MISSING | map_data.json not found |
| Lab/map_data_post_computationalgeometry | -- MISSING | map_data.json not found |
| Lab/map_data_post_meshes | -- MISSING | map_data.json not found |
| Lab/map_data_post_patterngeneration | -- MISSING | map_data.json not found |
| Lab/map_data_post_criticalalgorithms | -- MISSING | map_data.json not found |
| Lab/map_data_post_speculativecomputation | -- MISSING | map_data.json not found |
| Lab/map_data_post_recursiveemergence | -- MISSING | map_data.json not found |
| Lab/map_data_post_artmathematics | -- MISSING | map_data.json not found |
| Lab/map_data_post_proceduralaudio | -- MISSING | map_data.json not found |
| Lab/map_data_post_graphtheory | -- MISSING | map_data.json not found |
| Lab/map_data_post_advancedlaboratory | -- MISSING | map_data.json not found |
| Lab/map_data_post_resourcemanagement | -- MISSING | map_data.json not found |
| Lab/map_data_post_geometric | -- MISSING | map_data.json not found |

### Fix Instructions

**Lab**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'living_paper' at (2,2) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_lines' at (2,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'light_sphere' at (3,4) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'vr_component_demo' at (4,4) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 4 teleports ((8,1), (3,2), (2,4), (8,5)) — normal case is 1

## lsystems — "L-Systems: Rules Grow Structure" (7 maps: 0 OK, 7 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| LSystems_Tree_L_Systems | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| LSystems_AnimatedTree | FAIL | R5: Teleport at (5,4) has height 1, must be 0 (void) |
| LSystems_ContextSensitiveTree | FAIL | R5: Teleport at (7,6) has height 1, must be 0 (void) |
| LSystems_ForestCompetition | FAIL | R5: Teleport at (6,8) has height 1, must be 0 (void) |
| LSystems_Context_Free_Grammars_CFG | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| LSystems_CityGenerator | FAIL | R5: Teleport at (7,7) has height 1, must be 0 (void) |
| LSystems_Hilbert3D | FAIL | R5: Teleport at (6,6) has height 1, must be 0 (void) |

### Fix Instructions

**LSystems_Tree_L_Systems**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix LSystems_Tree_L_Systems`

**LSystems_AnimatedTree**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix LSystems_AnimatedTree`

**LSystems_ContextSensitiveTree**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix LSystems_ContextSensitiveTree`

**LSystems_ForestCompetition**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix LSystems_ForestCompetition`

**LSystems_Context_Free_Grammars_CFG**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix LSystems_Context_Free_Grammars_CFG`

**LSystems_CityGenerator**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix LSystems_CityGenerator`

**LSystems_Hilbert3D**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix LSystems_Hilbert3D`

## machinelearning — "Machine Learning: Algorithms That Learn" (8 maps: 3 OK, 5 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| ML_Evolution | OK |  |
| ML_Gradient_Landscape | OK |  |
| ML_Classification | OK |  |
| ML_Neural_Networks | FAIL | R3: Teleport at (3,12) is NOT reachable from spawn; R4: Artifact 'neural_network_visualization' at (2,5) h; R4: Artifact 'learn_world_stacked' at (1,10) h=2 unrea |
| ML_Perception | FAIL | R3: Teleport at (4,6) is NOT reachable from spawn; R4: Artifact 'computer_vision_vr' at (5,1) h=2 unreach; R4: Artifact 'convolutional_neural_networks_cnns_vr' a |
| ML_Sequence_Memory | FAIL | R3: Teleport at (2,10) is NOT reachable from spawn; R4: Artifact 'transformers_vr' at (1,6) h=2 unreachabl |
| ML_Generative | FAIL | R3: Teleport at (6,6) is NOT reachable from spawn |
| ML_Synthesis | FAIL | R4: Artifact 'anomaly_detection' at (0,9) h=2 unreacha |

### Fix Instructions

**ML_Neural_Networks**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'neural_network_visualization' at (2,5) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'learn_world_stacked' at (1,10) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**ML_Perception**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'computer_vision_vr' at (5,1) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'convolutional_neural_networks_cnns_vr' at (1,3) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**ML_Sequence_Memory**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'transformers_vr' at (1,6) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**ML_Generative**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge

**ML_Synthesis**
  Manual: Artifact 'anomaly_detection' at (0,9) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

## meshes — "Mesh Generation" (4 maps: 0 OK, 4 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Meshes_One | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| Meshes_Two | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| Meshes_Three | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| Meshes_Four | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |

### Fix Instructions

**Meshes_One**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Meshes_One`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**Meshes_Two**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Meshes_Two`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**Meshes_Three**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Meshes_Three`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**Meshes_Four**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Meshes_Four`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

## morphogenesis — "Morphogenesis: Pattern from Noise" (0 maps: 0 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|

## noise — "Noise: Entropy with Memory" (9 maps: 4 OK, 5 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Random_Noise_Types | OK |  |
| Noise_Columns | OK |  |
| Noise_One | FAIL | R4: Artifact 'noisetorus' at (5,5) h=0 unreachable [on; R4: Artifact 'noiselayers' at (5,6) h=0 unreachable [o |
| Noise_Voxel | OK |  |
| Noise_6_Wall | FAIL | R4: Artifact 'shader_noise_space' at (5,5) h=0 unreach |
| Noise_Inside_Noise | FAIL | R3: Teleport at (7,12) is NOT reachable from spawn; R4: Artifact 'dark_sphere' at (5,5) h=0 unreachable [o; R4: Artifact 'noisesphere' at (5,6) h=0 unreachable [o; R5: Teleport at (7,12) has height 2, must be 0 (void) |
| Noise_Space_10 | FAIL | R3: Teleport at (10,12) is NOT reachable from spawn; R4: Artifact 'dark_sphere' at (5,5) h=1 unreachable; R4: Artifact 'noise_space' at (5,6) h=1 unreachable |
| Noise_Perlin_Simplex | FAIL | R4: Artifact 'simplex_noise' at (2,3) h=0 unreachable ; R4: Artifact 'perlin_noise' at (7,3) h=0 unreachable [; R4: Artifact 'noise_terrain' at (5,6) h=0 unreachable ; R4: Artifact 'dark_sphere' at (5,7) h=0 unreachable [o; R4: Artifact 'perlin_noise_terrain' at (5,10) h=0 unre; R4: Artifact 'configurable_portal' at (8,12) h=0 unrea |
| Lab_Path | OK |  |

### Fix Instructions

**Noise_One**
  Manual: Artifact 'noisetorus' at (5,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'noiselayers' at (5,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Noise_6_Wall**
  Manual: Artifact 'shader_noise_space' at (5,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Noise_Inside_Noise**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Noise_Inside_Noise`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'dark_sphere' at (5,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'noisesphere' at (5,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (7,12) — no structure row at z=13 to catch player

**Noise_Space_10**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'dark_sphere' at (5,5) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'noise_space' at (5,6) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**Noise_Perlin_Simplex**
  Manual: Artifact 'simplex_noise' at (2,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'perlin_noise' at (7,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'noise_terrain' at (5,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (5,7) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'perlin_noise_terrain' at (5,10) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'configurable_portal' at (8,12) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

## particles — "Particle Systems" (5 maps: 5 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Particles_1 | OK |  |
| Particles_2 | OK |  |
| Particles_3 | OK |  |
| Particles_4 | OK |  |
| Particles_5 | OK |  |

## patterngeneration — "Shaders & Patterns: The Book of Shaders" (18 maps: 17 OK, 1 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Shader_01_Shaping | OK |  |
| Shader_02_Colors | OK |  |
| Shader_03_Shapes | OK |  |
| Shader_04_Matrices | OK |  |
| Shader_05_Patterns | OK |  |
| Shader_06_Random | OK |  |
| Shader_07_Noise | OK |  |
| Shader_08_CellularNoise | OK |  |
| Shader_09_FBM | OK |  |
| Shader_10_ReactionDiffusion | OK |  |
| Shader_11_QueerRubber | OK |  |
| Shader_12_PinkExtravaganza | OK |  |
| Pattern_Generation_Five | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| PatternGeneration_Diffusion_Limited_Aggregation_DLA | OK |  |
| PatternGeneration_Narrative_Generation | OK |  |
| PatternGeneration_Penrose_Tilings | OK |  |
| PatternGeneration_Typography_Generation | OK |  |
| PatternGeneration_Wang_Tiles | OK |  |

### Fix Instructions

**Pattern_Generation_Five**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Pattern_Generation_Five`
  Note: Teleport at (9,12) — no structure row at z=13 to catch player

## physicssimulation — "Physics Simulation: The Engine Behind Reality" (21 maps: 16 OK, 5 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| PhysicsSim_Foundations | FAIL | R5: Teleport at (3,8) has height 1, must be 0 (void) |
| PhysicsSim_Bodies | FAIL | R5: Teleport at (4,8) has height 1, must be 0 (void) |
| PhysicsSim_Springs | FAIL | R5: Teleport at (3,10) has height 1, must be 0 (void) |
| PhysicsSim_Fields | FAIL | R5: Teleport at (4,10) has height 1, must be 0 (void) |
| PhysicsSim_Continuum | FAIL | R5: Teleport at (4,10) has height 1, must be 0 (void) |
| PhysicsSimulation_Bouncing_Ball_Physics | OK |  |
| PhysicsSimulation_Cloth_Simulation | OK |  |
| PhysicsSimulation_Collision_Detection | OK |  |
| PhysicsSimulation_Constraints | OK |  |
| PhysicsSimulation_Finite_Element_Method_FEM | OK |  |
| PhysicsSimulation_Fluid_Simulation_SPH | OK |  |
| PhysicsSimulation_Force_Fields | OK |  |
| PhysicsSimulation_Mass_Spring_Damper | OK |  |
| PhysicsSimulation_Newton_s_Laws | OK |  |
| PhysicsSimulation_Numerical_Integration | OK |  |
| PhysicsSimulation_Particle_Systems | OK |  |
| PhysicsSimulation_Rigid_Body_Dynamics | OK |  |
| PhysicsSimulation_Spring_Mass_Systems | OK |  |
| PhysicsSimulation_Three_Body_Problem | OK |  |
| PhysicsSimulation_Vector_Fields | OK |  |
| PhysicsSimulation_Verlet_Integration | OK |  |

### Fix Instructions

**PhysicsSim_Foundations**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix PhysicsSim_Foundations`

**PhysicsSim_Bodies**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix PhysicsSim_Bodies`
  Note: Teleport at (4,8) — no structure row at z=9 to catch player

**PhysicsSim_Springs**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix PhysicsSim_Springs`
  Note: Teleport at (3,10) — no structure row at z=11 to catch player

**PhysicsSim_Fields**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix PhysicsSim_Fields`
  Note: Teleport at (4,10) — no structure row at z=11 to catch player

**PhysicsSim_Continuum**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix PhysicsSim_Continuum`
  Note: Teleport at (4,10) — no structure row at z=11 to catch player

## postfoundationscrisis — "Post-Crisis: Applied Limits" (3 maps: 3 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| CriticalAlgorithms_Algorithmic_Bias_Visualization | OK |  |
| SpeculativeComputation_Rhizome_Network | OK |  |
| AdvancedLaboratory_Lab_Equipment_Simulation | OK |  |

## primitives — "Primitives: Points Build Worlds" (11 maps: 6 OK, 5 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Point_One | FAIL | R3: Teleport at (1,5) is NOT reachable from spawn; R4: Artifact 'static_point' at (4,0) h=1 unreachable; R4: Artifact 'dark_sphere' at (3,2) h=0 unreachable [o; R4: Artifact 'interactive_point_origin' at (1,3) h=1 u; R4: Artifact 'frame_counter_display' at (0,9) h=1 unre; R4: Artifact 'CoordinateSystem3M' at (6,9) h=0 unreach |
| Point_Lines | FAIL | R4: Artifact 'perspective_lines' at (1,23) h=0 unreach; R4: Artifact 'scale_lines' at (3,23) h=0 unreachable [; R4: Artifact 'perspective_lines' at (5,23) h=0 unreach; R4: Artifact 'lightrod' at (3,25) h=0 unreachable [on ; R4: Artifact 'dgrid' at (6,26) h=0 unreachable [on VOI |
| Point_Trace | OK |  |
| Point_Line_Grid | FAIL | R4: Artifact 'grid_lines' at (4,3) h=0 unreachable [on; R4: Artifact 'dark_sphere' at (3,4) h=0 unreachable [o |
| Point_Triangle | OK |  |
| Point_Triangle_Context | OK |  |
| Primitives_Polythedra | FAIL | R3: Teleport at (5,6) is NOT reachable from spawn; R4: Artifact 'pyramid_edit' at (1,7) h=2 unreachable |
| Point_Animatedcube | OK |  |
| Primitives_Ignorance | FAIL | R4: Artifact 'plus' at (1,25) h=0 unreachable [on VOID; R4: Artifact 'plus' at (7,25) h=0 unreachable [on VOID |
| Primitives_Portals | OK |  |
| Primitives_Melencolia | OK |  |

### Fix Instructions

**Point_One**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'static_point' at (4,0) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (3,2) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'interactive_point_origin' at (1,3) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'frame_counter_display' at (0,9) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'CoordinateSystem3M' at (6,9) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Point_Lines**
  Manual: Artifact 'perspective_lines' at (1,23) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'scale_lines' at (3,23) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'perspective_lines' at (5,23) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'lightrod' at (3,25) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dgrid' at (6,26) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Point_Line_Grid**
  Manual: Artifact 'grid_lines' at (4,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (3,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Primitives_Polythedra**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'pyramid_edit' at (1,7) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**Primitives_Ignorance**
  Manual: Artifact 'plus' at (1,25) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'plus' at (7,25) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

## proceduralaudio — "Procedural Audio" (8 maps: 0 OK, 8 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| ProceduralAudio_Additive_Synthesis | FAIL | R5: Teleport at (9,11) has height 1, must be 0 (void) |
| ProceduralAudio_Subtractive_Synthesis | FAIL | R5: Teleport at (9,11) has height 1, must be 0 (void) |
| ProceduralAudio_FM_Synthesis | FAIL | R5: Teleport at (9,11) has height 1, must be 0 (void) |
| ProceduralAudio_Granular_Synthesis | FAIL | R5: Teleport at (9,11) has height 1, must be 0 (void) |
| ProceduralAudio_Audio_Effects | FAIL | R5: Teleport at (9,11) has height 1, must be 0 (void) |
| ProceduralAudio_Sound_Synthesis_Drone_Effects | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralAudio_Generative_Music_Algorithms | FAIL | R5: Teleport at (9,11) has height 1, must be 0 (void) |
| ProceduralAudio_Psychoacoustics | FAIL | R5: Teleport at (9,11) has height 1, must be 0 (void) |

### Fix Instructions

**ProceduralAudio_Additive_Synthesis**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralAudio_Additive_Synthesis`

**ProceduralAudio_Subtractive_Synthesis**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralAudio_Subtractive_Synthesis`

**ProceduralAudio_FM_Synthesis**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralAudio_FM_Synthesis`

**ProceduralAudio_Granular_Synthesis**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralAudio_Granular_Synthesis`

**ProceduralAudio_Audio_Effects**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralAudio_Audio_Effects`

**ProceduralAudio_Sound_Synthesis_Drone_Effects**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralAudio_Sound_Synthesis_Drone_Effects`

**ProceduralAudio_Generative_Music_Algorithms**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralAudio_Generative_Music_Algorithms`

**ProceduralAudio_Psychoacoustics**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralAudio_Psychoacoustics`

## proceduralgeneration — "Procedural Generation: Rules Build Worlds" (7 maps: 6 OK, 1 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| PG_Genetic_Evolution | OK |  |
| PG_Space_Colonization | OK |  |
| PG_Percolation_Network | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| PG_Branching_Growth | OK |  |
| PG_Caves_Mazes | OK |  |
| PG_Sculpted_Forms | OK |  |
| PG_Mirrored_Patterns | OK |  |

### Fix Instructions

**PG_Percolation_Network**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix PG_Percolation_Network`

## proceduralgeneration_all — "Procedural Generation (All Maps)" (42 maps: 0 OK, 42 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| ProceduralGeneration_21 | FAIL | R5: Teleport at (7,12) has height 1, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_BranchingGrowthAlgorithm | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_CaveRandomWalk | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_CubeMound | FAIL | R5: Teleport at (7,12) has height 1, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Delaunay_Triangulation | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Dome | FAIL | R5: Teleport at (7,12) has height 1, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Eight | FAIL | R5: Teleport at (8,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Eleven | FAIL | R5: Teleport at (7,12) has height 1, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Five | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Four | FAIL | R5: Teleport at (8,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Genetic_Algorithms | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Genetic_Programming | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Marching_Cubes_Algorithm | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_MarchingCave | FAIL | R5: Teleport at (12,12) has height 1, must be 0 (void) |
| ProceduralGeneration_MarchingGallery | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Markov_Chains | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Maze | FAIL | R5: Teleport at (2,0) has height 1, must be 0 (void); R5: Teleport at (15,16) has height 1, must be 0 (void) |
| ProceduralGeneration_N_grams | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Poisson_Disk_Sampling | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Reaction_Diffusion_Systems | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Seven | FAIL | R5: Teleport at (7,12) has height 1, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Space_Colonization_Algorithms | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Space_Partitioning | FAIL | R5: Teleport at (14,16) has height 1, must be 0 (void) |
| ProceduralGeneration_Ten | FAIL | R5: Teleport at (7,12) has height 1, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Three | FAIL | R5: Teleport at (7,12) has height 1, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Two | FAIL | R5: Teleport at (7,12) has height 1, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Voronoi_Diagrams | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Wave_Function_Collapse | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationBooleanPatterns | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationCaveExplorer3dUi | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationCrystalRandom | FAIL | R5: Teleport at (9,11) has height 1, must be 0 (void) |
| ProceduralGenerationMarchingcubesFlatLandscape | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationMarchingCubesInsideCave | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationMarchingcubesPortalLandscape | FAIL | R5: Teleport at (12,12) has height 1, must be 0 (void) |
| ProceduralGenerationMarchingCubesSculpture | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationMarchingcubesTorusSculpture | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationMarchingCubesVovelNoise | FAIL | R5: Teleport at (4,1) has height 1, must be 0 (void) |
| ProceduralGenerationNetSpace | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationPortals | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationSixteenCellNet | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationTesseractErrorTunnel | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGenerationWfcDungeonGenerator | FAIL | R5: Teleport at (2,1) has height 1, must be 0 (void) |

### Fix Instructions

**ProceduralGeneration_21**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_21`
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**ProceduralGeneration_BranchingGrowthAlgorithm**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_BranchingGrowthAlgorithm`

**ProceduralGeneration_CaveRandomWalk**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_CaveRandomWalk`

**ProceduralGeneration_CubeMound**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_CubeMound`
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**ProceduralGeneration_Delaunay_Triangulation**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Delaunay_Triangulation`

**ProceduralGeneration_Dome**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Dome`
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**ProceduralGeneration_Eight**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Eight`

**ProceduralGeneration_Eleven**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Eleven`
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**ProceduralGeneration_Five**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Five`

**ProceduralGeneration_Four**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Four`

**ProceduralGeneration_Genetic_Algorithms**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Genetic_Algorithms`

**ProceduralGeneration_Genetic_Programming**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Genetic_Programming`

**ProceduralGeneration_Marching_Cubes_Algorithm**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Marching_Cubes_Algorithm`

**ProceduralGeneration_MarchingCave**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_MarchingCave`

**ProceduralGeneration_MarchingGallery**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_MarchingGallery`

**ProceduralGeneration_Markov_Chains**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Markov_Chains`

**ProceduralGeneration_Maze**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Maze`
  Note: Map has 2 teleports ((2,0), (15,16)) — normal case is 1

**ProceduralGeneration_N_grams**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_N_grams`

**ProceduralGeneration_Poisson_Disk_Sampling**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Poisson_Disk_Sampling`

**ProceduralGeneration_Reaction_Diffusion_Systems**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Reaction_Diffusion_Systems`

**ProceduralGeneration_Seven**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Seven`
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**ProceduralGeneration_Space_Colonization_Algorithms**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Space_Colonization_Algorithms`

**ProceduralGeneration_Space_Partitioning**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Space_Partitioning`

**ProceduralGeneration_Ten**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Ten`
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**ProceduralGeneration_Three**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Three`
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**ProceduralGeneration_Two**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Two`
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**ProceduralGeneration_Voronoi_Diagrams**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Voronoi_Diagrams`

**ProceduralGeneration_Wave_Function_Collapse**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Wave_Function_Collapse`

**ProceduralGenerationBooleanPatterns**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationBooleanPatterns`

**ProceduralGenerationCaveExplorer3dUi**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationCaveExplorer3dUi`

**ProceduralGenerationCrystalRandom**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationCrystalRandom`

**ProceduralGenerationMarchingcubesFlatLandscape**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationMarchingcubesFlatLandscape`

**ProceduralGenerationMarchingCubesInsideCave**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationMarchingCubesInsideCave`

**ProceduralGenerationMarchingcubesPortalLandscape**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationMarchingcubesPortalLandscape`

**ProceduralGenerationMarchingCubesSculpture**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationMarchingCubesSculpture`

**ProceduralGenerationMarchingcubesTorusSculpture**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationMarchingcubesTorusSculpture`

**ProceduralGenerationMarchingCubesVovelNoise**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationMarchingCubesVovelNoise`

**ProceduralGenerationNetSpace**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationNetSpace`

**ProceduralGenerationPortals**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationPortals`

**ProceduralGenerationSixteenCellNet**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationSixteenCellNet`

**ProceduralGenerationTesseractErrorTunnel**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationTesseractErrorTunnel`

**ProceduralGenerationWfcDungeonGenerator**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGenerationWfcDungeonGenerator`

## qfeplaboratory — "QFEP Laboratory: The Formula Made Interactive" (8 maps: 0 OK, 8 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| QFEP_Introduction | FAIL | R1: Spawn is 's:1:1:1' — must be 's' (always start at  |
| QFEP_F_Term | FAIL | R1: Spawn is 's:1:1:1' — must be 's' (always start at ; R3: Teleport at (4,11) is NOT reachable from spawn; R4: Artifact 'crystal_cluster' at (4,4) h=2 unreachabl |
| QFEP_E_Term | FAIL | R1: Spawn is 's:1:1:1' — must be 's' (always start at ; R4: Artifact 'random_cubes' at (4,3) h=3 unreachable; R4: Artifact 'random_cubes' at (7,3) h=3 unreachable; R4: Artifact 'particle_chaos' at (5,5) h=3 unreachable; R4: Artifact 'random_cubes' at (4,7) h=3 unreachable; R4: Artifact 'random_cubes' at (7,7) h=3 unreachable |
| QFEP_Lambda_Spectrum | FAIL | R1: Spawn is 's:2:1:0' — must be 's' (always start at  |
| QFEP_Phi_Term | FAIL | R1: Spawn is 's:1:1:1' — must be 's' (always start at  |
| QFEP_Edge_Of_Chaos | FAIL | R1: Spawn is 's:1:1:1' — must be 's' (always start at ; R4: Artifact 'turing_pattern' at (4,3) h=3 unreachable; R4: Artifact 'turing_pattern' at (8,3) h=3 unreachable; R4: Artifact 'edge_core' at (6,6) h=4 unreachable; R4: Artifact 'emergence_zone' at (4,9) h=3 unreachable; R4: Artifact 'emergence_zone' at (8,9) h=3 unreachable |
| QFEP_Sandbox | FAIL | R1: Spawn is 's:1:1:1' — must be 's' (always start at ; R4: Artifact 'qfep_reactor' at (6,5) h=3 unreachable; R4: Artifact 'reactive_particles' at (4,7) h=3 unreach; R4: Artifact 'reactive_particles' at (8,7) h=3 unreach |
| QFEP_Synthesis | FAIL | R1: Spawn is 's:1:1:1' — must be 's' (always start at ; R4: Artifact 'qfep_formula_3d' at (5,5) h=3 unreachabl |

### Fix Instructions

**QFEP_Introduction**
Auto-fix (Rule 1):
  `python tools/map_pathfinder.py fix QFEP_Introduction`
  Note: Teleport at (4,9) — no structure row at z=10 to catch player

**QFEP_F_Term**
Auto-fix (Rule 1):
  `python tools/map_pathfinder.py fix QFEP_F_Term`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'crystal_cluster' at (4,4) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (4,11) — no structure row at z=12 to catch player

**QFEP_E_Term**
Auto-fix (Rule 1):
  `python tools/map_pathfinder.py fix QFEP_E_Term`
  Manual: Artifact 'random_cubes' at (4,3) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'random_cubes' at (7,3) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'particle_chaos' at (5,5) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'random_cubes' at (4,7) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'random_cubes' at (7,7) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (5,11) — no structure row at z=12 to catch player

**QFEP_Lambda_Spectrum**
Auto-fix (Rule 1):
  `python tools/map_pathfinder.py fix QFEP_Lambda_Spectrum`
  Note: Teleport at (2,17) — no structure row at z=18 to catch player

**QFEP_Phi_Term**
Auto-fix (Rule 1):
  `python tools/map_pathfinder.py fix QFEP_Phi_Term`
  Note: Teleport at (4,9) — no structure row at z=10 to catch player

**QFEP_Edge_Of_Chaos**
Auto-fix (Rule 1):
  `python tools/map_pathfinder.py fix QFEP_Edge_Of_Chaos`
  Manual: Artifact 'turing_pattern' at (4,3) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'turing_pattern' at (8,3) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'edge_core' at (6,6) h=4 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'emergence_zone' at (4,9) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'emergence_zone' at (8,9) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (6,12) — no structure row at z=13 to catch player

**QFEP_Sandbox**
Auto-fix (Rule 1):
  `python tools/map_pathfinder.py fix QFEP_Sandbox`
  Manual: Artifact 'qfep_reactor' at (6,5) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'reactive_particles' at (4,7) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'reactive_particles' at (8,7) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (6,13) — no structure row at z=14 to catch player

**QFEP_Synthesis**
Auto-fix (Rule 1):
  `python tools/map_pathfinder.py fix QFEP_Synthesis`
  Manual: Artifact 'qfep_formula_3d' at (5,5) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (5,11) — no structure row at z=12 to catch player

## randomness — "Randomness: Freedom from Pattern" (13 maps: 8 OK, 5 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Random_Definition | OK |  |
| Random_Remove | OK |  |
| Randomness_10_PRINT_Algorithm | OK |  |
| Random_Cubes | OK |  |
| Random_Rotate_Random_XYZ | OK |  |
| Random_Walk | FAIL | R4: Artifact 'random_walk_128' at (6,6) h=0 unreachabl; R4: Artifact 'dark_sphere' at (5,7) h=0 unreachable [o; R4: Artifact 'random_walk_leash' at (8,8) h=0 unreacha |
| Random_Gaussian | FAIL | R4: Artifact 'random_bell_curve' at (6,20) h=0 unreach; R5: Teleport at (9,2) has height 1, must be 0 (void) |
| Random_Mushrooms | OK |  |
| Random_Space_Geometry | OK |  |
| Randomness_Examples_of_Randomness | OK |  |
| Random_Pheromone | FAIL | R3: Teleport at (7,7) is NOT reachable from spawn; R4: Artifact 'dark_sphere' at (4,5) h=0 unreachable [o; R4: Artifact 'pheromone_terrain' at (5,5) h=0 unreacha; R4: Artifact 'clipboard' at (2,6) h=0 unreachable [on ; R4: Artifact 'clipboard' at (3,7) h=0 unreachable [on ; R5: Teleport at (7,7) has height 1, must be 0 (void) |
| Random_Space | FAIL | R5: Teleport at (6,14) has height 1, must be 0 (void) |
| Random_Game | FAIL | R3: Teleport at (7,0) is NOT reachable from spawn; R3: Teleport at (6,15) is NOT reachable from spawn; R4: Artifact 'r_c' at (1,3) h=0 unreachable [on VOID]; R4: Artifact 'r_c' at (2,3) h=0 unreachable [on VOID]; R4: Artifact 'r_c' at (3,3) h=0 unreachable [on VOID]; R4: Artifact 'r_c' at (1,4) h=0 unreachable [on VOID]; R4: Artifact 'r_c' at (2,4) h=0 unreachable [on VOID]; R4: Artifact 'r_c' at (3,4) h=0 unreachable [on VOID]; R4: Artifact 'armadillo_eggling' at (4,6) h=1 unreacha; R4: Artifact 'armadillo_eggling' at (8,6) h=1 unreacha; R4: Artifact 'origami_droideka' at (6,7) h=1 unreachab; R4: Artifact 'cube_projectile_spawner' at (6,8) h=1 un; R4: Artifact 'miura_crawler' at (2,10) h=1 unreachable; R4: Artifact 'kresling_spire' at (3,10) h=1 unreachabl; R4: Artifact 'scissor_stalker' at (4,10) h=1 unreachab; R4: Artifact 'kaleidocycle_enemy' at (5,10) h=0 unreac |

### Fix Instructions

**Random_Walk**
  Manual: Artifact 'random_walk_128' at (6,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (5,7) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'random_walk_leash' at (8,8) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 2 teleports ((0,4), (10,12)) — normal case is 1

**Random_Gaussian**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Random_Gaussian`
  Manual: Artifact 'random_bell_curve' at (6,20) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Random_Pheromone**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Random_Pheromone`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'dark_sphere' at (4,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'pheromone_terrain' at (5,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'clipboard' at (2,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'clipboard' at (3,7) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (7,7) — row z=8 has no floor cubes to catch player

**Random_Space**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Random_Space`
  Note: Teleport at (6,14) — no structure row at z=15 to catch player

**Random_Game**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'r_c' at (1,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'r_c' at (2,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'r_c' at (3,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'r_c' at (1,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'r_c' at (2,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'r_c' at (3,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'armadillo_eggling' at (4,6) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'armadillo_eggling' at (8,6) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'origami_droideka' at (6,7) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_projectile_spawner' at (6,8) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'miura_crawler' at (2,10) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'kresling_spire' at (3,10) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'scissor_stalker' at (4,10) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'kaleidocycle_enemy' at (5,10) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (6,15) — no structure row at z=16 to catch player
  Note: Map has 2 teleports ((7,0), (6,15)) — normal case is 1

## recursiveemergence — "Recursive Emergence" (11 maps: 11 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| RecursiveEmergence_Cellular_Automata_1D | OK |  |
| RecursiveEmergence_Cellular_Automata_2D | OK |  |
| RecursiveEmergence_Cellular_Automata_3D | OK |  |
| RecursiveEmergence_Rule_30_110 | OK |  |
| RecursiveEmergence_Lattice_Gas_Automata | OK |  |
| RecursiveEmergence_Fibonacci_Sequences | OK |  |
| RecursiveEmergence_Tail_Recursion_Memoization | OK |  |
| RecursiveEmergence_Iterated_Function_Systems_IFS | OK |  |
| RecursiveEmergence_Koch_Curve | OK |  |
| RecursiveEmergence_Mandelbrot_Set | OK |  |
| RecursiveEmergence_Julia_Set | OK |  |

## resourcemanagement — "Resource Management" (0 maps: 0 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|

## searchpathfinding — "Search & Pathfinding" (0 maps: 0 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|

## softbodies — "Soft Bodies & Morphogenesis: Matter That Finds Its Shape" (9 maps: 7 OK, 2 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| SoftBodies_Soft_Body_Deformation | OK |  |
| SoftBodies_Carusell | OK |  |
| SoftBodies_Obsticals | OK |  |
| SoftBodies_Obsticals_Part2 | OK |  |
| SoftBodies_Cloth_Physics | OK |  |
| SoftBodies_Playground_of_Joy | OK |  |
| SoftBodies_Affect_Theory_Visualization | OK |  |
| ProceduralGeneration_Reaction_Diffusion_Systems | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| Topology_Entropy_Morphogenesis | FAIL | R5: Teleport at (7,9) has height 1, must be 0 (void) |

### Fix Instructions

**ProceduralGeneration_Reaction_Diffusion_Systems**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Reaction_Diffusion_Systems`

**Topology_Entropy_Morphogenesis**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Topology_Entropy_Morphogenesis`

## spatial_partitioning — "Spatial Partitioning: Dividing Space" (4 maps: 0 OK, 4 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| ProceduralGeneration_Voronoi_Diagrams | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Delaunay_Triangulation | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |
| ProceduralGeneration_Space_Partitioning | FAIL | R5: Teleport at (14,16) has height 1, must be 0 (void) |
| ProceduralGeneration_Poisson_Disk_Sampling | FAIL | R5: Teleport at (9,12) has height 1, must be 0 (void) |

### Fix Instructions

**ProceduralGeneration_Voronoi_Diagrams**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Voronoi_Diagrams`

**ProceduralGeneration_Delaunay_Triangulation**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Delaunay_Triangulation`

**ProceduralGeneration_Space_Partitioning**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Space_Partitioning`

**ProceduralGeneration_Poisson_Disk_Sampling**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix ProceduralGeneration_Poisson_Disk_Sampling`

## speculativecomputation — "Speculative Computation" (0 maps: 0 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|

## structure — "Structure Grammar: Spatial Formulas" (16 maps: 14 OK, 2 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| F1_Pedestal | OK |  |
| F2_Corridor | OK |  |
| F4_Amphitheater | FAIL | R4: Artifact 'light_sphere' at (3,3) h=1 unreachable |
| F8_The_Drop | OK |  |
| F9_Frame | OK |  |
| F11_Comparison | OK |  |
| F12_Cathedral | OK |  |
| F13_Observation | OK |  |
| F14_Lab_Bench | OK |  |
| F17_Zen_Garden | OK |  |
| F20_Well | FAIL | R4: Artifact 'spectrum_display' at (3,3) h=0 unreachab |
| F26_Portal_Chamber | OK |  |
| F30_Ramp_Walkpath | OK |  |
| F31_Transport_Cube | OK |  |
| F32_Teleporter | OK |  |
| F33_Bridge | OK |  |

### Fix Instructions

**F4_Amphitheater**
  Manual: Artifact 'light_sphere' at (3,3) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**F20_Well**
  Manual: Artifact 'spectrum_display' at (3,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

## swarmintelligence — "Swarm Intelligence: No Leader, Yet Coordinated" (7 maps: 0 OK, 7 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| SwarmIntelligence_PhysarumColony | FAIL | R5: Teleport at (5,7) has height 1, must be 0 (void) |
| SwarmIntelligence_FlowFeilds | FAIL | R5: Teleport at (8,6) has height 1, must be 0 (void) |
| SwarmIntelligence_Boids_Algorithm | FAIL | R5: Teleport at (9,9) has height 1, must be 0 (void) |
| SwarmIntelligence_Agent_Based_Modeling_ABM | FAIL | R5: Teleport at (6,6) has height 1, must be 0 (void) |
| SwarmIntelligence_Ant_Colony_Optimization | FAIL | R5: Teleport at (8,5) has height 1, must be 0 (void) |
| SwarmIntelligence_Particle_Swarm_Optimization | FAIL | R5: Teleport at (7,7) has height 1, must be 0 (void) |
| SwarmIntelligence_Swarm_Intelligence_Algorithms | FAIL | R5: Teleport at (8,8) has height 1, must be 0 (void) |

### Fix Instructions

**SwarmIntelligence_PhysarumColony**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix SwarmIntelligence_PhysarumColony`

**SwarmIntelligence_FlowFeilds**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix SwarmIntelligence_FlowFeilds`

**SwarmIntelligence_Boids_Algorithm**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix SwarmIntelligence_Boids_Algorithm`

**SwarmIntelligence_Agent_Based_Modeling_ABM**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix SwarmIntelligence_Agent_Based_Modeling_ABM`

**SwarmIntelligence_Ant_Colony_Optimization**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix SwarmIntelligence_Ant_Colony_Optimization`

**SwarmIntelligence_Particle_Swarm_Optimization**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix SwarmIntelligence_Particle_Swarm_Optimization`

**SwarmIntelligence_Swarm_Intelligence_Algorithms**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix SwarmIntelligence_Swarm_Intelligence_Algorithms`

## templats — "Templates" (4 maps: 4 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Template_Basic | OK |  |
| Template_Medium | OK |  |
| Template_Large | OK |  |
| Template_Land | OK |  |

## testmaps — "Unused Artifacts Test" (22 maps: 0 OK, 22 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Test_1 | FAIL | R4: Artifact 'ChengSimulationScaled' at (5,6) h=0 unre |
| Test_2 | FAIL | R3: Teleport at (9,11) is NOT reachable from spawn; R4: Artifact 'closest_pair' at (5,5) h=0 unreachable [; R5: Teleport at (9,11) has height 2, must be 0 (void) |
| Test_3 | FAIL | R3: Teleport at (7,12) is NOT reachable from spawn; R3: Teleport at (8,12) is NOT reachable from spawn; R3: Teleport at (9,12) is NOT reachable from spawn; R4: Artifact 'distance_fields_sdf' at (3,5) h=0 unreac; R5: Teleport at (7,12) has height 2, must be 0 (void); R5: Teleport at (8,12) has height 2, must be 0 (void); R5: Teleport at (9,12) has height 2, must be 0 (void) |
| Test_4 | FAIL | R3: Teleport at (3,0) is NOT reachable from spawn; R3: Teleport at (7,12) is NOT reachable from spawn; R3: Teleport at (8,12) is NOT reachable from spawn; R3: Teleport at (9,12) is NOT reachable from spawn; R4: Artifact 'pathfinding3d' at (5,6) h=4 unreachable; R5: Teleport at (3,0) has height 3, must be 0 (void); R5: Teleport at (7,12) has height 4, must be 0 (void); R5: Teleport at (8,12) has height 4, must be 0 (void); R5: Teleport at (9,12) has height 4, must be 0 (void) |
| Test_5 | FAIL | R4: Artifact 'random_color_book_page_collection' at (1; R5: Teleport at (3,0) has height 1, must be 0 (void); R5: Teleport at (7,12) has height 1, must be 0 (void) |
| Test_6 | FAIL | R3: Teleport at (2,0) is NOT reachable from spawn; R3: Teleport at (7,12) is NOT reachable from spawn; R3: Teleport at (8,12) is NOT reachable from spawn; R3: Teleport at (9,12) is NOT reachable from spawn; R4: Artifact 'pathfinding_visualization' at (5,6) h=4 ; R4: Artifact 'network_analysis' at (2,11) h=7 unreacha; R5: Teleport at (2,0) has height 9, must be 0 (void); R5: Teleport at (7,12) has height 2, must be 0 (void); R5: Teleport at (8,12) has height 2, must be 0 (void); R5: Teleport at (9,12) has height 2, must be 0 (void) |
| Test_7 | FAIL | R3: Teleport at (9,12) is NOT reachable from spawn; R4: Artifact 'random_plants' at (3,7) h=1 unreachable; R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 2, must be 0 (void) |
| Test_8 | FAIL | R3: Teleport at (9,12) is NOT reachable from spawn; R4: Artifact 'random_plants' at (3,7) h=1 unreachable; R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 2, must be 0 (void) |
| Test_9 | FAIL | R4: Artifact 'graphspace' at (5,6) h=0 unreachable [on |
| Test_10 | FAIL | R3: Teleport at (9,11) is NOT reachable from spawn; R4: Artifact 'graphspace3d' at (5,5) h=0 unreachable [; R4: Artifact 'KonigsbergBridge' at (5,6) h=0 unreachab; R5: Teleport at (9,11) has height 2, must be 0 (void) |
| Test_11 | FAIL | R3: Teleport at (7,12) is NOT reachable from spawn; R3: Teleport at (8,12) is NOT reachable from spawn; R3: Teleport at (9,12) is NOT reachable from spawn; R4: Artifact 'graphspace' at (3,5) h=0 unreachable [on; R5: Teleport at (7,12) has height 2, must be 0 (void); R5: Teleport at (8,12) has height 2, must be 0 (void); R5: Teleport at (9,12) has height 2, must be 0 (void) |
| Test_12 | FAIL | R3: Teleport at (3,0) is NOT reachable from spawn; R3: Teleport at (7,12) is NOT reachable from spawn; R3: Teleport at (8,12) is NOT reachable from spawn; R3: Teleport at (9,12) is NOT reachable from spawn; R4: Artifact 'pathfinding3d' at (5,6) h=4 unreachable; R5: Teleport at (3,0) has height 3, must be 0 (void); R5: Teleport at (7,12) has height 4, must be 0 (void); R5: Teleport at (8,12) has height 4, must be 0 (void); R5: Teleport at (9,12) has height 4, must be 0 (void) |
| Test_13 | FAIL | R4: Artifact 'random_color_book_page_collection' at (1; R5: Teleport at (3,0) has height 1, must be 0 (void); R5: Teleport at (7,12) has height 1, must be 0 (void) |
| Test_14 | FAIL | R3: Teleport at (2,0) is NOT reachable from spawn; R3: Teleport at (7,12) is NOT reachable from spawn; R3: Teleport at (8,12) is NOT reachable from spawn; R3: Teleport at (9,12) is NOT reachable from spawn; R4: Artifact 'pathfinding_visualization' at (5,6) h=4 ; R4: Artifact 'network_analysis' at (2,11) h=7 unreacha; R5: Teleport at (2,0) has height 9, must be 0 (void); R5: Teleport at (7,12) has height 2, must be 0 (void); R5: Teleport at (8,12) has height 2, must be 0 (void); R5: Teleport at (9,12) has height 2, must be 0 (void) |
| Test_15 | FAIL | R4: Artifact 'random_color_book_page_collection' at (1; R5: Teleport at (3,0) has height 1, must be 0 (void); R5: Teleport at (7,12) has height 1, must be 0 (void) |
| Test_16 | FAIL | R3: Teleport at (2,0) is NOT reachable from spawn; R3: Teleport at (7,12) is NOT reachable from spawn; R3: Teleport at (8,12) is NOT reachable from spawn; R3: Teleport at (9,12) is NOT reachable from spawn; R4: Artifact 'pathfinding_visualization' at (5,6) h=4 ; R4: Artifact 'network_analysis' at (2,11) h=7 unreacha; R5: Teleport at (2,0) has height 9, must be 0 (void); R5: Teleport at (7,12) has height 2, must be 0 (void); R5: Teleport at (8,12) has height 2, must be 0 (void); R5: Teleport at (9,12) has height 2, must be 0 (void) |
| Test_Scene_1 | FAIL | R3: Teleport at (7,12) is NOT reachable from spawn; R5: Teleport at (0,1) has height 1, must be 0 (void); R5: Teleport at (7,12) has height 2, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| Test_Scene_2 | FAIL | R3: Teleport at (7,12) is NOT reachable from spawn; R5: Teleport at (7,12) has height 2, must be 0 (void); R5: Teleport at (8,12) has height 1, must be 0 (void); R5: Teleport at (9,12) has height 1, must be 0 (void) |
| test_cctv | FAIL | R5: Teleport at (3,6) has height 1, must be 0 (void) |
| test_gridagent | FAIL | R5: Teleport at (8,7) has height 1, must be 0 (void) |
| test_gridagent_algogun | FAIL | R5: Teleport at (10,9) has height 1, must be 0 (void) |
| Test_Substrates | FAIL | R5: Teleport at (5,10) has height 1, must be 0 (void) |

### Fix Instructions

**Test_1**
  Manual: Artifact 'ChengSimulationScaled' at (5,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Test_2**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_2`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'closest_pair' at (5,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (9,11) — no structure row at z=12 to catch player
  Note: Map has 2 teleports ((1,1), (9,11)) — normal case is 1

**Test_3**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_3`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'distance_fields_sdf' at (3,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (7,12) — no structure row at z=13 to catch player
  Note: Teleport at (8,12) — no structure row at z=13 to catch player
  Note: Teleport at (9,12) — no structure row at z=13 to catch player
  Note: Map has 4 teleports ((1,1), (7,12), (8,12), (9,12)) — normal case is 1

**Test_4**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_4`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'pathfinding3d' at (5,6) h=4 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 4 teleports ((3,0), (7,12), (8,12), (9,12)) — normal case is 1

**Test_5**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_5`
  Manual: Artifact 'random_color_book_page_collection' at (1,11) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 4 teleports ((3,0), (7,12), (8,12), (9,12)) — normal case is 1

**Test_6**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_6`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'pathfinding_visualization' at (5,6) h=4 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'network_analysis' at (2,11) h=7 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 4 teleports ((2,0), (7,12), (8,12), (9,12)) — normal case is 1

**Test_7**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_7`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'random_plants' at (3,7) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**Test_8**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_8`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'random_plants' at (3,7) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**Test_9**
  Manual: Artifact 'graphspace' at (5,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Test_10**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_10`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'graphspace3d' at (5,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'KonigsbergBridge' at (5,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (9,11) — no structure row at z=12 to catch player
  Note: Map has 2 teleports ((1,1), (9,11)) — normal case is 1

**Test_11**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_11`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'graphspace' at (3,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Teleport at (7,12) — no structure row at z=13 to catch player
  Note: Teleport at (8,12) — no structure row at z=13 to catch player
  Note: Teleport at (9,12) — no structure row at z=13 to catch player
  Note: Map has 4 teleports ((1,1), (7,12), (8,12), (9,12)) — normal case is 1

**Test_12**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_12`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'pathfinding3d' at (5,6) h=4 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 4 teleports ((3,0), (7,12), (8,12), (9,12)) — normal case is 1

**Test_13**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_13`
  Manual: Artifact 'random_color_book_page_collection' at (1,11) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 4 teleports ((3,0), (7,12), (8,12), (9,12)) — normal case is 1

**Test_14**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_14`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'pathfinding_visualization' at (5,6) h=4 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'network_analysis' at (2,11) h=7 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 4 teleports ((2,0), (7,12), (8,12), (9,12)) — normal case is 1

**Test_15**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_15`
  Manual: Artifact 'random_color_book_page_collection' at (1,11) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 4 teleports ((3,0), (7,12), (8,12), (9,12)) — normal case is 1

**Test_16**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_16`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'pathfinding_visualization' at (5,6) h=4 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'network_analysis' at (2,11) h=7 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Note: Map has 4 teleports ((2,0), (7,12), (8,12), (9,12)) — normal case is 1

**Test_Scene_1**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_Scene_1`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Note: Teleport at (7,12) — no structure row at z=13 to catch player
  Note: Teleport at (8,12) — no structure row at z=13 to catch player
  Note: Teleport at (9,12) — no structure row at z=13 to catch player
  Note: Map has 4 teleports ((0,1), (7,12), (8,12), (9,12)) — normal case is 1

**Test_Scene_2**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_Scene_2`
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Note: Teleport at (7,12) — no structure row at z=13 to catch player
  Note: Teleport at (8,12) — no structure row at z=13 to catch player
  Note: Teleport at (9,12) — no structure row at z=13 to catch player
  Note: Map has 3 teleports ((7,12), (8,12), (9,12)) — normal case is 1

**test_cctv**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix test_cctv`
  Note: Teleport at (3,6) — no structure row at z=7 to catch player

**test_gridagent**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix test_gridagent`

**test_gridagent_algogun**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix test_gridagent_algogun`

**Test_Substrates**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Test_Substrates`
  Note: Teleport at (5,10) — no structure row at z=11 to catch player

## transformation — "Transformation: What Stays the Same When Everything Changes" (6 maps: 2 OK, 4 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Trans_Intro | FAIL | R3: Teleport at (5,14) is NOT reachable from spawn; R4: Artifact 'balance_puzzle' at (5,10) h=2 unreachabl; R4: Artifact 'dark_sphere' at (5,14) h=0 unreachable [ |
| Trans_Translate_1 | FAIL | R4: Artifact 'player_trace' at (0,0) h=1 unreachable; R4: Artifact 'z_translation_cube' at (6,2) h=0 unreach; R4: Artifact 'pick_up_cube' at (5,3) h=0 unreachable [; R4: Artifact 'dark_sphere' at (3,10) h=1 unreachable; R4: Artifact 'y_translation_cube' at (1,11) h=1 unreac; R4: Artifact 'pick_up_cube' at (2,12) h=3 unreachable; R4: Artifact 'pick_up_cube' at (4,12) h=2 unreachable |
| Trans_Translate_2 | FAIL | R3: Teleport at (7,8) is NOT reachable from spawn; R4: Artifact 'toruscylinder' at (5,2) h=0 unreachable ; R4: Artifact 'z_translation_cube' at (0,5) h=0 unreach; R4: Artifact 'dark_sphere' at (3,6) h=0 unreachable [o; R4: Artifact 'x_translation_cube' at (2,8) h=1 unreach; R4: Artifact 'pickup_gate' at (6,9) h=1 unreachable; R4: Artifact 'translation_cube_demo' at (1,11) h=1 unr; R4: Artifact 'cube_scene' at (0,12) h=1 unreachable; R4: Artifact 'cube_scene' at (1,12) h=1 unreachable; R4: Artifact 'cube_scene' at (2,12) h=1 unreachable; R4: Artifact 'cube_scene' at (0,13) h=1 unreachable; R4: Artifact 'cube_scene' at (2,13) h=1 unreachable; R4: Artifact 'cube_scene' at (0,14) h=1 unreachable; R4: Artifact 'cube_scene' at (2,14) h=1 unreachable; R4: Artifact 'cube_scene' at (0,15) h=1 unreachable; R4: Artifact 'pick_up_cube' at (1,15) h=5 unreachable; R4: Artifact 'cube_scene' at (2,15) h=1 unreachable |
| Trans_Rotation_1 | OK |  |
| Trans_Rotation_2 | FAIL | R4: Artifact 'dark_sphere' at (3,6) h=0 unreachable [o; R4: Artifact 'pick_up_cube' at (2,51) h=0 unreachable ; R4: Artifact 'carousel_cake' at (3,53) h=0 unreachable |
| Trans_Scale | OK |  |

### Fix Instructions

**Trans_Intro**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'balance_puzzle' at (5,10) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (5,14) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Trans_Translate_1**
  Manual: Artifact 'player_trace' at (0,0) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'z_translation_cube' at (6,2) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'pick_up_cube' at (5,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (3,10) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'y_translation_cube' at (1,11) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'pick_up_cube' at (2,12) h=3 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'pick_up_cube' at (4,12) h=2 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**Trans_Translate_2**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'toruscylinder' at (5,2) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'z_translation_cube' at (0,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (3,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'x_translation_cube' at (2,8) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'pickup_gate' at (6,9) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'translation_cube_demo' at (1,11) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_scene' at (0,12) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_scene' at (1,12) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_scene' at (2,12) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_scene' at (0,13) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_scene' at (2,13) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_scene' at (0,14) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_scene' at (2,14) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_scene' at (0,15) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'pick_up_cube' at (1,15) h=5 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'cube_scene' at (2,15) h=1 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**Trans_Rotation_2**
  Manual: Artifact 'dark_sphere' at (3,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'pick_up_cube' at (2,51) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'carousel_cake' at (3,53) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

## unused — "Unused" (23 maps: 14 OK, 9 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| Dialectic_Automation | OK |  |
| Directionality_Examples | FAIL | R5: Teleport at (12,24) has height 1, must be 0 (void) |
| One_Adapt_1 | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| One_Adapt_2 | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| One_Adapt_3 | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| One_Adapt_4 | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| One_Adapt_5 | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| One_Adapt_6 | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| One_Adapt_7 | FAIL | R5: Teleport at (5,6) has height 1, must be 0 (void) |
| oscillation_1 | OK |  |
| oscillation_2 | OK |  |
| oscillation_3 | OK |  |
| oscillation_4 | OK |  |
| oscillation_5 | OK |  |
| oscillation_6 | OK |  |
| oscillation_7 | OK |  |
| Pattern_Generation_One | OK |  |
| Pattern_Generation_Two | OK |  |
| Pattern_Generation_Three | FAIL | R5: Teleport at (11,11) has height 1, must be 0 (void) |
| Pattern_Generation_Four | OK |  |
| Pattern_Generation_Six | OK |  |
| Pattern_Generation_Seven | OK |  |
| Primitives_2 | OK |  |

### Fix Instructions

**Directionality_Examples**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Directionality_Examples`
  Note: Teleport at (12,24) — no structure row at z=25 to catch player

**One_Adapt_1**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix One_Adapt_1`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**One_Adapt_2**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix One_Adapt_2`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**One_Adapt_3**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix One_Adapt_3`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**One_Adapt_4**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix One_Adapt_4`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**One_Adapt_5**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix One_Adapt_5`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**One_Adapt_6**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix One_Adapt_6`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**One_Adapt_7**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix One_Adapt_7`
  Note: Teleport at (5,6) — no structure row at z=7 to catch player

**Pattern_Generation_Three**
Auto-fix (Rule 5):
  `python tools/map_pathfinder.py fix Pattern_Generation_Three`
  Note: Map has 3 teleports ((11,10), (11,11), (9,12)) — normal case is 1

## vectors — "Vectors: Direction + Magnitude = Everything (MERGED INTO FORCES)" (0 maps: 0 OK, 0 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|

## wavefunctions — "Wavefunctions: Everything Oscillates" (12 maps: 4 OK, 8 fail, 0 missing)

| Map | Status | Issues |
|-----|--------|--------|
| WaveFunctions_Intro | OK |  |
| WaveFunctions_Pendulum | OK |  |
| WaveFunctions_Sine_Space | FAIL | R3: Teleport at (10,26) is NOT reachable from spawn; R4: Artifact 'colorballs' at (5,7) h=0 unreachable [on; R4: Artifact 'colorballs' at (5,12) h=0 unreachable [o; R4: Artifact 'dark_sphere' at (5,13) h=0 unreachable [; R4: Artifact 'sine_space' at (5,15) h=0 unreachable [o; R4: Artifact 'colorballs' at (5,17) h=0 unreachable [o |
| WaveFunctions_Unit_Circle | FAIL | R4: Artifact 'unit_circle_advanced' at (6,3) h=0 unrea; R4: Artifact 'colorballs' at (5,6) h=0 unreachable [on; R4: Artifact 'dark_sphere' at (6,13) h=0 unreachable [ |
| WaveFunctions_3D_Wave_Propagation | FAIL | R3: Teleport at (13,16) is NOT reachable from spawn; R4: Artifact 'dark_sphere' at (5,4) h=0 unreachable [o; R4: Artifact 'kusama_sine' at (5,6) h=0 unreachable [o; R4: Artifact 'wave_propagation_3d' at (7,8) h=0 unreac |
| WaveFunctions_Effect_Sound | OK |  |
| Wavefunctions_Bernini | OK |  |
| WaveFunctions_John_Cage | FAIL | R4: Artifact 'ruth_asawa_sculpture' at (6,6) h=0 unrea; R4: Artifact 'dark_sphere' at (5,7) h=0 unreachable [o |
| WaveFunctions_AirMusic | FAIL | R4: Artifact 'dark_sphere' at (4,4) h=0 unreachable [o; R4: Artifact 'SystemsMusicTest' at (5,5) h=0 unreachab |
| Wavefunctions_Sky_Stairs | FAIL | R4: Artifact 'math_objects' at (6,11) h=8 unreachable |
| WaveFunctions_TrigWalkingPath | FAIL | R3: Teleport at (10,2) is NOT reachable from spawn; R4: Artifact 'TrigWalkingPath' at (6,3) h=0 unreachabl; R4: Artifact 'dark_sphere' at (4,7) h=0 unreachable [o |
| WaveFunctions_Synthesis_Lab | FAIL | R4: Artifact 'SoundscapeRadioRack' at (2,11) h=4 unrea |

### Fix Instructions

**WaveFunctions_Sine_Space**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'colorballs' at (5,7) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'colorballs' at (5,12) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (5,13) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'sine_space' at (5,15) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'colorballs' at (5,17) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**WaveFunctions_Unit_Circle**
  Manual: Artifact 'unit_circle_advanced' at (6,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'colorballs' at (5,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (6,13) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**WaveFunctions_3D_Wave_Propagation**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'dark_sphere' at (5,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'kusama_sine' at (5,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'wave_propagation_3d' at (7,8) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**WaveFunctions_John_Cage**
  Manual: Artifact 'ruth_asawa_sculpture' at (6,6) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (5,7) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**WaveFunctions_AirMusic**
  Manual: Artifact 'dark_sphere' at (4,4) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'SystemsMusicTest' at (5,5) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**Wavefunctions_Sky_Stairs**
  Manual: Artifact 'math_objects' at (6,11) h=8 unreachable — add wp/tc/br to connect, or move artifact to reachable cell

**WaveFunctions_TrigWalkingPath**
  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge
  Manual: Artifact 'TrigWalkingPath' at (6,3) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell
  Manual: Artifact 'dark_sphere' at (4,7) h=0 unreachable [on VOID] — add wp/tc/br to connect, or move artifact to reachable cell

**WaveFunctions_Synthesis_Lab**
  Manual: Artifact 'SoundscapeRadioRack' at (2,11) h=4 unreachable — add wp/tc/br to connect, or move artifact to reachable cell
