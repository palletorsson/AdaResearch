extends SceneTree

var out: String
var checks: Array = []
var failed := false
var room
var study
var sphere

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

func capture(name: String):
    await frames(4)
    check("Capture " + name, root.get_texture().get_image().save_png(out.path_join(name)) == OK)

func emitted_matches() -> bool:
    var points: PackedVector3Array = study.face_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    if points.size() != 24:
        return false
    for i in range(study.faces.size()):
        for j in 3:
            if not points[i*3+j].is_equal_approx(study.positions[study.faces[i][j]]):
                return false
    return true

func actual_triangle_edges(mesh: Mesh) -> Dictionary:
    var arrays := mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    var result: Dictionary = {}
    for i in range(0,indices.size(),3):
        var corners := [vertices[indices[i]],vertices[indices[i+1]],vertices[indices[i+2]]]
        if (corners[1]-corners[0]).cross(corners[2]-corners[0]).length_squared() < 0.000000000001:
            continue
        for j in 3:
            var a: Vector3 = corners[j].snapped(Vector3.ONE*0.00001)
            var b: Vector3 = corners[(j+1)%3].snapped(Vector3.ONE*0.00001)
            result[[a,b] if a < b else [b,a]] = true
    return result

func guides_match() -> bool:
    var expected := actual_triangle_edges(sphere.sphere_mesh)
    if sphere.edge_view.segments.size() != expected.size():
        return false
    for edge in sphere.edge_view.segments:
        var offset: Vector3 = edge.quaternion * Vector3.UP * edge.mesh.height * 0.5
        var a: Vector3 = (edge.position-offset).snapped(Vector3.ONE*0.00001)
        var b: Vector3 = (edge.position+offset).snapped(Vector3.ONE*0.00001)
        if not expected.has([a,b] if a < b else [b,a]):
            return false
    return true

func pose(tracker: XRPositionalTracker, at: Vector3):
    tracker.set_pose("grip", Transform3D(Basis.IDENTITY,at),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func run():
    room = load("res://primitive_rules.tscn").instantiate()
    study = room.get_node("Octahedron")
    sphere = room.get_node("Sphere")
    root.add_child(room)
    await frames(15)
    room.player.position = Vector3(0.65,0,3.1)
    room.player.camera.position.y = 2.05
    room.player.camera.look_at(Vector3(0,1.45,-0.7))
    var initial: Array[Vector3] = study.positions.duplicate()
    check("Generator returns the declared six signed-axis points in order", initial == [Vector3(0.55,0,0),Vector3(-0.55,0,0),Vector3(0,0.55,0),Vector3(0,-0.55,0),Vector3(0,0,0.55),Vector3(0,0,-0.55)])
    var count: int = study.get_child_count()
    var bigger: Array[Vector3] = study.octahedron_positions(0.75)
    check("Calling the function changes neither the visible study nor its child count", study.positions == initial and study.get_child_count() == count)
    var equal_radius := true
    for i in 6:
        equal_radius = equal_radius and is_equal_approx(bigger[i].length(),0.75) and bigger[i].is_equal_approx(initial[i]*(0.75/0.55))
    check("A second positive argument changes radius and preserves direction", equal_radius)
    var independent: Array[Vector3] = study.octahedron_positions(0.55)
    independent[0] = Vector3.ONE
    check("Each call returns an independent list", study.positions == initial and study.octahedron_positions(0.55) == initial)
    var incidence: Dictionary = {}
    var regular := true
    var outward := true
    for row in study.faces:
        var a: Vector3 = initial[row[0]]
        var b: Vector3 = initial[row[1]]
        var c: Vector3 = initial[row[2]]
        outward = outward and (b-a).cross(c-a).dot((a+b+c)/3) > 0
        for i in 3:
            var first: int = row[i]
            var second: int = row[(i+1)%3]
            var key := Vector2i(mini(first,second),maxi(first,second))
            incidence[key] = incidence.get(key,0)+1
            regular = regular and is_equal_approx(initial[first].distance_to(initial[second]),sqrt(2)*0.55)
    check("Supplied connectivity closes eight equilateral faces around twelve shared edges", regular and outward and study.faces.size()==8 and incidence.size()==12 and incidence.values().all(func(n):return n==2))
    check("Rendered vertices use the generated positions through face rows", emitted_matches())
    var sphere_vertices: PackedVector3Array = sphere.sphere_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    check("Sphere starts at the same radius with eight radial and four height divisions", sphere.sphere_mesh.radial_segments==8 and sphere.sphere_mesh.rings==4 and is_equal_approx(sphere.sphere_mesh.radius,0.55) and is_equal_approx(sphere.sphere_mesh.height,1.1))
    check("Guide follows actual non-degenerate mesh edges without duplicate seam strokes", guides_match())
    await capture("room.png")
    # Run the literal learner edit on a bare Node3D.
    var edited := GDScript.new()
    edited.source_code = FileAccess.get_file_as_string("res://studies/primitive_rules/octahedron.gd").replace("positions = octahedron_positions(0.55)","positions = octahedron_positions(0.75)")
    check("The printed radius edit compiles", edited.reload()==OK)
    var bare = edited.new()
    bare.position = Vector3(20,1.4,0)
    root.add_child(bare)
    await frames(5)
    check("Edited script runs without authored child nodes", bare.positions==bigger and bare.handles.size()==6 and bare.face_mesh.get_surface_count()==1)
    bare.queue_free()
    for i in 6:
        study.handles[i].position = bigger[i]
    await frames(3)
    await capture("radius.png")
    for i in 6:
        study.handles[i].position = initial[i]
    study.handles[2].position.x += 0.3
    await frames(8)
    check("Handle edit persists between frames and updates incident faces", not is_equal_approx(study.positions[2].length(),0.55) and study.positions[2].is_equal_approx(initial[2]+Vector3(0.3,0,0)) and emitted_matches())
    check("The generator is not called to constrain edits during processing", study.positions[2] != study.octahedron_positions(0.55)[2])
    await capture("edited.png")
    study.handles[2].position = initial[2]
    for radial in [16,8]:
        var ring_count := 4 if radial==16 else 8
        var sphere_edit := GDScript.new()
        sphere_edit.source_code = FileAccess.get_file_as_string("res://studies/primitive_rules/sphere.gd").replace("sphere_mesh.radial_segments = 8","sphere_mesh.radial_segments = "+str(radial)).replace("sphere_mesh.rings = 4","sphere_mesh.rings = "+str(ring_count))
        check("Printed sphere setting edit compiles: %d/%d" % [radial,ring_count],sphere_edit.reload()==OK)
        var specimen = sphere_edit.new()
        specimen.position = sphere.position
        room.add_child(specimen)
        sphere.queue_free()
        sphere = specimen
        await frames(5)
        var changed: PackedVector3Array = sphere.sphere_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        check("Setting changes generated geometry while keeping dimensions: %d/%d" % [radial,ring_count],changed.size()>sphere_vertices.size() and is_equal_approx(sphere.sphere_mesh.radius,0.55) and is_equal_approx(sphere.sphere_mesh.height,1.1) and sphere.sphere_mesh.radial_segments==radial and sphere.sphere_mesh.rings==ring_count)
        check("Guide reflects edited source: %d/%d" % [radial,ring_count],guides_match())
        await capture("sphere-%d-%d.png" % [radial,ring_count])
    var guide_count: int = sphere.edge_view.segments.size()
    sphere.edge_view.show_edges(sphere.sphere_mesh)
    await frames(4)
    check("Rebuilding the guide replaces old strokes", guides_match() and sphere.edge_view.get_child_count()==guide_count)
    var centroid: Vector3 = study.global_position+(initial[2]+initial[4]+initial[0])/3
    var normal := Vector3.ONE.normalized()
    var query := PhysicsRayQueryParameters3D.create(centroid+normal*0.08,centroid-normal*0.08)
    check("Visible face interior has no added collider", study.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
    var player = room.player
    player.position = Vector3(-1,0,1.1)
    player.camera.look_at(study.handles[4].global_position)
    await frames(3)
    player.interact()
    await frames(4)
    check("Desktop aim picks up the local positive-Z point", study.handles[4].is_picked_up())
    var before: Vector3 = study.handles[4].position
    var event := InputEventMouseMotion.new()
    event.relative = Vector2(90,-60)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    player._unhandled_input(event)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    await frames(6)
    check("Mouse movement edits data in the translated study frame", study.handles[4].position.distance_to(before)>0.1 and emitted_matches())
    player.interact()
    await frames(3)
    var released: Vector3 = study.handles[4].position
    await frames(8)
    check("Desktop release retains the new position", not study.handles[4].is_picked_up() and study.positions[4].is_equal_approx(released))
    study.handles[4].position = initial[4]
    var xr = load("res://prepared/xr_player.gd").new()
    var tracker := XRControllerTracker.new()
    tracker.name = "left_hand"
    tracker.type = XRServer.TRACKER_CONTROLLER
    tracker.hand = XRPositionalTracker.TRACKER_HAND_LEFT
    XRServer.add_tracker(tracker)
    pose(tracker,study.handles[4].global_position)
    xr.camera.position.y = 1.65
    room.add_child(xr)
    player.camera.current = true
    await frames(10)
    tracker.set_input("grip",1.0)
    await frames(5)
    check("Synthetic near grip picks up the translated study handle", xr.pickups[0].picked_up_object==study.handles[4])
    before = study.handles[4].global_position
    pose(tracker,before+Vector3(0.3,0,0))
    await frames(6)
    check("Synthetic hand moves the point and its incident triangles", study.handles[4].global_position.x>before.x+0.2 and emitted_matches())
    tracker.set_input("grip",0.0)
    await frames(4)
    released = study.handles[4].position
    await frames(8)
    check("Synthetic release retains the edit", not study.handles[4].is_picked_up() and study.positions[4].is_equal_approx(released))
    xr.queue_free()
    await frames(3)
    XRServer.remove_tracker(tracker)
    var restart = load("res://studies/primitive_rules/octahedron.gd").new()
    restart.position = Vector3(20,1.4,0)
    root.add_child(restart)
    await frames(5)
    check("A fresh instance restores generated data without sharing the edited list", restart.positions==initial and study.positions!=initial)
    check("Repeated updates retain a fixed six handles, twelve edges and one surface", study.handles.size()==6 and study.segments.size()==12 and study.face_mesh.get_surface_count()==1 and study.get_child_count()==count)
    restart.queue_free()
    room.queue_free()
    await frames(4)
    FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":not failed,"checks":checks,"physical_headset_tested":false,"input":"Actual desktop mouse handler; synthetic XR grip and poses","screenshots":"Native student room"},"\t"))
    print("Primitive rules: ",checks.size()," checks; passed: ",not failed)
    quit(1 if failed else 0)
