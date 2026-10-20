extends "bench.gd"
const Membership = preload("membership.gd")
var model := Membership.new()
var restricted := false
var size := 4
var assumed := false
var was_held := false
var held_x := 0.0
var result: Dictionary = {}

func _ready() -> void:
    start("RUSSELL / TEST THE DEMAND", ["OUT", "IN", "DOMAIN", "SIZE"],
        [choose.bind(false), choose.bind(true), domain, next_size])
    refresh()

func choose(value: bool) -> void:
    if point.held(): return
    assumed = value
    refresh()

func domain() -> void:
    if point.held(): return
    restricted = not restricted
    refresh()

func next_size() -> void:
    if point.held(): return
    size = size % 6 + 1
    refresh()

func _process(_delta: float) -> void:
    if point.held():
        was_held = true
        held_x = to_local(point.global_position).x
    elif was_held:
        was_held = false
        choose(held_x >= 0)

func refresh() -> void:
    result = model.test(assumed, restricted, size)
    point_home = Vector3(0.65 if assumed else -0.65, 1.23, 0.25)
    clear_drawing()
    for i in 2:
        var x := -0.65 if i==0 else 0.65
        block(drawing, Vector3(x, 1.01, 0.25), Vector3(0.75, 0.04, 0.42), Color("30465b"))
        label(drawing, "OUT" if i==0 else "IN", Vector3(x, 1.08, 0.48))
    if restricted:
        for x in result.members:
            var at := Vector3((x-(size-1)*0.5)*0.3, 1.04, -0.38)
            block(drawing, at, Vector3.ONE*0.12, Color("99bbc7"))
            label(drawing, str(x), at+Vector3.UP*0.18)
    readout.text = "%s\nChoose %s; rule requires %s. %s\n%s" % [
        "WITHIN U = %s"%str(result.members) if restricted else "UNRESTRICTED: p = not p",
        "IN" if assumed else "OUT", "IN" if result.required else "OUT",
        "AGREES" if result.agrees else "DISAGREES",
        "Result = %d; it is outside U."%size if restricted else "Test both Booleans. No fixed answer."]
