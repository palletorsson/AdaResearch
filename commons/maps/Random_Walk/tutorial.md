# A point keeps its steps

## Learning elements

- A sampled heading becomes a displacement.
- Position accumulates steps.
- A boundary changes a proposed endpoint.
- A trail records accepted positions without steering the walk.
- Repeating a walk requires its start, rule and generator state.

Find the glass terrarium. Follow the red bead in 2D mode. Its direction keeps changing, yet it stays on one level. The other four beads still move. ONE changes what is easy to follow; it does not remove the rest.

Random Rotate kept adding turns. Now our familiar PointBody adds displacements. Coordinates supplies the local frame, Lines the connecting cylinder, and Trace the list of retained positions. We will build one planar walker. The cabinet's 3D and LONG STEP modes remain comparisons to visit afterwards.

## Give the point a rule

Work in your copy of Endless Museum. Add an empty `Node3D` under Random Walk and attach `07_a_point_keeps_steps.gd`. Place `point_body.gd` and `line_skin.gd` beside it. They are the existing point and Trace renderer, printed below without changes. Day Zero supplies the player, camera, lighting and XR Tools. The new script constructs its own table, boundary and labels. These display meshes add no collision.

The reconstruction was checked at hall-local position `(4, 0, 7)`, with no rotation. Leave room on its positive-Z side for your body to approach. This is a temporary work station in your copy of the museum; the installed terrarium remains beside it.

The point begins at the centre and takes one step every quarter-second. **Pick it up to pause.** Ordinary release projects your chosen starting place onto the tabletop plane, clamps that start inside the square, clears the previous trail and restarts the seeded walk. To repeat the last run from its previous start, **press the trigger while holding the point, then release it**. That combination ignores the new hand position. The label shows which release is pending.

This deliberately changes the role of the hand. In Trace, we recorded where you carried the point. Here holding pauses the generator; release supplies a start. The program then chooses the steps. The point remains the same class.

Read `step()` first. It draws, adds, folds and records.

<!-- student-code:07_a_point_keeps_steps.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const HALF := 0.85
const HEIGHT := 1.26
@export var seed_value := 42
@export_range(0.01, 0.4) var step_size := 0.12
@export_range(0.05, 1.0) var seconds_per_step := 0.25
@export_range(1, 256) var max_steps := 128
var rng := RandomNumberGenerator.new()
var point: XRToolsPickable
var trail := Node3D.new()
var status: Label3D
var origin := Vector3(0, HEIGHT, 0)
var current := Vector3(0, HEIGHT, 0)
var positions: Array[Vector3] = []
var steps := 0
var elapsed := 0.0
var held := false
var replay_requested := false
var proposed := Vector3.ZERO

func _ready() -> void:
    box(Vector3(0, 0.5, 0), Vector3(0.8, 1, 0.8))
    box(Vector3(0, 1.05, 0), Vector3(2.2, 0.1, 2.2))
    var corners: Array[Vector3] = [Vector3(-HALF, HEIGHT, -HALF), Vector3(HALF, HEIGHT, -HALF), Vector3(HALF, HEIGHT, HALF), Vector3(-HALF, HEIGHT, HALF)]
    for i in range(4):
        var edge = join(self, corners[i], corners[(i + 1) % 4])
        edge.material_override.albedo_color = Color(0.3, 0.3, 0.3)
    add_child(trail)
    point = PointBody.new()
    add_child(point)
    point.picked_up.connect(on_pickup)
    point.dropped.connect(on_drop)
    point.action_pressed.connect(on_action)
    box(Vector3(0, 1.95, -0.80), Vector3(1.5, 0.34, 0.05))
    status = label("", Vector3(0, 1.95, -0.75))
    label("HOLD: pause | RELEASE: start here\nTRIGGER + RELEASE: replay", Vector3(0, 0.86, 1.12))
    restart(origin)

func restart(at: Vector3) -> void:
    origin = Vector3(clampf(at.x, -HALF, HALF), HEIGHT, clampf(at.z, -HALF, HALF))
    current = origin
    point.position = current
    rng.seed = seed_value
    steps = 0
    elapsed = 0.0
    proposed = current
    positions.assign([current])
    for line in trail.get_children():
        trail.remove_child(line)
        line.queue_free()
    show_status()

func _process(delta: float) -> void:
    if held or steps >= max_steps:
        return
    elapsed += delta
    while elapsed >= seconds_per_step and steps < max_steps:
        elapsed -= seconds_per_step
        step()
    point.position = current

func _physics_process(_delta: float) -> void:
    if not held:
        point.position = current

func step() -> void:
    if steps >= max_steps:
        return
    var angle := rng.randf() * TAU
    var displacement := Vector3(cos(angle), 0, sin(angle)) * step_size
    proposed = current + displacement
    var accepted := reflect_endpoint(proposed)
    join(trail, current, accepted)
    current = accepted
    point.position = current
    positions.append(current)
    steps += 1
    show_status()

func reflect_endpoint(p: Vector3) -> Vector3:
    if p.x < -HALF: p.x = -2.0 * HALF - p.x
    if p.x > HALF: p.x = 2.0 * HALF - p.x
    if p.z < -HALF: p.z = -2.0 * HALF - p.z
    if p.z > HALF: p.z = 2.0 * HALF - p.z
    return Vector3(p.x, HEIGHT, p.z)

func on_pickup(_body: XRToolsPickable) -> void:
    held = true
    replay_requested = false
    show_status()

func on_action(_body: XRToolsPickable) -> void:
    if held:
        replay_requested = true
        show_status()

func on_drop(_body: XRToolsPickable) -> void:
    var start := origin if replay_requested else to_local(point.global_position)
    held = false
    replay_requested = false
    restart(start)

func show_status() -> void:
    var state := "WALKING" if steps < max_steps else "COMPLETE"
    if held: state = "REPLAY ON RELEASE" if replay_requested else "HELD / PAUSED"
    status.text = "Seed %d | %d / %d | %s\nx %.2f   z %.2f | %d positions" % [seed_value, steps, max_steps, state, current.x, current.z, positions.size()]

func join(parent: Node3D, a: Vector3, b: Vector3) -> MeshInstance3D:
    var line = LineSkin.new()
    parent.add_child(line)
    var displacement := b - a
    line.show_segment(a, displacement, displacement.length())
    return line

func box(at: Vector3, size: Vector3) -> void:
    var body := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    body.mesh = shape
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.88, 0.86, 0.82)
    body.material_override = finish
    body.position = at
    add_child(body)

func label(words: String, at: Vector3) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 28
    text.pixel_size = 0.0025
    text.modulate = Color(0.12, 0.12, 0.12)
    text.outline_size = 0
    add_child(text)
    return text
```

## Follow one step

`rng.randf() * TAU` chooses an angle around the circle. Sine and cosine return from Wavefunctions: together they turn that angle into a unit heading in XZ. Multiplying by `step_size` makes a 12-centimetre displacement. The Y component is zero.

`proposed = current + displacement` starts from the position already reached. Assigning only the displacement would instead keep placing the point near the origin. One random number chooses the new heading; the preceding heading and the drawn trail do not enter that choice.

`reflect_endpoint()` folds any overshoot back into the square. At the right boundary, `x = 0.85`, a proposal of `0.90` becomes `0.80`. Clamping it to `0.85` would be a different rule. The four tests act on X and Z independently, so a proposal can fold at a corner too. This small implementation assumes each step is shorter than the square's width; the supplied step-size range stays within that assumption.

We connect the old position to the accepted endpoint, then store that endpoint. The line does **not** include a wall-contact point. Near an edge, a displayed segment may therefore be shorter than the proposal. The bounds apply to the point's centre; this is a geometric rule, not a rigid-body collision with a glass wall.

## Keep the record separate

`positions` begins with the starting position. Every event appends one accepted position. After 64 steps it contains 65 entries, and the trail contains 64 segments. The point sits at the latest entry. Unlike the cabinet's rolling window of older samples, this small study keeps the whole run, up to 128 steps.

`current` is the state used by the next step. The `positions` list is its account. Neither the list nor the segment nodes are consulted when drawing another heading. Clear those records while retaining `current` and the generator state: the next position remains the same. A self-avoiding walk would need to read its history when choosing where it may go.

The record and all segment endpoints use the lesson root's local coordinates. Turning or moving the whole station carries the drawing with it. Ordinary release converts the point's global hand position back into that local frame before choosing a new start.

## Keep time and replay explicit

The timer comes from Random Rotate. Each complete interval produces an event; `while` lets a slow frame contain several. The finite step budget bounds the work. Holding the point consumes no steps or random draws. Release resets the timer along with the run.

The point still has the frozen physics body introduced for pickup. `_physics_process()` keeps that body at `current` while it is free, including after the run completes. It stops assigning the position while you hold the point, so the hand can carry it. This display update draws no random number and takes no new step.

Here replay rebuilds the path from the same **origin, seed, step size, boundary rule and draw order**. It does not play an already stored path, as the previous lesson played its saved angles. The seed alone is insufficient: starting near an edge changes where the same proposals are folded. This comparison uses the same Godot version; a seed is not a promise of identical results across engine versions.

The installed cabinet also uses a step timer, but accepts at most five batches per drawing frame and discards excess time. Its RESET retains a partial timer. Compare its replays by step count, not by assuming the same wall-clock history. The learner study keeps a simpler finite run and clears its timer on restart.

## The constructions you already have

Keep these two files unchanged. PointBody supplies the sphere, collision shape and inherited pickup signals. LineSkin turns two endpoints into a visible cylinder; it does not make a wall or a physical string.

<details>
<summary>Complete PointBody and LineSkin dependencies</summary>

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

</details>

## Make a change you can explain

1. Change `step_size` from `0.12` to `0.24`, leaving the seed and start at the centre. Before either path reaches an edge, its displacement from the start doubles. After a reflection the paths need not be scaled copies. Predict the first two endpoints, then compare the runs.
2. Change `seconds_per_step` from `0.25` to `0.5`. At an equal step count the path is unchanged; reaching that count takes longer. Separate changing the rule from changing its pace.
3. In `step()`, replace the call to `reflect_endpoint(proposed)` with `Vector3(clampf(proposed.x, -HALF, HALF), HEIGHT, clampf(proposed.z, -HALF, HALF))`. A proposal at x = 0.90 now ends at 0.85. The draws have not changed; their treatment at the boundary has. Restore reflection afterwards.

For an independent check, put the start near one corner. Choose a proposed displacement that exceeds both edges. Work out the folded endpoint before running the program, and explain why the visible connecting segment does not show a bounce. The code checks exercise that corner case, source edits, replay, held time and the distinction between a record and a steering rule.

## Return to the hall

The terrarium's five walkers share a generator. One planar step consumes one draw per walker. Its 3D direction consumes two, and LONG STEP adds another to choose a bounded length. Switching modes therefore changes both the geometry and how the stream is consumed. Its trail keeps previous positions and omits the bead's current one; our list includes the current endpoint. Both conventions are explicit choices about what a trail retains.

Visit the two rails next: a new position and an accumulated displacement are given the same input. Then try the held drawing dot, where the hand carries an origin and chance moves a tip around it. Across the basin, revisited cells raise the ground. These artifacts extend the question without adding three more required programs to this lesson.

Next is Random Gaussian. Keep the sampled values long enough to ask how they are distributed. A tangle shows an order of visits; a histogram will group values and leave that order out.
