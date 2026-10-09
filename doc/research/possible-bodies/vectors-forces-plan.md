# From an arrow to a room that acts

[Working route](index.html#Vectors_Act1_WhatAVectorIs) · [First vector hall and book](/necklace/thread?map=Vectors_Act1_WhatAVectorIs&role=primary) · [Change ideas](#change-ideas)

The accumulating question is **what bodies become possible with the capabilities we have learned?** A vector first describes a difference. Velocity gives movement a state that can persist. Acceleration changes that state. Forces, mass, contacts and constraints make movement depend on interactions. A field distributes a rule through space. A room can then participate in the computation.

The working method is to introduce one relationship, make its consequence observable, and carry it into another receiver. A hand-sized object and a wall should read the same measured state. A machine and the player should use explicitly related physical rules. Similar-looking arrows are not enough to establish that connection.

## Started: one vector, two wall views

VectorBasics now has an opt-in room_reading encounter in the opening hall. The editable arrow feeds XY and XZ projections on a large screen in a cleared side bay. SHORT, LONG, SHIFT and ZERO let the visitor compare magnitude, common translation and coincident endpoints before PARTS reveals components. The wall names clipping instead of silently treating its drawing window as the size of the world.

The two primary book artifacts remain VectorBasics and vector_normalize_demo. Supporting artifacts remain in the room. A normalization readout that always printed one now reports the actual output length, including zero.

![The editable vector and its wall projections](vector_start_Vectors_Act1_WhatAVectorIs.png)

[Desktop check report](vector-forces-start-check.json). Headset reach, tracked-hand use, visual comfort and sustained performance remain to be walked.

## The progression to build, hall by hall

The following are **curation and implementation proposals** based on the artifacts currently placed. They do not claim that all these connections are already implemented. Preserve useful existing encounters while selecting one or two linked primaries for each argument.

| Hall | Capability to retain | Application in the room and on bodies | Difference to test |
|---|---|---|---|
| Vectors_Act1_WhatAVectorIs | Displacement, magnitude and direction | **Started:** editable pins feed two wall views; normalization is the second primary. | Shift both addresses; preserve their difference. Inspect zero and clipped projections. |
| VFM_02_Operations | Compose vectors and inspect their contributions | **Implemented:** adder_board with room_sum shares its result between the wall, floor and carriage. Compare via-A and direct routes. [Walkthrough and checks](vector-addition.html). | Contributions can cancel while each remains nonzero. Separate displacement composition from applied force. |
| Vectors_Act2_VectorArithmetic | Apply addition, projection and turning at different scales | Use vector_addition_walk for a route, then torque_crank with a hinged wall. Retain the local demonstration next to its room application. | Equal force at different lever arms can produce different turning. A projected component leaves a remainder. |
| VFM_03_Motion | Retain velocity; integrate acceleration | VectorMotion drives a carriage with position and velocity traces continuing onto the wall. Compare equal force on two masses only through an explicit F/m model. | A visible position is not the whole state. Switch off the input and observe what persists. |
| VFM_05_Launch | Set an initial velocity; follow its subsequent evolution | Reuse force_pad and human_catapult. Compare a launched parcel with a player crossing toward the same marked landing region. | The existing pad assigns velocity; it does not apply a continuing force. Change launch components separately from gravity and drag. |
| Vectors_Act3_FieldsAndMotion | Sample a rule at the body's current address | Use field_room and its actual sampler for wall arrows, a test parcel and a bounded walk-through lane. Establish the data connection before adding field presets. | The wall sample and the body's sample can differ in address and time. Distinguish a direction field from acceleration or force. |
| Vectors_Act4a_KineticForces | Let resistance and constraints shape a route | Stage wedge_slide and drag_corridor as two legs of a larger machine. Let a parcel reveal a route before the player enters it. | Surface friction and velocity-dependent drag need different rules and different baselines. |
| Vectors_Act4b_Oscillation | Restoring tendencies, overshoot and damping | Compare a spring-driven carriage with an articulated wall or crossing platform. Preserve pendulum_hall and spring_tower as candidates for scale. | A prescribed periodic rotation and a physical oscillator can look similar while responding differently to disturbance. |
| Change_Choreography | Relative phase and throughput | **Built:** twenty light rods and the conveyor receiver. Four idea markers now hold the next experiments. | Fixed phase offset, frequency drift and physical backlog are different relations. |
| VFM_07_Gravity | Pairwise attraction and dependence on position | Begin with orbit_pair; project the same attractor geometry into a larger chamber. Review body physics before extending that field to the player. | A field is not a drawn orbit. Initial velocity and the central interaction jointly shape a trajectory. |
| VFM_09_Legs | Coordinate supports and contact through a gait | Preserve the seven existing walkers. Use comparable floor strips and a shared view of contact timing across body plans. | More legs change available coordination; do not silently give every body the same controller. |
| VFM_08_Arena | Exchange motion through collision and reflection | Link collision_carts or reflection_hall to movable partitions and visible approach vectors. Add targets after the collision argument is legible. | A reflected geometric direction is not a complete collision model: mass, restitution and contact matter. |
| Vectors_Act5_ForceAsPlace | Combine local rules into navigable space | Develop force_field_zone and vector_machine into a bounded room with wall controls, a test parcel, player entry and a clear exit. | Which rule acts where, how overlapping fields combine, and what happens when a body leaves the volume. |

**Ordering issue to resolve next:** the current route places VFM_05_Launch before VFM_03_Motion. I recommend teaching persistent velocity and acceleration in Motion before the launch experiment. This proposal is recorded here; the existing order has not been changed in this pass.

## One result, different receivers

For each encounter, record the quantity and units first. A displacement in metres, velocity in metres per second, acceleration in metres per second squared and force in newtons are different quantities even when each is stored as Vector3.

The reusable implementation should expose one result to the display and to each receiver. The wall draws it; a rigid body responds through its mass and physics; the player controller uses an explicit locomotion adapter. A controlled comparison names what is shared and what differs. A force application should eventually have these records:

- **Question and control:** what the visitor can change, and which values stay fixed.
- **Machine receiver:** the parcel, carriage, hinge or moving part that makes the result visible.
- **Spatial receiver:** the floor region, wall, platform or room volume that applies the rule.
- **Player receiver:** what can actually happen to the player, and through which controller.
- **Observation:** the predicted result, measured trajectory and useful discrepancy.
- **Remainder:** a threshold, saturation, excluded body, missed contact or unresolved boundary.

The current code already contains useful material, but its names are not sufficient evidence. force_pad sets launch velocity. force_field_zone applies acceleration-like velocity updates over time and compensates for the player's ordinary gravity. Before combining fields, test entry, exit, overlap and restoration of the body's previous settings. A force divided by mass must be implemented explicitly where that is the intended lesson.

<h2 id="change-ideas">Four wishes standing in Change</h2>

The proposals stand in Change_Choreography as if_not_exist_create artifacts. Each carries its requested token, purpose, example to inspect and intended footprint. They are non-solid, classified as decoration and excluded from the primary book thread. Replace a marker with its implemented encounter when ready; keep the map as the source of the request.

| Creation token | Cell | Intended footprint | Question |
|---|---|---|---|
| floor_eyes_delayed_attention | (18,6) | 4 × 4 | Do the eyes share a present, or look at different moments of the player's movement? |
| late_connection_platform | (18,11) | 4 × 3 | Can a phase adjustment make two individually working platforms form a crossing? |
| escalator_wrong_destination | (5,18) | 5 × 4 | What is local progress when the promised destination is a wall? Keep an alternate exit. |
| mutual_cleanup_machines | (6,24) | 5 × 2 | Where does the remainder go when each machine only clears its own patch? |

![Four future-idea markers around the two timing machines](vector_start_Change_Choreography.png)

These footprints are starting reservations to revisit during construction, not completed architectural solutions. The wish reader reports all four as open.

## Next actionable improvement

The addition encounter is implemented in VFM_02_Operations: two editable contributions, one sum, wall and floor views, and direct or via-A carriage travel. [See the illustrated encounter](vector-addition.html). Next, inspect Vectors_Act2_VectorArithmetic and build its comparison of operations from these same quantities. Motion then needs a distinct encounter where velocity persists and acceleration changes it; the proposed Motion-before-Launch reorder remains unapplied.

---

## The revised opening book passage

# The same difference, somewhere else

Can something move without its vector changing?

We have given points addresses, transformed shapes, made patterns and followed changes through time. Now keep two addresses together. One names a beginning; the other names an end. What can we carry forward from their relation?

<!-- @VectorBasics -->

At the first bench, move either pin of the small arrow. Watch the large wall. Two yellow arrows respond: an elevation view, XY, and a floor-plan view, XZ. They are two projections of the same displacement. Predict which view will change most before moving the tip again.

Press **SHORT**, then **LONG**. The displacement changes from a quarter metre to one metre without changing its direction. Look between the hand-sized arrow and the wall. The pictures have different display scales; their shared input is the difference between the pins in world coordinates.

Press **SHIFT**. Both pins move together by twenty centimetres along the bench. Their addresses change. Does the wall have anything new to report? Press again to return them. An unchanged picture can be evidence that the machine is doing exactly what we asked.

Only now press **PARTS**. The components and magnitude appear on the console; coloured legs make the components visible in each projection.

```gdscript
var displacement = end.global_position - start.global_position
```

Subtraction keeps the difference and discards the two original addresses. This is a free displacement vector: it can be represented at another origin without changing its direction or length. Later, where a force is applied will matter. We should not carry this freedom into every physical question without testing it.

The wall keeps the world axes fixed. Turning the bench changes how its local directions relate to that frame. A screen on a wall is another arrangement inside the room, not a transparent window onto mathematics. One projection leaves out Z; the other leaves out Y. Neither alone tells the whole displacement.

Now press **ZERO**. The pins coincide, and the displacement has length zero. There is no direction for the yellow arrow to show. If you press SHORT or LONG from this state, the interface chooses the direction (1,1,1), normalised. That direction is a convention supplied by the control, not information rescued from zero.

The wall samples the pins twenty times a second. An update can reach the small arrow before it reaches the large picture. If a projection exceeds the drawing window, the wall limits its drawn length and labels the clipping; the component numbers retain the measured displacement. The representation has a capacity, and it says where that capacity ends.

<!-- @ -->

The coordinate frame, route courier and length lantern remain nearby as supporting encounters. A path has an origin and a history even when a displacement summary does not keep them. What was useful to discard for this question may be necessary for the next one.

<!-- @vector_normalize_demo -->

At the second primary, compare the input vector with its normalised companion. Change the input direction and length. Which changes reach the companion? Which do not?

The operation divides a nonzero vector by its own magnitude:

```gdscript
var magnitude = v.length()
var unit = v / magnitude if magnitude > 0.001 else Vector3.ZERO
```

Length is removed while direction is retained. The sphere and rings provide the diagram's reference for unit length; they are part of the display's scale. A long input can become shorter and a short input longer. Normalisation is not simply shrinking.

This implementation also chooses a threshold: magnitudes at or below 0.001 return zero. It does not normalise every tiny nonzero input. The boundary keeps the calculation usable while treating a neighbourhood around zero as having no available direction. The numeric output now reports the computed length, including zero, rather than always printing one.

<!-- @ -->

We have made something reusable by leaving information behind. First the two addresses, then the magnitude. Reuse is powerful because of these reductions; the reductions also need to remain open to inspection.

Next, in **VFM_02_Operations**, vectors meet. We will compare a composed displacement with its separate contributions before asking a force to change a body's movement. The arrow on the wall can eventually become an instruction to the room. Today it describes; it does not push.


## Continued: the gap and its remainder

[The linked subtraction and projection encounters are now implemented](vector-gap-projection.html), with real Godot images, the revised arithmetic chapter and desktop checks. Five primary artifacts and all twelve placements remain. The current next hall is Launch; changing the route to put Motion before Launch is still a proposal.


## Continued: stand inside the curve

[Launch now has a full-scale chamber with central controls and paired flights](launch-chamber.html). The current next hall is VFM_03_Motion. The sequence order is unchanged.


## Motion is now built

[When the push ends](motion-chamber.html): a full-scale force-controlled body, central controls and the friction ramp comparison. Both book primaries are placed; 34 desktop checks pass. Continue from Motion to Fields and Motion. Headset review remains open.


## Fields and Motion is now built

[The arrow does not decide](field-receivers.html): two receivers sample one spatial rule, with central controls and linked floor/wall histories. One matching book primary; all 13 artifacts remain. 39 desktop checks pass. Kinetic Forces follows; headset review remains open.
