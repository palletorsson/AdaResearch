extends "res://tools/probes/transformation_encounters.gd"
## The printed learner code, hosted in the real Grid hall for this check only.

func landing_checks() -> void:
    museum.flush_stamps()
    await create_timer(1.0).timeout
    var study: Node3D = load("res://doc/book/iterations/2026-10-06-trace-to-grid/grid.gd").new()
    study.name = "PointStudy"
    study.position = Vector3(8.5, 0, 8.5)
    hall.add_child(study)
    await create_timer(0.3).timeout
    check("student program belongs to actual Grid hall", study.get_parent() == hall and str(hall.get_meta("em_map", "")) == "Point_Line_Grid")
    check("study retains unit scale", study.global_basis.get_scale().is_equal_approx(Vector3.ONE))
    check("study has museum floor", not floor_at(study.global_position).is_empty())
    observations["study_local_position"] = xyz(study.position)
    observations["study_world_position"] = xyz(study.global_position)
    var artifacts: Array = []
    for record in museum.get("_edit_records"):
        if record.get("seg") == hall:
            artifacts.append(str(record.get("token", "")))
    observations["existing_artifacts"] = artifacts
    check("museum reference artifacts retained", artifacts.any(func(token): return str(token).begins_with("grid_lines")) and artifacts.any(func(token): return str(token).begins_with("grab_sphere_point_snap")))
    var player: Node3D = museum.get("_player")
    if player != null:
        player.visible = false
    var controller := XRController3D.new()
    root.add_child(controller)
    controller.global_position = study.point.global_position
    var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
    pickup.hand_offset_mode = 4
    pickup.ranged_enable = false
    controller.add_child(pickup)
    await create_timer(0.3).timeout
    pickup._update_closest_object()
    pickup._pick_up_object(study.point)
    check("actual XRTools holds the study point in museum", study.point.is_picked_up())
    var route: Array[Vector3] = [Vector3(0.33,1.12,0.2),Vector3(0.78,0.93,0.14),Vector3(0.85,0.60,0.11),Vector3(0.1,0.52,0.27),Vector3(-0.6,0.62,-0.16),Vector3(-0.73,1.17,-0.08),Vector3(-0.27,1.37,0.04),Vector3(-0.1,1.0,0.38)]
    for p in route:
        controller.global_position = study.to_global(p)
        await create_timer(0.15).timeout
    var original: Array = study.positions.duplicate()
    observations["retained_positions"] = original.map(func(p): return xyz(p))
    check("same recorder accepts the fixture gesture in museum", original.size() == 9)
    var eye := study.to_global(Vector3(-0.4,1.65,3.0))
    var target := study.to_global(Vector3(0,1.22,0))
    await snapshot("museum-pitch-025",eye,target,65)
    pickup._on_button_pressed(pickup.action_button_action)
    await tick()
    await tick()
    check("museum comparison keeps original trace", study.positions == original and is_equal_approx(study.grid_step,0.5))
    check("derived records match retained count", study.addresses.size() == original.size() and study.snapped_positions.size() == original.size())
    await snapshot("museum-pitch-050",eye,target,65)
    await snapshot("museum-workplace",study.to_global(Vector3(-1.1,1.65,4.4)),study.to_global(Vector3(-1.0,1.1,-0.5)),78)
    pickup.drop_object()

func finish() -> void:
    var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Unchanged printed Grid script placed temporarily in the actual Endless Museum Grid hall. Verifies floor, local frame, existing artifacts, recording and pitch comparison. Fixed programmatic input and standing camera captures; no physical headset or human learning verification. Production hall files are not changed."}
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("MUSEUM GRID STUDY: ",checks.size()," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
