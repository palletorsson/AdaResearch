extends "bench.gd"
const SignedChange = preload("signed_change.gd")
const LOW := 1.12
const TRAVEL := 0.48
var model := SignedChange.new()
var labels_revealed := false

func _ready() -> void:
    start("PHI / GIVE A DIFFERENCE A WEIGHT",
        ["REVERSE", "2s / 4s", "KEEP", "ZERO PHI", "LABELS"],
        [reverse_pair, change_interval, keep, zero_phi, toggle_labels])
    redraw()

func _process(_delta: float) -> void:
    if point == null or not point.held(): return
    var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL, 0.0, 1.0)
    model.set_phi(2.0*fraction-1.0)
    redraw()

func reverse_pair() -> void:
    if point.held(): return
    model.reverse_pair()
    redraw()

func change_interval() -> void:
    if point.held(): return
    model.set_interval(4.0 if model.interval == 2.0 else 2.0)
    redraw()

func keep() -> void:
    if point.held(): return
    model.keep()
    redraw()

func zero_phi() -> void:
    if point.held(): return
    model.set_phi(0.0)
    redraw()

func toggle_labels() -> void:
    if point.held(): return
    labels_revealed = not labels_revealed
    redraw()

func signed(value: float) -> String:
    # Avoid printing negative zero at this displayed precision.
    return "%+.3f" % (0.0 if absf(value) < 0.0005 else value)

func redraw() -> void:
    clear_drawing()
    var r := model.reading()
    point_home = Vector3(-1.17, LOW+(model.phi+1.0)*0.5*TRAVEL, 0.22)
    for i in 2:
        var value: float = model.earlier if i == 0 else model.later
        var x := -0.62+i*0.62
        block(drawing, Vector3(x,1.02+value*0.26,0),
            Vector3(0.22,maxf(value*0.52,0.002),0.22), Color("79c9df"))
        label(drawing, ("EARLIER" if i == 0 else "LATER")+" %.2f" % value,
            Vector3(x,1.06,0.36),16)
    var baseline := Vector3(0.82,1.40,0)
    segment(baseline-Vector3(0.22,0,0),baseline+Vector3(0.22,0,0))
    if not is_zero_approx(r.contribution):
        block(drawing, baseline+Vector3(0,r.contribution*0.20,0),
            Vector3(0.20,absf(r.contribution)*0.40,0.20), Color("f087b4"))
    label(drawing,"PHI x CHANGE",Vector3(0.82,1.06,0.36),16)
    var words := "Signed weight; no judgement supplied"
    if labels_revealed: words = "Earlier labels: RESIST (-) / EMBRACE (+)"
    var record := "KEEP: no record yet"
    if not model.kept.is_empty():
        record = "KEEP phi %+.2f / change %s / %.0fs / product %s" % [
            model.kept.phi,signed(model.kept.difference),model.kept.interval,signed(model.kept.contribution)]
    readout.text = "AUTHORED pair %.2f -> %.2f over %.0fs\nChange %s / average rate %s per s\nPHI %+.2f x change = %s\n%s\n%s" % [
        r.earlier,r.later,r.interval,signed(r.difference),signed(r.rate),
        r.phi,signed(r.contribution),record,words]
