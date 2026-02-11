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
		AudioSynthesizer.SoundType.ARTIFACT_REVEAL_SHIMMER:
			AudioSynthesizer._generate_artifact_reveal_shimmer(data, sample_count, params)
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
		AudioSynthesizer.SoundType.MOOG_KRAFTWERK_SEQUENCER:
			generate_custom_moog_kraftwerk_sequencer(data, sample_count, params)
		AudioSynthesizer.SoundType.HERBIE_HANCOCK_MOOG_FUSION:
			generate_custom_herbie_hancock_moog_fusion(data, sample_count, params)
		AudioSynthesizer.SoundType.APHEX_TWIN_MODULAR:
			generate_custom_aphex_twin_modular(data, sample_count, params)
		AudioSynthesizer.SoundType.FLYING_LOTUS_SAMPLER:
			generate_custom_flying_lotus_sampler(data, sample_count, params)
		# Cinematic / legacy synths
		AudioSynthesizer.SoundType.CS80_BRASS_LEAD:
			AudioSynthesizer._generate_cs80_brass_lead(data, sample_count)
		AudioSynthesizer.SoundType.CINEMATIC_432HZ_PAD:
			AudioSynthesizer._generate_cinematic_432hz_pad(data, sample_count)
		# Pop legacy timbres
		AudioSynthesizer.SoundType.POP_JUNO_CHORUS_PAD:
			AudioSynthesizer._generate_juno_chorus_pad(data, sample_count)
		AudioSynthesizer.SoundType.POP_DX7_BALLAD_KEYS:
			AudioSynthesizer._generate_dx7_ballad_keys(data, sample_count)
		AudioSynthesizer.SoundType.POP_OBXA_BRASS:
			AudioSynthesizer._generate_obxa_brass(data, sample_count)
		AudioSynthesizer.SoundType.POP_PROPHET_LEAD:
			AudioSynthesizer._generate_prophet_lead(data, sample_count)
		AudioSynthesizer.SoundType.POP_FUNK_BASS:
			AudioSynthesizer._generate_funk_bass(data, sample_count)
		AudioSynthesizer.SoundType.HEARTBEAT:
			generate_custom_heartbeat(data, sample_count, params)
		AudioSynthesizer.SoundType.LAB_HUM:
			generate_custom_lab_hum(data, sample_count, params)
		# Expressive Lead & Melodic Sounds
		AudioSynthesizer.SoundType.SUPERSAW_LEAD:
			generate_custom_supersaw_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.SYNC_LEAD:
			generate_custom_sync_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.FM_BELL:
			generate_custom_fm_bell(data, sample_count, params)
		AudioSynthesizer.SoundType.SQUARE_LEAD:
			generate_custom_square_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.PORTAMENTO_LEAD:
			generate_custom_portamento_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.VOCAL_FORMANT:
			generate_custom_vocal_formant(data, sample_count, params)
		AudioSynthesizer.SoundType.BRASS_STAB:
			generate_custom_brass_stab(data, sample_count, params)
		AudioSynthesizer.SoundType.STRING_ENSEMBLE:
			generate_custom_string_ensemble(data, sample_count, params)
		AudioSynthesizer.SoundType.PLUCK_LEAD:
			generate_custom_pluck_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.GLASS_LEAD:
			generate_custom_glass_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.DISTORTED_LEAD:
			generate_custom_distorted_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.BITCRUSHED_LEAD:
			generate_custom_bitcrushed_lead(data, sample_count, params)
		# Experimental / Algorithmic - route to AudioSynthesizer
		AudioSynthesizer.SoundType.RADIOPHONIC_WORKSHOP:
			AudioSynthesizer._generate_radiophonic_workshop(data, sample_count, params)
		AudioSynthesizer.SoundType.XENAKIS_STOCHASTIC:
			AudioSynthesizer._generate_xenakis_stochastic(data, sample_count, params)
		AudioSynthesizer.SoundType.SPIEGEL_INTELLIGENT:
			AudioSynthesizer._generate_spiegel_intelligent(data, sample_count, params)
		AudioSynthesizer.SoundType.AUTECHRE_FLUTTER:
			AudioSynthesizer._generate_autechre_flutter(data, sample_count, params)
		AudioSynthesizer.SoundType.IKEDA_DATAPLEX:
			AudioSynthesizer._generate_ikeda_dataplex(data, sample_count, params)
		AudioSynthesizer.SoundType.ECCOJAM_DRIFT:
			AudioSynthesizer._generate_eccojam_drift(data, sample_count, params)
		AudioSynthesizer.SoundType.CELLULAR_AUTOMATA:
			AudioSynthesizer._generate_cellular_automata(data, sample_count, params)
		# Pop & EDM - route to AudioSynthesizer
		AudioSynthesizer.SoundType.MORODER_DISCO_BASS:
			AudioSynthesizer._generate_moroder_disco_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.PROPHET_PAD:
			AudioSynthesizer._generate_prophet_pad(data, sample_count, params)
		AudioSynthesizer.SoundType.PRINCE_SYNC_LEAD:
			AudioSynthesizer._generate_prince_sync_lead(data, sample_count, params)
		AudioSynthesizer.SoundType.ELECTRO_808:
			AudioSynthesizer._generate_electro_808(data, sample_count, params)
		AudioSynthesizer.SoundType.DETROIT_TECHNO:
			AudioSynthesizer._generate_detroit_techno(data, sample_count, params)
		AudioSynthesizer.SoundType.HOUSE_ORGAN:
			AudioSynthesizer._generate_house_organ(data, sample_count, params)
		AudioSynthesizer.SoundType.RAVE_STAB:
			AudioSynthesizer._generate_rave_stab(data, sample_count, params)
		AudioSynthesizer.SoundType.SUPERSAW_PROGRESSIVE:
			AudioSynthesizer._generate_supersaw_progressive(data, sample_count, params)
		AudioSynthesizer.SoundType.WOBBLE_BASS:
			AudioSynthesizer._generate_wobble_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.SYNTHWAVE_LEAD:
			AudioSynthesizer._generate_synthwave_lead(data, sample_count, params)
		# Space Dystopia Soundscape Pop - route to AudioSynthesizer
		AudioSynthesizer.SoundType.SPACE_CHOIR_PAD:
			AudioSynthesizer._generate_space_choir_pad(data, sample_count, params)
		AudioSynthesizer.SoundType.CINEMATIC_STRINGS:
			AudioSynthesizer._generate_cinematic_strings(data, sample_count, params)
		AudioSynthesizer.SoundType.INDUSTRIAL_CLANK:
			AudioSynthesizer._generate_industrial_clank(data, sample_count, params)
		AudioSynthesizer.SoundType.RAIN_ATMOSPHERE:
			AudioSynthesizer._generate_rain_atmosphere(data, sample_count, params)
		AudioSynthesizer.SoundType.WAVETABLE_MORPH:
			AudioSynthesizer._generate_wavetable_morph(data, sample_count, params)
		AudioSynthesizer.SoundType.PEDAL_STEEL_SWELL:
			AudioSynthesizer._generate_pedal_steel_swell(data, sample_count, params)
		AudioSynthesizer.SoundType.GLITCH_CHAOS:
			AudioSynthesizer._generate_glitch_chaos(data, sample_count, params)
		AudioSynthesizer.SoundType.NOIR_SAX_BREATH:
			AudioSynthesizer._generate_noir_sax_breath(data, sample_count, params)
		AudioSynthesizer.SoundType.SPACE_SUB_DRONE:
			AudioSynthesizer._generate_space_sub_drone(data, sample_count, params)
		# Essential Drum Sounds
		AudioSynthesizer.SoundType.CLAP:
			generate_custom_clap(data, sample_count, params)
		AudioSynthesizer.SoundType.OPEN_HIHAT:
			generate_custom_open_hihat(data, sample_count, params)
		AudioSynthesizer.SoundType.SNARE_ACOUSTIC:
			generate_custom_snare_acoustic(data, sample_count, params)
		AudioSynthesizer.SoundType.RIMSHOT:
			generate_custom_rimshot(data, sample_count, params)
		# Production Polish
		AudioSynthesizer.SoundType.SHAKER:
			generate_custom_shaker(data, sample_count, params)
		AudioSynthesizer.SoundType.TAMBOURINE:
			generate_custom_tambourine(data, sample_count, params)
		AudioSynthesizer.SoundType.RIDE_CYMBAL:
			generate_custom_ride_cymbal(data, sample_count, params)
		AudioSynthesizer.SoundType.CRASH_CYMBAL:
			generate_custom_crash_cymbal(data, sample_count, params)
		# Genre-Specific
		AudioSynthesizer.SoundType.TOM_LOW:
			generate_custom_tom(data, sample_count, params, "low")
		AudioSynthesizer.SoundType.TOM_MID:
			generate_custom_tom(data, sample_count, params, "mid")
		AudioSynthesizer.SoundType.TOM_HIGH:
			generate_custom_tom(data, sample_count, params, "high")
		AudioSynthesizer.SoundType.CONGA:
			generate_custom_conga(data, sample_count, params)
		AudioSynthesizer.SoundType.BONGO:
			generate_custom_bongo(data, sample_count, params)
		# Genre-Defining Bass Sounds
		AudioSynthesizer.SoundType.REESE_BASS:
			generate_custom_reese_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.WOBBLE_BASS_CUSTOM:
			generate_custom_wobble_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.PLUCK_BASS:
			generate_custom_pluck_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.SUB_BASS_SINE:
			generate_custom_sub_bass_sine(data, sample_count, params)
		AudioSynthesizer.SoundType.DISTORTED_BASS:
			generate_custom_distorted_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.JUNO_BASS:
			generate_custom_juno_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.MINIMOOG_BASS:
			generate_custom_minimoog_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.SH101_BASS:
			generate_custom_sh101_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.PROPHET_BASS:
			generate_custom_prophet_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.UPRIGHT_BASS:
			generate_custom_upright_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.SLAP_BASS:
			generate_custom_slap_bass(data, sample_count, params)
		AudioSynthesizer.SoundType.PICKED_BASS:
			generate_custom_picked_bass(data, sample_count, params)

	return create_audio_stream(data)

static func generate_custom_basic_sine_wave(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var frequency = params.get("frequency", 440.0)
	var amplitude = params.get("amplitude", 0.3)
	var fade_in_time = params.get("fade_in_time", 0.05)
	var fade_out_time = params.get("fade_out_time", 0.05)
	
	var _duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
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
	
	print("[SYNTH] TELEPORT DRONE GENERATING with wave_type: %s" % wave_type)
	
	var _duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
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
	
	print("[SYNTH] BASS PULSE GENERATING with wave_type: %s" % wave_type)
	
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
	
	print("[SYNTH] LASER SHOT GENERATING with wave_type: %s" % wave_type)
	
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
	
	print("[SYNTH] POWER-UP JINGLE GENERATING with scale: %s" % scale_type)
	
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
	
	print("[SYNTH] EXPLOSION GENERATING multi-band synthesis")
	
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
	
	print("[SYNTH] RETRO JUMP GENERATING with wave_type: %s" % wave_type)
	
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
	
	print("[SYNTH] SHIELD HIT GENERATING with ring modulation")
	
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
	
	print("[SYNTH] AMBIENT WIND GENERATING with noise density: %d" % noise_density)
	
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
	
	print("[SYNTH] DARK 808 KICK GENERATING with pitch sweep")
	
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
	
	print("[SYNTH] ACID 606 HIHAT GENERATING with filter sweep")
	
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
	
	print("[SYNTH] DARK 808 SUB BASS GENERATING with slow modulation")
	
	var _duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
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
	
	print("[SYNTH] AMBIENT AMIGA DRONE GENERATING multi-layer synthesis")
	
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
	# Accept both specific and common parameter names
	var osc1_freq = params.get("osc1_freq", params.get("frequency", 110.0))
	var osc2_freq = params.get("osc2_freq", osc1_freq * 2.0)  # Default to octave above
	var osc2_detune = params.get("osc2_detune", params.get("detune", 0.3))
	var filter_cutoff = params.get("filter_cutoff", params.get("cutoff", 2000.0))
	var filter_resonance = params.get("filter_resonance", params.get("resonance", 0.7))
	var filter_env_amount = params.get("filter_env_amount", params.get("env_mod", 0.8))
	var amp_attack = params.get("amp_attack", params.get("attack", 0.01))
	var amp_decay = params.get("amp_decay", params.get("decay", 0.3))
	var amp_sustain = params.get("amp_sustain", params.get("sustain", 0.7))
	var amp_release = params.get("amp_release", params.get("release", 1.0))
	var portamento = params.get("portamento", params.get("glide", 0.1))
	var wave_type = params.get("wave_type", params.get("waveform", "sawtooth"))
	var amplitude = params.get("amplitude", params.get("amp", 0.4))
	
	print("[SYNTH] MOOG BASS LEAD GENERATING with wave_type: %s" % wave_type)
	
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
	# Accept both specific and common parameter names
	var base_freq = params.get("base_freq", params.get("frequency", 82.4))
	var filter_cutoff = params.get("filter_cutoff", params.get("cutoff", 800.0))
	var filter_resonance = params.get("filter_resonance", params.get("resonance", 0.85))
	var filter_env_mod = params.get("filter_env_mod", params.get("env_mod", 0.9))
	var accent_amount = params.get("accent_amount", params.get("accent", 0.6))
	var slide_time = params.get("slide_time", params.get("slide", 0.2))
	var decay_time = params.get("decay_time", params.get("decay", 0.8))
	var distortion = params.get("distortion", params.get("drive", 0.3))
	var wave_type = params.get("wave_type", params.get("waveform", "sawtooth"))
	var amplitude = params.get("amplitude", params.get("amp", 0.3))
	
	print("[SYNTH] TB-303 ACID BASS GENERATING with wave_type: %s" % wave_type)
	
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
	# Accept both specific and common parameter names
	var carrier_freq = params.get("carrier_freq", params.get("frequency", 220.0))
	var modulator_ratio = params.get("modulator_ratio", params.get("ratio", 2.0))
	var fm_index = params.get("fm_index", params.get("mod_depth", 3.0))
	var mod_env_attack = params.get("mod_env_attack", params.get("attack", 0.01))
	var mod_env_decay = params.get("mod_env_decay", params.get("decay", 0.3))
	var mod_env_sustain = params.get("mod_env_sustain", params.get("sustain", 0.2))
	var mod_env_release = params.get("mod_env_release", params.get("release", 1.0))
	var carrier_attack = params.get("carrier_attack", params.get("attack", 0.01))
	var carrier_decay = params.get("carrier_decay", params.get("decay", 0.5))
	var carrier_sustain = params.get("carrier_sustain", params.get("sustain", 0.3))
	var carrier_release = params.get("carrier_release", params.get("release", 2.0))
	var velocity_sensitivity = params.get("velocity_sensitivity", params.get("velocity", 0.7))
	var amplitude = params.get("amplitude", params.get("amp", 0.4))
	
	print("[SYNTH] DX7 ELECTRIC PIANO GENERATING FM synthesis")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
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
	
	print("[SYNTH] C64 SID LEAD GENERATING with PWM")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
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
	
	print("[SYNTH] AMIGA MOD SAMPLE GENERATING with wave_type: %s" % wave_type)
	
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
		var _loop_end_sample = loop_start_sample + loop_length * sample_count
		
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
	
	print("[SYNTH] PPG WAVE PAD GENERATING wavetable synthesis")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
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
	
	print("[SYNTH] TR-909 KICK GENERATING drum synthesis")
	
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
	
	print("[SYNTH] JUPITER-8 STRINGS GENERATING ensemble synthesis")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
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
	
	print("[SYNTH] KORG M1 PIANO GENERATING digital piano synthesis")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
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
	
	print("[SYNTH] ARP 2600 LEAD GENERATING analog synthesis")
	
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
	
	print("[SYNTH] SYNARE 3 DISCO TOM GENERATING - the 'Ring My Bell' sound!")
	
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
	
	print("[SYNTH] SYNARE 3 COSMIC FX GENERATING - UFO and space sounds! ??")
	
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

static func generate_custom_moog_kraftwerk_sequencer(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var bpm = params.get("bpm", 120.0)
	var sequence_steps = params.get("sequence_steps", 16)
	var base_note = params.get("base_note", "C3")
	var sequence_pattern = params.get("sequence_pattern", "kraftwerk_classic")
	var filter_cutoff = params.get("filter_cutoff", 800.0)
	var filter_resonance = params.get("filter_resonance", 0.7)
	var filter_envelope = params.get("filter_envelope", 0.6)
	var oscillator_wave = params.get("oscillator_wave", "sawtooth")
	var pulse_width = params.get("pulse_width", 0.5)
	var oscillator_sync = params.get("oscillator_sync", "off")
	var portamento = params.get("portamento", 0.05)
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.3)
	var sustain = params.get("sustain", 0.6)
	var release = params.get("release", 0.2)
	var accent_amount = params.get("accent_amount", 0.3)
	var step_gate_length = params.get("step_gate_length", 0.8)
	var analog_drift = params.get("analog_drift", 0.02)
	var vintage_warmth = params.get("vintage_warmth", 0.3)
	var stereo_spread = params.get("stereo_spread", 0.2)
	var amplitude = params.get("amplitude", 0.7)
	
	print("[SYNTH] MOOG KRAFTWERK SEQUENCER GENERATING - Electronic precision!")
	
	# Note frequency mapping
	var note_frequencies = {
		"C2": 65.41, "C#2": 69.30, "D2": 73.42, "D#2": 77.78, "E2": 82.41, "F2": 87.31,
		"F#2": 92.50, "G2": 98.00, "G#2": 103.83, "A2": 110.00, "A#2": 116.54, "B2": 123.47,
		"C3": 130.81, "C#3": 138.59, "D3": 146.83, "D#3": 155.56, "E3": 164.81, "F3": 174.61,
		"F#3": 185.00, "G3": 196.00, "G#3": 207.65, "A3": 220.00, "A#3": 233.08, "B3": 246.94,
		"C4": 261.63
	}
	
	var base_freq = note_frequencies.get(base_note, 130.81)
	
	# Define sequence patterns inspired by Kraftwerk
	var sequences = {
		"kraftwerk_classic": [0, 0, 7, 0, 4, 0, 7, 0, 2, 2, 7, 2, 0, 4, 7, 0],  # Intervals from base
		"autobahn": [0, 2, 4, 7, 4, 2, 0, -5, 0, 2, 4, 7, 4, 2, 0, 0],
		"trans_europe": [0, 0, 0, 7, 7, 5, 4, 4, 2, 2, 0, 0, 7, 5, 4, 2],
		"robots": [0, 4, 7, 12, 7, 4, 0, 0, 2, 5, 9, 14, 9, 5, 2, 0],
		"radioactivity": [0, 3, 7, 10, 7, 3, 0, -2, 0, 3, 7, 10, 7, 3, 0, 0],
		"custom": [0, 2, 4, 5, 7, 9, 11, 12, 11, 9, 7, 5, 4, 2, 0, 0]  # Default custom
	}
	
	var sequence = sequences.get(sequence_pattern, sequences["kraftwerk_classic"])
	
	# Accent pattern (typical Kraftwerk accents)
	var accents = [true, false, false, false, true, false, true, false, false, false, true, false, true, false, false, false]
	
	var step_duration = (60.0 / bpm) / 4.0  # 16th notes
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	var previous_freq = base_freq
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var global_progress = t / duration
		
		# Calculate current step with evolving pattern
		var pattern_evolution = sin(2.0 * PI * 0.05 * t)  # Slow pattern evolution
		var evolved_step_duration = step_duration * (1.0 + pattern_evolution * 0.1)
		var step_time = fmod(t, evolved_step_duration * sequence_steps)
		var step_index = int(step_time / evolved_step_duration) % sequence.size()
		var step_progress = fmod(step_time / evolved_step_duration, 1.0)
		
		# Calculate note frequency with progression
		var semitone_offset = sequence[step_index]
		
		# Add octave jumps during progression
		var octave_jump = 0
		if global_progress > 0.5 and int(t * 4.0) % 32 < 8:  # Octave jumps in second half
			octave_jump = 12
		elif global_progress > 0.75 and int(t * 2.0) % 16 < 4:  # More octave jumps
			octave_jump = -12
		
		var target_freq = base_freq * pow(2.0, (semitone_offset + octave_jump) / 12.0)
		
		# Apply portamento (pitch glide)
		var current_freq = target_freq
		if portamento > 0.0 and step_progress < portamento:
			var glide_amount = step_progress / portamento
			glide_amount = glide_amount * glide_amount * (3.0 - 2.0 * glide_amount)  # Smoothstep
			current_freq = previous_freq + (target_freq - previous_freq) * glide_amount
		else:
			previous_freq = target_freq
		
		# Analog drift simulation
		var drift = sin(2.0 * PI * analog_drift * t * 3.0) * analog_drift
		drift += sin(2.0 * PI * analog_drift * t * 7.0) * analog_drift * 0.5
		current_freq *= (1.0 + drift)
		
		# Generate oscillator wave
		var wave = 0.0
		match oscillator_wave:
			"sawtooth":
				wave = 2.0 * (current_freq * t - floor(current_freq * t)) - 1.0
			"square":
				wave = 1.0 if sin(2.0 * PI * current_freq * t) > 0 else -1.0
			"triangle":
				var saw = 2.0 * (current_freq * t - floor(current_freq * t)) - 1.0
				wave = 2.0 * abs(saw) - 1.0
			"pulse":
				var phase = fmod(current_freq * t, 1.0)
				wave = 1.0 if phase < pulse_width else -1.0
		
		# Oscillator sync (hard sync to fundamental)
		if oscillator_sync == "on":
			var sync_freq = base_freq
			var sync_phase = fmod(sync_freq * t, 1.0)
			if sync_phase < 0.01:  # Reset oscillator phase
				wave *= 0.1
		
		# Classic Moog ladder filter simulation
		var filter_env_amount = 1.0
		if step_progress < 0.1:
			filter_env_amount = 1.0 + filter_envelope * (step_progress / 0.1)
		else:
			filter_env_amount = 1.0 + filter_envelope * exp(-(step_progress - 0.1) * 3.0)
		
		var dynamic_cutoff = filter_cutoff * filter_env_amount
		
		# Add progressive filter sweeps
		var sweep_freq = 0.1 + global_progress * 0.2  # Faster sweeps over time
		var filter_sweep = sin(2.0 * PI * sweep_freq * t) * 600.0 * (1.0 + global_progress)
		dynamic_cutoff += filter_sweep
		
		var filter_factor = clamp(dynamic_cutoff / 2000.0, 0.2, 1.0)
		
		# Apply resonance (Moog-style feedback)
		var resonance_boost = 1.0 + filter_resonance * 1.8
		filter_factor *= resonance_boost
		
		# Additional resonant peak at cutoff frequency
		var resonant_peak = sin(2.0 * PI * dynamic_cutoff * t) * filter_resonance * 0.1
		
		var filtered_wave = (wave + resonant_peak) * filter_factor
		
		# Gate and envelope
		var gate = 1.0
		if step_progress > step_gate_length:
			gate = 0.0
		
		# ADSR envelope per step
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var step_samples = step_duration * AudioSynthesizer.SAMPLE_RATE
		var step_sample_index = int(step_progress * step_samples)
		
		if step_sample_index < attack_samples:
			envelope = float(step_sample_index) / attack_samples
		elif step_sample_index < attack_samples + decay_samples:
			var decay_progress = (step_sample_index - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		elif gate > 0.0:
			envelope = sustain
		else:
			# Release phase
			var release_samples = release * AudioSynthesizer.SAMPLE_RATE
			var release_index = step_sample_index - (step_gate_length * step_samples)
			if release_index < release_samples:
				envelope = sustain * (1.0 - release_index / release_samples)
			else:
				envelope = 0.0
		
		# Apply accent
		var accent_multiplier = 1.0
		if accents[step_index % accents.size()]:
			accent_multiplier = 1.0 + accent_amount
		
		# Vintage warmth (subtle harmonic distortion)
		var warm_wave = filtered_wave
		if vintage_warmth > 0.0:
			warm_wave = tanh(filtered_wave * (1.0 + vintage_warmth)) * (1.0 / (1.0 + vintage_warmth))
		
		# Stereo spread simulation (slight detuning)
		var stereo_detune = sin(2.0 * PI * 0.1 * t) * stereo_spread * 0.01
		var detuned_freq = current_freq * (1.0 + stereo_detune)
		var stereo_component = sin(2.0 * PI * detuned_freq * t) * stereo_spread * 0.2
		
		# Final output
		data[i] = (warm_wave + stereo_component) * envelope * accent_multiplier * amplitude * gate

static func generate_custom_herbie_hancock_moog_fusion(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var moog_model = params.get("moog_model", "minimoog")
	var chord_progression = params.get("chord_progression", "rockit")
	var base_note = params.get("base_note", "C3")
	var funk_rhythm = params.get("funk_rhythm", "syncopated")
	var filter_cutoff = params.get("filter_cutoff", 1200.0)
	var filter_resonance = params.get("filter_resonance", 0.6)
	var filter_envelope = params.get("filter_envelope", 0.8)
	var oscillator_detune = params.get("oscillator_detune", 0.05)
	var oscillator_mix = params.get("oscillator_mix", 0.7)
	var pulse_width_mod = params.get("pulse_width_mod", 0.4)
	var lfo_rate = params.get("lfo_rate", 2.5)
	var lfo_amount = params.get("lfo_amount", 0.3)
	var attack = params.get("attack", 0.02)
	var decay = params.get("decay", 0.4)
	var sustain = params.get("sustain", 0.7)
	var release = params.get("release", 0.6)
	var polyphony = params.get("polyphony", 4)
	var chord_voicing = params.get("chord_voicing", "jazz_7th")
	var groove_feel = params.get("groove_feel", 0.15)
	var velocity_sensitivity = params.get("velocity_sensitivity", 0.6)
	var distortion = params.get("distortion", 0.2)
	var chorus_depth = params.get("chorus_depth", 0.3)
	var vintage_character = params.get("vintage_character", 0.4)
	var space_reverb = params.get("space_reverb", 0.25)
	var amplitude = params.get("amplitude", 0.8)
	
	print("[SYNTH] HERBIE HANCOCK MOOG FUSION GENERATING - Jazz-funk revolution!")
	
	# Note frequency mapping
	var note_frequencies = {
		"C2": 65.41, "C#2": 69.30, "D2": 73.42, "D#2": 77.78, "E2": 82.41, "F2": 87.31,
		"F#2": 92.50, "G2": 98.00, "G#2": 103.83, "A2": 110.00, "A#2": 116.54, "B2": 123.47,
		"C3": 130.81, "C#3": 138.59, "D3": 146.83, "D#3": 155.56, "E3": 164.81, "F3": 174.61,
		"F#3": 185.00, "G3": 196.00, "G#3": 207.65, "A3": 220.00, "A#3": 233.08, "B3": 246.94,
		"C4": 261.63
	}
	
	var root_freq = note_frequencies.get(base_note, 130.81)
	
	# Chord progressions inspired by Herbie's classics
	var progressions = {
		"rockit": [[0, 4, 7, 11], [-2, 2, 5, 9], [0, 4, 7, 11], [2, 6, 9, 13]],  # Future funk
		"chameleon": [[0, 3, 7, 10], [5, 8, 12, 15], [0, 3, 7, 10], [3, 7, 10, 14]],  # Modal jazz
		"cantaloupe": [[0, 4, 7, 10], [2, 5, 9, 12], [-3, 0, 4, 7], [0, 4, 7, 10]],  # Funky jazz
		"future_shock": [[0, 4, 7, 11], [7, 11, 14, 18], [0, 4, 7, 11], [5, 9, 12, 16]],  # Electronic fusion
		"jazz_fusion": [[0, 4, 7, 11], [2, 6, 9, 13], [5, 9, 12, 16], [0, 4, 7, 11]],  # Standard progression
		"custom": [[0, 4, 7, 10], [2, 5, 9, 12], [7, 11, 14, 17], [0, 4, 7, 10]]  # Custom voicing
	}
	
	var chord_sequence = progressions.get(chord_progression, progressions["rockit"])
	
	# Rhythm patterns
	var rhythm_patterns = {
		"straight": [1.0, 0.7, 0.8, 0.6, 1.0, 0.7, 0.8, 0.6],
		"syncopated": [1.0, 0.3, 0.8, 0.4, 0.6, 0.9, 0.2, 0.7],
		"swing": [1.0, 0.4, 0.8, 0.3, 0.9, 0.5, 0.7, 0.4],
		"latin": [1.0, 0.6, 0.3, 0.8, 0.5, 0.9, 0.4, 0.7],
		"afrobeat": [1.0, 0.5, 0.7, 0.3, 0.8, 0.4, 0.9, 0.6]
	}
	
	var rhythm_pattern = rhythm_patterns.get(funk_rhythm, rhythm_patterns["syncopated"])
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var chord_duration = duration / chord_sequence.size()
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _global_progress = t / duration
		
		# Current chord
		var chord_index = int(t / chord_duration) % chord_sequence.size()
		var chord_progress = fmod(t / chord_duration, 1.0)
		var current_chord = chord_sequence[chord_index]
		
		# Rhythm timing with groove
		var beat_time = fmod(t * 4.0, 1.0)  # 4 beats per second
		var rhythm_index = int(t * 32.0) % rhythm_pattern.size()  # 32nd note resolution
		var rhythm_velocity = rhythm_pattern[rhythm_index]
		
		# Add groove feel (slight timing variations)
		var groove_offset = sin(2.0 * PI * t * 16.0) * groove_feel * 0.01
		beat_time += groove_offset
		
		# LFO modulation (global for all voices)
		var lfo = sin(2.0 * PI * lfo_rate * t) * lfo_amount
		
		# Generate polyphonic voices
		var total_wave = 0.0
		var voice_count = min(polyphony, current_chord.size())
		
		for voice in range(voice_count):
			var semitone_offset = current_chord[voice]
			var note_freq = root_freq * pow(2.0, semitone_offset / 12.0)
			
			# Oscillator detuning for thickness
			var detune_offset = (float(voice) / voice_count - 0.5) * oscillator_detune
			note_freq *= (1.0 + detune_offset)
			
			# Apply LFO modulation to frequency
			note_freq *= (1.0 + lfo * 0.02)
			
			# Generate different waveforms based on Moog model
			var wave = 0.0
			match moog_model:
				"minimoog":
					# Sawtooth with pulse mix
					var saw = 2.0 * (note_freq * t - floor(note_freq * t)) - 1.0
					var pulse_width = 0.5 + pulse_width_mod * lfo * 0.3
					var pulse = 1.0 if fmod(note_freq * t, 1.0) < pulse_width else -1.0
					wave = saw * oscillator_mix + pulse * (1.0 - oscillator_mix)
				"micromoog":
					# Single oscillator with sub-octave
					var main = sin(2.0 * PI * note_freq * t)
					var sub = sin(2.0 * PI * note_freq * 0.5 * t) * 0.3
					wave = main + sub
				"polymoog":
					# Multi-oscillator ensemble
					var osc1 = sin(2.0 * PI * note_freq * t)
					var osc2 = sin(2.0 * PI * note_freq * 1.01 * t)
					var osc3 = sin(2.0 * PI * note_freq * 0.99 * t)
					wave = (osc1 + osc2 + osc3) / 3.0
				"hybrid":
					# Mix of all models
					var saw = 2.0 * (note_freq * t - floor(note_freq * t)) - 1.0
					var sine = sin(2.0 * PI * note_freq * t)
					wave = saw * 0.6 + sine * 0.4
			
			# Voice-specific envelope
			var voice_envelope = 1.0
			var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
			var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
			var chord_samples = chord_progress * chord_duration * AudioSynthesizer.SAMPLE_RATE
			
			if chord_samples < attack_samples:
				voice_envelope = chord_samples / attack_samples
			elif chord_samples < attack_samples + decay_samples:
				var decay_progress = (chord_samples - attack_samples) / decay_samples
				voice_envelope = 1.0 - decay_progress * (1.0 - sustain)
			else:
				voice_envelope = sustain
			
			# Apply velocity sensitivity
			voice_envelope *= (1.0 - velocity_sensitivity) + velocity_sensitivity * rhythm_velocity
			
			total_wave += wave * voice_envelope / voice_count
		
		# Moog ladder filter with envelope
		var filter_env = 1.0
		if chord_progress < 0.1:
			filter_env = 1.0 + filter_envelope * (chord_progress / 0.1)
		else:
			filter_env = 1.0 + filter_envelope * exp(-(chord_progress - 0.1) * 2.0)
		
		var dynamic_cutoff = filter_cutoff * filter_env
		dynamic_cutoff += lfo * 200.0  # LFO modulation of filter
		
		# Multi-stage filter (Moog ladder approximation)
		var filter_factor = clamp(dynamic_cutoff / 3000.0, 0.3, 1.0)
		var resonance_boost = 1.0 + filter_resonance * 2.0
		
		# Filter resonance feedback
		var resonant_feedback = sin(2.0 * PI * dynamic_cutoff * t) * filter_resonance * 0.15
		var filtered_wave = (total_wave + resonant_feedback) * filter_factor * resonance_boost
		
		# Harmonic distortion (subtle tube/transistor saturation)
		if distortion > 0.0:
			filtered_wave = tanh(filtered_wave * (1.0 + distortion * 2.0)) / (1.0 + distortion)
		
		# Vintage character (analog imperfections)
		if vintage_character > 0.0:
			var drift = sin(2.0 * PI * vintage_character * t * 0.1) * vintage_character * 0.02
			var noise = (randf() - 0.5) * vintage_character * 0.005
			filtered_wave *= (1.0 + drift + noise)
		
		# Chorus effect (classic jazz-fusion sound)
		var chorus_wave = filtered_wave
		if chorus_depth > 0.0:
			var chorus_delay = 0.002 + chorus_depth * 0.003  # 2-5ms delay
			var chorus_lfo = sin(2.0 * PI * 0.8 * t) * chorus_depth
			var delayed_sample_index = i - int((chorus_delay + chorus_lfo * 0.001) * AudioSynthesizer.SAMPLE_RATE)
			if delayed_sample_index >= 0 and delayed_sample_index < i:
				var delayed_wave = filtered_wave * 0.7  # Approximate delayed signal
				chorus_wave = (filtered_wave + delayed_wave) * 0.7
		
		# Spatial reverb (hall/plate reverb simulation)
		var reverb_wave = chorus_wave
		if space_reverb > 0.0:
			var reverb_delay1 = int(0.03 * AudioSynthesizer.SAMPLE_RATE)  # 30ms
			var reverb_delay2 = int(0.07 * AudioSynthesizer.SAMPLE_RATE)  # 70ms
			if i >= reverb_delay1:
				reverb_wave += chorus_wave * space_reverb * 0.3
			if i >= reverb_delay2:
				reverb_wave += chorus_wave * space_reverb * 0.2
		
		# Rhythm gating
		var gate = rhythm_velocity
		
		# Final output with dynamics
		data[i] = reverb_wave * gate * amplitude

static func generate_custom_aphex_twin_modular(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var complexity_level = params.get("complexity_level", "advanced")
	var modular_algorithm = params.get("modular_algorithm", "nonlinear_chaos")
	var oscillator_count = params.get("oscillator_count", 8)
	var cross_modulation = params.get("cross_modulation", 0.7)
	var feedback_amount = params.get("feedback_amount", 0.6)
	var chaos_factor = params.get("chaos_factor", 0.4)
	var frequency_ratio_1 = params.get("frequency_ratio_1", 1.618)  # Golden ratio
	var frequency_ratio_2 = params.get("frequency_ratio_2", 2.718)  # Euler's number
	var frequency_ratio_3 = params.get("frequency_ratio_3", 3.141)  # Pi
	var sequence_pattern = params.get("sequence_pattern", "mathematical")
	var filter_type = params.get("filter_type", "multi_pole")
	var filter_cutoff = params.get("filter_cutoff", 2000.0)
	var filter_resonance = params.get("filter_resonance", 0.8)
	var filter_tracking = params.get("filter_tracking", 0.5)
	var lfo_1_rate = params.get("lfo_1_rate", 0.3)
	var lfo_2_rate = params.get("lfo_2_rate", 7.8)
	var lfo_3_rate = params.get("lfo_3_rate", 23.4)
	var lfo_sync = params.get("lfo_sync", "free_running")
	var envelope_complexity = params.get("envelope_complexity", "multi_stage")
	var attack = params.get("attack", 0.001)
	var decay = params.get("decay", 0.2)
	var sustain = params.get("sustain", 0.3)
	var release = params.get("release", 2.0)
	var granular_size = params.get("granular_size", 0.05)
	var granular_density = params.get("granular_density", 20)
	var phase_distortion = params.get("phase_distortion", 0.3)
	var ring_modulation = params.get("ring_modulation", 0.2)
	var bit_reduction = params.get("bit_reduction", 0.1)
	var sample_rate_reduction = params.get("sample_rate_reduction", 0.05)
	var stereo_width = params.get("stereo_width", 0.8)
	var reverb_algorithm = params.get("reverb_algorithm", "algorithmic")
	var reverb_amount = params.get("reverb_amount", 0.3)
	var glitch_probability = params.get("glitch_probability", 0.15)
	var mathematical_precision = params.get("mathematical_precision", 0.9)
	var amplitude = params.get("amplitude", 0.7)
	
	print("[SYNTH] APHEX TWIN MODULAR GENERATING - Experimental synthesis mastery!")
	
	# Mathematical constants and sequences
	var golden_ratio = 1.618033988749
	var _euler_number = 2.718281828459
	var pi_constant = 3.141592653589
	
	# Generate mathematical sequences based on pattern
	var sequence_values = []
	match sequence_pattern:
		"mathematical":
			for i in range(32):
				sequence_values.append(pow(golden_ratio, i) - floor(pow(golden_ratio, i)))
		"fibonacci":
			var fib = [1, 1]
			for i in range(30):
				fib.append((fib[i] + fib[i + 1]) % 100)
			sequence_values = fib
		"prime_numbers":
			sequence_values = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131]
		"fractal":
			for i in range(32):
				var x = float(i) / 32.0
				sequence_values.append(abs(sin(x * pi_constant * 4.0) * cos(x * pi_constant * 8.0)))
		"random_walk":
			var walk_value = 0.5
			for i in range(32):
				walk_value += (randf() - 0.5) * 0.1
				walk_value = clamp(walk_value, 0.0, 1.0)
				sequence_values.append(walk_value)
		"human_feel":
			for i in range(32):
				var human_variation = sin(float(i) * 0.1) + randf() * 0.1 - 0.05
				sequence_values.append(0.5 + human_variation * 0.3)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var base_freq = 110.0  # A2
	
	# Musical progression setup
	var chord_progression = [
		[0, 4, 7],      # I - Major triad
		[5, 9, 12],     # vi - Minor sixth
		[3, 7, 10],     # IV - Major fourth  
		[7, 11, 14]     # V - Major fifth
	]
	var progression_length = 4.0  # 4 seconds per chord
	var _beats_per_chord = 8  # 8 beats per chord change
	
	# Initialize feedback delay lines for complex modular routing
	var feedback_buffers = []
	var feedback_buffer_size = int(0.1 * AudioSynthesizer.SAMPLE_RATE)  # 100ms
	for i in range(oscillator_count):
		var buffer = []
		buffer.resize(feedback_buffer_size)
		buffer.fill(0.0)
		feedback_buffers.append(buffer)
	
	var feedback_indices = []
	feedback_indices.resize(oscillator_count)
	feedback_indices.fill(0)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var global_progress = t / duration
		
		# Musical progression timing
		var chord_time = fmod(t, progression_length * chord_progression.size())
		var current_chord_index = int(chord_time / progression_length) % chord_progression.size()
		var chord_progress = fmod(chord_time / progression_length, 1.0)
		var current_chord = chord_progression[current_chord_index]
		
		# Beat timing for rhythmic elements
		var beat_rate = 2.0  # 2 beats per second (120 BPM)
		var _beat_time = fmod(t * beat_rate, 1.0)
		var is_strong_beat = int(t * beat_rate) % 4 == 0  # Strong beat every 4 beats
		
		# Complex LFO network with tempo sync
		var lfo_1 = sin(2.0 * PI * lfo_1_rate * t)
		var lfo_2 = sin(2.0 * PI * lfo_2_rate * t + lfo_1 * 0.5)  # Cross-modulated
		var lfo_3 = sin(2.0 * PI * lfo_3_rate * t + lfo_2 * 0.3)
		
		# Evolving chaos oscillator
		var chaos_evolution = sin(2.0 * PI * 0.1 * t)  # Slow evolution
		var chaos_x = sin(t * chaos_factor * (10.0 + chaos_evolution * 5.0))
		var chaos_y = cos(t * chaos_factor * (15.0 + chaos_evolution * 3.0))
		var chaos_z = sin(t * chaos_factor * 7.0) * cos(t * chaos_factor * 11.0)
		var chaos_mod = (chaos_x + chaos_y + chaos_z) / 3.0 * chaos_factor
		
		# Sequence-driven frequency modulation with progression
		var sequence_rate = 8.0 + chaos_mod * 4.0  # Variable sequence rate
		var sequence_index = int(t * sequence_rate) % sequence_values.size()
		var sequence_value = sequence_values[sequence_index]
		
		# Generate complex oscillator network
		var total_wave = 0.0
		var oscillator_outputs = []
		
		for osc in range(oscillator_count):
			var osc_ratio = [frequency_ratio_1, frequency_ratio_2, frequency_ratio_3][osc % 3]
			
			# Map oscillator to chord notes for harmonic progression
			var chord_note_index = osc % current_chord.size()
			var semitone_offset = current_chord[chord_note_index]
			var chord_freq = base_freq * pow(2.0, semitone_offset / 12.0)
			
			var osc_freq = chord_freq * osc_ratio * (1.0 + float(osc) * 0.05)
			
			# Apply sequence modulation with progression
			osc_freq *= (1.0 + sequence_value * 0.3 * (1.0 + chord_progress))
			
			# Apply evolving LFO modulations
			var lfo_intensity = 1.0 + global_progress * 0.5  # Intensify over time
			osc_freq *= (1.0 + lfo_1 * 0.02 * lfo_intensity + lfo_2 * 0.01 + lfo_3 * 0.005)
			
			# Apply chaos modulation with beat sync
			var beat_chaos = chaos_mod * (1.0 + (1.0 if is_strong_beat else 0.5))
			osc_freq *= (1.0 + beat_chaos * 0.1)
			
			# Cross-modulation from other oscillators
			var cross_mod = 0.0
			if osc > 0:
				for prev_osc in range(osc):
					if prev_osc < oscillator_outputs.size():
						cross_mod += oscillator_outputs[prev_osc] * cross_modulation * 0.1
			
			osc_freq *= (1.0 + cross_mod)
			
			# Generate base waveform based on algorithm
			var wave = 0.0
			match modular_algorithm:
				"linear_fm":
					var modulator_freq = osc_freq * 2.0
					var fm_amount = lfo_1 * cross_modulation
					wave = sin(2.0 * PI * osc_freq * t + sin(2.0 * PI * modulator_freq * t) * fm_amount)
				"nonlinear_chaos":
					var phase = 2.0 * PI * osc_freq * t
					var chaotic_mod = sin(phase * 3.0) + cos(phase * 5.0) * 0.5
					wave = sin(phase + chaotic_mod * chaos_factor)
				"feedback_loops":
					var feedback_index = feedback_indices[osc]
					var feedback_sample = feedback_buffers[osc][feedback_index]
					var phase = 2.0 * PI * osc_freq * t + feedback_sample * feedback_amount
					wave = sin(phase)
					# Store in feedback buffer
					feedback_buffers[osc][feedback_index] = wave
					feedback_indices[osc] = (feedback_index + 1) % feedback_buffer_size
				"granular_madness":
					var grain_freq = osc_freq * (1.0 + randf() * 0.2 - 0.1)
					var grain_phase = fmod(t * granular_density, 1.0)
					if grain_phase < granular_size:
						wave = sin(2.0 * PI * grain_freq * t) * sin(grain_phase * PI / granular_size)
					else:
						wave = 0.0
				"phase_distortion":
					var phase = 2.0 * PI * osc_freq * t
					var distorted_phase = phase + sin(phase * 2.0) * phase_distortion
					wave = sin(distorted_phase)
				"custom_patch":
					# Complex custom algorithm
					var phase1 = 2.0 * PI * osc_freq * t
					var phase2 = 2.0 * PI * osc_freq * 1.5 * t
					wave = sin(phase1) * cos(phase2) + sin(phase1 * 0.5) * 0.3
			
			# Apply ring modulation
			if ring_modulation > 0.0 and osc > 0:
				var ring_freq = base_freq * 3.0
				wave *= (sin(2.0 * PI * ring_freq * t) * ring_modulation + (1.0 - ring_modulation))
			
			# Store oscillator output for cross-modulation
			oscillator_outputs.append(wave)
			total_wave += wave / oscillator_count
		
		# Complex multi-pole filter
		var filter_env = 1.0
		match envelope_complexity:
			"simple_adsr":
				var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
				var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
				var release_samples = release * AudioSynthesizer.SAMPLE_RATE
				var _total_samples = attack_samples + decay_samples + release_samples
				
				if i < attack_samples:
					filter_env = float(i) / attack_samples
				elif i < attack_samples + decay_samples:
					var decay_progress = (i - attack_samples) / decay_samples
					filter_env = 1.0 - decay_progress * (1.0 - sustain)
				else:
					filter_env = sustain
			"multi_stage":
				# Complex envelope with multiple stages
				var _stage_duration = duration / 5.0
				var stage = int(global_progress * 5.0)
				var stage_progress = fmod(global_progress * 5.0, 1.0)
				match stage:
					0: filter_env = stage_progress  # Attack
					1: filter_env = 1.0 - stage_progress * 0.3  # Decay 1
					2: filter_env = 0.7 + stage_progress * 0.2  # Rise
					3: filter_env = 0.9 - stage_progress * 0.6  # Decay 2
					4: filter_env = 0.3 * (1.0 - stage_progress)  # Release
			"looping":
				var loop_period = 0.5  # 500ms loops
				var loop_progress = fmod(t / loop_period, 1.0)
				filter_env = sin(loop_progress * 2.0 * PI) * 0.5 + 0.5
			"triggered":
				var trigger_rate = 4.0  # 4 Hz
				var trigger_phase = fmod(t * trigger_rate, 1.0)
				if trigger_phase < 0.1:
					filter_env = trigger_phase / 0.1
				else:
					filter_env = exp(-(trigger_phase - 0.1) * 10.0)
			"generative":
				# AI-like generative envelope
				var gen_freq1 = 0.7
				var gen_freq2 = 1.3
				filter_env = (sin(2.0 * PI * gen_freq1 * t) + cos(2.0 * PI * gen_freq2 * t)) * 0.25 + 0.5
		
		# Dynamic filter cutoff with progression
		var dynamic_cutoff = filter_cutoff
		
		# Filter follows chord progression
		var chord_brightness = float(current_chord_index) / chord_progression.size()
		dynamic_cutoff *= (0.5 + chord_brightness + chord_progress * 0.3)
		
		dynamic_cutoff *= filter_env * filter_tracking
		dynamic_cutoff += lfo_1 * 500.0 + lfo_2 * 200.0 + lfo_3 * 100.0
		
		# Beat-synced filter sweeps
		var beat_sweep = sin(2.0 * PI * beat_rate * t) * 400.0
		if is_strong_beat:
			beat_sweep *= 2.0
		dynamic_cutoff += beat_sweep
		
		dynamic_cutoff = clamp(dynamic_cutoff, 20.0, 20000.0)
		
		# Apply complex filter
		var filtered_wave = total_wave
		match filter_type:
			"ladder":
				var filter_factor = clamp(dynamic_cutoff / 5000.0, 0.1, 1.0)
				filtered_wave *= filter_factor * (1.0 + filter_resonance)
			"state_variable":
				var cutoff_norm = dynamic_cutoff / 10000.0
				var lowpass = total_wave * cutoff_norm
				var highpass = total_wave * (1.0 - cutoff_norm)
				var bandpass = (lowpass + highpass) * 0.5
				filtered_wave = bandpass + lowpass * filter_resonance
			"multi_pole":
				# 4-pole filter simulation
				for pole in range(4):
					var pole_cutoff = dynamic_cutoff / pow(2.0, pole)
					var pole_factor = clamp(pole_cutoff / 8000.0, 0.2, 1.0)
					filtered_wave *= pole_factor
				filtered_wave *= (1.0 + filter_resonance * 1.5)
			"comb_filter":
				var delay_samples = int(AudioSynthesizer.SAMPLE_RATE / dynamic_cutoff)
				if i >= delay_samples:
					filtered_wave += total_wave * filter_resonance * 0.7
			"formant":
				# Vocal formant filter
				var formant_freq1 = dynamic_cutoff
				var formant_freq2 = dynamic_cutoff * 2.2
				var formant_freq3 = dynamic_cutoff * 3.8
				filtered_wave = (sin(2.0 * PI * formant_freq1 * t) + 
								sin(2.0 * PI * formant_freq2 * t) * 0.7 + 
								sin(2.0 * PI * formant_freq3 * t) * 0.3) * total_wave * 0.3
			"vocal":
				# Vowel-like filtering
				var vowel_formants = [800.0, 1200.0, 2400.0]  # "A" vowel
				filtered_wave = 0.0
				for formant in vowel_formants:
					filtered_wave += sin(2.0 * PI * formant * t) * total_wave / 3.0
		
		# Digital processing effects
		var processed_wave = filtered_wave
		
		# Bit reduction
		if bit_reduction > 0.0:
			var bits = 16.0 - bit_reduction * 12.0  # 16-bit down to 4-bit
			processed_wave = floor(processed_wave * pow(2, bits)) / pow(2, bits)
		
		# Sample rate reduction
		if sample_rate_reduction > 0.0:
			var reduced_rate = AudioSynthesizer.SAMPLE_RATE * (1.0 - sample_rate_reduction * 0.9)
			var sample_step = float(AudioSynthesizer.SAMPLE_RATE) / reduced_rate
			if int(float(i) / sample_step) != int(float(i - 1) / sample_step):
				# Keep current sample
				pass
			else:
				# Use previous sample (sample and hold)
				if i > 0:
					processed_wave = processed_wave  # This creates the aliasing effect
		
		# Stereo width processing
		var stereo_detune = sin(2.0 * PI * 0.3 * t) * stereo_width * 0.01
		var stereo_component = sin(2.0 * PI * base_freq * (1.0 + stereo_detune) * t) * stereo_width * 0.2
		
		# Reverb algorithm
		var reverbed_wave = processed_wave
		if reverb_amount > 0.0:
			match reverb_algorithm:
				"algorithmic":
					# Algorithmic reverb (Schroeder)
					var delay1 = int(0.03 * AudioSynthesizer.SAMPLE_RATE)
					var delay2 = int(0.07 * AudioSynthesizer.SAMPLE_RATE)
					var delay3 = int(0.13 * AudioSynthesizer.SAMPLE_RATE)
					if i >= delay3:
						reverbed_wave += processed_wave * reverb_amount * 0.4
					if i >= delay2:
						reverbed_wave += processed_wave * reverb_amount * 0.3
					if i >= delay1:
						reverbed_wave += processed_wave * reverb_amount * 0.2
				"impossible":
					# Impossible reverb (non-causal)
					var future_delay = int(0.01 * AudioSynthesizer.SAMPLE_RATE)
					if i + future_delay < sample_count:
						reverbed_wave += processed_wave * reverb_amount * 0.3
		
		# Glitch processing
		if randf() < glitch_probability * 0.001:  # Scale down probability
			match int(randf() * 5):
				0: processed_wave *= randf() * 3.0  # Volume glitch
				1: processed_wave = -processed_wave  # Phase flip
				2: processed_wave = 0.0  # Dropout
				3: processed_wave = sin(2.0 * PI * 1000.0 * randf() * t)  # Noise burst
				4: processed_wave = processed_wave * processed_wave  # Square distortion
		
		# Mathematical precision (quantization)
		if mathematical_precision < 1.0:
			var precision_factor = pow(10.0, mathematical_precision * 6.0)
			processed_wave = round(processed_wave * precision_factor) / precision_factor
		
		# Final output with stereo component
		data[i] = (reverbed_wave + stereo_component) * amplitude

static func generate_custom_flying_lotus_sampler(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var beat_pattern = params.get("beat_pattern", "j_dilla_swing")
	var sample_mode = params.get("sample_mode", "granular_chop")
	var bpm = params.get("bpm", 85.0)
	var swing_amount = params.get("swing_amount", 0.6)
	var chop_density = params.get("chop_density", 16)
	var sample_layers = params.get("sample_layers", 4)
	var jazz_harmonies = params.get("jazz_harmonies", "complex_7th")
	var polyrhythm_ratio = params.get("polyrhythm_ratio", "3_against_4")
	var filter_type = params.get("filter_type", "sp404_vintage")
	var filter_cutoff = params.get("filter_cutoff", 1500.0)
	var filter_resonance = params.get("filter_resonance", 0.4)
	var vintage_saturation = params.get("vintage_saturation", 0.3)
	var tape_wow_flutter = params.get("tape_wow_flutter", 0.15)
	var lfo_rate = params.get("lfo_rate", 1.2)
	var lfo_chaos = params.get("lfo_chaos", 0.3)
	var attack = params.get("attack", 0.005)
	var decay = params.get("decay", 0.8)
	var sustain = params.get("sustain", 0.4)
	var release = params.get("release", 1.5)
	var reverb_space = params.get("reverb_space", "chamber")
	var reverb_amount = params.get("reverb_amount", 0.4)
	var delay_time = params.get("delay_time", 0.125)
	var delay_feedback = params.get("delay_feedback", 0.3)
	var stutter_probability = params.get("stutter_probability", 0.2)
	var glitch_amount = params.get("glitch_amount", 0.1)
	var bass_emphasis = params.get("bass_emphasis", 0.5)
	var high_freq_roll = params.get("high_freq_roll", 0.2)
	var sample_rate_redux = params.get("sample_rate_redux", 0.1)
	var bit_crush = params.get("bit_crush", 0.05)
	var stereo_width = params.get("stereo_width", 0.7)
	var experimental_factor = params.get("experimental_factor", 0.4)
	var amplitude = params.get("amplitude", 0.8)
	
	print("[SYNTH] FLYING LOTUS SAMPLER GENERATING - Genre-defying beat music!")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var beat_duration = 60.0 / bpm / 4.0  # 16th note duration
	
	# Jazz chord progressions inspired by Flying Lotus
	var chord_progressions = {
		"simple_triads": [[0, 4, 7], [2, 5, 9], [3, 7, 10], [5, 9, 12]],
		"jazz_7th": [[0, 4, 7, 11], [2, 5, 9, 12], [3, 7, 10, 14], [5, 9, 12, 16]],
		"complex_7th": [[0, 4, 7, 11, 14], [2, 5, 9, 12, 16], [3, 7, 10, 14, 17], [5, 9, 12, 16, 19]],
		"modal_jazz": [[0, 3, 7, 10], [5, 8, 12, 15], [2, 5, 9, 12], [7, 10, 14, 17]],
		"chromatic": [[0, 1, 4, 7], [3, 4, 7, 10], [6, 7, 10, 13], [9, 10, 13, 16]],
		"atonal": [[0, 2, 6, 10], [1, 5, 8, 11], [4, 7, 11, 14], [3, 6, 9, 13]]
	}
	
	var chord_progression = chord_progressions.get(jazz_harmonies, chord_progressions["complex_7th"])
	
	# Beat patterns
	var beat_patterns = {
		"straight": [1.0, 0.0, 0.5, 0.0, 1.0, 0.0, 0.5, 0.0],
		"j_dilla_swing": [1.0, 0.2, 0.6, 0.3, 0.8, 0.1, 0.7, 0.4],
		"off_kilter": [1.0, 0.3, 0.1, 0.7, 0.5, 0.2, 0.8, 0.4],
		"polyrhythmic": [1.0, 0.6, 0.3, 0.8, 0.4, 0.9, 0.2, 0.7],
		"broken_beat": [1.0, 0.0, 0.7, 0.2, 0.0, 0.9, 0.3, 0.0],
		"future_funk": [1.0, 0.4, 0.8, 0.2, 0.6, 0.3, 0.9, 0.1]
	}
	
	var rhythm_pattern = beat_patterns.get(beat_pattern, beat_patterns["j_dilla_swing"])
	
	# Polyrhythm ratios
	var polyrhythm_ratios = {
		"none": 1.0,
		"3_against_2": 1.5,
		"3_against_4": 0.75,
		"5_against_4": 1.25,
		"7_against_8": 0.875,
		"complex": 1.618  # Golden ratio
	}
	
	var poly_ratio = polyrhythm_ratios.get(polyrhythm_ratio, 0.75)
	
	# Initialize delay buffer
	var delay_buffer_size = int(delay_time * AudioSynthesizer.SAMPLE_RATE)
	var delay_buffer = []
	delay_buffer.resize(delay_buffer_size)
	delay_buffer.fill(0.0)
	var delay_index = 0
	
	var base_freq = 110.0  # A2
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _global_progress = t / duration
		
		# Current chord progression
		var chord_duration = 4.0  # 4 seconds per chord
		var chord_index = int(t / chord_duration) % chord_progression.size()
		var _chord_progress = fmod(t / chord_duration, 1.0)
		var current_chord = chord_progression[chord_index]
		
		# Beat timing with swing
		var beat_time = fmod(t / beat_duration, 1.0)
		var beat_index = int(t / beat_duration) % rhythm_pattern.size()
		var beat_velocity = rhythm_pattern[beat_index]
		
		# Apply swing
		var swing_offset = 0.0
		if beat_index % 2 == 1:  # Off-beats
			swing_offset = swing_amount * 0.1
		beat_time += swing_offset
		
		# Polyrhythmic layer
		var poly_beat_time = fmod(t / (beat_duration * poly_ratio), 1.0)
		var poly_velocity = sin(2.0 * PI * poly_beat_time) * 0.3 + 0.7
		
		# Sample chopping simulation
		var chop_rate = float(chop_density) / 4.0  # Chops per beat
		var chop_time = fmod(t * chop_rate, 1.0)
		var _chop_index = int(t * chop_rate) % 64
		
		# LFO with chaos
		var lfo_base = sin(2.0 * PI * lfo_rate * t)
		var lfo_chaos_mod = sin(2.0 * PI * lfo_rate * 3.7 * t) * lfo_chaos
		var lfo = lfo_base * (1.0 + lfo_chaos_mod)
		
		# Tape wow and flutter
		var wow_freq = 0.5  # 0.5 Hz wow
		var flutter_freq = 15.0  # 15 Hz flutter
		var wow = sin(2.0 * PI * wow_freq * t) * tape_wow_flutter * 0.02
		var flutter = sin(2.0 * PI * flutter_freq * t) * tape_wow_flutter * 0.005
		var tape_modulation = 1.0 + wow + flutter
		
		# Generate layered samples
		var total_wave = 0.0
		
		# Grain size for granular effects (used across multiple modes)
		var grain_size = 0.02 + lfo * 0.01  # 20-30ms grains
		
		for layer in range(sample_layers):
			var layer_chord_index = layer % current_chord.size()
			var semitone_offset = current_chord[layer_chord_index]
			var layer_freq = base_freq * pow(2.0, semitone_offset / 12.0)
			
			# Apply tape modulation to frequency
			layer_freq *= tape_modulation
			
			# Different sample modes
			var layer_wave = 0.0
			match sample_mode:
				"classic_chop":
					layer_wave = sin(2.0 * PI * layer_freq * t)
					if chop_time > 0.8:  # Gate off during chop
						layer_wave = 0.0
				"granular_chop":
					var grain_phase = fmod(chop_time, grain_size * chop_rate)
					var grain_env = sin(grain_phase * PI / (grain_size * chop_rate))
					layer_wave = sin(2.0 * PI * layer_freq * t) * grain_env
				"time_stretch":
					var stretch_factor = 1.0 + lfo * 0.3
					layer_wave = sin(2.0 * PI * layer_freq * t * stretch_factor)
				"pitch_shift":
					var pitch_shift = 1.0 + lfo * 0.2
					layer_wave = sin(2.0 * PI * layer_freq * pitch_shift * t)
				"reverse_grain":
					var reverse_time = grain_size - fmod(t, grain_size)
					layer_wave = sin(2.0 * PI * layer_freq * reverse_time)
				"stutter_mode":
					if randf() < stutter_probability * 0.01:
						var stutter_freq = layer_freq * (2.0 + randf() * 2.0)
						layer_wave = sin(2.0 * PI * stutter_freq * t)
					else:
						layer_wave = sin(2.0 * PI * layer_freq * t)
			
			# Layer-specific processing
			if layer == 0:  # Bass layer
				layer_wave *= (1.0 + bass_emphasis)
				layer_freq *= 0.5  # Sub bass
			elif layer == sample_layers - 1:  # High layer
				layer_wave *= (1.0 - high_freq_roll)
			
			total_wave += layer_wave / sample_layers
		
		# Apply beat velocity and polyrhythm
		total_wave *= beat_velocity * poly_velocity
		
		# Filtering based on type
		var filtered_wave = total_wave
		match filter_type:
			"sp404_vintage":
				# SP-404 style low-pass with resonance
				var cutoff_norm = filter_cutoff / 8000.0
				filtered_wave *= cutoff_norm * (1.0 + filter_resonance)
				# Add some vintage character
				filtered_wave = tanh(filtered_wave * (1.0 + vintage_saturation)) / (1.0 + vintage_saturation)
			"mpc_classic":
				# MPC style filter with slight high cut
				var mpc_factor = clamp(filter_cutoff / 6000.0, 0.4, 1.0)
				filtered_wave *= mpc_factor
			"analog_warmth":
				# Warm analog filtering
				filtered_wave *= clamp(filter_cutoff / 5000.0, 0.3, 1.0)
				filtered_wave = tanh(filtered_wave * 1.2) * 0.8
			"digital_harsh":
				# Harsh digital filtering
				var bits = 16.0 - bit_crush * 12.0
				filtered_wave = floor(filtered_wave * pow(2, bits)) / pow(2, bits)
			"formant_vocal":
				# Vocal formant filtering
				var formant_freq = filter_cutoff
				filtered_wave *= sin(2.0 * PI * formant_freq * t) * 0.3 + 0.7
			"comb_delays":
				# Comb filter delays
				var comb_delay = int(AudioSynthesizer.SAMPLE_RATE / filter_cutoff)
				if i >= comb_delay:
					filtered_wave += total_wave * filter_resonance * 0.5
		
		# Sample rate reduction
		if sample_rate_redux > 0.0:
			var reduced_rate = AudioSynthesizer.SAMPLE_RATE * (1.0 - sample_rate_redux * 0.8)
			var sample_step = float(AudioSynthesizer.SAMPLE_RATE) / reduced_rate
			if int(float(i) / sample_step) == int(float(i - 1) / sample_step):
				# Hold previous sample
				pass
		
		# ADSR envelope per chop
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var chop_samples = chop_time * (AudioSynthesizer.SAMPLE_RATE / chop_rate)
		
		if chop_samples < attack_samples:
			envelope = chop_samples / attack_samples
		elif chop_samples < attack_samples + decay_samples:
			var decay_progress = (chop_samples - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		else:
			envelope = sustain
		
		# Apply envelope
		filtered_wave *= envelope
		
		# Delay effect
		var delayed_sample = delay_buffer[delay_index]
		filtered_wave += delayed_sample * delay_feedback
		delay_buffer[delay_index] = filtered_wave
		delay_index = (delay_index + 1) % delay_buffer_size
		
		# Glitch effects
		if randf() < glitch_amount * 0.001:
			match int(randf() * 4):
				0: filtered_wave *= randf() * 3.0  # Volume spike
				1: filtered_wave = -filtered_wave  # Phase flip
				2: filtered_wave = 0.0  # Dropout
				3: filtered_wave = sin(2.0 * PI * 1000.0 * randf() * t)  # Noise burst
		
		# Reverb simulation
		var reverbed_wave = filtered_wave
		if reverb_amount > 0.0:
			match reverb_space:
				"room":
					var room_delay = int(0.02 * AudioSynthesizer.SAMPLE_RATE)
					if i >= room_delay:
						reverbed_wave += filtered_wave * reverb_amount * 0.3
				"chamber":
					var chamber_delay1 = int(0.04 * AudioSynthesizer.SAMPLE_RATE)
					var chamber_delay2 = int(0.08 * AudioSynthesizer.SAMPLE_RATE)
					if i >= chamber_delay1:
						reverbed_wave += filtered_wave * reverb_amount * 0.4
					if i >= chamber_delay2:
						reverbed_wave += filtered_wave * reverb_amount * 0.2
				"hall":
					var hall_delay1 = int(0.06 * AudioSynthesizer.SAMPLE_RATE)
					var hall_delay2 = int(0.12 * AudioSynthesizer.SAMPLE_RATE)
					var hall_delay3 = int(0.18 * AudioSynthesizer.SAMPLE_RATE)
					if i >= hall_delay1:
						reverbed_wave += filtered_wave * reverb_amount * 0.3
					if i >= hall_delay2:
						reverbed_wave += filtered_wave * reverb_amount * 0.2
					if i >= hall_delay3:
						reverbed_wave += filtered_wave * reverb_amount * 0.1
				"space_delay":
					var space_delay = int(0.25 * AudioSynthesizer.SAMPLE_RATE)
					if i >= space_delay:
						reverbed_wave += filtered_wave * reverb_amount * 0.6
		
		# Stereo width processing
		var stereo_detune = sin(2.0 * PI * 0.7 * t) * stereo_width * 0.02
		var stereo_component = sin(2.0 * PI * base_freq * (1.0 + stereo_detune) * t) * stereo_width * 0.1
		
		# Experimental processing
		if experimental_factor > 0.0:
			# Add some experimental modulation
			var exp_mod1 = sin(2.0 * PI * 1.618 * t) * experimental_factor * 0.1
			var exp_mod2 = cos(2.0 * PI * 2.718 * t) * experimental_factor * 0.05
			reverbed_wave *= (1.0 + exp_mod1 + exp_mod2)
		
		# Final output
		data[i] = (reverbed_wave + stereo_component) * amplitude

# =============================================================================
# HEARTBEAT - Biological heartbeat with lub-dub rhythm
# =============================================================================
static func generate_custom_heartbeat(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var bpm = params.get("bpm", 70.0)
	var amplitude = params.get("amplitude", 0.4)
	var depth = params.get("depth", 0.8)

	var _duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var beat_interval = 60.0 / bpm  # Time between heartbeats

	# Heartbeat frequencies - low thump
	var lub_freq = 40.0  # First beat (lub) - lower
	var dub_freq = 55.0  # Second beat (dub) - slightly higher
	var lub_dub_gap = 0.15  # Gap between lub and dub in seconds

	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count

		# Find position within current beat cycle
		var beat_phase = fmod(t, beat_interval)

		# Generate lub-dub pattern
		var wave = 0.0

		# LUB (first thump) - occurs at start of beat
		var lub_duration = 0.08
		if beat_phase < lub_duration:
			var lub_progress = beat_phase / lub_duration
			var lub_envelope = sin(PI * lub_progress)  # Smooth bump
			var lub_wave = sin(2.0 * PI * lub_freq * beat_phase)
			# Add harmonics for body resonance
			lub_wave += 0.3 * sin(2.0 * PI * lub_freq * 2.0 * beat_phase)
			wave += lub_wave * lub_envelope * depth

		# DUB (second thump) - occurs after gap
		var dub_start = lub_dub_gap
		var dub_duration = 0.06
		if beat_phase > dub_start and beat_phase < dub_start + dub_duration:
			var dub_local = beat_phase - dub_start
			var dub_progress = dub_local / dub_duration
			var dub_envelope = sin(PI * dub_progress) * 0.7  # Slightly softer
			var dub_wave = sin(2.0 * PI * dub_freq * dub_local)
			dub_wave += 0.2 * sin(2.0 * PI * dub_freq * 2.0 * dub_local)
			wave += dub_wave * dub_envelope * depth

		# Add subtle body resonance between beats
		var body_resonance = sin(2.0 * PI * 25.0 * t) * 0.02 * depth
		wave += body_resonance

		# Overall envelope for fade in/out
		var overall_envelope = 1.0
		if progress < 0.05:
			overall_envelope = progress / 0.05
		elif progress > 0.95:
			overall_envelope = (1.0 - progress) / 0.05

		data[i] = wave * overall_envelope * amplitude

# =============================================================================
# LAB_HUM - Sterile sci-fi lab ambience with multi-layered sine hum
# =============================================================================
static func generate_custom_lab_hum(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var base_freq = params.get("base_freq", 60.0)  # Electrical hum frequency (50Hz EU / 60Hz US)
	var amplitude = params.get("amplitude", 0.25)
	var mod_depth = params.get("mod_depth", 0.3)

	var _duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE

	# Multiple harmonic layers for rich lab ambience
	var harmonics = [1.0, 2.0, 3.0, 5.0]  # Fundamental + harmonics
	var harmonic_levels = [1.0, 0.3, 0.15, 0.08]  # Decreasing levels

	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count

		var wave = 0.0

		# Layer 1: Base electrical hum with harmonics
		for h in range(harmonics.size()):
			var freq = base_freq * harmonics[h]
			var level = harmonic_levels[h]
			wave += sin(2.0 * PI * freq * t) * level

		# Layer 2: Slow amplitude modulation (breathing effect)
		var slow_mod = 1.0 + sin(2.0 * PI * 0.1 * t) * mod_depth * 0.3
		wave *= slow_mod

		# Layer 3: Subtle high-frequency shimmer (fluorescent light flicker)
		var flicker_freq = 120.0  # Double mains frequency
		var flicker = sin(2.0 * PI * flicker_freq * t) * 0.05
		wave += flicker

		# Layer 4: Very low drone for depth
		var sub_drone = sin(2.0 * PI * 30.0 * t) * 0.15 * mod_depth
		wave += sub_drone

		# Layer 5: Random subtle variation (air circulation texture)
		var noise_mod = sin(2.0 * PI * 0.3 * t + sin(2.0 * PI * 0.7 * t) * 2.0)
		wave *= (1.0 + noise_mod * mod_depth * 0.1)

		# Sterile clinical character - slight phase shift for width
		var stereo_component = sin(2.0 * PI * base_freq * 1.001 * t) * 0.1
		wave += stereo_component

		# Overall envelope
		var envelope = 1.0
		if progress < 0.1:
			envelope = progress / 0.1  # Slow fade in
		elif progress > 0.9:
			envelope = (1.0 - progress) / 0.1  # Slow fade out

		# Smoothstep the envelope
		envelope = envelope * envelope * (3.0 - 2.0 * envelope)

		data[i] = wave * envelope * amplitude * 0.5  # Keep levels moderate

# =============================================================================
# GENRE-DEFINING BASS SOUNDS
# Research-based synthesis for authentic genre character
# =============================================================================

# =============================================================================
# REESE BASS - DnB Essential (Juno-106 style)
# Detuned saws with slow phasing movement, dark and ominous
# Hardware: Originally Juno-106, later refined in samplers
# =============================================================================
static func generate_custom_reese_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Accept both specific and common parameter names
	var freq = params.get("frequency", params.get("freq", 55.0))
	var detune_cents = params.get("detune_cents", params.get("detune", 12.0))
	var num_voices = int(params.get("voices", 3))
	var phase_rate = params.get("phase_rate", params.get("movement", 0.3))
	var filter_cutoff = params.get("filter_cutoff", params.get("cutoff", 800.0))
	var filter_resonance = params.get("filter_resonance", params.get("resonance", 0.3))
	var distortion = params.get("distortion", params.get("drive", 0.4))
	var attack = params.get("attack", 0.05)
	var release = params.get("release", 0.3)
	var amplitude = params.get("amplitude", params.get("amp", 0.45))
	
	print("[SYNTH] REESE BASS GENERATING - DnB essential with %d detuned voices" % num_voices)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	# Calculate detune ratios for each voice
	var detune_ratios = []
	for v in range(num_voices):
		var cents_offset = (float(v) / (num_voices - 1) - 0.5) * detune_cents * 2.0 if num_voices > 1 else 0.0
		detune_ratios.append(pow(2.0, cents_offset / 1200.0))
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Phase modulation for movement (the reese "wobble")
		var phase_mod = sin(2.0 * PI * phase_rate * t) * 0.5
		
		# Generate detuned sawtooth oscillators
		var wave = 0.0
		for v in range(num_voices):
			var voice_freq = freq * detune_ratios[v]
			# Add phase offset per voice for stereo width
			var phase_offset = float(v) * 0.3 + phase_mod * (0.5 if v % 2 == 0 else -0.5)
			var saw = 2.0 * fmod(voice_freq * t + phase_offset, 1.0) - 1.0
			wave += saw
		wave /= num_voices
		
		# Low-pass filter with slight resonance
		var filter_env = 1.0 - exp(-progress * 3.0)  # Filter opens over time
		var dynamic_cutoff = filter_cutoff * (0.5 + filter_env * 0.5)
		var filter_factor = clamp(dynamic_cutoff / 4000.0, 0.1, 1.0)
		wave *= filter_factor * (1.0 + filter_resonance * 0.5)
		
		# Soft distortion for warmth and grit
		if distortion > 0.0:
			wave = tanh(wave * (1.0 + distortion * 2.0)) / (1.0 + distortion)
		
		# ADSR envelope
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i >= release_start:
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = 1.0 - release_progress
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# WOBBLE BASS - Dubstep (Massive/FM8 style)
# LFO on filter cutoff, aggressive character
# =============================================================================
static func generate_custom_wobble_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 55.0))
	var wobble_rate = params.get("wobble_rate", params.get("lfo_rate", 4.0))
	var wobble_depth = params.get("wobble_depth", params.get("lfo_depth", 0.8))
	var base_cutoff = params.get("base_cutoff", params.get("cutoff", 400.0))
	var max_cutoff = params.get("max_cutoff", 4000.0)
	var resonance = params.get("resonance", 0.7)
	var distortion = params.get("distortion", params.get("drive", 0.6))
	var sub_amount = params.get("sub_amount", params.get("sub", 0.3))
	var attack = params.get("attack", 0.01)
	var release = params.get("release", 0.2)
	var amplitude = params.get("amplitude", params.get("amp", 0.5))
	
	print("[SYNTH] WOBBLE BASS GENERATING - Dubstep with %.1f Hz LFO" % wobble_rate)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# LFO for wobble (sine or triangle based on depth)
		var lfo = sin(2.0 * PI * wobble_rate * t)
		lfo = (lfo + 1.0) * 0.5  # Normalize to 0-1
		
		# Main oscillator - sawtooth
		var saw = 2.0 * fmod(freq * t, 1.0) - 1.0
		
		# Add sub oscillator (sine, one octave down)
		var sub = sin(2.0 * PI * freq * 0.5 * t) * sub_amount
		
		var wave = saw + sub
		
		# Dynamic filter cutoff driven by LFO
		var cutoff = base_cutoff + lfo * wobble_depth * (max_cutoff - base_cutoff)
		var filter_factor = clamp(cutoff / 6000.0, 0.05, 1.0)
		
		# Resonant filter simulation
		var resonance_boost = 1.0 + resonance * 2.0 * lfo
		wave *= filter_factor * resonance_boost
		
		# Add resonant peak
		var resonant_peak = sin(2.0 * PI * cutoff * t) * resonance * 0.15 * lfo
		wave += resonant_peak
		
		# Heavy distortion for aggression
		if distortion > 0.0:
			wave = tanh(wave * (1.0 + distortion * 3.0)) / (1.0 + distortion * 0.5)
		
		# Envelope
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i >= release_start:
			envelope = 1.0 - (i - release_start) / (sample_count - release_start)
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# PLUCK BASS - House/Pop (Juno-60 style)
# Fast attack, medium decay, punchy and defined
# =============================================================================
static func generate_custom_pluck_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 82.4))  # E2
	var attack = params.get("attack", 0.005)
	var decay = params.get("decay", 0.25)
	var sustain = params.get("sustain", 0.2)
	var filter_attack = params.get("filter_attack", 0.01)
	var filter_decay = params.get("filter_decay", 0.15)
	var filter_base = params.get("filter_base", params.get("cutoff", 500.0))
	var filter_peak = params.get("filter_peak", 3000.0)
	var resonance = params.get("resonance", 0.4)
	var wave_type = params.get("wave_type", params.get("waveform", "saw"))
	var amplitude = params.get("amplitude", params.get("amp", 0.5))
	
	print("[SYNTH] PLUCK BASS GENERATING - House/Pop punchy bass with %s wave" % wave_type)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Generate base waveform
		var wave = 0.0
		match wave_type:
			"saw", "sawtooth":
				wave = 2.0 * fmod(freq * t, 1.0) - 1.0
			"square":
				wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
			"triangle":
				var phase = fmod(freq * t, 1.0)
				wave = 4.0 * abs(phase - 0.5) - 1.0
			_:
				wave = 2.0 * fmod(freq * t, 1.0) - 1.0
		
		# Filter envelope (fast attack, medium decay)
		var filter_env = 0.0
		if t < filter_attack:
			filter_env = t / filter_attack
		else:
			filter_env = exp(-(t - filter_attack) / filter_decay)
		
		var cutoff = filter_base + filter_env * (filter_peak - filter_base)
		var filter_factor = clamp(cutoff / 5000.0, 0.1, 1.0)
		wave *= filter_factor * (1.0 + resonance * filter_env)
		
		# Amplitude envelope (plucky)
		var envelope = 0.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		else:
			envelope = sustain * exp(-(progress - (attack + decay) / duration) * 2.0)
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# SUB BASS SINE - Pure Sub (808 style)
# Clean sine wave, no harmonics, foundation layer
# =============================================================================
static func generate_custom_sub_bass_sine(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 40.0))
	var attack = params.get("attack", 0.02)
	var decay = params.get("decay", 0.5)
	var sustain = params.get("sustain", 0.8)
	var release = params.get("release", 0.5)
	var pitch_drop = params.get("pitch_drop", params.get("drop", 0.0))  # Semitones to drop
	var pitch_drop_time = params.get("pitch_drop_time", 0.05)
	var amplitude = params.get("amplitude", params.get("amp", 0.6))
	
	print("[SYNTH] SUB BASS SINE GENERATING - Pure sub at %.1f Hz" % freq)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Pitch drop (808-style)
		var current_freq = freq
		if pitch_drop > 0.0 and t < pitch_drop_time:
			var drop_progress = t / pitch_drop_time
			var semitone_offset = pitch_drop * (1.0 - drop_progress)
			current_freq = freq * pow(2.0, semitone_offset / 12.0)
		
		# Pure sine wave
		var wave = sin(2.0 * PI * current_freq * t)
		
		# Soft ADSR envelope (no clicks)
		var envelope = 0.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
			envelope = envelope * envelope * (3.0 - 2.0 * envelope)  # Smoothstep
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		elif i < release_start:
			envelope = sustain
		else:
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = sustain * (1.0 - release_progress)
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# DISTORTED BASS - Rock/Industrial (Bass guitar + tube amp)
# Tube saturation, gritty character
# =============================================================================
static func generate_custom_distorted_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 82.4))  # E2
	var drive = params.get("drive", params.get("distortion", 0.7))
	var tone = params.get("tone", 0.6)  # 0 = dark, 1 = bright
	var presence = params.get("presence", 0.4)
	var attack = params.get("attack", 0.01)
	var sustain_level = params.get("sustain", 0.7)
	var release = params.get("release", 0.3)
	var sub_mix = params.get("sub_mix", params.get("sub", 0.2))
	var amplitude = params.get("amplitude", params.get("amp", 0.5))
	
	print("[SYNTH] DISTORTED BASS GENERATING - Rock/Industrial with drive %.2f" % drive)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Main oscillator - saw for harmonics
		var saw = 2.0 * fmod(freq * t, 1.0) - 1.0
		
		# Add square for more aggressive character
		var square = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
		
		# Sub oscillator (clean sine for low end)
		var sub = sin(2.0 * PI * freq * 0.5 * t) * sub_mix
		
		# Mix oscillators
		var wave = saw * 0.6 + square * 0.4
		
		# Tube saturation stages (cascaded for more harmonics)
		var drive_amount = 1.0 + drive * 4.0
		wave = tanh(wave * drive_amount)
		wave = tanh(wave * (1.0 + drive * 2.0))  # Second stage
		
		# Add odd harmonics (tube character)
		if presence > 0.0:
			wave += sin(2.0 * PI * freq * 3.0 * t) * presence * 0.1
			wave += sin(2.0 * PI * freq * 5.0 * t) * presence * 0.05
		
		# Tone control (simple high-pass/low-pass balance)
		var filter_factor = 0.3 + tone * 0.7
		wave *= filter_factor
		
		# Mix in clean sub
		wave = wave * (1.0 - sub_mix * 0.5) + sub
		
		# Envelope
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		elif i < release_start:
			envelope = sustain_level
		else:
			envelope = sustain_level * (1.0 - (i - release_start) / (sample_count - release_start))
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# JUNO BASS - 80s Pop (Roland Juno-106)
# Chorus, warmth, classic Roland character
# =============================================================================
static func generate_custom_juno_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 82.4))
	var sub_level = params.get("sub_level", params.get("sub", 0.5))
	var chorus_rate = params.get("chorus_rate", 0.5)
	var chorus_depth = params.get("chorus_depth", params.get("chorus", 0.3))
	var filter_cutoff = params.get("filter_cutoff", params.get("cutoff", 1500.0))
	var filter_resonance = params.get("filter_resonance", params.get("resonance", 0.3))
	var filter_env = params.get("filter_env", 0.5)
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.3)
	var sustain = params.get("sustain", 0.6)
	var release = params.get("release", 0.4)
	var amplitude = params.get("amplitude", params.get("amp", 0.45))
	
	print("[SYNTH] JUNO BASS GENERATING - 80s pop with Roland chorus")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Main oscillator - sawtooth
		var saw = 2.0 * fmod(freq * t, 1.0) - 1.0
		
		# Sub oscillator - square one octave down (Juno characteristic)
		var sub = (1.0 if sin(2.0 * PI * freq * 0.5 * t) > 0 else -1.0) * sub_level
		
		# Juno chorus (3 slightly detuned voices with LFO)
		var chorus_lfo = sin(2.0 * PI * chorus_rate * t)
		var voice1 = 2.0 * fmod(freq * (1.0 + chorus_depth * 0.01 * chorus_lfo) * t, 1.0) - 1.0
		var voice2 = 2.0 * fmod(freq * (1.0 - chorus_depth * 0.01 * chorus_lfo) * t, 1.0) - 1.0
		var voice3 = 2.0 * fmod(freq * (1.0 + chorus_depth * 0.005 * sin(chorus_lfo * 1.3)) * t, 1.0) - 1.0
		
		var chorused = (saw + voice1 + voice2 + voice3) / 4.0
		
		# Mix main and sub
		var wave = chorused * 0.7 + sub * 0.3
		
		# Filter envelope
		var f_env = 1.0
		var env_time = t * 8.0  # Fast filter env
		f_env = exp(-env_time) * filter_env + (1.0 - filter_env)
		
		var dynamic_cutoff = filter_cutoff * (0.5 + f_env * 0.5)
		var filter_factor = clamp(dynamic_cutoff / 4000.0, 0.2, 1.0)
		wave *= filter_factor * (1.0 + filter_resonance * f_env)
		
		# Amplitude envelope
		var envelope = 0.0
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
			envelope = sustain * (1.0 - (i - release_start) / (sample_count - release_start))
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# MINIMOOG BASS - Funk/Soul (Moog Model D)
# Ladder filter, fat and warm, oscillator stacking
# =============================================================================
static func generate_custom_minimoog_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 55.0))  # A1
	var osc1_wave = params.get("osc1_wave", "saw")
	var osc2_wave = params.get("osc2_wave", "square")
	var osc2_detune = params.get("osc2_detune", params.get("detune", 0.05))
	var osc2_octave = params.get("osc2_octave", 0)  # 0, -1, +1
	var osc_mix = params.get("osc_mix", 0.5)
	var filter_cutoff = params.get("filter_cutoff", params.get("cutoff", 1000.0))
	var filter_resonance = params.get("filter_resonance", params.get("resonance", 0.5))
	var filter_env_amount = params.get("filter_env_amount", params.get("env_mod", 0.7))
	var filter_attack = params.get("filter_attack", 0.01)
	var filter_decay = params.get("filter_decay", 0.3)
	var amp_attack = params.get("attack", 0.005)
	var amp_decay = params.get("decay", 0.3)
	var amp_sustain = params.get("sustain", 0.8)
	var amp_release = params.get("release", 0.3)
	var keyboard_tracking = params.get("keyboard_tracking", 0.5)
	var amplitude = params.get("amplitude", params.get("amp", 0.5))
	
	print("[SYNTH] MINIMOOG BASS GENERATING - Fat Moog ladder filter")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Oscillator 1
		var osc1 = 0.0
		match osc1_wave:
			"saw", "sawtooth":
				osc1 = 2.0 * fmod(freq * t, 1.0) - 1.0
			"square":
				osc1 = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
			"triangle":
				var phase = fmod(freq * t, 1.0)
				osc1 = 4.0 * abs(phase - 0.5) - 1.0
		
		# Oscillator 2 (detuned, possibly different octave)
		var osc2_freq = freq * pow(2.0, osc2_octave) * (1.0 + osc2_detune)
		var osc2 = 0.0
		match osc2_wave:
			"saw", "sawtooth":
				osc2 = 2.0 * fmod(osc2_freq * t, 1.0) - 1.0
			"square":
				osc2 = 1.0 if sin(2.0 * PI * osc2_freq * t) > 0 else -1.0
			"triangle":
				var phase = fmod(osc2_freq * t, 1.0)
				osc2 = 4.0 * abs(phase - 0.5) - 1.0
		
		# Mix oscillators
		var wave = osc1 * (1.0 - osc_mix) + osc2 * osc_mix
		
		# Moog ladder filter envelope
		var filter_env = 0.0
		if t < filter_attack:
			filter_env = t / filter_attack
		else:
			filter_env = exp(-(t - filter_attack) / filter_decay)
		
		# Keyboard tracking affects cutoff
		var kb_track = 1.0 + (freq / 440.0 - 1.0) * keyboard_tracking
		var dynamic_cutoff = filter_cutoff * kb_track
		dynamic_cutoff += filter_env * filter_env_amount * 3000.0
		
		# 4-pole ladder filter simulation
		var filter_factor = clamp(dynamic_cutoff / 5000.0, 0.1, 1.0)
		var resonance_boost = 1.0 + filter_resonance * 3.0 * filter_env
		
		# Cascaded filtering (Moog ladder approximation)
		for pole in range(4):
			wave *= filter_factor * 0.9
		wave *= resonance_boost
		
		# Warm saturation (Moog transistor character)
		wave = tanh(wave * 1.3)
		
		# Amplitude envelope
		var envelope = 0.0
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
			envelope = amp_sustain * (1.0 - (i - release_start) / (sample_count - release_start))
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# SH-101 BASS - Acid/Electro (Roland SH-101)
# Single oscillator, high resonance, glide/slide
# =============================================================================
static func generate_custom_sh101_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 55.0))
	var target_freq = params.get("target_freq", freq * 1.5)  # For slide
	var glide_time = params.get("glide_time", params.get("glide", 0.15))
	var wave_type = params.get("wave_type", params.get("waveform", "saw"))
	var filter_cutoff = params.get("filter_cutoff", params.get("cutoff", 600.0))
	var filter_resonance = params.get("filter_resonance", params.get("resonance", 0.75))
	var filter_env_amount = params.get("filter_env_amount", params.get("env_mod", 0.8))
	var filter_decay = params.get("filter_decay", 0.4)
	var accent = params.get("accent", 0.5)
	var attack = params.get("attack", 0.005)
	var decay = params.get("decay", 0.5)
	var sustain = params.get("sustain", 0.3)
	var release = params.get("release", 0.2)
	var amplitude = params.get("amplitude", params.get("amp", 0.45))
	
	print("[SYNTH] SH-101 BASS GENERATING - Acid squelch with %.2f resonance" % filter_resonance)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var current_freq = freq
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Portamento/glide
		if t < glide_time:
			var glide_progress = t / glide_time
			glide_progress = glide_progress * glide_progress * (3.0 - 2.0 * glide_progress)  # Smoothstep
			current_freq = freq + (target_freq - freq) * glide_progress
		else:
			current_freq = target_freq
		
		# Single oscillator
		var wave = 0.0
		match wave_type:
			"saw", "sawtooth":
				wave = 2.0 * fmod(current_freq * t, 1.0) - 1.0
			"square":
				wave = 1.0 if sin(2.0 * PI * current_freq * t) > 0 else -1.0
			"pulse":
				var phase = fmod(current_freq * t, 1.0)
				wave = 1.0 if phase < 0.25 else -1.0  # Narrow pulse
		
		# Filter envelope with accent
		var filter_env = exp(-t / filter_decay)
		var accent_boost = 1.0 + accent * 0.5 * filter_env
		
		# Resonant filter (SH-101/303 character)
		var dynamic_cutoff = filter_cutoff + filter_env * filter_env_amount * 3000.0 * accent_boost
		var filter_factor = clamp(dynamic_cutoff / 5000.0, 0.05, 1.0)
		
		# High resonance creates the squelch
		var resonance_boost = 1.0 + filter_resonance * 3.0
		wave *= filter_factor * resonance_boost
		
		# Add resonant peak (the acid "squelch")
		var resonant_peak = sin(2.0 * PI * dynamic_cutoff * t) * filter_resonance * 0.2 * filter_env
		wave += resonant_peak
		
		# Slight distortion for grit
		wave = tanh(wave * 1.5)
		
		# Amplitude envelope
		var envelope = 0.0
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
			envelope = sustain * (1.0 - (i - release_start) / (sample_count - release_start))
		
		# Accent affects amplitude too
		envelope *= accent_boost
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# PROPHET BASS - Synthwave (Sequential Prophet-5)
# Lush, complex, poly-mod for character
# =============================================================================
static func generate_custom_prophet_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 82.4))
	var osc_detune = params.get("osc_detune", params.get("detune", 0.08))
	var poly_mod_amount = params.get("poly_mod_amount", params.get("poly_mod", 0.3))
	var poly_mod_rate = params.get("poly_mod_rate", 5.0)
	var filter_cutoff = params.get("filter_cutoff", params.get("cutoff", 1200.0))
	var filter_resonance = params.get("filter_resonance", params.get("resonance", 0.4))
	var filter_env = params.get("filter_env", 0.6)
	var unison_voices = int(params.get("unison_voices", params.get("voices", 4)))
	var unison_spread = params.get("unison_spread", 0.02)
	var attack = params.get("attack", 0.02)
	var decay = params.get("decay", 0.4)
	var sustain = params.get("sustain", 0.6)
	var release = params.get("release", 0.5)
	var amplitude = params.get("amplitude", params.get("amp", 0.4))
	
	print("[SYNTH] PROPHET BASS GENERATING - Synthwave lush with %d unison voices" % unison_voices)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Poly-mod LFO (Prophet-5 characteristic)
		var poly_mod = sin(2.0 * PI * poly_mod_rate * t) * poly_mod_amount
		
		# Generate unison voices
		var wave = 0.0
		for v in range(unison_voices):
			var voice_detune = (float(v) / (unison_voices - 1) - 0.5) * unison_spread if unison_voices > 1 else 0.0
			var voice_freq = freq * (1.0 + voice_detune + osc_detune)
			
			# Saw with poly-mod on pitch
			var mod_freq = voice_freq * (1.0 + poly_mod * 0.02)
			var saw = 2.0 * fmod(mod_freq * t, 1.0) - 1.0
			wave += saw
		wave /= unison_voices
		
		# Filter with envelope
		var f_env = exp(-t * 3.0) * filter_env + (1.0 - filter_env)
		var dynamic_cutoff = filter_cutoff * (0.5 + f_env * 0.5)
		dynamic_cutoff += poly_mod * 200.0  # Poly-mod affects filter
		
		var filter_factor = clamp(dynamic_cutoff / 4000.0, 0.2, 1.0)
		wave *= filter_factor * (1.0 + filter_resonance * f_env)
		
		# Slight warmth
		wave = tanh(wave * 1.2)
		
		# Amplitude envelope
		var envelope = 0.0
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
			envelope = sustain * (1.0 - (i - release_start) / (sample_count - release_start))
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# UPRIGHT BASS - Jazz/Lo-fi (Physical modeling)
# Body resonance, finger noise, woody character
# =============================================================================
static func generate_custom_upright_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 82.4))
	var body_resonance = params.get("body_resonance", params.get("body", 0.4))
	var finger_noise = params.get("finger_noise", params.get("noise", 0.15))
	var string_tension = params.get("string_tension", params.get("tension", 0.6))
	var attack = params.get("attack", 0.03)
	var decay = params.get("decay", 1.0)
	var sustain = params.get("sustain", 0.4)
	var release = params.get("release", 0.5)
	var warmth = params.get("warmth", 0.7)
	var amplitude = params.get("amplitude", params.get("amp", 0.5))
	
	print("[SYNTH] UPRIGHT BASS GENERATING - Jazz with body resonance")
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	# Body resonance frequencies (typical upright bass)
	var body_freqs = [62.0, 95.0, 123.0, 185.0]
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# String vibration (Karplus-Strong inspired)
		var string_wave = sin(2.0 * PI * freq * t)
		# Add harmonics with decay
		string_wave += sin(2.0 * PI * freq * 2.0 * t) * 0.5 * exp(-t * 2.0)
		string_wave += sin(2.0 * PI * freq * 3.0 * t) * 0.25 * exp(-t * 3.0)
		string_wave += sin(2.0 * PI * freq * 4.0 * t) * 0.12 * exp(-t * 4.0)
		
		# String tension affects brightness
		string_wave *= (0.5 + string_tension * 0.5)
		
		# Body resonance
		var body_wave = 0.0
		for bf in body_freqs:
			var resonance_amount = exp(-abs(freq - bf) / 50.0) * body_resonance
			body_wave += sin(2.0 * PI * bf * t) * resonance_amount * exp(-t * 1.5)
		
		# Finger noise on attack
		var noise = 0.0
		if t < 0.05:
			var noise_t = t * 8000.0
			noise = (sin(noise_t) * 0.4 + sin(noise_t * 1.7) * 0.3) * exp(-t * 60.0) * finger_noise
		
		var wave = string_wave + body_wave * 0.3 + noise
		
		# Warmth (low-pass character)
		var filter_factor = 0.3 + warmth * 0.4
		wave *= filter_factor
		
		# Envelope
		var envelope = 0.0
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
			envelope = sustain * (1.0 - (i - release_start) / (sample_count - release_start))
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# SLAP BASS - Funk (Bass guitar technique)
# Sharp attack transient, string slap, percussive
# =============================================================================
static func generate_custom_slap_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 82.4))
	var slap_intensity = params.get("slap_intensity", params.get("slap", 0.8))
	var pop_amount = params.get("pop_amount", params.get("pop", 0.5))
	var string_brightness = params.get("string_brightness", params.get("brightness", 0.7))
	var attack = params.get("attack", 0.002)
	var decay = params.get("decay", 0.3)
	var sustain = params.get("sustain", 0.3)
	var release = params.get("release", 0.15)
	var compression = params.get("compression", 0.6)
	var amplitude = params.get("amplitude", params.get("amp", 0.55))
	
	print("[SYNTH] SLAP BASS GENERATING - Funk with slap intensity %.2f" % slap_intensity)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Slap transient (bright, percussive)
		var slap = 0.0
		if t < 0.015:
			var slap_env = exp(-t * 150.0)
			# High frequency content for the "slap" sound
			slap = sin(t * 4000.0) * 0.5 + sin(t * 6000.0) * 0.3 + sin(t * 8000.0) * 0.2
			slap *= slap_env * slap_intensity
		
		# Pop/pluck attack
		var pop = 0.0
		if t < 0.03:
			var pop_env = exp(-t * 80.0)
			pop = sin(2.0 * PI * freq * 4.0 * t) * pop_env * pop_amount
		
		# Main string vibration
		var string_wave = sin(2.0 * PI * freq * t)
		# Harmonics for brightness
		string_wave += sin(2.0 * PI * freq * 2.0 * t) * 0.4 * string_brightness
		string_wave += sin(2.0 * PI * freq * 3.0 * t) * 0.2 * string_brightness
		string_wave += sin(2.0 * PI * freq * 4.0 * t) * 0.1 * string_brightness
		
		var wave = slap + pop + string_wave
		
		# Compression for funk punch
		if compression > 0.0:
			var threshold = 0.6
			if abs(wave) > threshold:
				var excess = abs(wave) - threshold
				wave = sign(wave) * (threshold + excess * (1.0 - compression))
		
		# Envelope
		var envelope = 0.0
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
			envelope = sustain * (1.0 - (i - release_start) / (sample_count - release_start))
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# PICKED BASS - Rock (Electric bass with pick)
# Pick attack, string vibration, defined articulation
# =============================================================================
static func generate_custom_picked_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq = params.get("frequency", params.get("freq", 82.4))
	var pick_hardness = params.get("pick_hardness", params.get("pick", 0.7))
	var pick_position = params.get("pick_position", params.get("position", 0.3))  # 0 = bridge, 1 = neck
	var tone = params.get("tone", 0.6)
	var attack = params.get("attack", 0.003)
	var decay = params.get("decay", 0.5)
	var sustain = params.get("sustain", 0.5)
	var release = params.get("release", 0.25)
	var drive = params.get("drive", 0.2)
	var amplitude = params.get("amplitude", params.get("amp", 0.5))
	
	print("[SYNTH] PICKED BASS GENERATING - Rock with pick hardness %.2f" % pick_hardness)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Pick attack noise
		var pick_noise = 0.0
		if t < 0.01:
			var pick_env = exp(-t * 200.0) * pick_hardness
			# Bright transient for pick
			pick_noise = sin(t * 5000.0) * 0.4 + sin(t * 7500.0) * 0.3
			pick_noise *= pick_env
		
		# Main string vibration
		var string_wave = sin(2.0 * PI * freq * t)
		
		# Harmonics depend on pick position
		# Closer to bridge = more harmonics
		var harmonic_amount = 1.0 - pick_position * 0.5
		string_wave += sin(2.0 * PI * freq * 2.0 * t) * 0.5 * harmonic_amount
		string_wave += sin(2.0 * PI * freq * 3.0 * t) * 0.3 * harmonic_amount
		string_wave += sin(2.0 * PI * freq * 4.0 * t) * 0.15 * harmonic_amount
		string_wave += sin(2.0 * PI * freq * 5.0 * t) * 0.08 * harmonic_amount
		
		var wave = pick_noise + string_wave
		
		# Tone control
		wave *= (0.4 + tone * 0.6)
		
		# Optional drive
		if drive > 0.0:
			wave = tanh(wave * (1.0 + drive * 2.0)) / (1.0 + drive * 0.5)
		
		# Envelope
		var envelope = 0.0
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
			envelope = sustain * (1.0 - (i - release_start) / (sample_count - release_start))
		
		data[i] = wave * envelope * amplitude

# =============================================================================
# ESSENTIAL DRUM SOUNDS - Production-quality drum synthesis
# =============================================================================

# =============================================================================
# CLAP - TR-909 style layered noise bursts with room character
# Reference: Roland TR-909, LinnDrum - the sound of house/pop music
# Technique: Multiple short noise bursts (4-8) layered with 15-30ms delays
# =============================================================================
static func generate_custom_clap(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 0.35))
	var tone = params.get("tone", 0.6)  # 0=dark, 1=bright
	var room = params.get("room", 0.3)  # Room reverb amount
	var layers = int(params.get("layers", 5))  # Number of clap layers (4-8)
	var spread = params.get("spread", 0.025)  # Time spread between layers (seconds)
	var filter_freq = params.get("filter_freq", 1200.0 + tone * 800.0)  # Bandpass center
	var amplitude = params.get("amplitude", 0.5)
	
	# Layer timing - each clap hits slightly after the previous
	var layer_times = []
	for layer in range(layers):
		# Slightly randomized timing for natural feel
		layer_times.append(layer * spread * (0.8 + randf() * 0.4))
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var wave = 0.0
		
		# Generate each clap layer
		for layer in range(layers):
			var layer_t = t - layer_times[layer]
			if layer_t >= 0:
				# Each layer is a short noise burst
				var layer_duration = 0.015 + randf() * 0.01  # 15-25ms per burst
				
				if layer_t < layer_duration:
					# Generate bandpass-filtered noise
					var noise = 0.0
					for n in range(6):
						var freq = filter_freq * (0.5 + float(n) * 0.3)
						noise += sin(t * freq * 2.0 * PI + n * 1.37) * (1.0 / (n + 1))
					noise = tanh(noise * 2.0)  # Soft clip for density
					
					# Short attack, fast decay per layer
					var layer_env = exp(-layer_t / layer_duration * 3.0)
					
					# Later layers are slightly quieter
					var layer_amp = 1.0 - float(layer) / layers * 0.3
					
					wave += noise * layer_env * layer_amp
		
		# Overall envelope with room tail
		var main_envelope = exp(-t / decay)
		
		# Add room reverb simulation (simple delay + decay)
		var room_wave = 0.0
		if room > 0.0:
			var room_delay = 0.03  # 30ms early reflection
			var room_t = t - room_delay
			if room_t > 0:
				room_wave = wave * exp(-room_t / (decay * 1.5)) * room
		
		# Apply high-pass filter to remove rumble (claps have no low end)
		var hp_factor = 0.8 + tone * 0.15
		
		data[i] = (wave + room_wave) * main_envelope * hp_factor * amplitude

# =============================================================================
# OPEN_HIHAT - TR-909/808 style long decay metallic hi-hat
# Reference: Roland TR-909, TR-808 - essential for groove
# Technique: Multiple square wave oscillators at inharmonic ratios
# =============================================================================
static func generate_custom_open_hihat(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 0.5))  # Longer than closed
	var tone = params.get("tone", 0.7)  # 0=dark, 1=bright
	var metallic = params.get("metallic", 0.6)  # Metallic ring amount
	var amplitude = params.get("amplitude", 0.35)
	
	# TR-909 uses 6 square wave oscillators at these ratios for metallic character
	var osc_ratios = [1.0, 1.28, 1.42, 1.67, 2.0, 2.14]
	var base_freq = 200.0 + tone * 100.0  # Base frequency for metallic oscillators
	
	# High-frequency noise component frequencies
	var noise_freq_base = 8000.0 + tone * 4000.0
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Metallic oscillator component (6 oscillators at inharmonic ratios)
		var metallic_wave = 0.0
		for osc in range(osc_ratios.size()):
			var freq = base_freq * osc_ratios[osc]
			# Square wave for each oscillator
			var phase = fmod(freq * t, 1.0)
			var sq = 1.0 if phase < 0.5 else -1.0
			metallic_wave += sq * (1.0 / osc_ratios.size())
		
		# Ring modulate for extra complexity
		metallic_wave *= sin(2.0 * PI * base_freq * 1.5 * t)
		
		# Noise component (high-pass filtered white noise simulation)
		var noise = 0.0
		for n in range(8):
			var freq = noise_freq_base + n * 1200.0
			noise += sin(t * freq + n * 2.13) * (1.0 / (n + 1))
		noise = tanh(noise * 1.5)
		
		# Mix metallic and noise based on metallic parameter
		var wave = metallic_wave * metallic + noise * (1.0 - metallic * 0.5)
		
		# Open hi-hat envelope: instant attack, long exponential decay
		var envelope = exp(-t / decay)
		
		# Tone shaping: reduce lows, emphasize highs
		var high_emphasis = 0.7 + tone * 0.3
		
		data[i] = wave * envelope * high_emphasis * amplitude

# =============================================================================
# SNARE_ACOUSTIC - Layered acoustic snare with body, wires, and air
# Reference: Real acoustic snare drums, not electronic
# Technique: Drum body (sine/triangle), snare wires (high noise), transient
# =============================================================================
static func generate_custom_snare_acoustic(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 0.25))
	var pitch = params.get("pitch", 200.0)  # Body pitch (150-250Hz typical)
	var wire_amount = params.get("wires", params.get("snare", 0.6))  # Snare wire level
	var body_amount = params.get("body", 0.5)  # Drum body level
	var attack_click = params.get("attack", params.get("click", 0.4))  # Attack transient
	var tune = params.get("tune", 0.5)  # Pitch variation
	var tone = params.get("tone", 0.5)  # 0=dark, 1=bright
	var amplitude = params.get("amplitude", 0.6)
	
	# Pitch adjusted by tune parameter
	var body_freq = pitch * (0.8 + tune * 0.4)
	var wire_freq_base = 4000.0 + tone * 4000.0  # Wire resonance 4-8kHz
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# 1. BODY - Pitched sine/triangle with slight pitch drop
		var body_pitch_env = 1.0 + exp(-t * 40.0) * 0.3  # Pitch drops quickly at start
		var body_wave = sin(2.0 * PI * body_freq * body_pitch_env * t)
		# Add harmonic for body resonance
		body_wave += sin(2.0 * PI * body_freq * 2.0 * body_pitch_env * t) * 0.3
		var body_env = exp(-t / (decay * 0.8))
		var body = body_wave * body_env * body_amount
		
		# 2. SNARE WIRES - High-frequency noise with characteristic rattle
		var wire_noise = 0.0
		for n in range(10):
			var freq = wire_freq_base + n * 800.0
			wire_noise += sin(t * freq + n * 1.7) * (1.0 / (n + 1))
		# Add some modulation for wire rattle character
		var wire_mod = 1.0 + sin(2.0 * PI * 180.0 * t) * 0.3  # Subtle modulation
		wire_noise *= wire_mod
		wire_noise = tanh(wire_noise * 1.5)
		var wire_env = exp(-t / (decay * 0.6))
		var wires = wire_noise * wire_env * wire_amount
		
		# 3. ATTACK TRANSIENT - Sharp click at the start
		var click_freq = 1500.0 + tone * 1000.0
		var click_wave = sin(2.0 * PI * click_freq * t)
		click_wave += sin(2.0 * PI * click_freq * 2.5 * t) * 0.5
		var click_env = exp(-t * 80.0)  # Very fast decay
		var click = click_wave * click_env * attack_click
		
		# 4. AIR/ROOM - Subtle low-frequency rumble
		var air = sin(2.0 * PI * 80.0 * t) * exp(-t / decay) * 0.1
		
		# Combine all layers
		var wave = body + wires + click + air
		
		data[i] = wave * amplitude

# =============================================================================
# RIMSHOT - Wood + metal click for dub/reggae
# Reference: Acoustic rimshot, 808 rimshot
# Technique: Short high-frequency click + wood resonance
# =============================================================================
static func generate_custom_rimshot(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 0.08))  # Very short
	var pitch = params.get("pitch", 600.0)  # Wood body pitch
	var click_amount = params.get("click", 0.7)  # Metal click level
	var wood_amount = params.get("wood", params.get("body", 0.6))  # Wood resonance
	var tone = params.get("tone", 0.6)
	var amplitude = params.get("amplitude", 0.5)
	
	var click_freq = 1500.0 + tone * 1000.0
	var wood_freq = pitch * (0.8 + tone * 0.4)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# 1. METAL CLICK - Very short, high frequency
		var click = sin(2.0 * PI * click_freq * t)
		click += sin(2.0 * PI * click_freq * 2.3 * t) * 0.4  # Harmonic
		var click_env = exp(-t * 100.0)  # Extremely fast
		click *= click_env * click_amount
		
		# 2. WOOD BODY - Short resonant thump
		var wood = sin(2.0 * PI * wood_freq * t)
		wood += sin(2.0 * PI * wood_freq * 1.5 * t) * 0.3  # Fifth harmonic
		var wood_env = exp(-t / decay)
		wood *= wood_env * wood_amount
		
		# 3. SLIGHT PITCH DROP for punch
		var pitch_drop = sin(2.0 * PI * (wood_freq * 0.5) * t) * exp(-t * 50.0) * 0.2
		
		data[i] = (click + wood + pitch_drop) * amplitude

# =============================================================================
# SHAKER - 16th note groove texture with filtered noise
# Reference: Egg shaker, maraca
# Technique: High-pass filtered noise with short granular envelope
# =============================================================================
static func generate_custom_shaker(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 0.05))  # Very short
	var tone = params.get("tone", 0.7)  # 0=dark, 1=bright
	var density = params.get("density", 0.8)  # Grain density
	var filter_freq = params.get("filter_freq", 3000.0 + tone * 4000.0)
	var amplitude = params.get("amplitude", 0.3)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# High-pass filtered noise (shaker has no low frequencies)
		var noise = 0.0
		for n in range(8):
			var freq = filter_freq + n * 1000.0
			noise += sin(t * freq + n * 3.14) * (1.0 / (n + 1))
		
		# Add some granular texture
		var grain_rate = 200.0 * density  # Grains per second
		var grain_phase = fmod(t * grain_rate, 1.0)
		var grain_env = sin(grain_phase * PI) if grain_phase < 0.3 else 0.0
		noise *= (0.5 + grain_env * 0.5)
		
		# Overall envelope
		var envelope = exp(-t / decay)
		
		data[i] = noise * envelope * amplitude

# =============================================================================
# TAMBOURINE - Pop/disco essential with jingles + shell hit
# Reference: Real tambourine with metal jingles
# Technique: Shell hit at ~300-500Hz, jingles at 5-10kHz metallic
# =============================================================================
static func generate_custom_tambourine(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 0.3))
	var jingle_brightness = params.get("brightness", params.get("tone", 0.7))
	var shell_level = params.get("shell", 0.4)
	var jingle_level = params.get("jingles", 0.7)
	var amplitude = params.get("amplitude", 0.4)
	
	var shell_freq = 400.0
	var jingle_base_freq = 6000.0 + jingle_brightness * 3000.0
	
	# Jingle frequencies (multiple slightly detuned for shimmer)
	var jingle_freqs = [1.0, 1.05, 1.12, 1.18, 1.25, 1.33]
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# 1. SHELL HIT - Low thump
		var shell = sin(2.0 * PI * shell_freq * t)
		shell += sin(2.0 * PI * shell_freq * 2.0 * t) * 0.3
		var shell_env = exp(-t * 20.0)  # Fast decay
		shell *= shell_env * shell_level
		
		# 2. JINGLES - Multiple metallic frequencies with shimmer
		var jingles = 0.0
		for j in range(jingle_freqs.size()):
			var freq = jingle_base_freq * jingle_freqs[j]
			# Mix of sine and square for metallic character
			var jingle_wave = sin(2.0 * PI * freq * t) * 0.7
			jingle_wave += (1.0 if sin(2.0 * PI * freq * 1.3 * t) > 0 else -1.0) * 0.3
			jingles += jingle_wave / jingle_freqs.size()
		
		# Jingles sustain longer than shell
		var jingle_env = exp(-t / decay)
		jingles *= jingle_env * jingle_level
		
		# Add slight modulation for shimmer
		var shimmer = 1.0 + sin(2.0 * PI * 15.0 * t) * 0.1
		jingles *= shimmer
		
		data[i] = (shell + jingles) * amplitude

# =============================================================================
# RIDE_CYMBAL - Jazz/ambient long metallic shimmer
# Reference: Jazz ride cymbal
# Technique: Complex inharmonic partials with very long decay
# =============================================================================
static func generate_custom_ride_cymbal(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 3.0))  # Very long
	var tone = params.get("tone", 0.5)  # Bell vs bow character
	var bell = params.get("bell", 0.0)  # Bell hit amount (0=bow, 1=bell)
	var stick = params.get("stick", 0.3)  # Stick click amount
	var amplitude = params.get("amplitude", 0.35)
	
	# Ride has many inharmonic partials
	var partial_ratios = [1.0, 1.48, 1.89, 2.13, 2.58, 3.14, 3.78, 4.21]
	var base_freq = 300.0 + bell * 200.0  # Bell is higher
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# 1. CYMBAL BODY - Complex partials
		var cymbal = 0.0
		for p in range(partial_ratios.size()):
			var freq = base_freq * partial_ratios[p]
			# Each partial has slightly different decay
			var partial_decay = decay * (1.0 - float(p) / partial_ratios.size() * 0.5)
			var partial_env = exp(-t / partial_decay)
			
			var partial_wave = sin(2.0 * PI * freq * t)
			cymbal += partial_wave * partial_env / partial_ratios.size()
		
		# 2. HIGH FREQUENCY SHIMMER
		var shimmer = 0.0
		for s in range(5):
			var freq = 5000.0 + s * 2000.0 + tone * 3000.0
			shimmer += sin(t * freq + s * 1.5) / 5.0
		shimmer *= exp(-t / (decay * 0.7))
		
		# 3. STICK CLICK - Initial attack
		var click = sin(2.0 * PI * 4000.0 * t) * exp(-t * 80.0) * stick
		
		# Bell adds more fundamental ring
		if bell > 0.0:
			cymbal += sin(2.0 * PI * base_freq * 0.5 * t) * exp(-t / decay) * bell * 0.5
		
		data[i] = (cymbal + shimmer * 0.3 + click) * amplitude

# =============================================================================
# CRASH_CYMBAL - Transition cymbal with noise burst + metallic decay
# Reference: Crash cymbal
# Technique: Wide frequency noise burst + metallic partials, long decay
# =============================================================================
static func generate_custom_crash_cymbal(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 2.0))
	var tone = params.get("tone", 0.6)  # 0=dark, 1=bright
	var attack_noise = params.get("attack", 0.6)  # Initial noise burst
	var amplitude = params.get("amplitude", 0.45)
	
	var partial_ratios = [1.0, 1.32, 1.67, 2.14, 2.78, 3.45, 4.12]
	var base_freq = 250.0 + tone * 100.0
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# 1. INITIAL NOISE BURST - Crash has explosive start
		var noise = 0.0
		for n in range(12):
			var freq = 2000.0 + n * 1500.0 + tone * 2000.0
			noise += sin(t * freq + n * 2.7) / 12.0
		var noise_env = exp(-t * 15.0)  # Fast decay on noise
		noise *= noise_env * attack_noise
		
		# 2. METALLIC BODY - Sustained ring
		var metallic = 0.0
		for p in range(partial_ratios.size()):
			var freq = base_freq * partial_ratios[p]
			var partial_env = exp(-t / (decay * (1.0 - float(p) / partial_ratios.size() * 0.4)))
			metallic += sin(2.0 * PI * freq * t) * partial_env / partial_ratios.size()
		
		# 3. HIGH SHIMMER
		var shimmer = 0.0
		for s in range(6):
			var freq = 8000.0 + s * 2500.0
			shimmer += sin(t * freq + s * 1.3) / 6.0
		shimmer *= exp(-t / (decay * 0.5))
		
		# Overall envelope
		var envelope = exp(-t / decay)
		
		data[i] = (noise + metallic * 0.7 + shimmer * 0.3) * envelope * amplitude

# =============================================================================
# TOM - Pitched drum for fills (LOW/MID/HIGH variants)
# Reference: Acoustic toms, 808/909 toms
# Technique: Pitched sine with pitch envelope (starts high, drops)
# =============================================================================
static func generate_custom_tom(data: PackedFloat32Array, sample_count: int, params: Dictionary, tom_type: String = "mid"):
	var decay = params.get("decay_time", params.get("decay", 0.35))
	var tone = params.get("tone", 0.5)
	var pitch_env_amount = params.get("pitch_env", 0.4)  # How much pitch drops
	var attack = params.get("attack", params.get("click", 0.3))
	var amplitude = params.get("amplitude", 0.6)
	
	# Base pitch depends on tom type
	var base_pitch = 80.0  # Low
	match tom_type:
		"low":
			base_pitch = params.get("pitch", 80.0)
		"mid":
			base_pitch = params.get("pitch", 140.0)
		"high":
			base_pitch = params.get("pitch", 220.0)
	
	base_pitch *= (0.9 + tone * 0.2)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# PITCH ENVELOPE - Starts higher, drops to fundamental
		var pitch_env = 1.0 + pitch_env_amount * exp(-t * 25.0)
		var freq = base_pitch * pitch_env
		
		# TOM BODY - Sine wave with some harmonic content
		var body = sin(2.0 * PI * freq * t)
		body += sin(2.0 * PI * freq * 2.0 * t) * 0.2  # Harmonic
		body += sin(2.0 * PI * freq * 0.5 * t) * 0.15  # Sub
		
		# ATTACK CLICK
		var click = sin(2.0 * PI * 1500.0 * t) * exp(-t * 60.0) * attack
		
		# Amplitude envelope
		var envelope = exp(-t / decay)
		
		data[i] = (body * envelope + click) * amplitude

# =============================================================================
# CONGA - Latin/house grooves with slap transient
# Reference: Latin congas (quinto, conga, tumba)
# Technique: Pitched membrane synthesis with slap transient
# =============================================================================
static func generate_custom_conga(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 0.2))
	var pitch = params.get("pitch", 280.0)  # Typical conga pitch
	var slap = params.get("slap", 0.5)  # Slap amount (vs muted)
	var tone = params.get("tone", 0.5)
	var open = params.get("open", params.get("mute", 0.7))  # 0=muted, 1=open
	var amplitude = params.get("amplitude", 0.5)
	
	var body_freq = pitch * (0.8 + tone * 0.4)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# PITCH ENVELOPE - Slight drop
		var pitch_env = 1.0 + 0.15 * exp(-t * 30.0)
		var freq = body_freq * pitch_env
		
		# BODY - Membrane resonance
		var body = sin(2.0 * PI * freq * t)
		body += sin(2.0 * PI * freq * 1.6 * t) * 0.25  # Inharmonic partial
		body += sin(2.0 * PI * freq * 2.2 * t) * 0.15
		
		# SLAP TRANSIENT - High frequency click
		var slap_wave = 0.0
		if slap > 0.0:
			var slap_freq = 2500.0 + tone * 1500.0
			slap_wave = sin(2.0 * PI * slap_freq * t) * exp(-t * 50.0) * slap
			slap_wave += sin(2.0 * PI * slap_freq * 1.8 * t) * exp(-t * 60.0) * slap * 0.5
		
		# Envelope depends on open/muted
		var envelope = exp(-t / (decay * open + 0.05))
		
		data[i] = (body * envelope + slap_wave) * amplitude

# =============================================================================
# BONGO - Higher pitched percussion fills
# Reference: Cuban bongos (hembra/macho)
# Technique: Similar to conga but higher pitched, sharper attack
# =============================================================================
static func generate_custom_bongo(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var decay = params.get("decay_time", params.get("decay", 0.12))  # Shorter than conga
	var pitch = params.get("pitch", 450.0)  # Higher than conga
	var attack = params.get("attack", params.get("slap", 0.6))  # Sharp attack
	var tone = params.get("tone", 0.6)
	var amplitude = params.get("amplitude", 0.45)
	
	var body_freq = pitch * (0.9 + tone * 0.2)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		
		# PITCH ENVELOPE - Quick drop
		var pitch_env = 1.0 + 0.2 * exp(-t * 40.0)
		var freq = body_freq * pitch_env
		
		# BODY - Higher membrane sound
		var body = sin(2.0 * PI * freq * t)
		body += sin(2.0 * PI * freq * 1.5 * t) * 0.3
		body += sin(2.0 * PI * freq * 2.8 * t) * 0.1
		
		# ATTACK - Very sharp
		var attack_wave = sin(2.0 * PI * 3500.0 * t) * exp(-t * 80.0) * attack
		
		# Envelope
		var envelope = exp(-t / decay)
		
		data[i] = (body * envelope + attack_wave) * amplitude

# ============================================================================
# EXPRESSIVE LEAD & MELODIC SOUNDS
# Research: Leads need 2-5kHz presence, velocity->timbre, expressive control
# ============================================================================

static func generate_custom_supersaw_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# SUPERSAW LEAD - Trance/EDM essential (JP-8000 style)
	# Research: 7 detuned saws, +/-25-30 cents spread, stereo width
	var freq = params.get("frequency", params.get("freq", 440.0))
	var detune_cents = params.get("detune_cents", params.get("detune", 25.0))
	var velocity = params.get("velocity", 0.8)
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.2)
	var sustain = params.get("sustain", 0.7)
	var release = params.get("release", 0.3)
	var filter_cutoff = params.get("filter_cutoff", params.get("cutoff", 4000.0))
	var filter_resonance = params.get("filter_resonance", params.get("resonance", 0.3))
	var vibrato_rate = params.get("vibrato_rate", 5.0)
	var vibrato_depth = params.get("vibrato_depth", 0.01)
	var amplitude = params.get("amplitude", 0.4)
	
	# Detune spread (cents) for 7 voices - JP-8000 style
	var detune_spread = [-1.0, -0.67, -0.33, 0.0, 0.33, 0.67, 1.0]
	var voice_mix = [0.7, 0.85, 0.95, 1.0, 0.95, 0.85, 0.7]
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Vibrato (delayed onset)
		var vibrato = 0.0
		if progress > 0.1:
			var vib_intensity = min((progress - 0.1) / 0.3, 1.0)
			vibrato = sin(2.0 * PI * vibrato_rate * t) * vibrato_depth * vib_intensity
		var mod_freq = freq * (1.0 + vibrato)
		
		# Generate 7 detuned sawtooth waves
		var total_wave = 0.0
		for voice in range(7):
			var voice_detune_cents = detune_spread[voice] * detune_cents
			var detune_ratio = pow(2.0, voice_detune_cents / 1200.0)
			var voice_freq = mod_freq * detune_ratio
			var saw = 2.0 * fmod(voice_freq * t, 1.0) - 1.0
			total_wave += saw * voice_mix[voice]
		total_wave /= 7.0
		
		# Velocity affects filter cutoff
		var vel_cutoff = filter_cutoff * (0.5 + velocity * 0.5)
		var filter_env = exp(-progress * 3.0) * 0.5 + 0.5
		var dynamic_cutoff = vel_cutoff * filter_env
		var filter_factor = clamp(dynamic_cutoff / 8000.0, 0.2, 1.0)
		var filtered = total_wave * filter_factor * (1.0 + filter_resonance * filter_env)
		
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
		
		var vel_amp = 0.5 + velocity * 0.5
		data[i] = filtered * envelope * amplitude * vel_amp


static func generate_custom_sync_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# SYNC LEAD - Aggressive oscillator sync
	var freq = params.get("frequency", params.get("freq", 440.0))
	var sync_ratio = params.get("sync_ratio", 2.5)
	var velocity = params.get("velocity", 0.8)
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.3)
	var sustain = params.get("sustain", 0.6)
	var release = params.get("release", 0.4)
	var filter_cutoff = params.get("filter_cutoff", params.get("cutoff", 3000.0))
	var filter_resonance = params.get("filter_resonance", params.get("resonance", 0.5))
	var sync_sweep = params.get("sync_sweep", 0.0)
	var vibrato_rate = params.get("vibrato_rate", 5.5)
	var vibrato_depth = params.get("vibrato_depth", 0.015)
	var amplitude = params.get("amplitude", 0.45)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var master_phase = 0.0
	var slave_phase = 0.0
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var vibrato = sin(2.0 * PI * vibrato_rate * t) * vibrato_depth
		var master_freq = freq * (1.0 + vibrato)
		var current_sync = sync_ratio + sync_sweep * sin(2.0 * PI * 0.5 * t)
		var slave_freq = master_freq * current_sync
		
		var master_inc = master_freq / AudioSynthesizer.SAMPLE_RATE
		var slave_inc = slave_freq / AudioSynthesizer.SAMPLE_RATE
		
		master_phase += master_inc
		slave_phase += slave_inc
		
		if master_phase >= 1.0:
			master_phase = fmod(master_phase, 1.0)
			slave_phase = 0.0
		
		var wave = 2.0 * slave_phase - 1.0
		
		var vel_cutoff = filter_cutoff * (0.6 + velocity * 0.4)
		var filter_env = exp(-progress * 4.0) * 0.6 + 0.4
		var dynamic_cutoff = vel_cutoff * filter_env
		var filter_factor = clamp(dynamic_cutoff / 6000.0, 0.3, 1.0)
		var filtered = wave * filter_factor * (1.0 + filter_resonance * filter_env * 0.5)
		
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
		
		var vel_amp = 0.6 + velocity * 0.4
		data[i] = filtered * envelope * amplitude * vel_amp


static func generate_custom_fm_bell(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# FM BELL - DX7 style metallic bell
	var freq = params.get("frequency", params.get("freq", 440.0))
	var mod_ratio = params.get("mod_ratio", params.get("ratio", 1.414))
	var mod_index = params.get("mod_index", params.get("mod_depth", 5.0))
	var velocity = params.get("velocity", 0.8)
	var attack = params.get("attack", 0.001)
	var decay = params.get("decay", 1.5)
	var brightness = params.get("brightness", 0.7)
	var amplitude = params.get("amplitude", 0.4)
	
	var _duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var modulator_freq = freq * mod_ratio
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var mod_env = exp(-progress * 8.0) * velocity
		var current_mod_index = mod_index * mod_env * brightness
		
		var modulator = sin(2.0 * PI * modulator_freq * t)
		var carrier = sin(2.0 * PI * freq * t + modulator * current_mod_index)
		
		var mod2_freq = freq * 2.414
		var mod2 = sin(2.0 * PI * mod2_freq * t) * current_mod_index * 0.3
		carrier += sin(2.0 * PI * freq * t + mod2) * 0.3
		carrier /= 1.3
		
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		else:
			envelope = exp(-progress * (3.0 / decay))
		
		var vel_amp = 0.5 + velocity * 0.5
		data[i] = carrier * envelope * amplitude * vel_amp


static func generate_custom_square_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# SQUARE LEAD - Chiptune/retro
	var freq = params.get("frequency", params.get("freq", 440.0))
	var pulse_width = params.get("pulse_width", 0.5)
	var pwm_rate = params.get("pwm_rate", 4.0)
	var pwm_depth = params.get("pwm_depth", 0.2)
	var velocity = params.get("velocity", 0.8)
	var attack = params.get("attack", 0.005)
	var decay = params.get("decay", 0.1)
	var sustain = params.get("sustain", 0.8)
	var release = params.get("release", 0.2)
	var vibrato_rate = params.get("vibrato_rate", 6.0)
	var vibrato_depth = params.get("vibrato_depth", 0.02)
	var retro_quantize = params.get("retro_quantize", false)
	var amplitude = params.get("amplitude", 0.35)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var vibrato = 0.0
		if progress > 0.15:
			var vib_intensity = min((progress - 0.15) / 0.2, 1.0)
			vibrato = sin(2.0 * PI * vibrato_rate * t) * vibrato_depth * vib_intensity
		var mod_freq = freq * (1.0 + vibrato)
		
		var dynamic_pw = pulse_width + sin(2.0 * PI * pwm_rate * t) * pwm_depth
		dynamic_pw = clamp(dynamic_pw, 0.1, 0.9)
		
		var phase = fmod(mod_freq * t, 1.0)
		var wave = 1.0 if phase < dynamic_pw else -1.0
		
		if velocity > 0.7:
			var harm_amount = (velocity - 0.7) / 0.3 * 0.2
			wave += sin(2.0 * PI * mod_freq * 3.0 * t) * harm_amount
		
		if retro_quantize:
			wave = floor(wave * 7.5) / 7.5
		
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
		
		var vel_amp = 0.6 + velocity * 0.4
		data[i] = wave * envelope * amplitude * vel_amp


static func generate_custom_portamento_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# PORTAMENTO LEAD - Smooth gliding
	var start_freq = params.get("start_freq", params.get("frequency", 440.0))
	var end_freq = params.get("end_freq", start_freq * 1.5)
	var glide_time = params.get("glide_time", params.get("portamento", 0.15))
	var velocity = params.get("velocity", 0.8)
	var attack = params.get("attack", 0.02)
	var decay = params.get("decay", 0.2)
	var sustain = params.get("sustain", 0.7)
	var release = params.get("release", 0.4)
	var filter_cutoff = params.get("filter_cutoff", 3500.0)
	var vibrato_rate = params.get("vibrato_rate", 5.0)
	var vibrato_depth = params.get("vibrato_depth", 0.02)
	var waveform = params.get("waveform", "sawtooth")
	var amplitude = params.get("amplitude", 0.4)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var glide_samples = glide_time * AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		var current_freq = start_freq
		if i < glide_samples:
			var glide_progress = float(i) / glide_samples
			glide_progress = 1.0 - pow(1.0 - glide_progress, 2.0)
			current_freq = start_freq * pow(end_freq / start_freq, glide_progress)
		else:
			current_freq = end_freq
		
		if i > glide_samples:
			var vib_intensity = min((float(i) - glide_samples) / (glide_samples * 0.5), 1.0)
			current_freq *= 1.0 + sin(2.0 * PI * vibrato_rate * t) * vibrato_depth * vib_intensity
		
		var wave = 0.0
		match waveform:
			"sawtooth":
				wave = 2.0 * fmod(current_freq * t, 1.0) - 1.0
			"square":
				wave = 1.0 if fmod(current_freq * t, 1.0) < 0.5 else -1.0
			"sine":
				wave = sin(2.0 * PI * current_freq * t)
			"triangle":
				var phase = fmod(current_freq * t, 1.0)
				wave = 4.0 * abs(phase - 0.5) - 1.0
		
		var vel_cutoff = filter_cutoff * (0.5 + velocity * 0.5)
		var filter_factor = clamp(vel_cutoff / 6000.0, 0.3, 1.0)
		wave *= filter_factor
		
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
		
		var vel_amp = 0.6 + velocity * 0.4
		data[i] = wave * envelope * amplitude * vel_amp


static func generate_custom_vocal_formant(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# VOCAL FORMANT - Vowel sounds
	var freq = params.get("frequency", params.get("freq", 220.0))
	var vowel = params.get("vowel", "ah")
	var velocity = params.get("velocity", 0.8)
	var attack = params.get("attack", 0.05)
	var decay = params.get("decay", 0.2)
	var sustain = params.get("sustain", 0.7)
	var release = params.get("release", 0.3)
	var vibrato_rate = params.get("vibrato_rate", 5.5)
	var vibrato_depth = params.get("vibrato_depth", 0.015)
	var breathiness = params.get("breathiness", 0.1)
	var amplitude = params.get("amplitude", 0.4)
	
	var formants = {
		"ah": [800.0, 1200.0, 2500.0],
		"ee": [300.0, 2300.0, 3000.0],
		"oo": [350.0, 600.0, 2400.0],
		"eh": [600.0, 1800.0, 2600.0],
		"oh": [500.0, 900.0, 2400.0]
	}
	
	var current_formants = formants.get(vowel, formants["ah"])
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		var vibrato = sin(2.0 * PI * vibrato_rate * t) * vibrato_depth
		var mod_freq = freq * (1.0 + vibrato)
		
		var source = 2.0 * fmod(mod_freq * t, 1.0) - 1.0
		var breath = (sin(t * 8000.0) * 0.5 + sin(t * 12000.0) * 0.3) * breathiness
		source += breath
		
		var filtered = 0.0
		var formant_weights = [1.0, 0.7, 0.4]
		
		for f in range(current_formants.size()):
			var formant_freq = current_formants[f]
			var bandwidth = formant_freq * 0.1
			var _formant_response = sin(2.0 * PI * formant_freq * t)
			var distance = abs(mod_freq - formant_freq)
			var resonance = exp(-distance / bandwidth) * formant_weights[f]
			filtered += source * resonance
		
		var wave = filtered * 0.7 + source * 0.3
		
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
		
		var vel_amp = 0.5 + velocity * 0.5
		data[i] = wave * envelope * amplitude * vel_amp


static func generate_custom_brass_stab(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# BRASS STAB - House/funk (fast attack, filter sweep)
	var freq = params.get("frequency", params.get("freq", 440.0))
	var velocity = params.get("velocity", 0.9)
	var attack = params.get("attack", 0.008)
	var decay = params.get("decay", 0.4)
	var sustain = params.get("sustain", 0.3)
	var release = params.get("release", 0.2)
	var filter_start = params.get("filter_start", 500.0)
	var filter_peak = params.get("filter_peak", params.get("filter_cutoff", 4000.0))
	var filter_resonance = params.get("filter_resonance", 0.6)
	var filter_attack = params.get("filter_attack", 0.02)
	var detune = params.get("detune", 0.008)
	var voices = params.get("voices", 3)
	var amplitude = params.get("amplitude", 0.5)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var filter_attack_samples = filter_attack * AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var wave = 0.0
		for v in range(voices):
			var voice_detune = (float(v) / (voices - 1) - 0.5) * detune * 2.0 if voices > 1 else 0.0
			var voice_freq = freq * (1.0 + voice_detune)
			wave += 2.0 * fmod(voice_freq * t, 1.0) - 1.0
		wave /= voices
		
		var filter_env = 0.0
		if i < filter_attack_samples:
			filter_env = float(i) / filter_attack_samples
		else:
			filter_env = exp(-(progress - filter_attack) * 3.0)
		
		var vel_peak = filter_start + (filter_peak - filter_start) * velocity
		var dynamic_cutoff = filter_start + (vel_peak - filter_start) * filter_env
		
		var filter_factor = clamp(dynamic_cutoff / 6000.0, 0.15, 1.0)
		var resonance_boost = 1.0 + filter_resonance * filter_env * 0.8
		wave *= filter_factor * resonance_boost
		wave += sin(2.0 * PI * dynamic_cutoff * t) * filter_resonance * filter_env * 0.15
		
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
		
		var vel_amp = 0.6 + velocity * 0.4
		data[i] = wave * envelope * amplitude * vel_amp


static func generate_custom_string_ensemble(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# STRING ENSEMBLE - Lush pads for melodies
	var freq = params.get("frequency", params.get("freq", 440.0))
	var velocity = params.get("velocity", 0.7)
	var attack = params.get("attack", 0.3)
	var decay = params.get("decay", 0.3)
	var sustain = params.get("sustain", 0.8)
	var release = params.get("release", 0.5)
	var chorus_rate = params.get("chorus_rate", 1.5)
	var chorus_depth = params.get("chorus_depth", 0.15)
	var voices = params.get("voices", 6)
	var vibrato_rate = params.get("vibrato_rate", 5.0)
	var vibrato_depth = params.get("vibrato_depth", 0.008)
	var filter_cutoff = params.get("filter_cutoff", 3000.0)
	var amplitude = params.get("amplitude", 0.35)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var vibrato = 0.0
		if progress > 0.2:
			var vib_intensity = min((progress - 0.2) / 0.3, 1.0)
			vibrato = sin(2.0 * PI * vibrato_rate * t) * vibrato_depth * vib_intensity
		
		var wave = 0.0
		for v in range(voices):
			var voice_phase = float(v) / voices * 2.0 * PI
			var chorus_mod = sin(2.0 * PI * chorus_rate * t + voice_phase) * chorus_depth
			var voice_freq = freq * (1.0 + chorus_mod * 0.02 + vibrato)
			var saw = 2.0 * fmod(voice_freq * t, 1.0) - 1.0
			wave += saw
		wave /= voices
		
		var filter_factor = clamp(filter_cutoff / 5000.0, 0.3, 1.0)
		wave *= filter_factor
		
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		var decay_samples = decay * AudioSynthesizer.SAMPLE_RATE
		var release_start = (1.0 - release / duration) * sample_count
		
		if i < attack_samples:
			var attack_progress = float(i) / attack_samples
			envelope = attack_progress * attack_progress * (3.0 - 2.0 * attack_progress)
		elif i < attack_samples + decay_samples:
			var decay_progress = (i - attack_samples) / decay_samples
			envelope = 1.0 - decay_progress * (1.0 - sustain)
		elif i < release_start:
			envelope = sustain
		else:
			var release_progress = (i - release_start) / (sample_count - release_start)
			envelope = sustain * (1.0 - release_progress)
		
		var vel_amp = 0.5 + velocity * 0.5
		data[i] = wave * envelope * amplitude * vel_amp


static func generate_custom_pluck_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# PLUCK LEAD - Kalimba/marimba style
	var freq = params.get("frequency", params.get("freq", 440.0))
	var velocity = params.get("velocity", 0.8)
	var decay_time = params.get("decay_time", params.get("decay", 0.8))
	var brightness = params.get("brightness", 0.7)
	var body_resonance = params.get("body_resonance", 0.3)
	var attack = params.get("attack", 0.001)
	var amplitude = params.get("amplitude", 0.45)
	
	var delay_samples = int(AudioSynthesizer.SAMPLE_RATE / freq)
	var delay_line = PackedFloat32Array()
	delay_line.resize(delay_samples)
	
	for j in range(delay_samples):
		delay_line[j] = (randf() * 2.0 - 1.0) * brightness
	
	var delay_index = 0
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var wave = delay_line[delay_index]
		var next_index = (delay_index + 1) % delay_samples
		var filtered = (delay_line[delay_index] + delay_line[next_index]) * 0.5
		var decay_factor = 0.995 + velocity * 0.004
		delay_line[delay_index] = filtered * decay_factor
		delay_index = next_index
		
		if body_resonance > 0.0:
			wave += sin(2.0 * PI * freq * 2.0 * t) * body_resonance * exp(-progress * 5.0)
		
		var envelope = exp(-progress * (5.0 / decay_time))
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		if i < attack_samples:
			envelope *= float(i) / attack_samples
		
		var vel_amp = 0.5 + velocity * 0.5
		data[i] = wave * envelope * amplitude * vel_amp


static func generate_custom_glass_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# GLASS LEAD - Crystalline bell-like FM
	var freq = params.get("frequency", params.get("freq", 880.0))
	var mod_ratio = params.get("mod_ratio", params.get("ratio", 3.0))
	var mod_index = params.get("mod_index", params.get("mod_depth", 3.0))
	var velocity = params.get("velocity", 0.7)
	var attack = params.get("attack", 0.02)
	var decay = params.get("decay", 2.0)
	var shimmer = params.get("shimmer", 0.3)
	var amplitude = params.get("amplitude", 0.35)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var mod_env = exp(-progress * 4.0)
		var current_mod = mod_index * mod_env * velocity
		
		var mod_freq = freq * mod_ratio
		var modulator = sin(2.0 * PI * mod_freq * t)
		var carrier = sin(2.0 * PI * freq * t + modulator * current_mod)
		
		var shimmer_wave = 0.0
		if shimmer > 0.0:
			shimmer_wave = sin(2.0 * PI * freq * 5.14 * t) * shimmer * mod_env * 0.3
			shimmer_wave += sin(2.0 * PI * freq * 7.23 * t) * shimmer * mod_env * 0.2
		
		var wave = carrier + shimmer_wave
		
		var envelope = 1.0
		var attack_samples = attack * AudioSynthesizer.SAMPLE_RATE
		
		if i < attack_samples:
			envelope = float(i) / attack_samples
		else:
			envelope = exp(-progress * (2.0 / decay))
		
		var vel_amp = 0.5 + velocity * 0.5
		data[i] = wave * envelope * amplitude * vel_amp


static func generate_custom_distorted_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# DISTORTED LEAD - Rock/industrial saturation
	var freq = params.get("frequency", params.get("freq", 440.0))
	var velocity = params.get("velocity", 0.8)
	var drive = params.get("drive", params.get("distortion", 0.7))
	var distortion_type = params.get("distortion_type", "tube")
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.2)
	var sustain = params.get("sustain", 0.8)
	var release = params.get("release", 0.3)
	var tone = params.get("tone", 0.6)
	var vibrato_rate = params.get("vibrato_rate", 5.5)
	var vibrato_depth = params.get("vibrato_depth", 0.02)
	var amplitude = params.get("amplitude", 0.4)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		var vibrato = sin(2.0 * PI * vibrato_rate * t) * vibrato_depth
		var mod_freq = freq * (1.0 + vibrato)
		
		var wave = 2.0 * fmod(mod_freq * t, 1.0) - 1.0
		wave += (1.0 if fmod(mod_freq * t, 1.0) < 0.5 else -1.0) * 0.3
		
		var pre_gain = 1.0 + drive * 5.0 * velocity
		wave *= pre_gain
		
		match distortion_type:
			"tube":
				if wave > 0:
					wave = tanh(wave * 1.2)
				else:
					wave = tanh(wave * 0.9)
			"fuzz":
				wave = tanh(wave * 2.0)
				wave = sign(wave) * pow(abs(wave), 0.7)
			"hard":
				wave = clamp(wave, -0.8, 0.8)
		
		var tone_cutoff = 1000.0 + tone * 4000.0
		var tone_factor = clamp(tone_cutoff / 5000.0, 0.3, 1.0)
		wave *= tone_factor
		
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
		
		var vel_amp = 0.6 + velocity * 0.4
		data[i] = wave * envelope * amplitude * vel_amp


static func generate_custom_bitcrushed_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# BITCRUSHED LEAD - Lo-fi character
	var freq = params.get("frequency", params.get("freq", 440.0))
	var velocity = params.get("velocity", 0.8)
	var bit_depth = params.get("bit_depth", 8)
	var sample_rate_reduction = params.get("sample_rate_reduction", 0.3)
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.2)
	var sustain = params.get("sustain", 0.7)
	var release = params.get("release", 0.3)
	var mix = params.get("mix", params.get("wet", 0.8))
	var vibrato_rate = params.get("vibrato_rate", 5.0)
	var vibrato_depth = params.get("vibrato_depth", 0.015)
	var waveform = params.get("waveform", "sawtooth")
	var amplitude = params.get("amplitude", 0.4)
	
	var duration = float(sample_count) / AudioSynthesizer.SAMPLE_RATE
	var hold_interval = 1 + int(sample_rate_reduction * 10.0)
	var held_sample = 0.0
	var quant_levels = pow(2, bit_depth - 1)
	
	for i in range(sample_count):
		var t = float(i) / AudioSynthesizer.SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		var vibrato = sin(2.0 * PI * vibrato_rate * t) * vibrato_depth
		var mod_freq = freq * (1.0 + vibrato)
		
		var clean_wave = 0.0
		match waveform:
			"sawtooth":
				clean_wave = 2.0 * fmod(mod_freq * t, 1.0) - 1.0
			"square":
				clean_wave = 1.0 if fmod(mod_freq * t, 1.0) < 0.5 else -1.0
			"sine":
				clean_wave = sin(2.0 * PI * mod_freq * t)
			"triangle":
				var phase = fmod(mod_freq * t, 1.0)
				clean_wave = 4.0 * abs(phase - 0.5) - 1.0
		
		if i % hold_interval == 0:
			held_sample = clean_wave
		var crushed_wave = held_sample
		crushed_wave = floor(crushed_wave * quant_levels) / quant_levels
		
		var wave = clean_wave * (1.0 - mix) + crushed_wave * mix
		
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
		
		var vel_amp = 0.5 + velocity * 0.5
		data[i] = wave * envelope * amplitude * vel_amp
