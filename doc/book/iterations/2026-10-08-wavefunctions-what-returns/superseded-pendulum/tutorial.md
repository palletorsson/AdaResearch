# The same place, another direction

**Learning elements**

- Angle and angular velocity
- Restoring acceleration
- Constrained hand release
- Repeated crossings

Find the pendulum and its still reference ring. Pull the bob aside and release it. Watch two crossings of the ring. The place returns; the direction changes. This is our first question: what must the point keep for its next movement to make sense?

## What you bring

Keep the PointBody class from Lines and Coordinates, the recent-position record from Trace, and the velocity updates from Forces. Transformation already used a sine of time to prescribe movement. Here the angle changes because a restoring acceleration changes the angular velocity.

**Build:** turn the familiar pickable point into a pendulum bob. Keep its angle and angular velocity; let a hand supply a release.

**Investigate:** start at the same angle with different velocities. Predict the next direction before running either version.

## Work inside the museum

Use the existing `PointStudy` Node3D, under the current hall, upright at unit scale. The checked working position is hall-local `(6.3, 0, 16.5)` metres. The museum supplies floor, light, camera, desktop carry and XR hands. Day Zero already installed Godot XR Tools; this script is not an empty-project example.

Save the complete script below as `01_return.gd` and attach it to `PointStudy`. The preload points to the existing `point_body.gd`; its complete source is repeated at the end for reference. If you saved your class elsewhere, change this one declared path. No named scene children are required. The script creates its sphere, rod, ring and readout.

The class and your saved work continue from Forces. Each run makes a new instance; the museum does not automatically transport one physical sphere between halls. This bob uses the original frozen PointBody rather than the freely simulated `free_point.gd`. Its angular rule determines its position. Jolt must not also integrate it as an unconstrained body.

## Complete code — 01_return.gd

<!-- student-code:01_return.gd -->

```gdscript
extends Node3D

const PointBody = preload("res://doc/book/studies/forces-point-lineage/point_body.gd")
const PIVOT := Vector3(0, 1.9, 0)
const LENGTH := 0.75
const GRAVITY := 9.8

var angle := 0.45
var speed := 0.0
var damping := 0.995
var held := false
var crossings := 0
var velocities: Array[Vector3] = []
var last_position := Vector3.ZERO
var bob: XRToolsPickable
var rod: MeshInstance3D
var label: Label3D

func _ready() -> void:
    bob = PointBody.new()
    add_child(bob)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color("17191c")
    black.roughness = 0.16
    bob.get_child(0).material_override = black
    bob.picked_up.connect(begin_hold)
    bob.dropped.connect(end_hold)
    bob.set_meta("desktop_hook_target", self)

    rod = MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.008
    cylinder.bottom_radius = 0.008
    cylinder.height = LENGTH
    rod.mesh = cylinder
    add_child(rod)

    var ring := MeshInstance3D.new()
    var circle := TorusMesh.new()
    circle.inner_radius = 0.17
    circle.outer_radius = 0.19
    ring.mesh = circle
    ring.position = PIVOT + Vector3(0, -LENGTH, 0)
    add_child(ring)

    label = Label3D.new()
    label.font_size = 36
    label.pixel_size = 0.0025
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.position = PIVOT + Vector3(0, 0.32, 0)
    add_child(label)
    draw_state()

func _physics_process(delta: float) -> void:
    if held:
        var offset := to_local(bob.global_position) - PIVOT
        angle = clampf(atan2(offset.x, -offset.y), -PI*0.45, PI*0.45)
        velocities.append((bob.global_position - last_position) / delta)
        if velocities.size() > 5:
            velocities.pop_front()
        last_position = bob.global_position
        speed = 0.0
    else:
        advance(delta)
    draw_state()

func advance(delta: float) -> void:
    var previous := angle
    var acceleration := -(GRAVITY / LENGTH) * sin(angle)
    speed += acceleration * delta
    speed *= damping
    angle = clampf(angle + speed * delta, -PI*0.45, PI*0.45)
    if previous * angle < 0.0:
        crossings += 1

func begin_hold(_body: Node3D) -> void:
    held = true
    velocities.clear()
    last_position = bob.global_position

func end_hold(_body: Node3D) -> void:
    held = false
    var velocity := Vector3.ZERO
    for sample in velocities:
        velocity += sample
    if not velocities.is_empty():
        velocity /= velocities.size()
    velocity = global_basis.inverse() * velocity
    var tangent := Vector3(cos(angle), sin(angle), 0)
    speed = clampf(velocity.dot(tangent) / LENGTH, -10.0, 10.0)
    velocities.clear()

func on_desktop_grab(_pointer: Node) -> void:
    if not held:
        begin_hold(bob)

func on_desktop_drop(_pointer: Node) -> void:
    if held:
        end_hold(bob)

func draw_state() -> void:
    var offset := Vector3(sin(angle), -cos(angle), 0) * LENGTH
    if not held:
        bob.global_position = to_global(PIVOT + offset)
    rod.position = PIVOT + offset * 0.5
    rod.rotation.z = angle
    label.text = "angle %+.2f rad   speed %+.2f rad/s\ncrossings %d" % [angle, speed, crossings]
```


## Follow one update

`angle` is measured in radians from the downward vertical. `speed` is signed angular velocity in radians per second. Positive angles place the bob to the right of the pivot. `LENGTH` is the 0.75-metre distance from pivot to centre; it is not the diameter of the sphere.

The new operation is in `advance`. At a positive angle, the minus sign makes the acceleration negative: the bob begins moving back. Acceleration changes `speed`, then speed changes `angle`. At a turning point speed can be zero while acceleration is not. At the centre acceleration is zero while speed need not be. The two numbers answer different questions.

This order is the same velocity-then-position update used in Forces, now expressed as angle and angular velocity. The rod does not exert a simulated joint force. `draw_state` places the bob on the declared circle. The model keeps one swinging plane and limits the angle to ±0.45π; it does not model a complete revolution or impacts with surrounding objects.

`previous * angle < 0` detects a change of side between two samples. It is a small sampled crossing counter. Landing exactly on zero can miss a crossing; this is not an exact event-time solver. It is enough to observe alternating directions in the supplied release. A counter is another record with a rule about what qualifies.

## Give the movement a beginning

Pull the sphere in VR, or carry it with the museum’s desktop pointer. While held, its world position is converted into the study’s frame. `atan2` reads its angle around the pivot. The body follows the hand freely during the hold; when released it returns to the circle. Keep your hand near that circle to avoid a large snap.

The short list stores the latest five hand-velocity samples. Releasing averages them, converts the result from world space to the study’s axes, and uses a dot product to keep the component along the tangent. Dividing metres per second by the pendulum length gives radians per second. Motion straight through the swinging plane contributes nothing to that component. The ±10 rad/s clamp bounds the accepted release.

First hold still for several physics ticks, then release. The remembered hand velocity should be zero. Next give a gentle push as you release. The initial place can be similar while the next movement differs. Pickup clears the hand samples, but retains the crossing count. Each has its own reason to reset.

## Predict, then build another case

Start once with `angle = 0.0` and `speed = 0.8`, and again with `speed = -0.8`. Predict which side each reaches first. Compare the signs on the readout. Next start at `angle = 0.3`, `speed = 0.0`: why does this still body start moving?

Make a second `PointStudy` beside the first, using the same script. Give the two instances the same starting angle and opposite speeds. Each must own its angle, velocity samples and counter. Change the second instance’s starting values without changing the first. Show that they can share a class while retaining different states. If you prefer two small script copies for this first comparison, keep both and name the changed starting values.

## Model notes

The existing hall’s free pendulum multiplies angular velocity by `0.995` on every physics tick. This reconstruction retains that rule. At 60 ticks/s, one second applies the multiplier 60 times; at 90, it applies it 90 times. These are physics rates, not automatically screen or headset refresh rates. Comparisons should use the same physics setting. A later change to time-based damping would be a change to the model.

The hall has a smaller bob, a 0.6-metre rod, a prediction curve, signals to other artifacts and additional damping regimes. The study uses a 0.75-metre rod for the inherited sphere and isolates the free swing. Do not expect the periods to match. Its drawing and collider are visible support for the angular model; contact does not supply its restoring acceleration.

The predicted curve behind the installed bob begins from a standard release. It does not record your hand. The neighbouring clock-driven cubes also have a different source: their rule reads time. The controlled cube listens to the installed pendulum, not to this new study. Try both before deciding that similar movement means the same operation.

## What travels onward

Keep `01_return.gd`, including the two-number state and the hand’s release. In Pendulum, the next hall, we will add a timestamped record to this movement. A crossing count tells us how often one boundary was crossed. A trace can keep what happened between crossings.

## Carried code — PointBody

This is the unchanged class already used in Forces, at `res://doc/book/studies/forces-point-lineage/point_body.gd`. Read it here when needed; the new lesson does not ask you to rebuild the sphere constructor.

<!-- student-code:point_body.gd -->

```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```
