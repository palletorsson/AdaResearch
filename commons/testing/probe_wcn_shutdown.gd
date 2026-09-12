extends SceneTree
## Which artifact crashes the engine at quit? (waves / chance / noise, 2026-09-12: the museum
## probes of WaveFunctions_AirMusic and WaveFunctions_Synthesis_Lab write their reports and
## then exit 3221225477 / 127 with a C++ backtrace; Effect Sound and the Randomness halls exit 0.)
## Instantiates ONE scene under a Node3D, lets it run a few seconds, writes a JSON and quits;
## the exit code is the finding. Nothing of the museum is involved.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_shutdown.gd -- --scene=res://commons/artifacts/air_music_display_case/air_music_display_case.tscn --seconds=4
##
## Writes res://ada_run/waves_chance_noise/probe_shutdown_<basename>.json before quitting.
func _initialize() -> void: run.call_deferred()

func run() -> void:
	var scene_path := "res://commons/artifacts/air_music_display_case/air_music_display_case.tscn"
	var seconds := 4.0
	var free_first := false
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--scene="): scene_path = str(a).trim_prefix("--scene=")
		if str(a).begins_with("--seconds="): seconds = float(str(a).trim_prefix("--seconds="))
		if str(a) == "--free-first": free_first = true
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.6, 4)
	world.add_child(cam)
	cam.make_current()
	var mode := "scene"
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--mode="): mode = str(a).trim_prefix("--mode=")
	var inst: Node = null
	if mode == "synth_only":
		# the FM piano synth by script: its reverb bus, twelve players, one note queued to a worker
		inst = load("res://commons/audio/systems/air_points/FMPianoSynth.gd").new()
		inst.name = "FMPianoSynth"
		world.add_child(inst)
		inst.call("play_note", 440.0, 0.8, 1.5)
		scene_path = "synth_only"
	elif mode == "bus_only":
		# only what _setup_reverb does: a bus added at runtime with a reverb effect, sent to Master
		var idx: int = AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(idx, "FMPianoReverb")
		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.98; reverb.damping = 0.15; reverb.spread = 1.0; reverb.dry = 0.4; reverb.wet = 0.85
		AudioServer.add_bus_effect(idx, reverb)
		AudioServer.set_bus_send(idx, "Master")
		var p := AudioStreamPlayer.new(); p.bus = "FMPianoReverb"; world.add_child(p)
		scene_path = "bus_only"
	elif mode == "players_only":
		# twelve AudioStreamPlayers on the Master bus, one playing a generated WAV
		for i in range(12):
			var p := AudioStreamPlayer.new(); world.add_child(p)
			if i == 0:
				var gen = load("res://commons/audio/generators/FMPianoGenerator.gd")
				if gen != null: p.stream = gen.generate_note(440.0, 0.8, 1.5); p.play()
		scene_path = "players_only"
	else:
		var ps: PackedScene = load(scene_path)
		inst = ps.instantiate() if ps != null else null
		if inst != null:
			world.add_child(inst)
	await create_timer(seconds).timeout
	var report := {"scene": scene_path, "instantiated": inst != null, "seconds": seconds, "free_first": free_first,
		"children": inst.get_child_count() if inst != null else -1, "engine": Engine.get_version_info().string}
	var base: String = scene_path.get_file().get_basename()
	var f := FileAccess.open("res://ada_run/waves_chance_noise/probe_shutdown_%s.json" % base, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-shutdown] ", base, " ran ", seconds, " s; quitting now (the exit code is the finding)")
	if free_first and inst != null:
		world.remove_child(inst)
		inst.free()
		await process_frame
	quit(0)
