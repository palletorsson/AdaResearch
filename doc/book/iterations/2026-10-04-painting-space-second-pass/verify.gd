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
    check("Zero-length picking ray is rejected", room.sphere_hit(room.centres[5], Vector3.ZERO).is_empty())
    room.inspect(4)
    check("Focus leaves only the selected station visible", room.stage_roots.filter(func(n): return n.visible).size() == 1 and not room.backdrop.visible)
    room.clear_brush()
    room.has_last_sample = false
    room.sample_stroke({"position": room.centres[4] + Vector3(-.7, 0, 0)})
    room.sample_stroke({"position": room.centres[4] + Vector3(.7, 0, 0)})
    check("Fast space stroke receives intermediate samples", room.brush_count > 20)
    var stroke_count: int = room.brush_count
    var stroke_position: Vector3 = room.brush_state[8].position
    key(KEY_B)
    await frames()
    check("B changes material while retaining the drawing", room.brush_style == 1 and room.brush_count == stroke_count and room.brush.get_instance_transform(8).origin.is_equal_approx(stroke_position))
    check("Only one brush representation is visible", room.brush_forms.filter(func(m): return m.visible_instance_count > 0).size() == 1)
    key(KEY_X)
    key(KEY_BRACKETRIGHT)
    await frames()
    check("Colour and size controls change the next mark", room.ink_index == 1 and room.brush_radius > .2)
    room.stamp_space(room.centres[4])
    check("Chosen colour is stored with the mark", room.brush_state[room.brush_next - 1].colour == room.PALETTE[1])
    room.undo_stack.clear()
    room.remember_undo()
    room.clear_brush()
    check("Undo restores cleared space marks", room.undo() and room.brush_count == stroke_count + 1)
    room.inspect(5)
    room.clear_paint()
    room.has_last_sample = false
    var start := Vector3(-.55, 0, 1).normalized()
    var finish := Vector3(.55, 0, 1).normalized()
    room.sample_stroke({"position": room.centres[5] + start * room.RADIUS, "direction": start})
    room.sample_stroke({"position": room.centres[5] + finish * room.RADIUS, "direction": finish})
    check("Fast surface stroke paints between pointer samples", room.paint_image.get_pixel(384, 128).a > .5)
    var painted_bytes: PackedByteArray = room.paint_image.get_data()
    room.remember_undo()
    room.clear_paint()
    check("Undo restores surface paint exactly", room.undo() and room.paint_image.get_data() == painted_bytes)
    var original_position: Vector3 = room.brush_state[8].position
    var save_path := out.path_join("verification-only.save")
    check("Drawing can be saved", room.save_drawing(save_path))
    room.clear_brush()
    room.clear_paint()
    check("Saved drawing can be loaded", room.load_drawing(save_path))
    check("Both paint and 3D mark positions survive save/load", room.paint_image.get_data() == painted_bytes and room.brush_state[8].position == original_position and room.brush_count == stroke_count + 1)
    var bad: Dictionary = room.snapshot()
    bad.radius = -1.0
    check("Invalid saved state is rejected without changing the drawing", not room.restore_snapshot(bad) and room.paint_image.get_data() == painted_bytes)
    check("Test save cleaned up", DirAccess.remove_absolute(save_path) == OK)
    room.ink_index = 0
    room.brush_radius = .20
    room.set_brush_style(0)
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
    room.inspect(4)
    room.set_brush_style(1)
    await capture("brush-bubbles.png")
    room.set_brush_style(2)
    await capture("brush-light.png")
    room.set_brush_style(0)
    # A second viewpoint tests parallax for the same saved marks.
    room.yaw = 1.1
    room.pitch = .35
    room.update_camera()
    await capture("brush-side.png")
    room.inspect(4)
    room.canvas.show()
    room.capture_mode = false
    screen = room.camera.unproject_position(room.centres[4])
    click(screen, false)
    await capture("drawing-controls.png")
    check("Depth guide appears at the current brush", room.guide.visible and room.cursor.visible)
    room.canvas.hide()
    room.capture_mode = true
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
    for i in 120:
        room.time = i / 120.0 * TAU / .55
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
