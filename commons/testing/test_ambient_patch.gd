extends SceneTree
var checks: Array = []
var failures: Array = []
var out := "res://doc/reports/ambient-patch-2026-09-22/"
var instrument: Node3D
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"passed":ok,"label":label})
	if not ok: failures.append(label)
func run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.026,.041,.051)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.72,.82,.9)
	env.environment.ambient_light_energy = .7
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35,-25,0)
	sun.light_energy = 1.4
	stage.add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(.10,1.57,1.55)
	camera.fov = 64
	stage.add_child(camera)
	camera.look_at(Vector3(0,1.34,0))
	camera.make_current()
	var buses_before := AudioServer.bus_count
	instrument = load("res://commons/artifacts/ambient_patch/ambient_patch.tscn").instantiate()
	stage.add_child(instrument)
	await process_frame
	var engine: Node3D = instrument.audio
	check(not engine.playing and engine.bus_name.is_empty(),"Silent arrival does not allocate a DSP bus")
	check(engine.voices.size() == 8,"Voice pool is bounded at eight")
	# Exercise native retained handles, not just the instrument's parameter setter.
	for key in instrument.sliders:
		var slider: Node3D = instrument.sliders[key]
		slider._track.move_slider(.153)
		check(absf(float(engine.parameters[key])-.85)<.015,key+" native slider updates audio state")
		slider._track.move_slider(-.09)
		check(float(engine.parameters[key])<.001,key+" reaches its minimum")
	var defaults := {"density":.68,"rate":.38,"warmth":.65,"space":.72,"drift":.55,"level":.64}
	for key in defaults:
		instrument.sliders[key].set_normalized_value(defaults[key])
		engine.set_parameter(key,defaults[key])
	instrument.buttons.transport.pressed.emit()
	check(engine.preparing,"PLAY starts asynchronous sample preparation")
	var started := Time.get_ticks_msec()
	while engine.preparing and Time.get_ticks_msec()-started < 30000: await process_frame
	check(engine.sample_cache.size()==2,"Two legacy synthesizer samples prepared")
	if engine.sample_cache.size()!=2: finish(); return
	check(engine.playing,"Requested playback starts after preparation")
	for id in engine.sample_cache:
		var stream: AudioStreamWAV = engine.sample_cache[id]
		check(stream.data.decode_s16(0)==0 and stream.data.decode_s16(stream.data.size()-2)==0,id+" PCM starts and ends at zero")
	check(AudioServer.bus_count==buses_before+1,"One isolated effects bus is allocated")
	engine.set_process(false)
	var traces: Array = []
	for attempt in 2:
		engine.stop(true)
		engine.start()
		engine.set_process(false)
		for tick in 600:
			engine.elapsed = tick*.2
			engine.advance_score(.2)
			for voice in engine.voices: voice.stop()
		traces.append(engine.events.duplicate(true))
	check(traces[0]==traces[1] and traces[0].size()>10,"Same seed reproduces the event score")
	var in_scale := true
	for event in traces[0]: in_scale = in_scale and (event.midi%12 in [0,2,4,7,9])
	check(in_scale,"Every generated pitch belongs to the displayed scale")
	instrument.buttons.seed.pressed.emit()
	engine.start()
	engine.set_process(false)
	for tick in 600:
		engine.elapsed = tick*.2
		engine.advance_score(.2)
		for voice in engine.voices: voice.stop()
	check(engine.events!=traces[0],"NEW SEED changes the generated event score")
	engine.set_parameter("density",0)
	engine.start()
	engine.set_process(false)
	for tick in 100: engine.advance_score(1)
	check(engine.notes_played==0,"Zero density leaves silence")
	engine.set_parameter("density",1)
	engine.start()
	engine.set_process(false)
	engine.advance_score(60)
	check(engine.notes_played<=3,"A long frame does not cause a catch-up burst")
	for voice in engine.voices: voice.stop()
	for i in 10: engine._play_note(0,60)
	check(engine.voices.filter(func(v): return v.playing).size()==8 and engine.skipped_voices>=2,"Saturation skips excess notes without stealing held voices")
	engine.stop(true)
	engine.patch_seed = 220926
	for key in defaults: engine.set_parameter(key,defaults[key])
	engine.start()
	var record := AudioEffectRecord.new()
	record.format = AudioStreamWAV.FORMAT_16_BITS
	var master_slot := AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0,record)
	record.set_recording_active(true)
	await create_timer(4).timeout
	check(instrument.scope_peak>0,"Displayed scope reads actual nonzero output PCM")
	await shot("console-playing.png")
	await create_timer(10).timeout
	instrument.buttons.route.pressed.emit()
	check(engine.route=="pan","LFO ROUTE changes the real modulation destination")
	await create_timer(1).timeout
	check(absf(engine.pan.pan)>.01,"Pan destination receives the slow modulation")
	await shot("console-pan.png")
	await create_timer(12).timeout
	instrument.buttons.transport.pressed.emit()
	await create_timer(2).timeout
	check(not engine.playing and engine.voices.all(func(v): return not v.playing),"STOP fades out and releases every voice")
	record.set_recording_active(false)
	var wav := record.get_recording()
	check(wav!=null and wav.data.size()>100000,"Engine mixdown contains recorded PCM")
	if wav: wav.save_to_wav(out+"ambient-preview.wav")
	AudioServer.remove_bus_effect(0,master_slot)
	engine.start()
	instrument.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame
	check(not engine.playing and engine.voices.all(func(v): return not v.playing),"Museum process culling stops playback")
	instrument.process_mode = Node.PROCESS_MODE_INHERIT
	instrument.queue_free()
	await process_frame
	check(AudioServer.bus_count==buses_before,"Teardown removes only the instrument's own bus")
	finish()

func shot(file: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+file)

func finish() -> void:
	var file := FileAccess.open(out+"tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("AMBIENT_PATCH ",checks.size()," checks; failures: ",failures)
	quit(0 if failures.is_empty() else 1)
