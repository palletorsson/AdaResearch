extends "res://tools/probes/transformation_encounters.gd"

const PRIMARY = {
    "WaveFunctions_Intro": "y_oscillation_cube",
    "WaveFunctions_Pendulum": "PendulumWave",
    "WaveFunctions_Sine_Space": "sine_flow_tray",
    "WaveFunctions_Unit_Circle": "unit_circle_advanced",
    "WaveFunctions_3D_Wave_Propagation": "coupled_oscillator_lattice",
    "WaveFunctions_Effect_Sound": "DualBallFMController",
    "Wavefunctions_Bernini": "bernini_columns",
    "WaveFunctions_John_Cage": "john_cage_tech_noir",
    "WaveFunctions_AirMusic": "resonating_metallophone",
    "Wavefunctions_Sky_Stairs": "sine_cylinder_staircase",
    "WaveFunctions_TrigWalkingPath": "beat_frequency_demo",
    "WaveFunctions_Synthesis_Lab": "additive_wave_demo"
}

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/" + map_id + "/map_data.json"))
    var w: float = data.map_info.dimensions.width
    var d: float = data.map_info.dimensions.depth
    var origin := hall.global_position + Vector3(0, 0, 4)
    var walker = museum.get("_player")
    if walker is Node3D: walker.visible = false
    var walk_camera = museum.get("_cam")
    if walk_camera is Node3D: walk_camera.visible = false
    observations.artifacts = []
    var primary: Node3D
    for record in museum.get("_edit_records"):
        var node = record.get("node")
        if not is_instance_valid(node) or record.get("seg") != hall: continue
        var bounds: AABB = museum.call("_seat_extent", node)
        observations.artifacts.append({"token": record.get("token"), "position": xyz(node.global_position-origin), "bounds_position": xyz(bounds.position-origin), "bounds_size": xyz(bounds.size)})
        if record.get("token") == PRIMARY[map_id]: primary = node
    check("existing primary artifact present", primary != null)
    await snapshot("above", origin + Vector3(w*0.25, 12, 0), origin + Vector3(w*0.5, 0, d*0.5), 70)
    await snapshot("entry", origin + Vector3(w*0.5, 1.7, 1), origin + Vector3(w*0.5, 1.5, d*0.7), 75)
    if primary != null:
        if map_id == "WaveFunctions_Intro":
            await snapshot("primary", primary.global_position + Vector3(0.1, 0.5, -1.8), primary.global_position + Vector3(0,0.1,0), 52)
        else:
            await snapshot("primary", primary.global_position + Vector3(-2, 2, -4), primary.global_position + Vector3.UP, 65)
    var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "spec.json"))
    if spec.has("lesson"):
        await study_checks(spec)
    observations.scope = "Existing museum, native rendering. Prescribed cube motion; no student-comprehension or headset claim."

func study_checks(spec: Dictionary) -> void:
    var lesson = load(spec.lesson).new()
    var at: Array = spec.bay
    lesson.position = Vector3(at[0], at[1], at[2])
    hall.add_child(lesson)
    await tick()
    lesson.set_process(false)
    check("student study has museum floor", not floor_at(lesson.global_position).is_empty())
    check("student object is a single cube mesh", lesson.cube.mesh is BoxMesh)
    check("student creates its own readout", lesson.label.is_inside_tree())
    lesson.elapsed = 0.5
    lesson.draw_state()
    check("cube reaches the predicted upper height", absf(lesson.cube.position.y - 1.7) < 0.00001)
    lesson.elapsed = 1.5
    lesson.draw_state()
    check("cube reaches the predicted lower height", absf(lesson.cube.position.y - 0.9) < 0.00001)
    lesson.phase = PI
    lesson.elapsed = 0.01
    lesson.draw_state()
    check("phase changes direction inside the hall", lesson.cube.position.y < lesson.centre.y)
    check("display remains in the museum's frame", lesson.cube.global_position.is_equal_approx(lesson.to_global(lesson.cube.position)))
    var approach: Vector3 = lesson.to_global(Vector3(0,0,-1.3))
    check("student approach has floor", not floor_at(approach).is_empty())
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.26
    capsule.height = 1.6
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = capsule
    query.transform = Transform3D(Basis.IDENTITY, approach + Vector3.UP * 0.91)
    query.collision_mask = 1 | 4
    var hits = hall.get_world_3d().direct_space_state.intersect_shape(query)
    var obstacles: Array = []
    for hit in hits:
        if hit.collider != museum.get("_player") and not lesson.is_ancestor_of(hit.collider): obstacles.append(str(hit.collider.get_path()))
    check("student approach clear of other bodies", obstacles.is_empty())
    observations.approach_obstacles = obstacles
    observations.lesson = spec.lesson
    observations.bay = at
    lesson.phase = 0.0
    lesson.elapsed = 0.5
    lesson.draw_state()
    await snapshot("student", lesson.to_global(Vector3(0,1.65,-3.3)), lesson.to_global(Vector3(0,1.55,0)), 52)
    lesson.queue_free()
