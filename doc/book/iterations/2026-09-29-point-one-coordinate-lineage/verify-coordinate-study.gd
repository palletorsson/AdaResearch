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
    var script := GDScript.new()
    script.source_code = source
    check("Tutorial code compiles", script.reload() == OK)
    var study: Node3D = load("res://coordinates.tscn").instantiate()
    study.set_script(script)
    root.add_child(study)
    return study

func run() -> void:
    var folder: String = get_script().resource_path.get_base_dir()
    var code: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("lesson-code.json")))
    check("The first project scene is the coordinate study", ProjectSettings.get_setting("application/run/main_scene") == "res://coordinates.tscn")
    var position: Node3D = study_with(code.position)
    check("An unused position leaves both markers unseen", not position.get_node("A").visible and not position.get_node("B").visible)
    check("The supplied reference stays present", position.get_node("Guides").get_child_count() == 7)
    check("Day Zero camera remains current", position.get_node("Camera3D").current)
    position.free()

    var visible: Node3D = study_with(code.visible)
    check("The first attachment reveals only A", visible.get_node("A").visible and not visible.get_node("B").visible)
    check("A marks the coordinate from the lesson", visible.get_node("A").position.is_equal_approx(Vector3(-0.75, 1.12, 0)))
    check("The supplied marker keeps the production radius", is_equal_approx(visible.get_node("A").mesh.radius, 0.14))
    visible.free()

    var coordinates: Array[Vector3] = [Vector3(0.75, 1.12, 0), Vector3(-0.75, 1.7, 0), Vector3(-0.75, 1.12, 0.7)]
    var replacements: Array[String] = ["0.75, 1.12, 0.0", "-0.75, 1.7, 0.0", "-0.75, 1.12, 0.7"]
    for i in range(3):
        var variant: Node3D = study_with(String(code.visible).replace("-0.75, 1.12, 0.0", replacements[i]))
        check("The authored axis variation reaches its coordinate " + str(i), variant.get_node("A").position.is_equal_approx(coordinates[i]))
        check("Changing a coordinate leaves marker size unchanged " + str(i), is_equal_approx(variant.get_node("A").mesh.radius, 0.14))
        variant.free()

    var two: Node3D = study_with(code.two)
    check("Both positions are made visible", two.get_node("A").visible and two.get_node("B").visible)
    check("Two positions share one reference", two.get_node("A").get_parent() == two.get_node("B").get_parent())
    check("Two positions share the same supplied shape", two.get_node("A").mesh == two.get_node("B").mesh)
    check("The final coordinates are distinct", two.get_node("A").position.is_equal_approx(Vector3(-0.75,1.12,0)) and two.get_node("B").position.is_equal_approx(Vector3(0.75,1.12,0)))
    two.free()

    var moved: Node3D = study_with(String(code.two).replace("var b := Vector3(0.75, 1.12, 0.0)", "var b := Vector3(-0.75, 1.7, 0.0)"))
    check("B can be placed above A without moving A", moved.get_node("B").position.is_equal_approx(Vector3(-0.75,1.7,0)) and moved.get_node("A").position.is_equal_approx(Vector3(-0.75,1.12,0)))
    moved.free()

    var coincident: Node3D = study_with(String(code.two).replace("var b := Vector3(0.75, 1.12, 0.0)", "var b := Vector3(-0.75, 1.12, 0.0)"))
    check("Two objects can keep the same position", coincident.get_node("A") != coincident.get_node("B") and coincident.get_node("A").position.is_equal_approx(coincident.get_node("B").position))
    coincident.free()

    var completed: Node3D = load("res://coordinates.tscn").instantiate()
    root.add_child(completed)
    check("The downloaded script produces the completed arrangement", completed.get_node("A").visible and completed.get_node("B").visible and completed.get_node("A").position != completed.get_node("B").position)
    completed.free()
    var report := {"passed": failures == 0, "engine": Engine.get_version_info().string, "checks": checks, "scope": "Actual tutorial blocks and named coordinate variations run against the supplied scene. No visual, learner or headset trial."}
    var file := FileAccess.open(folder.path_join("native-verification.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "
")
    file.close()
    print("COORDINATE STUDY: ", checks.size(), " checks; passed: ", failures == 0)
    quit(0 if failures == 0 else 1)
