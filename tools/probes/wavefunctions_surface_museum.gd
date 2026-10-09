extends "res://tools/probes/wavefunctions_lessons_museum.gd"

func clear_approach(owner: Node3D, at: Vector3, title: String) -> void:
    check(title+" has floor",not floor_at(at).is_empty())
    var capsule := CapsuleShape3D.new()
    capsule.radius=0.26;capsule.height=1.6
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not owner.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    check(title+" is unobstructed",obstacles.is_empty())
    observations[title]=obstacles

func landing_checks() -> void:
    await super.landing_checks()
    var tray := find_scene("/sine_flow_tray.gd")
    var corridor := find_scene("/SineWallCorridor.gd")
    var landscape := find_scene("/algorithms/wavefunctions/sine_space/SineSpace.gd")
    var model := find_scene("/sine_wall_explanation.gd")
    check("four named encounters loaded",tray!=null and corridor!=null and landscape!=null and model!=null)
    if tray==null or corridor==null or landscape==null or model==null:return
    var origin := hall.global_position+Vector3(0,0,4)
    var shift := Vector3(landscape.global_position.x-origin.x-6.5,0,0)
    for p in [Vector3(8.5,0,2.5),Vector3(6.5,0,7),Vector3(6.5,0,12.5),Vector3(6,0,16),Vector3(6,0,17.01),Vector3(6,0,34.99),Vector3(6,0,35.5),Vector3(11.5,0,37.5)]:
        clear_approach(corridor,origin+p+shift,"route "+str(p.z))
    clear_approach(tray,tray.to_global(Vector3(-1.5,0,0)),"tray controls")
    clear_approach(corridor,corridor.to_global(Vector3(-1.05,0,-4.6)),"corridor controls")
    check("explanation raised to readable height",model.global_position.y>0.95 and model.global_position.y<1.1)
    check("corridor lies along onward route",absf(corridor.global_basis.z.dot(Vector3.FORWARD))>0.99)
    check("corridor walls remain noncolliding",not corridor.enable_collision and corridor._left_wall_shape.shape==null and corridor._right_wall_shape.shape==null)
    check("corridor retains its supporting slab",corridor._floor_shape!=null and not corridor._floor_shape.disabled)
    corridor.set_phase_offset(PI)
    var gaps: Array = corridor.gap_range()
    check("half-turn makes constant local X gap",absf(gaps[0]-2.0)<0.0001 and absf(gaps[1]-2.0)<0.0001)
    corridor.toggle_animation()
    var stopped_phase: float = corridor.phase
    await create_timer(0.15).timeout
    check("freeze preserves phase",not corridor.animate_at_runtime and is_equal_approx(corridor.phase,stopped_phase))
    corridor.reset_declared()
    check("reset restores moving passage",corridor.animate_at_runtime)
    var floor_node: Node3D = landscape.walk_floor
    check("walk placement uses the static topology surface",landscape.floor_mode=="walk" and floor_node!=null and not landscape.is_processing())
    if floor_node!=null:
        check("large terrain has matching drawn and collision faces",floor_node.mesh_instance.mesh.get_faces()==floor_node.collision_shape.shape.get_faces())
        var size: Vector2 = floor_node.space_size
        check("exact fit closes the declared basin",is_equal_approx(size.x*floor_node.scale.x,landscape.walk_width) and is_equal_approx(size.y*floor_node.scale.z,18.0))
        var legacy = load("res://algorithms/wavefunctions/sine_space/SineSpace.gd").new()
        check("other sine floors retain the old fit by default",not legacy.walk_fit_exact)
        legacy.floor_mode="walk";legacy.walk_width=8.0;legacy.walk_depth=18.0
        legacy.position=Vector3(1000,0,0)
        root.add_child(legacy)
        check("unconfigured walk floor retains unscaled half waves",legacy.walk_floor.scale.is_equal_approx(Vector3.ONE))
        legacy.apply_grid_config({"fit":"exact"})
        var fitted: Node3D = legacy.walk_floor
        check("exact fit can also be configured after ready",is_equal_approx(fitted.space_size.x*fitted.scale.x,8.0) and is_equal_approx(fitted.space_size.y*fitted.scale.z,18.0))
        legacy.queue_free()
        var centre: float = floor_node.global_position.x-origin.x
        for p in [Vector3(centre-landscape.walk_width/2+0.01,0,24),Vector3(centre+landscape.walk_width/2-0.01,0,24),Vector3(centre,0,17.01),Vector3(centre,0,34.99)]:
            check("fitted basin edge has support "+str(p),not floor_at(origin+p).is_empty())
        for p in [Vector3(0,0,0),Vector3(1,0,1),Vector3(-1,0,2)]:
            var q := PhysicsRayQueryParameters3D.create(floor_node.to_global(p+Vector3.UP*2),floor_node.to_global(p+Vector3.DOWN*2),1)
            check("sine basin supports at "+str(p),not hall.get_world_3d().direct_space_state.intersect_ray(q).is_empty())
    var original_surface = tray.surface
    var old_radius: float = tray.snapshot().radius_m
    tray.buttons["SIZE"].pressed.emit()
    check("size control changes body not surface",tray.snapshot().radius_m!=old_radius and tray.surface==original_surface)
    tray.buttons["RESET"].pressed.emit()
    check("reset restores middle size and relief",is_equal_approx(tray.snapshot().radius_m,0.075) and is_equal_approx(tray.snapshot().relief_m,0.30))
    tray.buttons["RELEASE"].pressed.emit()
    await tick();await tick()
    check("real release control starts complete batch",tray.running and tray.bodies.size()==32)
    await create_timer(1.0).timeout
    check("released bodies enter physical motion",tray.bodies.any(func(b): return b.linear_velocity.length()>0.01))
    tray.buttons["RESET"].pressed.emit()
    await tick()
    await snapshot("tray",tray.to_global(Vector3(-3.0,2.6,3.2)),tray.to_global(Vector3(-0.5,1.25,0)),65)
    await snapshot("corridor",corridor.to_global(Vector3(1.6,1.7,-5.5)),corridor.to_global(Vector3(0,1.6,0)),75)
    await snapshot("floor",origin+shift+Vector3(6,1.65,16.0),origin+shift+Vector3(6,0.0,27),70)
    await snapshot("gallery",origin+shift+Vector3(2,12,0),origin+shift+Vector3(7,0,20),75)
    observations.scope="Real museum route and temporarily mounted printed program; native Godot/Jolt checks, no independent student or headset claim."

func study_checks(spec: Dictionary) -> void:
    var Lesson = load(spec.lesson)
    var lesson = Lesson.new()
    lesson.position=Vector3(10.5,0,8.5)
    hall.add_child(lesson)
    await tick()
    clear_approach(lesson,lesson.to_global(Vector3(0,0,-1.5)),"study front")
    clear_approach(lesson,lesson.to_global(Vector3(1.3,0,0)),"study side")
    check("printed mesh and point exist in museum",lesson.surface.mesh!=null and lesson.point.is_inside_tree())
    check("point remains the carried sphere",lesson.point.get_child(0).mesh is SphereMesh and is_equal_approx(lesson.point.get_child(1).shape.radius,0.14))
    await create_timer(1.0).timeout
    lesson.point.freeze=true
    check("sphere is above the museum floor after contact",lesson.point.global_position.y>0.14)
    observations.student_point_position=xyz(lesson.point.position)
    await snapshot("student",lesson.to_global(Vector3(-1.7,2.3,-2.3)),lesson.to_global(Vector3(0,0.9,0)),57)
    lesson.queue_free()
    await tick()
    var coarse = Lesson.new()
    coarse.cells=4;coarse.position=Vector3(10.5,0,8.5)
    hall.add_child(coarse)
    await create_timer(1.0).timeout
    coarse.point.freeze=true
    check("coarse example is nearly flat in real hall",coarse.points.all(func(p): return absf(p.y-0.8)<0.00001))
    await snapshot("coarse",coarse.to_global(Vector3(-1.7,2.3,-2.3)),coarse.to_global(Vector3(0,0.9,0)),57)
    coarse.queue_free()
    observations.lesson=spec.lesson
    observations.bay=[10.5,0,8.5]
