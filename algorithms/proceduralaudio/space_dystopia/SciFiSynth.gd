extends Node
class_name SciFiSynth

# Space Dystopia Orchestrator
# Manages instances of SaxSynth, FMPianoSynth, and uses EpicSynthEngine lib.
# Sequences the 10 Procedural Tracks.

# Instruments
var sax: SaxSynth
var piano: FMPianoSynth
var pad_player_l: AudioStreamPlayer
var pad_player_r: AudioStreamPlayer
var noise_player: AudioStreamPlayer
var wind_gen: GranularWindGenerator
var wave_synth: WavetableSynth


# State
var current_track_idx: int = -1
var time: float = 0.0
var sequencer_active: bool = false
var step: int = 0
var seed_val: int = 12345

# --- Setup ---
func _ready():
	_setup_reverb()
	_setup_instruments()
	
func _setup_reverb():
	var bus_name = "SpaceReverb"
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		idx = AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
		
		# Space Reverb Effect
		var reverb = AudioEffectReverb.new()
		reverb.room_size = 0.85 # Huge Space
		reverb.damping = 0.3 # Warm/Dark
		reverb.spread = 0.8
		reverb.wet = 0.4
		reverb.dry = 0.8
		AudioServer.add_bus_effect(idx, reverb)

	
func _setup_instruments():
	# 1. Saxophone (Custom DSP)
	sax = SaxSynth.new()
	sax.name = "SaxSynth"
	sax.output_bus = "SpaceReverb" # Route to global reverb
	add_child(sax)
	
	# 2. Piano (Reuse existing FMPianoSynth)
	# We need to dynamically load it since it's an existing script
	var PianoScript = load("res://commons/audio/systems/air_points/FMPianoSynth.gd")
	if PianoScript:
		piano = PianoScript.new()
		piano.name = "FMPianoSynth"
		piano.gain = 0.5
		add_child(piano)
	else:
		push_error("SciFiSynth: Could not load FMPianoSynth.gd")
		
	# 3. Pads (EpicSynthEngine Playback)
	pad_player_l = AudioStreamPlayer.new()
	pad_player_l.bus = "SpaceReverb"
	add_child(pad_player_l)
	
	pad_player_r = AudioStreamPlayer.new()
	pad_player_r.bus = "SpaceReverb"
	add_child(pad_player_r)
	
	# 4. Noise
	noise_player = AudioStreamPlayer.new()
	noise_player.volume_db = -20.0
	add_child(noise_player)
	
	# 5. Wind
	wind_gen = GranularWindGenerator.new()
	wind_gen.name = "GranularWind"
	wind_gen.output_bus = "SpaceReverb"
	add_child(wind_gen)
	
	# 6. Wavetable
	wave_synth = WavetableSynth.new()
	wave_synth.name = "WavetableSynth"
	wave_synth.output_bus = "SpaceReverb"
	add_child(wave_synth)

# --- Track Control ---

func play_track(bgm_index: int):
	stop_all()
	current_track_idx = bgm_index
	time = 0.0
	step = 0
	sequencer_active = true
	
	print("SciFiSynth: Playing Track %d" % bgm_index)
	
	match bgm_index:
		1: _setup_track_1_drift()
		2: _setup_track_2_interdimensional()
		3: _setup_track_3_foundry()
		4: _setup_track_4_noir()
		5: _setup_track_5_stellar()
		6: _setup_track_6_neon()
		7: _setup_track_7_skyline()
		8: _setup_track_8_market()
		9: _setup_track_9_celestial()
		10: _setup_track_10_singularity()
		# Add others...

func stop_all():
	sequencer_active = false
	if sax: sax.stop_note()
	if pad_player_l: pad_player_l.stop()
	if pad_player_r: pad_player_r.stop()
	if noise_player: noise_player.stop()
	if wave_synth: wave_synth.stop_note()

func _process(delta):
	if not sequencer_active: return
	time += delta
	
	match current_track_idx:
		1: _seq_track_1_drift(delta)
		2: _seq_track_2_interdimensional(delta)
		3: _seq_track_3_foundry(delta)
		4: _seq_track_4_noir(delta)
		5: _seq_track_5_stellar(delta)
		6: _seq_track_6_neon(delta)
		7: _seq_track_7_skyline(delta)
		8: _seq_track_8_market(delta)
		9: _seq_track_9_celestial(delta)
		10: _seq_track_10_singularity(delta)

# --- TRACK 1: Post-Singularity Drift ---
# Concept: Deep SubBass Drone + Random Sparse Piano + Wind
func _setup_track_1_drift():
	# 1. Start Drone (Infinite SubBass)
	var drone_params = {"freq": 55.0, "duration": 600.0} # 10 mins
	var stream = EpicSynthEngine.generate_patch("sub_bass", drone_params)
	pad_player_l.stream = stream
	pad_player_l.play()
	
	# 2. Config Wind
	wind_gen.grain_density = 60.0 # Heavy storm
	wind_gen.grain_pitch_base = 1.5 # Higher pitch whistling

func _seq_track_1_drift(_delta):
	# Sparse Piano Logic (Markov Chain Lite)
	# Play a note every 5-10 seconds
	if randf() < 0.005: # approx once per 3-4 sec at 60fps
		var scale = [48, 51, 55, 58, 60, 63] # C Minor / Phrygian-ish
		var note_idx = randi() % scale.size()
		var midi = scale[note_idx]
		# Transpose randomly to upper octave
		if randf() > 0.7: midi += 12
		
		var freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
		if piano: piano.play_note(freq, 0.4 + randf() * 0.4, 4.0)

# --- TRACK 2: Interdimensional ---
# Concept: Evolving Wavetable Pad + Cold Digital Arp
func _setup_track_2_interdimensional():
	# Start evolving drone
	wave_synth.play_note(55.0, 0.4, 0.0) # A1 drone

func _seq_track_2_interdimensional(_delta):
	# Automation: Slowly sweep wavetable position
	# 0 = Sine, 1 = Tri, 2 = Saw, 3 = Square, 4 = Pulse
	var sweep = (sin(time * 0.1) + 1.0) * 2.0 # 0 to 4 slow sweep
	wave_synth.set_shape_pos(sweep)
	
	# Sparse high register blips (Digital Rain)
	if randf() < 0.008:
		# Use FMPiano for digital blips
		if piano: 
			var midi = 84 + (randi() % 12) * 2 # Whole tone scale
			var freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
			piano.play_note(freq, 0.2, 0.2)

			piano.play_note(freq, 0.2, 0.2)
	
# --- TRACK 3: The Automated Foundry ---
# Concept: Industrial Clanking Loops + Dissonant Drone
func _setup_track_3_foundry():
	# 1. Low Dissonant Drone
	var drone_params = {"freq": 40.0, "duration": 600.0}
	var stream = EpicSynthEngine.generate_patch("sub_bass", drone_params)
	pad_player_l.stream = stream
	pad_player_l.volume_db = -3.0
	pad_player_l.play()
	
	# Pre-generate simple metal hit for re-use? 
	# Actually for SciFiSynth we sequence them live via a one-shot player?
	# SciFiSynth architecture uses AudioStreamPlayers for Pads (Loops) but piano/sax for notes.
	# We'll use the 'noise_player' to trigger hits or re-purpose a player.
	pass

func _seq_track_3_foundry(_delta):
	# Industrial Rhythm (Slow, heavy)
	# BPM ~ 60
	var t_int = int(time * 1000)
	
	# Heavy Metal Clank on beat 1
	if t_int % 4000 < 50 and step != 1:
		var hit_params = {"freq": 150.0, "ratio": 1.414, "mod": 8.0, "duration": 2.0}
		var hit = EpicSynthEngine.generate_patch("metallic_hit", hit_params)
		# We need a transient player. Let's use pad_player_r for hits in this track since it has no pad.
		pad_player_r.stream = hit
		pad_player_r.volume_db = -3.0
		pad_player_r.play()
		step = 1
		
	# Secondary high metallic ping
	if t_int % 4000 > 2000 and t_int % 4000 < 2050 and step != 2:
		var hit_params = {"freq": 800.0, "ratio": 2.7, "mod": 3.0, "duration": 0.5}
		var hit = EpicSynthEngine.generate_patch("metallic_hit", hit_params)
		# We can trigger this ON TOP? No, AudioStreamPlayer is monophonic.
		# This is a limitation of the current SciFiSynth simple setup. 
		# We'll skip secondary overlap or use 'noise_player' if it wasn't noise.
		# Actually, let's use the 'piano' synth to act as high metal pings!
		if piano: piano.play_note(880.0, 0.3, 0.1)
		step = 2

	if t_int % 4000 > 3000: step = 0

# --- TRACK 4: Augmented Noir ---
# Concept: Saxophone Solo (SaxSynth) + Warm Pad (EpicSynth CS80)
func _setup_track_4_noir():
	# 1. Warm Pad Background
	var pad_params = {"freq": 110.0, "duration": 600.0}
	var stream = EpicSynthEngine.generate_patch("cs80_pad_1", pad_params)
	pad_player_l.stream = stream
	pad_player_l.volume_db = -6.0
	pad_player_l.play()

func _seq_track_4_noir(_delta):
	# Saxophone "Human" Player Logic
	# Phrases: Play for 2-4 sec, Rest for 3-6 sec
	
	# Very simple state machine for the "Player"
	var t_int = int(time * 1000)
	
	# Play a phrase every 8 seconds approx
	if step == 0 and (t_int % 8000 < 50): 
		# Start Phrase
		# Melody: C Minor Bluesy (C, Eb, F, G, Bb)
		var note = 261.63 # Middle C (C4)
		if randf() > 0.5: note = 311.13 # Eb
		
		sax.play_note(note, 0.9)
		step = 1
		
	elif step == 1 and (t_int % 8000 > 1500):
		# Move to second note of phrase
		var note = 349.23 # F
		if randf() > 0.5: note = 392.00 # G
		sax.play_note(note, 0.7)
		step = 2
		
	elif step == 2 and (t_int % 8000 > 3500):
		# End phrase
		sax.stop_note()
		step = 0

# --- TRACK 5: Stellar Shadowing ---
# Concept: Analog Pad + Sacred Choir + Cold Wavetable
func _setup_track_5_stellar():
	# 1. Deep Analog Pad (Root)
	var pad_params = {"freq": 146.83, "duration": 600.0} # D3
	var stream = EpicSynthEngine.generate_patch("cs80_pad_1", pad_params)
	pad_player_l.stream = stream
	pad_player_l.volume_db = -9.0
	pad_player_l.play()
	
	# 2. Sacred Choir (Fifth)
	var choir_params = {"freq": 220.0, "duration": 600.0, "vowel": "ooh"} # A3
	var choir_stream = EpicSynthEngine.generate_patch("choir_ensemble", choir_params)
	pad_player_r.stream = choir_stream
	pad_player_r.volume_db = -6.0
	pad_player_r.play()
	
	# 3. Cold Wavetable (Octave up)
	if not wave_synth:
		wave_synth = WavetableSynth.new()
		wave_synth.name = "WavetableSynth"
		wave_synth.output_bus = "SpaceReverb"
		add_child(wave_synth)
	
	wave_synth.play_note(293.66, 0.3, 3.0) # D4, Square wave start

func _seq_track_5_stellar(_delta):
	# Very slow morph
	var morph = (sin(time * 0.05) + 1.0) * 2.0 # 0 to 4
	wave_synth.set_shape_pos(morph)

	wave_synth.set_shape_pos(morph)

# --- TRACK 6: Neon Rain ---
# Concept: Jazz Noir, Sax Solo, Rain Ambience
func _setup_track_6_neon():
	# 1. Rain/Traffic Ambience (Using Wind Gen as Rain)
	wind_gen.grain_density = 80.0 # Dense drops
	wind_gen.grain_pitch_base = 4.0 # High pitch hiss
	
	# 2. Minimal Bass foundation
	var bass_params = {"freq": 32.7, "duration": 600.0} # C1
	var stream = EpicSynthEngine.generate_patch("sub_bass", bass_params)
	pad_player_l.stream = stream
	pad_player_l.volume_db = -6.0
	pad_player_l.play()

func _seq_track_6_neon(_delta):
	# Generative Jazz Quintet Logic
	var t_int = int(time * 1000)
	
	# 1. Saxophone: "Lonely on the corner"
	# Play phrase every 10 seconds
	if t_int % 10000 < 50 and step != 1:
		# Smoky Minor 9th Lick
		# C Minor: C, D, Eb, F, G, Bb, B
		var note = 261.63 # C4
		if randf() > 0.5: note = 311.13 # Eb4
		sax.play_note(note, 0.6) # Gentle
		step = 1
		
	elif step == 1 and t_int % 10000 > 1500:
		var note = 233.08 # Bb3
		sax.play_note(note, 0.5)
		step = 2
		
	elif step == 2 and t_int % 10000 > 3000:
		sax.stop_note()
		step = 0
		
	# 2. Piano: Random jazz voicings
	if randf() < 0.01:
		if piano:
			var scale = [60, 63, 65, 67, 70, 74] # Cm9 voicing notes
			var midi = scale[randi() % scale.size()]
			var freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
			piano.play_note(freq, 0.3, 2.0)

# --- TRACK 7: The Elegiac Skyline ---
# Concept: Pedal Steel Guitar Swells + Post-Rock Piano
func _setup_track_7_skyline():
	# 1. Pedal Steel Chord Drone (Root)
	var ps_params = {"freq": 220.0, "duration": 600.0} # A3
	var stream = EpicSynthEngine.generate_patch("pedal_steel", ps_params)
	pad_player_l.stream = stream
	pad_player_l.volume_db = -4.0
	pad_player_l.play()
	
	# 2. Pedal Steel Harmony (Fifth)
	var ps_params2 = {"freq": 329.63, "duration": 600.0} # E4
	var stream2 = EpicSynthEngine.generate_patch("pedal_steel", ps_params2)
	pad_player_r.stream = stream2
	pad_player_r.volume_db = -6.0
	pad_player_r.play()

func _seq_track_7_skyline(_delta):
	# Mournful Piano (High reverb)
	if randf() < 0.005:
		if piano:
			var scale = [69, 72, 76, 79, 81] # A Minor
			var midi = scale[randi() % scale.size()]
			var freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
			piano.play_note(freq, 0.3, 3.0)

			piano.play_note(freq, 0.3, 3.0)

# --- TRACK 8: Martian Market Pulse ---
# Concept: Analog Step Sequence + Industrial Clank
func _setup_track_8_market():
	# 1. Background Hiss/Wind (Market atmosphere)
	wind_gen.grain_density = 40.0
	wind_gen.grain_pitch_base = 0.5 # Low rumble
	
	# 2. Simple Beat (Using Metallic Hits on off-beats for industrial feel)
	# Done in sequencer

func _seq_track_8_market(_delta):
	# 120 BPM = 500ms per beat. 16th note = 125ms
	var t_int = int(time * 1000)
	var beat_16 = (t_int / 125) % 16
	
	# Step Sequencer (Arp)
	# Pattern: Root, 5th, Octave, 5th
	if beat_16 != step: # New 16th note
		step = beat_16
		
		# Bass Line Pluck
		if beat_16 % 2 == 0: # 8th notes
			var note = 55.0 # A1
			if beat_16 == 4 or beat_16 == 12: note = 82.41 # E2 (5th)
			if beat_16 == 8: note = 110.0 # A2 (Octave)
			
			var params = {"freq": note, "duration": 0.3}
			var pluck = EpicSynthEngine.generate_patch("analog_pluck", params)
			pad_player_l.stream = pluck
			pad_player_l.volume_db = -4.0
			pad_player_l.play()
			
		# Metallic Percussion (Kick-ish / Snare-ish)
		if beat_16 == 0: # Kick
			var hit = EpicSynthEngine.generate_patch("metallic_hit", {"freq": 60.0, "ratio": 1.1, "mod": 5.0, "duration": 0.5})
			pad_player_r.stream = hit
			pad_player_r.volume_db = -2.0
			pad_player_r.play()
			
		if beat_16 == 8: # Snare clank
			var hit = EpicSynthEngine.generate_patch("metallic_hit", {"freq": 250.0, "ratio": 2.4, "mod": 8.0, "duration": 0.4})
			# We only have 2 loop players + piano + sax + noise.
			# Let's borrow 'noise_player' for the snare clank if not busy, or overwrite Kick (since they don't overlap much)
			# Actually Pad_R is occupied by Kick. We can try to use Piano?
			if piano: piano.play_note(440.0, 0.1, 0.1) # Digital click layer

# --- TRACK 9: Celestial Symphony ---
# Concept: Solina String Machine Chords + High Lead
func _setup_track_9_celestial():
	# 1. String Machine Chords (Root + 5th)
	var chord_root = 196.0 # G3
	var str_params_1 = {"freq": chord_root, "duration": 600.0}
	var str_stream_1 = EpicSynthEngine.generate_patch("string_machine", str_params_1)
	pad_player_l.stream = str_stream_1
	pad_player_l.volume_db = -5.0
	pad_player_l.play()
	
	var str_params_2 = {"freq": chord_root * 1.5, "duration": 600.0} # D4
	var str_stream_2 = EpicSynthEngine.generate_patch("string_machine", str_params_2)
	pad_player_r.stream = str_stream_2
	pad_player_r.volume_db = -5.0
	pad_player_r.play()

func _seq_track_9_celestial(_delta):
	# Lead melody using FMPiano (Bell-like)
	if randf() < 0.01:
		if piano:
			var scale = [79, 81, 83, 84, 86, 88, 91] # G Major / Lydian
			var midi = scale[randi() % scale.size()]
			var freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
			piano.play_note(freq, 0.5, 1.0)

# --- TRACK 10: The Singularity Event ---
# Concept: Final Merge - All Drones + Glitch
func _setup_track_10_singularity():
	# 1. Sub Bass Foundation
	var bass_params = {"freq": 40.0, "duration": 600.0}
	var stream1 = EpicSynthEngine.generate_patch("sub_bass", bass_params)
	pad_player_l.stream = stream1
	pad_player_l.volume_db = -6.0
	pad_player_l.play()
	
	# 2. String Machine (High Tension)
	var str_params = {"freq": 440.0, "duration": 600.0}
	var stream2 = EpicSynthEngine.generate_patch("string_machine", str_params)
	pad_player_r.stream = stream2
	pad_player_r.volume_db = -9.0
	pad_player_r.play()
	
	# 3. Wavetable Glitch Drone
	if not wave_synth:
		wave_synth = WavetableSynth.new()
		wave_synth.name = "WavetableSynth"
		wave_synth.output_bus = "SpaceReverb"
		add_child(wave_synth)
	
	wave_synth.play_note(110.0, 0.2, 0.0)

func _seq_track_10_singularity(_delta):
	# Chaos Engine
	# Randomly morph wavetable fast
	var warp = (sin(time * 10.0) + 1.0) * 2.0
	wave_synth.set_shape_pos(warp)
	
	# Random Piano Stabs (Bitcrushed style high notes)
	if randf() < 0.05:
		if piano:
			var freq = 2000.0 + randf() * 2000.0
			piano.play_note(freq, 0.2, 0.1)
