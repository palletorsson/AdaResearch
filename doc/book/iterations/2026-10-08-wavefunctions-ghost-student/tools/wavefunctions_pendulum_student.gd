extends SceneTree

var checks: Array = []
var failures: Array = []

func _initialize() -> void: run.call_deferred()

func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value: failures.append(title)
    print("[pendulum] ", "PASS " if value else "FAIL ", title)

func advance(lesson: Node3D, seconds: float, rate: int = 60) -> void:
    for i in int(round(seconds * rate)): lesson._physics_process(1.0/rate)
    lesson.draw_state()

func run() -> void:
    await process_frame
    var source := "res://doc/book/studies/wavefunctions-lineage/02_pendulum_record.gd"
    var report := "res://doc/book/iterations/2026-10-08-pendulum-a-record-of-return/student-test.json"
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--lesson="): source = argument.trim_prefix("--lesson=")
        if argument.begins_with("--report="): report = argument.trim_prefix("--report=")
    var Lesson = load(source)
    var lesson = Lesson.new()
    root.add_child(lesson)
    lesson.set_process(false); lesson.set_physics_process(false)
    check("complete program creates its cube", lesson.cube.mesh is BoxMesh and lesson.cube.is_inside_tree())
    check("cube retains the previous lesson's size", lesson.cube.scale.is_equal_approx(Vector3.ONE*0.4))
    check("readout initialised by ready", lesson.label.is_inside_tree() and not lesson.label.text.is_empty())
    check("bounded display allocated once", lesson.marks.size() == 120 and lesson.history.is_empty())
    check("initial cube is at a constrained radius", absf(lesson.cube.global_position.distance_to(lesson.pivot.global_position)-1.0)<0.00001)
    lesson._physics_process(1.0/60)
    check("gravity accelerates towards the hanging position", lesson.angular_velocity<0 and lesson.angle<PI/4)
    check("sub-interval update stores no observation", lesson.history.is_empty())
    lesson._physics_process(1.0/60)
    check("first observation waits for a physics tick", lesson.history.size()==1 and absf(lesson.history[0].time-2.0/60)<0.00001)
    var first = lesson.history[0]
    var stored: Vector3 = first.position
    var stamp: float = first.time
    check("record stores study coordinates rather than pivot offset", stored.is_equal_approx(lesson.to_local(lesson.cube.global_position)) and not stored.is_equal_approx(lesson.cube.position))
    advance(lesson,0.5)
    check("motion does not mutate saved positions", first.position.is_equal_approx(stored) and first.time==stamp)
    var expected: Vector3 = stored + Vector3(0,0,-(lesson.elapsed-stamp)*0.6)
    check("age has the predicted display depth", lesson.display_position(first).is_equal_approx(expected))
    for i in 30: lesson.display_position(first)
    check("redrawing never accumulates displacement in record", first.position.is_equal_approx(stored))
    check("display has one visible mark per observation", lesson.marks[0].visible and not lesson.marks[lesson.history.size()].visible)
    check("rendered first mark matches the computed position", lesson.marks[0].position.is_equal_approx(expected))
    var gaps: Array = []
    for i in range(1,lesson.history.size()): gaps.append(lesson.history[i].time-lesson.history[i-1].time)
    check("25 ms request actually includes 1-tick gaps", absf(gaps.min()-1.0/60)<0.00001)
    check("25 ms request actually includes 2-tick gaps", absf(gaps.max()-2.0/60)<0.00001)
    var before_angle: float = lesson.angle
    var before_speed: float = lesson.angular_velocity
    var before_time: float = lesson.elapsed
    lesson.set_sampling(0.2)
    check("sampler switch clears record and remainder", lesson.history.is_empty() and lesson.sample_clock==0.0)
    check("sampler switch preserves motion and clock", lesson.angle==before_angle and lesson.angular_velocity==before_speed and lesson.elapsed==before_time)
    check("sampler switch hides old display", not lesson.marks[0].visible)
    lesson.reset_experiment()
    check("reset restores initial state and local clock", lesson.angle==lesson.initial_angle and lesson.angular_velocity==0.0 and lesson.elapsed==0.0 and lesson.history.is_empty())
    lesson.set_sampling(0.025)
    advance(lesson,8.0)
    check("fine history obeys count bound", lesson.history.size()==120)
    var fine_span: float = lesson.history.back().time-lesson.history[0].time
    check("fine count bound retains about three seconds", fine_span>2.9 and fine_span<3.1)
    check("all records stay in the swing plane", lesson.history.all(func(s): return absf(s.position.z)<0.00001))
    var second = Lesson.new()
    second.sample_interval=0.2
    second.position=Vector3(3,0,-5)
    second.rotation.y=PI/2
    root.add_child(second); second.set_process(false);second.set_physics_process(false)
    advance(second,8.0)
    check("recording rate leaves motion unchanged", absf(second.angle-lesson.angle)<0.00001 and absf(second.angular_velocity-lesson.angular_velocity)<0.00001)
    check("coarse history has about thirty marks", second.history.size()>=29 and second.history.size()<=31)
    var coarse_span: float = second.history.back().time-second.history[0].time
    check("coarse age bound keeps more duration", coarse_span>5.7 and coarse_span<=6.00001 and coarse_span>fine_span)
    check("all retained records obey age limit", second.history.all(func(s): return second.elapsed-s.time<=6.00001))
    check("translated rotated study still records its local plane", second.history.all(func(s): return absf(s.position.z)<0.00001))
    var saved_angle: float = second.angle
    var count: int = second.history.size()
    var old_depth: float = second.marks[0].position.z
    second.trail_speed=0.3; second.draw_state()
    check("half drawing speed halves the depth", absf(second.marks[0].position.z-old_depth*0.5)<0.00001)
    check("drawing change retains motion and record", second.angle==saved_angle and second.history.size()==count)
    second.max_samples=20;second.reset_experiment();second.set_sampling(0.1)
    advance(second,8.0)
    check("independent 20-entry variation hits count limit", second.history.size()==20 and second.history.back().time-second.history[0].time<2.1)
    second.reset_experiment()
    second.set_sampling(0.025)
    second.gravity=0.0
    second._physics_process(0.2)
    check("late update saves one real observation, not invented backlog", second.history.size()==1 and absf(second.history[0].time-0.2)<0.00001)
    check("zero velocity and gravity retain angle", second.angle==second.initial_angle)
    second.angular_velocity=0.4
    advance(second,0.5)
    check("injected velocity changes the future", absf(second.angle-second.initial_angle-0.2)<0.00001)
    var physics_clock: float = lesson.elapsed
    for i in 90: lesson._process(1.0/90)
    check("render frames do not advance physics time", lesson.elapsed==physics_clock)
    var phases: Array = []
    for rate in [60,120]:
        lesson.reset_experiment();advance(lesson,2.0,rate);phases.append(lesson.angle)
    check("smaller time steps give a close two-second solution", absf(phases[0]-phases[1])<0.02)
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"engine":Engine.get_version_info(),"scope":"Teacher-authored native checks of the exact printed program; not independent reconstruction or headset validation."},"  "))
    lesson.free();second.free()
    quit(0 if failures.is_empty() else 1)
