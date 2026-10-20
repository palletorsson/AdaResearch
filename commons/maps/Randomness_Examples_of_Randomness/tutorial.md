# A draw estimates

**Learning elements**

- Uniform samples in a square
- Circle membership and hit counts
- A running Monte Carlo estimate
- Finite-sample fluctuation and sampling bias

Space Geometry asked how neighbouring values relate. Here **draws supply evidence for an estimate**. Keep the point, arrays and counters. Draw two coordinates, record their position, and count whether it falls inside a circle. The sampling rule must suit the area we claim to measure.

First visit the Monte Carlo board already in this gallery. Press REPLAY, then THROW. A mark inside the circle increases both the inside count and the total; an outside mark increases only the total. Predict how the estimate will change before requesting another point. THROW requests a generated position; you are not aiming a physical dart. The BUDGET dial chooses 100, 500, 2000 or 8000 samples and restarts the same seed; FILL reaches that count. +100 extends the current run. NEXT SEED starts another run; 8 SEEDS compares eight runs without changing the displayed one.

## Reconstruct the counting rule

In your local copy of the prepared Endless Museum, add a Node3D at hall-local **(10.5, 0, 13), Y rotation 180 degrees**, with unit scale. Save the two files below together and attach `11_a_draw_estimates.gd` to it. The museum supplies the player, camera, floor, lighting and installed XR Tools. This temporary learner board creates its own geometry and labels beside the existing works. Its front is local positive Z; the geometry is visual only, and the museum floor supports you.

Reuse PointBody from the earlier lessons. Hold it over a labelled third of the board and press its trigger: REPLAY clears the record and rewinds the seed; ONE adds a sample; BATCH adds sixteen. Moving or releasing the point changes no samples. These are the familiar local-X zones, not touch buttons or snapping. The installed board uses rectangular buttons and a budget dial; our reconstruction keeps the counting lesson small.

Read `add_samples()` first. Each position lies in a square from −1 to 1 on both axes. The circle has radius 1 and area π; the square has area 4. With uniform sampling over this square, the proportion inside estimates π/4. Multiplying by four estimates π. The squared-distance test avoids a square root; it makes the same inside/outside decision.

The left panel retains every sample: teal inside, pink outside. Its circle outline uses 64 short cylinders; the equation decides membership, not collisions with that drawn edge. On the right, each black dot records the estimate after that sample. Horizontal position is sample number, vertical position is the estimate from 0 to 4. The gold line marks π for comparison; it never enters the counting calculation. Before any sample, the label shows `--` because there is no ratio yet.

## The complete study

<!-- student-code:11_a_draw_estimates.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LIMIT := 256
const BATCH := 16

var sample_seed := 42
var x_span := 1.0
var samples: Array[Vector2] = []
var estimates: Array[float] = []
var inside := 0
var marks: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    box(Vector3(2.8, 0.65, 0.8), Vector3(0, 0.325, 0.0), Color(0.25, 0.25, 0.25))
    box(Vector3(2.8, 2.1, 0.05), Vector3(0, 1.6, 0), Color(0.88, 0.86, 0.81))
    box(Vector3(1.2, 1.2, 0.01), Vector3(-0.65, 1.7, 0.03), Color(0.98, 0.97, 0.93))
    for i in range(64):
        var a := TAU * i / 64.0
        var b := TAU * (i + 1) / 64.0
        line(Vector3(-0.65 + cos(a) * 0.6, 1.7 + sin(a) * 0.6, 0.045),
            Vector3(-0.65 + cos(b) * 0.6, 1.7 + sin(b) * 0.6, 0.045), Color.BLACK)
    line(Vector3(0.15, 1.1, 0.045), Vector3(1.25, 1.1, 0.045), Color.BLACK)
    line(Vector3(0.15, 1.1, 0.045), Vector3(0.15, 2.1, 0.045), Color.BLACK)
    line(Vector3(0.15, 1.1 + PI * 0.25, 0.045), Vector3(1.25, 1.1 + PI * 0.25, 0.045), Color(0.65, 0.38, 0.05))
    label("ESTIMATE 0..4\nstep 1..%d | gold: pi" % LIMIT, Vector3(0.7, 2.3, 0.05), 22)
    status = label("", Vector3(0, 2.52, 0.05), 25)
    label("REPLAY           ONE           BATCH", Vector3(0, 0.83, 0.43), 24)
    point = PointBody.new()
    point.position = Vector3(0, 1.04, 0.55)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    rng.seed = sample_seed
    samples.clear()
    estimates.clear()
    inside = 0
    for mark in marks:
        mark.free()
    marks.clear()
    update_status()

func add_samples(amount: int) -> void:
    for _i in range(mini(amount, LIMIT - samples.size())):
        var p := Vector2(rng.randf_range(-x_span, x_span), rng.randf_range(-1.0, 1.0))
        samples.append(p)
        var hit := p.length_squared() <= 1.0
        if hit:
            inside += 1
        var estimate := 4.0 * inside / samples.size()
        estimates.append(estimate)
        var colour := Color(0.04, 0.42, 0.37) if hit else Color(0.8, 0.12, 0.23)
        marks.append(dot(Vector3(-0.65 + p.x * 0.6, 1.7 + p.y * 0.6, 0.06), colour))
        var x := 0.15 + (samples.size() - 1) * 1.1 / (LIMIT - 1)
        marks.append(dot(Vector3(x, 1.1 + estimate * 0.25, 0.06), Color(0.08, 0.08, 0.08)))
    update_status()

func update_status() -> void:
    var value := "--" if estimates.is_empty() else "%.4f" % estimates[-1]
    status.text = "seed %d | %d / %d inside | estimate %s" % [sample_seed, inside, samples.size(), value]

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.4:
        replay()
    elif x < 0.4:
        add_samples(1)
    else:
        add_samples(BATCH)

func material(colour: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = colour
    result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return result

func dot(at: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.009
    mesh.height = 0.018
    mesh.radial_segments = 8
    mesh.rings = 4
    view.mesh = mesh
    view.position = at
    view.material_override = material(colour)
    add_child(view)
    return view

func line(a: Vector3, b: Vector3, colour: Color) -> void:
    var view := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.003
    mesh.bottom_radius = 0.003
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 6
    view.mesh = mesh
    view.position = (a + b) / 2.0
    view.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
    view.material_override = material(colour)
    add_child(view)

func box(size: Vector3, at: Vector3, colour: Color) -> void:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    view.material_override = material(colour)
    add_child(view)

func label(text: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = text
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02)
    view.outline_size = 0
    add_child(view)
    return view
```

## The carried point

Keep your existing `point_body.gd` beside the study. This is the unchanged class, included so the printed lesson has no missing code dependency beyond the declared XR Tools installation. The small sample marks are visual spheres; they do not each need pickup behaviour.

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

## Follow the record

`samples` keeps the positions. `inside` counts those accepted by the circle test. `estimates` keeps one ratio per position, so the graph retains how the answer changed. The expression starts with `4.0` to produce a floating-point ratio. Display helpers build familiar spheres, cylinders, boxes and labels; none of them draws a random value.

Add sixteen points individually. REPLAY, then request one BATCH. The positions, counts and estimate history should match exactly in this engine version. The loop groups requests; it does not choose a different sampling procedure. A new seed can produce a different run, but resetting only the counters would not replay the old one.

There is room for 256 samples. At that limit another request does nothing and spends no random draws. All 256 samples remain visible. The installed artwork has a selectable budget up to 8000 and shows only its latest 300 marks; its counts include the whole run. Both versions rewind their local generator on REPLAY. The same seed with the same sampling procedure lets you compare the same finite sample; a seed alone does not specify the whole experiment.

## Test a change you can explain

1. Change `BATCH` from 16 to 32. After replay, eight batches should reproduce the same 256 positions as sixteen batches did before. Predict the whole record, not only a number close to π.
2. Change `sample_seed` from 42 to 43. Fill the board again. A different estimate is not a failed program. Watch the history: a later point can move the estimate farther from π. A larger independent uniform sample reduces sampling uncertainty in general; it does not guarantee a better answer at every step.
3. Restore seed 42 and change `x_span` from 1.0 to 0.2. Leave the circle test and factor four alone. The points now occupy only a central strip. The program still runs, but `4 × inside / total` no longer estimates π under the original square-area argument. The source of the error is visible before you inspect the final number. More draws from the same strip do not restore the missing coverage. Restore 1.0 afterward.

For a calculation you can check by hand, imagine the first four records are `(0,0)`, `(1,1)`, `(0.5,0.5)` and `(-1,-1)`. Two are inside. The estimates after each record would be 4, 2, 8/3 and 2. More samples did not make this particular history steadily more accurate. This fixture checks the arithmetic; it is not itself a random experiment.

## What travels onward

You have separated drawing, classification and interpretation. The seed can replay the evidence; it cannot certify that the evidence suits the question. Keep that distinction as you inspect the painting, pipes and particle study: their random choices serve different purposes and do not all need to estimate an area.

In Pheromone, a recorded visit will enter a later choice. Samples there will depend on a changing field. We will follow that feedback explicitly instead of assuming each new position was drawn independently from the same square.
