# What the student can carry

Active book and museum spine; auxiliary sequences indexed as extensions only.

Proposed learning targets, not an assertion that every lesson is delivered. The active walking order is preserved. Each dependency must be taught earlier or supplied explicitly.

## Preparation

Establish a working place and a prepared receiver.

### A place to run (borrow)

Requires: The supplied starting project.

Open, edit, run and stop a supplied scene.

Leave able to make: Change a greeting in the prepared room.

Try elsewhere: Change a different property and find the result.

Supplied: Camera, floor, light and editor setup.

Halls: Before the spine.

### A body and a hand (borrow)

Requires: A place to run.

Use a prepared XR player and controller pickup route.

Leave able to make: A scene in which a supplied object can be held.

Try elsewhere: Take another prepared object in the same scene.

Supplied: XR Tools, controller bindings and Quest deployment; portable starter pending.

Halls: Before the spine.

## Primitives

What must we add before a position can be seen, connected, kept, enclosed and used again; what does each addition allow or leave out?

### Begin once, continue (build)

Requires: A place to run.

Initialise, retain a value and update it.

Leave able to make: A greeting and a changing count.

Try elsewhere: Change the increment without changing the display machinery.

Supplied: Prepared labels; engine scheduling.

Halls: Point_Zero.

### Give a position a body (build)

Requires: Begin once, continue.

Separate a position, its visible surface, collision and illumination.

Leave able to make: A point whose appearance and physical boundary can differ.

Try elsewhere: Change the sphere radius while keeping the boundary, or the reverse.

Supplied: Sphere construction; supplied light and switch. Coordinate reading and pickup follow in their own hall.

Halls: Point_One.

### Hold a point, name its reference (build)

Requires: Give a position a body, A body and a hand.

Use the supplied pickup; read and set X, Y and Z; distinguish local and world positions.

Leave able to make: Two independently positioned markers, ready to become endpoints.

Try elsewhere: Move one marker in a translated parent; explain why the world address changes.

Supplied: Production XR pickable, guides and cards. Portable XR starter is still pending.

Halls: Point_Coordinates.

### Connect and measure (build)

Requires: Hold a point, name its reference, Begin once, continue.

Relate two positions in one reference frame; measure separation.

Leave able to make: A segment that follows two movable endpoints.

Try elsewhere: Connect two different objects and preserve its measurement.

Supplied: Prepared A/B markers, segment.gd cylinder renderer and readout. XR hold remains supplied by the museum.

Halls: Point_Lines.

### Keep movement (build)

Requires: Connect and measure, Begin once, continue.

Introduce an ordered list and a condition for retaining a sample.

Leave able to make: A path made from selected positions.

Try elsewhere: Record a different moving point and compare what is lost.

Supplied: Input receiver and line-strip rendering.

Halls: Point_Trace.

### Choose an address (compare)

Requires: Keep movement.

Separate a measured position from a snapped address.

Leave able to make: A retained path and a snapped comparison.

Try elsewhere: Change spacing while preserving the original trace.

Supplied: Grid drawing and readouts.

Halls: Point_Line_Grid.

### Close edges, give a face (build)

Requires: Connect and measure.

Close three edges between non-collinear points, then add a face and read its vertex order. Snapping and the carried trace return as further comparisons, not requirements for the first face.

Leave able to make: An editable triangular surface with a visible boundary.

Try elsewhere: Move a corner; compare a collapsed triangle with a filled one.

Supplied: Mesh display; the first face needs neither a grid nor the six-corner fan experiment.

Halls: Point_Triangle_Context.

### Let faces enclose a region (build)

Requires: Close edges, give a face.

Join triangular faces into an open corner; add the missing base to close a tetrahedral surface. Separate enclosure from collision and entry.

Leave able to make: An open and a closed surface using the same four non-coplanar positions.

Try elsewhere: Remove a different face; compare the visible opening with the supplied convex collision hull.

Supplied: Preview, face renderer and collision comparison. A single triangle was already a mesh.

Halls: Primitives_Polythedra.

### Keep connections, move a corner (build)

Requires: Let faces enclose a region.

Keep the triangle indices while changing vertex positions; locate the shared diagonal inside a square-looking cube face.

Leave able to make: A cube whose corner can move while its face connections remain.

Try elsewhere: Change a different corner and predict which faces follow; compare with a rigidly folding net.

Supplied: Prepared cube indices and the face renderer already used for the enclosure.

Halls: Point_Animatedcube.

### Reuse a made object (build)

Requires: Keep connections, move a corner.

Distinguish a mesh resource, a reusable scene and its placed instances. Arrange familiar parts without rebuilding them.

Leave able to make: An arrangement of two instances of a supplied box scene.

Try elsewhere: Move one instance while keeping the other in place; then compare changing a shared resource.

Supplied: Box scene, material and pickup component; explain whether edited resources are shared.

Halls: Point_Animatedcube.

### Inspect the prepared form (compare)

Requires: Keep connections, move a corner.

Configure a generated mesh; distinguish a fixed polyhedron from a polygonal approximation of a curved surface.

Leave able to make: A configurable sphere, capsule or ring.

Try elsewhere: Hold size constant while changing its construction density.

Supplied: Godot primitive classes and renderer.

Halls: Primitives_Ignorance.

### Choose where to stop (compare)

Requires: Inspect the prepared form, Connect and measure.

Follow a subdivision rule and compare a finite approximation with a mathematical limit. A tolerance and the last displayed example have different meanings.

Leave able to make: A polygon comparison with a chosen side count and perimeter gap.

Try elsewhere: Choose a positive tolerance; find a member that meets it without claiming exact equality.

Supplied: Circle reference, display and subdivision helper; numerical error analysis can wait.

Halls: Primitives_Portals.

### What geometry promises (reflect)

Requires: Choose where to stop, Reuse a made object.

Recognise familiar operations in an authored arrangement.

Leave able to make: An arrangement whose geometry can be questioned.

Try elsewhere: Change one relation while preserving a recognisable reference.

Supplied: Historical context and existing sculptures.

Halls: Primitives_Melencolia.

## Transformation

What remains the same, and whose passage changes when the form moves?

### Give a form a changing pose (build)

Requires: Keep connections, move a corner, Begin once, continue.

Translate a familiar object; distinguish assignment, interpolation and carrying.

Leave able to make: A moving object with a chosen start and destination.

Try elsewhere: Move another object along the same route with different timing.

Supplied: Pickup base, player transport and safe reset.

Halls: Trans_Pre, Trans_Introduction, Trans_Translation.

### Turn around a reference (build)

Requires: Give a form a changing pose.

Choose a pivot and axis; compare orientation and swept space.

Leave able to make: A rotating form with an observable return.

Try elsewhere: Move the pivot while keeping the angular change.

Supplied: Quaternion and collision machinery until required.

Halls: Trans_Rotation.

### Scale meets a body (compare)

Requires: Give a form a changing pose.

Change size relative to a reference and a receiving body.

Leave able to make: A size comparison that changes possible passage.

Try elsewhere: Change the receiver instead of repeating the same enlargement.

Supplied: Player scaling infrastructure and safe reset.

Halls: Trans_Scale.

### A changing boundary (compare)

Requires: Turn around a reference, Scale meets a body.

Combine transforms, proximity and timing; distinguish restoration from memory.

Leave able to make: A boundary that changes what can pass.

Try elsewhere: Give the same transform a different trigger or return rule.

Supplied: Detection, door and reset components.

Halls: Trans_Body, Trans_Pit.

## Arrays

Does removing an occupant erase its address or change what a body can stand on?

### Keep many addresses (build)

Requires: Give a form a changing pose, Keep movement.

Introduce indexing and loops explicitly; distinguish an address from its occupant.

Leave able to make: A row, plane and volume of independently addressable instances.

Try elsewhere: Remove an occupant without moving the other addresses.

Supplied: Instancing helper and flight enclosure.

Halls: Array, Tutorial_3D.

### A local rule covers a surface (build)

Requires: Keep many addresses, Turn around a reference.

Map a small motif by index; change a rule and one exception separately.

Leave able to make: A small tile study and a larger receiving surface.

Try elsewhere: Move the same rule from floor to wall.

Supplied: Tile geometry and display controls.

Halls: Tutorial_Tiling_Floor, Tutorial_Tiling_Walls.

### Give a pattern time (build)

Requires: A local rule covers a surface, Begin once, continue.

Separate stored pattern, step index and playback clock.

Leave able to make: A monochrome floor with a repeatable temporal pattern.

Try elsewhere: Change timing without changing the stored pattern.

Supplied: Contact input and sound playback.

Halls: Tutorial_Disco.

## Colour

Which part of a colour belongs to a surface, a light, a receiver or a social permission?

### Add an attribute (build)

Requires: Keep many addresses, Inspect the prepared form, Give a form a changing pose.

Attach colour to existing construction without changing its geometry.

Leave able to make: An arrangement whose parts carry chosen colours.

Try elsewhere: Keep poses fixed while regrouping by colour.

Supplied: Materials and neutral scene lighting.

Halls: Color_Context_Placed.

### A colour between things (compare)

Requires: Add an attribute.

Distinguish surface colour, illumination and appearance.

Leave able to make: A white receiver under a changeable light.

Try elsewhere: Change the receiver while keeping the light.

Supplied: Renderer, exposure and material setup.

Halls: Color_Flashlight.

### Navigate a colour choice (build)

Requires: Add an attribute, Give a position a body, Keep many addresses.

Map a gesture or address to channels; distinguish RGB from HSV.

Leave able to make: A palette that selects and recalls a colour.

Try elsewhere: Give the same input range a different channel mapping.

Supplied: Hand receiver and prepared palette display.

Halls: Color_Nails, Color_Rainbow, Color_Pillar, Color_Grid_Pallet.

### Leave colour somewhere (compare)

Requires: Navigate a colour choice, Keep movement.

Separate input, surface contact, persistent mark and visual access.

Leave able to make: A supplied painting surface that retains a chosen mark.

Try elsewhere: Change the receiving surface and ask what can still be reached.

Supplied: Spray, texture storage and transparency implementation.

Halls: Color_Paint, Color_Walls.

## Tiling

How does one local choice become the order surrounding us?

### Author a source, repeat it (build)

Requires: A local rule covers a surface, Navigate a colour choice, Leave colour somewhere.

Separate source motif, palette, index rule and output surface.

Leave able to make: A pattern made from an authored motif.

Try elsewhere: Change only the source, then only its repetition rule.

Supplied: Pattern editor and output preview.

Halls: Pattern_Disco, Pattern_Foundry, Tutorial_Pattern, Array_Patterns.

### Transform the repetition (compare)

Requires: Author a source, repeat it, Turn around a reference.

Compose translations, reflections and glides; follow an address across a repeat.

Leave able to make: A controlled comparison of pattern families.

Try elsewhere: Retain the motif while changing the symmetry rule.

Supplied: Symmetry catalogue, ribbon mesh and viewing controls.

Halls: Symmetry_Seventeen, Ribbon_Patterns_01, Ribbon_Patterns_02, Ribbon_Patterns_03.

## Change

Which interval makes a change visible, and what does accumulation retain?

### Compare change, accumulate (build)

Requires: Connect and measure, Keep movement, Begin once, continue.

Define an independent variable, difference quotient and finite accumulation.

Leave able to make: A small slope and accumulated-area study.

Try elsewhere: Change the sampling interval and compare its effect.

Supplied: Plotting and prepared function receiver.

Halls: Change_Intro.

### A rule at every position (build)

Requires: Compare change, accumulate, Keep many addresses.

Read a vector-valued rule at a position and define how a receiver uses it.

Leave able to make: A path following samples of a field.

Try elsewhere: Feed the same field to another receiving rule.

Supplied: Field display and particle drawing.

Halls: Flow_Field.

## Forces

A force acts on which body, with which memory and resistance?

### Combine contributions (build)

Requires: Connect and measure, A rule at every position.

Add and subtract displacements; introduce projection when needed.

Leave able to make: An endpoint composed from named contributions.

Try elsewhere: Translate the construction without changing its vector relation.

Supplied: Arrow rendering and coordinate guides.

Halls: Vectors_Act1_WhatAVectorIs, VFM_02_Operations, Vectors_Act2_VectorArithmetic.

### Let state carry motion (build)

Requires: Combine contributions, Compare change, accumulate, Begin once, continue.

Separate position, velocity and acceleration; identify the time step.

Leave able to make: A moving body whose previous velocity matters.

Try elsewhere: Apply equal commands to bodies with different stored velocities.

Supplied: Physics engine or a clearly identified integration helper.

Halls: VFM_05_Launch, VFM_03_Motion.

### A law and its receiver (compare)

Requires: Let state carry motion, A rule at every position.

Relate force, restoring response, drag, mass and support to a particular receiver.

Leave able to make: A small force study with a held reference condition.

Try elsewhere: Apply one field to two differently configured bodies.

Supplied: Collision solver, contact and support instruments.

Halls: Vectors_Act3_FieldsAndMotion, Vectors_Act4a_KineticForces, Vectors_Act4b_Oscillation, Change_Choreography, VFM_07_Gravity, VFM_09_Legs, VFM_08_Arena, Vectors_Act5_ForceAsPlace.

## Form Finding

Who chose the criterion under which this form appears to have found its place?

### Follow a criterion (build)

Requires: Compare change, accumulate, Combine contributions.

Define a cost, estimate a slope and choose a step.

Leave able to make: A descent that can reach different local endings.

Try elsewhere: Keep the cost while changing the start or step size.

Supplied: Landscape display; derivative helper only if explained.

Halls: FormFinding_Descent.

### Let relations hold a form (build)

Requires: A law and its receiver, Keep connections, move a corner, Follow a criterion.

Introduce anchors, rest lengths and iterative relaxation.

Leave able to make: A hanging or relaxed form whose boundary can be edited.

Try elsewhere: Move an anchor instead of specifying the final shape.

Supplied: Solver and stable time step.

Halls: FormFinding_Catenary, FormFinding_Relaxation, FormFinding_Equilibrium.

### Permit another ending (compare)

Requires: Follow a criterion, Let relations hold a form.

Compare greedy descent with an explicitly supplied random proposal.

Leave able to make: A search whose acceptance rule can be changed.

Try elsewhere: Keep the proposal stream while changing the criterion.

Supplied: Seeded proposals before the full Randomness lesson.

Halls: FormFinding_Annealing, FormFinding_Forge.

## Wave Functions

Is the return prescribed, physically produced, recorded or only apparently the same?

### A phase gives a return (build)

Requires: Turn around a reference, A law and its receiver, Keep movement.

Relate a phase and amplitude to position; compare prescribed motion and dynamics.

Leave able to make: A repeated movement and its recorded projection.

Try elsewhere: Change phase independently of amplitude or rate.

Supplied: Trigonometric function and drawing helpers.

Halls: WaveFunctions_Intro, WaveFunctions_Pendulum, WaveFunctions_Sine_Space, WaveFunctions_Unit_Circle.

### Send and combine a wave (build)

Requires: A phase gives a return, A rule at every position.

Use position and time in a wave rule; add contributions or modulate a parameter.

Leave able to make: A wave field or displaced column.

Try elsewhere: Use the same values for a different receiver.

Supplied: Surface construction and audio buffer when needed.

Halls: WaveFunctions_3D_Wave_Propagation, WaveFunctions_Effect_Sound, Wavefunctions_Bernini.

### An event gives sound a beginning (compare)

Requires: Send and combine a wave, Begin once, continue.

Separate sampled signal, trigger, envelope and captured silence.

Leave able to make: A prepared voice with controllable onset and duration.

Try elsewhere: Trigger the same voice twice and compare independent state.

Supplied: Audio device, buffers and microphone permissions.

Halls: WaveFunctions_John_Cage, WaveFunctions_AirMusic, Wavefunctions_Sky_Stairs.

### Many components, one result (build)

Requires: Send and combine a wave, An event gives sound a beginning, Keep many addresses.

Sum known components while keeping their amounts and shared phase.

Leave able to make: A small additive instrument.

Try elsewhere: Remove one component and locate its consequence.

Supplied: Signal display and audio output.

Halls: WaveFunctions_TrigWalkingPath, WaveFunctions_Synthesis_Lab.

## Randomness

Who chooses the set within which chance is allowed to operate?

### Keep a procedure, vary a draw (build)

Requires: Keep many addresses, Give a form a changing pose, Begin once, continue.

Introduce seed, sample and eligibility; use a draw in an existing operation.

Leave able to make: A repeatable random arrangement or walk.

Try elsewhere: Keep the draws while changing how they are interpreted.

Supplied: Random generator implementation.

Halls: Random_Definition, Random_Entropy, Random_Remove, Randomness_10_PRINT_Algorithm, Random_Cubes, Random_Rotate_Random_XYZ, Random_Walk.

### A sample has an account (compare)

Requires: Keep a procedure, vary a draw, Keep movement, A rule at every position.

Distinguish distribution, sample, boundary and record; follow a draw into a consequence.

Leave able to make: A sampled population and its histogram or path.

Try elsewhere: Change the admissible set without changing the sampling method.

Supplied: Histogram, trail display and game receiver.

Halls: Random_Gaussian, Random_Mushrooms, Random_Space_Geometry, Randomness_Examples_of_Randomness, Random_Pheromone, Random_Space, Random_Game.

## Noise

What changes when a field value becomes colour, height or support?

### Sample a related field (build)

Requires: Keep a procedure, vary a draw, A rule at every position, Send and combine a wave.

Distinguish independent draws from spatially related samples; scale the input domain.

Leave able to make: A field mapped to height or colour.

Try elsewhere: Feed the same sample values into another mapping.

Supplied: Noise algorithm implementation and mesh receiver.

Halls: Random_Noise_Types, Noise_Columns, Noise_One, Noise_Voxel, Noise_6_Wall, Noise_Inside_Noise.

### A field becomes support (compare)

Requires: Sample a related field, Keep connections, move a corner, A changing boundary.

Separate a scalar value, a threshold, a visible surface and a collider.

Leave able to make: A terrain comparison with explicit support.

Try elsewhere: Keep the field while changing height or passage threshold.

Supplied: Terrain meshing and safe walking support.

Halls: Noise_Space_10, Noise_Perlin_Simplex, Lab_Path.

## Shaders

What can an appearance promise that the body of the room does not provide?

### A rule for a surface sample (build)

Requires: Sample a related field, Add an attribute, Author a source, repeat it.

Introduce shader input coordinates and output colour before complex effects.

Leave able to make: A small material with a controllable pattern.

Try elsewhere: Apply the same rule to a second mesh.

Supplied: ShaderMaterial setup and rendering pipeline.

Halls: Shader_01_Shaping, Shader_05_Patterns.

### Displace, layer, remember (compare)

Requires: A rule for a surface sample, Keep connections, move a corner, Send and combine a wave.

Distinguish vertex displacement, layered fields and persistent texture state.

Leave able to make: A material study whose visible and physical boundaries can differ.

Try elsewhere: Keep geometry fixed while changing the shading rule.

Supplied: Collision remains separate; reaction-diffusion feedback supplied before CA.

Halls: Shader_11_QueerRubber, Shader_09_FBM, Shader_12_PinkExtravaganza, Shader_10_ReactionDiffusion.

## Cellular Automata

What global consequence follows from this local neighbourhood and update?

### A local rule remembers (build)

Requires: Keep many addresses, Begin once, continue, Author a source, repeat it.

Introduce neighbours, discrete state and separate current/next buffers.

Leave able to make: A small grid that steps one generation at a time.

Try elsewhere: Change one neighbourhood rule and inspect the global pattern.

Supplied: Display and neighbour-boundary policy made explicit.

Halls: CA_Introduction, CA_ElementaryRules, CA_GameOfLife, CA_BeyondBinary.

### Change what a state can be (compare)

Requires: A local rule remembers, A rule at every position, A sample has an account.

Extend binary state to graded values; compare inputs and paired histories.

Leave able to make: A local update with a readable difference between two runs.

Try elsewhere: Keep the initial state while changing one coupling.

Supplied: Display; graded-field and multi-state examples.

Halls: CA_ExpandingSpace, CA_SoftRules, CA_AgentsCircuits, CA_EdgeOfChaos.

## Fractals

Which finite budget gives this apparent infinity its body?

### Replace a part with a rule (build)

Requires: Keep connections, move a corner, Give a form a changing pose, Keep many addresses.

Introduce a terminating recursive step and a depth budget.

Leave able to make: A bounded recursively constructed curve or volume.

Try elsewhere: Keep endpoints while replacing what lies between them.

Supplied: Mesh batching and safe geometry budget.

Halls: Fractal_Recursion, Fractal_RecursiveTrees, Fractal_CantorSet, Fractal_KochSierpinski, Fractal_MengerSponge, Fractal_GoldenSpiral, Fractal_Synthesis.

## L-Systems

What does a rule say, and what does its interpreter allow it to become?

### Rewrite, then interpret (build)

Requires: Replace a part with a rule, Connect and measure, Turn around a reference.

Separate a symbol sequence from its geometric reading; introduce a state stack.

Leave able to make: A rewritten sentence read by a moving point.

Try elsewhere: Read the same sentence with another angle or interpretation.

Supplied: Turtle drawing and stack preview.

Halls: LSystems_Grammar_Lab, LSystems_Growth, LSystems_Grammars_And_Curves.

### A path carries a surface (build)

Requires: Keep movement, Keep connections, move a corner, Choose where to stop, Turn around a reference, Keep many addresses.

Carry rings along retained path points and join their neighbours with triangle faces; distinguish path sampling from ring resolution.

Leave able to make: A suspended tube drawing that can be continued from either end.

Try elsewhere: Keep a path and radius while changing the ring side count, then continue an inherited stroke.

Supplied: Frame transport, mesh renderer, endpoint and pen pickup, bounded undo history.

Halls: LSystems_Grammars_And_Curves.

### A rule becomes a place (compare)

Requires: Rewrite, then interpret, Keep connections, move a corner, A changing boundary.

Carry a grammar into width, support, competition and face operations.

Leave able to make: An architectural or form-grammar variant.

Try elsewhere: Preserve the rule while changing which faces or resources qualify.

Supplied: Generation budgets and full-scale support.

Halls: LSystems_Architecture, LSystems_Competition, LSystems_Living, LSystems_Shape_Grammars, Assemblage_Same_Desire.

## Procedural Generation

What counts as a desirable body or a connected, usable route?

### Build, score, choose (build)

Requires: A rule becomes a place, Keep a procedure, vary a draw, Follow a criterion.

Separate a genome, its constructed body and the criterion that selects it.

Leave able to make: A small population with inspectable selection.

Try elsewhere: Use another score on the same candidates.

Supplied: Population display and mutation source.

Halls: PG_Genetic_Evolution.

### A connection needs room (build)

Requires: A rule becomes a place, A field becomes support, A sample has an account.

Choose a local growth/connection rule; distinguish connectivity from bodily clearance.

Leave able to make: A growing network and a carved route.

Try elsewhere: Change eligibility or width while keeping the initial points.

Supplied: Neighbour search and carving/meshing; graph vocabulary returns later.

Halls: PG_Space_Colonization, PG_Branching_Growth, PG_Percolation_Network, PG_Caves_Mazes, PG_Sculpted_Forms, PG_Mirrored_Patterns.

## Soft Bodies

What holds a deforming body together, and which attachments are allowed to change?

### Keep a body in relation (compare)

Requires: Let relations hold a form, Keep connections, move a corner, A law and its receiver.

Vary pins, pressure and constitutive settings independently of presentation.

Leave able to make: A supplied deformable body with an authored boundary condition.

Try elsewhere: Change an attachment rather than its visible form.

Supplied: Soft-body solver, stable mesh and collision setup.

Halls: SoftBodies_Soft_Body_Deformation, SoftBodies_Cloth_Physics, SoftBodies_Carusell, SoftBodies_Obsticals, SoftBodies_Obsticals_Part2, SoftBodies_Playground_of_Joy, SoftBodies_Affect_Theory_Visualization.

### Two fields change each other (build)

Requires: Change what a state can be, Sample a related field, Compare change, accumulate.

Separate local reaction, diffusion, update step and display.

Leave able to make: A small two-field update with controllable coupling.

Try elsewhere: Hold the start and change one response term.

Supplied: Field storage and surface extraction where used.

Halls: ProceduralGeneration_Reaction_Diffusion_Systems, Topology_Entropy_Morphogenesis.

## Isosurfaces

Which samples and threshold are enough to declare a boundary?

### Extract a boundary (build)

Requires: A field becomes support, Close edges, give a face, Keep many addresses.

Sample a scalar field; choose a level; interpolate crossings before assembling faces.

Leave able to make: A small sampled volume with an inspectable surface.

Try elsewhere: Change threshold without changing the source field.

Supplied: Marching-cubes case table and mesh plumbing.

Halls: ISO_Introduction, ISO_LookupTable, ISO_ShapesGallery, ISO_TorusGyroid.

### Compose the condition (compare)

Requires: Extract a boundary, Sample a related field, Keep movement.

Edit contributions and domains; distinguish a height map from a volume.

Leave able to make: A cavity, terrain or joined field surface.

Try elsewhere: Keep the extractor and replace the field.

Supplied: Meshing, collision and rebuild scheduling.

Halls: ISO_Sculpting, ISO_FlatTerrain, ISO_PortalLandscape, ISO_Caves, ISO_CaveGeneration, ISO_AnimatedNoise, ISO_Metaballs, ISO_ImplicitModeling, ISO_RhizomeBody.

## Boolean Surfaces

When does taking something away make room for another body?

### Make room by subtraction (build)

Requires: Keep connections, move a corner, Scale meets a body.

Define union, intersection and ordered difference of solids.

Leave able to make: A cavity or room whose operands can be repositioned.

Try elsewhere: Swap operand order, then scale the resulting negative space.

Supplied: CSG engine; does not require implementing marching cubes.

Halls: Boolean_Verbs, Boolean_Gallery, Boolean_Works.

## Swarm Intelligence

Whose local information contributes to the apparent collective decision?

### A local view of others (build)

Requires: Let state carry motion, A rule at every position, Keep a procedure, vary a draw, A local rule remembers.

Give an agent state, a sensing neighbourhood and an update policy.

Leave able to make: A small group responding to neighbours or a shared trail.

Try elsewhere: Change perception while keeping the response rule.

Supplied: Neighbour lookup and trail diffusion.

Halls: SwarmIntelligence_PhysarumColony, SwarmIntelligence_FlowFields, SwarmIntelligence_Boids_Algorithm, SwarmIntelligence_Agent_Based_Modeling_ABM.

### Remember and compare routes (compare)

Requires: A local view of others, Follow a criterion, A connection needs room.

Separate personal memory, shared signal and optimisation criterion.

Leave able to make: A route or position search with inspectable memory.

Try elsewhere: Keep the candidates while changing who can share a result.

Supplied: Graph storage before its formal chapter.

Halls: SwarmIntelligence_Ant_Colony_Optimization, SwarmIntelligence_Particle_Swarm_Optimization, SwarmIntelligence_Swarm_Intelligence_Algorithms.

## Machine Learning

What has been named a feature, a label or an improvement?

### Choose what improvement means (build)

Requires: Build, score, choose, Follow a criterion, A sample has an account.

Define data, features, labels and an objective; distinguish clustering from classification.

Leave able to make: A small classifier or optimiser with a visible criterion.

Try elsewhere: Change labels or the cost while preserving the observations.

Supplied: Dataset display and training helpers.

Halls: ML_Evolution, ML_Gradient_Landscape, ML_Classification.

### Compose a learned mapping (build)

Requires: Choose what improvement means, Combine contributions, Keep many addresses.

Use a supplied layer, then inspect one weighted sum, bias and activation.

Leave able to make: A small mapping with editable weights.

Try elsewhere: Compare a single unit with a layered response.

Supplied: Network first as a supplied component; single-unit inspection follows.

Halls: ML_Neural_Networks, ML_Perception.

### A mapping retains or generates (compare)

Requires: Compose a learned mapping, Keep movement, Keep a procedure, vary a draw.

Distinguish hidden state, generated sample and learned parameters.

Leave able to make: A prepared model whose state or input can be changed separately.

Try elsewhere: Reset state without replacing weights.

Supplied: Trained models and training machinery; not a one-chapter GAN implementation.

Halls: ML_Sequence_Memory, ML_Generative, ML_Synthesis.

## Graph Theory

Which relation survives when the picture is rearranged?

### Name the relations (build)

Requires: Connect and measure, Keep many addresses, A law and its receiver.

Separate node identity, edge relation and drawing position.

Leave able to make: An explicit graph with an independent layout.

Try elsewhere: Move the drawing without changing the adjacency.

Supplied: Layout solver; returns to earlier networks.

Halls: GT_Foundations, GT_Layout.

### Choose a route or allocation (build)

Requires: Name the relations, A connection needs room, Remember and compare routes.

Introduce queues/stacks when used; compare reachability, cost, capacity and matching.

Leave able to make: A small path or allocation experiment.

Try elsewhere: Keep the graph and change the question asked of it.

Supplied: Algorithm implementations beyond the first taught traversal.

Halls: GT_Pathfinding, GT_Network_Analysis, GT_Connectivity, GT_Spanning_Trees, GT_Flow, GT_Matching.

## Foundations Crisis

What does this model let us claim, and what cannot follow from this demonstration?

### A model has conditions (reflect)

Requires: What geometry promises, Turn around a reference, Name the relations.

Identify a geometric assumption and a changed interpretation.

Leave able to make: A controlled comparison of models.

Try elsewhere: Hold an observation while changing the model's premise.

Supplied: Geometry renderers; no theorem proved by the display.

Halls: Euclid_Parallel, NonEuclidean_Spaces.

### A claim and its warrant (reflect)

Requires: A model has conditions, A local rule remembers, Replace a part with a rule, Choose a route or allocation.

Distinguish construction, consistency, proof, projection and toy demonstration.

Leave able to make: A small explicit rule system with declared limits.

Try elsewhere: Find a claim the demonstration cannot establish.

Supplied: Formal results require their own arguments; no forced coding quota.

Halls: Russell_Paradox, Godel_Incompleteness, Escher_Impossible, Brouwer_Intuitionism, Florensky_Paraconsistent, Crisis_Synthesis.

## QFEP Laboratory

What exactly does the instrument measure, and where does the interpretation exceed it?

### Read what a measure measures (reflect)

Requires: A claim and its warrant, A sample has an account, Follow a criterion, Change what a state can be.

Give each project term a stated operational measure and scope.

Leave able to make: A comparison of order, variation and response under declared rules.

Try elsewhere: Replace one proxy while keeping the physical arrangement.

Supplied: QFEP as the project's research framing; entropy and spread are not interchangeable.

Halls: QFEP_Introduction, QFEP_F_Term, QFEP_E_Term, QFEP_Lambda_Spectrum, QFEP_Phi_Term, QFEP_Edge_Of_Chaos.

### Connect an intervention (compare)

Requires: Read what a measure measures, A rule at every position, Keep a body in relation.

Distinguish a control value, a connection and the receiver's used value.

Leave able to make: An intervention that can be connected, cut and compared.

Try elsewhere: Cut a route without assuming its previous effect is undone.

Supplied: Receiver models and UI; verify each coupling.

Halls: QFEP_Sandbox, QFEP_Synthesis.

## After the Crisis

Can the work keep its conditions, exclusions and possible revisions available to others?

### Keep the source with the judgement (reflect)

Requires: Connect an intervention, Choose what improvement means, Name the relations, Leave colour somewhere.

Retain provenance, competing requirements and contributors rather than only a verdict.

Leave able to make: An arrangement that exposes who or what its rule admits.

Try elsewhere: Change a rule while keeping the excluded case visible.

Supplied: Authored scenarios and provenance display.

Halls: CriticalAlgorithms_Algorithmic_Bias_Visualization, CriticalAlgorithms_Applied_Ethics, SpeculativeComputation_Paraconsistent_Engineering, SpeculativeComputation_Situated_Computation, SpeculativeComputation_Collective_Knowledge.

### Make a work answer back (reflect)

Requires: Keep the source with the judgement, A connection needs room, Make room by subtraction, Let relations hold a form.

Combine routes, assemblies and records into a situated work.

Leave able to make: A first independent work built from selected earlier capabilities.

Try elsewhere: Name one promise, test it bodily, and revise the responsible operation.

Supplied: Only the infrastructure the chosen work needs.

Halls: SpeculativeComputation_Rhizome_Network, AdvancedLaboratory_Lab_Equipment_Simulation, PostCrisis_Synthesis.

## Handover notes

### Deliver the held point

Point Coordinates follows the corridor, but its download has no player or pickup rig.

Supply and test a reduced XR starter; teach object-side pickup, then reuse the same point in Line.

### One connection before 64 points

Replaced the grid-first lesson with two known positions, subtraction, length and a supplied renderer. A standalone Godot project passed 22 geometry/readout checks.

Keep the portable study aligned with tutorial.md. A self-contained XR starter remains a separate Coordinates task.

### Introduce the record before its machinery

Trace opens with a source excerpt containing recording gates, shaping and list operations.

Teach a tiny ordered list and one retention condition first. Reuse Line distance; borrow rendering.

### Triangle edges are a step inside the active hall

Point_Triangle is not in the active primitives map list. The current Point_Triangle_Context tutorial already moves from edges to face.

Keep both conceptual steps in Point_Triangle_Context. Do not add or reorder maps merely to draw this tree.

### A random proposal arrives before Randomness

Annealing uses random proposals before the dedicated Randomness sequence.

Supply a named repeatable proposal stream here; return to its seed and distribution later.

### Feedback arrives before its full local-rule lesson

The Shader sequence contains a reaction-diffusion encounter before CA and the later Soft Bodies return.

Use a supplied feedback texture now; teach the two-field update later. Distinguish a return from a repeated lesson.

### Whole network, then one unit

Neural Networks precedes Perception deliberately; the latter is a zoom into a single unit.

Name the supplied network interface first. Teach its unit when the route zooms in; do not automatically reorder.

### Networks before Graph Theory

Growth and swarm examples already need adjacency and paths before the formal Graph Theory sequence.

Introduce the smallest useful connection record where first needed; Graph Theory later generalises it.

### Tutorial and current technical account disagree

The tutorial describes position spread, while the current technical account counts equal-weight branch endings and reports ln(N).

Reconcile the learner lesson against the current encounter. Never silently call spread Shannon entropy or treat a project proxy as universal.

### Follow the encounter, not the old map name

The current CA_GameOfLife tutorial follows retained rows and histories; the explicit Life dish occurs in CA_BeyondBinary.

Use the source encounter titles in the atlas; verify the intended teaching step before changing names or order.

### Encounters without a tutorial file

10 active halls have no non-empty tutorial.md. They may have strong manuscripts, artifacts or technical notes.

Decide whether each hall needs a making lesson, an explicit borrowed component or a deliberate reflective role. Do not generate filler to fill the column.
