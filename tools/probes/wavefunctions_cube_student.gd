extends SceneTree

var checks: Array = []
var failures: Array = []

func _initialize() -> void: run.call_deferred()

func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value: failures.append(title)
    print("[wave-cube] ", "PASS " if value else "FAIL ", title)

func run() -> void:
    await process_frame
    var source := "res://doc/book/studies/wavefunctions-lineage/01_cube_return.gd"
    var report := "res://doc/book/iterations/2026-10-08-wavefunctions-what-returns/student-test.json"
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--lesson="): source = argument.trim_prefix("--lesson=")
        if argument.begins_with("--report="): report = argument.trim_prefix("--report=")
    var Lesson = load(source)
    var lesson = Lesson.new()
    root.add_child(lesson); lesson.set_process(false)
    check("ready creates the cube mesh", lesson.cube.mesh is BoxMesh)
    check("ready creates the label", lesson.label.is_inside_tree() and not lesson.label.text.is_empty())
    check("cube retains whole-object scale", lesson.cube.scale.is_equal_approx(Vector3.ONE*0.4))
    var heights := [1.3,1.7,1.3,0.9,1.3]
    for i in 5:
        lesson.elapsed = i*0.5; lesson.draw_state()
        check("predicted height at " + str(i*0.5) + " seconds", absf(lesson.cube.position.y-heights[i]) < 0.00001)
    lesson.elapsed = 0.5; lesson.draw_state()
    var once: float = lesson.cube.position.y
    for i in 100: lesson.draw_state()
    check("same time never accumulates height", absf(lesson.cube.position.y-once)<0.00001)
    check("formula changes only the vertical coordinate", lesson.cube.position.x==lesson.centre.x and lesson.cube.position.z==lesson.centre.z)
    lesson.amplitude = 0.8
    check("double amplitude doubles the upward extent", absf(lesson.height_at(0.5)-lesson.centre.y-0.8)<0.00001)
    check("amplitude leaves the period unchanged", absf(lesson.height_at(2)-lesson.centre.y)<0.00001)
    lesson.amplitude = 0.4; lesson.frequency = 1.0
    check("double frequency reaches the top in a quarter second", absf(lesson.height_at(0.25)-1.7)<0.00001)
    check("double frequency completes a cycle in one second", absf(lesson.height_at(1)-lesson.centre.y)<0.00001)
    lesson.frequency = 0.5; lesson.phase = PI
    check("half-cycle phase retains the middle start", absf(lesson.height_at(0)-lesson.centre.y)<0.00001)
    check("half-cycle phase reverses the first direction", lesson.height_at(0.01)<lesson.centre.y)
    lesson.phase = PI/2
    check("quarter-cycle phase begins at the top", absf(lesson.height_at(0)-1.7)<0.00001)
    lesson.frequency = 0
    check("zero frequency retains the selected phase height", absf(lesson.height_at(5)-1.7)<0.00001)
    lesson.amplitude = 0
    check("zero amplitude holds the centre", absf(lesson.height_at(3)-lesson.centre.y)<0.00001)
    lesson.amplitude = 0.4; lesson.frequency = 0.5; lesson.phase = 0
    var rates: Array = []
    for fps in [30,90]:
        lesson.elapsed=0
        for i in fps*3: lesson._process(1.0/fps)
        rates.append(lesson.cube.position.y)
    check("equal elapsed seconds agree across render rates", absf(rates[0]-rates[1])<0.00001)
    var second = Lesson.new()
    second.phase = PI; second.position.x = 1.5
    root.add_child(second); second.set_process(false)
    lesson.elapsed = 0.5; lesson.draw_state()
    second.elapsed = 0.5; second.draw_state()
    check("two cubes can be at opposite extremes", absf(lesson.cube.position.y-1.7)<0.00001 and absf(second.cube.position.y-0.9)<0.00001)
    lesson._process(0.1)
    check("instances keep independent clocks", absf(second.elapsed-0.5)<0.00001)
    second.frequency=1.0
    check("instances keep independent parameters", is_equal_approx(lesson.frequency,0.5))
    var file := FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"source":source,"checks":checks,"failures":failures,"engine":Engine.get_version_info(),"scope":"Exact published cube code; teacher-authored native checks, not human or headset evidence."},"  "))
    file.close()
    lesson.free();second.free()
    quit(0 if failures.is_empty() else 1)
