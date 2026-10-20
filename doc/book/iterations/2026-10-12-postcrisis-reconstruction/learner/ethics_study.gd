extends "study_base.gd"
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
    readout.text = "%s / seat %d to %d: %.2fm
Rule: all centre gaps >= %.2fm / %s
Authored rule; not an access or speech measure" % ["RING" if circle else "ROWS",selected,other,positions[selected].distance_to(positions[other]),minimum_gap,"PASS" if model.accepts(positions,minimum_gap) else "FAIL"]
