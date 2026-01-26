# AudioSynthesizer.gd
# Path: res://commons/audio/AudioSynthesizer.gd
# Procedural Audio Synthesizer for generating sound effects and music
# Generates 16-bit PCM WAV data based on mathematical functions

extends Node
class_name AudioSynthesizer

const SAMPLE_RATE = 44100
const BAR_DURATION = 2.0 # Seconds per bar at 120 BPM (4/4)

# Threading
static var generation_thread: Thread
static var mutex: Mutex = Mutex.new()
static var is_generating = false

# signal song_ready(stream: AudioStreamInteractive) - Unused

# Audio configuration
# const SAMPLE_RATE = 44100.0 # This was replaced by the new SAMPLE_RATE above
const CHANNELS = 1

# Constants
const BPM = 100.0
# const BAR_DURATION = 240.0 / BPM # This was replaced by the new BAR_DURATION above

static func generate_pop_interactive_song(_parameters: Dictionary = {}) -> AudioStreamInteractive:
	# 1. Pick Key and Progression
	randomize()
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "4"
	var scale = PopMusicTheory.get_major_scale_notes(root_note)
	var progression = PopMusicTheory.PROG_POP_4 # Default
	
	print("AudioSynthesizer: Generating Pop Song in ", root_note)
	
	# Create Interactive Stream
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 3
	playback.initial_clip = 0
	
	# 2. Generate Sections
	# Intro: Pad only
	var intro_stream = _generate_pop_section_stream(progression, scale, ["pad"])
	playback.set_clip_stream(0, intro_stream)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, 1) # Intro -> Verse
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Verse: Bass + Keys + Drums
	var verse_stream = _generate_pop_section_stream(progression, scale, ["bass", "keys", "drums"])
	playback.set_clip_stream(1, verse_stream)
	playback.set_clip_name(1, "Verse")
	playback.set_clip_auto_advance(1, 1) # Verse -> Chorus
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Chorus: Full Mix
	var chorus_stream = _generate_pop_section_stream(progression, scale, ["bass", "keys", "pad", "lead", "drums"])
	playback.set_clip_stream(2, chorus_stream)
	playback.set_clip_name(2, "Chorus")
	playback.set_clip_auto_advance(2, 1) # Chorus -> Verse (Loop back)
	playback.set_clip_auto_advance_next_clip(2, 1)
	
	# 3. Transitions
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 2.0)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 1.0)
	playback.add_transition(2, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 2.0)
	
	return playback

static func generate_ambient_works_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	# Aphex Twin "Ambient Works 85-92" Style Generator
	# Characteristics: Warm analogue pads, lo-fi breakbeats, tape drift, acid bass
	
	randomize()
	# Slower tempo for ambient techno (85-95 BPM)
	var bpm = 90.0
	var bar_duration = 240.0 / bpm
	
	# Key selection (often minor/dorean for this style)
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3" # Lower register
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)
	var progression = [1, 5, 6, 4] # Simple emotive progression
	
	print("AudioSynthesizer: Generating Ambient Works Song in ", root_note)
	
	# Create Interactive Stream
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4 # Intro, Build, Main, Outro
	playback.initial_clip = 0
	
	# 1. Intro: Tape Keys + Drift
	var intro_stream = _generate_ambient_section_stream(progression, scale, ["keys", "noise"], bar_duration)
	playback.set_clip_stream(0, intro_stream)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, 1)  # Auto-advance to Build
	playback.set_clip_auto_advance_next_clip(0, 1)

	# 2. Build: Add Warm Pad, Bass, and Drums (Groove starts)
	var build_stream = _generate_ambient_section_stream(progression, scale, ["keys", "pad", "bass", "drums", "noise"], bar_duration)
	playback.set_clip_stream(1, build_stream)
	playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, 1)  # Auto-advance to Main
	playback.set_clip_auto_advance_next_clip(1, 2)

	# 3. Main: Full Groove (Breakbeat + Acid Bass)
	var main_stream = _generate_ambient_section_stream(progression, scale, ["keys", "pad", "bass", "drums", "noise"], bar_duration)
	playback.set_clip_stream(2, main_stream)
	playback.set_clip_name(2, "Main")
	playback.set_clip_auto_advance(2, 1)  # Auto-advance to Outro
	playback.set_clip_auto_advance_next_clip(2, 3)

	# 4. Outro: Fade to Pad
	var outro_stream = _generate_ambient_section_stream(progression, scale, ["pad", "noise"], bar_duration)
	playback.set_clip_stream(3, outro_stream)
	playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, 1)  # Auto-advance back to Intro (loop)
	playback.set_clip_auto_advance_next_clip(3, 0)

	# Transitions (Long crossfades for ambient feel)
	var xfade = 4.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback

static func _generate_ambient_section_stream(progression: Array, scale: Array, instruments: Array, bar_duration: float, panning: String = "center") -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2 # Double length bars for slower feel
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# INSTRUMENTS
		
		if "pad" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_warm_juno_pad(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.6)
			
		if "keys" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_tape_drift_keys(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.5)
			
		if "bass" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_acid_bass_sub(data, samples_per_chord, root_freq)
			_mix_into(chord_mix, data, 0.7)
			
		if "drums" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_lofi_breakbeat(data, samples_per_chord)
			_mix_into(chord_mix, data, 0.8)
			
		if "noise" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_tape_hiss(data, samples_per_chord)
			_mix_into(chord_mix, data, 0.15) # Subtle background texture

		# Mix into final buffer
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				var sample = chord_mix[j]
				# Sanitize NaN/Inf values that would kill audio
				if is_nan(sample) or is_inf(sample):
					sample = 0.0
				# Clamp to prevent clipping
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)

	# Anti-Pop Fade (10ms fade in/out)
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))

	if panning == "right_to_left":
		# Create stereo mix with panning (Right -> Left)
		var stereo_mix = PackedFloat32Array()
		stereo_mix.resize(total_samples * 2)
		
		for i in range(total_samples):
			var t_prog = float(i) / float(total_samples)
			var pan_l = t_prog        # 0.0 -> 1.0 (Left channel gain)
			var pan_r = 1.0 - t_prog  # 1.0 -> 0.0 (Right channel gain)
			
			var mono_sample = final_mix[i]
			stereo_mix[i * 2] = mono_sample * pan_l     # Left
			stereo_mix[i * 2 + 1] = mono_sample * pan_r # Right
			
		return _create_stereo_audio_stream(stereo_mix, AudioStreamWAV.LOOP_DISABLED)
	else:
		# Center panning: Duplicate mono to L/R for consistent Stereo output
		var stereo_mix = PackedFloat32Array()
		stereo_mix.resize(total_samples * 2)
		
		for i in range(total_samples):
			var sample = final_mix[i]
			stereo_mix[i * 2] = sample      # Left
			stereo_mix[i * 2 + 1] = sample  # Right
			
		return _create_stereo_audio_stream(stereo_mix, AudioStreamWAV.LOOP_DISABLED)

static func generate_pop_song_async(parameters: Dictionary, callback_object: Object, callback_method: String):
	if is_generating:
		print("AudioSynthesizer: Already generating sound")
		return

	if not generation_thread:
		generation_thread = Thread.new()
	
	is_generating = true
	print("AudioSynthesizer: Starting background generation...")
	
	# Pass data as a single dictionary to the thread function
	var thread_data = {
		"params": parameters,
		"callback_obj": callback_object,
		"callback_method": callback_method
	}
	
	generation_thread.start(_thread_generate_pop_song.bind(thread_data))

static func _thread_generate_pop_song(data: Dictionary):
	print("AudioSynthesizer: Thread started")
	var stream = null
	if data.params.get("type") == "AMBIENT":
		stream = generate_ambient_works_song(data.params)
	else:
		stream = generate_pop_interactive_song(data.params)
	
	_on_generation_complete.call_deferred(stream, data)

static func _on_generation_complete(stream: AudioStreamInteractive, data: Dictionary):
	print("AudioSynthesizer: Background generation complete")
	
	if generation_thread.is_alive():
		generation_thread.wait_to_finish()
	
	is_generating = false
	
	if data.callback_obj and data.callback_obj.has_method(data.callback_method):
		data.callback_obj.call(data.callback_method, stream)

static func _generate_pop_section_stream(progression: Array, scale: Array, instruments: Array) -> AudioStreamWAV:
	var total_duration = progression.size() * BAR_DURATION
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	
	var samples_per_chord = int(BAR_DURATION * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var bass_freq = root_freq * 0.25
		
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		if "pad" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_juno_chorus_pad(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.5)
			
		if "keys" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_dx7_ballad_keys(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.6)
			
		if "bass" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_funk_bass(data, samples_per_chord, bass_freq)
			_mix_into(chord_mix, data, 0.7)

		if "lead" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_obxa_brass(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.4)

		if "drums" in instruments:
			var beat_samples = int(samples_per_chord / 4.0)
			var kick_data = PackedFloat32Array(); kick_data.resize(int(SAMPLE_RATE * 0.2))
			_generate_tr909_kick(kick_data, kick_data.size())
			var hat_data = PackedFloat32Array(); hat_data.resize(int(SAMPLE_RATE * 0.1))
			_generate_acid_606_hihat(hat_data, hat_data.size())
			
			var drum_mix = PackedFloat32Array(); drum_mix.resize(samples_per_chord); drum_mix.fill(0.0)
			_mix_at_offset(drum_mix, kick_data, 0, 0.8)
			_mix_at_offset(drum_mix, kick_data, beat_samples * 2, 0.8)
			var hat_offset = int(beat_samples * 0.5)
			for b in range(4):
				_mix_at_offset(drum_mix, hat_data, b * beat_samples + hat_offset, 0.4)
			_mix_into(chord_mix, drum_mix, 1.0)

		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				var sample = chord_mix[j]
				if is_nan(sample) or is_inf(sample):
					sample = 0.0
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)

	# Anti-Pop Fade (10ms fade in/out) ensures zero-crossing at clip boundaries
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
				
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)

static func _apply_fade_envelope(buffer: PackedFloat32Array, fade_length: int):
	var size = buffer.size()
	if size < fade_length * 2:
		fade_length = size / 2
		
	for i in range(fade_length):
		var t = float(i) / float(fade_length)
		# Fade In
		buffer[i] *= t
		# Fade Out
		buffer[size - 1 - i] *= t


static func _mix_into(target: PackedFloat32Array, source: PackedFloat32Array, level: float):
	for i in range(min(target.size(), source.size())):
		target[i] += source[i] * level

static func _mix_at_offset(target: PackedFloat32Array, source: PackedFloat32Array, offset: int, level: float):
	var end = min(target.size(), offset + source.size())
	for i in range(offset, end):
		target[i] += source[i - offset] * level

# Sound type definitions
enum SoundType {
	BASIC_SINE_WAVE,   # Simple sine wave - perfect for learning
	PICKUP_MARIO,      # Mario-style pickup sound
	TELEPORT_DRONE,    # Electrostatic synth drone
	LIFT_BASS_PULSE,   # Bass pulse for lifts
	GHOST_DRONE,       # Ghostly atmospheric drone
	MELODIC_DRONE,     # Beautiful melodic drone
	LASER_SHOT,        # Sci-fi laser beam - frequency sweeps
	POWER_UP_JINGLE,   # Achievement/reward - musical harmony
	EXPLOSION,         # Impact/destruction - multi-band synthesis
	RETRO_JUMP,        # Classic platformer jump - pitch bend
	SHIELD_HIT,        # Metallic impact - ring modulation
	AMBIENT_WIND,      # Atmospheric texture - filtered noise
	DARK_808_KICK,     # Deep 808 kick with pitch envelope and click attack
	ACID_606_HIHAT,    # Filtered noise hi-hat with metallic ring characteristic of 606
	DARK_808_SUB_BASS, # Deep sub bass with slow modulation and dark character
	AMBIENT_AMIGA_DRONE, # Multi-layered ambient drone with slow modulation and detuning
	MOOG_BASS_LEAD,    # Classic Moog lead/bass with ladder filter and oscillator sync
	TB303_ACID_BASS,   # Roland TB-303 acid bass with characteristic filter sweep
	DX7_ELECTRIC_PIANO, # Yamaha DX7 FM electric piano - the sound of the 80s
	C64_SID_LEAD,      # Commodore 64 SID chip lead sound with PWM and ring modulation
	AMIGA_MOD_SAMPLE,  # Amiga ProTracker style sample with Paula chip characteristics
	# Additional vintage synthesizer sounds
	PPG_WAVE_PAD,      # PPG Wave 2.2 wavetable pad
	TR909_KICK,        # Roland TR-909 kick drum
	JUPITER_8_STRINGS, # Roland Jupiter-8 string ensemble
	KORG_M1_PIANO,     # Korg M1 digital piano
	ARP_2600_LEAD,     # ARP 2600 analog lead synthesizer
	SYNARE_3_DISCO_TOM, # Star Instruments Synare 3 disco tom
	SYNARE_3_COSMIC_FX, # Star Instruments Synare 3 cosmic FX
	MOOG_KRAFTWERK_SEQUENCER, # Moog-style Kraftwerk sequencer
	HERBIE_HANCOCK_MOOG_FUSION, # Herbie Hancock jazz-fusion Moog
	APHEX_TWIN_MODULAR, # Aphex Twin experimental modular synthesis
	FLYING_LOTUS_SAMPLER, # Flying Lotus beat machine sampler-synth
	# Sci-Fi / Half-Life inspired sounds
	SCI_FI_LAB_HUM_CLEAN,    # Sterile, multi-layered sine wave hum
	SCI_FI_RESONANT_DRONE,   # Evolving metallic swells (FM)
	SCI_FI_DATA_CHIRPS,      # Randomized computer activity
	SCI_FI_VENTILATION,      # Filtered air texture
	SCI_FI_ELECTROMAGNETIC,  # Subtle tech interference
	# Cinematic / Movie-inspired sounds
	CS80_BRASS_LEAD,         # Vangelis-style CS-80 brass lead
	CINEMATIC_432HZ_PAD,      # Warm pad tuned to 432Hz base
	# Pop Music / Synth Legends
	POP_JUNO_CHORUS_PAD,     # Roland Juno-106 Lush Pad
	POP_DX7_BALLAD_KEYS,     # Yamaha DX7 E-Piano
	POP_OBXA_BRASS,          # Oberheim OB-Xa Jump Brass
	POP_PROPHET_LEAD,        # Prophet-5 Sync Lead
	POP_FUNK_BASS,           # Minimoog Funk Bass
	POP_INTERACTIVE_SONG,    # Procedural Pop Song (Interactive Stream)
	AMBIENT_WORKS_SONG,      # Aphex Twin Style Ambient (Interactive Stream)
	# Biological / Ambient sounds
	HEARTBEAT,               # Biological heartbeat with lub-dub rhythm
	LAB_HUM                  # Sterile lab ambience with multi-layered sine hum
}

# Sound generation functions
static func generate_sound(type: SoundType, duration: float = 1.0, parameters: Dictionary = {}) -> AudioStream:
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	match type:
		SoundType.POP_INTERACTIVE_SONG:
			return generate_pop_interactive_song(parameters)
		SoundType.AMBIENT_WORKS_SONG:
			return generate_ambient_works_song(parameters)
		SoundType.BASIC_SINE_WAVE:
			_generate_basic_sine_wave(data, sample_count)
		SoundType.PICKUP_MARIO:
			_generate_pickup_sound(data, sample_count)
		SoundType.TELEPORT_DRONE:
			_generate_teleport_drone(data, sample_count)
		SoundType.LIFT_BASS_PULSE:
			_generate_bass_pulse(data, sample_count)
		SoundType.GHOST_DRONE:
			_generate_ghost_drone(data, sample_count)
		SoundType.MELODIC_DRONE:
			_generate_melodic_drone(data, sample_count)
		SoundType.LASER_SHOT:
			_generate_laser_shot(data, sample_count)
		SoundType.POWER_UP_JINGLE:
			_generate_power_up_jingle(data, sample_count)
		SoundType.EXPLOSION:
			_generate_explosion(data, sample_count)
		SoundType.RETRO_JUMP:
			_generate_retro_jump(data, sample_count)
		SoundType.SHIELD_HIT:
			_generate_shield_hit(data, sample_count)
		SoundType.AMBIENT_WIND:
			_generate_ambient_wind(data, sample_count)
		SoundType.DARK_808_KICK:
			_generate_dark_808_kick(data, sample_count)
		SoundType.ACID_606_HIHAT:
			_generate_acid_606_hihat(data, sample_count)
		SoundType.DARK_808_SUB_BASS:
			_generate_dark_808_sub_bass(data, sample_count)
		SoundType.AMBIENT_AMIGA_DRONE:
			_generate_ambient_amiga_drone(data, sample_count)
		SoundType.MOOG_BASS_LEAD:
			_generate_moog_bass_lead(data, sample_count)
		SoundType.TB303_ACID_BASS:
			_generate_tb303_acid_bass(data, sample_count)
		SoundType.DX7_ELECTRIC_PIANO:
			_generate_dx7_electric_piano(data, sample_count)
		SoundType.C64_SID_LEAD:
			_generate_c64_sid_lead(data, sample_count)
		SoundType.AMIGA_MOD_SAMPLE:
			_generate_amiga_mod_sample(data, sample_count)
		SoundType.PPG_WAVE_PAD:
			_generate_ppg_wave_pad(data, sample_count)
		SoundType.TR909_KICK:
			_generate_tr909_kick(data, sample_count)
		SoundType.JUPITER_8_STRINGS:
			_generate_jupiter_8_strings(data, sample_count)
		SoundType.KORG_M1_PIANO:
			_generate_korg_m1_piano(data, sample_count)
		SoundType.ARP_2600_LEAD:
			_generate_arp_2600_lead(data, sample_count)
		SoundType.SYNARE_3_DISCO_TOM:
			_generate_synare_3_disco_tom(data, sample_count)
		SoundType.SYNARE_3_COSMIC_FX:
			_generate_synare_3_cosmic_fx(data, sample_count)
		SoundType.MOOG_KRAFTWERK_SEQUENCER:
			_generate_moog_kraftwerk_sequencer(data, sample_count)
		SoundType.HERBIE_HANCOCK_MOOG_FUSION:
			_generate_herbie_hancock_moog_fusion(data, sample_count)
		SoundType.APHEX_TWIN_MODULAR:
			_generate_aphex_twin_modular(data, sample_count)
		SoundType.FLYING_LOTUS_SAMPLER:
			_generate_flying_lotus_sampler(data, sample_count)
		SoundType.SCI_FI_LAB_HUM_CLEAN:
			_generate_sci_fi_lab_hum_clean(data, sample_count)
		SoundType.SCI_FI_RESONANT_DRONE:
			_generate_sci_fi_resonant_drone(data, sample_count)
		SoundType.SCI_FI_DATA_CHIRPS:
			_generate_sci_fi_data_chirps(data, sample_count)
		SoundType.SCI_FI_VENTILATION:
			_generate_sci_fi_ventilation(data, sample_count)
		SoundType.SCI_FI_ELECTROMAGNETIC:
			_generate_sci_fi_electromagnetic(data, sample_count)
		SoundType.CS80_BRASS_LEAD:
			_generate_cs80_brass_lead(data, sample_count)
		SoundType.CINEMATIC_432HZ_PAD:
			_generate_cinematic_432hz_pad(data, sample_count)
		SoundType.POP_JUNO_CHORUS_PAD:
			_generate_juno_chorus_pad(data, sample_count)
		SoundType.POP_DX7_BALLAD_KEYS:
			_generate_dx7_ballad_keys(data, sample_count)
		SoundType.POP_OBXA_BRASS:
			_generate_obxa_brass(data, sample_count)
		SoundType.POP_PROPHET_LEAD:
			_generate_prophet_lead(data, sample_count)
		SoundType.POP_FUNK_BASS:
			_generate_funk_bass(data, sample_count)
	
	return _create_audio_stream(data)

static func _generate_basic_sine_wave(data: PackedFloat32Array, sample_count: int):
	# Simple sine wave: amplitude * sin(2π * frequency * time)
	var frequency = 440.0  # A4 note
	var amplitude = 0.3
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		data[i] = amplitude * sin(2.0 * PI * frequency * t)

static func _generate_pickup_sound(data: PackedFloat32Array, sample_count: int):
	# Mario-style pickup: rising frequency with envelope
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Rising frequency from 440Hz to 880Hz
		var freq = 440.0 + (440.0 * progress)
		
		# Sharp attack, quick decay envelope
		var envelope = exp(-progress * 8.0)
		
		# Square wave for retro feel
		var wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
		
		data[i] = wave * envelope * 0.3

static func _generate_teleport_drone(data: PackedFloat32Array, sample_count: int):
	# Electrostatic drone with modulation - harsh sawtooth with noise
	var _duration = float(sample_count) / SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency with slow modulation
		var base_freq = 220.0
		var mod_freq = 0.5
		var freq = base_freq + sin(2.0 * PI * mod_freq * t) * 30.0
		
		# Sawtooth wave for harsh sound
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Add deterministic noise for electrostatic feel (not random for looping)
		var noise_t = t * 1000.0  # High frequency noise
		var noise = sin(noise_t) * 0.3 + sin(noise_t * 1.7) * 0.2 + sin(noise_t * 2.3) * 0.1
		noise = noise * 0.2
		
		# Smooth envelope: fade in -> stay -> fade out -> silence
		var envelope = 0.0
		if progress < 0.05:  # Quick fade in first 5%
			envelope = progress / 0.05
		elif progress < 0.9:  # Stay steady for most of the time
			envelope = 1.0
		elif progress < 0.98:  # Quick fade out
			envelope = (0.98 - progress) / 0.08
		else:  # Silent for last 2%
			envelope = 0.0
		
		# Apply smooth curve to envelope to avoid clicks
		envelope = envelope * envelope * (3.0 - 2.0 * envelope)  # Smoothstep
		
		data[i] = (wave + noise) * 0.2 * envelope

static func _generate_bass_pulse(data: PackedFloat32Array, sample_count: int):
	# Deep bass pulse for lifts
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Very low frequency
		var freq = 60.0
		
		# Pulse envelope - sharp attack, slow decay
		var pulse_rate = 2.0  # 2 Hz pulse
		var pulse = abs(sin(2.0 * PI * pulse_rate * t))
		var envelope = exp(-t * 2.0)
		
		# Sine wave for smooth bass
		var wave = sin(2.0 * PI * freq * t)
		
		data[i] = wave * pulse * envelope * 0.4

static func _generate_ghost_drone(data: PackedFloat32Array, sample_count: int):
	# Ghostly atmospheric drone - designed for seamless looping
	var duration = float(sample_count) / SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Multiple frequency layers
		var freq1 = 110.0
		var freq2 = 165.0  # Perfect fifth
		var freq3 = 220.0  # Octave
		
		# Slow amplitude modulation that completes full cycles
		var mod_freq = 2.0 / duration  # 2 complete modulation cycles per loop
		var mod = sin(2.0 * PI * mod_freq * t) * 0.3 + 0.7
		
		# Layered sine waves
		var wave = sin(2.0 * PI * freq1 * t) * 0.4
		wave += sin(2.0 * PI * freq2 * t) * 0.3
		wave += sin(2.0 * PI * freq3 * t) * 0.2
		
		data[i] = wave * mod * 0.15

static func _generate_melodic_drone(data: PackedFloat32Array, sample_count: int):
	# Beautiful melodic drone with harmony
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Harmonic series based on 220Hz
		var fundamental = 220.0
		var wave = 0.0
		
		# Add harmonics with decreasing amplitude
		wave += sin(2.0 * PI * fundamental * t) * 0.4        # Fundamental
		wave += sin(2.0 * PI * fundamental * 1.5 * t) * 0.3  # Perfect fifth
		wave += sin(2.0 * PI * fundamental * 2.0 * t) * 0.2  # Octave
		wave += sin(2.0 * PI * fundamental * 3.0 * t) * 0.1  # Perfect fifth above
		
		# Gentle tremolo
		var tremolo = sin(2.0 * PI * 4.0 * t) * 0.1 + 0.9
		
		data[i] = wave * tremolo * 0.2

static func _generate_laser_shot(data: PackedFloat32Array, sample_count: int):
	# Sci-fi laser beam - frequency sweep with sharp attack
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dramatic frequency sweep from high to low
		var start_freq = 2000.0
		var end_freq = 100.0
		var freq = start_freq + (end_freq - start_freq) * (progress * progress)  # Quadratic curve
		
		# Sharp attack, exponential decay
		var envelope = exp(-progress * 12.0) if progress < 0.1 else exp(-(progress - 0.1) * 4.0) * 0.3
		
		# Sawtooth wave for harsh laser character
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Add high-frequency harmonics for electric character
		wave += sin(2.0 * PI * freq * 3.0 * t) * 0.3 * envelope
		
		data[i] = wave * envelope * 0.4

static func _generate_power_up_jingle(data: PackedFloat32Array, sample_count: int):
	# Achievement/reward - ascending arpeggio in C major
	var duration = float(sample_count) / SAMPLE_RATE
	var note_duration = duration / 4.0  # 4 notes
	
	# C major arpeggio: C, E, G, C (262, 330, 392, 523 Hz)
	var frequencies = [262.0, 330.0, 392.0, 523.0]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var note_index = int(t / note_duration)
		note_index = clamp(note_index, 0, 3)
		
		var note_t = fmod(t, note_duration) / note_duration  # Progress within current note
		var freq = frequencies[note_index]
		
		# Bell-like envelope for each note
		var envelope = exp(-note_t * 3.0) * sin(PI * note_t)
		
		# Clean sine wave with subtle harmonics
		var wave = sin(2.0 * PI * freq * t) * 0.8
		wave += sin(2.0 * PI * freq * 2.0 * t) * 0.2  # Octave harmonic
		
		data[i] = wave * envelope * 0.3

static func _generate_explosion(data: PackedFloat32Array, sample_count: int):
	# Multi-band explosion - low rumble, mid crack, high sizzle
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Three frequency bands with different characteristics
		
		# Low rumble (20-100 Hz) - long decay
		var low_freq = 20.0 + sin(2.0 * PI * 0.5 * t) * 30.0
		var low_envelope = exp(-progress * 1.5)
		var low_wave = sin(2.0 * PI * low_freq * t) * low_envelope * 0.6
		
		# Mid crack (200-800 Hz) - sharp attack
		var mid_freq = 400.0 + sin(2.0 * PI * 3.0 * t) * 200.0
		var mid_envelope = exp(-progress * 8.0)
		var mid_wave = (2.0 * (mid_freq * t - floor(mid_freq * t)) - 1.0) * mid_envelope * 0.4
		
		# High sizzle (1-8 kHz) - noise-like, quick decay
		var high_noise = sin(t * 15000.0) * 0.3 + sin(t * 22000.0) * 0.2 + sin(t * 31000.0) * 0.1
		var high_envelope = exp(-progress * 15.0)
		var high_wave = high_noise * high_envelope * 0.3
		
		# Combine all bands
		data[i] = (low_wave + mid_wave + high_wave) * 0.5

static func _generate_retro_jump(data: PackedFloat32Array, sample_count: int):
	# Classic platformer jump - rising pitch with square wave
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Rising frequency curve (like jumping up)
		var start_freq = 150.0
		var peak_freq = 400.0
		var freq = start_freq + (peak_freq - start_freq) * sin(PI * progress * 0.7)  # Rise then level off
		
		# Sharp attack, medium decay
		var envelope = exp(-progress * 4.0) if progress < 0.05 else exp(-(progress - 0.05) * 2.0) * 0.8
		
		# Square wave with variable duty cycle
		var duty = 0.5 + sin(2.0 * PI * 2.0 * t) * 0.1  # Slight duty cycle modulation
		var phase = fmod(freq * t, 1.0)
		var wave = 1.0 if phase < duty else -1.0
		
		data[i] = wave * envelope * 0.35

static func _generate_shield_hit(data: PackedFloat32Array, sample_count: int):
	# Metallic impact - ring modulation and resonance
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Main resonant frequency
		var main_freq = 800.0
		var ring_freq = 60.0  # Ring modulation frequency
		
		# Sharp metallic attack, ringing decay
		var envelope = exp(-progress * 6.0)
		
		# Ring modulated sine wave for metallic character
		var carrier = sin(2.0 * PI * main_freq * t)
		var modulator = sin(2.0 * PI * ring_freq * t) * 0.5 + 0.5
		var ring_mod = carrier * modulator
		
		# Add harmonic resonances
		ring_mod += sin(2.0 * PI * main_freq * 1.5 * t) * 0.4 * envelope
		ring_mod += sin(2.0 * PI * main_freq * 2.0 * t) * 0.2 * envelope
		
		# Add initial impact "clank"
		var impact = exp(-progress * 50.0) * (sin(2.0 * PI * 1200.0 * t) * 0.8)
		
		data[i] = (ring_mod * envelope + impact) * 0.3

static func _generate_ambient_wind(data: PackedFloat32Array, sample_count: int):
	# Atmospheric texture - filtered noise with slow modulation
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Generate pseudo-random noise using multiple sine waves
		var noise = 0.0
		noise += sin(t * 100.0) * 0.4
		noise += sin(t * 237.0) * 0.3
		noise += sin(t * 341.0) * 0.2
		noise += sin(t * 567.0) * 0.1
		
		# Low-pass filter simulation (simple averaging)
		# This creates a "whooshing" filtered noise effect
		var filtered_noise = noise * 0.7
		
		# Slow amplitude modulation for wind gusts
		var gust_mod1 = sin(2.0 * PI * 0.2 * t) * 0.3 + 0.7  # 0.2 Hz
		var gust_mod2 = sin(2.0 * PI * 0.07 * t) * 0.2 + 0.8  # 0.07 Hz
		var modulation = gust_mod1 * gust_mod2
		
		# Add subtle tonal elements (like wind through objects)
		var tonal = sin(2.0 * PI * 80.0 * t) * 0.1 + sin(2.0 * PI * 120.0 * t) * 0.05
		
		data[i] = (filtered_noise + tonal) * modulation * 0.2

static func _generate_dark_808_kick(data: PackedFloat32Array, sample_count: int):
	# Deep 808 kick with pitch envelope and click attack
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pitch envelope - starts at start_freq, drops to end_freq
		var start_freq = 60.0
		var end_freq = 35.0
		var freq = start_freq + (end_freq - start_freq) * (1.0 - exp(-progress * 4.0))
		
		# Main 808 body - sine wave with saturation
		var body = sin(2.0 * PI * freq * t)
		
		# Apply saturation/distortion
		var saturation = 1.5
		body = tanh(body * saturation) / saturation
		
		# Click attack component
		var click_freq = 1200.0
		var click_decay = 80.0
		var click = sin(2.0 * PI * click_freq * t) * exp(-progress * click_decay)
		
		# Amplitude envelope
		var envelope = exp(-progress * 4.0)
		
		data[i] = (body * envelope + click * 0.1) * 0.7

static func _generate_acid_606_hihat(data: PackedFloat32Array, sample_count: int):
	# Filtered noise hi-hat with metallic ring characteristic of 606
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Generate high-frequency noise
		var noise = 0.0
		noise += sin(t * 8000.0 + sin(t * 15000.0)) * 0.4
		noise += sin(t * 12000.0 + sin(t * 18000.0)) * 0.3
		noise += sin(t * 16000.0 + sin(t * 22000.0)) * 0.2
		
		# Apply noise intensity
		noise *= 2.0
		
		# Filter sweep - high-pass filter simulation
		var filter_start_freq = 8000.0
		var filter_sweep = 3000.0
		var filter_freq = filter_start_freq + filter_sweep * progress
		
		# Simple high-pass filtering by reducing low frequencies
		var filtered_noise = noise * (1.0 + filter_freq / 8000.0)
		
		# Metallic ring component
		var metallic_freq = 12000.0
		var ring = sin(2.0 * PI * metallic_freq * t) * 0.2
		
		# Sharp decay envelope
		var envelope = exp(-progress * 15.0)
		
		data[i] = (filtered_noise + ring) * envelope * 0.3

static func _generate_dark_808_sub_bass(data: PackedFloat32Array, sample_count: int):
	# Deep sub bass with slow modulation and dark character
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency with slow modulation
		var base_freq = 35.0
		var mod_freq = 0.3
		var mod_depth = 5.0
		var freq = base_freq + sin(2.0 * PI * mod_freq * t) * mod_depth
		
		# Fundamental sine wave
		var fundamental = sin(2.0 * PI * freq * t)
		
		# Add harmonics for richness
		var harmonic2 = sin(2.0 * PI * freq * 2.0 * t) * 0.1
		var harmonic3 = sin(2.0 * PI * freq * 3.0 * t) * 0.05
		
		# Slow attack and very slow decay
		var envelope = 1.0
		if progress < 0.2:  # Attack phase
			envelope = progress / 0.2
		else:  # Decay phase
			envelope = exp(-(progress - 0.2) * 0.5)
		
		data[i] = (fundamental + harmonic2 + harmonic3) * envelope * 0.5

static func _generate_ambient_amiga_drone(data: PackedFloat32Array, sample_count: int):
	# Multi-layered ambient drone with slow modulation and detuning
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Three frequency layers
		var freq1 = 45.0   # Fundamental
		var freq2 = 90.0   # Octave
		var freq3 = 67.5   # Perfect fifth
		
		# Slow modulation
		var mod_freq = 0.13
		var mod_depth = 0.3
		var mod_offset = 0.7
		var modulation = sin(2.0 * PI * mod_freq * t) * mod_depth + mod_offset
		
		# Layer 1 - fundamental with detuning
		var detune1 = sin(2.0 * PI * 0.07 * t) * 0.7
		var layer1 = sin(2.0 * PI * (freq1 + detune1) * t) * 0.5
		
		# Layer 2 - octave
		var layer2 = sin(2.0 * PI * freq2 * t) * 0.3
		
		# Layer 3 - fifth with slight detuning
		var detune3 = sin(2.0 * PI * 0.11 * t) * 0.5
		var layer3 = sin(2.0 * PI * (freq3 + detune3) * t) * 0.2
		
		# Additional detuned layer for thickness
		var detune_layer = sin(2.0 * PI * (freq1 + 0.7) * t) * 0.1
		
		# Combine all layers
		var combined = (layer1 + layer2 + layer3 + detune_layer) * modulation
		
		data[i] = combined * 0.3

static func _generate_moog_bass_lead(data: PackedFloat32Array, sample_count: int):
	# Classic Moog lead/bass with ladder filter and oscillator sync
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dual oscillator setup
		var osc1_freq = 110.0
		var osc2_freq = 220.0
		var detune = 0.3
		
		# Sawtooth waves for classic Moog sound
		var osc1 = 2.0 * (osc1_freq * t - floor(osc1_freq * t)) - 1.0
		var osc2 = 2.0 * ((osc2_freq + detune) * t - floor((osc2_freq + detune) * t)) - 1.0
		
		# Mix oscillators
		var mixed = osc1 * 0.6 + osc2 * 0.4
		
		# Ladder filter simulation (simple low-pass)
		var filter_cutoff = 2000.0
		var resonance = 0.7
		var filter_env = exp(-progress * 2.0)
		var filtered = mixed * (filter_cutoff / 8000.0) * (1.0 + resonance * filter_env)
		
		# ADSR envelope
		var envelope = 1.0
		if progress < 0.01:  # Attack
			envelope = progress / 0.01
		elif progress < 0.3:  # Decay
			envelope = 1.0 - (progress - 0.01) * 0.3 / 0.29
		elif progress < 0.8:  # Sustain
			envelope = 0.7
		else:  # Release
			envelope = 0.7 * (1.0 - (progress - 0.8) / 0.2)
		
		data[i] = filtered * envelope * 0.4

static func _generate_tb303_acid_bass(data: PackedFloat32Array, sample_count: int):
	# Roland TB-303 acid bass with characteristic filter sweep
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency
		var base_freq = 82.4  # Low E
		
		# Sawtooth wave for classic 303 sound
		var wave = 2.0 * (base_freq * t - floor(base_freq * t)) - 1.0
		
		# Characteristic filter sweep
		var filter_cutoff = 800.0 + sin(2.0 * PI * 0.5 * t) * 400.0
		var resonance = 0.85
		
		# Filter simulation
		var filter_factor = filter_cutoff / 4000.0
		var filtered = wave * filter_factor * (1.0 + resonance)
		
		# Add slight distortion for grit
		filtered = tanh(filtered * 1.3)
		
		# Envelope with accent
		var envelope = exp(-progress * 5.0)
		var accent = 1.0 + 0.6 * exp(-progress * 20.0)
		
		data[i] = filtered * envelope * accent * 0.3

static func _generate_dx7_electric_piano(data: PackedFloat32Array, sample_count: int):
	# Yamaha DX7 FM electric piano - the sound of the 80s
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# FM synthesis parameters
		var carrier_freq = 220.0
		var modulator_ratio = 2.0
		var fm_index = 3.0
		
		# Modulator envelope (quick decay for bell-like attack)
		var mod_env = exp(-progress * 8.0)
		
		# Carrier envelope (slower decay for sustain)
		var carrier_env = exp(-progress * 2.0) * 0.7 + 0.3
		
		# FM synthesis
		var modulator_freq = carrier_freq * modulator_ratio
		var modulator = sin(2.0 * PI * modulator_freq * t) * fm_index * mod_env
		var carrier = sin(2.0 * PI * carrier_freq * t + modulator)
		
		data[i] = carrier * carrier_env * 0.4

static func _generate_c64_sid_lead(data: PackedFloat32Array, sample_count: int):
	# Commodore 64 SID chip lead sound with PWM and ring modulation
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency
		var base_freq = 440.0
		
		# Pulse width modulation
		var pwm_rate = 6.0
		var pwm_depth = 0.3
		var pulse_width = 0.25 + sin(2.0 * PI * pwm_rate * t) * pwm_depth
		
		# Generate pulse wave
		var phase = fmod(base_freq * t, 1.0)
		var pulse = 1.0 if phase < pulse_width else -1.0
		
		# Ring modulation for metallic character
		var ring_freq = base_freq * 1.5
		var ring_mod = sin(2.0 * PI * ring_freq * t) * 0.2 + 0.8
		
		# Filter simulation (simple resonant low-pass)
		var filter_cutoff = 2000.0
		var resonance = 0.6
		var filtered = pulse * (filter_cutoff / 8000.0) * (1.0 + resonance)
		
		# ADSR envelope
		var envelope = 1.0
		if progress < 0.01:  # Attack
			envelope = progress / 0.01
		elif progress < 0.2:  # Decay
			envelope = 1.0 - (progress - 0.01) * 0.5 / 0.19
		elif progress < 0.7:  # Sustain
			envelope = 0.5
		else:  # Release
			envelope = 0.5 * (1.0 - (progress - 0.7) / 0.3)
		
		data[i] = filtered * ring_mod * envelope * 0.35

static func _generate_amiga_mod_sample(data: PackedFloat32Array, sample_count: int):
	# Amiga ProTracker style sample with Paula chip characteristics
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency (C4)
		var base_freq = 261.6
		
		# Generate sawtooth wave (common in Amiga samples)
		var wave = 2.0 * (base_freq * t - floor(base_freq * t)) - 1.0
		
		# Paula chip filtering (simple low-pass for warmth)
		var paula_filter = 0.7
		var filtered = wave * paula_filter
		
		# Bit crushing simulation (8-bit characteristic)
		var bit_depth = 8
		var quantization = pow(2, bit_depth - 1)
		var crushed = floor(filtered * quantization) / quantization
		
		# Simple loop with crossfade
		var loop_point = 0.5
		if progress > loop_point:
			var fade = (1.0 - progress) / (1.0 - loop_point)
			crushed *= fade
		
		data[i] = crushed * 0.8

static func _generate_ppg_wave_pad(data: PackedFloat32Array, sample_count: int):
	# PPG Wave 2.2 wavetable pad
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Wavetable position (morphing between waveforms)
		var wavetable_pos = 0.3  # Default position
		
		# Generate morphing wavetable
		var base_freq = 220.0
		var wave1 = sin(2.0 * PI * base_freq * t)  # Sine
		var wave2 = 2.0 * (base_freq * t - floor(base_freq * t)) - 1.0  # Sawtooth
		var wave = wave1 * (1.0 - wavetable_pos) + wave2 * wavetable_pos
		
		# LFO modulation
		var lfo = sin(2.0 * PI * 0.5 * t) * 0.2
		wave *= (1.0 + lfo)
		
		# ADSR envelope for pad
		var envelope = 1.0
		if progress < 0.2:  # Attack
			envelope = progress / 0.2
		elif progress > 0.8:  # Release
			envelope = (1.0 - progress) / 0.2
		
		data[i] = wave * envelope * 0.4

static func _generate_tr909_kick(data: PackedFloat32Array, sample_count: int):
	# Roland TR-909 kick drum
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pitch envelope (starts high, drops quickly)
		var pitch_start = 120.0
		var pitch_end = 60.0
		var pitch_envelope = exp(-progress * 20.0)
		var freq = pitch_end + (pitch_start - pitch_end) * pitch_envelope
		
		# Generate kick wave (sine with click)
		var kick = sin(2.0 * PI * freq * t)
		
		# Add click attack
		var click = sin(2.0 * PI * 2000.0 * t) * exp(-progress * 50.0) * 0.3
		
		# Amplitude envelope
		var envelope = exp(-progress * 8.0)
		
		data[i] = (kick + click) * envelope * 0.8

static func _generate_jupiter_8_strings(data: PackedFloat32Array, sample_count: int):
	# Roland Jupiter-8 string ensemble
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Multiple oscillators for richness
		var fundamental = 220.0
		var wave = 0.0
		wave += sin(2.0 * PI * fundamental * t) * 0.3
		wave += sin(2.0 * PI * fundamental * 1.5 * t) * 0.2  # Fifth
		wave += sin(2.0 * PI * fundamental * 2.0 * t) * 0.15  # Octave
		wave += sin(2.0 * PI * fundamental * 3.0 * t) * 0.1   # Higher harmonics
		
		# Chorus effect simulation
		var chorus_rate = 1.2
		var chorus = sin(2.0 * PI * chorus_rate * t) * 0.3 + 1.0
		wave *= chorus
		
		# String envelope (slow attack)
		var envelope = 1.0
		if progress < 0.3:  # Attack
			envelope = progress / 0.3
		elif progress > 0.7:  # Release
			envelope = (1.0 - progress) / 0.3
		
		data[i] = wave * envelope * 0.3

static func _generate_korg_m1_piano(data: PackedFloat32Array, sample_count: int):
	# Korg M1 digital piano
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Digital piano harmonics
		var freq = 261.6  # C4
		var wave = 0.0
		wave += sin(2.0 * PI * freq * t) * 0.5
		wave += sin(2.0 * PI * freq * 2.0 * t) * 0.2
		wave += sin(2.0 * PI * freq * 3.0 * t) * 0.1
		wave += sin(2.0 * PI * freq * 4.0 * t) * 0.05
		
		# Piano envelope (quick attack, slow decay)
		var envelope = 1.0
		if progress < 0.01:  # Quick attack
			envelope = progress / 0.01
		else:  # Exponential decay
			envelope = exp(-(progress - 0.01) * 3.0)
			
		data[i] = wave * envelope * 0.35

static func _generate_juno_chorus_pad(data: PackedFloat32Array, sample_count: int, chord_freqs: Array = [220.0]):
	# Roland Juno-106 Lush Pad (Polyphonic)
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# PWM LFO
		var pwm_lfo = sin(2.0 * PI * 0.5 * t) * 0.4 + 0.5
		
		var mixed = 0.0
		
		for freq in chord_freqs:
			# Layer 1: Center Pulse-Saw
			var wave1 = _get_pulse_saw(freq, t, pwm_lfo)
			
			# Layer 2: Left Detune (Chorus I)
			var detune1 = sin(2.0 * PI * 0.5 * t) * 0.003
			var wave2 = _get_pulse_saw(freq * (1.0 + detune1), t, pwm_lfo)
			
			# Layer 3: Right Detune (Chorus II)
			var detune2 = cos(2.0 * PI * 0.8 * t) * 0.005
			var wave3 = _get_pulse_saw(freq * (1.0 - detune2), t, pwm_lfo) 
			
			mixed += (wave1 * 0.5) + (wave2 * 0.3) + (wave3 * 0.3)
		
		# Normalize gain based on voice count
		mixed /= max(1, chord_freqs.size())
		
		# ADSR Pad Envelope
		var envelope = 1.0
		if progress < 0.3: envelope = progress / 0.3
		elif progress > 0.6: envelope = (1.0 - progress) / 0.4
			
		data[i] = mixed * envelope * 0.3

static func _get_pulse_saw(freq: float, t: float, width: float) -> float:
	# Hybrid Sawtooth / Pulse wave
	var phase = fmod(freq * t, 1.0)
	var saw = 2.0 * phase - 1.0
	var pulse = 1.0 if phase < width else -1.0
	return saw * 0.5 + pulse * 0.5

static func _generate_dx7_ballad_keys(data: PackedFloat32Array, sample_count: int, chord_freqs: Array = [329.63]):
	# Yamaha DX7 Electric Piano (FM) - Polyphonic
	# Algorithm: Modulator -> Carrier
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var mixed = 0.0
		for freq in chord_freqs:
			# Modulator (Metal/Tine character)
			# Ratio 14.0 for bell like tone
			var mod_ratio = 14.0
			var mod_env = exp(-progress * 10.0) # Quick decay
			var mod_index = 2.0 * mod_env
			var modulator = sin(2.0 * PI * freq * mod_ratio * t) * mod_index
			
			# Carrier 1 (Body)
			# Ratio 1.0
			var car1_env = exp(-progress * 2.0)
			var car1 = sin(2.0 * PI * freq * t + modulator) * car1_env
			
			# Carrier 2 (Thump/Bass)
			var car2_env = exp(-progress * 5.0)
			var car2 = sin(2.0 * PI * freq * t) * car2_env * 0.5
			
			mixed += (car1 + car2) * 0.5
			
		mixed /= max(1, chord_freqs.size())
		data[i] = mixed * 0.5

static func _generate_obxa_brass(data: PackedFloat32Array, sample_count: int, chord_freqs: Array = [130.81]):
	# Oberheim OB-Xa "Jump" Brass - Polyphonic
	# Detuned Sawtooths + Filter Envelope
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var mixed = 0.0
		for freq in chord_freqs:
			var osc1 = _get_saw(freq, t)
			var osc2 = _get_saw(freq * 1.01, t) # Detuned
			var osc3 = _get_saw(freq * 0.995, t) # Detuned flat
			
			mixed += (osc1 + osc2 + osc3) * 0.33
			
		mixed /= max(1, chord_freqs.size())
		
		# Filter Envelope (Bright attack, sustain)
		var filter_env = 0.0
		if progress < 0.1: filter_env = progress / 0.1 + 0.5
		else: filter_env = max(0.5, 1.5 - (progress - 0.1) * 2.0)
		
		# Simulate filter by scaling amplitude of a high-pass layer? 
		# Or just cheat: Bright saw vs Dull saw mix
		# "Jump" sound is VERY bright. Let's just use the raw saw with a volume envelope.
		
		var amp_env = 1.0
		if progress < 0.05: amp_env = progress / 0.05
		elif progress > 0.8: amp_env = (1.0 - progress) / 0.2
		
		data[i] = mixed * amp_env * filter_env * 0.4

static func _get_saw(freq: float, t: float) -> float:
	return 2.0 * (freq * t - floor(freq * t)) - 1.0

static func _generate_prophet_lead(data: PackedFloat32Array, sample_count: int, freq: float = 440.0):
	# Prophet-5 Sync Lead (Monophonic)
	# Oscillator Sync effect
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var master_freq = freq
		# Slave freq sweeps up
		var slave_freq = freq * (1.0 + sin(2.0 * PI * 2.0 * t) * 0.5 + 1.0) 
		
		# Master resets Slave phase
		var _master_phase = fmod(master_freq * t, 1.0)
		var _slave_phase = fmod(slave_freq * t, 1.0)
		
		# Hard Sync simulation: 
		# Real hard sync resets slave phase when master phase resets.
		# analytically: 
		var sync_time = floor(master_freq * t) / master_freq
		var time_since_sync = t - sync_time
		var synced_slave_phase = fmod(slave_freq * time_since_sync, 1.0)
		
		var wave = 2.0 * synced_slave_phase - 1.0
		
		var env = 1.0
		if progress > 0.9: env = (1.0 - progress) / 0.1
		
		data[i] = wave * env * 0.3

static func _generate_funk_bass(data: PackedFloat32Array, sample_count: int, freq: float = 55.0):
	# Minimoog Funk Bass (Monophonic)
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var saw = _get_saw(freq, t)
		var square = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
		var mix = saw * 0.7 + square * 0.3
		
		# Filter Env (Snap)
		var f_env = exp(-progress * 15.0)
		
		# Amp Env
		var a_env = exp(-progress * 5.0)
		
		data[i] = mix * a_env * (0.5 + 0.5 * f_env) * 0.6

static func _generate_arp_2600_lead(data: PackedFloat32Array, sample_count: int):
	# ARP 2600 analog lead synthesizer
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Sawtooth wave
		var freq = 440.0
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Filter sweep
		var filter_cutoff = 1500.0 + sin(2.0 * PI * 2.0 * t) * 800.0
		var filter_factor = clamp(filter_cutoff / 4000.0, 0.3, 1.0)
		wave *= filter_factor
		
		# ADSR envelope
		var envelope = 1.0
		if progress < 0.05:  # Attack
			envelope = progress / 0.05
		elif progress < 0.3:  # Decay
			envelope = 1.0 - (progress - 0.05) * 0.3 / 0.25
		elif progress < 0.7:  # Sustain
			envelope = 0.7
		else:  # Release
			envelope = 0.7 * (1.0 - (progress - 0.7) / 0.3)
		
		data[i] = wave * envelope * 0.6

static func _generate_synare_3_disco_tom(data: PackedFloat32Array, sample_count: int):
	# Star Instruments Synare 3 disco tom - the "Ring My Bell" sound
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dual oscillators with pitch envelope
		var osc1_freq = 200.0 * (1.0 + 0.7 * exp(-progress * 8.0))  # Pitch envelope drops
		var osc2_freq = 400.0 * (1.0 + 0.7 * exp(-progress * 8.0))
		
		# Generate oscillator waves (pulse waves)
		var osc1 = 1.0 if sin(2.0 * PI * osc1_freq * t) > 0.3 else -1.0
		var osc2 = 1.0 if sin(2.0 * PI * osc2_freq * t) > 0.3 else -1.0
		
		# Mix oscillators
		var osc_mix = osc1 * 0.3 + osc2 * 0.7
		
		# Add noise component
		var noise_t = t * 5000.0  # High frequency noise
		var noise = sin(noise_t) * 0.7 + sin(noise_t * 1.3) * 0.3
		noise = noise * 0.3
		
		# Filter with resonance and sweep
		var filter_cutoff = 1200.0 * exp(-progress * 2.0)  # Downward sweep
		var filter_factor = clamp(filter_cutoff / 2000.0, 0.2, 1.0)
		
		# Apply resonance (simple resonant peak)
		var resonance_boost = 1.0 + 0.6 * exp(-(abs(filter_cutoff - 800.0) / 200.0))
		filter_factor *= resonance_boost
		
		var wave = (osc_mix + noise) * filter_factor
		
		# ADSR envelope (tom-like: instant attack, long decay)
		var envelope = 1.0
		if progress < 0.001:  # Instant attack
			envelope = progress / 0.001
		else:  # Exponential decay
			envelope = exp(-progress * 2.5)
		
		# Analog drift simulation
		var drift = sin(2.0 * PI * 0.02 * t) * 0.02
		envelope *= (1.0 + drift)
		
		data[i] = wave * envelope * 0.5

static func _generate_synare_3_cosmic_fx(data: PackedFloat32Array, sample_count: int):
	# Star Instruments Synare 3 cosmic FX - UFO and space sounds
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Frequency sweep (exponential curve from low to high)
		var start_freq = 100.0
		var end_freq = 2000.0
		var freq = start_freq * pow(end_freq / start_freq, progress)
		
		# Dual oscillators with slight detuning
		var osc1 = sin(2.0 * PI * freq * t)
		var osc2 = sin(2.0 * PI * freq * 1.02 * t)  # Slight detune
		
		# LFO modulation for wobble effect
		var lfo = sin(2.0 * PI * 2.0 * t) * 0.3
		var modulated_freq = freq * (1.0 + lfo)
		
		# Mix oscillators with noise
		var wave = osc1 * 0.8 + osc2 * 0.6
		
		# Add cosmic noise
		var noise_t = t * 1000.0
		var noise = sin(noise_t) * 0.4 + sin(noise_t * 1.3) * 0.3
		wave += noise * 0.4
		
		# Filter with high resonance for cosmic effect
		var filter_cutoff = modulated_freq * 1.5
		var filter_factor = clamp(filter_cutoff / 3000.0, 0.3, 1.0)
		wave *= filter_factor * 1.85  # High resonance
		
		# Envelope (slow attack, long release)
		var envelope = 1.0
		if progress < 0.25:  # Attack
			envelope = progress / 0.25
		else:  # Release
			envelope = exp(-(progress - 0.25) * 1.5)
		
		data[i] = wave * envelope * 0.4

static func _generate_moog_kraftwerk_sequencer(data: PackedFloat32Array, sample_count: int):
	# Moog-style Kraftwerk sequencer - classic analog step sequencer
	var bpm = 120.0
	var steps = 16
	var step_duration = (60.0 / bpm) / 4.0  # 16th notes
	
	# Classic Kraftwerk sequence pattern (simplified)
	var sequence = [
		261.63, 261.63, 392.00, 261.63,  # C C G C
		329.63, 261.63, 392.00, 261.63,  # E C G C
		293.66, 293.66, 392.00, 293.66,  # D D G D
		261.63, 329.63, 392.00, 261.63   # C E G C
	]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Calculate current step
		var step_index = int(t / step_duration) % steps
		var step_progress = fmod(t / step_duration, 1.0)
		
		var freq = sequence[step_index]
		
		# Moog-style sawtooth wave
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Classic Moog filter (simplified)
		var filter_cutoff = 800.0 + sin(2.0 * PI * 0.5 * t) * 300.0
		var filter_factor = clamp(filter_cutoff / 2000.0, 0.3, 1.0)
		wave *= filter_factor * 1.7  # Resonance
		
		# Step envelope
		var envelope = 1.0
		if step_progress > 0.8:  # Gate off for last 20% of step
			envelope = 0.0
		
		# ADSR envelope per step
		if step_progress < 0.01:
			envelope *= step_progress / 0.01  # Quick attack
		elif step_progress > 0.6:
			envelope *= exp(-(step_progress - 0.6) * 10.0)  # Decay
		
		data[i] = wave * envelope * 0.6

static func _generate_herbie_hancock_moog_fusion(data: PackedFloat32Array, sample_count: int):
	# Herbie Hancock jazz-fusion Moog - layered, chorded, funky
	var chord_freqs = [
		261.63, 329.63, 392.00, 493.88,  # Cmaj7
		293.66, 369.99, 440.00, 554.37,  # Dm7
		329.63, 415.30, 493.88, 622.25,  # Em7
		349.23, 440.00, 523.25, 659.26   # Fmaj7
	]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Jazz rhythm pattern
		var beat = fmod(t * 2.0, 4.0)  # 2 beats per second, 4-beat pattern
		var chord_index = int(beat) % 4
		
		# Get chord frequencies
		var root = chord_freqs[chord_index * 4]
		var third = chord_freqs[chord_index * 4 + 1]
		var fifth = chord_freqs[chord_index * 4 + 2]
		var seventh = chord_freqs[chord_index * 4 + 3]
		
		# Multiple oscillators for richness
		var wave1 = sin(2.0 * PI * root * t)  # Root
		var wave2 = sin(2.0 * PI * third * t) * 0.8  # Third
		var wave3 = sin(2.0 * PI * fifth * t) * 0.6  # Fifth
		var wave4 = sin(2.0 * PI * seventh * t) * 0.4  # Seventh
		
		var combined_wave = (wave1 + wave2 + wave3 + wave4) / 4.0
		
		# Moog filter sweep
		var filter_cutoff = 800.0 + sin(2.0 * PI * 0.3 * t) * 400.0
		var filter_factor = clamp(filter_cutoff / 1500.0, 0.4, 1.0)
		combined_wave *= filter_factor
		
		# Funk envelope - quick attack, sustained
		var envelope = 1.0
		var beat_pos = fmod(beat, 1.0)
		if beat_pos < 0.05:
			envelope = beat_pos / 0.05  # Quick attack
		elif beat_pos > 0.9:
			envelope = 1.0 - (beat_pos - 0.9) / 0.1  # Quick release
		
		data[i] = combined_wave * envelope * 0.7

static func _generate_aphex_twin_modular(data: PackedFloat32Array, sample_count: int):
	# Aphex Twin modular synthesis - complex, chaotic, mathematical
	var base_freq = 220.0  # A3
	var osc_count = 6
	var chaos_amount = 0.4
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Complex oscillator network with cross-modulation
		var total_wave = 0.0
		
		for osc in range(osc_count):
			var osc_freq = base_freq * (1.0 + float(osc) * 0.618)  # Golden ratio intervals
			
			# Chaotic modulation between oscillators
			var chaos_mod = sin(2.0 * PI * osc_freq * 0.1 * t) * chaos_amount
			var modulated_freq = osc_freq * (1.0 + chaos_mod)
			
			# Phase distortion
			var phase = 2.0 * PI * modulated_freq * t
			var distorted_phase = phase + sin(phase * 3.0) * 0.3
			
			var wave = sin(distorted_phase)
			
			# Ring modulation between adjacent oscillators
			if osc > 0:
				var ring_freq = base_freq * (1.0 + float(osc - 1) * 0.618)
				wave *= sin(2.0 * PI * ring_freq * t) * 0.5 + 0.5
			
			total_wave += wave / osc_count
		
		# Complex filter with resonance
		var filter_cutoff = 1000.0 + sin(2.0 * PI * 0.7 * t) * 800.0
		var filter_factor = clamp(filter_cutoff / 3000.0, 0.2, 1.0)
		var resonance = 0.8
		
		# Add resonant feedback
		var resonant_peak = sin(2.0 * PI * filter_cutoff * t) * resonance * 0.2
		total_wave = (total_wave + resonant_peak) * filter_factor
		
		# Granular processing
		var grain_size = 0.01  # 10ms grains
		var grain_index = int(t / grain_size)
		var grain_phase = fmod(t / grain_size, 1.0)
		
		# Randomize grain parameters
		var grain_pitch = 1.0 + (sin(grain_index * 1.618) * 0.2)
		if grain_phase < 0.1 or grain_phase > 0.9:
			total_wave *= grain_pitch * (sin(grain_phase * PI) * sin(grain_phase * PI))
		
		# Bit reduction for digital artifacts
		var bits = 12.0  # Reduce to 12-bit
		total_wave = floor(total_wave * pow(2, bits)) / pow(2, bits)
		
		# Complex envelope
		var envelope = 1.0
		var global_progress = t / (float(sample_count) / SAMPLE_RATE)
		
		if global_progress < 0.1:
			envelope = global_progress / 0.1
		elif global_progress > 0.8:
			envelope = 1.0 - (global_progress - 0.8) / 0.2
		
		# Add glitches randomly
		if randf() < 0.001:  # 0.1% chance per sample
			total_wave *= randf() * 2.0
		
		data[i] = total_wave * envelope * 0.6

static func _generate_warm_juno_pad(data: PackedFloat32Array, sample_count: int, freqs: Array):
	# Warm, drifting pad inspired by Juno-106
	if sample_count <= 0 or freqs.is_empty():
		return
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var sample = 0.0
		var chorus_lfo = sin(2.0 * PI * 0.5 * t) * 0.002
		
		for freq in freqs:
			# Sawtooth with slight PWM character logic
			# Using dual detuned saws for thickness
			var f1 = freq * (1.0 + chorus_lfo)
			var f2 = freq * (0.998 - chorus_lfo)
			
			var saw1 = 2.0 * (f1 * t - floor(f1 * t)) - 1.0
			var saw2 = 2.0 * (f2 * t - floor(f2 * t)) - 1.0
			
			sample += (saw1 + saw2) * 0.5
			
		sample /= max(1, freqs.size())
		
		# Low Pass Filter (Simulated via simple moving average / sine sum approximation for stability)
		# For procedural, simpler to just use soft sine approximation of filter cutoff
		# Here we multiply by a "dullness" factor based on harmonics
		
		# Amplitude Envelope (Slow attack/release)
		var envelope = 1.0
		if progress < 0.2: envelope = progress / 0.2
		elif progress > 0.8: envelope = (1.0 - progress) / 0.2
		
		# Filter Sweep
		var cutoff_mod = sin(2.0 * PI * 0.1 * t) * 0.3 + 0.7
		
		data[i] = sample * envelope * cutoff_mod * 0.4

static func _generate_tape_drift_keys(data: PackedFloat32Array, sample_count: int, freqs: Array):
	# Triangle/Sine keys with pitch wow/flutter
	if sample_count <= 0 or freqs.is_empty():
		return
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Tape Wow/Flutter LFOs
		var wow = sin(2.0 * PI * 0.5 * t) * 0.003 # Slow drift
		var flutter = sin(2.0 * PI * 6.0 * t) * 0.001 # Fast jitter
		var pitch_mod = 1.0 + wow + flutter
		
		var sample = 0.0
		for freq in freqs:
			var f = freq * pitch_mod
			# Triangle wave
			var tri = abs(4.0 * (f * t - floor(f * t + 0.75)) - 2.0) - 1.0
			sample += tri
			
		sample /= max(1, freqs.size())
		
		# Lo-Fi Bandpass Filter simulation (simulated by reducing high freq clarity)
		
		# Pluckish envelope but soft
		var envelope = exp(-progress * 4.0) 
		
		data[i] = sample * envelope * 0.5

static func _generate_acid_bass_sub(data: PackedFloat32Array, sample_count: int, freq: float):
	# Deep, resonant, slightly distorted bass
	if sample_count <= 0 or freq <= 0.0:
		return
	var octaved_freq = freq * 0.5 # Sub octave

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Sawtooth -> Lowpass -> Distortion
		var saw = 2.0 * (octaved_freq * t - floor(octaved_freq * t)) - 1.0
		
		# Filter envelope (Acid pluck)
		var filter_env = exp(-progress * 10.0)
		var cutoff_mult = 1.0 + filter_env * 3.0
		
		# Simple Lowpass approx
		# In real DSP we'd run a state filter, here we simulate the result
		# A dark saw is like a sine + some lower harmonics
		
		# Let's cheat and synthesize the filtered result directly for clean generation
		var filtered = sin(2.0 * PI * octaved_freq * t) # Fundamental
		filtered += sin(2.0 * PI * octaved_freq * 2.0 * t) * 0.5 * cutoff_mult # 2nd harmonic
		
		# Distortion/Saturation
		filtered = tanh(filtered * 1.5)
		
		# Amp envelope
		var amp_env = 1.0
		if progress > 0.9: amp_env = (1.0 - progress) / 0.1
		
		data[i] = filtered * amp_env * 0.6

static func _generate_lofi_breakbeat(data: PackedFloat32Array, sample_count: int):
	# Procedural breakbeat pattern
	if sample_count <= 0:
		return
	var beat_len = float(sample_count)
	var steps = 16
	var step_len = beat_len / steps

	# Prevent division by zero
	if step_len < 1.0:
		step_len = 1.0

	# Basic "Amen-ish" pattern
	var kicks = [0, 10]
	var snares = [4, 12, 15]
	var hats = [0, 2, 4, 6, 8, 10, 12, 14]

	# Add micro-timing offset for "human/MPC" feel
	@warning_ignore("unused_variable")
	var swing = 0.05

	for i in range(sample_count):
		@warning_ignore("unused_variable")
		var t = float(i) / SAMPLE_RATE
		var current_step = int(float(i) / step_len)
		var step_progress = fmod(float(i), step_len) / step_len
		
		var sample = 0.0
		
		# KICK (Sine sweep + click)
		if current_step in kicks and step_progress < 0.3:
			var kt = step_progress * 0.5 # Time relative to kick start
			var kfreq = 150.0 * exp(-kt * 20.0) # Sweep down
			sample += sin(2.0 * PI * kfreq * kt) * exp(-kt * 10.0) * 0.8
			
		# SNARE (Noise + Tone)
		if current_step in snares and step_progress < 0.2:
			var st = step_progress * 0.5
			var tone = sin(2.0 * PI * 200.0 * st) * exp(-st * 15.0)
			var noise = (randf() * 2.0 - 1.0) * exp(-st * 20.0)
			sample += (tone * 0.5 + noise * 0.6) * 0.7
			
		# HIHAT (High noise)
		if current_step in hats and step_progress < 0.05:
			var ht = step_progress * 0.1
			var noise = (randf() * 2.0 - 1.0) * exp(-ht * 50.0)
			sample += noise * 0.3
			
		data[i] = sample

static func _generate_tape_hiss(data: PackedFloat32Array, sample_count: int):
	for i in range(sample_count):
		# Pink noise approximation or just soft white noise
		var white = randf() * 2.0 - 1.0
		# Apply simple lowpass
		# In this static context, previous sample access is tricky without state, 
		# so we interpret noise as random volume fluctuations
		
		data[i] = white * 0.05 # Very quiet floor


static func _generate_flying_lotus_sampler(data: PackedFloat32Array, sample_count: int):
	# Flying Lotus sampler - hip-hop beats with jazz fusion and experimental elements
	var bpm = 85.0
	var beat_duration = 60.0 / bpm / 4.0  # 16th note duration
	
	# Jazz chord progression
	var chord_freqs = [
		261.63, 329.63, 392.00, 493.88,  # Cmaj7
		220.00, 277.18, 329.63, 415.30,  # Am7
		174.61, 220.00, 261.63, 329.63,  # Fmaj7
		196.00, 246.94, 293.66, 369.99   # G7
	]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# J Dilla-style swing
		var _beat_time = fmod(t / beat_duration, 1.0)
		var swing_offset = 0.0
		if int(t / beat_duration) % 2 == 1:  # Swing on off-beats
			swing_offset = 0.1
		
		# Current chord (changes every 2 seconds)
		var chord_index = int(t / 2.0) % 4
		var chord_root = chord_freqs[chord_index * 4]
		var chord_third = chord_freqs[chord_index * 4 + 1]
		var chord_fifth = chord_freqs[chord_index * 4 + 2]
		var chord_seventh = chord_freqs[chord_index * 4 + 3]
		
		# Sample chop simulation
		var chop_rate = 16.0  # 16th note chops
		var _chop_index = int((t + swing_offset) * chop_rate) % 32
		var chop_progress = fmod((t + swing_offset) * chop_rate, 1.0)
		
		# Multi-layered samples
		var bass_wave = sin(2.0 * PI * chord_root * 0.5 * t)  # Sub bass
		var chord_wave = (sin(2.0 * PI * chord_third * t) + 
						 sin(2.0 * PI * chord_fifth * t) + 
						 sin(2.0 * PI * chord_seventh * t)) / 3.0
		
		# Granular chopping
		var grain_size = 0.05  # 50ms grains
		var grain_phase = fmod(chop_progress, grain_size / beat_duration)
		var grain_envelope = sin(grain_phase * PI / (grain_size / beat_duration))
		
		var total_wave = bass_wave * 0.6 + chord_wave * 0.4
		total_wave *= grain_envelope
		
		# SP-404 style filter
		var filter_cutoff = 1200.0 + sin(2.0 * PI * 0.3 * t) * 600.0
		var filter_factor = clamp(filter_cutoff / 2400.0, 0.3, 1.0)
		total_wave *= filter_factor
		
		# Vintage saturation
		total_wave = tanh(total_wave * 1.5) * 0.7
		
		# Beat envelope
		var envelope = 1.0
		if chop_progress > 0.8:  # Gate off near end of chop
			envelope = 1.0 - (chop_progress - 0.8) / 0.2
		
		# Random stutters
		if randf() < 0.02 and chop_progress < 0.2:  # 2% chance of stutter
			total_wave *= randf() * 2.0
		
		data[i] = total_wave * envelope * 0.7

static func _create_audio_stream(data: PackedFloat32Array, loop_mode: int = AudioStreamWAV.LOOP_FORWARD) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = loop_mode
	stream.loop_begin = 0
	stream.loop_end = data.size()
	
	# Convert float data to 16-bit integers (use PackedByteArray directly)
	var byte_array = PackedByteArray()
	byte_array.resize(data.size() * 2)  # 2 bytes per 16-bit sample
	
	for i in range(data.size()):
		var sample = int(clamp(data[i], -1.0, 1.0) * 32767.0)  # Clamp and convert to 16-bit
		var byte_index = i * 2
		
		# Little-endian 16-bit encoding
		byte_array[byte_index] = sample & 0xFF          # Low byte
		byte_array[byte_index + 1] = (sample >> 8) & 0xFF  # High byte
	
	stream.data = byte_array
	return stream

static func _create_stereo_audio_stream(data_stereo: PackedFloat32Array, loop_mode: int = AudioStreamWAV.LOOP_FORWARD) -> AudioStreamWAV:
	# Expects interleaved stereo data (L, R, L, R...)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.loop_mode = loop_mode
	
	var frame_count = data_stereo.size() / 2
	stream.loop_begin = 0
	stream.loop_end = frame_count
	
	# Convert float data to 16-bit integers
	var byte_array = PackedByteArray()
	byte_array.resize(data_stereo.size() * 2)
	
	for i in range(data_stereo.size()):
		var sample = int(clamp(data_stereo[i], -1.0, 1.0) * 32767.0)
		var byte_index = i * 2
		byte_array[byte_index] = sample & 0xFF
		byte_array[byte_index + 1] = (sample >> 8) & 0xFF
	
	stream.data = byte_array
	return stream

# Save sounds to disk for reuse in the same directory
static func generate_and_save_all_sounds():
	print("AudioSynthesizer: Generating all sounds...")
	
	var sounds = {
		"pickup_mario": generate_sound(SoundType.PICKUP_MARIO, 0.5),
		"teleport_drone": generate_sound(SoundType.TELEPORT_DRONE, 3.0),
		"lift_bass_pulse": generate_sound(SoundType.LIFT_BASS_PULSE, 2.0),
		"ghost_drone": generate_sound(SoundType.GHOST_DRONE, 4.0),
		"melodic_drone": generate_sound(SoundType.MELODIC_DRONE, 5.0)
	}
	
	# Save in the same directory as this script (res://commons/audio/)
	var script_path = "res://commons/audio/"
	
	# Ensure the audio directory exists
	var dir = DirAccess.open("res://commons/")
	if not dir:
		print("AudioSynthesizer: ERROR - Cannot access res://commons/ directory")
		return
		
	if not dir.dir_exists("audio"):
		dir.make_dir("audio")
		print("AudioSynthesizer: Created audio directory at res://commons/audio/")
	
	for sound_name in sounds.keys():
		var file_path = script_path + sound_name + ".tres"
		var save_result = ResourceSaver.save(sounds[sound_name], file_path)
		if save_result == OK:
			print("  ✅ Saved: %s" % file_path)
		else:
			print("  ❌ Failed to save: %s (Error: %d)" % [file_path, save_result])
	
	print("AudioSynthesizer: All sounds generated and saved as .tres resources to res://commons/audio/!")

# Utility function to get all available sound types for UI/debugging
static func get_all_sound_types() -> Array[SoundType]:
	return [
		SoundType.BASIC_SINE_WAVE,
		SoundType.PICKUP_MARIO,
		SoundType.TELEPORT_DRONE, 
		SoundType.LIFT_BASS_PULSE,
		SoundType.GHOST_DRONE,
		SoundType.MELODIC_DRONE,
		SoundType.LASER_SHOT,
		SoundType.POWER_UP_JINGLE,
		SoundType.EXPLOSION,
		SoundType.RETRO_JUMP,
		SoundType.SHIELD_HIT,
		SoundType.AMBIENT_WIND,
		SoundType.DARK_808_KICK,
		SoundType.ACID_606_HIHAT,
		SoundType.DARK_808_SUB_BASS,
		SoundType.AMBIENT_AMIGA_DRONE,
		SoundType.MOOG_BASS_LEAD,
		SoundType.TB303_ACID_BASS,
		SoundType.DX7_ELECTRIC_PIANO,
		SoundType.C64_SID_LEAD,
		SoundType.AMIGA_MOD_SAMPLE,
		SoundType.PPG_WAVE_PAD,
		SoundType.TR909_KICK,
		SoundType.JUPITER_8_STRINGS,
		SoundType.KORG_M1_PIANO,
		SoundType.ARP_2600_LEAD,
		SoundType.SYNARE_3_DISCO_TOM,
		SoundType.SYNARE_3_COSMIC_FX,
		SoundType.MOOG_KRAFTWERK_SEQUENCER,
		SoundType.HERBIE_HANCOCK_MOOG_FUSION,
		SoundType.APHEX_TWIN_MODULAR,
		SoundType.FLYING_LOTUS_SAMPLER
	]

# Get human-readable name for a sound type
static func get_sound_type_name(type: SoundType) -> String:
	match type:
		SoundType.BASIC_SINE_WAVE:
			return "Basic Sine Wave"
		SoundType.PICKUP_MARIO:
			return "Mario Pickup"
		SoundType.TELEPORT_DRONE:
			return "Teleport Drone"
		SoundType.LIFT_BASS_PULSE:
			return "Bass Pulse"
		SoundType.GHOST_DRONE:
			return "Ghost Drone"
		SoundType.MELODIC_DRONE:
			return "Melodic Drone"
		SoundType.LASER_SHOT:
			return "Laser Shot"
		SoundType.POWER_UP_JINGLE:
			return "Power-Up Jingle"
		SoundType.EXPLOSION:
			return "Explosion"
		SoundType.RETRO_JUMP:
			return "Retro Jump"
		SoundType.SHIELD_HIT:
			return "Shield Hit"
		SoundType.AMBIENT_WIND:
			return "Ambient Wind"
		SoundType.DARK_808_KICK:
			return "Dark 808 Kick"
		SoundType.ACID_606_HIHAT:
			return "Acid 606 Hi-Hat"
		SoundType.DARK_808_SUB_BASS:
			return "Dark 808 Sub Bass"
		SoundType.AMBIENT_AMIGA_DRONE:
			return "Ambient Amiga Drone"
		SoundType.MOOG_BASS_LEAD:
			return "Moog Bass Lead"
		SoundType.TB303_ACID_BASS:
			return "TB-303 Acid Bass"
		SoundType.DX7_ELECTRIC_PIANO:
			return "DX7 Electric Piano"
		SoundType.C64_SID_LEAD:
			return "C64 SID Lead"
		SoundType.AMIGA_MOD_SAMPLE:
			return "Amiga MOD Sample"
		SoundType.PPG_WAVE_PAD:
			return "PPG Wave Pad"
		SoundType.TR909_KICK:
			return "TR-909 Kick"
		SoundType.JUPITER_8_STRINGS:
			return "Jupiter-8 Strings"
		SoundType.KORG_M1_PIANO:
			return "Korg M1 Piano"
		SoundType.ARP_2600_LEAD:
			return "ARP 2600 Lead"
		SoundType.SYNARE_3_DISCO_TOM:
			return "Synare 3 Disco Tom"
		SoundType.SYNARE_3_COSMIC_FX:
			return "Synare 3 Cosmic FX"
		SoundType.MOOG_KRAFTWERK_SEQUENCER:
			return "Moog Kraftwerk Sequencer"
		SoundType.HERBIE_HANCOCK_MOOG_FUSION:
			return "Herbie Hancock Moog Fusion"
		SoundType.APHEX_TWIN_MODULAR:
			return "Aphex Twin Modular"
		SoundType.FLYING_LOTUS_SAMPLER:
			return "Flying Lotus Sampler"
		SoundType.SCI_FI_LAB_HUM_CLEAN:
			return "Sci-Fi Lab Hum (Clean)"
		SoundType.SCI_FI_RESONANT_DRONE:
			return "Sci-Fi Resonant Drone"
		SoundType.SCI_FI_DATA_CHIRPS:
			return "Sci-Fi Data Chirps"
		SoundType.SCI_FI_VENTILATION:
			return "Sci-Fi Ventilation"
		SoundType.SCI_FI_ELECTROMAGNETIC:
			return "Sci-Fi Electromagnetic"
		SoundType.CS80_BRASS_LEAD:
			return "CS-80 Brass Lead"
		SoundType.CINEMATIC_432HZ_PAD:
			return "Cinematic 432Hz Pad"
		_:
			return "Unknown Sound"

static func _generate_sci_fi_lab_hum_clean(data: PackedFloat32Array, sample_count: int):
	# Sterile, multi-layered sine wave hum
	# Inspired by clean lab environments
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Pure sine waves at specific resonant frequencies
		var hum1 = sin(2.0 * PI * 60.0 * t) * 0.5      # Mains hum foundation
		var hum2 = sin(2.0 * PI * 120.0 * t) * 0.15    # First harmonic
		var hum3 = sin(2.0 * PI * 180.0 * t) * 0.05    # Second harmonic
		
		# High frequency "monitor whine" (very subtle)
		var whine = sin(2.0 * PI * 15000.0 * t) * 0.02
		
		# Slow amplitude modulation (breathing)
		var breath = sin(2.0 * PI * 0.1 * t) * 0.1 + 0.9
		
		data[i] = (hum1 + hum2 + hum3 + whine) * breath * 0.4

static func _generate_sci_fi_resonant_drone(data: PackedFloat32Array, sample_count: int):
	# Evolving metallic swells using FM synthesis
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# FM Synthesis
		var carrier_freq = 110.0
		var mod_freq = 220.0 * 1.5  # Non-integer ratio for metallic sound
		
		# Evolving modulation index
		var mod_index = 2.0 + sin(2.0 * PI * 0.2 * t) * 1.5
		
		var modulator = sin(2.0 * PI * mod_freq * t) * mod_index
		var carrier = sin(2.0 * PI * carrier_freq * t + modulator)
		
		# Add a second layer for depth
		var layer2_freq = 55.0
		var layer2 = sin(2.0 * PI * layer2_freq * t) * 0.3
		
		# Slow panning/movement effect (simulated with amplitude mod)
		var movement = sin(2.0 * PI * 0.15 * t) * 0.2 + 0.8
		
		data[i] = (carrier * 0.6 + layer2) * movement * 0.3

static func _generate_sci_fi_data_chirps(data: PackedFloat32Array, sample_count: int):
	# Randomized computer activity / data processing sounds
	# Uses rapid frequency modulation and bursts
	
	var burst_interval = 0.15
	var _current_burst = 0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Determine if we are in a burst
		var burst_time = fmod(t, burst_interval)
		
		var audio_signal = 0.0
		
		if burst_time < 0.05: # Active burst duration
			# High speed arpeggio/data sound
			var freq_base = 2000.0
			var freq_mod = sin(2.0 * PI * 100.0 * t) * 500.0
			
			# Square wave for digital character
			var phase = fmod((freq_base + freq_mod) * t, 1.0)
			audio_signal = 1.0 if phase < 0.5 else -1.0
			
			# Apply envelope to burst
			audio_signal *= exp(-burst_time * 20.0)
		
		# Add some background digital noise
		if randf() < 0.01:
			audio_signal += (randf() * 2.0 - 1.0) * 0.1
			
		data[i] = audio_signal * 0.25

static func _generate_sci_fi_ventilation(data: PackedFloat32Array, sample_count: int):
	# Filtered air texture
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# White noise generation
		var noise = randf() * 2.0 - 1.0
		
		# Low pass filter simulation (simple moving average approximation)
		# In a real DSP we'd use state variables, here we simulate the *result*
		# by summing low frequency sines which is cleaner for generation
		
		var air = 0.0
		# Summing non-harmonic sines to approximate filtered noise texture
		air += sin(2.0 * PI * 100.0 * t + noise) * 0.5
		air += sin(2.0 * PI * 230.0 * t + noise) * 0.3
		air += sin(2.0 * PI * 340.0 * t) * 0.2
		
		# Add "wind" modulation
		var gust = sin(2.0 * PI * 0.05 * t) * 0.2 + 0.8
		
		data[i] = air * gust * 0.15

static func _generate_sci_fi_electromagnetic(data: PackedFloat32Array, sample_count: int):
	# Subtle tech interference / electromagnetic radiation
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# 50Hz/60Hz hum characteristic
		var hum = sin(2.0 * PI * 50.0 * t)
		
		# Add sharp spikes (interference)
		var spike = 0.0
		if randf() < 0.001:
			spike = 1.0
			
		# High frequency buzz
		var buzz = sin(2.0 * PI * 3000.0 * t) * (sin(2.0 * PI * 10.0 * t) * 0.5 + 0.5)
		
		data[i] = (hum * 0.4 + spike * 0.3 + buzz * 0.1) * 0.2

static func _generate_cs80_brass_lead(data: PackedFloat32Array, sample_count: int):
	# Vangelis-style CS-80 brass lead
	# Characteristic: Sawtooth, filter sweep, aftertouch-like swelling
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dual oscillator sawtooths with slight detuning
		var freq1 = 110.0 # A2
		var freq2 = 110.0 * 1.002 # Slight detune
		
		var saw1 = 2.0 * (freq1 * t - floor(freq1 * t)) - 1.0
		var saw2 = 2.0 * (freq2 * t - floor(freq2 * t)) - 1.0
		
		var raw_wave = (saw1 + saw2) * 0.5
		
		# Filter simulation (Low Pass opening up)
		# Simulating the famous CS-80 poly-aftertouch swell
		var swell = sin(PI * progress) # Swells in middle
		var cutoff_base = 800.0
		var cutoff_mod = 2000.0 * swell
		var cutoff = cutoff_base + cutoff_mod
		
		# Simple low-pass approximation
		var filter_factor = clamp(cutoff / 4000.0, 0.1, 1.0)
		var filtered = raw_wave * filter_factor
		
		# Add some "analog" drift
		var drift = sin(2.0 * PI * 0.5 * t) * 0.05
		
		# Envelope
		var envelope = 1.0
		if progress < 0.1: # Attack
			envelope = progress / 0.1
		elif progress > 0.8: # Release
			envelope = (1.0 - progress) / 0.2
			
		data[i] = filtered * (1.0 + drift) * envelope * 0.5

static func _generate_cinematic_432hz_pad(data: PackedFloat32Array, sample_count: int):
	# Warm pad tuned to 432Hz base (approx -32 cents from 440Hz)
	# 432Hz is approx 0.9818 of 440Hz
	var tuning_factor = 432.0 / 440.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency (A3 tuned to 432Hz reference)
		var base_freq = 220.0 * tuning_factor
		
		# Multiple detuned sawtooths for thick "analog" sound
		var wave = 0.0
		var detune_amounts = [1.0, 1.005, 0.995, 2.0, 2.01] # Unison + Octave
		
		for detune in detune_amounts:
			var f = base_freq * detune
			# Sawtooth with slow PWM-like movement
			var phase = f * t
			var saw = 2.0 * (phase - floor(phase)) - 1.0
			wave += saw
			
		wave /= detune_amounts.size()
		
		# Low pass filter (warmth)
		var filter_cutoff = 1200.0
		var filter_factor = clamp(filter_cutoff / 4000.0, 0.2, 0.8)
		wave *= filter_factor
		
		# Slow, dreamy envelope
		var envelope = 1.0
		if progress < 0.3: # Long attack
			envelope = progress / 0.3
		elif progress > 0.7: # Long release
			envelope = (1.0 - progress) / 0.3
			
		# Stereo-like widening (simulated in mono by phase shifting LFOs)
		var shimmer = sin(2.0 * PI * 3.0 * t) * 0.1 + 0.9
		
		data[i] = wave * envelope * shimmer * 0.4
