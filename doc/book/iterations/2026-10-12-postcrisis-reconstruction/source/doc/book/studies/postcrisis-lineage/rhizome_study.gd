extends "study_base.gd"
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
    readout.text = "Nodes %d / links per arrival %d / components %d
Node %d: degree %d / %s" % [model.points.size(),model.links,model.components(),selected,model.neighbours(selected).size(),"present" if model.active[selected] else "removed"]
