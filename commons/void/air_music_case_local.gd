extends "res://commons/artifacts/air_music_display_case/air_music_display_case.gd"
## Preserve the museum case. Its slider emits one argument, while the source
## callback accepts none; its synth plays through a pool of child voices.

func _setup_controls():
	super._setup_controls()
	if _volume_slider:
		_volume_slider.slider_moved.disconnect(_on_volume_changed)
		_volume_slider.slider_moved.connect(_volume_changed_with_value)

func _volume_changed_with_value(_value) -> void:
	super._on_volume_changed()
	_apply_voice_volume()

func _adjust_audio():
	super._adjust_audio()
	_apply_voice_volume()

func _apply_voice_volume() -> void:
	if not air_music_instance: return
	var synth: Node = air_music_instance.get_node_or_null("FMPianoSynth")
	if synth is FMPianoSynth:
		synth.gain = db_to_linear(audio_volume_db)
		for voice in synth._players: voice.volume_db = audio_volume_db
