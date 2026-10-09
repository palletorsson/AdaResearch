extends SceneTree

var checks: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
    run.call_deferred()

func check(label: String, ok: bool) -> void:
    checks.append({"name": label, "passed": ok})
    if not ok:
        failures += 1
        push_error(label)

func study_with(source: String) -> Node3D:
    var lesson := GDScript.new()
    lesson.source_code = source
    check("Actual lesson block compiles", lesson.reload() == OK)
    var study := Node3D.new()
    check("Test starts on a bare Node3D with no scene children", study.get_child_count() == 0)
    study.set_script(lesson)
    root.add_child(study)
    var display: Label3D = study.get("display")
    check("Script creates exactly one Label3D child", study.get_child_count() == 1 and display.get_parent() == study)
    check("Display height is relative to its parent", display.position == Vector3(0, 1.5, 0))
    return study

func run() -> void:
    var folder: String = get_script().resource_path.get_base_dir()
    var code: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("lesson-code.json")))
    for i in range(3):
        await process_frame
    check("Engine processing predates the lesson", Engine.get_process_frames() > 0)

    var greeting := study_with(code.greeting)
    var greeting_display: Label3D = greeting.get("display")
    check("Ready sets text on the code-created display", greeting_display.text == "Hello, world.")
    greeting_display.text = "Changed after ready."
    for i in range(3):
        await process_frame
    check("Ready does not reset the greeting on later frames", greeting_display.text == "Changed after ready.")
    greeting.free()

    var changed := study_with(String(code.greeting).replace("Hello, world.", "We are here."))
    check("Editing the greeting changes its display", changed.get("display").text == "We are here.")
    changed.free()

    var counter := study_with(code.counter)
    var counter_display: Label3D = counter.get("display")
    check("Ready displays the initial count", counter.get("count") == 0 and counter_display.text == "0")
    for i in range(4):
        await process_frame
    var live_count: int = counter.get("count")
    check("Real process calls retain and increase the count", live_count > 0 and counter_display.text == str(live_count))
    check("The engine count has an earlier beginning", Engine.get_process_frames() > live_count)
    counter.set_process(false)
    counter.call("_process", 0.001)
    counter.call("_process", 0.5)
    check("Two calls add two despite different intervals", counter.get("count") == live_count + 2 and counter_display.text == str(live_count + 2))
    check("Repeated processing does not create more displays", counter.get_child_count() == 1)
    counter.free()

    var once := study_with(code.once)
    check("Counting in ready displays one", once.get("count") == 1 and once.get("display").text == "1")
    for i in range(4):
        await process_frame
    check("The count stays one while the engine runs", once.get("count") == 1 and once.get("display").text == "1")
    once.free()

    var twice := study_with(String(code.counter).replace("count += 1", "count += 2"))
    twice.set_process(false)
    twice.call("_process", 0.016)
    check("Changed increment gives two", twice.get("count") == 2 and twice.get("display").text == "2")
    twice.call("_process", 0.016)
    check("Next call gives four", twice.get("count") == 4 and twice.get("display").text == "4")
    twice.free()

    var fresh: Node3D = load("res://hello_world.tscn").instantiate()
    check("Prepared room has no scene-authored label", fresh.find_children("*", "Label3D", true, false).is_empty())
    root.add_child(fresh)
    var display: Label3D = fresh.get("display")
    check("Downloaded script creates its own display", display.get_parent() == fresh and display.text == "0")
    check("Prepared camera is active", fresh.get_node("Camera3D").current)
    for i in range(3):
        await process_frame
    check("Downloaded counter runs", fresh.get("count") > 0 and display.text == str(fresh.get("count")))
    fresh.free()

    var report := {"passed": failures == 0, "engine": Engine.get_version_info().string, "checks": checks, "scope": "All lesson blocks on a bare Node3D without any scene children, lifecycle and increment variations, plus the downloadable prepared study. No beginner or headset trial."}
    var file := FileAccess.open(folder.path_join("native-verification.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "\n")
    file.close()
    print("HELLO WORLD: ", checks.size(), " checks; passed: ", failures == 0)
    quit(0 if failures == 0 else 1)
