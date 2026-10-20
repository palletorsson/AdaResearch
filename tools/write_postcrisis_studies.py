"""Visible interactions; inherited point and bench keep their original roles."""
from write_postcrisis_code import DEST
FILES={
'study_base.gd':'''extends "bench.gd"
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
''',
'bias_study.gd':'''extends "study_base.gd"
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
    readout.text = "Compression %.2f / authored positions\nWarm gap %.2fm; grey gap %.2fm" % [model.amount,positions[0].distance_to(positions[1]),positions[3].distance_to(positions[4])]
''',
'ethics_study.gd':'''extends "study_base.gd"
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
    readout.text = "%s / seat %d to %d: %.2fm\nRule: all centre gaps >= %.2fm / %s\nAuthored rule; not an access or speech measure" % ["RING" if circle else "ROWS",selected,other,positions[selected].distance_to(positions[other]),minimum_gap,"PASS" if model.accepts(positions,minimum_gap) else "FAIL"]
''',
'conflict_study.gd':'''extends "study_base.gd"
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
    readout.text = "%s / selected %s\nTwo sourced records remain; Q has %s" % [model.description("door-1@12:00","open"),str(model.selected),model.description("door-1@12:00","Q")]
''',
'situated_study.gd':'''extends "study_base.gd"
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
    readout.text = "%s: %s / %.0f%% authored\nSource: %s / no measured probability" % [claim.subject,claim.predicate,claim.confidence*100,claim.source]
''',
'collective_study.gd':'''extends "study_base.gd"
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
    readout.text = "Version %d / pieces %d / sources %d / ever %d\nAdditions %d / participations %d / revisions %d" % [model.version,model.pieces.size(),model.sources.size(),model.ever.size(),model.additions,model.participations,model.revisions]
''',
'rhizome_study.gd':'''extends "study_base.gd"
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
    readout.text = "Nodes %d / links per arrival %d / components %d\nNode %d: degree %d / %s" % [model.points.size(),model.links,model.components(),selected,model.neighbours(selected).size(),"present" if model.active[selected] else "removed"]
''',
'assembly_study.gd':'''extends "study_base.gd"
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
    readout.text = "%s / %s / edits %d / displaced %d\n%s" % ["RELATION end %d"%endpoint if relation else "POSITION",Body.IDS[index],model.edits,model.displaced(),message]
''',
'synthesis_study.gd':'''extends "study_base.gd"
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
        readout.text = message+"\nThe second place is empty."
        return
    draw_body(model.graph.points,model.graph.edges,Vector3(.65,1.02,0),Color("ddbd88"))
    point_home = model.graph.points[selected]*.4+Vector3(.65,1.02,0)
    readout.text = "Edits %d / displaced %d / groups %d\n%s\n%s" % [model.edits,model.displaced(),model.graph.components(),Body.IDS[selected],note_message]
''',
}
def main():
    for name,code in FILES.items(): (DEST/name).write_text(code,encoding='utf8')
    print('Wrote nine visual scripts')
if __name__=='__main__':main()
