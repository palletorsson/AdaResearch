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

The supplied [`assembly.tscn`](../../../doc/book/studies/postcrisis-lineage/assembly.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`assembly_museum.gd`](../../../doc/book/studies/postcrisis-lineage/assembly_museum.gd), set the `LESSON` preload to your `assembly_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

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
