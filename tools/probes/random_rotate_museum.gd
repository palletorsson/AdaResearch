extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var stack = find_scene("/random_decay_multimesh.gd")
    var floor_field = find_scene("/SlopeGradientCubes.gd")
    var legacy = find_scene("/RandomRotateRandomXYZ.gd")
    check("installed stack and static field exist", stack != null and floor_field != null)
    if stack == null or floor_field == null: return
    stack.set_process(false)
    floor_field.set_process(false)
    observations.artifacts = []
    for rec in museum.get("_edit_records"):
        var n = rec.get("node")
        if not is_instance_valid(n) or rec.get("seg") != hall: continue
        observations.artifacts.append({"token":rec.get("token"),"hall_local":xyz(hall.to_local(n.global_position))})
    check("namesake floor rotator has no target in museum", legacy != null and legacy.multimesh == null)
    check("two stacks retain20 cubes and120 prisms", stack._layers.size() == 2 and stack._layers[0].base_positions.size() == 20 and stack._layers[1].base_positions.size() == 120)
    check("rotation study disables drift sinking and colour changes", stack.drift_strength == 0 and stack.sink_distance == 0 and stack.cube_color_decay_mix == 0 and stack.prism_color_decay_mix == 0)
    check("stacks use equal rates and common units", stack.cube_decay_speed_scale == stack.prism_decay_speed_scale and stack.force_uniform_item_size and stack.rotation_xy_plane_only)
    stack._reset_layers()
    await snapshot("hall-before", hall.to_global(Vector3(6,14,0)), hall.to_global(Vector3(6,0,13)), 68)
    await snapshot("stack-aligned", stack.to_global(Vector3(0,3,-8)), stack.to_global(Vector3(0,1.8,0)), 65)
    stack.decay_active = true
    stack._process(1.0)
    check("startup delay retains aligned cubes", stack._layers[0].angles[0] == Vector3.ZERO)
    stack._rng.seed = 42
    for i in range(3600): stack._process(1.0/60.0)
    var changed := false
    var stable := true
    for layer in stack._layers:
        for i in range(layer.base_positions.size()):
            var tr: Transform3D = layer.multimesh.get_instance_transform(i)
            var angle: Vector3 = layer.angles[i]
            changed = changed or absf(angle.z) > 0.0001
            stable = stable and angle.x == 0 and angle.y == 0 and tr.origin.is_equal_approx(layer.base_positions[i]) and tr.basis.get_scale().is_equal_approx(Vector3.ONE)
    check("controlled60second advance changes angles only", changed and stable)
    var state: int = stack._rng.state
    var time: float = stack._decay_elapsed
    var angle: Vector3 = stack._layers[0].angles[0]
    stack._toggle_decay();stack._process(3.0)
    check("pause retains clock angle and generator", stack._decay_elapsed == time and stack._rng.state == state and stack._layers[0].angles[0] == angle)
    await snapshot("stack-turned", stack.to_global(Vector3(0,3,-8)), stack.to_global(Vector3(0,1.8,0)), 65)
    stack._toggle_decay();stack._process(1.0/60.0)
    check("resume continues the elapsed clock", stack._decay_elapsed > time)
    state = stack._rng.state
    stack._reset_layers()
    check("reset aligns without rewinding random stream", stack._rng.state == state and stack._decay_elapsed == 0 and stack._layers[0].angles[0] == Vector3.ZERO)
    check("static comparison has25 cubes and no animation", floor_field._cubes.size() == 25 and not floor_field.animate_slope)
    floor_field._update_cubes(floor_field.max_slope_angle)
    check("half-wave has level ends and a tilted middle", is_zero_approx(floor_field._cubes[0].rotation.x) and is_equal_approx(floor_field._cubes[2].rotation.x, -PI/6) and absf(floor_field._cubes[4].rotation.x) < 0.00001)
    var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"): await study_checks(spec)
    observations.scope = "Real museum; scripted input and controlled fixed-step advance. No physical headset or blind reader. Native stack algorithm remains frame-dependent."

func study_checks(spec: Dictionary) -> void:
    var study = load(spec.lesson).new()
    study.position = Vector3(3,0,7.5)
    study.rotation.y = PI/2
    hall.add_child(study)
    study.set_process(false)
    await tick()
    observations.student_bay = xyz(study.position)
    check("student bay has floor", not floor_at(study.global_position).is_empty())
    var feet_ok := true
    for x in [-1.05, -0.35, 0.35, 1.05]:
        for z in [-0.35, 0.35]:
            var support := floor_at(study.to_global(Vector3(x,0,z)))
            feet_ok = feet_ok and not support.is_empty()
    check("both plinth footprints sit over floor", feet_ok)
    var approach: Vector3 = study.to_global(Vector3(0,0,2.2))
    check("student approach has floor", not floor_at(approach).is_empty())
    var query := PhysicsShapeQueryParameters3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.26; capsule.height = 1.6
    query.shape = capsule
    query.transform = Transform3D(Basis.IDENTITY, approach+Vector3.UP*0.91)
    query.collision_mask = 1|4
    var obstacles: Array = []
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider != museum.get("_player") and not study.is_ancestor_of(hit.collider): obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles = obstacles
    check("student approach is clear", obstacles.is_empty())
    check("printed program initializes in the museum", study.turns.size() == 24 and study.cursor == 0)
    await snapshot("student-start", study.to_global(Vector3(0,2,4.4)), study.to_global(Vector3(0,1.4,0)), 48)
    study.point.position.x = 0
    study.point.action()
    check("first point action makes equal orientations", study.cursor == 1 and study.assigned.basis.is_equal_approx(study.accumulated.basis))
    study.point.position.x = 0.8; study.point.action()
    study._process(study.seconds_per_step*12.01)
    study.point.action()
    check("play then pause consumes13 recorded turns", study.cursor == 13 and not study.playing and not study.assigned.basis.is_equal_approx(study.accumulated.basis))
    observations.seed = study.seed_value
    observations.turns_degrees = []
    for turn in study.turns: observations.turns_degrees.append(rad_to_deg(turn))
    observations.latest_degrees = rad_to_deg(study.latest)
    observations.total_degrees = rad_to_deg(study.total)
    await snapshot("student-turns", study.to_global(Vector3(0,2,4.4)), study.to_global(Vector3(0,1.4,0)), 48)
    var saved: Array = study.turns.duplicate()
    study.point.position.x = -0.8; study.point.action()
    check("replay retains record while clearing poses", study.turns == saved and study.cursor == 0 and study.total == 0)
    study.free()
