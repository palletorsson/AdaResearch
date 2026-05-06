extends Node

# PopInteractiveMusic.gd
# Demonstrates AudioStreamInteractive (runtime construction)
# Transitions between Intro, Verse, Chorus

var playback: AudioStreamInteractive
var player: AudioStreamPlayer

const BPM = 100.0
const BAR_DURATION = 240.0 / BPM # 4 beats * 60/BPM e.g. 2.4s
const SAMPLE_RATE = 44100

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)
	
	randomize()
	_generate_new_song()

func _generate_new_song():
	# 1. Pick Key and Progression
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "4"
	var scale = PopMusicTheory.get_major_scale_notes(root_note)
	var progression = PopMusicTheory.PROG_POP_4 # Default for now
	
	print("Generating Song in ", root_note, " Major. Progression: ", progression)
	
	# Create Interactive Stream
	playback = AudioStreamInteractive.new()
	playback.clip_count = 3
	
	# 2. Generate Sections
	# Intro: Pad only (Chord I held or simple progression)
	var intro_stream = _generate_section_stream(progression, scale, ["pad"])
	playback.set_clip_stream(0, intro_stream)
	playback.set_clip_name(0, "Intro")
	
	# Verse: Bass + Keys + Minimal Drums
	var verse_stream = _generate_section_stream(progression, scale, ["bass", "keys", "drums"])
	playback.set_clip_stream(1, verse_stream)
	playback.set_clip_name(1, "Verse")
	
	# Chorus: Full Mix with Drums
	var chorus_stream = _generate_section_stream(progression, scale, ["bass", "keys", "pad", "lead", "drums"])
	playback.set_clip_stream(2, chorus_stream)
	playback.set_clip_name(2, "Chorus")
	
	# 3. Transitions
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 2.0)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 1.0)
	playback.add_transition(2, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 2.0)
	
	player.stream = playback
	player.play()

func _generate_section_stream(progression: Array, scale: Array, instruments: Array) -> AudioStreamWAV:
	# Duration: One full cycle of progression (4 chords * 1 bar)
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
		# Bass is 2 octaves down
		var bass_freq = root_freq * 0.25
		
		# Generate Instrument Layers
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		if "pad" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			AudioSynthesizer._generate_juno_chorus_pad(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.6)
			
		if "keys" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			AudioSynthesizer._generate_dx7_ballad_keys(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.7)
			
		if "bass" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			AudioSynthesizer._generate_funk_bass(data, samples_per_chord, bass_freq)
			_mix_into(chord_mix, data, 0.8)

		if "lead" in instruments:
			# Lead melody? random notes from scale?
			# Just play Arp logic or high root for now
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			AudioSynthesizer._generate_obxa_brass(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.5)

		# Add dynamic drums (Kick on 1, 3. Hat on offbeats)
		if "drums" in instruments:
			var beat_samples = int(samples_per_chord / 4.0) # 1 beat
			# Kick on 1 and 3 (0 and 2)
			var kick_data = PackedFloat32Array(); kick_data.resize(int(SAMPLE_RATE * 0.2)) # Short kick
			AudioSynthesizer._generate_tr909_kick(kick_data, kick_data.size())
			
			var hat_data = PackedFloat32Array(); hat_data.resize(int(SAMPLE_RATE * 0.1)) # Short hat
			AudioSynthesizer._generate_acid_606_hihat(hat_data, hat_data.size())
			
			# Sequencer Mix
			var drum_mix = PackedFloat32Array(); drum_mix.resize(samples_per_chord)
			drum_mix.fill(0.0)
			
			# Kick: Beat 0 and 2
			_mix_at_offset(drum_mix, kick_data, 0, 0.8)
			_mix_at_offset(drum_mix, kick_data, beat_samples * 2, 0.8)
			# Extra syncopated kick?
			# _mix_at_offset(drum_mix, kick_data, beat_samples * 2 + beat_samples/2, 0.6)
			
			# Hats: Offbeats (Beat 0.5, 1.5, 2.5, 3.5)
			var hat_offset = int(beat_samples * 0.5)
			for b in range(4):
				_mix_at_offset(drum_mix, hat_data, b * beat_samples + hat_offset, 0.4)
				
			_mix_into(chord_mix, drum_mix, 1.0)

		# Add chord_mix to final_mix
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				final_mix[start_idx + j] = chord_mix[j]
				
	return AudioSynthesizer._create_audio_stream(final_mix)

func _mix_into(target: PackedFloat32Array, source: PackedFloat32Array, level: float):
	for i in range(min(target.size(), source.size())):
		target[i] += source[i] * level

func _mix_at_offset(target: PackedFloat32Array, source: PackedFloat32Array, offset: int, level: float):
	var end = min(target.size(), offset + source.size())
	for i in range(offset, end):
		target[i] += source[i - offset] * level

	
func play_intro():
	# Index 0 = Intro
	player.get_stream_playback().switch_to_clip(0)

func play_verse():
	# Index 1 = Verse
	player.get_stream_playback().switch_to_clip(1)

func play_chorus():
	# Index 2 = Chorus
	player.get_stream_playback().switch_to_clip(2)
