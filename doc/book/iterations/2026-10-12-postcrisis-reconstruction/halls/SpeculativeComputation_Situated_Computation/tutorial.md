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

The supplied [`situated.tscn`](../../source/doc/book/studies/postcrisis-lineage/situated.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`situated_museum.gd`](../../source/doc/book/studies/postcrisis-lineage/situated_museum.gd), set the `LESSON` preload to your `situated_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

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
