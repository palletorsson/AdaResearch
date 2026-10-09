# Forces through the hands

**Status:** Proposed primary objects and upgrades. Source audit complete; these upgrades are not implemented by this document.

Inside Endless Museum. Keep the familiar point, cube, slope and platform. One primary reconstruction per hall; supporting play may show the same principle again. Hands initiate the experiment. Consequences can exceed the intention. Preserve the existing Keep choices.

## Force and primary-object list

| Hall | Subject | Primary object | Action |
| --- | --- | --- | --- |
| 01 — Vectors_Act1_WhatAVectorIs | Displacement, magnitude, unit direction | The held point and its origin | Grab the black point; move it around the origin. |
| 02 — VFM_02_Operations | Vector addition | Two input points and one resultant point | Move the two input points; watch their result follow. |
| 03 — Vectors_Act2_VectorArithmetic | Projection and remainder | The point beside a rail | Pull the free point sideways and along the rail; compare the projected marker. |
| 04 — VFM_05_Launch | Initial velocity, gravity and trajectory | The familiar point, a hand-aimed launcher and a basket | Load the point, pull the launcher handle, aim and release. |
| 05 — VFM_03_Motion | Force, mass, acceleration and retained velocity | The point with a calibrated hand force tool | Aim the force tool at a point and hold its action to apply a measured push. |
| 06 — Vectors_Act3_FieldsAndMotion | Position-dependent force; sampling a vector field | The point in a room-sized vortex | Move the field source, release a point, then enter the same field as a player receiver. |
| 07 — Vectors_Act4a_KineticForces | Velocity-dependent drag | The point crossing a visible drag volume | Push or throw the point into the volume; catch it and try another approach. |
| 08 — Vectors_Act4b_Oscillation | Restoring force and damping | The point on a spring | Pull the point away from equilibrium and let go. |
| 09 — Change_Choreography | Rate, phase and accumulating contact | The familiar cubes on the conveyor | Feed cubes by hand; hold or swing the receiver gate. |
| 10 — VFM_07_Gravity | Pairwise attraction and initial conditions | Two, then three familiar points | Arrange the points by hand and release them; give one a small sideways start. |
| 11 — VFM_09_Legs | Support, contact and centre of mass | The loaded table and its removable cube foot | Pull a support, move the load, or poke the table with the familiar point/stick. |
| 12 — VFM_08_Arena | Impulse, collision and recoil | The catalyst point and a reactive target rig | Aim and fire, throw the point, swing a stick, or push the target directly. |
| 13 — Vectors_Act5_ForceAsPlace | Combined thrust, gravity and player velocity | Two catalyst-family points in the player's hands | Aim down/back and hold both triggers to fly; release, coast and land. |

## Order and lineage

Retain the thirteen-hall order for this pass. The first three halls prepare vector operations; Choreography returns to prescribed motion and throughput, not a new force law. Launch previews a release before Motion explains force and mass. Supply the launcher mechanism there; teach its spring/hinge dynamics later. Torque is a supporting encounter, not silently a second required tutorial. A flight preview may return earlier, but the complete player receiver lesson remains last.

PointBody → movable point → dynamic point → force receiver → source of a field / powered hand tool. Cube → load, obstacle, pin, support and backlog. Spring, hinge, rail and basket constrain these familiar bodies. The final receiver is the player.

## Catalyst audit

### The primitive resolution sphere

Extends resolution_point, which continues PointBody. Holding changes mesh resolution. Its action sends the current sphere form as a projectile and returns the dropped sphere to suspension.

**Gap:** Shares catalyst grouping/hit conventions, but is not the full BecomingCatalyst mode controller or the new thrust point.

Sources: `commons/artifacts/ignorance_gallery/resolution_catalyst.gd`, `commons/artifacts/ignorance_gallery/resolution_point.gd`, `commons/artifacts/ignorance_gallery/form_projectile.gd`

### The full Becoming Catalyst

Absorbed hand tool, wrist mode selection, curriculum projectile modes, editing modes, held-field interactions and capability progression. The forces projectile reduces nearby rigid-body velocities and temporarily increases damping. Its README understates the current implementation; source is authoritative here.

**Gap:** The inspected Forces mode is a calming shot. A general pull/capture/launch force mode is not implemented in that mode. Mode availability depends on progression and configuration. All listed powers are not necessarily available on entry to Forces.

Sources: `commons/hazards/becoming_catalyst/becoming_catalyst.gd`, `commons/hazards/becoming_catalyst/catalyst_orb.gd`, `commons/hazards/becoming_catalyst/modes/forces_projectile.gd`, `commons/managers/CatalystCapabilityManager.gd`, `commons/hazards/becoming_catalyst/capacity_bracelet/capacity_bracelet.gd`

### Two black flight points

In the final hall, Vectors_Act5_ForceAsPlace, inside force_capability_lab. Both extend PointBody. Aim down/back and hold their actions: each supplies 11 m/s² opposite the nozzle direction. Release ends thrust while velocity and gravity continue. The visor reads that same connection.

**Gap:** A separate implementation with a court-local player movement adapter; not a catalyst power carried through every hall. It currently supplies acceleration rather than a force derived from a declared player mass.

Sources: `commons/artifacts/force_capability_lab/force_point.gd`, `commons/artifacts/force_capability_lab/force_capability_lab.gd`, `commons/artifacts/force_capability_lab/body_visor.gd`

### Breaking and restoration

The opt-in artifact reaction component already handles tool hits and timed rebuilding. The court contains a real hinged falling pole.

**Gap:** The existing reaction component hides a target and shows illustrative debris; it is not physical fracture. The pole is released by a button and is not yet a breakable, hand-released joint. Impact-driven breaking requires a real threshold and released rigid pieces or a released constraint.

Sources: `commons/interactables/artifact_reactions/README.md`, `commons/interactables/artifact_reactions/reaction.gd`, `commons/artifacts/force_capability_lab/force_capability_lab.gd`


**Integration decision:** Continue PointBody for the learner's small reconstructed object. Add bounded capabilities to that object and use an adapter to the existing catalyst input/mode/target protocols. Reuse the bracelet for nearby controls. Do not replace PointBody with the entire editor-heavy BecomingCatalyst script, or present these separate implementations as already unified. Preserve earned modes and existing editor input bindings.

Flying points: `Vectors_Act5_ForceAsPlace`, capability court. Direct entry: `commons/scenes/force_capability_museum.tscn`.

## Interaction rules

- Grab, pull, push, swing, aim and release operate the actual object. A button labelled PULL FOOT is a candidate for a removable foot.
- Use a constrained grab or bounded force tether for a jointed handle. Ordinary pose-snapping pickup must not drag the hinge anchor through the room.
- Put reset, comparison and display controls on the existing off-hand interface, or beside the working hand. Show which experiment they control; never reset unrelated bodies.
- Keep triggers for powered actions such as thrust or firing. A held object owns its action so the absorbed catalyst does not fire at the same time.
- Offer one readable trial and a way to escalate it with more bodies, a blocked exit or another constraint. Keep one causal question visible.
- Let misses, fallen bodies and overflow remain. Explicit reset restores the apparatus; lost-body recovery and finite spawn limits are disclosed.
- Use colour from the earlier sequence for consistent roles: source, receiver and trace. Label them as well. Do not communicate force only through colour.
- Use vectors sampled from the actual receiver model. Distinguish force, acceleration, velocity, displacement and display length; a trail records where a body went, not the field itself.
- Entry events release or remove a physical condition once per trial. Subsequent collisions and collapse come from simulation, not a scripted failure animation.
- A headset has no sustained weight feedback. Show mass through response to an equal applied force; do not promise the hand will feel simulated kilograms.

## Hall-by-hall changes

### 01. Pull a direction into view — Vectors_Act1_WhatAVectorIs

**Subject:** Displacement, magnitude, unit direction. **Primary:** The held point and its origin.

**Current lesson selection:** `force_point_direction`; full tutorial.md still needs alignment after implementation.

**Action:** Grab the black point; move it around the origin.

**Today:** force_point_direction already supports actual pickup and reads the point's displacement. RESET and UNIT are separate controls.

**Upgrade:** Keep this working artifact. Make the unit marker readable beside the held point; move its optional toggle and reset within reach. Give a nearby target ring to line up with the arrow.

**Consequence:** Stretch the relation across the room, bring it almost to zero, then reverse it. The target ring does not magnetically correct the point.

**Tutorial direction:** Continue PointBody and subtract the origin from its position. Read length; normalize only when the displacement is nonzero. Keep visual length and vector magnitude distinct. The student chooses another position and predicts the readings. Carry direction and magnitude into the next hall.

**Independent check:** Move to an unlisted position. Check the displacement and length; at zero, hide direction instead of inventing one.

**Supporting encounters:** Magnitude and stretch benches remain comparisons, not additional reconstructions.

Sources: `commons/artifacts/force_halls/point_lesson.gd`, `commons/artifacts/force_halls/lesson_point.gd`

### 02. Two hands, one result — VFM_02_Operations

**Subject:** Vector addition. **Primary:** Two input points and one resultant point.

**Current lesson selection:** `force_point_addition`; full tutorial.md still needs alignment after implementation.

**Action:** Move the two input points; watch their result follow.

**Today:** force_point_addition already constructs the result from the two displacements.

**Upgrade:** Keep both inputs at comfortable reach and make their roles unmistakable. Add a movable destination hoop for a hands-on cancellation/alignment challenge. Do not turn this into a forces lesson before force has been introduced.

**Consequence:** Large opposed inputs nearly cancel; small hand changes then move the result a long way relative to its previous near-zero length.

**Tutorial direction:** Reuse the displacement calculation in one frame and add the vectors. The input points remain yours; the result is computed. Make cancelling vectors, swap the two contributions and explain the unchanged endpoint. This same sum later combines two thrusters.

**Independent check:** Choose cancelling inputs, then two unequal inputs and swap them. Result equals a+b in every case.

**Supporting encounters:** The floor walk shows the route; the result preserves its endpoint rather than its travelled length.

Sources: `commons/artifacts/force_halls/point_lesson.gd`

### 03. What the rail accepts — Vectors_Act2_VectorArithmetic

**Subject:** Projection and remainder. **Primary:** The point beside a rail.

**Current lesson selection:** `force_point_projection`; full tutorial.md still needs alignment after implementation.

**Action:** Pull the free point sideways and along the rail; compare the projected marker.

**Today:** force_point_projection shows the projection and perpendicular remainder. The torque crank is a separate comparison.

**Upgrade:** Give the projected marker a legible collar/rail form and put a basket at one end. Keep the free input visibly separate; the geometric projection is not a simulated force constraint.

**Consequence:** You can make a large sideways movement without advancing the rail marker. Move the basket and try a new approach.

**Tutorial direction:** Use the known displacement and a unit rail direction. Compute the component and retain the remainder; add them to recover the original vector. The student changes the rail direction and predicts the result. Carry decomposition forward to aim, slopes and fields.

**Independent check:** Perpendicular input leaves projection unchanged; projection plus remainder reconstructs the input.

**Supporting encounters:** Keep the crank as a preview of turning. Torque needs its own later explanation, not an unexplained dot-product synonym.

Sources: `commons/artifacts/force_halls/point_lesson.gd`

### 04. Let the point go — VFM_05_Launch

**Subject:** Initial velocity, gravity and trajectory. **Primary:** The familiar point, a hand-aimed launcher and a basket.

**Current lesson selection:** `launch_arc`; full tutorial.md still needs alignment after implementation.

**Action:** Load the point, pull the launcher handle, aim and release.

**Today:** launch_arc is the selected analytic lesson. The trial catapult has a real hinge but a FIRE button applies a 0.35-second torque pulse. The pipe has real contact walls. The donut cake mortar exists in the last court with LOWER/FIRE/HIGHER buttons.

**Upgrade:** Supply the launcher hardware and let the learner own the released point and its trajectory. Replace angle buttons with a constrained hand-aimed barrel/handle. Catch in an actual movable basket. Return the donut mortar as a variant, with a handle-mounted firing action.

**Consequence:** Move the basket, bank a shot, or place the pipe between launcher and target. A collision invalidates the simple free-flight prediction. Rings can catch on posts because their collision geometry preserves the hole.

**Tutorial direction:** Carry the point into motion with a measured release velocity and constant downward acceleration. Compare its predicted free path with the actual flight. The launcher is supplied at this stage; its spring or hinge dynamics are not a second reconstruction. Change the release and predict a new landing.

**Independent check:** Compare predicted and actual free flight before contact. Verify changing the aim changes launch direction, not gravity. A miss stays visible.

**Supporting encounters:** Catapult, open pipe and donut mortar are different ways to release the same learned body; no need to build all three in the tutorial.

Sources: `commons/artifacts/force_trials/trial.gd`, `commons/artifacts/force_capability_lab/ring_mortar.gd`

### 05. Keep pushing, then stop pushing — VFM_03_Motion

**Subject:** Force, mass, acceleration and retained velocity. **Primary:** The point with a calibrated hand force tool.

**Current lesson selection:** `force_trial_mass`; full tutorial.md still needs alignment after implementation.

**Action:** Aim the force tool at a point and hold its action to apply a measured push.

**Today:** force_trial_mass applies 2 N for one second to equal-sized points of 1, 2 and 4 kg, using a PUSH button.

**Upgrade:** Put the calibrated push in the hand. Keep an optional equal-duration comparison on the same controller. Free play permits pushing cubes too. Show the selected body, applied force and velocity together.

**Consequence:** End the push but leave the receiver moving. Add another point in its path. Reverse the tool before contact and try to stop the consequence you started.

**Tutorial direction:** Extend the dynamic PointBody with an applied force while an action is held. Godot integrates the rigid body; do not also manually integrate its position. Reuse the same force and duration to compare mass. Ending input removes the force without assigning zero velocity.

**Independent check:** Under the declared equal-force, equal-time comparison, velocity changes scale inversely with mass. Releasing input must not erase velocity.

**Supporting encounters:** The Newton and velocity benches remain readout comparisons. Hand throws alone are not evidence of equal applied force.

Sources: `commons/artifacts/force_trials/trial.gd`

### 06. Enter the swirl — Vectors_Act3_FieldsAndMotion

**Subject:** Position-dependent force; sampling a vector field. **Primary:** The point in a room-sized vortex.

**Current lesson selection:** `force_trial_vortex`; full tutorial.md still needs alignment after implementation.

**Action:** Move the field source, release a point, then enter the same field as a player receiver.

**Today:** force_trial_vortex affects its point and cube on a plane. SPIRAL currently changes both tangential force and the point's starting velocity. VectorFieldFlow and the later local-field player adapter provide separate receiver examples. The trial does not yet move the player.

**Upgrade:** Build one walk-in field using the existing receiver adapters. Draw a sparse arrow lattice from the same field function used by physics; add actual sphere and player trails. Keep a nearby radial/swirl control and separate it from initial velocity so comparisons change one variable.

**Consequence:** A loose cube joins your orbit; you thrust across the current or overshoot the exit. Move the source and see the pattern move while existing bodies retain their momentum.

**Tutorial direction:** Evaluate a vector from the point's current position and apply it each physics step. Compare radial attraction with a tangential contribution while keeping the start fixed. Distinguish field arrows from the body's velocity and recorded path. The player adapter is supplied, with its acceleration units declared.

**Independent check:** The displayed field sample matches the applied rule at an arbitrary location. Zero the field: velocity remains. Entry/exit restores ordinary player movement exactly once.

**Supporting encounters:** Keep the existing direct-velocity receiver as one contrast. Do not call it the same dynamics as force integration.

Sources: `commons/artifacts/force_trials/trial.gd`, `commons/artifacts/force_field_zone/field_carry_provider.gd`, `commons/artifacts/force_capability_lab/body_visor.gd`

### 07. Pull through resistance — Vectors_Act4a_KineticForces

**Subject:** Velocity-dependent drag. **Primary:** The point crossing a visible drag volume.

**Current lesson selection:** `drag_corridor`; full tutorial.md still needs alignment after implementation.

**Action:** Push or throw the point into the volume; catch it and try another approach.

**Today:** drag_corridor is the selected measured lesson. A separate roll/slide trial compares rotation-locked and freely rotating balls with a cube on slopes.

**Upgrade:** Make the drag region unmistakable, with a movable boundary or nearby coefficient control. Carry the point into it by hand and offer a matched release for measurement. Add a rolling/sliding slope within reach as the contact-friction comparison.

**Consequence:** Try dragging a train of attached bodies through the region; later bodies continue pushing after the first slows. Leave the resulting pile.

**Tutorial direction:** Add resistance opposite to the point's velocity and declare whether the model is linear or quadratic. Use the previous force/mass relation to predict slowing. Keep surface friction and rolling separate from this drag law. Compare another mass using the same initial velocity.

**Independent check:** The drag force opposes nonzero velocity and is zero at rest. Entering and leaving restores the intended model without double damping.

**Supporting encounters:** The mower and work meter can remain optional. The meanings of drag as resistance, pulling and performance may meet in final.md without becoming the same physical claim.

Sources: `commons/artifacts/force_trials/trial.gd`, `commons/maps/Vectors_Act4a_KineticForces/tutorial.md`

### 08. Stretch what will return — Vectors_Act4b_Oscillation

**Subject:** Restoring force and damping. **Primary:** The point on a spring.

**Current lesson selection:** `spring_tower`; full tutorial.md still needs alignment after implementation.

**Action:** Pull the point away from equilibrium and let go.

**Today:** spring_tower is the selected one-dimensional lesson with a constrained cube handle. The final court also has two PointBody spring balls that can collide, plus a real falling hinge pole.

**Upgrade:** Use the PointBody spring pair as the visual continuation, with a constraint-aware grab. Put damping beside the hand. Bring a hinged pole close enough to poke with the moving point; keep the pole's torque explanation optional until selected as its own lesson.

**Consequence:** A spring ball hits its neighbour, which knocks a cube, which releases the pole. The endpoint depends on contacts, not a scripted sequence of falls.

**Tutorial direction:** Reuse displacement and velocity. Apply a restoring force toward the spring's rest position and a separate damping term. Pull and release the same point; then add one receiver for collision. The learner changes one parameter and predicts overshoot before testing it.

**Independent check:** Force reverses across equilibrium. With damping, the chosen model loses energy after release. Joint anchors remain fixed while the hand moves a handle.

**Supporting encounters:** The mobile, coupled pendulums and hinged pole show other constraints. A hinge is a constraint; torque is the turning effect of force, not a new name for oscillation.

Sources: `commons/artifacts/force_capability_lab/force_capability_lab.gd`, `commons/maps/Vectors_Act4b_Oscillation/tutorial.md`

### 09. The receiver cannot keep up — Change_Choreography

**Subject:** Rate, phase and accumulating contact. **Primary:** The familiar cubes on the conveyor.

**Current lesson selection:** `phase_rod_array`; full tutorial.md still needs alignment after implementation.

**Action:** Feed cubes by hand; hold or swing the receiver gate.

**Today:** The selected tutorial is phase_rod_array. force_trial_conveyor is a supporting trial with FEED/GATE buttons. Its receiver currently freezes and arranges accepted cubes into a stack.

**Upgrade:** Promote a small conveyor/gate encounter as the proposed lesson; keep the rods as a precise phase comparison. Replace the gate button with a handle. Let received cubes settle in a physical basket instead of arranging them by code. Keep the finite supply visible.

**Consequence:** Close the receiver while the belt continues. The queue piles, tips and spills. Opening the gate does not undo what has already fallen.

**Tutorial direction:** Return to the cube array, clock and repeated action. Control one feed interval and one gate phase; count arrivals and departures. The belt motion is supplied and prescribed. Collisions produce the backlog. This is a synthesis of earlier timing and contact, not a new fundamental force.

**Independent check:** A faster input than output grows the queue. Changing phase differs from changing rate. Cubes remain real colliders after entering the basket.

**Supporting encounters:** Phase rods retain their clear periodic comparison. Do not make the robot-arm loop or every timing machine another required reconstruction.

Sources: `commons/artifacts/force_trials/trial.gd`, `commons/maps/Change_Choreography/tutorial.md`

### 10. The source is also a body — VFM_07_Gravity

**Subject:** Pairwise attraction and initial conditions. **Primary:** Two, then three familiar points.

**Current lesson selection:** `force_trial_threebody`; full tutorial.md still needs alignment after implementation.

**Action:** Arrange the points by hand and release them; give one a small sideways start.

**Today:** force_trial_threebody has two planar trios, softened close-range attraction and a RELEASE button. The points in that model have no collision contacts. The attractor/doorstop trial is a separate contact experiment.

**Upgrade:** Let hands establish the initial positions; put simultaneous release and the matched-start comparison on the nearby controller. Preserve the collisionless comparison rather than silently adding contacts to its model. In a side bay, use a movable attractor to pull a real doorstop.

**Consequence:** The point meant to open a route catches the doorstop too; the hinged door moves. That is a receiver-selection consequence, distinct from the clean three-body model.

**Tutorial direction:** Start with one pair, compute their interaction and apply equal opposite forces. Add the third point by summing each pair once. State the planar and softened-force assumptions. Compare one changed initial condition without claiming that every divergent pair of paths proves chaos.

**Independent check:** Each pair contributes equal opposite force. A changed initial condition leaves the comparison's other state untouched. The nearby contact experiment declares its different receiver rules.

**Supporting encounters:** Keep the fixed-source orbit as a contrast. The model source policy matters as much as the drawing of an orbit.

Sources: `commons/artifacts/force_trials/trial.gd`

### 11. Remove what holds it up — VFM_09_Legs

**Subject:** Support, contact and centre of mass. **Primary:** The loaded table and its removable cube foot.

**Current lesson selection:** `force_trial_support`; full tutorial.md still needs alignment after implementation.

**Action:** Pull a support, move the load, or poke the table with the familiar point/stick.

**Today:** force_trial_support has real rigid-body feet, slab and loads. PULL FOOT currently supplies an impulse for the player. The nearby walkers have commanded gaits, not simulated balance.

**Upgrade:** Replace PULL FOOT with an actual graspable support. Let the table settle on entry. Add one clear entry-triggered release of a ball onto a marginally supported shelf; subsequent collapse is physical. Add a releasable joint/post only if it produces a legible contact chain.

**Consequence:** Catch a falling cube or use it as a new prop. The experiment becomes repair, not just destruction. A knocked-out post opens a route and drops what it supported.

**Tutorial direction:** Reuse the cube as a support surface with extent and the point as a movable load. Construct a small assembly, let contacts settle, then change one support or load position. Predict stability and retain the result. Leave gait control to a later tutorial.

**Independent check:** Removing a support actually changes contact geometry. The entry event fires once per trial. Restoring the apparatus waits while a player or held object occupies the return space.

**Supporting encounters:** The walkers remain alternative arrangements. A scripted step does not demonstrate physical balance; disappearance plus decorative fragments does not demonstrate fracture.

Sources: `commons/artifacts/force_trials/trial.gd`, `commons/interactables/artifact_reactions/README.md`

### 12. Aim at what will move — VFM_08_Arena

**Subject:** Impulse, collision and recoil. **Primary:** The catalyst point and a reactive target rig.

**Current lesson selection:** `force_trial_bowling`; full tutorial.md still needs alignment after implementation.

**Action:** Aim and fire, throw the point, swing a stick, or push the target directly.

**Today:** force_trial_bowling is the selected lesson. The hall has a balls-only sentry, dropper, collision carts and target. The full catalyst can fire, but its Forces shot primarily calms. Generic reactive targets colour or disappear rather than fracture physically.

**Upgrade:** Make a single range from cube pins, a hinged plate and a catch basket. Adapt the point's shot to one explicit impulse/contact contract; avoid adding an impulse twice if the projectile contact already supplies it. Keep the calming shot as a separate visible operation. A breakable latch releases a real body.

**Consequence:** Hit the moving plate: it knocks a support; cubes spill into the basket; the full basket changes the next collision. Try to stop the chain with the calming power. Precision and failure share the same rig.

**Tutorial direction:** Continue the point and cube with one short impulse exchange. Compare a braced and free launcher, then a direct hit and a miss. Reconstruct one receiver first. Target selection, cooldown, physical breakage and restoration are declared supporting systems, not hidden parts of the force law.

**Independent check:** A hit transfers motion once; a miss does not. Recoil has the opposite sign under the stated model. A hinge stays anchored until its specified release condition. Calming reduces motion without being labelled attraction.

**Supporting encounters:** Start with unarmed mechanical targets; the existing sentry can supply a moving challenge later. No new enemy species is needed to make the range compelling.

Sources: `commons/artifacts/force_trials/trial.gd`, `commons/hazards/becoming_catalyst/modes/forces_projectile.gd`, `commons/hazards/becoming_catalyst/catalyst_projectile.gd`, `commons/interactables/artifact_reactions/reaction.gd`

### 13. You become the receiver — Vectors_Act5_ForceAsPlace

**Subject:** Combined thrust, gravity and player velocity. **Primary:** Two catalyst-family points in the player's hands.

**Current lesson selection:** `force_capability_lab`; full tutorial.md still needs alignment after implementation.

**Action:** Aim down/back and hold both triggers to fly; release, coast and land.

**Today:** The two black thrust spheres are here, in the capability court beyond the field crossing. The body visor, launch pad, real hinge, spring pair, moving platform and donut cake mortar already exist.

**Upgrade:** Make the spheres the first unmistakable encounter and adapt their input to the shared catalyst capability model. Put visor, reset and trial selection at the wrist or working hand. Add reachable landing targets, baskets and a route over the void. Integrate the swirl only through one player movement owner.

**Consequence:** Fly while carrying a cube, land on a moving platform, send a ring through a suspended target, or break a latch and improvise a bridge. Let the apparatus combine without requiring all of it in the tutorial.

**Tutorial direction:** Return to vector addition: sum both point contributions and apply gravity to the player receiver. State that the current adapter supplies acceleration in m/s² rather than force in newtons. Release stops thrust, not motion. Compare one hand, two aligned hands and opposed hands using the same body visor readings.

**Independent check:** Aligned inputs add; opposed inputs cancel. Releasing triggers preserves velocity. Only one adapter integrates player motion; teleport/exit clears local ownership and the overlay cleanly.

**Supporting encounters:** A launch pad currently sets initial velocity; it is not sustained upward force. The mortar launches at a declared speed. Keep these distinctions visible while allowing free combinations.

Sources: `commons/artifacts/force_capability_lab/force_point.gd`, `commons/artifacts/force_capability_lab/force_capability_lab.gd`, `commons/artifacts/force_capability_lab/body_visor.gd`, `commons/artifacts/force_capability_lab/ring_mortar.gd`

## Build order

1. Target rig: familiar point, hand action, cube pin, hinged plate, basket, physical release and local reset. Establish the reusable interaction contract here.
2. Spring and support: replace proxy buttons with constrained grabs and a removable support. Add one causal arrival event and retain the aftermath.
3. Walk-in swirl: share the sampled rule with visible vectors, dynamic points and a declared player adapter; show actual trails.
4. Flight and launch: make the existing spheres easy to find, reuse the shared hand controls, then replace mortar angle buttons with direct aiming.
5. Bring the remaining halls onto the same interaction conventions. Write/retest each full tutorial only against the working primary object.

## Acceptance

- The visitor can discover and perform the main action without walking to a remote control panel.
- Actual XR pickup/release and action dispatch are tested, including a hand already holding an object. No double firing or competing grab ownership.
- Each lesson has one independent prediction/change/assertion. The displayed quantity comes from the same code/state as the physical receiver.
- One modest trial is legible; one escalation produces genuine contact, constraint or retained-state consequences. Misses are not secretly corrected.
- Local reset restores only this trial, respects occupied/held bodies and keeps exits usable. Ordinary aftermath persists until reset or hall unload, with bounds disclosed.
- Museum captures demonstrate the real artifact. Headset reach and Quest frame-time testing remain separate from desktop and supplied-rig assertions.
- Update FORCES_LESSON.md, tutorial.md and ghost-student assertions together after a prototype passes. Keep final.md reflective, with claims matching actual behavior.

## Evidence boundary

Static source audit, not new runtime validation. Real hall images are from the prior curated capture. Runtime code, canonical lesson contracts and full manuscripts were not changed. Edit `doc/book/course/forces-primary-objects.json` and run `python tools/publish_force_primary_objects.py` to regenerate this report.
