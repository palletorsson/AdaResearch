extends "res://tools/probes/wavefunctions_lessons_museum.gd"

func landing_checks() -> void:
    await super.landing_checks()
    await gallery_checks()
    observations.scope = "Rearranged museum and temporarily mounted student program. Native placement, projection and behaviour checks; scripted hand gesture, no headset claim."

func gallery_checks() -> void:
    var pendulum := find_scene("/PendulumWave.gd")
    var paintings := find_scene("/WavePaintings.gd")
    var hand := find_scene("/draw_dot_time_domain.gd")
    var foucault := find_scene("/foucault_pendulum.gd")
    check("all four principal encounters retained",pendulum!=null and paintings!=null and hand!=null and foucault!=null)
    if pendulum==null or paintings==null or hand==null or foucault==null:return
    check("main pendulum is a larger 2.8 metre swing",is_equal_approx(pendulum.length,2.8) and is_equal_approx(pendulum.pivot_height,3.9))
    check("painting enlarged from 20 to 60 percent",absf(paintings.scale.x-0.6)<0.0001 and paintings.pendulums.size()==3)
    check("hand point is at reachable height",hand._grab_point.global_position.y>0.95 and hand._grab_point.global_position.y<1.5)
    check("hand recorder panel stays mounted",hand.data_table_mount=="plinth" and hand._data_panel!=null)
    check("hand timeline expires before the next display",is_equal_approx(hand.fade_duration,10.0))
    var origin := hall.global_position+Vector3(0,0,4)
    for at in [Vector3(10.5,0,2.5),Vector3(10.5,0,10.5),Vector3(10.5,0,17.5),Vector3(10.5,0,27.5)]:
        clear_approach(pendulum,origin+at,"central passage "+str(at.z))
    for z in [21.0,23.0,24.5,26.5]:
        clear_approach(paintings,origin+Vector3(8.1,0,z),"route between paintings "+str(z))
    clear_approach(pendulum,pendulum.to_global(Vector3(-3.4,0,0)),"sampler buttons")
    clear_approach(pendulum,pendulum.to_global(Vector3(-4.0,0,-3.0)),"side readout")
    clear_approach(hand,hand.global_position+Vector3(0,-hand.global_position.y,-1.1),"hand recorder front")
    pendulum.set_process(false);pendulum.set_physics_process(false)
    pendulum.reset_experiment()
    for i in 600:pendulum._physics_process(1.0/60)
    pendulum._draw_trail();pendulum._update_readout()
    var floor_record = pendulum._floor_projection
    check("floor projection has a real rendered segment per adjacent sample",floor_record!=null and floor_record.segments.multimesh.visible_instance_count==pendulum.trail_points.size()-1)
    var p: Vector3 = pendulum.trail_points.back()
    var record_before: Array = pendulum.trail_points.duplicate()
    var floor_point: Vector3 = floor_record.floor_position(p)
    check("floor projection retains x and age depth",absf(floor_point.x-p.x)<0.00001 and absf(floor_point.z+(pendulum.time-p.z)*0.6)<0.00001)
    check("projection lies just above runner",absf(floor_point.y-0.035)<0.00001)
    floor_record.draw_record()
    check("projection leaves source observations intact",record_before==pendulum.trail_points)
    var segment: Transform3D = floor_record.segments.multimesh.get_instance_transform(0)
    var start: Vector3 = floor_record.floor_position(pendulum.trail_points[0])
    var end: Vector3 = floor_record.floor_position(pendulum.trail_points[1])
    check("floor cylinder actually joins its two samples",(segment*Vector3(0,-0.5,0)).distance_to(start)<0.00001 and (segment*Vector3(0,0.5,0)).distance_to(end)<0.00001)
    var legacy = load("res://algorithms/wavefunctions/oscillation_driver/PendulumWave.tscn").instantiate()
    legacy.position=Vector3(-1000,0,0)
    root.add_child(legacy)
    legacy.set_process(false);legacy.set_physics_process(false)
    check("unconfigured pendulum retains original dimensions",is_equal_approx(legacy.length,2.0) and is_equal_approx(legacy.pivot_height,2.9) and is_equal_approx(legacy.frame_half_width,1.7))
    check("floor projection is opt in",legacy._floor_projection==null)
    check("large and original rods do not share a changed mesh",is_equal_approx(legacy.rod.mesh.height,2.0) and is_equal_approx(pendulum.rod.mesh.height,2.8))
    legacy.queue_free()
    var t: float = pendulum.time
    var a: float = pendulum.angle
    pendulum.set_sampler("coarse")
    check("gallery sampler preserves swing and clock",pendulum.time==t and pendulum.angle==a and pendulum.trail_points.is_empty())
    for i in 600:pendulum._physics_process(1.0/60)
    pendulum._draw_trail();pendulum._update_readout()
    await snapshot("pendulum-floor",pendulum.to_global(Vector3(-4.5,2.4,-6.8)),pendulum.to_global(Vector3(0,1.2,-2.5)),65)
    await snapshot("readout",pendulum.to_global(Vector3(-4.5,1.65,-3)),pendulum.to_global(Vector3(-3.1,1.45,-3)),50)
    await snapshot("paintings",paintings.to_global(Vector3(0,2.0,15)),paintings.to_global(Vector3(0,1.8,0)),75)
    await snapshot("painting-close",paintings.to_global(Vector3(0,1.9,4.0)),paintings.to_global(Vector3(0,1.2,-1.5)),65)
    hand.set_process(false)
    for i in 160:
        var seconds := i*0.05
        hand._grab_point.global_position=hand.to_global(Vector3(0.55*sin(seconds*2),0.3*cos(seconds*2),0))
        hand._process(0.05)
    check("scripted hand movement leaves a nontrivial timeline",hand._trail_points.size()>30 and hand._trail_points[0].z>hand._trail_points.back().z+2.0)
    await snapshot("hand-timeline",hand.to_global(Vector3(2,0.65,-2.0)),hand.to_global(Vector3(0,0.1,2.0)),70)
    await snapshot("foucault",foucault.global_position+Vector3(-3,2.3,-3),foucault.global_position+Vector3(0,0.2,0),60)
    await snapshot("gallery-above",origin+Vector3(1,17,1),origin+Vector3(10.5,0,15),75)
    observations.gallery={"pendulum_length":pendulum.length,"pivot_height":pendulum.pivot_height,"painting_scale":paintings.scale.x,"hand_height":hand.global_position.y,"record_count":pendulum.trail_points.size(),"scripted_hand_capture":true}

func clear_approach(lesson: Node3D, at: Vector3, title: String) -> void:
    check(title + " has floor", not floor_at(at).is_empty())
    var capsule := CapsuleShape3D.new()
    capsule.radius=0.26;capsule.height=1.6
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array = []
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider != museum.get("_player") and not lesson.is_ancestor_of(hit.collider): obstacles.append(str(hit.collider.get_path()))
    check(title + " clear of other bodies",obstacles.is_empty())
    observations[title]=obstacles

func study_checks(spec: Dictionary) -> void:
    var Lesson = load(spec.lesson)
    var lesson = Lesson.new()
    lesson.position=Vector3(10,0,21.8)
    hall.add_child(lesson)
    lesson.set_process(false);lesson.set_physics_process(false)
    await tick()
    check("student cube present in real hall",lesson.cube.mesh is BoxMesh and lesson.cube.is_inside_tree())
    check("student bay has floor",not floor_at(lesson.global_position).is_empty())
    clear_approach(lesson,lesson.to_global(Vector3(0,0,1.2)),"first study approach")
    clear_approach(lesson,lesson.to_global(Vector3(-1.2,0,-1.5)),"history side walk")
    var second = Lesson.new()
    second.position=Vector3(2.5,0,22.2)
    second.sample_interval=0.2
    hall.add_child(second)
    second.set_process(false);second.set_physics_process(false)
    await tick()
    check("comparison bay has floor",not floor_at(second.global_position).is_empty())
    clear_approach(second,second.to_global(Vector3(0,0,1.2)),"second study approach")
    lesson.reset_experiment();second.reset_experiment()
    for i in 480:
        lesson._physics_process(1.0/60)
        second._physics_process(1.0/60)
    lesson.draw_state();second.draw_state()
    check("two samplers leave swing states equal",absf(lesson.angle-second.angle)<0.00001)
    check("fine display reaches its count bound",lesson.history.size()==120)
    check("coarse display retains fewer marks",second.history.size()>=29 and second.history.size()<=31)
    check("coarse record retains longer duration",second.history[0].time<lesson.history[0].time)
    var position_before: Vector3 = lesson.history[0].position
    lesson.draw_state()
    check("record remains intact in museum",lesson.history[0].position.is_equal_approx(position_before))
    check("cube stays above floor",lesson.to_local(lesson.cube.global_position).y>0.75)
    observations.lesson=spec.lesson
    observations.bays=[[10,0,21.8],[2.5,0,22.2]]
    observations.fine_count=lesson.history.size()
    observations.coarse_count=second.history.size()
    await snapshot("student-fine",lesson.to_global(Vector3(-2.4,2.1,1.3)),lesson.to_global(Vector3(0,1.5,-0.8)),58)
    # Same bay and elapsed time, only sampling changes for a legible comparison.
    lesson.reset_experiment();lesson.set_sampling(0.2)
    for i in 480: lesson._physics_process(1.0/60)
    lesson.draw_state()
    await snapshot("student-coarse",lesson.to_global(Vector3(-2.4,2.1,1.3)),lesson.to_global(Vector3(0,1.5,-0.8)),58)
    await snapshot("context",hall.to_global(Vector3(9.5,2.2,23.2)),hall.to_global(Vector3(7.4,1.5,18.7)),75)
    lesson.queue_free();second.queue_free()
