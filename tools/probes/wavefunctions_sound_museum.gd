extends "res://tools/probes/wavefunctions_lessons_museum.gd"

func press(rig: Node3D, index: int) -> void:
    var button: Node = rig._panel.find_child("Btn_%d" % index, true, false)
    var area: Node = button.get_node_or_null("InteractableAreaButton") if button!=null else null
    check("audition button %d has its real input receiver" % index,area!=null and area.has_signal("button_pressed"))
    if area!=null:area.button_pressed.emit(area)

func clear_approach(owner: Node3D, at: Vector3, title: String) -> void:
    var floor_hit := floor_at(at)
    check(title+" has level floor",not floor_hit.is_empty() and absf(floor_hit.position.y-at.y)<0.06)
    var capsule := CapsuleShape3D.new()
    capsule.radius=0.26;capsule.height=1.6
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not owner.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    check(title+" is unobstructed",obstacles.is_empty())
    observations[title]=obstacles

func landing_checks() -> void:
    await super.landing_checks()
    var rig := find_scene("/DualBallFMController.gd")
    check("existing two-ball instrument retained",rig!=null)
    if rig==null:return
    var origin := hall.global_position+Vector3(0,0,4)
    for at in [Vector3(11.5,0,2.5),Vector3(11.5,0,5.5),Vector3(14,0,6),Vector3(14,0,10),Vector3(14,0,13.5),Vector3(12,0,15),Vector3(12.5,0,20),Vector3(12.5,0,25),Vector3(11.5,0,29)]:
        clear_approach(rig,origin+at,"route "+str(at))
    clear_approach(rig,Vector3(rig.global_position.x,origin.y,rig.global_position.z-1.1),"instrument front")
    check("both carrier and modulator are at reachable hand height",rig.carrier_ball.global_position.y-origin.y>0.9 and rig.carrier_ball.global_position.y-origin.y<1.6 and rig.modulator_ball.global_position.y-origin.y>0.9 and rig.modulator_ball.global_position.y-origin.y<1.6)
    check("desk staging and longhand scope preserved",rig.stand=="desks" and rig.evidence=="longhand" and rig._panel!=null)
    var spheres_before := [rig.carrier_ball,rig.modulator_ball]
    rig.play_on_move=false
    press(rig,0)
    check("baseline remains 440 Hz with zero modulation",is_equal_approx(rig.carrier_freq,440) and is_zero_approx(rig.mod_index))
    press(rig,1)
    var saved: PackedByteArray=rig._ref_stream.data.duplicate()
    var before: Dictionary=rig.get_reference()
    rig.modulator_mapper.set_values(2.0,2.0,0.5)
    rig.modulator_mapper.values_changed.emit(2.0,2.0,0.5)
    check("real mapper signal changes only phase depth",rig.mod_index==2 and rig.differences_from_reference().size()==1 and rig.differences_from_reference()[0].begins_with("I "))
    check("holding A preserves its parameters and rendered samples",rig.get_reference()==before and rig._ref_stream.data==saved)
    press(rig,3)
    check("comparison starts retained A",rig.last_note_tag=="A" and rig.audio_player.stream.data==saved)
    await create_timer(rig._ref_seconds+0.35).timeout
    check("comparison then plays changed B",rig.last_note_tag=="B" and rig.audio_player.stream.data!=saved)
    check("both existing hand controls remain the same bodies",spheres_before==[rig.carrier_ball,rig.modulator_ball])
    var authored: Dictionary={}
    var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
    for row in doc.layers.interactables:
        for token in row:
            if str(token).strip_edges().is_empty():continue
            var id: String=str(token).split(":")[0].split("#")[0]
            authored[id]=int(authored.get(id,0))+1
    var present: Dictionary={}
    for record in museum.get("_edit_records"):
        if record.get("seg")!=hall or not is_instance_valid(record.get("node")):continue
        var token: String=str(record.get("token"))
        if authored.has(token):present[token]=int(present.get(token,0))+1
    check("all thirty-three authored placements remain present",present==authored and authored.values().reduce(func(a,b):return a+b,0)==33)
    observations.authored_placements=present
    await snapshot("instrument",rig.to_global(Vector3(0.25,1.65,2.5)),rig.to_global(Vector3(0.25,1.4,0)),60)
    await snapshot("gallery",origin+Vector3(3,22,-2),origin+Vector3(12,0,17),72)
    await snapshot("first-encounter",origin+Vector3(11.5,1.65,4),rig.global_position+Vector3.UP*1.15,73)
    observations.scope="Actual museum layout, retained artifact placements, controlled mapper signals and A/B playback. No synthesis code changed; no physical headset or listening-quality claim."

func study_checks(spec: Dictionary) -> void:
    var lesson=load(spec.lesson).new()
    lesson.position=Vector3(7,0,10);lesson.rotation.y=PI
    hall.add_child(lesson)
    await tick()
    clear_approach(lesson,lesson.to_global(Vector3(0,0,1.3)),"student approach")
    check("printed program constructs pickable sphere and sound inside museum",lesson.point.enabled and lesson.player is AudioStreamPlayer3D and lesson.reference.data.size()==52920)
    lesson.point.position.y=1.3
    lesson.point.action_pressed.emit(lesson.point)
    check("carried point trigger starts museum study playback",lesson.busy and lesson.player.playing)
    lesson.draw_state()
    var eye: Vector3=lesson.to_global(Vector3(0.1,1.7,3.0))
    var target: Vector3=lesson.to_global(Vector3(0,1.5,0))
    var query := PhysicsRayQueryParameters3D.create(eye,target,1)
    check("student curve sightline is clear",hall.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
    await snapshot("student",eye,target,59)
    observations.student_bay=[7,0,10]
    observations.student_bay_yaw=180
    await create_timer(1.6).timeout
    lesson.queue_free()
    await tick()
