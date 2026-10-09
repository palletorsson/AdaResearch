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

The canonical [chapter](final.md) follows approach, overshoot, reversal and the observation boundary. The opening trail comparison concerns overlaid return travel: pink's extent beyond the centre can show that it crossed, while a static line does not by itself show timing, repeated visits or current direction. The exact integration, history, arrow sampling, gain cycle and exit conventions remain above. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-field-and-receiver/before/commons/maps/Vectors_Act3_FieldsAndMotion/final.md) is retained for comparison. This reading pass adds no runtime or headset result.
