extends SceneTree
var out := "res://doc/reports/room-memory-2026-09-22/"
var checks: Array = []
var failures: Array = []
var room: Node3D
var camera: Camera3D
var worker_times: Array = []
class RoomMemoryGrabber extends Node3D:
	var picked_up_ranged := false
class MemoryStagingProbe extends Node3D:
	signal scene_loaded
	var requested := ""
	func load_scene(path: String) -> void: requested = path

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"passed":ok,"label":label})
	if not ok: failures.append(label)
	print("ROOM_MEMORY ","PASS " if ok else "FAIL ",label)

func idle(engine: Node) -> void:
	var start := Time.get_ticks_msec()
	while engine.busy and Time.get_ticks_msec()-start<20000: await process_frame
	check(not engine.busy,"Worker completes without blocking scene frames")

func run() -> void:
	var baseline_buses := AudioServer.bus_count
	room = load("res://commons/artifacts/ambient_patch/room_memory.tscn").instantiate()
	root.add_child(room)
	camera = Camera3D.new()
	camera.environment = room.environment
	camera.position = Vector3(0,1.65,2.04)
	camera.fov = 78
	root.add_child(camera)
	camera.look_at(Vector3(0,1.5,-1.96))
	camera.make_current()
	await physics_frame
	var e: Node3D = room.audio
	check(not e.recording and e.mic==null and not e.player.playing,"Arrival is silent; microphone is never started automatically")
	check(room.buttons.size()==9 and room.sliders.size()==2,"Nine physical buttons, two physical sliders")
	check(room.walls.size()==9,"All six absorber panels and three walls follow the surface setting")
	var state := room.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = CapsuleShape3D.new()
	query.shape.radius = .22
	query.shape.height = 1.7
	query.collision_mask = 1
	query.transform.origin = Vector3(0,.87,0)
	check(state.intersect_shape(query).is_empty(),"Clear standing space in the room centre")
	query.transform.origin = Vector3(0,.87,2.3)
	query.motion = Vector3(0,0,-2.3)
	check(state.intersect_shape(query).is_empty() and state.cast_motion(query)[0]>.99,"Doorway has a clear walking route into the room")
	for key in room.stations:
		var station: Node3D = room.stations[key]
		var feet := station.position+station.basis.z*.55
		query.motion = Vector3.ZERO
		query.transform.origin = feet+Vector3.UP*.87
		check(state.intersect_shape(query).is_empty(),key+" has a clear operating position")
		query.transform.origin = Vector3(0,.87,0)
		query.motion = feet
		check(state.cast_motion(query)[0]>.99,key+" is reachable from the centre")
	for key in room.buttons:
		var button: Node3D = room.buttons[key]
		inspect(button,button.get_node("InteractableAreaButton/CollisionShape3D").global_position,key)
	for key in room.sliders:
		var slider: Node3D = room.sliders[key]
		for value in [0.0,1.0]:
			slider.set_normalized_value(value)
			await physics_frame
			inspect(slider,slider._handle.global_position,key+str(value))
		var grabber := RoomMemoryGrabber.new()
		root.add_child(grabber)
		grabber.global_transform = slider._handle.global_transform
		slider._handle.pick_up(grabber)
		grabber.global_position = slider._track.get_parent().to_global(Vector3(.18*.4,0,0))
		for i in 5: await physics_frame; await process_frame
		check(absf(float(e.get(key))-.4)<.015,key+" responds to native XR Tools grab on rotated station")
		slider._handle.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
		grabber.queue_free()
	e.set_absorption(0)
	room.sliders.absorption.set_normalized_value(0)
	e.set_level(.65)
	room.sliders.level.set_normalized_value(.65)
	room.buttons.demo.pressed.emit()
	await idle(e)
	check(e.generation==0 and e.original.size()>100000,"Bundled synthetic phrase creates pass zero with a finite tail")
	check(e.player.playing and e.source_name=="synthetic demo voice","Demo plays and is labelled as synthetic speech")
	e.original_stream.save_to_wav(out+"pass-00.wav")
	await create_timer(.8).timeout
	var frames: PackedVector2Array = e.capture.get_buffer(e.capture.get_frames_available())
	check(frames.size()>1000 and Array(frames).any(func(v): return v.length()>.0001),"Native output capture contains audible PCM")
	await shot("room-entry.png")
	var original: PackedFloat32Array = e.original.duplicate()
	for pass_index in 12:
		room.buttons.next.pressed.emit()
		await idle(e)
		worker_times.append(e.last_worker_ms)
		check(e.generation==pass_index+1,"Pass counter increments exactly once")
		check(e.current.size()==original.size(),"Repeated passes do not grow the recording window")
		check(e.original==original,"Original voice survives repeated filtering")
		if e.generation in [1,4,12]: e.current_stream.save_to_wav(out+"pass-%02d.wav"%e.generation)
	check(e.current!=original,"Repeated signal differs from the source")
	var hard: PackedFloat32Array = e.current.duplicate()
	var peak := 0.0
	for sample in hard: peak=maxf(peak,absf(sample))
	check(peak<=.551 and peak>.5,"Each pass is peak-normalized below full scale")
	var dsp = load("res://commons/artifacts/ambient_patch/room_memory_dsp.gd")
	var twice: Dictionary = dsp.room_pass(dsp.room_pass(original,0).samples,0)
	check(twice.samples!=dsp.room_pass(original,0).samples,"Two passes really recurse, rather than replaying one filtered original")
	check(dsp.room_pass(original,0,Vector3(8,3,5)).samples!=dsp.room_pass(original,0).samples,"Dimensions change the computed resonances")
	await create_timer(.8).timeout
	await shot("room-pass-12.png")
	camera.position = room.stations.RETURN.position+room.stations.RETURN.basis.z*.8+Vector3.UP*1.55
	camera.look_at(room.stations.RETURN.to_global(Vector3(0,1.08,0)))
	await shot("return-controls.png")
	room.buttons.original.pressed.emit()
	check(e.generation==12 and e.player.stream==e.original_stream,"Original comparison does not reset the experiment")
	room.buttons.replay.pressed.emit()
	check(e.player.stream==e.current_stream,"REPLAY restores the current generation")
	room.buttons.reset.pressed.emit()
	check(e.generation==0 and e.current==original and not e.player.playing,"RESET stops audio and restores the original")
	room.buttons.next.pressed.emit()
	room.buttons.reset.pressed.emit()
	await idle(e)
	check(e.generation==0 and e.current==original,"RESET during processing discards the pending result")
	e.set_absorption(1)
	for i in 12:
		e.next_pass()
		await idle(e)
	e.current_stream.save_to_wav(out+"soft-pass-12.wav")
	check(e.current!=hard,"Absorbent and reflective surfaces produce different sound from the same voice")
	room.sliders.absorption.set_normalized_value(1)
	room._refresh()
	check(room.walls.all(func(w): return w.material_override.albedo_color.is_equal_approx(Color(.12,.23,.25))),"Visible surface changes follow the actual audio parameter")
	camera.position = Vector3(-1.65,1.68,1.6)
	camera.look_at(Vector3(.4,1.28,-.7))
	await shot("absorbent-room.png")
	e.set_absorption(.5)
	check(e.generation==0 and e.current==original and not e.automatic,"Changing absorption restarts from the same original for comparison")
	e.toggle_auto()
	check(e.automatic and e.player.playing,"AUTO starts playback")
	e.player.finished.emit()
	await idle(e)
	check(e.generation==1 and e.automatic,"Finished playback schedules exactly one new automatic pass")
	e.toggle_auto()
	check(not e.automatic and not e.player.playing,"AUTO / STOP stops the sequence")
	e.generation = 24
	e.automatic = true
	e.next_pass()
	check(not e.automatic and not e.busy,"Automatic recursion is bounded at 24 passes")
	e.reset()
	# Test the record-bus path using known synthetic PCM, without opening a real mic.
	e._ensure_mic()
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(e.mic_bus)),"Microphone bus is muted to prevent live feedback")
	var fake_mic := AudioStreamPlayer.new()
	fake_mic.stream = load(e.DEMO) as AudioStreamWAV
	fake_mic.bus = e.mic_bus
	root.add_child(fake_mic)
	e.recording = true
	e.recorder.set_recording_active(true)
	fake_mic.play()
	await create_timer(.9).timeout
	e._finish_recording()
	fake_mic.stop()
	await idle(e)
	check(e.source_name=="your local recording" and not e.mic.playing and not e.recording,"Recording pipeline accepts PCM then closes capture")
	fake_mic.queue_free()
	var silence := AudioStreamWAV.new()
	silence.format=AudioStreamWAV.FORMAT_16_BITS
	silence.mix_rate=22050
	silence.data = PackedByteArray()
	var silent_data := PackedByteArray()
	silent_data.resize(44100)
	silence.data=silent_data
	check(dsp.prepare(silence).has("error"),"Silence is rejected instead of amplifying microphone noise")
	e.recording = true
	e.recorder.set_recording_active(true)
	e.mic_capture.clear_buffer()
	e._record_seconds = 7.95
	e._process(.1)
	check(not e.recording,"Recording automatically ends at eight seconds")
	await idle(e)
	var staging := MemoryStagingProbe.new()
	root.add_child(staging)
	var compact: Node3D = load("res://commons/artifacts/ambient_patch/ambient_patch.tscn").instantiate()
	staging.add_child(compact)
	compact.buttons.room.pressed.emit()
	await process_frame
	check(staging.requested=="res://commons/scenes/room_memory.tscn","Synthesis Lab ENTER ROOM now selects the Lucier experiment")
	staging.queue_free()
	room.queue_free()
	await process_frame
	check(AudioServer.bus_count==baseline_buses,"Leaving the instrument removes only its owned audio buses")
	var wrapper = load("res://commons/scenes/room_memory.tscn").instantiate()
	staging = MemoryStagingProbe.new()
	root.add_child(staging)
	staging.add_child(wrapper)
	await physics_frame
	check(not wrapper.leaving,"Arrival does not overlap the exit trigger")
	check(wrapper.desktop!=null and wrapper.room.audio!=null,"Complete scene loads through the existing XR wrapper")
	await shot("playable-entry.png")
	wrapper.room.buttons.ambient.pressed.emit()
	await process_frame
	check(staging.requested=="res://commons/scenes/ambient_listening_room.tscn","Earlier generative ambient room remains available")
	wrapper.return_to_hall()
	await process_frame
	check(staging.requested=="res://commons/scenes/endless_museum_staged.tscn","Return uses the existing staged museum")
	staging.queue_free()
	await process_frame
	FileAccess.open(out+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"worker_ms":worker_times,"scope":"Desktop source/PCM/native control/geometry tests. Headset microphone permission, comfort and performance untested."},"  "))
	print("ROOM_MEMORY_RESULT ",checks.size()," checks; failures ",failures)
	quit(0 if failures.is_empty() else 1)

func inspect(host: Node3D, target: Vector3, label: String) -> void:
	var station := host.get_parent()
	if not String(station.name).ends_with("Station"): station=station.get_parent()
	var feet: Vector3 = station.global_position+station.global_basis.z*.55
	var distance := Vector2(target.x-feet.x,target.z-feet.z).length()
	var from := feet+Vector3.UP*1.2
	var ray := PhysicsRayQueryParameters3D.create(from,target+(target-from).normalized()*.01,1|(1<<20)|(1<<22))
	ray.collide_with_areas = true
	var hit := room.get_world_3d().direct_space_state.intersect_ray(ray)
	check(distance<.7 and target.y>.7 and target.y<1.25,label+" is within working reach")
	check(not hit.is_empty() and (hit.collider==host or host.is_ancestor_of(hit.collider)),label+" has an unobstructed interaction ray")

func shot(file: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+file)
