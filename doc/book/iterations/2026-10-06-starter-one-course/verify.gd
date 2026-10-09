extends SceneTree
## Exercises the packaged lessons, the supplied desktop adapter and real XR Tools.
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var output: String
var mode: String
var room: Node3D

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, id: String) -> void:
    checks.append({"id": id, "passed": ok})
    if not ok:
        failures.append(id)
        print("FAIL ", id)

func frames(n: int = 4) -> void:
    for i in n:
        await physics_frame
        await process_frame

func open_room(scene: String) -> Node3D:
    if is_instance_valid(room):
        room.queue_free()
        await frames(3)
    room = load("res://" + scene + ".tscn").instantiate()
    root.add_child(room)
    current_scene = room
    await frames()
    room.player.set_physics_process(false)
    return room.get_node("PointStudy")

func e_key() -> void:
    var event := InputEventKey.new()
    event.physical_keycode = KEY_E
    event.keycode = KEY_E
    event.pressed = true
    Input.parse_input_event(event)
    await frames(3)
    event = InputEventKey.new()
    event.physical_keycode = KEY_E
    event.keycode = KEY_E
    event.pressed = false
    Input.parse_input_event(event)
    await frames(2)

func archive_hash() -> String:
    var path := ProjectSettings.globalize_path("user://ada_student_trace.scn")
    return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""

func finish() -> void:
    FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify({
        "mode": mode, "passed": failures.is_empty(), "checks": checks,
        "failures": failures, "archive_sha256": archive_hash()}, "  "))
    quit(0 if failures.is_empty() else 1)

func run() -> void:
    var args := OS.get_cmdline_user_args()
    output = args[0]
    mode = args[1]
    if mode == "produce":
        await produce()
    elif mode == "close-held":
        await close_held()
    elif mode == "consume":
        await consume()
    elif mode == "checks":
        await controls_and_geometry()
    finish()

func produce() -> void:
    var trace := await open_room("point_trace")
    var point: Node3D = trace.point
    var controller := XRController3D.new()
    room.add_child(controller)
    var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
    pickup.hand_offset_mode = 4
    controller.add_child(pickup)
    controller.global_position = point.global_position
    await frames()
    pickup._pick_up_object(point)
    await frames()
    check(point.is_picked_up(), "trace/real_xr_pickup")
    check(trace.positions.size() == 1, "trace/grip_does_not_invent_a_stroke")
    for at in [Vector3(-0.5,1.12,0),Vector3(-0.5,1.75,0),Vector3(0.5,1.75,0),Vector3(0.5,1.12,0),Vector3(0,1.12,0.2)]:
        controller.global_position = trace.to_global(at)
        await frames(5)
    var count: int = trace.positions.size()
    await frames(8)
    check(trace.positions.size() == count, "trace/pause_adds_no_entry")
    check(count >= 6, "trace/held_movement_makes_the_record")
    check(trace.trail.get_child_count() == count - 1, "trace/neighbours_make_segments")
    pickup.drop_object()
    await frames(4)
    check(not archive_hash().is_empty(), "trace/intentional_release_saves")
    var archive = load("res://lessons/Point_Trace/trace_archive.gd")
    var saved: Node3D = archive.load_drawing()
    check(saved != null, "trace/archive_loads")
    if saved != null:
        check(saved.get_child_count() == count - 1, "trace/saved_geometry_not_only_positions")
        check(saved.get_meta("positions") == PackedVector3Array(trace.positions), "trace/saved_record_matches_hand")
        saved.free()
    FileAccess.open("user://expected-trace.json", FileAccess.WRITE).store_string(JSON.stringify({
        "hash": archive_hash(), "count": count}))
    # Suspending XR input is supplied lifecycle behaviour, not an intentional save.
    var xr: Node3D = load("res://prepared/xr_player.gd").new()
    room.add_child(xr)
    xr.body.enabled = false
    xr.left.global_position = point.global_position
    xr.pickups[0]._pick_up_object(point)
    xr.left.position += Vector3(0.25,0.1,0)
    await frames(4)
    var kept := archive_hash()
    xr.set_input_active(false)
    await frames(4)
    check(archive_hash() == kept, "trace/xr_focus_loss_does_not_save")
    xr.queue_free()
    await frames(2)
    # Exercise scene removal while holding, not only normal release.
    var before := archive_hash()
    pickup._pick_up_object(point)
    controller.position += Vector3(0.4,0.2,0.3)
    await frames()
    room.queue_free()
    await frames(5)
    check(archive_hash() == before, "trace/scene_removal_does_not_save")

func close_held() -> void:
    var expected = JSON.parse_string(FileAccess.get_file_as_string("user://expected-trace.json"))
    check(archive_hash() == expected.hash, "close/incoming_file_intact")
    var trace := await open_room("point_trace")
    room.player.position = Vector3(0,0,1.2)
    room.player.camera.look_at(trace.point.global_position)
    var pose: Transform3D = trace.point.global_transform
    await e_key()
    check(trace.point.is_picked_up(), "desktop/e_key_selects_the_point")
    check(trace.point.global_transform.is_equal_approx(pose), "desktop/pickup_keeps_position_and_orientation")
    check(trace.positions.size() == 1, "desktop/no_pickup_spur")
    room.player.position.x += 0.4
    await frames(6)
    check(trace.positions.size() > 1, "desktop/held_movement_reaches_the_recorder")
    check(archive_hash() == expected.hash, "close/holding_has_not_saved")
    room.player.grabber.queue_free()
    await frames(5)
    check(archive_hash() == expected.hash, "close/adapter_cleanup_does_not_save")
    room.player.grabber = load("res://prepared/desktop_grab.gd").new()
    room.player.camera.add_child(room.player.grabber)
    room.player.grabber.take(trace.point)
    await frames(3)
    check(trace.point.is_picked_up(), "close/quit_with_a_held_point")
    # finish() quits while still held. A NEW engine process checks the file afterwards.

func consume() -> void:
    var expected = JSON.parse_string(FileAccess.get_file_as_string("user://expected-trace.json"))
    check(archive_hash() == expected.hash, "grid/process_quit_did_not_overwrite_drawing")
    var grid := await open_room("point_grid")
    check(grid.sculpture != null, "grid/previous_process_drawing_arrives")
    if grid.sculpture == null:
        return
    check(grid.positions.size() == int(expected.count), "grid/the_same_sample_count")
    var original: PackedVector3Array = grid.positions.duplicate()
    var poses: Array[Transform3D] = []
    var heights: Array[float] = []
    for i in grid.sculpture.get_child_count():
        var a: MeshInstance3D = grid.sculpture.get_child(i)
        var b: MeshInstance3D = grid.grid_copy.get_child(i)
        poses.append(a.transform)
        heights.append(a.mesh.height)
        check(a.mesh != b.mesh and a.material_override != b.material_override, "grid/independent_resources_" + str(i))
    for pitch in [0.5,0.1,0.25]:
        grid.grid_step = pitch
        grid._place_on_grid()
        for i in original.size():
            var p := original[i]
            check(grid.addresses[i] == Vector3i(roundi(p.x/pitch),roundi(p.y/pitch),roundi(p.z/pitch)), "grid/address_"+str(pitch)+"/"+str(i))
        check(grid.positions == original, "grid/original_data_" + str(pitch))
        for i in poses.size():
            var segment: MeshInstance3D = grid.sculpture.get_child(i)
            check(segment.transform.is_equal_approx(poses[i]) and is_equal_approx(segment.mesh.height,heights[i]), "grid/original_geometry_"+str(pitch)+"/"+str(i))
    check(archive_hash() == expected.hash, "grid/file_unchanged_after_all_interpretations")
    var flat: Node3D = load("res://lessons/Point_Line_Grid/grid_flat_y.gd").new()
    room.add_child(flat)
    for address in flat.addresses:
        check(address.y == 0, "grid/flat_y_exercise_"+str(address))
    check(flat.positions == original and archive_hash() == expected.hash, "grid/flat_edit_preserves_source")
    var triangle := await open_room("point_triangle")
    check(triangle.handles.size() == 3, "triangle/three_selections_arrive")
    check(triangle.face.surface.mesh != null, "triangle/selected_noncollinear_face_visible")
    check(triangle.face.surface.material_override.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL, "triangle/lit_face")
    var poly := await open_room("point_polyhedra")
    check(poly.body.surface.material_override.cull_mode == BaseMaterial3D.CULL_DISABLED, "polyhedra/interior_remains_visible")
    check(poly.points.size() == 4 and poly.faces.size() == 4, "polyhedra/first_enclosure")
    var before: int = poly.body.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
    poly.faces.pop_front()
    poly.body.show_faces(poly.points,poly.faces)
    check(poly.body.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == before-3, "polyhedra/omitted_connection_opens_face")
    check(archive_hash() == expected.hash, "lineage/triangle_and_polyhedra_keep_original")

func controls_and_geometry() -> void:
    var zero := await open_room("point_zero")
    check(zero.label is Label3D and zero.label.is_inside_tree(), "zero/creates_label")
    var previous := int(zero.label.text)
    await frames(4)
    check(int(zero.label.text) > previous, "zero/reads_advancing_frame_count")
    zero.queue_free()
    await frames()
    var once: Node3D = load("res://lessons/Point_Zero/counter_once.gd").new()
    room.add_child(once)
    previous = int(once.label.text)
    await frames(4)
    check(int(once.label.text) == previous, "zero/once_edit_holds_one_reading")
    var point_one := await open_room("point_one")
    check(point_one.point is StaticBody3D, "point_one/static_body")
    check(is_equal_approx(point_one.point.get_child(0).mesh.radius,0.14), "point_one/sphere_radius")
    var coords := await open_room("point_coordinates")
    coords.position += Vector3(2,0,0)
    coords.rotation.y = 0.4
    coords._process(0)
    check(coords.point.has_method("is_picked_up"), "coordinates/pickup_is_present")
    check(coords.to_local(coords.point.global_position).is_equal_approx(coords.CENTRE), "coordinates/local_survives_moved_frame")
    check(not coords.point.global_position.is_equal_approx(coords.CENTRE), "coordinates/world_includes_frame")
    check(coords.readout.text.contains("LOCAL") and coords.readout.text.contains("WORLD"), "coordinates/readout_both_frames")
    var lines := await open_room("point_lines")
    check(is_equal_approx(lines.distance,1.0), "lines/one_metre")
    var start: Vector3 = lines.point.position
    var end: Vector3 = lines.point_b.position
    var midpoint: Vector3 = lines.line.position
    check(midpoint.is_equal_approx((start+end)/2.0), "lines/calculation_reaches_b")
    var reverse: Node3D = load("res://lessons/Point_Lines/line_reversed.gd").new()
    room.add_child(reverse)
    reverse.set_process(false)
    reverse._process(0)
    var reversed_end: Vector3 = reverse.line.position + reverse.line.basis.y*reverse.distance*0.5
    check(not reversed_end.is_equal_approx(reverse.point_b.position), "lines/reversal_visibly_misses_b")
    check(is_equal_approx(reverse.distance,lines.distance), "lines/reversal_keeps_length")
    reverse.free()
    var cube := await open_room("point_cube")
    var saved: PackedVector3Array = cube.first.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].duplicate()
    var normals_before: PackedVector3Array = cube.second.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL].duplicate()
    cube.second.points[6].z += 0.35
    cube.second.show_faces(cube.second.points,cube.second.faces)
    var normals_after: PackedVector3Array = cube.second.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
    check(normals_after != normals_before, "cube/crease_changes_lighting_normals")
    check(cube.first.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == saved, "cube/other_instance_unchanged")
    check(cube.second.surface.material_override.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL, "cube/lit_surface")
    for name in ["primitive_rules","primitive_godot","primitive_column","primitive_profiles","primitive_portals","primitive_composition"]:
        var lesson := await open_room(name)
        check(lesson.get_child_count()>0,"route/"+name+"_builds")
    var gallery: Node3D = load("res://studies/resolution_colonnade/gallery.gd").new()
    room.add_child(gallery)
    var cards := 0
    for child in gallery.architecture.get_children():
        if child is Label3D and child.text.contains("SIDES  /"):
            cards += 1
            check(is_equal_approx(child.position.y,1.0) and child.modulate.r < 0.3, "colonnade/card_"+str(cards)+"_height_contrast")
    check(cards == 25, "colonnade/every_body_has_card")
    gallery.queue_free()
    var motion: Node3D = load("res://studies/trans_pre/motion_readout.gd").new()
    room.add_child(motion)
    motion.show_values(0,1,0.7,1.3)
    check(not motion.values.text.contains("    t ="), "motion/no_untaught_t_at_stage_zero")
    motion.show_values(1,1,0.7,1.3)
    check(motion.values.text.contains("    t ="), "motion/t_appears_with_motion")
