# Forces — tutorial sequence

Current canonical manuscripts, 6 October 2026. Exported in museum order. Read STATUS.md for readiness and review flags.

---

## 1. Vectors_Act1_WhatAVectorIs

# One displacement, two wall projections

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Displacement
- Magnitude and direction
- Normalization
- Display scale

The opt-in `lesson:room_reading` layer on VectorBasics starts with its input arrow and hides the legacy decomposition displays. A floor console offers SHORT, LONG, SHIFT, ZERO and PARTS. The input arrow is brought forward above the console. The projection screen occupies a cleared side bay; former interior grid columns in that footprint have been removed.

Both projections read `end.global_position - start.global_position`. SHORT selects magnitude 0.25 m and LONG selects 1 m. They retain direction above magnitude 0.0001; at or below that threshold they supply normalised (1,1,1). This preset threshold differs from the normalisation companion's 0.001 threshold. SHIFT alternates a common 0.2 m translation of both pins along the console axis. ZERO makes them coincide. PARTS reveals world components and two component-leg drawings. This is a description of displacement, not a force controller.

The wall's XY and XZ diagrams use 0.85 display metres per world metre. Each projection is limited to radius 1.05 display metres. The clipping label names that bound; the numeric displacement is unchanged. The adapter samples at 20 Hz and rebuilds only after a measured vector or reveal-state change. Body, world and drawing coordinates are kept explicit. Existing VectorBasics placements without the lesson metadata retain their interface.

The companion vector_normalize_demo uses a 0.001 magnitude threshold. Its numeric readout uses the computed unit.length(), including 0.000 for the zero result. Its drawn unit sphere belongs to the illustration's scale, not the world-metre scale of the first wall.

Before expanding this into bodily locomotion, introduce velocity state, acceleration and integration. The existing force_pad assigns launch velocity; force_field_zone adjusts velocity over time. They require distinct adapters and distinct comparisons.

## Reading and retained detail

The canonical [chapter](source/commons/maps/Vectors_Act1_WhatAVectorIs/final.md) follows the encounter. Exact scales, control steps, timing and implementation qualifications remain here. The complete [pre-pass chapter](source/doc/book/iterations/2026-09-24-forces-relations/before/commons/maps/Vectors_Act1_WhatAVectorIs/final.md) is retained for comparison.


---

## 2. VFM_02_Operations

# Two contributions, one destination

**Learning elements**

- Vector addition
- Resultant displacement
- Route length
- Coordinate conversion

Primary: `adder_board`, opt-in `lesson:room_sum`. Start with GO; then SWAP and GO. Predict the endpoint before revealing RULE. Compare PATH via A with direct. CANCEL makes B = -A; compare nonzero out-and-back distance with zero resultant.

Controls use real push_button pointer events: A/B selects input; X-/X+/F-/F+ change components by 0.5 m within [-1,1]. PATH switches route, SWAP exchanges inputs, CANCEL opposes them, GO homes and runs, RULE toggles arithmetic. There are no draggable pins in this room variant. The ordinary board retains its original interface in other placements.

`result = a + b` drives both wall and floor. Vector2 stores (local X, local forward) in metres; floor placement is Vector3(v.x, height, -v.y). Wall plotting uses 0.48 display metres per input metre. Both operands and all sums fit the chart; no projection component or result is clipped. Carriage speed is prescribed at 0.8 m/s. Waypoint traversal consumes leftover time across corners; movement is updated in the physics callback. The guarded AnimatableBody is not a force experiment or a player transport platform.

GO instantly resets position and travelled distance. Input/path changes stop and reset the trip; input selection and RULE do not stop it. The old 26 supporting instruments remain in their original relative arrangement, shifted ten source rows behind this arena. The next sequence hall remains Vectors_Act2_VectorArithmetic.

## From the floor plan into the scene

The carriage's coordinate conversion is:

```gdscript
return Vector3(v.x, height, -v.y)
```

The second plan component becomes local negative Z; height is supplied separately. The wall's upward diagram axis denotes forward movement on the stage, not a climb. Starting values A=(1,0), B=(0,1) give route length 2 m and direct length sqrt(2) m. The travelled counter starts again after GO's instantaneous homing; it does not include the reset movement.

## Reading and retained detail

The canonical [chapter](source/commons/maps/VFM_02_Operations/final.md) follows the encounter. Exact scales, control steps, timing and implementation qualifications remain here. The complete [pre-pass chapter](source/doc/book/iterations/2026-09-24-forces-relations/before/commons/maps/VFM_02_Operations/final.md) is retained for comparison.


---

## 3. Vectors_Act2_VectorArithmetic

# One gap, two stations

**Learning elements**

- Signed dot product
- Projection
- Remainders
- Recombination

Keep five existing primary tokens in order: vector_add, vector_sub, dot_aligner, projection_shadow, torque_crank. All twelve artifacts remain. The new work upgrades vector_sub and projection_shadow through opt-in room_gap and room_projection configurations; other placements keep their original consoles.

Subtraction: A/B selects an address, X-/X+/F-/F+ change a component by 0.5 coordinate metres, SWAP reverses A-B, SHIFT translates both by 0.5 along X and reverses on next accepted press, SAME copies A to B, RESET restores A=(1,.5), B=(-.5,0), RULE reveals arithmetic. Components are bounded to [-1.5,1.5]; common moves are refused atomically at the boundary.

Projection: binds to the gap source inside the same museum segment. TURN rotates a unit rail 30 degrees, SLIDE moves source A perpendicular to that rail by 0.5 metres (alternating sign), FLIP reverses rail orientation, RESET restores both source inputs and rail, RULE reveals arithmetic. The actual shared gap feeds kept=axis*gap.dot(axis), remainder=gap-kept. One coordinate metre is displayed as half a metre on both stages and walls. This is a diagram scale, not player/world position measurement. Values are live while the hall is loaded, not a saved cross-session state.

Test sequence: swap; common translation; coincidence; perpendicular slide; rail turn; sign reversal. Predict first, reveal second. Keep the input fixed while changing the receiver, then change the input in a direction the receiver cannot record. The closed loop is kept+remainder=gap. Zero gaps remain finite; the rail is never a zero direction.

Existing dot and torque consoles are distinct examples, not subscribers to this pair. Dot uses an alignment slider and a chosen threshold; torque uses normalized directions and a displayed wheel angle. Its readout reports sin(theta), the chosen angle and a static wheel pose. The unit-direction cross product sets that pose; it does not integrate angular velocity or report rpm. The final chapter now identifies those limits instead of claiming free aiming, continuous physical wheel motion or a newly simulated force.

Next on the unchanged route: VFM_05_Launch. Motion-before-Launch remains an editorial proposal.

The remaining dot console uses normalized directions and FRIEND at dot >= 0.985. Its ordinary slider spans a limited range; the full signed range of a dot product is mathematical context, not a claim that this control reaches every angle. The crank computes r_dir.cross(f_dir) from unit directions. Actual torque would include arm length and force magnitude; the displayed angular factor alone is not physical torque. Projection recombination and perpendicularity hold to ordinary floating-point precision.

## Reading and retained detail

The canonical [chapter](source/commons/maps/Vectors_Act2_VectorArithmetic/final.md) follows the encounter. Exact scales, control steps, timing and implementation qualifications remain here. The complete [pre-pass chapter](source/doc/book/iterations/2026-09-24-forces-relations/before/commons/maps/Vectors_Act2_VectorArithmetic/final.md) is retained for comparison.


---

## 4. VFM_05_Launch

# Control a flight from inside its diagram

**Learning elements**

- Position functions
- Initial velocity
- Acceleration
- Model assumptions

Primary launch_arc uses lesson:launch_chamber at source cell (17,7), yaw 180, floor placement without a plinth. All 17 artifact identities remain; the 16 supporting instruments keep their relative configuration shifted 14 rows behind the new arrival chamber. Footprint 34x38. gate_depth_rows=0 prevents an extra entrance partition from cutting through the flight lanes.

The visitor stands between two control banks, with analytic flight lanes at local Z=-3 and +3. Launches start at X=-5, Y=.3; landing is the same centre height. Local positions use metre scale. No collider, rigid-body force or player-velocity command belongs to the flight markers.

ANGLE-/ANGLE+ choose 15..75 degrees in five-degree steps. SPEED cycles 10→6→8→10 m/s. PAIR adds 90-angle at the same speed. GRAVITY toggles 10/15 m/s². These controls reset the current flight. FIRE restarts playback; SLOW toggles local elapsed-time speed 1/.25, and PATH/PARTS/RULE toggle representations without resetting flight.

Position is origin+v0*t+Vector3.DOWN*.5*gravity*t*t. Each lane clamps its own t at 2*v0.y/gravity. Landing freezes the pre-impact state, without collision resolution. Uniform gravity, equal endpoint heights and absent drag are explicit assumptions. Velocity arrows use 0.2 display m per m/s; acceleration arrows 0.1 display m per m/s². PATH draws 64 equal-time straight segments per trajectory; live markers are evaluated analytically at render time. Dynamic arrows reuse at most eight rigs during playback.

Discovery: launch before showing the prediction; compare complementary angles; observe different landing times; inspect zero vertical velocity at apex with continuing acceleration; vary one parameter at a time. Keep computed diagrams distinct from the other room's force pads and player-launch mechanisms.

Next on the unchanged route: VFM_03_Motion.

## Reading and retained detail

The canonical [chapter](source/commons/maps/VFM_05_Launch/final.md) follows the encounter. Exact control steps, arrow scales, timing, bounded histories and reset rules remain here. The complete [pre-pass chapter](source/doc/book/iterations/2026-09-24-launch-and-motion/before/commons/maps/VFM_05_Launch/final.md) is retained for comparison. This reading pass does not claim a new runtime or headset test.


---

## 5. VFM_03_Motion

# Motion: a command meets a stored velocity

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Force schedules
- Mass
- Retained velocity
- Engine integration

The two primary encounters are `VectorMotion` (this map's `motion_chamber` variant), then `friction_ramp`. Begin with the observable comparisons in final.md; use this page to inspect the mechanisms afterward.

## The chamber

Stand between the control banks. PUSH X and PUSH F each request a 2 N force for one second, in local +X or local -Z. A new push replaces the previous command and restarts its duration. COAST cancels commanded force and braking while preserving velocity. BRAKE applies force opposite the current velocity, capped at 2 N; a smaller final step avoids deliberately accelerating past rest. RESET clears position, velocity, local clock and history. MASS cycles 1/2/4 kg and resets the run. Neither reset changes the selected damping or reveal switches.

A `RigidBody3D` integrates motion. There is no manual position update during ordinary motion. Force is converted from the chamber frame to the world frame:

```gdscript
body.apply_central_force(global_basis * local_force)
```

For a constant force away from contacts, the useful prediction is delta_v = force / mass * duration. At 1 kg the full 2 N pulse gives about 2 m/s; at 2 kg about 1 m/s. PUSH F after PUSH X adds a perpendicular velocity component. It does not erase the earlier one.

The body has zero gravity, explicit replacement damping, locked height and rotation, no sleeping and continuous collision detection. DRAG toggles linear damping between 0 and 0.8. COAST does not disable damping. The cube and four static boundaries share only collision bit 19; the visitor and furniture are excluded. Boundary materials produce an elastic reflection under the tested desktop solver. This is a selected horizontal collision world, not the museum's complete contact world.

PARTS reveals three reused arrow rigs: velocity (0.35 m per m/s), measured acceleration (0.2 m per m/s squared), commanded force (0.3 m per N). All cap at 2.5 m. Measured acceleration is the change in solver velocity divided by the physics interval. It can include contacts and damping absent from commanded force. The readout updates at 10 Hz, so brief contact peaks are not a complete force record.

TRAIL displays at most 120 position samples at nominally 10 Hz. It records even while hidden and discards the oldest sample when full. The geometry rebuilds only on sampling; arrow nodes are reused. The running time belongs to this resettable experiment, not the engine's total lifetime.

## The smaller friction ramp

At 30 degrees, vary the coefficient mu; then hold mu fixed and vary angle. Reset between comparisons of descent. The custom scalar model tests:

```gdscript
_is_sliding = sin(angle_rad) > friction_mu * cos(angle_rad)
```

When sliding, acceleration is `G * (sin(angle_rad) - friction_mu * cos(angle_rad))`. Velocity accumulates acceleration times delta. Displayed travel accumulates velocity times delta times 0.01, and reaching the end resets the block. The STATIC branch immediately sets velocity to zero. One coefficient serves the model's starting and sliding conditions. Do not treat that discontinuous reset as the large chamber's braking response or the display distance as an unscaled physical measurement.

The map opts into a physical stand via `#table:1`. Its placement offset is 0.1 m above the museum's 1 m support; the panel is at world height 1.06 m. Other ramp placements are unchanged.

## Red thread and evidence

Launch calculated a complete flight from its initial conditions. Motion keeps a current state for the next intervention. `Vectors_Act3_FieldsAndMotion` follows: inspect whether its spatial instructions prescribe velocity or change it through acceleration before calling them forces.

34 desktop checks pass in `commons/testing/probe_motion_chamber.gd`: real pointer presses, pulse/mass/coast/brake/drag/contact response, bounded history, stable arrow allocation, sampled approaches, control heights, ramp threshold and legacy compact scene. Headset reach, comfort and performance remain untested. All 17 source artifact identities remain; two are primary.

## Reading and retained detail

The canonical [chapter](source/commons/maps/VFM_03_Motion/final.md) follows the encounter. Exact control steps, arrow scales, timing, bounded histories and reset rules remain here. The complete [pre-pass chapter](source/doc/book/iterations/2026-09-24-launch-and-motion/before/commons/maps/VFM_03_Motion/final.md) is retained for comparison. This reading pass does not claim a new runtime or headset test.


---

## 6. Vectors_Act3_FieldsAndMotion

# One field, two receiver rules

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Position and velocity state
- Assignment and accumulation
- Acceleration updates
- Reset conditions

This follows VFM_03_Motion, where finite force pulses changed a rigid body's stored velocity. It prepares Vectors_Act4a_KineticForces, where named forces must be connected to particular bodies and units.

The sole book primary is VectorFieldFlow, opting into `field_receivers` in this map. Its ordinary compact scene remains available in other placements. VectorMotion and the other eleven supporting artifacts remain placed.

## Compare before explaining

Start in SINK at gain 1, positive sign. RUN for about four model seconds. Cyan approaches the centre without crossing; pink crosses and starts returning later. Reveal TRAILS, then ARROWS and RULE. Pause with RUN. RESET clears both states and histories and pauses, retaining parameters and reveals.

FIELD cycles SINK, SWIRL, UNIFORM. REVERSE flips sign. GAIN cycles 1 -> 1.5 -> 0.5 -> 1. Parameter edits preserve state, making a reversed influence different from a velocity reset. RESET between controlled comparisons.

## Spatial rule

SINK returns `Vector3(-p.x, 0, -p.z) * 0.35`; SWIRL returns `Vector3(-p.z, 0, p.x) * 0.35`; UNIFORM returns `Vector3.RIGHT * 0.8`. The base value is capped at length 2 before gain and sign. These are dimensionless samples in this apparatus. The floor shows 63 samples through two MultiMeshes, with 0.4 m of arrow per field unit. Samples are rebuilt only when parameters change. Hiding arrows does not change the model.

## Receiving the sample

Cyan sets `velocities[i] = sample`, using a conversion of 1 m/s per field unit. Pink adds `velocities[i] += sample * STEP`, using 1 m/s squared per field unit. Both then perform `positions[i] += velocities[i] * STEP`. Each samples at its own position, so their inputs diverge after their positions diverge.

This is an explicit numerical, collision-free comparison. Pink uses a semi-implicit Euler acceleration update; it is not a RigidBody3D and has no mass or applied force. In the previous hall the physics engine integrated a real rigid body. Here the two update rules are deliberately exposed side by side.

The fixed model step is 1/120 s. A call advances at most 0.25 model seconds; longer stalls discard excess wall time. At the frame limits |X| >= 5 or |Z| >= 4 a receiver freezes just beyond the threshold, keeping its outgoing velocity. This is an observation cutoff, not a collision. Both exiting pauses the run.

Markers are displayed at heights 1.45 and 1.9 m, but use identical planar coordinates and initial position (-2, -2). Their history buffers keep at most 240 positions, sampled every 12 steps. The same positions draw a floor-space path and a wall plan with X scaled by 0.5 and Z by 0.28. Different projection scales mean wall lengths and angles cannot be read as metre-scale geometry. Controls stand at 1.04 m; routes to either side remain open.

## Relation to the old scene

The preserved compact VectorFieldFlow blends previous velocity toward a sample with `lerp(sample, 0.35)` and multiplies by 0.985 each rendered update. It retains velocity state and is neither the new direct velocity assignment nor the new acceleration integrator. Its coefficients are per frame. The old chapter's memoryless claim was inaccurate. Its manuscript is backed up with the room's before state.

39 desktop checks cover the pointer controls, sink overshoot, uniform quantitative predictions, reversal, parameter cycles, pause/reset, timestep partition agreement, history limits, exit convention, stable geometry, sampled approaches, control height and legacy scene creation. Headset reach, comfort and sustained performance remain open.

## Reading and retained detail

The canonical [chapter](source/commons/maps/Vectors_Act3_FieldsAndMotion/final.md) follows approach, overshoot, reversal and the observation boundary. The opening trail comparison concerns overlaid return travel: pink's extent beyond the centre can show that it crossed, while a static line does not by itself show timing, repeated visits or current direction. The exact integration, history, arrow sampling, gain cycle and exit conventions remain above. The complete [pre-pass chapter](source/doc/book/iterations/2026-09-24-field-and-receiver/before/commons/maps/Vectors_Act3_FieldsAndMotion/final.md) is retained for comparison. This reading pass adds no runtime or headset result.


---

## 7. Vectors_Act4a_KineticForces

# Kinetic forces: inspect the receiver

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Velocity-dependent force
- Linear drag
- Mass response
- Receiver contracts

This hall follows the field receiver comparison and precedes Vectors_Act4b_Oscillation. Book primary order: drag_corridor, force_mower, centrifuge_ring. All eight source artifacts remain.

## Physical drag

The map opts drag_corridor into kinetic_drag. Three RigidBody3D probes start at local X=-4 with velocity 4 m/s along +X. Each holds a fixed coefficient b: 0.4, 1.3, 3.2 kg/s. The applied force is -b times world velocity. Default mass is 1 kg; MASS cycles 1/2/4 and resets the bodies to a held state. FIRE restarts. Linear and angular damping are explicitly replaced by zero, gravity is zero, rotation is locked and the local scene is at unit scale with no yaw. The observation freezes a probe after X reaches +4, retaining its outgoing state. There is no collision response at that cutoff.

Away from the cutoff the continuous prediction is v(t)=v0 exp(-b t/m). The discrete engine response is checked against this with a numerical tolerance. The coefficient is a chosen model value, not a measured fluid property. Pink force arrows reuse three rigs, drawn at 0.12 m/N. Readouts update at 10 Hz. The force calculation continues each physics update.

WALK starts off. In the central strip |X|<=1.35, Z from -4.5 to +4.5 and local Y between -0.2 and 2.3, it returns a locomotion multiplier 1/(1+b_numeric), where b_numeric is the numeric coefficient in kg/s. This is an explicit illustrative mapping, equivalent to normalising b by 1 kg/s, not another integration of the probe's force.

The ordinary endless-museum desktop path applies that factor to horizontal velocity after input/feel computes it and before move_and_slide. It leaves vertical velocity untouched. The XR adapter runs at order 90 after direct movement requests and scales ground_control_velocity. It respects exclusive movement. Because XRTools caches its providers at ready, the body-owned adapter is inserted once into the cached list when this opted-in room finds an XR body; newly added XR bodies are handled too. It remains a no-op when no enabled medium contains the body. Tracked physical walking is not damped. Headset comfort is untested.

## Signed mower work

The mower remains a constrained pickable prop. Its path counter sums displacement lengths. Signed nominal work now sums nominal_force.dot(displacement), with the drawn F_MAG=0.95 N force aligned to current mower orientation and configured angle. A forward-and-back traversal with fixed orientation cancels nominal work but adds two legs of path. A sideways move contributes zero nominal work. This is not measured hand effort or a physical energy budget. Grass cutting remains a proximity operation and is not undone by returning. The initial placement is excluded from the ledger by seeding the first measured position on the first process update.

## Prescribed circle

The ring's actual angular speed now equals its displayed linear speed divided by radius. The prior two unrelated speed mappings disagreed. This map adds a SPEED button cycling 2/4/6 m/s at radius 3.4 m. An angular phase accumulates independently, so speed edits preserve position on the circle. The button rebuild is deferred until after its press event completes. Two arrows are built on parameter changes and transformed with the pod each frame, avoiding repeated mesh creation. Velocity uses 0.18 m per m/s; required centripetal acceleration uses 0.10 m per m/s squared. The inward arrow is an acceleration, not a mass-specific applied force.

## Verification

The desktop probe exercises actual physics decay, mass response, live pointer controls, the ordinary desktop movement path, XRTools adapter registration and stick-request transformation without hardware, exclusive movement, signed mower work, ring speed/phase, clear corridor samples and control reach. This is not a headset playtest. See the illustrated guide and machine-readable check report for the final count.


---

## 8. Vectors_Act4b_Oscillation

# Restoring Forces and Balance

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Restoring force
- Damping
- Equilibrium
- State integration

This hall builds on accumulated velocity in Motion and linear drag in Kinetic Forces. Its one primary, spring_tower with lesson:restoring_forces, uses a horizontal spring-damper variant. The legacy tower remains a prescribed cosine animation elsewhere. The later Wavefunctions chapter develops rhythm, records, phase and sound.

## State and update

restoring_forces.gd stores scalar displacement x in metres, velocity v in m/s, mass m in kg and stiffness k in N/m. It integrates F = -kx - cv with semi-implicit Euler: velocity first, then position using the new velocity. A 1/120 s accumulator produces identical results for 30/60 Hz frame partitions. Each external update caps catch-up at 0.25 seconds. The frozen XRToolsPickable is the model's view and input handle, not an independently simulated rigid body.

Default x=1.25, v=0, m=2, k=8, damping ratio zero, initially held. A horizontal rail assumes support: gravity, contact friction and collision forces are absent. Equilibrium is x=0. The drawn coil stretches between x=-3.2 and the cube; its geometry is illustrative and is not a soft-body solver.

Damping coefficient c=2*zeta*sqrt(k*m), in kg/s. Ratios are 0, 0.25, 1 and 2.5. Critical/overdamped non-crossing comparisons use release from rest in this linear undriven model. Parameter changes retain x and v. Changing m/k can alter calculated energy; changing either recalculates c to retain the selected ratio.

## Input

Two banks offer PULL / RELEASE / RESET and DAMP / MASS / SPRING / PARTS / RULE. PULL cycles held displacements -1.25, +0.625, +1.25; RESET returns to +1.25. Both zero velocity, elapsed model time and crossings while retaining parameters and reveal settings. RELEASE zeros velocity and begins from the current position. DAMP cycles the four ratios; MASS cycles 2/4/1; SPRING cycles 8/16/4.

Actual XRTools pickup and drop signals are connected. spring_handle.gd runs at physics priority 100 after the grab driver, projects its requested world position onto local X, clamps to +/-1.5 m, and keeps Y=1.35, Z=0 with fixed orientation. Dropping begins motion from rest, ignoring throwing velocity. PULL/RELEASE/RESET are ignored while grabbed. The handle belongs to no_gravity_gun and releases frozen. Collision mask zero prevents a competing contact solver. Tracked-hand comfort is untested.

## Displays and limits

PARTS shows cyan restoring, orange damping and gold total force, on the body and wall. Both use the same samples and 0.04 m/N scale. RULE reveals the update; numerical readouts run at 10 Hz. Coil mesh and six arrow rigs are allocated once and transformed thereafter. There is no time-history plot here.

A crossing counts a displacement sign change during free integration. The cutoff at |x|>2.25 freezes outgoing state and retains velocity in the readout. It does not bounce, clamp the model to a wall or dissipate its velocity. The model continues arbitrarily small motion near rest rather than inventing an exact stopping threshold.

## Space and checks

All 22 identities remain. A sixteen-row arrival extends the room from 30x30 to 30x46. Spring moves to (15,8) at unit scale; the other 21 placements shift together. surreal_kinetic_sculpture is compacted to scale 0.12 and raised 0.7 m. Its opt-in presentation:museum disables standalone lights, cameras and screen overlays while retaining its moving forms.

The actual museum probe verifies analytical free-spring response, energy error tolerance, damping comparisons, mass response, frame partition agreement, live pointer controls, supplied XRTools pickup/drop, retained state, force signs, matching wall arrows, allocation stability and sampled approaches. See restoring-forces-check.json in the illustrated guide for the current count. Headset testing and detailed supporting-exhibit review remain open.


---

## 9. Change_Choreography

# Timing machines: period, phase and throughput

**Learning elements**

- Period
- Phase
- Relative rate
- Accumulated angle

This hall follows Vectors_Act4b_Oscillation in Forces. It returns to the rate and accumulation ideas from Change. Its primary order is phase_rod_array then conveyor_backlog; the later gravity hall retains its position.

## Twenty rotors

A four-by-five indexed array uses `angle = TAU * frequency * elapsed + phase`. Base frequency is 1/6 Hz. ONE + changes index 9 by PI/4 modulo TAU. WAVE sets phase `(index % 5) * TAU/5`. DRIFT sets indices 10..19 to 1.04 times the base frequency. Relative frequency is 1/150 Hz, so the two groups align every 150 seconds. Controls switch configurations immediately; elapsed time remains continuous. RESET restores equal phases and frequencies, not elapsed zero. RULE toggles the displayed equation. Rotation is prescribed, not simulated by torque. The light rods are visual moving parts above collidable bases.

## The receiver

The existing conveyor_belt scene supplies the visual deck. A new StaticBody3D provides a moving surface, with world-oriented `constant_linear_velocity` of 0.9 m/s. Spawned RigidBody3D parcels have mass 0.5, side 0.44 m, friction 0.75 and bounce 0.05. Continuous collision detection is enabled. Parcel sleeping is disabled so a queue released on a moving static surface resumes contact-driven motion. The belt surface is 1.2 m above the floor; the narrow receiving tray has its floor at 0.45 m. Belt, side rails and receiving tray have colliders. Finite contacts and the physics timestep govern the resulting arrangement.

Feed attempts occur every 1.2 seconds. Each collection pulse removes at most the oldest live parcel whose local x is at least 2.9 m and whose centre has dropped below 1.12 m into the tray. The receiver intervals are MATCHED 1.2 s, BACKLOG 3.0 s, RECOVERING 0.6 s. A pulse with no arrived parcel does nothing. Entering a receiver mode restarts its interval timer; it does not reset the feed timer or existing parcels. RESET clears parcel bodies and local counts, restores matched operation and preserves elapsed time.

`admitted - collected == boxes.size()` is the accounting invariant. Admission pauses if the inlet is occupied or the 48-body cap is reached. Capacity is shown on the console. The experiment is bounded; it is not an unlimited source of physics bodies. Parcels are rigid bodies, not XR pickables, and the pile is not a certified climbing route.

## Review

Compare one phase offset before a phase wave, then frequency drift. Compare actual transport under matched intervals, backlog and recovery. Desktop scripted-pointer and physics tests accompany the first implementation. Headset reach, hand interaction, label comfort and live performance remain to be walked.


<!-- study-spine:paired_time -->

## Return: A second together

Halve the rate difference; compare the growing gap with an unchanged phase offset. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses loop, rate, transform. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`paired_time`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](source/doc/book/iterations/2026-10-02-gonzalez-torres-a-second-together/index.html). These controls change only the dial state. RESET restores this pair without restarting the hall.

<!-- study-edit:paired_time -->

### One source change: A second together

Change DRIFT_RATIO from 1.04 to 1.02 in paired_time_score.gd. After RESET and DRIFT RIGHT, predict the gap after 30 seconds: 18° instead of 36°. Keep the 12-second base period. Then choose SAME RATE and observe that the gap stops growing without closing.

```gdscript
const DRIFT_RATIO := 1.02
```

Source: `commons/artifacts/spine_studies/paired_time_score.gd`. Use the prepared scene to run and compare.

<!-- paired-time-reference -->

### Compare a rate with an offset

This encounter follows the phase rods and the conveyor in **Forces → Choreography**. The map ID retains the name `Change_Choreography`. Day Zero supplied the repeating update; Change supplied a rate and its accumulation; Oscillation and this hall supplied returning movement and phase. The two dials are an application of that existing toolbox.

Begin with RESET. Each hand makes one turn in twelve seconds. Use DRIFT RIGHT, wait thirty seconds and then reveal READING: the right hand has gained 36°. SAME RATE gives the right hand the left hand's speed while preserving both current positions. The gap stops growing. OFFSET +45° changes only the right position, immediately. ALIGN copies the left position to the right without changing either rate. If their rates still differ, alignment lasts only an instant.

HOLD / RUN pauses these two stored angles, not the player or the museum. READING reveals the current ratio and clockwise phase gap. RESET restores the original angles, equal rates, running state and hidden readout. No controls move the wall or its collider.

The one-line edit above halves the rate difference. Before running it, predict the gap after the same thirty seconds. The relative rate is `(1.02 - 1.0) / 12` turns per second. It gains 0.05 turns, or 18°. At a 4% difference the dials align every 300 seconds; at 2%, every 600 seconds. This is visual alignment modulo a turn, not recovery of a lost history.

### What the program keeps

The production score stores two angles. Each update adds its chosen rate multiplied by the same `delta`:

```gdscript
left_angle = fposmod(left_angle + TAU / PERIOD_SECONDS * delta, TAU)
right_angle = fposmod(right_angle + TAU / PERIOD_SECONDS * right_ratio * delta, TAU)
```

Changing `right_ratio` does not replace either angle. That is why changing speed has no immediate jump. `align()` assigns `right_angle = left_angle`; it has a different job. `fposmod` keeps the displayed angles within one turn. The code discards whole-turn counts, so its readout cannot tell you how many times one dial has lapped the other.

The renderer maps those angles onto identical single-hand dials; all fabrication, pointer controls and the museum player are supplied. Neither dial is a wall clock. They have no independent oscillator, battery or ageing mechanism. Engine stalls advance both through the same elapsed delta; the rate difference is authored explicitly. Full hardware clock synchronization, audio, independent oscillators and lifetime simulation are outside this first edit.


### References and model limits

[Whitney: Felix Gonzalez-Torres](https://whitney.org/artists/3454). The Whitney research led to this artist. This particular paired-clock reference is not presented as a Whitney collection work.

[Foundation: “Untitled” (Perfect Lovers), 1991](https://www.felixgonzalez-torresfoundation.org/works/untitled-perfect-lovers2). The Foundation records two wall clocks and wall paint, ideally installed above head height. Ada uses enlarged single-hand dials and explicit rate controls; it is an original application, not an authorized installation or reconstruction of that work.

[MoMA: “Untitled” (Perfect Lovers), 1991](https://www.moma.org/collection/works/81074). MoMA describes initially synchronized battery-powered clocks, possible drift or stoppage, resetting, and the context of the artist’s partner being diagnosed with AIDS. The digital study models none of that bodily or material vulnerability.

<!-- /paired-time-reference -->


---

## 10. VFM_07_Gravity

# Gravity: two encounters, one interaction law

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Pair contributions
- Receiving masses
- Equal and opposite forces
- Held sources

Start with RUN, watch, then use the left bank to change a beginning. PARTS and RULE reveal the model after observation. Stable primary tokens are orbital_mechanics_demo and three_body_problem. Both opt into commons/artifacts/orbital_mechanics_demo/gravity_relations.gd; the original standalone scenes remain available without the lesson metadata.

## Controls

| Control | Effect |
| --- | --- |
| RUN | Pause/resume retained state; a frame exit requires RESET. |
| RESET | Reset both copies and their clocks/trails, retaining selected parameters; wait paused. |
| SPEED, first station | Reset with 0.6, 1, 1.25 or 1.6 times this softened model's circular speed at radius 3 m. |
| REVERSE, first station | Negate current satellite velocity without resetting position or time. |
| BODIES, second station | Toggle two/three equal 4 kg masses; reset. The first pair's initial states remain the same. |
| NUDGE, second station | Reset paired copies with 0, 0.03 or 0.15 m added only to the last body's initial X in copy B. |
| PATH | Hide/show history; recording continues. |
| PARTS | Show acceleration arrows, scaled 0.30 m per m/s² and capped at 2 m; baseline maximum acceleration stays numerical on the board. |
| RULE | Reveal softened law, units, integration frequency and fixed/mutual response. |

## Model and retained state

G=1 m³/(kg s²), epsilon=0.25 m. Pair force is G mi mj r/(r²+epsilon²)^(3/2). The first experiment assigns no acceleration to source zero (12 kg); satellite mass is 1 kg. The second adds equal and opposite pair forces before dividing by each 4 kg receiving mass. This is a changed model of close attraction, not an exact point-gravity solver.

Velocity Verlet advances at 1/240 s. Each step computes all accelerations, half-kicks velocity, drifts positions, recomputes accelerations and finishes the kick. Frame-delta catch-up caps at 0.25 s, so a longer stall does not simulate all elapsed wall time.

The equal pair begins at X=-2/+2 with opposite tangential velocities calculated for a softened circular pair. The third begins at (0,0,2.6), velocity zero. A nudged comparison retains its changed centre of mass: no recentering or velocity adjustment. RMS separation measures corresponding positions at the same model time; it is not a Lyapunov exponent.

Both models calculate in X–Z. Opaque bodies render at Y=1.45; translucent comparison bodies at Y=2.10. This offset is display only. Bodies have no mutual collision or player-force coupling. The visitor can stand within the plan.

Trails sample at 20 Hz, retain 240 positions per body and reuse mesh resources. The entire experiment freezes when any body's absolute X or Z exceeds 5.2 m. Outgoing velocity is preserved. This is an observation cutoff, neither a wall response nor a proof of escape.

## Evidence

The actual-museum desktop probe commons/testing/probe_gravity_relations.gd passes 51 checks: circular motion, reversal, conservation tolerances, third-body contributions, controlled nudges, deterministic replay, frame cutoff, bounded trails, controls and sampled capsule approaches. At four seconds, the selected three-body baseline has momentum residual 0.00001985 kg m/s and energy ratio 0.99992286 relative to its beginning. Tested momentum tolerance is 0.001 kg m/s; the solver uses finite-precision Vector3 state. These bounds describe this checked interval, not all possible configurations. Headset reach, comfort, performance and detailed secondary review remain open.


---

## 11. VFM_09_Legs

# Support before a step

**Learning elements**

- Support polygons
- Mass projection
- Static balance
- Model limits

## Primary 1: support_polygon_lab

The 3.4 × 0.25 × 3.4 m plate is an actual RigidBody3D, mass 10 kg, gravity_scale=1, no added linear/angular damping and no sleep. Its custom centre of mass cycles (0,0,0), (-0.65,0,+0.65), (+0.65,0,-0.65). Inertia remains (12,20,12) kg m², a prescribed tensor rather than an automatic recalculation of a material load. A gold X-ray cube sits at that exact mass centre.

Four posts at X/Z=±1.35 m have 0.16 m square tops at Y=1.5 m. The held plate begins with its underside 0.01 m above them. Plate, posts and catching floor share friction 0.8 and bounce 0. They use private collision bit 22. The player and ordinary museum furnishings do not collide with the load.

| Control | Implemented action |
| --- | --- |
| RELEASE | Unfreeze and wake the load; engine gravity/contact then determine motion. |
| RESET | Restore level pose and zero velocities, freeze, retain choices. |
| FEET | Cycle four posts; three excluding corner 1; adjacent pair 3/4; diagonal pair 2/4. Reset held on each edit. |
| SHIFT | Cycle the three custom mass centres and reset held. |
| PARTS | Show X-ray mass centre, its floor projection, initial footprint on floor and wall, live wall cross, measured tilt and initial signed margin. |
| RULE | State the assumptions and material/body settings. |

Geometry2D.convex_hull encloses the corners of the selected pad squares. Signed margin is the shortest distance from the initial mass projection to that outline, positive inside and negative outside. The footprint is a prediction for the initial horizontal arrangement, not a live collision/contact sensor. The wall compresses floor Z by a factor of 0.6; it is a plan of the same geometry, not a second experiment. Measured tilt is acos of body-up dotted with world-up.

With vertical weight and suitable upward support forces, a mass projection inside the support polygon allows static balance. Finite contact patches matter: two opposed squares span a narrow area; two ideal points span only a line. Boundary equilibrium is marginal. This does not decide dynamic balance, frictional sliding, arbitrary contact orientations or a gait controller.

## Primary 2: four_leg_critter

The original scene is retained. Body extends leg_walker_base.gd, a MeshInstance3D. Patrol advances position directly. Ground sampling helps place foot targets; it does not integrate body gravity. _update_gait chooses the most overstretched planted foot when no foot is stepping. Swing interpolates a target with smoothstep and adds a parabolic vertical arc. FABRIK reaches toward the target. No support-polygon test governs lifting and no body tipping results from unsupported configurations.

The other six walkers remain as supporting variations. The row changes more than leg count; rig dimensions and stepping rules differ. Neither diagonal pairing nor a particular gait follows necessarily from having four legs. Do not reuse the earlier map prose as physical evidence; it is archived in the before record.

## Verification

The actual-museum probe exercises pointer buttons, held/reset behavior, real contact support and tipping, finite-pad geometry, shared material, exact mass marker, paired floor/wall display, original four-leg scene and five sampled standing approaches. Captures are actual Godot desktop views. Headset legibility, reach, comfort and sustained performance remain open. The experiment does not give the player physical weight on its plate.


---

## 12. VFM_08_Arena

# Arena: selection, state and collision

**Learning elements**

- Eligibility conditions
- Occlusion
- Event history
- Authored thresholds

## arena_relation_lab

A full-scale station wraps the existing head_crab.gd controller using lesson_crab.gd. That subclass replaces only candidate selection and fallback target acquisition. It nominates this station's food and either a beacon or one actual museum-player node. The nearest visible candidate strictly within 6 m is eligible, excluding the inherited temporary ignore list. A strict less-than comparison means an exact distance tie retains the food candidate encountered first. No sight memory is used; stale targets are cleared on selection. This is explicitly different from the base crab's global candidate groups and brief sight memory.

Candidate distance uses 3D node positions; _sees uses the existing horizontal ray at floor + 0.20 m with collision mask 1. The screen is real query-blocking geometry. It can also block the visitor's route when present; passages remain at both ends. The displayed candidate line lies at a fixed display height and is not the ray itself.

Crab scale is 0.3, chase speed 0.8 m/s, patrol speed zero, path grid disabled. Existing whisker/shape-query avoidance and plant/swing gait remain. Movement writes position; this is not a RigidBody3D and does not model momentum transfer. The scoped crab cannot bite. Existing crabs and turret deeper in the hall retain their own behavior.

| Control | Action |
| --- | --- |
| RUN | Pause/resume this crab's controller, including the feeding timer. |
| RESET | Replace crab with an unfed instance, remove this station's food, pause; retain beacon, screen, visitor and reveal choices. |
| BEACON | Cycle centre, right, left target positions without resetting the animal. |
| VISITOR | Switch nominated target between beacon and actual museum player. |
| FOOD | Offer one native mushroom on the pink pad; no stacking, none after the stopping threshold. |
| SCREEN | Show/hide a 2.4 × 1.4 m collision screen and its sight obstruction. |
| PARTS | Reveal candidate, candidate line, distance, feeding timer and completed meals. |
| RULE | Expose selection scope, distance/sight geometry, lack of sight memory and the five-meal threshold. |

Food reuses SporeMushroom via lesson_food.gd. _plant removes global spider_bait membership; only this station's selector considers it. Walking pickup is disabled. begin_absorb, consume, eating animation and the meal count use the existing code. A meal begins within feed_reach=0.26 m measured horizontally and takes feed_time=2 seconds of controller updates. Once begun, feeding completes before selection resumes. The fifth completed meal calls _root, disables bite and both speeds. No branches are created and no policy is learned.

At absolute local X or Z greater than 5 m, the station pauses its crab. This is an observation bound, not a wall. RUN cannot resume a boundary exit until RESET. Food's short planting/consumption tweens are separate from pausing the crab.

## collision_carts

The existing scene and passage are retained. MASS RATIO maps 0..1 to striker mass 0.4..2.6; target mass is 1, incoming striker speed 1, target initially still. Analytic elastic 1D outcomes are vA=(mA-mB)/(mA+mB)*u and vB=2*mA/(mA+mB)*u. Upper/lower lanes show before/after. Both momentum and kinetic energy balance under those stated conditions. Arrows have a visibility threshold and a fixed length offset, so their drawn length is not a precision speed scale.

## Verification scope

The desktop probe runs in the actual museum and checks live pointer controls, selection/occlusion, autonomous arrival and feeding, timed consumption, five-meal state, reset, actual player nomination, observation boundary, approaches and the retained collision-carts model. It also tests conservation at three ratios independently of the displayed arrows. These do not certify every retained Arena artifact. Headset reach, legibility, comfort and sustained performance remain open.


---

## 13. Vectors_Act5_ForceAsPlace

# A local acceleration and three receivers

**Learning elements**

- Field membership
- Acceleration
- Retained velocity
- Receiver adapters

Start with vector_machine, force_cube, then force_field_zone. Compare the preserved plank with entry into the field. The machine exposes pitch [-pi/2,pi/2], yaw [0,2pi], magnitude [0,15] m/s². Yaw zero points world +Z. Opening acceleration (0,-9.8,0); for an initial up/forward trial choose pitch about 45 degrees, yaw zero, magnitude about 7.5. These values invite a crossing attempt, not a guaranteed landing for every incoming velocity.

The lesson is opted in by #lesson:force_as_place on the machine, zone and three probes. The machine locates the shared em_map ancestor and updates only opted-in zones there, including zones loaded after its controls. Legacy machines skip these scoped zones.

Released RigidBody3D receivers in the real Area3D save gravity_scale, replace it with zero, then add field_vector * delta directly to linear_velocity. This is acceleration, independent of mass. Godot retains body damping/contact. Leaving the area, becoming frozen, or removing the field restores saved gravity. There is no claim that this overrides every other force.

Desktop locomotion samples incoming velocity before its ordinary update, then asks the opted-in containing field for its retained post-collision velocity plus a*dt. The final handoff happens before move_and_slide; collision output is recorded for the next step. While inside, this replaces keyboard steering/jump output. Exit clears field history, ordinary horizontal input takes over, and the vertical state returns to normal gravity. First containing field owns a visitor if volumes overlap.

The XRTools provider runs at order 95, respects earlier exclusive providers, uses move_player and returns exclusive ownership inside. It installs for both existing and late XRTools player bodies without duplicates. This changes software locomotion, not tracked physical movement. Headset comfort and embodied testing remain pending.

Field dimensions: five metres, centred in X/Z and extending from local y=0 to 5. Visitor feet use strict X/Z interior and y in [-0.02,5]; physical cubes use area overlap. On entry, velocity is retained. Zero field acceleration does not stop motion. The carry receiver has no added damping; the loose probes retain linear_damp 0.3 plus project defaults.

ForceCube displays sampled velocity * 0.5, capped at 2.6 m, decomposed in body-local axes. This lesson removes the legacy seeded rest arrow; stationary means zero. Its readout declares the visual scale/cap instead of calling the arrow force. Recovery below four metres from its home height restores the initial transform and freezes; basin floor contact can prevent reaching that threshold.

The map is reversed in Z across all layers to place the machine before the field in museum travel. All eight artifact placements and six identities remain. Original walls, five-row pit and two-cell plank are preserved. Field geometry is an Area and drawing, not a wall; its opt-in placement must not erase the plank from the museum walk graph.


