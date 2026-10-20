"""Small complete working copies for the eight existing post-crisis halls."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'doc/book/studies/postcrisis-lineage'
FILES={
'observation.gd':'''extends RefCounted
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
''',
'distinctions.gd':'''extends RefCounted
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
''',
'seating.gd':'''extends RefCounted
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
''',
'claims.gd':'''extends RefCounted
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
''',
'viewpoints.gd':'''extends RefCounted
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
''',
'contributions.gd':'''extends RefCounted
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
''',
'network.gd':'''extends RefCounted
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
''',
'body.gd':'''extends RefCounted
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
''',
'pose_file.gd':'''extends RefCounted
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
''',
}

def main():
    DEST.mkdir(parents=True,exist_ok=True)
    for name,code in FILES.items(): (DEST/name).write_text(code,encoding='utf8')
    for name in ['point_body.gd','line_skin.gd','bench.gd','reports.gd']:
        source=ROOT/'doc/book/studies/foundations-lineage'/name
        (DEST/name).write_text(source.read_text(encoding='utf8'),encoding='utf8')
    print('Wrote',len(FILES),'models and four declared carried files')
if __name__=='__main__':main()
