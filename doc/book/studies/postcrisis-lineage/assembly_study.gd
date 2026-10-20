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
