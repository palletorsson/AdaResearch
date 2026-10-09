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
    room = load("res://point_polyhedra.tscn").instantiate()
    study = room.get_node("Study")
    root.add_child(room)
    await frames(15)

func capture(name: String):
    await frames(4)
    check("Capture " + name, root.get_texture().get_image().save_png(out.path_join(name)) == OK)

func vertices() -> PackedVector3Array:
    return study.face_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func expected_vertices() -> PackedVector3Array:
    var result := PackedVector3Array()
    for row in study.faces:
        for i in row:
            result.append(study.handles[i].position)
    return result

func free_edges(rows: Array) -> int:
    var counts: Dictionary = {}
    for row in rows:
        for j in 3:
            var a: int = row[j]
            var b: int = row[(j + 1) % 3]
            var key := Vector2i(mini(a,b), maxi(a,b))
            counts[key] = counts.get(key, 0) + 1
    var free := 0
    for count in counts.values():
        if count == 1:
            free += 1
    return free

func volume_measure(points: Array[Vector3]) -> float:
    return absf((points[1] - points[0]).dot((points[2] - points[0]).cross(points[3] - points[0]))) / 6.0

func pose(tracker: XRPositionalTracker, at: Vector3):
    tracker.set_pose("grip", Transform3D(Basis.IDENTITY, at), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func run():
    Memory.save_trace([Vector3.ZERO, Vector3.ONE])
    await open_room()
    check("Short trace produces an instruction, no substitute geometry", study.handles.is_empty() and not study.is_processing() and "at least three" in study.readout.text)
    await capture("empty.png")
    check("Original Trace release record exists", FileAccess.file_exists(source_path))
    var record := FileAccess.get_file_as_string(source_path)
    FileAccess.open(Memory.path, FileAccess.WRITE).store_string(record)
    var original := Memory.read_trace()
    var source_hash := FileAccess.get_sha256(Memory.path)
    await open_room()
    var third := original.size() / 3
    check("Earlier three positions return unchanged as rim vertices", study.positions.slice(1) == [original[0], original[third], original[third * 2]])
    var centre: Vector3 = (original[0] + original[third] + original[third * 2]) / 3.0
    check("Fourth point is the declared Z offset from their centre", study.positions[0].is_equal_approx(centre + Vector3(0,0,-0.7)))
    check("Four editable corners and six boundary segments are constructed", study.handles.size() == 4 and study.segments.size() == 6)
    check("Three face rows submit nine correct positions and leave a three-edge rim", vertices().size() == 9 and vertices() == expected_vertices() and free_edges(study.faces) == 3)
    room.player.position = Vector3(-0.2, 0, 1.6)
    room.player.camera.look_at(study.global_position + centre)
    await capture("open.png")
    var saved_positions: Array[Vector3] = study.positions.duplicate()
    study.faces.append([1, 3, 2])
    await frames(5)
    check("Adding the fourth row closes the rim without moving any position", vertices().size() == 12 and vertices() == expected_vertices() and free_edges(study.faces) == 0 and study.positions == saved_positions)
    check("The retained trace fixture supplies a nonzero tetrahedron volume", volume_measure(study.positions) > 0.01)
    await capture("closed.png")
    study.faces.pop_back()
    await frames(3)
    check("Removing the row restores the opening and preserves all four vertices", study.positions == saved_positions and vertices().size() == 9 and free_edges(study.faces) == 3)
    # An actual edited script with the printed extra row must also compile and construct.
    var edited := GDScript.new()
    edited.source_code = FileAccess.get_file_as_string("res://studies/point_polyhedra/polyhedra.gd").replace("    [0, 3, 1],", "    [0, 3, 1],\n    [1, 3, 2],")
    check("The printed one-row code edit compiles", edited.reload() == OK)
    var bare = edited.new()
    bare.position = Vector3(20, 0, 0)
    root.add_child(bare)
    await frames(4)
    check("Edited lesson constructs four faces on a bare Node3D", bare.handles.size() == 4 and bare.faces.size() == 4 and bare.face_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 12)
    bare.queue_free()
    await frames(3)
    study.faces.append([1, 3, 2])
    await frames(3)
    var rim_before: PackedVector3Array = vertices().slice(9,12)
    study.handles[0].position += Vector3(-0.25,0.25,-0.2)
    await frames(5)
    check("Moving apex updates its three faces while the opposite face stays fixed", vertices() == expected_vertices() and vertices().slice(9,12) == rim_before)
    check("Repeated updates keep one mesh surface and six segment nodes", study.face_mesh.get_surface_count() == 1 and study.segments.size() == 6)
    study.handles[0].position = centre
    await frames(4)
    check("Four coplanar points enclose zero volume despite four face rows", study.faces.size() == 4 and volume_measure(study.positions) < 0.000001)
    await capture("coplanar.png")
    study.handles[0].position = saved_positions[0]
    await frames(4)
    check("Moving apex out of the plane restores nonzero volume", volume_measure(study.positions) > 0.01)
    var rim_centre: Vector3 = (study.handles[1].global_position + study.handles[2].global_position + study.handles[3].global_position) / 3.0
    var normal: Vector3 = (study.handles[2].global_position-study.handles[1].global_position).cross(study.handles[3].global_position-study.handles[1].global_position).normalized()
    var query := PhysicsRayQueryParameters3D.create(rim_centre + normal * 0.12, rim_centre - normal * 0.12)
    check("Closing the visible rim does not introduce a collision surface", study.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
    # Move a front rim corner through the real desktop pickup path.
    var player = room.player
    player.position = Vector3(study.handles[2].global_position.x,0,0.65)
    player.camera.look_at(study.handles[2].global_position)
    await frames(3)
    player.interact()
    await frames(4)
    check("Desktop aim picks up a numbered corner", study.handles[2].is_picked_up())
    var before: Vector3 = study.handles[2].global_position
    var event := InputEventMouseMotion.new()
    event.relative = Vector2(110,-90)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    player._unhandled_input(event)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    await frames(6)
    check("Mouse movement updates all faces referring to the moved vertex", study.handles[2].global_position.distance_to(before) > 0.1 and vertices() == expected_vertices())
    player.interact()
    await frames(4)
    var released: Vector3 = study.handles[2].position
    await frames(10)
    check("Desktop release retains the edited position without saving over Trace", study.handles[2].position.is_equal_approx(released) and not study.handles[2].is_picked_up() and FileAccess.get_sha256(Memory.path) == source_hash)
    var xr = load("res://prepared/xr_player.gd").new()
    var tracker := XRControllerTracker.new()
    tracker.name = "left_hand"
    tracker.type = XRServer.TRACKER_CONTROLLER
    tracker.hand = XRPositionalTracker.TRACKER_HAND_LEFT
    XRServer.add_tracker(tracker)
    pose(tracker, study.handles[1].global_position)
    xr.camera.position.y = 1.65
    room.add_child(xr)
    player.camera.current = true
    await frames(10)
    tracker.set_input("grip",1.0)
    await frames(5)
    check("Synthetic XR near grip picks up the corner", xr.pickups[0].picked_up_object == study.handles[1])
    before = study.handles[1].global_position
    pose(tracker,before + Vector3(-0.3,0.2,0.2))
    await frames(6)
    check("Synthetic hand movement retains the shared frame and face connections", study.handles[1].get_parent() == study and study.handles[1].global_position.distance_to(before)>0.2 and vertices() == expected_vertices())
    tracker.set_input("grip",0.0)
    await frames(5)
    released = study.handles[1].position
    await frames(10)
    check("XR release holds its corner without altering the source file", study.handles[1].position.is_equal_approx(released) and not study.handles[1].is_picked_up() and FileAccess.get_sha256(Memory.path) == source_hash)
    xr.queue_free()
    await frames(3)
    XRServer.remove_tracker(tracker)
    await open_room()
    check("Restart recovers original positions and the open face list", study.positions == saved_positions and study.faces.size() == 3)
    study.faces.clear()
    await frames(3)
    check("Empty face list keeps the wire structure without an invalid submission", study.face_mesh.get_surface_count() == 0 and study.segments.size() == 6 and study.handles.size() == 4)
    room.queue_free()
    await frames(3)
    FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":not failed,"checks":checks,"source_points":original.size(),"source_sha256":source_hash,"physical_headset_tested":false,"source_record":"Same synthetic XR release record used in Trace, Grid and Triangle"},"\t"))
    print("Polyhedra: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
