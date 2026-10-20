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

The supplied [`conflict.tscn`](../../../doc/book/studies/postcrisis-lineage/conflict.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`conflict_museum.gd`](../../../doc/book/studies/postcrisis-lineage/conflict_museum.gd), set the `LESSON` preload to your `conflict_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

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
