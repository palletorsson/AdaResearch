extends SceneTree
var checks: Array[Dictionary] = []
var failed := false

func _initialize() -> void:
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"name": label, "passed": passed})
    failed = failed or not passed
    if not passed:
        push_error(label)

func run() -> void:
    var source: PackedScene = load("res://base.tscn")
    var base: Node3D = source.instantiate()
    root.add_child(base)
    await physics_frame
    await physics_frame
    check("The greeting is present at startup", base.get_node("Welcome").text == "Hello, world.")
    check("The supplied camera is current", base.get_node("Camera3D").is_current())
    var world: PhysicsDirectSpaceState3D = base.get_world_3d().direct_space_state
    var hit := world.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 1, 0), Vector3(0, -1, 0)))
    check("The supplied floor has a physical boundary", not hit.is_empty())
    base.get_node("Welcome").text = "This is my first change."
    var copy := PackedScene.new()
    check("The changed scene can be packed", copy.pack(base) == OK)
    var folder: String = get_script().resource_path.get_base_dir()
    var save_path: String = folder.path_join("edited-base-test.tscn")
    check("The changed scene can be saved", ResourceSaver.save(copy, save_path) == OK)
    base.queue_free()
    await process_frame
    var reloaded: PackedScene = load(save_path)
    var changed: Node3D = reloaded.instantiate()
    root.add_child(changed)
    await process_frame
    check("The saved change survives reopening", changed.get_node("Welcome").text == "This is my first change.")
    changed.queue_free()
    await process_frame
    var report := {"passed": not failed, "checks": checks, "scope": "Native startup, camera and floor, edit/save/reload. No headset or beginner trial."}
    var f := FileAccess.open(folder.path_join("day-zero-native.json"), FileAccess.WRITE)
    f.store_string(JSON.stringify(report, "  ") + "\n")
    f.close()
    print("DAY_ZERO: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
