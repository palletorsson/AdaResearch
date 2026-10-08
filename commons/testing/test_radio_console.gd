extends SceneTree
const OUT := "res://doc/reports/interfaces-2026-09-21/radio-console/"
var variant := "after"
var checks: Array = []
var failures: Array = []
var world: Node3D
var camera: Camera3D
var radio: Node3D

class QuietPlayer extends Node3D:
	var volume_adjustment := 0.0
	var loaded: Array[String] = []
	var starts := 0
	var stops := 0
	var is_generating := false
	var unavailable_sounds:PackedStringArray=[]
	func load_config_from_file(path: String) -> bool:
		loaded.append(path)
		return FileAccess.file_exists(path)
	func start() -> void: starts += 1
	func stop() -> void: stops += 1

class QuietRadio extends "res://commons/audio/rack_configs/SoundscapeRadioRack.gd":
	func _setup_soundscape_player():
		soundscape_player = QuietPlayer.new()
		add_child(soundscape_player)

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks.append({"passed": ok, "message": message})
	if not ok: failures.append(message)
	print("RADIO ", "PASS " if ok else "FAIL ", message)
func settle() -> void:
	for i in 6:
		await process_frame
		await physics_frame
func run() -> void:
	if not OS.get_cmdline_user_args().is_empty(): variant = OS.get_cmdline_user_args()[0]
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.09,.11,.14)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.9,.93,1)
	env.environment.ambient_light_energy = .8
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40,-25,0)
	world.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(12,12)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(.23,.26,.29)
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.current = true
	root.msaa_3d = Viewport.MSAA_4X
	radio = load("res://commons/audio/rack_configs/SoundscapeRadioRack.tscn").instantiate()
	radio.set_script(QuietRadio)
	radio.position = Vector3(0,1.20,0)
	radio.rotation_degrees.x = -15
	world.add_child(radio)
	await settle()
	check(radio.find_children("*","Label3D",true,false).is_empty(),"Radio text is flat on surfaces")
	check(radio.get_node("TuningWheel").scale.is_equal_approx(Vector3.ONE),"Tuning control keeps its authored physical size")
	check(radio.get_node("VolumeWheel").scale.is_equal_approx(Vector3.ONE),"Volume control keeps its authored physical size")
	check(is_equal_approx(radio.current_angle, radio.station_width*.5),"Initial between-stations sound agrees with wheel position")
	check(is_equal_approx(radio.soundscape_player.volume_adjustment,radio.target_volume_db),"Initial noise uses the selected volume")
	await capture("console",Vector3(.28,1.53,1.02),Vector3(0,1.24,0),52)
	radio.set_station(2)
	check(is_equal_approx(radio.tuning_wheel.hinge_position,radio.current_angle),"Station shortcut synchronizes the physical wheel")
	for face in ["scale","presets","list","void"]:
		radio.apply_grid_config({"face":face})
		await capture(face,Vector3(.12,1.50,1.10),Vector3(0,1.24,0),50)
	if variant == "after": await verify_after()
	FileAccess.open(OUT+variant+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"baseline":variant=="before","headset_tested":false,"silent_radio_test_double":true},"\t"))
	quit(0 if variant=="before" or failures.is_empty() else 1)

func verify_after() -> void:
	check(radio._panel.screen.position.z > radio.get_node("ScreenBezel").position.z + radio.get_node("ScreenBezel").mesh.size.z*.5,"Printed display sits in front of its bezel")
	var tuning:Node3D = radio.get_node("TuningWheel")
	var volume:Node3D = radio.get_node("VolumeWheel")
	var quiet:Node3D = radio.soundscape_player
	var pointer:=Node3D.new()
	world.add_child(pointer)
	radio.apply_grid_config({"face":"scale"})
	radio._flush_audio_request()
	check(quiet.loaded.back().ends_with("underwater_research_lab.json"),"Station 3 requests its actual preset file")
	check(is_equal_approx(volume.hinge.hinge_position,94.5),"Starting -6 dB agrees with physical volume angle")
	check(volume._reading.label.text=="-6 dB","Level wheel reports decibels instead of a misleading percent")
	var starts:int=quiet.starts
	for face in ["scale","presets","list","void"]:
		radio.apply_grid_config({"face":face})
		check(radio.current_station==2 and quiet.starts==starts,"Face "+face+" preserves the selected sound")
		check(tuning._reading.screen.visible==(face=="scale"),"Face "+face+" reveals tuning coordinates only on the band")
		check(volume._reading.screen.visible==(face!="void"),"Face "+face+" respects the volume-readout rule")
		check(radio.find_children("*","Label3D",true,false).is_empty(),"Face "+face+" keeps every label on a flat surface")
		var face_id:int=radio._face_root.get_instance_id()
		radio.apply_grid_config({"face":face})
		radio.apply_grid_config({"unrelated":"value"})
		radio.apply_grid_config({"face":"invalid"})
		check(radio._face_root.get_instance_id()==face_id,"Face "+face+" ignores identical, unrelated and invalid configuration")
	radio.apply_grid_config({"face":"void"})
	check(radio._face_root.get_child_count()==0 and not tuning._reading.screen.visible and not volume._reading.screen.visible,"Void supplies no station, level, needle or preparation reading")
	radio.apply_grid_config({"face":"presets"})
	check(radio._preset_lamps.size()==9,"Preset face has one lamp for each real station")
	check(radio._preset_lamps[2].color.g>.9 and radio._preset_lamps[1].color.g<.3,"Only the selected station lamp is lit")
	tuning.set_angle_degrees(20)
	check(radio.current_station==-1 and radio._station_reading.text=="","Between-stations state has no numeric substitute on the discrete face")
	check(radio._preset_lamps.all(func(lamp):return lamp.color.g<.3),"All preset lamps turn off between stations")
	radio._flush_audio_request()
	check(quiet.loaded.back().ends_with("minimal_drone.json"),"The gap requests the existing noise/drone preset")
	radio.apply_grid_config({"face":"list"})
	radio.set_station(8)
	check(radio._list_labels.size()==9 and radio._list_labels[8].get_theme_color("font_color").g==1,"List face highlights the last station")
	radio.next_station()
	check(radio.current_station==0 and is_zero_approx(tuning.get_angle_degrees()),"Next station wraps and moves the wheel to the first station")
	radio.previous_station()
	check(radio.current_station==8 and is_equal_approx(tuning.get_angle_degrees(),320),"Previous station wraps and moves the wheel to the last station")
	radio.apply_grid_config({"face":"scale"})
	tuning.set_angle_degrees(360)
	check(radio.current_station==-1 and is_equal_approx(radio._needle.position.x,1040),"Band endpoint and physical end-stop agree")
	tuning.set_angle_degrees(0)
	check(radio.current_station==0 and is_equal_approx(radio._needle.position.x,60),"Band beginning and first station agree")
	for yaw in [0,90]:
		radio.rotation_degrees.y=yaw
		radio.set_station(0)
		var handle:Node3D=tuning.hinge.get_node("Handles/Handle1/InteractableHandle")
		var hand:=grab(handle)
		move_hand(hand,tuning,80)
		await settle()
		check(radio.current_station==2 and is_equal_approx(radio.current_angle,80),"XR grab selects station 3 at yaw "+str(yaw))
		check(tuning._reading.label.text=="+80°","Wheel reading follows radio tuning at yaw "+str(yaw))
		hand.drop_object()
		hand.queue_free()
		await settle()
		check(radio.current_station==2,"Released tuning wheel retains its station at yaw "+str(yaw))
		volume.set_angle_degrees(0)
		hand=grab(volume.hinge.get_node("Handles/Handle1/InteractableHandle"))
		move_hand(hand,volume,-67.5)
		await settle()
		check(is_equal_approx(radio.target_volume_db,-30) and is_equal_approx(quiet.volume_adjustment,-30),"Physical level wheel changes playback gain at yaw "+str(yaw))
		hand.drop_object()
		hand.queue_free()
		await settle()
		var query:=PhysicsRayQueryParameters3D.create(volume.to_global(Vector3(.075,.02,.3)),volume.to_global(Vector3(.075,.02,-.04)),(1<<20)|(1<<22))
		var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(),"Mounted level wheel receives a real pointer ray at yaw "+str(yaw))
		if not hit.is_empty():
			XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
			var local:Vector3=volume.to_local(hit.position)
			var end:Vector3=volume.to_global(Vector3(-local.y,local.x,local.z))
			XRToolsPointerEvent.moved(pointer,hit.collider,end,hit.position)
			XRToolsPointerEvent.released(pointer,hit.collider,end)
			check(absf(radio.target_volume_db-(-16.666667))<.001,"Mounted pointer produces the expected live gain at yaw "+str(yaw))
	radio.rotation_degrees.y=0
	volume.set_angle_degrees(-135)
	check(is_equal_approx(radio.target_volume_db,-40),"Negative volume end-stop is quiet attenuation, not a dead half-turn")
	volume.set_angle_degrees(135)
	check(is_equal_approx(radio.target_volume_db,0),"Positive volume end-stop is zero additional attenuation")
	volume.set_angle_degrees(-67.5)
	tuning.set_angle_degrees(20)
	radio._flush_audio_request()
	check(is_equal_approx(quiet.volume_adjustment,-30),"Noise transition preserves the selected level")
	# During background generation we keep the latest desired station and never stop/join it from input.
	starts=quiet.starts
	var stops:int=quiet.stops
	quiet.is_generating=true
	radio.set_station(1)
	radio._flush_audio_request()
	radio.set_station(5)
	radio._flush_audio_request()
	check(quiet.starts==starts and quiet.stops==stops,"Tuning during generation does not block by stopping or restarting the worker")
	quiet.is_generating=false
	radio._flush_audio_request()
	check(quiet.loaded.back().ends_with("blade_runner_minimal.json") and quiet.starts==starts+1,"Only the latest queued station is started when generation finishes")
	check(is_equal_approx(quiet.volume_adjustment,-30),"Queued station also inherits the selected level")
	var old_sources:Array=radio.station_presets.duplicate()
	radio.station_presets.clear()
	radio.next_station()
	radio.previous_station()
	radio.set_station(0)
	tuning.set_angle_degrees(20)
	check(radio.current_station==-1,"Empty station catalogue remains a noise state without modulo errors")
	radio.station_presets.assign(old_sources)
	radio.set_station(2)
	radio._flush_audio_request()
	await capture("operating",Vector3(0,1.60,1.06),Vector3(0,1.24,0),57)
	quiet.unavailable_sounds.append("unresolved.test")
	radio._update_display()
	check(radio._status.text=="SOME SOUNDS UNAVAILABLE","Incomplete sound generation is visible on informative faces")
	radio.apply_grid_config({"face":"void"})
	check(radio._face_root.get_child_count()==0,"Void retains its listening-only restriction even for playback diagnostics")
	quiet.unavailable_sounds.clear()
	radio.apply_grid_config({"face":"scale"})
	await test_playback()
	# Load the production InteractableDemo entry, but cancel its costly preset startup in this fixture.
	var demo:Node3D=load("res://commons/interactables/interactable_radio_demo.tscn").instantiate()
	world.add_child(demo)
	var ref:Node3D=demo.get_node("RadioReference")
	ref.radio._audio_timer.stop()
	check(ref.radio.get_script().resource_path.ends_with("SoundscapeRadioRack.gd"),"Focused InteractableDemo mounts the production radio")
	check(ref.radio.get_node("TuningWheel").global_basis.get_scale().is_equal_approx(Vector3.ONE),"Reference keeps the physical wheel at metre scale")
	check(ref.get_node("RadioPlinth").rotation.is_equal_approx(Vector3.ZERO),"Reference plinth stays upright under the inclined radio")
	radio.hide()
	await capture("reference",Vector3(.70,1.55,1.75),Vector3(0,1.03,0),48)
	demo.queue_free()
	await settle()

class TestGrabber extends Node3D:
	var picked_up_ranged:=false
	var held:Node3D
	func drop_object()->void:
		held.let_go(self,Vector3.ZERO,Vector3.ZERO)
		held=null
func grab(handle:Node3D)->TestGrabber:
	var hand:=TestGrabber.new()
	world.add_child(hand)
	hand.global_transform=handle.global_transform
	hand.held=handle
	handle.pick_up(hand)
	return hand
func move_hand(hand:TestGrabber,control:Node3D,degrees:float)->void:
	var rest:Vector3=control.hinge.to_local(hand.held.handle_origin.global_position)
	hand.global_position=control.hinge.get_parent().to_global(Basis(Vector3.RIGHT,deg_to_rad(degrees))*rest)

class CountingBank extends Node:
	var requested:Array[String]=[]
	func _generate_sound(sound_id:String)->AudioStream:
		requested.append(sound_id)
		var stream:=AudioStreamWAV.new()
		stream.format=AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate=22050
		stream.stereo=true
		var data:=PackedByteArray()
		data.resize(8820)
		stream.data=data
		return stream

func test_playback()->void:
	var backend:Node3D=load("res://commons/audio/systems/SciFiLoFiSoundscape.gd").new()
	world.add_child(backend)
	var bank:=CountingBank.new()
	world.add_child(bank)
	backend._sound_bank=bank
	backend.volume_adjustment=-6
	backend.load_config({"continuous_layers":[{"sound_id":"test.drone","volume_db":-12}],"random_events":[{"sound_pool":["test.click"],"interval_range":[100,100],"volume_range":[-18,-18]}]})
	backend.start()
	var deadline:=Time.get_ticks_msec()+5000
	while backend.is_generating and Time.get_ticks_msec()<deadline:await process_frame
	check(backend.is_playing and not backend.is_generating,"Actual threaded soundscape player reaches playback")
	check(bank.requested==["test.drone","test.click"],"Worker resolves actual sound IDs and pre-generates event pools")
	check(backend.continuous_players.size()==1,"Event pool streams are not installed as continuous layers")
	if not backend.continuous_players.is_empty():
		var audio:AudioStreamPlayer3D=backend.continuous_players[0]
		check(is_equal_approx(audio.volume_db,-18),"New continuous layer includes the selected overall attenuation")
		backend.volume_adjustment=-20
		check(is_equal_approx(audio.volume_db,-32),"Changing gain updates a layer already playing")
		backend.volume_adjustment=-20
		check(is_equal_approx(audio.volume_db,-32),"Repeating the same gain does not accumulate attenuation")
		backend._on_event_timeout({"sound_pool":["test.click"],"interval_range":[100,100],"volume_range":[-18,-18],"bus":"Master"})
		check(bank.requested.size()==2,"Playing a cached event does not synthesize sound on the render thread")
		var effect:AudioStreamPlayer3D=backend.effect_players[0]
		check(is_equal_approx(effect.volume_db,-38),"New event uses the current gain")
		backend.volume_adjustment=-10
		check(is_equal_approx(audio.volume_db,-22) and is_equal_approx(effect.volume_db,-28),"Live gain changes preserve both continuous and event base levels")
	var mono:=AudioStreamWAV.new()
	mono.format=AudioStreamWAV.FORMAT_16_BITS
	mono.mix_rate=22050
	mono.stereo=false
	var mono_data:=PackedByteArray()
	mono_data.resize(4410)
	mono.data=mono_data
	backend.precreated_streams={"mono":{"stream":mono,"config":{"volume_db":-12}}}
	backend._create_players_from_precreated()
	check(mono.loop_end==2205,"Bank-provided mono streams loop their full length in frames")
	backend.stop()
	# Both formats are exercised against real generators, with short output.
	backend._sound_bank = root.get_node("SoundBank")
	var bank_stream:AudioStreamWAV=backend._generate_layer_stream({"sound_id":"trap_beats.hihat_closed"})
	check(bank_stream != null and bank_stream.data.size()>0,"Production sound-bank ID produces real PCM samples")
	var old_stream:AudioStreamWAV=backend._generate_layer_stream({"generator":"TechnoNoirGenerator","method":"create_static_burst","params":{"duration":.03}})
	check(old_stream != null and old_stream.data.size()>0,"Legacy generator-style configuration still produces PCM samples")
	var short_drone:AudioStreamWAV=backend._generate_layer_stream({"sound_id":"techno_noir.drone","parameters":{"buffer_length":.02,"base_freq":110}})
	check(short_drone != null and short_drone.data.size()==int(short_drone.mix_rate*.02)*4,"Bank-based drone honors the preset parameter dictionary")
	backend.queue_free()
	bank.queue_free()
	await settle()


func capture(tag:String,at:Vector3,target:Vector3,fov:float)->void:
	camera.position = at
	camera.fov = fov
	camera.look_at(target)
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+variant+"/"+tag+".png")
