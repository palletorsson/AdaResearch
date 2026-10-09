# Keep what the student made

*Possible student objects across the 25 sequences · 5 October 2026*

The best default is **one manageable object, or a small family of objects, developed through several halls**. A new room should give the student another meaningful use for something they can already make. Some rooms can be places to compare, compose or reflect without adding another programming construction.

This is a proposal for choosing tutorial objects. The museum already contains a much wider collection. The list does not require removing those works or making every artifact part of the tutorial. It does not change the spine, current learning subjects, `tutorial.md`, `final.md` or game code.

Our strongest completed example is the tested student code from Point One through Coordinates, Lines and Trace. Point Zero has its own complete counter study. Grid and the longer object journeys proposed here still need their own exact continuations and runtime evidence. Many existing tutorials are source studies or older drafts, not these proposed student programs.

**Keep the object while it helps the learner notice the new operation. Branch when keeping it would require machinery unrelated to the lesson.** A point can be held and recorded. The resulting position list can have grid addresses. A triangle needs an explicit selection of three valid corners and a face construction; it is not obtained simply by renaming the trace. A column generator is another object built with the capacity to generate and connect positions.

## Name what continues

There are three useful forms of continuity:

- **Code:** keep the existing construction and add a capability. Coordinates gives the point its pickup behaviour. This does not by itself mean the same runtime instance survives loading another hall.
- **Data:** preserve something the student made and give it another use. Grid can derive snapped positions from their own trace without altering its source.
- **Operation:** apply a known function or rule to another material. A motif can return on a wall and on a garment, with the change of coordinates and receiver explained.

A shared appearance or name is not enough. At every handoff, ask: **what exactly has the student kept?** Name the file, record or function, its frame and lifetime where relevant, and the new construction that receives it.

## Choose the smallest useful next change

For each hall, decide whether it **continues**, **derives**, **branches**, **composes** or **inspects** the student's work. These are planning labels, not a required architecture or a fixed order.

Continue the point with pickup. Derive a snapped drawing from its record. Branch into a face-building study. Compose learned forms in Melencolia. Inspect two results without adding an artificial coding task. The reflective text can carry a transition while the tutorial pauses or consolidates.

Before writing code, fill in this short card:

```text
OBJECT: what the student can point to, use or retain.
BRING: exact earlier code, data or operation.
CHANGE: the new capability selected for this hall.
KEEP: what survives; state frame/lifetime where relevant.
CHECK: what should remain true; what new result should occur.
DEFER: nearby complexity that belongs elsewhere.
```

Then use the [reconstruction rules](../2026-10-05-the-tutorial-must-run/rules.html): print and explain the complete small result, run the printed code, test the handoff and behaviour, and require a relevant broken version to fail. A real student still has to show what they can explain and make independently.

This should not become one giant script or a universal artifact base class. A saved working version can become the predecessor of a clean small continuation. Shared helpers need declared inputs and outputs. New data representations need an explained conversion. A parameter edit should reveal a useful distinction, rather than merely fill another hall.

## Four journeys worth keeping in view

**Point → held point → line → trace → addressed drawing.** This is the immediate line to complete. Continue the actual dot and preserve the student's particular drawing.

**Cell board → authored motif → palette → patterned surface or garment.** Addressing, values, colour and sampling become separate choices. A musical score is a related use of indexing, with its own value meanings.

**Moving point → retained velocity → restoring force → oscillator → signal.** Use known position and trace tools while changing the rule of motion. Distinguish a prescribed path from a simulated response.

**Line → branching construction → rewritten sentence → interpreted tree or passage.** Keep the renderer or path records where useful; explain the shift from recursive geometry to symbolic rewriting.

These cross-sequence journeys carry selected operations and records. They do not replace the live spine or imply automatic transport among existing exhibits.

## Where several objects are better

Form Finding needs a search marker, constrained chain and balanced mobile because their ways of arriving at a result differ. Machine Learning needs explicit model branches; a fitted value, clustering procedure, filter and memory are not interchangeable. Foundations Crisis is best treated as a cabinet of small claim-testing constructions, each with its own assumptions. Reflection supplies their relationship without forcing one physical mechanism through all of them.

The useful unit is therefore **an object with a developing purpose**, not necessarily one object per map or exactly one per sequence. It should become something the student can use in their own work. The map-by-map teaching choice remains open to revision.


---

## 1. Primitives: Points Build Worlds

**Possible object:** A point, its trace, and a family of constructed forms

Point → held point → endpoints → retained trace → grid addresses. Then choose corners for a face, connect faces into bodies, and generate forms from profiles.

**What continues:** Point code and segment helper; then position data, face connectivity and a profile function. These are explicit branches, not one unchanged node.

**Where to branch:** Keep Point Zero’s counter as a timing instrument. Triangle selects valid corners rather than claiming any trace automatically becomes a face. Tetrahedron, cube and generated column need different topology or construction rules.

Selected halls: `Point_One` → `Point_Coordinates` → `Point_Lines` → `Point_Trace` → `Point_Line_Grid` → `Point_Triangle_Context` → `Primitives_Polythedra` → `Primitives_Columns` → `Primitives_Profiles` → `Primitives_Melencolia`

## 2. Transformation: What Stays the Same When Everything Changes

**Possible object:** A block that can become a moving platform or doorway

Give a known body a timed displacement, a pivot, a changing scale and an input-controlled transformation. Compare what its surface and collision permit.

**What continues:** The constructed body and its transform parameters; explicit local/world frames and timing.

**Where to branch:** A study of the visitor’s body is a separate receiver. A visible scaled door does not silently give the player another size or a safe crossing.

Selected halls: `Trans_Introduction` → `Trans_Translation` → `Trans_Rotation` → `Trans_Scale` → `Trans_Body` → `Trans_Pit`

## 3. Arrays and Regularity

**Possible object:** An editable cell board, then a volume of cells

Read and change an addressed cell; extend the arrangement into depth; let values choose tile orientations. A later clock reads an event score.

**What continues:** Addressed storage and explicit read/write operations; reusable geometry for its visible cells.

**Where to branch:** Occupancy, orientation and sound events are different values. The score is a branch using known indexing, not the same dataset renamed.

Selected halls: `Array` → `Tutorial_3D` → `Tutorial_Tiling_Floor` → `Tutorial_Tiling_Walls` → `Tutorial_Disco`

## 4. Color and Composition

**Possible object:** A colour sampler and palette; a separate paint tool

Return a colour from a position, apply it to a named receiver, vary the coordinate rule, and retain chosen colours. Use a spray tool to leave colour on an image.

**What continues:** A colour-returning function, palette values and receiver connections; the painting branch keeps its image state.

**Where to branch:** A light source, surface colour and painted pixel are different mechanisms. Flashlight and Paint deserve small separate builds; Rainbow can offer composition without new compulsory code.

Selected halls: `Color_Flashlight` → `Color_Nails` → `Color_Rainbow` → `Color_Pillar` → `Color_Grid_Pallet` → `Color_Paint` → `Color_Walls`

## 5. Patterns: Dress the Architecture

**Possible object:** A small motif that can dress a wall or garment

Make and retain a motif, change its repetition and orientation, test a symmetry with an asymmetric mark, then repeat it with UV coordinates.

**What continues:** The source motif, palette and repeat rule as separate named things.

**Where to branch:** A new supporting surface may need a new coordinate mapping. The same motif does not require the same mesh or automatic transfer between museum exhibits.

Selected halls: `Pattern_Foundry` → `Tutorial_Pattern` → `Array_Patterns` → `Symmetry_Seventeen` → `Ribbon_Patterns_01` → `Ribbon_Patterns_03`

## 6. Change: Rate, Accumulation, and Flow

**Possible object:** A curve-measuring instrument and a field-following point

Sample a supplied curve to estimate a rate and an accumulation; then let a field determine successive displacements of a point that leaves a trace.

**What continues:** Sampling functions, declared units and the earlier trace recorder.

**Where to branch:** The field follower has a different input from the curve instrument. A sampled picture is not automatically a differentiable function.

Selected halls: `Change_Intro` → `Flow_Field`

## 7. Vectors & Forces: From Direction to Dynamics

**Possible object:** A moving puck with retained velocity and a trail

Give it a launch, keep velocity between updates, apply acceleration, add restoration and damping, then compare fields acting on it.

**What continues:** Position, velocity, acceleration and a clear update rule; keep the path for comparison.

**Where to branch:** An analytic projectile, an engine rigid body and the visitor’s movement use different update mechanisms. Support, legs and targeting can remain selected side studies.

Selected halls: `VFM_05_Launch` → `VFM_03_Motion` → `Vectors_Act3_FieldsAndMotion` → `Vectors_Act4a_KineticForces` → `Vectors_Act4b_Oscillation` → `Vectors_Act5_ForceAsPlace`

## 8. Form Finding: Rules, Constraints and Possible Shapes

**Possible object:** A search marker, a constrained chain, and a balanced mobile

Move a candidate towards a better value; compare an evaluated hanging curve with iterative constraint correction; explore balance and occasional uphill proposals.

**What continues:** A candidate description, criterion, update rule and stopping condition, made explicit for each construction.

**Where to branch:** These are companion studies. Gradient search, catenary evaluation, relaxation and mechanical equilibrium should not masquerade as one solver.

Selected halls: `FormFinding_Descent` → `FormFinding_Catenary` → `FormFinding_Relaxation` → `FormFinding_Equilibrium` → `FormFinding_Annealing` → `FormFinding_Forge`

## 9. Wavefunctions: What Returns

**Possible object:** An oscillator and a visible record of its signal

Control amplitude, frequency and phase; show a cycle as position or height; compare a computed swing, coupled neighbours and a sum of components.

**What continues:** Oscillator parameters, a sampling convention and retained signal values where needed.

**Where to branch:** A prescribed sine, a physical pendulum, a propagating wave and an audio event are related studies with distinct state and time scales.

Selected halls: `WaveFunctions_Intro` → `WaveFunctions_Pendulum` → `WaveFunctions_Sine_Space` → `WaveFunctions_Unit_Circle` → `WaveFunctions_3D_Wave_Propagation` → `WaveFunctions_Synthesis_Lab`

## 10. Randomness: What Can Chance Change?

**Possible object:** A seeded composition board, with a walking-point branch

Record reproducible choices; use them to remove, orient or place elements. Let a moving point accumulate chosen steps, then compare distributions and feedback.

**What continues:** Seed plus procedure, retained samples and the earlier point/trace tools.

**Where to branch:** A seed alone cannot preserve a result if the procedure changes. An independent choice per cell and an accumulated walk need different state.

Selected halls: `Random_Definition` → `Random_Remove` → `Randomness_10_PRINT_Algorithm` → `Random_Cubes` → `Random_Walk` → `Random_Gaussian` → `Random_Pheromone`

## 11. Noise: Fields and Possible Bodies

**Possible object:** A sampled field made into a relief tile

Sample a field, then use its values for heights, colours, thresholds and displaced surfaces. Compare its effect on another receiving body.

**What continues:** Field settings, sampling coordinates and a saved sample grid where comparison requires one.

**Where to branch:** A volume needs three-dimensional samples; a flat image does not already contain them. Surface displacement does not automatically change collision.

Selected halls: `Random_Noise_Types` → `Noise_Columns` → `Noise_One` → `Noise_Voxel` → `Noise_6_Wall` → `Noise_Inside_Noise` → `Lab_Path`

## 12. Shaders: What a Surface Answers To

**Possible object:** A material with an authored shape motif

Build a shape from coordinates, transform and repeat it, put the material on familiar forms, then distort and layer it.

**What continues:** A shape function, material parameters and declared coordinate conventions.

**Where to branch:** Reaction–diffusion adds retained image state and a repeated update. It should branch from the stateless material rather than hide feedback inside an unexplained shader.

Selected halls: `Shader_01_Shaping` → `Shader_05_Patterns` → `Shader_11_QueerRubber` → `Shader_09_FBM` → `Shader_12_PinkExtravaganza` → `Shader_10_ReactionDiffusion`

## 13. Cellular Automata: Local Rules, Global Patterns

**Possible object:** A cell board with a present and a next state

Choose a local rule, update cells from a separate current state, retain history, then compare other neighbourhoods, state values and inputs.

**What continues:** Current/next storage, neighbourhood lookup and a visible history of rule applications.

**Where to branch:** A row, sheet and volume require explicit changes of indexing and neighbours. Check the actual artifacts: some existing hall names do not name the rule or dimension currently inside.

Selected halls: `CA_Introduction` → `CA_ElementaryRules` → `CA_GameOfLife` → `CA_BeyondBinary` → `CA_SoftRules` → `CA_AgentsCircuits` → `CA_EdgeOfChaos`

## 14. Fractals: Rules, Scale and Room to Move

**Possible object:** A recursive line sculpture

Let a construction call itself with a stopping condition; branch it, retain intervals or replace segments; compare depth and resource budget.

**What continues:** A construction function, its parameters, stopping rule and selected geometry.

**Where to branch:** A subdivided solid and a numerical recurrence are separate studies. Their shared repetition does not make their data or algorithms identical.

Selected halls: `Fractal_Recursion` → `Fractal_RecursiveTrees` → `Fractal_CantorSet` → `Fractal_KochSierpinski` → `Fractal_MengerSponge` → `Fractal_GoldenSpiral` → `Fractal_Synthesis`

## 15. L-Systems: Rules Grow Structure

**Possible object:** A sentence that grows into a tree or passage

Rewrite symbols, interpret them as movement, add a stack for branches, then give the same grammar another drawing vocabulary or growth condition.

**What continues:** Axiom, production rules, resulting sentence and interpreter configuration, kept separate.

**Where to branch:** Changing the interpreter can make architecture from a grammar. Shape grammar and assembly need their own explicit matching rules; they are not automatically the same turtle.

Selected halls: `LSystems_Grammar_Lab` → `LSystems_Growth` → `LSystems_Grammars_And_Curves` → `LSystems_Architecture` → `LSystems_Competition` → `LSystems_Shape_Grammars` → `Assemblage_Same_Desire`

## 16. Procedural Generation: Rules Build Worlds

**Possible object:** A growth skeleton and a carved passage system

Describe and score candidates; grow branches towards targets; inspect connectivity; then carve a small traversable layout and sample its surfaces.

**What continues:** Generator recipes and selected outputs; an explicit conversion where a branch skeleton informs a volume.

**Where to branch:** Optimisation, space colonisation and cave carving are different generators. Teach or supply the small adjacency operation needed here before the later full Graph sequence.

Selected halls: `PG_Genetic_Evolution` → `PG_Space_Colonization` → `PG_Branching_Growth` → `PG_Percolation_Network` → `PG_Caves_Mazes` → `PG_Sculpted_Forms`

## 17. Soft Bodies & Morphogenesis: Matter That Finds Its Shape

**Possible object:** A pinned sheet that becomes a moving fabric study

Give a mesh constraints, choose its pinned points, drive its support, encounter obstacles and retain a deformed pose.

**What continues:** Mesh connectivity, attachment choices and the explicitly supplied or taught deformation model.

**Where to branch:** A deforming shader is not a physical solver. Reaction–diffusion and topology studies remain separate objects; a single cloth should not pretend to cover them all.

Selected halls: `SoftBodies_Soft_Body_Deformation` → `SoftBodies_Cloth_Physics` → `SoftBodies_Carusell` → `SoftBodies_Obsticals` → `SoftBodies_Playground_of_Joy` → `ProceduralGeneration_Reaction_Diffusion_Systems` → `Topology_Entropy_Morphogenesis`

## 18. Isosurfaces: Implicit to Explicit

**Possible object:** A scalar-field sculpture that can become a cave

Sample a field and extract a boundary; compose fields, edit them, excavate terrain and compare a moving field with its resulting surface.

**What continues:** Field recipe, threshold, sample spacing and ordered edits; the extractor stays named support where it is not the lesson.

**Where to branch:** A field value, extracted mesh and traversable collision body are separate results. Larger terrain and rhizome bodies may branch from the same small field vocabulary.

Selected halls: `ISO_Introduction` → `ISO_LookupTable` → `ISO_ShapesGallery` → `ISO_Sculpting` → `ISO_FlatTerrain` → `ISO_Caves` → `ISO_Metaballs` → `ISO_RhizomeBody`

## 19. Boolean Surfaces: CSG as Composition

**Possible object:** A solid block and a reusable cutting body

Union, subtract or intersect two solids; keep alternatives; then grow the subtraction into a cavity, tunnel or room that a visitor can enter.

**What continues:** Operand geometry, operation order, transforms and an authored construction recipe.

**Where to branch:** A hollow in a mesh does not guarantee a walkable entrance or suitable collision. Spatial access becomes an explicit test.

Selected halls: `Boolean_Verbs` → `Boolean_Gallery` → `Boolean_Works`

## 20. Swarm Intelligence: Where Coordination Lives

**Possible object:** A colony of simple moving agents

Follow a shared field, respond to neighbours, change a state, or retain a route or best position. Compare where each system keeps its information.

**What continues:** A small agent update interface and clearly separated shared records, neighbour data and private memory.

**Where to branch:** Trail deposition, boids, ant routes and particle-swarm optimisation need distinct branches. One generic steering formula cannot account for them all.

Selected halls: `SwarmIntelligence_PhysarumColony` → `SwarmIntelligence_FlowFields` → `SwarmIntelligence_Boids_Algorithm` → `SwarmIntelligence_Agent_Based_Modeling_ABM` → `SwarmIntelligence_Ant_Colony_Optimization` → `SwarmIntelligence_Particle_Swarm_Optimization`

## 21. Machine Learning: What Changes, and Why?

**Possible object:** A scored moving creature, then a small prediction instrument

Retain trials of a movement recipe; fit a parameter to observations; assign points to centres and update those centres; keep weights separate from activations.

**What continues:** Dataset, parameters, objective and evaluation results, each versioned separately.

**Where to branch:** Evolution, clustering, classification, image filtering and memory are different constructions. Select modest genuine learning tasks; the existing staged generative exhibit does not establish trained generative learning.

Selected halls: `ML_Evolution` → `ML_Gradient_Landscape` → `ML_Classification` → `ML_Neural_Networks` → `ML_Perception` → `ML_Sequence_Memory` → `ML_Generative` → `ML_Synthesis`

## 22. Graph Theory: What Connections Permit

**Possible object:** An editable network of places and connections

Build vertices and edges, redraw without changing connections, find paths, inspect components, select a spanning tree, then add capacities or matching constraints.

**What continues:** Stable vertex identities and edges; positions are a drawing of the network. Later tasks explicitly add weights, capacities or partitions.

**Where to branch:** A directed flow network and a matching problem need additional schema and different questions; do not merely recolour a path and call it a new algorithm.

Selected halls: `GT_Foundations` → `GT_Layout` → `GT_Pathfinding` → `GT_Network_Analysis` → `GT_Connectivity` → `GT_Spanning_Trees` → `GT_Flow` → `GT_Matching`

## 23. Foundations Crisis: The Limits of Formalization

**Possible object:** A collection of small instruments for testing a claim

Compare geometric assumptions, examine bounded collections and proof steps, and distinguish a coherent view from a physically possible construction.

**What continues:** Explicit assumptions, bounded examples, observations and the limits of each check.

**Where to branch:** No single object is recommended. Geometry, paradox, proof and contradiction deserve distinct encounters. A finite demonstration must not claim to prove a general theorem about formal systems.

Selected halls: `Euclid_Parallel` → `NonEuclidean_Spaces` → `Russell_Paradox` → `Godel_Incompleteness` → `Escher_Impossible` → `Brouwer_Intuitionism` → `Florensky_Paraconsistent` → `Crisis_Synthesis`

## 24. QFEP Laboratory: The Formula Made Interactive

**Possible object:** A responsive lamp or body, accompanied by saved trial cards

Keep contributions beside a total; build a bounded predictor or possibility tree; name an interval of change; then connect a chosen input to the supplied body's response.

**What continues:** Named inputs, operations, contributions and revisions. A comparison record can unite the experiments without equating their meanings.

**Where to branch:** The project's terms require operational definitions for each experiment. A score does not establish an ethical judgement or validate the whole QFEP framework. The controlled body joins selected experiments; it need not appear in every hall.

Selected halls: `QFEP_Introduction` → `QFEP_F_Term` → `QFEP_E_Term` → `QFEP_Lambda_Spectrum` → `QFEP_Phi_Term` → `QFEP_Sandbox` → `QFEP_Synthesis`

## 25. Post-Crisis: Applied Limits

**Possible object:** A revisable shared room and a record of its changes

Inspect exclusions, preserve disagreement and provenance, alter a walkable relation, then bring an assembly and its recorded choices into the closing room.

**What continues:** Selected constructions, contributors, choices and revisable connections. The record explains what changed and what was kept.

**Where to branch:** The early ethical and situated-computation studies need their own bounded objects. Rhizome, assembly and return form the strongest spatial continuation; simulation does not replace social participation.

Selected halls: `CriticalAlgorithms_Algorithmic_Bias_Visualization` → `CriticalAlgorithms_Applied_Ethics` → `SpeculativeComputation_Situated_Computation` → `SpeculativeComputation_Collective_Knowledge` → `SpeculativeComputation_Rhizome_Network` → `AdvancedLaboratory_Lab_Equipment_Simulation` → `PostCrisis_Synthesis`
