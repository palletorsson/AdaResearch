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
