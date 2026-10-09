# What can a generator make room for?

Pedagogical proposal · 14 September 2026 · based on the existing maps and their source code. The museum route and artifact roles have not been changed by this review.

The sequence has strong material, but its current order and descriptions do not yet make the learning cumulative enough. The reader already knows arrays, transformations, randomness, fields, cellular updates, recursion and grammars. Procedural generation should bring those capabilities into a question: **how do we construct a world whose possibilities we can examine and change?**

Genetic Evolution can remain the opening. It follows the editable descriptions in L-systems and adds evaluation and selection. This is not the visitor's first encounter with generation; it is the moment we ask which generated forms a criterion allows to continue.

## The proposed walk

**Select → guide → branch → connect → inhabit → materialize → compose.**

These are successive additions to the visitor's toolbox, not a claim that every algorithm is a more advanced version of the preceding one. A later room should reuse something we can now understand, while exposing a new choice.

| Order and hall | What the learner adds | Recommended principal artifacts | Concrete encounter to develop |
|---|---|---|---|
| 1 · [Genetic Evolution](/necklace/thread?map=PG_Genetic_Evolution&role=primary) | Representation → criterion → selection. A rendered body and its numerical score can disagree. | **GeneticProgramming** | HOLD a witness, change TARGET without changing genes, add an uncounted RING, then STEP. This encounter is implemented and desktop-tested. |
| 2 · [Space Colonization](/necklace/thread?map=PG_Space_Colonization&role=primary) | A distribution of demands guides construction. Positions and vector sums become a growth direction. | **space_colonization_algorithm** | Expose one tip, the points assigned to it, their directions and the resulting segment. Begin with a few known points before a large cloud. Show remaining/reached points separately. |
| 3 · [Branching Growth](/necklace/thread?map=PG_Branching_Growth&role=primary) | Change what counts as a local invitation and which growing sites remain active. | **branching_growth_algorithm** | Compare nearest-target growth with the previous accumulated-direction rule over shared points. First suppress jitter/pulsing to isolate the decision; restore them afterwards. Count children at one node so a fork is a structural event, not merely a tree-like silhouette. |
| 4 · [Percolation Network](/necklace/thread?map=PG_Percolation_Network&role=primary) | Local relations become global reachability. Density is not connectivity. | **percolationnetwork_ca** | First compare a face contact with a corner contact. Then follow one source through the larger lattice. Hold samples while changing occupation, and distinguish the flow graph from the player's collision route. |
| 5 · [Caves / Mazes](/necklace/thread?map=PG_Caves_Mazes&role=primary) | A trajectory or graph becomes an interior. A connected route also needs width, headroom and support. | **caverandomwalk + maze_generation** | Keep a visible carving trace beside the void it leaves. Compare the maze's explicit traversal/backtracking with the cave's biased wandering. Test a short full-size passage with the same body in both. |
| 6 · [Sculpted Forms](/necklace/thread?map=PG_Sculpted_Forms&role=primary) | A process can become input to another construction. Sampling and cutting change what survives. | **cube_mound_scene + dome** | Compare the physical pile with the grid/mesh recorded from its centres. Then reveal the dome's cutting volumes: the absent material has an authored shape. Use layered_membrane as a further comparison of many surfaces with apparent thickness. |
| 7 · [Mirrored Patterns](/necklace/thread?map=PG_Mirrored_Patterns&role=primary) | Compose earlier operations, then distinguish a surface relation from a route relation. | **mirror_cellular_texture_for_3d + rhizomatic_maze_space** | Two distinct encounters: hold a cellular fragment while changing its copying arrangement; then hold a network's starting points while comparing tree, loop-capable and severed constructions. Finish by walking a tested route and dressing its surface. |

Only Genetic's new controls and route are accepted runtime work in this proposal. The later actions are development targets grounded in existing code, not controls already verified in the museum.

## Two route changes

The sequence file lists seven halls; the active museum contains six. **Restore Space Colonization after Genetic, then put Branching Growth immediately after it, before Percolation.** This is the recommended order, not an applied migration.

The two growth rules become a direct comparison. Percolation then asks a different question about the resulting relations: what can reach what? Caves/Mazes turns that question into a body's passage. This avoids introducing attraction growth, leaving it for percolation, and returning to a second attraction rule without a clear reason.

Space Colonization exists on disk and in the book but is absent from map_authored and both active museum plans. Restoring it requires the same source/history, floor, control and exit review as the other halls. Its existing work should not disappear merely because the route omitted it.

## What the source review changes

- **Space Colonization does not currently fork a growing tip.** In grow_iteration, each influenced leaf produces one successor, and the new leaves replace the old set. Multiple roots can give several strands, but this operation does not split one into two. I recommend teaching the accumulated direction first, then repairing the growth policy if the hall is to claim a branching space-colonization model. The present manuscript's unqualified fork discussion needs correction before acceptance.
- **Branching Growth is not the fixed-angle recursive tree described by its old summary.** It consults the nearest unreached attractor, adds optional jitter/pulsing, and can keep older branch sites active. Its useful comparison with Space Colonization concerns both the consulted targets and the persistence of growth sites.
- **Percolation uses an 18×18×18 lattice with six face neighbours.** The old summary describes a two-dimensional slider demonstration and quotes a 2D threshold. That is not this implementation. Establish source-to-boundary reachability over specified finite samples; do not present one run or a preset called critical as a measured universal threshold. Occupied white sites have collision while flowing/source/connected sites do not: the signal and the visitor obey different passage rules.
- **organic_space constructs a shell, tunnels and details through geometric operations, with noise and random choices.** It is not the noise-gradient tree described by the Branching summary. Keep it there as a contrasting way to obtain an organic-looking result; revisit its union/subtraction modes beside Sculpted Forms. If a later spatial review supports relocating it, carry its provenance and text along. Do not remove it now.
- **Caves/Mazes already contains three useful works.** The cave has deliberately biased stages; the default maze uses randomized backtracking. A claim that one is undesigned and the other wholly deterministic misses both programs. binary_space_partitioning is a useful third comparison: divide space into rooms/regions. Retain it without making the visitor learn three full generators simultaneously.
- **Sculpted Forms is more specific than a generic stacking gallery.** The mound records a physics state into a voxel surface; dome exposes Boolean cutting. The existing layered_membrane scene points to an obsolete script location, while its script exists under hybrid_complex/layeredmembrane. Repair that reference before treating it as a functioning comparison.
- **The last hall contains two distinct arguments.** Repeating or reflecting an image does not by itself change which tunnels connect. The rhizomatic generator already offers tree/rhizome/severed/plateau configurations; their graph properties and actual collision routes still need verification in this hall. Its name alone does not prove every point is reachable or that a network has no hierarchy.

These findings come from source inspection. They are candidates for the next hall reviews, not new runtime certifications.

## Keep the full collection

The primary label means that the book follows an artifact through a teachable operation. It is not a limit of one artifact per room.

- Genetic: keep science_screen as secondary; its grid view is not yet a genetic monitor.
- Percolation: keep synthesis_stand and dark_sphere in their supporting/staging roles. They need not become another required lesson.
- Branching: keep organic_space and give its contrasting construction an honest description.
- Caves/Mazes: promote maze_generation alongside caverandomwalk when their comparison is implemented; retain binary_space_partitioning as the next optional comparison.
- Sculpted: give cube_mound_scene and dome successive book passages; repair and retain layered_membrane. Promote it too if its layer comparison becomes essential to the encounter.
- Mirrored: let the book follow both the cellular copying artifact and the rhizomatic network, one argument at a time. Retain pattern_tunnel_machine as the bodily application: surface dress can change while the supporting route remains fixed.

Those are proposed promotions. Current role files and book markers remain unchanged until their encounters are developed together.

## The question carried through all seven rooms

**What bodies are possible under this construction, and what must change to make room for another?**

Give the question a different place to land each time: the selected object; the field guiding growth; the sites allowed to branch; the signal crossing a graph; the visitor entering a void; the material boundary; and the network whose paths and dress can be revised.

The critical opening should follow the useful operation. First learn to construct and predict. Then change one condition and discover where that prediction fails, or where something valuable remains outside the model. A useful direction for desire is not always more complexity. We may want a sheltered corner, a wider entrance, a kept rejected specimen, another connection, or permission to stop changing a form.

For precision, compare **geometry** through dimensions, curvature and appearance; compare **topology** through components, connections, loops and openings; compare **access** with a declared body and actual collision. These relations can affect one another, but one picture cannot certify all three. Entropy and computational cost also require stated quantities rather than a judgement that a surface looks complicated.

## A repeatable staging method

Each hall can move from a small legible example, to a controlled comparison, to a spatial application. This can happen within one hall; we do not need to multiply maps.

Use a held state or recorded input where a comparison needs it. Make the current step and stopping reason legible. Show targets before hiding consumed ones; show a trace before presenting only the final solid. Reuse compact controls where they fit, choosing buttons appropriate to the operation rather than forcing every machine into an identical menu.

Audit floor ownership first: museum ground, generated geometry, collision and intentional absence. A zero is not automatically a floor; an inherited hole is not automatically meaningful. Every proposed walk needs an approach and exit as well as an impressive interior. Record generation time, geometry/collision count and visible budgets where they constrain what we can make.

The next concrete decision is this proposed order and the growth-room distinction. With that direction settled, restore and develop Space Colonization as the missing bridge. Its first test should show exactly one vector decision and whether the implementation can produce a fork. Then continue the full first traverse.

## Inspected sources

Map inventories, current roles, book passages and sequence: commons/maps/PG_*/map_data.json; commons/data/artifact_roles.json; commons/maps/sequences/proceduralgeneration.json; commons/data/museum/em_plan.json.

Core operations: SpaceColonizationAlgorithm.gd::grow_iteration/create_root_nodes; branching_growth_algorithm.gd::grow_step; percolationnetwork_ca.gd::update_percolation_automata/create_single_cube_collision; caverandomwalk.gd::_biased_step_towards/_carve_cave; maze_generator_vr.gd::_generation_step; cube_mound.gd::generate_mesh_from_cubes; dome.gd::_apply_facture; organic_space.gd::generate_base_shell; RhizomaticMazeSpace.gd::generate_network_structure and RhizomaticMazeGenerator.gd; mirror_cellular_texture_for_3d.gd and its child automaton; layered_membrane scene/script; pattern_tunnel_machine.gd.
