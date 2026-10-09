extends SceneTree
## Reproducible native geometry, input and visual comparisons. No headset claims.
var room
var out: String
var checks: Array = []

func _initialize() -> void:
    out = OS.get_cmdline_user_args()[0]
    DirAccess.make_dir_recursive_absolute(out)
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"check": label, "passed": passed})
    if not passed:
        push_warning("CHECK FAILED: " + label)

func frames(n: int = 3) -> void:
    for i in n:
        await process_frame
    await RenderingServer.frame_post_draw

func capture(file: String) -> void:
    await frames(5)
    check("Native capture " + file, root.get_texture().get_image().save_png(out.path_join(file)) == OK)

func send(event: InputEvent) -> void:
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func key(code: int) -> void:
    var e = InputEventKey.new()
    e.keycode = code
    e.pressed = true
    send(e)
    e = e.duplicate()
    e.pressed = false
    send(e)

func motion(at: Vector2, held: bool = true) -> void:
    var e = InputEventMouseMotion.new()
    e.position = at
    e.relative = at - room.pointer
    e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
    e.shift_pressed = true
    send(e)

func button(at: Vector2, pressed: bool) -> void:
    var e = InputEventMouseButton.new()
    e.position = at
    e.button_index = MOUSE_BUTTON_LEFT
    e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
    e.shift_pressed = true
    e.pressed = pressed
    send(e)

func wheel(at: Vector2) -> void:
    var e = InputEventMouseButton.new()
    e.position = at
    e.button_index = MOUSE_BUTTON_WHEEL_UP
    e.shift_pressed = true
    e.pressed = true
    send(e)

func vertices(index: int) -> PackedVector3Array:
    return room.meshes[index].get_child(0).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func run() -> void:
    room = load("res://gallery.tscn").instantiate()
    root.add_child(room)
    await frames(12)
    room.canvas.hide()
    var original = room.strokes.duplicate(true)
    check("Six constructions built from one input stroke", room.meshes.size() == 6 and room.meshes.all(func(m): return m.get_child_count() == 1))
    check("Loaded, wash and dry versions have identical geometry", vertices(2) == vertices(4) and vertices(4) == vertices(5))
    check("Twisting changes the surface without rewriting the path", vertices(2) != vertices(3) and room.strokes == original)
    check("First four constructions retain the same material parameters", room.meshes[1].get_child(0).material_override.roughness == room.meshes[3].get_child(0).material_override.roughness and room.meshes[1].get_child(0).material_override.metallic == room.meshes[3].get_child(0).material_override.metallic)
    await capture("gallery.png")
    for i in 6:
        room.inspect(i)
        await capture(["round-line.png", "flat-stroke.png", "loaded-stroke.png", "twisted-ribbon.png", "wash.png", "dry-brush.png"][i])
    room.inspect(3)
    room.yaw = 1.22
    room.update_camera()
    await capture("ribbon-side.png")
    var fine_count = vertices(3).size()
    room.spacing = .4
    room.rebuild()
    check("Coarser sampling reduces mesh data while retaining the stored path", vertices(3).size() < fine_count and room.strokes == original)
    room.inspect(3)
    await capture("coarse.png")
    room.spacing = .055
    room.rebuild()
    await capture("fine.png")
    # Same planar path: a camera change does not thicken the surface.
    var planar = PackedVector3Array()
    for p in room.strokes[0].points:
        planar.append(Vector3(p.x, p.y, 0))
    room.strokes[0].points = planar
    room.rebuild()
    room.inspect(1)
    room.yaw = 0.0
    room.pitch = 0.0
    room.update_camera()
    await capture("planar-front.png")
    var before = vertices(1)
    room.yaw = PI / 2.0
    room.update_camera()
    check("Orbit retains mesh positions", vertices(1) == before)
    await capture("planar-edge.png")
    room.reset_example(1)
    room.inspect(4)
    room.yaw = 0.0
    room.pitch = .02
    room.update_camera()
    var overlaps = room.strokes.duplicate(true)
    await capture("wash-crossing-front.png")
    room.inspect(2)
    room.yaw = 0.0
    room.pitch = .02
    room.update_camera()
    await capture("opaque-crossing.png")
    room.inspect(4)
    room.pitch = .02
    room.yaw = PI
    room.update_camera()
    await capture("wash-crossing-back.png")
    room.strokes.reverse()
    room.rebuild()
    await capture("wash-crossing-order.png")
    room.strokes = overlaps
    room.rebuild()
    room.inspect(5)
    room.yaw = 0.0
    room.pitch = .02
    room.update_camera()
    await capture("dry-crossing.png")
    room.reset_example(2)
    room.width = .18
    room.rebuild()
    room.inspect(2)
    await capture("portrait.png")
    room.inspect(3)
    await capture("portrait-twisted.png")
    room.yaw = .91
    room.update_camera()
    await capture("portrait-side.png")
    # Real input handler receives separate strokes, not direct point insertion.
    room.inspect(3)
    key(KEY_C)
    check("Clear empties all six representations", room.strokes.is_empty() and room.meshes.all(func(m): return m.get_child_count() == 0))
    button(Vector2(600, 530), true)
    for i in 31:
        motion(Vector2(600 + i * 12, 530 - sin(i / 30.0 * PI) * 170))
        if i == 15:
            wheel(room.pointer)
    button(Vector2(960, 530), false)
    await frames(2)
    check("Mouse replay makes one connected stroke", room.strokes.size() == 1 and room.strokes[0].points.size() >= 30)
    var path: PackedVector3Array = room.strokes[0].points
    var depth_min = INF
    var depth_max = -INF
    for p in path:
        var depth = p.dot(room.camera.global_basis.z)
        depth_min = minf(depth_min, depth)
        depth_max = maxf(depth_max, depth)
    check("Shift-wheel changes depth during a stroke", depth_max - depth_min > .14)
    var count = room.point_count()
    motion(Vector2(1060, 700), false)
    await frames()
    check("Pen-up travel adds no positions", room.point_count() == count)
    key(KEY_X)
    button(Vector2(680, 670), true)
    for i in 21:
        motion(Vector2(680 + i * 9, 670 - i * 2))
    button(Vector2(860, 630), false)
    await frames(2)
    check("Pen lift makes separate meshes without a joining strip", room.strokes.size() == 2 and room.meshes.all(func(m): return m.get_child_count() == 2))
    check("New colour belongs to the new stroke", room.strokes[0].colour != room.strokes[1].colour)
    var drawn = room.strokes.duplicate(true)
    key(KEY_BRACKETRIGHT)
    key(KEY_PERIOD)
    key(KEY_EQUAL)
    check("Width twist and material changes preserve drawing data", room.strokes == drawn)
    await capture("mouse-strokes.png")
    key(KEY_Z)
    check("Undo removes exactly the last stroke", room.strokes.size() == 1 and room.strokes[0] == drawn[0])
    room.strokes = drawn.duplicate(true)
    room.rebuild()
    key(KEY_P)
    key(KEY_Z)
    check("Switching examples is undoable", room.strokes == drawn)
    key(KEY_R)
    key(KEY_Z)
    check("Restoring an example is undoable", room.strokes == drawn)
    check("Drawing saves in an isolated test file", room.save_drawing(out.path_join("test-drawing.json")))
    room.clear_drawing()
    check("Saved drawing loads", room.load_drawing(out.path_join("test-drawing.json")))
    var same = room.strokes.size() == drawn.size()
    for i in room.strokes.size():
        same = same and room.strokes[i].points.size() == drawn[i].points.size()
        for j in room.strokes[i].points.size():
            same = same and room.strokes[i].points[j].distance_to(drawn[i].points[j]) < .00001
    check("Reload preserves every stored point", same)
    FileAccess.open(out.path_join("invalid.json"), FileAccess.WRITE).store_string('{"version":1,"strokes":[{"points":[[0,"bad",0]],"colour":"ffffff"}]}')
    var valid = room.strokes.duplicate(true)
    check("Malformed input is rejected without replacing the drawing", not room.load_drawing(out.path_join("invalid.json")) and room.strokes == valid)
    button(Vector2(700, 400), true)
    motion(Vector2(800, 380))
    room.get_window().focus_exited.emit()
    check("Losing window focus ends the stroke", not room.drawing)
    count = room.point_count()
    motion(Vector2(900, 390))
    check("Focus loss prevents further paint deposition", room.point_count() == count)
    button(Vector2(900, 390), false)
    var giant = PackedVector3Array()
    for i in 66:
        giant.append(Vector3(-100 if i % 2 == 0 else 100, 0, 0))
    var previous = room.strokes.duplicate(true)
    room.strokes.clear()
    for i in 24:
        room.strokes.append({"points": giant, "colour": Color.WHITE})
    var sample_count = 0
    for stroke in room.strokes:
        sample_count += room.render_points(stroke.points).size()
    check("Long valid paths obey the total rendered sample budget", sample_count <= room.MAX_RENDER_SAMPLES)
    check("Capping detail preserves recorded positions and announces adaptation", room.point_count() == 24 * 66 and room.adaptive_sampling)
    room.strokes = previous
    room.rebuild()
    room.canvas.show()
    await capture("controls.png")
    var passed = checks.all(func(c): return c.passed)
    var report = {"passed": passed, "checks": checks, "scope": "Native Godot mesh and shader renders plus scripted desktop input replay. No manual pressure, tracked controller or Quest test."}
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
    print(JSON.stringify({"passed": passed, "checks": checks.size()}))
    quit(0 if passed else 1)
