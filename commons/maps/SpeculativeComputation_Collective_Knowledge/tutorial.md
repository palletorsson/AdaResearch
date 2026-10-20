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

The supplied [`collective.tscn`](../../../doc/book/studies/postcrisis-lineage/collective.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`collective_museum.gd`](../../../doc/book/studies/postcrisis-lineage/collective_museum.gd), set the `LESSON` preload to your `collective_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

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
