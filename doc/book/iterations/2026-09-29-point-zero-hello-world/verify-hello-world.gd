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
    var study: Node3D = load("res://hello_world.tscn").instantiate()
    study.set_script(lesson)
    root.add_child(study)
    return study

func run() -> void:
    var folder: String = get_script().resource_path.get_base_dir()
    var code: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("lesson-code.json")))
    for i in range(3):
        await process_frame
    var before_arrival: int = Engine.get_process_frames()
    check("Engine processing predates this study instance", before_arrival > 0)
    check("Project selects the supplied hello-world scene", ProjectSettings.get_setting("application/run/main_scene") == "res://hello_world.tscn")

    var greeting: Node3D = study_with(code.greeting)
    check("Ready assigns the greeting to the supplied display", greeting.get_node("Greeting").text == "Hello, world.")
    check("The inherited greeting is hidden", not greeting.get_node("Welcome").visible)
    check("Greeting-only lesson leaves the number empty", greeting.get_node("Counter").text == "")
    check("Base camera remains current", greeting.get_node("Camera3D").current)
    greeting.get_node("Greeting").text = "Changed after ready."
    for i in range(3):
        await process_frame
    check("Ready does not overwrite the display on later frames", greeting.get_node("Greeting").text == "Changed after ready.")
    greeting.free()

    var revised: Node3D = study_with(String(code.greeting).replace("Hello, world.", "We are here."))
    check("An authored greeting reaches the display", revised.get_node("Greeting").text == "We are here.")
    revised.free()

    var counter: Node3D = study_with(code.counter)
    check("A fresh node starts its own count at zero", counter.get("count") == 0)
    for i in range(4):
        await process_frame
    var live_count: int = counter.get("count")
    check("Real process callbacks increase the retained count", live_count > 0)
    check("The supplied display reports the same count", counter.get_node("Counter").text == str(live_count))
    check("The engine total has an earlier starting reference", Engine.get_process_frames() > live_count)
    check("Counting preserves the greeting", counter.get_node("Greeting").text == "Hello, world.")
    counter.set_process(false)
    counter.call("_process", 0.001)
    counter.call("_process", 0.5)
    check("Two manual calls add two despite different time intervals", counter.get("count") == live_count + 2)
    check("Text follows both retained updates", counter.get_node("Counter").text == str(live_count + 2))
    counter.free()

    var once: Node3D = study_with(code.once)
    check("Moving the update into ready counts once", once.get("count") == 1 and once.get_node("Counter").text == "1")
    var before_wait: int = Engine.get_process_frames()
    for i in range(4):
        await process_frame
    check("The engine continues while the lesson count stays one", Engine.get_process_frames() > before_wait and once.get("count") == 1 and once.get_node("Counter").text == "1")
    once.free()

    var twice: Node3D = study_with(String(code.counter).replace("count += 1", "count += 2"))
    twice.set_process(false)
    twice.call("_process", 0.016)
    check("Changing the increment produces two", twice.get("count") == 2 and twice.get_node("Counter").text == "2")
    twice.call("_process", 0.016)
    check("The next call continues from two to four", twice.get("count") == 4 and twice.get_node("Counter").text == "4")
    twice.free()

    var fresh: Node3D = load("res://hello_world.tscn").instantiate()
    root.add_child(fresh)
    check("The downloaded scene starts a fresh greeting and count", fresh.get("count") == 0 and fresh.get_node("Greeting").text == "Hello, world.")
    for i in range(2):
        await process_frame
    check("The downloaded complete script runs its counter", fresh.get("count") > 0)
    fresh.free()

    var report := {"passed": failures == 0, "engine": Engine.get_version_info().string, "checks": checks, "scope": "Actual tutorial code, lifecycle, live processing and lesson variations. No rendered-browser, learner or headset trial."}
    var file := FileAccess.open(folder.path_join("native-verification.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "
")
    file.close()
    print("HELLO WORLD: ", checks.size(), " checks; passed: ", failures == 0)
    quit(0 if failures == 0 else 1)
