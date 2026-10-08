extends Node3D
## Local phrase capture and finite recursive room passes. No network or saves.
signal state_changed
const DSP = preload("res://commons/artifacts/ambient_patch/room_memory_dsp.gd")
const DEMO := "res://commons/artifacts/ambient_patch/room_memory_demo.res"
const MAX_PASSES := 24
var generation := 0
var absorption := 0.0
var level := .65
var automatic := false
var recording := false
var busy := false
var source_name := "no voice yet"
var status := "Record a phrase, or choose DEMO VOICE."
var original := PackedFloat32Array()
var current := PackedFloat32Array()
var original_stream: AudioStreamWAV
var current_stream: AudioStreamWAV
var player: AudioStreamPlayer3D
var capture: AudioEffectCapture
var spectrum: AudioEffectSpectrumAnalyzer
var bus_name := ""
var mic_bus := ""
var mic: AudioStreamPlayer
var recorder: AudioEffectRecord
var mic_capture: AudioEffectCapture
var _record_seconds := 0.0
var _thread: Thread
var _job := ""
var _accept_job := true
var _next_source_name := ""
var last_worker_ms := 0

func _ready() -> void:
	player = AudioStreamPlayer3D.new()
	player.name = "RoomLoudspeaker"
	player.position = Vector3(-1.85,1.35,-1.92)
	player.unit_size = 4.0
	player.max_distance = 12.0
	player.volume_db = -8.0
	add_child(player)
	player.finished.connect(_finished)

func load_demo() -> void:
	if busy or recording: return
	stop()
	_next_source_name = "synthetic demo voice"
	var wav := load(DEMO) as AudioStreamWAV
	_queue("source",DSP.prepare.bind(wav))

func record_toggle() -> void:
	if recording:
		_finish_recording()
		return
	if busy: return
	stop()
	if not ProjectSettings.get_setting("audio/driver/enable_input",false):
		status = "Audio input disabled. Use DEMO VOICE."
		state_changed.emit()
		return
	if OS.has_feature("android") and not OS.get_granted_permissions().has("android.permission.RECORD_AUDIO"):
		OS.request_permission("android.permission.RECORD_AUDIO")
		status = "Allow the microphone, then press RECORD again."
		state_changed.emit()
		return
	_ensure_mic()
	_record_seconds = 0
	mic_capture.clear_buffer()
	recording = true
	status = "RECORDING / press again to finish / maximum 8 seconds"
	recorder.set_recording_active(true)
	mic.play()
	state_changed.emit()

func _ensure_mic() -> void:
	if mic: return
	mic_bus = "RoomMemoryMic_%s"%get_instance_id()
	AudioServer.add_bus()
	var index := AudioServer.bus_count-1
	AudioServer.set_bus_name(index,mic_bus)
	# Capture is before the muted bus output: never feed live microphone to speakers.
	AudioServer.set_bus_mute(index,true)
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(index,recorder)
	mic_capture = AudioEffectCapture.new()
	mic_capture.buffer_length = .25
	AudioServer.add_bus_effect(index,mic_capture)
	mic = AudioStreamPlayer.new()
	mic.stream = AudioStreamMicrophone.new()
	mic.bus = mic_bus
	add_child(mic)

func _finish_recording() -> void:
	recording = false
	recorder.set_recording_active(false)
	mic.stop()
	_next_source_name = "your local recording"
	var wav: AudioStreamWAV
	if mic_capture.get_frames_available()>0: wav = recorder.get_recording()
	_queue("source",DSP.prepare.bind(wav))

func next_pass() -> void:
	if busy or recording: return
	if current.is_empty():
		status = "Choose a voice first."
		state_changed.emit()
		return
	if generation>=MAX_PASSES:
		automatic = false
		status = "24 passes complete. RESET to return to the voice."
		state_changed.emit()
		return
	player.stop()
	_queue("pass",DSP.room_pass.bind(current.duplicate(),absorption))

func _queue(kind: String, work: Callable) -> void:
	_job = kind
	_accept_job = true
	_thread = Thread.new()
	busy = true
	status = "Preparing voice..." if kind=="source" else "Passing the previous recording through the room..."
	var error := _thread.start(work)
	if error!=OK:
		busy = false
		_thread = null
		automatic = false
		status = "Could not start the audio worker. Try again."
	state_changed.emit()

func play_original() -> void:
	if recording or busy or original_stream==null: return
	automatic = false
	_play(original_stream)
	status = "ORIGINAL / compare with the current pass"
	state_changed.emit()

func play_current() -> void:
	if recording or busy or current_stream==null: return
	_play(current_stream)
	status = "PLAYING / pass %02d"%generation
	state_changed.emit()

func toggle_auto() -> void:
	if automatic:
		stop()
		return
	if recording or busy or current_stream==null: return
	automatic = true
	play_current()

func _finished() -> void:
	if automatic: next_pass()
	else:
		status = "Ready / next pass or compare the original."
		state_changed.emit()

func reset() -> void:
	stop()
	current = original.duplicate()
	current_stream = original_stream
	generation = 0
	status = "Reset to the original voice."
	state_changed.emit()

func set_absorption(value: float) -> void:
	var next := clampf(value,0,1)
	if is_equal_approx(absorption,next): return
	absorption = next
	reset()
	status = "Surface changed / restart from the same original."
	state_changed.emit()

func set_level(value: float) -> void:
	level = clampf(value,0,1)
	player.volume_db = linear_to_db(level*.58) if level>0 else -80.0

func _play(stream: AudioStreamWAV) -> void:
	_ensure_output()
	player.stream = stream
	set_level(level)
	player.play()

func _ensure_output() -> void:
	if not bus_name.is_empty(): return
	bus_name = "RoomMemory_%s"%get_instance_id()
	AudioServer.add_bus()
	var index := AudioServer.bus_count-1
	AudioServer.set_bus_name(index,bus_name)
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -6.0
	AudioServer.add_bus_effect(index,limiter)
	capture = AudioEffectCapture.new()
	capture.buffer_length = .25
	AudioServer.add_bus_effect(index,capture)
	spectrum = AudioEffectSpectrumAnalyzer.new()
	spectrum.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
	AudioServer.add_bus_effect(index,spectrum)
	player.bus = bus_name

func stop(_immediate := true) -> void:
	automatic = false
	_accept_job = false
	if player: player.stop()
	if recording:
		recording = false
		recorder.set_recording_active(false)
		mic.stop()
	status = "Stopped."
	state_changed.emit()

func _process(delta: float) -> void:
	if recording:
		_record_seconds += delta
		if _record_seconds >= DSP.MAX_VOICE_SECONDS: _finish_recording()
	if busy and _thread and not _thread.is_alive():
		var result: Dictionary = _thread.wait_to_finish()
		_thread = null
		busy = false
		if not _accept_job:
			state_changed.emit()
			return
		if result.has("error"):
			status = result.error
			automatic = false
		elif _job=="source":
			original = result.samples
			original_stream = result.stream
			current = original.duplicate()
			current_stream = original_stream
			generation = 0
			source_name = _next_source_name
			play_current()
		else:
			current = result.samples
			current_stream = result.stream
			generation += 1
			last_worker_ms = result.worker_ms
			play_current()
		state_changed.emit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_DISABLED: stop()

func _exit_tree() -> void:
	stop()
	if _thread and _thread.is_started(): _thread.wait_to_finish()
	for owned_bus in [bus_name,mic_bus]:
		if not owned_bus.is_empty():
			var index := AudioServer.get_bus_index(owned_bus)
			if index>=0: AudioServer.remove_bus(index)
