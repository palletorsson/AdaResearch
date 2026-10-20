# Post-crisis — complete tutorial sequence

Eight halls in the existing Endless Museum. Review snapshot: 12 October 2026.

<!-- Source: commons/maps/CriticalAlgorithms_Algorithmic_Bias_Visualization/tutorial.md -->

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

Use Godot 4.6 in this museum project. Create `res://doc/book/studies/postcrisis-lineage/` (or your own folder). Carry `point_body.gd` and `line_skin.gd` unchanged from [Euclid](source/commons/maps/Euclid_Parallel/tutorial.md), `bench.gd` from [Russell](source/commons/maps/Russell_Paradox/tutorial.md), and `reports.gd` from [Florensky](source/commons/maps/Florensky_Paraconsistent/tutorial.md). Those complete printed files supply the frozen XR/desktop point, finite cylinder, initialized labels/buttons and support-pair operations. Their relative filenames must stay together. No other student dependency is hidden.

The supplied [`bias.tscn`](source/doc/book/studies/postcrisis-lineage/bias.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`bias_museum.gd`](source/doc/book/studies/postcrisis-lineage/bias_museum.gd), set the `LESSON` preload to your `bias_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

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


---

<!-- Source: commons/maps/CriticalAlgorithms_Applied_Ethics/tutorial.md -->

# Arrange the same seats

**Learning elements**

- Controlled comparison
- Arrays of positions
- Whole-object placement
- Authored acceptance criterion

Walk around the installed HEAD and CIRCLE models. They change chair count and relative size as well as arrangement. Our working copy isolates position: the same six cube-built seats retain their count, dimensions, colour and order in both layouts. This uses the whole meshes we learned to transform, without transforming their faces separately.

ROWS places two rows of three. RING places six centres at equal angles on a circle. The earlier sine and cosine operations return as a way to arrange positions. Each cube is drawn at one array entry. SEAT moves the carried point to another entry; dropping it near another seat selects that entry without relocating the seats.

The cylinder joins the selected seat to the next index, and the readout measures that distance. The index order is not a claim about who speaks next. In rows, the wrap between indices can be long; around the ring, every adjacent gap is equal within float tolerance. Comparing these exact distances still does not establish equal participation, sightlines or comfort. Those require a different test with people.

Now leave the ring still and press RULE. It changes an authored minimum centre-to-centre distance from 0.50 m to 0.90 m. The same positions pass the first rule and fail the second. `accepts` checks every distinct pair; the cylinder still shows only the next indexed pair. Change the threshold in code and predict the result before pressing it. You are now editing a criterion for acceptance, not only choosing a supplied arrangement. This is not chair-edge clearance, a route test or an accessibility standard. Who needed this constraint, and what evidence would justify choosing it?

## Continue the student folder

Keep the files from **Room for a distinction** in the same student folder. Add the complete files below; their relative preloads use that carried folder. The sphere, cylinder renderer, bench and pickup adapter are reused without being explained or rebuilt again.

The supplied [`ethics.tscn`](source/doc/book/studies/postcrisis-lineage/ethics.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`ethics_museum.gd`](source/doc/book/studies/postcrisis-lineage/ethics_museum.gd), set the `LESSON` preload to your `ethics_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

## Complete new code

### `seating.gd`

<!-- student-code:seating.gd -->
```gdscript
extends RefCounted
# Six equal seats: this working comparison varies positions only.
func layout(circle: bool) -> Array[Vector3]:
    var points: Array[Vector3] = []
    for i in 6:
        if circle:
            var angle := TAU*float(i)/6.0
            points.append(Vector3(cos(angle)*0.7,1.1,sin(angle)*0.7))
        else:
            points.append(Vector3(-0.75+float(i%3)*0.75,1.1,-0.45 if i<3 else 0.45))
    return points

func gaps(points: Array[Vector3]) -> Array[float]:
    var result: Array[float] = []
    for i in points.size(): result.append(points[i].distance_to(points[(i+1)%points.size()]))
    return result

# An authored centre-distance rule, not an accessibility or fairness standard.
func accepts(points: Array[Vector3], minimum_gap: float) -> bool:
    if points.size()<2 or not is_finite(minimum_gap) or minimum_gap<=0: return false
    for i in points.size():
        for j in range(i+1,points.size()):
            if points[i].distance_to(points[j])+0.00001<minimum_gap: return false
    return true
```

### `ethics_study.gd`

<!-- student-code:ethics_study.gd -->
```gdscript
extends "study_base.gd"
const Model = preload("seating.gd")
var model := Model.new()
var circle := false
var minimum_gap := 0.5
var selected := 0
var positions: Array[Vector3] = []

func _ready() -> void:
    start("ARRANGE / SIX EQUAL SEATS",["ROWS","RING","SEAT","RULE"],[arrange.bind(false),arrange.bind(true),next_seat,change_rule])
    refresh()

func arrange(value: bool) -> void:
    if point.held(): return
    circle = value
    refresh()

func change_rule() -> void:
    if point.held(): return
    minimum_gap = 0.9 if minimum_gap<0.7 else 0.5
    refresh()

func next_seat() -> void:
    if point.held(): return
    selected = (selected+1)%6
    refresh()

func release(at: Vector3) -> void:
    var best := INF
    for i in 6:
        var distance := at.distance_to(positions[i]+Vector3.UP*.18)
        if distance<best: best=distance; selected=i
    refresh()

func refresh() -> void:
    positions = model.layout(circle)
    clear_drawing()
    for i in 6:
        block(drawing,positions[i],Vector3(.22,.09,.22),Color("b9c3cd"))
        block(drawing,positions[i]+Vector3(0,.13,-.09),Vector3(.22,.22,.04),Color("b9c3cd"))
        label(drawing,str(i),positions[i]+Vector3(0,.1,.16),16)
    point_home = positions[selected]+Vector3.UP*.2
    var other := (selected+1)%6
    segment(positions[selected],positions[other])
    readout.text = "%s / seat %d to %d: %.2fm
Rule: all centre gaps >= %.2fm / %s
Authored rule; not an access or speech measure" % ["RING" if circle else "ROWS",selected,other,positions[selected].distance_to(positions[other]),minimum_gap,"PASS" if model.accepts(positions,minimum_gap) else "FAIL"]
```

### `assert_ethics.gd`

<!-- student-code:assert_ethics.gd -->
```gdscript
extends "assertions.gd"
const Model = preload("seating.gd")
func run() -> void:
    var model := Model.new()
    var rows := model.layout(false)
    var ring := model.layout(true)
    expect("same six seats",rows.size()==6 and ring.size()==6)
    expect("layout changes positions",rows!=ring)
    var gaps := model.gaps(ring)
    for i in 6: expect("equal circular gap %d"%i,is_equal_approx(gaps[i],gaps[0]))
    expect("indexed row wrap differs",not is_equal_approx(model.gaps(rows)[0],model.gaps(rows)[2]))
    var doubled: Array[Vector3] = []
    for p in ring: doubled.append(p*2)
    expect("scaling doubles measured gaps",is_equal_approx(model.gaps(doubled)[0],gaps[0]*2))
    var kept := ring.duplicate()
    expect("same geometry passes loose rule",model.accepts(ring,.5))
    expect("same geometry fails strict rule",not model.accepts(ring,.9))
    expect("changing criterion leaves positions",ring==kept)
    expect("all pairs checked not just indexed neighbours",not model.accepts([Vector3.ZERO,Vector3(2,0,0),Vector3(.1,0,0),Vector3(4,0,0)],.5))
    expect("invalid spacing rule refused",not model.accepts(ring,-1) and not model.accepts(ring,NAN))
```

## Predict, run, change one thing

Predict equal neighbouring gaps around the ring, but not around the indexed rows. Change only the radius in code and predict how every ring gap scales. Keep seat count, mesh size and colour unchanged. Freeze the ring and predict PASS at 0.50 m and FAIL at 0.90 m; assert that every position is unchanged after evaluating both rules. Explain why a geometric equality is insufficient evidence of equal access.

The assertion file above runs against your model files. From the project directory, use your Godot executable with:

```text
Godot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_ethics.gd --no-bridges
```

Adjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.

Carry onward: **Keep the two accounts** will reuse these operations.


---

<!-- Source: commons/maps/SpeculativeComputation_Paraconsistent_Engineering/tutorial.md -->

# Keep the two accounts

**Learning elements**

- Source-tagged records
- Selection versus deletion
- Four-valued support reused

At the existing conflict sculpture, try OVERLAP and RESOLVED. Its shorter branch makes a selection visible. Our working copy keeps both source records even when one column is shortened. The carried sphere can choose A or B; BOTH restores the two visible heights. The displayed selection never deletes the rejected account.

Bring `reports.gd` from Florensky. Its pair records support for and against a proposition separately. `claims.gd` now gives each report a subject, predicate, value, source and evidence description. The toy reports refer to the same door at the same time. Only matching subjects and predicates contribute to a support pair. Different predicates or different times must not accidentally become a contradiction.

Choosing A or B is a presentation decision stored in `selected`. `support` reads the retained records, so the pair remains BOTH after either selection. Q still has no support. This reuses the earlier formal distinction without pretending the museum sculpture executes a proof system. A source label is provenance; an evidence string is not automatically good evidence.

## Continue the student folder

Keep the files from **Arrange the same seats** in the same student folder. Add the complete files below; their relative preloads use that carried folder. The sphere, cylinder renderer, bench and pickup adapter are reused without being explained or rebuilt again.

The supplied [`conflict.tscn`](source/doc/book/studies/postcrisis-lineage/conflict.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`conflict_museum.gd`](source/doc/book/studies/postcrisis-lineage/conflict_museum.gd), set the `LESSON` preload to your `conflict_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

## Complete new code

### `claims.gd`

<!-- student-code:claims.gd -->
```gdscript
extends RefCounted
const Reports = preload("reports.gd")
var records: Array[Dictionary] = []
var selected := -1

func add(subject: String, predicate: String, value: bool, source: String, evidence: String) -> void:
    records.append({"subject":subject,"predicate":predicate,"value":value,
        "source":source,"evidence":evidence})

func resolve(index: int) -> bool:
    if index < -1 or index >= records.size(): return false
    selected = index
    return true

func support(subject: String, predicate: String) -> Vector2i:
    var pair := Vector2i.ZERO
    for record in records:
        if record.subject == subject and record.predicate == predicate:
            if record.value: pair.x = 1
            else: pair.y = 1
    return pair

func description(subject: String, predicate: String) -> String:
    return Reports.new().describe(support(subject,predicate))
```

### `conflict_study.gd`

<!-- student-code:conflict_study.gd -->
```gdscript
extends "study_base.gd"
const Claims = preload("claims.gd")
var model := Claims.new()

func _ready() -> void:
    model.add("door-1@12:00","open",true,"A","report A")
    model.add("door-1@12:00","open",false,"B","report B")
    start("KEEP THE DISAGREEMENT",["BOTH","CHOOSE A","CHOOSE B"],[choose.bind(-1),choose.bind(0),choose.bind(1)])
    refresh()

func choose(index: int) -> void:
    if point.held(): return
    model.resolve(index)
    refresh()

func release(at: Vector3) -> void: choose(0 if at.x<0 else 1)

func refresh() -> void:
    clear_drawing()
    for i in 2:
        var height := .52 if model.selected in [-1,i] else .1
        block(drawing,Vector3(-.55+i*1.1,1+height*.5,0),Vector3(.18,height,.18),Color("a8bec7"))
        label(drawing,model.records[i].source,Vector3(-.55+i*1.1,1.65,0))
    point_home = Vector3(0 if model.selected<0 else (-.55+model.selected*1.1),1.14,.55)
    readout.text = "%s / selected %s
Two sourced records remain; Q has %s" % [model.description("door-1@12:00","open"),str(model.selected),model.description("door-1@12:00","Q")]
```

### `assert_conflict.gd`

<!-- student-code:assert_conflict.gd -->
```gdscript
extends "assertions.gd"
const Claims = preload("claims.gd")
func run() -> void:
    var model := Claims.new()
    model.add("door@12","open",true,"A","observation A")
    model.add("door@12","open",false,"B","observation B")
    var before := model.records.duplicate(true)
    expect("opposed reports both supported",model.support("door@12","open")==Vector2i(1,1))
    expect("selection succeeds",model.resolve(0))
    expect("selection does not erase evidence",model.records==before)
    expect("selection does not resolve support",model.support("door@12","open")==Vector2i(1,1))
    expect("unrelated Q gains no support",model.support("door@12","Q")==Vector2i.ZERO)
    model.add("door@13","open",true,"C","later time")
    expect("different time stays separate",model.support("door@13","open")==Vector2i(1,0))
    expect("bad selection refused",not model.resolve(9) and model.selected==0)
    expect("reopen retains records",model.resolve(-1) and model.records.size()==3)
```

## Predict, run, change one thing

Choose A: both original records must remain, the support pair must remain (1,1), and Q must remain (0,0). Add a report about another time: it must not affect this subject. Then reopen the comparison without constructing replacement reports.

The assertion file above runs against your model files. From the project directory, use your Godot executable with:

```text
Godot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_conflict.gd --no-bridges
```

Adjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.

Carry onward: **A claim has an address** will reuse these operations.


---

<!-- Source: commons/maps/SpeculativeComputation_Situated_Computation/tutorial.md -->

# A claim has an address

**Learning elements**

- Subject and predicate
- Provenance
- Presentation versus stored data

Continue from the retained claims to the four installed situated readouts. Their verdicts and percentages are supplied by their configuration. They do not measure the approaching player. Our working copy reuses `Claims`, with the same subject identifier and four different predicates and sources. The sphere chooses which record is displayed; it does not alter that record's judgement. The selected pad turns amber and a short cylinder links it to the raised sphere, making the selection legible from different viewpoints.

`read` makes a deep copy for presentation. COVER replaces the source only in that returned copy. REVEAL can therefore recover it, and another view still has its original provenance. The source, predicate and confidence remain separate fields. A 92% label is not a calibrated probability simply because it is numeric.

The four verdicts answer different questions; they are not automatically logical negations. The existing camera witnesses extend the inquiry into viewpoint and time. They remain another encounter in this hall. This small lesson concentrates on retaining the address of a claim when its presentation changes.

## Continue the student folder

Keep the files from **Keep the two accounts** in the same student folder. Add the complete files below; their relative preloads use that carried folder. The sphere, cylinder renderer, bench and pickup adapter are reused without being explained or rebuilt again.

The supplied [`situated.tscn`](source/doc/book/studies/postcrisis-lineage/situated.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`situated_museum.gd`](source/doc/book/studies/postcrisis-lineage/situated_museum.gd), set the `LESSON` preload to your `situated_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

## Complete new code

### `viewpoints.gd`

<!-- student-code:viewpoints.gd -->
```gdscript
extends RefCounted
const Claims = preload("claims.gd")
const WORDS = ["ORDERLY", "CREATIVE", "DANGEROUS", "IRRELEVANT"]
const SOURCES = ["NW", "NE", "SW", "SE"]
const CONFIDENCE = [0.88, 0.76, 0.92, 0.61]
var claims := Claims.new()

func _init() -> void:
    for i in 4:
        claims.add("4729",WORDS[i],true,SOURCES[i],"AUTHORED EXAMPLE; NO MEASUREMENT")

func read(index: int, cover: bool) -> Dictionary:
    if index < 0 or index >= 4: return {}
    var result: Dictionary = claims.records[index].duplicate(true)
    result["confidence"] = CONFIDENCE[index]
    if cover: result.source = "COVERED"
    return result
```

### `situated_study.gd`

<!-- student-code:situated_study.gd -->
```gdscript
extends "study_base.gd"
const Model = preload("viewpoints.gd")
var model := Model.new()
var selected := 0
var covered := false

func _ready() -> void:
    start("LOCATE THE CLAIM",["VIEW","COVER","REVEAL"],[next_view,set_cover.bind(true),set_cover.bind(false)])
    refresh()

func next_view() -> void:
    if point.held(): return
    selected = (selected+1)%4
    refresh()

func set_cover(value: bool) -> void:
    if point.held(): return
    covered = value
    refresh()

func release(at: Vector3) -> void:
    selected = (0 if at.x<0 else 1)+(2 if at.z>0 else 0)
    refresh()

func refresh() -> void:
    clear_drawing()
    for i in 4:
        var at := Vector3(-.65 if i%2==0 else .65,1.15,-.3 if i<2 else .3)
        block(drawing,at,Vector3(.65,.05,.3),Color("e8c18c") if i==selected else Color("a7b7c4"))
        label(drawing,Model.SOURCES[i],at+Vector3.UP*.1)
        if i==selected:
            point_home = at+Vector3.UP*.3
            segment(at,point_home)
    var claim := model.read(selected,covered)
    readout.text = "%s: %s / %.0f%% authored
Source: %s / no measured probability" % [claim.subject,claim.predicate,claim.confidence*100,claim.source]
```

### `assert_situated.gd`

<!-- student-code:assert_situated.gd -->
```gdscript
extends "assertions.gd"
const Model = preload("viewpoints.gd")
func run() -> void:
    var model := Model.new()
    var original := model.claims.records.duplicate(true)
    var hidden := model.read(2,true)
    expect("source covered in view",hidden.source=="COVERED")
    expect("same subject",hidden.subject=="4729")
    expect("coverage preserves underlying data",model.claims.records==original)
    hidden.predicate = "ALTERED"
    expect("returned copy independent",model.read(2,false).predicate=="DANGEROUS")
    expect("source recoverable",model.read(2,false).source=="SW")
    expect("authored confidence .92",is_equal_approx(model.read(2,false).confidence,.92))
    expect("invalid view refused",model.read(4,false).is_empty())
    expect("different predicates are not negations",model.claims.support("4729","DANGEROUS")==Vector2i(1,0))
```

## Predict, run, change one thing

Cover the source, then reveal it. Predict that the underlying dictionary remains unchanged. Modify the returned copy in a test; a fresh read must still return the original. Explain what evidence would be needed before treating an authored confidence as a measured probability.

The assertion file above runs against your model files. From the project directory, use your Godot executable with:

```text
Godot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_situated.gd --no-bridges
```

Adjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.

Carry onward: **Count contributions and revisions** will reuse these operations.


---

<!-- Source: commons/maps/SpeculativeComputation_Collective_Knowledge/tutorial.md -->

# Count contributions and revisions

**Learning elements**

- Events versus distinct sources
- Version boundaries
- Revision without addition

Watch the installed peer tool, then keep the same distinction between a displayed choice and its retained source. In this working copy an arrival is a cube record: source, original position, current position, dispute flag and revision count. The carried sphere edits the first piece only after DISPUTE. Earlier position work now changes a contribution without counting it as a new arrival.

ADD follows a declared A, A, B sequence. Repeating A increases additions but not distinct sources in the current version. VERSION saves one deep copy of the preceding pieces and empties the current list and source set. `ever` and the lifetime totals remain. When A returns in another version it contributes another participation, but no new lifetime source.

REVISE changes a disputed piece's pose and retains its source and original position. The dispute stays open. Attribution to VISITOR reports who used this local control; it does not authenticate an identity or settle an argument. The first piece can also be moved with the sphere. This simulation cannot decide whether the revision is warranted. Another person contesting its reason would require a collaborative process beyond these counters. Capacity is six displayed pieces so the whole example remains inspectable; the installed exhibit supports more. Neither is a networked collaborative editor or a permanent archive.

## Continue the student folder

Keep the files from **A claim has an address** in the same student folder. Add the complete files below; their relative preloads use that carried folder. The sphere, cylinder renderer, bench and pickup adapter are reused without being explained or rebuilt again.

The supplied [`collective.tscn`](source/doc/book/studies/postcrisis-lineage/collective.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`collective_museum.gd`](source/doc/book/studies/postcrisis-lineage/collective_museum.gd), set the `LESSON` preload to your `collective_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

## Complete new code

### `contributions.gd`

<!-- student-code:contributions.gd -->
```gdscript
extends RefCounted
var pieces: Array[Dictionary] = []
var previous: Array[Dictionary] = []
var sources: Dictionary = {}
var ever: Dictionary = {}
var additions := 0
var participations := 0
var revisions := 0
var version := 1

func add(source: String, at: Vector3) -> void:
    pieces.append({"source":source,"original":at,"pose":at,"disputed":false,"revision":0})
    additions += 1
    if not sources.has(source): participations += 1
    sources[source] = true
    ever[source] = true

func dispute(index: int) -> bool:
    if index < 0 or index >= pieces.size(): return false
    pieces[index].disputed = true
    return true

func revise(index: int, at: Vector3) -> bool:
    if index < 0 or index >= pieces.size() or not pieces[index].disputed: return false
    pieces[index].pose = at
    pieces[index].revision += 1
    pieces[index]["revised_by"] = "VISITOR"
    revisions += 1
    return true

func next_version() -> void:
    previous = pieces.duplicate(true)
    pieces.clear()
    sources.clear()
    version += 1
```

### `collective_study.gd`

<!-- student-code:collective_study.gd -->
```gdscript
extends "study_base.gd"
const Model = preload("contributions.gd")
var model := Model.new()
var arrivals := 0

func _ready() -> void:
    start("COUNT WHAT ARRIVED",["ADD","DISPUTE","REVISE","VERSION"],[arrive,dispute,revise,version])
    refresh()

func arrive() -> void:
    if point.held() or model.pieces.size()>=6: return
    var source: String = ["A","A","B"][arrivals%3]
    var i := model.pieces.size()
    model.add(source,Vector3(-.9+i*.35,1.13,0))
    arrivals += 1
    refresh()

func dispute() -> void:
    if point.held(): return
    model.dispute(0)
    refresh()

func revise() -> void:
    if point.held() or model.pieces.is_empty(): return
    model.revise(0,model.pieces[0].pose+Vector3.UP*.1)
    refresh()

func release(at: Vector3) -> void:
    model.revise(0,(at-Vector3(0,0,.3)).clamp(Vector3(-1.1,1.05,-.5),Vector3(1.1,1.6,.5)))
    refresh()

func version() -> void:
    if point.held(): return
    model.next_version()
    refresh()

func refresh() -> void:
    clear_drawing()
    for piece in model.pieces:
        block(drawing,piece.pose,Vector3.ONE*.17,Color("d9a592") if piece.disputed else Color("a8c3bd"))
        label(drawing,piece.source,piece.pose+Vector3.UP*.2,16)
    point_home = model.pieces[0].pose+Vector3(0,0,.3) if not model.pieces.is_empty() else Vector3(0,1.15,.55)
    readout.text = "Version %d / pieces %d / sources %d / ever %d
Additions %d / participations %d / revisions %d" % [model.version,model.pieces.size(),model.sources.size(),model.ever.size(),model.additions,model.participations,model.revisions]
```

### `assert_collective.gd`

<!-- student-code:assert_collective.gd -->
```gdscript
extends "assertions.gd"
const Model = preload("contributions.gd")
func run() -> void:
    var model := Model.new()
    for source in ["A","A","B"]: model.add(source,Vector3.ZERO)
    expect("arrivals are not sources",model.additions==3 and model.sources.size()==2 and model.participations==2)
    expect("undisputed revision refused",not model.revise(0,Vector3.ONE))
    expect("dispute accepted",model.dispute(0))
    expect("revision accepted",model.revise(0,Vector3.ONE))
    expect("revision keeps source and original",model.pieces[0].source=="A" and model.pieces[0].original==Vector3.ZERO)
    expect("revision not addition or settlement",model.pieces.size()==3 and model.additions==3 and model.revisions==1 and model.pieces[0].disputed)
    model.next_version()
    model.add("A",Vector3.UP)
    expect("new version resets only local source set",model.sources.size()==1 and model.ever.size()==2 and model.participations==3 and model.additions==4)
    expect("previous version kept independently",model.previous.size()==3 and model.previous[0].pose==Vector3.ONE)
    expect("invalid index refused",not model.dispute(-1) and not model.revise(99,Vector3.ZERO))
```

## Predict, run, change one thing

Add A, A, B: expect three additions, two current sources and two participations. Begin another version and add A: expect four additions, one current source, two lifetime sources and three participations. Dispute and move a piece: its source and original pose remain, piece count stays fixed, revision rises.

The assertion file above runs against your model files. From the project directory, use your Godot executable with:

```text
Godot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_collective.gd --no-bridges
```

Adjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.

Carry onward: **Connections before passages** will reuse these operations.


---

<!-- Source: commons/maps/SpeculativeComputation_Rhizome_Network/tutorial.md -->

# Connections before passages

**Learning elements**

- Seeded positions
- Nearest earlier neighbours
- Adjacency and connected components

Enter the composed cave and find a return that does not retrace every passage. Then inspect the separate grower near its entrance. The cave is not generated by that tabletop graph. Our working copy isolates the grower's rule using the carried point and finite cylinders from Lines. We bring deterministic sampling from Randomness and indexed lists from Arrays.

The example prepares 24 seeded positions. Two initial points have no connecting edge. STEP adds one point and links it to the nearest earlier points. The neighbour search excludes the arriving point itself. With one link, each arrival extends exactly one component: two trees remain. With three links, the third point connects both seeds; later arrivals add circuits. The smaller sample layout is our declared construction, not an exact replay of the installed grower's 40 points.

LINKS rebuilds edges at the same positions. NODE or the sphere selects a point; CUT toggles whether that point participates. Edges remain stored so restoring a point can restore its old relations. `components` visits active neighbours, counting isolated active points too. Growth refuses while a point is cut, keeping the comparison fixed. REPLAY returns to the same two starting samples and retains the link setting.

`rewire` sorts only earlier indices by squared distance; the first entries supply the neighbours. Squared distance keeps the same order without a square root. In `components`, `todo` is a stack of indices still to visit. Pop one, skip it if `seen` already contains it, mark it, then add its active neighbours. The inner loop exhausts everything reachable from that starting index. The outer loop begins a new component only at an active, unvisited point. `seen` is what makes a circuit safe to traverse without looping forever.

Graph adjacency says which indices are joined. It does not guarantee that a body can enter the corresponding cave passage. A crossing of drawn cylinders does not add an edge. A degree counts neighbours; it does not measure influence. LINK changes one supplied parameter; it does not let a node revise the nearest-earlier rule. Name what is still fixed: boundary, arrival order, distance metric and authority to edit. Decentralized adjacency does not imply shared control over those choices. Assembly next reuses this graph representation to distinguish moving a joint from changing its neighbour.

## Continue the student folder

Keep the files from **Count contributions and revisions** in the same student folder. Add the complete files below; their relative preloads use that carried folder. The sphere, cylinder renderer, bench and pickup adapter are reused without being explained or rebuilt again.

The supplied [`rhizome.tscn`](source/doc/book/studies/postcrisis-lineage/rhizome.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`rhizome_museum.gd`](source/doc/book/studies/postcrisis-lineage/rhizome_museum.gd), set the `LESSON` preload to your `rhizome_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

## Complete new code

### `network.gd`

<!-- student-code:network.gd -->
```gdscript
extends RefCounted
var points: Array[Vector3] = []
var edges: Array[Vector2i] = []
var active: Array[bool] = []
var samples: Array[Vector3] = []
var links := 3

func seed_samples(seed_value: int = 47) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    samples.clear()
    for i in 24:
        var angle := rng.randf_range(0,TAU)
        var radius := rng.randf_range(0.32,0.8) if i>=2 else 0.04
        samples.append(Vector3(cos(angle)*radius,1.28,sin(angle)*radius*0.7))
    replay()

func replay() -> void:
    points.assign(samples.slice(0,2))
    active.assign([true,true])
    edges.clear()

func grow() -> bool:
    if points.size() >= samples.size() or false in active: return false
    points.append(samples[points.size()])
    active.append(true)
    rewire(links)
    return true

func rewire(count: int) -> void:
    links = clampi(count,1,3)
    edges.clear()
    for i in range(2,points.size()):
        var earlier: Array = range(i)
        earlier.sort_custom(func(a,b): return points[i].distance_squared_to(points[a]) < points[i].distance_squared_to(points[b]))
        for j in mini(links,i): edges.append(Vector2i(i,earlier[j]))

func neighbours(index: int) -> Array[int]:
    var result: Array[int] = []
    if index<0 or index>=active.size() or not active[index]: return result
    for edge in edges:
        var other := edge.y if edge.x==index else (edge.x if edge.y==index else -1)
        if other>=0 and active[other]: result.append(other)
    return result

func components() -> int:
    var seen: Dictionary = {}
    var total := 0
    for i in points.size():
        if not active[i] or seen.has(i): continue
        total += 1
        var todo: Array = [i]
        while not todo.is_empty():
            var current: int = todo.pop_back()
            if seen.has(current): continue
            seen[current] = true
            todo.append_array(neighbours(current))
    return total
```

### `rhizome_study.gd`

<!-- student-code:rhizome_study.gd -->
```gdscript
extends "study_base.gd"
const Model = preload("network.gd")
var model := Model.new()
var selected := 0

func _ready() -> void:
    model.seed_samples()
    start("CONNECT / SAME POSITIONS",["STEP","LINKS","NODE","CUT","REPLAY"],[step,links,next_node,cut,replay])
    refresh()

func step() -> void:
    if point.held(): return
    model.grow()
    refresh()

func links() -> void:
    if point.held(): return
    model.rewire(1 if model.links==3 else 3)
    refresh()

func next_node() -> void:
    if point.held(): return
    selected = (selected+1)%model.points.size()
    refresh()

func cut() -> void:
    if point.held(): return
    model.active[selected] = not model.active[selected]
    refresh()

func replay() -> void:
    if point.held(): return
    model.replay()
    selected = 0
    refresh()

func release(at: Vector3) -> void:
    var best := INF
    for i in model.points.size():
        var distance := at.distance_to(model.points[i])
        if distance<best: best=distance; selected=i
    refresh()

func refresh() -> void:
    clear_drawing()
    for i in model.points.size(): dot(model.points[i],Color("adc9bf") if model.active[i] else Color("4b5060"))
    for edge in model.edges:
        if model.active[edge.x] and model.active[edge.y]: segment(model.points[edge.x],model.points[edge.y])
    point_home = model.points[selected]+Vector3.UP*.16
    readout.text = "Nodes %d / links per arrival %d / components %d
Node %d: degree %d / %s" % [model.points.size(),model.links,model.components(),selected,model.neighbours(selected).size(),"present" if model.active[selected] else "removed"]
```

### `assert_rhizome.gd`

<!-- student-code:assert_rhizome.gd -->
```gdscript
extends "assertions.gd"
const Model = preload("network.gd")
func run() -> void:
    var model := Model.new()
    model.seed_samples(47)
    expect("two unlinked seeds",model.points.size()==2 and model.edges.is_empty() and model.components()==2)
    while model.grow(): pass
    var positions := model.points.duplicate()
    model.rewire(1)
    expect("one link forms forest with two components",model.edges.size()==22 and model.components()==2)
    model.rewire(3)
    expect("three links connect and create cycles",model.components()==1 and model.edges.size()>model.points.size()-1)
    expect("rewiring leaves positions",model.points==positions)
    var edges := model.edges.duplicate()
    model.active[0] = false
    expect("cut node has zero active degree",model.neighbours(0).is_empty())
    expect("cut prevents growth",not model.grow())
    model.active[0] = true
    expect("restore uses same edges",model.edges==edges and model.components()==1)
    model.replay()
    while model.grow(): pass
    expect("replay exactly retains samples",model.points==positions)
    var other := Model.new()
    other.seed_samples(47)
    while other.grow(): pass
    expect("fresh same seed recreates positions",other.points==positions)
    other.seed_samples(48)
    expect("new seed changes samples",other.samples!=model.samples)
```

## Predict, run, change one thing

At 24 points with all active, one-link growth has 22 edges and two components; three-link growth is connected and has circuits. Cut node 0, restore it, and verify the same edges return. Replay and regrow: positions must match exactly in this run. Do not interpret a restored edge as a newly invented repair.

The assertion file above runs against your model files. From the project directory, use your Godot executable with:

```text
Godot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_rhizome.gd --no-bridges
```

Adjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.

Carry onward: **Change a position, change a neighbour** will reuse these operations.


---

<!-- Source: commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/tutorial.md -->

# Change a position, change a neighbour

**Learning elements**

- Local coordinates
- Indexed connectivity
- Changed releases
- Validated persistence
- Prediction before editing

Find the installed gold body and its turquoise collars. Move a joint, then reroute one connection without moving a joint. Our working copy uses the same thirteen named positions and twelve connections from the VRBody assembly. `Body` composes the graph from Rhizome; it does not run its growth rule. The same PointBody is the editing handle, and LineSkin shows the indexed connections.

To keep the new code small, JOINT selects which position the single sphere edits. MODE switches from position editing to one endpoint of the left forearm connection; END selects its other endpoint. This is a reduced interface to the same distinction, not a replacement of the installed body's thirteen handles. The model is drawn at 0.48 scale above the bench. `body_position` reverses that display transform after `to_local` has removed the hall transform. Stored positions stay in the body's own frame.

In POSITION mode, release changes the selected joint if it moved more than 0.01 m in body coordinates. Bounds are explicit. In RELATION mode, release within 0.18 m of a joint proposes its index. Self-links, duplicate links and empty-space releases are refused; eleven other edges stay authored. Neither operation enforces anatomical proportions. The gold lines remain visual relations, distinct from the physical ragdoll elsewhere in the hall.

After a changed release, `PoseFile` validates and writes one latest record through a temporary file. Its schema retains coordinates, edge indices and completed edit count under an explicit model version; that version fixes names and starting geometry. Like the Foundations journal, loading checks structure before trusting data. JSON integers reload as floats, so valid indices are checked and converted. Invalid existing files are preserved and saving refuses to overwrite them.

The student file is `user://ada_postcrisis_pose_v1.json`. The installed gold body uses its separate Assembly record. Our two student halls share the student file; they do not overwrite the visitor's installed-workshop pose. This compact schema has no timestamps, identity, path or history. A save failure leaves the new body only in this working copy. Synthesis can read only the last successful file.

For one optional investigation, fill the empty `prediction` string in `assembly_study.gd` with your expectation before running the lesson. Press PREDICT before your next edit. `Observation.begin` saves that exact starting pose and prediction in a separate file. It refuses an empty prediction and refuses to replace an existing file. Keep the resulting changed pose, then continue to Synthesis. Use another `note_path` for a new experiment so the earlier one remains available. No prediction is supplied on your behalf.

## Continue the student folder

Keep the files from **Connections before passages** in the same student folder. Add the complete files below; their relative preloads use that carried folder. The sphere, cylinder renderer, bench and pickup adapter are reused without being explained or rebuilt again.

The supplied [`assembly.tscn`](source/doc/book/studies/postcrisis-lineage/assembly.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`assembly_museum.gd`](source/doc/book/studies/postcrisis-lineage/assembly_museum.gd), set the `LESSON` preload to your `assembly_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

## Complete new code

### `body.gd`

<!-- student-code:body.gd -->
```gdscript
extends RefCounted
const Network = preload("network.gd")
const IDS = ["torso","head","l_sh","r_sh","l_elb","r_elb","l_hand","r_hand","pelvis","l_knee","r_knee","l_foot","r_foot"]
const START = [Vector3(0,1.2,0),Vector3(0,1.55,0),Vector3(-.25,1.35,0),Vector3(.25,1.35,0),
    Vector3(-.45,1.15,0),Vector3(.45,1.15,0),Vector3(-.55,.95,.05),Vector3(.55,.95,.05),
    Vector3(0,.95,0),Vector3(-.15,.6,0),Vector3(.15,.6,0),Vector3(-.12,.15,.1),Vector3(.12,.15,.1)]
const EDGES = [Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(2,4),Vector2i(3,5),Vector2i(4,6),
    Vector2i(5,7),Vector2i(0,8),Vector2i(8,9),Vector2i(8,10),Vector2i(9,11),Vector2i(10,12)]
var graph := Network.new()
var edits := 0

func _init() -> void:
    graph.points.assign(START)
    graph.edges.assign(EDGES)
    graph.active.resize(13)
    graph.active.fill(true)

func move_joint(index: int, position: Vector3) -> bool:
    if index<0 or index>=13 or not position.is_finite(): return false
    var bounded := position.clamp(Vector3(-1.9,.12,-1.9),Vector3(1.9,2.35,1.9))
    if graph.points[index].distance_to(bounded)<=.01: return false
    graph.points[index] = bounded
    edits += 1
    return true

func join(endpoint: int, target: int) -> bool:
    if endpoint not in [0,1] or target<0 or target>=13: return false
    var proposed: Vector2i = graph.edges[5]
    if proposed[endpoint]==target or proposed[1-endpoint]==target: return false
    proposed[endpoint] = target
    for i in graph.edges.size():
        if i!=5 and (graph.edges[i]==proposed or graph.edges[i]==Vector2i(proposed.y,proposed.x)): return false
    graph.edges[5] = proposed
    edits += 1
    return true

func nearest(at: Vector3, radius: float = .18) -> int:
    var found := -1
    for i in graph.points.size():
        var distance := at.distance_to(graph.points[i])
        if distance < radius: radius = distance; found = i
    return found

func displaced() -> int:
    var count := 0
    for i in 13:
        if graph.points[i].distance_to(START[i])>.01: count += 1
    return count

func pack() -> Dictionary:
    var positions: Array = []
    var edges: Array = []
    for p in graph.points: positions.append([p.x,p.y,p.z])
    for edge in graph.edges: edges.append([edge.x,edge.y])
    return {"schema":1,"model":"postcrisis-body-v1","positions":positions,"edges":edges,"edits":edits}
```

### `pose_file.gd`

<!-- student-code:pose_file.gd -->
```gdscript
extends RefCounted
const Body = preload("body.gd")
const PATH = "user://ada_postcrisis_pose_v1.json"

func whole(value, low: int, high: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=low and value<=high

func decode(data) -> Dictionary:
    if not data is Dictionary or not data.has_all(["schema","model","positions","edges","edits"]): return {"ok":false}
    if data.schema!=1 or data.model!="postcrisis-body-v1" or not whole(data.edits,0,1000000): return {"ok":false}
    if not data.positions is Array or data.positions.size()!=13 or not data.edges is Array or data.edges.size()!=12: return {"ok":false}
    var body := Body.new()
    for i in 13:
        var p = data.positions[i]
        if not p is Array or p.size()!=3: return {"ok":false}
        for n in p:
            if not (n is int or n is float) or not is_finite(float(n)): return {"ok":false}
        var v := Vector3(p[0],p[1],p[2])
        if absf(v.x)>1.9 or absf(v.z)>1.9 or v.y<.12 or v.y>2.35: return {"ok":false}
        body.graph.points[i] = v
    var seen: Dictionary = {}
    for i in 12:
        var e = data.edges[i]
        if not e is Array or e.size()!=2 or not whole(e[0],0,12) or not whole(e[1],0,12) or e[0]==e[1]: return {"ok":false}
        var edge := Vector2i(int(e[0]),int(e[1]))
        var key := Vector2i(mini(edge.x,edge.y),maxi(edge.x,edge.y))
        if seen.has(key) or (i!=5 and edge!=Body.EDGES[i]): return {"ok":false}
        seen[key] = true
        body.graph.edges[i] = edge
    body.edits = int(data.edits)
    return {"ok":true,"body":body}

func read(path: String = PATH) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok":true,"empty":true,"message":"No pose kept. Visit Assembly."}
    var file := FileAccess.open(path,FileAccess.READ)
    if file==null or file.get_length()>65536: return {"ok":false,"message":"Cannot read this record."}
    var parser := JSON.new()
    if parser.parse(file.get_as_text())!=OK: return {"ok":false,"message":"Invalid JSON; file kept unchanged."}
    var result := decode(parser.data)
    result["empty"] = false
    result["message"] = "Saved pose read." if result.ok else "Invalid record; file kept unchanged."
    return result

func save(body, path: String = PATH) -> bool:
    if not decode(body.pack()).ok or not read(path).ok: return false
    var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
    if file==null: return false
    file.store_string(JSON.stringify(body.pack(),"  "))
    file.flush()
    var error := file.get_error()
    file.close()
    if error!=OK: return false
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK
```

### `observation.gd`

<!-- student-code:observation.gd -->
```gdscript
extends RefCounted
const PoseFile = preload("pose_file.gd")
const PATH = "user://ada_postcrisis_observation_v1.json"
var poses := PoseFile.new()

func words(value) -> bool:
    return value is String and not value.strip_edges().is_empty() and value.length()<=1000

func valid(data) -> bool:
    if not data is Dictionary or not data.has_all(["schema","before","prediction","complete"]): return false
    if data.schema!=1 or not data.complete is bool or not words(data.prediction): return false
    if not poses.decode(data.before).ok: return false
    if data.complete:
        if not data.has_all(["after","observation","keep_reason"]): return false
        if not poses.decode(data.after).ok or not words(data.observation) or not words(data.keep_reason): return false
        if data.after.edits<=data.before.edits: return false
    return true

func read(path: String = PATH) -> Dictionary:
    if not FileAccess.file_exists(path): return {}
    var file := FileAccess.open(path,FileAccess.READ)
    if file==null or file.get_length()>65536: return {}
    var parser := JSON.new()
    if parser.parse(file.get_as_text())!=OK: return {}
    return parser.data if valid(parser.data) else {}

func write(data: Dictionary, path: String) -> bool:
    if not valid(data): return false
    var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
    if file==null: return false
    file.store_string(JSON.stringify(data,"  "))
    file.flush()
    var error := file.get_error()
    file.close()
    if error!=OK: return false
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK

func begin(body, prediction: String, path: String = PATH) -> bool:
    # One experiment per file: never silently replace an earlier note.
    if FileAccess.file_exists(path): return false
    return write({"schema":1,"before":body.pack(),"prediction":prediction,"complete":false},path)

func finish(body, observed: String, reason: String, path: String = PATH) -> bool:
    var data := read(path)
    if data.is_empty() or data.complete: return false
    data["after"] = body.pack()
    data["observation"] = observed
    data["keep_reason"] = reason
    data["complete"] = true
    return write(data,path)

func matches(data: Dictionary, body) -> bool:
    if not valid(data) or not data.complete: return false
    var stored = poses.decode(data.after).body
    return stored.graph.points==body.graph.points and stored.graph.edges==body.graph.edges and stored.edits==body.edits
```

### `assembly_study.gd`

<!-- student-code:assembly_study.gd -->
```gdscript
extends "study_base.gd"
const Body = preload("body.gd")
const PoseFile = preload("pose_file.gd")
const Observation = preload("observation.gd")
@export_multiline var prediction: String = ""
var notes := Observation.new()
var note_path: String = Observation.PATH
var model := Body.new()
var storage := PoseFile.new()
var record_path: String = PoseFile.PATH
var selected := 6
var relation := false
var endpoint := 1
var message := "New starting body."

func _ready() -> void:
    start("ASSEMBLE / KEEP THE RELATION",["JOINT","MODE","END","RELOAD","PREDICT"],[next_joint,mode,next_end,reload_pose,predict])
    reload_pose()

func predict() -> void:
    if point.held(): return
    message = "Prediction saved before the next edit." if notes.begin(model,prediction,note_path) else "Write a prediction; use a new note path if one already exists."
    refresh()

func display_position(at: Vector3) -> Vector3: return at*.48+Vector3(0,1.02,.05)
func body_position(at: Vector3) -> Vector3: return (at-Vector3(0,1.02,.05))/.48

func next_joint() -> void:
    if point.held(): return
    selected = (selected+1)%13
    refresh()

func mode() -> void:
    if point.held(): return
    relation = not relation
    refresh()

func next_end() -> void:
    if point.held(): return
    endpoint = 1-endpoint
    refresh()

func reload_pose() -> void:
    if point.held(): return
    var loaded := storage.read(record_path)
    if loaded.ok and not loaded.empty: model = loaded.body
    message = loaded.message
    refresh()

func release(at: Vector3) -> void:
    var location := body_position(at)
    var changed: bool = model.join(endpoint,model.nearest(location)) if relation else model.move_joint(selected,location)
    if changed:
        message = "Saved locally." if storage.save(model,record_path) else "Save failed; working pose is only in this study."
    else: message = "No valid change; attachment retained."
    refresh()

func refresh() -> void:
    clear_drawing()
    for p in model.graph.points: dot(display_position(p),Color("ddbd88"),.022)
    for edge in model.graph.edges: segment(display_position(model.graph.points[edge.x]),display_position(model.graph.points[edge.y]))
    var index: int = model.graph.edges[5][endpoint] if relation else selected
    point_home = display_position(model.graph.points[index])
    readout.text = "%s / %s / edits %d / displaced %d
%s" % ["RELATION end %d"%endpoint if relation else "POSITION",Body.IDS[index],model.edits,model.displaced(),message]
```

### `assert_assembly.gd`

<!-- student-code:assert_assembly.gd -->
```gdscript
extends "assertions.gd"
const Body = preload("body.gd")
const PoseFile = preload("pose_file.gd")
func run() -> void:
    var model := Body.new()
    expect("thirteen joints twelve edges one component",model.graph.points.size()==13 and model.graph.edges.size()==12 and model.graph.components()==1)
    expect("unchanged release not an edit",not model.move_joint(6,Body.START[6]))
    expect("moved hand accepted",model.move_joint(6,Body.START[6]+Vector3.UP*.2))
    expect("displacement and edits start together",model.displaced()==1 and model.edits==1)
    model.move_joint(6,Body.START[6])
    expect("return reduces displacement not edit count",model.displaced()==0 and model.edits==2)
    var positions := model.graph.points.duplicate()
    expect("hand connection can meet head",model.join(1,1))
    expect("connection change preserves all positions",model.graph.points==positions)
    expect("hand is isolated",model.graph.neighbours(6).is_empty() and model.graph.components()==2)
    expect("other end rejoins hand",model.join(0,6) and model.graph.components()==1)
    expect("self link refused",not model.join(1,6))
    expect("duplicate link refused",not model.join(0,0))
    var storage := PoseFile.new()
    var roundtrip := storage.decode(JSON.parse_string(JSON.stringify(model.pack())))
    expect("JSON float indices restored",roundtrip.ok and roundtrip.body.graph.edges==model.graph.edges)
    expect("all coordinates restored",roundtrip.body.graph.points==model.graph.points)
    var broken := model.pack(); broken.edges[0]=[0,0]
    expect("bad edge refused",not storage.decode(broken).ok)
    broken=model.pack(); broken.positions[0][0]="not a coordinate"
    expect("bad coordinate refused",not storage.decode(broken).ok)
    broken=model.pack(); broken.edges[5]=[1.5,2]
    expect("fractional indices refused",not storage.decode(broken).ok)
    broken=model.pack(); broken.edits=-1
    expect("negative edit count refused",not storage.decode(broken).ok)
    expect("nonfinite input refused",not model.move_joint(0,Vector3(INF,0,0)))
```

## Predict, run, change one thing

Move the left hand away and back in two releases: edits rise twice and displacement returns to zero. Reroute the second endpoint of edge 5 from hand to head: the hand is isolated and the rest contains a cycle. Move the other endpoint from elbow to that hand: every joint reconnects. Save and reload without losing the relation.

The assertion file above runs against your model files. From the project directory, use your Godot executable with:

```text
Godot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_assembly.gd --no-bridges
```

Adjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.

Carry onward: **The body that crosses the threshold** will reuse these operations.


---

<!-- Source: commons/maps/PostCrisis_Synthesis/tutorial.md -->

# The body that crosses the threshold

**Learning elements**

- Reconstruction from a file
- Counts versus state
- Missing and invalid records
- Observation tied to a saved pose

Bring the file made by the preceding student lesson into the existing Synthesis hall. The installed amber body and ledger already demonstrate the workshop's separate record. Our working copy reconstructs the student's record beside its starting body. No live point node travels between scenes: the data supplies positions and connections to new instances of familiar renderers.

READ validates the file using the same `PoseFile`; it does not silently repair or invent data. With no record, the second place stays empty. With an invalid record, the error remains visible and the file remains unchanged. A valid read produces a `Body` whose coordinates, connectivity and edit count match the saved version.

Edits count changed releases. Displaced joints compare the current positions with the starting positions. Moving a joint away and back can therefore raise edits while reducing displacement. A rerouted connection can change the number of connected groups without moving any joint. These are different questions answered from the same record.

JOINT changes the displayed selection without rewriting the file. Taking and releasing the sphere also leaves the record intact: this is a reader, not another editor. The complete code is short because validation, graph traversal and rendering were written earlier. To investigate accountability, keep the next question separate: what activity did a change enable or obstruct, what observation supports that judgement, and who can revisit it? The pose schema alone supplies none of those answers.

An optional note makes one investigation inspectable. Fill the empty `observation` and `keep_reason` strings in `synthesis_study.gd` with what you noticed and why you choose to keep this change, then run the lesson and press KEEP NOTE. This completes the separate prediction record begun in Assembly. It retains the before and after poses, your original prediction (even if wrong), observation and reason. READ can tell whether the completed note still matches the current pose. If another edit replaced the pose on disk, KEEP NOTE requires READ first; it will not silently attach your note to that newer body.

These are text values you write in the two student scripts; there is no new VR keyboard or automatic interpretation of your intention. Open the JSON under Godot's user data folder to read the complete note. The program checks structure and pose identity, not the truth of your explanation, whether the prediction was sincere, or whether anybody else agrees. It saves no participant identity, gesture path or full revision history. This is evidence for revisiting one decision, not a finished accountability system. Keeping a before snapshot also does not implement an Undo command.

## Continue the student folder

Keep the files from **Change a position, change a neighbour** in the same student folder. Add the complete files below; their relative preloads use that carried folder. The sphere, cylinder renderer, bench and pickup adapter are reused without being explained or rebuilt again.

The supplied [`synthesis.tscn`](source/doc/book/studies/postcrisis-lineage/synthesis.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`synthesis_museum.gd`](source/doc/book/studies/postcrisis-lineage/synthesis_museum.gd), set the `LESSON` preload to your `synthesis_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

## Complete new code

### `synthesis_study.gd`

<!-- student-code:synthesis_study.gd -->
```gdscript
extends "study_base.gd"
const Body = preload("body.gd")
const PoseFile = preload("pose_file.gd")
const Observation = preload("observation.gd")
@export_multiline var observation: String = ""
@export_multiline var keep_reason: String = ""
var notes := Observation.new()
var note_path: String = Observation.PATH
var note_message := "No note read."
var storage := PoseFile.new()
var record_path: String = PoseFile.PATH
var model = null
var selected := 6
var message := ""

func _ready() -> void:
    start("RETURN / THE SAME RECORD",["READ","JOINT","KEEP NOTE"],[reload_pose,next_joint,keep_note])
    reload_pose()

func reload_pose() -> void:
    if point.held(): return
    var loaded := storage.read(record_path)
    model = loaded.body if loaded.ok and not loaded.empty else null
    message = loaded.message
    var note := notes.read(note_path)
    note_message = "No valid note; pose still readable."
    if not note.is_empty():
        note_message = "Prediction awaits an observation." if not note.complete else ("Note matches this pose." if model!=null and notes.matches(note,model) else "Note belongs to another pose.")
    refresh()

func keep_note() -> void:
    if point.held() or model==null: return
    var current := storage.read(record_path)
    if not current.ok or current.empty or current.body.pack()!=model.pack():
        note_message = "Pose changed on disk. READ before attaching a note."
    elif notes.finish(model,observation,keep_reason,note_path):
        note_message = "Note kept for this pose; no claim of proof."
    else:
        note_message = "Need an open prediction, a changed pose and your two texts."
    refresh()

func next_joint() -> void:
    if point.held(): return
    selected = (selected+1)%13
    refresh()

func draw_body(points, edges, offset: Vector3, colour: Color) -> void:
    for p in points: dot(p*.4+offset,colour,.02)
    for edge in edges: segment(points[edge.x]*.4+offset,points[edge.y]*.4+offset)

func refresh() -> void:
    clear_drawing()
    draw_body(Body.START,Body.EDGES,Vector3(-.65,1.02,0),Color("9fc2db"))
    if model==null:
        point_home = Vector3(-.65,1.22,.35)
        readout.text = message+"
The second place is empty."
        return
    draw_body(model.graph.points,model.graph.edges,Vector3(.65,1.02,0),Color("ddbd88"))
    point_home = model.graph.points[selected]*.4+Vector3(.65,1.02,0)
    readout.text = "Edits %d / displaced %d / groups %d
%s
%s" % [model.edits,model.displaced(),model.graph.components(),Body.IDS[selected],note_message]
```

### `assert_synthesis.gd`

<!-- student-code:assert_synthesis.gd -->
```gdscript
extends "assertions.gd"
const Body = preload("body.gd")
const PoseFile = preload("pose_file.gd")
const Observation = preload("observation.gd")
const NOTE = "user://ada_postcrisis_note_assert_only.json"
const PATH = "user://ada_postcrisis_assert_only.json"
func run() -> void:
    if FileAccess.file_exists(PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    var storage := PoseFile.new()
    expect("missing record is explicitly empty",storage.read(PATH).ok and storage.read(PATH).empty)
    var model := Body.new()
    model.move_joint(6,Body.START[6]+Vector3.UP*.2)
    model.join(1,1)
    expect("real disk save succeeds",storage.save(model,PATH))
    var bytes := FileAccess.get_file_as_string(PATH)
    var second_reader := PoseFile.new()
    var read := second_reader.read(PATH)
    expect("fresh reader restores graph",read.ok and read.body.graph.edges==model.graph.edges)
    expect("fresh reader restores positions and edits",read.body.graph.points==model.graph.points and read.body.edits==2)
    expect("reading does not rewrite file",FileAccess.get_file_as_string(PATH)==bytes)
    var bad := FileAccess.open(PATH,FileAccess.WRITE); bad.store_string("{broken"); bad.close()
    expect("malformed file refused",not storage.read(PATH).ok)
    expect("saving cannot silently erase invalid record",not storage.save(model,PATH) and FileAccess.get_file_as_string(PATH)=="{broken")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    expect("unwritable parent reports failure",not storage.save(model,"user://ada_absent_postcrisis_test_folder/pose.json"))
    if FileAccess.file_exists(NOTE): DirAccess.remove_absolute(ProjectSettings.globalize_path(NOTE))
    var notes := Observation.new()
    var before := Body.new()
    expect("empty prediction refused",not notes.begin(before,"",NOTE))
    expect("prediction can precede an edit",notes.begin(before,"All joints will stay connected.",NOTE))
    expect("existing prediction not overwritten",not notes.begin(before,"Replace it",NOTE))
    var pending := FileAccess.get_file_as_string(NOTE)
    expect("unchanged body cannot complete trial",not notes.finish(before,"No change","Keep",NOTE))
    expect("failed completion retains prediction",FileAccess.get_file_as_string(NOTE)==pending)
    expect("observation and reason required",not notes.finish(model,"","Keep",NOTE))
    expect("changed body accepts observation",notes.finish(model,"The hand is isolated; two groups.","Keep this case to compare with a connected body.",NOTE))
    var note := notes.read(NOTE)
    expect("wrong prediction retained",note.prediction=="All joints will stay connected.")
    expect("before and after are independent",note.before.edits==0 and note.after.edits==2)
    expect("note binds complete pose",notes.matches(note,model))
    model.move_joint(6,Body.START[6])
    expect("later pose is a different observation subject",not notes.matches(note,model))
    var kept_note := FileAccess.get_file_as_string(NOTE)
    expect("completed note not silently rewritten",not notes.finish(model,"Replace","Replace",NOTE) and FileAccess.get_file_as_string(NOTE)==kept_note)
    expect("incomplete note schema refused",not notes.valid({"schema":1,"complete":true}))
    var broken_note := note.duplicate(true)
    broken_note.after.edges[0]=[0,0]
    expect("invalid pose inside note refused",not notes.valid(broken_note))
    var bad_note := FileAccess.open(NOTE,FileAccess.WRITE)
    bad_note.store_string("{broken");bad_note.close()
    expect("invalid note retained without blocking pose decoding",notes.read(NOTE).is_empty() and not notes.finish(model,"Replace","Replace",NOTE) and FileAccess.get_file_as_string(NOTE)=="{broken" and storage.decode(model.pack()).ok)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(NOTE))
```

## Predict, run, change one thing

First visit with no file: the amber place must be empty. Then create a changed pose in Assembly, close that study and read here in another process. Compare all thirteen positions, all twelve edges and the edit count. Selecting another joint must not change the file bytes. A malformed copy must be refused rather than displayed as a plausible body. For the optional note, predict before editing, retain a wrong prediction if it occurs, then finish with your own observation and reason. Assert that later edits make the note a record of the earlier pose, and that saving the note does not rewrite the pose file.

The assertion file above runs against your model files. From the project directory, use your Godot executable with:

```text
Godot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_synthesis.gd --no-bridges
```

Adjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.

Return to an earlier artifact with a particular change and an observation to test. A record makes that return possible; it does not settle its consequences.
