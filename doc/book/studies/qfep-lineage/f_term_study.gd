extends "bench.gd"
const Prediction = preload("prediction.gd")
const LOW := 1.18
const TRAVEL := 0.48
var model := Prediction.new()
var cells: Array[MeshInstance3D] = []
var marks: Array[MeshInstance3D] = []

func _ready() -> void:
    start("CHANGE THE GUESS / KEEP THE GRID", ["P .1", "P .9", "EXPECT 0", "EXPECT 1", "KEEP"],
        [set_p.bind(0.1), set_p.bind(0.9), expect.bind(0), expect.bind(1), keep_reading])
    readout.font_size = 28
    block(drawing, Vector3(-1.08,LOW+TRAVEL/2,0), Vector3(0.018,TRAVEL,0.018), Color("526071"))
    label(drawing, "p(1) / lift sphere", Vector3(-1.06,1.08,0.25),18)
    for i in model.SAMPLES:
        var at := Vector3(-0.48+(i%8)*0.17,1.015,-0.65+(i/8)*0.17)
        cells.append(block(drawing,at,Vector3(0.15,0.018,0.15),Color.WHITE))
        marks.append(block(drawing,at+Vector3(0,0.016,0.057),Vector3(0.12,0.01,0.016),Color("ffb74d")))
    redraw()

func _process(_delta: float) -> void:
    if point.held():
        var value := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        if not is_equal_approx(value,model.p):
            model.set_probability(value)
            redraw()

func set_p(value: float) -> void:
    if point.held(): return
    model.set_probability(value)
    redraw()

func expect(bit: int) -> void:
    if point.held(): return
    model.prediction = bit
    redraw()

func keep_reading() -> void:
    if point.held(): return
    model.keep()
    redraw()

func redraw() -> void:
    var outcomes := model.bits()
    for i in outcomes.size():
        cells[i].material_override.albedo_color = Color("50dbef") if outcomes[i]==1 else Color("17232e")
        marks[i].visible = outcomes[i] != model.prediction
    point_home = Vector3(-1.08,LOW+model.p*TRAVEL,0.22)
    if not point.held(): point.position = point_home
    var r := model.reading()
    readout.text = "p(1) %.2f / guess %d\nH %.3f bits/symbol / expected error %.1f%%\nObserved %d / %d (%.1f%%)" % [
        r.p,r.prediction,r.source_h,100.0*r.expected_error,r.mistakes,r.count,100.0*r.mistakes/r.count]
    if model.kept.is_empty():
        readout.text += "\nKEEP a reading; amber marks the mistakes"
    else:
        var k := model.kept
        readout.text += "\nKept p %.2f / guess %d / H %.3f\nKept mistakes %d / %d" % [k.p,k.prediction,k.source_h,k.mistakes,k.count]
