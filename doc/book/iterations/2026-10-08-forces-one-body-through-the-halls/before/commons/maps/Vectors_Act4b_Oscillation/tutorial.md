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
