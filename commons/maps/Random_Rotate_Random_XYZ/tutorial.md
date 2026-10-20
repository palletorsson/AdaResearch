# Keep the turn

## Learning elements

- Assigning an angle and accumulating a turn.
- Signed increments: a later turn can undo an earlier one.
- One recorded input, two interpretations.
- A timed step, independent of the drawing frame.
- Replaying a record without drawing again.

Find the two upright stacks. Wait after RESET. Their pieces keep their places while small turns build on previous turns. The shapes have not become different meshes. Their orientations carry a history.

In Random Cubes, each result added to a total. Here the cube returns, but the contribution is a signed angle. Transformation taught us to turn a whole body. We will give two identical cubes the same list of angles: one takes the latest value, and the other keeps the sum. The PointBody you already made operates the comparison.

## Build the comparison in the hall

Work in your copy of the prepared Endless Museum. Add an empty `Node3D` under Random Rotate and attach `06_turns_kept.gd`. Keep the unchanged `point_body.gd` beside it. Day Zero supplies the player, camera, light and XR Tools. The script creates both cubes, their marks, plinths and labels; these display meshes have no collision. A tested temporary position is hall-local `(3, 0, 7.5)`, Y rotation **90 degrees**, facing into the room.

Hold the point above **STEP** and press the trigger. Both cubes receive the next recorded angle. Over **PLAY / PAUSE**, the same action starts or pauses timed stepping. **REPLAY** returns both cubes to zero and the cursor to the start; STEP then reads the same turns again. At the end, PLAY starts that record again. These controls read the point's position relative to the lesson root.

Read `step()` first. The remaining functions make that short operation visible and repeatable.

<!-- student-code:06_turns_kept.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const TURN_AXIS := Vector3.BACK
@export var seed_value := 42
@export_range(1, 60) var step_count := 24
@export_range(1.0, 45.0) var limit_degrees := 20.0
@export_range(0.1, 5.0) var seconds_per_step := 0.8
var rng := RandomNumberGenerator.new()
var turns: Array[float] = []
var cursor := 0
var latest := 0.0
var total := 0.0
var elapsed := 0.0
var playing := false
var assigned: MeshInstance3D
var accumulated: MeshInstance3D
var status: Label3D
var point: XRToolsPickable

func _ready() -> void:
    for x in [-0.7, 0.7]:
        box(self, Vector3(x, 0.55, 0), Vector3(0.7, 1.1, 0.7), Color(0.88, 0.86, 0.82))
    assigned = cube(-0.7)
    accumulated = cube(0.7)
    label("LATEST ANGLE", Vector3(-0.7, 0.99, 0.4))
    label("SUM OF TURNS", Vector3(0.7, 0.99, 0.4))
    status = label("", Vector3(0, 2.3, 0))
    box(self, Vector3(0, 0.78, 0.8), Vector3(2.4, 0.05, 0.55), Color(0.88, 0.86, 0.82))
    label("REPLAY          STEP          PLAY / PAUSE", Vector3(0, 0.7, 1.1))
    point = PointBody.new()
    point.position = Vector3(0, 0.96, 0.8)
    add_child(point)
    point.action_pressed.connect(point_action)
    make_record()

func make_record() -> void:
    rng.seed = seed_value
    turns.clear()
    for i in range(step_count):
        turns.append(deg_to_rad(rng.randf_range(-limit_degrees, limit_degrees)))
    replay()

func replay() -> void:
    cursor = 0
    latest = 0.0
    total = 0.0
    elapsed = 0.0
    playing = false
    show_angles()

func step() -> void:
    if cursor >= turns.size():
        return
    latest = turns[cursor]
    total += latest
    cursor += 1
    if cursor == turns.size():
        playing = false
    show_angles()

func _process(delta: float) -> void:
    if not playing:
        return
    elapsed += delta
    while elapsed >= seconds_per_step and cursor < turns.size():
        elapsed -= seconds_per_step
        step()

func point_action(_body: XRToolsPickable) -> void:
    if point.position.x < -0.4:
        replay()
    elif point.position.x > 0.4:
        if cursor == turns.size():
            replay()
        playing = not playing
    else:
        playing = false
        elapsed = 0.0
        step()
    show_angles()

func show_angles() -> void:
    assigned.basis = Basis(TURN_AXIS, latest)
    accumulated.basis = Basis(TURN_AXIS, total)
    var state := "PLAYING" if playing else "PAUSED"
    if cursor == turns.size():
        state = "RECORD COMPLETE"
    status.text = "Seed %d | %d / %d | %s\nLatest %.1f deg | Sum %.1f deg" % [seed_value, cursor, turns.size(), state, rad_to_deg(latest), rad_to_deg(total)]

func cube(x: float) -> MeshInstance3D:
    var body := box(self, Vector3(x, 1.53, 0), Vector3.ONE * 0.6, Color(0.18, 0.18, 0.18))
    # An off-centre mark makes the cube's orientation distinguishable.
    box(body, Vector3(0.14, 0.23, 0.307), Vector3(0.22, 0.065, 0.025), Color(1.0, 0.35, 0.58))
    return body

func box(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    body.material_override = material
    body.position = at
    parent.add_child(body)
    return body

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

## One value, two operations

`make_record()` prepares a finite list of 24 angles. Each draw lies between −20 and +20 degrees; `deg_to_rad()` converts it to the radians the rotation uses. The list is already complete before either cube turns. The seed identifies this generator procedure; it is not a promise of the same numbers in every future engine version.

`cursor` is the next unread address. In `step()`, `latest = turns[cursor]` replaces one value. `total += latest` retains the preceding total and adds the new value. Both operations use the **same** entry; a second draw would make the comparison harder to interpret.

Suppose the list begins **+10°, +10°, −5°**. The left cube takes orientations **10°, 10°, −5°**. The right reaches **10°, 20°, 15°**. A bounded increment does not impose the same bound on the sum. Negative increments can cancel positive ones, so accumulated turning need not move steadily farther from zero.

`Basis(TURN_AXIS, angle)` gives the whole cube an orientation around one unit axis. `Vector3.BACK` is local positive Z: the cube turns in the plane facing you. Its position and mesh stay unchanged. The off-centre pink mark lets you distinguish orientations that an unmarked cube's symmetry could conceal. [Godot: Basis](https://docs.godotengine.org/en/stable/classes/class_basis.html)

The sum is retained separately from the rendered orientation. After a full turn the cube can look unchanged while the stored total has increased by 360°. The displayed body alone cannot recover all the turns that led to it.

## Time reads the record

`_process(delta)` receives elapsed seconds. It accumulates that time, then uses `while` to consume every complete 0.8-second interval. A slow drawing frame may contain several lesson steps. A faster monitor does not create extra random draws: playback only reads the saved list.

Pause keeps a partly completed interval. REPLAY clears it. Manual STEP also clears it and pauses playback, so your press is the next event rather than an extra step immediately before a timed one. The last entry stops playback. The guard at the start of `step()` prevents reading past the list.

REPLAY never calls the generator. `make_record()` does: it resets the seed, replaces the list, then resets playback. This distinction matters in the installed stack, whose RESET aligns the pieces but does **not** rewind its generator.

## The point is still your point

This is the existing PointBody dependency. Keep your copy; it is printed here so the complete example can be reconstructed without a prepared mesh child. Its inherited pickup behaviour stays the same. What its action does belongs to this lesson.

<details>
<summary>Complete inherited PointBody — keep this file beside the lesson</summary>

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

</details>

## Change one thing and predict it

1. Step once. Predict why the orientations agree. Step again and explain why they can separate even though their inputs remain identical.
2. Change `limit_degrees` from `20.0` to `40.0`, leaving the seed and entry count alone. In this generator implementation the signed entries double. At the same cursor, both numeric angles double; the visible pose can wrap around a full turn. Compare the labels as well as the cubes.
3. Change `TURN_AXIS` from `Vector3.BACK` to `Vector3.RIGHT`. Keep the original angle record. The same values now pitch the cubes around local X. What changed is the axis of interpretation, not the random numbers. This does not sample all spatial orientations: that is a different problem.
4. Before running it, predict a record containing **+10°, +10°, −5°**. For a controlled exercise, replace the drawing loop in `make_record()` with `turns.assign([deg_to_rad(10.0), deg_to_rad(10.0), deg_to_rad(-5.0)])`. Keep its final `replay()` call. Explain both labels after the third step, then replay and check again.

The code checks reconstruct the printed files, compare the amplitude and axis edits, test this supplied record, and deliberately break accumulation, replay and timing. Passing those checks establishes what the program does. Your own explanation of a new record is the further test of understanding.

## Return to the larger stack

Our two cubes isolate addition. The installed display also keeps angular velocity and an authored wear value; random kicks alter that state before it updates the angle. It currently updates per rendered frame, so a seed alone does not make its timing or trajectory match across frame rates. The learner comparison deliberately uses fixed record-reading intervals. It is a reconstruction of the central relation, not a replacement implementation of the full exhibit.

The nearby weathering rig reacts to movement without drawing random numbers. Neither that input nor mixing values from a software clock establishes a hardware random source. Keep the source of a change separate from how the change looks.

Carry the distinction into Random Walk. The cube has kept a sum of turns; the point will keep a sum of displacements. Trace's list returns so you can see where those steps have taken it.
