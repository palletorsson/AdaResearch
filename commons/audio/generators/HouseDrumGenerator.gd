extends Node

## HouseDrumGenerator - TR-909 Style House Drums
## Classic house and techno drum synthesis based on Roland TR-909 techniques
##
## Key differences from 808/trap:
## - 909 kick: Punchy with noise transient, wave-shaped triangle
## - 909 snare: Snappy with distinct low/high regions
## - 909 hi-hats: Metallic with proper ratios, tight closed, sizzling open
## - Classic rim shot and clap sounds

const SAMPLE_RATE = 44100
const FORMAT = AudioStreamWAV.FORMAT_16_BITS

static var rng = RandomNumberGenerator.new()

static func _create_stream(stereo: bool = false) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = FORMAT
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = stereo
	return stream

# ===== 909 KICK - PUNCHY HOUSE KICK =====

static func create_909_kick(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate classic 909-style house kick with punch and body
	
	Parameters:
	- tune: float (default: 50.0) - Fundamental frequency
	- attack: float (default: 0.5) - Attack punch intensity (0-1)
	- decay: float (default: 0.5) - Decay time multiplier
	- punch: float (default: 0.8) - Click/transient intensity
	"""
	rng.randomize()
	var stream = _create_stream(false)
	
	var tune = params.get("tune", 50.0)
	var attack = params.get("attack", 0.5)
	var decay = params.get("decay", 0.5)
	var punch = params.get("punch", 0.8)
	
	var decay_time = 0.15 + (decay * 0.35)  # 150ms to 500ms
	var buffer_length = decay_time + 0.1
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 2)
	
	var phase = 0.0
	var dt = 1.0 / SAMPLE_RATE
	
	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		
		# Pitch envelope - 909 style fast drop
		var pitch_env = exp(-t * 40.0)  # Very fast pitch drop
		var current_freq = tune + (tune * 4.0 * pitch_env)
		
		# Main oscillator - wave-shaped triangle (sounds almost like sine)
		phase += current_freq * dt
		var triangle = abs(fmod(phase * 2.0, 2.0) - 1.0) * 2.0 - 1.0
		# Wave shape to approach sine
		var body = sin(triangle * PI / 2.0)
		
		# Amplitude envelope - fast attack, controlled decay
		var amp_env = exp(-t / (decay_time * 0.7))
		
		# Noise transient - key 909 characteristic
		var transient = 0.0
		if t < 0.01:  # First 10ms
			var noise = rng.randf_range(-1.0, 1.0)
			var transient_env = (1.0 - t / 0.01)
			transient = noise * transient_env * punch * 0.4
		
		# Click/attack boost
		var click = 0.0
		if t < 0.003:  # First 3ms
			click = sin(t * 8000.0) * (1.0 - t / 0.003) * attack * 0.5
		
		var sample = (body * amp_env * 0.85) + transient + click
		
		# Soft saturation for warmth
		sample = tanh(sample * 1.3) * 0.9
		
		# Fade out to prevent click
		var fade_out = 1.0
		if i > frame_count - 128:
			fade_out = float(frame_count - i) / 128.0
		sample *= fade_out
		
		sample = clamp(sample, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * 32767.0))
	
	stream.data = data
	return stream

# ===== 909 SNARE - SNAPPY HOUSE SNARE =====

static func create_909_snare(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate classic 909-style snare with tone and snappy noise
	
	Parameters:
	- tone: float (default: 0.5) - Balance between body and snap
	- snappy: float (default: 0.7) - High frequency snap intensity
	- decay: float (default: 0.3) - Overall decay time
	- tune: float (default: 180.0) - Body pitch
	"""
	rng.randomize()
	var stream = _create_stream(true)
	
	var tone = params.get("tone", 0.5)
	var snappy = params.get("snappy", 0.7)
	var decay = params.get("decay", 0.3)
	var tune = params.get("tune", 180.0)
	
	var buffer_length = decay + 0.2
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		
		# Body - two resonant frequencies (909 style)
		var body_env = exp(-t / (decay * 0.5))
		var body1 = sin(2.0 * PI * tune * t) * body_env
		var body2 = sin(2.0 * PI * tune * 1.5 * t) * body_env * 0.6
		var body = (body1 + body2) * tone * 0.5
		
		# Noise component - two regions like 909
		var noise = rng.randf_range(-1.0, 1.0)
		
		# Low noise region (body resonance)
		var low_noise_env = exp(-t / (decay * 0.3))
		var low_noise = noise * low_noise_env * 0.3 * (1.0 - snappy * 0.5)
		
		# High noise region (snappy wires) - filtered noise simulation
		var high_noise_env = exp(-t / (decay * 0.7))
		# Simple pseudo-highpass by mixing with previous sample
		var high_noise = noise * high_noise_env * snappy * 0.6
		
		# Transient click
		var click = 0.0
		if t < 0.002:
			click = rng.randf_range(-1.0, 1.0) * (1.0 - t / 0.002) * 0.4
		
		var sample = body + low_noise + high_noise + click
		
		# Slight saturation
		sample = tanh(sample * 1.2)
		
		# Fade out
		var fade_out = 1.0
		if i > frame_count - 128:
			fade_out = float(frame_count - i) / 128.0
		sample *= fade_out
		
		sample = clamp(sample, -1.0, 1.0)
		
		# Stereo spread
		var left = sample
		var right = sample * 0.95
		
		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))
	
	stream.data = data
	return stream

# ===== 909 CLOSED HI-HAT - TIGHT =====

static func create_909_hihat_closed(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate tight 909-style closed hi-hat with metallic character
	
	Parameters:
	- decay: float (default: 0.04) - Short decay time
	- tune: float (default: 1.0) - Pitch multiplier
	- tone: float (default: 0.5) - Brightness
	"""
	rng.randomize()
	var stream = _create_stream(true)
	
	var decay = params.get("decay", 0.04)
	var tune = params.get("tune", 1.0)
	var tone_param = params.get("tone", 0.5)
	
	var buffer_length = max(decay * 4, 0.12)
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	# 909 hi-hat uses 6 square wave oscillators at specific non-harmonic ratios
	# These ratios create the metallic character
	var base_freq = 330.0 * tune
	var ratios = [1.0, 1.342, 1.541, 1.732, 2.0, 2.236]
	
	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		
		var sample = 0.0
		var amp_env = exp(-t / decay)
		
		# Mix of square waves at different ratios
		for j in range(ratios.size()):
			var freq = base_freq * ratios[j]
			# Square wave with slight randomization for more organic sound
			var sq = sign(sin(2.0 * PI * freq * t + rng.randf_range(-0.1, 0.1)))
			# Weight higher partials less
			var weight = 1.0 / (float(j) + 1.0)
			sample += sq * weight
		
		sample *= amp_env / float(ratios.size())
		
		# Bandpass-like filtering (emphasize 7-10kHz region)
		# Simple simulation: add high-frequency noise character
		var noise = rng.randf_range(-0.3, 0.3) * amp_env * tone_param
		sample = sample * 0.4 + noise
		
		# Hard clip for edge
		sample = clamp(sample * 0.6, -1.0, 1.0)
		
		# Stereo
		var left = sample
		var right = sample * 0.92
		
		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))
	
	stream.data = data
	return stream

# ===== 909 OPEN HI-HAT - SIZZLE =====

static func create_909_hihat_open(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate sizzling 909-style open hi-hat
	
	Parameters:
	- decay: float (default: 0.3) - Longer decay for open sound
	- tune: float (default: 1.0) - Pitch multiplier
	"""
	rng.randomize()
	var stream = _create_stream(true)
	
	var decay = params.get("decay", 0.3)
	var tune = params.get("tune", 1.0)
	
	var buffer_length = decay + 0.15
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	var base_freq = 310.0 * tune
	var ratios = [1.0, 1.342, 1.541, 1.732, 2.0, 2.236, 2.561]
	
	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		
		var sample = 0.0
		var amp_env = exp(-t / decay)
		
		for j in range(ratios.size()):
			var freq = base_freq * ratios[j]
			var sq = sign(sin(2.0 * PI * freq * t))
			var weight = 1.0 / (float(j) + 1.0)
			sample += sq * weight
		
		sample *= amp_env / float(ratios.size())
		
		# Add shimmer noise
		var noise = rng.randf_range(-0.4, 0.4) * amp_env
		sample = sample * 0.35 + noise * 0.5
		
		# Fade out smoothly
		var fade_out = 1.0
		if i > frame_count - 256:
			fade_out = float(frame_count - i) / 256.0
		sample *= fade_out
		
		sample = clamp(sample * 0.5, -1.0, 1.0)
		
		var left = sample
		var right = sample * 0.88
		
		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))
	
	stream.data = data
	return stream

# ===== 909 CLAP - LAYERED HAND CLAPS =====

static func create_909_clap(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate classic 909 clap with multiple micro-transients
	
	Parameters:
	- decay: float (default: 0.3) - Reverb tail decay
	- spread: float (default: 0.025) - Spread between clap layers
	"""
	rng.randomize()
	var stream = _create_stream(true)
	
	var decay = params.get("decay", 0.3)
	var spread = params.get("spread", 0.025)
	
	var buffer_length = decay + 0.1
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	# Pre-calculate clap layer timing (4 micro-transients within 30ms)
	var layer_times = [0.0, 0.008, 0.016, 0.024]
	
	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		
		var sample = 0.0
		
		# Multiple hand clap layers
		for layer_t in layer_times:
			var local_t = t - layer_t
			if local_t >= 0.0:
				# Filtered noise burst for each clap
				var noise = rng.randf_range(-1.0, 1.0)
				var layer_env = exp(-local_t / 0.012) * 0.7  # Fast decay per layer
				sample += noise * layer_env
		
		# Overall reverb tail envelope
		var tail_env = exp(-t / decay)
		sample *= tail_env
		
		# Bandpass-like character (mid-high frequencies)
		# Add some tonal coloring
		sample += sin(2.0 * PI * 1500.0 * t) * tail_env * 0.1
		
		sample = tanh(sample * 1.5) * 0.8
		
		# Fade out
		var fade_out = 1.0
		if i > frame_count - 128:
			fade_out = float(frame_count - i) / 128.0
		sample *= fade_out
		
		sample = clamp(sample, -1.0, 1.0)
		
		# Wide stereo for claps
		var pan = rng.randf_range(-0.1, 0.1)
		var left = sample * (1.0 - pan * 0.5)
		var right = sample * (1.0 + pan * 0.5)
		
		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))
	
	stream.data = data
	return stream

# ===== 909 RIM SHOT - CLICK =====

static func create_909_rim(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate classic 909 rim shot click
	
	Parameters:
	- tune: float (default: 800.0) - Rim pitch
	- decay: float (default: 0.05) - Very short decay
	"""
	rng.randomize()
	var stream = _create_stream(true)
	
	var tune = params.get("tune", 800.0)
	var decay = params.get("decay", 0.05)
	
	var buffer_length = decay + 0.05
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		
		var amp_env = exp(-t / decay)
		
		# Two pitched components for the metallic character
		var tone1 = sin(2.0 * PI * tune * t)
		var tone2 = sin(2.0 * PI * tune * 1.5 * t)
		
		# Noise burst for attack
		var noise = 0.0
		if t < 0.003:
			noise = rng.randf_range(-1.0, 1.0) * (1.0 - t / 0.003)
		
		var sample = (tone1 * 0.5 + tone2 * 0.3 + noise * 0.4) * amp_env
		
		sample = clamp(sample * 0.7, -1.0, 1.0)
		
		var left = sample
		var right = sample * 0.95
		
		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))
	
	stream.data = data
	return stream

# ===== SOUND DISPATCHER =====

static func generate_sound(sound_name: String, params: Dictionary = {}) -> AudioStreamWAV:
	"""Generate a sound by name"""
	match sound_name.to_lower():
		"909_kick", "kick", "house_kick":
			return create_909_kick(params)
		"909_snare", "snare", "house_snare":
			return create_909_snare(params)
		"909_hihat_closed", "hihat_closed", "closed_hat":
			return create_909_hihat_closed(params)
		"909_hihat_open", "hihat_open", "open_hat":
			return create_909_hihat_open(params)
		"909_clap", "clap", "house_clap":
			return create_909_clap(params)
		"909_rim", "rim", "rimshot":
			return create_909_rim(params)
		_:
			print("⚠️ HouseDrumGenerator: Unknown sound: ", sound_name)
			return null
