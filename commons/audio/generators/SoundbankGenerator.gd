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
		"arp":   [1,0,0,1, 0,0,1,0, 0,1,0,0, 1,0,0,1],  # Dotted-8th cascade (Jan Hammer, Kavinsky)
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
		"sequence":[1,0,0,0, 0,0,0,1, 0,0,1,0, 0,0,0,0],  # Irregular, degraded — tape-warped feel
	},
	
	# Rave: Aggressive, LOUD, frantic
	"rave": {
		"kick":  [2,0,2,0, 2,0,2,0, 2,0,2,0, 2,0,2,0],  # All accents!
		"snare": [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,2],
		"hihat": [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1],  # 16ths full blast
		"stab":  [0,0,0,2, 0,0,2,0, 0,0,0,2, 0,2,0,0],  # Rotating accent position — frantic, triplet-adjacent
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
		"arp":   [1,0,0,1, 0,1,0,0, 1,0,0,1, 0,1,0,0],  # Syncopated pop bounce (Like a Prayer era)
		"stab":  [0,0,0,1, 0,1,0,0, 0,0,0,1, 0,0,1,0],  # Bouncy offbeat stab
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
	
	# Dub House: Deep, spacious, hypnotic - Basic Channel/Maurizio style
	# The SPACE between hits is the instrument. Less is more.
	# Reference: "Phylyps Trak", "Quadrant Dub", Rhythm & Sound
	"dub_house": {
		"kick":    [2,0,0,0, 1,0,0,0.2, 1,0,0,0, 1,0,0.2,0],  # 4-on-floor with subtle ghost kicks
		"rimshot": [0,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,0,0],      # SPARSE - single rimshot on beat 4
		"snare":   [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],      # Essentially unused - rimshot replaces it
		"clap":    [0,0,0,0, 0,0,0,0, 0.8,0,0,0, 0,0,0,0],    # Single soft clap on 3 (sparse accent)
		"hihat":   [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0.6],    # Offbeat 8ths + ghost open hat on &4
		"stab":    [0,0,0,1, 0,0,0,0.25, 0,0,0,1, 0,0,0,0.25],# Dub chord with delay-style ghost echoes
	},
	
	# 90s R&B: Authentic New Jack Swing at 92 BPM
	# Reference: Guy "Piece of My Love", Teddy Riley, Blackstreet
	# Pattern designed for 18% swing — the pocket lives here
	"nineties_rnb": {
		"kick":      [2,0,0.4,0, 0,0.3,0,0.25, 1,0,0,0.35, 0,0.5,0,0.25],  # Syncopated 808 with tasteful ghosts
		"snare":     [0,0,0.2,0, 2,0,0,0.25, 0,0,0.15,0, 2,0,0,0.3],       # 2&4 with light pre/after ghosts
		"clap":      [0,0,0,0, 1,0,0.15,0, 0,0,0,0, 1,0,0.2,0],            # Layered clap with subtle flare
		"hihat":     [0.8,0.2,0.6,0.2, 0.85,0.2,0.55,0.25, 0.8,0.2,0.6,0.2, 0.9,0.25,0.7,0.25],  # Silky swung 16ths
		"shaker":    [0.35,0.25,0.35,0.25, 0.35,0.25,0.35,0.25, 0.35,0.25,0.35,0.25, 0.35,0.25,0.35,0.25],  # Soft 16ths
		"fingersnap":[0,0,0,0, 0.8,0,0,0, 0,0,0,0, 0.8,0,0,0], # Subtle 2&4
		"rhodes":    [1,0,0.4,0, 0,0,0.7,0.2, 0.9,0,0.3,0, 0,0,0.6,0.3],  # More offbeat comping
		"pad":       [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],     # Sustained JV-1080 strings
		"strings":   [0,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],     # Swell on beat 3
		"organ":     [0,0,0.8,0, 0,0,0.65,0, 0,0,0.8,0, 0,0,0.7,0],  # M1-style offbeat stabs
		"lead":      [0,0,0,0, 0,0,0.55,0, 0,0,0,0, 0,0.8,0,0.5],    # Sparse hook answer phrase
	},
	
	# Chromatic Story: Jazz-influenced emotional journey (Am → C)
	# Light jazzy feel with room for chromatic exploration
	"chromatic_story": {
		"kick":    [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Light 4-on-floor (half notes feel)
		"snare":   [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # 2 and 4 (brushes)
		"hihat":   [0.6,0,0.4,0, 0.6,0,0.4,0, 0.6,0,0.4,0, 0.6,0,0.4,0],  # Swung 8ths with ghost notes
		"rimshot": [0,0,0,0, 0,0,0.5,0, 0,0,0,0, 0,0,0.5,0],  # Jazz rimclick accents
		"piano":   [1,0,0,0.4, 0,0,1,0, 0.6,0,0,0.4, 0,0,0.8,0],  # Comping with syncopation
		"pad":     [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # Sustained chord
		"sequence":[0,0,1,0, 0,1,0,0, 0,0,1,0, 1,0,0,0],  # Chromatic arpeggio pattern
	},
	
	# Vangelis CS-80: Cinematic, expressive, sparse drums with big pads
	"vangelis_cs80": {
		"cr5000_kick":  [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Sparse, cinematic
		"cr5000_snare": [0,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,0,0],  # Only on 4 (sparse)
		"cr5000_hihat": [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0],  # Offbeat hats
		"jupiter_arp":  [1,0,0,0, 1,0,0,0, 1,0,1,0, 0,0,1,0],  # Slow shimmer with acceleration — expressive CS-80
	},
	
	# === HYBRID PATTERNS (cross-genre experiments) ===
	
	# Replicant's Dawn: Vangelis meets Detroit (cinematic machine)
	"replicants_dawn": {
		"kick":        [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # Detroit 4-on-floor
		"snare":       [0,0,0,0, 0.5,0,0,0, 0,0,0,0, 1,0,0,0],  # Ghost on 2, hit on 4
		"hihat":       [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0],  # Offbeat (Detroit style)
		"clap":        [0,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,0,0],  # Sparse, cinematic
		"stab":        [0,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0],  # Detroit stab
		"jupiter_arp": [1,0,1,0, 0,0,1,0, 1,0,0,0, 1,0,1,0],  # Detroit-influenced regularity — more mechanical than vanilla Vangelis
	},
	
	# Foggy Frequencies: Boards of Canada x Burial (lo-fi 2-step)
	"foggy_frequencies": {
		"kick":      [0,0,1,0, 0,0,0,0, 0,0,1,0, 0,0.5,0,0],  # Burial displacement
		"snare":     [0,0,0,0, 1,0,0,0.5, 0,0,0,0, 0.5,0,0,1],  # BoC swung snare
		"hihat":     [0.5,0,0,0.5, 0,1,0.5,0, 0.5,0,0,0.5, 0,1,0,0.5],  # Ghostly
		"texture":   [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # BoC texture continuous
		"crackle":   [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # Burial crackle continuous
		"sequence":  [0,0,1,0, 0,0,0,0, 1,0,0,0, 0,1,0,0],  # Broken, ghostly fragments — distinct from BoC
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
	
	# Dark Wave Cathedral: She Past Away meets Bauhaus — post-punk syncopation, tribal toms
	# Reference: She Past Away "Ritüel", Boy Harsher "Pain", Bauhaus "Bela Lugosi's Dead"
	# 118 BPM, syncopated kick, gated snare, tribal toms, cold hypnotic arp
	"dark_wave": {
		"kick":     [2,0,0,0, 0,0,1,0, 0,0,0,0, 0,1,0,0],  # Syncopated post-punk
		"snare":    [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,0],  # Gated crack on 2&4
		"hihat":    [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,0.5,0],  # 8ths with ghost
		"tom_low":  [0,0,1,0, 0,0,0,0, 1,0,0,0, 0,0,1,0],  # Tribal deep
		"tom_high": [0,0,0,0, 0,0,0,1, 0,0,1,0, 0,0,0,0],  # Tight pitched
		"clap":     [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # Layered with snare
		"arp":      [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1],  # Never stops — the heartbeat
	},

	# K-Bass: Korean bass music — jungle/DnB grammar with Seoul sensibilities
	# Reference: yunji "ECHO", ENTER THE K-BASS Vol.1 (SCR × ScreaM)
	# 170 BPM, break-led, sub as lead instrument, drop-based dynamics
	"k_bass": {
		"kick":    [2,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0],  # Syncopated jungle kick
		"snare":   [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,1],  # Strong 2&4 with ghost roll
		"hihat":   [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1],  # Rolling 16ths (jungle)
		"sub":     [2,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Sub as LEAD — pressure on 1&3
		"stab":    [0,0,0,0, 0,0,0,2, 0,0,0,0, 0,0,0,0],  # Metallic stab punctuation (sparse)
		"break":   [1,0,1,0, 0,1,0,0, 1,0,0,1, 0,0,1,0],  # Chopped break pattern overlay
		"atmosphere": [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # Tension drone (sustained)
	},
	
	# === ADDITIONAL GENRE PATTERNS ===
	
	# Acid House: 303 sequence IS the genre — rolling, accent-driven
	# Reference: Phuture "Acid Tracks", DJ Pierre, Adonis
	"acid_house": {
		"kick":      [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # 4-on-floor
		"snare":     [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # 2 and 4
		"hihat":     [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],  # Open/closed 8ths
		"clap":      [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # Layered with snare
		"sequencer": [1,0,1,1, 0,1,1,0, 1,1,0,1, 0,1,0,1],  # 303 rolling pattern (accent-driven)
	},
	
	# Acid Techno 303: Harder, more relentless — Birmingham/Berlin acid
	# Reference: Hardfloor "Acperience 1", Dave Clarke, Chris Liberator
	"acid_techno_303": {
		"kick":      [2,0,0,0, 2,0,0,0, 2,0,0,0, 2,0,0,0],  # Pounding 4-on-floor
		"snare":     [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,0],  # Hard snare on 2&4
		"hihat":     [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1],  # Relentless 16ths
		"clap":      [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,0],  # Hard clap
		"sequencer": [1,1,0,2, 1,0,2,1, 0,1,2,0, 1,2,0,1],  # Aggressive 303 with accents
	},
	
	# French Touch: Filtered disco, offbeat everything — Daft Punk, Cassius, Etienne de Crécy
	# Reference: "Around the World", "Da Funk", Stardust "Music Sounds Better with You"
	"french_touch": {
		"kick":  [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # 4-on-floor
		"snare": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # 2 and 4
		"clap":  [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # Layered
		"hihat": [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,1],  # Offbeat with open hat on &4
		"stab":  [0,1,0,0, 0,1,0,1, 0,1,0,0, 0,1,0,1],  # Disco stab — offbeat funk
	},
	
	# Ambient Techno: Very sparse, dub-influenced — Basic Channel/Pole territory
	# Reference: Biosphere "Substrata", Wolfgang Voigt, Deepchord
	"ambient_techno": {
		"kick":  [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Half-time pulse
		"snare": [0,0,0,0, 0,0,0,0, 0,0,0,0, 0.5,0,0,0],  # Ghost snare on 4
		"hihat": [0,0,0.5,0, 0,0,0.5,0, 0,0,0.5,0, 0,0,0.5,0],  # Whisper offbeat hats
		"stab":  [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # Single chord hit per bar
	},
	
	# Lo-fi House: Dusty, sample-based — DJ Seinfeld, Mall Grab, Ross from Friends
	# Reference: "U", "I Just Wanna", warm tape hiss aesthetic
	"lofi_house": {
		"kick":  [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0.5,0],  # 4-on-floor with ghost
		"snare": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # 2 and 4
		"hihat": [0,0,1,1, 0,0,1,0, 0,0,1,1, 0,0,1,0],  # Offbeat shaker feel
		"stab":  [0,0,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,1],  # Dusty offbeat sample chops
	},
	
	# Supersaw Trance: Anthemic, building — Ferry Corsten, ATB, Paul van Dyk
	# Reference: "Out of the Blue", "9pm (Till I Come)", gate trance builds
	"supersaw_trance": {
		"kick":  [2,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # Accent on 1
		"snare": [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,0],  # Big 2&4
		"clap":  [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # Layered
		"hihat": [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],  # Driving 8ths
		"arp":   [1,0,0,1, 0,1,0,0, 1,0,0,1, 0,0,1,0],  # Gate trance arp — syncopated, not straight
	},
	
	# Reese Jungle: Breakbeat chopped, dark reese bass — Goldie, Photek, Dillinja
	# Reference: "Inner City Life", "Ni Ten Ichi Ryu", dark roller aesthetics
	"reese_jungle": {
		"kick":  [2,0,0,0, 0,0,1,0, 0,0,0,0, 0,1,0,0],  # Broken kick pattern
		"snare": [0,0,0,0, 2,0,0,0.5, 0,0,0,0, 2,0,0,1],  # Strong hits with ghost rolls
		"hihat": [1,1,0,1, 0,1,1,0, 1,0,1,1, 0,1,0,1],  # Chopped break hats
		"stab":  [0,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0],  # Single dark reese stab
	},
	
	# Midnight Metroplex: Jazz-tinged Detroit — Carl Craig, Moodymann, Kenny Larkin
	# Reference: "Bug in the Bassbin", "Shades of Jae", sparse melodic techno
	"midnight_metroplex": {
		"kick":  [2,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # Detroit 4-on-floor
		"snare": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # 2 and 4
		"hihat": [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0],  # Offbeat hats
		"stab":  [0,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,0,1],  # Jazz chord stab — syncopated, sparse
		"lead":  [0,0,0,0, 0,0,0,0.5, 0,0,0,0, 0,0.7,0,0],  # Ghost melody fragments
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
	"dub_house": {
		"pattern": [0,0,1,0, 0,0,0,1, 0,0,1,0, 0,0,0,1],  # Offbeat sub pulse
		"style": "sustained",
	},
	# 90s R&B: Deep Moog sub bass with filter envelope — chromatic approach tones
	"nineties_rnb": {
		"pattern": [1,0,0.4,0, 0,0.3,0,0.2, 1,0,0.3,0, 0,0.4,0,0.2],  # Root + ghost approach notes
		"style": "sustained",  # Deep round Moog sub with filter envelope
	},
	# Chromatic Story: Walking bass with chromatic passing tones
	"chromatic_story": {
		"pattern": [1,0,0,0, 0,0,1,0, 0,0,1,0, 0,0,1,0],  # Walking quarter notes with pickup
		"style": "walking",  # Jazz walking bass style
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
	# Dark Wave: Juno-106 Moog analog round bass — follows chord root
	"dark_wave": {
		"pattern": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,1,0],  # Root hits + step 15 anticipation
		"style": "sustained",  # Juno chorus bass, long round notes
	},
	# K-Bass: Reese sub as lead — pressure and weight, physical impact
	"k_bass": {
		"pattern": [2,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],  # Sub hits on 1&3, accent on 1
		"style": "sustained",  # Long, physical sub pressure
	},
	# Acid House: Pulsing 303 bass, locked to kick
	"acid_house": {
		"pattern": [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # 4-on-floor pulse
		"style": "sustained",
	},
	# Acid Techno 303: Hard, distorted bass
	"acid_techno_303": {
		"pattern": [2,0,0,0, 2,0,0,0, 2,0,0,0, 2,0,0,0],  # Pounding, accented
		"style": "sustained",
	},
	# French Touch: Filtered disco bass — side-chained
	"french_touch": {
		"pattern": [0,0,1,0, 0,0,0,1, 0,0,1,0, 0,0,0,1],  # Offbeat disco
		"style": "short",  # Choppy, filtered
	},
	# Ambient Techno: Deep, sparse sub
	"ambient_techno": {
		"pattern": [1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0],  # One hit per bar
		"style": "sustained",  # Long, deep drone
	},
	# Lo-fi House: Warm, round bass
	"lofi_house": {
		"pattern": [1,0,0,0, 0,0,1,0, 1,0,0,0, 0,0,1,0],  # Syncopated warmth
		"style": "sustained",
	},
	# Supersaw Trance: Driving bass, locked to kick
	"supersaw_trance": {
		"pattern": [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],  # Driving 4-on-floor
		"style": "sustained",
	},
	# Reese Jungle: Heavy reese sub
	"reese_jungle": {
		"pattern": [2,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0],  # Sub pressure with offbeat hit
		"style": "sustained",  # Long, dark reese
	},
	# Midnight Metroplex: Jazz-influenced walking bass
	"midnight_metroplex": {
		"pattern": [1,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0],  # Sparse, jazzy
		"style": "sustained",
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
	"dub_house": 8.0,            # Deep house sway
	"vangelis_cs80": 0.0,        # Cinematic straight
	"nineties_rnb": 18.0,        # Authentic New Jack Swing (Teddy Riley groove)
	"chromatic_story": 5.0,      # Slight jazz swing (not too heavy)
	"replicants_dawn": 0.0,      # Machine precision (Detroit side)
	"foggy_frequencies": 15.0,   # Blend of Burial (12) and BoC (18)
	"chicago_dusseldorf": 4.0,   # Slight groove, transitioning to straight
	"k_bass": 0.0,               # Jungle straight — precision at 170 BPM
	"dark_wave": 7.0,            # Slight swing — deliberate, ritualistic (from song config)
	"acid_house": 0.0,           # Machine straight — 303 precision
	"acid_techno_303": 0.0,      # Relentless machine
	"french_touch": 0.0,         # Tight disco machine
	"ambient_techno": 0.0,       # Dub precision
	"lofi_house": 10.0,          # Dusty, loose swing
	"supersaw_trance": 0.0,      # Driving straight
	"reese_jungle": 0.0,         # Breakbeat precision at speed
	"midnight_metroplex": 6.0,   # Jazz-tinged Detroit groove
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
	"dub_house": {
		"base": 0.7,       # Softer base - dub house breathes
		"accent": 0.9,     # Even accents are restrained
		"ghost": 0.25,     # Ghosts are felt, not heard (Basic Channel subtlety)
		"variation": 0.08, # Less variation = more hypnotic repetition
	},
	"vangelis_cs80": {
		"base": 0.7,       # Cinematic dynamics
		"accent": 0.95,    # Expressive but controlled
		"ghost": 0.3,
		"variation": 0.12, # Slight human expression
	},
	"nineties_rnb": {
		"base": 0.65,      # Soft, silky smooth
		"accent": 0.9,     # Expressive but controlled
		"ghost": 0.3,      # Subtle ghost notes (felt, not heard)
		"variation": 0.13, # Human feel — Teddy Riley pocket
	},
	"chromatic_story": {
		"base": 0.65,      # Moderate - room for dynamics
		"accent": 0.85,    # Expressive but not harsh
		"ghost": 0.3,      # Audible ghost notes (jazz feel)
		"variation": 0.12, # Human variation - not machine
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
	"k_bass": {
		"base": 0.85,      # Strong, physical
		"accent": 1.0,     # Impact moments hit HARD
		"ghost": 0.4,      # Audible ghosts in break patterns
		"variation": 0.08, # Tight but not robotic
	},
	"dark_wave": {
		"base": 0.75,      # Driving but controlled
		"accent": 1.0,     # Kick accents hit hard
		"ghost": 0.35,     # Ghost hihats felt not heard
		"variation": 0.06, # Tight, ritualistic repetition
	},
	"acid_house": {
		"base": 0.85,      # Driving, raw
		"accent": 1.0,     # 303 accents hit hard
		"ghost": 0.5,
		"variation": 0.05, # Machine tight
	},
	"acid_techno_303": {
		"base": 0.95,      # Loud, relentless
		"accent": 1.0,     # Everything hits
		"ghost": 0.6,
		"variation": 0.02, # Very tight machine
	},
	"french_touch": {
		"base": 0.85,      # Filtered disco energy
		"accent": 1.0,     # Stab accents
		"ghost": 0.45,
		"variation": 0.08, # Groovy but tight
	},
	"ambient_techno": {
		"base": 0.5,       # Very soft, spacious
		"accent": 0.7,     # Even accents are restrained
		"ghost": 0.2,      # Whisper
		"variation": 0.1,  # Slight drift
	},
	"lofi_house": {
		"base": 0.7,       # Warm, dusty
		"accent": 0.85,    # Not too punchy
		"ghost": 0.35,
		"variation": 0.15, # Lo-fi wobble
	},
	"supersaw_trance": {
		"base": 0.9,       # Big, anthemic
		"accent": 1.0,     # Full power
		"ghost": 0.5,
		"variation": 0.05, # Driving precision
	},
	"reese_jungle": {
		"base": 0.85,      # Dark, heavy
		"accent": 1.0,     # Breaks hit hard
		"ghost": 0.4,      # Ghost notes in breaks
		"variation": 0.1,  # Break feel
	},
	"midnight_metroplex": {
		"base": 0.7,       # Understated, jazz feel
		"accent": 0.9,     # Expressive but controlled
		"ghost": 0.3,      # Subtle ghosts
		"variation": 0.12, # Human, expressive
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
	"dub_house": {
		"sections": ["intro", "build", "main", "breakdown", "drop", "main", "outro"],
		"bars": [8, 8, 16, 8, 16, 8, 4],
	},
	"vangelis_cs80": {
		"sections": ["intro", "build", "main", "breakdown", "climax", "outro"],
		"bars": [8, 8, 16, 8, 16, 8],
	},
	# 90s R&B: Classic verse-chorus-bridge structure
	"nineties_rnb": {
		"sections": ["intro", "verse1", "prechorus1", "chorus1", "bridge", "outro"],
		"bars": [8, 16, 8, 16, 8, 8],
	},
	# Chromatic Story: 8-section emotional journey (Am → C)
	"chromatic_story": {
		"sections": ["uncertainty", "searching", "darkness", "hope", "jazz", "breakthrough", "resolution", "celebration"],
		"bars": [8, 8, 8, 8, 16, 8, 8, 8],
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
	# K-Bass: Drop-based structure — tension, release, switch-ups
	"k_bass": {
		"sections": ["intro", "build", "drop1", "breakdown", "drop2", "switchup", "outro"],
		"bars": [8, 8, 16, 8, 16, 8, 4],
	},
	# Dark Wave Cathedral: Ritual build → peak → tribal descent → rebuild → fade
	"dark_wave": {
		"sections": ["intro", "build", "verse", "chorus", "verse_2", "chorus_2", "breakdown", "build_2", "chorus_3", "outro"],
		"bars": [8, 8, 16, 8, 16, 8, 8, 4, 16, 8],
	},
	# Acid House: Build → acid drops
	"acid_house": {
		"sections": ["intro", "build", "drop", "breakdown", "drop", "outro"],
		"bars": [4, 8, 16, 8, 16, 4],
	},
	# Acid Techno 303: Relentless, minimal structure
	"acid_techno_303": {
		"sections": ["intro", "build", "main", "breakdown", "main", "outro"],
		"bars": [4, 8, 16, 4, 16, 4],
	},
	# French Touch: Disco-influenced with filter sweeps
	"french_touch": {
		"sections": ["intro", "build", "main", "breakdown", "drop", "main", "outro"],
		"bars": [4, 8, 16, 8, 16, 8, 4],
	},
	# Ambient Techno: Long, sparse sections
	"ambient_techno": {
		"sections": ["intro", "build", "main", "breakdown", "main", "outro"],
		"bars": [8, 8, 16, 8, 16, 8],
	},
	# Lo-fi House: Warm, sample-based loops
	"lofi_house": {
		"sections": ["intro", "build", "main", "breakdown", "drop", "outro"],
		"bars": [4, 8, 16, 8, 16, 4],
	},
	# Supersaw Trance: Anthemic build-drop structure
	"supersaw_trance": {
		"sections": ["intro", "build", "main", "breakdown", "climax", "outro"],
		"bars": [8, 16, 16, 8, 16, 8],
	},
	# Reese Jungle: Breakbeat, drop-heavy
	"reese_jungle": {
		"sections": ["intro", "build", "drop1", "breakdown", "drop2", "outro"],
		"bars": [8, 8, 16, 8, 16, 4],
	},
	# Midnight Metroplex: Jazz-tinged Detroit, contemplative
	"midnight_metroplex": {
		"sections": ["intro", "build", "main", "breakdown", "main", "outro"],
		"bars": [8, 8, 16, 8, 16, 8],
	},
}


static func _merge_with_song_research_parameters(default_song_id: String, runtime_parameters: Dictionary) -> Dictionary:
	var requested_song_id = str(runtime_parameters.get("song_id", default_song_id)).strip_edges()
	if requested_song_id.is_empty():
		requested_song_id = default_song_id
	
	var merged = _load_song_research_defaults(default_song_id)
	if requested_song_id != default_song_id:
		var requested_defaults = _load_song_research_defaults(requested_song_id)
		for key in requested_defaults.keys():
			merged[key] = requested_defaults[key]
	for key in runtime_parameters.keys():
		merged[key] = runtime_parameters[key]
	
	merged["song_id"] = requested_song_id
	
	if not merged.has("progression_name"):
		var progression_data = merged.get("chord_progressions", null)
		if progression_data is Array and progression_data.size() > 0 and progression_data[0] is Dictionary:
			merged["progression_name"] = str(progression_data[0].get("name", ""))
	
	return merged


static func _load_song_research_defaults(song_id: String) -> Dictionary:
	var alias_map = {
		"aphex_twin": "aphex_twin_digital_amber",
	}
	var lookup_song_id = alias_map.get(song_id, song_id)
	var config_path = "res://commons/audio/parameters/songs/%s.json" % lookup_song_id
	if not FileAccess.file_exists(config_path):
		return {"song_id": song_id}
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return {"song_id": song_id}
	
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"song_id": song_id}
	
	var config: Dictionary = parsed
	var defaults: Dictionary = {"song_id": song_id}
	
	var config_params = config.get("parameters", {})
	if config_params is Dictionary:
		for param_name in config_params.keys():
			var param_info = config_params[param_name]
			if param_info is Dictionary:
				if param_info.has("value"):
					defaults[param_name] = param_info["value"]
				elif param_info.has("default"):
					defaults[param_name] = param_info["default"]
	
	if config.has("arrangement") and config["arrangement"] is Dictionary:
		var arrangement: Dictionary = config["arrangement"]
		defaults["arrangement"] = arrangement
		defaults["carry_layers"] = bool(arrangement.get("carry_layers", true))
		
		var variation_hint = str(arrangement.get("variation", "")).to_lower()
		if arrangement.has("enable_motif_variation"):
			defaults["enable_motif_variation"] = bool(arrangement["enable_motif_variation"])
		elif arrangement.has("motif_variation"):
			defaults["enable_motif_variation"] = bool(arrangement["motif_variation"])
		elif not variation_hint.is_empty():
			defaults["enable_motif_variation"] = not (variation_hint in ["none", "off", "false", "minimal"])
		
		if arrangement.has("motif_variation_amount"):
			defaults["motif_variation_amount"] = float(arrangement["motif_variation_amount"])
		elif variation_hint == "minimal":
			defaults["motif_variation_amount"] = 0.2
		elif variation_hint == "medium":
			defaults["motif_variation_amount"] = 0.45
		elif variation_hint == "high":
			defaults["motif_variation_amount"] = 0.75
	
	if config.has("chord_progressions"):
		defaults["chord_progressions"] = config["chord_progressions"]
	
	var rhythm = config.get("rhythm", null)
	if rhythm is Dictionary:
		if rhythm.has("humanize_ms"):
			defaults["humanize_ms"] = float(rhythm["humanize_ms"])
		if rhythm.has("swing_pct"):
			defaults["swing_pct"] = float(rhythm["swing_pct"])
	
	return defaults


static func generate_song(genre_id: String, parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters(genre_id, parameters)
	var bank = SoundbankLoader.load_genre(genre_id)
	if bank.get_available_sounds().is_empty():
		push_error("SoundbankGenerator: No sounds loaded for " + genre_id)
		return null
	
	var brief = bank.get_brief()
	var bpm = parameters.get("bpm", bank.get_bpm())
	var bar_duration = 240.0 / bpm
	var humanize_ms = float(parameters.get("humanize_ms", brief.get("rhythm", {}).get("humanize_ms", 0)))
	var swing_pct = float(parameters.get("swing_pct", SWING.get(genre_id, 0.0)))
	var velocity_cfg = VELOCITY.get(genre_id, VELOCITY["detroit_techno"])
	var carry_layers_enabled = bool(parameters.get("carry_layers", true))
	var carry_layer_names = parameters.get("carry_layer_names", [])
	var enable_motif_variation = bool(parameters.get("enable_motif_variation", false))
	var motif_variation_amount = clampf(float(parameters.get("motif_variation_amount", 0.25)), 0.0, 1.0)
	
	randomize()
	var key_value = str(parameters.get("key", ""))
	var root_note = _key_to_root_note(key_value)
	if root_note.is_empty():
		root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	
	# Choose scale based on genre character
	var scale: Array
	if not key_value.is_empty():
		scale = PopMusicTheory.get_minor_scale_notes(root_note) if _is_minor_key(key_value) else PopMusicTheory.get_major_scale_notes(root_note)
	elif genre_id in ["madonna_80s", "gypsy_woman_house", "ada_theme"]:
		scale = PopMusicTheory.get_major_scale_notes(root_note)
	else:
		scale = PopMusicTheory.get_minor_scale_notes(root_note)
	
	var progression = _resolve_progression_from_parameters(genre_id, parameters, scale)
	
	print("SoundbankGenerator: Generating %s in %s at %s BPM (swing: %s%%)" % [genre_id, root_note, bpm, swing_pct])
	
	var structure = STRUCTURES.get(genre_id, STRUCTURES["detroit_techno"])
	var arrangement_plan = _resolve_arrangement_plan(structure, parameters.get("arrangement", {}), bank.get_available_sounds())
	var section_names = arrangement_plan.get("sections", structure["sections"])
	var section_bars = arrangement_plan.get("bars", structure["bars"])
	var section_sound_overrides = arrangement_plan.get("section_sounds", {})
	var genre_patterns = PATTERNS.get(genre_id, {})
	var carry_pool: Array = []
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = section_names.size()
	playback.initial_clip = 0
	
	for i in range(section_names.size()):
		var section_name = section_names[i]
		var num_bars = section_bars[i]
		var section_sounds = section_sound_overrides.get(section_name, [])
		if section_sounds.is_empty():
			section_sounds = bank.get_section_sounds(section_name)
		if section_sounds.is_empty():
			section_sounds = bank.get_available_sounds()
		section_sounds = _dedupe_sounds(section_sounds)
		
		if carry_layers_enabled and not carry_pool.is_empty():
			section_sounds = _merge_unique_sounds(section_sounds, carry_pool)
		
		print("  Section '%s' (%d bars): %s" % [section_name, num_bars, ", ".join(section_sounds)])
		
		var stream = _generate_section(bank, genre_id, section_sounds, progression, 
										scale, bar_duration, bpm, num_bars, 
										humanize_ms, swing_pct, velocity_cfg,
										section_name, enable_motif_variation, motif_variation_amount)
		playback.set_clip_stream(i, stream)
		playback.set_clip_name(i, section_name.capitalize())
		
		playback.set_clip_auto_advance(i, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
		var next_clip = (i + 1) % section_names.size()
		playback.set_clip_auto_advance_next_clip(i, next_clip)
		
		if carry_layers_enabled:
			carry_pool = _extract_carry_layers(section_sounds, carry_layer_names, genre_patterns)
	
	var xfade_val = arrangement_plan.get("crossfade_s", brief.get("transitions", {}).get("crossfade_s", 2.0))
	var xfade: float = float(xfade_val) if not xfade_val is Dictionary else 2.0
	for i in range(section_names.size()):
		var next = (i + 1) % section_names.size()
		playback.add_transition(i, next,
			AudioStreamInteractive.TRANSITION_FROM_TIME_END,
			AudioStreamInteractive.TRANSITION_TO_TIME_START,
			AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _resolve_arrangement_plan(base_structure: Dictionary, arrangement_data, available_sounds: Array) -> Dictionary:
	var plan = {
		"sections": base_structure.get("sections", []).duplicate(),
		"bars": base_structure.get("bars", []).duplicate(),
		"section_sounds": {},
	}
	
	if not arrangement_data is Dictionary:
		return plan
	
	var arrangement: Dictionary = arrangement_data
	var default_bars = int(arrangement.get("loop_length_bars", 8))
	var parsed_sections: Array = []
	var parsed_bars: Array = []
	var section_sound_overrides: Dictionary = {}
	
	if arrangement.has("sections"):
		var section_data = arrangement["sections"]
		if section_data is Array:
			if section_data.size() > 0 and section_data[0] is Dictionary:
				for section_info in section_data:
					var section_name = str(section_info.get("name", "")).strip_edges().to_lower()
					if section_name.is_empty():
						continue
					parsed_sections.append(section_name)
					var bars = int(section_info.get("bars", section_info.get("length_bars", default_bars)))
					parsed_bars.append(maxi(1, bars))
					var raw_elements = section_info.get("elements", section_info.get("instruments", []))
					var resolved_elements = _resolve_arrangement_elements(raw_elements, available_sounds)
					if not resolved_elements.is_empty():
						section_sound_overrides[section_name] = resolved_elements
			else:
				for section_name_variant in section_data:
					var section_name = str(section_name_variant).strip_edges().to_lower()
					if section_name.is_empty():
						continue
					parsed_sections.append(section_name)
					parsed_bars.append(_default_section_bar_count(plan["sections"], plan["bars"], section_name, default_bars))
		elif section_data is Dictionary:
			var section_dict: Dictionary = section_data
			for section_key in section_dict.keys():
				var section_name = str(section_key).strip_edges().to_lower()
				if section_name.is_empty():
					continue
				parsed_sections.append(section_name)
				var section_info = section_dict[section_key]
				var bars = default_bars
				if section_info is Dictionary:
					bars = int(section_info.get("bars", section_info.get("length_bars", default_bars)))
					var raw_elements = section_info.get("elements", section_info.get("instruments", []))
					var resolved_elements = _resolve_arrangement_elements(raw_elements, available_sounds)
					if not resolved_elements.is_empty():
						section_sound_overrides[section_name] = resolved_elements
				parsed_bars.append(maxi(1, bars))
	
	if not parsed_sections.is_empty() and parsed_sections.size() == parsed_bars.size():
		plan["sections"] = parsed_sections
		plan["bars"] = parsed_bars
	
	plan["section_sounds"] = section_sound_overrides
	if arrangement.has("transitions"):
		var transitions = arrangement["transitions"]
		if transitions is Dictionary and transitions.has("crossfade_s"):
			plan["crossfade_s"] = float(transitions["crossfade_s"])
	if arrangement.has("crossfade_s"):
		plan["crossfade_s"] = float(arrangement["crossfade_s"])
	
	return plan


static func _resolve_arrangement_elements(raw_elements, available_sounds: Array) -> Array:
	var resolved: Array = []
	if not raw_elements is Array:
		return resolved
	
	for item in raw_elements:
		var token = str(item).strip_edges().to_lower()
		if token.is_empty():
			continue
		if token == "all":
			return available_sounds.duplicate()
		var sound_name = _resolve_sound_name(token, available_sounds)
		if not sound_name.is_empty() and not resolved.has(sound_name):
			resolved.append(sound_name)
	
	return resolved


static func _resolve_sound_name(token: String, available_sounds: Array) -> String:
	for sound_name in available_sounds:
		if str(sound_name).to_lower() == token:
			return sound_name
	
	var parts = token.split("_")
	if not parts.is_empty():
		var first_token = parts[0]
		for sound_name in available_sounds:
			if str(sound_name).to_lower() == first_token:
				return sound_name
	
	for sound_name in available_sounds:
		var lowered = str(sound_name).to_lower()
		if token.begins_with(lowered) or token.find(lowered) != -1:
			return sound_name
	
	return ""


static func _default_section_bar_count(base_sections: Array, base_bars: Array, section_name: String, fallback_bars: int) -> int:
	var idx = base_sections.find(section_name)
	if idx >= 0 and idx < base_bars.size():
		return int(base_bars[idx])
	return maxi(1, fallback_bars)


static func _dedupe_sounds(sounds: Array) -> Array:
	var deduped: Array = []
	for sound_name in sounds:
		if not deduped.has(sound_name):
			deduped.append(sound_name)
	return deduped


static func _merge_unique_sounds(primary: Array, additions: Array) -> Array:
	var merged = _dedupe_sounds(primary)
	for sound_name in additions:
		if not merged.has(sound_name):
			merged.append(sound_name)
	return merged


static func _extract_carry_layers(sounds: Array, requested_layers: Array, patterns: Dictionary) -> Array:
	var carry: Array = []
	for sound_name in sounds:
		if _should_carry_sound(str(sound_name), requested_layers, patterns):
			carry.append(sound_name)
	if carry.size() > 4:
		carry = carry.slice(0, 4)
	return carry


static func _should_carry_sound(sound_name: String, requested_layers: Array, patterns: Dictionary) -> bool:
	if not requested_layers.is_empty():
		return requested_layers.has(sound_name)
	
	if patterns.has(sound_name):
		return false
	
	var lowered = sound_name.to_lower()
	if lowered in ["bass", "sub", "hoover", "kick", "snare", "clap", "hihat", "rimshot", "shaker", "tambourine", "perc", "fingersnap", "break"]:
		return false
	
	var carry_tokens = ["pad", "atmosphere", "texture", "crackle", "string", "choir", "siren", "vocal", "drone", "noise"]
	for token in carry_tokens:
		if lowered.find(token) != -1:
			return true
	
	return false


static func _key_to_root_note(key_value: String) -> String:
	if key_value.is_empty():
		return ""
	var root = _extract_chord_root(key_value)
	if root.is_empty():
		return ""
	return root + "3"


static func _is_minor_key(key_value: String) -> bool:
	var lowered = key_value.to_lower()
	if lowered.find("maj") != -1:
		return false
	return lowered.ends_with("m") or lowered.find(" minor") != -1


static func _resolve_progression_from_parameters(genre_id: String, parameters: Dictionary, scale: Array) -> Array:
	var fallback = _get_genre_progression(genre_id)
	var progression_data = parameters.get("chord_progressions", null)
	if progression_data == null:
		return fallback
	
	var progression_name = str(parameters.get("progression_name", ""))
	var chords = _extract_chords_from_progressions(progression_data, progression_name)
	var degrees = _chords_to_degrees(chords, scale)
	return fallback if degrees.is_empty() else degrees


static func _extract_chords_from_progressions(progressions, preferred_name: String) -> Array:
	var target_name = preferred_name.to_lower()
	
	if progressions is Array:
		if progressions.is_empty():
			return []
		if progressions[0] is Dictionary:
			var fallback: Array = []
			for progression in progressions:
				var progression_name = str(progression.get("name", "")).to_lower()
				var chords = progression.get("chords", [])
				if fallback.is_empty() and chords is Array:
					fallback = _expand_progression_chords(chords, progression)
				if not target_name.is_empty() and progression_name == target_name and chords is Array:
					return _expand_progression_chords(chords, progression)
			return fallback
		return progressions
	
	if progressions is Dictionary:
		if progressions.has("chords") and progressions["chords"] is Array:
			return _expand_progression_chords(progressions["chords"], progressions)
		for key in progressions.keys():
			var value = progressions[key]
			if value is Dictionary and value.has("chords") and value["chords"] is Array:
				if target_name.is_empty() or str(key).to_lower() == target_name or str(value.get("name", "")).to_lower() == target_name:
					return _expand_progression_chords(value["chords"], value)
	
	return []


static func _expand_progression_chords(chords: Array, progression_info: Dictionary) -> Array:
	var bars_per_chord = maxi(1, int(progression_info.get("bars_per_chord", 1)))
	if bars_per_chord <= 1:
		return chords
	
	var expanded: Array = []
	for chord in chords:
		for _repeat_idx in range(bars_per_chord):
			expanded.append(chord)
	return expanded


static func _chords_to_degrees(chords: Array, scale: Array) -> Array:
	var degrees: Array = []
	for chord_value in chords:
		var chord_name = str(chord_value).strip_edges()
		if chord_name.is_empty():
			continue
		var degree = _roman_to_degree(chord_name)
		if degree == -1:
			var root = _extract_chord_root(chord_name)
			if root.is_empty():
				continue
			degree = _find_scale_degree(root, scale)
		if degree >= 0:
			degrees.append(degree)
	return degrees


static func _roman_to_degree(symbol: String) -> int:
	var core = symbol.strip_edges()
	if core.is_empty():
		return -1
	
	while core.begins_with("b") or core.begins_with("#"):
		core = core.substr(1)
	
	var roman = ""
	for i in range(core.length()):
		var ch = core[i]
		if ch in ["I", "V", "i", "v"]:
			roman += ch
		else:
			break
	
	match roman.to_upper():
		"I":
			return 0
		"II":
			return 1
		"III":
			return 2
		"IV":
			return 3
		"V":
			return 4
		"VI":
			return 5
		"VII":
			return 6
		_:
			return -1


static func _extract_chord_root(chord_name: String) -> String:
	var token = chord_name.strip_edges()
	if token.is_empty():
		return ""
	
	var slash_idx = token.find("/")
	if slash_idx != -1:
		token = token.substr(0, slash_idx)
	
	var first = token[0].to_upper()
	if not first in ["A", "B", "C", "D", "E", "F", "G"]:
		return ""
	
	var root = first
	if token.length() > 1:
		var accidental = token[1]
		if accidental == "#" or accidental == "b":
			root += accidental
	
	return _normalize_note_name(root)


static func _normalize_note_name(note_name: String) -> String:
	var flat_map = {
		"Db": "C#",
		"Eb": "D#",
		"Gb": "F#",
		"Ab": "G#",
		"Bb": "A#",
		"Cb": "B",
		"Fb": "E",
	}
	return flat_map.get(note_name, note_name)


static func _find_scale_degree(root_note: String, scale: Array) -> int:
	for i in range(scale.size()):
		var note = str(scale[i])
		if note.is_empty():
			continue
		var octave_idx = note.length() - 1
		var scale_root = note.substr(0, octave_idx)
		if scale_root == root_note:
			return i
	
	var root_idx = PopMusicTheory.NOTES.find(root_note)
	if root_idx == -1:
		return -1
	
	var best_idx = -1
	var best_dist = 99
	for i in range(scale.size()):
		var note = str(scale[i])
		if note.is_empty():
			continue
		var octave_idx = note.length() - 1
		var scale_root = note.substr(0, octave_idx)
		var scale_idx = PopMusicTheory.NOTES.find(scale_root)
		if scale_idx == -1:
			continue
		var dist = abs(scale_idx - root_idx)
		dist = mini(dist, 12 - dist)
		if dist < best_dist:
			best_dist = dist
			best_idx = i
	
	return best_idx


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
	parameters = _merge_with_song_research_parameters(hybrid_id, parameters)
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
	var swing_pct = float(parameters.get("swing_pct", SWING.get(hybrid_id, 0.0)))
	var velocity_cfg = VELOCITY.get(hybrid_id, VELOCITY["detroit_techno"])
	var carry_layers_enabled = bool(parameters.get("carry_layers", true))
	var carry_layer_names = parameters.get("carry_layer_names", [])
	var enable_motif_variation = bool(parameters.get("enable_motif_variation", false))
	var motif_variation_amount = clampf(float(parameters.get("motif_variation_amount", 0.25)), 0.0, 1.0)
	
	randomize()
	var key_value = str(parameters.get("key", ""))
	var root_note = _key_to_root_note(key_value)
	if root_note.is_empty():
		root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note) if key_value.is_empty() or _is_minor_key(key_value) else PopMusicTheory.get_major_scale_notes(root_note)
	var progression = _resolve_progression_from_parameters(hybrid_id, parameters, scale)
	
	print("SoundbankGenerator: Generating hybrid '%s' (%s × %s) in %s at %s BPM" % [
		hybrid_id, config.primary_bank, config.secondary_bank, root_note, bpm
	])
	
	var structure = STRUCTURES.get(hybrid_id, STRUCTURES["detroit_techno"])
	var arrangement_plan = _resolve_arrangement_plan(structure, parameters.get("arrangement", {}), config.sound_sources.keys())
	var section_names = arrangement_plan.get("sections", structure["sections"])
	var section_bars = arrangement_plan.get("bars", structure["bars"])
	var section_sound_overrides = arrangement_plan.get("section_sounds", {})
	var hybrid_patterns = PATTERNS.get(hybrid_id, {})
	var carry_pool: Array = []
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = section_names.size()
	playback.initial_clip = 0
	
	for i in range(section_names.size()):
		var section_name = section_names[i]
		var num_bars = section_bars[i]
		var section_sounds = section_sound_overrides.get(section_name, config.section_sounds.get(section_name, []))
		section_sounds = _dedupe_sounds(section_sounds)
		if carry_layers_enabled and not carry_pool.is_empty():
			section_sounds = _merge_unique_sounds(section_sounds, carry_pool)
		
		print("  Section '%s' (%d bars): %s" % [section_name, num_bars, ", ".join(section_sounds)])
		
		var stream = _generate_hybrid_section(
			primary_bank, secondary_bank, config,
			hybrid_id, section_sounds, progression,
			scale, bar_duration, bpm, num_bars,
			swing_pct, velocity_cfg,
			section_name, enable_motif_variation, motif_variation_amount
		)
		playback.set_clip_stream(i, stream)
		playback.set_clip_name(i, section_name.capitalize())
		
		playback.set_clip_auto_advance(i, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
		var next_clip = (i + 1) % section_names.size()
		playback.set_clip_auto_advance_next_clip(i, next_clip)
		
		if carry_layers_enabled:
			carry_pool = _extract_carry_layers(section_sounds, carry_layer_names, hybrid_patterns)
	
	# Add crossfades
	var xfade = float(arrangement_plan.get("crossfade_s", 2.0))
	for i in range(section_names.size()):
		var next = (i + 1) % section_names.size()
		playback.add_transition(i, next,
			AudioStreamInteractive.TRANSITION_FROM_TIME_END,
			AudioStreamInteractive.TRANSITION_TO_TIME_START,
			AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _generate_hybrid_section(
	primary_bank: SoundbankLoader, secondary_bank: SoundbankLoader,
	config: Dictionary, hybrid_id: String, sounds: Array,
	progression: Array, scale: Array,
	bar_duration: float, bpm: float, num_bars: int,
	swing_pct: float, velocity_cfg: Dictionary,
	section_name: String = "", enable_motif_variation: bool = false,
	motif_variation_amount: float = 0.25
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
		var motif_degree = _resolve_motif_degree(degree, bar, num_bars, enable_motif_variation, motif_variation_amount)
		var motif_chord_freqs = PopMusicTheory.get_chord_frequencies(scale, motif_degree)
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
			
			if sound_name == "siren":
				if bar == 0:
					_add_continuous_sound(final_mix, script, 0,
						total_samples, sound_name, root_freq, chord_freqs, velocity_cfg,
						0.0, total_duration)
				continue
			
			# Drums and melodic patterns (use hybrid patterns)
			if patterns.has(sound_name):
				var hit_chords = motif_chord_freqs if _is_hook_sound(sound_name) else chord_freqs
				var bar_pattern = _get_bar_pattern(patterns[sound_name], sound_name, bar, section_name, enable_motif_variation, motif_variation_amount)
				_add_pattern_sound(final_mix, script, bar_start, bar_pattern,
								   step_samples, sound_name, 0.0, swing_pct,
								   velocity_cfg, hit_chords, hybrid_id, bar)
			# Bass with its own pattern
			elif sound_name in ["bass", "sub", "hoover"]:
				_add_bass_pattern(final_mix, script, bar_start, bass_cfg,
								  step_samples, root_freq, velocity_cfg, bar_duration)
			# Continuous sounds (pads, atmosphere, etc.)
			else:
				_add_continuous_sound(final_mix, script, bar_start,
									  int(bar_duration * SAMPLE_RATE),
									  sound_name, root_freq, chord_freqs, velocity_cfg,
									  bar * bar_duration, total_duration)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.02))
	return _create_audio_stream(final_mix)


static func _get_genre_progression(genre_id: String) -> Array:
	match genre_id:
		"moroder_disco":
			return [0, 0, 0, 0]  # SINGLE CHORD - pure hypnosis (I Feel Love style)
		"detroit_techno":
			return [0, 5, 3, 4]  # i - VI - iv - V (classic Detroit)
		"synthwave":
			return [0, 3, 5, 4]  # i - iv - vi - V (cinematic 80s)
		"burial":
			return [0, 5, 0, 3]  # i - VI - i - iv (sparse, South London)
		"boards_of_canada", "boards_of_canada_v2":
			return [0, 2, 5, 0]  # I - iii - vi - I (nostalgic, childlike)
		"rave":
			return [0, 0, 5, 5]  # i - i - VI - VI (aggressive, simple)
		"kraftwerk", "kraftwerk_v2":
			return [0, 4, 0, 4]  # i - V - i - V (robotic oscillation)
		"madonna_80s":
			return [0, 5, 3, 4]  # I - vi - IV - V (classic pop, MAJOR!)
		"gypsy_woman_house":
			return [0, 3, 4, 0]  # I - IV - V - I (uplifting house, MAJOR!)
		"dub_house":
			return [0, 3, 0, 3]  # i - iv - i - iv (minimal movement)
		"vangelis_cs80":
			return [0, 3, 5, 4]  # i - iv - vi - V (cinematic minor drama)
		"nineties_rnb":
			return [0, 3, 6, 2]  # Dm → Gm → C → F (i-iv-bVII-bIII, Guy style)
		"chromatic_story":
			return [0, 3, 4, 2]  # Am → F → G → Dm (chromatic journey)
		"replicants_dawn":
			return [0, 5, 3, 4]  # Dm - Bb - Gm - A (cinematic minor)
		"foggy_frequencies":
			return [0, 5, 6, 3]  # Fm - Ab - Eb - Db (descending, melancholic)
		"chicago_dusseldorf":
			return [0, 3, 4, 0]  # Am - Dm - G - C (soulful then robotic)
		# === Added: genres that were falling through to default ===
		"acid_house":
			return [0, 0, 0, 0]  # Single chord hypnosis (Phuture style, let the 303 do the work)
		"acid_techno_303":
			return [0, 0, 5, 0]  # i - i - VI - i (minimal movement, 303 carries it)
		"ambient_techno":
			return [0, 6, 3, 5]  # i - VII - iv - VI (slow drift, Basic Channel)
		"ambient_works":
			return [0, 5, 2, 4]  # i - VI - iii - V (melancholic descent, SAW-era)
		"french_touch":
			return [0, 4, 2, 5]  # i - V - iii - VI (funky, filtered disco)
		"k_bass":
			return [0, 0, 3, 0]  # i - i - iv - i (sub-led, minimal - let the reese speak)
		"midnight_metroplex":
			return [0, 4, 3, 6]  # i - V - iv - VII (Drexciya noir, jazz-tinged)
		"lofi_house":
			return [0, 3, 5, 3]  # i - iv - vi - iv (warm, dusty loop)
		"supersaw_trance":
			return [0, 5, 3, 4]  # i - VI - iv - V (anthemic, uplifting)
		"reese_jungle":
			return [0, 4, 3, 6]  # i - V - iv - VII (rolling, dark)
		"pop_generative", "pop_v2":
			return [0, 3, 4, 5]  # I - IV - V - vi (bright pop)
		"pop_madonna":
			return [0, 5, 3, 4]  # I - vi - IV - V (classic 80s pop)
		"prog_synth_70s", "prog_synth_v2":
			return [0, 2, 4, 6]  # i - iii - V - VII (modal exploration)
		"blade_runner":
			return [0, 3, 5, 4]  # i - iv - vi - V (Vangelis noir)
		"dark_wave_cathedral":
			return [0, 4, 5, 4]  # i - V - VI - V (gothic oscillation)
		"aphex_twin_digital_amber":
			return [0, 5, 2, 4]  # i - VI - iii - V (complex, melancholic)
		"ada_theme":
			return [0, 3, 4, 5]  # I - IV - V - vi (warm, hopeful)
		"kpop_prog_remix":
			return [0, 4, 5, 3]  # i - V - VI - iv (K-pop drama + prog complexity)
		"burial_v2":
			return [0, 3, 0, 5]  # i - iv - i - VI (ghost dub variation)
		_:
			push_warning("SoundbankGenerator: No progression defined for '%s' — using genre-hashed fallback. Add an entry to _get_genre_progression()." % genre_id)
			# Hash the genre name to pick a semi-random but consistent progression
			# so unknown genres at least don't ALL sound identical
			var h = genre_id.hash()
			var options = [
				[0, 3, 5, 4],  # i - iv - vi - V
				[0, 5, 3, 6],  # i - VI - iv - VII
				[0, 4, 0, 3],  # i - V - i - iv
				[0, 6, 3, 5],  # i - VII - iv - VI
				[0, 3, 6, 4],  # i - iv - VII - V
			]
			return options[absi(h) % options.size()]


static func _generate_section(bank: SoundbankLoader, genre_id: String, sounds: Array, 
							   progression: Array, scale: Array, 
							   bar_duration: float, bpm: float, num_bars: int,
							   humanize_ms: float, swing_pct: float,
							   velocity_cfg: Dictionary, section_name: String = "",
							   enable_motif_variation: bool = false,
							   motif_variation_amount: float = 0.25) -> AudioStreamWAV:
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
		var motif_degree = _resolve_motif_degree(degree, bar, num_bars, enable_motif_variation, motif_variation_amount)
		var motif_chord_freqs = PopMusicTheory.get_chord_frequencies(scale, motif_degree)
		var root_freq = chord_freqs[0] if chord_freqs.size() > 0 else 220.0
		
		for sound_name in sounds:
			if not bank.has_sound(sound_name):
				continue
			
			var script = bank.get_sound_script(sound_name)
			if script == null:
				continue
			
			if sound_name == "siren":
				if bar == 0:
					_add_continuous_sound(final_mix, script, 0,
						total_samples, sound_name, root_freq, chord_freqs, velocity_cfg,
						0.0, total_duration)
				continue
			
			# Drums and melodic patterns
			if patterns.has(sound_name):
				var hit_chords = motif_chord_freqs if _is_hook_sound(sound_name) else chord_freqs
				var bar_pattern = _get_bar_pattern(patterns[sound_name], sound_name, bar, section_name, enable_motif_variation, motif_variation_amount)
				_add_pattern_sound(final_mix, script, bar_start, bar_pattern, 
								   step_samples, sound_name, humanize_ms, swing_pct,
								   velocity_cfg, hit_chords, genre_id, bar)
			# Bass with its own pattern
			elif sound_name in ["bass", "sub", "hoover"]:
				_add_bass_pattern(final_mix, script, bar_start, bass_cfg,
								  step_samples, root_freq, velocity_cfg, bar_duration)
			# Continuous sounds
			else:
				_add_continuous_sound(final_mix, script, bar_start, 
									  int(bar_duration * SAMPLE_RATE), 
									  sound_name, root_freq, chord_freqs, velocity_cfg,
									  bar * bar_duration, total_duration)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.02))
	return _create_audio_stream(final_mix)


static func _resolve_motif_degree(base_degree: int, bar_index: int, num_bars: int, enabled: bool, amount: float) -> int:
	if not enabled or amount <= 0.0:
		return base_degree
	if randf() > amount:
		return base_degree
	
	var phrase_pos = bar_index % 8
	if phrase_pos == 7:
		return (base_degree + 4) % 7
	if phrase_pos == 3 or phrase_pos == 6:
		return (base_degree + 2) % 7
	if bar_index == num_bars - 1:
		return (base_degree + 5) % 7
	return base_degree


static func _is_hook_sound(sound_name: String) -> bool:
	return sound_name in ["stab", "arp", "sequence", "sequencer", "jupiter_arp", "singing_voice", "vocoder", "lead", "piano", "organ", "rhodes"]


static func _get_bar_pattern(base_pattern: Array, sound_name: String, bar_index: int, section_name: String, enabled: bool, amount: float) -> Array:
	if not enabled or amount <= 0.0:
		return base_pattern
	
	var pattern = base_pattern.duplicate()
	var lowered = sound_name.to_lower()
	
	if lowered in ["hihat", "shaker", "tambourine"] and randf() < amount * 0.4 and bar_index % 8 == 7:
		if pattern.size() > 14:
			pattern[14] = maxi(float(pattern[14]), 0.5)
		if pattern.size() > 15:
			pattern[15] = maxi(float(pattern[15]), 0.5)
	
	if _is_hook_sound(sound_name) and randf() < amount * 0.5:
		var add_step = 6 if bar_index % 2 == 0 else 10
		if add_step < pattern.size():
			pattern[add_step] = maxi(float(pattern[add_step]), 1.0)
			if section_name.to_lower().find("break") != -1:
				pattern[add_step] = mini(float(pattern[add_step]), 0.6)
	
	return pattern


static func _add_pattern_sound(mix: PackedFloat32Array, script, bar_start: int, 
								pattern: Array, step_samples: int, sound_name: String,
								humanize_ms: float, swing_pct: float,
								velocity_cfg: Dictionary, chord_freqs: Array,
								genre_id: String = "", bar_index: int = 0) -> void:
	# For hook sounds, get genre-specific arp/melody pattern to cycle through chord tones
	var is_hook = _is_hook_sound(sound_name)
	var arp_indices: Array = []
	if is_hook and chord_freqs.size() >= 3:
		arp_indices = _get_arp_indices_for_genre(genre_id, sound_name, bar_index)
	
	var active_step_counter := 0  # Counts only steps that actually trigger
	
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
		
		# For hook sounds: cycle through chord tones using arp pattern
		var hit_freqs = chord_freqs
		if is_hook and arp_indices.size() > 0 and chord_freqs.size() >= 3:
			var arp_idx = arp_indices[active_step_counter % arp_indices.size()]
			# arp_idx maps to chord tone: 0=root, 1=3rd, 2=5th, 3=octave
			var selected_freq: float
			if arp_idx >= chord_freqs.size():
				selected_freq = chord_freqs[0] * 2.0  # Octave up
			else:
				selected_freq = chord_freqs[arp_idx]
			hit_freqs = [selected_freq, chord_freqs[1], chord_freqs[2]]
		
		active_step_counter += 1
		_add_sound_hit(mix, script, step_start, sound_name, hit_freqs, volume)


## Returns an array of chord-tone indices for cycling through on each hit.
## 0 = root, 1 = 3rd, 2 = 5th, 3 = octave (root * 2)
## Genre-specific patterns create distinct arpeggio characters.
static func _get_arp_indices_for_genre(genre_id: String, sound_name: String, bar_index: int) -> Array:
	# Stabs typically hit chord tones (root or full chord) — less arpeggiation
	if sound_name in ["stab", "piano", "organ", "rhodes"]:
		match genre_id:
			"detroit_techno", "midnight_metroplex":
				return [0, 0, 2, 0]  # Root-heavy with occasional 5th
			"gypsy_woman_house", "chicago_dusseldorf":
				return [0, 1, 2, 1] if bar_index % 2 == 0 else [2, 1, 0, 1]  # Alternating direction
			"french_touch":
				return [1, 2, 0, 2]  # Disco inversion — starts on 3rd
			"dub_house":
				return [0, 2, 0, 2]  # Minimal root-5th
			_:
				return [0, 1, 2, 1]  # Default: up-down through chord
	
	# Arps and sequences cycle through chord tones — this IS the melody
	match genre_id:
		"moroder_disco":
			return [0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 0, 1, 2, 3]  # Classic disco triangle
		"synthwave":
			return [0, 2, 1, 3, 0, 2, 1, 3]  # Wide, cinematic jumps
		"madonna_80s":
			return [0, 1, 2, 3, 2, 1, 0, 0]  # Pop arp with root anchor
		"boards_of_canada", "foggy_frequencies":
			# Irregular — skip tones, repeat, warp
			return [0, 0, 2, 1, 0, 2, 0, 1] if bar_index % 4 < 2 else [2, 0, 1, 0, 2, 1, 0, 0]
		"kraftwerk", "chicago_dusseldorf":
			return [0, 3, 0, 3, 2, 3, 0, 3]  # Robotic octave + 5th
		"vangelis_cs80", "replicants_dawn":
			return [0, 2, 3, 2, 0, 1, 3, 1]  # Expressive, wide voicing
		"rave":
			return [0, 3, 0, 3, 0, 3, 0, 3]  # Octave stab — aggressive
		"dark_wave":
			return [0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 0, 1, 2, 3]  # Triangle — never stops
		"burial":
			return [0, 2, 0, 2, 0, 0, 2, 0]  # Sparse root-5th
		"acid_house", "acid_techno_303":
			return [0, 0, 2, 0, 1, 0, 3, 0]  # 303-style — root-heavy with chromatic escapes
		"ambient_techno":
			return [0, 2, 1, 2]  # Slow, drifting chord tones
		"french_touch":
			return [1, 2, 3, 2, 1, 0, 1, 2]  # Disco: starts on 3rd, funky inversion
		"supersaw_trance":
			return [0, 1, 2, 3, 3, 2, 1, 0]  # Anthemic — full sweep up and down
		"reese_jungle", "k_bass":
			return [0, 0, 2, 0, 0, 2, 0, 0]  # Sub-focused — mostly root
		"lofi_house":
			return [0, 1, 0, 2, 0, 1, 2, 0]  # Dusty, irregular cycling
		"nineties_rnb", "chromatic_story":
			return [0, 1, 2, 1, 0, 2, 1, 0]  # Smooth, jazzy voice-leading
		"dark_wave_cathedral":
			return [0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 0, 1, 2, 3]  # Triangle arp
		_:
			# Genre-hashed fallback — at least different per genre
			var h = absi(genre_id.hash())
			var options = [
				[0, 1, 2, 3, 2, 1, 0, 1],  # Triangle
				[0, 2, 1, 3, 0, 2, 1, 3],  # Wide jumps
				[0, 0, 2, 1, 0, 2, 0, 1],  # Root-heavy irregular
				[0, 1, 2, 1, 2, 3, 2, 1],  # Ascending bias
				[3, 2, 1, 0, 1, 2, 3, 2],  # Descending bias
			]
			return options[h % options.size()]


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
			"kick", "snare", "clap", "rimshot", "shaker", "fingersnap", "tambourine", "perc":
				if script.has_method("generate"):
					sample = script.generate(t, 0.0)
			"hihat":
				if script.has_method("generate_closed"):
					sample = script.generate_closed(t, 0.0)
				elif script.has_method("generate"):
					sample = script.generate(t, 0.0, false)
			"stab", "piano", "organ", "rhodes", "strings", "pad":
				if script.has_method("generate"):
					sample = script.generate(t, chord_freqs, 0.0)
			"arp", "sequence", "sequencer", "jupiter_arp", "singing_voice", "vocoder", "lead":
				var freq = chord_freqs[0] if chord_freqs.size() > 0 else 440.0
				if script.has_method("generate"):
					sample = script.generate(t, freq, 0.0)
			_:
				# Fallback for unknown instruments - try different signatures
				if script.has_method("generate_sample"):
					sample = script.generate_sample(t, chord_freqs)
				elif script.has_method("generate"):
					# Try with just t, trigger_time (drums)
					sample = script.generate(t, 0.0)
		
		mix[idx] = clampf(mix[idx] + sample * volume, -1.0, 1.0)


static func _add_continuous_sound(mix: PackedFloat32Array, script, start: int, 
								   length: int, sound_name: String, 
								   root_freq: float, chord_freqs: Array,
								   velocity_cfg: Dictionary,
								   time_offset: float = 0.0,
								   note_duration_override: float = -1.0) -> void:
	var note_duration = note_duration_override if note_duration_override > 0 else float(length) / SAMPLE_RATE
	var volume = velocity_cfg["base"]
	
	for i in range(length):
		var idx = start + i
		if idx >= mix.size():
			break
		
		var t = time_offset + float(i) / SAMPLE_RATE
		var sample = 0.0
		
		# Poly sounds take chord_freqs Array; mono sounds take single float freq.
		var freq = chord_freqs[0] if chord_freqs.size() > 0 else root_freq
		var is_poly = sound_name in ["pad", "atmosphere", "supersaw", "siren", "strings", "choir", "stab"]
		var is_ambient = sound_name in ["crackle", "texture"]
		
		if is_poly:
			if script.has_method("generate"):
				sample = script.generate(t, chord_freqs, note_duration, 0.0)
			elif script.has_method("generate_sample"):
				sample = script.generate_sample(t, chord_freqs)
		elif is_ambient:
			if script.has_method("generate"):
				sample = script.generate(t, 0.0)
		else:
			# Mono-frequency sounds: lead, arp, sequence, organ, piano, vocal, etc.
			if script.has_method("generate"):
				sample = script.generate(t, freq, 0.0)
			elif script.has_method("generate_sample"):
				sample = script.generate_sample(t, freq)
		
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
