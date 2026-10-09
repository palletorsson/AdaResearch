# The experiment leaves the apparatus

Fourteen Forces encounters for Endless Museum

Design proposal. Existing source inspected; proposed interactions have not been implemented or tested. Canonical hall order, tutorial.md, final.md and museum code are unchanged.

Carry the familiar black point into experiments that work within a limit. Change one relation. The apparatus still follows its rules, but the consequence may leave the job, the receiver or the room we assigned to it.

## Cybernetics and the experiment

Cybernetics has a precise account of limits to regulation. Ashby's requisite variety relates the disturbances a regulator must answer to the distinctions and responses available to it. Under the stated conditions, too little regulatory variety leaves some variation in the outcomes. This is a limit relative to a regulator and a task, not proof of an absolutely uncontainable entity. [Ashby, An Introduction to Cybernetics, chapter 11](https://ashby.info/Ashby-Introduction-to-Cybernetics.pdf)

Our design inference: make the missing capacity playable. A collector cannot distinguish cargo from furniture; a stabilizer measures position but ignores velocity; an outlet cannot process the incoming stock. Ask what the controller can sense, affect and preserve. Increasing power alone need not supply the missing distinction.

The Nature of Code supplies a useful mechanism vocabulary: accumulated forces change a body's motion, spring forces introduce restoring relations, and steering provides another contribution to motion. Ada can let those mechanisms meet in a shared room. The instability is not evidence that a physics bug is desirable. [The Nature of Code: Forces](https://natureofcode.com/forces/)

Your Half-Life reading gives the dramatic structure: an experiment opens conditions it can no longer manage. Here the first escaped 'monster' can be the same sphere the student built. It becomes threatening through mass, momentum, attachment or a goal that persists after circumstances change. This is our interpretation and design proposal, not a claim about a historical influence.

## Fourteen encounters

These are encounter candidates within existing halls, not fourteen new maps or fourteen compulsory lessons. The proposed ability route still starts with the sphere, then launch, two-hand flight, release/braking, fields, deflection and return. Motion-before-Launch remains a proposal; the canonical thirteen-hall spine has not been reordered.

### 01. The point does not stop

I · Acquire a capacity · Core mechanism

Candidate halls: VFM_03_Motion

**Task:** Push the familiar sphere onto a marked place.

**Learn:** Velocity, force and mass; distinguish a brief impulse from a sustained push.

**Possible consequence:** The push ends, but the point crosses its target and strikes a loose stop block. The stop becomes another moving body.

**Player choices:** Use a smaller push, oppose its motion, or arrange a receiver. Compare the same impulse on equal-sized bodies with different declared masses.

**Carry forward:** The same point keeps its motion after input ends. This is what the launch and flight encounters depend on.

**Implementation boundary:** Existing point lineage; the controlled push/impulse comparison and movable stop are proposed.

**Proposed test:** In the isolated test, with gravity and damping disabled, ending the applied input does not zero velocity; the same impulse produces the expected inverse-mass change. Contact is a separate test.

Source references:

- [commons/primitives/point/interactive_point_origin_force.gd](../../../../commons/primitives/point/interactive_point_origin_force.gd)

### 02. Perfect delivery, moving destination

I · Acquire a capacity · Core mechanism

Candidate halls: VFM_05_Launch

**Task:** Launch the point into a receiving tray; then use a pad to cross the gap yourself.

**Learn:** Impulse, gravity and trajectory; a receiver also has mass and contact.

**Possible consequence:** The point lands correctly in a loose tray. Its arrival slides the tray off the intended display position.

**Player choices:** Change launch direction, secure the tray or allow a longer stopping distance. A correct trajectory need not make a successful delivery.

**Carry forward:** A launch starts a motion whose later contacts belong to the world.

**Implementation boundary:** Installed pad is a reference, not proof of the movable-tray encounter.

**Proposed test:** Specify whether the launcher sets velocity or applies an impulse. Fire once per activation. The baseline reaches a fixed tray; the loose-tray variant retains contact response.

Source references:

- [commons/artifacts/force_pad/force_pad.gd](../../../../commons/artifacts/force_pad/force_pad.gd)

### 03. Two points carry a body

I · Acquire a capacity · Ability / combination

Candidate halls: VFM_05_Launch, Vectors_Act5_ForceAsPlace

**Task:** Hold a point in each hand and reach a balcony.

**Learn:** Sum two force contributions; separate input from retained velocity.

**Possible consequence:** One hand stops thrusting while the other continues. The intended straight flight becomes a curved approach.

**Player choices:** Aim down/back and hold triggers to thrust up/forward, as already agreed. Release one trigger, compare, then counter-thrust to land.

**Carry forward:** The point is now a tool that acts on the player's motion. Release still leaves a moving body.

**Implementation boundary:** Two-sphere flight remains proposed. The adapter is an integration seam, not the completed ability.

**Proposed test:** A single movement owner adds both inputs; release or drop clears only that input. Neither event zeros the player's velocity. Keep firing a separate action or explicit mode.

Source references:

- [commons/artifacts/force_field_zone/field_carry_provider.gd](../../../../commons/artifacts/force_field_zone/field_carry_provider.gd)

### 04. The brake has a length

I · Acquire a capacity · Core mechanism

Candidate halls: VFM_03_Motion, Vectors_Act4a_KineticForces

**Task:** Release thrust and settle onto a narrow landing shelf.

**Learn:** Gravity, opposing force and drag; stopping takes time and distance.

**Possible consequence:** Entering a drag zone slows the approach but does not freeze it. A late correction carries the point or visitor beyond the shelf.

**Player choices:** Brake earlier, change the declared drag coefficient, or approach with less speed. First observe the ball, then feel the same relation through movement.

**Carry forward:** A boundary drawn on the floor is not an instantaneous change in a body's state.

**Implementation boundary:** Proposed matched ball/player comparison.

**Proposed test:** Name the chosen drag model rather than imply one universal air law. At nonzero relative velocity its force opposes that motion; it vanishes at zero relative velocity.

Source references:

- [commons/artifacts/force_field_zone/field_carry_provider.gd](../../../../commons/artifacts/force_field_zone/field_carry_provider.gd)

### 05. The trolley refuses

II · The room participates · Core mechanism

Candidate halls: VFM_03_Motion, Vectors_Act4a_KineticForces

**Task:** Move a trolley carrying the point across a floor seam.

**Learn:** Contact, friction and a threshold for motion.

**Possible consequence:** A wheel catches or a high-friction patch holds the trolley. More push initially achieves no movement; once it clears, the same input is excessive.

**Player choices:** Reduce the sustained push, change the contact route or unload the trolley. Later, after the spring lesson, return with an elastic pull.

**Carry forward:** The floor is part of the experiment. A blocked body is not necessarily an unresponsive program.

**Implementation boundary:** The current ramp is a reduced one-axis model. A free trolley/contact encounter must be made and tested.

**Proposed test:** Provide a successful baseline. Distinguish geometric wheel obstruction from friction. In the friction-only comparison change one material parameter; do not pre-script the release.

Source references:

- [commons/artifacts/friction_ramp/friction_ramp.gd](../../../../commons/artifacts/friction_ramp/friction_ramp.gd)

### 06. Retrieve the point, collect the room

II · The room participates · Core mechanism

Candidate halls: Vectors_Act3_FieldsAndMotion, VFM_07_Gravity

**Task:** Use the catalyst to retrieve a point beyond reach.

**Learn:** Direction to a source, distance-dependent attraction and affected-body selection.

**Possible consequence:** Loose blocks and a nearby tray satisfy the same receiver rule. They move toward the collector too, interfering with the retrieval.

**Player choices:** Move the source, lower its strength, narrow the eligible receiver set, or use the gathered objects as a new structure.

**Carry forward:** A force has a scope. 'Bring it here' contains an unresolved 'it'.

**Implementation boundary:** Real rigid-body attraction exists; the staged retrieval and comparison remain proposed.

**Proposed test:** Use a declared bounded force model; handle zero separation. Verify which receivers are affected and which are excluded. Do not call a one-way powered attractor mutual gravity.

Source references:

- [commons/primitives/point/interactive_point_origin_force.gd](../../../../commons/primitives/point/interactive_point_origin_force.gd)

### 07. The drain that will not empty

II · The room participates · Field combination

Candidate halls: Vectors_Act3_FieldsAndMotion

**Task:** Clear floating debris through a collection opening.

**Learn:** Radial and tangential vector components; velocity entering a field.

**Possible consequence:** The tangential component keeps debris circulating around the opening. The mechanism moves everything vigorously while removing very little.

**Player choices:** Reduce circulation, increase the inward component, or place a receiver along the orbit. Enter the field after observing its effect on the point.

**Carry forward:** Movement and completion are different measures. Additive influences must meet the velocity already present.

**Implementation boundary:** Existing vortex assigns player velocity. An additive version with interacting debris is new work.

**Proposed test:** Show inward-only and tangent-only comparisons before combining. Do not overwrite incoming velocity and describe that as force accumulation.

Source references:

- [commons/artifacts/force_vortex/force_vortex.gd](../../../../commons/artifacts/force_vortex/force_vortex.gd)

### 08. The shot opens another problem

III · Relations fight back · Core contact / opponent

Candidate halls: VFM_08_Arena

**Task:** Clear a rolling sphere from a passage with the catalyst.

**Learn:** Impulse, mass and transfer of momentum through contact.

**Possible consequence:** The shot diverts the sphere successfully; the sphere strikes a second prop across the route. The obstruction has changed location and shape.

**Player choices:** Aim to redirect, catch or wedge it. In the first trial it is passive; only later enable a visible bounded approach force.

**Carry forward:** The opponent is the familiar point with motion and a relation to the route, not a separate health-bar lesson.

**Implementation boundary:** Projectile appearance exists; collision_carts is a before/after display. The proposed contact encounter needs a tested dynamic target.

**Proposed test:** Use actual dynamic receivers. Disable the driving force in the mass comparison. Account for gravity, floor impulses and restitution before making conservation claims.

Source references:

- [commons/artifacts/ignorance_gallery/resolution_catalyst.gd](../../../../commons/artifacts/ignorance_gallery/resolution_catalyst.gd)
- [commons/artifacts/collision_carts/collision_carts.gd](../../../../commons/artifacts/collision_carts/collision_carts.gd)

### 09. Home comes to the point

III · Relations fight back · Core mechanism / returning opponent

Candidate halls: Vectors_Act4b_Oscillation

**Task:** Pull a tethered sphere aside so you can cross.

**Learn:** Rest length, restoring force and damping; a fixed versus movable anchor.

**Possible consequence:** With the sphere caught, releasing the anchor's floor lock allows the rolling base to move toward it. The return mechanism changes what 'home' means.

**Player choices:** Anchor the base, shorten the extension, damp the return, or use the moving base as transport. The same sphere can be a gate, tool or load.

**Carry forward:** A restoring relation connects two bodies. The tutorial's fixed anchor was an assumption.

**Implementation boundary:** Existing one-axis spring/damper supplies a study, not this free two-body apparatus.

**Proposed test:** Begin with F = -kx in one axis. The dynamic-anchor variant applies equal and opposite spring forces. Track energy supplied by pulling or preloading; do not add a launch impulse for the gag.

Source references:

- [commons/artifacts/spring_tower/restoring_forces.gd](../../../../commons/artifacts/spring_tower/restoring_forces.gd)

### 10. The door opens too well

III · Relations fight back · Optional angular study

Candidate halls: Vectors_Act2_VectorArithmetic, VFM_08_Arena

**Task:** Open a heavy revolving door with the point.

**Learn:** Lever arm, torque and angular response.

**Possible consequence:** A push far from the hinge opens it efficiently, but the sweeping leaf carries a tray or closes a neighbouring route.

**Player choices:** Change where the push is applied, restrain the swing or time the crossing. The door's function does not end at its handle.

**Carry forward:** A force's point of application matters as well as its direction and magnitude.

**Implementation boundary:** Current door uses a manually integrated angular demonstration. A hinged contact version is proposed.

**Proposed test:** Compare equal forces at different perpendicular lever arms. The door must have contact and angular response; a prescribed animation cannot validate the collision claim.

Source references:

- [commons/artifacts/revolving_door/revolving_door.gd](../../../../commons/artifacts/revolving_door/revolving_door.gd)

### 11. The well-equipped body

III · Relations fight back · Optional assemblage after angular study

Candidate halls: Vectors_Act4b_Oscillation, VFM_08_Arena

**Task:** Attach useful pieces to a suspended point without letting it touch the floor.

**Learn:** Mass distribution, balance and rotational inertia.

**Possible consequence:** An off-centre shelf improves carrying capacity but tips the body; adding a counterweight restores one relation while increasing the load.

**Player choices:** Detach, redistribute, rebalance or keep the unexpected orientation as a sculpture. The accumulated body need not be restored to a perfect sphere.

**Carry forward:** A capacity changes what else a body can do. The finished assemblage records choices through its current structure.

**Implementation boundary:** Current mobile references are not evidence of this freely composed physical body.

**Proposed test:** Attachments must contribute to the chosen compound mass/inertia or declared joint model. Fixed visual children alone do not prove the effect.

Source references:

- [commons/artifacts/calder_mobile/calder_mobile.gd](../../../../commons/artifacts/calder_mobile/calder_mobile.gd)
- [commons/artifacts/prop_mobile/prop_mobile.gd](../../../../commons/artifacts/prop_mobile/prop_mobile.gd)

### 12. The successful factory

IV · A limit becomes visible · Return to the cube / system combination

Candidate halls: Change_Choreography

**Task:** Keep the exit clear while the familiar conveyor supplies cubes.

**Learn:** Production and collection rates, finite stock, contact and accumulated load.

**Possible consequence:** Every box arrives correctly, but the receiver is slower. Stock occupies the floor, meets other stock, and changes the route. Stopping production does not remove the backlog.

**Player choices:** Pause admission, increase collection, redirect stock or turn a pile into a route. Keep the capacity bound visible; the engine itself need not be overwhelmed.

**Carry forward:** The cube returns from Primitives as an accumulating consequence. A rate difference becomes an architectural condition.

**Implementation boundary:** Two existing source-backed foundations; the combined room-scale encounter is proposed.

**Proposed test:** Retain the accounting relation admitted - collected = present. Distinguish physical active stock from stored backlog. Verify the full/blocked policy instead of silently deleting boxes.

Source references:

- [commons/artifacts/cube_sorting_line/cube_sorting_line.gd](../../../../commons/artifacts/cube_sorting_line/cube_sorting_line.gd)
- [commons/artifacts/timing_machines/conveyor_backlog.gd](../../../../commons/artifacts/timing_machines/conveyor_backlog.gd)

### 13. The assistant that overcorrects

IV · A limit becomes visible · Optional control study / later tutorial return

Candidate halls: Vectors_Act4b_Oscillation, VFM_08_Arena

**Task:** Ask a powered platform to keep the point over its centre.

**Learn:** Position error, feedback gain, velocity damping and limited actuation.

**Possible consequence:** A position-only controller corrects after the point is already moving. Corrections carry it back across the target. A later delay variant makes the consequence of acting on old information visible.

**Player choices:** Reduce gain, include velocity in the control rule, reduce the task's demand or stop the controller and balance manually.

**Carry forward:** More corrective power is not the same as better regulation. This can return in learning and adaptive-control sequences.

**Implementation boundary:** New apparatus and optional teaching concept. Do not make a full control-theory lesson a hidden prerequisite for completing Forces.

**Proposed test:** Declare a powered controller and force cap. Establish the no-delay baseline first. Distinguish modeled oscillation from numerical instability; test timestep sensitivity before interpreting an apparent runaway.

### 14. Containment / carry one point across

V · Live with the consequence · Capstone / no new force law

Candidate halls: Vectors_Act5_ForceAsPlace

**Task:** Carry one point to the plinth across a laboratory using the tools already learned.

**Learn:** Select and combine known forces; observe state, dependencies and the limits of the task.

**Possible consequence:** Use only a few active systems: a feeding belt, a movable receiver, a tether and a passing field. Clearing one obstruction changes what the next system receives. A spill can become a ramp, an anchor or a continuing blockage.

**Player choices:** Fly, redirect, hold admission, restrain a body, make another path, or preserve an unexpected arrangement. The final condition may deserve a name the instruction did not supply.

**Carry forward:** Leave the scene available to inspect. Later noise, agents or learning can revisit this same apparatus and introduce one new cause.

**Implementation boundary:** Composed encounter is a proposal. Existing artifacts do not yet share a verified force/receiver contract.

**Proposed test:** An ordinary successful delivery must be possible. Test component rules, retained state, body bounds and deliberate reset. Never require one collapse or comic ending to prove emergence.

Source references:

- [commons/artifacts/timing_machines/conveyor_backlog.gd](../../../../commons/artifacts/timing_machines/conveyor_backlog.gd)
- [commons/artifacts/force_field_zone/field_carry_provider.gd](../../../../commons/artifacts/force_field_zone/field_carry_provider.gd)

## Writing and implementation rules

1. Each encounter begins with one ordinary task and a baseline that can succeed.
2. First isolate the mechanism; then change one declared condition. A funny outcome is possible, not a required scripted ending.
3. The same black sphere, grey cubes, off-white trolley, tray, tether and receiving plinth recur. Ability changes are readable before new decoration is added.
4. A source of energy is visible: trigger thrust, powered belt, hand work, gravity or a preloaded spring. Nothing launches merely because the story needs a surprise.
5. The player can intervene: cut power, restrain, redirect, let go, use the result differently or reset explicitly. Preserve an aftermath long enough to inspect.
6. Keep body state and force input distinct. Position, velocity and spring extension carry consequences; do not accidentally keep accumulating a past force after it has stopped.
7. In Godot, declare who integrates motion. Use the engine for free rigid-body contacts; use one receiver owner for XR player movement. Do not apply a second custom integration to the same body.
8. The tutorial prints the minimal complete continuation and tests its rule. The reflection asks what the rule permitted, omitted and made costly. The museum can contain further experiments.
9. Technical failure, numerical instability and unexpected lawful behavior are different. Verify the first two before claiming an emergent consequence.
10. Noise, flocking, learning and soft bodies can return to these apparatus later. They are not hidden prerequisites for this Forces pass.

## Existing evidence

### The conveyor you named is in the cube hall

Point_Animatedcube contains cube_sorting_line. It feeds grabbable rigid cubes on a moving-surface belt; unsorted stock accumulates and can end the round. Settled cubes can be stored as backlog and reclaimed. That storage policy matters: it is not an unlimited pile of simultaneously active rigid bodies.

- [commons/maps/Point_Animatedcube/map_data.json](../../../../commons/maps/Point_Animatedcube/map_data.json)
- [commons/artifacts/cube_sorting_line/cube_sorting_line.gd](../../../../commons/artifacts/cube_sorting_line/cube_sorting_line.gd)
- [commons/artifacts/cube_sorting_line/cube_sorter_backlog.gd](../../../../commons/artifacts/cube_sorting_line/cube_sorter_backlog.gd)

### Forces already has another useful conveyor

Change_Choreography contains conveyor_backlog: rigid boxes, a timed receiver, a visible 48-body limit and held admission when full or obstructed. Feed and receiver rates can differ. These are strong foundations for the proposed overflow encounter; an expanded room-spanning cascade is still new work.

- [commons/artifacts/timing_machines/conveyor_backlog.gd](../../../../commons/artifacts/timing_machines/conveyor_backlog.gd)

### Existing diagrams are not automatically interacting apparatus

collision_carts shows calculated before/after lanes; tug_of_war directly positions a load; force_vortex assigns player velocity. They can inform the lessons, but they do not yet prove contact-driven collisions, a jointed tug or additive vortex forces.

- [commons/artifacts/collision_carts/collision_carts.gd](../../../../commons/artifacts/collision_carts/collision_carts.gd)
- [commons/artifacts/tug_of_war/tug_of_war.gd](../../../../commons/artifacts/tug_of_war/tug_of_war.gd)
- [commons/artifacts/force_vortex/force_vortex.gd](../../../../commons/artifacts/force_vortex/force_vortex.gd)

### The returning point needs a deliberate state policy

resolution_catalyst returns home after release, while interactive_point_origin_force already applies bounded attraction to nearby rigid bodies. Two-sphere flight, persistent consequences and the proposed receiver behavior need explicit implementation; sharing the point's appearance does not establish those abilities.

- [commons/artifacts/ignorance_gallery/resolution_catalyst.gd](../../../../commons/artifacts/ignorance_gallery/resolution_catalyst.gd)
- [commons/primitives/point/interactive_point_origin_force.gd](../../../../commons/primitives/point/interactive_point_origin_force.gd)

## First builds

1. Prototype 12 first: the conveyor already connects known cubes, rates, contact and a room that changes. Compare matched throughput with backlog, preserving the visible finite bound.
2. Prototype 9 next: fixed anchor → rolling anchor makes one changed assumption unmistakable and reuses the returning point.
3. Develop 3 alongside them as the accepted player ability: two trigger-controlled sphere contributions, one movement owner, gravity and retained velocity.
4. Use 14 to combine only the strongest verified encounters. Keep angular assemblage and the feedback platform optional until the core route is clear.

## References

- [Ashby: limits of regulation and requisite variety, chapter 11](https://ashby.info/Ashby-Introduction-to-Cybernetics.pdf)
- [The Nature of Code: Forces](https://natureofcode.com/forces/)
- [The Nature of Code: Oscillation / spring forces](https://natureofcode.com/oscillation/)
- [The Nature of Code: Autonomous Agents / steering](https://natureofcode.com/autonomous-agents/)
