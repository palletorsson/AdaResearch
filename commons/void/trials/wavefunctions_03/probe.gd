extends "res://commons/void/trials/formfinding_02/probe.gd"

func expected_empty_source(node: Node3D) -> bool:
	return node.get_meta("artifact_lookup_name","")=="BigPipeSystem"

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level),game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	match level:
		1:await sound_checks(tag)
		2:await bernini_checks(tag)
		3:await cage_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

func sound_checks(tag: String) -> void:
	var fm:Node3D=artifact("DualBallFMController")
	await stand_local(fm,Vector3(.75,.06,1.65))
	await press(fm._panel.find_child("Btn_0",true,false))
	check(tag+"BASELINE sets unmodulated 440 Hz through pointer",is_equal_approx(fm.carrier_freq,440) and is_zero_approx(fm.mod_index) and fm.last_note_tag=="baseline")
	await press(fm._panel.find_child("Btn_1",true,false))
	check(tag+"HOLD stores playable original sound",fm.has_reference() and fm._ref_stream.data.size()>0)
	var saved:PackedByteArray=fm._ref_stream.data.duplicate()
	var reference:Dictionary=fm.get_reference()
	fm.modulator_mapper.set_values(2.0,2.0,.5)
	fm.modulator_mapper.values_changed.emit(2.0,2.0,.5)
	check(tag+"mapper API changes B while reference A is retained",fm.mod_index==2 and fm.get_reference()==reference and fm._ref_stream.data==saved)
	await press(fm._panel.find_child("Btn_3",true,false))
	check(tag+"COMPARE pointer starts retained A",fm.last_note_tag=="A" and fm.audio_player.stream.data==saved)
	await frames(int(ceil((fm._ref_seconds+.4)*60)))
	check(tag+"COMPARE clock advances to changed B",fm.last_note_tag=="B" and fm.audio_player.stream.data!=saved)
	fm.play_on_move=false
	await grab_point(tag,fm.carrier_ball)
	await drop_point()
	var timbre:Node3D=artifact("timbre_sculptor")
	await stand_local(timbre,Vector3(0,.06-1.3,1.45))
	await press(timbre.buttons.SAW);await frames(40)
	check(tag+"SAW pointer changes eight harmonic targets",timbre.target_amplitudes.size()==8 and is_equal_approx(timbre.target_amplitudes[1],.5))
	check(tag+"FM source desks and longhand evidence kept",fm.stand=="desks" and fm.evidence=="longhand")
	var pipe:Node3D=artifact("BigPipeSystem")
	check(tag+"unbuilt source pipe stays honestly empty",not pipe.auto_build and pipe._curves.is_empty())
	for entry in game.building.content.data.floors[level].artifacts:
		if entry.artifact == "GlassRack":
			var rack: Node3D = station(entry.id)
			check(tag+entry.id+" loads its selected glass apparatus",rack.config_file==entry.config.config and rack.find_children("*","MeshInstance3D",true,false).size()>0 and rack.find_child("Frame",true,false)==null)

func bernini_checks(tag: String) -> void:
	var rig:Node3D=artifact("bernini_columns").get_node("BerniniColumns")
	check(tag+"nine full-size original columns",rig.columns.size()==9 and rig.colonnade=="grid" and is_equal_approx(rig.column_height,8))
	var rotating:Node3D=rig.columns[0].get_node("RotatingRoot")
	var surface:MeshInstance3D=rotating.get_child(0)
	var vertices:PackedVector3Array=surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].duplicate()
	var before:Transform3D=rotating.transform
	await frames(30)
	check(tag+"column rotation advances without rewriting mesh",not rotating.transform.is_equal_approx(before) and surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==vertices)
	rig.rotate_columns=false;before=rotating.transform;await frames(15)
	check(tag+"rotation property API pauses intact geometry",rotating.transform.is_equal_approx(before))
	rig.rotate_columns=true
	var voice:Node3D=artifact("vowel_sound_board")
	check(tag+"original phrase overrides ambient voice",voice.get_meta("config_say")=="right here, right now" and voice.get_meta("config_repeat")=="true" and not voice.is_ambient_enabled)
	check(tag+"dress retains source mounting height",is_equal_approx(artifact("ElphabaDress").get_parent().position.y,.914))

func cage_checks(tag: String) -> void:
	var cage:Node3D=artifact("john_cage_tech_noir")
	var start_ms:int=Time.get_ticks_msec()
	while not cage.generation_complete and Time.get_ticks_msec()-start_ms<90000:
		await create_timer(.25).timeout
	await frames(90)
	check(tag+"Cage real background audio generation completes",cage.generation_complete)
	var eligible:Array=[]
	for key in cage.sound_types:
		for clip in cage.precreated_sounds.get(key,[]):eligible.append(clip)
	check(tag+"21 prepared effects contain actual samples",eligible.size()==21 and eligible.all(func(c):return c is AudioStreamWAV and c.data.size()>0))
	check(tag+"two continuous layers and seven visual voices retained",cage.drone_player.playing and cage.ambient_player.playing and cage.visualizer_infos.size()==7)
	cage.set_process(false)
	for player in cage.effect_players:player.stop()
	cage.play_random_effect()
	var sounding:int=0
	for player in cage.effect_players:
		if player.playing and player.stream in eligible:sounding+=1
	check(tag+"scheduler API chooses one generated sound",sounding==1)
	cage.set_process(true)
	var display:Node3D=artifact("dual_display_test")
	check(tag+"two live museum panels mounted in native world",display._museum_panels_installed and display.has_node("SpectralSineWave/MuseumWaveform") and display.has_node("SpectrumDisplay/MuseumSpectrum"))
	var sculpture:Node3D=artifact("ruth_asawa_sculpture")
	check(tag+"full ten-metre wire sculpture retained",is_equal_approx(sculpture.height,10) and sculpture.mesh!=null and sculpture.audio_reactive)
	# Generation's large temporary loading bar is not the final artifact bounds.
	if not xr:
		measured=measured.filter(func(entry):return entry.floor!=level)
		var ids:Array=game.building.content.data.floors[level].artifacts.map(func(a):return a.id)
		fit_notes=fit_notes.filter(func(entry):return entry.id not in ids)
	inspect_floor(tag+"ready: ")

func capture_floor() -> void:
	var y:float=game.building.spec.levels[level]
	match level:
		1:
			await photo("01-sound-instruments",Vector3(5,y+2.8,11),Vector3(0,y+1.2,3))
			await photo("02-fm-comparison",Vector3(.8,y+1.8,5.5),Vector3(.3,y+1,3))
			await photo("03-harmonics",Vector3(12,y+2.5,-3),Vector3(12,y+1,-8))
		2:
			await photo("04-bernini-columns",Vector3(1.7,y+1.7,1),Vector3(0,y+3,-6))
			await photo("05-dress-and-voice",Vector3(8,y+2.3,12),Vector3(13,y+1,7))
		3:
			await photo("06-cage-listening",Vector3(2,y+2.4,6),Vector3(4,y+1.3,-1))
			await photo("07-asawa-and-displays",Vector3(-8,y+2.6,12),Vector3(-16,y+2,2))
