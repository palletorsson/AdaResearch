# Noise Columns — one body, three drivers

## Learning elements

- Scalar driver and receiving function.
- A fixed value, a periodic value and a coherent field sample.
- Time used as a sampling address.
- Local clock; holding a displayed state.
- Rest positions and repeatable deformation.

## Look before naming

The three columns are already in the museum. Watch them before pressing REVEAL. Which holds? Which seems to return? FREEZE holds their clock. SPIN turns the held shapes; MARBLE changes the shaft's surface. These are separate operations.

From Wavefunctions you bring the twisted shaft: rings of positions, joined by triangle faces. From Randomness you bring a named seed and a repeatable recipe. Here the new operation is small: **send different sources through the same receiving function**. Noise supplies a number; the shaft decides what it changes.

## Continue the construction

Use one empty Node3D in your existing museum learner space, at floor level with unit scale. Give it about four metres of width and stand on its local +Z side. Attach `02_column_drivers.gd`. Save `shaft.gd` and your existing `point_body.gd` beside it. All three files are printed below. Day Zero's XR Tools, player, camera, lighting and grip/trigger actions remain supplied by the museum.

This is a small reconstruction beside the installed work. It carries Bernini's ring-and-face construction with a narrower profile and fixed half-turn. It isolates the vertical drop; the installed shafts also have ribs, bulges and other offsets. It does not reconstruct the marble shader, capitals or their supports. These display shafts have no colliders. The sphere is our earlier pickable PointBody: hold it and press the trigger to pause or resume this study. Its initial position is set before it enters the physics tree.

### The new script

The three kinds keep the same order: held, sine, field. Every shaft has the same rest positions, faces and material. Only its incoming value differs.

<!-- student-code:02_column_drivers.gd -->
```gdscript
extends Node3D

const Shaft = preload("shaft.gd")
const PointBody = preload("point_body.gd")
const KINDS := ["held", "periodic", "field"]
@export var top_drop := 0.70
var time := 0.0
var playing := true
var next_update := 0.0
var phases: Array[float] = []
var shafts: Array[MeshInstance3D] = []
var noise := FastNoiseLite.new()
var control: PointBody
var label := Label3D.new()

func _ready() -> void:
    noise.seed = 31415
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    noise.frequency = 0.35
    noise.fractal_type = FastNoiseLite.FRACTAL_NONE
    for i in range(KINDS.size()):
        var shaft := Shaft.new()
        shaft.position.x = (i - 1) * 1.1
        add_child(shaft)
        shafts.append(shaft)
    control = PointBody.new()
    control.position = Vector3(0, 1.0, 1.0)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    control.get_child(0).material_override = black
    add_child(control)
    control.action_pressed.connect(toggle_clock)
    label.position = Vector3(0, 2.9, 0)
    label.font_size = 28
    label.pixel_size = 0.0025
    add_child(label)
    draw_values()
    next_update = 1.0 / 12.0

func driver(kind: String, seconds: float) -> float:
    match kind:
        "periodic":
            return sin(seconds * 0.9) * 0.5 + 0.5
        "field":
            return clampf(noise.get_noise_2d(seconds * 0.55, 0.0) * 0.5 + 0.5, 0.0, 1.0)
        _:
            return 0.10

func _process(delta: float) -> void:
    if not playing:
        return
    time += delta
    if time >= next_update:
        draw_values()
        next_update = time + 1.0 / 12.0

func draw_values() -> void:
    phases.clear()
    for i in range(shafts.size()):
        var value := driver(KINDS[i], time)
        phases.append(value)
        shafts[i].receive(value, top_drop)
    draw_label()

func draw_label() -> void:
    label.text = "HELD %.2f / SINE %.2f / FIELD %.2f\nLOCAL %.2f s / %s / GRIP + TRIGGER: pause" % [phases[0], phases[1], phases[2], time, "RUN" if playing else "HELD"]

func toggle_clock(_held: Variant) -> void:
    playing = not playing
    # Update the status without replacing the shape held between mesh updates.
    draw_label()
```

`time` counts seconds only while this local clock runs. In `sin(seconds * 0.9)`, 0.9 is radians per second; a cycle takes `TAU / 0.9`, about seven seconds. Multiplying the signed result by 0.5 and adding 0.5 maps it to 0–1. This output is an amount, not an angle.

The field branch turns time into an address: `(seconds * 0.55, 0)`. The first coordinate advances 0.55 field units per second; the second stays fixed. Frequency scales that address inside FastNoiseLite. The seed selects a repeatable field. Nearby addresses give related values. Asking again at the same address gives the same value; it does not spend another random draw.

The study explicitly uses Simplex without fractal layers. The installed trio uses Simplex with the resource's layered defaults. Their numerical paths differ; both hand one bounded value to a whole shaft. Layering is a later subject. Neither branch samples independently at every vertex.

The display updates at most twelve times per second. Between updates it holds its last mesh and values. Pausing preserves that displayed shape; it stops this clock without pausing the museum. The held driver remains 0.10 even when the clock runs.

### The carried shaft, with a receiver

The loops and face indices return from Bernini. `rest` keeps the undeformed positions. `weights` records how much of the drop each height receives: zero at the foot, one at the top, the square root of relative height between. Only `receive()` adds the new deformation. The maximum drop is measured in local metres because the study has unit scale.

<!-- student-code:shaft.gd -->
```gdscript
# The ring-and-face construction from Bernini, with one receiving function.
extends MeshInstance3D

const HEIGHT := 2.4
const SIDES := 8
const SPANS := 16
var rest: Array[Vector3] = []
var weights: Array[float] = []
var faces: Array[Vector3i] = []
var points: Array[Vector3] = []

func _init() -> void:
    for row in range(SPANS + 1):
        var v := float(row) / SPANS
        for corner in range(SIDES):
            var angle := TAU * corner / SIDES
            var p := Vector3(0.23 * cos(angle), 0, 0.14 * sin(angle))
            rest.append(p.rotated(Vector3.UP, PI * v) + Vector3(0, HEIGHT * v, 0))
            weights.append(sqrt(v))
    for row in range(SPANS):
        for corner in range(SIDES):
            var a := row * SIDES + corner
            var b := row * SIDES + (corner + 1) % SIDES
            faces.append(Vector3i(a, b, a + SIDES))
            faces.append(Vector3i(b, b + SIDES, a + SIDES))
    var bottom := rest.size()
    rest.append(Vector3.ZERO)
    weights.append(0.0)
    var top := rest.size()
    rest.append(Vector3.UP * HEIGHT)
    weights.append(1.0)
    for corner in range(SIDES):
        var next := (corner + 1) % SIDES
        faces.append(Vector3i(bottom, next, corner))
        faces.append(Vector3i(top, SPANS * SIDES + corner, SPANS * SIDES + next))
    var ivory := StandardMaterial3D.new()
    ivory.albedo_color = Color(0.91, 0.89, 0.84)
    ivory.roughness = 0.55
    material_override = ivory

func receive(value: float, maximum_drop: float) -> void:
    points.clear()
    for i in range(rest.size()):
        points.append(rest[i] - Vector3.UP * weights[i] * maximum_drop * value)
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    builder.set_smooth_group(-1)
    for face in faces:
        for index in [face.x, face.y, face.z]:
            builder.add_vertex(points[index])
    builder.generate_normals()
    mesh = builder.commit()
```

Every update starts from `rest`. It does not subtract another amount from yesterday's altered position. At value 1 the top drops 0.70 metres; at 0.5 it drops 0.35 metres. The foot stays at zero. Face indices and vertex count stay the same. That does not make this a simulation of stone under load, nor guarantee that arbitrary parameter changes will avoid folds or self-intersection.

### The point we already know

This is the unchanged PointBody from the previous hall, included so the printed example is complete. Its frozen release keeps the control where you leave it. The lesson supplies its black material and connects its existing action signal; pickup itself is not a new subject here.

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

## Make a prediction, then change the receiver

1. Before editing, predict the sine column at time zero, a quarter-cycle and a half-cycle. Its incoming values are 0.5, 1 and 0.5; the top heights should be 2.05, 1.70 and 2.05 metres. Watch a complete return. Pause it and walk around.
2. Change only `top_drop` from 0.70 to 0.35. Predict what stays: driver values, repeat period, field addresses, number of vertices and face connections. Every vertical displacement should halve; the top at a quarter-cycle should now be 2.05 metres. Compare at the same times, not at two unrelated moments.
3. Call the receiver twice with the same value. It must give the same positions. If the column sinks farther on the second call, find where the original positions were lost.

The visible result should support your explanation of the change. A passing script alone does not show that you can distinguish its source from its receiver.

## Carry onward

Leave the columns frozen and look at the installed dark sphere. Its own clock continues. A sine changes brightness and emission there, without rebuilding the mesh. You already know those material properties from Colour. Noise One will take one retained field sample and send it to two receivers: height and colour.
