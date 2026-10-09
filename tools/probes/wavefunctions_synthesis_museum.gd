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

func press(bench: Node, name: String) -> void:
    var button: Node=bench._panel.find_child(name,true,false)
    var area: Node=button.get_node("InteractableAreaButton")
    area.button_pressed.emit(area)
    await tick()

func landing_checks() -> void:
    await super.landing_checks()
    var origin:=hall.global_position+Vector3(0,0,4)
    for i in range(57):clear_approach(origin+Vector3(11.5,0,2+0.5*i),"central route %d"%i)
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
    var expected: Dictionary={};var present: Dictionary={}
    for row in data.layers.interactables:
        for value in row:
            if str(value).is_empty():continue
            var token:=str(value).split(":")[0].split("#")[0]
            expected[token]=int(expected.get(token,0))+1
    for record in museum.get("_edit_records"):
        if record.get("seg")!=hall or not is_instance_valid(record.get("node")):continue
        var token:=str(record.get("token"))
        if expected.has(token):present[token]=int(present.get(token,0))+1
    check("all 26 authored placements retained",present==expected and present.size()==26)
    var bench:=find_scene("/additive_wave_demo.gd")
    var ambient:=find_scene("/ambient_patch.gd")
    check("primary and separate listening console loaded",bench!=null and ambient!=null)
    if bench==null:return
    bench.set_process(false)
    check("bench starts with five arrival amounts",bench.harmonic_amplitudes==[1.0,0.5,0.333,0.25,0.2])
    check("bench recipe naming initially withheld",bench.preset_label.text=="ARRIVAL RECIPE")
    await press(bench,"Btn_2")
    check("real HOLD button stops phase",bench.held)
    bench._time=0.123;bench._process(0.5)
    check("held phase survives processing",absf(bench._time-0.123)<0.00001)
    var slider: Node=bench.harmonic_sliders[2]
    slider.set_normalized_value(0.7)
    var inner: Node=slider.get("_slider")
    inner.slider_moved.emit(inner.get("slider_position"));bench._process(0)
    check("actual slider event changes H3 only",absf(bench.harmonic_amplitudes[2]-0.7)<0.00001 and bench.harmonic_amplitudes[1]==0.5)
    check("bench raw sum retains negative contribution",absf(bench._calculate_wave_value(PI/2)-0.5)<0.00001)
    await press(bench,"Btn_1");bench._process(0)
    check("real H1 ALONE isolates first contribution",bench.harmonic_amplitudes==[1.0,0.0,0.0,0.0,0.0])
    await press(bench,"Btn_0");bench._process(0)
    check("real BASELINE restores recipe without resetting phase",bench.harmonic_amplitudes==[1.0,0.5,0.333,0.25,0.2] and absf(bench._time-0.123)<0.00001)
    var copied: Array=bench.get_baseline();copied[0]=0
    check("baseline getter returns an independent record",bench.get_baseline()[0]==1)
    var sum_ok:=true
    for i in range(256):
        var angle: float=bench.phase_at(i);var total:=0.0
        for h in range(5):total+=bench.harmonic_amplitudes[h]*sin((h+1)*angle)
        sum_ok=sum_ok and absf(total-bench._calculate_wave_value(angle))<0.00001
    check("all exhibit samples equal signed weighted sums",sum_ok)
    bench._set_amplitudes([1.0,0.5,0.333,0.25,0.22])
    check("small recipe change retains sawtooth name",bench._detect_preset().contains("Sawtooth"))
    bench._set_amplitudes([1.0,0.5,0.333,0.25,0.24])
    check("larger recipe change crosses naming threshold",bench._detect_preset()=="Custom Waveform")
    bench._set_amplitudes([1.0,0.0,0.005,0.0,0.0]);bench._process(0)
    check("hidden small ribbon still changes raw sum",absf(bench._calculate_wave_value(PI/2)-0.995)<0.00001)
    bench.restore_baseline();bench._time=0;bench._process(0)
    var fifth: Vector3=bench.component_meshes.to_global(bench._component_vertex(0,-0.2,4))
    check("fifth component clears bench and readout",fifth.y>1.15)
    clear_approach(bench.to_global(Vector3(0,0,1.5)),"primary comparison")
    clear_approach(bench.to_global(Vector3(1.36,0,1.45)),"primary sliders")
    if ambient!=null:clear_approach(ambient.to_global(Vector3(0,0,1.1)),"listening console")
    for z in [15,18,21]:
        clear_approach(origin+Vector3(5.5,0,z-0.8),"specimen bench %d"%z)
    check("additive display and controls remain at native scale",bench.scale.is_equal_approx(Vector3.ONE))
    for token in ["synthesis_stand","double_helix_scene","UnitCircleTrig"]:
        for record in museum.get("_edit_records"):
            if record.get("seg")!=hall or record.get("token")!=token:continue
            var node: Node3D=record.node
            var bounds: AABB=museum.call("_seat_extent",node)
            check(token+" fits its gallery bay",bounds.size.x<7 and bounds.size.z<7 and bounds.position.y>-0.01)
            if token=="double_helix_scene":
                var driver: Node=node.get_node("DoubleHelix")
                driver.set_process(false)
                for i in range(180):driver._process(0.1)
                var bounded: bool=driver.trail_points1.all(func(p):return p.y>=-4.8001)
                check("slow-frame helix trail stays above footing",bounded and driver.trail_points1.size()>1)
                driver.set_process(true)
    await snapshot("bench",bench.to_global(Vector3(0.3,1.7,3.8)),bench.to_global(Vector3(0.2,1.4,0.3)),57)
    if ambient!=null:await snapshot("listening",ambient.to_global(Vector3(-2,2.1,4)),ambient.to_global(Vector3(0,1,0)),63)
    await snapshot("gallery",origin+Vector3(25,18,-1),origin+Vector3(12,0.5,17),65)
    observations.scope="Native museum and exact printed study. Actual exhibit callbacks; no physical-headset, independent-student or complete Room Memory travel claim."

func study_checks(spec: Dictionary) -> void:
    var lesson=load(spec.lesson).new()
    lesson.position=Vector3(16,0,11);lesson.rotation.y=PI
    hall.add_child(lesson);lesson.set_process(false);await tick()
    clear_approach(lesson.to_global(Vector3(0,0,1.8)),"learner standing view")
    check("exact learner program builds in actual museum",lesson.points.size()==5 and lesson.rows.size()==6)
    lesson.points[2].position.y=0.8;lesson._process(0)
    check("museum hand-height removes H3 and raises quarter-cycle sum",absf(lesson.sum_at(PI/2)-1.2)<0.00001)
    lesson.phase=0.41;lesson.points[4].action()
    check("museum point action restores recipe at same phase",absf(lesson.amounts[2]-1.0/3.0)<0.00001 and absf(lesson.phase-0.41)<0.00001)
    lesson.phase=0;lesson.draw_state()
    await snapshot("student",lesson.to_global(Vector3(0.2,2.3,5.2)),lesson.to_global(Vector3(0,1.9,0)),57)
    observations.student_bay=[16,0,11];observations.student_yaw=180
    lesson.queue_free();await tick()
