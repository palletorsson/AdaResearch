# The point gains power: thirty upgrades for Vectors & Forces

Design proposal only; current thirteen-hall order retained. No runtime, tutorial.md or final.md changes. Source inspection is not a runtime test.

You bring the familiar point into a wing where it first describes a movement, then receives forces, becomes a tool, and helps you work with a room that keeps changing. The continuing task is to carry it to a new place; each hall changes what that task requires.

SAME POINT + SAME CUBE. 13 core hall lessons; practice reuses them; extensions remain optional. Describe → launch → retain motion → meet resistance → return → accumulate → interact → compose. One visible question, one controllable change, one readable consequence. Precision and failure both remain possible.

## Narrative

### I. Describe the journey

The point is familiar. What changes is how you describe its relation to another place. You learn to preserve a direction, combine a route and decide which part of a gap matters.

Ideas: 1, 2, 3, 4, 5, 6, 7, 8

### II. Give the point motion

A predicted arc reaches across the room. Then the point keeps a velocity after your command ends. The same object becomes a thruster; now you must learn how to arrive.

Ideas: 9, 10, 11, 12, 13

### III. Meet the room

The room has its own conditions. Identical arrows produce different receiver responses. Surfaces resist, channels guide and a released point continues beyond the apparatus.

Ideas: 14, 15, 16, 17, 18, 19

### IV. Let one event reach another

A spring returns the point. Another body receives its movement. Cycles can align or drift, and the conveyor makes delay accumulate into an altered room.

Ideas: 20, 21, 22, 23, 24

### V. Other bodies answer

Attraction affects more than a nominated target. A source may also move; a support may cease to support. The student encounters bodies with their own conditions of stability.

Ideas: 25, 26, 27, 28

### VI. Make another way through

A deflection opens a passage. The final task asks the student to choose among learned operations, including a use for the aftermath. The same point becomes part of their capacity to inhabit the world.

Ideas: 29, 30

## The existing halls

### 1. Vectors_Act1_WhatAVectorIs — A relation I can carry

Revisit the point and line. Move both endpoints together, then change their separation. The learner distinguishes a position, a displacement and its displayed arrow; a unit direction becomes available for later aiming.

**Reflective question:** What survives when a relation moves?

### 2. VFM_02_Operations — One destination, more than one journey

Join two displacements using the familiar point. Compare the resultant with the travelled route, then make another route to the same place. This prepares addition of compatible velocity or force contributions without treating them as the same quantity.

**Reflective question:** What does a destination omit?

### 3. Vectors_Act2_VectorArithmetic — What part of the relation matters?

Use a moving target to construct a gap, compare directions, and resolve the gap along a rail plus a remainder. Keep projection as the main code lesson. Dot-product aiming is a return; the lever is a preview whose physical dynamics arrive later.

**Reflective question:** Who decides which component counts?

### 4. VFM_05_Launch — A prediction crosses the room

Give the point an initial velocity and compare the predicted path with a chosen receiver. Use the already supplied trajectory runner; name gravity and starting conditions without teaching an entire solver. A launch-pad crossing lets the player experience the same trajectory idea.

**Reflective question:** What did the prediction assume about arrival?

### 5. VFM_03_Motion — The point keeps moving

Continue with an actual dynamic point. Apply a finite force, release it, brake it, and compare masses. The new lesson is retained velocity under force. Two held points then reuse normalization and addition to provide the agreed thrust ability.

**Reflective question:** What continues after the command ends?

### 6. Vectors_Act3_FieldsAndMotion — The room answers

Give two receivers the same spatial vector: one takes it as velocity, the other as acceleration. Reuse the point's state instead of replacing it with a fresh particle system. The vortex combines radial and tangential contributions as practice.

**Reflective question:** Does an arrow command a speed or change it?

### 7. Vectors_Act4a_KineticForces — Contact changes the journey

Carry the moving point into contact and resistance. Keep velocity-dependent drag as the new code lesson; use friction, an incline and a transparent curved channel as controlled comparisons. Make each model's constraints visible before adding spectacle.

**Reflective question:** Which histories does a model keep or erase?

### 8. Vectors_Act4b_Oscillation — A relation pulls back

Attach the point to a visible anchor. Extend it and release; compare return and damping while retaining velocity. Colliding spring balls and a hinged bridge are applications or optional joint studies, not prerequisites for understanding the spring.

**Reflective question:** What happens when the place of return can move?

### 9. Change_Choreography — One cycle changes the next

Reuse a known movement to make two cycles meet. Separate phase from rate in the small lesson, then use the conveyor's input and receiver rates to make accumulation visible. A robot-arm duet is an optional interpretation with supplied controllers.

**Reflective question:** Can two successful tasks prevent a shared result?

### 10. VFM_07_Gravity — The source is also a body

Upgrade the familiar point into a bounded attractor. Begin with one target, then compare a held source with a released source receiving the opposite interaction force. A three-body comparison is an optional later experiment.

**Reflective question:** What was being supported while the source looked fixed?

### 11. VFM_09_Legs — A body needs support

Place the known cube on finite supports; shift its mass distribution and release it. Make the static balance prediction and its limits explicit. The four-legged character is a supplied extension, whose commanded gait must not be mistaken for physical balance.

**Reflective question:** Which capacities does a body need to remain here?

### 12. VFM_08_Arena — Other bodies have conditions

Use the point's projectile to redirect a dynamic target, with selection and occlusion shown separately from collision response. Reuse known impulse and momentum; the new lesson is the receiver's eligibility and state. A bowling layout offers a quiet practice version.

**Reflective question:** Must making a passage mean destroying a body?

### 13. Vectors_Act5_ForceAsPlace — The experiment becomes a place

Deliver the point through a local acceleration field using the available tools. First compare the same field's cube and visitor adapters; then compose launch, brake, guide and support. The student chooses a route and explains its consequences.

**Reflective question:** What can we do with the room we have changed?

## Thirty upgrades

### 01. The arrow you can carry

**CORE · Vectors_Act1_WhatAVectorIs**

**Question:** Does the relation change when both points move?

Use the familiar black point as the movable endpoint. A paired handle shifts both ends; the arrow and two wall projections follow. Recall the unit-direction operation; idea 2 isolates it as practice.

**Learning elements:** Displacement, Reference frame, Magnitude, Direction normalization (revisited)

**Carry forward:** Point, coordinates and line.

**Precision:** Both endpoints translate together while their difference remains unchanged.

**Possible consequence:** A wall projection can shrink although the three-dimensional gap stays the same.

**Existing source:** The hall already has the room-reading vector and projection study.

**Implementation work:** Add recognizable point handles and one shared displacement readout; preserve the existing geometry model.

**Future acceptance check:** Translate both ends by the same offset and assert equal displacement; verify a changed gap and declared display scale.

**Builds on ideas:** earlier Point / Coordinates / Lines

- [algorithms/vectors/01_vector_basics/VectorBasics.gd](../../../../algorithms/vectors/01_vector_basics/VectorBasics.gd)

### 02. Aim without changing strength

**PRACTICE · Vectors_Act1_WhatAVectorIs**

**Question:** Can a longer pointing gesture keep the same direction?

Pair the long displacement arrow with a unit arrow carried by the same point. Change length, then direction; at coincident endpoints show no available direction.

**Learning elements:** Normalization, Direction versus magnitude, Zero-vector policy

**Carry forward:** A direction reused by aiming and thrust.

**Precision:** Long and short nonzero gaps produce the same unit direction.

**Possible consequence:** Coincident points cannot supply a direction; a visible threshold prevents an invented aim.

**Existing source:** The normalization study already uses a 0.001 magnitude threshold and reference sphere/rings.

**Implementation work:** Connect the familiar point input; retain and disclose that threshold rather than silently changing it.

**Future acceptance check:** Above threshold, unit length and collinearity; at/below threshold, documented zero result.

**Builds on ideas:** 1

- [commons/artifacts/vector_normalize_demo/vector_normalize_demo.gd](../../../../commons/artifacts/vector_normalize_demo/vector_normalize_demo.gd)

### 03. Two moves deliver one point

**CORE · VFM_02_Operations**

**Question:** Where do these two movements take it?

Extend vector_addition_walk into a delivery diagram: two placed displacement arrows carry the point to a marked plinth. Reveal the single resultant.

**Learning elements:** Vector addition, Head-to-tail construction, Compatible quantities

**Carry forward:** The same endpoint and displacement values.

**Precision:** Two legs end at origin plus a plus b.

**Possible consequence:** A reversed contribution changes the destination; the cancelled route may still have travelled a distance.

**Existing source:** Walked and console addition studies exist.

**Implementation work:** Add destination/route comparison around their arithmetic; this remains prescribed displacement, not force simulation.

**Future acceptance check:** Assert endpoint equals origin+a+b, including opposing inputs; label units as metres.

**Builds on ideas:** 1

- [commons/artifacts/vector_addition_walk/vector_addition_walk.gd](../../../../commons/artifacts/vector_addition_walk/vector_addition_walk.gd)
- [commons/artifacts/vector_op_console/vector_op_console.gd](../../../../commons/artifacts/vector_op_console/vector_op_console.gd)

### 04. Same arrival, different journey

**PRACTICE · VFM_02_Operations**

**Question:** Can two routes finish together and still differ?

Save two short routes for the point, both ending on the same plinth. Keep their traces, lengths and encountered obstacles beside the shared resultant.

**Learning elements:** Displacement versus path length, Ordered samples

**Carry forward:** Trace records and the sum from the previous encounter.

**Precision:** Two different routes agree on final displacement.

**Possible consequence:** One passes behind a screen or crosses an occupied space; a shared result does not promise the same experience.

**Existing source:** The installed addition route already distinguishes travelled distance from the result.

**Implementation work:** Reuse the Trace sample contract for a second bounded route; no automatic cross-hall persistence is assumed.

**Future acceptance check:** Compare equal endpoints, distinct recorded paths and summed segment lengths.

**Builds on ideas:** 3

- [commons/artifacts/vector_addition_walk/vector_addition_walk.gd](../../../../commons/artifacts/vector_addition_walk/vector_addition_walk.gd)

### 05. The target moved

**PRACTICE · Vectors_Act2_VectorArithmetic**

**Question:** What remains between the point and its destination?

Continue the shared gap room with the familiar point and a movable target cup. Moving either updates target minus source; swap them to reverse the gap.

**Learning elements:** Vector subtraction, Relative position

**Carry forward:** The same two positions, later used by attraction.

**Precision:** The arrow reaches the target from the source.

**Possible consequence:** Moving the destination changes the instruction even though the point has not moved.

**Existing source:** A bounded room_gap station and shared gap/projection data already exist.

**Implementation work:** Restyle endpoints as the carried point and receiver; keep the existing bounds visible.

**Future acceptance check:** Subtract, swap, coincide and shift both ends; assert sign and translation invariance.

**Builds on ideas:** 1, 3

- [commons/artifacts/vector_op_console/gap_projection_room.gd](../../../../commons/artifacts/vector_op_console/gap_projection_room.gd)

### 06. The rail keeps only part

**CORE · Vectors_Act2_VectorArithmetic**

**Question:** How much of this gap lies along the rail?

Make the projection station a small delivery rail. Show the point's along-rail destination and leave the perpendicular remainder visible as a second line.

**Learning elements:** Target minus source, Signed dot product, Projection, Perpendicular remainder

**Carry forward:** The gap from the previous encounter.

**Precision:** Along component plus remainder recovers the original gap.

**Possible consequence:** A point on the rail can be as close as this rule permits and still miss the target.

**Existing source:** The installed room_projection already exposes a unit rail, retained component and remainder.

**Implementation work:** Add a clear receiver at the projected position; treat the rail as a geometric constraint here.

**Future acceptance check:** Assert recombination and perpendicular remainder, including reversed rail and zero gap.

**Builds on ideas:** 1, 3

- [commons/artifacts/vector_op_console/gap_projection_room.gd](../../../../commons/artifacts/vector_op_console/gap_projection_room.gd)
- [commons/artifacts/projection_shadow/projection_shadow.gd](../../../../commons/artifacts/projection_shadow/projection_shadow.gd)

### 07. The receiver is looking elsewhere

**PRACTICE · Vectors_Act2_VectorArithmetic**

**Question:** Is the point inside the receiver's cone of attention?

Replace the dot_aligner's implied combat with an aimable receiver and a visible acceptance cone. Put the point ahead, sideways and behind before trying a threshold.

**Learning elements:** Normalized dot product, Angular threshold, Selection rule

**Carry forward:** Unit directions and signed dot.

**Precision:** A clearly aligned point is accepted.

**Possible consequence:** The nearest point can remain outside the receiver's chosen direction.

**Existing source:** DotAligner renders angular cases and a slider-driven classification; it is not a verified moving sensor.

**Implementation work:** Add actual point/controller directions and a declared threshold; keep distance and occlusion separate.

**Future acceptance check:** Check dot values for parallel, perpendicular and opposing directions, plus threshold boundaries.

**Builds on ideas:** 2, 5, 6

- [commons/artifacts/dot_aligner/dot_aligner.gd](../../../../commons/artifacts/dot_aligner/dot_aligner.gd)

### 08. Where you push will matter

**EXTENSION · Vectors_Act2_VectorArithmetic**

**Question:** Which applied direction can turn this lever?

Keep torque_crank as a geometric preview. Move the indicated application point and direction; compare parallel and perpendicular cases, then mark its later hinge return.

**Learning elements:** Cross product, Lever arm, Torque direction

**Carry forward:** The relation r cross F, reused with real dynamics later.

**Precision:** The preview identifies the same moment from a long weak and short strong push.

**Possible consequence:** Pushing along the lever can show zero moment despite a large force magnitude.

**Existing source:** Current crank is a static angular-factor diagram with generated readouts, not measured rotational dynamics.

**Implementation work:** Improve the preview labels now; physical hinge response belongs to idea 22 after Motion.

**Future acceptance check:** Verify vector cross-product direction and zero parallel moment; do not test a rendered angle as an angular acceleration.

**Builds on ideas:** 6, 7

- [commons/artifacts/torque_crank/torque_crank.gd](../../../../commons/artifacts/torque_crank/torque_crank.gd)

### 09. The cup across the room

**CORE · VFM_05_Launch**

**Question:** Will this initial velocity reach the receiver?

Keep the launch chamber's analytic predictor and place a cup at its proposed landing. Reuse the point appearance; compare high and low paths before enabling a physical trial variant.

**Learning elements:** Initial velocity, Constant acceleration, Trajectory assumptions

**Carry forward:** The direction, magnitude and saved trace.

**Precision:** A trial with matching declared assumptions reaches the predicted neighbourhood.

**Possible consequence:** An intervening ring contact changes the physical flight beyond the collision-free prediction.

**Existing source:** An analytic launch chamber and separate catapult artifacts exist; their matching is not yet verified.

**Implementation work:** Build a controlled comparison with matched initial state and gravity. Full force accumulation is explained in Motion.

**Future acceptance check:** Check sampled trajectory and landing height; compare a no-contact dynamic trial within a declared integration tolerance.

**Builds on ideas:** 1, 3, 6

- [commons/artifacts/launch_arc/launch_chamber.gd](../../../../commons/artifacts/launch_arc/launch_chamber.gd)
- [commons/artifacts/catapult/catapult.gd](../../../../commons/artifacts/catapult/catapult.gd)

### 10. Your body follows the arc

**PRACTICE · VFM_05_Launch**

**Question:** Can you land where you sent the point?

Put a short launch-pad course beside the sphere trial: generous platforms first, poles over the existing void only as an optional challenge.

**Learning elements:** Launch state, Ballistic motion, Landing velocity

**Carry forward:** The known launch setting applied through the player adapter.

**Precision:** A clear launch and landing complete the crossing.

**Possible consequence:** The correct destination with excessive arrival speed carries the body onward.

**Existing source:** Player launch artifacts exist; receiver behavior differs from the analytic point.

**Implementation work:** Declare whether each pad sets launch velocity or adds impulse; one activation per entry; desktop/VR adapter and landing checks.

**Future acceptance check:** Assert the chosen launch policy and re-entry behavior; test collisions and a recoverable landing before the void.

**Builds on ideas:** 9

- [commons/artifacts/force_pad/force_pad.gd](../../../../commons/artifacts/force_pad/force_pad.gd)
- [commons/artifacts/human_catapult/human_catapult.gd](../../../../commons/artifacts/human_catapult/human_catapult.gd)

### 11. Let go of the command

**CORE · VFM_03_Motion**

**Question:** Does the point stop when the push stops?

Upgrade motion_chamber with the familiar point beside its cube. PUSH, COAST and BRAKE retain their distinct meanings; a visible trail records the result.

**Learning elements:** Force, Mass and acceleration, Retained velocity, Engine integration

**Carry forward:** One dynamic point, later used for thrust and targets.

**Precision:** A timed push followed by braking stops near the chosen mark.

**Possible consequence:** COAST leaves velocity; the point can pass its intended destination.

**Existing source:** A real RigidBody3D pulse/coast/brake chamber exists with private collision layers and a bounded trail.

**Implementation work:** Add a same-contract sphere receiver; preserve the isolated baseline before opening it to room props.

**Future acceptance check:** Off contact and without damping, compare delta-v to F*t/m; COAST retains velocity; BRAKE opposes it without an authored overshoot.

**Builds on ideas:** 3, 9

- [algorithms/vectors/08_vector_motion/motion_chamber.gd](../../../../algorithms/vectors/08_vector_motion/motion_chamber.gd)

### 12. Same push, different body

**PRACTICE · VFM_03_Motion**

**Question:** Which body changes its velocity most?

Give equal-sized point receivers different explicitly labelled masses. Apply the same timed force and compare velocities before comparing collisions.

**Learning elements:** F=ma, Controlled comparison, Mass versus visual size

**Carry forward:** The force scheduler and receiver from Motion.

**Precision:** The measured velocity change follows the selected mass.

**Possible consequence:** A visually identical point is harder to accelerate because an invisible parameter differs.

**Existing source:** Motion already cycles 1/2/4 kg; an additional mass study exists.

**Implementation work:** Use Motion's actual receiver for side-by-side comparison; keep damping and contacts controlled.

**Future acceptance check:** Hold force/duration constant; test inverse mass response. Do not suggest heavier objects fall faster under common gravitational acceleration.

**Builds on ideas:** 11

- [algorithms/vectors/08_vector_motion/motion_chamber.gd](../../../../algorithms/vectors/08_vector_motion/motion_chamber.gd)
- [algorithms/forces/example_2_2_forces_mass_variation_vr.gd](../../../../algorithms/forces/example_2_2_forces_mass_variation_vr.gd)

### 13. Two points can carry you

**PRACTICE · VFM_03_Motion**

**Question:** Can two hands give you one controlled flight?

Continue the point as a thruster in each hand. Aim down/back and press triggers to rise/advance; change one hand, release both, then counter-thrust to land.

**Learning elements:** Vector sum of forces, Sustained thrust, Counter-thrust

**Carry forward:** The familiar point becomes a reusable player ability.

**Precision:** Balanced contributions produce an intended approach and landing.

**Possible consequence:** Releasing one hand changes the sum; releasing both leaves motion and gravity.

**Existing source:** Catalyst and XR receiver adapter exist; dual-point flight is still proposed.

**Implementation work:** One movement owner sums both inputs. Define mass/gravity/strength and a separate firing mode; resolve catalyst auto-return explicitly.

**Future acceptance check:** Each release removes only that input; no duplicate integration or velocity reset; compare desktop and synthetic XR before headset validation.

**Builds on ideas:** 2, 3, 11, 12

- [commons/artifacts/ignorance_gallery/resolution_catalyst.gd](../../../../commons/artifacts/ignorance_gallery/resolution_catalyst.gd)
- [commons/artifacts/force_field_zone/field_carry_provider.gd](../../../../commons/artifacts/force_field_zone/field_carry_provider.gd)

### 14. Same arrows, different journeys

**CORE · Vectors_Act3_FieldsAndMotion**

**Question:** What does this receiver do with the field?

Give two familiar points the same sampled field. One assigns velocity; the other receives acceleration into its retained velocity. Let the student switch the receiving rule.

**Learning elements:** Field sampling, Assignment versus accumulation, State update

**Carry forward:** The same point state and vector arithmetic.

**Precision:** Both trajectories match their declared update rules.

**Possible consequence:** Identical field arrows produce different paths because the receivers keep different state.

**Existing source:** The hall already compares two receiver contracts.

**Implementation work:** Replace anonymous display particles with a small recognizable pair; reuse the same bounded field sample.

**Future acceptance check:** Feed equal field values; assert velocity assignment on one and velocity increment on the other, including zero field.

**Builds on ideas:** 11

- [algorithms/vectors/10_vector_field_flow/VectorFieldFlow.gd](../../../../algorithms/vectors/10_vector_field_flow/VectorFieldFlow.gd)

### 15. The drain becomes an orbit

**PRACTICE · Vectors_Act3_FieldsAndMotion**

**Question:** Will gathering the point bring it to the centre?

Begin with one sphere and a radial attraction; add a tangential contribution. Then release a few loose cubes and let entry speed change the result.

**Learning elements:** Radial and tangential vectors, Force superposition, Incoming velocity

**Carry forward:** Direction, addition and an acceleration receiver.

**Precision:** A chosen field carries a point toward its receiver or into a sustained circulating path.

**Possible consequence:** A collecting rule can produce circulation or congestion instead of arrival.

**Existing source:** The installed vortex replaces player velocity; it cannot yet substantiate this acceleration-based encounter.

**Implementation work:** Make an explicit new additive variant; begin with loose points, then connect the player after matching contracts.

**Future acceptance check:** Bound the centre term; preserve incoming velocity; verify each contribution separately and zero contribution on exit.

**Builds on ideas:** 2, 3, 14

- [commons/artifacts/force_vortex/force_vortex.gd](../../../../commons/artifacts/force_vortex/force_vortex.gd)
- [commons/artifacts/force_field_zone/force_field_zone.gd](../../../../commons/artifacts/force_field_zone/force_field_zone.gd)

### 16. The tray refuses to move

**PRACTICE · Vectors_Act4a_KineticForces**

**Question:** How much of the applied push reaches movement?

Return to friction_ramp beside a small movable tray. Compare an increasing push on a level surface, then a changed incline; keep the original simplified model labelled.

**Learning elements:** Static threshold, Sliding friction, Normal contact

**Carry forward:** The same cube and force schedule.

**Precision:** A deliberate change crosses the starting threshold and permits delivery.

**Possible consequence:** A stuck tray can release and travel farther than expected; stopping is another task.

**Existing source:** Existing ramp is a prescribed one-axis scalar model with immediate static stop and end reset.

**Implementation work:** Add a separate physical tray comparison; do not silently present the old ramp as a full static/kinetic contact model.

**Future acceptance check:** Measure onset and post-release behavior for the declared model; check that a damping change is not mislabelled friction.

**Builds on ideas:** 11, 12

- [commons/artifacts/friction_ramp/friction_ramp.gd](../../../../commons/artifacts/friction_ramp/friction_ramp.gd)

### 17. The room takes speed away

**CORE · Vectors_Act4a_KineticForces**

**Question:** Why do equal starts finish differently?

Use drag_corridor's existing rigid receivers with matching initial speed. Give the point the same drag law, then use the mower as an optional signed-work comparison.

**Learning elements:** Velocity-dependent drag, Coefficient, Mass response

**Carry forward:** The inherited velocity state and force application.

**Precision:** A chosen resistance produces a repeatable slowdown.

**Possible consequence:** Equal initial speed does not guarantee equal distance; reversing motion reverses drag.

**Existing source:** Physical drag study exists. Mower reports configured nominal work, not measured hand effort.

**Implementation work:** Carry the point into the existing drag runner; keep work as a labelled side comparison rather than a second compulsory lesson.

**Future acceptance check:** For linear drag, force opposes velocity and vanishes at rest; compare damping and contact settings explicitly.

**Builds on ideas:** 11, 14

- [commons/artifacts/drag_corridor/kinetic_drag.gd](../../../../commons/artifacts/drag_corridor/kinetic_drag.gd)
- [commons/artifacts/force_mower/force_mower.gd](../../../../commons/artifacts/force_mower/force_mower.gd)

### 18. Slide, roll or tip?

**EXTENSION · Vectors_Act4a_KineticForces**

**Question:** Does changing one constraint change the race?

Build a shallow incline comparison from the wedge/ramp family. First release the same body with rotation locked and free; only then compare the sphere and cube.

**Learning elements:** Angular freedom, Friction, Shape and contact

**Carry forward:** The familiar bodies and controlled experiment.

**Precision:** A chosen constraint/shape produces an expected mode of movement.

**Possible consequence:** A cube catches an edge and tips, changing the contact that determined its path.

**Existing source:** Ramp and torque studies supply concepts; a coupled rigid-body roll/slide comparison is new.

**Implementation work:** Create a short physical lane with visible lock state and matched initial conditions; no scripted winner.

**Future acceptance check:** Verify lock/free cases and measured angular velocity; change one factor at a time before comparing shapes.

**Builds on ideas:** 8, 11, 16

- [commons/artifacts/friction_ramp/friction_ramp.gd](../../../../commons/artifacts/friction_ramp/friction_ramp.gd)
- [commons/artifacts/torque_crank/torque_crank.gd](../../../../commons/artifacts/torque_crank/torque_crank.gd)

### 19. Where the pipe lets go

**PRACTICE · Vectors_Act4a_KineticForces**

**Question:** Does the point keep curving after the guide ends?

Return the point to a transparent curved channel. A declared launch sends it around the bend; move a cup to predict its departure.

**Learning elements:** Contact constraint, Tangential departure, Gravity after release

**Carry forward:** The launch point and current velocity.

**Precision:** The cup receives the sphere after it leaves the channel.

**Possible consequence:** The receiver placed along an imagined continuing curve misses the free path.

**Existing source:** The ring currently prescribes circular motion; it is not a free contact-driven pipe.

**Implementation work:** Build actual segmented channel colliders and a visible outlet; compare with the prescribed ring rather than replacing it covertly.

**Future acceptance check:** Check collisions inside the curve and velocity direction at departure; no position snapping after exit.

**Builds on ideas:** 9, 11, 17

- [commons/artifacts/centrifuge_ring/centrifuge_ring.gd](../../../../commons/artifacts/centrifuge_ring/centrifuge_ring.gd)
- [commons/artifacts/launch_arc/launch_chamber.gd](../../../../commons/artifacts/launch_arc/launch_chamber.gd)

### 20. The point returns

**CORE · Vectors_Act4b_Oscillation**

**Question:** What makes it come back, and what makes it settle?

Continue spring_tower with the familiar point on a visible spring. Change rest length or stiffness, release from a chosen extension, then compare damping.

**Learning elements:** Restoring force, Rest length, Damping, Equilibrium

**Carry forward:** The point's velocity and force accumulator.

**Precision:** A chosen displacement produces a readable return that settles under damping.

**Possible consequence:** The point passes the resting position because restoring force does not erase velocity.

**Existing source:** An explicit one-axis spring-damper study and grab handle exist.

**Implementation work:** Preserve the minimal one-axis lesson; spatial tether becomes practice after this verified baseline.

**Future acceptance check:** Test force sign about rest, zero restoring force at rest, retained velocity and energy loss under damping.

**Builds on ideas:** 11, 17

- [commons/artifacts/spring_tower/restoring_forces.gd](../../../../commons/artifacts/spring_tower/restoring_forces.gd)

### 21. The second spring answers

**PRACTICE · Vectors_Act4b_Oscillation**

**Question:** Will the returning point strike its neighbour?

Place two spring-mounted points close enough to collide. Adjust spacing and release only one; later compare fixed versus movable anchors.

**Learning elements:** Coupled consequences, Contact transfer, Dynamic anchors

**Carry forward:** The spring law and the same point receiver.

**Precision:** A timed collision transfers motion in an intelligible rhythm.

**Possible consequence:** A slight spacing change creates a miss, an extra collision or a changed return.

**Existing source:** Spring references exist; free contact-coupled receivers and dynamic anchors need construction.

**Implementation work:** Keep spring force and collision integration owned once; apply opposite spring response to a dynamic anchor.

**Future acceptance check:** Verify isolated spring behavior before coupling; check contact, finite forces and anchor response without requiring a particular comic ending.

**Builds on ideas:** 20

- [commons/artifacts/spring_tower/restoring_forces.gd](../../../../commons/artifacts/spring_tower/restoring_forces.gd)
- [algorithms/physicssimulation/springsystem/spring_system.gd](../../../../algorithms/physicssimulation/springsystem/spring_system.gd)

### 22. A pole becomes your bridge

**EXTENSION · Vectors_Act4b_Oscillation**

**Question:** Where will the free end meet the ground?

Upgrade the existing hinge family into a falling pole with a visible pivot and stop. Release it toward a receiver; a slider latch can hold or release it in a later variant.

**Learning elements:** Hinge axis, Limits, Torque and support

**Carry forward:** The geometric lever relation becomes physical.

**Precision:** The pole settles on a support and makes a crossing.

**Possible consequence:** A poorly chosen stop leaves it short or knocks a loose support aside.

**Existing source:** Hinge and slider demos exist; inspected crank/drawbridge scripts set target speed without enabling their motors.

**Implementation work:** Verify motor flags, axes and limits first; begin with passive gravity-driven hinge release. Slider is supplied optional apparatus.

**Future acceptance check:** Assert allowed/blocked rotation, stable contact at support and usable reset. Motor-enabled behavior must be tested separately from passive swing.

**Builds on ideas:** 8, 11, 18

- [algorithms/joint/03_hinge_crank/HingeCrank.gd](../../../../algorithms/joint/03_hinge_crank/HingeCrank.gd)
- [algorithms/joint/09_drawbridge_hinge/DrawbridgeHinge.gd](../../../../algorithms/joint/09_drawbridge_hinge/DrawbridgeHinge.gd)
- [algorithms/joint/04_slider_press/SliderPress.gd](../../../../algorithms/joint/04_slider_press/SliderPress.gd)

### 23. Two cycles try to meet

**CORE · Change_Choreography**

**Question:** Is the gap between them fixed, or growing?

Use paired_time/phase rods to time a moving cup against a release gate. Adjust phase alone, then rate alone. A two-robot-arm exchange is an optional theatrical version.

**Learning elements:** Phase, Period, Relative rate

**Carry forward:** Known motion and named state.

**Precision:** Matched rate and chosen offset produce repeated successful handoffs.

**Possible consequence:** A small rate mismatch turns an initially perfect handoff into a later miss.

**Existing source:** Paired time and rods exist; robot arms are posed props without the proposed transfer controllers.

**Implementation work:** Keep the two-cycle comparison small. Add a cup/gate receiver; supply rather than teach robot kinematics here.

**Future acceptance check:** At equal rates verify constant phase difference; at unequal rates verify drift; reset clock and offset independently.

**Builds on ideas:** 9, 20

- [commons/artifacts/spine_studies/paired_time.gd](../../../../commons/artifacts/spine_studies/paired_time.gd)
- [commons/artifacts/timing_machines/phase_rod_array.gd](../../../../commons/artifacts/timing_machines/phase_rod_array.gd)
- [commons/artifacts/robot_arm/robot_arm.gd](../../../../commons/artifacts/robot_arm/robot_arm.gd)

### 24. The conveyor remembers the delay

**PRACTICE · Change_Choreography**

**Question:** Can the receiver keep up?

Return the familiar cubes to the existing conveyor. Pause the receiver briefly, restart it at equal rate, then increase its rate and compare the retained backlog.

**Learning elements:** Input/output rate, Accumulation, State through time

**Carry forward:** The earlier cube, loops and timing.

**Precision:** A receiver faster than input clears the stored excess.

**Possible consequence:** Matching rates after the pause stops further growth but does not automatically erase the backlog.

**Existing source:** Actual rigid-box conveyors exist with finite-body and stored-stock policies.

**Implementation work:** Expose feed/receive counts and the visible capacity bound; preserve accumulation between edits.

**Future acceptance check:** Track stock accounting, compare rates and test reset; do not imply infinite active bodies or assert an exact avalanche shape.

**Builds on ideas:** 11, 23

- [commons/artifacts/timing_machines/conveyor_backlog.gd](../../../../commons/artifacts/timing_machines/conveyor_backlog.gd)
- [commons/artifacts/cube_sorting_line/cube_sorting_line.gd](../../../../commons/artifacts/cube_sorting_line/cube_sorting_line.gd)

### 25. The point retrieves more than you asked

**CORE · VFM_07_Gravity**

**Question:** Does the source know which object you wanted?

Extend the held attracting point with explicit range and receiver filtering. Put a wanted sphere beside a useful loose doorstop, then compare held and freely responding sources.

**Learning elements:** Pair forces, Receiver eligibility, Equal and opposite response

**Carry forward:** The point becomes a bounded attraction tool.

**Precision:** A declared filter retrieves the intended receiver.

**Possible consequence:** An unfiltered source can also remove a support; freeing the source lets both bodies move.

**Existing source:** Held point already queries rigid bodies and applies bounded central force; reciprocal free-source version requires verification.

**Implementation work:** Make source policy explicit, add a target/filter comparison and a simple mutual-response variant.

**Future acceptance check:** Test filter/range and bounded near-source force; free pairs receive opposite forces while accelerations depend on mass; release retains velocity.

**Builds on ideas:** 1, 6, 11

- [commons/primitives/point/interactive_point_origin_force.gd](../../../../commons/primitives/point/interactive_point_origin_force.gd)

### 26. Three bodies, two beginnings

**EXTENSION · VFM_07_Gravity**

**Question:** How long do nearby starts remain close?

Return the attraction law as two small three-body experiments with trails. Change one initial velocity slightly; include an organised reference as well as a sensitive case.

**Learning elements:** Pair accumulation, Initial conditions, Sensitivity versus integration error

**Carry forward:** The shared attraction law and Trace.

**Precision:** A chosen reference maintains its expected organisation within the model's tolerance.

**Possible consequence:** Another initial state changes the partnership or sends a body outward.

**Existing source:** Three-body scene already contains several starting configurations and trails.

**Implementation work:** Provide side-by-side bounded replay; preserve parameters and distinguish physical-model behavior from timestep error.

**Future acceptance check:** Repeat identical starts; compare timesteps before claiming sensitive dynamics. Do not label every orbit chaotic.

**Builds on ideas:** 25

- [algorithms/physicssimulation/threebodyproblem/ThreeBodyProblem.gd](../../../../algorithms/physicssimulation/threebodyproblem/ThreeBodyProblem.gd)

### 27. Take away one support

**CORE · VFM_09_Legs**

**Question:** Which part can you remove while it still stands?

Use support_polygon_lab with the familiar cube as load. Shift the mass marker, remove one support and predict before release; preserve the fallen arrangement.

**Learning elements:** Support region, Mass projection, Static balance limits

**Carry forward:** The cube, gravity and the lever relation.

**Precision:** A supported configuration stays upright.

**Possible consequence:** A changed support or mass position causes a tilt that can create a ramp or obstruction.

**Existing source:** An actual rigid load, finite supports and static-hull forecast exist.

**Implementation work:** Make the goal a small supported display; retain aftermath and distinguish initial static prediction from dynamic stability.

**Future acceptance check:** Test centre and shifted load cases, removed supports and measured tilt; do not treat a hull test as a general gait guarantee.

**Builds on ideas:** 11, 25

- [commons/artifacts/support_polygon_lab/support_polygon_lab.gd](../../../../commons/artifacts/support_polygon_lab/support_polygon_lab.gd)

### 28. The dog must brace before it fires

**EXTENSION · VFM_09_Legs**

**Question:** What supports its action?

Use the four-legged walker as a supplied character. First show planted feet and declared firing state; later compare a verified physical brace/load rig with its commanded gait.

**Learning elements:** Support versus commanded pose, Stateful action, Optional recoil

**Carry forward:** Known support and impulse concepts.

**Precision:** A braced action is legible and leaves a route for the player.

**Possible consequence:** A changed support interrupts a declared firing condition; a future physical variant can respond to recoil.

**Existing source:** Existing gait is commanded movement plus IK, not a self-balancing rigid-body dog; weapon and physical reaction are new.

**Implementation work:** Stage implementation: visible support states, supplied character behavior, then tested dynamics. Do not require a robot controller tutorial.

**Future acceptance check:** Assert telegraphed state transitions and declared support criterion; claim physical recoil only after a dynamic receiver test.

**Builds on ideas:** 27

- [commons/hazards/octapod_crawler/four_leg_critter.gd](../../../../commons/hazards/octapod_crawler/four_leg_critter.gd)

### 29. Make a passage with one shot

**CORE · VFM_08_Arena**

**Question:** Can you redirect what blocks your way?

Let the point catalyst fire at one dynamic obstructing body. Show target eligibility and occlusion before the shot; let the impact change motion. A bowling arrangement reuses this receiver as practice.

**Learning elements:** Eligibility and occlusion, Interaction states, Impulse received once

**Carry forward:** The same point, aiming rule and dynamic-body contract.

**Precision:** A measured deflection opens the passage.

**Possible consequence:** The obstacle moves into a different position; a stronger shot can create another obstruction.

**Existing source:** Arena has explicit selection/state but commanded motion; collision carts are analytic, bowling uses custom Mover. None alone proves a dynamic impulse target.

**Implementation work:** Add one real receiver first; keep sensing, scripted agency and physical response separate. Extend into bowling only after contact checks.

**Future acceptance check:** Occluders block selection; one collision applies one declared impulse; motion is retained after the event. Reset restores a known baseline.

**Builds on ideas:** 6, 11, 25

- [commons/artifacts/arena_relation_lab/arena_relation_lab.gd](../../../../commons/artifacts/arena_relation_lab/arena_relation_lab.gd)
- [commons/artifacts/collision_carts/collision_carts.gd](../../../../commons/artifacts/collision_carts/collision_carts.gd)
- [algorithms/forces/games/force_bowling_vr.gd](../../../../algorithms/forces/games/force_bowling_vr.gd)
- [commons/artifacts/ignorance_gallery/resolution_catalyst.gd](../../../../commons/artifacts/ignorance_gallery/resolution_catalyst.gd)

### 30. Deliver it through the room you changed

**CORE · Vectors_Act5_ForceAsPlace**

**Question:** Can your learned abilities make another route?

Upgrade force_as_place into a bounded delivery room. Compare local acceleration on the point/cube and the player, then choose among launch, thrust, spring, support or a repaired conveyor path.

**Learning elements:** Field membership, Receiver adapters, Composition and transfer

**Carry forward:** Point, cube, vector operations and the abilities built through the sequence.

**Precision:** The student delivers the point and explains which operations made the route possible.

**Possible consequence:** A missed delivery leaves a usable ramp, moving receiver or blocked path that can be incorporated into another attempt.

**Existing source:** The opt-in room already has cube/desktop/XR field adapters with different exit contracts. A coherent delivery task and retained tool state are proposed.

**Implementation work:** Start with a small selection of verified tools; declare field entry/exit, per-body integration owner and intentional cross-hall state transfer. Keep the existing passage usable.

**Future acceptance check:** Verify each adapter separately, retained entry velocity, zero-field behavior and documented exit. Accept multiple solutions; test rules and reset rather than a required ending.

**Builds on ideas:** 9, 11, 14, 17, 20, 23, 25, 27, 29

- [commons/artifacts/force_field_zone/force_field_zone.gd](../../../../commons/artifacts/force_field_zone/force_field_zone.gd)
- [commons/artifacts/force_field_zone/field_carry_provider.gd](../../../../commons/artifacts/force_field_zone/field_carry_provider.gd)
- [commons/artifacts/force_cube/force_cube.gd](../../../../commons/artifacts/force_cube/force_cube.gd)
- [commons/artifacts/vector_machine/vector_machine.gd](../../../../commons/artifacts/vector_machine/vector_machine.gd)

## Delivery passes

### 1. Confirm the spine of the lesson

One agreed paragraph and reconstructable lesson per existing hall. Review the abstract/analytic/physical distinction before expanding full code.

Ideas: 1, 3, 6, 9, 11, 14, 17, 20, 23, 25, 27, 29, 30

### 2. Build one continuous point

Establish the dynamic point and selected persistence contract, verify launch versus force, then implement the approved two-hand thrust in the existing museum.

Ideas: 9, 11, 13

### 3. Make consequences observable

Upgrade one field, one channel, one spring pair, the conveyor and one target; each has a baseline success and a retained aftermath.

Ideas: 15, 19, 20, 21, 24, 29

### 4. Add optional apparatus selectively

Choose extension specimens after the core route works. They must not become prerequisites for finishing the basic force tutorial.

Ideas: 8, 18, 22, 26, 28

## Ground rules

1. Preserve the identity/look of PointBody and the inherited cube. Extend behavior where compatible; do not claim that current independent artifacts already share one runtime instance.
2. Declare the state handed between halls: body configuration, learned tool modes and selected trace/experiment records. Implement the transport explicitly; do not assume live nodes survive a map unload.
3. Every visible arrow names its quantity and frame: displacement in m, velocity in m/s, acceleration in m/s², force in N. Compatible quantities may be added; their types are not interchangeable.
4. Opening mathematical models can be prescribed geometry. Label them; compare with physical receivers only after defining the different contracts.
5. One owner integrates each body. Never add a custom velocity/position integration on top of a Godot rigid-body solver that already advances the same state.
6. Keep player camera orientation level and separate tracked motion from software propulsion. Physical headset comfort remains a later test, not guaranteed by desktop assertions.
7. Give each core tutorial one rebuildable focus and print its complete changed code plus an exact reference to inherited code. Core success includes an independent changed example.
8. Reflection asks what a rule retains, excludes or makes possible. It need not explain every museum artifact; optional apparatus can remain outside both written tracks.
9. Do not stage numerical failure as evidence of a force. Tunnelling, unstable joints and fake deformation are not substitutes for a tested mechanical relation.
10. Leave aftermath inspectable, with an explicit reset. Bound active bodies and reveal that capacity; a test must not demand a specific collapse.
11. Noise, flocking, fluid pressure, cloth, robot inverse kinematics and physical quadruped locomotion remain later topics or supplied systems.
12. The thirteen core lessons depend on earlier core knowledge. Practice provides additional attempts; extension concepts are never prerequisites for the core route. Listed idea dependencies are knowledge/behavior dependencies, not a promise of shared runtime code today.

## Verification

Future implementation checks are specified per idea but were not run. This report only checks proposal completeness, prerequisite ordering, source file existence and the current hall mapping.

## References

- [The Nature of Code — Vectors](https://natureofcode.com/vectors/): Reference progression for displacement, vector operations, motion and acceleration; Ada's apparatus are original proposals.
- [The Nature of Code — Forces](https://natureofcode.com/forces/): Reference for force accumulation, mass, resistance and attraction; no claim that it excludes unintended consequences.
- [Godot — RigidBody3D](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html): Integration ownership and the distinction between continuous force and one-off impulse.
