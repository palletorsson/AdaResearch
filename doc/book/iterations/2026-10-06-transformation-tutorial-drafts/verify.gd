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

func translation() -> void:
    for variant in ["base", "corner", "diagonal"]:
        for rate in [30, 120]:
            var study := make("Trans_Translation", variant)
            var original := corners(study.cube)
            advance(study, 2.0, rate)
            var expected := Vector3(0, 2, 0) if variant == "base" else Vector3(-2, 3, 0)
            check("translation/halfway_" + variant + str(rate), study.cube.position.is_equal_approx(expected))
            check("translation/level_" + variant + str(rate), study.cube.basis.is_equal_approx(Basis.IDENTITY))
            check("translation/shape_preserved_" + variant + str(rate), same_distances(original, corners(study.cube)))
            advance(study, 2.0, rate)
            expected = Vector3(2, 3, 2) if variant == "diagonal" else Vector3(2, 3, 0)
            check("translation/destination_" + variant + str(rate), study.cube.position.is_equal_approx(expected))
            advance(study, 6.0, rate)
            check("translation/stops_" + variant + str(rate), study.cube.position.is_equal_approx(expected))
            study.free()

func rotation() -> void:
    for variant in ["base", "orbit", "vertical"]:
        var study := make("Trans_Rotation", variant)
        var original := corners(study.cube)
        var mark_start: Vector3 = study.mark.global_position
        var pivot_at: Vector3 = study.pivot.global_position
        advance(study, 2.0, 60)
        var expected := Vector3(0, 1.2, 0)
        if variant == "orbit": expected = Vector3(0, 1.2, -2)
        if variant == "vertical": expected = Vector3(0, -0.8, 0)
        check("rotation/quarter_centre_" + variant, study.cube.global_position.is_equal_approx(world.to_global(expected)))
        check("rotation/pivot_fixed_" + variant, study.pivot.global_position.is_equal_approx(pivot_at))
        check("rotation/local_offset_fixed_" + variant, study.cube.position.is_equal_approx(study.offset))
        check("rotation/rigid_distances_" + variant, same_distances(original, corners(study.cube)))
        check("rotation/mark_moves_" + variant, not study.mark.global_position.is_equal_approx(mark_start))
        advance(study, 6.0, 60)
        check("rotation/full_return_" + variant, study.mark.global_position.is_equal_approx(mark_start))
        study.free()

func scaling() -> void:
    for variant in ["base", "large", "wide", "double"]:
        var study := make("Trans_Scale", variant)
        var factors: Vector3 = study.factors
        var left: MeshInstance3D = study.doorway.get_child(0)
        var right: MeshInstance3D = study.doorway.get_child(1)
        var lintel: MeshInstance3D = study.doorway.get_child(2)
        check("scale/local_values_" + variant, left.position == Vector3(-0.285, 0.3, 0) and left.mesh.size == Vector3(0.12, 0.6, 0.2))
        var gap: float = left.global_position.distance_to(right.global_position) - 0.12 * factors.x
        check("scale/clear_width_" + variant, same(gap, 0.45 * factors.x))
        check("scale/clear_height_" + variant, same(lintel.global_position.y - 0.06 * factors.y, 0.6 * factors.y))
        check("scale/base_on_floor_" + variant, same(left.global_position.y - 0.3 * factors.y, 0.0))
        check("scale/witness_parent_" + variant, study.point.get_parent() == study)
        check("scale/witness_fixed_" + variant, study.point.global_position.is_equal_approx(world.to_global(Vector3(1.8, 0.325, 0))) and same(study.point.global_basis.x.length() * study.point.mesh.radius * 2.0, 0.65))
        study.free()

func bodily() -> void:
    var missing := make("Trans_Body")
    missing._process(1.0)
    check("body/no_player_stays_full", missing.cube.scale == Vector3.ONE and same(missing.cube.position.y, 0.5))
    missing.free()
    for group in ["em_walker", "player_body"]:
        var player := body_at(world.to_global(Vector3(0, 1.7, 8)), group, 1 if group == "em_walker" else 524288)
        var study := make("Trans_Body")
        check("body/finds_" + group, study.player == player)
        for distance in [0.0, 1.0, 2.5, 4.0, 10.0]:
            player.global_position = world.to_global(Vector3(0, 1.7, distance))
            study._process(0.016)
            var factor := 0.25 if distance <= 1.0 else (0.625 if distance == 2.5 else 1.0)
            check("body/scale_" + group + str(distance), same(study.cube.scale.x, factor))
            check("body/floor_" + group + str(distance), same(study.cube.position.y - study.cube.scale.y * 0.5, 0.0))
        player.global_position = world.to_global(Vector3(0, 15, 2.5))
        study._process(0.016)
        check("body/height_ignored_" + group, same(study.cube.scale.x, 0.625))
        player.global_position = world.to_global(Vector3(0, 1.7, 8))
        study._process(0.016)
        check("body/returns_" + group, study.cube.scale.is_equal_approx(Vector3.ONE))
        study.free()
        study = make("Trans_Body", "turn")
        player.global_position = world.to_global(Vector3(0, 1.7, 2.5))
        study._process(0.016)
        check("body/turn_variant_" + group, same(study.cube.rotation_degrees.y, 45.0) and study.cube.scale.is_equal_approx(Vector3.ONE))
        study.free()
        study = make("Trans_Body", "far")
        player.global_position = world.to_global(Vector3(0, 1.7, 3.5))
        study._process(0.016)
        check("body/new_midpoint_" + group, same(study.cube.scale.x, 0.625))
        study.free()
        player.free()

func pit() -> void:
    var study := make("Trans_Pit")
    var frame: Transform3D = study.get_child(0).global_transform
    study.apply_pose(1.0)
    check("pit/open_position", study.leaves[0].position.is_equal_approx(Vector3(-1.7, 2.15, 0)) and study.leaves[1].position.is_equal_approx(Vector3(1.7, 2.15, 0)))
    check("pit/open_turn", same(study.leaves[0].rotation_degrees.z, -55.0) and same(study.leaves[1].rotation_degrees.z, 55.0))
    check("pit/open_scale", study.visuals[0].scale.is_equal_approx(Vector3.ONE * 0.35))
    for t in [0.0, 0.5, 1.0]:
        study.apply_pose(t)
        for i in 2:
            check("pit/solid_size_" + str(t) + str(i), study.shapes[i].size.is_equal_approx(study.visuals[i].mesh.size * study.visuals[i].scale))
            check("pit/body_unit_scale_" + str(t) + str(i), study.leaves[i].scale.is_equal_approx(Vector3.ONE))
    check("pit/frame_fixed", study.get_child(0).global_transform.is_equal_approx(frame))
    study.apply_pose(0.0)
    check("pit/closed_pose", same(study.leaves[0].position.x, -0.55) and study.leaves[0].basis.is_equal_approx(Basis.IDENTITY))
    study.free()
    for variant in ["base", "slow", "wider"]:
        for rate in [30, 120]:
            study = make("Trans_Pit", variant)
            var player := body_at(world.to_global(Vector3(0, 1, 0)), "em_walker", 1)
            await physics_ticks()
            for i in rate * 3: study._physics_process(1.0 / rate)
            var expected := 0.5 if variant == "slow" else 1.0
            check("pit/progress_" + variant + str(rate), same(study.progress, expected))
            if variant == "wider": check("pit/wider_pose_" + str(rate), same(study.leaves[1].position.x, 2.05))
            player.global_position += Vector3(0, 0, 20)
            await physics_ticks()
            for i in rate * 3: study._physics_process(1.0 / rate)
            check("pit/returns_" + variant + str(rate), same(study.progress, 0.0))
            study.free()
            player.free()
    study = make("Trans_Pit")
    var prop := body_at(world.to_global(Vector3(0, 1, 0)), "prop", 1)
    await physics_ticks()
    study._physics_process(3.0)
    check("pit/prop_ignored", same(study.progress, 0.0))
    prop.free()
    var first := body_at(world.to_global(Vector3(0, 1, 0)), "em_walker", 1)
    var second := body_at(world.to_global(Vector3(0.5, 1, 0)), "player_body", 524288)
    await physics_ticks()
    study._physics_process(3.0)
    first.global_position += Vector3(0, 0, 20)
    await physics_ticks()
    study._physics_process(3.0)
    check("pit/remaining_xr_holds_open", same(study.progress, 1.0))
    second.global_position += Vector3(0, 0, 20)
    await physics_ticks()
    study._physics_process(1.5)
    check("pit/leaving_halfway_returns_gradually", same(study.progress, 0.5))
    first.global_position = world.to_global(Vector3(0, 1, 0))
    await physics_ticks()
    study._physics_process(0.75)
    check("pit/reentry_reverses_from_current", same(study.progress, 0.75))
    study.free()
    first.free()
    second.free()
    await door_passage()

func walking_body(group: String) -> CharacterBody3D:
    var body := CharacterBody3D.new()
    body.collision_layer = 524288 if group == "player_body" else 1
    body.collision_mask = 1
    body.add_to_group(group)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.2
    capsule.height = 1.6
    collision.shape = capsule
    body.add_child(collision)
    world.add_child(body)
    return body

func door_passage() -> void:
    for group in ["em_walker", "player_body"]:
        var study := make("Trans_Pit")
        var player := walking_body(group)
        player.position = Vector3(0, 0.8, 1.2)
        study.apply_pose(0.0)
        await physics_ticks()
        var hit := player.move_and_collide(world.global_basis * Vector3(0, 0, -2.4))
        check("pit/closed_blocks_" + group, hit != null and player.position.z > 0.2)
        player.position = Vector3(0, 0.8, 1.2)
        study.apply_pose(1.0)
        await physics_ticks()
        hit = player.move_and_collide(world.global_basis * Vector3(0, 0, -2.4))
        check("pit/open_passes_" + group, hit == null and same(player.position.z, -1.2))
        player.position = Vector3(1.25, 0.8, 1.2)
        await physics_ticks()
        hit = player.move_and_collide(world.global_basis * Vector3(0, 0, -2.4))
        check("pit/frame_stays_solid_" + group, hit != null and player.position.z > 0.2)
        # Probe space that the full-size leaf occupied, clear after real collision resizing.
        var query := PhysicsShapeQueryParameters3D.new()
        var probe := SphereShape3D.new()
        probe.radius = 0.03
        query.shape = probe
        query.collision_mask = 1
        query.transform.origin = study.leaves[1].to_global(Vector3(0, -1, 0))
        query.exclude = [player.get_rid()]
        check("pit/withdrawn_collision_" + group, world.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
        # Let actual engine physics callbacks open and close the printed door.
        player.position = Vector3(0, 0.8, 1.2)
        study.progress = 0.0
        study.apply_pose(0.0)
        study.duration = 0.12
        study.set_physics_process(true)
        await create_timer(0.35).timeout
        check("pit/live_opens_" + group, same(study.progress, 1.0))
        hit = player.move_and_collide(world.global_basis * Vector3(0, 0, -2.4))
        check("pit/live_passes_" + group, hit == null and same(player.position.z, -1.2))
        player.position.z = -5.0
        await create_timer(0.35).timeout
        check("pit/live_closes_" + group, same(study.progress, 0.0))
        study.free()
        player.free()

func run() -> void:
    var args := OS.get_cmdline_user_args()
    prefix = "res://" + args[0] + "/"
    root.add_child(world)
    world.position = Vector3(3, 0, 2)
    world.rotation.y = 0.4
    await pre()
    introduction()
    translation()
    rotation()
    scaling()
    bodily()
    await pit()
    # A real callback also has to run; the comparisons above use controlled elapsed seconds.
    var live := make("Trans_Pre")
    live.set_process(true)
    await create_timer(0.08).timeout
    check("runtime/process_callback", live.elapsed > 0.0)
    live.free()
    FileAccess.open(args[1], FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("CHECKS ", checks.size(), " FAILURES ", failures.size())
    quit(0 if failures.is_empty() else 1)
