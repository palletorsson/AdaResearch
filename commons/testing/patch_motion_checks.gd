extends RefCounted
class Press extends RefCounted:
	var event_type := 2
class Hand extends Node3D:
	var picked_up_ranged := false

func run(tree: SceneTree, station: Node3D, camera: Camera3D) -> void:
	var app = station.specimen.patch_application
	var manager: SynthCableManager = app.manager
	var live = app.live
	tree.check("existing UVAC exposes physical sockets on desktop",manager._all_jacks.size() == 8)
	tree.check("four supplied cords form audio and independent motor routes",manager.routes.vco_frequency == ["vcf_audio_in"] and manager.has_route("vcf_audio_out","vca_audio_in") and manager.has_route("power_gate","motor_gate"))
	for i in 5: await tree.process_frame
	tree.check("arrival is silent and stationary",not live.audible and not app.motor_running)
	app.get_node("POWER").pointer_event(Press.new())
	await tree.create_timer(0.25).timeout
	tree.check("power control starts live sound and patched motor",app.powered and live.audible and app.motor_running and live.frames_generated > 0)
	var previous: float = app.phase
	await tree.create_timer(0.15).timeout
	tree.check("powered machine turns real transforms",app.phase > previous and absf(app.wheels[0].rotation.z) > 0.01)
	var motor_cable: SynthCable
	for cable in manager.cables:
		if cable.get_input_jack() == app.motor: motor_cable = cable
	tree.check("gate cord shows travelling signal",motor_cable.flow > 0 and motor_cable.pulse.visible)
	motor_cable.plug_b.on_desktop_grab(null)
	await tree.process_frame; previous = app.phase
	await tree.create_timer(0.1).timeout
	tree.check("pulling motor plug removes route and stops rotation",not manager.has_route("power_gate","motor_gate") and not app.motor_running and is_equal_approx(previous,app.phase))
	tree.check("independent synth continues after motor unplug",live.audible)
	motor_cable.plug_b.global_position = app.motor.get_socket_position()
	motor_cable.plug_b.on_desktop_drop(null)
	await tree.process_frame
	tree.check("desktop release snaps both socket and cable state",app.motor.connected_plug == motor_cable.plug_b and manager.has_route("power_gate","motor_gate"))
	var hand := Hand.new(); tree.root.add_child(hand)
	hand.global_transform = motor_cable.plug_b.global_transform
	motor_cable.plug_b.pick_up(hand)
	for i in 4: await tree.physics_frame
	tree.check("native XR grab unplugs the same body",motor_cable.plug_b.is_picked_up() and not app.motor.is_connected)
	hand.position += Vector3(0.2,0.1,0)
	for i in 6: await tree.physics_frame
	tree.check("plug mesh follows native XR pickup",motor_cable.plug_b.global_position.distance_to(app.motor.get_socket_position()) > 0.1)
	motor_cable.plug_b.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	motor_cable.plug_b.snap_to_jack(app.motor); hand.queue_free()
	var free_cable := manager.spawn_cable()
	# Exercise the production desktop ray and grab/drop path as well.
	var pointer = load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	tree.root.add_child(pointer); pointer.set_process(false); pointer._camera = camera
	var visitor_pose := camera.global_transform
	camera.global_position = motor_cable.plug_b.to_global(Vector3(0,0,0.65))
	camera.look_at(motor_cable.plug_b.global_position)
	for i in 3: await tree.physics_frame
	tree.check("desktop ray finds motor plug",pointer._find_grabbable() == motor_cable.plug_b)
	pointer._grab_held(motor_cable.plug_b)
	tree.check("unpatch refuses to delete a held cord",not app.unpatch())
	pointer._drop_held()
	pointer.queue_free(); camera.global_transform = visitor_pose
	motor_cable.plug_b.snap_to_jack(app.motor)
	tree.check("occupied socket refuses a second plug",not free_cable.plug_a.snap_to_jack(app.gate))
	manager.remove_cable(motor_cable)
	free_cable.plug_a.snap_to_jack(app.gate)
	var audio_plug = manager.cables[0].plug_b
	audio_plug._unsnap()
	tree.check("gate cord cannot enter an audio input",not free_cable.plug_b.snap_to_jack(manager.input_jacks.vcf_audio_in[0]))
	audio_plug.snap_to_jack(manager.input_jacks.vcf_audio_in[0])
	manager.remove_cable(free_cable)
	tree.check("removing cable clears socket ownership and routes",not app.gate.is_connected and not app.motor.is_connected and not manager.has_route("power_gate","motor_gate"))
	app.example_patch()
	for i in 5: await tree.process_frame
	var first: SynthCable = manager.cables[0]
	var rebuilds := first.mesh_rebuilds
	for i in 6: await tree.process_frame
	tree.check("stationary cord does not rebuild its sweep every frame",first.mesh_rebuilds == rebuilds)
	first.plug_a._unsnap()
	await tree.process_frame
	tree.check("source unplug silences downstream audio",not live.audible and not manager.has_route("vco_frequency","vcf_audio_in"))
	app.example_patch()
	app.speaker_jack.force_disconnect()
	await tree.process_frame
	tree.check("unplugged speaker silences a complete upstream patch",not live.audible)
	app.example_patch()
	# Capture actual samples after the bus filter, not merely a UI value.
	camera.global_position = app.to_global(Vector3(1.6,1.55,4.8))
	camera.look_at(app.to_global(Vector3(-0.4,1.15,1.7)))
	var bus := AudioServer.get_bus_index(app.rack.dedicated_bus_name)
	var capture := AudioEffectCapture.new(); capture.buffer_length = 1.5
	var capture_index := AudioServer.get_bus_effect_count(bus)
	AudioServer.add_bus_effect(bus,capture)
	var controls: Dictionary = app.rack.active_controls
	controls.VCF_cutoff.instance.set_normalized_value(0.0)
	controls.VCF_enabled.instance.set_normalized_value(1.0)
	await tree.create_timer(0.35).timeout
	var filtered := await record(tree,capture,0.8)
	controls.VCF_enabled.instance.set_normalized_value(0.0)
	await tree.create_timer(0.25).timeout
	var dry := await record(tree,capture,0.8)
	var wet_rms := energy(filtered); var dry_rms := energy(dry)
	tree.check("native bus produces nonzero synth audio",dry_rms > 0.00001 and dry.size() > 1000)
	tree.check("filter lever audibly attenuates the generated harmonics",wet_rms < dry_rms*0.65 and not live.filtered)
	# Bypass by actually repatching VCO directly to VCA.
	manager.remove_cable(manager.cables[0]); manager.remove_cable(manager.cables[0])
	app.connect_pair(manager.output_jacks.vco_frequency,manager.input_jacks.vca_audio_in[0])
	await tree.process_frame
	tree.check("direct physical patch bypasses VCF",live.audible and not live.filtered)
	app.lever.set_angle_degrees(-40)
	await tree.create_timer(0.3).timeout
	var silence := await record(tree,capture,0.18)
	tree.check("open power lever stops both motor and measured audio",not app.motor_running and energy(silence) < maxf(0.000001,dry_rms*0.01))
	# Publish a short A/B excerpt: dry, filtered, then power off.
	var pcm := PackedVector2Array(); pcm.append_array(dry); pcm.append_array(filtered); pcm.append_array(silence)
	var wave := AudioStreamWAV.new(); wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = int(AudioServer.get_mix_rate()); wave.stereo = true
	var bytes := PackedByteArray(); bytes.resize(pcm.size()*4)
	for i in pcm.size():
		bytes.encode_s16(i*4,roundi(clampf(pcm[i].x*4,-1,1)*32767))
		bytes.encode_s16(i*4+2,roundi(clampf(pcm[i].y*4,-1,1)*32767))
	wave.data = bytes; wave.save_to_wav(tree.OUT+"tube-patch-audio.wav")
	AudioServer.remove_bus_effect(bus,capture_index)
	app.example_patch(); controls.VCF_cutoff.instance.set_normalized_value(0.17)
	controls.VCF_enabled.instance.set_normalized_value(1.0); app.lever.set_angle_degrees(40)
	for pose in ["machine","patch"]:
		camera.global_position = app.to_global(Vector3(1.8,1.8,6.6) if pose == "machine" else Vector3(0.1,1.6,3.65))
		camera.look_at(app.to_global(Vector3(0,1.8,0) if pose == "machine" else Vector3(-0.40,1.28,1.96)))
		for i in 12: await tree.process_frame
		await RenderingServer.frame_post_draw
		tree.check("native museum capture "+pose,tree.root.get_texture().get_image().save_png(tree.OUT+"tube-"+pose+".png") == OK)
	app.lever.set_angle_degrees(-40)

func record(tree: SceneTree, capture: AudioEffectCapture, seconds: float) -> PackedVector2Array:
	capture.clear_buffer(); await tree.create_timer(seconds).timeout
	return capture.get_buffer(capture.get_frames_available())
func energy(frames: PackedVector2Array) -> float:
	var sum := 0.0
	for frame in frames: sum += frame.length_squared()
	return sqrt(sum/maxi(1,frames.size()))
