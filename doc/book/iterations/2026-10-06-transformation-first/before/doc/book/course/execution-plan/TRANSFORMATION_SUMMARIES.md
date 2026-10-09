# Transformation — tutorial summaries

6 October 2026 · Proposed next writing pass · Seven halls in the existing spine order

## The sequence in one paragraph

Carry the recognisable cube built in Primitives into the working Endless Museum and give it behaviour. First make time change its position; then let an action change its destination. Use a retained index to follow a route, an offset to turn around a centre, and a parent to transform a group. Replace the clock with the visitor's position, distinguishing a present condition from a remembered encounter. Finally, combine these operations into a small opening mechanism. Keep the forms in black, white and grey so that position, orientation, size and timing carry the comparisons. The sphere returns as a familiar reference and a transfer exercise. The chapter develops programming through things the student can change and explain: from constructing a body to authoring what it does.

## Are we ready?

**Yes, to write the next tutorial one hall at a time. Primitives establishes the core vocabulary; it does not finish basic programming.** Transformation is the right place to develop state, branches, events and change through time. No preliminary catch-all programming chapter is needed.

| Foundation | What the current Primitives tutorials explain | What should develop next |
| --- | --- | --- |
| Execution | `_ready()`, `_process()`, calls, initialization: Point Zero. | Seconds, update rate and state across callbacks: Trans_Pre. |
| Values and references | Constants, variables, position values, object creation and properties: Point One and Coordinates. | Member state versus temporary local calculations; explicit units and frames. |
| Classes and instances | PointBody in Lines; CubeBody extends FaceBody in Cube; independent meshes and arrays. | Add behaviour to familiar constructions; do not introduce classes again as though they were new. |
| Arrays and loops | Retained positions, indexing and neighbour traversal in Trace; face indices; nested loops in Columns. | A route index retained across frames, then collections of independent objects in Arrays. |
| Conditions | Trace's distance threshold; finite stopping and a work budget in Portals. | Explain complementary `if/else` branches, boundary cases, current booleans and remembered flags. |
| Functions | Calls throughout; parameters, arguments, local results and typed returns in Ignorance. | Small update, request and reset functions with explicit responsibilities. |
| Events | Pickup is supplied; Trace explains connecting release to saving. | Make event → handler → state → visible response an explicit lesson in Trans_Introduction. |
| Checking a result | Predictions, changed examples, assertions and independent variations are present. | Predict intermediate states, inspect values, isolate a fault and reset repeatedly. |

The old 4 October foundation plan deferred the first authored class to Colour. The actual lessons have since moved that introduction to Lines. Treat Colour's later class work as development and reuse. Likewise, the supplied timer in Godot Primitives is an encounter with timing, not proof that the student can author a timing rule. The tests establish program behaviour; human understanding remains unobserved.

## 1. Trans_Pre — give the cube a clock

Return to the student's CubeBody, retaining its mesh and grayscale appearance. In a small study inside this hall, move it between two declared positions by accumulating `delta` in seconds and deriving a bounded interpolation fraction. Start with one journey that stops at its destination: explain which variable persists, which value is recalculated, and what `if/else` does at the duration boundary. Change duration while keeping endpoints fixed; predict the start, midpoint and finish, then reset and repeat. The museum's collection system stays supplied. Once this works, an optional linear-return versus sine comparison introduces period and range; the circular explanation waits for Waves. Carry the cube and its explicit timing rule.

## 2. Trans_Introduction — a request is not the movement

At the existing MOVE THE BANK crossing, move the slider and press RESET while the landing is travelling. Continue the learner's cube as a small visible model of that response. Connect the declared controls to a named function that sets a bounded target; let an update function bring the current position towards it. Explain signal, handler and argument by following one request through the code. RESET requests the home target rather than teleporting the body, matching the installed landing. Test both inputs, repeat RESET during travel, and change speed without changing the destination. Control construction, the physical crossing and rider transport remain supplied. Carry target/current state and reusable event handling.

## 3. Trans_Translation — remember the next destination

The hall's carriers take different journeys. Give the familiar cube a short array of waypoints in one declared local frame, reusing Trace's ordered positions and Lines' displacement and distance. Keep a route index between updates and move only as far as the elapsed time permits. Explain why looping over every waypoint immediately would not animate a journey. Guard repeated positions before normalising or dividing; finish at the last waypoint, with reset returning to the start. Try unequal leg lengths and a repeated waypoint, then compare two frame intervals over equal simulated time. The learner controls a visible route model; carrying the visitor remains supplied. Carry ordered data that now directs motion.

## 4. Trans_Rotation — choose the centre of a turn

Follow a marked face in the museum's rotation studies, then turn the same learner cube about a named axis and pivot. Reuse Coordinates' frames and Ignorance's returning functions: subtract the centre, rotate the offset, then add the centre back. Explain radians, angular rate and elapsed time at the point of use; keep the rotation mathematics provided by the engine. Compare turning in place with orbiting an offset centre, then reverse an X/Y turn pair on the marked cube. Predict a quarter-turn position and check that the radius remains fixed. The ride physics stays supplied. Carry a reusable turn rule whose frame, pivot and operation order are explicit.

## 5. Trans_Scale — change a group, keep a witness

The bottle enlarges the museum's small room while the visitor remains the reference. Reuse two CubeBody instances under one explicitly created parent, with the familiar sphere outside the group as a fixed witness. Apply a positive uniform scale to the parent and predict both the children's apparent sizes and the distances between their centres. Compare their unchanged local positions with changed world positions. Set scale from a saved starting value rather than repeatedly multiplying it each frame; reset without replacing the instances. The museum's bottle, visitor relocation and physical boundaries remain supplied. Carry an understanding of transform ownership: a group's change reaches its children, not everything nearby.

## 6. Trans_Body — respond now, remember afterwards

Watch the slats and blocks return when you leave, while the cut lattice retains your passage. Give one familiar cube a bounded response to a supplied visitor-position value, converted into the study's frame. Compute `near` afresh each update; keep a separate `visited` flag after the first approach. Explain the difference between a temporary observation and stored state, adding `and` or `not` only where the selected condition requires it. Approach, leave and return; predict the reversible size response and persistent flag, then clear the memory deliberately. Test the exact distance boundary. Tracking, collision adaptation and carving remain supplied. Carry one input with two different rules for what survives it.

## 7. Trans_Pit — make the operations work together

Use the existing two-leaf exit as the final comparison, then compose a small mechanism from two instances of the learner's cube. One bounded opening fraction drives their translation, rotation and scale; a supplied occupancy input requests opening, and an empty interval permits closing. Reuse functions, branches, elapsed time and retained state without adding a new syntax topic. Stop at an intermediate fraction and predict both leaves' poses before running them. Test approach, departure, re-entry and reset, including repeated requests; then choose another timing rule. The museum's doorway and collision implementation remain supplied, and a visual gap alone does not prove passage. Carry a coordinated behaviour ready to apply across a collection in Arrays.

## What the full lessons must deliver

- Work inside the existing museum. Name the study's host and placement before writing code; distinguish its reconstruction from the installed artifact. Reuse classes and saved code, without claiming one live node persists through every hall.
- Print the complete small program once in each `tutorial.md`, with every required small helper visible and inherited files identified. No hidden label, cube or unexplained scene lookup. Explain new operations close to their use; keep `final.md` reflective.
- Run the exact printed source, the exercise variant and a relevant deliberately broken version. Check timing boundaries, independent instances, frames and reset behaviour where applicable. A running museum artifact is not evidence that the reduced tutorial runs.
- End with a small transfer: apply one learned motion to PointBody while keeping its construction. Declare who owns movement; do not let animation fight the XR hand during a grab. This is an exercise to implement and test, not a claim that a persistent catalyst has already been built.

## What remains to write

The seven summaries above are **proposals for the next full lessons**, not a report that those lessons already meet the current contract. Trans_Pre still uses the older starter and excerpts. Trans_Introduction explains the installed landing through excerpts. Translation, Rotation, Scale, Body and Pit largely describe production mechanisms rather than print the selected complete learner programs. The existing order fits the proposed progression; no hall needs moving to begin.

Arrays should deepen collection ownership, shared references and indexed updates. Colour should deepen functions, values, material ownership and independent object state. Together these sequences can consolidate the foundations before the later Randomness study. Dictionaries, extensive inheritance hierarchies, general matrix algebra, serialization internals and XR-player implementation need not be prerequisites here.

Source basis: [current seven-hall order](../../../../commons/maps/sequences/transformation.json), the corresponding current `tutorial.md` files, [Primitives takeaways](PRIMITIVES_TAKEAWAYS.md), [editable execution plan](http://localhost:3003/tutorial-plan?view=summaries&map=Trans_Pre), and [the reconstruction rules](../functional_text/RECONSTRUCTION.md). The installed [landing](../../../../commons/artifacts/adjustable_landing/adjustable_landing.gd) and [airlock](../../../../commons/artifacts/transformation_airlock/transformation_airlock.gd) ground the event and closing-mechanism summaries. The plan UI retains its existing drafts; this file is the consolidated review proposal. No tutorial, reflective text, spine order or museum code changed in this pass.
