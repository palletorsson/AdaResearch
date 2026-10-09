# Propagation — a neighbour responds

## Learning elements

- Neighbour coupling through displacement differences.
- One old state and a separate next state.
- Propagation through coupling, distinguished from phase-delayed animation.
- Boundary points with fewer neighbours.

In the museum, find the lattice of small spheres. Press SINE to select PULSE. The centre receives one push after half a second. Follow a nearby sphere. Now press COUPLED to select INDEPENDENT: the trial restarts, but that neighbour stays still. Restore COUPLED and watch again. The source repeats the same action; the links change what can receive it.

In Unit Circle, we prescribed the point's position from an angle. Here we carry its PointBody shape into a row of nine points. Each keeps a displacement and a velocity, as in Forces. Arrays hold their states. The new operation lets a difference between neighbouring displacements contribute force.

## Build beside the existing lattice

Use the Endless Museum and installed XR Tools from Day Zero. Save the three files below together. Attach `05_neighbour_motion.gd` to an empty Node3D in this hall's entrance bay: hall-local `(12, 0, 11)`, Y rotation `180°`, scale `1`. The museum supplies the player, camera, light and floor. The script creates all the points, rods and readout. It does not control the existing exhibit.

These points move only vertically. Their resting centres are 1.4 metres above the floor, spaced half a metre apart. Displacement is an offset in metres; velocity is metres per second. `restoring` and `coupling` are spring coefficients in newtons per metre; `damping` is newton-seconds per metre; `mass` is kilograms.

The point's pickup and collision are disabled for this study. Our arrays now govern its motion. Jolt must not add another integration of gravity or contact to that same movement. We keep the familiar sphere, while stating what its role has changed to.

## The complete study

<!-- student-code:05_neighbour_motion.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export var count := 9
@export var spacing := 0.5
@export var mass := 1.0
@export var restoring := 4.0
@export var coupling := 12.0
@export var damping := 0.3
@export var running := true
var displacement: Array[float] = []
var velocity: Array[float] = []
var points: Array[RigidBody3D] = []
var links: Array[MeshInstance3D] = []
var label: Label3D
var elapsed := 0.0

func _ready() -> void:
    assert(count >= 3 and mass > 0.0)
    for i in range(count):
        var point := PointBody.new()
        point.enabled = false
        point.collision_layer = 0
        point.collision_mask = 0
        add_child(point)
        var ink := StandardMaterial3D.new()
        ink.albedo_color = Color(0.95, 0.45, 0.65) if i == count / 2 else Color(0.04, 0.04, 0.05)
        ink.roughness = 0.25
        point.get_child(0).material_override = ink
        points.append(point)
        if i > 0:
            var link := LineSkin.new()
            add_child(link)
            links.append(link)
    label = Label3D.new()
    label.position = Vector3(0, 2.5, 0)
    label.font_size = 30
    label.pixel_size = 0.004
    add_child(label)
    reset()

func reset() -> void:
    displacement.resize(count)
    velocity.resize(count)
    displacement.fill(0.0)
    velocity.fill(0.0)
    displacement[count / 2] = 0.6
    elapsed = 0.0
    draw_state()

func _physics_process(delta: float) -> void:
    if running:
        step(delta)
    draw_state()

func step(delta: float) -> void:
    var next_displacement := displacement.duplicate()
    var next_velocity := velocity.duplicate()
    for i in range(count):
        var force := -restoring * displacement[i] - damping * velocity[i]
        for j in [i - 1, i + 1]:
            if j >= 0 and j < count:
                force += coupling * (displacement[j] - displacement[i])
        next_velocity[i] = velocity[i] + force / mass * delta
        next_displacement[i] = displacement[i] + next_velocity[i] * delta
    displacement = next_displacement
    velocity = next_velocity
    elapsed += delta

func draw_state() -> void:
    for i in range(count):
        points[i].position = Vector3((i - (count - 1) * 0.5) * spacing, 1.4 + displacement[i], 0)
    for i in range(links.size()):
        var a := points[i].position
        var difference := points[i + 1].position - a
        links[i].show_segment(a, difference, difference.length())
        links[i].visible = coupling > 0.0
    label.text = "t %.2f s | coupling %.1f N/m\ncentre %+.3f m | next %+.3f m" % [elapsed, coupling, displacement[count / 2], displacement[count / 2 + 1]]
```


`reset()` raises only the middle point by 0.6 metres and leaves every velocity at zero. This is our release condition. The museum exhibit instead applies a velocity pulse; both comparisons begin with a local disturbance, but they do not begin with the same state.

Read the force calculation as three contributions. Restoring force draws a point towards its resting height. Damping opposes its velocity. Each neighbour contributes `coupling * (displacement[j] - displacement[i])`. If the neighbour is higher, that contribution pulls upward. If their offsets agree, it contributes zero. This is a simplified vertical spring relation, not a full 3D elastic rod.

The indices `i - 1` and `i + 1` name the neighbours. The bounds check gives the end points one neighbour each. It does not connect the ends into a loop or hold them fixed. Each end still has its own restoring force and damping.

## Everyone reads the same moment

The two `duplicate()` calls create separate next-state arrays. Every force reads the old `displacement` and `velocity`. Only after all points have been calculated do we replace those arrays. Updating `displacement[i]` inside the loop would let later points read some already-updated neighbours. The array's traversal order would then become part of the model.

Within each point's next state, force divided by mass changes velocity; the **new** velocity changes displacement. This is the velocity-first Euler step used in the museum lattice. `_physics_process()` supplies the physics timestep. The given coefficients work at the project's normal 60 physics ticks per second; arbitrary large timesteps or spring strengths can make this numerical method unstable.

`draw_state()` gives the stored values bodies. The rods show the declared connections and disappear when coupling is zero. They do not exert force or collide. The force comes from `step()`, even with the drawing hidden.

## Predict, then compare

Before running, predict the first update. The raised centre begins to fall. Its two immediate neighbours begin to rise equally. The points beyond those neighbours do not move on this first step: their old neighbours were still at rest. Later steps carry the disturbance farther.

Run with `coupling = 0.0`, then restart with `12.0`. All other values and the initial raised point stay the same. Without coupling, only the centre moves. With it, neighbouring points respond. A crest passes through the row while each sphere keeps its horizontal address.

Now make an independent version with `count = 7`. Predict which index starts raised and which points should match across the centre. Change the initial displacement from `0.6` to `0.3` and rerun. At matching simulated times the offsets should be half as large: the rule is linear. The row remains symmetric, with one neighbour at each end. Explain those results before adding more points.

## Carried files

PointBody and LineSkin are unchanged from Unit Circle. Keep matching copies if you already have them. They supply the visible sphere and thin cylinder; the new work is the relation between stored states.

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


<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


Return to the museum lattice. It extends the relation over a two-dimensional array, including diagonal neighbours; our row has only left and right neighbours. The nearby tiled field uses a different mechanism: it calculates each tile's height from distance and time. A similar-looking wave does not establish the same connection between its parts. In Effect Sound, we will meet another relationship: one oscillation changes another's phase.
