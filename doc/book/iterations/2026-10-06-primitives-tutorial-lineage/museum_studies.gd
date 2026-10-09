extends "res://tools/probes/transformation_encounters.gd"
const BASE := "res://doc/book/iterations/2026-10-06-primitives-tutorial-lineage/"
const PREVIOUS := "res://doc/book/iterations/2026-10-06-trace-saved-to-grid/trace/"
const FLAG := BASE + "archive-backup.json"
const BACKUP := BASE + "archive-before.bin"

func landing_checks() -> void:
    museum.flush_stamps()
    await create_timer(0.6).timeout
    if map_id in ["Point_Triangle_Context", "Primitives_Polythedra"]:
        var archive = load(PREVIOUS + "trace_archive.gd")
        var existed := FileAccess.file_exists(archive.PATH)
        FileAccess.open(FLAG, FileAccess.WRITE).store_string(JSON.stringify({"path": ProjectSettings.globalize_path(archive.PATH), "existed": existed}))
        if existed:
            FileAccess.open(BACKUP, FileAccess.WRITE).store_buffer(FileAccess.get_file_as_bytes(archive.PATH))
        var trace: Node3D = load(PREVIOUS + "trace.gd").new()
        hall.add_child(trace)
        trace.set_process(false)
        for p in [Vector3(-0.6, 1.12, 0), Vector3(0.1, 1.9, 0), Vector3(0.5, 1.2, 0.4)]:
            trace.point.position = p
            trace._process(0.016)
            await process_frame
        trace._save_trace(trace.point)
        await create_timer(0.1).timeout
        trace.free()
        observations["drawing"] = "Synthetic recorded positions for this capture; user archive restored by runner."
    var script = load(BASE + map_id + "/lesson.gd")
    check("lesson script can instantiate", script != null and script.can_instantiate())
    if script == null or not script.can_instantiate():
        return
    var study: Node3D = script.new()
    study.name = "LearnerStudy"
    study.position = clear_spot(6.0 if map_id == "Primitives_Columns" else 3.2)
    if map_id == "Point_Triangle_Context": study.position = Vector3(6.5, 0, 22.5)
    # Capture positions selected from the actual floor plan, away from display plinths.
    if map_id == "Primitives_Polythedra": study.position = Vector3(4.5, 0, 3.0)
    if map_id == "Primitives_Portals": study.position = Vector3(3.5, 0, 11.5)
    if map_id == "Primitives_Melencolia": study.position = Vector3(2.5, 0, 12.0)
    hall.add_child(study)
    await create_timer(0.3).timeout
    check("exact learner program mounted in requested hall", study.get_parent() == hall)
    check("study has museum floor", not floor_at(study.global_position).is_empty())
    var player: Node3D = museum.get("_player")
    if player != null:
        player.visible = false
    var distance := 3.2
    if map_id == "Primitives_Columns": distance = 5.5
    if map_id == "Primitives_Profiles": distance = 4.4
    await snapshot("learner-study", study.to_global(Vector3(-0.8, 1.8, distance)), study.to_global(Vector3(0, 1.05, 0.2)), 65)
    if map_id in ["Primitives_Polythedra", "Primitives_Ignorance", "Primitives_Portals", "Primitives_Melencolia"]:
        await snapshot("learner-close", study.to_global(Vector3(0.25, 1.7, 1.8)), study.to_global(Vector3(0, 1.05, 0)), 85)
    if map_id == "Primitives_Polythedra":
        await snapshot("learner-close", study.to_global(Vector3(1.3, 1.9, 1.0)), study.to_global(Vector3(0, 1.45, 0)), 70)
    if map_id == "Primitives_Columns":
        await snapshot("learner-close", study.to_global(Vector3(0, 1.7, 2.7)), study.to_global(Vector3(0, 1.1, 0)), 95)
    if map_id == "Primitives_Godot":
        var controller := XRController3D.new()
        root.add_child(controller)
        controller.global_position = study.point.global_position
        var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
        pickup.hand_offset_mode = 4
        controller.add_child(pickup)
        await create_timer(0.2).timeout
        pickup._pick_up_object(study.point)
        await create_timer(4.5).timeout
        check("held sphere reaches coarse bounds", study.point.sphere.rings == 1 and study.point.sphere.radial_segments == 4)
        pickup.drop_object()
        await snapshot("held-resolution", study.to_global(Vector3(0, 1.5, 1.5)), study.to_global(Vector3(0, 1.2, 0)), 52)
        controller.queue_free()
    observations["station_local"] = xyz(study.position)
    observations["learner_main"] = BASE + map_id + "/lesson.gd"

func clear_spot(width: float) -> Vector3:
    var volume := BoxShape3D.new()
    volume.size = Vector3(width, 1.4, 5.5)
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = volume
    query.collision_mask = 1
    var space := hall.get_world_3d().direct_space_state
    for z in range(5, 30, 2):
        for x in range(5, 24, 2):
            var at := Vector3(x + 0.5, 0, z + 0.5)
            if floor_at(hall.to_global(at)).is_empty(): continue
            query.transform = Transform3D(Basis.IDENTITY, hall.to_global(at + Vector3(0, 1.1, 1.5)))
            if space.intersect_shape(query, 1).is_empty(): return at
    return Vector3(8.5, 0, 8.5)

func finish() -> void:
    FileAccess.open(folder + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "hall": map_id, "checks": checks, "failures": failures, "observations": observations, "scope": "Exact printed program mounted temporarily in the real Endless Museum hall. Synthetic input; no permanent placement or headset claim."}, "  "))
    quit(0 if failures.is_empty() else 1)
