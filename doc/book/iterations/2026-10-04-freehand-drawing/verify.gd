extends SceneTree
## Replays irregular mouse strokes through the normal input handler.
## These coordinates are a test drawing, not an image converted to a mesh.
var room
var out: String
var checks: Array = []

func _initialize() -> void:
    out = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"check": label, "passed": passed})

func frames(n: int = 3) -> void:
    for i in n:
        await process_frame
    await RenderingServer.frame_post_draw

func send(event: InputEvent) -> void:
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func key(code: int) -> void:
    var e := InputEventKey.new()
    e.keycode = code
    e.pressed = true
    send(e)
    e = e.duplicate()
    e.pressed = false
    send(e)

func motion(at: Vector2, held: bool = true) -> void:
    var e := InputEventMouseMotion.new()
    e.position = at
    e.global_position = at
    e.relative = at - room.pointer_position
    e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
    send(e)

func button(at: Vector2, pressed: bool) -> void:
    var e := InputEventMouseButton.new()
    e.position = at
    e.global_position = at
    e.button_index = MOUSE_BUTTON_LEFT
    e.pressed = pressed
    e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
    send(e)

func wheel(at: Vector2, up: bool) -> void:
    var e := InputEventMouseButton.new()
    e.position = at
    e.global_position = at
    e.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
    e.pressed = true
    send(e)

func stroke(coords: Array, label: String) -> void:
    var start: Vector2 = coords[0]
    motion(start, false)
    var first: int = room.brush_count
    button(start, true)
    var initial: Vector3 = room.brush_state[first].position
    check(label + ": pen-down begins at the pointer", room.camera.unproject_position(initial).distance_to(start) < .01)
    for i in range(1, coords.size()):
        var before: Vector2 = coords[i - 1]
        var finish: Vector2 = coords[i]
        var steps := maxi(1, ceili(before.distance_to(finish) / 16.0))
        for j in range(1, steps + 1):
            motion(before.lerp(finish, j / float(steps)))
        await frames(1)
    button(coords.back(), false)
    var count: int = room.brush_count
    await frames(4)
    check(label + ": releasing stops the stroke", not room.drawing and room.brush_count == count)

func capture(file: String) -> void:
    await frames(8)
    check("Native capture: " + file, root.get_texture().get_image().save_png(out.path_join(file)) == OK)

func run() -> void:
    room = load("res://study.tscn").instantiate()
    root.add_child(room)
    await frames(12)
    room.inspect(4)
    room.clear_brush()
    room.brush_radius = .12
    room.undo_stack.clear()
    room.capture_mode = true
    room.canvas.hide()
    # Irregular outlines and pen lifts; all geometry comes from normal mouse input.
    await stroke([Vector2(755,260), Vector2(696,279), Vector2(657,320), Vector2(637,378), Vector2(642,448), Vector2(662,504), Vector2(700,558), Vector2(753,592), Vector2(804,600), Vector2(855,574), Vector2(897,526), Vector2(923,462), Vector2(930,390), Vector2(909,321), Vector2(870,277), Vector2(812,258), Vector2(755,260)], "Face outline")
    key(KEY_X)
    wheel(Vector2(800,430), true)
    await stroke([Vector2(678,391), Vector2(698,378), Vector2(723,376), Vector2(749,392), Vector2(725,402), Vector2(701,401), Vector2(678,391)], "Left eye")
    await stroke([Vector2(821,388), Vector2(846,372), Vector2(873,377), Vector2(897,393), Vector2(871,402), Vector2(845,400), Vector2(821,388)], "Right eye")
    key(KEY_X)
    wheel(Vector2(800,430), true)
    await stroke([Vector2(788,396), Vector2(777,432), Vector2(766,466), Vector2(782,478), Vector2(803,470)], "Nose")
    var nose_count: int = room.brush_count
    # A deliberately disconnected mark proves the move between strokes is not drawn.
    motion(Vector2(1100,350), false)
    await frames(5)
    check("Pen-up movement adds no connecting marks", room.brush_count == nose_count)
    await stroke([Vector2(725,515), Vector2(754,522), Vector2(786,526), Vector2(816,521), Vector2(845,507)], "Mouth")
    key(KEY_X)
    wheel(Vector2(800,430), false)
    wheel(Vector2(800,430), false)
    wheel(Vector2(800,430), false)
    await stroke([Vector2(642,451), Vector2(611,431), Vector2(603,375), Vector2(620,307), Vector2(665,246), Vector2(727,219), Vector2(791,210), Vector2(862,227), Vector2(920,265), Vector2(960,321), Vector2(974,399), Vector2(951,471)], "Hair")
    await stroke([Vector2(704,558), Vector2(695,626), Vector2(639,648), Vector2(576,681), Vector2(546,735)], "Left shoulder")
    await stroke([Vector2(852,575), Vector2(865,625), Vector2(923,646), Vector2(981,680), Vector2(1010,735)], "Right shoulder")
    check("Whole drawing fits without recycling its first marks", room.brush_count < room.MAX_STAMPS)
    var depth_min := INF
    var depth_max := -INF
    for i in room.brush_count:
        var d: float = (room.camera.position - room.brush_state[i].position).dot(room.camera.basis.z)
        depth_min = minf(depth_min, d)
        depth_max = maxf(depth_max, d)
    check("Depth layers span at least 0.8 metres", depth_max - depth_min > .8)
    var portrait: Dictionary = room.snapshot()
    await capture("portrait-soft.png")
    key(KEY_B)
    check("Spheres retain every stroke position and colour", room.brush_state == portrait.stamps)
    await capture("portrait-spheres.png")
    key(KEY_B)
    check("Light points retain every stroke position and colour", room.brush_state == portrait.stamps)
    await capture("portrait-lines.png")
    # Undo the final shoulder, then restore the test drawing without changing a user save.
    key(KEY_Z)
    check("Undo removes one complete stroke", room.brush_count < portrait.count and room.brush_count > 0)
    room.restore_snapshot(portrait)
    var file := out.path_join("portrait.save")
    check("Test drawing saves locally", room.save_drawing(file))
    room.clear_brush()
    check("Test drawing reloads unchanged", room.load_drawing(file) and room.brush_state == portrait.stamps)
    room.set_brush_style(1)
    room.yaw += .95
    room.update_camera()
    await capture("portrait-side.png")
    room.inspect(4)
    room.capture_mode = false
    room.canvas.show()
    await capture("portrait-controls.png")
    # Change depth while the pointer remains down: one stroke must travel in depth.
    button(Vector2(1150,360), true)
    var a: Vector3 = room.brush_state[room.brush_count - 1].position
    wheel(Vector2(1180,395), true)
    motion(Vector2(1200,430))
    var b: Vector3 = room.brush_state[room.brush_count - 1].position
    button(Vector2(1200,430), false)
    check("Wheel moves a held stroke out of its original plane", absf((b - a).dot(room.camera.basis.z)) > .25)
    key(KEY_Z)
    button(Vector2(1170,500), true)
    room.get_window().focus_exited.emit()
    check("Losing window focus ends drawing", not room.drawing)
    var count_after_focus: int = room.brush_count
    await frames(8)
    check("An unfocused held pointer adds no further marks", room.brush_count == count_after_focus)
    button(Vector2(1170,500), false)
    var passed := checks.all(func(c): return c.passed)
    var report := {"passed": passed, "checks": checks, "portrait_marks": portrait.count, "depth_span_metres": depth_max - depth_min, "scope": "Scripted mouse-event replay of an irregular drawing plus an actual desktop drag session. No tracked hand or headset test."}
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
    print(JSON.stringify({"passed": passed, "checks": checks.size(), "marks": portrait.count}))
    quit(0 if passed else 1)
