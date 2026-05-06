# LiveAudioEngine.gd
# Real-time audio synthesis engine using AudioStreamGenerator
# Drives the LiveRack with actual audio output

extends Node
class_name LiveAudioEngine

const SAMPLE_RATE = 44100.0
const BUFFER_SIZE = 1024

var rack: Node  # LiveRack instance
var audio_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback

# Timing
var samples_since_step: int = 0
var samples_per_step: int = 0

# Per-channel state
var kick_phase: float = 0.0
var kick_time: float = 999.0  # Time since trigger

var hat_time: float = 999.0
var hat_should_play: bool = false
var hat_is_open: bool = false

var acid_phase: float = 0.0
var acid_time: float = 999.0
var acid_note: int = -1
var acid_target_freq: float = 110.0
var acid_current_freq: float = 110.0
var acid_filter_state: Array = [0.0, 0.0, 0.0]

# Master filter
var master_filter_state: Array = [0.0, 0.0, 0.0, 0.0]

signal audio_level(left: float, right: float)


func _ready():
	_setup_audio()


func _setup_audio():
	# Create generator stream
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.1  # 100ms buffer
	
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = generator
	audio_player.bus = "Master"
	add_child(audio_player)


func set_rack(r: Node):
	rack = r
	if rack:
		rack.step_hit.connect(_on_step)
		_update_timing()


func _update_timing():
	if rack:
		var beats_per_second = rack.bpm / 60.0
		var steps_per_second = beats_per_second * 4  # 16th notes
		samples_per_step = int(SAMPLE_RATE / steps_per_second)


func start():
	if not rack:
		push_error("LiveAudioEngine: No rack set!")
		return
	
	_update_timing()
	audio_player.play()
	playback = audio_player.get_stream_playback()
	set_process(true)
	print("LiveAudioEngine: Started")


func stop():
	audio_player.stop()
	set_process(false)
	print("LiveAudioEngine: Stopped")


func _process(_delta: float):
	if playback == null:
		return
	
	# Fill audio buffer
	var frames_available = playback.get_frames_available()
	if frames_available < 32:
		return
	
	var buffer = PackedVector2Array()
	buffer.resize(frames_available)
	
	for i in range(frames_available):
		var sample = _generate_sample()
		buffer[i] = Vector2(sample, sample)  # Mono for now
		
		samples_since_step += 1
		if samples_since_step >= samples_per_step:
			samples_since_step = 0
			_advance_step()
	
	playback.push_buffer(buffer)


func _advance_step():
	if not rack or not rack.playing:
		return
	
	rack.advance(float(samples_per_step) / SAMPLE_RATE)


func _on_step(step_num: int):
	# Trigger sounds for this step
	_trigger_kick(step_num)
	_trigger_hat(step_num)
	_trigger_acid(step_num)


func _trigger_kick(step_num: int):
	# Four on the floor
	if step_num % 4 == 0 and not rack.channel_mutes.get("kick", false):
		kick_time = 0.0
		kick_phase = 0.0


func _trigger_hat(step_num: int):
	if rack.channel_mutes.get("hats", false):
		return
	
	match rack.hat_pattern:
		0:  # 8th notes
			hat_should_play = step_num % 2 == 0
		1:  # Offbeat
			hat_should_play = step_num % 2 == 1
		2:  # 16th notes
			hat_should_play = true
	
	if hat_should_play:
		hat_time = 0.0
		hat_is_open = step_num % 4 == 2


func _trigger_acid(step_num: int):
	if rack.channel_mutes.get("acid", false):
		return
	
	var pattern = rack.acid_pattern
	if step_num < pattern.size():
		acid_note = pattern[step_num]
		if acid_note != -1:
			acid_target_freq = 440.0 * pow(2.0, (acid_note - 69) / 12.0)
			
			# Check for slide
			var slides = rack.acid_slides
			if step_num < slides.size() and slides[step_num]:
				# Slide - don't reset time, let freq glide
				pass
			else:
				acid_time = 0.0
				acid_phase = 0.0


func _generate_sample() -> float:
	var output = 0.0
	var dt = 1.0 / SAMPLE_RATE
	
	# Kick
	if not rack.channel_mutes.get("kick", false):
		output += _render_kick_sample(dt) * rack.channel_levels.get("kick", 1.0)
	
	# Hats
	if not rack.channel_mutes.get("hats", false):
		output += _render_hat_sample(dt) * rack.channel_levels.get("hats", 0.7)
	
	# Acid
	if not rack.channel_mutes.get("acid", false):
		output += _render_acid_sample(dt) * rack.channel_levels.get("acid", 0.8)
	
	# Master filter
	output = _apply_master_filter(output)
	
	# Master drive
	output = tanh(output * (1.0 + rack.master_drive * 2.0))
	
	return output * 0.7  # Headroom


func _render_kick_sample(dt: float) -> float:
	if kick_time > 0.5:
		return 0.0
	
	kick_time += dt
	
	# 909 kick
	var pitch_env = exp(-kick_time / 0.02)
	var freq = rack.kick_pitch + (150.0 - rack.kick_pitch) * pitch_env
	
	kick_phase += freq * dt
	var body = sin(TAU * kick_phase)
	
	# Click
	var click = sin(TAU * 3000.0 * kick_time) * exp(-kick_time * 50.0) * 0.3
	
	# Envelope
	var env = exp(-kick_time / rack.kick_decay)
	var punch_env = 1.0 + rack.kick_punch * exp(-kick_time * 100.0)
	
	return (body + click) * env * punch_env * 0.9


func _render_hat_sample(dt: float) -> float:
	if hat_time > 0.5:
		return 0.0
	
	hat_time += dt
	
	var decay = 0.3 if hat_is_open else rack.hat_decay
	
	# Metallic oscillators
	var freqs = [204.0, 298.0, 366.0, 522.0, 540.0, 598.0]
	var metallic = 0.0
	for f in freqs:
		metallic += 1.0 if fmod(f * hat_time, 1.0) < 0.5 else -1.0
	metallic /= freqs.size()
	
	# Noise
	var noise = randf_range(-1, 1) * 0.3
	
	var env = exp(-hat_time / decay)
	
	return (metallic * 0.7 + noise) * env * 0.4


func _render_acid_sample(dt: float) -> float:
	if acid_note == -1 or acid_time > 1.0:
		return 0.0
	
	acid_time += dt
	
	# Slide frequency towards target
	var slide_speed = 1.0 / rack.slide_time if rack.slide_time > 0 else 100.0
	acid_current_freq = lerp(acid_current_freq, acid_target_freq, dt * slide_speed * 10.0)
	
	# Oscillator
	acid_phase += acid_current_freq * dt
	var osc = fmod(acid_phase, 1.0) * 2.0 - 1.0
	
	# Check accent for this step
	var is_accent = false
	var accents = rack.acid_accents
	if rack.step < accents.size():
		is_accent = accents[rack.step]
	
	# Filter parameters
	var env_mod = rack.acid_env_mod * (1.4 if is_accent else 1.0)
	var reso = min(rack.acid_resonance + (0.2 if is_accent else 0.0), 0.98)
	var decay = 0.2 * (0.5 if is_accent else 1.0)
	
	# Filter envelope
	var filter_env = exp(-acid_time / decay)
	var filter_freq = rack.acid_cutoff + filter_env * env_mod * 2500.0
	
	# 3-pole 303 filter
	var fc = clamp(filter_freq / SAMPLE_RATE, 0.001, 0.49)
	var g = tan(PI * fc)
	
	var feedback = acid_filter_state[2] * reso * 4.0
	var x = osc - feedback
	
	# Diode clip
	x = _diode_clip(x)
	
	acid_filter_state[0] += g * (x - acid_filter_state[0])
	acid_filter_state[1] += g * (acid_filter_state[0] - acid_filter_state[1])
	acid_filter_state[2] += g * (acid_filter_state[1] - acid_filter_state[2])
	
	var filtered = acid_filter_state[2]
	
	# Amp envelope
	var amp_env = exp(-acid_time / 0.3)
	var accent_boost = 1.2 if is_accent else 1.0
	
	return tanh(filtered * 1.5) * amp_env * accent_boost * 0.6


func _diode_clip(x: float) -> float:
	if x > 0:
		return 1.0 - exp(-x)
	else:
		return -1.0 + exp(x)


func _apply_master_filter(sample: float) -> float:
	var cutoff = 200.0 + rack.master_filter * 10000.0
	var fc = clamp(cutoff / SAMPLE_RATE, 0.001, 0.49)
	var g = tan(PI * fc)
	
	var x = sample
	for i in range(4):
		master_filter_state[i] += g * (x - master_filter_state[i])
		x = master_filter_state[i]
	
	return master_filter_state[3]
