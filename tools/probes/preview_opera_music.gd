extends SceneTree
## Capture the real Godot mixer, including the singing-triggered gain envelopes.
const Voice := preload("res://commons/void/inner_voice_godot.gd")
const Score := preload("res://commons/void/inner_opera_score.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var bindings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/opera/tower_bindings.json"))
	var recorder := AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	var music := Score.new()
	root.add_child(music)
	assert(music.configure(bindings.accompaniment))
	music.set_context(true, false)
	var voice := Voice.new()
	voice.volume_db = float(bindings.volume_db)
	root.add_child(voice)
	assert(voice.load_score(bindings.score, bindings.voice, bindings.renderer).is_empty())
	voice.started.connect(func(_id, _text): music.set_singing(true))
	voice.finished.connect(func(_id): music.set_singing(false))
	await create_timer(3.0).timeout
	assert(voice.sing("crate"))
	await voice.finished
	await create_timer(4.5).timeout
	assert(voice.sing("clock"))
	await voice.finished
	await create_timer(4.0).timeout
	music.set_context(false, false)
	await create_timer(1.6).timeout
	recorder.set_recording_active(false)
	var wav := recorder.get_recording()
	var target := ProjectSettings.globalize_path("res://../lofi/version-3-with-lofi.wav")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): target = arg.trim_prefix("--output=")
	assert(wav.save_to_wav(target) == OK)
	print("OPERA_PREVIEW ", target, " ", wav.get_length(), " s")
	voice.queue_free()
	music.queue_free()
	await create_timer(0.2).timeout
	quit()
