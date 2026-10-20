# Full-project audio integration, including real autoloads and existing controls.
extends "res://tools/probes/void_fog_probe.gd"

func wait(seconds := 0.2) -> void:
	await get_tree().create_timer(seconds).timeout

func run() -> void:
	await wait(3.0)
	var sound: Node3D = game.soundscape
	var bank: Node = get_node("/root/SoundBank")
	check("full game has wind and two distant city beds", sound.wind.playing and sound.cities.size() == 2 and sound.cities.all(func(p): return p.playing))
	check("beds loop with nonempty sound data", sound.wind.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and sound.wind.stream.get_length() > 20 and sound.cities[0].stream.get_length() > 20)
	check("music, ambience and effects have independent buses", sound.wind.bus == "VoidAmbience" and sound.voices[0].bus == "VoidEffects" and sound.music[0].bus == "VoidMusic")
	check("MP3 music players join the existing SoundBank lifecycle", sound.music.all(func(p): return p in bank._music_players))
	check("no placeholder song starts when playlist is empty", not sound.music[0].playing and not sound.music[1].playing)
	sound._schedule_bird()
	check("bird scheduling leaves 50 to 110 seconds between attempts", sound.bird_wait >= 50 and sound.bird_wait <= 110)
	check("siren does not play on arrival", not sound.siren.playing and sound.siren_wait > 110 and sound.siren_wait <= 240)
	check("continuous ambience is substantially quieter", sound._db("wind") <= -28 and sound._db("city") <= -28 and sound._db("bird1") <= -22)
	sound.play_bird()
	var bird_at: Vector3 = sound.bird.global_position
	check("bird has a world-space source outside the tower", sound.bird.playing and bird_at.distance_to(game.camera.global_position) > 50)
	game.camera.rotation.y += 0.5
	await wait()
	check("turning the head does not move the bird source", sound.bird.global_position.is_equal_approx(bird_at))
	sound.play_siren()
	check("siren leaves an existing bird call alone", not sound.siren.playing)
	sound.bird.stop()
	sound.siren_wait = 0
	sound._process(0)
	var siren_at: Vector3 = sound.siren.global_position
	check("scheduled siren is quiet, non-looping and far below the tower", sound.siren.playing and siren_at.distance_to(game.camera.global_position) > 250 and siren_at.y < -75 and sound.siren.volume_db <= -22 and sound.siren.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	check("next siren attempt waits two to four minutes", sound.siren_wait >= 120 and sound.siren_wait <= 240)
	game.camera.rotation.y -= 0.5
	await wait()
	check("turning the head does not move the siren source", sound.siren.global_position.is_equal_approx(siren_at))
	sound.play_bird()
	check("birds leave the distant siren space", not sound.bird.playing)
	sound.siren.stop()
	check("city horizon is one instanced mesh with no colliders", game.atmosphere.city.multimesh.instance_count == 72 and game.atmosphere.city.find_children("*", "CollisionObject3D", true, false).is_empty())
	check("full-project fog fix remains intact", game.camera.environment.fog_enabled and game.camera.environment.fog_density == 1.0)
	game.place_player(game.spawn_for(2))
	await wait(0.3)
	check("Point Coordinates' existing held point receives feedback", sound.hooks.has(game.coordinate_point.get_instance_id()))
	game.place_player(game.spawn_for(3))
	await wait(0.5)
	var room: Node3D = game.building.content.exhibits["3/setting_out"].get_node("Artifact/MeasurementRoom")
	game.place_player(Vector3(room.global_position.x, -17.94, room.global_position.z + 1.0))
	await wait()
	var count: int = sound.cue_count
	room.point_a.position.x += 0.3
	room.reset_button._on_button_entered(game.body)
	await wait()
	check("actual line reset button emits one spatial click", sound.cue_count == count + 1 and sound.last_kind == "click" and sound.last_position.is_equal_approx(room.reset_button.global_position))
	check("sound does not replace the reset operation", room.point_a.position.is_equal_approx(room.HOME_A))
	room.reset_button._on_button_exited(game.body)
	for i in range(3): sound._scan_floor(3)
	await wait()
	count = sound.cue_count
	room.reset_button._on_button_entered(game.body)
	await wait()
	check("rebinding a loaded floor never duplicates clicks", sound.cue_count == count + 1)
	room.reset_button._on_button_exited(game.body)
	game.place_player(game.spawn_for(4))
	await wait(0.5)
	var drawing: Node3D = game.building.content.exhibits["4/record"].get_node("Artifact/ShadowPoint")
	var point: Node3D = drawing.point
	game.place_player(Vector3(point.global_position.x, -23.94, point.global_position.z + 1.0))
	await wait()
	count = sound.cue_count
	point.on_desktop_grab(null)
	await wait()
	check("taking the existing black point sounds once at the point", sound.cue_count == count + 1 and sound.last_kind == "grab" and sound.last_position.distance_to(point.global_position) < 0.1)
	point.position += Vector3(0.3, 0.1, 0)
	await wait()
	point.on_desktop_drop(null)
	await wait()
	check("release sounds and the existing trace survives", sound.last_kind == "release" and drawing.ink.get_child_count() > 0)
	var ramp: Node3D = game.building.content.exhibits["4/release"].get_node("Artifact/BallRamp")
	# Supply through the existing factory: the newly born point must be hooked.
	ramp._supply_ball()
	await wait()
	check("new ramp balls acquire feedback without rescanning the hall", sound.hooks.has(ramp.ball.get_instance_id()))
	game.place_player(game.spawn_for(0))
	await wait(0.3)
	count = sound.cue_count
	point.picked_up.emit(point)
	await wait()
	check("sleeping floors cannot emit object feedback", sound.cue_count == count)
	count = sound.cue_count
	check("distant feedback is culled", not sound.play_cue("click", game.camera.global_position + Vector3(100, 0, 0)) and sound.cue_count == count)
	# The real catalyst panels are on Point One, not on the rooftop.
	game.place_player(game.spawn_for(1))
	await wait(0.3)
	count = sound.cue_count
	var panel_checked := false
	for cell in game.building.content.cells.values():
		if cell.floor != 1 or cell.node.global_position.distance_to(game.camera.global_position) > 18: continue
		var height: float = cell.height
		var reacted: bool = game.building.content.react_at_world(cell.node.global_position, "catalyst.primitives")
		await wait(0.1)
		panel_checked = reacted and cell.height != height and sound.last_kind == "activate" and sound.cue_count == count + 1
		break
	check("catalyst panel activation changes geometry and sounds once", panel_checked)
	check("sound voices remain bounded", sound.voices.size() == 8)
	check("MP3 fixture loads on the music channel", sound.play_music("res://tools/probes/fixtures/void_music.mp3", 0.1))
	await wait(0.25)
	check("MP3 plays without stopping city or wind", sound.music[sound.music_slot].stream is AudioStreamMP3 and sound.music[sound.music_slot].playing and sound.wind.playing and sound.cities[0].playing)
	var previous: AudioStreamPlayer = sound.music[sound.music_slot]
	sound.play_music("res://tools/probes/fixtures/void_music.mp3", 0.1)
	await wait(0.25)
	check("music switch fades and stops the previous deck", not previous.playing and sound.music[sound.music_slot].playing)
	var coverage: Array = sound.coverage()
	FileAccess.open(output.path_join("interaction-coverage.json"), FileAccess.WRITE).store_string(JSON.stringify(coverage, "\t"))
	if capture:
		game.place_player(Vector3(1.5, 0.06, 6.5))
		game.body.enabled = false
		game.set_physics_process(false)
		game.status.hide()
		for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
		game.camera.look_at(Vector3(65, -25, 180))
		get_viewport().msaa_3d = Viewport.MSAA_4X
		await wait(1.0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("city-from-roof.png"))
	var players: Array = sound.music.duplicate()
	game.queue_free()
	await wait()
	check("leaving the tower unregisters its music players", players.all(func(p): return p not in bank._music_players))
	await xr_grip()
	var passed := checks.all(func(item): return item.passed)
	FileAccess.open(output.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": passed, "checks": checks, "hooked_objects": coverage.size(), "scope": "Full-project desktop audio routing, real artifact operations and real XRTools grip/release with synthetic trackers. Provisional assets; headset listening still needed."}, "\t"))
	get_tree().quit(0 if passed else 1)

func xr_grip() -> void:
	var trackers: Array[XRPositionalTracker] = []
	for entry in [["head", "default", Vector3(0, 1.65, 0)], ["left_hand", "aim", Vector3(-0.3, 1.2, -0.4)], ["right_hand", "aim", Vector3(0.3, 1.2, -0.4)]]:
		var item: XRPositionalTracker = XRPositionalTracker.new() if entry[0] == "head" else XRControllerTracker.new()
		item.name = entry[0]
		item.type = XRServer.TRACKER_HEAD if entry[0] == "head" else XRServer.TRACKER_CONTROLLER
		item.set_pose(entry[1], Transform3D(Basis.IDENTITY, entry[2]), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		XRServer.add_tracker(item)
		trackers.append(item)
	var left := trackers[1] as XRControllerTracker
	var right := trackers[2] as XRControllerTracker
	left.set_input("primary", Vector2.ZERO)
	right.set_input("primary", Vector2.ZERO)
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = true
	add_child(game)
	game.place_player(game.spawn_for(2))
	await wait(0.3)
	var point: RigidBody3D = game.coordinate_point
	game.place_player(Vector3(point.global_position.x, -11.94, point.global_position.z + 0.6))
	await wait(0.2)
	var origin: XROrigin3D = game.get_node("XROrigin3D")
	right.set_pose("aim", Transform3D(Basis.IDENTITY, origin.to_local(point.global_position)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await wait(0.3)
	var count: int = game.soundscape.cue_count
	right.set_input("grip", 1.0)
	await wait(0.3)
	check("real XRTools grip produces pickup and spatial grab sound", game.pickups[1].picked_up_object == point and game.soundscape.cue_count > count and game.soundscape.last_kind == "grab")
	right.set_input("grip", 0.0)
	await wait(0.3)
	check("real XRTools release produces spatial release sound", game.pickups[1].picked_up_object == null and game.soundscape.last_kind == "release")
	game.queue_free()
	await wait(0.2)
	for item in trackers: XRServer.remove_tracker(item)
