extends SceneTree
## Native two-mode rendering and scripted desktop input replay. No human drawing claims.
var room
var out: String
var checks: Array = []

func _initialize() -> void:
    var args = OS.get_cmdline_user_args()
    if args.is_empty():
        push_error("Pass an isolated output directory after --.")
        quit(2)
        return
    out = args[0]
    DirAccess.make_dir_recursive_absolute(out)
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"check": label, "passed": passed})
    if not passed:
        push_warning("CHECK FAILED: " + label)

func frames(count: int = 3) -> void:
    for i in count:
        await process_frame
    await RenderingServer.frame_post_draw

func capture(file: String) -> void:
    await frames(5)
    check("Native capture " + file, root.get_texture().get_image().save_png(out.path_join(file)) == OK)

func send(event: InputEvent) -> void:
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func key(code: int) -> void:
    var event = InputEventKey.new()
    event.keycode = code
    event.pressed = true
    send(event)
    event = event.duplicate()
    event.pressed = false
    send(event)

func motion(at: Vector2, held: bool = true, mask: int = MOUSE_BUTTON_MASK_LEFT) -> void:
    var event = InputEventMouseMotion.new()
    event.position = at
    event.relative = at - room.pointer
    event.button_mask = mask if held else 0
    send(event)

func button(at: Vector2, pressed: bool, index: int = MOUSE_BUTTON_LEFT) -> void:
    var event = InputEventMouseButton.new()
    event.position = at
    event.button_index = index
    event.button_mask = (MOUSE_BUTTON_MASK_LEFT if index == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT) if pressed else 0
    event.pressed = pressed
    send(event)

func wheel(at: Vector2) -> void:
    var event = InputEventMouseButton.new()
    event.position = at
    event.button_index = MOUSE_BUTTON_WHEEL_UP
    event.shift_pressed = true
    event.pressed = true
    send(event)

func geometry_signature(node: Node) -> Array:
    # Record geometry values, not object IDs or materials changed by display controls.
    var values: Array = []
    if node is MeshInstance3D:
        values.append(node.transform)
        for surface in node.mesh.get_surface_count():
            values.append(node.mesh.surface_get_arrays(surface))
    elif node is MultiMeshInstance3D:
        values.append(node.transform)
        values.append(node.multimesh.instance_count)
        for instance in node.multimesh.instance_count:
            values.append(node.multimesh.get_instance_transform(instance))
        for surface in node.multimesh.mesh.get_surface_count():
            values.append(node.multimesh.mesh.surface_get_arrays(surface))
    for child in node.get_children():
        var child_values = geometry_signature(child)
        if not child_values.is_empty():
            values.append(child_values)
    return values

func paths_match(expected: Array) -> bool:
    if room.strokes.size() != expected.size():
        return false
    for i in expected.size():
        if room.strokes[i].points.size() != expected[i].points.size():
            return false
        if room.strokes[i].colour.to_html(true) != expected[i].colour.to_html(true):
            return false
        for j in expected[i].points.size():
            if room.strokes[i].points[j].distance_to(expected[i].points[j]) > .00001:
                return false
    return true

func write_text(name: String, value: String) -> String:
    var path = out.path_join(name)
    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(value)
    return path

func run() -> void:
    room = load("res://draw_lines.tscn").instantiate()
    root.add_child(room)
    await frames(12)
    var authored = room.strokes.duplicate(true)
    check("Initial authored portrait uses coloured tube lines", room.draw_mode == 0 and room.shape_instances.size() == 8 and room.shape_instances.all(func(node): return node is MeshInstance3D))
    check("Tube colours are unshaded and nonemissive", room.shape_instances.all(func(node): return node.material_override.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and not node.material_override.emission_enabled))
    room.canvas.hide()
    await capture("lines.png")
    key(KEY_B)
    check("B changes lines into dots without modifying stored strokes", room.draw_mode == 1 and room.strokes == authored and room.shape_instances.all(func(node): return node is MultiMeshInstance3D))
    var ink_matches = true
    for i in room.shape_instances.size():
        var material = room.shape_instances[i].material_override
        ink_matches = ink_matches and material is ShaderMaterial and material.get_shader_parameter("ink") == authored[i].colour
    check("Light-dot material retains each stroke colour", ink_matches)
    var samples_match = room.shape_instances.size() == authored.size()
    for i in authored.size():
        var sampled = room.render_points(authored[i].points)
        var mm = room.shape_instances[i].multimesh
        samples_match = samples_match and mm.instance_count == sampled.size()
        for j in mini(mm.instance_count, sampled.size()):
            samples_match = samples_match and mm.get_instance_transform(j).origin.is_equal_approx(sampled[j])
    check("Dot instance positions follow the same stored paths", samples_match)
    await capture("dots.png")
    var geometry = geometry_signature(room.meshes[0])
    var glowing = room.environment.glow_enabled
    key(KEY_G)
    check("G toggles screen glow without changing geometry or stored strokes", room.environment.glow_enabled != glowing and geometry_signature(room.meshes[0]) == geometry and room.strokes == authored)
    await capture("dots-no-glow.png")
    check("Screen glow changes the rendered light-dot pixels", Image.load_from_file(out.path_join("dots.png")).get_data() != Image.load_from_file(out.path_join("dots-no-glow.png")).get_data())
    key(KEY_G)
    button(Vector2(800, 500), true, MOUSE_BUTTON_RIGHT)
    motion(Vector2(650, 515), true, MOUSE_BUTTON_MASK_RIGHT)
    button(Vector2(650, 515), false, MOUSE_BUTTON_RIGHT)
    check("Right-drag orbits without drawing or moving the dot geometry", absf(room.yaw) > .5 and room.strokes == authored and geometry_signature(room.meshes[0]) == geometry)
    await capture("dots-side.png")
    room.yaw = 0.0
    room.pitch = 0.0
    room.update_camera()
    room.canvas.show()
    await capture("controls.png")
    room.canvas.hide()
    key(KEY_1)
    check("1 selects lines while retaining the portrait", room.draw_mode == 0 and room.strokes == authored)
    key(KEY_C)
    check("C clears the strokes and rendered shapes", room.strokes.is_empty() and room.shape_instances.is_empty())
    # Events pass through the normal viewport input route, never direct point insertion.
    button(Vector2(540, 540), true)
    for i in 31:
        motion(Vector2(540 + i * 15, 540 - sin(i / 30.0 * PI) * 185))
        if i == 15:
            wheel(room.pointer)
    button(Vector2(990, 540), false)
    await frames(2)
    check("Plain left-drag records a connected coloured stroke", room.strokes.size() == 1 and room.strokes[0].points.size() >= 30 and room.shape_instances.size() == 1 and room.shape_instances[0] is MeshInstance3D)
    var depth_min = INF
    var depth_max = -INF
    for point in room.strokes[0].points:
        var depth = point.dot(room.camera.global_basis.z)
        depth_min = minf(depth_min, depth)
        depth_max = maxf(depth_max, depth)
    check("Shift-wheel changes depth during an active stroke", depth_max - depth_min > .14)
    var count = room.point_count()
    motion(Vector2(1030, 700), false)
    await frames()
    check("Pen-up motion does not add recorded positions", room.point_count() == count)
    key(KEY_X)
    button(Vector2(620, 680), true)
    for i in 21:
        motion(Vector2(620 + i * 13, 680 - i * 2))
    button(Vector2(880, 640), false)
    await frames(2)
    check("Releasing and pressing creates separate stroke meshes", room.strokes.size() == 2 and room.shape_instances.size() == 2)
    check("X assigns the next colour only to the new stroke", room.strokes[0].colour != room.strokes[1].colour)
    var drawn = room.strokes.duplicate(true)
    await capture("input-lines.png")
    key(KEY_2)
    check("2 renders the input replay as dots without changing the strokes", room.draw_mode == 1 and room.strokes == drawn and room.shape_instances.size() == 2 and room.shape_instances.all(func(node): return node is MultiMeshInstance3D))
    button(Vector2(1060, 390), true)
    button(Vector2(1060, 390), false)
    await frames(2)
    check("One click leaves exactly one independent light dot", room.strokes.size() == 3 and room.strokes.back().points.size() == 1 and room.shape_instances.back().multimesh.instance_count == 1)
    var with_point = room.strokes.duplicate(true)
    await capture("input-dots.png")
    key(KEY_Z)
    check("Z undoes exactly the solitary dot", room.strokes == drawn)
    key(KEY_Z)
    check("Z then undoes exactly the last dragged stroke", room.strokes.size() == 1 and room.strokes[0] == drawn[0])
    room.strokes = with_point.duplicate(true)
    room.rebuild()
    var fine_count = 0
    for node in room.shape_instances:
        fine_count += node.multimesh.instance_count
    key(KEY_S)
    var coarse_count = 0
    for node in room.shape_instances:
        coarse_count += node.multimesh.instance_count
    check("S changes dot spacing while retaining every recorded point", coarse_count < fine_count and room.strokes == with_point)
    key(KEY_BRACKETRIGHT)
    check("Changing brush size preserves all stroke positions and colours", room.strokes == with_point)
    check("Drawing saves to an isolated test file", room.save_drawing(out.path_join("test-drawing.json")))
    key(KEY_C)
    check("Loading restores the saved strokes including the solitary dot", room.load_drawing(out.path_join("test-drawing.json")) and paths_match(with_point))
    var valid = room.strokes.duplicate(true)
    var invalid_cases = [
        {"name":"invalid-types.json", "data":{"version":1, "strokes":[{"points":[[0,"bad",0]], "colour":"ffffff"}]}},
        {"name":"empty-stroke.json", "data":{"version":1, "strokes":[{"points":[], "colour":"ffffff"}]}},
        {"name":"out-of-bounds.json", "data":{"version":1, "strokes":[{"points":[[101,0,0]], "colour":"ffffff"}]}},
        {"name":"invalid-colour.json", "data":{"version":1, "strokes":[{"points":[[0,0,0]], "colour":"not-a-colour"}]}},
        {"name":"unsupported-version.json", "data":{"version":2, "strokes":[]}}
    ]
    for invalid in invalid_cases:
        var invalid_path = write_text(invalid.name, JSON.stringify(invalid.data))
        check("Reject " + invalid.name + " without replacing the drawing", not room.load_drawing(invalid_path) and room.strokes == valid)
    var excess_strokes = []
    for i in room.MAX_STROKES + 1:
        excess_strokes.append({"points":[[0,0,0]], "colour":"ffffff"})
    var excess_path = write_text("too-many-strokes.json", JSON.stringify({"version":1,"strokes":excess_strokes}))
    check("Loading rejects excessive stroke count without data loss", not room.load_drawing(excess_path) and room.strokes == valid)
    var excess_points = []
    for i in room.MAX_POINTS + 1:
        excess_points.append([0,0,0])
    excess_path = write_text("too-many-points.json", JSON.stringify({"version":1,"strokes":[{"points":excess_points,"colour":"ffffff"}]}))
    check("Loading rejects excessive point count without data loss", not room.load_drawing(excess_path) and room.strokes == valid)
    excess_path = write_text("oversized-file.json", " ".repeat(500001))
    check("Loading rejects oversized files without data loss", not room.load_drawing(excess_path) and room.strokes == valid)
    button(Vector2(700, 400), true)
    motion(Vector2(800, 380))
    room.get_window().focus_exited.emit()
    count = room.point_count()
    motion(Vector2(900, 390))
    check("Window focus loss ends deposition immediately", not room.drawing and room.point_count() == count)
    button(Vector2(900, 390), false)
    var giant = PackedVector3Array()
    for i in 66:
        giant.append(Vector3(-100 if i % 2 == 0 else 100, 0, 0))
    room.strokes.clear()
    for i in room.MAX_STROKES:
        room.strokes.append({"points":giant, "colour":Color.WHITE})
    room.set_mode(1)
    var rendered = 0
    for node in room.shape_instances:
        rendered += node.multimesh.instance_count
    check("Long valid paths stay within the total rendered dot budget", rendered <= room.MAX_RENDER_SAMPLES and room.shape_instances.size() == room.MAX_STROKES)
    check("Adaptive sampling retains the raw long paths and is announced", room.point_count() == room.MAX_STROKES * 66 and room.adaptive_sampling)
    room.set_mode(0)
    var vertex_count = 0
    for node in room.shape_instances:
        vertex_count += node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
    check("Long valid paths also keep tube geometry bounded", vertex_count <= room.MAX_RENDER_SAMPLES * 9 + room.MAX_STROKES * 20 and room.point_count() == room.MAX_STROKES * 66)
    var passed = checks.all(func(item): return item.passed)
    var report = {"passed":passed,"checks":checks,"rendered_long_path_dots":rendered,"rendered_long_path_tube_vertices":vertex_count,"scope":"Native Godot rendering and scripted input through Input.parse_input_event. Portrait captures are authored example paths, not human drawing. No tracked controller or Quest test."}
    write_text("verification.json", JSON.stringify(report, "\t"))
    print(JSON.stringify({"passed":passed,"checks":checks.size()}))
    quit(0 if passed else 1)
