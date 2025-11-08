extends Node

# TrapBeatsGenerator - TR-1000 Style Trap Beats
# BANG HARDER THAN YOUR DAW
#
# Minimal but powerful trap drum generator with classic 808-style sounds
# Optimized for trap, hip-hop, and electronic music production

class_name TrapBeatsGenerator

# Audio constants
const SAMPLE_RATE = 44100
const FORMAT = AudioStreamWAV.FORMAT_16_BITS

# ===== UTILITY METHODS =====

static func _create_rng(seed_value: int = -1) -> RandomNumberGenerator:
	"""Create a RandomNumberGenerator with optional seed"""
	var rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	return rng

static func _create_stream_base(stereo: bool = true) -> AudioStreamWAV:
	"""Create a basic AudioStreamWAV with standard settings"""
	var stream = AudioStreamWAV.new()
	stream.format = FORMAT
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = stereo
	return stream

# ===== 808 KICK - TUNED BASS BOMB =====

static func create_808_kick(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate deep tuned 808 kick with pitch envelope

	Parameters:
	- pitch: float (default: 60.0) - Starting pitch in Hz
	- pitch_decay: float (default: 0.05) - Pitch envelope decay time
	- decay: float (default: 1.2) - Amplitude decay time
	- punch: float (default: 1.5) - Initial transient punch
	- sub_boost: float (default: 0.3) - Sub-bass harmonic boost
	- distortion: float (default: 0.1) - Soft clipping amount
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(false)  # Mono for centered bass

	var pitch = params.get("pitch", 60.0)
	var pitch_decay = params.get("pitch_decay", 0.05)
	var decay = params.get("decay", 1.2)
	var punch = params.get("punch", 1.5)
	var sub_boost = params.get("sub_boost", 0.3)
	var distortion = params.get("distortion", 0.1)

	var buffer_length = max(decay + 0.5, 1.5)
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 2)  # Mono

	# Phase accumulator for proper frequency modulation
	var phase = 0.0
	var dt = 1.0 / SAMPLE_RATE

	# Fade-in duration (to prevent clicks)
	var fade_in_samples = min(64, frame_count / 10)  # ~1.5ms fade-in
	
	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Pitch envelope - exponential decay from starting pitch
		var pitch_env = exp(-t / pitch_decay)
		var current_pitch = pitch * pitch_env + (pitch * 0.2)  # Never goes to zero

		# Accumulate phase based on current frequency
		phase += 2.0 * PI * current_pitch * dt

		# Amplitude envelope with punch
		var amp_env = exp(-t / decay)
		if t < 0.005:  # 5ms punch transient
			amp_env *= punch

		# Fade-in at the beginning to prevent clicks
		var fade_in = 1.0
		if i < fade_in_samples:
			fade_in = float(i) / float(fade_in_samples)
			# Smooth fade-in curve (sine curve)
			fade_in = sin(fade_in * PI * 0.5)
		
		# Fade-out at the end to prevent clicks
		var fade_out = 1.0
		var fade_out_start = frame_count - 128  # Last ~3ms
		if i > fade_out_start:
			var fade_out_progress = float(i - fade_out_start) / 128.0
			fade_out = 1.0 - fade_out_progress
			# Smooth fade-out curve
			fade_out = sin(fade_out * PI * 0.5)

		# Main sine wave oscillator
		var sample = sin(phase) * amp_env

		# Add sub-bass harmonic for depth
		sample += sin(phase * 0.5) * amp_env * sub_boost

		# Soft clipping for analog warmth
		if distortion > 0.0:
			sample = tanh(sample * (1.0 + distortion))

		# Add tiny noise for texture
		sample += rng.randf_range(-0.01, 0.01) * amp_env

		# Apply fade-in and fade-out
		sample *= fade_in * fade_out

		sample = clamp(sample * 0.8, -1.0, 1.0)

		data.encode_s16(i * 2, int(sample * 32767.0))

	stream.data = data
	return stream

# ===== TRAP SNARE - SNAPPY WITH TAIL =====

static func create_trap_snare(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate trap-style snare with tone and noise

	Parameters:
	- pitch: float (default: 200.0) - Snare body pitch
	- snap: float (default: 0.8) - Transient snap intensity
	- tone_decay: float (default: 0.08) - Tone decay time
	- noise_decay: float (default: 0.15) - Noise tail decay
	- brightness: float (default: 0.6) - High frequency content
	- reverb_tail: float (default: 0.3) - Reverb simulation
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var pitch = params.get("pitch", 200.0)
	var snap = params.get("snap", 0.8)
	var tone_decay = params.get("tone_decay", 0.08)
	var noise_decay = params.get("noise_decay", 0.15)
	var brightness = params.get("brightness", 0.6)
	var reverb_tail = params.get("reverb_tail", 0.3)

	var buffer_length = 0.4
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)  # Stereo

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Tone component - pitched resonance
		var tone_env = exp(-t / tone_decay)
		var tone = sin(2.0 * PI * pitch * t) * tone_env * 0.4
		tone += sin(2.0 * PI * pitch * 1.6 * t) * tone_env * 0.2  # Harmonic

		# Noise component - filtered white noise
		var noise_env = exp(-t / noise_decay)
		var noise = rng.randf_range(-1.0, 1.0) * noise_env

		# High-pass filter the noise for brightness
		noise = noise * brightness + (1.0 - brightness) * noise * 0.3

		# Transient snap
		var snap_env = exp(-t / 0.002) * snap
		var snap_component = rng.randf_range(-1.0, 1.0) * snap_env

		# Mix components
		var sample = tone * 0.3 + noise * 0.5 + snap_component * 0.3

		# Reverb tail simulation
		if t > 0.05:
			var reverb = noise * reverb_tail * 0.2
			sample += reverb

		sample = clamp(sample, -1.0, 1.0)

		# Stereo width
		var left = sample
		var right = sample * 0.95

		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))

	stream.data = data
	return stream

# ===== HI-HAT CLOSED - CRISPY =====

static func create_hihat_closed(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate closed hi-hat with metallic character

	Parameters:
	- decay: float (default: 0.05) - Decay time
	- brightness: float (default: 0.8) - Metallic brightness
	- tightness: float (default: 0.9) - How tight/closed
	- pitch: float (default: 8000.0) - Base frequency
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var decay = params.get("decay", 0.05)
	var brightness = params.get("brightness", 0.8)
	var tightness = params.get("tightness", 0.9)
	var pitch = params.get("pitch", 8000.0)

	var buffer_length = max(decay * 3, 0.15)
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Metallic ratios for hi-hat sound
		var ratios = [1.0, 1.47, 1.93, 2.74, 3.46, 4.31]
		var sample = 0.0

		for ratio in ratios:
			var freq = pitch * ratio
			sample += sin(2.0 * PI * freq * t) * (1.0 / ratio)

		# Mix with noise for realistic metal character
		var noise = rng.randf_range(-1.0, 1.0)
		sample = sample * (1.0 - brightness * 0.5) + noise * brightness

		# Tight exponential decay
		var env = exp(-t / (decay * tightness))
		sample *= env

		sample = clamp(sample * 0.3, -1.0, 1.0)

		# Stereo spread
		var left = sample
		var right = sample * 0.9

		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))

	stream.data = data
	return stream

# ===== HI-HAT OPEN - SIZZLE =====

static func create_hihat_open(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate open hi-hat with long sizzle

	Parameters:
	- decay: float (default: 0.3) - Decay time
	- brightness: float (default: 0.85) - Metallic brightness
	- openness: float (default: 0.7) - How open/loose
	- pitch: float (default: 7500.0) - Base frequency
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var decay = params.get("decay", 0.3)
	var brightness = params.get("brightness", 0.85)
	var openness = params.get("openness", 0.7)
	var pitch = params.get("pitch", 7500.0)

	var buffer_length = max(decay * 2, 0.5)
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Metallic ratios
		var ratios = [1.0, 1.47, 1.93, 2.74, 3.46, 4.31, 5.12]
		var sample = 0.0

		for ratio in ratios:
			var freq = pitch * ratio
			sample += sin(2.0 * PI * freq * t) * (1.0 / ratio)

		# More noise for open character
		var noise = rng.randf_range(-1.0, 1.0)
		sample = sample * (1.0 - brightness * 0.6) + noise * brightness

		# Slower decay for open sound
		var env = exp(-t / (decay * (0.5 + openness)))
		sample *= env

		# Add slight modulation for shimmer
		sample *= 1.0 + sin(2.0 * PI * 60.0 * t) * 0.05

		sample = clamp(sample * 0.25, -1.0, 1.0)

		# Wide stereo
		var left = sample
		var right = sample * 0.85

		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))

	stream.data = data
	return stream

# ===== CLAP - LAYERED HAND CLAPS =====

static func create_clap(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate trap clap with layered transients

	Parameters:
	- layers: int (default: 5) - Number of clap layers
	- spread: float (default: 0.015) - Time spread between layers
	- brightness: float (default: 0.7) - High frequency content
	- reverb: float (default: 0.4) - Reverb amount
	- decay: float (default: 0.2) - Tail decay time
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var layers = params.get("layers", 5)
	var spread = params.get("spread", 0.015)
	var brightness = params.get("brightness", 0.7)
	var reverb = params.get("reverb", 0.4)
	var decay = params.get("decay", 0.2)

	var buffer_length = 0.5
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0

		# Layer multiple transients for realistic clap
		for layer in range(layers):
			var offset = layer * spread
			if t >= offset:
				var layer_time = t - offset
				var layer_env = exp(-layer_time / 0.05)

				# Filtered noise burst
				var noise = rng.randf_range(-1.0, 1.0)
				# High-pass character
				noise = noise * brightness + (1.0 - brightness) * noise * 0.2

				sample += noise * layer_env / float(layers)

		# Add reverb tail
		if t > 0.03:
			var reverb_noise = rng.randf_range(-1.0, 1.0)
			var reverb_env = exp(-(t - 0.03) / decay)
			sample += reverb_noise * reverb * reverb_env * 0.3

		sample = clamp(sample, -1.0, 1.0)

		# Stereo width
		var left = sample
		var right = sample * 0.92

		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))

	stream.data = data
	return stream

# ===== 808 RIMSHOT - SHARP CLICK =====

static func create_808_rim(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate 808-style rimshot/rim click

	Parameters:
	- pitch: float (default: 800.0) - Body pitch
	- click: float (default: 0.8) - Click intensity
	- decay: float (default: 0.04) - Decay time
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var pitch = params.get("pitch", 800.0)
	var click = params.get("click", 0.8)
	var decay = params.get("decay", 0.04)

	var buffer_length = 0.15
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Body tone
		var tone_env = exp(-t / decay)
		var tone = sin(2.0 * PI * pitch * t) * tone_env * 0.3

		# Click transient
		var click_env = exp(-t / 0.003)
		var click_sound = rng.randf_range(-1.0, 1.0) * click_env * click

		var sample = tone + click_sound * 0.7
		sample = clamp(sample * 0.6, -1.0, 1.0)

		data.encode_s16(i * 4, int(sample * 32767.0))
		data.encode_s16(i * 4 + 2, int(sample * 32767.0))

	stream.data = data
	return stream

# ===== 808 COWBELL - ICONIC =====

static func create_808_cowbell(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate 808 cowbell sound

	Parameters:
	- pitch: float (default: 540.0) - Fundamental pitch
	- decay: float (default: 0.3) - Decay time
	- metallic: float (default: 0.7) - Metallic character
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(false)

	var pitch = params.get("pitch", 540.0)
	var decay = params.get("decay", 0.3)
	var metallic = params.get("metallic", 0.7)

	var buffer_length = max(decay * 2, 0.5)
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 2)

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Cowbell uses square waves at metallic ratios
		var fundamental = sin(2.0 * PI * pitch * t)
		var harmonic1 = sin(2.0 * PI * pitch * 2.3 * t)
		var harmonic2 = sin(2.0 * PI * pitch * 3.1 * t)

		var sample = fundamental * 0.5
		sample += harmonic1 * 0.3 * metallic
		sample += harmonic2 * 0.2 * metallic

		# Square wave for classic 808 character
		sample = sign(sample) * abs(sample) * 0.7

		# Decay envelope
		var env = exp(-t / decay)
		sample *= env

		sample = clamp(sample * 0.5, -1.0, 1.0)

		data.encode_s16(i * 2, int(sample * 32767.0))

	stream.data = data
	return stream

# ===== TRAP TOM - TUNED DRUM =====

static func create_trap_tom(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate tuned tom/drum hit

	Parameters:
	- pitch: float (default: 120.0) - Tom pitch
	- decay: float (default: 0.4) - Decay time
	- punch: float (default: 1.2) - Attack punch
	- tone: float (default: 0.6) - Tonal vs noisy
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(false)

	var pitch = params.get("pitch", 120.0)
	var decay = params.get("decay", 0.4)
	var punch = params.get("punch", 1.2)
	var tone = params.get("tone", 0.6)

	var buffer_length = max(decay * 2, 0.6)
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 2)

	# Phase accumulator for proper frequency modulation
	var phase = 0.0
	var dt = 1.0 / SAMPLE_RATE

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Pitch envelope - toms have pitch drop
		var pitch_env = exp(-t / 0.08)
		var current_pitch = pitch * (1.0 + pitch_env * 0.5)

		# Accumulate phase based on current frequency
		phase += 2.0 * PI * current_pitch * dt

		# Tone component
		var tone_sample = sin(phase) * tone

		# Noise component for drum head
		var noise = rng.randf_range(-1.0, 1.0) * (1.0 - tone)

		var sample = tone_sample + noise

		# Amplitude envelope with punch
		var amp_env = exp(-t / decay)
		if t < 0.01:
			amp_env *= punch

		sample *= amp_env
		sample = clamp(sample * 0.7, -1.0, 1.0)

		data.encode_s16(i * 2, int(sample * 32767.0))

	stream.data = data
	return stream

# ===== GENERATION ROUTER =====

static func generate_sound(sound_name: String, params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate a trap beat sound by name

	Available sounds:
	- 808_kick, kick, bass_drum
	- trap_snare, snare
	- hihat_closed, hh_closed, closed_hat
	- hihat_open, hh_open, open_hat
	- clap, handclap
	- 808_rim, rimshot, rim
	- 808_cowbell, cowbell
	- trap_tom, tom, drum
	"""
	var normalized_name = sound_name.to_lower().strip_edges()

	match normalized_name:
		"808_kick", "kick", "bass_drum":
			return create_808_kick(params)
		"trap_snare", "snare":
			return create_trap_snare(params)
		"hihat_closed", "hh_closed", "closed_hat":
			return create_hihat_closed(params)
		"hihat_open", "hh_open", "open_hat":
			return create_hihat_open(params)
		"clap", "handclap":
			return create_clap(params)
		"808_rim", "rimshot", "rim":
			return create_808_rim(params)
		"808_cowbell", "cowbell":
			return create_808_cowbell(params)
		"trap_tom", "tom", "drum":
			return create_trap_tom(params)
		_:
			push_warning("TrapBeatsGenerator: Unknown sound name: " + sound_name)
			return null
