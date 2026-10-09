extends "res://doc/book/iterations/2026-10-06-primitives-tutorial-lineage/museum_studies.gd"
const LESSON := "res://doc/book/iterations/2026-10-06-trans-pre-three-operations/"

func landing_checks() -> void:
    museum.flush_stamps()
    await create_timer(0.6).timeout
    var at := clear_spot(3.2)
    var player: Node3D = museum.get("_player")
    if player != null:
        player.visible = false
    observations["station_local"] = xyz(at)
    observations["scope"] = "Temporary exact-code studies in Trans_Pre; only the camera and study root are supplied. Installed exhibits unchanged."
    for variant in ["still", "translate", "turn", "scale", "rise"]:
        var study: Node3D = load(LESSON + "variants/" + variant + "/lesson.gd").new()
        study.name = "TransformStudy"
        study.position = at
        hall.add_child(study)
        study.set_process(false)
        if variant == "rise": study._process(1.0)
        check(variant + ": exact study mounted", study.cube.get_parent() == study and study.get_parent() == hall)
        check(variant + ": floor under study", not floor_at(study.global_position).is_empty())
        await snapshot(variant, study.to_global(Vector3(-2.7, 2.5, 4.7)), study.to_global(Vector3(0.4, 1.5, 0)), 45)
        study.free()
    observations["rise_time_seconds"] = 1.0
    var pickup: Node3D = load(LESSON + "lesson.gd").new()
    pickup.position = at
    hall.add_child(pickup)
    pickup.set_process(false)
    var saved_player: Vector3 = player.global_position
    player.global_position = hall.to_global(at + Vector3(0, 0, 2))
    await create_timer(0.25).timeout
    check("real walker outside keeps pickup", is_instance_valid(pickup))
    await snapshot("pickup-before", hall.to_global(at + Vector3(-2.7, 2.5, 4.7)), hall.to_global(at + Vector3(0.4, 1.5, 0)), 45)
    player.global_position = hall.to_global(at)
    await create_timer(0.3).timeout
    check("real museum walker collects by overlap", not is_instance_valid(pickup))
    await snapshot("pickup-after", hall.to_global(at + Vector3(-2.7, 2.5, 4.7)), hall.to_global(at + Vector3(0.4, 1.5, 0)), 45)
    player.global_position = saved_player
