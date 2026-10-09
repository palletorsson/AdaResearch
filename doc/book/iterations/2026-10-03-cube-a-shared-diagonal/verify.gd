extends SceneTree

var out: String
var checks: Array = []
var failed := false
var room
var study

func _initialize():
    out = OS.get_cmdline_user_args()[0]
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

func open_room(shift: float = 0.0):
    if is_instance_valid(room):
        room.queue_free()
        await frames(3)
    room = load("res://point_cube.tscn").instantiate()
    study = room.get_node("Study")
    study.corner_shift = shift
    root.add_child(room)
    await frames(15)

func capture(name: String):
    await frames(4)
    check("Capture " + name, root.get_texture().get_image().save_png(out.path_join(name)) == OK)

func view():
    room.player.position = Vector3(1.6, 0, 2.05)
    room.player.camera.position.y = 2.15
    room.player.camera.look_at(study.global_position + Vector3(0,1.3,0))

func triangle(index: int) -> PackedVector3Array:
    return study.face_mesh.surface_get_arrays(index)[Mesh.ARRAY_VERTEX]

func normal(points: PackedVector3Array) -> Vector3:
    return (points[1]-points[0]).cross(points[2]-points[0]).normalized()

func emitted_matches() -> bool:
    if study.face_mesh.get_surface_count() != study.faces.size():
        return false
    for i in range(study.faces.size()):
        var row: Array = study.faces[i]
        var expected := PackedVector3Array([study.positions[row[0]],study.positions[row[1]],study.positions[row[2]]])
        if triangle(i) != expected:
            return false
    return true

func pose(tracker: XRPositionalTracker, at: Vector3):
    tracker.set_pose("grip", Transform3D(Basis.IDENTITY, at), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func run():
    await open_room()
    var initial: Array[Vector3] = study.positions.duplicate()
    var connections: Array = study.faces.duplicate(true)
    check("Eight supplied coordinates start with twelve unit-length boundary edges", initial.size() == 8 and study.edges.size() == 12)
    var unit_edges := true
    for edge in study.edges:
        unit_edges = unit_edges and is_equal_approx(study.positions[edge[0]].distance_to(study.positions[edge[1]]), 1.0)
    check("The authored boundary edges are each one metre", unit_edges)
    var incidence: Dictionary = {}
    for row in study.faces:
        for i in 3:
            var a: int = row[i]
            var b: int = row[(i+1)%3]
            var key := Vector2i(mini(a,b),maxi(a,b))
            incidence[key] = incidence.get(key,0)+1
    check("Twelve triangles close the mesh with eighteen shared edges including diagonals", study.faces.size() == 12 and incidence.size() == 18 and incidence.values().all(func(n): return n == 2))
    check("The two front triangles initially share a plane and the expected diagonal", normal(triangle(0)).is_equal_approx(normal(triangle(1))) and study.diagonal_pair == [5,7] and emitted_matches())
    check("The pink material marks only the second front patch", study.face_mesh.surface_get_material(1) == study.FoldMaterial and study.face_mesh.surface_get_material(0) == study.FaceMaterial)
    view()
    await capture("cube.png")
    var fixed_front := triangle(0)
    var moving_front := triangle(1)
    study.handles[6].position.z += 0.35
    await frames(5)
    check("Moving 6 leaves the first front triangle fixed and tilts the second", triangle(0) == fixed_front and triangle(1) != moving_front and not normal(triangle(0)).is_equal_approx(normal(triangle(1))))
    check("Only the requested coordinate changes; connections stay fixed", study.positions[6].is_equal_approx(initial[6]+Vector3(0,0,0.35)) and study.positions.slice(0,6) == initial.slice(0,6) and study.positions[7] == initial[7] and study.faces == connections and emitted_matches())
    await capture("creased.png")
    study.show_diagonal = false
    await frames(3)
    check("Hiding the guide leaves both face triangles intact", not study.diagonal.visible and triangle(0) == fixed_front and triangle(1).size() == 3)
    study.show_faces = false
    await frames(3)
    check("Hiding faces keeps eight handles and twelve edge segments", study.face_mesh.get_surface_count() == 0 and study.handles.size() == 8 and study.segments.size() == 12 and study.segments.all(func(s): return s.visible))
    await capture("wire.png")
    study.show_faces = true
    study.show_diagonal = true
    await frames(3)
    var deformed: Array[Vector3] = study.positions.duplicate()
    study.faces[0] = [4,5,6]
    study.faces[1] = [4,6,7]
    study.diagonal_pair = [4,6]
    await frames(5)
    check("Other diagonal preserves every coordinate while changing both front triangles", study.positions == deformed and triangle(0) != fixed_front and emitted_matches())
    check("Both alternate front triangles tilt away from the original front plane", not normal(triangle(0)).is_equal_approx(Vector3.BACK) and not normal(triangle(1)).is_equal_approx(Vector3.BACK))
    check("Other diagonal spans the chosen corners", study.diagonal.position.is_equal_approx((study.positions[4]+study.positions[6])*0.5) and is_equal_approx(study.diagonal.mesh.height,study.positions[4].distance_to(study.positions[6])))
    await capture("other-diagonal.png")
    study.handles[6].position = initial[6]
    await frames(3)
    check("Both alternate patches again cover the same flat square after restoration", normal(triangle(0)).is_equal_approx(Vector3.BACK) and normal(triangle(1)).is_equal_approx(Vector3.BACK))
    # Compile and run the actual two printed code edits independently of the scene.
    var changed := GDScript.new()
    changed.source_code = FileAccess.get_file_as_string("res://studies/point_cube/cube.gd").replace("var corner_shift := 0.0", "var corner_shift := 0.35").replace("[4, 5, 7], [5, 6, 7]", "[4, 5, 6], [4, 6, 7]").replace("var diagonal_pair := [5, 7]", "var diagonal_pair := [4, 6]")
    check("The printed shift and diagonal edits compile", changed.reload() == OK)
    var bare = changed.new()
    bare.position = Vector3(20,0,0)
    root.add_child(bare)
    await frames(5)
    check("Edited script constructs on a bare Node3D and reproduces the edited data", bare.handles.size() == 8 and bare.positions == deformed and bare.diagonal_pair == [4,6] and bare.faces[0] == [4,5,6])
    bare.queue_free()
    await frames(3)
    await open_room(0.35)
    check("corner_shift gives a repeatable startup edit", study.positions == deformed and study.faces == connections)
    await open_room()
    check("Restart with zero shift recovers the regular cube", study.positions == initial and study.faces == connections)
    var centre: Vector3 = study.global_position + Vector3(0,1.3,0.5)
    var query := PhysicsRayQueryParameters3D.create(centre+Vector3(0,0,0.1),centre-Vector3(0,0,0.1))
    check("Visible front surface adds no collision across its interior", study.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
    var player = room.player
    player.position = Vector3(0.5,0,1.1)
    player.camera.look_at(study.handles[6].global_position)
    await frames(3)
    player.interact()
    await frames(4)
    check("Desktop aim picks up corner 6", study.handles[6].is_picked_up())
    var before: Vector3 = study.handles[6].global_position
    var event := InputEventMouseMotion.new()
    event.relative = Vector2(100,-70)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    player._unhandled_input(event)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    await frames(6)
    check("Mouse-driven movement updates mesh neighbours while the first front patch stays fixed", study.handles[6].global_position.distance_to(before) > 0.1 and emitted_matches() and triangle(0) == fixed_front)
    player.interact()
    await frames(4)
    var released: Vector3 = study.handles[6].position
    await frames(10)
    check("Desktop release retains the edited corner", not study.handles[6].is_picked_up() and study.handles[6].position.is_equal_approx(released))
    study.handles[6].position = initial[6]
    await frames(3)
    var xr = load("res://prepared/xr_player.gd").new()
    var tracker := XRControllerTracker.new()
    tracker.name = "left_hand"
    tracker.type = XRServer.TRACKER_CONTROLLER
    tracker.hand = XRPositionalTracker.TRACKER_HAND_LEFT
    XRServer.add_tracker(tracker)
    pose(tracker,study.handles[6].global_position)
    xr.camera.position.y = 1.65
    room.add_child(xr)
    player.camera.current = true
    await frames(10)
    tracker.set_input("grip",1.0)
    await frames(5)
    check("Synthetic near grip picks up corner 6", xr.pickups[0].picked_up_object == study.handles[6])
    before = study.handles[6].global_position
    pose(tracker,before+Vector3(0,0,0.35))
    await frames(6)
    check("Synthetic hand pull creates the expected crease in the shared frame", study.handles[6].get_parent() == study and study.handles[6].global_position.z > before.z+0.2 and emitted_matches() and triangle(0) == fixed_front)
    tracker.set_input("grip",0.0)
    await frames(4)
    released = study.handles[6].position
    await frames(10)
    check("Synthetic release keeps the selected corner", not study.handles[6].is_picked_up() and study.handles[6].position.is_equal_approx(released))
    check("Repeated drawing retains twelve surfaces, twelve boundary segments and one guide", study.face_mesh.get_surface_count() == 12 and study.segments.size() == 12 and study.get_child_count() == 23)
    xr.queue_free()
    await frames(3)
    XRServer.remove_tracker(tracker)
    room.queue_free()
    await frames(3)
    FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":not failed,"checks":checks,"physical_headset_tested":false,"input":"Actual desktop handler with injected mouse motion; synthetic XR grip and poses","screenshots":"Native student room, matched elevated desktop camera"},"\t"))
    print("Cube: ",checks.size()," checks; passed: ",not failed)
    quit(1 if failed else 0)
