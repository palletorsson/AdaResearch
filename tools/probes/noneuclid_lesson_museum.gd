extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    var start := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start < 30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("museum finished loading", museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    check("original three-model bench retained", find_scene("/triangle_curvature_workbench.gd") != null)
    var lesson = load("res://doc/book/iterations/2026-10-11-noneuclid-what-counts-as-straight/author/printed/surface_study.gd")
    var launcher = load("res://doc/book/studies/noneuclid-lineage/museum.gd")
    var study: Node3D = launcher.mount(hall, lesson)
    await tick()
    study.set_process(false)
    check("printed lesson in existing hall", study.get_parent()==hall)
    var exclude: Array[RID] = []
    var player := museum.get_node_or_null("Walker") as CollisionObject3D
    if player != null: exclude.append(player.get_rid())
    for body in study.find_children("*","CollisionObject3D",true,false): exclude.append(body.get_rid())
    var clear := true
    for x: float in [-0.5,0,0.5]:
        var p := study.to_global(Vector3(x,0,1.9))
        var hit := floor_at(p)
        clear = clear and not hit.is_empty() and absf(hit.position.y-p.y)<0.04
    check("approach supported by floor",clear)
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.5,2.2,4.0)
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = shape
    query.transform = study.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.2,0.65))
    query.collision_mask = 1
    query.exclude = exclude
    var hits := hall.get_world_3d().direct_space_state.intersect_shape(query)
    check("study and approach clear solid obstacles",hits.is_empty())
    observations["overlap_bodies"] = []
    for hit in hits: observations.overlap_bodies.append(str(hit.collider.get_path()))
    if not hits.is_empty() or not clear:
        observations["clear_candidates"] = []
        for x: float in [3,5,7,8,9,11,13,14]:
            for z: float in [3,4,5,6,7,9,11,13,15,17]:
                for height: float in [0,1,2]:
                    for yaw: float in [0,PI]:
                        var at := Transform3D(Basis(Vector3.UP,yaw),Vector3(x,height,z))
                        query.transform = hall.global_transform*at*Transform3D(Basis.IDENTITY,Vector3(0,1.2,0.65))
                        if not hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty(): continue
                        var supported := true
                        for dx: float in [-0.5,0,0.5]:
                            var p := hall.to_global(at*Vector3(dx,0,1.9))
                            var floor_hit := floor_at(p)
                            supported = supported and not floor_hit.is_empty() and absf(floor_hit.position.y-p.y)<0.04
                        if supported: observations.clear_candidates.append([x,height,z,yaw])
    for word: String in ["Plane","Sphere","Reset"]:
        var button: Node3D = study.get_node(word)
        check(word+" above console and upward",button.position.y>1.01 and button.basis.y.dot(Vector3.UP)>0.999)
    await snapshot("plane", study.to_global(Vector3(1.5,3.3,3.2)),study.to_global(Vector3(0,1.0,0.1)),62)
    await snapshot("above", hall.to_global(Vector3(8,25,27)),hall.to_global(Vector3(8,0,10)),62)
    var saved = study.model.points.duplicate()
    var ids: Array = []
    for point in study.points: ids.append(point.get_instance_id())
    study.get_node("Sphere").pressed.emit()
    await tick()
    check("sphere mode measured excess",study.model.spherical and study.model.measure().sum>180 and study.face.mesh==null)
    var same: bool = study.model.points==saved
    for i in range(3): same = same and study.points[i].get_instance_id()==ids[i]
    check("same instances and records",same)
    check("native sphere point stays on surface after physics",absf((study.points[1].position-study.CENTRE).length()-study.RADIUS)<0.001)
    await snapshot("sphere",study.to_global(Vector3(1.5,3.3,3.2)),study.to_global(Vector3(0,1.0,0.1)),62)
    study.model.points.assign([Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN])
    study.redraw()
    check("native oracle measured from tangents",absf(study.model.measure().sum-199.4712206)<0.001)
    await snapshot("known-triangle",study.to_global(Vector3(1.5,3.3,3.2)),study.to_global(Vector3(0,1.0,0.1)),62)
    study.model.points.assign([Vector2(-0.7,0),Vector2(0.7,0),Vector2.ZERO])
    study.redraw()
    check("native degenerate reading refused",study.readout.text.contains("No triangle"))
    await snapshot("degenerate",study.to_global(Vector3(1.5,3.3,3.2)),study.to_global(Vector3(0,1.0,0.1)),62)
    study.get_node("Reset").pressed.emit()
    study.get_node("Plane").pressed.emit()
    check("return to plane recovers original pairs",study.model.points==saved and absf(study.model.measure().sum-180)<0.001)
    observations["scope"] = "Actual isolated museum and exact printed study; synthetic controls. Working-copy launch, not permanent map placement or physical XR."

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
    print("SURFACE MUSEUM ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
