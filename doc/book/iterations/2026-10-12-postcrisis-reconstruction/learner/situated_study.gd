extends "study_base.gd"
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
    readout.text = "%s: %s / %.0f%% authored
Source: %s / no measured probability" % [claim.subject,claim.predicate,claim.confidence*100,claim.source]
