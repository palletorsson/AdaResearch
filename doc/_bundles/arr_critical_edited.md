<<<ADA_BUNDLE>>>
sequence: array_tutorial
file: critical.md
maps: 7
skipped_passing: 1
created: 2026-04-23T23:10:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Tutorial_Pattern>>>
# Data that rhymes — the pattern tile and the politics of rule-generated ornament

A tile is a small grid with a rule that assigns a colour to each cell. The rule can be simple: colour black when (x + y) is even, colour white otherwise. The resulting pattern is a checkerboard, and the checkerboard is a famous object in the history of ornament — it is one of the first patterns a child can draw and one of the first structures a tiling algorithm can produce.

Owen Jones's 1856 *Grammar of Ornament* argued that decorative patterns are generated from a small set of principles applied consistently across a surface. Jones catalogued patterns from every tradition he could access and proposed that the underlying grammar was universal. Tutorial_Pattern stages Jones's argument computationally. The grammar is a rule; the surface is the tile; the ornament is the rule's output.

Four small tile stations sit around the room. Each station holds a tiny grid and a rule. The first rule is the checkerboard. The second is a wave: colour scales with sin(x). The third combines x and y multiplicatively. The fourth exposes the full expression as an editable string, so the learner can write their own rule and watch the tiles respond. The progression is from fixed grammar to open grammar, and the openness is the map's final gesture.

A large preview board on the wall takes whichever rule is active and tiles it across a much bigger surface. The local pattern scales to global ornament, and the scaling is not cosmetic; it demonstrates that a small rule produces a large pattern without additional work. Jones's grammar is multiplicative in this sense: a few principles, applied at scale, produce whole visual traditions.

The politics of rule-generated ornament are in the cultural traffic the rules claim to describe. Jones's book included patterns from Islamic, Egyptian, Chinese, Greek, and Renaissance traditions, and he presented them all as instances of a shared grammar. Later scholarship has pushed back: flattening traditions into a universal grammar erases the specific histories and meanings each tradition carries. The map holds Jones's move lightly — its rules produce pretty patterns, and the prettiness does not claim to explain any specific tradition's ornament.

The mode toggle between direct and mirrored tiling is where the map's argument about ornament's rules becomes interactive. Turning simple rules into kaleidoscopic variants takes only a flip-and-copy operation, and the operation multiplies the visual complexity dramatically. The complexity is not earned by new rules; it is earned by a symmetry operation applied to the existing rule, and the map makes the operation available to the learner.

Within the sequence, Tutorial_Pattern is where arrays stop being data containers and become pattern generators. The learner leaves knowing that data rhymes because a rule makes it rhyme, and that choosing which rule to apply is the work of pattern-making. Array_Patterns will next push the move into full wallpaper-group symmetries, and the rule-grammar relationship will become the subject of the next map rather than a byproduct of this one.

<<<MAP: Tutorial_Single>>>
# The scalar before the array — one cube and the politics of handing over the grip

The whole map is one platform, one cube, one exit. The learner's task is to pick up the cube, or to walk past it, and to cross to the teleporter. No array is introduced. No pattern is taught. The map's job is to teach the hand that it can close around an object, and to teach the eye that the hand's closure is the interaction the VR runtime has been waiting for.

Merleau-Ponty's phenomenology of the body argues that the body schema — the implicit map of what the body can reach, touch, and move — is acquired through repeated practice with specific objects. Picking up a cup, a pen, a stone each leaves a slightly different trace in the body schema, and the schema's updates are the precondition for more complex actions. Tutorial_Single is a body-schema calibration for VR. The cube is the one object, and closing a hand around it is the one practice.

The platform is minimal — four cells by three — so the learner cannot walk far without reaching the edge. The cube sits at the centre, so the learner cannot ignore it. The teleporter sits at the far end, so the exit is visible from spawn. The architecture is a series of affordances that guide the body toward the single interaction the map is about, and the guidance is not hidden; it is the point.

A small diagram on a nearby stand shows the hand-tracking contract in three frames: open hand near object, closed hand triggers a grab, release re-opens. The diagram is a diagram about the diagram-less activity the map is asking the body to perform. Merleau-Ponty would note that the diagram is not the body schema but a proposition about it, and that the body will learn the grip by closing on the cube rather than by reading the diagram.

The politics of the single interaction are in the control the learner is handed. VR systems often begin by listing available buttons, gestures, and modes. This map does not. It hands the learner one cube and one grip, and it trusts them to discover the grip by trying. The trust is a small political choice — it refuses the defaulting-to-instruction habit that dominates interface design — and the choice makes the interaction feel discovered rather than assigned.

Within the sequence, Tutorial_Single is the scalar before the array. Before a corridor, before a grid, before a volume, the learner needs to be able to pick something up. The single cube is a scalar value; the remaining maps will extend the operation into one, two, and three dimensions. Tutorial_Row comes next, and the row will turn the grip into movement along an axis.

<<<MAP: Tutorial_Row>>>
# The first index — a corridor as array and the politics of linear traversal

An array's most basic form is the row. Values stored in sequence, indexed by a single integer, accessed by the same operation across every position. Tutorial_Row converts this into architecture: a corridor seven columns wide, nine rows deep, with a single lane running forward through the centre. Movement along the lane is equivalent to incrementing an integer index.

Michel de Certeau's work on walking-as-reading argues that moving through urban space is a way of producing the space's meaning. A walker enacts a particular trajectory through a city that was designed for many possible trajectories, and the walker's trajectory is one of many legitimate readings. The corridor here stages a deliberately narrow case. There is only one lane. The walking and the reading are the same operation, and the array is what the operation addresses.

A rig along the central lane constrains the learner's movement to the Z axis. The rig is visible as a subtle track on the floor, but its effect is felt rather than seen: lateral movement is restrained, and the body naturally aligns with the lane as it walks. A simple counter on the wall shows the learner's current index along the lane, incrementing as they step forward and decrementing as they step back. The lane is the array; the step is the access.

A small wall panel shows the equivalent code: `cell = row[i]`, with `i` tied to the live counter. As the learner moves, the code's highlight moves too, so traversal and indexing share a display. The equivalence is deliberate. Walking forward and accessing `row[i+1]` are the same operation at different levels of description, and the map refuses to privilege one description over the other.

De Certeau's politics of walking applies here with a caveat. De Certeau was writing about cities whose architecture supported many possible walks. The corridor supports only one, and the single-lane constraint flattens the trajectory diversity that de Certeau valued. The map acknowledges this by keeping the corridor short and the lesson explicit: a 1D array is a minimal data structure, and reading it linearly is the only operation it supports. The flattening is the feature; richer traversals will come in the later maps.

The politics of linear traversal are in the contract between the learner and the data structure. A 1D array promises order: the first cell is before the second, which is before the third, and there is no way to reach the third without passing the second. The corridor enacts this contract physically. You cannot skip cells, because the rig does not allow it. The contract is restrictive, and the restrictiveness is what makes the operation legible.

Within the sequence, Tutorial_Row is the first array dimension. Tutorial_2D_Build will next add the second, and the grid will support richer traversals that the row cannot. The sequence progresses by serially adding dimensions, and each addition loosens one of the earlier constraints.

<<<MAP: Tutorial_2D_Build>>>
# The grid is a politics — row and column helpers and the decision to address a point

A 1D array needs one index. A 2D grid needs two. The jump from line to grid is the jump from sequence to space, and the map stages the jump carefully: four cells by four cells, small enough to comprehend at a glance and large enough to require a systematic addressing scheme.

Benedict Anderson's work on imagined communities argues that census, map, and grid are the state's tools for making populations governable. The grid assigns each subject a coordinate, and the coordinate is the hook that bureaucratic operations hang on. Tutorial_2D_Build stages this at pedagogical scale. The four-by-four grid is a small census; the row and column helpers are the operations that decompose the two-index address into its components; the grid agent is the bureaucratic subject that visits every cell in order.

The grid lies flat on the floor. Each cell is labelled with its row and column indices. A row helper and a column helper sit at two sides of the grid. Pressing the row helper highlights every cell in a chosen row; pressing the column helper highlights every cell in a chosen column. The two helpers decompose the two-index address into its components, so the learner can see why a coordinate pair matters before being asked to use one.

A small grid agent stands at one corner. Starting it triggers a programmatic traversal: the agent visits every cell in row-major order, then in column-major order, then in a diagonal. Its steps are visible, and a side panel names each step as an update to a pair of indices. The traversal is the first algorithmic movement the learner has seen; previous maps moved under the learner's feet, and this map moves under an agent's.

Anderson's argument about census and grid lands here as a question about who is doing the addressing. In the map, the learner addresses cells via helpers, and the agent addresses cells via a traversal algorithm. Both are legitimate, but they differ in authority: the learner's addressing is exploratory, while the agent's is systematic. A real census would resemble the agent's traversal more than the learner's exploration, and the political weight of the grid would be the systematic addressing rather than the exploratory one.

The politics of two-index addressing are in the coupling. Once a grid is addressable by (row, column), operations can be written against the coupling: "apply this to every cell in row 2", "swap column 1 and column 3", "sort diagonals". The coupling is productive and dangerous. It produces the rich vocabulary of 2D array operations that underpins everything from image processing to spreadsheet analysis; it also produces the conditions under which grid-addressable populations become governable targets of those operations.

Within the sequence, Tutorial_2D_Build is the jump from line to grid. Tutorial_3D will next add the third dimension, and the volume will expose further possibilities the grid cannot. The sequence continues its dimensional progression, and each added dimension brings both new computational power and new questions about who the operations are serving.

<<<MAP: Tutorial_3D>>>
# The volume is a choice — three indices and the politics of stepped access

A 3D volume is four cells by four cells by four cells — sixty-four addresses indexed by three integers. The map stages the volume with stepped platforms along the north and west sides, so the learner can reach the upper layers on foot rather than relying on teleporters. The stepping is a design choice about how to make the third dimension accessible, and the choice carries its own politics.

Henri Lefebvre's analysis of spatial practice distinguishes between conceived space (the designer's abstract map), perceived space (the inhabitant's body-level sense of the space), and lived space (the space as it is used and understood by its occupants). The volume in Tutorial_3D is all three at once. The addressing scheme is conceived; the stepped platforms and lifts are perceived; the learner's walking trajectory is lived. The three registers do not always agree, and the map's pedagogy runs through their disagreements.

The volume itself is partially transparent, so the learner can see layers above and below their current height while standing on any given platform. The transparency is a conceit: real stacked data does not visually announce its neighbours. The map grants the learner access that a real 3D array would not offer, and the granting is what makes the dimensional progression teachable rather than disorienting.

A small helper at the entrance walks the learner through the addressing convention. Three sliders set row, column, and layer independently; adjusting any one of them moves a highlight cube to the corresponding cell inside the volume. The learner can see that the same indexing logic scales: one index gave a row, two gave a grid, three give a volume. The scaling is the map's argument about dimensional generalisation.

Lefebvre would note that the stepped platforms favour a specific body. A learner with mobility, balance, and vertical reach can navigate the volume fluently. A learner without these advantages relies on the lifts, and the lifts are slower and less flexible. The volume's accessibility is not uniform, and the asymmetry is a design decision that the map makes without apology.

A side wall shows the code `cell = grid[x][y][z]` alongside the live sliders, so each numerical change highlights the corresponding bracket. The code-space parallel is the map's final argument about dimensional access: the same syntactic structure scales with the dimension count, and the scaling is what makes 3D array operations tractable. One more bracket, one more index, one more loop.

Within the sequence, Tutorial_3D completes the dimensional ladder. Tutorial_Pattern will next shift the grid from a data container to a pattern generator, and the sequence's trajectory will pivot from addressing to rhyming. The volume the learner leaves behind remains as a demonstration that dimensional generalisation is a syntactic rather than substantive move.

<<<MAP: Tutorial_Disco>>>
# The dance floor is an array — time as the third index and the politics of composition

A 17-by-17 dance floor is a grid at scale. It is large enough to get lost in and small enough that every tile is visible. Each tile is an address — row, column, and a local state — and stepping on a tile activates a response. The floor's third dimension is time, because a step sequencer divides a loop into beats and plays back the learner's activations at a steady tempo.

Erin Manning's work on dance and philosophy argues that movement is thought in matter. The dancer's trajectory is not an expression of a prior intention; it is a mode of thinking that becomes legible only as it is performed. The dance floor in Tutorial_Disco takes this argument and installs it as an array interaction. The learner's walk across the tiles is composition, and the composition is the learner's thinking legible as pattern.

The sequencer runs along one wall. It divides a short loop into steps and advances one step at a time. The pattern the learner steps out on the floor is captured, cell by cell, into the sequencer's state, and the sequencer plays it back at the chosen tempo. The playback is the composition as record; the learner's walk is the composition as performance; the two are the same composition in different modes.

A set of mode buttons changes what the sequencer does with the captured state. One mode triggers a sound per active tile. Another lights the tile for one beat. Another propagates the active tile to its neighbours, so a sparse walk produces a filling wave. Each mode is a different interpretation of the same array, and the interpretations accumulate into a small toolkit for composing with the floor.

Manning's argument about dance-as-thought lands on the relationship between the learner's path and the sequencer's playback. The learner does not plan the path in advance; they walk, and the sequencer captures what they walked. The playback then exposes the walk as a pattern the learner may not have intended to produce. The composition emerges in the walk and becomes legible in the playback, and the legibility is often a surprise.

The politics of composition-by-movement are in the refusal of pre-specification. A traditional score specifies what the performer should do; the dance floor captures what the performer did. The former treats the composition as primary and the performance as its execution; the latter treats the performance as primary and the composition as its record. The map's sympathies lie with the latter, and the sympathies shape what the map rewards.

Within the sequence, Tutorial_Disco is the playful capstone. It scales the array from the small, comprehensible grids of the earlier maps to a floor large enough to get lost in, and it adds time as a new dimension. The next encounter in the curriculum, the Wavefunctions sequence, picks up on the temporal pattern the dance floor hints at.

<<<MAP: Chamber_Arrays>>>
# The grid as shared authored surface — placement, traversal, and the politics of the absent catalyst

Chamber_Arrays is the only catalyst chamber in the curriculum that does not hand the learner a projection tool. The interaction is observation and arrangement: the learner places obstacles on a grid, and a grid agent adapts its traversal in response. No projectiles are fired. No damage is dealt. The chamber's argument is that arrays hold state, and state responds to what is placed within it.

Bruno Latour's actor-network theory treats artifacts and humans as co-participants in whatever practice is underway. A desk is not a passive support for work; it is a participant in the work, enforcing certain postures and foreclosing others. The grid agent in the chamber is Latour's participant made explicit. The learner does not command the agent; the learner places obstacles, and the agent's traversal is shaped by the placements. Both sides are participants in the composition the chamber stages.

The chamber is small. A grid covers the floor, labelled by row and column. A grid_agent:copy moves through the grid according to a simple traversal rule — row-major scan, with detours around obstacles. The learner carries a set of small blocks they can place on any cell. Each placement forces the agent to find a new path.

A science screen on the wall reads out the agent's current plan as a sequence of cell indices. As obstacles are added, the plan updates, and the screen highlights which indices changed. A second display tracks how many extra steps each new obstacle costs. The readouts convert placement into a measurable effect on the agent's work, so the learner can calibrate their obstacles rather than simply adding them.

Latour's insight lands on the question of authorship. A grid with no obstacles is the agent's grid; its traversal is given. A grid with placed obstacles is a shared grid; its traversal is the product of the agent's rule and the learner's placements. Neither side is the sole author. The composition is a network, and the chamber makes the network legible by showing both sides' contributions in the same readout.

The politics of the absent catalyst are in the refusal of projection. A catalyst chamber typically rewards the learner for emitting a projection that changes the creature's state. Chamber_Arrays refuses this structure. The learner changes the agent's behaviour by placing blocks on a shared surface, and the change is collaborative rather than coercive. The refusal of projection is a small statement about what the curriculum's catalyst practice can be.

Within the sequence, Chamber_Arrays reframes the catalyst practice as arrangement rather than projection. The lesson is that arrays hold state, and state responds to what is placed within it. The chamber hands the learner back to the Lab with the array catalyst absent by design, and with a body-level sense that authorship is often a matter of what you let sit where rather than what you emit at whom.
