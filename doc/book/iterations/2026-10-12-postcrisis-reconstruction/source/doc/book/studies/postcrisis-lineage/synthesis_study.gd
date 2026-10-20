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
