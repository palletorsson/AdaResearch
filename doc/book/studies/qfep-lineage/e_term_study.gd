extends "bench.gd"
const Possibilities = preload("possibilities.gd")
const LOW := 1.18
const TRAVEL := 0.48
var model := Possibilities.new()
var tips: Array[MeshInstance3D] = []
var caps: Array[MeshInstance3D] = []

func _ready() -> void:
    start("COUNT THE ENDINGS / KEEP THE PATHS", ["ONE","TWO","OPEN","PRUNE","KEEP"],
        [choose.bind(1),choose.bind(2),choose.bind(3),prune,keep_reading])
    readout.font_size = 28
    redraw()

func _process(_delta: float) -> void:
    if point.held():
        var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        var value := 1 + int(round(fraction*2.0))
        if value != model.branch:
            model.set_branch(value)
            redraw()

func choose(value: int) -> void:
    if point.held(): return
    model.set_branch(value)
    redraw()

func prune() -> void:
    if point.held(): return
    model.prune()
    redraw()

func keep_reading() -> void:
    if point.held(): return
    model.keep()
    show_reading()

func position_for(path: String) -> Vector3:
    if path.is_empty(): return Vector3(0,1.05,0.4)
    var index := 0
    for digit in path:
        index = index*model.branch + int(digit)
    var slots := int(pow(model.branch,path.length()))
    return Vector3(-1.0+2.0*(index+0.5)/slots,1.05+path.length()*0.11,0.4-path.length()*0.25)

func redraw() -> void:
    tips.clear()
    caps.clear()
    clear_drawing()
    block(drawing,Vector3(-1.17,LOW+TRAVEL/2,0),Vector3(0.018,TRAVEL,0.018),Color("526071"))
    label(drawing,"1 / 2 / 3 branches",Vector3(-1.12,1.08,0.25),18)
    block(drawing,position_for(""),Vector3.ONE*0.045,Color("be95ed"))
    for edge in model.edges:
        var a := position_for(edge.from)
        var b := position_for(edge.to)
        var line := LineSkin.new()
        (line.mesh as CylinderMesh).top_radius = 0.003
        (line.mesh as CylinderMesh).bottom_radius = 0.003
        drawing.add_child(line)
        line.show_segment(a,b-a,a.distance_to(b))
        if edge.closed:
            caps.append(block(drawing,b,Vector3(0.035,0.022,0.022),Color("ffb74d")))
        elif edge.to.length() == model.LEVELS:
            tips.append(block(drawing,b,Vector3.ONE*0.015,Color("50dbef")))
    point_home = Vector3(-1.17,LOW+(model.branch-1)*TRAVEL/2,0.22)
    if not point.held(): point.position = point_home
    show_reading()

func show_reading() -> void:
    var r := model.reading()
    readout.text = "%d branches / 4 stages / equal leaf weights\n%d endings / H %.3f nats\n%d closures / %d endings removed" % [
        r.branch,r.leaves,r.entropy_nats,r.closures,r.removed_leaves]
    if model.kept.is_empty():
        readout.text += "\nCyan = ending / amber = closed branch"
    else:
        readout.text += "\nKept %d endings / H %.3f nats" % [model.kept.leaves,model.kept.entropy_nats]
