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
	# Moroder Disco: "I Feel Love" - hypnotic 16th sequencer
	"moroder_disco": {
		"kick":          [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # 4-on-floor
		"hihat":         [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1],  # Constant 16ths!
		"snare":         [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # 2 and 4
		"sequencer":     [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1],  # THE motor - never stops
		"singing_voice": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # "I... feel... love..."
	},
	
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
	
	# Vangelis CS-80: Cinematic, expressive, sparse drums with big pads
	"vangelis_cs80": {
		"cr5000_kick":  [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Sparse, cinematic
		"cr5000_snare": [0,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,0,0],  # Only on 4 (sparse)
		"cr5000_hihat": [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0],  # Offbeat hats
		"jupiter_arp":  [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],  # 8th note arpeggio
	},
	
	# === HYBRID PATTERNS (cross-genre experiments) ===
	
	# Replicant's Dawn: Vangelis meets Detroit (cinematic machine)
	"replicants_dawn": {
		"kick":        [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # Detroit 4-on-floor
		"snare":       [0,0,0,0, 0.5,0,0,0, 0,0,0,0, 1,0,0,0],  # Ghost on 2, hit on 4
		"hihat":       [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0],  # Offbeat (Detroit style)
		"clap":        [0,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,0,0],  # Sparse, cinematic
		"stab":        [0,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0],  # Detroit stab
		"jupiter_arp": [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],  # Vangelis shimmer
	},
	
	# Foggy Frequencies: Boards of Canada x Burial (lo-fi 2-step)
	"foggy_frequencies": {
		"kick":      [0,0,1,0, 0,0,0,0, 0,0,1,0, 0,0.5,0,0],  # Burial displacement
		"snare":     [0,0,0,0, 1,0,0,0.5, 0,0,0,0, 0.5,0,0,1],  # BoC swung snare
		"hihat":     [0.5,0,0,0.5, 0,1,0.5,0, 0.5,0,0,0.5, 0,1,0,0.5],  # Ghostly
		"texture":   [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # BoC texture continuous
		"crackle":   [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # Burial crackle continuous
		"sequence":  [1,0,0,0, 0,0,1,0, 0,1,0,0, 0,0,0,1],  # BoC warped sequence
		"vocal":     [0,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Burial vocal chop (sparse)
	},
	
	# Chicago to Düsseldorf: House x Kraftwerk (groove becomes machine)
	"chicago_dusseldorf": {
		"kick":     [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # 4-on-floor (shared)
		"snare":    [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # 2 and 4
		"clap":     [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # Chicago clap
		"hihat":    [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],  # Motorik 8ths
		"piano":    [0,0,1,0, 0,0,0,1, 0,0,1,0, 0,0,0,1],  # Chicago offbeat piano (THE sound!)
		"organ":    [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # Sustained organ
		"sequence": [1,0,0,1, 0,0,1,0, 1,0,0,1, 0,0,1,0],  # Kraftwerk sequence
		"vocoder":  [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Robotic vocoder hits
	},
}

# =============================================================================
# BASS PATTERNS - Rhythmic, not just sustained
# =============================================================================

const BASS_PATTERNS = {
	"moroder_disco": {
		"pattern": [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # Pulsing with the sequencer
		"style": "sustained",
	},
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
	# Vangelis CS-80: Sparse, cinematic sub bass
	"vangelis_cs80": {
		"pattern": [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # Very sparse
		"style": "sustained",  # Long, emotional notes
	},
	# Hybrid: Replicant's Dawn - Detroit bass with cinematic space
	"replicants_dawn": {
		"pattern": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Detroit locked to kick
		"style": "sustained",
	},
	# Hybrid: Foggy Frequencies - Burial sub with BoC warmth
	"foggy_frequencies": {
		"pattern": [1,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0],  # Burial offbeat sub
		"style": "sustained",
	},
	# Hybrid: Chicago to Düsseldorf - morphing bass
	"chicago_dusseldorf": {
		"pattern": [0,0,1,0, 0,0,0,1, 0,0,1,0, 0,0,0,1],  # Chicago offbeat
		"style": "short",
	},
}

# =============================================================================
# SWING AMOUNTS (percentage, applied to off-beats)
# =============================================================================

const SWING = {
	"moroder_disco": 0.0,        # Machine straight - hypnotic precision
	"detroit_techno": 0.0,       # Machine straight
	"synthwave": 0.0,            # Straight 80s
	"burial": 12.0,              # UK garage swing
	"boards_of_canada": 18.0,    # Lazy hip-hop swing
	"rave": 0.0,                 # Straight aggression
	"kraftwerk": 0.0,            # Robot precision
	"madonna_80s": 0.0,          # Tight pop
	"gypsy_woman_house": 8.0,    # Groovy house swing
	"vangelis_cs80": 0.0,        # Cinematic straight
	"replicants_dawn": 0.0,      # Machine precision (Detroit side)
	"foggy_frequencies": 15.0,   # Blend of Burial (12) and BoC (18)
	"chicago_dusseldorf": 4.0,   # Slight groove, transitioning to straight
}

# =============================================================================
# VELOCITY CURVES (base velocity multiplier)
# =============================================================================

const VELOCITY = {
	"ada_theme": {
		"base": 0.5,       # Soft, supportive
		"accent": 0.7,
		"ghost": 0.25,
		"variation": 0.1,
	},
	"aphex_twin": {
		"base": 0.65,      # Warm but present
		"accent": 0.85,
		"ghost": 0.35,     # Audible ghosts (lo-fi character)
		"variation": 0.18, # Human wobble
	},
	"moroder_disco": {
		"base": 0.85,      # Consistent, driving
		"accent": 1.0,
		"ghost": 0.6,
		"variation": 0.02, # Very tight - machine
	},
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
	"vangelis_cs80": {
		"base": 0.7,       # Cinematic dynamics
		"accent": 0.95,    # Expressive but controlled
		"ghost": 0.3,
		"variation": 0.12, # Slight human expression
	},
	"replicants_dawn": {
		"base": 0.75,      # Blend: Detroit machine + Vangelis expression
		"accent": 0.95,
		"ghost": 0.4,
		"variation": 0.08,
	},
	"foggy_frequencies": {
		"base": 0.5,       # Soft, lo-fi (BoC influence)
		"accent": 0.7,
		"ghost": 0.2,      # Very quiet ghosts
		"variation": 0.18, # Human, nostalgic
	},
	"chicago_dusseldorf": {
		"base": 0.8,       # Starts groovy, becomes machine
		"accent": 0.95,
		"ghost": 0.5,
		"variation": 0.06, # Transitioning to robotic
	},
}

# =============================================================================
# SECTION STRUCTURES
# =============================================================================

const STRUCTURES = {
	"ada_theme": {
		"sections": ["intro", "verse", "chorus", "verse", "chorus", "bridge", "outro"],
		"bars": [4, 8, 8, 8, 8, 4, 4],
	},
	"aphex_twin": {
		"sections": ["intro", "build", "main", "breakdown", "main", "outro"],
		"bars": [8, 8, 16, 8, 16, 8],
	},
	"moroder_disco": {
		"sections": ["intro", "build", "main", "vocal", "breakdown", "drop", "outro"],
		"bars": [8, 8, 16, 16, 8, 16, 8],
	},
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
		"sections": ["intro", "verse", "chorus", "verse", "chorus", "outro"],
		"bars": [8, 16, 8, 16, 8, 8],
	},
	"madonna_80s": {
		"sections": ["intro", "verse", "prechorus", "chorus", "verse", "chorus", "outro"],
		"bars": [4, 8, 4, 8, 8, 8, 4],
	},
	"gypsy_woman_house": {
		"sections": ["intro", "build", "main", "breakdown", "drop", "main", "outro"],
		"bars": [4, 8, 16, 8, 16, 8, 4],
	},
	"vangelis_cs80": {
		"sections": ["intro", "build", "main", "breakdown", "climax", "outro"],
		"bars": [8, 8, 16, 8, 16, 8],
	},
	# Replicant's Dawn: Vangelis x Detroit - cinematic to machine
	"replicants_dawn": {
		"sections": ["intro", "build", "main", "breakdown", "climax", "outro"],
		"bars": [8, 8, 16, 8, 8, 8],
	},
	# Foggy Frequencies: BoC x Burial - nostalgic nocturne
	"foggy_frequencies": {
		"sections": ["intro", "build", "main", "breakdown", "main", "outro"],
		"bars": [8, 8, 16, 8, 16, 8],
	},
	# Chicago to Düsseldorf: House x Kraftwerk - soul becomes machine
	"chicago_dusseldorf": {
		"sections": ["intro", "verse", "transition", "robotic", "breakdown", "finale", "outro"],
		"bars": [4, 16, 8, 16, 8, 16, 4],
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
	if genre_id in ["madonna_80s", "gypsy_woman_house", "ada_theme"]:
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
	
	var xfade_val = brief.get("transitions", {}).get("crossfade_s", 2.0)
	var xfade: float = float(xfade_val) if not xfade_val is Dictionary else 2.0
	for i in range(section_names.size()):
		var next = (i + 1) % section_names.size()
		playback.add_transition(i, next,
			AudioStreamInteractive.TRANSITION_FROM_TIME_END,
			AudioStreamInteractive.TRANSITION_TO_TIME_START,
			AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


# =============================================================================
# HYBRID SONG GENERATION
# Combines sounds from multiple soundbanks for cross-genre experiments
# =============================================================================

const HYBRID_CONFIGS = {
	"replicants_dawn": {
		"primary_bank": "vangelis_cs80",
		"secondary_bank": "detroit_techno",
		"bpm": 120,
		"description": "Vangelis × Detroit - existential machine awakening",
		# Which sounds come from which bank
		"sound_sources": {
			"vp330_choir": "vangelis_cs80",
			"prophet_pad": "vangelis_cs80",
			"cs80_strings": "vangelis_cs80",
			"cs80_brass": "vangelis_cs80",
			"cs80_lead": "vangelis_cs80",
			"jupiter_arp": "vangelis_cs80",
			"kick": "detroit_techno",
			"snare": "detroit_techno",
			"hihat": "detroit_techno",
			"clap": "detroit_techno",
			"bass": "detroit_techno",
			"stab": "detroit_techno",
		},
		"section_sounds": {
			"intro": ["vp330_choir", "prophet_pad"],
			"build": ["cs80_strings", "jupiter_arp", "prophet_pad"],
			"main": ["kick", "hihat", "bass", "cs80_brass", "prophet_pad"],
			"breakdown": ["prophet_pad", "snare"],
			"climax": ["kick", "snare", "hihat", "clap", "bass", "cs80_lead", "cs80_strings", "vp330_choir"],
			"outro": ["vp330_choir", "prophet_pad"],
		},
	},
	"foggy_frequencies": {
		"primary_bank": "boards_of_canada",
		"secondary_bank": "burial",
		"bpm": 130,
		"description": "BoC × Burial - nostalgic nocturne",
		"sound_sources": {
			"texture": "boards_of_canada",
			"sequence": "boards_of_canada",
			"pad": "boards_of_canada",
			"bass": "boards_of_canada",
			"kick": "burial",
			"snare": "burial",
			"hihat": "burial",
			"sub": "burial",
			"crackle": "burial",
			"atmosphere": "burial",
			"vocal": "burial",
		},
		"section_sounds": {
			"intro": ["texture", "crackle"],
			"build": ["sequence", "pad", "atmosphere"],
			"main": ["kick", "snare", "hihat", "pad", "bass"],
			"breakdown": ["vocal", "sequence", "crackle"],
			"outro": ["texture", "crackle"],
		},
	},
	"chicago_dusseldorf": {
		"primary_bank": "gypsy_woman_house",
		"secondary_bank": "kraftwerk",
		"bpm": 122,
		"description": "Chicago House × Kraftwerk - soul becomes machine",
		"sound_sources": {
			"piano": "gypsy_woman_house",
			"organ": "gypsy_woman_house",
			"pad": "gypsy_woman_house",
			"bass": "gypsy_woman_house",
			"kick": "gypsy_woman_house",
			"clap": "gypsy_woman_house",
			"hihat": "kraftwerk",
			"snare": "kraftwerk",
			"sequence": "kraftwerk",
			"vocoder": "kraftwerk",
		},
		"section_sounds": {
			"intro": ["piano", "organ", "pad"],
			"verse": ["kick", "clap", "hihat", "bass", "piano"],
			"transition": ["piano", "sequence"],
			"robotic": ["kick", "hihat", "snare", "bass", "vocoder"],
			"breakdown": ["piano", "pad"],
			"finale": ["kick", "hihat", "organ", "clap", "sequence", "vocoder"],
			"outro": ["sequence", "pad"],
		},
	},
}


static func generate_hybrid_song(hybrid_id: String, parameters: Dictionary = {}) -> AudioStreamInteractive:
	"""Generate a song that combines sounds from multiple soundbanks"""
	if not HYBRID_CONFIGS.has(hybrid_id):
		push_error("SoundbankGenerator: Unknown hybrid config: " + hybrid_id)
		return null
	
	var config = HYBRID_CONFIGS[hybrid_id]
	var primary_bank = SoundbankLoader.load_genre(config.primary_bank)
	var secondary_bank = SoundbankLoader.load_genre(config.secondary_bank)
	
	if primary_bank.get_available_sounds().is_empty() or secondary_bank.get_available_sounds().is_empty():
		push_error("SoundbankGenerator: Failed to load soundbanks for hybrid " + hybrid_id)
		return null
	
	var bpm = parameters.get("bpm", config.get("bpm", 120))
	var bar_duration = 240.0 / bpm
	var swing_pct = SWING.get(hybrid_id, 0.0)
	var velocity_cfg = VELOCITY.get(hybrid_id, VELOCITY["detroit_techno"])
	
	randomize()
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)
	var progression = _get_genre_progression(hybrid_id)
	
	print("SoundbankGenerator: Generating hybrid '%s' (%s × %s) in %s at %s BPM" % [
		hybrid_id, config.primary_bank, config.secondary_bank, root_note, bpm
	])
	
	var structure = STRUCTURES.get(hybrid_id, STRUCTURES["detroit_techno"])
	var section_names = structure["sections"]
	var section_bars = structure["bars"]
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = section_names.size()
	playback.initial_clip = 0
	
	for i in range(section_names.size()):
		var section_name = section_names[i]
		var num_bars = section_bars[i]
		var section_sounds = config.section_sounds.get(section_name, [])
		
		print("  Section '%s' (%d bars): %s" % [section_name, num_bars, ", ".join(section_sounds)])
		
		var stream = _generate_hybrid_section(
			primary_bank, secondary_bank, config,
			hybrid_id, section_sounds, progression,
			scale, bar_duration, bpm, num_bars,
			swing_pct, velocity_cfg
		)
		playback.set_clip_stream(i, stream)
		playback.set_clip_name(i, section_name.capitalize())
		
		playback.set_clip_auto_advance(i, 1)
		var next_clip = (i + 1) % section_names.size()
		playback.set_clip_auto_advance_next_clip(i, next_clip)
	
	# Add crossfades
	for i in range(section_names.size()):
		var next = (i + 1) % section_names.size()
		playback.add_transition(i, next,
			AudioStreamInteractive.TRANSITION_FROM_TIME_END,
			AudioStreamInteractive.TRANSITION_TO_TIME_START,
			AudioStreamInteractive.FADE_CROSS, 2.0)
	
	return playback


static func _generate_hybrid_section(
	primary_bank: SoundbankLoader, secondary_bank: SoundbankLoader,
	config: Dictionary, hybrid_id: String, sounds: Array,
	progression: Array, scale: Array,
	bar_duration: float, bpm: float, num_bars: int,
	swing_pct: float, velocity_cfg: Dictionary
) -> AudioStreamWAV:
	"""Generate a section using sounds from multiple banks"""
	var total_duration = num_bars * bar_duration
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	
	var step_samples = int((bar_duration / 16.0) * SAMPLE_RATE)  # 16th note (bar has 16 steps)
	var patterns = PATTERNS.get(hybrid_id, PATTERNS["detroit_techno"])
	var bass_cfg = BASS_PATTERNS.get(hybrid_id, BASS_PATTERNS["detroit_techno"])
	var sound_sources = config.get("sound_sources", {})
	
	for bar in range(num_bars):
		var bar_start = int(bar * bar_duration * SAMPLE_RATE)
		var chord_idx = bar % progression.size()
		var degree = progression[chord_idx]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0] if chord_freqs.size() > 0 else 220.0
		
		for sound_name in sounds:
			# Determine which bank has this sound
			var source_bank_name = sound_sources.get(sound_name, config.primary_bank)
			var bank = primary_bank if source_bank_name == config.primary_bank else secondary_bank
			
			if not bank.has_sound(sound_name):
				continue
			
			var script = bank.get_sound_script(sound_name)
			if script == null:
				continue
			
			# Drums and melodic patterns (use hybrid patterns)
			if patterns.has(sound_name):
				_add_pattern_sound(final_mix, script, bar_start, patterns[sound_name],
								   step_samples, sound_name, 0.0, swing_pct,
								   velocity_cfg, chord_freqs)
			# Bass with its own pattern
			elif sound_name in ["bass", "sub", "hoover"]:
				_add_bass_pattern(final_mix, script, bar_start, bass_cfg,
								  step_samples, root_freq, velocity_cfg, bar_duration)
			# Continuous sounds (pads, atmosphere, etc.)
			else:
				_add_continuous_sound(final_mix, script, bar_start,
									  int(bar_duration * SAMPLE_RATE),
									  sound_name, root_freq, chord_freqs, velocity_cfg)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.02))
	return _create_audio_stream(final_mix)


static func _get_genre_progression(genre_id: String) -> Array:
	match genre_id:
		"moroder_disco":
			return [0, 0, 0, 0]  # SINGLE CHORD - pure hypnosis (I Feel Love style)
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
		"vangelis_cs80":
			return [0, 3, 5, 4]  # i - iv - vi - V (cinematic minor drama)
		"replicants_dawn":
			return [0, 5, 3, 4]  # Dm - Bb - Gm - A (cinematic minor)
		"foggy_frequencies":
			return [0, 5, 6, 3]  # Fm - Ab - Eb - Db (descending, melancholic)
		"chicago_dusseldorf":
			return [0, 3, 4, 0]  # Am - Dm - G - C (soulful then robotic)
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
	
	var step_duration = bar_duration / 16.0  # 16th note (bar has 16 steps)
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
			"stab", "piano", "organ":
				if script.has_method("generate"):
					sample = script.generate(t, chord_freqs, 0.0)
			"arp", "sequence":
				var freq = chord_freqs[0] if chord_freqs.size() > 0 else 440.0
				if script.has_method("generate"):
					sample = script.generate(t, freq, 0.0)
			_:
				# Fallback for unknown instruments (likely drums)
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
