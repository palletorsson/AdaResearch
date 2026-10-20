extends SceneTree

var world := Node3D.new()
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var prefix := "res://normal/"

func _initialize() -> void:
    run.call_deferred()

func check(id: String, ok: bool) -> void:
    checks.append({"id": id, "passed": ok})
    if not ok:
        failures.append(id)
        print("FAIL ", id)

func same(a: float, b: float) -> bool:
    return absf(a - b) < 0.0001

func make(hall: String, variant := "base") -> Node3D:
    var study: Node3D = load(prefix + hall + "/" + variant + "/lesson.gd").new()
    world.add_child(study)
    study.set_process(false)
    study.set_physics_process(false)
    return study

func advance(study: Node3D, seconds: float, rate: int) -> void:
    for i in int(round(seconds * rate)):
        study._process(1.0 / rate)

func corners(body: MeshInstance3D) -> PackedVector3Array:
    var result := PackedVector3Array()
    for i in 8:
        result.append(body.to_global(body.mesh.get_aabb().get_endpoint(i)))
    return result

func same_distances(a: PackedVector3Array, b: PackedVector3Array, factor := 1.0) -> bool:
    for i in a.size():
        for j in range(i + 1, a.size()):
            if not same(b[i].distance_to(b[j]), factor * a[i].distance_to(a[j])):
                return false
    return true

func body_at(at: Vector3, group: String, layer: int) -> CharacterBody3D:
    var body := CharacterBody3D.new()
    body.collision_layer = layer
    body.collision_mask = 0
    if not group.is_empty(): body.add_to_group(group)
    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.15
    collision.shape = shape
    body.add_child(collision)
    world.add_child(body)
    body.global_position = at
    return body

func physics_ticks() -> void:
    for i in 5:
        await physics_frame
        await process_frame

func pre() -> void:
    var still := make("Trans_Pre", "still")
    var original := corners(still.cube)
    advance(still, 3.0, 60)
    check("pre/still_when_operations_zero", corners(still.cube) == original)
    still.free()
    var rising := make("Trans_Pre", "rise")
    original = corners(rising.cube)
    rising._process(1.0)
    check("pre/rise_preserves_distances", same_distances(original, corners(rising.cube)))
    check("pre/rise_preserves_orientation", rising.cube.basis.is_equal_approx(Basis.IDENTITY))
    check("pre/rise_quarter_period", same(rising.cube.position.y, 1.65))
    rising.free()
    var steady := make("Trans_Pre")
    steady._process(0.5)
    check("pre/steady_midleg", same(steady.cube.position.y, 1.475) and same(steady.cube.scale.x, 1.1))
    steady._process(1.0)
    check("pre/steady_return_midleg", same(steady.cube.position.y, 1.475) and same(steady.cube.scale.x, 1.1))
    steady.free()
    var turning := make("Trans_Pre", "rise_turn")
    turning._process(2.0)
    check("pre/continuous_turn", same(turning.cube.rotation_degrees.y, 90.0))
    check("pre/turn_keeps_size", turning.cube.scale.is_equal_approx(Vector3.ONE))
    turning.free()
    for rate in [30, 120]:
        var study := make("Trans_Pre")
        original = corners(study.cube)
        advance(study, 1.0, rate)
        check("pre/time_" + str(rate), same(study.elapsed, 1.0))
        check("pre/combined_rise_" + str(rate), same(study.cube.position.y, 1.65))
        check("pre/combined_turn_" + str(rate), same(study.cube.rotation_degrees.y, 45.0))
        check("pre/combined_scale_" + str(rate), study.cube.scale.is_equal_approx(Vector3.ONE * 1.2))
        check("pre/distances_scale_together_" + str(rate), same_distances(original, corners(study.cube), 1.2))
        advance(study, 2.0, rate)
        check("pre/lower_size_bound_" + str(rate), same(study.cube.scale.x, 0.8) and same(study.cube.position.y, 0.95))
        var area: Area3D = study.cube.get_child(0)
        check("pre/sensor_follows_transform_" + str(rate), area.global_transform.is_equal_approx(study.cube.global_transform))
        study.free()
    var slow := make("Trans_Pre", "slow")
    slow._process(2.0)
    check("pre/slow_only_wave", same(slow.cube.position.y, 1.65) and same(slow.cube.scale.x, 1.2) and same(slow.cube.rotation_degrees.y, 90.0))
    slow.free()
    for group in ["em_walker", "player_body", "prop", "wrong_layer"]:
        var pickup := make("Trans_Pre", "still")
        var target: Vector3 = pickup.cube.global_position
        var layer := 524288 if group == "player_body" else 1
        if group == "wrong_layer": layer = 2
        var body := body_at(target + Vector3(0, 0, 5), "em_walker" if group == "wrong_layer" else group, layer)
        await physics_ticks()
        check("pre/outside_keeps_" + group, is_instance_valid(pickup))
        body.global_position = target
        await physics_ticks()
        var should_collect: bool = group in ["em_walker", "player_body"]
        check("pre/overlap_" + group, is_instance_valid(pickup) != should_collect)
        if is_instance_valid(pickup): pickup.free()
        body.free()
    var moving := make("Trans_Pre", "still")
    var old: Vector3 = moving.cube.global_position
    moving.cube.position.x = 3.0
    var player := body_at(old, "em_walker", 1)
    await physics_ticks()
    check("pre/old_place_empty", is_instance_valid(moving))
    player.global_position = world.to_global(Vector3(3, 1.3, 0))
    await physics_ticks()
    check("pre/new_place_collects", not is_instance_valid(moving))
    if is_instance_valid(moving): moving.free()
    player.free()

func introduction() -> void:
    var study := make("Trans_Introduction", "near")
    check("intro/owns_nine_boxes", study.get_child_count() == 9)
    check("intro/start_position", study.travel.position.is_equal_approx(Vector3(-4, 0.9, -1.4)))
    check("intro/start_growth", study.grow.scale.is_equal_approx(Vector3.ONE * 0.25))
    check("intro/start_turn", same(study.turn.rotation_degrees.y, 0.0))
    study._process(20.0)
    check("intro/held_pose", same(study.travel.position.z, -1.4))
    study.free()
    study = make("Trans_Introduction", "far")
    check("intro/travel_reaches_far_bank", same(study.travel.position.z, 1.4) and study.travel.basis.is_equal_approx(Basis.IDENTITY))
    check("intro/growth_uniform", study.grow.scale.is_equal_approx(Vector3.ONE))
    check("intro/growth_centre_fixed", study.grow.position == Vector3.ZERO)
    check("intro/growth_top_meets_banks", same(study.grow.position.y + study.grow.scale.y, 1.0))
    check("intro/quarter_turn", same(study.turn.rotation_degrees.y, 90.0))
    var endpoint: Vector3 = study.turn.transform * Vector3(-1, 0, 0)
    check("intro/turned_edge_meets_bank", same(endpoint.z, study.far_banks[2].position.z - 0.5))
    study.free()
    study = make("Trans_Introduction", "moved")
    endpoint = study.turn.transform * Vector3(-1, 0, 0)
    check("intro/moved_bank_gap", same(study.far_banks[2].position.z - 0.5 - endpoint.z, 0.5))
    check("intro/moved_growth_gap", same(study.far_banks[1].position.z - 0.5 - study.grow.scale.z, 0.5))
    study.free()
    study = make("Trans_Introduction", "middle")
    check("intro/middle", same(study.travel.position.z, 0.0) and same(study.turn.rotation_degrees.y, 45.0) and study.grow.scale.is_equal_approx(Vector3.ONE * 0.625))
    study.free()
    for rate in [30, 120]:
        study = make("Trans_Introduction")
        advance(study, 4.0, rate)
        check("intro/time_end_" + str(rate), same(study.travel.position.z, 1.4))
        advance(study, 4.0, rate)
        check("intro/time_return_" + str(rate), same(study.travel.position.z, -1.4))
        study.free()

func handoff() -> void:
    var prior: Node3D = load("res://predecessor/lesson.gd").new()
    world.add_child(prior)
    check("handoff/prior_arrangement_runs", prior.get_child_count() == 3 and prior.cubes.size() == 2)
    check("handoff/prior_point_retains_pickup_body", prior.point is RigidBody3D and prior.point.freeze)
    var old_cube: Node3D = prior.cubes[0]
    var bounds: AABB = old_cube.surface.mesh.get_aabb()
    check("handoff/prior_cube_bottom_origin", same(bounds.position.y, 0.0) and same(bounds.end.y, 1.0))
    var study := make("movement")
    check("handoff/movement_has_one_body", study.get_child_count() == 1)
    check("handoff/movement_has_no_sensor_yet", study.cube.get_child_count() == 0)
    var centred: AABB = study.cube.mesh.get_aabb()
    check("handoff/explicit_centred_origin", same(centred.position.y, -0.5) and same(centred.end.y, 0.5))
    check("handoff/same_one_metre_dimensions", bounds.size.is_equal_approx(centred.size))
    study._process(1.0)
    check("handoff/movement_before_collection_runs", same(study.cube.position.y, 1.65) and same(study.cube.rotation_degrees.y, 45.0))
    check("handoff/saved_arrangement_untouched", prior.cubes[0].position.is_equal_approx(Vector3(-0.8, 0, 0)) and prior.cubes.size() == 2)
    prior.free()
    study.free()
    var comparison := make("Trans_Introduction")
    check("handoff/no_collection_in_comparison", comparison.travel.get_child_count() == 0 and not comparison.has_method("_on_body_entered"))
    check("handoff/every_visual_is_carried_class", comparison.travel.get_script() == comparison.grow.get_script() and comparison.grow.get_script() == comparison.turn.get_script())
    check("handoff/meshes_are_independent", comparison.travel.mesh != comparison.grow.mesh and comparison.grow.mesh != comparison.turn.mesh)
    var growing_size: Vector3 = comparison.grow.mesh.size
    comparison.travel.mesh.size = Vector3(3, 2, 1)
    check("handoff/change_one_mesh_only", comparison.grow.mesh.size == growing_size)
    comparison.apply_pose(-3.0)
    check("handoff/pose_clamps_low", same(comparison.travel.position.z, -1.4))
    comparison.apply_pose(3.0)
    check("handoff/pose_clamps_high", same(comparison.travel.position.z, 1.4))
    check("handoff/period_means_full_cycle", same(comparison.period, 8.0))
    comparison.free()

func run() -> void:
    var args := OS.get_cmdline_user_args()
    prefix = "res://" + args[0] + "/"
    root.add_child(world)
    world.position = Vector3(3, 0, 2)
    world.rotation.y = 0.4
    handoff()
    await pre()
    introduction()
    var live := make("Trans_Pre")
    live.set_process(true)
    await create_timer(0.08).timeout
    check("runtime/process_callback", live.elapsed > 0.0)
    live.free()
    FileAccess.open(args[1], FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("CHECKS ", checks.size(), " FAILURES ", failures.size())
    quit(0 if failures.is_empty() else 1)
