extends "study_base.gd"
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
    readout.text = "%s / selected %s
Two sourced records remain; Q has %s" % [model.description("door-1@12:00","open"),str(model.selected),model.description("door-1@12:00","Q")]
