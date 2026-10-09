extends "res://tools/probes/wavefunctions_lessons_museum.gd"

func clear_approach(owner: Node3D, at: Vector3, title: String) -> void:
    var hit:=floor_at(at)
    check(title+" has level floor",not hit.is_empty() and absf(hit.position.y-at.y)<0.06)
    var capsule:=CapsuleShape3D.new()
    capsule.radius=0.26;capsule.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for h in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if h.collider!=museum.get("_player") and (owner==null or not owner.is_ancestor_of(h.collider)):obstacles.append(str(h.collider.get_path()))
    check(title+" has body clearance",obstacles.is_empty())
    if not obstacles.is_empty():observations[title]=obstacles

func settle() -> void:
    for i in range(5):await physics_frame
    await process_frame

func place_tip(rig: Node3D, target: Vector3) -> void:
    var stick: Node3D=rig.get_stick()
    var tip: Node3D=stick.get_node("Blade/Top/TrackBall")
    stick.global_position+=target-tip.global_position
    await settle()

func landing_checks() -> void:
    museum.call("flush_stamps");await tick()
    await super.landing_checks()
    var origin:=hall.global_position+Vector3(0,0,4)
    var rig:=find_scene("/ResonatingMetallophone.gd")
    check("existing eight-bar instrument present",rig!=null and rig.bars.size()==8)
    if rig==null:return
    check("metallophone faces the entrance",is_equal_approx(fposmod(rig.rotation_degrees.y,360),180))
    for i in range(45):clear_approach(null,origin+Vector3(9.5,0,2+0.4*i),"route %d"%i)
    clear_approach(null,rig.to_global(Vector3(0,0,1.1)),"metallophone approach")
    var eye: Vector3=rig.to_global(Vector3(0,1.65,1.1))
    var readout: Vector3=rig.to_global(Vector3(0,1.65,0.03))
    check("standing-eye readout sightline clear",hall.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,readout,1)).is_empty())
    var expected: Dictionary={"GlassRack":2,"lab_table":2,"dark_sphere":1,"SystemsMusicTest":1,"RackAmbientDrone":1,"BigPipeSystem":1,"air_music_display_case":1,"resonating_metallophone":1}
    var present: Dictionary={}
    for record in museum.get("_edit_records"):
        if record.get("seg")!=hall or not is_instance_valid(record.get("node")):continue
        var token: String=str(record.get("token"))
        if expected.has(token):present[token]=int(present.get(token,0))+1
    check("all ten authored placements retained",present==expected)
    observations.preserved_artifacts=present
    rig.stop_all_resonances()
    var stick: RigidBody3D=rig.get_stick()
    stick.freeze=true
    stick.collision_layer=stick.picked_up_layer
    stick.collision_mask=0
    await place_tip(rig,rig.bars[0].global_position+Vector3.UP*0.4)
    rig.stop_all_resonances()
    await place_tip(rig,rig.bars[0].global_position+Vector3.UP*0.11)
    check("actual nested stick tip starts a bar on contact",rig.bars[0].audio_player.playing)
    await place_tip(rig,rig.bars[0].global_position+Vector3.UP*0.4)
    await create_timer(0.15).timeout
    var age: float=rig.bars[0].audio_player.get_playback_position()
    await place_tip(rig,rig.bars[3].global_position+Vector3.UP*0.4)
    await place_tip(rig,rig.bars[3].global_position+Vector3.UP*0.11)
    check("another actual bar overlaps first",rig.bars[0].audio_player.playing and rig.bars[3].audio_player.playing)
    check("original bar age is not restarted",rig.bars[0].audio_player.get_playback_position()>=age)
    await place_tip(rig,rig.bars[3].global_position+Vector3.UP*0.4)
    await create_timer(0.15).timeout
    await place_tip(rig,rig.bars[3].global_position+Vector3.UP*0.11)
    check("restrike restarts only selected bar",rig.bars[3].audio_player.get_playback_position()<0.18 and rig.bars[0].audio_player.get_playback_position()>0.3)
    await place_tip(rig,rig.bars[3].global_position+Vector3.UP*0.4)
    check("sum display samples generated audio",rig.visualizer.sample_audio and rig.visualizer._audio_windows.size()>=2 and rig.visualizer._summed_samples.size()==512)
    await snapshot("instrument",rig.to_global(Vector3(1.4,2.0,3.1)),rig.to_global(Vector3(0,1.05,0)),54)
    rig.stop_all_resonances()
    stick.set_meta("returning",true)
    await place_tip(rig,rig.bars[1].global_position+Vector3.UP*0.11)
    check("returning stick does not start another note",not rig.bars[1].audio_player.playing)
    stick.transform=rig._stick_rest
    stick.set_meta("returning",false)
    await settle()
    await snapshot("gallery",origin+Vector3(-1,20,-1),origin+Vector3(9,0,12),67)
    await snapshot("entry-after",origin+Vector3(9.5,1.65,2),origin+Vector3(9,1.3,13),72)
    observations.scope="Actual museum: unchanged instrument, physical stick-tip contacts, overlap, restrike, return suppression, route and view checks. No headset or listening-quality claim."

func study_checks(spec: Dictionary) -> void:
    var lesson=load(spec.lesson).new()
    lesson.position=Vector3(13,0,14);lesson.rotation.y=PI
    hall.add_child(lesson);await settle()
    clear_approach(null,lesson.to_global(Vector3(0,0,1.25)),"student approach")
    check("exact printed contact study constructs in museum",lesson.bars.size()==2 and lesson.players.size()==2 and lesson.point.enabled)
    lesson.point.position=lesson.bars[0].position;await settle()
    await create_timer(0.2).timeout
    lesson.point.position=lesson.bars[1].position;await settle()
    check("physical point contacts produce two independent museum voices",lesson.players[0].playing and lesson.players[1].playing and lesson.ages_now()[0]>lesson.ages_now()[1])
    lesson.point.position=Vector3(-1.2,1.05,0.6);await settle()
    var eye: Vector3=lesson.to_global(Vector3(1.5,2.1,3.4))
    var target: Vector3=lesson.to_global(Vector3(0,1.4,0))
    check("student sightline clear",hall.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,target,1)).is_empty())
    await snapshot("student",eye,target,51)
    observations.student_bay=[13,0,14];observations.student_yaw=180
    lesson.queue_free();await tick()
