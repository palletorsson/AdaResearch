extends SceneTree
var room
var out: String
var checks: Array = []

func _initialize() -> void:
    out = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"check": label, "passed": passed})
    if not passed:
        push_error(label)

func frames(n: int = 3) -> void:
    for i in n:
        await process_frame
    await RenderingServer.frame_post_draw

func key(code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func click(at: Vector2, pressed: bool) -> void:
    var motion := InputEventMouseMotion.new()
    motion.position = at
    motion.global_position = at
    Input.parse_input_event(motion)
    var event := InputEventMouseButton.new()
    event.position = at
    event.global_position = at
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func capture(file: String) -> void:
    await frames(10)
    check("Native render: " + file, root.get_texture().get_image().save_png(out.path_join(file)) == OK)

func run() -> void:
    room = load("res://study.tscn").instantiate()
    root.add_child(room)
    await frames(20)
    check("Eight stations created", room.centres.size() == 8)
    var point_error := 0.0
    for i in room.points.instance_count:
        var position: Vector3 = room.points.get_instance_transform(i).origin
        point_error = maxf(point_error, absf(position.distance_to(room.centres[1]) - room.RADIUS))
    check("All 420 points lie on the same 1.3m radius", point_error < .0001)
    check("Latitude and longitude have 1440 tube segments", room.line_count == 1440)
    check("Central ray reaches the front of the paint sphere", room.sphere_hit(room.centres[5] + Vector3(0, 0, 5), Vector3.FORWARD).position.distance_to(room.centres[5] + Vector3(0, 0, room.RADIUS)) < .00001)
    check("Ray pointing away does not paint", room.sphere_hit(room.centres[5] + Vector3(0, 0, 5), Vector3.BACK).is_empty())
    check("Ray missing the sphere does not paint", room.sphere_hit(room.centres[5] + Vector3(5, 0, 5), Vector3.FORWARD).is_empty())
    room.clear_paint()
    room.paint_direction(Vector3.LEFT)
    check("Paint wraps across longitude seam", room.paint_image.get_pixel(0, 128).a > .5 and room.paint_image.get_pixel(511, 128).a > .5)
    room.clear_paint()
    room.paint_direction(Vector3.UP)
    check("Paint reaches all longitudes at north pole", room.paint_image.get_pixel(0, 0).a > .5 and room.paint_image.get_pixel(256, 0).a > .5)
    check("Paint does not leak to opposite pole", room.paint_image.get_pixel(256, 255).a == 0)
    check("Zero direction rejected", not room.paint_direction(Vector3.ZERO))
    room.clear_brush()
    for i in room.MAX_STAMPS + 9:
        room.stamp_space(Vector3(i, 0, 0))
    check("Space brush stays within fixed memory budget", room.brush_count == room.MAX_STAMPS and room.brush.visible_instance_count == room.MAX_STAMPS)
    check("Oldest brush marks are recycled", room.brush.get_instance_transform(8).origin.x == room.MAX_STAMPS + 8)
    room.clear_brush()
    check("Clear removes visible space marks", room.brush.visible_instance_count == 0)
    room.reset_demo()
    key(KEY_6)
    await frames()
    check("Key 6 selects surface painting", room.selected == 5)
    key(KEY_C)
    await frames()
    check("C clears surface paint", room.paint_count == 0)
    var screen: Vector2 = room.camera.unproject_position(room.centres[5])
    click(screen, true)
    await frames(12)
    click(screen, false)
    await frames()
    check("Mouse click paints through camera picking", room.paint_count > 0)
    check("Releasing mouse ends drawing", not room.drawing)
    key(KEY_5)
    await frames()
    key(KEY_C)
    await frames()
    screen = room.camera.unproject_position(room.centres[4])
    click(screen, true)
    await frames(12)
    click(screen, false)
    await frames()
    check("Mouse click leaves free-space marks", room.brush_count > 0)
    var depth_before: float = room.brush_depth
    var wheel := InputEventMouseButton.new()
    wheel.button_index = MOUSE_BUTTON_WHEEL_UP
    wheel.pressed = true
    Input.parse_input_event(wheel)
    await frames()
    check("Wheel changes free-space drawing depth", room.brush_depth < depth_before)
    key(KEY_SPACE)
    await frames()
    var t: float = room.time
    await frames(10)
    check("Pause freezes the moving trace", room.time == t)
    key(KEY_G)
    await frames()
    check("G disables glow without removing geometry", not room.environment.glow_enabled and room.points.visible_instance_count != 0)
    key(KEY_G)
    room.reset_demo()
    room.capture_mode = true
    room.canvas.hide()
    room.cursor.hide()
    room.inspect(-1)
    await capture("gallery.png")
    var names := ["solid", "points", "lines", "shells", "space-brush", "painted-sphere", "slices", "memory"]
    for i in 8:
        room.inspect(i)
        room.cursor.hide()
        await capture(names[i] + ".png")
    room.inspect(5)
    room.clear_paint()
    room.cursor.hide()
    await capture("unpainted-sphere.png")
    room.reset_demo(5)
    room.inspect(2)
    room.environment.glow_enabled = false
    await capture("lines-no-glow.png")
    room.environment.glow_enabled = true
    room.inspect(7)
    # Frames from the native renderer, later assembled into a small looping preview.
    for i in 36:
        room.time = i / 36.0 * TAU / .55
        room.update_tails()
        await frames(2)
        root.get_texture().get_image().save_png(out.path_join("motion-%02d.png" % i))
    var passed := true
    for item in checks:
        passed = passed and item.passed
    var report := {"passed": passed, "checks": checks, "scope": "Native Godot 4.6 Forward+ desktop. Mouse events, ray picking, spherical paint seam/pole, bounded brush memory, animation pause and rendered views. No headset, museum collision or Web export test."}
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
    print(JSON.stringify({"passed": passed, "checks": checks.size()}))
    quit(0 if passed else 1)
