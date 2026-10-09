# Support before a step

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
