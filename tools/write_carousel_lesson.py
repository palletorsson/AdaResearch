from pathlib import Path
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/SoftBodies_Carusell'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Carusell'
O=R/'doc/book/iterations/2026-10-09-carousel-the-support-moves'
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```'
t='''# Carusell — the support moves

## Learning elements

- A prescribed rotation: angular rate × elapsed time
- Move selected attachments in world coordinates
- Separate a command from the body's physical response
- Stop a driver without rebuilding the simulation

In Cloth Physics you chose which points must stay. Keep that sheet and the same grabbable black point. This time the two upper corners follow a turning bar. Their attachment remains; its position changes.

## Watch the existing ride

The museum already contains a turning ring, jointed links and soft hanging bodies. Use SPEED, REVERSE and STOP while keeping one body in view. STOP stops the hub's rotation command. It does not remove gravity or restore the hanging bodies to their starting shapes.

The nearby cloth strips provide a fixed-support comparison. The pickup cubes, sticks and other soft objects remain available to explore. Reconstructing the whole collection is not this lesson's task.

## Continue the sheet

Save `study.gd` beside your unchanged `hanging_sheet.gd` and `point_body.gd` from Cloth Physics. Attach it to a unit-scale Node3D in an open part of the prepared museum. The museum supplies the player, camera, floor, XRTools and Jolt. The complete inherited files are included below for checking.

This study isolates the ride's driven-attachment operation using your existing sheet. It leaves out the ride's rigid links and joints. Its bar is visual and has no collider. Two gold markers show the attachment targets.

The familiar rotation rule advances `phase` in radians. Multiplying the rate by `delta` gives an angle for this physics step. `wrapf()` keeps the recorded angle between −π and π; it does not make the motion reverse at that boundary.

For each selected corner, `hub.to_global(offset)` converts a position on the bar into a position in the museum. `soft_body_move_point()` gives that target to the pinned vertex. `get_physics_rid()` identifies this sheet in Godot's physics server. Pinning prevents forces from moving these entries, but the program can still move them. The other entries remain the solver's responsibility.

Only the hub angle and the two attachment targets are prescribed. We never assign the sheet's whole rotation to make it follow the bar. The body can lag, fold or keep moving after the bar stops.

<!-- MAIN -->

`rebuild()` selects the two corners before the fresh sheet enters the world. Its reference mesh and material settings are unchanged. The two attachment targets are updated on every physics step, including while stopped; a stopped support still holds its points.

## Use the same ball

Grip the black point and press it slowly into the sheet. Its collider and pickup behaviour are unchanged. The held trigger now pauses or resumes the turning support. It changes the host's rate; it does not replace the point or the cloth.

Desktop keys: **1** switches between the base rate and twice that rate; **2** reverses the current rate; **3** stops it; **R** rebuilds the sheet and starts again. Reversing zero still gives zero. Use **1**, or the held trigger, to start after stopping. Resuming selects the positive base rate. The installed museum desk keeps its own SPEED, REVERSE and STOP controls; its speed presets differ from this small study.

Stop after a turn. The angle stops changing, but the free vertices can continue moving. Stop again: nothing is rebuilt. Then use REBUILD and notice the different operation—the reference sheet returns and the angle starts again at zero.

## One independent change

Change `RATE` from 0.4 to 0.8 and restart. Predict twice the commanded angle over the same interval: 0.8 instead of 0.4 radians after one second. One full turn takes `TAU / rate` seconds at a constant positive rate. Keep the geometry, pins and response settings unchanged.

Does the free edge travel twice as far? That does not follow from doubling the command. Its movement also depends on its current shape, velocity, gravity and contact. Explain the difference using the two gold attachment markers and one point farther down the surface.

Carry this separation into the next room: a program can drive a changing condition while a simulated body responds. There the changing condition will be pressure, and the surface will enclose the visitor.

<details>
<summary>Inherited sheet — unchanged from Cloth Physics</summary>

<!-- SHEET -->

</details>

<details>
<summary>Inherited grabbable PointBody — unchanged</summary>

<!-- POINT -->

</details>

The installed ride advances `ride_hub.rotation.y` in `_physics_process()` and attaches its soft bodies to moving rigid links through `set_point_pinned()` attachment paths. The learner study exposes the world-space target directly so the existing sheet can carry the new operation. Both arrangements prescribe the support; this is not a simulation of a motor receiving reaction torque.

Sources: `algorithms/softbodies/joyride/revolving_joy_ride.gd`, `commons/artifacts/timing_machines/soft_workshop.gd`. API: [PhysicsServer3D: moving pinned points](https://docs.godotengine.org/en/4.6/classes/class_physicsserver3d.html#class-physicsserver3d-method-soft-body-move-point). The supplied solver handles the free entries; the complete boundary update is printed above.
'''
t=t.replace('<!-- MAIN -->',block('study.gd')).replace('<!-- SHEET -->',block('hanging_sheet.gd')).replace('<!-- POINT -->',block('point_body.gd'))
(M/'tutorial.md').write_bytes(t.encode())
f=(O/'before/commons/maps/SoftBodies_Carusell/final.md').read_text(encoding='utf8')
f=f.replace('The joints are hinges: pins of no length that let each link swing about a point on the one above it.','The links meet at pin joints. They hold two attachment positions together while allowing the links to turn; they do not impose a hinge\'s single axis.')
f=f.replace('The hub is different in kind. It is a body the solver may not push: its angle is written each step, and nothing the hanging bodies do reaches it. So the teardrops report the ride, and the ride never reports them.','The hub is different in kind. Its angle is written each step; the hanging bodies cannot push back on that command. Their response can reach your attention without changing the rate that produced it.')
f=f.replace('The rate is measured in radians per second. A complete turn is `TAU` radians. The driven rotation connects this hall to Transformation and Oscillation, but the hanging bodies add a different problem: their current state matters to what happens next.','You have turned a body before. Here the turn reaches other bodies through an attachment. They meet the next movement with whatever the last one has left in them.')
f=f.replace('The support can stop commanding a new angle while its consequences continue.','The support can stop commanding a new angle while its consequences continue. Stopping the instruction is not the same as ending the event.')
(M/'final.md').write_bytes(f.encode())
technical='''# The support moves — implementation

The primary encounter is `algorithms/softbodies/joyride/revolving_joy_ride.tscn`. Its script creates a frozen RigidBody3D hub in kinematic freeze mode and advances its Y rotation by `ride_speed * delta`. Four chains each contain two dynamic rigid links and two **PinJoint3D** connections. These are point joints with rotational freedom, not single-axis hinges. A soft sphere has selected cap vertices attached to its lower rigid link. Motion is prescribed at the hub; the load does not change its commanded rate.

The installed desk in `commons/artifacts/timing_machines/soft_workshop.gd` exposes SPEED, REVERSE, STOP, STIFFNESS, PRESSURE and RULE. SPEED cycles 0.4, 1.6 and 1.0 rad/s; REVERSE negates the current rate; STOP assigns zero. Neither STOP nor REVERSE reconstructs the ride. STIFFNESS first assigns .5, then .1 and .9. PRESSURE first assigns .5, then 1 and 0. Control values are not a calibrated material measurement.

The nearby cloth_straps is a fixed-support comparison. Other pickup and soft-body artifacts remain part of the collection. The old rear structure and floor coverage remain; consult the current room receipt before claiming walkable approaches.

## Runnable learner reconstruction · 9 October 2026

`doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Carusell/` contains the unchanged sheet and PointBody from Cloth Physics plus a new complete host. It selects two top corners before adding the sheet to the world. A visual hub turns; each physics step transforms the two reference offsets to world space and passes them to PhysicsServer3D.soft_body_move_point. This isolates the driven boundary using the carried sheet, without reproducing the ride's links, decorative ring or four soft spheres.

STOP changes only rate. The same sheet, geometry, coefficients and PointBody persist. Its pinned targets continue to be written at the stopped support position. REBUILD deliberately replaces the sheet and restores phase zero and the base rate. A held PointBody trigger toggles play/hold; desktop1 selects speed,2 reverses,3 stops,R rebuilds. The point parks on release. The small bar has no collider. No moving-surface grabbing, force-feedback motor or material calibration is claimed.

The learner changes RATE .4 to .8 and compares equal elapsed intervals. Only the commanded angular advance must double; free-vertex displacement is not required to double. Exact printed-code, native room checks and limits are recorded in `doc/book/iterations/2026-10-09-carousel-the-support-moves/`.

API: [PhysicsServer3D](https://docs.godotengine.org/en/4.6/classes/class_physicsserver3d.html#class-physicsserver3d-method-soft-body-move-point), [PinJoint3D](https://docs.godotengine.org/en/4.6/classes/class_pinjoint3d.html).
'''
(M/'technical.md').write_bytes(technical.encode())
print('Carusell tutorial and reflection drafted from the installed operation.')
