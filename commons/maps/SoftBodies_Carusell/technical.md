# The support moves — implementation

The primary encounter is `algorithms/softbodies/joyride/revolving_joy_ride.tscn`. Its script creates a frozen RigidBody3D hub in kinematic freeze mode and advances its Y rotation by `ride_speed * delta`. Four chains each contain two dynamic rigid links and two **PinJoint3D** connections. These are point joints with rotational freedom, not single-axis hinges. A soft sphere has selected cap vertices attached to its lower rigid link. Motion is prescribed at the hub; the load does not change its commanded rate.

The installed desk in `commons/artifacts/timing_machines/soft_workshop.gd` exposes SPEED, REVERSE, STOP, STIFFNESS, PRESSURE and RULE. SPEED cycles 0.4, 1.6 and 1.0 rad/s; REVERSE negates the current rate; STOP assigns zero. Neither STOP nor REVERSE reconstructs the ride. STIFFNESS first assigns .5, then .1 and .9. PRESSURE first assigns .5, then 1 and 0. Control values are not a calibrated material measurement.

The nearby cloth_straps is a fixed-support comparison. Other pickup and soft-body artifacts remain part of the collection. The old rear structure and floor coverage remain; consult the current room receipt before claiming walkable approaches.

## Runnable learner reconstruction · 9 October 2026

`doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Carusell/` contains the unchanged sheet and PointBody from Cloth Physics plus a new complete host. It selects two top corners before adding the sheet to the world. A visual hub turns; each physics step transforms the two reference offsets to world space and passes them to PhysicsServer3D.soft_body_move_point. This isolates the driven boundary using the carried sheet, without reproducing the ride's links, decorative ring or four soft spheres.

STOP changes only rate. The same sheet, geometry, coefficients and PointBody persist. Its pinned targets continue to be written at the stopped support position. REBUILD deliberately replaces the sheet and restores phase zero and the base rate. A held PointBody trigger toggles play/hold; desktop1 selects speed,2 reverses,3 stops,R rebuilds. The point parks on release. The small bar has no collider. No moving-surface grabbing, force-feedback motor or material calibration is claimed.

The learner changes RATE .4 to .8 and compares equal elapsed intervals. Only the commanded angular advance must double; free-vertex displacement is not required to double. Exact printed-code, native room checks and limits are recorded in `doc/book/iterations/2026-10-09-carousel-the-support-moves/`.

API: [PhysicsServer3D](https://docs.godotengine.org/en/4.6/classes/class_physicsserver3d.html#class-physicsserver3d-method-soft-body-move-point), [PinJoint3D](https://docs.godotengine.org/en/4.6/classes/class_pinjoint3d.html).
