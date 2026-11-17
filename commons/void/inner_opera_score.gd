extends Node
## Quiet accompaniment with a gentle lift during a thought. The voice is never
## attenuated by this node. Both loops keep time while their gains change.
const BUS := "VoidMusic"
var config := {}
var bed: AudioStreamPlayer
var pulse: AudioStreamPlayer
var active := false
var singing := false
var quiet := false
var envelope := 0.0
var presence := 0.0
var prepared := false

func configure(path: String) -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not bool(parsed.get("enabled", false)): return false
	config = parsed
	if AudioServer.get_bus_index(BUS) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
		AudioServer.set_bus_volume_db(AudioServer.bus_count - 1, -16.0)
	bed = _player("SoftKeys", str(config.bed))
	pulse = _player("BrushedPulse", str(config.pulse))
	prepared = bed.stream != null and pulse.stream != null
	if not prepared:
		push_warning("Inner-opera accompaniment unavailable; voice continues alone.")
		return false
	bed.play()
	pulse.play()
	return true

func _player(title: String, path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = title
	player.bus = BUS
	player.volume_db = -80.0
	var source: AudioStream
	if ResourceLoader.exists(path): source = load(path) as AudioStream
	elif FileAccess.file_exists(path): source = AudioStreamWAV.load_from_file(path)
	if source is AudioStreamWAV:
		var loop: AudioStreamWAV = source.duplicate()
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop.loop_begin = 0
		loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
		player.stream = loop
	add_child(player)
	var bank := get_node_or_null("/root/SoundBank")
	if bank != null and bank.has_method("register_music_player"): bank.register_music_player(player)
	return player

func set_context(on_floor: bool, muted: bool) -> void:
	active = on_floor
	quiet = muted
	if quiet and prepared:
		bed.volume_db = -80.0
		pulse.volume_db = -80.0

func set_singing(value: bool) -> void:
	singing = value

func _process(delta: float) -> void:
	if not prepared: return
	var rise := maxf(0.05, float(config.get("rise_seconds", 0.9)))
	var release := maxf(0.05, float(config.get("release_seconds", 3.0)))
	envelope = move_toward(envelope, 1.0 if singing else 0.0, delta / (rise if singing else release))
	presence = move_toward(presence, 1.0 if active and not quiet else 0.0, delta / 1.5)
	for pair in [[bed, "bed"], [pulse, "pulse"]]:
		var level := lerpf(db_to_linear(float(config[pair[1] + "_idle_db"])), db_to_linear(float(config[pair[1] + "_singing_db"])), envelope) * presence
		pair[0].volume_db = -80.0 if quiet or level <= 0.0001 else linear_to_db(level)

func state() -> Dictionary:
	return {"ready": prepared, "active": active, "singing": singing, "quiet": quiet, "lift": envelope,
		"bed_db": bed.volume_db if bed != null else -80.0, "pulse_db": pulse.volume_db if pulse != null else -80.0}

func _exit_tree() -> void:
	var bank := get_node_or_null("/root/SoundBank")
	for player in [bed, pulse]:
		if player == null: continue
		player.stop()
		if bank != null and bank.has_method("unregister_music_player"): bank.unregister_music_player(player)
