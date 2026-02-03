# SoundbankGenerator.gd
# Generates songs using isolated soundbanks with GENRE-SPECIFIC patterns
#
# Each genre has its own:
# - Drum patterns (4-on-floor vs 2-step vs motorik vs breakbeat)
# - Bass patterns (rhythmic, not just sustained)
# - Velocity curves (dynamics)
# - Swing amount
# - Arrangement structure

class_name SoundbankGenerator
extends RefCounted

const SAMPLE_RATE = 44100.0


# =============================================================================
# GENRE-SPECIFIC DRUM PATTERNS
# Each pattern is 16 steps (one bar of 16th notes)
# Values: 0 = off, 1 = normal, 2 = accent, 0.5 = ghost note
# =============================================================================

const PATTERNS = {
	# Detroit Techno: 4-on-floor machine funk
	"detroit_techno": {
		"kick":  [2,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # Accent on 1
		"snare": [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,0],  # Strong 2 and 4
		"clap":  [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
		"hihat": [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],
		"stab":  [0,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0],
	},
	
	# Synthwave: 80s pop/rock feel - BIG dynamics
	"synthwave": {
		"kick":  [2,0,0,0, 1,0,0,0, 2,0,0,0, 1,0,0,0],
		"snare": [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,0],  # BIG gated hits
		"hihat": [1,0,0.5,0, 1,0,0.5,0, 1,0,0.5,0, 1,0,0.5,0],  # Ghost 16ths
		"arp":   [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],
	},
	
	# Burial: 2-STEP - kick avoids beat 1! Ghost notes everywhere
	"burial": {
		"kick":  [0,0,1,0, 0,0,0,0, 0,0,1,0, 0,0.5,0,0],  # Ghost kick
		"snare": [0,0,0,0, 1,0,0,0.5, 0,0,0,0, 1,0,0,0],  # Ghost snares
		"hihat": [0.5,1,0,0.5, 0,1,0.5,0, 0.5,0,1,0.5, 0,1,0,0.5],  # Swung ghosts
		"sub":   [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
	},
	
	# Boards of Canada: Hip-hop influenced, lazy, soft
	"boards_of_canada": {
		"kick":    [1,0,0,0, 0,0,0.5,0, 0,0,0,0, 1,0,0,0],  # Soft ghost
		"snare":   [0,0,0,0, 1,0,0,0, 0,0,0,0, 0.5,0,0,1],  # Swung
		"hihat":   [0.5,0,0,0.5, 0,0,0.5,0, 0.5,0,0,0.5, 0,0,0.5,0],  # Very soft
		"sequence":[1,0,0,0, 0,0,1,0, 0,1,0,0, 0,0,0,1],
	},
	
	# Rave: Aggressive, LOUD, frantic
	"rave": {
		"kick":  [2,0,2,0, 2,0,2,0, 2,0,2,0, 2,0,2,0],  # All accents!
		"snare": [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,2],
		"hihat": [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1],  # 16ths full blast
		"stab":  [0,0,0,0, 0,0,0,2, 0,0,0,0, 0,0,0,2],  # Hard stabs
	},
	
	# Kraftwerk: Motorik - steady, consistent, robotic (no dynamics!)
	"kraftwerk": {
		"kick":     [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # All same level
		"snare":    [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
		"hihat":    [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],  # Motorik 8ths
		"sequence": [1,0,0,1, 0,0,1,0, 1,0,0,1, 0,0,1,0],
	},
	
	# Madonna 80s: Upbeat pop, tight, driving
	"madonna_80s": {
		"kick":  [2,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # Strong downbeat
		"snare": [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,0],  # Big 2 and 4
		"clap":  [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,1,0],  # Extra clap before 4
		"hihat": [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],  # Driving 8ths
		"arp":   [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],  # Running 8ths
		"stab":  [0,0,0,0, 0,0,0,1, 0,0,0,0, 0,0,0,1],  # Offbeat stabs
	},
	
	# Gypsy Woman House: Bouncy, groovy, piano-driven
	"gypsy_woman_house": {
		"kick":  [2,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # 4-on-floor
		"snare": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
		"clap":  [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,0],  # Strong claps
		"hihat": [1,0,1,1, 1,0,1,1, 1,0,1,1, 1,0,1,1],  # Bouncy 16ths (signature!)
		"piano": [0,0,1,0, 0,0,0,1, 0,0,1,0, 0,0,0,1],  # Offbeat stabs (THE sound!)
		"organ": [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # Sustained organ
	},
}

# =============================================================================
# BASS PATTERNS - Rhythmic, not just sustained
# =============================================================================

const BASS_PATTERNS = {
	"detroit_techno": {
		"pattern": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Locked to kick
		"style": "sustained",  # Long notes
	},
	"synthwave": {
		"pattern": [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # 4 hits per bar
		"style": "sustained",
	},
	"burial": {
		"pattern": [1,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0],  # Offbeat sub
		"style": "sustained",
	},
	"boards_of_canada": {
		"pattern": [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # Very sparse
		"style": "sustained",
	},
	"rave": {
		"pattern": [1,1,1,1, 0,0,0,0, 1,1,1,1, 0,0,0,0],  # Hoover drone/slide
		"style": "continuous",  # Constant drone
	},
	"kraftwerk": {
		"pattern": [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # Locked to kick
		"style": "short",  # Staccato
	},
	"madonna_80s": {
		"pattern": [1,0,0,0, 0,0,1,0, 1,0,0,0, 0,0,1,0],  # Syncopated pop
		"style": "sustained",
	},
	"gypsy_woman_house": {
		"pattern": [0,0,1,0, 0,0,0,1, 0,0,1,0, 0,0,0,1],  # OFFBEAT bouncy (signature!)
		"style": "short",  # Bouncy short notes
	},
}

# =============================================================================
# SWING AMOUNTS (percentage, applied to off-beats)
# =============================================================================

const SWING = {
	"detroit_techno": 0.0,       # Machine straight
	"synthwave": 0.0,            # Straight 80s
	"burial": 12.0,              # UK garage swing
	"boards_of_canada": 18.0,    # Lazy hip-hop swing
	"rave": 0.0,                 # Straight aggression
	"kraftwerk": 0.0,            # Robot precision
	"madonna_80s": 0.0,          # Tight pop
	"gypsy_woman_house": 8.0,    # Groovy house swing
}

# =============================================================================
# VELOCITY CURVES (base velocity multiplier)
# =============================================================================

const VELOCITY = {
	"detroit_techno": {
		"base": 0.85,      # Consistent machine level
		"accent": 1.0,
		"ghost": 0.5,
		"variation": 0.05, # Minimal variation
	},
	"synthwave": {
		"base": 0.9,
		"accent": 1.0,     # BIG accents
		"ghost": 0.4,
		"variation": 0.1,
	},
	"burial": {
		"base": 0.6,       # Softer overall
		"accent": 0.8,
		"ghost": 0.25,     # Very quiet ghosts
		"variation": 0.15, # More human variation
	},
	"boards_of_canada": {
		"base": 0.55,      # Soft, lo-fi
		"accent": 0.75,
		"ghost": 0.2,
		"variation": 0.2,  # Most variation
	},
	"rave": {
		"base": 1.0,       # LOUD
		"accent": 1.0,     # Everything maxed
		"ghost": 0.7,
		"variation": 0.0,  # Crushed, no dynamics
	},
	"kraftwerk": {
		"base": 0.7,       # Moderate, precise
		"accent": 0.7,     # NO accents - robotic consistency
		"ghost": 0.7,
		"variation": 0.0,  # Zero variation - machine
	},
	"madonna_80s": {
		"base": 0.9,       # Bright, punchy
		"accent": 1.0,     # Strong accents
		"ghost": 0.5,
		"variation": 0.08, # Tight but human
	},
	"gypsy_woman_house": {
		"base": 0.85,      # Warm, groovy
		"accent": 1.0,     # Punchy accents
		"ghost": 0.45,
		"variation": 0.1,  # Groovy variation
	},
}

# =============================================================================
# SECTION STRUCTURES
# =============================================================================

const STRUCTURES = {
	"detroit_techno": {
		"sections": ["intro", "build", "main", "breakdown", "main", "outro"],
		"bars": [4, 8, 16, 8, 16, 4],
	},
	"synthwave": {
		"sections": ["intro", "verse", "chorus", "verse", "chorus", "outro"],
		"bars": [8, 8, 8, 8, 8, 4],
	},
	"burial": {
		"sections": ["intro", "build", "main", "breakdown", "main", "outro"],
		"bars": [8, 8, 16, 8, 8, 8],
	},
	"boards_of_canada": {
		"sections": ["intro", "main", "interlude", "main", "outro"],
		"bars": [8, 16, 8, 16, 8],
	},
	"rave": {
		"sections": ["intro", "build", "drop", "breakdown", "drop", "outro"],
		"bars": [4, 8, 16, 4, 16, 4],
	},
	"kraftwerk": {
		"sections": ["intro", "verse", "verse", "bridge", "verse", "outro"],
		"bars": [8, 16, 16, 8, 16, 8],
	},
	"madonna_80s": {
		"sections": ["intro", "verse", "prechorus", "chorus", "verse", "chorus", "outro"],
		"bars": [4, 8, 4, 8, 8, 8, 4],
	},
	"gypsy_woman_house": {
		"sections": ["intro", "build", "main", "breakdown", "drop", "main", "outro"],
		"bars": [4, 8, 16, 8, 16, 8, 4],
	},
}


static func generate_song(genre_id: String, parameters: Dictionary = {}) -> AudioStreamInteractive:
	var bank = SoundbankLoader.load_genre(genre_id)
	if bank.get_available_sounds().is_empty():
		push_error("SoundbankGenerator: No sounds loaded for " + genre_id)
		return null
	
	var brief = bank.get_brief()
	var bpm = parameters.get("bpm", bank.get_bpm())
	var bar_duration = 240.0 / bpm
	var humanize_ms = brief.get("rhythm", {}).get("humanize_ms", 0)
	var swing_pct = SWING.get(genre_id, 0.0)
	var velocity_cfg = VELOCITY.get(genre_id, VELOCITY["detroit_techno"])
	
	randomize()
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	
	# Choose scale based on genre character
	var scale: Array
	if genre_id in ["madonna_80s", "gypsy_woman_house"]:
		# Uplifting genres use MAJOR
		scale = PopMusicTheory.get_major_scale_notes(root_note)
	else:
		# Darker genres use minor
		scale = PopMusicTheory.get_minor_scale_notes(root_note)
	
	var progression = _get_genre_progression(genre_id)
	
	print("SoundbankGenerator: Generating %s in %s at %s BPM (swing: %s%%)" % [genre_id, root_note, bpm, swing_pct])
	
	var structure = STRUCTURES.get(genre_id, STRUCTURES["detroit_techno"])
	var section_names = structure["sections"]
	var section_bars = structure["bars"]
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = section_names.size()
	playback.initial_clip = 0
	
	for i in range(section_names.size()):
		var section_name = section_names[i]
		var num_bars = section_bars[i]
		var section_sounds = bank.get_section_sounds(section_name)
		if section_sounds.is_empty():
			section_sounds = bank.get_available_sounds()
		
		print("  Section '%s' (%d bars): %s" % [section_name, num_bars, ", ".join(section_sounds)])
		
		var stream = _generate_section(bank, genre_id, section_sounds, progression, 
		                                scale, bar_duration, bpm, num_bars, 
		                                humanize_ms, swing_pct, velocity_cfg)
		playback.set_clip_stream(i, stream)
		playback.set_clip_name(i, section_name.capitalize())
		
		playback.set_clip_auto_advance(i, 1)
		var next_clip = (i + 1) % section_names.size()
		playback.set_clip_auto_advance_next_clip(i, next_clip)
	
	var xfade = brief.get("transitions", {}).get("crossfade_s", 2.0)
	for i in range(section_names.size()):
		var next = (i + 1) % section_names.size()
		playback.add_transition(i, next,
			AudioStreamInteractive.TRANSITION_FROM_TIME_END,
			AudioStreamInteractive.TRANSITION_TO_TIME_START,
			AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _get_genre_progression(genre_id: String) -> Array:
	match genre_id:
		"detroit_techno":
			return [0, 5, 3, 4]
		"synthwave":
			return [0, 3, 5, 4]
		"burial":
			return [0, 5, 0, 3]
		"boards_of_canada":
			return [0, 2, 5, 0]
		"rave":
			return [0, 0, 5, 5]
		"kraftwerk":
			return [0, 4, 0, 4]
		"madonna_80s":
			return [0, 5, 3, 4]  # I - vi - IV - V (classic pop, MAJOR!)
		"gypsy_woman_house":
			return [0, 3, 4, 0]  # I - IV - V - I (uplifting house, MAJOR!)
		_:
			return [0, 5, 3, 4]


static func _generate_section(bank: SoundbankLoader, genre_id: String, sounds: Array, 
                               progression: Array, scale: Array, 
                               bar_duration: float, bpm: float, num_bars: int,
                               humanize_ms: float, swing_pct: float,
                               velocity_cfg: Dictionary) -> AudioStreamWAV:
	var total_duration = num_bars * bar_duration
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	
	var step_duration = bar_duration / 4.0  # 16th note
	var step_samples = int(step_duration * SAMPLE_RATE)
	
	var patterns = PATTERNS.get(genre_id, PATTERNS["detroit_techno"])
	var bass_cfg = BASS_PATTERNS.get(genre_id, BASS_PATTERNS["detroit_techno"])
	
	for bar in range(num_bars):
		var bar_start = int(bar * bar_duration * SAMPLE_RATE)
		var chord_idx = bar % progression.size()
		var degree = progression[chord_idx]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0] if chord_freqs.size() > 0 else 220.0
		
		for sound_name in sounds:
			if not bank.has_sound(sound_name):
				continue
			
			var script = bank.get_sound_script(sound_name)
			if script == null:
				continue
			
			# Drums and melodic patterns
			if patterns.has(sound_name):
				_add_pattern_sound(final_mix, script, bar_start, patterns[sound_name], 
				                   step_samples, sound_name, humanize_ms, swing_pct,
				                   velocity_cfg, chord_freqs)
			# Bass with its own pattern
			elif sound_name in ["bass", "sub", "hoover"]:
				_add_bass_pattern(final_mix, script, bar_start, bass_cfg,
				                  step_samples, root_freq, velocity_cfg, bar_duration)
			# Continuous sounds
			else:
				_add_continuous_sound(final_mix, script, bar_start, 
				                      int(bar_duration * SAMPLE_RATE), 
				                      sound_name, root_freq, chord_freqs, velocity_cfg)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.02))
	return _create_audio_stream(final_mix)


static func _add_pattern_sound(mix: PackedFloat32Array, script, bar_start: int, 
                                pattern: Array, step_samples: int, sound_name: String,
                                humanize_ms: float, swing_pct: float,
                                velocity_cfg: Dictionary, chord_freqs: Array) -> void:
	for step in range(pattern.size()):
		var vel = pattern[step]
		if vel == 0:
			continue
		
		var step_start = bar_start + step * step_samples
		
		# Apply swing (delay off-beats)
		if swing_pct > 0 and step % 2 == 1:
			var swing_samples = int(swing_pct / 100.0 * step_samples * 0.5)
			step_start += swing_samples
		
		# Apply humanization
		if humanize_ms > 0:
			var offset_samples = int((randf() - 0.5) * 2.0 * humanize_ms * SAMPLE_RATE / 1000.0)
			step_start = maxi(0, step_start + offset_samples)
		
		# Calculate velocity
		var volume = velocity_cfg["base"]
		if vel >= 2:
			volume = velocity_cfg["accent"]
		elif vel < 1:
			volume = velocity_cfg["ghost"]
		
		# Add random variation
		volume *= 1.0 + (randf() - 0.5) * velocity_cfg["variation"] * 2.0
		
		_add_sound_hit(mix, script, step_start, sound_name, chord_freqs, volume)


static func _add_bass_pattern(mix: PackedFloat32Array, script, bar_start: int,
                               bass_cfg: Dictionary, step_samples: int, 
                               root_freq: float, velocity_cfg: Dictionary,
                               bar_duration: float) -> void:
	var pattern = bass_cfg["pattern"]
	var style = bass_cfg["style"]
	
	if style == "continuous":
		# Continuous drone (rave hoover)
		var length = int(bar_duration * SAMPLE_RATE)
		var volume = velocity_cfg["base"]
		for i in range(length):
			var idx = bar_start + i
			if idx >= mix.size():
				break
			var t = float(i) / SAMPLE_RATE
			var sample = 0.0
			if script.has_method("generate"):
				sample = script.generate(t, root_freq, bar_duration, 0.0)
			elif script.has_method("generate_sample"):
				sample = script.generate_sample(t, root_freq)
			mix[idx] = clampf(mix[idx] + sample * volume, -1.0, 1.0)
		return
	
	for step in range(pattern.size()):
		if pattern[step] == 0:
			continue
		
		var step_start = bar_start + step * step_samples
		
		# Calculate note length based on style
		var note_length: float
		if style == "short":
			note_length = 0.1  # Staccato
		else:
			# Find next hit to determine sustain length
			var next_hit = 16
			for j in range(step + 1, 16):
				if pattern[j] > 0:
					next_hit = j
					break
			note_length = float(next_hit - step) * float(step_samples) / SAMPLE_RATE * 0.9
		
		var length_samples = int(note_length * SAMPLE_RATE)
		var volume = velocity_cfg["base"]
		
		for i in range(length_samples):
			var idx = step_start + i
			if idx >= mix.size():
				break
			var t = float(i) / SAMPLE_RATE
			var sample = 0.0
			if script.has_method("generate"):
				sample = script.generate(t, root_freq, note_length, 0.0)
			elif script.has_method("generate_sample"):
				sample = script.generate_sample(t, root_freq)
			mix[idx] = clampf(mix[idx] + sample * volume, -1.0, 1.0)


static func _add_sound_hit(mix: PackedFloat32Array, script, start: int, 
                           sound_name: String, chord_freqs: Array, volume: float) -> void:
	var duration_samples = int(0.5 * SAMPLE_RATE)
	
	for i in range(duration_samples):
		var idx = start + i
		if idx >= mix.size():
			break
		
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0
		
		match sound_name:
			"kick", "snare", "clap":
				if script.has_method("generate"):
					sample = script.generate(t, 0.0)
			"hihat":
				if script.has_method("generate_closed"):
					sample = script.generate_closed(t, 0.0)
				elif script.has_method("generate"):
					sample = script.generate(t, 0.0, false)
			"stab":
				if script.has_method("generate"):
					sample = script.generate(t, chord_freqs, 0.0)
			"arp", "sequence":
				var freq = chord_freqs[0] if chord_freqs.size() > 0 else 440.0
				if script.has_method("generate"):
					sample = script.generate(t, freq, 0.0)
			_:
				if script.has_method("generate"):
					sample = script.generate(t, 0.0)
		
		mix[idx] = clampf(mix[idx] + sample * volume, -1.0, 1.0)


static func _add_continuous_sound(mix: PackedFloat32Array, script, start: int, 
                                   length: int, sound_name: String, 
                                   root_freq: float, chord_freqs: Array,
                                   velocity_cfg: Dictionary) -> void:
	var note_duration = float(length) / SAMPLE_RATE
	var volume = velocity_cfg["base"]
	
	for i in range(length):
		var idx = start + i
		if idx >= mix.size():
			break
		
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0
		
		match sound_name:
			"pad", "atmosphere", "supersaw":
				if script.has_method("generate"):
					sample = script.generate(t, chord_freqs, note_duration, 0.0)
				elif script.has_method("generate_sample"):
					sample = script.generate_sample(t, chord_freqs)
			"crackle", "texture":
				if script.has_method("generate"):
					sample = script.generate(t, 0.0)
			"vocal", "vocoder":
				var freq = chord_freqs[0] if chord_freqs.size() > 0 else 440.0
				if script.has_method("generate"):
					sample = script.generate(t, freq, 0.0)
			_:
				if script.has_method("generate_sample"):
					sample = script.generate_sample(t, chord_freqs)
				elif script.has_method("generate"):
					sample = script.generate(t, 0.0)
		
		mix[idx] = clampf(mix[idx] + sample * volume, -1.0, 1.0)


static func _apply_fade_envelope(buffer: PackedFloat32Array, fade_samples: int) -> void:
	var size = buffer.size()
	for i in range(mini(fade_samples, size)):
		var fade = float(i) / fade_samples
		buffer[i] *= fade
		buffer[size - 1 - i] *= fade


static func _create_audio_stream(buffer: PackedFloat32Array) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(buffer.size() * 2)
	
	for i in range(buffer.size()):
		var sample_16 = int(clampf(buffer[i], -1.0, 1.0) * 32767.0)
		data[i * 2] = sample_16 & 0xFF
		data[i * 2 + 1] = (sample_16 >> 8) & 0xFF
	
	stream.data = data
	return stream
