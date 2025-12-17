extends Node3D

# Simple TTS Speaker
# Speaks the assigned message on _ready

@export var message: String = ""
@export var voice_id: String = "" # Optional specific voice
@export var volume: int = 50
@export var pitch: float = 1.0
@export var rate: float = 1.0

func _ready():
	_create_debug_label()
	
	if message.is_empty():
		return
		
	# Small delay to ensure engine is ready and scene is loaded
	await get_tree().create_timer(1.0).timeout
	
	_play_debug_beep()
	speak()

func _create_debug_label():
	var label = Label3D.new()
	label.text = "TTS: " + message
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.5, 0)
	label.font_size = 32
	add_child(label)

func _play_debug_beep():
	var player = AudioStreamPlayer3D.new()
	var sample = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 44100
	sample.stereo = false
	
	var data = PackedByteArray()
	var frames = 8820 # 0.2s
	data.resize(frames * 2)
	
	for i in range(frames):
		var t = float(i) / 44100.0
		var val = sin(t * 880.0 * TAU) * 32767.0 # 880Hz beep
		data.encode_s16(i * 2, int(val))
	
	sample.data = data
	player.stream = sample
	add_child(player)
	player.play()

func speak():
	var voices = DisplayServer.tts_get_voices()
	var selected_voice = voice_id
	
	if selected_voice.is_empty() and not voices.is_empty():
		# Default to first English voice if available, or just the first voice
		for voice in voices:
			if voice["language"].begins_with("en"):
				selected_voice = voice["id"]
				break
		if selected_voice.is_empty():
			selected_voice = voices[0]["id"]
	
	if not selected_voice.is_empty():
		print("TTS Speaker saying: '%s'" % message)
		DisplayServer.tts_speak(message, selected_voice, volume, pitch, rate)
	elif voices.is_empty():
		print("TTS Speaker Warning: No voices available, attempting default fallback")
		DisplayServer.tts_speak(message, "", volume, pitch, rate)
	else:
		print("TTS Speaker Warning: Voice selection failed")

	# Optional: Clean up after a while (though we might want to keep it for re-triggering later)
	# queue_free()
