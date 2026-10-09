extends SceneTree

const Memory = preload("res://prepared/trace_memory.gd")
var out: String
var source_path: String
var checks: Array = []
var failed := false
var room
var study

func _initialize():
    out = OS.get_cmdline_user_args()[0]
    source_path = OS.get_cmdline_user_args()[1]
    Memory.path = out.path_join("test-record.json")
    run.call_deferred()

func check(label: String, passed: bool):
    checks.append({"check": label, "passed": passed})
    if not passed:
        failed = true
        push_error(label)

func frames(count: int):
    for i in count:
        await physics_frame
    await process_frame
    await RenderingServer.frame_post_draw

func open_room():
    if is_instance_valid(room):
        room.queue_free()
        await frames(3)
    room = load("res://point_triangle.tscn").instantiate()
    study = room.get_node("Study")
    root.add_child(room)
    await frames(15)

func capture(name: String):
    await frames(3)
    check("Capture " + name, root.get_texture().get_image().save_png(out.path_join(name)) == OK)

func vertices() -> PackedVector3Array:
    return study.face_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func current_vertices() -> PackedVector3Array:
    return PackedVector3Array([study.a.position, study.b.position, study.c.position])

func pose(tracker: XRPositionalTracker, at: Vector3):
    tracker.set_pose("grip", Transform3D(Basis.IDENTITY, at), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func run():
    Memory.save_trace([Vector3.ZERO, Vector3.ONE])
    await open_room()
    check("A two-position record stops honestly without inventing a triangle", not study.is_processing() and not study.a.visible and study.face_mesh.get_surface_count() == 0 and "at least three" in study.readout.text)
    await capture("empty.png")
    # Continue the exact record generated through grip/release in the prior lesson test.
    check("Prior Trace release record exists", FileAccess.file_exists(source_path))
    var record := FileAccess.get_file_as_string(source_path)
    FileAccess.open(Memory.path, FileAccess.WRITE).store_string(record)
    var original := Memory.read_trace()
    var source_hash := FileAccess.get_sha256(Memory.path)
    await open_room()
    check("Triangle reads the same original used by Grid", original.size() > 3 and study.source_points == original)
    var third := original.size() / 3
    check("Selection takes original indices without snapping, flattening or fitting", current_vertices() == PackedVector3Array([original[0], original[third], original[third * 2]]))
    check("Closed outline alone creates no face", study.ab.visible and study.bc.visible and study.ca.visible and study.face_mesh.get_surface_count() == 0)
    room.player.position = Vector3(0, 0, 1.7)
    room.player.camera.look_at(study.global_position + Vector3(0, 1.4, 0))
    await capture("outline.png")
    study.show_face = true
    await frames(5)
    check("Explicit triangle submission uses the same three positions", study.face_mesh.get_surface_count() == 1 and vertices() == current_vertices())
    check("Face material displays both sides and needs no normals", study.face.material_override.cull_mode == BaseMaterial3D.CULL_DISABLED and study.face.material_override.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED)
    await capture("face.png")
    var original_vertices := current_vertices()
    room.player.position = Vector3(0, 0, -2.0)
    room.player.camera.look_at(study.global_position + Vector3(0, 1.35, 0))
    await capture("back.png")
    check("Changing the view leaves submitted positions unchanged", vertices() == original_vertices)
    room.player.position = Vector3(0, 0, 1.7)
    room.player.camera.look_at(study.global_position + Vector3(0, 1.4, 0))
    study.c.position = (study.a.position + study.b.position) * 0.5
    await frames(4)
    var submitted := vertices()
    check("Collinear corners retain three vertices with zero area", submitted.size() == 3 and (submitted[1] - submitted[0]).cross(submitted[2] - submitted[0]).length() < 0.000001)
    await capture("collinear.png")
    study.c.position = study.a.position
    await frames(3)
    check("Coincident corner hides its zero-length boundary segment", not study.ca.visible and vertices() == current_vertices())
    study.c.position = original_vertices[2]
    await frames(6)
    check("Separating corners recovers the face without accumulating surfaces", study.ca.visible and study.face_mesh.get_surface_count() == 1 and vertices() == original_vertices)
    study.show_face = false
    await frames(3)
    check("Removing fill preserves the handles and segments", study.face_mesh.get_surface_count() == 0 and study.a.visible and study.ab.visible and study.ca.visible)
    study.show_face = true
    await frames(3)
    var centre: Vector3 = (study.a.global_position + study.b.global_position + study.c.global_position) / 3.0
    var normal: Vector3 = (study.b.global_position - study.a.global_position).cross(study.c.global_position - study.a.global_position).normalized()
    var ray := PhysicsRayQueryParameters3D.create(centre + normal * 0.15, centre - normal * 0.15)
    check("Visible face has no collision at its interior", study.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
    var player = room.player
    player.position = Vector3(study.c.global_position.x, 0, 0.65)
    player.camera.look_at(study.c.global_position)
    await frames(3)
    player.interact()
    await frames(4)
    check("Desktop aim picks up a triangle corner", study.c.is_picked_up())
    var before: Vector3 = study.c.global_position
    var event := InputEventMouseMotion.new()
    event.relative = Vector2(130, -100)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    player._unhandled_input(event)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    await frames(6)
    check("Mouse-driven corner movement rebuilds the face", study.c.global_position.distance_to(before) > 0.1 and vertices() == current_vertices())
    player.interact()
    await frames(4)
    var released: Vector3 = study.c.position
    await frames(12)
    check("Release retains the edited corner and leaves the original record untouched", not study.c.is_picked_up() and study.c.position.is_equal_approx(released) and study.source_points == original and FileAccess.get_sha256(Memory.path) == source_hash)
    var xr = load("res://prepared/xr_player.gd").new()
    var tracker := XRControllerTracker.new()
    tracker.name = "left_hand"
    tracker.type = XRServer.TRACKER_CONTROLLER
    tracker.hand = XRPositionalTracker.TRACKER_HAND_LEFT
    XRServer.add_tracker(tracker)
    pose(tracker, study.a.global_position)
    xr.camera.position.y = 1.65
    room.add_child(xr)
    player.camera.current = true
    await frames(10)
    tracker.set_input("grip", 1.0)
    await frames(5)
    check("Synthetic XR grip picks up the same kind of corner", xr.pickups[0].picked_up_object == study.a)
    before = study.a.global_position
    pose(tracker, before + Vector3(-0.3, 0.2, 0.25))
    await frames(6)
    check("XR corner movement changes depth and preserves the shared frame", study.a.get_parent() == study and study.a.global_position.distance_to(before) > 0.2 and vertices() == current_vertices())
    tracker.set_input("grip", 0.0)
    await frames(5)
    released = study.a.position
    await frames(10)
    check("XR release keeps the edited corner without saving over Trace", not study.a.is_picked_up() and study.a.position.is_equal_approx(released) and FileAccess.get_sha256(Memory.path) == source_hash)
    xr.queue_free()
    await frames(3)
    XRServer.remove_tracker(tracker)
    await open_room()
    check("Restart selects the original saved corners again", current_vertices() == original_vertices and not study.show_face)
    Memory.save_trace([Vector3(-0.7,1,0), Vector3(0.7,1,0), Vector3(0,2,0)])
    await open_room()
    check("Exactly three entries select three distinct list indices", study.a.position == Vector3(-0.7,1,0) and study.b.position == Vector3(0.7,1,0) and study.c.position == Vector3(0,2,0))
    FileAccess.open(Memory.path, FileAccess.WRITE).store_string(record)
    room.queue_free()
    await frames(3)
    var bare = load("res://studies/point_triangle/triangle.gd").new()
    root.add_child(bare)
    await frames(3)
    check("Lesson constructs all its objects on a bare Node3D", bare.get_child_count() == 8 and bare.source_points == original)
    bare.queue_free()
    await frames(3)
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "checks": checks, "source_points": original.size(), "selected_indices": [0, third, third * 2], "physical_headset_tested": false, "source_record": "Exact synthetic XR release record from trace-return-to-grid", "source_sha256": source_hash}, "\t"))
    print("Triangle: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
