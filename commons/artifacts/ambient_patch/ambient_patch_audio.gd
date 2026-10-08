extends Node3D
## Event-rate composition on the main thread; sample baking on Ada's audio worker.
## Eight finite voices, two shared baked notes, and native bus effects bound the cost.
signal note_started(lane: int, midi: int)
signal state_changed
const Worker = preload("res://commons/audio/AsyncAudioGenerator.gd")
const Pad = preload("res://commons/audio/generators/DiscreetAudioGenerator.gd")
const Bell = preload("res://commons/audio/generators/FMPianoGenerator.gd")
const SCALE = [0, 2, 4, 7, 9]
const PERIODS = [3.7, 6.1, 10.9]
static var sample_cache: Dictionary = {}
var parameters := {"density": .68, "rate": .38, "warmth": .65, "space": .72, "drift": .55, "level": .64}
var patch_seed: int = 220926
var route: String = "filter"
# The room places the same three lanes around the listener. Compact mode keeps
# the original single emitter position and stereo bus modulation.
var source_positions := PackedVector3Array([Vector3(0,1.3,0),Vector3(0,1.3,0),Vector3(0,1.3,0)])
var spatial_orbit := false
var playing := false
var preparing := false
var wanted := false
var elapsed := 0.0
var notes_played := 0
var skipped_voices := 0
var last_midi := 60
var events: Array = [] # Bounded diagnostic history, not a growing score.
var voices: Array[AudioStreamPlayer3D] = []
var bus_name := ""
var lowpass: AudioEffectLowPassFilter
var echo: AudioEffectDelay
var room: AudioEffectReverb
var pan: AudioEffectPanner
var capture: AudioEffectCapture
var _worker: Node
var _rng := RandomNumberGenerator.new()
var _due := [0.0, 1.4, 3.2]
var _gain := -60.0
var _ui_clock := 0.0
var _fade_clock := 0.0

func _ready() -> void:
	for i in 8:
		var voice := AudioStreamPlayer3D.new()
		voice.name = "Voice%d" % i
		voice.max_distance = 12.0
		voice.unit_size = 3.0
		voice.position.y = 1.3
		add_child(voice)
		voices.append(voice)
	set_process(false)

func set_parameter(key: String, value: float) -> void:
	if parameters.has(key): parameters[key] = clampf(value, 0, 1)
	state_changed.emit()

func set_route(value: String) -> void:
	if value not in ["filter", "pan"]: return
	route = value
	state_changed.emit()

func start() -> void:
	wanted = true
	if sample_cache.size() != 2:
		if preparing: return
		preparing = true
		_worker = Worker.new()
		add_child(_worker)
		_worker.generation_complete.connect(_sample_ready)
		_worker.generation_failed.connect(_sample_failed)
		# Callables use only RefCounted synthesis and PCM, never the scene tree.
		_worker.queue_sound("pad", bake_pad)
		_worker.queue_sound("bell", bake_bell)
		state_changed.emit()
		return
	if bus_name.is_empty(): _make_bus()
	_rng.seed = patch_seed
	_due = [0.0, 1.4, 3.2]
	elapsed = 0
	notes_played = 0
	events.clear()
	playing = true
	_fade_clock = 0
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), false)
	set_process(true)
	state_changed.emit()

func stop(immediate := false) -> void:
	wanted = false
	playing = false
	_fade_clock = 0
	if immediate:
		for voice in voices: voice.stop()
		_gain = -60
		if not bus_name.is_empty(): AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), true)
		set_process(false)
	state_changed.emit()

func new_seed() -> void:
	patch_seed += 1
	_rng.seed = patch_seed
	state_changed.emit()

static func bake_pad() -> AudioStreamWAV:
	return _taper(Pad.generate_note(261.625565, 3.5))

static func bake_bell() -> AudioStreamWAV:
	return _taper(Bell.generate_note(261.625565, .65, 3.0))

static func _taper(stream: AudioStreamWAV) -> AudioStreamWAV:
	# The legacy FM note ends at a finite exponential amplitude. Close both ends.
	var pcm := stream.data
	var count := pcm.size()/2
	var fade := mini(int(stream.mix_rate*.10), count/2)
	for i in fade:
		var gain := float(i)/float(fade)
		pcm.encode_s16(i*2, int(pcm.decode_s16(i*2)*gain))
		var tail := (count-1-i)*2
		pcm.encode_s16(tail, int(pcm.decode_s16(tail)*gain))
	stream.data = pcm
	return stream

func _sample_ready(id: String, stream: AudioStream) -> void:
	sample_cache[id] = stream
	if sample_cache.size() == 2:
		preparing = false
		if wanted and can_process(): start()
		state_changed.emit()

func _sample_failed(_id: String, error: String) -> void:
	preparing = false
	wanted = false
	push_error("Ambient patch: " + error)
	state_changed.emit()

func _make_bus() -> void:
	bus_name = "AmbientPatch_%d" % get_instance_id()
	AudioServer.add_bus()
	var index := AudioServer.bus_count-1
	AudioServer.set_bus_name(index,bus_name)
	AudioServer.set_bus_send(index,"Master")
	AudioServer.set_bus_volume_db(index,-60)
	lowpass = AudioEffectLowPassFilter.new()
	lowpass.resonance = .5
	echo = AudioEffectDelay.new()
	echo.tap1_delay_ms = 730
	echo.tap2_delay_ms = 1130
	echo.tap1_pan = -.5
	echo.tap2_pan = .5
	echo.feedback_active = true
	echo.feedback_delay_ms = 1130
	echo.feedback_lowpass = 2200
	room = AudioEffectReverb.new()
	room.room_size = .84
	room.damping = .64
	pan = AudioEffectPanner.new()
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -6
	capture = AudioEffectCapture.new()
	capture.buffer_length = .12
	for effect in [lowpass,echo,room,pan,limiter,capture]: AudioServer.add_bus_effect(index,effect)
	for voice in voices: voice.bus = bus_name

func _process(delta: float) -> void:
	if bus_name.is_empty(): return
	var target: float = lerpf(-36,-2,parameters.level) if playing else -60.0
	_gain = move_toward(_gain,target,delta*40)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name),_gain)
	if playing:
		elapsed += delta
		advance_score(delta)
	else:
		_fade_clock += delta
		if _fade_clock > 1.6:
			stop(true)
			return
	# Low-frequency control-rate modulation; no per-sample GDScript DSP.
	_ui_clock += delta
	if _ui_clock >= .05:
		_ui_clock = 0
		var lfo := sin(elapsed*TAU/29.0)*float(parameters.drift)
		var cutoff := lerpf(4600,420,parameters.warmth)
		lowpass.cutoff_hz = clampf(cutoff*pow(2,lfo if route == "filter" else 0),180,9000)
		pan.pan = lfo*.65 if route == "pan" and not spatial_orbit else 0.0
		if spatial_orbit:
			for voice in voices:
				voice.position = source_position(int(voice.get_meta("lane",0)))
		echo.tap1_level_db = lerpf(-36,-10,parameters.space)
		echo.tap2_level_db = lerpf(-40,-14,parameters.space)
		echo.feedback_level_db = lerpf(-24,-9,parameters.space)
		room.wet = lerpf(0,.48,parameters.space)
		room.dry = 1.0

func advance_score(delta: float) -> void:
	var rate: float = lerpf(.45,1.7,parameters.rate)
	for lane in 3:
		_due[lane] -= delta*rate
		if _due[lane] > 0: continue
		# A stalled frame never catches up with a burst of overdue notes.
		_due[lane] = PERIODS[lane]
		var accepted := _rng.randf() < float(parameters.density)
		var degree := _rng.randi_range(0,4)
		var midi: int = (60 if lane == 0 else (48 if lane == 1 else 72)) + SCALE[degree]
		if accepted: _play_note(lane,midi)

func _play_note(lane: int, midi: int) -> void:
	var free_voice: AudioStreamPlayer3D
	for voice in voices:
		if not voice.playing: free_voice = voice; break
	if free_voice == null:
		skipped_voices += 1
		return
	free_voice.set_meta("lane",lane)
	free_voice.position = source_position(lane)
	free_voice.stream = sample_cache["pad" if lane == 1 else "bell"]
	free_voice.pitch_scale = pow(2.0,float(midi-60)/12)
	free_voice.volume_db = -18 if lane == 1 else (-13 if lane == 0 else -18)
	free_voice.play()
	last_midi = midi
	notes_played += 1
	events.append({"time":snappedf(elapsed,.001),"lane":lane,"midi":midi})
	if events.size() > 128: events.pop_front()
	note_started.emit(lane,midi)

func source_position(lane: int) -> Vector3:
	var source := source_positions[clampi(lane,0,2)]
	if spatial_orbit and route == "pan":
		var angle := sin(elapsed*TAU/29.0)*float(parameters.drift)*.65
		return source.rotated(Vector3.UP,angle)
	return source

func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED and is_node_ready(): stop(true)

func _exit_tree() -> void:
	for voice in voices: voice.stop()
	if not bus_name.is_empty():
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0: AudioServer.remove_bus(index)
