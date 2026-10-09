extends "res://tools/probes/wavefunctions_lessons_museum.gd"

func clear_approach(at: Vector3, title: String) -> void:
    var hit:=floor_at(at)
    check(title+" has floor",not hit.is_empty() and absf(hit.position.y-at.y)<0.06)
    var capsule:=CapsuleShape3D.new();capsule.radius=0.26;capsule.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*0.91);query.collision_mask=1|4
    var obstacles: Array=[]
    for h in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if h.collider!=museum.get("_player"):obstacles.append(str(h.collider.get_path()))
    check(title+" has body clearance",obstacles.is_empty())
    if not obstacles.is_empty():observations[title]=obstacles

func set_frequency(slider: Node, frequency: float) -> void:
    slider.set_normalized_value((frequency-1.0)/9.0)
    # Exercise the actual inner slider event and its wrapper connection.
    var inner: Node=slider.get("_slider")
    inner.slider_moved.emit(inner.get("slider_position"))
    await tick()

func landing_checks() -> void:
    await super.landing_checks()
    var origin:=hall.global_position+Vector3(0,0,4)
    for i in range(85):clear_approach(origin+Vector3(16.5,0,2+0.5*i),"central route %d"%i)
    var beat:=find_scene("/beat_frequency_demo.gd")
    var path:=find_scene("/TrigWalkingPath.gd")
    var field:=find_scene("/WaveInterference.gd")
    check("three principal encounters loaded",beat!=null and path!=null and field!=null)
    if beat==null or path==null or field==null:return
    var expected: Dictionary={"beat_frequency_demo":1,"TrigWalkingPath":1,"sine_oscillation":1,"lissajous_curves":1,"wave_interference":1,"dark_sphere":1}
    var present: Dictionary={}
    for record in museum.get("_edit_records"):
        if record.get("seg")!=hall or not is_instance_valid(record.get("node")):continue
        var token: String=str(record.get("token"))
        if expected.has(token):present[token]=int(present.get(token,0))+1
    check("six authored exhibits retained",present==expected)
    beat.set_process(false)
    var slider_a:=beat.find_child("Param_0",true,false)
    var slider_b:=beat.find_child("Param_1",true,false)
    check("sliders start at displayed frequencies",absf(slider_a.get_normalized_value()*9+1-beat._freq_a)<0.001 and absf(slider_b.get_normalized_value()*9+1-beat._freq_b)<0.001)
    await set_frequency(slider_a,4.0);await set_frequency(slider_b,4.5)
    check("real slider events select nearby frequencies",absf(beat._freq_a-4)<0.001 and absf(beat._freq_b-4.5)<0.001)
    beat._time=1;beat._animate_spheres()
    var flat:=true
    for ball in beat._spheres_sum:flat=flat and absf(ball.position.y-(beat._base_y-beat.row_spacing))<0.00001
    check("actual exhibit cancels after one second",flat)
    check("visible sum label admits its half gain",beat.get_children().any(func(n):return n is Label3D and n.text=="(A+B)/2"))
    await set_frequency(slider_b,4.0)
    beat._time=0.123;beat._animate_spheres()
    var aligned:=true
    for i in range(beat.sphere_count):
        aligned=aligned and absf((beat._spheres_a[i].position.y-beat._base_y-beat.row_spacing)-(beat._spheres_sum[i].position.y-beat._base_y+beat.row_spacing))<0.00001
    check("equal frequencies match after display gain",aligned)
    await set_frequency(slider_a,1);await set_frequency(slider_b,10)
    check("both control range endpoints reachable",absf(beat._freq_a-1)<0.001 and absf(beat._freq_b-10)<0.001)
    await set_frequency(slider_a,4);await set_frequency(slider_b,4.5)
    beat._time=0.25;beat._animate_spheres()
    clear_approach(beat.to_global(Vector3(0,0,0.6))-Vector3.UP*beat.global_position.y,"beat controls approach")
    await snapshot("beat-controls",beat.to_global(Vector3(0,0.95,1.1)),beat.to_global(Vector3(0,0.92,0)),57)
    beat.set_process(true)
    check("full finite walking paths preserved",path.sine_steps.size()==40 and path.cosine_steps.size()==40)
    check("paths rooted half a metre below deck",absf(path.global_position.y+0.5)<0.001)
    check("three authored basin access surfaces present",hall.find_children("BasinAccess_*","StaticBody3D",true,false).size()==3)
    for z in [15.1,15.8,16.5]:clear_approach(origin+Vector3(7.5,0,z),"near bridge %.1f"%z)
    for offset in [0.3,1.5,3.0,4.4]:
        var at:=origin+Vector3(7.5,-1.2+offset*(1.2/4.5),40.5+offset)
        var hit:=floor_at(at)
        check("far ramp %.1f"%offset,not hit.is_empty() and absf(hit.position.y-at.y)<0.04)
    await walk_side_ramp(origin)
    field.set_process(false);field.time=0.37;field.animate_interference_field(0)
    var original: Array=[]
    for p in field.field_points:original.append(p.position.y)
    var saved:=field.transform
    field.position+=Vector3(4,2,-3);field.rotate_y(0.71);field.scale*=1.2
    field.animate_interference_field(0)
    var invariant:=true;var matches:=true
    for i in range(field.field_points.size()):
        var p: Node3D=field.field_points[i]
        invariant=invariant and absf(p.position.y-original[i])<0.00001
        var terms: Vector2=field._wave_terms(Vector3(p.position.x,0,p.position.z))
        matches=matches and absf(p.position.y-(terms.x+terms.y)*0.5)<0.00001
    check("interference independent of museum placement and drawn height",invariant)
    check("field and explanatory terms agree at every sample",matches)
    field.transform=saved;field.set_process(true)
    await snapshot("paths",origin+Vector3(13,8,13),origin+Vector3(7.5,-0.5,29),61)
    await snapshot("gallery",origin+Vector3(35,24,0),origin+Vector3(16,0,28),65)
    observations.scope="Actual controls, signed-sum display, local interference, route and ramp access. Full moving-path traversal and headset unverified."

func walk_side_ramp(origin: Vector3) -> void:
    var walker: CharacterBody3D=museum.get("_player")
    var saved:=walker.global_position
    walker.set_process(false);walker.set_physics_process(false)
    walker.global_position=origin+Vector3(2.75,0.04,14.5);walker.velocity=Vector3.ZERO
    var bottom:=0.0;var down_ok:=false;var up_ok:=false
    for direction in [1.0,-1.0]:
        for frame in range(400):
            await physics_frame
            walker.velocity=Vector3(0,0 if walker.is_on_floor() else walker.velocity.y-9.8/Engine.physics_ticks_per_second,2.5*direction)
            walker.move_and_slide()
            bottom=minf(bottom,walker.global_position.y)
            if direction>0 and walker.global_position.z>origin.z+25.5:
                down_ok=walker.is_on_floor();break
            if direction<0 and walker.global_position.z<origin.z+14.5:
                up_ok=walker.is_on_floor();break
    check("museum player descends to catch floor",down_ok and bottom<-3.1 and bottom>-3.5)
    check("museum player returns up side ramp",up_ok and walker.global_position.y>-0.1)
    observations.ramp_lowest=bottom
    walker.global_position=saved;walker.velocity=Vector3.ZERO

func study_checks(spec: Dictionary) -> void:
    var lesson=load(spec.lesson).new()
    lesson.position=Vector3(23,0,12);lesson.rotation.y=PI
    hall.add_child(lesson);lesson.set_process(false);await tick()
    clear_approach(lesson.to_global(Vector3(0,0,1.5)),"student standing view")
    check("printed program builds in museum",lesson.rows.size()==3 and lesson.point.enabled)
    lesson.point.position.y=1.45;lesson.elapsed=0.9;lesson.point.action()
    check("museum point action sets 4.25 Hz and shared start",absf(lesson.frequency_b-4.25)<0.00001 and lesson.elapsed==0)
    lesson.elapsed=2;lesson.draw_state()
    check("museum reconstruction cancels at predicted time",absf(lesson.values_at(2,PI/2).z)<0.00001)
    await snapshot("student-cancellation",lesson.to_global(Vector3(0.2,2.2,4.7)),lesson.to_global(Vector3(-0.1,1.7,0)),59)
    lesson.elapsed=0;lesson.draw_state()
    await snapshot("student",lesson.to_global(Vector3(0.2,2.2,4.7)),lesson.to_global(Vector3(-0.1,1.7,0)),59)
    observations.student_bay=[23,0,12];observations.student_yaw=180
    lesson.queue_free();await tick()
