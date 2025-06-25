# CustomSoundGenerator.gd
# Standalone sound generation functions for the Sound Designer Interface
# This file contains all the custom sound generation logic separated from the UI

extends RefCounted
class_name CustomSoundGenerator

# Custom sound generation with parameters
static func generate_custom_sound(type: AudioSynthesizer.SoundType, params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 1.0)
	var sample_count = int(AudioSynthesizer.SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	match type:
		AudioSynthesizer.SoundType.BASIC_SINE_WAVE:
			generate_custom_basic_sine_wave(data, sample_count, params)
		AudioSynthesizer.SoundType.PICKUP_MARIO:
			generate_custom_pickup_sound(data, sample_count, params)
		AudioSynthesizer.SoundType.TELEPORT_DRONE:
			generate_custom_teleport_drone(data, sample_count, params)
		AudioSynthesizer.SoundType.LIFT_BASS_PULSE:
			generate_custom_bass_pulse(data, sample_count, params)
		AudioSynthesizer.SoundType.GHOST_DRONE:
			generate_custom_ghost_drone(data, sample_count, params)
		AudioSynthesizer.SoundType.MELODIC_DRONE:
			generate_custom_melodic_drone(data, sample_count, params)
		AudioSynthesizer.SoundType.LASER_SHOT:
			generate_custom_laser_shot(data, sample_count, params)
		AudioSynthesizer.SoundType.POWER_UP_JINGLE:
			generate_custom_power_up_jingle(data, sample_count, params)
		AudioSynthesizer.SoundType.EXPLOSION:
			generate_custom_explosion(data, sample_count, params)
		AudioSynthesizer.SoundType.RETRO_JUMP:
			generate_custom_retro_jump(data, sample_count, params)
		AudioSynthesizer.SoundType.SHIELD_HIT:
			generate_custom_shield_hit(data, sample_count, params)
		AudioSynthesizer.SoundType.AMBIENT_WIND:
			generate_custom_ambient_wind(data, sample_count, params)
		AudioSynthesizer.SoundType.DARK_808_KICK:
			generate_custom_dark_808_kick(data, sample_count, params)
		AudioSynthesizer.SoundType.ACID_606_HIHAT:
			generate_custom_acid_606_hihat(data, sample_count, params)
		AudioSynthesizer.SoundType.DARK_808_SUB_BASS:
			generate_custom_dark_808_sub_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.AMBIENT_AMIGA_DRONE:
			generate_custom_ambient_amiga_drone(data, sample_count, params)
		AudioSynthesizer.SoundType.MOOG_BASS_LEAD:
			generate_custom_moog_bass_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.TB303_ACID_BASS:
			generate_custom_tb303_acid_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO:
			generate_custom_dx7_electric_piano(data, sample_count, params)
		AudioSynthesizer.SoundType.C64_SID_LEAD:
			generate_custom_c64_sid_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.AMIGA_MOD_SAMPLE:
			generate_custom_amiga_mod_sample(data, sample_count, params)
		AudioSynthesizer.SoundType.PPG_WAVE_PAD:
			generate_custom_ppg_wave_pad(data, sample_count, params)
		AudioSynthesizer.SoundType.TR909_KICK:
			generate_custom_tr909_kick(data, sample_count, params)
		AudioSynthesizer.SoundType.JUPITER_8_STRINGS:
			generate_custom_jupiter_8_strings(data, sample_count, params)
		AudioSynthesizer.SoundType.KORG_M1_PIANO:
			generate_custom_korg_m1_piano(data, sample_count, params)
		AudioSynthesizer.SoundType.ARP_2600_LEAD:
			generate_custom_arp_2600_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.SYNARE_3_DISCO_TOM:
			generate_custom_synare_3_disco_tom(data, sample_count, params)
		AudioSynthesizer.SoundType.SYNARE_3_COSMIC_FX:
			generate_custom_synare_3_cosmic_fx(data, sample_count, params)
	
	return create_audio_stream(data)

static func generate_custom_basic_sine_wave(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var frequency = params.get("frequency", 440.0)
	var amplitude = params.get("amplitude", 0.3)
	var fade_in_time = params.get("fade_in_time", 0.05)
	var fade_out_time = params.get("fade_out_time", 0.05)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pure sine wave
		var wave = sin(2.0 * PI * frequency * t)
		
		# Envelope with fade in/out to prevent clicks
		var envelope = 1.0
		if progress < fade_in_time:
			envelope = progress / fade_in_time
		elif progress > (1.0 - fade_out_time):
			envelope = (1.0 - progress) / fade_out_time
		
		# Smooth the envelope with smoothstep
		envelope = envelope * envelope * (3.0 - 2.0 * envelope)
		
		data[i] = wave * envelope * amplitude

static func generate_custom_pickup_sound(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var start_freq = params.get("start_freq", 440.0)
	var end_freq = params.get("end_freq", 880.0)
	var decay_rate = params.get("decay_rate", 8.0)
	var amplitude = params.get("amplitude", 0.3)
	var wave_type = params.get("wave_type", "square")
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = start_freq + (end_freq - start_freq) * progress
		var envelope = exp(-progress * decay_rate)
		
		var wave = 0.0
		match wave_type:
			"sine":
				wave = sin(2.0 * PI * freq * t)
			"square":
				wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
			"sawtooth":
				wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		data[i] = wave * envelope * amplitude

static func generate_custom_teleport_drone(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var base_freq = params.get("base_freq", 220.0)
	var mod_freq = params.get("mod_freq", 0.5)
	var mod_depth = params.get("mod_depth", 30.0)
	var noise_amount = params.get("noise_amount", 0.2)
	var amplitude = params.get("amplitude", 0.2)
	var fade_in_time = params.get("fade_in_time", 0.05)
	var fade_out_time = params.get("fade_out_time", 0.08)
	var wave_type = params.get("wave_type", "sawtooth")
	
	print("🎛️ TELEPORT DRONE GENERATING with wave_type: %s" % wave_type)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = base_freq + sin(2.0 * PI * mod_freq * t) * mod_depth
		
		# Generate different wave types
		var wave = 0.0
		match wave_type:
			"sine":
				wave = sin(2.0 * PI * freq * t)
			"square":
				wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
			"sawtooth":
				wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Add noise
		var noise = (randf() - 0.5) * noise_amount
		
		# Envelope
		var envelope = 0.0
		if progress < fade_in_time:
			envelope = progress / fade_in_time
		elif progress < (1.0 - fade_out_time):
			envelope = 1.0
		else:
			envelope = (1.0 - progress) / fade_out_time
		
		# Smoothstep envelope
		envelope = envelope * envelope * (3.0 - 2.0 * envelope)
		
		data[i] = (wave + noise) * amplitude * envelope

static func generate_custom_bass_pulse(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var base_freq = params.get("base_freq", 60.0)
	var pulse_rate = params.get("pulse_rate", 2.0)
	var decay_rate = params.get("decay_rate", 2.0)
	var amplitude = params.get("amplitude", 0.4)
	var wave_type = params.get("wave_type", "sine")
	
	print("🎛️ BASS PULSE GENERATING with wave_type: %s" % wave_type)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		var pulse = abs(sin(2.0 * PI * pulse_rate * t))
		var envelope = exp(-t * decay_rate)
		
		# Generate different wave types
		var wave = 0.0
		match wave_type:
			"sine":
				wave = sin(2.0 * PI * base_freq * t)
			"square":
				wave = 1.0 if sin(2.0 * PI * base_freq * t) > 0 else -1.0
			"sawtooth":
				wave = 2.0 * (base_freq * t - floor(base_freq * t)) - 1.0
		
		data[i] = wave * pulse * envelope * amplitude

static func generate_custom_ghost_drone(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq1 = params.get("freq1", 110.0)
	var freq2 = params.get("freq2", 165.0)
	var freq3 = params.get("freq3", 220.0)
	var mod_cycles = params.get("mod_cycles", 2.0)
	var amp1 = params.get("amplitude1", 0.4)
	var amp2 = params.get("amplitude2", 0.3)
	var amp3 = params.get("amplitude3", 0.2)
	var overall_amp = params.get("overall_amplitude", 0.15)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		var mod_freq = mod_cycles / duration
		var mod = sin(2.0 * PI * mod_freq * t) * 0.3 + 0.7
		
		var wave = sin(2.0 * PI * freq1 * t) * amp1
		wave += sin(2.0 * PI * freq2 * t) * amp2
		wave += sin(2.0 * PI * freq3 * t) * amp3
		
		data[i] = wave * mod * overall_amp

static func generate_custom_melodic_drone(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var fundamental = params.get("fundamental", 220.0)
	var tremolo_rate = params.get("tremolo_rate", 4.0)
	var tremolo_depth = params.get("tremolo_depth", 0.1)
	var harm1_mult = params.get("harmonic1_mult", 1.0)
	var harm2_mult = params.get("harmonic2_mult", 1.5)
	var harm3_mult = params.get("harmonic3_mult", 2.0)
	var harm4_mult = params.get("harmonic4_mult", 3.0)
	var harm1_amp = params.get("harmonic1_amp", 0.4)
	var harm2_amp = params.get("harmonic2_amp", 0.3)
	var harm3_amp = params.get("harmonic3_amp", 0.2)
	var harm4_amp = params.get("harmonic4_amp", 0.1)
	var overall_amp = params.get("overall_amplitude", 0.2)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		var tremolo = sin(2.0 * PI * tremolo_rate * t) * tremolo_depth + (1.0 - tremolo_depth)
		
		var wave = 0.0
		wave += sin(2.0 * PI * fundamental * harm1_mult * t) * harm1_amp
		wave += sin(2.0 * PI * fundamental * harm2_mult * t) * harm2_amp
		wave += sin(2.0 * PI * fundamental * harm3_mult * t) * harm3_amp
		wave += sin(2.0 * PI * fundamental * harm4_mult * t) * harm4_amp
		
		data[i] = wave * tremolo * overall_amp

static func generate_custom_laser_shot(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var start_freq = params.get("start_freq", 2000.0)
	var end_freq = params.get("end_freq", 100.0)
	var attack_time = params.get("attack_time", 0.05)
	var decay_rate = params.get("decay_rate", 12.0)
	var harmonic_amount = params.get("harmonic_amount", 0.3)
	var amplitude = params.get("amplitude", 0.4)
	var wave_type = params.get("wave_type", "sawtooth")
	
	print("🎛️ LASER SHOT GENERATING with wave_type: %s" % wave_type)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dramatic frequency sweep with curve options
		var freq = start_freq + (end_freq - start_freq) * (progress * progress)
		
		# Sharp attack, exponential decay
		var envelope = exp(-progress * decay_rate) if progress < attack_time else exp(-(progress - attack_time) * (decay_rate * 0.3)) * 0.3
		
		# Main wave
		var wave = 0.0
		match wave_type:
			"sine":
				wave = sin(2.0 * PI * freq * t)
			"square":
				wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
			"sawtooth":
				wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Add harmonics for electric character
		wave += sin(2.0 * PI * freq * 3.0 * t) * harmonic_amount * envelope
		
		data[i] = wave * envelope * amplitude

static func generate_custom_power_up_jingle(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var root_note = params.get("root_note", 262.0)  # C4
	var note_count = params.get("note_count", 4)
	var note_decay = params.get("note_decay", 3.0)
	var harmony_amount = params.get("harmony_amount", 0.2)
	var bell_character = params.get("bell_character", 0.8)
	var amplitude = params.get("amplitude", 0.3)
	var scale_type = params.get("scale_type", "major")
	
	print("🎛️ POWER-UP JINGLE GENERATING with scale: %s" % scale_type)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var note_duration = duration / note_count
	
	# Scale intervals (semitones from root)
	var intervals = []
	match scale_type:
		"major":
			intervals = [0, 4, 7, 12]  # C, E, G, C
		"minor":
			intervals = [0, 3, 7, 12]  # C, Eb, G, C
		"pentatonic":
			intervals = [0, 2, 4, 7]   # C, D, E, G
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var note_index = clamp(int(t / note_duration), 0, note_count - 1)
		var note_t = fmod(t, note_duration) / note_duration
		
		# Calculate frequency from interval
		var semitone_offset = intervals[note_index] if note_index < intervals.size() else intervals[-1]
		var freq = root_note * pow(2.0, semitone_offset / 12.0)
		
		# Bell-like envelope for each note
		var envelope = exp(-note_t * note_decay) * sin(PI * note_t) * bell_character
		
		# Clean sine wave with harmonics
		var wave = sin(2.0 * PI * freq * t)
		wave += sin(2.0 * PI * freq * 2.0 * t) * harmony_amount  # Octave
		
		data[i] = wave * envelope * amplitude

static func generate_custom_explosion(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var low_rumble_freq = params.get("low_rumble_freq", 30.0)
	var mid_crack_freq = params.get("mid_crack_freq", 400.0)
	var high_sizzle_freq = params.get("high_sizzle_freq", 4000.0)
	var low_decay = params.get("low_decay", 1.5)
	var mid_decay = params.get("mid_decay", 8.0)
	var high_decay = params.get("high_decay", 15.0)
	var low_amount = params.get("low_amount", 0.6)
	var mid_amount = params.get("mid_amount", 0.4)
	var high_amount = params.get("high_amount", 0.3)
	var amplitude = params.get("amplitude", 0.5)
	
	print("🎛️ EXPLOSION GENERATING multi-band synthesis")
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Low rumble - modulated sine
		var low_freq = low_rumble_freq + sin(2.0 * PI * 0.5 * t) * (low_rumble_freq * 0.5)
		var low_envelope = exp(-progress * low_decay)
		var low_wave = sin(2.0 * PI * low_freq * t) * low_envelope * low_amount
		
		# Mid crack - modulated sawtooth
		var mid_freq = mid_crack_freq + sin(2.0 * PI * 3.0 * t) * (mid_crack_freq * 0.5)
		var mid_envelope = exp(-progress * mid_decay)
		var mid_wave = (2.0 * (mid_freq * t - floor(mid_freq * t)) - 1.0) * mid_envelope * mid_amount
		
		# High sizzle - complex noise simulation
		var high_noise = sin(t * high_sizzle_freq) * 0.4 + sin(t * high_sizzle_freq * 1.7) * 0.3 + sin(t * high_sizzle_freq * 2.3) * 0.2
		var high_envelope = exp(-progress * high_decay)
		var high_wave = high_noise * high_envelope * high_amount
		
		data[i] = (low_wave + mid_wave + high_wave) * amplitude

static func generate_custom_retro_jump(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var start_freq = params.get("start_freq", 150.0)
	var peak_freq = params.get("peak_freq", 400.0)
	var curve_amount = params.get("curve_amount", 0.7)
	var attack_time = params.get("attack_time", 0.05)
	var decay_rate = params.get("decay_rate", 4.0)
	var duty_cycle = params.get("duty_cycle", 0.5)
	var duty_mod_rate = params.get("duty_mod_rate", 2.0)
	var amplitude = params.get("amplitude", 0.35)
	var wave_type = params.get("wave_type", "square")
	
	print("🎛️ RETRO JUMP GENERATING with wave_type: %s" % wave_type)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Rising frequency curve
		var freq = start_freq + (peak_freq - start_freq) * sin(PI * progress * curve_amount)
		
		# Retro-style envelope
		var envelope = exp(-progress * decay_rate) if progress < attack_time else exp(-(progress - attack_time) * (decay_rate * 0.5)) * 0.8
		
		# Generate wave with dynamic duty cycle
		var wave = 0.0
		match wave_type:
			"sine":
				wave = sin(2.0 * PI * freq * t)
			"square":
				var dynamic_duty = duty_cycle + sin(2.0 * PI * duty_mod_rate * t) * 0.1
				var phase = fmod(freq * t, 1.0)
				wave = 1.0 if phase < dynamic_duty else -1.0
			"sawtooth":
				wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		data[i] = wave * envelope * amplitude

static func generate_custom_shield_hit(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var main_freq = params.get("main_freq", 800.0)
	var ring_freq = params.get("ring_freq", 60.0)
	var impact_freq = params.get("impact_freq", 1200.0)
	var decay_rate = params.get("decay_rate", 6.0)
	var ring_amount = params.get("ring_amount", 0.5)
	var harmonic_amount = params.get("harmonic_amount", 0.4)
	var impact_amount = params.get("impact_amount", 0.8)
	var amplitude = params.get("amplitude", 0.3)
	
	print("🎛️ SHIELD HIT GENERATING with ring modulation")
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Sharp metallic attack, ringing decay
		var envelope = exp(-progress * decay_rate)
		
		# Ring modulated sine wave for metallic character
		var carrier = sin(2.0 * PI * main_freq * t)
		var modulator = sin(2.0 * PI * ring_freq * t) * ring_amount + (1.0 - ring_amount)
		var ring_mod = carrier * modulator
		
		# Add harmonic resonances
		ring_mod += sin(2.0 * PI * main_freq * 1.5 * t) * harmonic_amount * envelope
		ring_mod += sin(2.0 * PI * main_freq * 2.0 * t) * (harmonic_amount * 0.5) * envelope
		
		# Add initial impact "clank"
		var impact = exp(-progress * 50.0) * (sin(2.0 * PI * impact_freq * t) * impact_amount)
		
		data[i] = (ring_mod * envelope + impact) * amplitude

static func generate_custom_ambient_wind(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var noise_density = params.get("noise_density", 4)
	var filter_cutoff = params.get("filter_cutoff", 0.7)
	var gust_rate1 = params.get("gust_rate1", 0.2)
	var gust_rate2 = params.get("gust_rate2", 0.07)
	var tonal_freq1 = params.get("tonal_freq1", 80.0)
	var tonal_freq2 = params.get("tonal_freq2", 120.0)
	var tonal_amount = params.get("tonal_amount", 0.1)
	var amplitude = params.get("amplitude", 0.2)
	
	print("🎛️ AMBIENT WIND GENERATING with noise density: %d" % noise_density)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# Generate pseudo-random noise using multiple sine waves
		var noise = 0.0
		for n in range(noise_density):
			var freq = 100.0 + n * 150.0 + n * n * 50.0  # Varying frequencies
			noise += sin(t * freq) * (1.0 / (n + 1))  # Decreasing amplitude
		
		# Simple low-pass filter simulation
		var filtered_noise = noise * filter_cutoff
		
		# Slow amplitude modulation for wind gusts
		var gust_mod1 = sin(2.0 * PI * gust_rate1 * t) * 0.3 + 0.7
		var gust_mod2 = sin(2.0 * PI * gust_rate2 * t) * 0.2 + 0.8
		var modulation = gust_mod1 * gust_mod2
		
		# Add subtle tonal elements (wind through objects)
		var tonal = sin(2.0 * PI * tonal_freq1 * t) * tonal_amount + sin(2.0 * PI * tonal_freq2 * t) * (tonal_amount * 0.5)
		
		data[i] = (filtered_noise + tonal) * modulation * amplitude

static func create_audio_stream(data: PackedFloat32Array) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = AudioSynthesizer.SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED  # No looping for real-time generation
	
	var byte_array = PackedByteArray()
	byte_array.resize(data.size() * 2)
	
	for i in range(data.size()):
		var sample = int(clamp(data[i], -1.0, 1.0) * 32767.0)
		var byte_index = i * 2
		
		byte_array[byte_index] = sample & 0xFF
		byte_array[byte_index + 1] = (sample >> 8) & 0xFF
	
	stream.data = byte_array
	return stream

static func generate_custom_dark_808_kick(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var start_freq = params.get("start_freq", 60.0)
	var end_freq = params.get("end_freq", 35.0)
	var decay_rate = params.get("decay_rate", 4.0)
	var click_freq = params.get("click_freq", 1200.0)
	var click_decay = params.get("click_decay", 80.0)
	var amplitude = params.get("amplitude", 0.7)
	var saturation = params.get("saturation", 1.5)
	
	print("🎛️ DARK 808 KICK GENERATING with pitch sweep")
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Exponential pitch envelope from start_freq to end_freq
		var freq = start_freq * pow(end_freq / start_freq, progress)
		
		# Amplitude envelope with fast decay
		var envelope = exp(-progress * decay_rate)
		
		# Main 808 body - sine wave for pure sub bass
		var main_wave = sin(2.0 * PI * freq * t)
		
		# Add click attack for punch
		var click_envelope = exp(-progress * click_decay)
		var click_wave = sin(2.0 * PI * click_freq * t) * click_envelope * 0.3
		
		# Combine and apply saturation for darker character
		var combined = (main_wave * envelope + click_wave) * saturation
		
		# Soft clipping saturation
		combined = tanh(combined)
		
		data[i] = combined * amplitude

static func generate_custom_acid_606_hihat(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var filter_start_freq = params.get("filter_start_freq", 8000.0)
	var filter_sweep = params.get("filter_sweep", 3000.0)
	var metallic_freq = params.get("metallic_freq", 12000.0)
	var decay_rate = params.get("decay_rate", 15.0)
	var noise_intensity = params.get("noise_intensity", 2.0)
	var ring_amount = params.get("ring_amount", 0.2)
	var amplitude = params.get("amplitude", 0.3)
	
	print("🎛️ ACID 606 HIHAT GENERATING with filter sweep")
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Generate noise using multiple sine waves
		var noise = 0.0
		for n in range(8):
			var freq = 1000.0 + n * 800.0
			noise += sin(t * freq + n) * (1.0 / (n + 1))
		noise *= noise_intensity
		
		# Envelope with sharp attack and exponential decay
		var envelope = exp(-progress * decay_rate)
		
		# Sweeping filter simulation (reduces high frequencies over time)
		var filter_freq = filter_start_freq - (filter_sweep * progress)
		var filter_factor = clamp(filter_freq / 8000.0, 0.2, 1.0)
		
		# Add metallic ring modulation for 606 character
		var ring_mod = sin(2.0 * PI * metallic_freq * t) * ring_amount + (1.0 - ring_amount)
		
		# Apply filter and ring modulation
		var filtered_noise = noise * filter_factor * ring_mod
		
		data[i] = filtered_noise * envelope * amplitude

static func generate_custom_dark_808_sub_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var base_freq = params.get("base_freq", 35.0)
	var modulation_freq = params.get("modulation_freq", 0.3)
	var modulation_depth = params.get("modulation_depth", 5.0)
	var harmonic2_level = params.get("harmonic2_level", 0.1)
	var harmonic3_level = params.get("harmonic3_level", 0.05)
	var attack_time = params.get("attack_time", 8.0)
	var decay_rate = params.get("decay_rate", 0.5)
	var amplitude = params.get("amplitude", 0.5)
	
	print("🎛️ DARK 808 SUB BASS GENERATING with slow modulation")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Slow frequency modulation for movement
		var mod_wave = sin(2.0 * PI * modulation_freq * t)
		var freq = base_freq + mod_wave * modulation_depth
		
		# Long attack envelope followed by slow decay
		var envelope = 1.0
		if t < attack_time:
			envelope = t / attack_time
		else:
			envelope = exp(-(t - attack_time) * decay_rate)
		
		# Fundamental frequency
		var fundamental = sin(2.0 * PI * freq * t)
		
		# Add harmonics for richness
		var harmonic2 = sin(2.0 * PI * freq * 2.0 * t) * harmonic2_level
		var harmonic3 = sin(2.0 * PI * freq * 3.0 * t) * harmonic3_level
		
		var combined = fundamental + harmonic2 + harmonic3
		
		data[i] = combined * envelope * amplitude

static func generate_custom_ambient_amiga_drone(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq1_fundamental = params.get("freq1_fundamental", 45.0)
	var freq2_octave = params.get("freq2_octave", 90.0)
	var freq3_fifth = params.get("freq3_fifth", 67.5)
	var modulation_freq = params.get("modulation_freq", 0.13)
	var modulation_depth = params.get("modulation_depth", 0.3)
	var modulation_offset = params.get("modulation_offset", 0.7)
	var layer1_level = params.get("layer1_level", 0.5)
	var layer2_level = params.get("layer2_level", 0.3)
	var layer3_level = params.get("layer3_level", 0.2)
	var detune_amount = params.get("detune_amount", 0.7)
	var detune_level = params.get("detune_level", 0.1)
	var amplitude = params.get("amplitude", 0.3)
	
	print("🎛️ AMBIENT AMIGA DRONE GENERATING multi-layer synthesis")
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# Slow modulation for organic movement
		var mod_wave = sin(2.0 * PI * modulation_freq * t) * modulation_depth + modulation_offset
		
		# Layer 1: Fundamental frequency
		var layer1 = sin(2.0 * PI * freq1_fundamental * t) * layer1_level
		
		# Layer 2: Octave with slight modulation
		var layer2 = sin(2.0 * PI * freq2_octave * mod_wave * t) * layer2_level
		
		# Layer 3: Fifth with different modulation phase
		var mod_wave_offset = sin(2.0 * PI * modulation_freq * t + PI * 0.3) * modulation_depth + modulation_offset
		var layer3 = sin(2.0 * PI * freq3_fifth * mod_wave_offset * t) * layer3_level
		
		# Add detuned layer for Amiga-style richness
		var detune_freq = freq1_fundamental + detune_amount
		var detune_layer = sin(2.0 * PI * detune_freq * t) * detune_level
		
		# Combine all layers
		var combined = layer1 + layer2 + layer3 + detune_layer
		
		# Apply slow envelope for fade in/out
		var progress = float(i) / sample_count
		var envelope = 1.0
		if progress < 0.1:
			envelope = progress / 0.1
		elif progress > 0.9:
			envelope = (1.0 - progress) / 0.1
		
		data[i] = combined * envelope * amplitude

static func generate_custom_moog_bass_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var osc1_freq = params.get("osc1_freq", 110.0)
	var osc2_freq = params.get("osc2_freq", 220.0)
	var osc2_detune = params.get("osc2_detune", 0.3)
	var filter_cutoff = params.get("filter_cutoff", 2000.0)
	var filter_resonance = params.get("filter_resonance", 0.7)
	var filter_env_amount = params.get("filter_env_amount", 0.8)
	var amp_attack = params.get("amp_attack", 0.01)
	var amp_decay = params.get("amp_decay", 0.3)
	var amp_sustain = params.get("amp_sustain", 0.7)
	var amp_release = params.get("amp_release", 1.0)
	var portamento = params.get("portamento", 0.1)
	var wave_type = params.get("wave_type", "sawtooth")
	var amplitude = params.get("amplitude", 0.4)
	
	print("🎛️ MOOG BASS LEAD GENERATING with wave_type: %s" % wave_type)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dual oscillator setup with detuning
		var detune_freq = osc2_freq + osc2_detune
		
		# Generate different wave types
		var osc1_wave = 0.0
		var osc2_wave = 0.0
		match wave_type:
			"sine":
				osc1_wave = sin(2.0 * PI * osc1_freq * t)
				osc2_wave = sin(2.0 * PI * detune_freq * t)
			"square":
				osc1_wave = 1.0 if sin(2.0 * PI * osc1_freq * t) > 0 else -1.0
				osc2_wave = 1.0 if sin(2.0 * PI * detune_freq * t) > 0 else -1.0
			"triangle":
				var phase1 = fmod(osc1_freq * t, 1.0)
				var phase2 = fmod(detune_freq * t, 1.0)
				osc1_wave = 4.0 * abs(phase1 - 0.5) - 1.0
				osc2_wave = 4.0 * abs(phase2 - 0.5) - 1.0
			"sawtooth":
				osc1_wave = 2.0 * (osc1_freq * t - floor(osc1_freq * t)) - 1.0
				osc2_wave = 2.0 * (detune_freq * t - floor(detune_freq * t)) - 1.0
		
		# Mix oscillators
		var mixed = osc1_wave * 0.6 + osc2_wave * 0.4
		
		# Moog ladder filter simulation
		var filter_env = exp(-progress * 2.0) * filter_env_amount + (1.0 - filter_env_amount)
		var cutoff_mod = filter_cutoff * filter_env
		var filter_factor = cutoff_mod / 8000.0
		var filtered = mixed * filter_factor * (1.0 + filter_resonance * filter_env)
		
		# ADSR envelope
		var envelope = 1.0
		var attack_samples = amp_attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = amp_decay * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - amp_release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - amp_sustain)
		elif i < release_start:
			envelope = amp_sustain
		else:
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = amp_sustain * (1.0 - release_progress)
		
		data[i] = filtered * envelope * amplitude

static func generate_custom_tb303_acid_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var base_freq = params.get("base_freq", 82.4)
	var filter_cutoff = params.get("filter_cutoff", 800.0)
	var filter_resonance = params.get("filter_resonance", 0.85)
	var filter_env_mod = params.get("filter_env_mod", 0.9)
	var accent_amount = params.get("accent_amount", 0.6)
	var slide_time = params.get("slide_time", 0.2)
	var decay_time = params.get("decay_time", 0.8)
	var distortion = params.get("distortion", 0.3)
	var wave_type = params.get("wave_type", "sawtooth")
	var amplitude = params.get("amplitude", 0.3)
	
	print("🎛️ TB-303 ACID BASS GENERATING with wave_type: %s" % wave_type)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Generate wave
		var wave = 0.0
		match wave_type:
			"sawtooth":
				wave = 2.0 * (base_freq * t - floor(base_freq * t)) - 1.0
			"square":
				wave = 1.0 if sin(2.0 * PI * base_freq * t) > 0 else -1.0
		
		# Characteristic 303 filter sweep
		var filter_sweep = sin(2.0 * PI * 0.5 * t) * filter_env_mod
		var dynamic_cutoff = filter_cutoff * (1.0 + filter_sweep)
		var filter_factor = dynamic_cutoff / 4000.0
		var filtered = wave * filter_factor * (1.0 + filter_resonance)
		
		# Add distortion for grit
		filtered = tanh(filtered * (1.0 + distortion))
		
		# Envelope with accent
		var envelope = exp(-progress / decay_time * 5.0)
		var accent = 1.0 + accent_amount * exp(-progress * 20.0)
		
		data[i] = filtered * envelope * accent * amplitude

static func generate_custom_dx7_electric_piano(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var carrier_freq = params.get("carrier_freq", 220.0)
	var modulator_ratio = params.get("modulator_ratio", 2.0)
	var fm_index = params.get("fm_index", 3.0)
	var mod_env_attack = params.get("mod_env_attack", 0.01)
	var mod_env_decay = params.get("mod_env_decay", 0.3)
	var mod_env_sustain = params.get("mod_env_sustain", 0.2)
	var mod_env_release = params.get("mod_env_release", 1.0)
	var carrier_attack = params.get("carrier_attack", 0.01)
	var carrier_decay = params.get("carrier_decay", 0.5)
	var carrier_sustain = params.get("carrier_sustain", 0.3)
	var carrier_release = params.get("carrier_release", 2.0)
	var velocity_sensitivity = params.get("velocity_sensitivity", 0.7)
	var amplitude = params.get("amplitude", 0.4)
	
	print("🎛️ DX7 ELECTRIC PIANO GENERATING FM synthesis")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Modulator envelope (controls FM index)
		var mod_envelope = 1.0
		var mod_attack_samples = mod_env_attack * AudioSynthesizer.SAMPLE_RATE
		var mod_decay_samples = mod_env_decay * AudioSynthesizer.SAMPLE_RATE
		var mod_release_start = (1.0 - mod_env_release / duration) * sample_count
		
		if i < mod_attack_samples:
			mod_envelope = float(i) / mod_attack_samples
		elif i < mod_attack_samples + mod_decay_samples:
			var decay_progress = (i - mod_attack_samples) / mod_decay_samples
			mod_envelope = 1.0 - decay_progress * (1.0 - mod_env_sustain)
		elif i < mod_release_start:
			mod_envelope = mod_env_sustain
		else:
			var release_progress = (i - mod_release_start) / (sample_count - mod_release_start)
			mod_envelope = mod_env_sustain * (1.0 - release_progress)
		
		# Carrier envelope
		var carrier_envelope = 1.0
		var carr_attack_samples = carrier_attack * AudioSynthesizer.SAMPLE_RATE
		var carr_decay_samples = carrier_decay * AudioSynthesizer.SAMPLE_RATE
		var carr_release_start = (1.0 - carrier_release / duration) * sample_count
		
		if i < carr_attack_samples:
			carrier_envelope = float(i) / carr_attack_samples
		elif i < carr_attack_samples + carr_decay_samples:
			var decay_progress = (i - carr_attack_samples) / carr_decay_samples
			carrier_envelope = 1.0 - decay_progress * (1.0 - carrier_sustain)
		elif i < carr_release_start:
			carrier_envelope = carrier_sustain
		else:
			var release_progress = (i - carr_release_start) / (sample_count - carr_release_start)
			carrier_envelope = carrier_sustain * (1.0 - release_progress)
		
		# FM synthesis
		var modulator_freq = carrier_freq * modulator_ratio
		var modulator = sin(2.0 * PI * modulator_freq * t) * fm_index * mod_envelope
		var carrier = sin(2.0 * PI * carrier_freq * t + modulator)
		
		data[i] = carrier * carrier_envelope * amplitude * velocity_sensitivity

static func generate_custom_c64_sid_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var base_freq = params.get("base_freq", 440.0)
	var pulse_width = params.get("pulse_width", 0.25)
	var pwm_rate = params.get("pwm_rate", 6.0)
	var pwm_depth = params.get("pwm_depth", 0.3)
	var filter_cutoff = params.get("filter_cutoff", 2000.0)
	var filter_resonance = params.get("filter_resonance", 0.6)
	var ring_mod_amount = params.get("ring_mod_amount", 0.2)
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.2)
	var sustain = params.get("sustain", 0.5)
	var release = params.get("release", 0.5)
	var vibrato_rate = params.get("vibrato_rate", 5.0)
	var vibrato_depth = params.get("vibrato_depth", 0.1)
	var amplitude = params.get("amplitude", 0.35)
	
	print("🎛️ C64 SID LEAD GENERATING with PWM")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Vibrato
		var vibrato = sin(2.0 * PI * vibrato_rate * t) * vibrato_depth
		var mod_freq = base_freq * (1.0 + vibrato)
		
		# Pulse width modulation
		var dynamic_pw = pulse_width + sin(2.0 * PI * pwm_rate * t) * pwm_depth
		dynamic_pw = clamp(dynamic_pw, 0.1, 0.9)
		
		# Generate pulse wave
		var phase = fmod(mod_freq * t, 1.0)
		var pulse = 1.0 if phase < dynamic_pw else -1.0
		
		# Ring modulation for SID character
		var ring_freq = base_freq * 1.5
		var ring_mod = sin(2.0 * PI * ring_freq * t) * ring_mod_amount + (1.0 - ring_mod_amount)
		
		# Simple resonant filter
		var filter_factor = filter_cutoff / 8000.0
		var filtered = pulse * filter_factor * (1.0 + filter_resonance)
		
		# ADSR envelope
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		elif i < release_start:
			envelope = sustain
		else:
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = sustain * (1.0 - release_progress)
		
		data[i] = filtered * ring_mod * envelope * amplitude

static func generate_custom_amiga_mod_sample(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var sample_rate = params.get("sample_rate", 22050)
	var base_freq = params.get("base_freq", 261.6)
	var finetune = params.get("finetune", 0.0)
	var loop_start = params.get("loop_start", 0.1)
	var loop_length = params.get("loop_length", 0.5)
	var paula_filtering = params.get("paula_filtering", 0.7)
	var bit_crush = params.get("bit_crush", 8)
	var wave_type = params.get("wave_type", "sawtooth")
	var amplitude = params.get("amplitude", 0.8)
	
	print("🎛️ AMIGA MOD SAMPLE GENERATING with wave_type: %s" % wave_type)
	
	# Apply finetune (semitone adjustment)
	var tuned_freq = base_freq * pow(2.0, finetune / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Generate base waveform
		var wave = 0.0
		match wave_type:
			"sawtooth":
				wave = 2.0 * (tuned_freq * t - floor(tuned_freq * t)) - 1.0
			"square":
				wave = 1.0 if sin(2.0 * PI * tuned_freq * t) > 0 else -1.0
			"triangle":
				var phase = fmod(tuned_freq * t, 1.0)
				wave = 4.0 * abs(phase - 0.5) - 1.0
			"noise":
				wave = sin(tuned_freq * t * 17.0) * 0.4 + sin(tuned_freq * t * 23.0) * 0.3 + sin(tuned_freq * t * 31.0) * 0.2
		
		# Paula chip filtering (simple low-pass for warmth)
		var filtered = wave * paula_filtering + wave * (1.0 - paula_filtering) * 0.3
		
		# Bit crushing simulation
		var quantization = pow(2, bit_crush - 1)
		var crushed = floor(filtered * quantization) / quantization
		
		# Simple looping with crossfade
		var loop_start_sample = loop_start * sample_count
		var loop_end_sample = loop_start_sample + loop_length * sample_count
		
		if progress > loop_start and progress < (loop_start + loop_length):
			# We're in the loop section - add slight modulation
			crushed *= 0.98 + 0.02 * sin(2.0 * PI * 0.1 * t)
		elif progress > (loop_start + loop_length):
			# Fade out after loop
			var fade = (1.0 - progress) / (1.0 - (loop_start + loop_length))
			crushed *= fade
		
		data[i] = crushed * amplitude

static func generate_custom_ppg_wave_pad(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var wavetable_pos = params.get("wavetable_pos", 0.3)
	var filter_cutoff = params.get("filter_cutoff", 1200.0)
	var filter_resonance = params.get("filter_resonance", 0.4)
	var lfo_rate = params.get("lfo_rate", 0.5)
	var lfo_depth = params.get("lfo_depth", 0.2)
	var attack = params.get("attack", 1.0)
	var decay = params.get("decay", 0.5)
	var sustain = params.get("sustain", 0.7)
	var release = params.get("release", 2.0)
	var amplitude = params.get("amplitude", 0.4)
	
	print("🎛️ PPG WAVE PAD GENERATING wavetable synthesis")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Wavetable position (morphing between waveforms)
		var base_freq = 220.0
		var wave1 = sin(2.0 * PI * base_freq * t)  # Sine
		var wave2 = 2.0 * (base_freq * t - floor(base_freq * t)) - 1.0  # Sawtooth
		var wave = wave1 * (1.0 - wavetable_pos) + wave2 * wavetable_pos
		
		# LFO modulation
		var lfo = sin(2.0 * PI * lfo_rate * t) * lfo_depth
		wave *= (1.0 + lfo)
		
		# Simple filter simulation
		var filter_factor = filter_cutoff / 4000.0
		wave *= filter_factor * (1.0 + filter_resonance * 0.3)
		
		# ADSR envelope
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		elif i < release_start:
			envelope = sustain
		else:
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = sustain * (1.0 - release_progress)
		
		data[i] = wave * envelope * amplitude

static func generate_custom_tr909_kick(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var pitch = params.get("pitch", 60.0)
	var pitch_decay = params.get("pitch_decay", 0.05)
	var click_amount = params.get("click_amount", 0.3)
	var attack = params.get("attack", 0.001)
	var decay = params.get("decay", 0.3)
	var tone = params.get("tone", 0.5)
	var amplitude = params.get("amplitude", 0.8)
	
	print("🎛️ TR-909 KICK GENERATING drum synthesis")
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pitch envelope (starts high, drops quickly)
		var pitch_envelope = exp(-progress / pitch_decay)
		var freq = pitch * (1.0 + pitch_envelope * 2.0)
		
		# Generate kick wave (sine with click)
		var kick = sin(2.0 * PI * freq * t)
		
		# Add click attack
		var click = sin(2.0 * PI * 2000.0 * t) * exp(-progress * 50.0) * click_amount
		
		# Tone shaping
		var shaped = kick * tone + (kick * kick * kick) * (1.0 - tone)
		
		# Amplitude envelope
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		if i < attack_samples:
			envelope = float(i) / attack_samples
		else:
			envelope = exp(-(progress - attack) / decay)
		
		data[i] = (shaped + click) * envelope * amplitude

static func generate_custom_jupiter_8_strings(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var fundamental = params.get("fundamental", 220.0)
	var chorus_rate = params.get("chorus_rate", 1.2)
	var chorus_depth = params.get("chorus_depth", 0.3)
	var filter_cutoff = params.get("filter_cutoff", 2000.0)
	var filter_resonance = params.get("filter_resonance", 0.2)
	var attack = params.get("attack", 0.5)
	var decay = params.get("decay", 0.3)
	var sustain = params.get("sustain", 0.8)
	var release = params.get("release", 1.5)
	var amplitude = params.get("amplitude", 0.3)
	
	print("🎛️ JUPITER-8 STRINGS GENERATING ensemble synthesis")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Multiple oscillators for richness
		var wave = 0.0
		wave += sin(2.0 * PI * fundamental * t) * 0.3
		wave += sin(2.0 * PI * fundamental * 1.5 * t) * 0.2  # Fifth
		wave += sin(2.0 * PI * fundamental * 2.0 * t) * 0.15  # Octave
		wave += sin(2.0 * PI * fundamental * 3.0 * t) * 0.1   # Higher harmonics
		
		# Chorus effect simulation
		var chorus = sin(2.0 * PI * chorus_rate * t) * chorus_depth + 1.0
		wave *= chorus
		
		# Filter simulation
		var filter_factor = filter_cutoff / 4000.0
		wave *= filter_factor * (1.0 + filter_resonance * 0.2)
		
		# ADSR envelope
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		elif i < release_start:
			envelope = sustain
		else:
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = sustain * (1.0 - release_progress)
		
		data[i] = wave * envelope * amplitude

static func generate_custom_korg_m1_piano(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var frequency = params.get("frequency", 261.6)
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.8)
	var sustain = params.get("sustain", 0.6)
	var release = params.get("release", 2.0)
	var brightness = params.get("brightness", 0.7)
	var stereo_width = params.get("stereo_width", 0.5)
	var amplitude = params.get("amplitude", 0.5)
	
	print("🎛️ KORG M1 PIANO GENERATING digital piano synthesis")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Digital piano harmonics
		var wave = 0.0
		wave += sin(2.0 * PI * frequency * t) * 0.5
		wave += sin(2.0 * PI * frequency * 2.0 * t) * 0.2 * brightness
		wave += sin(2.0 * PI * frequency * 3.0 * t) * 0.1 * brightness
		wave += sin(2.0 * PI * frequency * 4.0 * t) * 0.05 * brightness
		
		# Stereo width simulation (slight detuning)
		var detune = sin(2.0 * PI * 0.1 * t) * stereo_width * 0.01
		var detuned_freq = frequency * (1.0 + detune)
		wave += sin(2.0 * PI * detuned_freq * t) * 0.1 * stereo_width
		
		# ADSR envelope
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		elif i < release_start:
			envelope = sustain
		else:
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = sustain * (1.0 - release_progress)
		
		data[i] = wave * envelope * amplitude

static func generate_custom_arp_2600_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var frequency = params.get("frequency", 440.0)
	var filter_cutoff = params.get("filter_cutoff", 1500.0)
	var filter_resonance = params.get("filter_resonance", 0.6)
	var filter_env_amount = params.get("filter_env_amount", 0.7)
	var attack = params.get("attack", 0.02)
	var decay = params.get("decay", 0.4)
	var sustain = params.get("sustain", 0.5)
	var release = params.get("release", 0.8)
	var portamento = params.get("portamento", 0.0)
	var amplitude = params.get("amplitude", 0.6)
	
	print("🎛️ ARP 2600 LEAD GENERATING analog synthesis")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Portamento (pitch glide)
		var current_freq = frequency
		if portamento > 0.0:
			var glide_progress = min(progress / portamento, 1.0)
			current_freq = frequency * 0.5 + frequency * 0.5 * glide_progress
		
		# Sawtooth wave
		var wave = 2.0 * (current_freq * t - floor(current_freq * t)) - 1.0
		
		# Filter envelope
		var filter_envelope = 1.0
		var filter_attack_samples = attack * AudioSynthesizer.SAMPLE_RATE * 0.5
		if i < filter_attack_samples:
			filter_envelope = float(i) / filter_attack_samples
		else:
			filter_envelope = exp(-(progress - attack * 0.5) * 3.0)
		
		# Filter simulation with envelope
		var dynamic_cutoff = filter_cutoff * (1.0 + filter_env_amount * filter_envelope)
		var filter_factor = clamp(dynamic_cutoff / 4000.0, 0.3, 1.0)
		wave *= filter_factor * (1.0 + filter_resonance * 0.5)
		
		# ADSR envelope
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		elif i < release_start:
			envelope = sustain
		else:
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = sustain * (1.0 - release_progress)
		
		data[i] = wave * envelope * amplitude

static func generate_custom_synare_3_disco_tom(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var osc1_freq = params.get("osc1_freq", 200.0)
	var osc2_freq = params.get("osc2_freq", 400.0)
	var osc_mix = params.get("osc_mix", 0.7)
	var noise_level = params.get("noise_level", 0.3)
	var filter_cutoff = params.get("filter_cutoff", 1200.0)
	var filter_resonance = params.get("filter_resonance", 0.6)
	var filter_sweep = params.get("filter_sweep", 0.8)
	var sweep_direction = params.get("sweep_direction", "down")
	var attack = params.get("attack", 0.001)
	var decay = params.get("decay", 0.8)
	var sustain = params.get("sustain", 0.0)
	var release = params.get("release", 0.3)
	var pitch_envelope = params.get("pitch_envelope", 0.7)
	var analog_drift = params.get("analog_drift", 0.02)
	var wave_type = params.get("wave_type", "pulse")
	var amplitude = params.get("amplitude", 0.5)
	
	print("🎛️ SYNARE 3 DISCO TOM GENERATING - the 'Ring My Bell' sound!")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pitch envelope (classic tom pitch drop)
		var pitch_env = 1.0 + pitch_envelope * exp(-progress * 8.0)
		var current_osc1_freq = osc1_freq * pitch_env
		var current_osc2_freq = osc2_freq * pitch_env
		
		# Analog drift simulation
		var drift = sin(2.0 * PI * analog_drift * t * 10.0) * analog_drift
		current_osc1_freq *= (1.0 + drift)
		current_osc2_freq *= (1.0 + drift * 0.7)
		
		# Generate oscillator waves
		var osc1 = 0.0
		var osc2 = 0.0
		
		match wave_type:
			"pulse":
				osc1 = 1.0 if sin(2.0 * PI * current_osc1_freq * t) > 0.3 else -1.0
				osc2 = 1.0 if sin(2.0 * PI * current_osc2_freq * t) > 0.3 else -1.0
			"sawtooth":
				osc1 = 2.0 * (current_osc1_freq * t - floor(current_osc1_freq * t)) - 1.0
				osc2 = 2.0 * (current_osc2_freq * t - floor(current_osc2_freq * t)) - 1.0
			"mixed":
				# Mix of pulse and sawtooth
				var pulse1 = 1.0 if sin(2.0 * PI * current_osc1_freq * t) > 0.3 else -1.0
				var saw1 = 2.0 * (current_osc1_freq * t - floor(current_osc1_freq * t)) - 1.0
				osc1 = pulse1 * 0.7 + saw1 * 0.3
				
				var pulse2 = 1.0 if sin(2.0 * PI * current_osc2_freq * t) > 0.3 else -1.0
				var saw2 = 2.0 * (current_osc2_freq * t - floor(current_osc2_freq * t)) - 1.0
				osc2 = pulse2 * 0.7 + saw2 * 0.3
		
		# Mix oscillators
		var wave = osc1 * (1.0 - osc_mix) + osc2 * osc_mix
		
		# Add noise component (essential for disco tom character)
		var noise_t = t * 3000.0  # High frequency noise
		var noise = sin(noise_t) * 0.6 + sin(noise_t * 1.7) * 0.4
		noise = tanh(noise * 2.0) * noise_level  # Slight distortion
		
		# Filter with resonance and sweep
		var filter_env = 1.0
		match sweep_direction:
			"down":
				filter_env = exp(-progress * 3.0)  # Downward sweep
			"up":
				filter_env = 1.0 - exp(-progress * 3.0)  # Upward sweep
			"up_down":
				filter_env = sin(PI * progress)  # Up then down
		
		var dynamic_cutoff = filter_cutoff * (1.0 + filter_sweep * filter_env)
		var filter_factor = clamp(dynamic_cutoff / 3000.0, 0.1, 1.0)
		
		# Apply resonance (creates the "ring" in "Ring My Bell")
		var resonance_boost = 1.0 + filter_resonance * exp(-abs(dynamic_cutoff - filter_cutoff) / 400.0)
		filter_factor *= resonance_boost
		
		var filtered_wave = (wave + noise) * filter_factor
		
		# ADSR envelope (tom-like: instant attack, long decay, no sustain)
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		elif sustain > 0.0 and i < release_start:
			envelope = sustain
		else:
			# Release phase for disco tom
			var release_progress = (i - max(attack_samples + decay_samples, release_start)) / (sample_count - max(attack_samples + decay_samples, release_start))
			envelope = sustain * exp(-release_progress * 3.0)
		
		data[i] = filtered_wave * envelope * amplitude

static func generate_custom_synare_3_cosmic_fx(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var start_freq = params.get("start_freq", 100.0)
	var end_freq = params.get("end_freq", 2000.0)
	var sweep_curve = params.get("sweep_curve", "exponential")
	var osc1_level = params.get("osc1_level", 0.8)
	var osc2_level = params.get("osc2_level", 0.6)
	var noise_level = params.get("noise_level", 0.4)
	var filter_resonance = params.get("filter_resonance", 0.85)
	var lfo_rate = params.get("lfo_rate", 2.0)
	var lfo_depth = params.get("lfo_depth", 0.3)
	var envelope_attack = params.get("envelope_attack", 0.5)
	var envelope_release = params.get("envelope_release", 2.0)
	var analog_chaos = params.get("analog_chaos", 0.05)
	var retrigger_enable = params.get("retrigger_enable", "off")
	var retrigger_rate = params.get("retrigger_rate", 4.0)
	var amplitude = params.get("amplitude", 0.4)
	
	print("🎛️ SYNARE 3 COSMIC FX GENERATING - UFO and space sounds! 🛸")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Frequency sweep with different curves
		var freq = start_freq
		match sweep_curve:
			"linear":
				freq = start_freq + (end_freq - start_freq) * progress
			"exponential":
				freq = start_freq * pow(end_freq / start_freq, progress)
			"logarithmic":
				freq = start_freq + (end_freq - start_freq) * sqrt(progress)
			"s_curve":
				# S-curve using smoothstep
				var smooth_progress = progress * progress * (3.0 - 2.0 * progress)
				freq = start_freq + (end_freq - start_freq) * smooth_progress
		
		# LFO modulation for cosmic wobble
		var lfo = sin(2.0 * PI * lfo_rate * t) * lfo_depth
		var modulated_freq = freq * (1.0 + lfo)
		
		# Analog chaos (random frequency drift)
		var chaos = sin(2.0 * PI * analog_chaos * t * 7.0) * analog_chaos
		chaos += sin(2.0 * PI * analog_chaos * t * 13.0) * analog_chaos * 0.5
		modulated_freq *= (1.0 + chaos)
		
		# Dual oscillators with slight detuning for thickness
		var osc1 = sin(2.0 * PI * modulated_freq * t) * osc1_level
		var osc2 = sin(2.0 * PI * modulated_freq * 1.02 * t) * osc2_level  # Slight detune
		
		# Add harmonic content for space-like timbre
		osc1 += sin(2.0 * PI * modulated_freq * 2.0 * t) * osc1_level * 0.3
		osc2 += sin(2.0 * PI * modulated_freq * 1.5 * t) * osc2_level * 0.2
		
		# Mix oscillators
		var wave = osc1 + osc2
		
		# Add cosmic noise component
		var noise_t = t * 2000.0  # High frequency noise
		var noise = sin(noise_t) * 0.7 + sin(noise_t * 1.7) * 0.5 + sin(noise_t * 2.3) * 0.3
		noise = tanh(noise * 1.5) * noise_level  # Slight saturation
		
		# Apply retrigger if enabled
		if retrigger_enable == "on":
			var retrigger_period = 1.0 / retrigger_rate
			var retrigger_phase = fmod(t, retrigger_period) / retrigger_period
			if retrigger_phase < 0.1:  # 10% of period for retrigger
				var retrigger_env = retrigger_phase / 0.1
				wave *= retrigger_env
				noise *= retrigger_env
		
		# High resonance filter for cosmic effect
		var filter_cutoff = modulated_freq * 1.8
		var filter_factor = clamp(filter_cutoff / 4000.0, 0.2, 1.0)
		
		# Apply resonance boost (creates the classic Synare "ring")
		var resonance_boost = 1.0 + filter_resonance * 2.0
		filter_factor *= resonance_boost
		
		# Additional resonant peak at filter frequency
		var resonant_peak = sin(2.0 * PI * filter_cutoff * t) * filter_resonance * 0.2
		
		var filtered_wave = (wave + noise + resonant_peak) * filter_factor
		
		# Envelope (cosmic FX typically have slow attack and long release)
		var envelope = 1.0
		var attack_samples = envelope_attack * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - envelope_release / duration) * sample_count
		
		if i < attack_samples:
			# Smooth attack
			envelope = float(i) / attack_samples
			envelope = envelope * envelope * (3.0 - 2.0 * envelope)  # Smoothstep
		elif i >= release_start:
			# Exponential release
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = exp(-release_progress * 2.0)
		else:
			# Sustain phase
			envelope = 1.0
		
		# Add subtle cosmic flutter
		var flutter = sin(2.0 * PI * 0.3 * t) * 0.05 + sin(2.0 * PI * 0.7 * t) * 0.03
		envelope *= (1.0 + flutter)
		
		data[i] = filtered_wave * envelope * amplitude
