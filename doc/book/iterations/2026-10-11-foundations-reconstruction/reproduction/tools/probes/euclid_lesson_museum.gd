extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    var start := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec() - start < 30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("existing museum finished loading", museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    check("original plaque retained", find_scene("/euclid_postulates_plaque.gd") != null)
    check("original triangle retained", find_scene("/angle_sum_triangle.gd") != null)
    var lesson = load("res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/author/printed/euclid_study.gd")
    var launcher = load("res://doc/book/studies/euclid-lineage/museum.gd")
    var study: Node3D = launcher.mount(hall, lesson)
    await tick()
    study.set_process(false)
    check("printed study belongs to existing hall", study.get_parent() == hall)
    for word: String in ["Guide", "Reset"]:
        var button := study.get_node(word) as Node3D
        check(word + " sits above table and faces upward", button.position.y > 1.01 and button.basis.y.dot(Vector3.UP) > 0.999)
    var clear := true
    var exclude: Array[RID] = []
    var player := museum.get_node_or_null("Walker") as CollisionObject3D
    if player != null: exclude.append(player.get_rid())
    for body in study.find_children("*", "CollisionObject3D", true, false): exclude.append(body.get_rid())
    for x: float in [-0.5, 0, 0.5]:
        var p := study.to_global(Vector3(x, 0, 1.8))
        var floor_hit := floor_at(p)
        clear = clear and not floor_hit.is_empty() and absf(floor_hit.position.y - p.y) < 0.04
    check("approach has supported floor", clear)
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.8, 2.1, 4.0)
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = shape
    query.transform = study.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.15, 0.6))
    query.collision_mask = 1
    query.exclude = exclude
    var hits := hall.get_world_3d().direct_space_state.intersect_shape(query)
    check("study and approach clear solid architecture", hits.is_empty())
    observations["overlap_bodies"] = []
    for hit in hits: observations.overlap_bodies.append(str(hit.collider.get_path()))
    if not hits.is_empty():
        observations["clear_z_candidates"] = []
        for index in range(16):
            var z := 11.0 + index * 0.25
            query.transform = hall.global_transform * Transform3D(Basis.IDENTITY, Vector3(5, 1.15, z + 0.6))
            if hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty():
                observations.clear_z_candidates.append(z)
    await snapshot("opening", study.to_global(Vector3(1.8, 3.1, 2.8)), study.to_global(Vector3(0, 1.1, 0)), 65)
    await snapshot("above", hall.to_global(Vector3(5, 23, 25)), hall.to_global(Vector3(5, 0, 10)), 60)
    study.model.points.assign([Vector2(-0.8, 0.7), Vector2(0.9, 0.6), Vector2(0.4, -0.7)])
    study.redraw()
    await tick()
    check("native scalene measurements", absf(study.model.measure().sum - 180) < 0.001)
    check("native points follow model after physics", study.points[2].position.distance_to(study.place(study.model.points[2])) < 0.001)
    await snapshot("scalene", study.to_global(Vector3(0, 3.5, 3.2)), study.to_global(Vector3(0, 1.15, 0)), 59)
    var before = study.model.points.duplicate()
    study.get_node("Guide").pressed.emit()
    check("native GUIDE changes only display", not study.guide.visible and study.model.points == before)
    await snapshot("guide-hidden", study.to_global(Vector3(0, 3.5, 3.2)), study.to_global(Vector3(0, 1.15, 0)), 59)
    study.model.points.assign([Vector2(-0.8, 0), Vector2(0.8, 0), Vector2.ZERO])
    study.redraw()
    check("native degeneracy withholds face", study.face.mesh == null and study.readout.text.contains("No triangle"))
    await snapshot("degenerate", study.to_global(Vector3(0, 3.5, 3.2)), study.to_global(Vector3(0, 1.15, 0)), 59)
    observations["scope"] = "Actual isolated Euclid hall and printed working-copy study, retained original exhibits; synthetic state changes, not headset usability or permanent map placement."

func finish() -> void:
    FileAccess.open(folder + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "observations": observations}, "  "))
    print("EUCLID MUSEUM ", checks.size() - failures.size(), "/", checks.size())
    quit(0 if failures.is_empty() else 1)
