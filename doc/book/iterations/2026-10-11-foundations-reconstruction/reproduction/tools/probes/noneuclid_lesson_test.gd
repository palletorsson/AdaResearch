extends SceneTree
const BASE := "res://doc/book/iterations/2026-10-11-noneuclid-what-counts-as-straight/author/printed/"
var checks: Array = []
var failed := 0

func check(word: String, value: bool) -> void:
    checks.append({"name": word, "passed": value})
    if not value: failed += 1
    print("SURFACE ", "PASS " if value else "FAIL ", word)

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    var model = load(BASE + "surface_triangle.gd").new()
    check("starts with Euclid pairs and flat sum", model.points.size() == 3 and not model.spherical and absf(model.measure().sum - 180) < 0.0001)
    model.points.assign([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])
    var flat = model.measure()
    check("flat right triangle oracle", absf(flat.angles[0] - 90) < 0.0001 and absf(flat.angles[1] - 45) < 0.0001 and absf(flat.angles[2] - 45) < 0.0001)
    var saved = model.points.duplicate()
    model.spherical = true
    var curved = model.measure()
    check("sphere independent right-isosceles oracle", absf(curved.angles[0] - 90) < 0.0001 and absf(curved.angles[1] - 54.7356103172) < 0.0001 and absf(curved.sum - 199.4712206345) < 0.0002)
    check("mode keeps source pairs", model.points == saved)
    var u: Vector3 = model.tangent(Vector3.UP, Vector3.RIGHT)
    var v: Vector3 = model.tangent(Vector3.UP, Vector3.BACK)
    check("sphere octant corner is ninety", absf(u.dot(v)) < 0.0001 and u.is_equal_approx(Vector3.RIGHT) and v.is_equal_approx(Vector3.BACK))
    var samples = model.edge(1, 24)
    var a: Vector3 = model.corner(model.points[1])
    var b: Vector3 = model.corner(model.points[2])
    var correct := true
    for p in samples: correct = correct and absf(p.length() - 1) < 0.0001 and absf(p.dot(a.cross(b))) < 0.0001
    check("edge on unit sphere and centre plane", correct)
    check("edge endpoint and sample count", samples.size() == 25 and samples[0].is_equal_approx(a) and samples[-1].is_equal_approx(b))
    var t: Vector3 = model.tangent(a,b)
    check("tangent is unit and normal perpendicular", absf(t.length()-1) < 0.0001 and absf(t.dot(a)) < 0.0001)
    var before = model.measure()
    check("one piece still has two exact endpoints", model.edge(1,1).size() == 2)
    check("sampling does not change measured angles", model.measure() == before)
    for i in range(3): model.points[i] *= 0.1
    check("smaller spherical triangle approaches flat sum", model.measure().sum > 180 and model.measure().sum < curved.sum)
    model.points.assign([Vector2.ZERO, Vector2.RIGHT, Vector2(2,0)])
    check("collinear chart is degenerate on sphere", not model.measure().valid)
    model.points.assign([Vector2.ZERO, Vector2.ZERO, Vector2.DOWN])
    check("coincident sphere corners refused", not model.measure().valid)
    model.reset()
    check("reset restores pairs keeps model", model.spherical and model.measure().valid)

    var host = load(BASE + "surface_study.gd").new()
    host.position = Vector3(3,0.4,-2)
    host.rotation = Vector3(0.1,0.7,-0.1)
    root.add_child(host)
    host.set_process(false)
    var ids: Array = []
    for point in host.points: ids.append(point.get_instance_id())
    check("full host initialized in plane", host.points.size() == 3 and host.edges.size() == 72 and host.plane.visible and not host.sphere.visible and host.face.mesh != null and host.readout.text.contains("PLANE"))
    saved = host.model.points.duplicate()
    host.get_node("Sphere").pressed.emit()
    check("sphere signal changes surfaces and calculation", host.model.spherical and host.sphere.visible and not host.plane.visible and host.face.mesh == null and host.model.measure().sum > 180)
    var same: bool = host.model.points == saved
    for i in range(3): same = same and host.points[i].get_instance_id() == ids[i]
    check("same points and records survive model switch", same)
    for i in range(8): await physics_frame
    check("sphere bodies remain on displayed sphere", absf((host.points[1].position-host.CENTRE).length()-host.RADIUS) < 0.0001)
    check("sphere inverse recovers a chosen chart pair", host.record_hand(1, host.CENTRE + Vector3(0.4,1,-0.3) * 2) and host.model.points[1].distance_to(Vector2(0.4,-0.3)) < 0.0001)
    saved = host.model.points.duplicate()
    check("lower chart refused with record kept", not host.record_hand(1,host.CENTRE+Vector3(0,-1,1)) and host.model.points == saved)
    check("near-equator guard keeps record", not host.record_hand(1,host.CENTRE+Vector3(1,0.01,1)) and host.model.points == saved)
    host.record_hand(1,host.CENTRE+Vector3(3,1,-2))
    check("sphere chart bounded", host.model.points[1] == Vector2(1,-1))
    var hand := Node3D.new()
    root.add_child(hand)
    var point = host.points[2]
    point.on_desktop_grab(hand)
    for i in range(8):
        point.global_position = host.to_global(host.CENTRE+Vector3(-0.35,1,0.6))
        host._process(0)
        await physics_frame
    check("sustained hand converted in rotated local frame", host.model.points[2].distance_to(Vector2(-0.35,0.6)) < 0.0001)
    saved = host.model.points.duplicate()
    host.get_node("Plane").pressed.emit()
    host.get_node("Reset").pressed.emit()
    check("switch and reset refused while held", host.model.spherical and host.model.points == saved)
    point.on_desktop_drop(hand)
    for i in range(8): await physics_frame
    check("release returns to retained spherical position", point.position.distance_to(host.display(host.model.corner(host.model.points[2]))) < 0.0001)
    host.get_node("Reset").pressed.emit()
    check("reset keeps spherical mode", host.model.spherical and host.model.points == model.points)
    host.get_node("Plane").pressed.emit()
    check("return recovers flat face and sum", host.face.mesh != null and host.plane.visible and not host.sphere.visible and absf(host.model.measure().sum-180)<0.0001)
    host.model.points.assign([Vector2.ZERO,Vector2.RIGHT,Vector2(2,0)])
    host.redraw()
    check("degenerate flat face withheld", host.face.mesh == null and host.readout.text.contains("No triangle"))
    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_R
    host._unhandled_key_input(key)
    check("keyboard restores construction", host.face.mesh != null)
    for word: String in ["Plane","Sphere","Reset"]:
        var button: Node3D = host.get_node(word)
        check(word+" control above board and upward", button.position.y > 1.01 and button.basis.y.dot(Vector3.UP)>0.999)
    host.free()
    hand.free()
    FileAccess.open(BASE.get_base_dir()+"/../results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failed==0,"failures":failed,"checks":checks,"scope":"Author reconstruction from printed code; synthetic input, not physical XR."},"  "))
    quit(0 if failed==0 else 1)
