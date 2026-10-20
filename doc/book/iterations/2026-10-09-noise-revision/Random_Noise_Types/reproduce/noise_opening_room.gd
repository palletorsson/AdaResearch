extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.8).timeout
    var stream = museum.get("_portal_stream")
    if stream != null:
        stream.set_process(false)
        stream.set_physics_process(false)
    var player = museum.get("_player")
    if player is Node3D:
        player.hide()
        player.set_process(false)
        player.set_physics_process(false)
        player.global_position = Vector3(0, -100, 0)
    camera.set_cull_mask_value(19, false)
    var wardrobe = museum.get("_wardrobe")
    if wardrobe != null and is_instance_valid(wardrobe.get("costume")):
        wardrobe.get("costume").hide()
    for child in museum.get_children():
        if child is Node3D and child.has_meta("em_map") and child != hall:
            child.hide()
    var bench := find_scene("/randompoints/randompoints.gd")
    var single := find_scene("/randompoint/randompoint.gd")
    check("existing comparison and clipped point present", bench != null and single != null)
    if bench == null or single == null: return
    var origin: Vector3 = single.global_position - hall.global_basis * Vector3(3.5, 1.25, 2.5)
    observations.source_origin = xyz(origin)
    observations.inventory = []
    for rec in museum.get("_edit_records"):
        var node = rec.get("node")
        if is_instance_valid(node) and hall.is_ancestor_of(node):
            observations.inventory.append({"key":rec.get("token", ""), "position":xyz(hall.to_local(node.global_position))})
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 32
    await snapshot("overhead", origin + hall.global_basis * Vector3(6, 28, 16), origin + hall.global_basis * Vector3(6, 0, 13), 60)
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    await snapshot("encounter", bench.to_global(Vector3(.25, 1.65, 1.8)), bench.to_global(Vector3(0, 1.2, 0)), 82)
    check("installed slabs use declared dimensions", bench.area_size.is_equal_approx(Vector3(.9, .9, .12)))
    var original: Array = []
    for p in bench._points.admitted: original.append(p.get_meta("home"))
    var drift := 0.0
    for p in bench._points.admitted: drift = maxf(drift, p.position.distance_to(p.get_meta("home")))
    observations.live_position_roundoff_m = drift
    bench.redraw()
    var replay: Array = []
    for p in bench._points.admitted: replay.append(p.get_meta("home"))
    check("installed redraw repeats the named construction", original == replay)
    var before_state: int = bench._rng.state
    bench._points.admitted[0].position = bench._points.admitted[1].position
    bench._watch_neighbours()
    check("installed observer counts a close pair", bench._touching > 0)
    check("installed observer leaves the carried point", bench._points.admitted[0].position == bench._points.admitted[1].position)
    bench.restore()
    check("installed restore keeps generator state", bench._rng.state == before_state)
    bench.cycle_load()
    observations.crowded = bench._stats.duplicate(true)
    check("installed LOAD keeps separation and reports unfilled separately", bench.num_points == 96 and bench._stats.admitted.short == 96 - bench._points.admitted.size())
    await snapshot("crowded", bench.to_global(Vector3(.2, 1.5, 2.0)), bench.to_global(Vector3(0, 1.15, .1)), 72)
    bench.cycle_load()
    single.point_node.position = Vector3(.2, .1, .4)
    single._process(.016)
    check("single point keeps local XY and clips depth", single.point_node.position.is_equal_approx(Vector3(.2, .1, 0)))
    # Optional printed reconstruction; the installed artifacts remain untouched.
    var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    if spec.has("lesson"):
        var study = load(spec.lesson).new()
        study.transform = hall.global_transform.affine_inverse() * Transform3D(hall.global_basis * Basis(Vector3.UP, PI / 2), origin + hall.global_basis * Vector3(2.0, 0, 7.0))
        hall.add_child(study)
        observations.learner_host = {"map_metres":[2,0,7],"yaw_degrees":90,"scale":1}
        var foot: Vector3 = study.to_global(Vector3(0, 0, 1.3))
        var support := floor_at(foot)
        check("learner approach has floor", not support.is_empty() and absf(support.position.y-foot.y) < .04)
        var shape := CapsuleShape3D.new()
        shape.radius = .28
        shape.height = 1.7
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = shape
        query.collision_mask = 1 | 4
        query.transform.origin = foot + Vector3.UP * .88
        check("learner approach has standing clearance", hall.get_world_3d().direct_space_state.intersect_shape(query, 4).is_empty())
        await create_timer(.5).timeout
        var retained := true
        for i in range(study.points.size()):
            retained = retained and study.points[i].position.is_equal_approx(study.CENTRE + study.homes[i])
        check("rendered point positions retain generated homes after physics frames", retained and study.close_pairs() == 0)
        observations.student_points = []
        for i in range(study.points.size()):
            observations.student_points.append({"local":xyz(study.points[i].position),"world":xyz(study.points[i].global_position),"expected":xyz(study.CENTRE+study.homes[i]),"freeze":study.points[i].freeze})
        await snapshot("student", study.to_global(Vector3(0, 1.65, 1.8)), study.to_global(Vector3(0, 1.5, 0)), 94)
        await grip_checks(study)
        study.queue_free()
    observations.scope = "Native museum and exact printed reconstruction when supplied; simulated XR Tools input, no physical headset claim."

func grip_checks(study: Node3D) -> void:
    var origin := XROrigin3D.new()
    root.add_child(origin)
    var controller := XRController3D.new()
    origin.add_child(controller)
    var pickup = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
    controller.add_child(pickup)
    var p: Node3D = study.points[0]
    controller.global_transform = p.global_transform
    p.pick_up(pickup)
    await tick()
    controller.global_position += study.global_basis * Vector3(.4, .2, .3)
    for i in 6: await tick()
    check("inherited point follows simulated grip", p.is_picked_up() and p.global_position.distance_to(controller.global_position) < .05)
    var count: int = study.points.size()
    study.control.position.x = .4
    study.control.action()
    check("LOAD leaves a currently held sample intact", study.points.size() == count and study.requested == 12)
    p.let_go(pickup, Vector3.ZERO, Vector3.ZERO)
    await tick()
    check("sample releases frozen", not p.is_picked_up() and p.freeze)
    var state: int = study.rng.state
    study.control.position.x = 1.2
    study.control.action()
    check("control restores sample without a draw", p.position.is_equal_approx(study.CENTRE + study.homes[0]) and study.rng.state == state)
    origin.queue_free()
    await tick()
