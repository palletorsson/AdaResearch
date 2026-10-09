extends SceneTree

var checks: Array[Dictionary] = []
var failures := 0
var folder: String

func _initialize() -> void:
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"name": label, "passed": passed})
    if not passed:
        failures += 1
        push_error(label)

func capture(filename: String) -> Image:
    for i in range(3):
        await process_frame
        await RenderingServer.frame_post_draw
    var picture := root.get_texture().get_image()
    check("Captured " + filename, picture.save_png(folder.path_join(filename)) == OK)
    return picture

func run() -> void:
    folder = get_script().resource_path.get_base_dir()
    root.size = Vector2i(1280, 720)
    var code: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("lesson-code.json")))
    var script := GDScript.new()
    script.source_code = code.greeting
    check("Greeting code compiles", script.reload() == OK)
    var room: Node3D = load("res://base.tscn").instantiate()
    room.set_script(script)
    root.add_child(room)
    var camera: Camera3D = room.get_node("Camera3D")
    var light: DirectionalLight3D = room.get_node("DirectionalLight3D")
    var environment: Environment = room.get_node("WorldEnvironment").environment
    var display: Label3D = room.get("display")
    check("Camera starts at the stated z position", is_equal_approx(camera.position.z, 4.7))
    check("Directional energy starts at 1.2", is_equal_approx(light.light_energy, 1.2))
    check("No ambient fill masks the light experiment", environment.ambient_light_source == Environment.AMBIENT_SOURCE_DISABLED)
    check("Label is unshaded by default", not display.shaded)
    var original_transform := display.transform
    var lit := await capture("camera-light-default.png")
    var left := display.global_position + Vector3(-0.5, 0, 0)
    var right := display.global_position + Vector3(0.5, 0, 0)
    var width_before := camera.unproject_position(left).distance_to(camera.unproject_position(right))
    camera.position.z = 3.0
    var width_near := camera.unproject_position(left).distance_to(camera.unproject_position(right))
    check("Nearer camera enlarges the projected span", width_near > width_before * 1.3)
    check("Moving the camera leaves the display transform unchanged", display.transform == original_transform)
    await capture("camera-nearer.png")
    camera.position.z = 4.7
    light.light_energy = 0.0
    var unlit := await capture("light-off.png")
    var lit_total := 0.0
    var unlit_total := 0.0
    for y in range(520, 650, 10):
        for x in range(400, 880, 10):
            lit_total += lit.get_pixel(x, y).get_luminance()
            unlit_total += unlit.get_pixel(x, y).get_luminance()
    check("Floor pixels darken when the light is off", unlit_total < lit_total * 0.25)
    var screen := camera.unproject_position(display.global_position)
    var same_bright_pixels := 0
    for y in range(int(screen.y) - 50, int(screen.y) + 50):
        for x in range(int(screen.x) - 250, int(screen.x) + 250):
            if lit.get_pixel(x, y).get_luminance() > 0.7 and unlit.get_pixel(x, y).get_luminance() > 0.7:
                same_bright_pixels += 1
    check("Bright text pixels remain when the light is off", same_bright_pixels > 100)
    light.light_energy = 1.2
    var report := {"passed": failures == 0, "engine": Engine.get_version_info().string, "checks": checks, "projected_span": {"original": width_before, "near": width_near}, "floor_luminance_sum": {"lit": lit_total, "unlit": unlit_total}, "bright_text_pixels_in_both": same_bright_pixels}
    var file := FileAccess.open(folder.path_join("view-verification.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "\n")
    file.close()
    room.free()
    for i in range(2):
        await process_frame
        await RenderingServer.frame_post_draw
    print("CAMERA AND LIGHT: ", checks.size(), " checks; passed: ", failures == 0)
    quit(0 if failures == 0 else 1)
