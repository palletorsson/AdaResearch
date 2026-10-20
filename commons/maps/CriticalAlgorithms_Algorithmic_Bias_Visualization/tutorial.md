# Room for a distinction

**Learning elements**

- Authored interpolation
- Stable identities
- Measurement versus interpretation

We are inside the existing bias hall. Move COMPRESSION on its labelled sculpture; then build a smaller working copy beside it. The PointBody from the early point lessons and Foundations becomes a handle. Its position controls one interpolation amount. The labels keep their identities while their positions change. We reuse `lerp` from Transformation and arrays from the earlier sequences.

Our six labels are authored examples, as are their two arrangements. The three warm words receive less space; the three grey words receive more. This is not a trained embedding or a measurement of any social group. The program can measure separation in this representation. Whether the grouping or the representation is appropriate requires further evidence.

`layout` returns a fresh array. Its index continues to identify the same word; drawing the arrangement never sorts or renames it. At amount 0, neighbouring labels in either row are 0.52 metres apart. At amount 1, the warm gap is 0.12 and the grey gap 0.80. HALF must produce the midpoint of those distances. Taking another viewpoint changes the image, not these coordinates.

The inherited bench builds its labels before assigning their text. `study_base.gd` adds one shared pickup/release adapter and a small visible dot. It retains the last held local coordinate so that a physics tick cannot erase the intended release. After physics, it also places the released marker at the current selection so that the visible sphere agrees with the readout. Later halls reuse this adapter. Only the point handle is pickable in this working copy; the displayed labels remain its subject.

## Continue the student folder

Use Godot 4.6 in this museum project. Create `res://doc/book/studies/postcrisis-lineage/` (or your own folder). Carry `point_body.gd` and `line_skin.gd` unchanged from [Euclid](../Euclid_Parallel/tutorial.md), `bench.gd` from [Russell](../Russell_Paradox/tutorial.md), and `reports.gd` from [Florensky](../Florensky_Paraconsistent/tutorial.md). Those complete printed files supply the frozen XR/desktop point, finite cylinder, initialized labels/buttons and support-pair operations. Their relative filenames must stay together. No other student dependency is hidden.

The supplied [`bias.tscn`](../../../doc/book/studies/postcrisis-lineage/bias.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`bias_museum.gd`](../../../doc/book/studies/postcrisis-lineage/bias_museum.gd), set the `LESSON` preload to your `bias_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

## Complete new code

### `study_base.gd`

<!-- student-code:study_base.gd -->
```gdscript
extends "bench.gd"
var was_held := false
var hand_at := Vector3.ZERO

func _process(_delta: float) -> void:
    if point.held():
        was_held = true
        hand_at = to_local(point.global_position)
        drag(hand_at)
    elif was_held:
        was_held = false
        release(hand_at)
    if not point.held(): point.position = point_home

func drag(_at: Vector3) -> void: pass
func release(_at: Vector3) -> void: pass

func dot(at: Vector3, colour: Color, radius: float = .035) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius*2
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    visual.material_override = material
    visual.position = at
    drawing.add_child(visual)
```

### `assertions.gd`

<!-- student-code:assertions.gd -->
```gdscript
extends RefCounted
var checks: Array[Dictionary] = []
func expect(label: String, condition: bool) -> void:
    checks.append({"name":label,"passed":condition})
    assert(condition,label)
```

### `check.gd`

<!-- student-code:check.gd -->
```gdscript
extends SceneTree
func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty(): push_error("Supply an assertion script path"); quit(1); return
    var script = load(args[0])
    if script==null: quit(1); return
    var suite = script.new()
    suite.run()
    var passed: bool = not suite.checks.is_empty()
    for result in suite.checks: passed = passed and result.passed
    print("PASS" if passed else "FAIL", " / ",args[0]," / ",suite.checks.size()," assertions")
    quit(0 if passed else 1)
```

### `distinctions.gd`

<!-- student-code:distinctions.gd -->
```gdscript
extends RefCounted
var amount := 0.0
const WORDS = ["queer", "disabled", "refugee", "normal", "professional", "objective"]

func layout(value: float) -> Array[Vector3]:
    amount = clampf(value, 0, 1)
    var result: Array[Vector3] = []
    for i in 6:
        var warm := i < 3
        var column := i % 3
        var start := Vector3((column-1)*0.52, 1.4, -0.3 if warm else 0.3)
        var finish := Vector3((column-1)*(0.12 if warm else 0.8), 1.4, -0.45 if warm else 0.45)
        result.append(start.lerp(finish, amount))
    return result
```

### `bias_study.gd`

<!-- student-code:bias_study.gd -->
```gdscript
extends "study_base.gd"
const Model = preload("distinctions.gd")
var model := Model.new()
var positions: Array[Vector3] = []

func _ready() -> void:
    start("DISTINGUISH / SAME WORDS",["OPEN","HALF","COMPRESS"],[set_amount.bind(0.0),set_amount.bind(.5),set_amount.bind(1.0)])
    refresh()

func set_amount(value: float) -> void:
    if point.held(): return
    model.amount = value
    refresh()

func drag(at: Vector3) -> void:
    model.amount = clampf((at.x+.8)/1.6,0,1)
    refresh()

func refresh() -> void:
    positions = model.layout(model.amount)
    point_home = Vector3(-.8+model.amount*1.6,1.17,.58)
    clear_drawing()
    for i in 6:
        dot(positions[i],Color("e4a98d") if i<3 else Color("b7c1c5"))
        label(drawing,Model.WORDS[i],positions[i]+Vector3.UP*.13,16)
    readout.text = "Compression %.2f / authored positions
Warm gap %.2fm; grey gap %.2fm" % [model.amount,positions[0].distance_to(positions[1]),positions[3].distance_to(positions[4])]
```

### `assert_bias.gd`

<!-- student-code:assert_bias.gd -->
```gdscript
extends "assertions.gd"
const Model = preload("distinctions.gd")
func run() -> void:
    var model := Model.new()
    var opening := model.layout(0)
    var middle := model.layout(.5)
    var end := model.layout(1)
    expect("six identities retained",opening.size()==6 and Model.WORDS.size()==6)
    expect("warm midpoint .32",is_equal_approx(middle[0].distance_to(middle[1]),.32))
    expect("grey midpoint .66",is_equal_approx(middle[3].distance_to(middle[4]),.66))
    expect("compression reduces warm gap",end[0].distance_to(end[1])<opening[0].distance_to(opening[1]))
    expect("fresh arrays leave earlier arrangement intact",is_equal_approx(opening[0].x,-.52))
    expect("range clamps at upper end",model.layout(3)==end)
    expect("range clamps at lower end",model.layout(-1)==opening)
```

## Predict, run, change one thing

Before HALF, predict warm gap 0.32 m and grey gap 0.66 m. Change the authored finish gap in code, predict its midpoint, and check a fresh layout. Drag beyond the control range: the amount must remain between 0 and 1. Keep the sphere instance and word order unchanged.

The assertion file above runs against your model files. From the project directory, use your Godot executable with:

```text
Godot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_bias.gd --no-bridges
```

Adjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.

Carry onward: **Arrange the same seats** will reuse these operations.
