extends SceneTree
const BASE := "res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/author/printed/"
var checks: Array = []
var failed := 0

func check(name: String, value: bool) -> void:
    checks.append({"name": name, "passed": value})
    if not value: failed += 1
    print("EUCLID ", "PASS " if value else "FAIL ", name)

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    var model = load(BASE + "triangle_record.gd").new()
    check("initial three angles measured", model.measure().valid and absf(model.measure().sum - 180) < 0.001)
    model.points.assign([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])
    var right: Dictionary = model.measure()
    check("right angle plus two forty-fives", absf(right.angles[0] - 90) < 0.001 and absf(right.angles[1] - 45) < 0.001 and absf(right.angles[2] - 45) < 0.001)
    check("right triangle area", is_equal_approx(right.area, 0.5))
    var ends: Array = model.parallel_ends()
    check("guide centred on C", ((ends[0] + ends[1]) * 0.5).is_equal_approx(model.points[2]))
    check("guide same base direction", absf((ends[1] - ends[0]).cross(model.points[1] - model.points[0])) < 0.001)
    model.points.assign([Vector2(-0.2, -0.4), Vector2(0.9, 0.1), Vector2(0.3, 0.8)])
    var original: Dictionary = model.measure()
    for i in range(3): model.points[i] = model.points[i].rotated(0.41) * 2 + Vector2(7, -3)
    var moved: Dictionary = model.measure()
    check("translation rotation uniform scale retain angles", absf(moved.angles[0] - original.angles[0]) < 0.001 and absf(moved.angles[1] - original.angles[1]) < 0.001 and absf(moved.angles[2] - original.angles[2]) < 0.001)
    check("doubling lengths quadruples area", absf(moved.area - original.area * 4) < 0.0001)
    model.points.reverse()
    check("reverse winding retains sum", absf(model.measure().sum - 180) < 0.001)
    model.points.assign([Vector2.ZERO, Vector2.RIGHT, Vector2(2, 0)])
    check("collinear reading withheld", not model.measure().valid)
    model.points.assign([Vector2.ZERO, Vector2.ZERO, Vector2.UP])
    check("coincident base has no guide", not model.measure().valid and model.parallel_ends().is_empty())
    model.points.assign([Vector2.ZERO, Vector2.RIGHT, Vector2(0.5, 0.000001)])
    check("near collinear tolerance stated", not model.measure().valid)
    model.reset()
    check("valid construction recovers", model.measure().valid)

    var host = load(BASE + "euclid_study.gd").new()
    host.position = Vector3(4, 0.3, -2)
    host.rotation.y = 0.7
    root.add_child(host)
    host.set_process(false)
    check("complete host initialized", host.points.size() == 3 and host.edges.size() == 3 and host.labels.size() == 3 and host.face.mesh != null)
    check("readout initialized", host.readout.text.contains("Measured sum"))
    var positions = host.model.points.duplicate()
    host.get_node("Guide").pressed.emit()
    check("real guide signal changes only display", not host.guide_on and not host.guide.visible and positions == host.model.points)
    var pointer := Node3D.new()
    root.add_child(pointer)
    var point = host.points[2]
    point.on_desktop_grab(pointer)
    point.reparent(pointer, true)
    point.global_position = host.to_global(Vector3(0.35, 2.3, -0.45))
    host._process(0)
    check("held point converted from world to local plane", host.model.points[2].distance_to(Vector2(0.35, -0.45)) < 0.0001)
    positions = host.model.points.duplicate()
    host.get_node("Reset").pressed.emit()
    check("reset blocked while holding", positions == host.model.points)
    point.action_pressed.emit(pointer)
    check("held action toggles guide", host.guide_on and host.guide.visible)
    point.global_position = host.to_global(Vector3(3, 2.3, -3))
    host._process(0)
    check("hand workspace bounds", host.model.points[2] == Vector2(1, -1))
    point.reparent(host, true)
    point.on_desktop_drop(pointer)
    for i in range(8): await physics_frame
    check("released point remains at recorded local position", point.position.distance_to(host.place(host.model.points[2])) < 0.001)
    host.get_node("Reset").pressed.emit()
    check("reset restores positions keeps guide setting", host.model.points == model.points and host.guide_on)
    host.model.points.assign([Vector2.ZERO, Vector2.RIGHT, Vector2(2, 0)])
    host.redraw()
    check("degenerate host has no face or reading", host.face.mesh == null and not host.guide.visible and host.readout.text.contains("No triangle"))
    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_R
    host._unhandled_key_input(key)
    check("keyboard reset restores face", host.face.mesh != null)
    host.free()
    pointer.free()
    var out := "res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/author/results.json"
    FileAccess.open(out, FileAccess.WRITE).store_string(JSON.stringify({"passed": failed == 0, "checks": checks, "failures": failed, "scope": "Author-informed exact-print reconstruction; synthetic input, not headset validation"}, "  "))
    quit(0 if failed == 0 else 1)
