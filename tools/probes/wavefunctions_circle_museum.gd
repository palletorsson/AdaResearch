extends "res://tools/probes/wavefunctions_lessons_museum.gd"

func snapshot(name: String, eye: Vector3, target: Vector3, fov: float = 55.0) -> void:
    if name in ["student", "projection"]:
        var query := PhysicsRayQueryParameters3D.create(eye,target,1)
        check(name+" sightline is clear",hall.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
    await super.snapshot(name,eye,target,fov)

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
    var circle := find_scene("/unit_circle/UnitCircle.gd")
    var bridge := find_scene("/unit_circle/SimpleOscillatingBridge.gd")
    var curve := find_scene("/oscillation_driver/OscillationCurve.gd")
    check("primary and supporting encounters loaded",circle!=null and bridge!=null and curve!=null)
    if circle==null or bridge==null or curve==null:return
    var origin := hall.global_position+Vector3(0,0,4)
    for p in [Vector3(11.5,0,2.5),Vector3(11.5,0,7),Vector3(2,0,10.5),Vector3(11.5,0,14),Vector3(11.5,0,19),Vector3(11.5,0,24),Vector3(11.5,0,26.5)]:
        clear_approach(circle,origin+p,"route "+str(p))
    check("gallery configuration applied",circle.gallery_projection and not circle.enable_collision and circle.samples_per_cycle==64)
    var panel: Node3D=circle.gallery_controls.panel
    var approach: Vector3=panel.to_global(Vector3(0,0,0.8))
    approach.y=origin.y
    clear_approach(circle,approach,"angle controller")
    check("angle panel is in hand reach",panel.global_position.y>0.8 and panel.global_position.y<1.3)
    circle.gallery_controls.slider.set_normalized_value(0.25)
    circle.gallery_controls.slider.slider_moved.emit(0.25)
    check("actual angle slider selects top point",not circle.running and absf(circle.angle-PI/2)<0.0001 and circle.rotating_point.position.distance_to(Vector3.UP)<0.0001)
    check("scrubbing retains complete finite graph",circle.finished and circle.built_index==127)
    var steps: Array=[]
    for n in circle.get_children():
        if str(n.name).begins_with("Platform_"):steps.append(n)
    check("exactly 128 graph samples",steps.size()==128)
    check("last sample closes two turns at declared extent",steps.back().position.distance_to(Vector3(13.8,0,0))<0.0001)
    check("graph has no hidden collision",steps.all(func(n): return n.get_child_count()==1))
    var stopped: float=circle.angle
    await create_timer(0.1).timeout
    check("paused angle remains still",is_equal_approx(circle.angle,stopped))
    circle.gallery_controls.play_button.button_pressed.emit(null)
    await create_timer(0.1).timeout
    check("actual run button restarts rotation",circle.running and circle.angle>stopped)
    circle.gallery_controls.replay_button.button_pressed.emit(null)
    check("actual replay clears retained graph",circle.running and not circle.finished and circle.built_index==-1 and circle.angle==0)
    circle._process(TAU*2/circle.rotation_speed)
    check("replay reaches exact two-turn endpoint",circle.finished and absf(circle.angle-TAU*2)<0.0001)
    circle._process(0.25)
    check("point continues after finite drawing",circle.finished and circle.angle>0 and circle.angle<TAU)
    circle.scrub_angle(PI/4)
    var legacy = load("res://algorithms/wavefunctions/unit_circle/UnitCircle.gd").new()
    check("unconfigured exhibit retains original dimensions and collision",not legacy.gallery_projection and legacy.wave_length==28 and legacy.enable_collision and legacy.platform_size==Vector3(1.5,0.3,5))
    legacy.position=Vector3(1000,0,0)
    root.add_child(legacy)
    legacy.apply_grid_config({"gallery":"projection"})
    legacy.scrub_angle(PI)
    check("gallery can be applied after ready",legacy.gallery_controls!=null and legacy.finished and legacy.built_index==127 and legacy.rotating_point.position.is_equal_approx(Vector3.LEFT))
    legacy.apply_grid_config({"gallery":"projection"})
    check("reapplying gallery preserves current state",legacy.angle==PI and legacy.built_index==127)
    legacy.queue_free()
    check("supporting bridge fits ten metre bay",bridge.scale.is_equal_approx(Vector3.ONE*0.25) and bridge.num_platforms*bridge.platform_spacing*bridge.scale.z<=10)
    check("bridge uses museum light and camera",bridge.museum_environment and bridge.find_children("*","DirectionalLight3D").is_empty() and bridge.find_children("*","Camera3D").is_empty())
    curve.set_process(false)
    for i in range(100):curve._process(0.1)
    check("scrolling curve stays inside declared width at ten FPS",curve.history_width==8 and curve.points.all(func(p):return p.x<=8))
    await snapshot("projection",circle.to_global(Vector3(6,0.3,7)),circle.to_global(Vector3(6,0,0)),78)
    await snapshot("control",circle.to_global(Vector3(-0.7,0.4,3.4)),circle.to_global(Vector3(0,0.2,0)),63)
    await snapshot("gallery",origin+Vector3(2,14,1),origin+Vector3(12,0,16),72)
    observations.scope="Native museum layout, actual controls and temporarily mounted printed program; no independent student or headset claim."

func study_checks(spec: Dictionary) -> void:
    var lesson=load(spec.lesson).new()
    lesson.position=Vector3(11,0,10);lesson.rotation.y=PI;lesson.running=false;lesson.angle=PI/4
    hall.add_child(lesson)
    await tick()
    clear_approach(lesson,lesson.to_global(Vector3(2.5,0,2)),"student viewing position")
    check("printed program creates its own museum readout",lesson.label.is_inside_tree() and lesson.label.text.contains("GRAPH"))
    check("printed circle shares graph height in museum",is_equal_approx(lesson.point.global_position.y,lesson.marker.global_position.y))
    check("printed body remains the carried point",is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14))
    await snapshot("student",lesson.to_global(Vector3(2.2,2.0,3.2)),lesson.to_global(Vector3(2.2,1.5,0)),82)
    observations.lesson=spec.lesson
    observations.bay=[11,0,10]
    observations.bay_yaw_degrees=180
    lesson.queue_free()
    await tick()
