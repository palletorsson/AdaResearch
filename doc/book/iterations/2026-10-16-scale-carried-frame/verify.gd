extends SceneTree

var world := Node3D.new()
var prefix := "res://normal/"
var checks: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
    run.call_deferred()

func check(id: String, ok: bool) -> void:
    checks.append({"id": id, "passed": ok})
    if not ok:
        failures.append(id)
        print("FAIL ", id)

func close(a: Vector3, b: Vector3) -> bool:
    return a.distance_to(b) < 0.0001

func make(state: String, variant := "base") -> Node3D:
    var scene: PackedScene = load(prefix + state + "/" + variant + "/study.tscn")
    var study: Node3D = scene.instantiate()
    world.add_child(study)
    study.set_process(false)
    return study

func bounds_in_study(body: MeshInstance3D, study: Node3D) -> AABB:
    var shape: AABB = body.mesh.get_aabb()
    var minimum := study.to_local(body.to_global(shape.get_endpoint(0)))
    var maximum := minimum
    for i in range(1, 8):
        var p := study.to_local(body.to_global(shape.get_endpoint(i)))
        minimum = minimum.min(p)
        maximum = maximum.max(p)
    return AABB(minimum, maximum - minimum)

func dimensions_in_world(body: MeshInstance3D) -> Vector3:
    var shape: AABB = body.mesh.get_aabb()
    var origin: Vector3 = body.to_global(shape.position)
    return Vector3(
        origin.distance_to(body.to_global(shape.position + Vector3(shape.size.x, 0, 0))),
        origin.distance_to(body.to_global(shape.position + Vector3(0, shape.size.y, 0))),
        origin.distance_to(body.to_global(shape.position + Vector3(0, 0, shape.size.z))))

func opening(study: Node3D) -> Vector3:
    var left := bounds_in_study(study.pivot.get_child(0), study)
    var right := bounds_in_study(study.pivot.get_child(1), study)
    var top := bounds_in_study(study.pivot.get_child(2), study)
    return Vector3(right.position.x - left.end.x, top.position.y, top.size.z)

func incoming_rotation() -> void:
    var study := make("incoming")
    check("incoming/parent_relation", study.travel.get_parent() == study.pivot)
    check("incoming/same_dimensions", close(study.travel.mesh.size, Vector3(1.2, 0.2, 0.8)))
    var mark: MeshInstance3D = study.travel.get_child(0)
    var initial_mark := mark.global_position
    study._process(2.0)
    check("incoming/quarter_turn", close(study.pivot.basis.x, Vector3(0, 0, -1)))
    check("incoming/fixed_centre", close(study.travel.global_position, study.to_global(Vector3(0, 1.2, 0))))
    check("incoming/mark_moves", not close(mark.global_position, initial_mark))
    study._process(6.0)
    check("incoming/full_return", close(mark.global_position, initial_mark))
    study._process(2.0)
    check("incoming/continues", close(study.pivot.basis.x, Vector3(0, 0, -1)))
    study.free()

func compare_scales() -> void:
    var expectations := {
        "base": {"factor": Vector3.ONE, "opening": Vector3(0.45, 0.6, 0.2), "fits": false},
        "uniform": {"factor": Vector3(4, 4, 4), "opening": Vector3(1.8, 2.4, 0.8), "fits": true},
        "width": {"factor": Vector3(4, 1, 1), "opening": Vector3(1.8, 0.6, 0.2), "fits": false},
        "xy": {"factor": Vector3(2, 2, 1), "opening": Vector3(0.9, 1.2, 0.2), "fits": true},
        "depth": {"factor": Vector3(1, 1, 3), "opening": Vector3(0.45, 0.6, 0.6), "fits": false},
    }
    for variant in expectations:
        var expected: Dictionary = expectations[variant]
        var factor: Vector3 = expected.factor
        var study := make("complete", variant)
        check(variant + "/parent_under_study", study.pivot.get_parent() == study)
        check(variant + "/three_doorway_parts", study.pivot.get_child_count() == 3)
        check(variant + "/witness_outside", study.point.get_parent() == study)
        var left: MeshInstance3D = study.pivot.get_child(0)
        var right: MeshInstance3D = study.pivot.get_child(1)
        var top: MeshInstance3D = study.pivot.get_child(2)
        check(variant + "/box_body_retained", left.get_script().resource_path.ends_with("box_body.gd") and top.get_script() == left.get_script())
        check(variant + "/independent_meshes", left.mesh != right.mesh and left.mesh != top.mesh)
        check(variant + "/stored_positions_unchanged", close(left.position, Vector3(-0.285, 0.3, 0)) and close(right.position, Vector3(0.285, 0.3, 0)) and close(top.position, Vector3(0, 0.66, 0)))
        check(variant + "/stored_mesh_sizes_unchanged", close(left.mesh.size, Vector3(0.12, 0.6, 0.2)) and close(top.mesh.size, Vector3(0.69, 0.12, 0.2)))
        check(variant + "/child_scales_unchanged", close(left.scale, Vector3.ONE) and close(right.scale, Vector3.ONE) and close(top.scale, Vector3.ONE))
        var actual := opening(study)
        check(variant + "/opening_width", absf(actual.x - expected.opening.x) < 0.0001)
        check(variant + "/opening_height", absf(actual.y - expected.opening.y) < 0.0001)
        check(variant + "/frame_depth", absf(actual.z - expected.opening.z) < 0.0001)
        check(variant + "/posts_on_floor", absf(bounds_in_study(left, study).position.y) < 0.0001 and absf(bounds_in_study(right, study).position.y) < 0.0001)
        check(variant + "/post_world_dimensions", close(dimensions_in_world(left), Vector3(0.12, 0.6, 0.2) * factor))
        check(variant + "/post_spacing", absf(left.global_position.distance_to(right.global_position) - 0.57 * factor.x) < 0.0001)
        check(variant + "/lintel_meets_posts", absf(bounds_in_study(left, study).end.y - bounds_in_study(top, study).position.y) < 0.0001)
        var measured_witness := dimensions_in_world(study.point)
        # Default SphereMesh tessellation misses the exact equator: compare its
        # actual world extents with the unscaled mesh. Parameters are checked below.
        check(variant + "/witness_diameter", close(measured_witness, study.point.mesh.get_aabb().size))
        check(variant + "/witness_position", close(study.point.global_position, study.to_global(Vector3(1.8, 0.325, 0))))
        check(variant + "/witness_on_floor", absf(bounds_in_study(study.point, study).position.y) < 0.0001)
        check(variant + "/witness_sphere", study.point.mesh is SphereMesh and absf(study.point.mesh.radius - 0.325) < 0.0001 and absf(study.point.mesh.height - 0.65) < 0.0001)
        check(variant + "/witness_dark", study.point.material_override != null and study.point.material_override.albedo_color.r < 0.1)
        var can_fit: bool = actual.x >= 0.65 and actual.y >= 0.65
        check(variant + "/geometric_clearance", can_fit == expected.fits)
        check(variant + "/no_collision_claim", study.find_children("*", "CollisionObject3D", true, false).is_empty())
        if variant == "uniform":
            check("uniform/opening_ratio", absf(actual.x / actual.y - 0.75) < 0.0001)
        elif variant == "width":
            check("width/ratio_changed", absf(actual.x / actual.y - 3.0) < 0.0001)
        study.free()

func assignments_and_instances() -> void:
    var study := make("complete")
    var other := make("complete")
    var before_witness: Transform3D = study.point.global_transform
    var mesh: Mesh = study.pivot.get_child(0).mesh
    study.apply_pose(Vector3(4, 4, 4))
    study.apply_pose(Vector3(4, 4, 4))
    check("pose/repeated_assignment", close(opening(study), Vector3(1.8, 2.4, 0.8)))
    study.apply_pose(Vector3.ONE)
    check("pose/return_to_original", close(opening(study), Vector3(0.45, 0.6, 0.2)))
    study.apply_pose(Vector3.ONE * 0.5)
    check("pose/positive_fraction", close(opening(study), Vector3(0.225, 0.3, 0.1)))
    check("pose/keeps_same_mesh", study.pivot.get_child(0).mesh == mesh)
    check("pose/reference_untouched", study.point.global_transform.is_equal_approx(before_witness))
    check("instances/independent_parent", close(opening(other), Vector3(0.45, 0.6, 0.2)))
    check("instances/independent_mesh", mesh != other.pivot.get_child(0).mesh)
    var spare: MeshInstance3D = study.box(Vector3(0.2, 0.3, 0.4), Vector3(3, 1, 0))
    check("box/still_attaches_to_study", spare.get_parent() == study and close(spare.position, Vector3(3, 1, 0)))
    check("box/outside_scaled_parent", close(dimensions_in_world(spare), Vector3(0.2, 0.3, 0.4)))
    study.free()
    other.free()

func run() -> void:
    var args := OS.get_cmdline_user_args()
    prefix = "res://" + args[0] + "/"
    root.add_child(world)
    world.position = Vector3(3, 0, 2)
    world.rotation.y = 0.4
    incoming_rotation()
    compare_scales()
    assignments_and_instances()
    var live_scene: PackedScene = load(prefix + "complete/uniform/study.tscn")
    var live: Node3D = live_scene.instantiate()
    world.add_child(live)
    var before: Transform3D = live.pivot.global_transform
    var witness_before: Transform3D = live.point.global_transform
    await create_timer(0.08).timeout
    check("runtime/static_pose", live.pivot.global_transform.is_equal_approx(before))
    check("runtime/static_reference", live.point.global_transform.is_equal_approx(witness_before))
    check("runtime/no_clock_callback", not live.is_processing())
    live.free()
    FileAccess.open(args[1], FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("CHECKS ", checks.size(), " FAILURES ", failures.size())
    quit(0 if failures.is_empty() else 1)
