extends SceneTree

var checks: Array = []
var failures: Array = []
var measurements: Dictionary = {}

func _initialize() -> void: run.call_deferred()

func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value: failures.append(title)
    print("[wave-student] ", "PASS " if value else "FAIL ", title)

func run() -> void:
    await process_frame
    var source := "res://doc/book/studies/wavefunctions-lineage/01_return.gd"
    var report := "res://doc/book/iterations/2026-10-08-wavefunctions-what-returns/student-test.json"
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--lesson="): source = argument.trim_prefix("--lesson=")
        if argument.begins_with("--report="): report = argument.trim_prefix("--report=")
    var Lesson = load(source)
    var lesson = Lesson.new()
    root.add_child(lesson)
    lesson.set_physics_process(false)
    check("ready creates its label", lesson.label != null and lesson.label.is_inside_tree())
    check("ready creates its sphere and collision", lesson.bob.get_child_count() >= 2)
    check("point retains XR pickable behavior", lesson.bob.has_signal("picked_up") and lesson.bob.has_method("pick_up"))
    check("point stays kinematic under the angular model", lesson.bob.freeze)
    check("point retains the Forces material", lesson.bob.get_child(0).material_override.albedo_color.is_equal_approx(Color("17191c")))
    check("ready places bob at the declared radius", absf(lesson.bob.position.distance_to(lesson.PIVOT) - lesson.LENGTH) < 0.00001)

    lesson.angle = 0.0; lesson.speed = 1.0
    lesson.advance(1.0/60.0)
    var forward: float = lesson.angle
    lesson.angle = 0.0; lesson.speed = -1.0
    lesson.advance(1.0/60.0)
    check("same position with opposite velocities separates", forward > 0 and lesson.angle < 0)
    check("symmetric states keep opposite angles", absf(forward + lesson.angle) < 0.00001)
    lesson.angle = 0.3; lesson.speed = 0.0
    lesson.advance(1.0/60.0)
    check("positive turning point accelerates toward centre", lesson.speed < 0 and lesson.angle < 0.3)
    lesson.angle = -0.3; lesson.speed = 0.0
    lesson.advance(1.0/60.0)
    check("negative turning point accelerates toward centre", lesson.speed > 0 and lesson.angle > -0.3)
    lesson.angle = 0.0; lesson.speed = 0.0
    for i in 300: lesson.advance(1.0/60.0)
    check("rest stays at rest", is_zero_approx(lesson.angle) and is_zero_approx(lesson.speed))

    lesson.angle = 0.3; lesson.speed = 0; lesson.crossings = 0
    var signs: Array = []
    for i in 360:
        var before: int = lesson.crossings
        lesson.advance(1.0/60.0)
        if lesson.crossings != before: signs.append(signf(lesson.speed))
        lesson.draw_state()
    check("six-second release makes repeated crossings", signs.size() >= 6)
    var alternating := true
    for i in range(1,signs.size()): alternating = alternating and signs[i] == -signs[i-1]
    check("crossings alternate velocity sign", alternating)
    check("constrained bob keeps its radius after motion", absf(lesson.bob.position.distance_to(lesson.PIVOT) - lesson.LENGTH) < 0.00001)
    check("readout exposes signed speed", "speed" in lesson.label.text and "rad/s" in lesson.label.text)
    measurements.crossing_signs = signs

    lesson.bob.picked_up.emit(lesson.bob)
    check("pickup signal begins hold", lesson.held)
    lesson.bob.position = lesson.PIVOT + Vector3(0.3,-0.6,0)
    var before: int = lesson.crossings
    for i in 8: lesson._physics_process(1.0/60.0)
    check("held position supplies angle", absf(lesson.angle - atan2(0.3,0.6)) < 0.00001)
    check("holding does not invent crossings", lesson.crossings == before)
    check("release sample window stays bounded", lesson.velocities.size() == 5)
    lesson.bob.dropped.emit(lesson.bob)
    check("still hand releases with zero angular speed", not lesson.held and is_zero_approx(lesson.speed))
    check("drop clears the hand sample record", lesson.velocities.is_empty())

    lesson.angle = 0.0
    lesson.begin_hold(lesson.bob)
    lesson.velocities.append(Vector3(lesson.LENGTH,0,0))
    lesson.end_hold(lesson.bob)
    check("tangential metres per second become radians per second", absf(lesson.speed - 1.0) < 0.00001)
    lesson.begin_hold(lesson.bob)
    lesson.velocities.append(Vector3(0,0,2))
    lesson.end_hold(lesson.bob)
    check("out-of-plane gesture contributes no swing", is_zero_approx(lesson.speed))
    lesson.rotation.y = PI/2
    lesson.begin_hold(lesson.bob)
    lesson.velocities.append(lesson.global_basis * Vector3(lesson.LENGTH,0,0))
    lesson.end_hold(lesson.bob)
    check("rotated study converts world hand velocity", absf(lesson.speed - 1) < 0.00001)
    lesson.rotation = Vector3.ZERO
    lesson.on_desktop_grab(null); lesson.on_desktop_drop(null)
    check("desktop begin/end use the same state", not lesson.held and is_zero_approx(lesson.speed))

    var amplitudes: Array = []
    for hz in [60,90]:
        lesson.angle = 0.3; lesson.speed = 0.0
        var peak := 0.0
        for i in 6*hz:
            lesson.advance(1.0/hz)
            if i >= 4*hz: peak = maxf(peak, absf(lesson.angle))
        amplitudes.append(peak)
    check("per-tick damping changes with physics tick rate", amplitudes[1] < amplitudes[0]*0.8)
    measurements.last_two_second_peak_by_physics_hz = {"60":amplitudes[0],"90":amplitudes[1]}

    var second = Lesson.new()
    root.add_child(second); second.set_physics_process(false)
    lesson.angle = 0.0; lesson.speed = 0.8; lesson.crossings = 0
    second.angle = 0.0; second.speed = -0.8; second.crossings = 0
    var unchanged: float = second.angle
    lesson.advance(1.0/60.0)
    check("independent instance has independent state", second.angle == unchanged)
    second.advance(1.0/60.0)
    check("two-instance transfer preserves opposite motion", absf(lesson.angle + second.angle) < 0.00001)
    var file := FileAccess.open(report, FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"source":source,"checks":checks,"failures":failures,"measurements":measurements,"engine":Engine.get_version_info(),"scope":"Published study in native Godot; no tracked headset or human learner claim."},"  "))
    file.close()
    lesson.free(); second.free()
    quit(0 if failures.is_empty() else 1)
