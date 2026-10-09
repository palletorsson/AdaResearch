# A curriculum through the existing halls: arrival to randomness

3 October 2026. Proposal for writing one tutorial at a time. The museum order and chapter texts have not been changed by this document.

**Current use:** this is planning material for the [tutorial storyboards](../TUTORIAL_STORYBOARDS.md), which Palle will correct before full lessons are written. Older setup instructions below are superseded by the existing Endless Museum environment. In particular, Point Zero uses its existing counter; do not create another teaching display. A production-script walkthrough is not automatically a useful learning progression. Resolve teaching choices in the storyboard before promoting this outline's proposed subject locations.

The companion [subject register](SUBJECT_REGISTER.md) records first usable introductions, prerequisites, later uses and deeper returns. It also distinguishes the proposed route from candidate code occurrences in the current tutorials. Following Palle's clarification, sine is taught briefly in Transformation and bounded random variation in Array; their named sequences develop those beginnings.

## Recommendation

Keep the ten sequence order from Primitives through Randomness. There is a coherent progression here. Improve the selection and teaching inside the halls before moving whole sequences.

The line is: **give something a body → change it → arrange many → assign and perceive differences → share a rule → measure change → give movement a history → arrange conditions for form → follow recurrence → make and examine choices.**

This is a route through the collection, not a claim that every artifact must illustrate the route. Museum objects can contribute atmosphere, comparison, play, difficulty or a possible future investigation without belonging to either manuscript.

Keep the current order for the first writing trial. Unit Circle before Sine Space remains an optional local comparison, but an earlier usable sine introduction removes the need to move it just to avoid an unexplained function. Motion before Launch is another possibility if both lessons must build their motion from scratch. Neither change has been applied to the museum.

## What can carry the lineage?

The tutorial can carry a construction forward: the list retained in Trace becomes positions we can rearrange, connect and generate. The critical text can carry a question forward: the name of a shape, the boundary it presents, the bodies it admits. Sometimes the encounter carries the transition before either account explains it.

These paths can separate and meet again. A reflective hall need not add syntax. A tutorial need not reconstruct the most prominent artifact, provided its chosen operation belongs to the actual material and the connection is made explicit.

There is one constraint: a question carried by final.md cannot silently count as a programming skill taught. If a later lesson requires an operation, its tutorial must have taught it, introduce the small missing step now, or explicitly supply it. Recognising a moving cube does not mean the learner can integrate acceleration. Hearing a chance composition does not mean they can implement its generator.

For each lesson choose one manageable construction, the important question it exposes, and what the learner can use again. Supply the surrounding apparatus openly. Keep the input, operation and output distinct: a position is not its mesh; a colour is not a surface; a field sample is not automatically a force; a list of positions is not a timed history.

The table labels below describe the proposed emphasis, not a claim about the quality or completeness of today's files:

- **Tutorial:** construction carries this step; the critical text remains free to ask its own question.
- **Together:** making and interpretation are particularly productive in relation.
- **Reading:** encounter and critical reflection carry the step; a short application or optional making exercise is sufficient.

## The ten sequences

| Sequence | What the learner can make or inspect | What the book can keep questioning | What travels onward |
|---|---|---|---|
| 1. Primitives | Positions, segments, retained paths, connected faces, small rules that generate geometry. | What has to be added before an abstract name can appear, resist, be held or seem complete? | Values, references, lists, traversal, connections, a first function with an explicit result. |
| 2. Transformation | Change position, orientation and size; compare a clocked change with a response to a body. | What survives a change? Who fits, who waits, what returns? | State, rates, conditions, thresholds, coordinate frames and composition of operations. |
| 3. Array | Generate repeated bodies at addresses; assign a local exception; revisit an address in time. | Does the rule leave room for a difference? What does an address keep when its occupant disappears? | Counted and nested iteration; address-to-position rules; occupancy, shared source and local state. |
| 4. Colour | Assign a colour, compute one from a position, store a choice and compare receivers. | Colour as measurement, appearance, association and permission; what can be chosen and what remains imposed? | Functions that map inputs to attributes, stored versus evaluated values, material/light distinctions. |
| 5. Tiling | Edit one source; repeat, reflect and wrap its addresses; carry a saved source onto another body. | What is shared, what is allowed to differ, and what does the carrier change? | Source/rule/receiver separation, periodic indexing, shared versus copied data and explicit adapters. |
| 6. Change | Compare two readings, accumulate contributions, follow a sampled field one step at a time. | What does a sample conceal? What did the total lose of the route? | Finite differences, numerical sums, step size and evolving state. |
| 7. Forces | Retain velocity; change it through acceleration; compare inputs, contacts and receiving bodies. | When is an arrow a command, a measurement or an influence? What lets a body continue or stand? | Vector operations revisited with units; integration, force laws, contact assumptions and receiver contracts. |
| 8. Form-finding | Change a cost, an anchor or a constraint and examine what settles. | Who chose the preferred state? Is a satisfactory form necessarily a minimum? | Iterative update, constraints, tolerance, objective and stopping rule. |
| 9. Wavefunctions | Record recurrence, relate phase to position, combine components and give a response its own beginning. | What returns, what remains different, and what does a record or representation preserve? | Phase, frequency, sampling, superposition, event timing and bounded records. |
| 10. Randomness | Draw, replay, count, select, accumulate and feed traces back into later choices. | Who defines the possible set? What does a statistic omit? When is uncertainty assigned, disclosed or experienced? | Seed and procedure, sample versus distribution, selection, population, boundary and feedback. |

Colour and Tiling belong after Array for a reason: an address can receive an attribute, and a small authored source can then travel across many addresses. Change begins where we stop only asking what a rule produces and begin asking how its output changes between readings. Forces gives that change a receiver and a remembered velocity. Form-finding asks what can settle; Wavefunctions asks what can return without settling. Randomness then changes how a next value is chosen while retaining the constructions already available.

## 1. Primitives — from a place to a construction

Day Zero supplies the running project, camera, lighting and input infrastructure. The student creates lesson objects in code, including text displays, and keeps their references in variables. Tutorial examples must not depend on named scene children or node-path lookups. The current Point Zero and Point One studies are useful starting material, not a demand that their present wording remain unchanged.

| Hall, in current order | Emphasis | Proposed contribution and limit |
|---|---|---|
| [Point_Zero](../../../../commons/maps/Point_Zero/tutorial.md) | Together | Ready once, process repeatedly; a count has a beginning. Create one Label3D and keep its reference. Compare camera distance with object size and illumination with visibility. Explain the small variable and node-creation operations used here; Point One develops them through positions. Arrival carries the critical opening. |
| [Point_One](../../../../commons/maps/Point_One/tutorial.md) | Tutorial | Name a value, assign it, change it. An unseen position gains a visible marker and then a contact boundary. Distinguish value, mesh and collider. The light switch supports the encounter without requiring a lighting system tutorial. |
| [Point_Coordinates](../../../../commons/maps/Point_Coordinates/tutorial.md) | Tutorial | Change one coordinate; distinguish a local position from a world position; keep two points independently. Supply the working XR hold and explain what it delivers. |
| [Point_Lines](../../../../commons/maps/Point_Lines/tutorial.md) | Together | Subtract the endpoints and measure the displacement. Recompute the relation when either moves. Supply the segment renderer. The plank, beam, perspective and walking studies expand what a line can mean without all becoming code exercises. |
| [Point_Trace](../../../../commons/maps/Point_Trace/tutorial.md) | Tutorial | Append positions to a one-dimensional list; inspect an entry and count; traverse it with a for loop. Supply input and drawing. Kept order does not retain the duration of a pause. Advanced recording policies can wait. |
| [Point_Line_Grid](../../../../commons/maps/Point_Line_Grid/tutorial.md) | Together | Turn a position into a discrete address by a chosen spacing. Reuse the trace list to compare chosen and snapped positions. Show one small arrangement; leave extensive nested generation to Array. |
| [Point_Triangle_Context](../../../../commons/maps/Point_Triangle_Context/tutorial.md) | Tutorial | Three non-collinear points define a triangle. Reuse segments, then add a face. Keep vertex order and connections visible; supply the general mesh submission machinery. A closed outline has not itself made a surface. |
| [Primitives_Polythedra](../../../../commons/maps/Primitives_Polythedra/tutorial.md) | Together | Faces can enclose a region; contact is still separate. Build one small enclosure and read its face list. Do not turn the barrier, scanner, rocks and every other placed comparison into prerequisites. |
| [Point_Animatedcube](../../../../commons/maps/Point_Animatedcube/tutorial.md) | Together | One corner participates in several edges and faces. Follow a shared position through its connections; distinguish editing a vertex from transforming the object. The prefab collection opens a different question about reuse. |
| [Primitives_Ignorance](../../../../commons/maps/Primitives_Ignorance/tutorial.md) | Together | Use the Platonic court for a first explicit rule that generates positions: the octahedron's opposite axis points. Name the operation as a function returning a list. Keep face connectivity supplied initially. Return to the sphere and change its divisions: a rule still produces finite geometry. |
| [Primitives_Portals](../../../../commons/maps/Primitives_Portals/tutorial.md) | Reading | Compare finite approximations and the cost of more divisions. Reuse a supplied circle sampler; do not require trigonometric derivation or portal rendering here. Later Wavefunctions opens the circle calculation. |
| [Primitives_Melencolia](../../../../commons/maps/Primitives_Melencolia/final.md) | Reading | Compose known forms and examine what geometric mastery promises. One optional arrangement exercise is enough. The tableau, history and unfinished looking carry the move into Transformation. |

The first function should have a small, useful contract: a radius goes in; positions come out. That does not generate topology automatically. Let the student discover the rule, generate its result, and move one vertex outside the rule. The question about information becomes concrete: what must we remember in addition to the shared construction?

This revises the earlier plan that reserved writing functions for Colour. Colour can develop functions as mappings and reusable operations; it need not introduce the word for the first time. A named class is warranted when a learner genuinely needs several independent bodies with their own state, not merely because a chapter number has arrived.

## 2. Transformation — the body stays recognisable, the relation changes

Carry the code-created body forward. Compare linear change with one smooth periodic motion. Teach sine here as a usable operation: its cycle input, its output from -1 to 1, and how amplitude and a positive period change the cube's height. The student can make and alter the motion without deriving sine from a circle. Waves later develops that relation, phase differences, sampling and superposition. Introduce a condition when a boundary or change of state actually requires one.

| Hall | Emphasis | Proposed contribution and limit |
|---|---|---|
| [Trans_Pre](../../../../commons/maps/Trans_Pre/tutorial.md) | Tutorial | Make the same cube move, turn and change size. Reuse process; distinguish elapsed time from a frame's delta. Introduce one sine-driven height, then change its amplitude and period. Compare one operation at a time before combining them. Supply neither an unexplained formula nor a full trigonometry course. |
| [Trans_Introduction](../../../../commons/maps/Trans_Introduction/final.md) | Reading | Watch and cross the three gaps. Timing and the visitor's dimensions make transformations consequential. A small parameter edit can accompany the walk; matrix construction is not required here. |
| [Trans_Translation](../../../../commons/maps/Trans_Translation/tutorial.md) | Together | Move between positions; compare a free path with movement constrained to a rail. Use a condition to reverse or hold at a limit. The destination does not describe every permitted journey. |
| [Trans_Rotation](../../../../commons/maps/Trans_Rotation/tutorial.md) | Together | Keep an angle and an axis; follow a corner around a pivot. Compare return of orientation with the travelled trace. Make parent and local frames explicit before composing turns. No quaternion derivation is required. |
| [Trans_Scale](../../../../commons/maps/Trans_Scale/final.md) | Reading | Change dimensions and compare against the body's clearance. A scale parameter is enough for the making exercise. Preserve the actual cut and repositioning in the room instead of describing smooth growth that is not shown. |
| [Trans_Body](../../../../commons/maps/Trans_Body/tutorial.md) | Together | Let a measured proximity change a part; compare resetting with remembering. Teach one threshold and a retained state. Slat rotation, removal and shrinking need not each introduce an unrelated architecture. |
| [Trans_Pit](../../../../commons/maps/Trans_Pit/tutorial.md) | Together | Compose translation, rotation and scale through timed states. Build a reduced door that opens, waits and returns. The museum supplies the whole structure; the learner owns its chosen state transition. |

Exit skill: a known body can change under a clock or condition. Exit question: whose body and waiting time were assumed? Array keeps the body and asks what changes when there are many addresses for it.

## 3. Array — a place for another decision

This sequence extends the list and traversal from Trace. Its new work is generating repeated placements, using several indices and distinguishing the address, its occupant and its attributes. It must not begin by assuming none of those earlier list skills exists.

| Hall | Emphasis | Proposed contribution and limit |
|---|---|---|
| [Array](../../../../commons/maps/Array/final.md) | Tutorial | Generate the row, then the plane: index becomes position, and each position can receive another choice. Teach counted and nested loops through a small visible array. Introduce a bounded random offset and a resettable local seed: change the range, repeat the requests, compare the copies. The changing floor and Molnar volume can expose occupancy and exceptions; their complete controllers stay supplied. **tutorial.md is missing.** |
| [Tutorial_3D](../../../../commons/maps/Tutorial_3D/tutorial.md) | Together | Add a third index. Remove an occupant while keeping its address. Reuse the placement function. Flight is supplied locomotion, not a property of arrays. |
| [Tutorial_Tiling_Floor](../../../../commons/maps/Tutorial_Tiling_Floor/tutorial.md) | Together | Assign a binary diagonal motif by a small address rule. Compare a 4×4 witness and the larger field; change one rule, then one cell. The current 56-word tutorial is an encounter note, not this making lesson yet. |
| [Tutorial_Tiling_Walls](../../../../commons/maps/Tutorial_Tiling_Walls/tutorial.md) | Reading | Put the same pattern on another receiver. Observe orientation, scale and collision. Reuse the rule instead of writing a second generator. The wall becoming passage can carry the critical development. |
| [Tutorial_Disco](../../../../commons/maps/Tutorial_Disco/final.md) | Together | Read a stored value at a returning step; distinguish address from time. Build a short binary sequence and advance its index. Supply sound synthesis. The current tutorial needs replacing: it describes a 17×17 foot-triggered floor rather than the present account of a 12-column floor and separate sequencer. |

Keep the black-and-white floor and wall work here. Their later return in Tiling is productive: first follow a given rule, later author and distribute its source. The simple scheme also gives Colour an address at which an attribute can be assigned.

## 4. Colour — the assigned value meets a receiver

We have already seen colour. This sequence makes its different roles inspectable. It is not eight opportunities to introduce eight language features. Reuse a small colour-valued function and stored swatch where appropriate; let the body and cultural questions retain their weight.

| Hall | Emphasis | Proposed contribution and limit |
|---|---|---|
| [Color_Context_Placed](../../../../commons/maps/Color_Context_Placed/final.md) | Reading | Gather known primitives, transforms and arrays into fixed compositions. Change a colour assignment while retaining the arrangement. Recognition and association lead; no new data model is needed. |
| [Color_Flashlight](../../../../commons/maps/Color_Flashlight/tutorial.md) | Together | Distinguish a light's colour from a material's colour. Change one input while holding the receiver fixed. Supply the prepared lighting and shader infrastructure. |
| [Color_Nails](../../../../commons/maps/Color_Nails/final.md) | Reading | Map a choice to nails or skin, and inspect which body receives it. A supplied hand receives a Color value through an explicit method. The politics of that choice cannot be reduced to a colour-picker implementation. |
| [Color_Rainbow](../../../../commons/maps/Color_Rainbow/final.md) | Reading | Return to divisions and ordered choices: alter the bands, compare what remains. Reuse counting and assignment. Celebration is part of the room, not a compulsory particle-system lesson. |
| [Color_Pillar](../../../../commons/maps/Color_Pillar/tutorial.md) | Together | Evaluate colour from position: separate hue, saturation and value, then compare with RGB coordinates. A small function maps a normalised position to colour. The matching ceiling lets the result become an environment. |
| [Color_Grid_Pallet](../../../../commons/maps/Color_Grid_Pallet/tutorial.md) | Tutorial | Store a colour at an address; leave and return; distinguish writing one cell from recomputing the rule. Reuse the Array grid and list access. |
| [Color_Paint](../../../../commons/maps/Color_Paint/tutorial.md) | Together | Accumulate a mark instead of replacing one cell's colour. Supply aiming, surface lookup and aerosol behaviour; teach one deposition/blending operation and its limits. The stored image is not a recoverable stroke history. |
| [Color_Walls](../../../../commons/maps/Color_Walls/final.md) | Reading | Compare appearance through a pane with physical passage. Carry forward the distinction between image and collision. A material or spacing edit applies existing tools; full transparency rendering remains supplied. |

The transition into Tiling is a return to the disco: the arrangement is familiar, but its values can receive a different palette. That return earns the new question of what happens when we edit the little source itself.

## 5. Tiling — one source, several consequences

The lineage here is source → repetition rule → receiver → saved version → another body. Keep the distinction between a shared reference and a stored copy explicit. Do not force the shader language or garment system into the first explanation of a repeating image.

| Hall | Emphasis | Proposed contribution and limit |
|---|---|---|
| [Pattern_Disco](../../../../commons/maps/Pattern_Disco/tutorial.md) | Together | Keep binary values and phase, change the palette lookup. Reuse the earlier floor and Colour's assignment. |
| [Pattern_Foundry](../../../../commons/maps/Pattern_Foundry/tutorial.md) | Together | Edit an entry in a 4×4 source and follow its repeated appearances. Teach one source-to-preview route first. Holding a copy and architectural receivers are returns within the hall; its entire machine collection need not be rebuilt. |
| [Tutorial_Pattern](../../../../commons/maps/Tutorial_Pattern/tutorial.md) | Tutorial | Hold the source still; change how the repeat samples it. Compare translation and reflection with an asymmetric mark. Distinguish changing the source from changing the sampling rule. |
| [Array_Patterns](../../../../commons/maps/Array_Patterns/tutorial.md) | Tutorial | Wrap surface indices back into the source; turn floor coordinates onto a wall. Teach remainder as returning to an address. A seam can make the mapping legible. |
| [Symmetry_Seventeen](../../../../commons/maps/Symmetry_Seventeen/final.md) | Together | Test what the selected transformations preserve. Reuse the earlier solids' question of sameness. A P1/PM/PG comparison is sufficient; implementing or proving all seventeen groups is not the entry lesson. |
| [Ribbon_Patterns_01](../../../../commons/maps/Ribbon_Patterns_01/final.md) | Together | Give the mark an interior: sample a small volume and inspect a layer. Return to the third index, occupancy and the meaning assigned to zero. **tutorial.md is missing.** |
| [Ribbon_Patterns_02](../../../../commons/maps/Ribbon_Patterns_02/final.md) | Reading | Keep the recipe while changing the carrier or finish. Observe the receiver's contribution. Supply shader implementation and return to it in Shaders. **tutorial.md is missing; a short comparison exercise is enough initially.** |
| [Ribbon_Patterns_03](../../../../commons/maps/Ribbon_Patterns_03/final.md) | Together | Save a recipe and apply it to a named garment part. Teach shared versus copied state through one small example; supply file handling, avatar and shader adapters. What may travel is also a critical question. **tutorial.md is missing.** |

The move to Change needs one explicit return: a rule already gives a value at an address. What happens if we compare its values at two nearby positions? We do not need to pretend that a dress causes calculus. The tutorial recovers a familiar operation; the critical text can move from an authored surface to the limits of describing its variation.

## 6. Change — compare, accumulate, take another step

This is a small sequence with a large prerequisite role. Keep it small: two samples, a quotient, a sum, one update. Supply complex source curves before deriving them. A spatial rate and a time rate need to be distinguished explicitly.

| Hall | Emphasis | Proposed contribution and limit |
|---|---|---|
| [Change_Intro](../../../../commons/maps/Change_Intro/tutorial.md) | Together | Return to two points and their segment. Compare rise/run over a chosen interval; accumulate height-times-width contributions with the known loop. The existing workbenches use position as the independent variable. A separate, short time-sampling example prepares motion; it is not already demonstrated by those plots. |
| [Flow_Field](../../../../commons/maps/Flow_Field/tutorial.md) | Together | Read a direction at the current position and take one step; the new position becomes the next query. Supply the noise or field generator initially. Distinguish this assigned direction from a velocity that carries momentum. |

Carry into Forces the need for a remembered velocity. The field can say where to go next without explaining how a moving body responds to that instruction.

## 7. Forces — what the body does with an input

Vectors return here in a new role. They were already positions and displacements; now we give rates, influences and responses separate meanings and units. Avoid retelling the entire Point Coordinates lesson.

| Hall | Emphasis | Proposed contribution and limit |
|---|---|---|
| [Vectors_Act1_WhatAVectorIs](../../../../commons/maps/Vectors_Act1_WhatAVectorIs/tutorial.md) | Together | Shift both endpoints without changing their difference; compare direction and magnitude. This is a return to Lines, now preparing motion. |
| [VFM_02_Operations](../../../../commons/maps/VFM_02_Operations/tutorial.md) | Tutorial | Add displacements; compare the route with the resultant. Reuse a short list of segments. An out-and-back journey can sum to zero without having length zero. |
| [Vectors_Act2_VectorArithmetic](../../../../commons/maps/Vectors_Act2_VectorArithmetic/tutorial.md) | Together | Subtraction reverses direction when its arguments exchange; projection retains a component. Select the needed operations and show their result. The crank can remain an encounter before a full torque model. |
| [VFM_05_Launch](../../../../commons/maps/VFM_05_Launch/final.md) | Reading | In the current order, encounter a supplied analytic flight and vary its initial conditions. Do not claim the learner has built an integrator yet. If making the flight is compulsory here, move Motion before this hall. |
| [VFM_03_Motion](../../../../commons/maps/VFM_03_Motion/tutorial.md) | Tutorial | Keep velocity between updates; acceleration changes velocity, velocity changes position. Compare a finite push with what continues afterward. State the timestep and units. Use a reduced numerical model before opening the engine's rigid-body solver. |
| [Vectors_Act3_FieldsAndMotion](../../../../commons/maps/Vectors_Act3_FieldsAndMotion/tutorial.md) | Together | Sample the same field for two receivers: one replaces velocity, another changes it. Reuse Flow Field and Motion to show why the receiver matters. |
| [Vectors_Act4a_KineticForces](../../../../commons/maps/Vectors_Act4a_KineticForces/tutorial.md) | Together | Apply one drag law to stored velocity; compare coefficients. Keep applied force, annotated work and prescribed circular motion distinct. They need not become one large exercise. |
| [Vectors_Act4b_Oscillation](../../../../commons/maps/Vectors_Act4b_Oscillation/tutorial.md) | Tutorial | Displacement produces a restoring influence; retained velocity can carry a body through equilibrium. Change damping. This prepares Waves without having to teach every oscillation representation now. |
| [Change_Choreography](../../../../commons/maps/Change_Choreography/tutorial.md) | Together | Revisit rate through phase drift and unequal throughput. Use a small repeated-angle rule or queue count. Compare prescribed clocks with contact-driven transport. |
| [VFM_07_Gravity](../../../../commons/maps/VFM_07_Gravity/tutorial.md) | Together | Let relative position determine attraction; compare a fixed source and mutual response. Choose one existing model for the tutorial, naming its assumptions. |
| [VFM_09_Legs](../../../../commons/maps/VFM_09_Legs/final.md) | Reading | Compare actual support with an animated gait. The student can reposition supports or a load using known tools; a complete locomotion controller is a later construction. |
| [VFM_08_Arena](../../../../commons/maps/VFM_08_Arena/final.md) | Together | A condition selects a target; a different model handles collision. Choose one small state or selection rule to teach. Full creature control and collision solving remain supplied. |
| [Vectors_Act5_ForceAsPlace](../../../../commons/maps/Vectors_Act5_ForceAsPlace/tutorial.md) | Together | Connect a region's influence to a named receiver, then observe entry and departure. Reuse thresholds and integration. Similar-looking bodies do not necessarily implement the same response. |

The sequence can carry physical intuition and programming together without implying that every authored motion is simulated force. This distinction becomes essential when a form seems to find itself in the next sequence.

## 8. Form-finding — the conditions are authored too

The useful learner construction is a small update or constraint. A whole spring solver, recursive truss and annealer are not all necessary assignments. The critical text should retain its challenge to what counts as improvement.

| Hall | Emphasis | Proposed contribution and limit |
|---|---|---|
| [FormFinding_Descent](../../../../commons/maps/FormFinding_Descent/tutorial.md) | Together | Evaluate a cost, estimate or supply its slope, take a step, compare the result. Reuse Change's differences. An optimisation step is not automatically a physical timestep. |
| [FormFinding_Catenary](../../../../commons/maps/FormFinding_Catenary/final.md) | Reading | Compare drawn, formula-generated and physically motivated forms. Change anchors in a supplied sampler. Deriving hyperbolic functions or a soap-film solver is not required to inspect the distinction. |
| [FormFinding_Relaxation](../../../../commons/maps/FormFinding_Relaxation/tutorial.md) | Tutorial | Retain current/previous positions and apply one distance constraint between two points. Repeat corrections and vary the budget. Supply the large mesh; the learner understands one relation that participates in it. |
| [FormFinding_Equilibrium](../../../../commons/maps/FormFinding_Equilibrium/final.md) | Together | Balance a small pair of contributions and predict a pivot. Distinguish precomputed balance from ongoing response. Recursive bracing and a complete structural solver can remain extensions. |
| [FormFinding_Annealing](../../../../commons/maps/FormFinding_Annealing/final.md) | Reading | Inspect how allowing an uphill proposal can leave a local trap. Supply the random proposal and acceptance mechanism for this visit. A manual or supplied-candidate comparison can expose the decision. Return to the generator and probabilistic acceptance after Randomness. |
| [FormFinding_Forge](../../../../commons/maps/FormFinding_Forge/final.md) | Together | Change one criterion for a satisfactory arrangement; distinguish stability, height and a prescribed target. Teach a small predicate or stopping rule. Do not equate a target interpolation with discovering the shape by minimisation. |

Annealing is an example of why a short introduction and a deeper study should be separate. The bounded draw from Array can now propose a change. Investigating why a worse state is sometimes accepted is new work; the acceptance law and search schedule must be explained or explicitly supplied. Revisit their statistical behaviour in Randomness. This does not require moving the whole Randomness sequence before Form-finding.

## 9. Wavefunctions — a return is not necessarily a repeated state

Keep physically evolved motion, prescribed oscillation and sampled records distinct. Reuse Trace's list, Transformation's angle and Change's rate. Sound is a receiver with its own sampling and event timing, not proof that every visual wave already makes audio.

| Hall, in current order | Emphasis | Proposed contribution and limit |
|---|---|---|
| [WaveFunctions_Intro](../../../../commons/maps/WaveFunctions_Intro/tutorial.md) | Together | Compare the released pendulum with the clocked cubes. A hand changes one future and not the other. Recover the difference between retained state and evaluation from time. |
| [WaveFunctions_Pendulum](../../../../commons/maps/WaveFunctions_Pendulum/tutorial.md) | Together | Reuse the motion update and record samples of the swing. Separate the physical step, recording interval and display spacing. Supply the instrument beyond the small update being inspected. |
| [WaveFunctions_Sine_Space](../../../../commons/maps/WaveFunctions_Sine_Space/tutorial.md) | Together | A sampled function becomes a surface and sometimes a collider. Reuse Transformation's sine operation with a spatial input; change one amplitude or wavelength. Unit Circle then gives that usable operation a geometric account. A local swap remains possible but is not required merely to introduce sine. |
| [WaveFunctions_Unit_Circle](../../../../commons/maps/WaveFunctions_Unit_Circle/tutorial.md) | Tutorial | Follow a rotating point, read one component and keep its samples. Give phase, sine and cosine a concrete relation. This opens the sampler borrowed in Portals and the clocked motions seen earlier. |
| [WaveFunctions_3D_Wave_Propagation](../../../../commons/maps/WaveFunctions_3D_Wave_Propagation/tutorial.md) | Tutorial | Let phase depend on distance and add contributions. Start with one source and a small row of receivers before the volume. |
| [WaveFunctions_Effect_Sound](../../../../commons/maps/WaveFunctions_Effect_Sound/tutorial.md) | Together | Put one oscillation inside another's phase. Change one parameter and compare against a held reference. Supply audio infrastructure; keep the chosen formula and sample output visible. |
| [Wavefunctions_Bernini](../../../../commons/maps/Wavefunctions_Bernini/final.md) | Reading | Evaluate a changing angle along height; a spatial parameter carries what previously unfolded in time. Return to the column without requiring a whole architectural generator. |
| [WaveFunctions_John_Cage](../../../../commons/maps/WaveFunctions_John_Cage/final.md) | Reading | Listen to the choices admitted by a prepared sound vocabulary and scheduler. A known bounded draw can choose from that vocabulary; keep the full scheduler supplied and investigate its selection policy in Randomness. Do not teach an ambient microphone instrument as though it were this installed encounter. |
| [WaveFunctions_AirMusic](../../../../commons/maps/WaveFunctions_AirMusic/tutorial.md) | Together | Let one event give a response its own start time; another response can overlap it. Reuse state and clocks. Supply contact detection and audio playback. |
| [Wavefunctions_Sky_Stairs](../../../../commons/maps/Wavefunctions_Sky_Stairs/final.md) | Reading | Compare a sampled path with a usable route. Change a step spacing or radius using known functions. Collision and bodily reach remain explicit conditions. |
| [WaveFunctions_TrigWalkingPath](../../../../commons/maps/WaveFunctions_TrigWalkingPath/tutorial.md) | Together | Use the current beat-frequency encounter: add two close frequencies and follow the slower envelope. Its inherited map name need not determine the lesson. |
| [WaveFunctions_Synthesis_Lab](../../../../commons/maps/WaveFunctions_Synthesis_Lab/tutorial.md) | Tutorial | Store component amounts and sum their evaluated contributions. Reuse the list, loop and function. Distinguish a recalculated sum from a feedback process that retains the previous result. |

At exit, we can recreate a result by specifying its inputs and procedure. Random Definition keeps that question of return, but now a generator has a state and the order of requests matters.

## 10. Randomness — what a draw is allowed to change

Begin with a short return to the bounded draw and repeatable seed already used in Array. The sequence then opens different kinds and uses of randomness: state and request order, selection, distributions, walks, populations and feedback. Follow a draw into its use: an attribute, a selected member, a step, a measurement or a condition for another event. Retain the distinction between a simulated die's physical outcome and a pseudo-random number request.

| Hall | Emphasis | Proposed contribution and limit |
|---|---|---|
| [Random_Definition](../../../../commons/maps/Random_Definition/tutorial.md) | Tutorial | Draw a value with a local generator, reset its seed and replay the request order. Assign the draws to a small familiar colour grid. The existing standalone study is a strong making anchor. |
| [Random_Entropy](../../../../commons/maps/Random_Entropy/tutorial.md) | Together | Count a finite alphabet; rearrange the same values and compare what the count preserves. Supply the entropy calculation initially while teaching the histogram. Derive the logarithmic quantity only in a clearly marked extension. |
| [Random_Remove](../../../../commons/maps/Random_Remove/tutorial.md) | Together | Define the eligible set, choose an entry and retain which entries remain. Probability depends on that set and the procedure. Compare a missing occupant with a missing address. |
| [Randomness_10_PRINT_Algorithm](../../../../commons/maps/Randomness_10_PRINT_Algorithm/final.md) | Tutorial | Give each grid cell one of two diagonal states. Reuse the floor motif, loop and source rule. Make the probability threshold visible; equal choice probability does not make every realised pattern symmetrical. |
| [Random_Cubes](../../../../commons/maps/Random_Cubes/final.md) | Together | Use the current dice encounters to collect frequencies and preserve a short ordered record. Compare a sum with its ingredients. Supply the physical die. The current edge-profile tutorial describes a different construction and should be replaced or clearly retained as an optional separate study. |
| [Random_Rotate_Random_XYZ](../../../../commons/maps/Random_Rotate_Random_XYZ/final.md) | Together | Apply draws to chosen transform parameters while keeping the parts. Reuse Transformation. Independent uniform angle choices do not automatically mean uniform spatial orientations; avoid that promise. |
| [Random_Walk](../../../../commons/maps/Random_Walk/tutorial.md) | Tutorial | Sample the next step, update position and keep a bounded trace. Distinguish the history displayed from the information the next choice actually uses. The boundary participates. |
| [Random_Gaussian](../../../../commons/maps/Random_Gaussian/tutorial.md) | Together | Compare a sampled value with a histogram and its binning rule. Use a supplied distribution sampler first; a guarded transform can be opened later. A statistical expectation is not a promise about the next draw. |
| [Random_Mushrooms](../../../../commons/maps/Random_Mushrooms/tutorial.md) | Together | Assign draws to named construction parameters; compare populations with controlled recipes. Reuse the primitive-generating function. Keep the admitted repertoire separate from how often its parameters occur. |
| [Random_Space_Geometry](../../../../commons/maps/Random_Space_Geometry/final.md) | Reading | Compare independent heights with a coherent field on the actual bench. Teach reading neighbouring differences; supply the noise generator and return to it in Noise. The current tutorial needs alignment with this selected encounter. |
| [Randomness_Examples_of_Randomness](../../../../commons/maps/Randomness_Examples_of_Randomness/tutorial.md) | Reading | Compare uses of a draw across marks, estimates, permitted paths and particles. Choose the dartboard's hit/total estimate as an optional small application; the other works remain a gallery of differences. |
| [Random_Pheromone](../../../../commons/maps/Random_Pheromone/final.md) | Together | Let a deposited field enter a later choice. Reuse grid, walker and trace, but now the trace helps cause the next step. Choose the existing attract/avoid comparison instead of assuming an unrelated ant system. |
| [Random_Space](../../../../commons/maps/Random_Space/final.md) | Reading | Follow the current layered field: frequency, weight and seeded offsets. Reuse Synthesis Lab's sum. The current sine-based display is a bridge to Noise, not evidence that every layered texture uses the same noise algorithm. Its tutorial describes a different arena. |
| [Random_Game](../../../../commons/maps/Random_Game/tutorial.md) | Together | Compare when an outcome is assigned, revealed and acted upon. Reuse conditions and stored state in a reduced game. Changing what the visitor knows need not change the underlying draw. |

Return after Randomness to the annealing proposal and the supplied sound scheduler: which generator is used, which choices are eligible, and what changes when the seed or request order changes? The earlier usable draw now has a deeper account and places to test it.

## Order decisions

| Decision | Recommendation | Reason and consequence |
|---|---|---|
| Whole sequences 1–10 | Keep. | The construction, repetition, attribute, variation, motion, settling, recurrence and choice line is convincing. Moving whole sequences would not repair mismatched or missing tutorials. |
| Floor and wall tiling inside Array, before Colour | Keep. | A restricted palette isolates the arrangement. Later Tiling adds authorship, sharing and receivers. These are different uses of related material. |
| Platonic construction and functions | Teach a small generator in Primitives_Ignorance; no move needed. | Points, lists, traversal and faces are already available. Functions answer a current need instead of waiting for Colour. |
| Launch before Motion | Keep as an encounter with a supplied analytic model initially. | Motion then opens retained velocity. If each hall must contain a from-scratch construction, exchange these two locally. Do not falsely describe the analytic flight as the same update as the force-driven cube. |
| Annealing before Randomness | Keep, with a declared return. | Array introduces the bounded draw. Form-finding uses it to propose a change and studies acceptance; Randomness develops the statistical questions. |
| Sine Space before Unit Circle | Keep for the first trial; compare a local swap only if it improves the lessons. | Transformation already gives the learner a usable sine operation. The circle is a deeper geometric explanation, not a prerequisite for every use. |
| Cage before the end of Waves and before Randomness | Keep. | Listening and the limits of the authored vocabulary carry this hall. A draw is already available; its policy and the full scheduler have later returns. |
| Noise previews in Flow Field and Randomness | Keep. | Using a declared field sampler can precede constructing it. Noise later investigates spatial dependence; previews must not pretend to teach its internal algorithm. |

The two tracks should not contradict one another about facts, but they need not disclose everything in the same order. There is no requirement that a critical chapter end with a programming prerequisite sentence. A short tutorial return can carry the construction across a reflective hall.

## What needs fixing before trusting the current tutorials as this curriculum

The current route contains **87 maps** through Randomness. **83 have tutorial.md**. Existence does not establish that they are complete, runnable or aligned with the present encounter.

1. **Array and the three Ribbon maps have no tutorial.md.** Give Array a real making lesson. The Ribbon maps can initially have small applications and declared supplied components; they need not become new shader and avatar courses.
2. **Tutorial_Tiling_Floor and Tutorial_Tiling_Walls are brief encounter notes.** They cannot yet carry the proposed progression from an address rule to a shared pattern on different receivers.
3. **Tutorial_Disco disagrees with the current final.md about the apparatus.** The tutorial opens with a 17×17 floor triggered by footsteps. The current text describes a twelve-column floor, a sixteen-step sequencer, independent clocks and a one-way flash connection. Source-check the chosen apparatus when writing the replacement.
4. **Several later tutorials describe a different construction from the selected current encounter.** Clear examples are WaveFunctions_John_Cage, Random_Cubes and Random_Space. The current critical texts concern a prepared chance soundscape, dice records and a layered field respectively. Their tutorials describe an ambient listener, edge-profile cubes and a composite finale arena. Preserve usable studies as optional work; do not call them the current hall's implementation.
5. **Form-finding sometimes promises too much.** Forge's final.md distinguishes a detector's height/stability criteria and a prescribed target from discovered form. Its tutorial's claim that settling and training are simply one algorithm, and that no form was specified, needs narrowing. A reduced lesson should preserve the distinctions visible in the encounter.
6. **Technical details still need checking during each rewrite.** For example, Unit Circle's tutorial says a quarter-turn chord equals the radius; equal-radius points a quarter turn apart are separated by radius times sqrt(2). This is a specific correction, not a reason to discard the hall. No full numerical or runnable-code audit was performed for this outline.

## Working method

For each next map, write four short notes before prose: what the student brings; which operation in which artifact they will own; what is supplied; where that operation returns. Include the critical question only where it is alive in the material. Keep other artifacts available without making the final text their inventory.

Then write one lesson and run its reduced example. Ask whether the student can change it deliberately and predict a consequence. Check its relation to the museum's real operation. Only then carry its prerequisite claims into the next lesson. A successful small example does not certify the entire artifact or VR encounter.

Start with the already agreed Point Zero and Point One revisions, then carry one code-created marker through Coordinates, Lines and Trace. Establish the list/loop lesson before revising the later references that currently say these skills first came from Array. Test the Platonic generator as the first small function that returns data. Fill the missing Array lesson next in its proper turn; it is a major bridge rather than permission to skip the early checks.

Automation can collect order, links, missing files, code declarations and reference mismatches. It cannot decide which encounter deserves to carry a question or what the learner can absorb at this moment. This document records editorial choices to test, rather than a mechanical allocation of one language feature per room.

## Basis and scope

Order comes from [curriculum_spine.json](../../../../commons/maps/curriculum_spine.json) and the ten sequence files in [commons/maps/sequences](../../../../commons/maps/sequences). The outline was informed by the headings and opening/closing passages of current tutorial.md and final.md across the route, selected intent.md files, and closer reading at the principal dependency breaks: Trace, the Array/Disco transition, Change, force/velocity distinctions, Annealing/Forge, Unit Circle/Cage and the opening of Randomness. The Platonic proposal also draws on the inspected vertex and face tables in [polyhedron_factory.gd](../../../../commons/primitives/shared/polyhedron_factory.gd).

This is a source-informed curriculum proposal, not a claim to have reread every paragraph or run every museum artifact. The chapter texts, course code, map placements and spine order remain unchanged by this pass.
