extends "bench.gd"
const Receiver = preload("routed_receiver.gd")
const Route = preload("input_route.gd")
const LOW := 1.12
const TRAVEL := 0.48
var receiver := Receiver.new()
var model := Route.new(receiver)
var selected := 0
var cube: MeshInstance3D
var wire: MeshInstance3D
var offered_label: Label3D
var used_label: Label3D

func _ready() -> void:
    start("OFFERED / RECEIVED",["LAMBDA","PHI","CONNECT / CUT","REPEAT","KEEP"],
        [select.bind(0),select.bind(1),toggle,repeat_response,keep])
    block(self,Vector3(-1.17,LOW+TRAVEL/2,0.05),Vector3(0.018,TRAVEL,0.018),Color("526071"))
    segment(Vector3(-0.2,1.12,0),Vector3(0.8,1.12,0))
    cube = block(self,Vector3(-0.2,1.24,0),Vector3.ONE*0.2,Color.WHITE)
    wire = block(self,Vector3(-0.69,1.02,0.22),Vector3(0.7,0.015,0.025),Color.WHITE)
    offered_label = label(self,"",Vector3(-0.91,1.70,0.18),20)
    used_label = label(self,"",Vector3(0.36,1.57,0),20)
    label(self,"1 metre / return at end",Vector3(0.3,1.02,0.36),17)
    redraw()

func _process(delta: float) -> void:
    if point == null: return
    if point.held():
        var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        model.set_value(selected,fraction if selected == 0 else 2.0*fraction-1.0)
    receiver.advance(delta)
    redraw()

func select(term: int) -> void:
    if point.held(): return
    selected = term
    redraw()

func toggle() -> void:
    if point.held(): return
    model.toggle()
    redraw()

func repeat_response() -> void:
    if point.held(): return
    receiver.repeat()
    redraw()

func keep() -> void:
    if point.held(): return
    model.keep()
    redraw()

func redraw() -> void:
    var r := model.reading()
    cube.position.x = -0.2+r.distance
    cube.material_override.albedo_color = r.colour
    wire.material_override.albedo_color = Color("43d7dc") if r.connected else Color("42484b")
    var fraction: float = r.offered[0] if selected == 0 else (r.offered[1]+1.0)*0.5
    point_home = Vector3(-1.17,LOW+fraction*TRAVEL,0.22)
    offered_label.text = "OFFER %.2f / %+.2f" % r.offered
    used_label.text = "USED %.2f / %+.2f" % r.used
    var kept := "KEEP: no comparison yet"
    if not model.kept.is_empty():
        kept = "Kept offer %.2f / %+.2f; used %.2f / %+.2f" % [
            model.kept.offered[0],model.kept.offered[1],model.kept.used[0],model.kept.used[1]]
    readout.text = "%s / hand edits %s\nSpeed %.2f m/s / time %.1f / distance %.2f\n%s" % [
        "CONNECTED" if r.connected else "CUT: inputs held","LAMBDA" if selected == 0 else "PHI",
        r.speed,r.elapsed,r.distance,kept]
