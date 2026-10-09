extends SceneTree

var checks: Array[Dictionary] = []
var failures := 0
var out: String

func _initialize() -> void:
    out = OS.get_environment("POINT_STUDY_OUTPUT")
    run.call_deferred()

func check(label: String, ok: bool) -> void:
    checks.append({"name": label, "passed": ok})
    if not ok:
        failures += 1
        push_error(label)

func settle() -> void:
    await physics_frame
    await physics_frame

func capture(filename: String) -> void:
    if DisplayServer.get_name() == "headless":
        return
    await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    check("Screenshot saved: " + filename, image.save_png(out.path_join(filename)) == OK)

func key(code: Key) -> InputEventKey:
    var event := InputEventKey.new()
    event.pressed = true
    event.physical_keycode = code
    return event

func run() -> void:
    var study: Node3D = load("res://study.tscn").instantiate()
    root.add_child(study)
    var helper = study.get_node("ContactProbe")
    helper.paused = true
    await settle()
    var absent: Node3D = study.get_node("Position")
    var visible: Node3D = study.get_node("Visible")
    var solid: Node3D = study.get_node("Solid")
    var mesh: MeshInstance3D = solid.get_child(0)
    var collision: CollisionShape3D = solid.get_child(1).get_child(0)
    check("Position alone creates no body", absent.get_child_count() == 0)
    check("Visible station only has a marker", visible.get_child_count() == 1 and visible.get_child(0) is MeshInstance3D)
    check("Three actual moving bodies supplied", helper.probes.size() == 3)
    check("Visible and physical radii initially coincide", is_equal_approx(mesh.mesh.radius, 0.14) and is_equal_approx(collision.shape.radius, 0.14))
    helper.reset_sweep()
    helper.paused = false
    await create_timer(2.8, true, true).timeout
    helper.paused = true
    check("Empty station lets the feeler cross", helper.labels[0].text == "crossed" and not helper.stopped[0])
    check("Visible surface lets the feeler cross", helper.labels[1].text == "crossed" and not helper.stopped[1])
    check("Solid boundary stops its feeler", helper.stopped[2] and helper.labels[2].text == "stopped")
    var normal_stop: float = helper.probes[2].position.x - solid.position.x
    check("Actual stop is at the authored boundary plus feeler width", absf(normal_stop + 0.14 + 0.0175) < 0.01)
    await capture("contact-default.png")

    var paused_position: Vector3 = helper.probes[0].position
    await create_timer(0.2, true, true).timeout
    check("Pause holds the moving bodies still", helper.probes[0].position.is_equal_approx(paused_position))
    helper._unhandled_key_input(key(KEY_R))
    check("R resets every contact result and position", not helper.stopped.has(true) and helper.probes[2].position.is_equal_approx(helper.origins[2]))

    collision.shape.radius = 0.35
    await settle()
    helper._unhandled_key_input(key(KEY_SPACE))
    check("Space resumes the paused sweep", not helper.paused)
    await create_timer(2.8, true, true).timeout
    helper.paused = true
    var expanded_stop: float = helper.probes[2].position.x - solid.position.x
    check("Enlarged boundary stops the feeler earlier", helper.stopped[2] and normal_stop - expanded_stop > 0.20)
    check("Enlarged boundary leaves the visible sphere unchanged", is_equal_approx(mesh.mesh.radius, 0.14))
    await capture("contact-larger-boundary.png")

    mesh.mesh.radius = 0.3
    mesh.mesh.height = 0.6
    collision.shape.radius = 0.07
    helper.reset_sweep()
    await settle()
    helper.paused = false
    await create_timer(2.8, true, true).timeout
    helper.paused = true
    var inner_stop: float = helper.probes[2].position.x - solid.position.x
    check("Smaller boundary stops the feeler inside the larger visible surface", helper.stopped[2] and absf(inner_stop) < 0.1 and absf(inner_stop) < mesh.mesh.radius)
    await capture("contact-smaller-boundary.png")

    helper.elapsed = helper.CYCLE_SECONDS - 0.01
    helper.paused = false
    await settle()
    helper.paused = true
    check("Automatic repeat clears the previous stop", not helper.stopped.has(true))

    # Compile the learner's actual edits, rather than a separate implementation.
    var examples := [
        ["visible.gd", "1.12", "1.7", "height"],
        ["visible.gd", "var radius := 0.14", "var radius := 0.3", "visible radius"],
        ["solid.gd", "sphere_shape.radius = radius", "sphere_shape.radius = 0.35", "collision radius"]
    ]
    for example in examples:
        var script := GDScript.new()
        script.source_code = FileAccess.get_file_as_string("res://" + example[0]).replace(example[1], example[2])
        check("Learner edit compiles: " + example[3], script.reload() == OK)
        var node := Node3D.new()
        node.set_script(script)
        root.add_child(node)
        if example[3] == "height":
            check("Height edit raises the marker", is_equal_approx(node.get_child(0).position.y, 1.7))
        elif example[3] == "visible radius":
            check("Radius edit expands only the visible marker", node.get_child_count() == 1 and is_equal_approx(node.get_child(0).mesh.radius, 0.3))
        else:
            check("Boundary edit retains the original visible radius", is_equal_approx(node.get_child(0).mesh.radius, 0.14) and is_equal_approx(node.get_child(1).get_child(0).shape.radius, 0.35))
        node.free()

    var file := FileAccess.open(out.path_join("native-verification.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed": failures == 0, "engine": Engine.get_version_info().string, "checks": checks, "scope": "Native portable study: actual moving-body contact, radius edits, pause/repeat and complete learner scripts. No museum or headset test."}, "  ") + "\n")
    file.close()
    print("CONTACT_STUDY: ", checks.size(), " checks, ", failures, " failures")
    study.queue_free()
    await process_frame
    quit(1 if failures else 0)
