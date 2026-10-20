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

The supplied [`ethics.tscn`](../../../doc/book/studies/postcrisis-lineage/ethics.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`ethics_museum.gd`](../../../doc/book/studies/postcrisis-lineage/ethics_museum.gd), set the `LESSON` preload to your `ethics_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

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
