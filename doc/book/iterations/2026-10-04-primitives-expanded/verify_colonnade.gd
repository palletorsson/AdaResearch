extends SceneTree
## Run from an isolated project containing the colonnade source files.
## Last user argument is the report path; no museum runtime files are touched.

var checks: Array = []
var failed := false


func _initialize() -> void:
    _run.call_deferred()


func _check(label: String, passed: bool) -> void:
    checks.append({"check": label, "passed": passed})
    failed = failed or not passed
    if not passed:
        push_error(label)


func _run() -> void:
    var scene: PackedScene = load("res://resolution_colonnade_museum.tscn")
    var room: Node3D = scene.instantiate()
    root.add_child(room)
    await physics_frame
    await physics_frame
    _check("Twenty-five full-size columns", room.columns.size() == 25)
    var controlled := true
    var last_count := 0
    var increasing := true
    var profiles: Array[int] = []
    var varied_heights: Array[float] = []
    var triangle_count := 0
    var finite := true
    var full_height := 0.0
    for i in room.columns.size():
        var column: Node3D = room.columns[i]
        var bounds: AABB = column.column_mesh.get_aabb()
        full_height = maxf(full_height, bounds.end.y + column.position.y)
        triangle_count += column.triangle_count
        if i < 5:
            controlled = controlled and column.profile_kind == 0 and \
                is_equal_approx(column.column_height, 4.67) and \
                is_equal_approx(column.width_factor, 1.0) and \
                column.profile_rings == 8 and column.radial_segments == room.COUNTS[i]
            increasing = increasing and column.triangle_count > last_count
            last_count = column.triangle_count
        else:
            if not profiles.has(column.profile_kind):
                profiles.append(column.profile_kind)
            if not varied_heights.has(column.column_height):
                varied_heights.append(column.column_height)
        _check("Column %d rests on its plinth" % i,
            is_equal_approx(bounds.position.y, 0.0) and is_equal_approx(column.position.y, 0.22))
        for surface in column.column_mesh.get_surface_count():
            var arrays: Array = column.column_mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            finite = finite and vertices.size() > 0 and vertices.size() == normals.size()
            for v in vertices:
                finite = finite and v.is_finite()
            for n in normals:
                finite = finite and n.is_finite() and is_equal_approx(n.length(), 1.0)
    _check("Entry row changes only radial resolution", controlled)
    _check("Entry row triangle counts increase with sides", increasing)
    _check("Varied grove retains five profiles and at least fifteen heights",
        profiles.size() == 5 and varied_heights.size() >= 15)
    _check("Finite geometry and unit normals", finite)
    _check("Tallest body retains its 6.17 metre total height", is_equal_approx(full_height, 6.17))
    _check("No camera, world environment, lights, architecture or floor",
        room.find_children("*", "Camera3D", true, false).is_empty() and \
        room.find_children("*", "WorldEnvironment", true, false).is_empty() and \
        room.find_children("*", "Light3D", true, false).is_empty() and \
        room.get_node_or_null("Architecture") == null)

    var actual_bounds := AABB()
    var first := true
    for node in room.find_children("*", "MeshInstance3D", true, false):
        if node.mesh == null:
            continue
        var local: AABB = room.global_transform.affine_inverse() * node.global_transform * node.mesh.get_aabb()
        actual_bounds = local if first else actual_bounds.merge(local)
        first = false
    _check("Physical geometry fits declared museum placement",
        actual_bounds.position.x >= -10.94 and actual_bounds.end.x <= 8.11 and \
        actual_bounds.position.z >= -13.06 and actual_bounds.end.z <= 10.94 and \
        actual_bounds.position.y >= -0.001 and actual_bounds.end.y <= 6.18)
    var space: PhysicsDirectSpaceState3D = room.get_world_3d().direct_space_state
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.7
    var clear := true
    for step in range(-64, 65):
        for x in [-0.70, 0.0, 0.70]:
            var query := PhysicsShapeQueryParameters3D.new()
            query.shape = capsule
            query.transform = Transform3D(Basis.IDENTITY, Vector3(x, 0.85, step * 0.25))
            query.collision_mask = 1
            clear = clear and space.intersect_shape(query, 1).is_empty()
    _check("1.7 m capsule has a continuous 2.1 m passage from entrance to exit", clear)
    var solid := true
    for column in room.columns:
        var at: Vector3 = column.position
        var ray := PhysicsRayQueryParameters3D.create(at + Vector3(-1.2, 1.0, 0),
            at + Vector3(1.2, 1.0, 0), 1)
        solid = solid and not space.intersect_ray(ray).is_empty()
    _check("All columns retain collision", solid)
    var report := {"passed": not failed, "checks": checks, "triangles_in_columns": triangle_count,
        "physical_bounds": {"min": [actual_bounds.position.x, actual_bounds.position.y, actual_bounds.position.z],
            "max": [actual_bounds.end.x, actual_bounds.end.y, actual_bounds.end.z]},
        "note": "Native isolated headless geometry and collision checks; main museum and headset review remain separate."}
    var output := OS.get_cmdline_user_args()[0]
    var file := FileAccess.open(output, FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "\n")
    file.close()
    print(JSON.stringify(report))
    quit(1 if failed else 0)
