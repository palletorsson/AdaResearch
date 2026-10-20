extends "bench.gd"
const Reports = preload("reports.gd")
var model := Reports.new()

func _ready() -> void:
    start("FLORENSKY / KEEP THE REPORTS DISTINCT", ["P FOR", "P AGAINST", "Q FOR", "CLEAR"],
        [toggle.bind(0),toggle.bind(1),toggle.bind(2),reset])
    refresh()

func toggle(which: int) -> void:
    if point.held(): return
    if which==0: model.p.x=1-model.p.x
    elif which==1: model.p.y=1-model.p.y
    elif which==2: model.q.x=1-model.q.x
    refresh()

func reset() -> void:
    if point.held(): return
    model.p=Vector2i.ZERO
    model.q=Vector2i.ZERO
    refresh()

func refresh() -> void:
    clear_drawing()
    for i in 3:
        var at := Vector3(-0.8+i*0.8,1.1,0)
        var present: bool = [model.p.x,model.p.y,model.q.x][i]==1
        block(drawing,at,Vector3(0.45,0.16 if present else 0.025,0.45),Color("bd9fd0") if present else Color("445464"))
        label(drawing,["P","not P","Q"][i],at+Vector3.UP*0.2)
    point_home=Vector3(0,1.2,0.48)
    readout.text="P: %s | Q: %s\nP and not P: %s\nTwo reports do not add support for Q."%[
        model.describe(model.p),model.describe(model.q),model.describe(model.both(model.p,model.neg(model.p)))]
