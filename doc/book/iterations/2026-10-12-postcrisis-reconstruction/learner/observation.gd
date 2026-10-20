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
