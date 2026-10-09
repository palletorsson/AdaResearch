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

func landing_checks() -> void:
    museum.call("flush_stamps")
    await tick()
    var rig:=find_scene("/john_cage_tech_noir.gd")
    check("installed soundscape present",rig!=null)
    if rig==null:return
    var start:=Time.get_ticks_msec()
    while not rig.generation_complete and Time.get_ticks_msec()-start<70000:
        await create_timer(0.5).timeout
    await create_timer(1.5).timeout
    check("actual sound generation completes",rig.generation_complete)
    check("two continuous layers are playing",rig.drone_player.playing and rig.ambient_player.playing)
    check("soundscape keeps seven visual voices",rig.visualizer_infos.size()==7)
    check("completed loading display is removed",rig.loading_bar_container==null)
    var ready:=0
    var buffers_valid:=true
    var eligible: Array=[]
    for key in rig.sound_types:
        var clips: Array=rig.precreated_sounds.get(key,[])
        ready+=clips.size()
        for clip in clips:
            buffers_valid=buffers_valid and clip is AudioStreamWAV and clip.data.size()>0
            eligible.append(clip)
    check("seven effect types have three ready variations each",ready==21 and buffers_valid)
    rig.set_process(false)
    for player in rig.effect_players:player.stop()
    rig.play_random_effect()
    var sounding:=0
    var valid_selection:=true
    for player in rig.effect_players:
        if player.playing:
            sounding+=1
            valid_selection=valid_selection and player.stream in eligible
    check("live scheduler plays one eligible prepared effect",sounding==1 and valid_selection)
    rig.set_process(true)
    await super.landing_checks()
    var origin:=hall.global_position+Vector3(0,0,4)
    for i in range(59):clear_approach(null,origin+Vector3(11.5,0,2+0.4*i),"route %d"%i)
    clear_approach(null,origin+Vector3(5.5,0,15.5),"wire sculpture approach")
    clear_approach(null,origin+Vector3(16.5,0,14.5),"soundscape approach")
    var expected: Dictionary={"dual_display_test":1,"ruth_asawa_sculpture":1,"dark_sphere":1,"john_cage_tech_noir":1}
    var present: Dictionary={}
    for record in museum.get("_edit_records"):
        if record.get("seg")!=hall or not is_instance_valid(record.get("node")):continue
        var token: String=str(record.get("token"))
        if not expected.has(token):continue
        present[token]=int(present.get(token,0))+1
        var bounds: AABB=museum.call("_seat_extent",record.node)
        if token=="ruth_asawa_sculpture":check("complete wire sculpture above the floor",bounds.position.y-origin.y>=0.05 and bounds.size.y>9.9)
        if token=="dual_display_test":check("display no longer intersects floor",bounds.position.y-origin.y>=0.35)
    check("all four authored exhibits retained",present==expected)
    var display:=find_scene("/dual_display_test.gd")
    check("legacy 3D display mounted in this hall",display.get("_museum_panels_installed") and display.has_node("SpectralSineWave/MuseumWaveform"))
    var wave: Node=display.get_node("SpectralSineWave/WaveformViewport/WaveformDisplay")
    check("waveform keeps its live render references",is_instance_valid(wave.get("_info_label")) and is_instance_valid(wave.get("_mesh_instance")))
    var panel_mesh: MeshInstance3D=display.get_node("SpectrumDisplay/AudioDisplay/GameSoundMeter").get("_mesh_instance")
    check("spectrum geometry inherits the museum panel transform",panel_mesh.get_parent()==display.get_node("SpectrumDisplay/MuseumSpectrum") and panel_mesh.global_position.y>origin.y+1)
    observations.preserved_artifacts=present
    await snapshot("listening",origin+Vector3(13.1,2.2,13.2),origin+Vector3(16.5,1.3,18.5),65)
    await snapshot("gallery",origin+Vector3(-1,22,-1),origin+Vector3(11,2,16),69)
    await snapshot("entry-after",origin+Vector3(11.5,1.65,2),origin+Vector3(11.5,3,19),72)
    await snapshot("displays",display.to_global(Vector3(0,1.4,6.2)),display.to_global(Vector3(0,1.1,0)),61)
    var sculpture:=find_scene("/ruth_asawa_sculpture.gd")
    sculpture.set_process(false)
    sculpture.smoothed_volume=1.0
    sculpture.smoothed_bands.fill(1.0)
    sculpture._apply_audio_to_mesh()
    var loud_bounds: AABB=museum.call("_seat_extent",sculpture)
    check("hanging sculpture remains above floor at maximum normalized audio",loud_bounds.position.y>origin.y+0.1)
    rig.shutdown_audio()
    check("completed generation thread joined on shutdown",rig.generation_thread==null and rig.stop_requested and not rig.drone_player.playing)
    observations.scope="Real museum, completed generated sounds and unchanged live sound scheduling. Native route/clearance and synthetic point-trigger checks. No physical headset or independent student claim."

func study_checks(spec: Dictionary) -> void:
    var lesson=load(spec.lesson).new()
    lesson.position=Vector3(16,0,10);lesson.rotation.y=PI
    hall.add_child(lesson);await tick();lesson.set_process(false)
    clear_approach(lesson,lesson.to_global(Vector3(0,0,1.65)),"student approach")
    check("exact printed score builds inside museum",lesson.score.size()==6 and lesson.notes.size()==3 and lesson.point.enabled)
    lesson.rng.seed=384;lesson.new_score();lesson.draw_state()
    var kept: Array=lesson.score.duplicate(true)
    lesson.point.action_pressed.emit(lesson.point)
    check("real trigger starts saved score in museum",lesson.playing and lesson.score==kept)
    lesson._process(float(kept[2].at)+0.001)
    check("museum clock dispatches first three saved choices",lesson.cursor==3 and lesson.players[2].stream==lesson.notes[int(kept[2].voice)])
    var eye: Vector3=lesson.to_global(Vector3(1.7,2.1,4.6))
    var target: Vector3=lesson.to_global(Vector3(0,1.5,0))
    var ray:=PhysicsRayQueryParameters3D.create(eye,target,1)
    check("score sightline clear",hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
    await snapshot("student",eye,target,53)
    lesson.point.action_pressed.emit(lesson.point)
    check("second left trigger keeps score and resets clock",lesson.cursor==0 and lesson.elapsed==0 and lesson.score==kept)
    lesson.point.position.x=0.65;lesson.point.action_pressed.emit(lesson.point)
    check("right trigger draws another known-seed score",lesson.score!=kept and lesson.playing)
    observations.student_bay=[16,0,10]
    observations.student_bay_yaw=180
    lesson.queue_free();await tick()
