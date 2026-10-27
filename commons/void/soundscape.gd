# soundscape.gd
# Scene-owned quiet city/wind, sparse birds/sirens, music and object feedback.
# Hooks existing interaction signals; never changes artifact behaviour or input.
extends Node3D

const MANIFEST := "res://commons/void/audio/manifest.json"
const BUS := {"ambience": "VoidAmbience", "music": "VoidMusic", "effects": "VoidEffects"}
const VOICES := 8
const FEEDBACK_SIGNALS := ["picked_up", "dropped", "declined", "slider_moved", "activated", "button_pressed", "pressed", "toggled", "action_pressed", "taken", "damage_dealt"]
var game: Node3D
var config: Dictionary
var streams: Dictionary = {}
var wind: AudioStreamPlayer
var cities: Array[AudioStreamPlayer3D] = []
var bird: AudioStreamPlayer3D
var siren: AudioStreamPlayer3D
var voices: Array[AudioStreamPlayer3D] = []
var music: Array[AudioStreamPlayer] = []
var music_slot := 0
var music_index := -1
var music_fade: Tween
var rng := RandomNumberGenerator.new()
var bird_wait := 0.0
var siren_wait := 0.0
var clock := 0.0
var prune_wait := 10.0
var last_cue: Dictionary = {}
var hooks: Dictionary = {}
var cue_count := 0
var last_kind := ""
var last_position := Vector3.ZERO
var hurt_voice: AudioStreamPlayer
var hurt_count := 0

func configure(owner_game: Node3D) -> void:
	game = owner_game
	config = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	rng.randomize()
	for channel in BUS:
		var bus: String = BUS[channel]
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), float(config.mix_db[channel]))
	for key in config.sounds:
		var path := str(config.sounds[key].path)
		var stream := _read_stream(path)
		if stream != null: streams[key] = stream
		else: push_warning("Void sound missing: " + path)
	# Own-body feedback stays audible while falling or returning to a checkpoint;
	# a busy pool of spatial artifact sounds must not swallow the grunt.
	hurt_voice = AudioStreamPlayer.new()
	hurt_voice.name = "PainGrunt"
	hurt_voice.bus = BUS.effects
	hurt_voice.stream = streams.get("grunt")
	hurt_voice.volume_db = _db("grunt")
	add_child(hurt_voice)
	wind = AudioStreamPlayer.new()
	wind.name = "Wind"
	wind.bus = BUS.ambience
	wind.stream = _loop("wind")
	wind.volume_db = -60
	add_child(wind)
	if wind.stream != null: wind.play()
	for at in [Vector3(-110, -65, -150), Vector3(140, -70, 110)]:
		var city := AudioStreamPlayer3D.new()
		city.name = "DistantCity"
		city.bus = BUS.ambience
		city.stream = _loop("city")
		city.position = at
		city.unit_size = 100.0
		city.max_distance = 450.0
		city.panning_strength = 0.55
		city.volume_db = -60
		add_child(city)
		if city.stream != null: city.play(0 if cities.is_empty() else 13.0)
		cities.append(city)
	bird = AudioStreamPlayer3D.new()
	bird.name = "OccasionalBird"
	bird.bus = BUS.ambience
	bird.unit_size = 22.0
	bird.max_distance = 160.0
	add_child(bird)
	siren = AudioStreamPlayer3D.new()
	siren.name = "FarCitySiren"
	siren.bus = BUS.ambience
	siren.unit_size = 100.0
	siren.max_distance = 600.0
	siren.panning_strength = 0.45
	add_child(siren)
	for i in range(VOICES):
		var voice := AudioStreamPlayer3D.new()
		voice.name = "ObjectVoice%d" % i
		voice.bus = BUS.effects
		voice.unit_size = 2.5
		voice.max_distance = 24.0
		voice.max_db = 0.0
		add_child(voice)
		voices.append(voice)
	var bank := get_node_or_null("/root/SoundBank")
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "Music%d" % i
		player.bus = BUS.music
		player.finished.connect(_music_finished.bind(player))
		add_child(player)
		music.append(player)
		if bank != null: bank.register_music_player(player)
	game.building.content.floor_changed.connect(_scan_floor)
	game.building.content.panel_activated.connect(func(at: Vector3): play_cue("activate", at))
	get_tree().node_added.connect(_node_added)
	_scan_floor(0)
	_schedule_bird()
	_schedule_siren()
	if not config.music.is_empty(): _next_track()

func _loop(key: String) -> AudioStream:
	if not streams.has(key): return null
	var stream: AudioStream = streams[key].duplicate()
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	elif stream is AudioStreamMP3 or stream is AudioStreamOggVorbis: stream.loop = true
	return stream

func _read_stream(path: String) -> AudioStream:
	# Imported resources work in exports. Raw loading also accepts a freshly
	# delivered sound before the editor has imported it (or a user:// MP3).
	if ResourceLoader.exists(path): return load(path) as AudioStream
	if FileAccess.file_exists(path):
		match path.get_extension().to_lower():
			"wav": return AudioStreamWAV.load_from_file(path)
			"mp3": return AudioStreamMP3.load_from_file(path)
			"ogg": return AudioStreamOggVorbis.load_from_file(path)
	return null

func _process(delta: float) -> void:
	if game == null: return
	clock += delta
	prune_wait -= delta
	if prune_wait <= 0:
		prune_wait = 10.0
		_prune_hooks()
	# Exposed roof/edges are a little windier; changes follow position smoothly.
	var at: Vector3 = game.body.global_position
	var exposure := maxf(clampf((absf(at.x) - 10.0) / 10.0, 0, 1), clampf((absf(at.z) - 3.0) / 6.0, 0, 1))
	if at.y > -3: exposure = 1.0
	wind.volume_db = move_toward(wind.volume_db, _db("wind") - (1.0-exposure)*4.0, delta*8)
	for city in cities: city.volume_db = move_toward(city.volume_db, _db("city"), delta*8)
	bird_wait -= delta
	if bird_wait <= 0:
		if not game.returning: play_bird()
		_schedule_bird()
	siren_wait -= delta
	if siren_wait <= 0:
		if not game.returning: play_siren()
		_schedule_siren()

func _db(key: String) -> float:
	return float(config.sounds.get(key, {}).get("db", -12.0))

func _schedule_bird() -> void:
	var interval: Array = config.get("bird_interval_seconds", [50, 110])
	bird_wait = rng.randf_range(maxf(5, float(interval[0])), maxf(6, float(interval[1])))

func play_bird() -> void:
	var key := "bird1" if rng.randf() < 0.5 else "bird2"
	if not streams.has(key) or bird.playing or siren.playing: return
	var angle := rng.randf_range(0, TAU)
	# A call stays at a world position while the listener moves/turns.
	bird.global_position = game.camera.global_position + Vector3(cos(angle)*55, rng.randf_range(8, 20), sin(angle)*55)
	bird.stream = streams[key]
	bird.volume_db = _db(key)
	bird.pitch_scale = rng.randf_range(0.94, 1.06)
	bird.play()

func _schedule_siren() -> void:
	var interval: Array = config.get("siren_interval_seconds", [120, 240])
	siren_wait = rng.randf_range(maxf(30, float(interval[0])), maxf(31, float(interval[1])))

func play_siren() -> void:
	if not streams.has("siren") or siren.playing or bird.playing: return
	# Fixed city locations, well below and beyond the tower. Never follows the head.
	var sources := [Vector3(-220, -85, -180), Vector3(240, -90, 150), Vector3(90, -80, 260)]
	siren.position = sources[rng.randi_range(0, sources.size() - 1)]
	siren.stream = streams.siren
	siren.volume_db = _db("siren")
	siren.pitch_scale = rng.randf_range(0.94, 1.02)
	siren.play()

## Explicit hook for interactions without a signal. No repeated contact sound.
func play_cue(kind: String, at: Vector3) -> bool:
	if not streams.has(kind) or game.returning or game.camera.global_position.distance_to(at) > 24: return false
	for voice in voices:
		if voice.playing: continue
		voice.global_position = at
		voice.stream = streams[kind]
		voice.volume_db = _db(kind)
		voice.pitch_scale = 1.0
		voice.play()
		cue_count += 1
		last_kind = kind
		last_position = at
		return true
	return false # Bounded polyphony; do not interrupt an already sounding cue.

func play_hurt() -> void:
	# Palle: remove the body pain sound. Keep the existing hook for callers,
	# while interactions, music and environmental ambience retain their audio.
	pass

func _scan_floor(_index: int) -> void:
	_bind_tree(game.building.content)

func _node_added(node: Node) -> void:
	# Ink creates many meshes. Only defer work for a potential sound source.
	if game != null and game.building.content.is_ancestor_of(node) and FEEDBACK_SIGNALS.any(func(key: String) -> bool: return node.has_signal(key)):
		_bind_later.call_deferred(weakref(node))

func _bind_later(ref: WeakRef) -> void:
	var node: Node = ref.get_ref()
	if is_instance_valid(node) and node.is_inside_tree(): _bind(node)

func _bind_tree(node: Node) -> void:
	_bind(node)
	for child in node.get_children(): _bind_tree(child)

func _bind(node: Node) -> void:
	if not node.get_meta("void_sound_enabled", true): return
	if node.get_meta("void_sound_bound", 0) == get_instance_id(): return
	node.set_meta("void_sound_bound", get_instance_id())
	var assigned: Dictionary = {}
	for pair in [["picked_up", "grab"], ["dropped", "release"], ["declined", "reject"], ["slider_moved", "click"], ["damage_dealt", "reject"]]:
		if node.has_signal(pair[0]): assigned[pair[0]] = pair[1]
	# One authoritative activation signal per node avoids duplicate clicks.
	for signal_name in ["activated", "button_pressed", "pressed", "toggled", "action_pressed", "taken"]:
		if node.has_signal(signal_name):
			assigned[signal_name] = "click" if signal_name in ["button_pressed", "pressed", "toggled"] else "activate"
			break
	if assigned.is_empty(): return
	for signal_name in assigned:
		var count := 0
		for description in node.get_signal_list():
			if description.name == signal_name: count = description.args.size(); break
		# Signal arguments describe the operation, not the sound. Discard them
		# explicitly; the object itself supplies the spatial source.
		var callback := _interaction.bind(weakref(node), str(assigned[signal_name]), str(signal_name))
		if count > 0: callback = callback.unbind(count)
		node.connect(signal_name, callback)
	hooks[node.get_instance_id()] = {"node": weakref(node), "signals": assigned}

func _interaction(ref: WeakRef, kind: String, signal_name: String) -> void:
	var node: Node = ref.get_ref()
	if not is_instance_valid(node) or not node.is_inside_tree() or not node.can_process(): return
	var source: Node = node
	while source != null and not source is Node3D: source = source.get_parent()
	if source == null or not source.is_visible_in_tree(): return
	var key := "%s/%s" % [node.get_instance_id(), signal_name]
	var cooldown := 0.22 if signal_name == "slider_moved" else 0.08
	if clock - float(last_cue.get(key, -10)) < cooldown: return
	last_cue[key] = clock
	play_cue(kind, source.global_position)

## Rendered MP3/OGG/WAV music stays independent of ambience and object voices.
func play_music(path: String, fade_seconds := 2.0) -> bool:
	var stream := _read_stream(path)
	if stream == null: return false
	if is_instance_valid(music_fade): music_fade.kill()
	var old := music[music_slot]
	music_slot = 1 - music_slot
	var next := music[music_slot]
	next.stop()
	next.stream = stream
	next.volume_db = -60
	next.play()
	music_fade = create_tween().set_parallel(true)
	music_fade.tween_property(next, "volume_db", 0.0, maxf(0.05, fade_seconds))
	music_fade.tween_property(old, "volume_db", -60.0, maxf(0.05, fade_seconds))
	music_fade.chain().tween_callback(old.stop)
	return true

func _next_track() -> void:
	var tracks: Array = config.music
	for attempt in range(tracks.size()):
		music_index = (music_index + 1) % tracks.size()
		if play_music(str(tracks[music_index])): return

func _music_finished(player: AudioStreamPlayer) -> void:
	if player == music[music_slot] and not config.music.is_empty(): _next_track()

func coverage() -> Array[Dictionary]:
	_prune_hooks()
	var result: Array[Dictionary] = []
	for id in hooks.keys():
		var node: Node = hooks[id].node.get_ref()
		if not is_instance_valid(node): hooks.erase(id); continue
		result.append({"path": str(game.get_path_to(node)), "signals": hooks[id].signals})
	return result

func _prune_hooks() -> void:
	for id in hooks.keys():
		if is_instance_valid(hooks[id].node.get_ref()): continue
		hooks.erase(id)
		for signal_name in FEEDBACK_SIGNALS: last_cue.erase("%s/%s" % [id, signal_name])

func _exit_tree() -> void:
	if is_instance_valid(music_fade): music_fade.kill()
	for player in get_children():
		if player is AudioStreamPlayer or player is AudioStreamPlayer3D:
			player.stop()
			player.stream = null
	streams.clear()
	var bank := get_node_or_null("/root/SoundBank")
	if bank != null:
		for player in music: bank.unregister_music_player(player)
