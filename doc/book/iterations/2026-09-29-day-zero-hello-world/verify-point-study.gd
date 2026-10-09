extends SceneTree

var checks: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
    run.call_deferred()

func check(label: String, ok: bool) -> void:
    checks.append({"name": label, "passed": ok})
    if not ok:
        failures += 1
        push_error(label)

func run() -> void:
    var packed: PackedScene = load("res://study.tscn")
    var study: Node3D = packed.instantiate()
    root.add_child(study)
    await physics_frame
    await physics_frame
    var absent: Node3D = study.get_node("Position")
    var visible: Node3D = study.get_node("Visible")
    var solid: Node3D = study.get_node("Solid")
    check("A saved position adds no visible or physical child", absent.get_child_count() == 0)
    check("Visible and solid mesh radii match", is_equal_approx(visible.get_child(0).mesh.radius, solid.get_child(0).mesh.radius))
    check("World address includes the station placement", solid.get_child(0).global_position.is_equal_approx(Vector3(1.25, 1.12, 0.0)))
    var fixed_body: StaticBody3D = solid.get_child(1)
    var mesh: MeshInstance3D = solid.get_child(0)
    var collision: CollisionShape3D = fixed_body.get_child(0)
    check("Visible and physical centres coincide", mesh.global_position.is_equal_approx(fixed_body.global_position))
    check("Visible and physical radii coincide", is_equal_approx(mesh.mesh.radius, collision.shape.radius))

    var space: PhysicsDirectSpaceState3D = study.get_world_3d().direct_space_state
    for station: Node3D in [absent, visible, solid]:
        var centre: Vector3 = station.to_global(Vector3(0, 1.12, 0))
        var query := PhysicsRayQueryParameters3D.create(centre + Vector3(0, 0, 1), centre + Vector3(0, 0, -1), 1)
        var hit: Dictionary = space.intersect_ray(query)
        check("Physics ray: " + str(station.name), not hit.is_empty() if station == solid else hit.is_empty())
        if station == solid and not hit.is_empty():
            check("Ray meets the authored sphere surface", absf(hit.position.z - 0.14) < 0.002)

    # A moving body also distinguishes visible-only from solid.
    var traveller := CharacterBody3D.new()
    var traveller_collision := CollisionShape3D.new()
    var traveller_shape := SphereShape3D.new()
    traveller_shape.radius = 0.04
    traveller_collision.shape = traveller_shape
    traveller.add_child(traveller_collision)
    root.add_child(traveller)
    traveller.position = Vector3(0, 10, 0)
    await physics_frame
    await physics_frame
    for station: Node3D in [absent, visible, solid]:
        var from := Transform3D(Basis.IDENTITY, station.to_global(Vector3(0, 1.12, 1)))
        var blocked: bool = traveller.test_move(from, Vector3(0, 0, -2))
        check("Moving body: " + str(station.name), blocked == (station == solid))

    # Test the suggested authored variation, then restore it.
    collision.shape.radius = 0.35
    await physics_frame
    await physics_frame
    var centre: Vector3 = fixed_body.global_position
    var expanded_query := PhysicsRayQueryParameters3D.create(centre + Vector3(0, 0, 1), centre + Vector3(0, 0, -1), 1)
    var expanded_hit: Dictionary = space.intersect_ray(expanded_query)
    check("Larger collision resists before the visible surface", not expanded_hit.is_empty() and absf(expanded_hit.position.z - 0.35) < 0.002)
    check("Changing collision leaves mesh radius unchanged", is_equal_approx(mesh.mesh.radius, 0.14))
    collision.shape.radius = 0.14
    var report := {"passed": failures == 0, "engine": Engine.get_version_info().string, "checks": checks, "scope": "Native standalone study: compilation, instantiation, world placement, physics rays and moving-body comparisons. No museum or headset run."}
    var report_path: String = get_script().resource_path.get_base_dir().path_join("point-study-native.json")
    var file := FileAccess.open(report_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "\n")
    file.close()
    print("POINT_STUDY: ", checks.size(), " checks; failures: ", failures)
    traveller.queue_free()
    study.queue_free()
    await process_frame
    quit(1 if failures else 0)
