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

func frames(count := 4):
    for i in count:
        await physics_frame
    await process_frame
    await RenderingServer.frame_post_draw

func capture(name: String):
    await frames()
    check("Native capture: " + name, root.get_texture().get_image().save_png(out.path_join(name)) == OK)

func face_vertices(mesh: Mesh) -> PackedVector3Array:
    return mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func closed_outward(mesh: Mesh, expected_triangles: int) -> bool:
    var data := mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
    if vertices.size() != expected_triangles * 3:
        return false
    var edges: Dictionary = {}
    var volume := 0.0
    for i in range(0, vertices.size(), 3):
        var a := vertices[i]
        var b := vertices[i + 1]
        var c := vertices[i + 2]
        var cross := (b - a).cross(c - a)
        if cross.length_squared() < 1e-12 or not normals[i].is_normalized() or cross.dot(normals[i]) >= 0:
            return false
        volume -= a.dot(b.cross(c)) / 6.0 # Godot uses clockwise front faces.
        for pair in [[a, b], [b, c], [c, a]]:
            var p: Vector3 = pair[0].snapped(Vector3.ONE * 0.00001)
            var q: Vector3 = pair[1].snapped(Vector3.ONE * 0.00001)
            var key := [p, q] if p < q else [q, p]
            edges[key] = edges.get(key, 0) + 1
    return volume > 0 and edges.values().all(func(n): return n == 2)

func source_edit(path: String, changes: Dictionary):
    var code := GDScript.new()
    code.source_code = FileAccess.get_file_as_string(path)
    for before in changes:
        check("Edit target exists: " + before, code.source_code.contains(before))
        code.source_code = code.source_code.replace(before, changes[before])
    check("Edited learner script compiles: " + path.get_file(), code.reload() == OK)
    var instance = code.new()
    instance.position = study.position
    room.remove_child(study)
    study.free()
    study = instance
    room.add_child(study)
    await frames()

func data_copy(mesh: Mesh) -> PackedVector3Array:
    return face_vertices(mesh).duplicate()

func run():
    room = load("res://primitive_column.tscn").instantiate()
    root.add_child(room)
    study = room.get_node("Column")
    await frames(16)
    room.player.position = Vector3(1.2, 0, 3.1)
    room.player.camera.look_at(Vector3(0, 1.2, -0.7))
    var original: Array[Vector3] = study.positions.duplicate()
    var original_mesh := data_copy(study.surface.mesh)
    check("Seven rings of eight positions, from floor to full height", original.size() == 56 and is_equal_approx(original[0].y, 0) and is_equal_approx(original[-1].y, 2.2))
    var radii_match := true
    for ring in 7:
        for side in 8:
            var p: Vector3 = original[ring * 8 + side]
            radii_match = radii_match and is_equal_approx(Vector2(p.x, p.z).length(), study.profile[ring]) and is_equal_approx(p.y, ring * 2.2 / 6)
    check("Every stored radius maps to its own evenly placed ring", radii_match)
    check("Column seams and both caps close with outward normals", closed_outward(study.surface.mesh, 112))
    # An independent cylinder formula checks the builder's volume and winding.
    var straight_profile: Array[float] = [0.5, 0.5]
    var cylinder: Array[Vector3] = study.column_positions(straight_profile, 2.0, 4)
    var mesh: Mesh = study.ColumnSurface.make(cylinder, 4)
    var v := face_vertices(mesh)
    var volume := 0.0
    for i in range(0, v.size(), 3):
        volume -= v[i].dot(v[i + 1].cross(v[i + 2])) / 6.0
    check("Four-sided constant profile encloses the independent expected volume 1 cubic metre", is_equal_approx(volume, 1.0) and closed_outward(mesh, 16))
    var fresh: Array[Vector3] = study.column_positions(study.profile, study.height, study.sides)
    fresh[0] += Vector3.ONE
    check("Returned data is independent of the visible column", study.positions == original and data_copy(study.surface.mesh) == original_mesh)
    await capture("column.png")

    var column_path := "res://studies/primitive_column/column.gd"
    await source_edit(column_path, {"0.22": "0.55"})
    var changed_ring_only := true
    for i in original.size():
        if i >= 24 and i < 32:
            changed_ring_only = changed_ring_only and is_equal_approx(study.positions[i].y, original[i].y) and is_equal_approx(Vector2(study.positions[i].x, study.positions[i].z).length(), 0.55)
        else:
            changed_ring_only = changed_ring_only and study.positions[i] == original[i]
    check("Printed profile edit changes only the middle ring, keeping height and side count", changed_ring_only and study.sides == 8 and is_equal_approx(study.height, 2.2))
    check("Bulged profile still closes with correct lighting normals", closed_outward(study.surface.mesh, 112))
    await capture("bulge.png")

    await source_edit(column_path, {"var height := 2.2": "var height := 1.6"})
    var width_kept := true
    for i in original.size():
        width_kept = width_kept and is_equal_approx(study.positions[i].x, original[i].x) and is_equal_approx(study.positions[i].z, original[i].z) and is_equal_approx(study.positions[i].y, original[i].y * 1.6 / 2.2)
    check("Printed height edit scales only Y and keeps the base on the floor", width_kept)
    await capture("height.png")

    for sides in [4, 6, 8, 12, 16]:
        await source_edit(column_path, {"var sides := 8": "var sides := " + str(sides)})
        var correct: bool = study.positions.size() == 7 * sides
        for ring in 7:
            for side in sides:
                var p: Vector3 = study.positions[ring * sides + side]
                correct = correct and is_equal_approx(Vector2(p.x, p.z).length(), study.profile[ring]) and is_equal_approx(p.y, ring * 2.2 / 6)
        check("Resolution %d preserves every radius and height and closes all faces" % sides, correct and closed_outward(study.surface.mesh, 14 * sides))
        if sides in [4, 16]:
            await capture("sides-%d.png" % sides)
    # Exercise supported bounds without attaching the high-detail mesh to the scene.
    var simple_profile: Array[float] = [0.3, 0.4]
    var simple: Array[Vector3] = study.column_positions(simple_profile, 0.8, 3)
    check("Two-ring triangular case closes", closed_outward(study.ColumnSurface.make(simple, 3), 12))
    var maximum: Array[float] = []
    maximum.resize(32)
    maximum.fill(0.8)
    var dense: Array[Vector3] = study.column_positions(maximum, 2.5, 256)
    check("Documented profile and side bounds produce finite closed geometry", dense.size() == 8192 and closed_outward(study.ColumnSurface.make(dense, 256), 16384))
    var ray := PhysicsRayQueryParameters3D.create(Vector3(0, 1, 1), Vector3(0, 1, -2))
    check("No implicit column collider", study.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
    ray = PhysicsRayQueryParameters3D.create(Vector3(1, 0.5, 0), Vector3(1, -0.5, 0))
    check("Prepared room still supplies a solid floor", not study.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
    room.queue_free()
    await frames()

    room = load("res://primitive_composition.tscn").instantiate()
    root.add_child(room)
    study = room.get_node("Composition")
    await frames(12)
    room.player.position = Vector3(0, 0, 3.3)
    room.player.camera.look_at(Vector3(0, 0.9, -0.7))
    var base_mesh := data_copy(study.bodies[0].mesh)
    check("Three matching constructions; each closes six triangles around five corners", study.bodies.size() == 3 and study.bodies.all(func(body): return body.vertices.size() == 5 and closed_outward(body.mesh, 6) and data_copy(body.mesh) == base_mesh))
    check("Bodies use the declared local positions in the placed study frame", study.bodies[1].position == Vector3(0, 0, -0.8) and study.bodies[1].global_position.is_equal_approx(Vector3(0, 0, -1.5)))
    await capture("arrangement.png")
    var camera = room.player.camera
    var first_screen_height: float = abs(camera.unproject_position(study.bodies[1].to_global(Vector3(0, 1.5, 0))).y - camera.unproject_position(study.bodies[1].global_position).y)
    var arrangement_path := "res://studies/primitive_composition/arrangement.gd"
    await source_edit(arrangement_path, {"Vector3(0, 0, -0.8)": "Vector3(0, 0, 0.8)"})
    var second_screen_height: float = abs(camera.unproject_position(study.bodies[1].to_global(Vector3(0, 1.5, 0))).y - camera.unproject_position(study.bodies[1].global_position).y)
    check("Printed Z edit brings an unchanged mesh forward", study.bodies[1].global_position.is_equal_approx(Vector3(0, 0, 0.1)) and study.bodies.all(func(body): return data_copy(body.mesh) == base_mesh))
    check("Its projected height increases without scaling its geometry", second_screen_height > first_screen_height * 1.2 and study.bodies[1].scale == Vector3.ONE)
    await capture("forward.png")
    await source_edit(arrangement_path, {"Vector3(0, 0, -0.8)": "Vector3(0, 0, 0.8)", "-1.15": "-0.55", "1.15": "0.55"})
    check("Printed spacing edit keeps floor height and all local geometry", is_equal_approx(study.bodies[0].position.x, -0.55) and is_equal_approx(study.bodies[2].position.x, 0.55) and study.bodies.all(func(body): return body.position.y == 0 and data_copy(body.mesh) == base_mesh))
    await capture("close.png")
    var places: Array[Vector3] = study.positions.duplicate()
    room.player.position = Vector3(2.7, 0, 1.8)
    room.player.camera.look_at(Vector3(0, 0.85, -0.7))
    await capture("side.png")
    check("Changing viewpoint leaves the arrangement data and mesh intact", study.positions == places and study.bodies.all(func(body): return data_copy(body.mesh) == base_mesh))
    var ray2 := PhysicsRayQueryParameters3D.create(Vector3(0, 0.5, 1.2), Vector3(0, 0.5, -2))
    check("Composition does not claim surface collision", study.get_world_3d().direct_space_state.intersect_ray(ray2).is_empty())
    var original_code = load(arrangement_path)
    var bare = original_code.new()
    bare.position = Vector3(20, 0, 0)
    root.add_child(bare)
    await frames()
    check("Authored defaults return in a fresh instance with no scene children", bare.bodies.size() == 3 and bare.bodies[1].position == Vector3(0, 0, -0.8) and bare.bodies.all(func(body): return data_copy(body.mesh) == base_mesh))
    var bare_column = load(column_path).new()
    bare_column.position = Vector3(25, 0, 0)
    root.add_child(bare_column)
    await frames()
    check("Column also builds on an empty Node3D without a authored mesh", bare_column.positions == original and data_copy(bare_column.surface.mesh) == original_mesh)
    bare.free()
    bare_column.free()
    room.queue_free()
    await frames()
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "checks": checks, "godot": Engine.get_version_info().string, "physical_headset_tested": false, "scenes": ["primitive_column.tscn", "primitive_composition.tscn"], "evidence": "Actual printed source edits compiled and run in the student room; native rendered captures."}, "\t"))
    print("Closing Primitives: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
