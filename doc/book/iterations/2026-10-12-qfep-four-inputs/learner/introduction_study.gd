extends "bench.gd"
const Balance = preload("balance.gd")
const NAMES := ["F", "E", "LAMBDA", "PHI"]
const COLOURS := [Color("50bfff"), Color("ffa451"), Color("ed6472"), Color("be8bee")]
const LOW := 1.18
const TRAVEL := 0.48
var model := Balance.new()
var selected := 0

func _ready() -> void:
    start("FOUR INPUTS / ONE RESULT", ["TERM", "KEEP", "PAIR A", "PAIR B", "ZERO L"],
        [next_term, keep_reading, pair_a, pair_b, zero_lambda])
    readout.font_size = 32
    redraw()

func _process(_delta: float) -> void:
    if point.held():
        var local_hand := to_local(point.global_position)
        var value := clampf((local_hand.y - LOW) / TRAVEL, 0.0, 1.0)
        if not is_equal_approx(value, model.values[selected]):
            model.set_term(selected, value)
            redraw()

func next_term() -> void:
    if point.held(): return
    selected = (selected + 1) % 4
    redraw()

func keep_reading() -> void:
    if point.held(): return
    model.keep()
    redraw()

func pair_a() -> void:
    if point.held(): return
    model.values = [0.4, 0.2, 0.5, 0.5]
    redraw()

func pair_b() -> void:
    if point.held(): return
    model.values = [0.6, 0.6, 0.5, 0.5]
    redraw()

func zero_lambda() -> void:
    if point.held(): return
    model.set_term(2, 0.0)
    redraw()

func redraw() -> void:
    clear_drawing()
    for i in 4:
        var x := (i - 1.5) * 0.55
        var height: float = model.values[i] * TRAVEL
        block(drawing, Vector3(x, LOW+TRAVEL/2, -0.06),
            Vector3(0.018, TRAVEL, 0.018), Color("526071"))
        block(drawing, Vector3(x, LOW+height/2, 0),
            Vector3(0.13, maxf(height, 0.004), 0.08), COLOURS[i])
        label(drawing, "%s %.2f" % [NAMES[i], model.values[i]], Vector3(x, 1.06, 0.1), 18)
        if not model.kept.is_empty():
            block(drawing, Vector3(x, LOW+model.kept[i]*TRAVEL, 0.08),
                Vector3(0.21, 0.012, 0.02), Color("f1eadb"))
    point_home = Vector3((selected-1.5)*0.55, LOW+model.values[selected]*TRAVEL, 0.22)
    if not point.held(): point.position = point_home
    var reading := "%s: lift sphere 0..1 / fixed change 0.30\nF - L*E + PHI*0.30 = %.3f" % [NAMES[selected], model.total(model.values)]
    if model.kept.is_empty():
        reading += "\nKEEP preserves the four inputs"
    else:
        var kept_total: float = model.total(model.kept)
        var difference: float = model.total(model.values) - kept_total
        if absf(difference) < 0.0005: difference = 0.0
        reading += "\nKept %.3f / difference %+.3f" % [kept_total, difference]
    readout.text = reading
