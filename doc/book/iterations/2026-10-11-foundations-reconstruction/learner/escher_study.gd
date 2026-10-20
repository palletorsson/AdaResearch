extends "bench.gd"
const HeightRoute = preload("height_route.gd")
var model := HeightRoute.new()
var tilted := false

func _ready() -> void:
    start("ESCHER / WHERE THE RISE RETURNS", ["STEP", "OPEN", "TILT", "RESET"],
        [advance, open_route, tilt, reset])
    refresh()

func frame() -> Transform3D:
    return global_transform*Transform3D(Basis(Vector3.FORWARD, 0.35 if tilted else 0), Vector3.UP*1.05)

func advance() -> void:
    if point.held(): return
    model.step(frame())
    refresh()

func open_route() -> void:
    if point.held(): return
    model.closed = not model.closed
    reset()

func tilt() -> void:
    if point.held(): return
    tilted = not tilted
    reset()

func reset() -> void:
    if point.held(): return
    model.reset()
    refresh()

func refresh() -> void:
    clear_drawing()
    var t := global_transform.affine_inverse()*frame()
    for i in model.points.size():
        var at: Vector3 = t*model.points[i]
        block(drawing, at, Vector3(0.25,0.07,0.25), Color("9eadb9"))
        label(drawing,str(i),at+Vector3(0,0.12,0),18)
        if i<model.points.size()-1 or model.closed:
            segment(at,t*model.points[(i+1)%model.points.size()])
    point_home = t*model.points[model.index]+Vector3.UP*0.16
    readout.text = "%s | step %d\nLast %+.3f m; up %.3f / down %.3f\n%s" % [
        "CLOSED" if model.closed else "OPEN", model.index, model.last, model.up, model.down,
        "Closing differences sum to %.5f"%model.closure(frame()) if model.closed else "The open end does not wrap."]
