extends "bench.gd"
const Recommendation = preload("recommendation.gd")
const LOW := 1.18
const TRAVEL := 0.48
const WIDTH := 1.8
const ROWS := [0.08,0.21,0.48,0.62,0.76,0.90]
var model := Recommendation.new()
var editing_weight := false
var cubes: Array[MeshInstance3D] = []
var strip: MeshInstance3D
var kept_strip: MeshInstance3D

func _ready() -> void:
    start("CHANGE A WEIGHT / MOVE A RECOMMENDATION",["WEIGHT","STRIP","KEEP","RETURN","ZERO L"],
        [select.bind(true),select.bind(false),keep_reading,return_route,zero_weight])
    readout.font_size = 27
    block(drawing,Vector3(0,1.0,0),Vector3(1.9,0.025,1.3),Color("263442"))
    strip = block(drawing,Vector3(0,1.025,0),Vector3(0.36,0.015,1.3),Color("4dedad"))
    kept_strip = block(drawing,Vector3(0,1.04,0),Vector3(0.012,0.015,1.3),Color("ffb74d"))
    var rng := RandomNumberGenerator.new()
    rng.seed = 46
    for fraction: float in ROWS:
        for row in 4:
            var at := Vector3((fraction-0.5)*WIDTH,1.14,-0.48+row*0.3)
            at += Vector3(rng.randf_range(-1,1),rng.randf_range(0,1),rng.randf_range(-1,1))*fraction*0.07
            var colour := Color("9fc7f0").lerp(Color("fa5f69"),fraction)
            var cube := block(drawing,at,Vector3.ONE*0.12,colour)
            cube.rotation = Vector3(rng.randf(),rng.randf(),rng.randf())*fraction
            cubes.append(cube)
    block(drawing,Vector3(-1.17,LOW+TRAVEL/2,0),Vector3(0.018,TRAVEL,0.018),Color("526071"))
    label(drawing,"same sphere / two controls",Vector3(-1.05,1.06,0.35),16)
    redraw()

func _process(_delta: float) -> void:
    if point.held():
        var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        if editing_weight:
            model.set_weight(fraction)
        else:
            model.set_route(lerpf(model.MIN_ROUTE,model.MAX_ROUTE,fraction))
        redraw()

func select(weight: bool) -> void:
    if point.held(): return
    editing_weight = weight
    redraw()

func keep_reading() -> void:
    if point.held(): return
    model.keep()
    redraw()

func return_route() -> void:
    if point.held(): return
    model.return_route()
    redraw()

func zero_weight() -> void:
    if point.held(): return
    model.set_weight(0.0)
    redraw()

func redraw() -> void:
    strip.position.x = model.strip_x(WIDTH)
    kept_strip.visible = not model.kept.is_empty()
    if kept_strip.visible: kept_strip.position.x = (model.kept.route-0.5)*WIDTH
    var r := model.reading()
    var fraction: float = r.weight if editing_weight else inverse_lerp(model.MIN_ROUTE,model.MAX_ROUTE,r.route)
    point_home = Vector3(-1.17,LOW+fraction*TRAVEL,0.22)
    if not point.held(): point.position = point_home
    var contribution: float = 0.0 if is_zero_approx(r.contribution) else r.contribution
    readout.text = "Hand edits %s / L %.2f / strip %.2f\nE input %.2f / -L*E %+.3f / total %.3f\nForms stay fixed; green recommends" % [
        "WEIGHT" if editing_weight else "STRIP",r.weight,r.route,r.parts[1],contribution,r.total]
    if model.kept.is_empty():
        readout.text += "\nKEEP a comparison"
    else:
        readout.text += "\nKept L %.2f / strip %.2f / total %.3f" % [model.kept.weight,model.kept.route,model.kept.total]
