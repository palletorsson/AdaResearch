# GenreSynthBrowser.gd
# Synth elements organized by GENRE and STYLE, with deep technical research
# Each sound element traced to its historical/technical origins

extends Control
class_name GenreSynthBrowser

const SAMPLE_RATE = 44100.0

# ═══════════════════════════════════════════════════════════════════════════
# GENRES - The organizing principle
# ═══════════════════════════════════════════════════════════════════════════

const GENRES = {
	"acid_house": {
		"name": "Acid House / Techno",
		"icon": "🧪",
		"era": "1987-present",
		"bpm_range": "120-145",
		"description": "Chicago/Detroit acid - defined by the TB-303 squelch and TR-808/909 drums",
		"key_artists": ["Phuture", "Hardfloor", "DJ Pierre", "Plastikman"],
		"elements": ["tr909_kick", "tr909_hihat", "tr909_clap", "tr808_kick", "tb303_acid", "acid_pad", "acid_lead", "arp_synth", "noise_riser", "impact_hit"]
	},
	"detroit_techno": {
		"name": "Detroit Techno",
		"icon": "🔩",
		"era": "1985-present",
		"bpm_range": "125-140",
		"description": "Cold machine funk - 909 drums, string stabs, minimal bass",
		"key_artists": ["Juan Atkins", "Derrick May", "Kevin Saunderson", "Jeff Mills"],
		"elements": ["tr909_kick", "tr909_hihat", "tr909_clap", "detroit_bass", "detroit_strings", "detroit_stab", "arp_sequence", "noise_riser", "noise_fall", "impact_hit"]
	},
	"chicago_house": {
		"name": "Chicago House",
		"icon": "🏠",
		"era": "1984-present",
		"bpm_range": "118-128",
		"description": "Soulful machine music - organ stabs, 909 drums, disco influence",
		"key_artists": ["Frankie Knuckles", "Marshall Jefferson", "Larry Heard"],
		"elements": ["tr909_kick", "tr909_hihat", "house_clap", "house_bass", "house_organ", "house_piano", "disco_hihat", "noise_riser", "noise_fall", "impact_hit"]
	},
	"rave_hardcore": {
		"name": "Rave / Hardcore",
		"icon": "⚡",
		"era": "1989-1995",
		"bpm_range": "140-180",
		"description": "High energy rave - hoovers, breakbeats, piano stabs",
		"key_artists": ["The Prodigy", "Altern-8", "SL2", "Acen"],
		"elements": ["tr909_kick", "amen_break", "hoover_bass", "mentasm", "rave_stab", "rave_piano", "trancer", "noise_riser", "noise_fall", "impact_hit"]
	},
	"jungle_dnb": {
		"name": "Jungle / Drum & Bass",
		"icon": "🌴",
		"era": "1992-present",
		"bpm_range": "160-180",
		"description": "Chopped breaks + rolling bass - Amen chopping, Reese bass",
		"key_artists": ["Goldie", "LTJ Bukem", "Roni Size", "Ed Rush"],
		"elements": ["amen_break", "tr909_kick", "jungle_sub", "reese_bass", "roller_bass", "dnb_pad", "jungle_stab", "noise_riser", "noise_fall", "impact_hit"]
	},
	"synthwave": {
		"name": "Synthwave / Retrowave",
		"icon": "🌆",
		"era": "2005-present",
		"bpm_range": "80-118",
		"description": "80s revival - gated drums, supersaws, arpeggios",
		"key_artists": ["Kavinsky", "Perturbator", "Carpenter Brut", "Gunship"],
		"elements": ["linn_kick", "gated_snare", "disco_hihat", "synthwave_bass", "supersaw", "arp_synth", "synthwave_lead", "solina_pad", "noise_riser", "impact_hit"]
	},
	"ambient_idm": {
		"name": "Ambient / IDM",
		"icon": "🌊",
		"era": "1990-present",
		"bpm_range": "70-140",
		"description": "Atmospheric textures - detuned pads, lo-fi, glitch",
		"key_artists": ["Aphex Twin", "Boards of Canada", "Autechre", "Brian Eno"],
		"elements": ["lofi_break", "bitcrush_drums", "warm_pad", "granular_pad", "ambient_drone", "tape_delay", "trap_bell", "noise_riser", "noise_fall", "impact_hit"]
	},
	"disco_funk": {
		"name": "Disco / Italo",
		"icon": "🪩",
		"era": "1975-1985",
		"bpm_range": "110-130",
		"description": "Moroder sequencers, 4-on-floor, string machines",
		"key_artists": ["Giorgio Moroder", "Donna Summer", "Cerrone", "Italo disco"],
		"elements": ["four_floor_kick", "disco_hihat", "house_clap", "disco_bass", "moroder_seq", "disco_strings", "solina_pad", "minimoog_lead", "noise_riser", "impact_hit"]
	},
	"hip_hop": {
		"name": "Hip-Hop / Trap",
		"icon": "🎤",
		"era": "1980-present",
		"bpm_range": "70-150",
		"description": "808 boom, SP-1200 crunch, modern trap hi-hats",
		"key_artists": ["Afrika Bambaataa", "J Dilla", "Metro Boomin", "Timbaland"],
		"elements": ["tr808_kick", "tr808_snare", "tr808_hihat", "trap_hihat", "808_bass", "sp1200_crunch", "trap_bell", "trap_pad", "noise_fall", "impact_hit"]
	},
	"prog_rock": {
		"name": "70s Prog / Krautrock",
		"icon": "🎸",
		"era": "1969-1980",
		"bpm_range": "80-140",
		"description": "Moog leads, motorik beats, ELP/Kraftwerk textures",
		"key_artists": ["Kraftwerk", "Tangerine Dream", "ELP", "Yes"],
		"elements": ["motorik_beat", "tr909_kick", "moog_bass", "minimoog_lead", "cs80_brass", "mellotron_strings", "arp_sequence", "tape_delay", "noise_riser", "noise_fall"]
	},
	"dub_techno": {
		"name": "Dub Techno",
		"icon": "DT",
		"era": "1992-present",
		"bpm_range": "108-122",
		"description": "Deep chords, sub pressure, and long feedback tails",
		"key_artists": ["Basic Channel", "Deepchord", "Monolake", "Rhythm & Sound"],
		"elements": ["tr909_kick", "tr909_hihat", "dub_sub", "dub_chord", "dub_echo_stab", "warm_pad", "tape_delay", "noise_riser", "noise_fall", "impact_hit"]
	},
	"uk_garage": {
		"name": "UK Garage / 2-Step",
		"icon": "UKG",
		"era": "1997-present",
		"bpm_range": "128-136",
		"description": "Shuffled hats, skippy drums, warm bass wobble and chopped hooks",
		"key_artists": ["MJ Cole", "Artful Dodger", "El-B", "Burial"],
		"elements": ["tr909_kick", "ukg_shuff_hat", "house_clap", "ukg_wobble_bass", "ukg_organ_stab", "ukg_pluck", "ukg_vocal_chop", "noise_riser", "noise_fall", "impact_hit"]
	},
	"neurofunk": {
		"name": "Neurofunk",
		"icon": "NF",
		"era": "1998-present",
		"bpm_range": "170-176",
		"description": "Precision drums, snarling mid-bass, and futuristic FX design",
		"key_artists": ["Ed Rush & Optical", "Noisia", "Phace", "Mefjus"],
		"elements": ["tr909_kick", "tr808_snare", "trap_hihat", "neuro_mid_bass", "reese_bass", "dnb_pad", "neuro_stab", "neuro_laser", "noise_riser", "impact_hit"]
	}
}

# ═══════════════════════════════════════════════════════════════════════════
# ELEMENTS - Deep technical definitions
# ═══════════════════════════════════════════════════════════════════════════

const SUITE_REQUIREMENTS = {
	"rhythm": 2,
	"bass": 1,
	"harmony": 1,
	"hook": 1,
	"fx": 1
}

const GENRE_SUITES = {
	"acid_house": {
		"rhythm": ["tr909_kick", "tr909_hihat", "tr909_clap", "tr808_kick"],
		"bass": ["tb303_acid"],
		"harmony": ["acid_pad"],
		"hook": ["acid_lead", "arp_synth"],
		"fx": ["noise_riser", "impact_hit"]
	},
	"detroit_techno": {
		"rhythm": ["tr909_kick", "tr909_hihat", "tr909_clap"],
		"bass": ["detroit_bass"],
		"harmony": ["detroit_strings"],
		"hook": ["detroit_stab", "arp_sequence"],
		"fx": ["noise_riser", "noise_fall", "impact_hit"]
	},
	"chicago_house": {
		"rhythm": ["tr909_kick", "tr909_hihat", "house_clap", "disco_hihat"],
		"bass": ["house_bass"],
		"harmony": ["house_organ", "house_piano"],
		"hook": ["house_piano"],
		"fx": ["noise_riser", "noise_fall", "impact_hit"]
	},
	"rave_hardcore": {
		"rhythm": ["tr909_kick", "amen_break"],
		"bass": ["hoover_bass", "mentasm"],
		"harmony": ["rave_piano"],
		"hook": ["rave_stab", "trancer"],
		"fx": ["noise_riser", "noise_fall", "impact_hit"]
	},
	"jungle_dnb": {
		"rhythm": ["amen_break", "tr909_kick"],
		"bass": ["jungle_sub", "reese_bass", "roller_bass"],
		"harmony": ["dnb_pad"],
		"hook": ["jungle_stab"],
		"fx": ["noise_riser", "noise_fall", "impact_hit"]
	},
	"synthwave": {
		"rhythm": ["linn_kick", "gated_snare", "disco_hihat"],
		"bass": ["synthwave_bass"],
		"harmony": ["supersaw", "solina_pad"],
		"hook": ["synthwave_lead", "arp_synth"],
		"fx": ["noise_riser", "impact_hit"]
	},
	"ambient_idm": {
		"rhythm": ["lofi_break", "bitcrush_drums"],
		"bass": ["ambient_drone"],
		"harmony": ["warm_pad", "granular_pad"],
		"hook": ["trap_bell"],
		"fx": ["tape_delay", "noise_riser", "noise_fall", "impact_hit"]
	},
	"disco_funk": {
		"rhythm": ["four_floor_kick", "disco_hihat", "house_clap"],
		"bass": ["disco_bass", "moroder_seq"],
		"harmony": ["disco_strings", "solina_pad"],
		"hook": ["minimoog_lead"],
		"fx": ["noise_riser", "impact_hit"]
	},
	"hip_hop": {
		"rhythm": ["tr808_kick", "tr808_snare", "tr808_hihat", "trap_hihat"],
		"bass": ["808_bass"],
		"harmony": ["trap_pad"],
		"hook": ["trap_bell"],
		"fx": ["sp1200_crunch", "noise_fall", "impact_hit"]
	},
	"prog_rock": {
		"rhythm": ["motorik_beat", "tr909_kick"],
		"bass": ["moog_bass"],
		"harmony": ["mellotron_strings", "cs80_brass"],
		"hook": ["minimoog_lead", "arp_sequence"],
		"fx": ["tape_delay", "noise_riser", "noise_fall"]
	},
	"dub_techno": {
		"rhythm": ["tr909_kick", "tr909_hihat"],
		"bass": ["dub_sub"],
		"harmony": ["dub_chord", "warm_pad"],
		"hook": ["dub_echo_stab"],
		"fx": ["tape_delay", "noise_riser", "noise_fall", "impact_hit"]
	},
	"uk_garage": {
		"rhythm": ["tr909_kick", "ukg_shuff_hat", "house_clap"],
		"bass": ["ukg_wobble_bass"],
		"harmony": ["ukg_organ_stab"],
		"hook": ["ukg_pluck", "ukg_vocal_chop"],
		"fx": ["noise_riser", "noise_fall", "impact_hit"]
	},
	"neurofunk": {
		"rhythm": ["tr909_kick", "tr808_snare", "trap_hihat"],
		"bass": ["neuro_mid_bass", "reese_bass"],
		"harmony": ["dnb_pad"],
		"hook": ["neuro_stab", "neuro_laser"],
		"fx": ["noise_riser", "noise_fall", "impact_hit"]
	}
}

const ELEMENTS = {
	# ─────────────────────────────────────────────────────────────────────
	# ACID / TECHNO ELEMENTS
	# ─────────────────────────────────────────────────────────────────────
	"tb303_acid": {
		"name": "TB-303 Acid Bass",
		"type": "bass",
		"genre": "acid_house",
		"machine": "Roland TB-303",
		"year": 1982,
		"description": "The defining acid sound. 18dB diode ladder filter with decay-only envelope.",
		"signal_flow": "VCO (saw/square) → VCF (18dB diode) → VCA",
		"tech_notes": """
The TB-303 filter is unique:
- 3-pole (18dB/octave), not 4-pole like Moog
- Diode ladder topology creates asymmetric soft clipping
- No attack on filter envelope - decay only
- Accent increases BOTH resonance AND envelope depth
- Slide is fixed ~60ms exponential portamento
		""",
		"parameters": {
			"waveform": {"type": "option", "options": ["sawtooth", "square"], "default": "sawtooth"},
			"cutoff": {"type": "float", "min": 60, "max": 2500, "default": 400, "unit": "Hz"},
			"resonance": {"type": "float", "min": 0, "max": 0.98, "default": 0.7},
			"env_mod": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Env Depth"},
			"decay": {"type": "float", "min": 0.03, "max": 2.0, "default": 0.3, "unit": "s"},
			"accent": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Accent"},
			"slide": {"type": "float", "min": 0.02, "max": 0.2, "default": 0.06, "unit": "s"},
			"distortion": {"type": "float", "min": 0, "max": 1, "default": 0.2, "label": "Diode Drive"}
		}
	},
	
	"tr909_kick": {
		"name": "TR-909 Kick Drum",
		"type": "drum",
		"genre": "acid_house",
		"machine": "Roland TR-909",
		"year": 1984,
		"description": "Punchy analog kick. Pitch envelope creates the 'punch'.",
		"signal_flow": "Bridged-T Osc → VCA + Click generator",
		"tech_notes": """
The 909 kick punch comes from pitch envelope:
- Pitch starts ~150Hz, drops to ~55Hz in ~20ms
- Body is quasi-sine (bridged-T oscillator)
- Click is short high-freq burst (~3kHz, 2-5ms)
- Adjustable decay, tune, attack amount
		""",
		"parameters": {
			"tune": {"type": "float", "min": 40, "max": 100, "default": 55, "unit": "Hz", "label": "Tune"},
			"pitch_start": {"type": "float", "min": 100, "max": 300, "default": 150, "unit": "Hz", "label": "Pitch Start"},
			"pitch_decay": {"type": "float", "min": 0.005, "max": 0.05, "default": 0.02, "unit": "s", "label": "Pitch Decay"},
			"attack": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Attack/Click"},
			"decay": {"type": "float", "min": 0.1, "max": 0.5, "default": 0.25, "unit": "s", "label": "Decay"},
			"punch": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Punch"}
		}
	},
	
	"tr909_hihat": {
		"name": "TR-909 Hi-Hat",
		"type": "drum",
		"genre": "acid_house",
		"machine": "Roland TR-909",
		"year": 1984,
		"description": "Metallic shimmer from 6 square wave oscillators at non-harmonic ratios.",
		"signal_flow": "6x Square OSC → Mixer → HPF → VCA",
		"tech_notes": """
The metallic 909 hat sound:
- 6 square waves at: 204, 298, 366, 522, 540, 598 Hz
- Non-harmonic ratios create metallic inharmonicity
- High-pass filtered (~8kHz)
- Closed hat: 20-80ms decay
- Open hat: 200-800ms decay
		""",
		"parameters": {
			"decay": {"type": "float", "min": 0.02, "max": 0.8, "default": 0.05, "unit": "s", "label": "Decay"},
			"tone": {"type": "float", "min": 6000, "max": 16000, "default": 10000, "unit": "Hz", "label": "Tone/HPF"},
			"pitch": {"type": "float", "min": 0.5, "max": 2, "default": 1, "label": "Pitch Mult"},
			"metallic": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "Metallic vs Noise"}
		}
	},
	
	"tr909_clap": {
		"name": "TR-909 Clap",
		"type": "drum",
		"genre": "acid_house",
		"machine": "Roland TR-909",
		"year": 1984,
		"description": "Multiple noise bursts simulating hand claps.",
		"signal_flow": "Noise → BPF → Multiple triggers → Reverb",
		"tech_notes": """
909 clap is actually multiple overlapping bursts:
- 4 noise bursts with slight timing spread
- Band-pass filtered around 1-2kHz
- Built-in reverb tail
- Tight, punchy, cuts through mix
		""",
		"parameters": {
			"tone": {"type": "float", "min": 800, "max": 3000, "default": 1500, "unit": "Hz", "label": "Tone"},
			"spread": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Spread"},
			"decay": {"type": "float", "min": 0.1, "max": 0.4, "default": 0.2, "unit": "s", "label": "Decay"},
			"reverb": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Reverb"}
		}
	},
	
	"tr808_kick": {
		"name": "TR-808 Kick Drum",
		"type": "drum",
		"genre": "hip_hop",
		"machine": "Roland TR-808",
		"year": 1980,
		"description": "Deep, boomy kick. Long decay = sub bass foundation.",
		"signal_flow": "Bridged-T Osc → VCA (long decay)",
		"tech_notes": """
The 808 boom:
- Lower fundamental than 909 (~50Hz vs ~55Hz)
- MUCH longer decay (up to 2+ seconds)
- Minimal click/transient
- When decay extended, becomes sub bass itself
- The foundation of hip-hop and bass music
		""",
		"parameters": {
			"tune": {"type": "float", "min": 30, "max": 80, "default": 50, "unit": "Hz", "label": "Tune"},
			"decay": {"type": "float", "min": 0.2, "max": 2, "default": 0.8, "unit": "s", "label": "Decay"},
			"tone": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Tone"},
			"click": {"type": "float", "min": 0, "max": 1, "default": 0.1, "label": "Click"}
		}
	},
	
	"acid_pad": {
		"name": "Acid Pad",
		"type": "pad",
		"genre": "acid_house",
		"machine": "Roland Juno-106 / Alpha Juno",
		"year": 1986,
		"description": "Warm resonant pad with filter sweep. Phuture vibes.",
		"signal_flow": "DCO (saw) → VCF (resonant, LFO mod) → VCA → Chorus",
		"tech_notes": """
Acid pad characteristics:
- Warm analog pad with movement
- Filter cutoff modulated by slow LFO
- Moderate resonance for color
- Built-in chorus for width
- Sits behind the 303 in acid tracks
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 200, "max": 4000, "default": 1200, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.7, "default": 0.35, "label": "Resonance"},
			"lfo_rate": {"type": "float", "min": 0.05, "max": 2, "default": 0.3, "unit": "Hz", "label": "LFO Rate"},
			"lfo_depth": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "LFO Depth"},
			"chorus": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Chorus"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# DETROIT TECHNO ELEMENTS
	# ─────────────────────────────────────────────────────────────────────
	"detroit_strings": {
		"name": "Detroit String Stab",
		"type": "pad",
		"genre": "detroit_techno",
		"machine": "Roland Juno-60/106",
		"year": 1982,
		"description": "Lush string pad with chorus. The soul of Detroit.",
		"signal_flow": "DCO (saw) → VCF → VCA → BBD Chorus",
		"tech_notes": """
The Juno string sound:
- Single DCO (saw or saw+sub)
- 24dB lowpass with moderate resonance
- Slow attack, medium release (pad envelope)
- BBD chorus is ESSENTIAL - modes I, II, or I+II
- Often layered with reverb
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 500, "max": 6000, "default": 2000, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.6, "default": 0.2, "label": "Resonance"},
			"attack": {"type": "float", "min": 0.05, "max": 2, "default": 0.3, "unit": "s", "label": "Attack"},
			"release": {"type": "float", "min": 0.1, "max": 3, "default": 1, "unit": "s", "label": "Release"},
			"chorus": {"type": "option", "options": ["off", "I", "II", "I+II"], "default": "I+II", "label": "Chorus"},
			"sub": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Sub Osc"}
		}
	},
	
	"detroit_stab": {
		"name": "Detroit Synth Stab",
		"type": "lead",
		"genre": "detroit_techno",
		"machine": "Various (Juno, DX7, M1)",
		"year": 1988,
		"description": "Short, punchy chord stab. Rhythmic accent.",
		"signal_flow": "Oscillator → Filter → Fast VCA envelope",
		"tech_notes": """
Detroit stab characteristics:
- Very fast attack (< 10ms)
- Short decay (50-200ms)
- Usually played as chord (minor 7th common)
- Filter slightly closed for warmth
- Often sidechained to kick
		""",
		"parameters": {
			"waveform": {"type": "option", "options": ["saw", "square", "fm"], "default": "saw", "label": "Wave"},
			"cutoff": {"type": "float", "min": 500, "max": 4000, "default": 1500, "unit": "Hz", "label": "Filter"},
			"decay": {"type": "float", "min": 0.03, "max": 0.3, "default": 0.1, "unit": "s", "label": "Decay"},
			"voices": {"type": "int", "min": 1, "max": 4, "default": 3, "label": "Voices"},
			"detune": {"type": "float", "min": 0, "max": 0.02, "default": 0.005, "label": "Detune"}
		}
	},
	
	"detroit_bass": {
		"name": "Detroit Bass Line",
		"type": "bass",
		"genre": "detroit_techno",
		"machine": "Minimoog / SH-101",
		"year": 1985,
		"description": "Simple, driving bass. Often just root notes.",
		"signal_flow": "VCO (saw/square) → VCF (24dB) → VCA",
		"tech_notes": """
Detroit bass is minimal:
- Single oscillator usually enough
- Sawtooth or square wave
- Filter moderately open
- Short decay, punchy envelope
- Sits under the kick, doesn't compete
		""",
		"parameters": {
			"waveform": {"type": "option", "options": ["saw", "square"], "default": "square", "label": "Wave"},
			"cutoff": {"type": "float", "min": 100, "max": 2000, "default": 600, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.5, "default": 0.2, "label": "Resonance"},
			"decay": {"type": "float", "min": 0.05, "max": 0.5, "default": 0.15, "unit": "s", "label": "Decay"},
			"glide": {"type": "float", "min": 0, "max": 0.3, "default": 0, "unit": "s", "label": "Glide"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# HOUSE ELEMENTS
	# ─────────────────────────────────────────────────────────────────────
	"house_organ": {
		"name": "House Organ Stab",
		"type": "keys",
		"genre": "chicago_house",
		"machine": "Korg M1 / Hammond",
		"year": 1987,
		"description": "The M1 'Organ 2' preset - foundation of house music.",
		"signal_flow": "Sample playback (ROM) → Filter → Amp",
		"tech_notes": """
The M1 Organ 2 preset:
- Sampled Hammond-style organ
- Slight attack for key click
- Percussive decay with sustain
- Often played in offbeat rhythms
- Layer with reverb for space
		""",
		"parameters": {
			"attack": {"type": "float", "min": 0, "max": 0.1, "default": 0.01, "unit": "s", "label": "Attack"},
			"decay": {"type": "float", "min": 0.1, "max": 1, "default": 0.3, "unit": "s", "label": "Decay"},
			"sustain": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Sustain"},
			"brightness": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Brightness"},
			"click": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Key Click"}
		}
	},
	
	"house_piano": {
		"name": "House Piano",
		"type": "keys",
		"genre": "chicago_house",
		"machine": "Korg M1 / DX7",
		"year": 1988,
		"description": "Bright piano stabs. Rhythmic chords.",
		"signal_flow": "FM or Sample → Filter → Amp",
		"tech_notes": """
House piano sound:
- Often M1 piano or DX7 E.Piano
- Bright, cutting high frequencies
- Staccato playing style
- Velocity sensitive for dynamics
- Sits above organ in mix
		""",
		"parameters": {
			"brightness": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "Brightness"},
			"decay": {"type": "float", "min": 0.1, "max": 2, "default": 0.5, "unit": "s", "label": "Decay"},
			"velocity": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "Velocity Sens"},
			"reverb": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Reverb"}
		}
	},
	
	"house_bass": {
		"name": "House Bass",
		"type": "bass",
		"genre": "chicago_house",
		"machine": "Minimoog / Juno",
		"year": 1985,
		"description": "Round, warm bass. Smooth and melodic.",
		"signal_flow": "VCO (saw) → VCF (low resonance) → VCA",
		"tech_notes": """
House bass is warm and round:
- Sawtooth filtered down
- Low resonance for smoothness
- Often melodic (bass lines, not just roots)
- Moderate attack to avoid click
- Sits in mix without dominating
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 100, "max": 1500, "default": 500, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.4, "default": 0.15, "label": "Resonance"},
			"attack": {"type": "float", "min": 0.001, "max": 0.1, "default": 0.02, "unit": "s", "label": "Attack"},
			"decay": {"type": "float", "min": 0.1, "max": 1, "default": 0.3, "unit": "s", "label": "Decay"},
			"sub": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Sub Level"}
		}
	},
	
	"house_clap": {
		"name": "House Clap",
		"type": "drum",
		"genre": "chicago_house",
		"machine": "Roland TR-909",
		"year": 1984,
		"description": "The house backbeat. Layered with snare on 2 and 4.",
		"signal_flow": "Noise → BPF → Multi-trigger → Reverb",
		"tech_notes": """
House clap characteristics:
- 909 clap layered with snare often
- Multiple noise bursts for 'clap' sound
- Small room reverb for width
- Hits on 2 and 4 with the snare
- Essential Chicago groove element
		""",
		"parameters": {
			"tone": {"type": "float", "min": 800, "max": 3000, "default": 1500, "unit": "Hz", "label": "Tone"},
			"spread": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Spread"},
			"decay": {"type": "float", "min": 0.1, "max": 0.5, "default": 0.25, "unit": "s", "label": "Decay"},
			"reverb": {"type": "float", "min": 0, "max": 1, "default": 0.35, "label": "Reverb"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# RAVE ELEMENTS
	# ─────────────────────────────────────────────────────────────────────
	"hoover_bass": {
		"name": "Hoover / Mentasm",
		"type": "bass",
		"genre": "rave_hardcore",
		"machine": "Roland Alpha Juno 2",
		"year": 1989,
		"description": "The vacuum cleaner sound. Detuned + portamento + filter sweep.",
		"signal_flow": "Multiple detuned OSC → Resonant filter → VCA",
		"tech_notes": """
The Hoover sound (Alpha Juno 'What The' patch):
- Multiple sawtooth oscillators, heavily detuned
- PWM on at least one oscillator
- Heavy portamento (100-200ms)
- Resonant lowpass with envelope sweep
- Distortion/saturation on output
Named after sounding like a vacuum cleaner.
		""",
		"parameters": {
			"voices": {"type": "int", "min": 2, "max": 5, "default": 3, "label": "Voices"},
			"detune": {"type": "float", "min": 0, "max": 0.03, "default": 0.01, "label": "Detune"},
			"pwm_depth": {"type": "float", "min": 0, "max": 0.4, "default": 0.2, "label": "PWM"},
			"portamento": {"type": "float", "min": 0, "max": 0.3, "default": 0.12, "unit": "s", "label": "Glide"},
			"cutoff": {"type": "float", "min": 200, "max": 3000, "default": 600, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.8, "default": 0.6, "label": "Resonance"},
			"filter_env": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "Env Depth"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Drive"}
		}
	},
	
	"rave_stab": {
		"name": "Rave Stab",
		"type": "lead",
		"genre": "rave_hardcore",
		"machine": "Various",
		"year": 1990,
		"description": "Bright, aggressive chord stab. Offbeat rhythm.",
		"signal_flow": "OSC → HPF → Distortion → VCA",
		"tech_notes": """
Rave stab characteristics:
- Bright, often high-pass filtered
- Very short decay (30-100ms)
- Distorted/saturated
- Played offbeat (between kicks)
- Often pitched up samples
		""",
		"parameters": {
			"brightness": {"type": "float", "min": 0, "max": 1, "default": 0.8, "label": "Brightness"},
			"decay": {"type": "float", "min": 0.02, "max": 0.2, "default": 0.05, "unit": "s", "label": "Decay"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Drive"},
			"hpf": {"type": "float", "min": 0, "max": 2000, "default": 500, "unit": "Hz", "label": "HPF"}
		}
	},
	
	"amen_break": {
		"name": "Amen Break",
		"type": "drum",
		"genre": "rave_hardcore",
		"machine": "Sampler (SP-1200, S950)",
		"year": 1969,
		"description": "The most sampled drum break in history. From 'Amen Brother'.",
		"signal_flow": "Sample → Time-stretch → Chop → Rearrange",
		"tech_notes": """
The Amen Break (by The Winstons, 1969):
- 4-bar drum solo, tempo ~136 BPM
- Usually chopped into individual hits
- Time-stretched for jungle/dnb tempos
- Swing timing is crucial
- Lo-fi sampling adds character
		""",
		"parameters": {
			"tempo": {"type": "float", "min": 120, "max": 180, "default": 160, "unit": "BPM", "label": "Tempo"},
			"swing": {"type": "float", "min": 0, "max": 0.3, "default": 0.15, "label": "Swing"},
			"lofi": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Lo-Fi"},
			"chop_style": {"type": "option", "options": ["full", "sliced", "rolled"], "default": "sliced", "label": "Style"}
		}
	},
	
	"rave_piano": {
		"name": "Rave Piano",
		"type": "keys",
		"genre": "rave_hardcore",
		"machine": "Korg M1",
		"year": 1991,
		"description": "Bright piano stabs. The 'Piano House' sound.",
		"signal_flow": "Sample → Filter (bright) → Fast VCA",
		"tech_notes": """
Rave piano (M1 Piano):
- Very bright, almost harsh high end
- Extremely short decay
- Played in rhythmic stabs
- Often with reverb tail
- Pitch bent for effect
		""",
		"parameters": {
			"brightness": {"type": "float", "min": 0.5, "max": 1, "default": 0.9, "label": "Brightness"},
			"decay": {"type": "float", "min": 0.05, "max": 0.5, "default": 0.15, "unit": "s", "label": "Decay"},
			"reverb": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Reverb"},
			"velocity": {"type": "float", "min": 0, "max": 1, "default": 0.8, "label": "Velocity"}
		}
	},
	
	"mentasm": {
		"name": "Mentasm",
		"type": "bass",
		"genre": "rave_hardcore",
		"machine": "Roland Alpha Juno 2",
		"year": 1991,
		"description": "The ORIGINAL hoover. Second Phase 'Mentasm'. Rave anthem.",
		"signal_flow": "PWM OSC → Resonant filter → Distortion → VCA",
		"tech_notes": """
Mentasm (Joey Beltram 1991):
- Based on Alpha Juno 'What The' patch
- PWM square wave with movement
- Heavy portamento between notes
- Filter sweep with high resonance
- Distorted output
- Named after the track that made it famous
		""",
		"parameters": {
			"pwm": {"type": "float", "min": 0.1, "max": 0.9, "default": 0.5, "label": "Pulse Width"},
			"pwm_rate": {"type": "float", "min": 0.1, "max": 5, "default": 1.5, "unit": "Hz", "label": "PWM Rate"},
			"cutoff": {"type": "float", "min": 200, "max": 3000, "default": 800, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.9, "default": 0.6, "label": "Resonance"},
			"portamento": {"type": "float", "min": 0.02, "max": 0.3, "default": 0.12, "unit": "s", "label": "Glide"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Drive"}
		}
	},
	
	"trancer": {
		"name": "Trancer Lead",
		"type": "lead",
		"genre": "rave_hardcore",
		"machine": "Roland JP-8000 / Virus",
		"year": 1995,
		"description": "Supersaw-based lead. Early trance anthem sound.",
		"signal_flow": "7x Detuned OSC → Filter → VCA → Delay",
		"tech_notes": """
Trancer lead characteristics:
- Multiple detuned sawtooths (3-7 voices)
- Filter opens on the attack
- Delay for spatial effect
- Often arpeggiated
- Paul van Dyk, early Tiesto territory
		""",
		"parameters": {
			"voices": {"type": "int", "min": 3, "max": 7, "default": 5, "label": "Voices"},
			"detune": {"type": "float", "min": 0, "max": 0.5, "default": 0.25, "label": "Detune"},
			"cutoff": {"type": "float", "min": 500, "max": 8000, "default": 3000, "unit": "Hz", "label": "Filter"},
			"attack": {"type": "float", "min": 0.01, "max": 0.3, "default": 0.05, "unit": "s", "label": "Attack"},
			"delay": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Delay Mix"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# JUNGLE / DnB ELEMENTS
	# ─────────────────────────────────────────────────────────────────────
	"reese_bass": {
		"name": "Reese Bass",
		"type": "bass",
		"genre": "jungle_dnb",
		"machine": "Roland SH-101 / Various",
		"year": 1988,
		"description": "Detuned sawtooths creating phasing. Named after Kevin Saunderson (Reese).",
		"signal_flow": "2-3 detuned saws → LPF → VCA",
		"tech_notes": """
The Reese bass (from 'Just Want Another Chance'):
- 2-3 sawtooth oscillators
- Heavily detuned (10-30 cents)
- Creates phasing/beating effect
- Low-pass filtered
- Often with slow LFO on filter
Bass equivalent of supersaw concept.
		""",
		"parameters": {
			"voices": {"type": "int", "min": 2, "max": 4, "default": 2, "label": "Voices"},
			"detune": {"type": "float", "min": 0, "max": 0.05, "default": 0.02, "label": "Detune"},
			"cutoff": {"type": "float", "min": 100, "max": 2000, "default": 500, "unit": "Hz", "label": "Filter"},
			"lfo_rate": {"type": "float", "min": 0, "max": 2, "default": 0.3, "unit": "Hz", "label": "LFO Rate"},
			"lfo_depth": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "LFO Depth"}
		}
	},
	
	"jungle_sub": {
		"name": "Jungle Sub Bass",
		"type": "bass",
		"genre": "jungle_dnb",
		"machine": "Any (sub-bass)",
		"year": 1993,
		"description": "Pure sub-bass sine. The weight under the breaks.",
		"signal_flow": "Sine OSC → VCA",
		"tech_notes": """
Jungle sub bass:
- Pure sine wave or filtered square
- Very low (30-60 Hz)
- Long notes, sustaining
- Locked to root of key
- Creates physical weight on system
		""",
		"parameters": {
			"frequency": {"type": "float", "min": 30, "max": 80, "default": 45, "unit": "Hz", "label": "Frequency"},
			"attack": {"type": "float", "min": 0.01, "max": 0.5, "default": 0.1, "unit": "s", "label": "Attack"},
			"release": {"type": "float", "min": 0.1, "max": 2, "default": 0.5, "unit": "s", "label": "Release"},
			"harmonics": {"type": "float", "min": 0, "max": 1, "default": 0.1, "label": "Harmonics"}
		}
	},
	
	"dnb_pad": {
		"name": "DnB Atmospheric Pad",
		"type": "pad",
		"genre": "jungle_dnb",
		"machine": "Roland JV-1080 / Virus",
		"year": 1996,
		"description": "Lush atmospheric pad. LTJ Bukem liquid territory.",
		"signal_flow": "Multi-OSC → Filter → Chorus → Reverb",
		"tech_notes": """
DnB pad characteristics:
- Warm, evolving texture
- Often string or vocal-based
- Long attack and release
- Heavy reverb for space
- Sits above the breaks, below the vocal
		""",
		"parameters": {
			"voices": {"type": "int", "min": 2, "max": 6, "default": 4, "label": "Voices"},
			"detune": {"type": "float", "min": 0, "max": 0.05, "default": 0.02, "label": "Detune"},
			"cutoff": {"type": "float", "min": 500, "max": 5000, "default": 2000, "unit": "Hz", "label": "Filter"},
			"attack": {"type": "float", "min": 0.1, "max": 2, "default": 0.5, "unit": "s", "label": "Attack"},
			"reverb": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Reverb"}
		}
	},
	
	"roller_bass": {
		"name": "Roller Bass",
		"type": "bass",
		"genre": "jungle_dnb",
		"machine": "Reese variant / Software",
		"year": 1998,
		"description": "Rolling, pulsing bass. The tech-step foundation.",
		"signal_flow": "Detuned OSC → Modulated filter → Distortion → VCA",
		"tech_notes": """
Roller bass characteristics:
- Based on Reese but more aggressive
- Filter modulated by LFO for rolling effect
- Often distorted/saturated
- Follows the drum pattern rhythm
- Ed Rush & Optical, Bad Company territory
		""",
		"parameters": {
			"detune": {"type": "float", "min": 0, "max": 0.04, "default": 0.02, "label": "Detune"},
			"cutoff": {"type": "float", "min": 100, "max": 2000, "default": 600, "unit": "Hz", "label": "Filter"},
			"lfo_rate": {"type": "float", "min": 1, "max": 16, "default": 4, "unit": "Hz", "label": "LFO Rate"},
			"lfo_depth": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "LFO Depth"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Drive"}
		}
	},
	
	"jungle_stab": {
		"name": "Jungle Stab",
		"type": "lead",
		"genre": "jungle_dnb",
		"machine": "Sampler / Rompler",
		"year": 1993,
		"description": "Chopped horn or string stab. Ragga jungle essential.",
		"signal_flow": "Sample → Pitch shift → Filter → Output",
		"tech_notes": """
Jungle stab characteristics:
- Often sampled from funk/soul records
- Horn or string section hits
- Pitch-shifted for effect
- Short, punchy, rhythmic
- Works with the breakbeat rhythm
		""",
		"parameters": {
			"pitch": {"type": "float", "min": -12, "max": 12, "default": 0, "label": "Pitch (semitones)"},
			"decay": {"type": "float", "min": 0.05, "max": 0.5, "default": 0.15, "unit": "s", "label": "Decay"},
			"tone": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Tone"},
			"reverb": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Reverb"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# SYNTHWAVE ELEMENTS
	# ─────────────────────────────────────────────────────────────────────
	"supersaw": {
		"name": "Supersaw",
		"type": "pad",
		"genre": "synthwave",
		"machine": "Roland JP-8000",
		"year": 1996,
		"description": "7 detuned sawtooths. THE trance/EDM lead sound.",
		"signal_flow": "7x Detuned Saw → Mixer → VCF → VCA",
		"tech_notes": """
JP-8000 Supersaw:
- 7 sawtooth oscillators
- Each at slightly different pitch
- Spread controls detune amount
- Mix controls center vs sides
- Creates massive, wide sound
- Foundation of trance and EDM
		""",
		"parameters": {
			"voices": {"type": "int", "min": 1, "max": 7, "default": 7, "label": "Voices"},
			"detune": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Detune"},
			"mix": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Center/Side Mix"},
			"cutoff": {"type": "float", "min": 500, "max": 12000, "default": 4000, "unit": "Hz", "label": "Filter"},
			"attack": {"type": "float", "min": 0.001, "max": 2, "default": 0.1, "unit": "s", "label": "Attack"},
			"release": {"type": "float", "min": 0.1, "max": 3, "default": 0.8, "unit": "s", "label": "Release"}
		}
	},
	
	"gated_snare": {
		"name": "Gated Reverb Snare",
		"type": "drum",
		"genre": "synthwave",
		"machine": "LinnDrum / Recorded",
		"year": 1980,
		"description": "The 80s snare sound. Big reverb, hard gate.",
		"signal_flow": "Snare → Big Reverb → Noise Gate",
		"tech_notes": """
Gated reverb (Phil Collins 'In The Air Tonight'):
- Large room or plate reverb
- Reverb tail hard-gated
- Gate closes abruptly (~100-200ms)
- Creates 'big but controlled' sound
- Defines 80s drum sound
		""",
		"parameters": {
			"tone": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Tone"},
			"reverb_size": {"type": "float", "min": 0, "max": 1, "default": 0.8, "label": "Reverb Size"},
			"gate_time": {"type": "float", "min": 0.05, "max": 0.5, "default": 0.15, "unit": "s", "label": "Gate Time"},
			"snappy": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Snappy"}
		}
	},
	
	"synthwave_bass": {
		"name": "Synthwave Bass",
		"type": "bass",
		"genre": "synthwave",
		"machine": "Prophet-5 / OB-X",
		"year": 1979,
		"description": "Analog bass with movement. Pulsing, rhythmic.",
		"signal_flow": "VCO (saw+sub) → VCF → VCA with sidechain",
		"tech_notes": """
Synthwave bass characteristics:
- Sawtooth + sub oscillator
- Sidechain to kick for pumping
- Filter modulated by LFO or sequence
- Warm but punchy
- Often arpeggiated
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 100, "max": 2000, "default": 600, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.6, "default": 0.3, "label": "Resonance"},
			"sub": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Sub Level"},
			"sidechain": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Sidechain"},
			"lfo_rate": {"type": "float", "min": 0, "max": 4, "default": 0, "unit": "Hz", "label": "Filter LFO"}
		}
	},
	
	"arp_synth": {
		"name": "Arpeggio Synth",
		"type": "lead",
		"genre": "synthwave",
		"machine": "Juno-60 / Prophet-5",
		"year": 1982,
		"description": "Classic 16th note arpeggios. Driving motion.",
		"signal_flow": "VCO → VCF → VCA (fast envelope)",
		"tech_notes": """
Arpeggio synth:
- Fast repeated notes (16th or 8th)
- Short decay envelope
- Filter slightly animated
- Often PWM for movement
- Defines synthwave motion
		""",
		"parameters": {
			"waveform": {"type": "option", "options": ["saw", "pulse", "both"], "default": "pulse", "label": "Wave"},
			"pwm": {"type": "float", "min": 0, "max": 0.4, "default": 0.2, "label": "PWM Depth"},
			"cutoff": {"type": "float", "min": 500, "max": 6000, "default": 2000, "unit": "Hz", "label": "Filter"},
			"decay": {"type": "float", "min": 0.02, "max": 0.3, "default": 0.08, "unit": "s", "label": "Decay"},
			"rate": {"type": "option", "options": ["8th", "16th", "32nd"], "default": "16th", "label": "Rate"}
		}
	},
	
	"synthwave_lead": {
		"name": "Synthwave Lead",
		"type": "lead",
		"genre": "synthwave",
		"machine": "Oberheim OB-X / Prophet-5",
		"year": 1979,
		"description": "Soaring, emotional lead. The sunset drive sound.",
		"signal_flow": "Dual OSC → Filter (env) → VCA → Delay/Reverb",
		"tech_notes": """
Synthwave lead characteristics:
- Two oscillators slightly detuned
- Filter opens on attack for expression
- Moderate portamento for slides
- Delay and reverb for space
- Kavinsky, Gunship, FM-84 territory
		""",
		"parameters": {
			"detune": {"type": "float", "min": 0, "max": 0.02, "default": 0.008, "label": "Detune"},
			"cutoff": {"type": "float", "min": 1000, "max": 8000, "default": 3500, "unit": "Hz", "label": "Filter"},
			"filter_env": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Filter Env"},
			"portamento": {"type": "float", "min": 0, "max": 0.2, "default": 0.05, "unit": "s", "label": "Glide"},
			"reverb": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Reverb"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# AMBIENT / IDM ELEMENTS  
	# ─────────────────────────────────────────────────────────────────────
	"warm_pad": {
		"name": "Warm Analog Pad",
		"type": "pad",
		"genre": "ambient_idm",
		"machine": "Juno-106 / OB-X",
		"year": 1982,
		"description": "Detuned oscillators with slow movement. Atmospheric.",
		"signal_flow": "Multiple detuned OSC → VCF (slow LFO) → VCA → Chorus",
		"tech_notes": """
Ambient pad characteristics:
- 4-8 detuned oscillators
- Slow attack (0.5-2s)
- Filter with slow LFO modulation
- Heavy chorus/ensemble
- Often lo-fi processed
		""",
		"parameters": {
			"voices": {"type": "int", "min": 2, "max": 8, "default": 5, "label": "Voices"},
			"detune": {"type": "float", "min": 0, "max": 0.1, "default": 0.03, "label": "Detune"},
			"cutoff": {"type": "float", "min": 200, "max": 4000, "default": 1500, "unit": "Hz", "label": "Filter"},
			"attack": {"type": "float", "min": 0.1, "max": 3, "default": 1, "unit": "s", "label": "Attack"},
			"release": {"type": "float", "min": 0.5, "max": 5, "default": 2, "unit": "s", "label": "Release"},
			"lfo_rate": {"type": "float", "min": 0.01, "max": 0.5, "default": 0.1, "unit": "Hz", "label": "LFO Rate"},
			"chorus": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Chorus"}
		}
	},
	
	"lofi_break": {
		"name": "Lo-Fi Breakbeat",
		"type": "drum",
		"genre": "ambient_idm",
		"machine": "SP-1200 / MPC",
		"year": 1987,
		"description": "Crunchy sampled drums. Bitcrushed warmth.",
		"signal_flow": "Sample → 12-bit conversion → VCA",
		"tech_notes": """
Lo-fi breakbeat (Boards of Canada style):
- 12-bit sampling (SP-1200)
- Low sample rate for crunch
- Tape saturation/wobble
- Vinyl crackle optional
- Humanized timing
		""",
		"parameters": {
			"bits": {"type": "int", "min": 8, "max": 16, "default": 12, "label": "Bit Depth"},
			"sample_rate": {"type": "float", "min": 0.3, "max": 1, "default": 0.6, "label": "Sample Rate"},
			"tape_wobble": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Tape Wobble"},
			"saturation": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Saturation"}
		}
	},
	
	"granular_pad": {
		"name": "Granular Texture",
		"type": "pad",
		"genre": "ambient_idm",
		"machine": "Software/Hardware granular",
		"year": 1990,
		"description": "Micro-sampled texture. Clouds of sound.",
		"signal_flow": "Source → Granular engine → Filter → Reverb",
		"tech_notes": """
Granular synthesis:
- Source split into tiny grains (5-50ms)
- Grains scattered/overlapped
- Pitch and position randomized
- Creates evolving textures
- Often uses vocal/instrument sources
		""",
		"parameters": {
			"grain_size": {"type": "float", "min": 5, "max": 100, "default": 30, "unit": "ms", "label": "Grain Size"},
			"density": {"type": "float", "min": 1, "max": 50, "default": 15, "label": "Density"},
			"pitch_scatter": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Pitch Scatter"},
			"position_scatter": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Position Scatter"},
			"reverb": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Reverb"}
		}
	},
	
	"tape_delay": {
		"name": "Tape Delay",
		"type": "effect",
		"genre": "ambient_idm",
		"machine": "Roland RE-201 Space Echo",
		"year": 1974,
		"description": "Warm, degrading delays. The Boards of Canada sound.",
		"signal_flow": "Input → Tape head → Playback → Feedback loop",
		"tech_notes": """
Space Echo characteristics:
- Multiple playback heads for rhythmic delays
- Tape saturation adds warmth
- High frequencies roll off with each repeat
- Wow/flutter adds movement
- Self-oscillation at high feedback
		""",
		"parameters": {
			"delay_time": {"type": "float", "min": 50, "max": 500, "default": 200, "unit": "ms", "label": "Delay"},
			"feedback": {"type": "float", "min": 0, "max": 0.95, "default": 0.5, "label": "Feedback"},
			"wow": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Wow/Flutter"},
			"saturation": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Saturation"},
			"tone": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Tone (Dark/Bright)"}
		}
	},
	
	"bitcrush_drums": {
		"name": "Bitcrushed Drums",
		"type": "drum",
		"genre": "ambient_idm",
		"machine": "Fairlight CMI / E-mu SP-1200",
		"year": 1985,
		"description": "Lo-fi digital crunch. 8-12 bit character.",
		"signal_flow": "Sample → Bit reduction → Sample rate reduction → Output",
		"tech_notes": """
Bitcrushing characteristics:
- Reduces bit depth (8-12 bits typical)
- Sample rate reduction adds aliasing
- Creates digital grit and warmth
- Aphex Twin, Autechre signature sound
- Combined with filtered noise for texture
		""",
		"parameters": {
			"bits": {"type": "int", "min": 4, "max": 16, "default": 8, "label": "Bit Depth"},
			"sample_rate": {"type": "float", "min": 0.1, "max": 1, "default": 0.5, "label": "Sample Rate"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Drive"},
			"decay": {"type": "float", "min": 0.1, "max": 1, "default": 0.3, "unit": "s", "label": "Decay"}
		}
	},
	
	"ambient_drone": {
		"name": "Ambient Drone",
		"type": "pad",
		"genre": "ambient_idm",
		"machine": "EMS VCS3 / Modular",
		"year": 1969,
		"description": "Evolving tonal mass. Brian Eno, Tim Hecker.",
		"signal_flow": "Multiple OSC → Slow modulation → Reverb/Delay",
		"tech_notes": """
Drone characteristics:
- Multiple oscillators at near-unison
- Very slow LFO modulation (0.01-0.1 Hz)
- Rich harmonic content
- Often uses just intonation intervals
- Creates sense of space and timelessness
		""",
		"parameters": {
			"voices": {"type": "int", "min": 2, "max": 8, "default": 4, "label": "Voices"},
			"detune": {"type": "float", "min": 0, "max": 0.1, "default": 0.02, "label": "Detune"},
			"drift": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Drift"},
			"brightness": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Brightness"},
			"reverb": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "Reverb"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# DISCO / ITALO ELEMENTS
	# ─────────────────────────────────────────────────────────────────────
	"moroder_seq": {
		"name": "Moroder Sequencer",
		"type": "bass",
		"genre": "disco_funk",
		"machine": "Moog Modular",
		"year": 1977,
		"description": "16th note pulse driving everything. 'I Feel Love'.",
		"signal_flow": "VCO → VCF (sequenced) → VCA (gated)",
		"tech_notes": """
Moroder sequencer bass ('I Feel Love'):
- Constant 16th notes
- Single note or simple pattern
- Filter modulated by sequence
- Creates hypnotic, driving pulse
- Foundation of electronic dance music
		""",
		"parameters": {
			"waveform": {"type": "option", "options": ["saw", "square", "pulse"], "default": "saw", "label": "Wave"},
			"cutoff": {"type": "float", "min": 200, "max": 3000, "default": 800, "unit": "Hz", "label": "Filter"},
			"env_amount": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Env Amount"},
			"decay": {"type": "float", "min": 0.02, "max": 0.2, "default": 0.06, "unit": "s", "label": "Decay"},
			"resonance": {"type": "float", "min": 0, "max": 0.7, "default": 0.3, "label": "Resonance"}
		}
	},
	
	"disco_strings": {
		"name": "Disco String Machine",
		"type": "pad",
		"genre": "disco_funk",
		"machine": "Solina / Eminent",
		"year": 1974,
		"description": "Lush ensemble strings. The disco orchestral sound.",
		"signal_flow": "Divide-down OSC → Ensemble → Phaser",
		"tech_notes": """
String machine (Solina, Eminent):
- Paraphonic divide-down oscillators
- Built-in ensemble/chorus effect
- Creates lush, wide string pad
- Often with phaser
- The orchestral disco sound
		""",
		"parameters": {
			"voices": {"type": "option", "options": ["violin", "cello", "strings"], "default": "strings", "label": "Voice"},
			"ensemble": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "Ensemble"},
			"phaser": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Phaser"},
			"attack": {"type": "float", "min": 0.05, "max": 1, "default": 0.3, "unit": "s", "label": "Attack"},
			"release": {"type": "float", "min": 0.1, "max": 2, "default": 0.8, "unit": "s", "label": "Release"}
		}
	},
	
	"disco_bass": {
		"name": "Disco Bass",
		"type": "bass",
		"genre": "disco_funk",
		"machine": "Minimoog / ARP Odyssey",
		"year": 1975,
		"description": "Funky octave bass. Driving the groove.",
		"signal_flow": "VCO → VCF (envelope) → VCA",
		"tech_notes": """
Disco bass characteristics:
- Often octave patterns (root + octave)
- Punchy envelope with fast attack
- Filter envelope for 'wow' on attack
- Sits behind kick, doesn't overpower
- Bernard Edwards (Chic) style
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 200, "max": 2000, "default": 600, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.6, "default": 0.2, "label": "Resonance"},
			"env_amount": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Filter Env"},
			"decay": {"type": "float", "min": 0.05, "max": 0.5, "default": 0.15, "unit": "s", "label": "Decay"}
		}
	},
	
	"four_floor_kick": {
		"name": "Four-on-the-Floor Kick",
		"type": "drum",
		"genre": "disco_funk",
		"machine": "Acoustic / LinnDrum",
		"year": 1975,
		"description": "The disco heartbeat. Steady quarter notes.",
		"signal_flow": "Sampled kick → Compression → Output",
		"tech_notes": """
Disco kick characteristics:
- Punchy but not boomy
- Clear attack for danceability
- Consistent level (compressed)
- Often layered with clap on 2&4
- The foundation of dance music
		""",
		"parameters": {
			"tune": {"type": "float", "min": 50, "max": 100, "default": 70, "unit": "Hz", "label": "Tune"},
			"punch": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Punch"},
			"decay": {"type": "float", "min": 0.1, "max": 0.4, "default": 0.2, "unit": "s", "label": "Decay"},
			"click": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Click"}
		}
	},
	
	"disco_hihat": {
		"name": "Disco Hi-Hat",
		"type": "drum",
		"genre": "disco_funk",
		"machine": "Acoustic / LinnDrum",
		"year": 1975,
		"description": "Open hat on the offbeat. The disco shimmer.",
		"signal_flow": "Sample → HPF → Output",
		"tech_notes": """
Disco hi-hat pattern:
- Closed hats on 8ths or 16ths
- OPEN hat on offbeats (+ of 2, + of 4)
- Creates the 'chick-a' groove
- Bright, crisp, cutting through mix
- Essential disco rhythm element
		""",
		"parameters": {
			"decay": {"type": "float", "min": 0.05, "max": 0.5, "default": 0.15, "unit": "s", "label": "Decay"},
			"open_decay": {"type": "float", "min": 0.1, "max": 0.8, "default": 0.4, "unit": "s", "label": "Open Decay"},
			"tone": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Tone"},
			"mix": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Open/Closed Mix"}
		}
	},
	
	"solina_pad": {
		"name": "Solina String Ensemble",
		"type": "pad",
		"genre": "disco_funk",
		"machine": "ARP/Solina String Ensemble",
		"year": 1974,
		"description": "THE string machine. Lush, wide, iconic.",
		"signal_flow": "Divide-down → Ensemble chorus → Output",
		"tech_notes": """
Solina characteristics:
- Divide-down oscillators (paraphonic)
- 3-phase BBD chorus creates width
- Violin + Viola + Cello + Bass sections
- No velocity, simple on/off
- Jean-Michel Jarre, disco, new wave
		""",
		"parameters": {
			"section": {"type": "option", "options": ["violin", "viola", "cello", "bass", "full"], "default": "full", "label": "Section"},
			"ensemble": {"type": "float", "min": 0, "max": 1, "default": 0.8, "label": "Ensemble"},
			"attack": {"type": "float", "min": 0.01, "max": 0.5, "default": 0.1, "unit": "s", "label": "Attack"},
			"release": {"type": "float", "min": 0.1, "max": 2, "default": 0.6, "unit": "s", "label": "Release"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# 70s PROG ELEMENTS
	# ─────────────────────────────────────────────────────────────────────
	"minimoog_lead": {
		"name": "Minimoog Lead",
		"type": "lead",
		"genre": "prog_rock",
		"machine": "Minimoog Model D",
		"year": 1970,
		"description": "Screaming portamento lead. Keith Emerson, Rick Wakeman.",
		"signal_flow": "3x VCO → Mixer → 24dB VCF → VCA",
		"tech_notes": """
Minimoog lead sound:
- 3 oscillators (often saw + saw + pulse)
- Slight detune for thickness
- 24dB ladder filter with resonance
- Heavy portamento/glide
- Filter envelope for expression
The sound of prog rock solos.
		""",
		"parameters": {
			"osc_mix": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "OSC Mix"},
			"detune": {"type": "float", "min": 0, "max": 0.02, "default": 0.005, "label": "Detune"},
			"cutoff": {"type": "float", "min": 500, "max": 8000, "default": 2500, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.9, "default": 0.5, "label": "Resonance"},
			"portamento": {"type": "float", "min": 0, "max": 0.5, "default": 0.15, "unit": "s", "label": "Portamento"},
			"filter_env": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Filter Env"}
		}
	},
	
	"motorik_beat": {
		"name": "Motorik Beat",
		"type": "drum",
		"genre": "prog_rock",
		"machine": "Acoustic drums / 808",
		"year": 1971,
		"description": "Relentless 4/4 pulse. Kraftwerk, Neu!, Can.",
		"signal_flow": "Kick (4/4) + Snare (2/4) + Driving hats",
		"tech_notes": """
Motorik (German: 'motor skill'):
- Steady, hypnotic 4/4
- Kick on every beat
- Snare on 2 and 4
- Driving hi-hats (8th or 16th)
- Creates trance-like state
The Autobahn rhythm.
		""",
		"parameters": {
			"tempo": {"type": "float", "min": 100, "max": 140, "default": 120, "unit": "BPM", "label": "Tempo"},
			"hat_pattern": {"type": "option", "options": ["8th", "16th"], "default": "8th", "label": "Hat Pattern"},
			"kick_punch": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Kick Punch"},
			"snare_tone": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Snare Tone"}
		}
	},
	
	"cs80_brass": {
		"name": "CS-80 Brass (Vangelis)",
		"type": "lead",
		"genre": "prog_rock",
		"machine": "Yamaha CS-80",
		"year": 1977,
		"description": "Expressive polyphonic brass. Vangelis 'Blade Runner'.",
		"signal_flow": "2x VCO per voice → HPF + LPF → Ring mod → VCA",
		"tech_notes": """
CS-80 characteristics:
- Polyphonic (8 voices)
- Ribbon controller for expression
- Ring modulation for metallic edge
- Aftertouch affects filter + vibrato
- The Blade Runner brass sound
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 500, "max": 6000, "default": 2000, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.6, "default": 0.3, "label": "Resonance"},
			"brilliance": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Brilliance"},
			"ring_mod": {"type": "float", "min": 0, "max": 1, "default": 0.2, "label": "Ring Mod"},
			"attack": {"type": "float", "min": 0.01, "max": 0.5, "default": 0.08, "unit": "s", "label": "Attack"},
			"vibrato": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Vibrato"}
		}
	},
	
	"mellotron_strings": {
		"name": "Mellotron Strings",
		"type": "pad",
		"genre": "prog_rock",
		"machine": "Mellotron M400",
		"year": 1963,
		"description": "Tape-based string samples. King Crimson, Genesis, Yes.",
		"signal_flow": "Tape playback → Simple amp → Output",
		"tech_notes": """
Mellotron characteristics:
- Real tape strips of orchestra recordings
- 8 second limit per note (tape length)
- Slight wow/flutter from tape mechanics
- Lo-fi warmth from 1960s recordings
- The definitive prog rock texture
		""",
		"parameters": {
			"brightness": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Brightness"},
			"attack": {"type": "float", "min": 0.01, "max": 0.5, "default": 0.1, "unit": "s", "label": "Attack"},
			"release": {"type": "float", "min": 0.1, "max": 2, "default": 0.5, "unit": "s", "label": "Release"},
			"wobble": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Tape Wobble"}
		}
	},
	
	"moog_bass": {
		"name": "Moog Bass",
		"type": "bass",
		"genre": "prog_rock",
		"machine": "Minimoog Model D",
		"year": 1970,
		"description": "Fat analog bass. The foundation of synth bass sounds.",
		"signal_flow": "3x VCO → Mixer → 24dB Ladder VCF → VCA",
		"tech_notes": """
Moog bass characteristics:
- 3 oscillators for massive low end
- 24dB/oct ladder filter = smooth rolloff
- Sub oscillator for weight
- Often uses square wave for punch
- Every synth bass since owes it something
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 80, "max": 2000, "default": 400, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.8, "default": 0.3, "label": "Resonance"},
			"osc_mix": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "OSC Mix"},
			"sub": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Sub Level"},
			"decay": {"type": "float", "min": 0.05, "max": 1, "default": 0.3, "unit": "s", "label": "Decay"}
		}
	},
	
	"arp_sequence": {
		"name": "ARP Sequencer",
		"type": "lead",
		"genre": "prog_rock",
		"machine": "ARP 2600 + Sequencer",
		"year": 1971,
		"description": "Analog sequencer patterns. Tangerine Dream, Klaus Schulze.",
		"signal_flow": "VCO → VCF → VCA (sequencer CV to all)",
		"tech_notes": """
Analog sequencer characteristics:
- Step sequencer controls pitch + filter + amp
- 8-16 step patterns typical
- Clock-synced to create hypnotic patterns
- Slight instability = organic feel
- Berlin School electronic music foundation
		""",
		"parameters": {
			"steps": {"type": "int", "min": 4, "max": 16, "default": 8, "label": "Steps"},
			"rate": {"type": "float", "min": 2, "max": 16, "default": 8, "unit": "Hz", "label": "Rate"},
			"cutoff": {"type": "float", "min": 200, "max": 4000, "default": 1000, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.8, "default": 0.4, "label": "Resonance"},
			"glide": {"type": "float", "min": 0, "max": 0.2, "default": 0.05, "unit": "s", "label": "Glide"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# HIP-HOP / TRAP ELEMENTS (NEW)
	# ─────────────────────────────────────────────────────────────────────
	"tr808_snare": {
		"name": "TR-808 Snare",
		"type": "drum",
		"genre": "hip_hop",
		"machine": "Roland TR-808",
		"year": 1980,
		"description": "Two tuned sines + noise. The foundation of hip-hop drums.",
		"signal_flow": "2x Sine OSC (180Hz, 330Hz) + Noise → BPF → VCA",
		"tech_notes": """
808 Snare anatomy:
- Body: Two sine oscillators at ~180Hz and ~330Hz
- Snappy: Band-pass filtered noise (1-5kHz)
- Tone knob balances body vs noise
- Snappy controls noise amount
- Tunable body frequencies
The crisp, punchy hip-hop snare.
		""",
		"parameters": {
			"tune": {"type": "float", "min": 120, "max": 250, "default": 180, "unit": "Hz", "label": "Tune"},
			"tone": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Tone"},
			"snappy": {"type": "float", "min": 0, "max": 1, "default": 0.6, "label": "Snappy"},
			"decay": {"type": "float", "min": 0.05, "max": 0.5, "default": 0.2, "unit": "s", "label": "Decay"}
		}
	},
	
	"tr808_hihat": {
		"name": "TR-808 Hi-Hat",
		"type": "drum",
		"genre": "hip_hop",
		"machine": "Roland TR-808",
		"year": 1980,
		"description": "Darker than 909. More tick than sizzle.",
		"signal_flow": "6x Square OSC → Mixer → VCF (darker) → VCA",
		"tech_notes": """
808 hi-hat vs 909:
- Same 6 square wave concept
- But filtered darker
- More 'tick' than 'sizzle'
- Shorter, tighter decay typical
- The classic hip-hop hat sound
		""",
		"parameters": {
			"decay": {"type": "float", "min": 0.02, "max": 0.3, "default": 0.08, "unit": "s", "label": "Decay"},
			"tune": {"type": "float", "min": 0.5, "max": 2, "default": 1, "label": "Tune"},
			"tone": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Tone (Dark/Bright)"}
		}
	},
	
	"trap_hihat": {
		"name": "Trap Hi-Hat",
		"type": "drum",
		"genre": "hip_hop",
		"machine": "808 + DAW",
		"year": 2012,
		"description": "Fast rolls, triplets, pitch modulation. Modern trap essential.",
		"signal_flow": "808 Hat → Rapid Trigger → Pitch Mod → Output",
		"tech_notes": """
Trap hi-hat characteristics:
- Based on 808 hat but rapid-fired
- 32nd note and triplet rolls
- Pitch modulation for variation
- Velocity variation for groove
- Defines modern trap/drill
		""",
		"parameters": {
			"tempo": {"type": "float", "min": 100, "max": 180, "default": 140, "unit": "BPM", "label": "Tempo"},
			"roll_speed": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "Roll Speed"},
			"pitch_mod": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Pitch Mod"},
			"decay": {"type": "float", "min": 0.01, "max": 0.1, "default": 0.03, "unit": "s", "label": "Decay"}
		}
	},
	
	"808_bass": {
		"name": "808 Sub Bass",
		"type": "bass",
		"genre": "hip_hop",
		"machine": "Roland TR-808 (extended)",
		"year": 1980,
		"description": "Long 808 kick as a bass instrument. Foundation of trap.",
		"signal_flow": "Sine OSC → Pitch Env → VCA (long decay) → Saturation",
		"tech_notes": """
808 as bass instrument:
- Extended decay makes it a bass note
- Pitch-trackable (plays melodies)
- Sub-heavy (30-60Hz fundamental)
- Often saturated for presence
- THE trap/drill bass sound
		""",
		"parameters": {
			"tune": {"type": "float", "min": 30, "max": 80, "default": 45, "unit": "Hz", "label": "Tune"},
			"decay": {"type": "float", "min": 0.3, "max": 3, "default": 1.5, "unit": "s", "label": "Decay"},
			"punch": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Punch"},
			"saturation": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Saturation"},
			"sub": {"type": "float", "min": 0, "max": 1, "default": 0.8, "label": "Sub Level"}
		}
	},
	
	"sp1200_crunch": {
		"name": "SP-1200 Crunch",
		"type": "effect",
		"genre": "hip_hop",
		"machine": "E-mu SP-1200",
		"year": 1987,
		"description": "12-bit, 26kHz - THE golden era hip-hop character.",
		"signal_flow": "Input → 26kHz Resample → 12-bit Quantize → SSM Filter",
		"tech_notes": """
SP-1200 magic:
- 12-bit sampling (2048 levels)
- 26.04kHz sample rate (aliasing!)
- SSM filter chips add warmth
- 10 second sample time forced creativity
- Marley Marl, Pete Rock, DJ Premier
		""",
		"parameters": {
			"bits": {"type": "int", "min": 8, "max": 16, "default": 12, "label": "Bit Depth"},
			"sample_rate": {"type": "float", "min": 0.3, "max": 1, "default": 0.59, "label": "Sample Rate"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Drive"},
			"bass_boost": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Bass Boost"}
		}
	},
	
	# ─────────────────────────────────────────────────────────────────────
	# SYNTHWAVE ELEMENTS (NEW)
	# ─────────────────────────────────────────────────────────────────────
	"acid_lead": {
		"name": "Acid Lead",
		"type": "lead",
		"genre": "acid_house",
		"machine": "Roland TB-303 (pitched lead)",
		"year": 1987,
		"description": "Sharp resonant acid lead for hooks layered over the bassline.",
		"signal_flow": "Saw OSC -> Resonant LPF -> Fast envelope -> Delay",
		"tech_notes": """
Acid lead profile:
- Higher register than the bassline
- Resonance-forward tone
- Fast decay for rhythmic phrasing
- Optional glide and delay for phrases
		""",
		"parameters": {
			"frequency": {"type": "float", "min": 110, "max": 1200, "default": 330, "unit": "Hz", "label": "Freq"},
			"cutoff": {"type": "float", "min": 300, "max": 4500, "default": 1600, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.98, "default": 0.72, "label": "Resonance"},
			"decay": {"type": "float", "min": 0.02, "max": 0.6, "default": 0.12, "unit": "s", "label": "Decay"},
			"glide": {"type": "float", "min": 0, "max": 0.2, "default": 0.04, "unit": "s", "label": "Glide"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Drive"}
		}
	},

	"trap_bell": {
		"name": "Trap Bell",
		"type": "lead",
		"genre": "hip_hop",
		"machine": "FM Bell Synth",
		"year": 2010,
		"description": "Dark FM bell for trap melodies and sparse motifs.",
		"signal_flow": "FM pair -> Short envelope -> Optional delay/reverb",
		"tech_notes": """
Trap bell traits:
- Metallic FM overtone stack
- Punchy attack with medium decay
- Works for minimal motifs and countermelodies
		""",
		"parameters": {
			"frequency": {"type": "float", "min": 160, "max": 1800, "default": 620, "unit": "Hz", "label": "Freq"},
			"mod_ratio": {"type": "float", "min": 0.5, "max": 8, "default": 2.5, "label": "FM Ratio"},
			"mod_index": {"type": "float", "min": 0, "max": 12, "default": 4.2, "label": "FM Index"},
			"decay": {"type": "float", "min": 0.08, "max": 2.2, "default": 0.7, "unit": "s", "label": "Decay"},
			"shimmer": {"type": "float", "min": 0, "max": 1, "default": 0.25, "label": "Shimmer"}
		}
	},

	"trap_pad": {
		"name": "Trap Pad",
		"type": "pad",
		"genre": "hip_hop",
		"machine": "Dark Analog Pad",
		"year": 2014,
		"description": "Moody filtered pad layer for modern trap atmospheres.",
		"signal_flow": "Detuned OSC stack -> LPF -> Slow envelope",
		"tech_notes": """
Trap pad profile:
- Dark cutoff with moderate resonance
- Slow attack and long release
- Subtle movement from detune/LFO drift
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 120, "max": 3500, "default": 700, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.85, "default": 0.24, "label": "Resonance"},
			"detune": {"type": "float", "min": 0, "max": 0.08, "default": 0.018, "label": "Detune"},
			"attack": {"type": "float", "min": 0.03, "max": 2.5, "default": 0.6, "unit": "s", "label": "Attack"},
			"release": {"type": "float", "min": 0.05, "max": 4.5, "default": 1.6, "unit": "s", "label": "Release"}
		}
	},

	"noise_riser": {
		"name": "Noise Riser",
		"type": "effect",
		"genre": "ambient_idm",
		"machine": "Noise + Filter Automation",
		"year": 2000,
		"description": "Transition riser for builds and section changes.",
		"signal_flow": "Noise source -> High-pass sweep -> Drive",
		"tech_notes": """
Riser behavior:
- Noise gets brighter over time
- Amplitude grows toward the end
- Optional mild distortion for intensity
		""",
		"parameters": {
			"duration": {"type": "float", "min": 0.4, "max": 6, "default": 2.4, "unit": "s", "label": "Duration"},
			"start_hz": {"type": "float", "min": 80, "max": 4000, "default": 250, "unit": "Hz", "label": "Start HPF"},
			"end_hz": {"type": "float", "min": 500, "max": 14000, "default": 9000, "unit": "Hz", "label": "End HPF"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.2, "label": "Drive"},
			"level": {"type": "float", "min": 0.05, "max": 1, "default": 0.5, "label": "Level"}
		}
	},

	"noise_fall": {
		"name": "Noise Downlifter",
		"type": "effect",
		"genre": "ambient_idm",
		"machine": "Noise + Filter Automation",
		"year": 2000,
		"description": "Downlifter for turnarounds, drops, and phrase endings.",
		"signal_flow": "Noise source -> High-pass sweep down -> Envelope",
		"tech_notes": """
Downlifter behavior:
- Starts bright and wide
- Closes filter while decaying
- Good for post-drop or break transitions
		""",
		"parameters": {
			"duration": {"type": "float", "min": 0.3, "max": 6, "default": 2.0, "unit": "s", "label": "Duration"},
			"start_hz": {"type": "float", "min": 500, "max": 14000, "default": 9500, "unit": "Hz", "label": "Start HPF"},
			"end_hz": {"type": "float", "min": 80, "max": 5000, "default": 260, "unit": "Hz", "label": "End HPF"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.18, "label": "Drive"},
			"level": {"type": "float", "min": 0.05, "max": 1, "default": 0.45, "label": "Level"}
		}
	},

	"impact_hit": {
		"name": "Impact Hit",
		"type": "effect",
		"genre": "ambient_idm",
		"machine": "Hybrid synth impact",
		"year": 2005,
		"description": "Low-end impact with noisy transient for section accents.",
		"signal_flow": "Low sine drop + noise burst -> Saturation",
		"tech_notes": """
Impact design:
- Sub thump with short pitch drop
- Broadband transient for attack
- Tail decays quickly to avoid masking
		""",
		"parameters": {
			"fundamental": {"type": "float", "min": 35, "max": 140, "default": 62, "unit": "Hz", "label": "Fundamental"},
			"pitch_drop": {"type": "float", "min": 0, "max": 24, "default": 10, "label": "Pitch Drop"},
			"noise": {"type": "float", "min": 0, "max": 1, "default": 0.35, "label": "Noise"},
			"decay": {"type": "float", "min": 0.05, "max": 1.2, "default": 0.28, "unit": "s", "label": "Decay"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.25, "label": "Drive"}
		}
	},

	# ----------------------------------------------------------------------------
	# VR GENRE EXPANSION: DUB TECHNO / UK GARAGE / NEUROFUNK
	# ----------------------------------------------------------------------------
	"dub_sub": {
		"name": "Dub Sub Bass",
		"type": "bass",
		"genre": "dub_techno",
		"machine": "Sine Sub Synth",
		"year": 1993,
		"description": "Deep mono sub foundation for dub techno pressure and space.",
		"signal_flow": "Sine OSC -> Gentle saturation -> VCA",
		"tech_notes": """
Dub techno sub:
- Fundamental-led low end
- Minimal harmonic content
- Long but controlled tail
		""",
		"parameters": {
			"frequency": {"type": "float", "min": 30, "max": 90, "default": 45, "unit": "Hz", "label": "Freq"},
			"decay": {"type": "float", "min": 0.2, "max": 2.5, "default": 1.2, "unit": "s", "label": "Decay"},
			"saturation": {"type": "float", "min": 0, "max": 1, "default": 0.12, "label": "Saturation"},
			"drift": {"type": "float", "min": 0, "max": 1, "default": 0.08, "label": "Drift"}
		}
	},

	"dub_chord": {
		"name": "Dub Chord",
		"type": "pad",
		"genre": "dub_techno",
		"machine": "Juno/MKS Chord Stab",
		"year": 1993,
		"description": "Filtered minor chord stab designed for long delays and reverb sends.",
		"signal_flow": "Detuned saw stack -> LPF -> Amp envelope",
		"tech_notes": """
Dub chord profile:
- Soft attack then decaying body
- Mid-focused tone for delay throws
- Slight detune for width
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 200, "max": 4000, "default": 900, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 0.9, "default": 0.35, "label": "Resonance"},
			"attack": {"type": "float", "min": 0.005, "max": 0.5, "default": 0.03, "unit": "s", "label": "Attack"},
			"decay": {"type": "float", "min": 0.1, "max": 2, "default": 0.7, "unit": "s", "label": "Decay"},
			"detune": {"type": "float", "min": 0, "max": 0.06, "default": 0.015, "label": "Detune"}
		}
	},

	"dub_echo_stab": {
		"name": "Dub Echo Stab",
		"type": "lead",
		"genre": "dub_techno",
		"machine": "Analog Stab + Tape Echo",
		"year": 1994,
		"description": "Short stab designed to be thrown into delay feedback.",
		"signal_flow": "Saw/Pulse blend -> LPF -> Short envelope -> Echo",
		"tech_notes": """
Echo stab role:
- Short transient source
- Midrange focus for delay clarity
- Slight drive for analog edge
		""",
		"parameters": {
			"frequency": {"type": "float", "min": 120, "max": 1200, "default": 320, "unit": "Hz", "label": "Freq"},
			"decay": {"type": "float", "min": 0.03, "max": 1, "default": 0.25, "unit": "s", "label": "Decay"},
			"echo_time": {"type": "float", "min": 0.1, "max": 0.8, "default": 0.38, "unit": "s", "label": "Echo Time"},
			"echo_feedback": {"type": "float", "min": 0, "max": 0.95, "default": 0.58, "label": "Feedback"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.2, "label": "Drive"}
		}
	},

	"ukg_shuff_hat": {
		"name": "UKG Shuffle Hat",
		"type": "drum",
		"genre": "uk_garage",
		"machine": "Sampled Hat + Groove Sequencing",
		"year": 1999,
		"description": "Skippy shuffled hat articulation for 2-step swing.",
		"signal_flow": "Noise/metal source -> fast env -> groove accents",
		"tech_notes": """
2-step hat behavior:
- Off-grid shuffle feel
- Ghost accents and roll-ins
- Bright but short sustain
		""",
		"parameters": {
			"tempo": {"type": "float", "min": 120, "max": 140, "default": 132, "unit": "BPM", "label": "Tempo"},
			"swing": {"type": "float", "min": 0, "max": 0.4, "default": 0.22, "label": "Swing"},
			"decay": {"type": "float", "min": 0.01, "max": 0.2, "default": 0.05, "unit": "s", "label": "Decay"},
			"tone": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "Tone"}
		}
	},

	"ukg_wobble_bass": {
		"name": "UKG Wobble Bass",
		"type": "bass",
		"genre": "uk_garage",
		"machine": "Square/Sub Hybrid",
		"year": 2000,
		"description": "Warm bouncing bass with medium-rate filter wobble.",
		"signal_flow": "Square+sub -> LPF (LFO mod) -> Saturation",
		"tech_notes": """
Garage bass profile:
- Round low end with rhythmic movement
- Filter wobble synced to groove feel
- Enough harmonics for small speakers
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 120, "max": 2000, "default": 480, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 1, "default": 0.35, "label": "Resonance"},
			"lfo_rate": {"type": "float", "min": 0.2, "max": 12, "default": 3.2, "unit": "Hz", "label": "LFO Rate"},
			"lfo_depth": {"type": "float", "min": 0, "max": 1, "default": 0.45, "label": "LFO Depth"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.25, "label": "Drive"}
		}
	},

	"ukg_organ_stab": {
		"name": "UKG Organ Stab",
		"type": "keys",
		"genre": "uk_garage",
		"machine": "M1-style Organ",
		"year": 1998,
		"description": "Bright organ chord hit used for syncopated garage phrasing.",
		"signal_flow": "Organ tone -> fast amp env -> chorus",
		"tech_notes": """
Garage organ:
- Snappy chord attack
- Short decay for rhythm slots
- Slight chorus for width
		""",
		"parameters": {
			"brightness": {"type": "float", "min": 0, "max": 1, "default": 0.65, "label": "Brightness"},
			"decay": {"type": "float", "min": 0.05, "max": 1.5, "default": 0.35, "unit": "s", "label": "Decay"},
			"chorus": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Chorus"},
			"detune": {"type": "float", "min": 0, "max": 0.03, "default": 0.006, "label": "Detune"}
		}
	},

	"ukg_pluck": {
		"name": "UKG Pluck",
		"type": "lead",
		"genre": "uk_garage",
		"machine": "Digital Pluck Synth",
		"year": 2001,
		"description": "Snappy pluck lead for top hooks and call-response motifs.",
		"signal_flow": "Saw/Pulse -> resonant LPF -> pluck envelope",
		"tech_notes": """
Pluck role:
- Fast transient definition
- Mid/high presence
- Short delay support
		""",
		"parameters": {
			"cutoff": {"type": "float", "min": 300, "max": 6000, "default": 1800, "unit": "Hz", "label": "Filter"},
			"resonance": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Resonance"},
			"decay": {"type": "float", "min": 0.03, "max": 0.8, "default": 0.22, "unit": "s", "label": "Decay"},
			"pluck": {"type": "float", "min": 0, "max": 1, "default": 0.8, "label": "Pluck"},
			"delay_mix": {"type": "float", "min": 0, "max": 1, "default": 0.22, "label": "Delay Mix"}
		}
	},

	"ukg_vocal_chop": {
		"name": "UKG Vocal Chop",
		"type": "effect",
		"genre": "uk_garage",
		"machine": "Formant Synth Chop",
		"year": 2000,
		"description": "Synthetic vocal-style chop for hook punctuation.",
		"signal_flow": "Pulse source -> formant shaping -> chopped gate",
		"tech_notes": """
Vocal chop traits:
- Formant peaks around speech bands
- Rhythmic slicing
- Optional grit for texture
		""",
		"parameters": {
			"formant": {"type": "float", "min": 0.5, "max": 2, "default": 1.15, "label": "Formant"},
			"slice_rate": {"type": "float", "min": 2, "max": 16, "default": 8, "unit": "Hz", "label": "Slice Rate"},
			"decay": {"type": "float", "min": 0.05, "max": 1, "default": 0.3, "unit": "s", "label": "Decay"},
			"grit": {"type": "float", "min": 0, "max": 1, "default": 0.3, "label": "Grit"},
			"width": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Width"}
		}
	},

	"neuro_mid_bass": {
		"name": "Neuro Mid Bass",
		"type": "bass",
		"genre": "neurofunk",
		"machine": "FM + Filter Morph Bass",
		"year": 2008,
		"description": "Aggressive moving mid-bass with FM edge and filter motion.",
		"signal_flow": "FM core -> LPF/BPF morph -> distortion",
		"tech_notes": """
Neuro bass traits:
- Dense mids with articulated movement
- LFO-driven timbre changes
- Controlled low-end to keep kick clear
		""",
		"parameters": {
			"frequency": {"type": "float", "min": 50, "max": 220, "default": 90, "unit": "Hz", "label": "Freq"},
			"mod_ratio": {"type": "float", "min": 0.5, "max": 6, "default": 1.8, "label": "FM Ratio"},
			"mod_index": {"type": "float", "min": 0, "max": 12, "default": 6, "label": "FM Index"},
			"cutoff": {"type": "float", "min": 100, "max": 3000, "default": 800, "unit": "Hz", "label": "Filter"},
			"lfo_rate": {"type": "float", "min": 0.2, "max": 12, "default": 4.5, "unit": "Hz", "label": "LFO Rate"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.45, "label": "Drive"}
		}
	},

	"neuro_stab": {
		"name": "Neuro Stab",
		"type": "lead",
		"genre": "neurofunk",
		"machine": "Resonant Stab Synth",
		"year": 2010,
		"description": "Sharp transient stab for syncopated neuro callouts.",
		"signal_flow": "Saw stack -> LPF -> short amp envelope",
		"tech_notes": """
Stab usage:
- Tight envelope
- Saturated upper mids
- Supports rhythmic punctuation
		""",
		"parameters": {
			"frequency": {"type": "float", "min": 100, "max": 1500, "default": 240, "unit": "Hz", "label": "Freq"},
			"attack": {"type": "float", "min": 0, "max": 0.05, "default": 0.005, "unit": "s", "label": "Attack"},
			"decay": {"type": "float", "min": 0.05, "max": 0.7, "default": 0.22, "unit": "s", "label": "Decay"},
			"cutoff": {"type": "float", "min": 500, "max": 6000, "default": 2200, "unit": "Hz", "label": "Filter"},
			"drive": {"type": "float", "min": 0, "max": 1, "default": 0.4, "label": "Drive"}
		}
	},

	"neuro_laser": {
		"name": "Neuro Laser FX",
		"type": "effect",
		"genre": "neurofunk",
		"machine": "Pitch Envelope Synth FX",
		"year": 2009,
		"description": "Descending laser-style hit for fills and transitions.",
		"signal_flow": "Sine/Pulse blend -> pitch envelope -> resonance/drive",
		"tech_notes": """
Laser profile:
- Fast pitch sweep
- Resonant edge
- Optional noise burst at onset
		""",
		"parameters": {
			"start_freq": {"type": "float", "min": 400, "max": 4000, "default": 1800, "unit": "Hz", "label": "Start Freq"},
			"end_freq": {"type": "float", "min": 40, "max": 800, "default": 120, "unit": "Hz", "label": "End Freq"},
			"decay": {"type": "float", "min": 0.05, "max": 1, "default": 0.35, "unit": "s", "label": "Decay"},
			"resonance": {"type": "float", "min": 0, "max": 1, "default": 0.65, "label": "Resonance"},
			"noise": {"type": "float", "min": 0, "max": 1, "default": 0.15, "label": "Noise"}
		}
	},

	"linn_kick": {
		"name": "LinnDrum Kick",
		"type": "drum",
		"genre": "synthwave",
		"machine": "LinnDrum / LM-1",
		"year": 1982,
		"description": "12-bit sampled kick. Punchy 80s character.",
		"signal_flow": "Sample (12-bit) → Output",
		"tech_notes": """
LinnDrum kick:
- First realistic drum machine samples
- 12-bit, 28kHz sample rate
- Punchy, tight, distinctive thud
- Prince, Phil Collins, countless 80s hits
- Tighter than 808, punchier than 909
		""",
		"parameters": {
			"tune": {"type": "float", "min": 60, "max": 120, "default": 80, "unit": "Hz", "label": "Tune"},
			"decay": {"type": "float", "min": 0.05, "max": 0.3, "default": 0.15, "unit": "s", "label": "Decay"},
			"punch": {"type": "float", "min": 0, "max": 1, "default": 0.7, "label": "Punch"},
			"tone": {"type": "float", "min": 0, "max": 1, "default": 0.5, "label": "Tone"}
		}
	}
}

# ═══════════════════════════════════════════════════════════════════════════
# UI COMPONENTS
# ═══════════════════════════════════════════════════════════════════════════

var _split: HSplitContainer
var _genre_tree: Tree
var _detail_panel: VBoxContainer
var _param_container: VBoxContainer
var _waveform: Control
var _audio_player: AudioStreamPlayer

var _current_genre: String = ""
var _current_element: String = ""
var _current_params: Dictionary = {}
var _param_controls: Dictionary = {}
var _waveform_data: PackedFloat32Array = PackedFloat32Array()

signal element_selected(element_id: String, genre: String)
signal preview_requested(element_id: String, params: Dictionary)


func _ready():
	_build_ui()
	_validate_suites()
	_populate_genres()
	_setup_audio()


func _build_ui():
	_split = HSplitContainer.new()
	_split.set_anchors_preset(Control.PRESET_FULL_RECT)
	_split.split_offset = 300
	add_child(_split)
	
	# Left: Genre tree
	var left = PanelContainer.new()
	left.custom_minimum_size.x = 280
	_split.add_child(left)
	
	var left_vbox = VBoxContainer.new()
	left.add_child(left_vbox)
	
	var title = Label.new()
	title.text = "🎹 SYNTH ELEMENTS BY GENRE"
	title.add_theme_font_size_override("font_size", 16)
	left_vbox.add_child(title)
	
	_genre_tree = Tree.new()
	_genre_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_genre_tree.hide_root = true
	_genre_tree.item_selected.connect(_on_item_selected)
	left_vbox.add_child(_genre_tree)
	
	# Right: Detail panel
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_split.add_child(right_scroll)
	
	_detail_panel = VBoxContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(_detail_panel)
	
	var placeholder = Label.new()
	placeholder.text = "Select a genre and element from the left"
	placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_detail_panel.add_child(placeholder)


func _populate_genres():
	var root = _genre_tree.create_item()
	
	for genre_id in GENRES:
		var genre = GENRES[genre_id]
		
		# Genre header
		var genre_item = _genre_tree.create_item(root)
		genre_item.set_text(0, "%s %s" % [genre.icon, genre.name])
		genre_item.set_metadata(0, {"type": "genre", "id": genre_id})
		genre_item.set_selectable(0, false)
		genre_item.collapsed = false  # Expand by default
		
		# Era/BPM subtitle
		var info_item = _genre_tree.create_item(genre_item)
		info_item.set_text(0, "  %s • %s BPM" % [genre.era, genre.bpm_range])
		info_item.set_selectable(0, false)
		info_item.set_custom_color(0, Color(0.5, 0.5, 0.5))
		
		var suite_status = get_suite_completeness(genre_id)
		var counts: Dictionary = suite_status.get("counts", {})
		var suite_item = _genre_tree.create_item(genre_item)
		suite_item.set_text(
			0,
			"  %s suite r:%d b:%d h:%d hk:%d fx:%d" % [
				"[ok]" if suite_status.get("complete", false) else "[missing]",
				int(counts.get("rhythm", 0)),
				int(counts.get("bass", 0)),
				int(counts.get("harmony", 0)),
				int(counts.get("hook", 0)),
				int(counts.get("fx", 0))
			]
		)
		suite_item.set_selectable(0, false)
		suite_item.set_custom_color(
			0,
			Color(0.45, 0.8, 0.45) if suite_status.get("complete", false) else Color(0.95, 0.6, 0.3)
		)
		
		# Elements
		for element_id in genre.elements:
			if ELEMENTS.has(element_id):
				var element = ELEMENTS[element_id]
				var elem_item = _genre_tree.create_item(genre_item)
				
				var type_icon = _get_type_icon(element.type)
				elem_item.set_text(0, "  %s %s" % [type_icon, element.name])
				elem_item.set_metadata(0, {"type": "element", "id": element_id, "genre": genre_id})


func get_genre_suite(genre_id: String) -> Dictionary:
	if not GENRE_SUITES.has(genre_id):
		return {}
	return GENRE_SUITES[genre_id].duplicate(true)


func get_suite_completeness(genre_id: String) -> Dictionary:
	var suite = get_genre_suite(genre_id)
	var counts: Dictionary = {}
	var missing: Array[String] = []
	var complete = true
	
	for role in SUITE_REQUIREMENTS:
		var required = int(SUITE_REQUIREMENTS[role])
		var role_elements = suite.get(role, [])
		var available = 0
		for element_id in role_elements:
			if ELEMENTS.has(element_id):
				available += 1
		
		counts[role] = available
		if available < required:
			complete = false
			missing.append("%s %d/%d" % [role, available, required])
	
	return {
		"complete": complete,
		"counts": counts,
		"missing": missing
	}


func _validate_suites():
	for genre_id in GENRES:
		var status = get_suite_completeness(genre_id)
		if not status.get("complete", false):
			var missing = status.get("missing", [])
			var missing_txt = ""
			for i in range(missing.size()):
				if i > 0:
					missing_txt += ", "
				missing_txt += str(missing[i])
			push_warning("Incomplete synth suite for %s: %s" % [genre_id, missing_txt])


func _get_type_icon(type: String) -> String:
	match type:
		"bass": return "🎸"
		"drum": return "🥁"
		"pad": return "🎹"
		"lead": return "🎺"
		"keys": return "🎹"
		_: return "🔊"


func _setup_audio():
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "Master"
	add_child(_audio_player)


func _on_item_selected():
	var selected = _genre_tree.get_selected()
	if not selected:
		return
	
	var meta = selected.get_metadata(0)
	if not meta or meta.type != "element":
		return
	
	_current_element = meta.id
	_current_genre = meta.genre
	_load_element(meta.id)
	element_selected.emit(meta.id, meta.genre)


func _load_element(element_id: String):
	if not ELEMENTS.has(element_id):
		return
	
	var element = ELEMENTS[element_id]
	
	# Clear panel
	for child in _detail_panel.get_children():
		child.queue_free()
	_param_controls.clear()
	
	# Init params
	_current_params = {}
	for pname in element.parameters:
		var p = element.parameters[pname]
		_current_params[pname] = p.default
	
	# Header
	var header = Label.new()
	header.text = element.name
	header.add_theme_font_size_override("font_size", 24)
	_detail_panel.add_child(header)
	
	# Machine info
	var machine_lbl = Label.new()
	machine_lbl.text = "🔧 %s (%d)" % [element.machine, element.year]
	machine_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_detail_panel.add_child(machine_lbl)
	
	# Description
	var desc = Label.new()
	desc.text = element.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_panel.add_child(desc)
	
	# Signal flow
	var flow_panel = PanelContainer.new()
	var flow_style = StyleBoxFlat.new()
	flow_style.bg_color = Color(0.1, 0.12, 0.15)
	flow_panel.add_theme_stylebox_override("panel", flow_style)
	_detail_panel.add_child(flow_panel)
	
	var flow_lbl = Label.new()
	flow_lbl.text = "📊 " + element.signal_flow
	flow_lbl.add_theme_font_size_override("font_size", 14)
	flow_panel.add_child(flow_lbl)
	
	# Tech notes (collapsible)
	if element.has("tech_notes"):
		var tech_btn = Button.new()
		tech_btn.text = "📖 Technical Details"
		tech_btn.toggle_mode = true
		_detail_panel.add_child(tech_btn)
		
		var tech_panel = PanelContainer.new()
		tech_panel.visible = false
		_detail_panel.add_child(tech_panel)
		
		var tech_lbl = Label.new()
		tech_lbl.text = element.tech_notes.strip_edges()
		tech_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tech_lbl.add_theme_font_size_override("font_size", 12)
		tech_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
		tech_panel.add_child(tech_lbl)
		
		tech_btn.toggled.connect(func(on): tech_panel.visible = on)
	
	_detail_panel.add_child(HSeparator.new())
	
	# Waveform display
	_waveform = Control.new()
	_waveform.custom_minimum_size = Vector2(0, 100)
	_waveform.draw.connect(_draw_waveform)
	_detail_panel.add_child(_waveform)
	
	# Controls
	var ctrl_hbox = HBoxContainer.new()
	_detail_panel.add_child(ctrl_hbox)
	
	var play_btn = Button.new()
	play_btn.text = "▶️ Preview"
	play_btn.pressed.connect(_on_preview)
	ctrl_hbox.add_child(play_btn)
	
	var stop_btn = Button.new()
	stop_btn.text = "⏹️ Stop"
	stop_btn.pressed.connect(func(): _audio_player.stop())
	ctrl_hbox.add_child(stop_btn)
	
	var rand_btn = Button.new()
	rand_btn.text = "🎲 Randomize"
	rand_btn.pressed.connect(_on_randomize)
	ctrl_hbox.add_child(rand_btn)
	
	_detail_panel.add_child(HSeparator.new())
	
	# Parameters
	var param_title = Label.new()
	param_title.text = "⚙️ PARAMETERS"
	param_title.add_theme_font_size_override("font_size", 16)
	_detail_panel.add_child(param_title)
	
	_param_container = VBoxContainer.new()
	_detail_panel.add_child(_param_container)
	
	for pname in element.parameters:
		var p = element.parameters[pname]
		_create_param_control(pname, p)
	
	_generate_preview()


func _create_param_control(pname: String, p: Dictionary):
	var hbox = HBoxContainer.new()
	_param_container.add_child(hbox)
	
	var label = Label.new()
	label.text = p.get("label", pname.capitalize())
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	match p.type:
		"float":
			var slider = HSlider.new()
			slider.min_value = p.min
			slider.max_value = p.max
			slider.value = p.default
			slider.step = (p.max - p.min) / 100.0
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.value_changed.connect(_on_param_changed.bind(pname))
			hbox.add_child(slider)
			
			var val_lbl = Label.new()
			val_lbl.text = "%.2f" % p.default
			val_lbl.custom_minimum_size.x = 50
			hbox.add_child(val_lbl)
			
			if p.has("unit"):
				var unit_lbl = Label.new()
				unit_lbl.text = p.unit
				unit_lbl.custom_minimum_size.x = 30
				hbox.add_child(unit_lbl)
			
			_param_controls[pname] = {"slider": slider, "label": val_lbl}
		
		"int":
			var spin = SpinBox.new()
			spin.min_value = p.min
			spin.max_value = p.max
			spin.value = p.default
			spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spin.value_changed.connect(_on_param_changed.bind(pname))
			hbox.add_child(spin)
			_param_controls[pname] = {"spinbox": spin}
		
		"option":
			var opt = OptionButton.new()
			for o in p.options:
				opt.add_item(str(o))
			var idx = p.options.find(p.default)
			opt.select(idx if idx >= 0 else 0)
			opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			opt.item_selected.connect(_on_option_changed.bind(pname, p.options))
			hbox.add_child(opt)
			_param_controls[pname] = {"option": opt}


func _on_param_changed(value: float, pname: String):
	_current_params[pname] = value
	if _param_controls.has(pname) and _param_controls[pname].has("label"):
		_param_controls[pname]["label"].text = "%.2f" % value
	_generate_preview()


func _on_option_changed(idx: int, pname: String, options: Array):
	_current_params[pname] = options[idx]
	_generate_preview()


func _on_preview():
	var stream = generate_element(_current_element, _current_params)
	if stream:
		_audio_player.stream = stream
		_audio_player.play()


func _on_randomize():
	if not ELEMENTS.has(_current_element):
		return
	
	var element = ELEMENTS[_current_element]
	for pname in element.parameters:
		var p = element.parameters[pname]
		match p.type:
			"float":
				var v = randf_range(p.min, p.max)
				_current_params[pname] = v
				if _param_controls.has(pname):
					_param_controls[pname]["slider"].value = v
			"int":
				var v = randi_range(p.min, p.max)
				_current_params[pname] = v
				if _param_controls.has(pname):
					_param_controls[pname]["spinbox"].value = v
			"option":
				var idx = randi() % p.options.size()
				_current_params[pname] = p.options[idx]
				if _param_controls.has(pname):
					_param_controls[pname]["option"].select(idx)
	_generate_preview()


func _generate_preview():
	var stream = generate_element(_current_element, _current_params)
	if stream:
		_extract_waveform(stream)
		if _waveform:
			_waveform.queue_redraw()


func _extract_waveform(stream: AudioStreamWAV):
	_waveform_data.clear()
	if not stream:
		return
	
	var data = stream.data
	var step = 4 if stream.stereo else 2
	
	for i in range(0, data.size(), step):
		if i + 1 < data.size():
			var s = data[i] | (data[i+1] << 8)
			if s > 32767:
				s -= 65536
			_waveform_data.append(float(s) / 32768.0)
	
	# Downsample
	if _waveform_data.size() > 512:
		var step_size = _waveform_data.size() / 512.0
		var downsampled = PackedFloat32Array()
		for i in range(512):
			downsampled.append(_waveform_data[int(i * step_size)])
		_waveform_data = downsampled


func _draw_waveform():
	if not _waveform:
		return
	
	var rect = _waveform.get_rect()
	var w = rect.size.x
	var h = rect.size.y
	var mid = h / 2
	
	_waveform.draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.08, 0.1))
	_waveform.draw_line(Vector2(0, mid), Vector2(w, mid), Color(0.25, 0.25, 0.3))
	
	if _waveform_data.size() > 1:
		var points = PackedVector2Array()
		for i in range(_waveform_data.size()):
			var x = float(i) / _waveform_data.size() * w
			var y = mid - _waveform_data[i] * mid * 0.9
			points.append(Vector2(x, y))
		_waveform.draw_polyline(points, Color(0.4, 0.8, 1.0), 1.5)


# ═══════════════════════════════════════════════════════════════════════════
# SOUND GENERATION (delegates to specific generators)
# ═══════════════════════════════════════════════════════════════════════════

func generate_element(element_id: String, params: Dictionary) -> AudioStreamWAV:
	match element_id:
		"tb303_acid": return _gen_303(params)
		"tr909_kick": return _gen_909_kick(params)
		"tr909_hihat": return _gen_909_hat(params)
		"tr909_clap": return _gen_909_clap(params)
		"tr808_kick": return _gen_808_kick(params)
		"detroit_strings": return _gen_juno_pad(params)
		"detroit_stab": return _gen_stab(params)
		"detroit_bass": return _gen_simple_bass(params)
		"house_organ": return _gen_organ(params)
		"house_bass": return _gen_simple_bass(params)
		"hoover_bass": return _gen_hoover(params)
		"rave_stab": return _gen_stab(params)
		"reese_bass": return _gen_reese(params)
		"jungle_sub": return _gen_sub(params)
		"supersaw": return _gen_supersaw(params)
		"gated_snare": return _gen_gated_snare(params)
		"synthwave_bass": return _gen_simple_bass(params)
		"arp_synth": return _gen_arp(params)
		"warm_pad": return _gen_juno_pad(params)
		"lofi_break": return _gen_lofi_drums(params)
		"moroder_seq": return _gen_moroder(params)
		"disco_strings": return _gen_strings(params)
		"minimoog_lead": return _gen_moog_lead(params)
		"cs80_brass": return _gen_brass(params)
		"mellotron_strings": return _gen_mellotron(params)
		"moog_bass": return _gen_moog_bass(params)
		"arp_sequence": return _gen_arp_seq(params)
		"granular_pad": return _gen_granular(params)
		"motorik_beat": return _gen_motorik(params)
		"acid_pad": return _gen_acid_pad(params)
		"house_clap": return _gen_house_clap(params)
		"mentasm": return _gen_mentasm(params)
		"trancer": return _gen_trancer(params)
		"dnb_pad": return _gen_dnb_pad(params)
		"roller_bass": return _gen_roller(params)
		"jungle_stab": return _gen_jungle_stab(params)
		"synthwave_lead": return _gen_synthwave_lead(params)
		"tape_delay": return _gen_tape_delay(params)
		"bitcrush_drums": return _gen_bitcrush(params)
		"ambient_drone": return _gen_ambient_drone(params)
		"disco_bass": return _gen_disco_bass(params)
		"four_floor_kick": return _gen_four_floor(params)
		"disco_hihat": return _gen_disco_hat(params)
		"solina_pad": return _gen_solina(params)
		"amen_break": return _gen_amen_break(params)
		"tr808_snare": return _gen_808_snare(params)
		"tr808_hihat": return _gen_808_hihat(params)
		"trap_hihat": return _gen_trap_hihat(params)
		"rave_piano": return _gen_rave_piano(params)
		"house_piano": return _gen_house_piano(params)
		"808_bass": return _gen_808_bass(params)
		"acid_lead": return _gen_acid_lead(params)
		"trap_bell": return _gen_trap_bell(params)
		"trap_pad": return _gen_trap_pad(params)
		"noise_riser": return _gen_noise_riser(params)
		"noise_fall": return _gen_noise_fall(params)
		"impact_hit": return _gen_impact_hit(params)
		"dub_sub": return _gen_dub_sub(params)
		"dub_chord": return _gen_dub_chord(params)
		"dub_echo_stab": return _gen_dub_echo_stab(params)
		"ukg_shuff_hat": return _gen_ukg_shuff_hat(params)
		"ukg_wobble_bass": return _gen_ukg_wobble_bass(params)
		"ukg_organ_stab": return _gen_organ(params)
		"ukg_pluck": return _gen_ukg_pluck(params)
		"ukg_vocal_chop": return _gen_ukg_vocal_chop(params)
		"neuro_mid_bass": return _gen_neuro_mid_bass(params)
		"neuro_stab": return _gen_stab(params)
		"neuro_laser": return _gen_neuro_laser(params)
		"linn_kick": return _gen_linn_kick(params)
		"sp1200_crunch": return _gen_sp1200(params)
		_: return _gen_test_tone()
	return null


# Generator implementations follow (abbreviated for length)
# Full implementations similar to SynthElementBrowser.gd

func _gen_303(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var wave = p.get("waveform", "sawtooth")
	var freq = 110.0
	var cutoff = p.get("cutoff", 400.0)
	var reso = p.get("resonance", 0.7)
	var env_mod = p.get("env_mod", 0.6)
	var decay = p.get("decay", 0.3)
	var accent = p.get("accent", 0.5)
	var dist = p.get("distortion", 0.2)
	
	var f = [0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Oscillator
		var osc = 0.0
		var ph = fmod(freq * t, 1.0)
		if wave == "sawtooth":
			osc = ph * 2.0 - 1.0
		else:
			osc = 1.0 if ph < 0.5 else -1.0
		
		# Envelope
		var env_d = decay * (1.0 - accent * 0.5)
		var env = exp(-t / env_d)
		var env_m = env_mod * (1.0 + accent * 0.4)
		var res_a = min(reso + accent * 0.2, 0.98)
		var ffreq = cutoff + env * env_m * 2500.0
		
		# 3-pole filter
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.49)
		var g = tan(PI * fc)
		var fb = f[2] * res_a * 4.0
		var x = osc - fb
		x = _diode(x, dist)
		f[0] += g * (x - f[0])
		f[1] += g * (f[0] - f[1])
		f[2] += g * (f[1] - f[2])
		
		var out = f[2] * env * (1.0 + accent * 0.3)
		data[i] = tanh(out * (1.0 + dist)) * 0.7
	
	return _to_wav(data)


func _diode(x: float, amt: float = 0.2) -> float:
	var d = 1.0 + amt * 3.0
	x *= d
	if x > 0:
		return (1.0 - exp(-x)) / d
	else:
		return (-1.0 + exp(x)) / d


func _gen_909_kick(p: Dictionary) -> AudioStreamWAV:
	var dur = 0.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tune = p.get("tune", 55.0)
	var p_start = p.get("pitch_start", 150.0)
	var p_decay = p.get("pitch_decay", 0.02)
	var atk = p.get("attack", 0.3)
	var decay = p.get("decay", 0.25)
	var punch = p.get("punch", 0.5)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var p_env = exp(-t / p_decay)
		var freq = tune + (p_start - tune) * p_env
		var body = sin(TAU * freq * t)
		var click = sin(TAU * 3000.0 * t) * exp(-t * 50.0) * atk
		var env = exp(-t / decay)
		var punch_e = 1.0 + punch * exp(-t * 100.0)
		data[i] = (body + click) * env * punch_e * 0.9
	
	return _to_wav(data)


func _gen_909_hat(p: Dictionary) -> AudioStreamWAV:
	var decay = p.get("decay", 0.05)
	var dur = max(decay + 0.05, 0.1)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var pitch = p.get("pitch", 1.0)
	var metallic = p.get("metallic", 0.7)
	var freqs = [204.0, 298.0, 366.0, 522.0, 540.0, 598.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var met = 0.0
		for f in freqs:
			met += 1.0 if fmod(f * pitch * t, 1.0) < 0.5 else -1.0
		met /= freqs.size()
		var noise = randf_range(-1, 1) * 0.3
		var env = exp(-t / decay)
		data[i] = (met * metallic + noise * (1.0 - metallic)) * env * 0.5
	
	return _to_wav(data)


func _gen_909_clap(p: Dictionary) -> AudioStreamWAV:
	var dur = 0.4
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tone = p.get("tone", 1500.0)
	var spread = p.get("spread", 0.5)
	var decay = p.get("decay", 0.2)
	var rev = p.get("reverb", 0.3)
	var times = [0.0, 0.012, 0.024, 0.036]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var noise = randf_range(-1, 1)
		var hit_e = 0.0
		for ht in times:
			var rt = t - ht * (1.0 + spread * 0.5)
			if rt >= 0:
				hit_e += exp(-rt * 30.0) * 0.3
		var main_e = exp(-t / decay)
		data[i] = noise * hit_e * main_e * 0.6
	
	return _to_wav(data)


func _gen_808_kick(p: Dictionary) -> AudioStreamWAV:
	var decay = p.get("decay", 0.8)
	var dur = decay + 0.1
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tune = p.get("tune", 50.0)
	var tone = p.get("tone", 0.5)
	var click = p.get("click", 0.1)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var p_env = exp(-t * 60.0)
		var freq = tune + p_env * 100.0
		var body = sin(TAU * freq * t)
		body += sin(TAU * freq * 2.0 * t) * tone * 0.2
		var cl = sin(TAU * 1500.0 * t) * exp(-t * 80.0) * click
		var env = exp(-t / decay)
		data[i] = (body + cl) * env * 0.9
	
	return _to_wav(data)


func _gen_juno_pad(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var cutoff = p.get("cutoff", 2000.0)
	var reso = p.get("resonance", 0.2)
	var atk = p.get("attack", 0.3)
	var rel = p.get("release", 1.0)
	var sub = p.get("sub", 0.3)
	var chorus_m = str(p.get("chorus", "I+II"))
	
	var freq = 220.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	var ch_buf1 = PackedFloat32Array()
	var ch_buf2 = PackedFloat32Array()
	ch_buf1.resize(int(SAMPLE_RATE * 0.05))
	ch_buf2.resize(int(SAMPLE_RATE * 0.05))
	var ch_pos = 0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var osc = fmod(freq * t, 1.0) * 2.0 - 1.0
		var sub_osc = (1.0 if fmod(freq * 0.5 * t, 1.0) < 0.5 else -1.0) * sub
		var sig = osc + sub_osc
		
		# ADSR
		var env = 1.0
		if t < atk:
			env = t / atk
		elif t > dur - 0.5:
			env = (dur - t) / 0.5
		
		# Filter
		var fc = clamp(cutoff / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = sig - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var filtered = filt[3]
		
		# Chorus
		if chorus_m != "off":
			var lfo1 = sin(TAU * 0.5 * t)
			var lfo2 = sin(TAU * 0.8 * t)
			var d1 = int((3.0 + lfo1 * 2.0) * SAMPLE_RATE / 1000.0)
			var d2 = int((4.0 + lfo2 * 2.0) * SAMPLE_RATE / 1000.0)
			var r1 = (ch_pos - d1 + ch_buf1.size()) % ch_buf1.size()
			var r2 = (ch_pos - d2 + ch_buf2.size()) % ch_buf2.size()
			ch_buf1[ch_pos] = filtered
			ch_buf2[ch_pos] = filtered
			ch_pos = (ch_pos + 1) % ch_buf1.size()
			
			if chorus_m == "I":
				filtered = (filtered + ch_buf1[r1]) * 0.5
			elif chorus_m == "II":
				filtered = (filtered + ch_buf2[r2]) * 0.5
			else:
				filtered = (filtered + ch_buf1[r1] + ch_buf2[r2]) / 3.0
		
		data[i] = filtered * env * 0.5
	
	return _to_wav(data)


func _gen_supersaw(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var voices = p.get("voices", 7)
	var detune = p.get("detune", 0.5)
	var mix = p.get("mix", 0.5)
	var cutoff = p.get("cutoff", 4000.0)
	var atk = p.get("attack", 0.1)
	var rel = p.get("release", 0.8)
	
	var freq = 220.0
	var spreads = [-0.11, -0.06, -0.02, 0.0, 0.02, 0.06, 0.11]
	var levels = [0.5, 0.7, 0.9, 1.0, 0.9, 0.7, 0.5]
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		var sig = 0.0
		var total = 0.0
		for v in range(min(voices, 7)):
			var d = 1.0 + spreads[v] * detune * 0.1
			var lvl = levels[v]
			if v == 3:
				lvl *= mix + 0.5
			else:
				lvl *= (1.0 - mix) + 0.5
			sig += (fmod(freq * d * t, 1.0) * 2.0 - 1.0) * lvl
			total += lvl
		sig /= total
		
		# Filter
		var fc = clamp(cutoff / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var x = sig
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		# Env
		var env = 1.0
		if t < atk:
			env = t / atk
		elif t > dur - rel:
			env = (dur - t) / rel
		
		data[i] = filt[3] * env * 0.5
	
	return _to_wav(data)


func _gen_hoover(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var voices = p.get("voices", 3)
	var detune = p.get("detune", 0.01)
	var pwm_d = p.get("pwm_depth", 0.2)
	var cutoff = p.get("cutoff", 600.0)
	var reso = p.get("resonance", 0.6)
	var f_env = p.get("filter_env", 0.7)
	var drive = p.get("drive", 0.4)
	
	var freq = 110.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var pw = 0.3 + sin(TAU * 4.0 * t) * pwm_d
		
		var sig = 0.0
		for v in range(voices):
			var d = 1.0 + (float(v) / voices - 0.5) * detune * 2.0
			sig += fmod(freq * d * t, 1.0) * 2.0 - 1.0
		sig /= voices
		sig = sig * 0.7 + (1.0 if fmod(freq * t, 1.0) < pw else -1.0) * 0.3
		
		var f_e = exp(-t * 3.0)
		var ffreq = cutoff + f_e * f_env * 3000.0
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = tanh(sig - fb)
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var env = 1.0
		if t < 0.02:
			env = t / 0.02
		elif t > dur - 0.5:
			env = (dur - t) / 0.5
		
		data[i] = tanh(filt[3] * (1.0 + drive * 2.0)) * env * 0.6
	
	return _to_wav(data)


func _gen_reese(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var voices = p.get("voices", 2)
	var detune = p.get("detune", 0.02)
	var cutoff = p.get("cutoff", 500.0)
	var lfo_r = p.get("lfo_rate", 0.3)
	var lfo_d = p.get("lfo_depth", 0.3)
	
	var freq = 55.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var sig = 0.0
		for v in range(voices):
			var d = 1.0 + (float(v) / voices - 0.5) * detune * 2.0
			sig += fmod(freq * d * t, 1.0) * 2.0 - 1.0
		sig /= voices
		
		var lfo = sin(TAU * lfo_r * t) * lfo_d
		var ffreq = cutoff * (1.0 + lfo)
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var x = sig
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		data[i] = filt[3] * 0.7
	
	return _to_wav(data)


func _gen_sub(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var freq = p.get("frequency", 45.0)
	var atk = p.get("attack", 0.1)
	var rel = p.get("release", 0.5)
	var harm = p.get("harmonics", 0.1)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var sig = sin(TAU * freq * t)
		sig += sin(TAU * freq * 2.0 * t) * harm * 0.5
		
		var env = 1.0
		if t < atk:
			env = t / atk
		elif t > dur - rel:
			env = (dur - t) / rel
		
		data[i] = sig * env * 0.8
	
	return _to_wav(data)


func _gen_stab(p: Dictionary) -> AudioStreamWAV:
	var dur = 0.3
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var wave = p.get("waveform", "saw")
	var cutoff = p.get("cutoff", 1500.0)
	var decay = p.get("decay", 0.1)
	var voices = p.get("voices", 3)
	var detune = p.get("detune", 0.005)
	
	var freq = 220.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var sig = 0.0
		for v in range(voices):
			var d = 1.0 + (float(v) / voices - 0.5) * detune * 2.0
			if wave == "saw":
				sig += fmod(freq * d * t, 1.0) * 2.0 - 1.0
			else:
				sig += 1.0 if fmod(freq * d * t, 1.0) < 0.5 else -1.0
		sig /= voices
		
		var env = exp(-t / decay)
		data[i] = sig * env * 0.6
	
	return _to_wav(data)


func _gen_simple_bass(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var wave = p.get("waveform", "saw")
	var cutoff = p.get("cutoff", 600.0)
	var reso = p.get("resonance", 0.2)
	var decay = p.get("decay", 0.3)
	var sub = p.get("sub", 0.4)
	
	var freq = 55.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var osc = 0.0
		if wave == "saw":
			osc = fmod(freq * t, 1.0) * 2.0 - 1.0
		else:
			osc = 1.0 if fmod(freq * t, 1.0) < 0.5 else -1.0
		
		var sub_osc = sin(TAU * freq * 0.5 * t) * sub
		var sig = osc + sub_osc
		
		var fc = clamp(cutoff / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = sig - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var env = exp(-t / decay)
		data[i] = filt[3] * env * 0.7
	
	return _to_wav(data)


func _gen_organ(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var atk = p.get("attack", 0.01)
	var decay = p.get("decay", 0.3)
	var sus = p.get("sustain", 0.6)
	var bright = p.get("brightness", 0.5)
	var click = p.get("click", 0.3)
	
	var freq = 220.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		# Drawbar-style organ (simplified)
		var sig = sin(TAU * freq * t) * 1.0
		sig += sin(TAU * freq * 2.0 * t) * 0.8 * bright
		sig += sin(TAU * freq * 3.0 * t) * 0.6 * bright
		sig += sin(TAU * freq * 4.0 * t) * 0.4 * bright
		sig /= 3.0
		
		# Click
		sig += sin(TAU * 2000.0 * t) * exp(-t * 100.0) * click
		
		# ADSR
		var env = 1.0
		if t < atk:
			env = t / atk
		elif t < atk + decay:
			env = 1.0 - (t - atk) / decay * (1.0 - sus)
		else:
			env = sus
		
		data[i] = sig * env * 0.5
	
	return _to_wav(data)


func _gen_gated_snare(p: Dictionary) -> AudioStreamWAV:
	var dur = 0.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tone = p.get("tone", 0.5)
	var rev_size = p.get("reverb_size", 0.8)
	var gate_t = p.get("gate_time", 0.15)
	var snappy = p.get("snappy", 0.6)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Snare body
		var body = sin(TAU * 200.0 * t) * exp(-t * 20.0) * tone
		var noise = randf_range(-1, 1) * exp(-t * 15.0) * snappy
		var sig = body + noise
		
		# Reverb tail (simplified)
		sig += randf_range(-1, 1) * rev_size * 0.3 * exp(-t * 5.0)
		
		# Gate
		if t > gate_t:
			sig *= max(0, 1.0 - (t - gate_t) * 20.0)
		
		data[i] = sig * 0.7
	
	return _to_wav(data)


func _gen_arp(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var wave = p.get("waveform", "pulse")
	var pwm = p.get("pwm", 0.2)
	var cutoff = p.get("cutoff", 2000.0)
	var note_decay = p.get("decay", 0.08)
	var rate = p.get("rate", "16th")
	
	var bpm = 120.0
	var notes_per_beat = 4 if rate == "16th" else (2 if rate == "8th" else 8)
	var note_dur = 60.0 / bpm / notes_per_beat
	
	var freq = 220.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var note_t = fmod(t, note_dur)
		
		var pw = 0.5 + sin(TAU * 2.0 * t) * pwm
		var osc = 0.0
		if wave == "saw":
			osc = fmod(freq * t, 1.0) * 2.0 - 1.0
		elif wave == "pulse":
			osc = 1.0 if fmod(freq * t, 1.0) < pw else -1.0
		else:
			osc = (fmod(freq * t, 1.0) * 2.0 - 1.0) * 0.5 + (1.0 if fmod(freq * t, 1.0) < pw else -1.0) * 0.5
		
		var fc = clamp(cutoff / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var x = osc
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var env = exp(-note_t / note_decay)
		data[i] = filt[3] * env * 0.5
	
	return _to_wav(data)


func _gen_moroder(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var wave = p.get("waveform", "saw")
	var cutoff = p.get("cutoff", 800.0)
	var env_amt = p.get("env_amount", 0.5)
	var decay = p.get("decay", 0.06)
	var reso = p.get("resonance", 0.3)
	
	var bpm = 120.0
	var step_dur = 60.0 / bpm / 4.0
	var freq = 110.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var step_t = fmod(t, step_dur)
		
		var osc = 0.0
		if wave == "saw":
			osc = fmod(freq * t, 1.0) * 2.0 - 1.0
		else:
			osc = 1.0 if fmod(freq * t, 1.0) < 0.5 else -1.0
		
		var env = exp(-step_t / decay)
		var ffreq = cutoff + env * env_amt * 2000.0
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = osc - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		data[i] = filt[3] * env * 0.6
	
	return _to_wav(data)


func _gen_strings(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var ens = p.get("ensemble", 0.7)
	var phaser = p.get("phaser", 0.3)
	var atk = p.get("attack", 0.3)
	var rel = p.get("release", 0.8)
	
	var freq = 220.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		# String ensemble (divide-down style)
		var sig = 0.0
		for v in range(4):
			var d = 1.0 + (float(v) - 1.5) * 0.003
			sig += fmod(freq * d * t, 1.0) * 2.0 - 1.0
		sig /= 4.0
		
		# Ensemble effect
		sig *= 1.0 + sin(TAU * 6.0 * t) * ens * 0.1
		
		# Phaser (simplified)
		sig += sig * sin(TAU * 0.5 * t) * phaser * 0.3
		
		# Env
		var env = 1.0
		if t < atk:
			env = t / atk
		elif t > dur - rel:
			env = (dur - t) / rel
		
		data[i] = sig * env * 0.4
	
	return _to_wav(data)


func _gen_moog_lead(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var osc_mix = p.get("osc_mix", 0.7)
	var detune = p.get("detune", 0.005)
	var cutoff = p.get("cutoff", 2500.0)
	var reso = p.get("resonance", 0.5)
	var porta = p.get("portamento", 0.15)
	var f_env = p.get("filter_env", 0.4)
	
	var freq = 440.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		var osc1 = fmod(freq * t, 1.0) * 2.0 - 1.0
		var osc2 = fmod(freq * (1.0 + detune) * t, 1.0) * 2.0 - 1.0
		var osc3 = 1.0 if fmod(freq * (1.0 - detune) * t, 1.0) < 0.5 else -1.0
		var sig = (osc1 + osc2) * osc_mix + osc3 * (1.0 - osc_mix)
		sig /= 2.0
		
		var env = 1.0
		if t < 0.02:
			env = t / 0.02
		elif t > dur - 0.5:
			env = (dur - t) / 0.5
		
		var ffreq = cutoff + env * f_env * 2000.0
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = sig - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		data[i] = filt[3] * env * 0.6
	
	return _to_wav(data)


func _gen_brass(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var cutoff = p.get("cutoff", 2000.0)
	var reso = p.get("resonance", 0.3)
	var brill = p.get("brilliance", 0.6)
	var ring = p.get("ring_mod", 0.2)
	var atk = p.get("attack", 0.08)
	var vib = p.get("vibrato", 0.3)
	
	var freq = 220.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var vibrato = sin(TAU * 5.0 * t) * vib * 0.02
		var f = freq * (1.0 + vibrato)
		
		var osc1 = fmod(f * t, 1.0) * 2.0 - 1.0
		var osc2 = sin(TAU * f * 1.01 * t)
		var sig = osc1 * 0.7 + osc2 * 0.3
		
		# Ring mod
		sig *= 1.0 - ring + ring * sin(TAU * f * 2.0 * t)
		
		# Filter
		var ffreq = cutoff * (1.0 + brill)
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = sig - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var env = 1.0
		if t < atk:
			env = t / atk
		elif t > dur - 0.5:
			env = (dur - t) / 0.5
		
		data[i] = filt[3] * env * 0.5
	
	return _to_wav(data)


func _gen_mellotron(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var bright = p.get("brightness", 0.5)
	var atk = p.get("attack", 0.1)
	var rel = p.get("release", 0.5)
	var wobble = p.get("wobble", 0.3)
	
	var freq = 220.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Tape wobble
		var wow = sin(TAU * 0.5 * t) * wobble * 0.01
		var flutter = sin(TAU * 6.0 * t) * wobble * 0.003
		var f = freq * (1.0 + wow + flutter)
		
		# String-like sawtooth ensemble (multiple detuned)
		var sig = 0.0
		sig += (fmod(f * t, 1.0) * 2.0 - 1.0) * 0.3
		sig += (fmod(f * 1.003 * t, 1.0) * 2.0 - 1.0) * 0.25
		sig += (fmod(f * 0.997 * t, 1.0) * 2.0 - 1.0) * 0.25
		sig += (fmod(f * 2.0 * t, 1.0) * 2.0 - 1.0) * 0.1  # Octave up
		
		# Simple lowpass for brightness
		var cutoff = 1000.0 + bright * 3000.0
		var rc = 1.0 / (TAU * cutoff)
		var alpha = 1.0 / (1.0 + rc * SAMPLE_RATE)
		sig = sig * alpha  # Simplified LP
		
		# Envelope
		var env = 1.0
		if t < atk:
			env = t / atk
		elif t > dur - rel:
			env = (dur - t) / rel
		
		data[i] = sig * env * 0.5
	
	return _to_wav(data)


func _gen_moog_bass(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var cutoff = p.get("cutoff", 400.0)
	var reso = p.get("resonance", 0.3)
	var osc_mix = p.get("osc_mix", 0.6)
	var sub_level = p.get("sub", 0.4)
	var decay = p.get("decay", 0.3)
	
	var freq = 55.0  # Low A
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# 3 oscillators
		var osc1 = fmod(freq * t, 1.0) * 2.0 - 1.0  # Saw
		var osc2_ph = fmod(freq * 1.002 * t, 1.0)
		var osc2 = 1.0 if osc2_ph < 0.5 else -1.0  # Square
		var sub = sin(TAU * freq * 0.5 * t)  # Sub octave
		
		var sig = osc1 * osc_mix + osc2 * (1.0 - osc_mix) * 0.8 + sub * sub_level
		
		# Moog ladder filter (4-pole)
		var env = exp(-t / decay)
		var ffreq = cutoff + env * cutoff * 2.0
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = sig - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		data[i] = filt[3] * env * 0.7
	
	return _to_wav(data)


func _gen_arp_seq(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var steps = p.get("steps", 8)
	var rate = p.get("rate", 8.0)
	var cutoff = p.get("cutoff", 1000.0)
	var reso = p.get("resonance", 0.4)
	var glide_time = p.get("glide", 0.05)
	
	# Simple pattern - minor scale steps
	var pattern = [0, 3, 7, 12, 7, 3, 0, -5]
	var base_freq = 110.0
	var current_freq = base_freq
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Which step are we on?
		var step_idx = int(t * rate) % steps
		var target_semitone = pattern[step_idx % pattern.size()]
		var target_freq = base_freq * pow(2.0, target_semitone / 12.0)
		
		# Glide
		var glide_alpha = 1.0 - exp(-1.0 / (glide_time * SAMPLE_RATE))
		current_freq += (target_freq - current_freq) * glide_alpha
		
		# Oscillator (saw)
		var osc = fmod(current_freq * t, 1.0) * 2.0 - 1.0
		
		# Step envelope
		var step_t = fmod(t * rate, 1.0)
		var step_env = exp(-step_t * 8.0)
		
		# Filter with envelope
		var ffreq = cutoff * (0.3 + step_env * 0.7)
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = osc - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		data[i] = filt[3] * step_env * 0.6
	
	return _to_wav(data)


func _gen_lofi_drums(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var bits = p.get("bits", 12)
	var sr_mult = p.get("sample_rate", 0.6)
	var wobble = p.get("tape_wobble", 0.3)
	var sat = p.get("saturation", 0.4)
	
	var levels = pow(2, bits - 1)
	var step_size = int(1.0 / sr_mult)
	var last_sample = 0.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var beat_t = fmod(t * 2.0, 1.0)  # Simple 2hz pulse
		
		# Simple kick/hat pattern
		var sig = 0.0
		if beat_t < 0.1:
			sig = sin(TAU * 50.0 * beat_t) * (1.0 - beat_t * 10.0)
		if fmod(t * 4.0, 1.0) < 0.05:
			sig += randf_range(-1, 1) * 0.3
		
		# Bitcrush
		sig = floor(sig * levels) / levels
		
		# Sample rate reduction
		if i % step_size == 0:
			last_sample = sig
		else:
			sig = last_sample
		
		# Tape wobble
		sig *= 1.0 + sin(TAU * 0.5 * t) * wobble * 0.1
		
		# Saturation
		sig = tanh(sig * (1.0 + sat * 2.0))
		
		data[i] = sig * 0.6
	
	return _to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# NEW IMPLEMENTATIONS - Historically accurate sound generators
# ═══════════════════════════════════════════════════════════════════════════

func _gen_amen_break(p: Dictionary) -> AudioStreamWAV:
	# The Amen Break - from "Amen Brother" by The Winstons (1969)
	# Original tempo ~136 BPM, 4 bars
	# This synthesizes the iconic pattern with proper swing
	
	var tempo = p.get("tempo", 160.0)
	var swing = p.get("swing", 0.15)
	var lofi = p.get("lofi", 0.5)
	var style = p.get("chop_style", "sliced")
	
	var beat_dur = 60.0 / tempo
	var sixteenth = beat_dur / 4.0
	var dur = beat_dur * 4.0  # One bar
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	# Amen pattern (simplified): K=kick, S=snare, H=hat, R=ride
	# Original pattern (16 steps): K-H-S-H-K-K-S-H-K-H-S-H-K-H-S-H
	# With ghost notes and swing
	var pattern = [
		{"t": 0, "type": "kick", "vel": 1.0},
		{"t": 1, "type": "hat", "vel": 0.6},
		{"t": 2, "type": "snare", "vel": 1.0},
		{"t": 3, "type": "hat", "vel": 0.5},
		{"t": 4, "type": "kick", "vel": 0.9},
		{"t": 5, "type": "kick", "vel": 0.7},  # Ghost kick
		{"t": 6, "type": "snare", "vel": 1.0},
		{"t": 7, "type": "hat", "vel": 0.6},
		{"t": 8, "type": "kick", "vel": 1.0},
		{"t": 9, "type": "hat", "vel": 0.5},
		{"t": 10, "type": "snare", "vel": 0.95},
		{"t": 11, "type": "hat", "vel": 0.6},
		{"t": 12, "type": "kick", "vel": 0.85},
		{"t": 13, "type": "hat", "vel": 0.5},
		{"t": 14, "type": "snare", "vel": 1.0},
		{"t": 15, "type": "hat", "vel": 0.7},
	]
	
	# Pre-calculate hit times with swing
	var hit_times = []
	for hit in pattern:
		var step = hit.t
		var base_time = step * sixteenth
		# Apply swing to off-beats (odd steps)
		if step % 2 == 1:
			base_time += sixteenth * swing
		hit_times.append({"time": base_time, "type": hit.type, "vel": hit.vel})
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var sig = 0.0
		
		for hit in hit_times:
			var dt = t - hit.time
			if dt >= 0 and dt < 0.3:
				match hit.type:
					"kick":
						# Acoustic kick - body + click
						var pitch_env = exp(-dt * 40.0)
						var freq = 60.0 + pitch_env * 80.0
						var body = sin(TAU * freq * dt) * exp(-dt * 15.0)
						var click = randf_range(-1, 1) * exp(-dt * 100.0) * 0.3
						sig += (body + click) * hit.vel * 0.8
					"snare":
						# Acoustic snare - body + wires
						var body = sin(TAU * 200.0 * dt) * exp(-dt * 25.0) * 0.5
						var wires = randf_range(-1, 1) * exp(-dt * 20.0) * 0.7
						sig += (body + wires) * hit.vel * 0.7
					"hat":
						# Hi-hat - filtered noise
						var noise = randf_range(-1, 1)
						sig += noise * exp(-dt * 50.0) * hit.vel * 0.35
		
		# Lo-fi processing (SP-1200 style)
		if lofi > 0:
			var bits = int(16 - lofi * 8)  # 16 to 8 bit
			var levels = pow(2, bits - 1)
			sig = floor(sig * levels) / levels
		
		data[i] = clamp(sig, -1.0, 1.0)
	
	return _to_wav(data)


func _gen_808_snare(p: Dictionary) -> AudioStreamWAV:
	# TR-808 Snare Drum
	# Two tuned oscillators (body) + noise (snappy wires)
	# Body: ~180Hz and ~330Hz sine waves
	# Snappy: Band-pass filtered noise
	
	var dur = 0.4
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tone = p.get("tone", 0.5)  # Body vs noise balance
	var snappy = p.get("snappy", 0.6)  # Noise character
	var tune = p.get("tune", 180.0)  # Body frequency
	var decay = p.get("decay", 0.2)
	
	var filt_state = [0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Body - two sine oscillators (808 characteristic)
		var body1 = sin(TAU * tune * t)
		var body2 = sin(TAU * tune * 1.83 * t)  # ~330Hz when tune=180
		var body = (body1 + body2 * 0.7) * tone
		
		# Snappy - band-pass filtered noise (1-5kHz range)
		var noise = randf_range(-1, 1)
		# Simple band-pass via state-variable filter
		var cutoff = 2500.0
		var q = 0.7
		var fc = clamp(cutoff / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = 1.0 / q
		var a1 = 1.0 / (1.0 + g * (g + k))
		var a2 = g * a1
		var v1 = a1 * filt_state[0] + a2 * (noise - filt_state[1])
		var v2 = filt_state[1] + g * v1
		filt_state[0] = 2.0 * v1 - filt_state[0]
		filt_state[1] = 2.0 * v2 - filt_state[1]
		var snappy_sig = v1 * snappy  # Band-pass output
		
		# Envelopes - body decays faster than snappy
		var body_env = exp(-t / (decay * 0.5))
		var snap_env = exp(-t / decay)
		
		var sig = body * body_env + snappy_sig * snap_env
		data[i] = sig * 0.8
	
	return _to_wav(data)


func _gen_808_hihat(p: Dictionary) -> AudioStreamWAV:
	# TR-808 Hi-Hat
	# Different from 909 - uses 6 square waves but at different ratios
	# 808 hats are darker, more "tick" than "sizzle"
	# Frequencies: 204, 298, 366, 522, 540, 598 Hz (same as 909 but filtered differently)
	
	var decay = p.get("decay", 0.08)
	var dur = max(decay + 0.05, 0.15)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tune = p.get("tune", 1.0)
	var tone = p.get("tone", 0.5)  # Dark to bright
	
	# 808 uses slightly different mix than 909
	var freqs = [204.0, 298.0, 366.0, 522.0, 540.0, 598.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		var met = 0.0
		for f in freqs:
			# Square waves
			met += 1.0 if fmod(f * tune * t, 1.0) < 0.5 else -1.0
		met /= freqs.size()
		
		# 808 has darker filter than 909
		# Simulated by mixing in less high-frequency content
		var bright = met
		var dark = met * 0.7 + sin(TAU * 300.0 * t) * 0.3
		var sig = lerp(dark, bright, tone)
		
		var env = exp(-t / decay)
		data[i] = sig * env * 0.5
	
	return _to_wav(data)


func _gen_trap_hihat(p: Dictionary) -> AudioStreamWAV:
	# Modern Trap Hi-Hat
	# Characteristics: fast rolls, pitch modulation, triplet patterns
	# Often 808 sample pitched up with rapid triggering
	
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tempo = p.get("tempo", 140.0)
	var roll_speed = p.get("roll_speed", 0.7)  # 0 = 16ths, 1 = 32nds/rolls
	var pitch_mod = p.get("pitch_mod", 0.3)
	var decay_base = p.get("decay", 0.03)
	
	var beat_dur = 60.0 / tempo
	
	# Generate trap hat pattern with rolls
	# Pattern: steady 16ths with 32nd rolls on certain beats
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var beat_pos = fmod(t / beat_dur, 4.0)  # Position in 4-beat bar
		
		# Base 16th note grid
		var sixteenth_pos = fmod(t, beat_dur / 4.0)
		var on_16th = sixteenth_pos < 0.01
		
		# Add rolls (32nd notes) on beats 2 and 4
		var in_roll_zone = (beat_pos > 1.8 and beat_pos < 2.2) or (beat_pos > 3.8 or beat_pos < 0.2)
		var roll_interval = beat_dur / 8.0 if roll_speed > 0.5 else beat_dur / 4.0
		var on_roll = fmod(t, roll_interval) < 0.005
		
		var triggered = on_16th or (in_roll_zone and on_roll and roll_speed > 0.3)
		
		var sig = 0.0
		if triggered:
			# Calculate time since trigger
			var note_t = sixteenth_pos if on_16th else fmod(t, roll_interval)
			
			# Pitch variation
			var pitch = 1.0 + sin(t * 3.0) * pitch_mod * 0.2
			
			# Trap hat sound - bright, clicky
			var freqs = [204.0, 298.0, 366.0, 522.0, 540.0, 598.0]
			for f in freqs:
				sig += 1.0 if fmod(f * pitch * note_t * 2.0, 1.0) < 0.5 else -1.0
			sig /= freqs.size()
			
			# Very fast decay
			var env = exp(-note_t / decay_base)
			sig *= env
			
			# Velocity variation for groove
			var vel = 0.7 + randf() * 0.3
			sig *= vel
		
		data[i] = sig * 0.4
	
	return _to_wav(data)


func _gen_rave_piano(p: Dictionary) -> AudioStreamWAV:
	# Rave Piano - Korg M1 Piano preset
	# Characteristics: Very bright, almost harsh highs
	# Short staccato, rhythmic stabs
	# The "piano house" sound (1991)
	
	var dur = 0.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var brightness = p.get("brightness", 0.9)
	var decay = p.get("decay", 0.15)
	var reverb = p.get("reverb", 0.4)
	var velocity = p.get("velocity", 0.8)
	
	var freq = 440.0  # A4
	
	# Reverb buffer (simple delay-based)
	var rev_buf = PackedFloat32Array()
	var rev_size = int(SAMPLE_RATE * 0.08)
	rev_buf.resize(rev_size)
	var rev_pos = 0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# M1 piano is sample-based, but we synthesize the character
		# Bright attack transient + decaying body
		
		# Hammer attack (very bright, short)
		var attack = 0.0
		if t < 0.01:
			attack = sin(TAU * 3000.0 * t) * (1.0 - t / 0.01) * brightness
			attack += sin(TAU * 5000.0 * t) * (1.0 - t / 0.01) * brightness * 0.5
		
		# Piano body - multiple harmonics
		var body = 0.0
		body += sin(TAU * freq * t) * 1.0
		body += sin(TAU * freq * 2.0 * t) * 0.7 * brightness
		body += sin(TAU * freq * 3.0 * t) * 0.4 * brightness
		body += sin(TAU * freq * 4.0 * t) * 0.3 * brightness
		body += sin(TAU * freq * 5.0 * t) * 0.2 * brightness
		body += sin(TAU * freq * 6.0 * t) * 0.1 * brightness
		body /= 3.0
		
		# Fast decay envelope (staccato)
		var env = exp(-t / decay)
		
		var sig = (attack * 0.5 + body) * env * velocity
		
		# Simple reverb
		var rev_sample = rev_buf[rev_pos]
		rev_buf[rev_pos] = sig
		rev_pos = (rev_pos + 1) % rev_size
		sig += rev_sample * reverb
		
		data[i] = sig * 0.5
	
	return _to_wav(data)


func _gen_house_piano(p: Dictionary) -> AudioStreamWAV:
	# Chicago House Piano - DX7 or M1 style
	# Warmer than rave piano, more soulful
	
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var brightness = p.get("brightness", 0.7)
	var decay = p.get("decay", 0.5)
	var velocity = p.get("velocity", 0.7)
	var reverb = p.get("reverb", 0.3)
	
	var freq = 440.0
	
	# Reverb buffer
	var rev_buf = PackedFloat32Array()
	var rev_size = int(SAMPLE_RATE * 0.06)
	rev_buf.resize(rev_size)
	var rev_pos = 0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# FM-style electric piano (DX7 character)
		var mod_index = 2.0 * (1.0 - brightness * 0.5) + 0.5
		var mod = sin(TAU * freq * t) * mod_index
		var carrier = sin(TAU * freq * t + mod)
		
		# Harmonics for presence
		var bright_harm = sin(TAU * freq * 2.0 * t) * brightness * 0.3
		bright_harm += sin(TAU * freq * 3.0 * t) * brightness * 0.15
		
		var sig = carrier + bright_harm
		
		# Envelope
		var env = exp(-t / decay)
		sig *= env * velocity
		
		# Reverb
		var rev_sample = rev_buf[rev_pos]
		rev_buf[rev_pos] = sig
		rev_pos = (rev_pos + 1) % rev_size
		sig += rev_sample * reverb
		
		data[i] = sig * 0.5
	
	return _to_wav(data)


func _gen_808_bass(p: Dictionary) -> AudioStreamWAV:
	# 808 as Bass Instrument
	# The extended 808 kick used as a bass note
	# Long decay, pitch-trackable, sub-heavy
	# Foundation of trap, drill, and modern hip-hop
	
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tune = p.get("tune", 45.0)  # Note frequency (F1 ~ 43Hz)
	var decay = p.get("decay", 1.5)
	var punch = p.get("punch", 0.5)  # Initial transient
	var saturation = p.get("saturation", 0.3)
	var sub = p.get("sub", 0.8)  # Sub harmonic level
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Pitch envelope for the punch
		var pitch_env = exp(-t * 50.0) * punch
		var freq = tune * (1.0 + pitch_env * 2.0)
		
		# Main body - sine wave
		var body = sin(TAU * freq * t)
		
		# Sub harmonic (octave down for weight)
		var sub_osc = sin(TAU * freq * 0.5 * t) * sub
		
		# Slight harmonics from saturation
		var harm = sin(TAU * freq * 2.0 * t) * saturation * 0.3
		
		var sig = body + sub_osc * 0.5 + harm
		
		# Long decay envelope
		var env = exp(-t / decay)
		
		# Soft saturation
		if saturation > 0:
			sig = tanh(sig * (1.0 + saturation))
		
		data[i] = sig * env * 0.8
	
	return _to_wav(data)


func _gen_linn_kick(p: Dictionary) -> AudioStreamWAV:
	# LinnDrum / LM-1 Kick
	# 12-bit sampled kick from the 80s
	# Punchy, tight, distinctive "thud"
	# Used on countless 80s records
	
	var dur = 0.4
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tune = p.get("tune", 80.0)
	var decay = p.get("decay", 0.15)
	var punch = p.get("punch", 0.7)
	var tone = p.get("tone", 0.5)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# LinnDrum kick has a specific punch character
		# Fast pitch drop, tighter than 808
		var pitch_env = exp(-t * 80.0)
		var freq = tune + pitch_env * 150.0
		
		# Body
		var body = sin(TAU * freq * t)
		
		# Click/attack transient
		var click = sin(TAU * 2000.0 * t) * exp(-t * 150.0) * punch
		
		# Tone control - adds upper harmonics
		var upper = sin(TAU * freq * 2.5 * t) * tone * 0.3
		
		var sig = body + click + upper
		
		# Envelope
		var env = exp(-t / decay)
		
		# 12-bit character (subtle quantization)
		var levels = pow(2, 11)
		sig = floor(sig * levels) / levels
		
		data[i] = sig * env * 0.8
	
	return _to_wav(data)


func _gen_sp1200(p: Dictionary) -> AudioStreamWAV:
	# E-mu SP-1200 Character
	# 12-bit, 26kHz sample rate = THE hip-hop crunch
	# Used by everyone from Marley Marl to Pete Rock
	
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var bits = p.get("bits", 12)
	var sample_rate_mult = p.get("sample_rate", 0.59)  # 26kHz / 44.1kHz
	var drive = p.get("drive", 0.4)
	var bass_boost = p.get("bass_boost", 0.3)
	
	# Generate a simple beat to process
	var beat_dur = 0.5
	var levels = pow(2, bits - 1)
	var step = max(1, int(1.0 / sample_rate_mult))
	var last_sample = 0.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var beat_t = fmod(t, beat_dur)
		
		# Simple kick-snare pattern
		var sig = 0.0
		if beat_t < 0.15:
			# Kick
			var freq = 50.0 + exp(-beat_t * 50.0) * 100.0
			sig = sin(TAU * freq * beat_t) * exp(-beat_t * 10.0)
		if fmod(t + beat_dur * 0.5, beat_dur) < 0.1:
			# Snare
			var snare_t = fmod(t + beat_dur * 0.5, beat_dur)
			sig += randf_range(-1, 1) * exp(-snare_t * 20.0) * 0.6
			sig += sin(TAU * 200.0 * snare_t) * exp(-snare_t * 30.0) * 0.4
		
		# SP-1200 processing chain
		
		# 1. Input drive (SSM chips had nice saturation)
		sig = tanh(sig * (1.0 + drive * 2.0))
		
		# 2. Sample rate reduction (26kHz)
		if i % step == 0:
			last_sample = sig
		else:
			sig = last_sample
		
		# 3. 12-bit quantization
		sig = floor(sig * levels) / levels
		
		# 4. Bass boost (SP-1200 had a bassy character)
		# Simple approximation
		sig *= 1.0 + bass_boost * 0.5
		
		data[i] = sig * 0.7
	
	return _to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# NEW GENERATORS - Ada Sound-Engineer additions
# ═══════════════════════════════════════════════════════════════════════════

func _gen_granular(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var grain_size_ms = p.get("grain_size", 30.0)
	var density = p.get("density", 15.0)
	var pitch_scatter = p.get("pitch_scatter", 0.3)
	var pos_scatter = p.get("position_scatter", 0.5)
	
	var grain_samples = int(grain_size_ms * SAMPLE_RATE / 1000.0)
	var source_freq = 220.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var sig = 0.0
		
		# Multiple overlapping grains
		for g in range(int(density)):
			var grain_phase = fmod(t * density + g * 0.1, 1.0)
			var grain_env = sin(PI * grain_phase)  # Hann window
			var pitch_mod = 1.0 + (randf() - 0.5) * pitch_scatter
			var grain_freq = source_freq * pitch_mod
			sig += sin(TAU * grain_freq * t) * grain_env * 0.15
		
		data[i] = tanh(sig) * 0.6
	
	return _to_wav(data)


func _gen_motorik(p: Dictionary) -> AudioStreamWAV:
	var tempo = p.get("tempo", 120.0)
	var kick_punch = p.get("kick_punch", 0.5)
	var snare_tone = p.get("snare_tone", 0.5)
	
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var beat_dur = 60.0 / tempo
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var beat_pos = fmod(t, beat_dur)
		var beat_num = int(t / beat_dur) % 4
		var sig = 0.0
		
		# Kick on every beat
		if beat_pos < 0.15:
			var k_env = exp(-beat_pos * (10.0 + kick_punch * 20.0))
			var k_freq = 50.0 + exp(-beat_pos * 40.0) * 80.0
			sig += sin(TAU * k_freq * beat_pos) * k_env * 0.8
		
		# Snare on 2 and 4
		if (beat_num == 1 or beat_num == 3) and beat_pos < 0.12:
			var s_env = exp(-beat_pos * 25.0)
			sig += randf_range(-1, 1) * s_env * 0.4
			sig += sin(TAU * (180.0 + snare_tone * 100.0) * beat_pos) * s_env * 0.3
		
		# Hi-hats on 8ths
		var eighth_pos = fmod(t, beat_dur * 0.5)
		if eighth_pos < 0.03:
			var h_env = exp(-eighth_pos * 100.0)
			sig += randf_range(-1, 1) * h_env * 0.25
		
		data[i] = tanh(sig) * 0.7
	
	return _to_wav(data)


func _gen_acid_pad(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var cutoff = p.get("cutoff", 1200.0)
	var reso = p.get("resonance", 0.35)
	var lfo_rate = p.get("lfo_rate", 0.3)
	var lfo_depth = p.get("lfo_depth", 0.4)
	var chorus_amt = p.get("chorus", 0.6)
	
	var freq = 110.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var lfo = sin(TAU * lfo_rate * t)
		
		# Detuned saws with chorus
		var osc1 = fmod(freq * t, 1.0) * 2.0 - 1.0
		var osc2 = fmod(freq * 1.005 * t, 1.0) * 2.0 - 1.0
		var osc3 = fmod(freq * 0.995 * t, 1.0) * 2.0 - 1.0
		var sig = (osc1 + osc2 * chorus_amt + osc3 * chorus_amt) / (1.0 + chorus_amt * 2.0)
		
		# Modulated filter
		var ffreq = cutoff * (1.0 + lfo * lfo_depth)
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = sig - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var env = 1.0 - exp(-t * 2.0)
		if t > dur - 0.5:
			env *= (dur - t) / 0.5
		
		data[i] = filt[3] * env * 0.5
	
	return _to_wav(data)


func _gen_house_clap(p: Dictionary) -> AudioStreamWAV:
	var dur = 0.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tone = p.get("tone", 1500.0)
	var spread = p.get("spread", 0.4)
	var decay = p.get("decay", 0.25)
	var reverb = p.get("reverb", 0.35)
	
	var times = [0.0, 0.01, 0.02, 0.035]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var sig = 0.0
		
		# Multiple hits
		for ht in times:
			var rt = t - ht * (1.0 + spread)
			if rt >= 0:
				var hit_env = exp(-rt * 25.0)
				sig += randf_range(-1, 1) * hit_env * 0.3
		
		# Main decay
		var main_env = exp(-t / decay)
		sig *= main_env
		
		# Simple reverb tail
		sig += sin(TAU * tone * 0.5 * t) * exp(-t / (decay * 2.0)) * reverb * 0.2
		
		data[i] = tanh(sig) * 0.6
	
	return _to_wav(data)


func _gen_mentasm(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var pw = p.get("pwm", 0.5)
	var pwm_rate = p.get("pwm_rate", 1.5)
	var cutoff = p.get("cutoff", 800.0)
	var reso = p.get("resonance", 0.6)
	var drive = p.get("drive", 0.5)
	
	var freq = 55.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# PWM square
		var pulse_width = pw + sin(TAU * pwm_rate * t) * 0.3
		var phase = fmod(freq * t, 1.0)
		var osc = 1.0 if phase < pulse_width else -1.0
		
		# Detuned copies
		var osc2 = 1.0 if fmod(freq * 1.01 * t, 1.0) < pulse_width else -1.0
		var osc3 = 1.0 if fmod(freq * 0.99 * t, 1.0) < pulse_width else -1.0
		var sig = (osc + osc2 * 0.7 + osc3 * 0.7) / 2.4
		
		# Resonant filter
		var ffreq = cutoff + sin(TAU * 0.3 * t) * cutoff * 0.5
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = sig - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		# Distortion
		sig = tanh(filt[3] * (1.0 + drive * 3.0))
		
		var env = 1.0
		if t < 0.1: env = t / 0.1
		if t > dur - 0.3: env = (dur - t) / 0.3
		
		data[i] = sig * env * 0.6
	
	return _to_wav(data)


func _gen_trancer(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var voices = p.get("voices", 5)
	var detune = p.get("detune", 0.25)
	var cutoff = p.get("cutoff", 3000.0)
	var atk = p.get("attack", 0.05)
	
	var freq = 220.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var sig = 0.0
		
		# Supersaw voices
		for v in range(voices):
			var detune_amt = (float(v) / (voices - 1) - 0.5) * detune * 0.1
			var v_freq = freq * (1.0 + detune_amt)
			sig += (fmod(v_freq * t, 1.0) * 2.0 - 1.0) / voices
		
		# Filter with attack envelope
		var env = 1.0 if t > atk else t / atk
		var ffreq = cutoff * (0.5 + env * 0.5)
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		for j in range(4):
			filt[j] += g * (sig - filt[j])
			sig = filt[j]
		
		if t > dur - 0.3: env *= (dur - t) / 0.3
		data[i] = sig * env * 0.5
	
	return _to_wav(data)


func _gen_dnb_pad(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var voices = p.get("voices", 4)
	var detune = p.get("detune", 0.02)
	var cutoff = p.get("cutoff", 2000.0)
	var atk = p.get("attack", 0.5)
	
	var freq = 220.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var sig = 0.0
		
		for v in range(voices):
			var d = (float(v) / (voices - 1) - 0.5) * detune
			sig += sin(TAU * freq * (1.0 + d) * t) / voices
		
		# Slow attack
		var env = 1.0 if t > atk else t / atk
		if t > dur - 0.5: env *= (dur - t) / 0.5
		
		data[i] = sig * env * 0.5
	
	return _to_wav(data)


func _gen_roller(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var detune = p.get("detune", 0.02)
	var cutoff = p.get("cutoff", 600.0)
	var lfo_rate = p.get("lfo_rate", 4.0)
	var lfo_depth = p.get("lfo_depth", 0.5)
	var drive = p.get("drive", 0.4)
	
	var freq = 55.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Reese-style detuned saws
		var osc1 = fmod(freq * t, 1.0) * 2.0 - 1.0
		var osc2 = fmod(freq * (1.0 + detune) * t, 1.0) * 2.0 - 1.0
		var sig = (osc1 + osc2) * 0.5
		
		# Rolling filter
		var lfo = sin(TAU * lfo_rate * t)
		var ffreq = cutoff * (1.0 + lfo * lfo_depth)
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		for j in range(4):
			filt[j] += g * (sig - filt[j])
			sig = filt[j]
		
		sig = tanh(sig * (1.0 + drive * 2.0))
		data[i] = sig * 0.6
	
	return _to_wav(data)


func _gen_jungle_stab(p: Dictionary) -> AudioStreamWAV:
	var dur = 0.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var pitch = p.get("pitch", 0.0)
	var decay = p.get("decay", 0.15)
	var tone = p.get("tone", 0.6)
	
	var freq = 440.0 * pow(2.0, pitch / 12.0)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Brass-like harmonics
		var sig = sin(TAU * freq * t) * 0.5
		sig += sin(TAU * freq * 2.0 * t) * 0.3
		sig += sin(TAU * freq * 3.0 * t) * 0.15
		sig *= tone
		
		# Stab envelope
		var env = exp(-t / decay)
		
		data[i] = sig * env * 0.6
	
	return _to_wav(data)


func _gen_synthwave_lead(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var detune = p.get("detune", 0.008)
	var cutoff = p.get("cutoff", 3500.0)
	var filter_env = p.get("filter_env", 0.4)
	
	var freq = 220.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		var osc1 = fmod(freq * t, 1.0) * 2.0 - 1.0
		var osc2 = fmod(freq * (1.0 + detune) * t, 1.0) * 2.0 - 1.0
		var sig = (osc1 + osc2) * 0.5
		
		var env = 1.0 if t > 0.1 else t / 0.1
		var ffreq = cutoff * (1.0 - filter_env + filter_env * env)
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		for j in range(4):
			filt[j] += g * (sig - filt[j])
			sig = filt[j]
		
		if t > dur - 0.3: env *= (dur - t) / 0.3
		data[i] = sig * env * 0.5
	
	return _to_wav(data)


func _gen_tape_delay(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var delay_ms = p.get("delay_time", 200.0)
	var feedback = p.get("feedback", 0.5)
	var wow = p.get("wow", 0.3)
	
	var delay_samples = int(delay_ms * SAMPLE_RATE / 1000.0)
	var buffer = PackedFloat32Array()
	buffer.resize(delay_samples)
	var buf_pos = 0
	
	var freq = 220.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Source: simple tone burst
		var src = 0.0
		if t < 0.3:
			src = sin(TAU * freq * t) * exp(-t * 5.0)
		
		# Read from delay with wow
		var wow_mod = int(sin(TAU * 0.5 * t) * wow * 10.0)
		var read_pos = (buf_pos - delay_samples + wow_mod + buffer.size()) % buffer.size()
		var delayed = buffer[read_pos]
		
		# Write to buffer
		buffer[buf_pos] = src + delayed * feedback
		buf_pos = (buf_pos + 1) % buffer.size()
		
		data[i] = (src + delayed) * 0.5
	
	return _to_wav(data)


func _gen_bitcrush(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var bits = p.get("bits", 8)
	var sr = p.get("sample_rate", 0.5)
	var drive = p.get("drive", 0.3)
	var decay = p.get("decay", 0.3)
	
	var levels = pow(2, bits - 1)
	var step = int(1.0 / sr)
	var last = 0.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Simple drum hit
		var sig = sin(TAU * 60.0 * t) * exp(-t / decay)
		sig += randf_range(-1, 1) * exp(-t * 20.0) * 0.3
		
		# Drive
		sig = tanh(sig * (1.0 + drive * 2.0))
		
		# Sample rate reduction
		if i % step == 0:
			last = sig
		else:
			sig = last
		
		# Bit reduction
		sig = floor(sig * levels) / levels
		
		data[i] = sig * 0.6
	
	return _to_wav(data)


func _gen_ambient_drone(p: Dictionary) -> AudioStreamWAV:
	var dur = 3.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var voices = p.get("voices", 4)
	var detune = p.get("detune", 0.02)
	var drift = p.get("drift", 0.3)
	var brightness = p.get("brightness", 0.4)
	
	var freq = 110.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var sig = 0.0
		
		for v in range(voices):
			var d = (float(v) / (voices - 1) - 0.5) * detune
			var drift_mod = sin(TAU * 0.05 * t + v * PI/3) * drift * 0.01
			var v_freq = freq * (1.0 + d + drift_mod)
			sig += sin(TAU * v_freq * t) / voices
			sig += sin(TAU * v_freq * 2.0 * t) * brightness / voices * 0.3
		
		# Slow fade in/out
		var env = 1.0
		if t < 0.5: env = t / 0.5
		if t > dur - 0.5: env = (dur - t) / 0.5
		
		data[i] = sig * env * 0.4
	
	return _to_wav(data)


func _gen_disco_bass(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var cutoff = p.get("cutoff", 600.0)
	var reso = p.get("resonance", 0.2)
	var env_amt = p.get("env_amount", 0.4)
	var decay = p.get("decay", 0.15)
	
	var freq = 110.0
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		var osc = fmod(freq * t, 1.0) * 2.0 - 1.0
		
		var env = exp(-t / decay)
		var ffreq = cutoff + env * env_amt * cutoff * 3.0
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = reso * 4.0
		var fb = filt[3] * k
		var x = osc - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		data[i] = filt[3] * env * 0.7
	
	return _to_wav(data)


func _gen_four_floor(p: Dictionary) -> AudioStreamWAV:
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var tune = p.get("tune", 70.0)
	var punch = p.get("punch", 0.6)
	var decay = p.get("decay", 0.2)
	var click = p.get("click", 0.4)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Pitch envelope
		var p_env = exp(-t * 40.0)
		var freq = tune + p_env * 80.0 * punch
		
		# Body
		var body = sin(TAU * freq * t)
		
		# Click
		var clk = sin(TAU * 2500.0 * t) * exp(-t * 200.0) * click
		
		# Envelope
		var env = exp(-t / decay)
		
		data[i] = (body + clk) * env * 0.8
	
	return _to_wav(data)


func _gen_disco_hat(p: Dictionary) -> AudioStreamWAV:
	var dur = 0.5
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var decay = p.get("decay", 0.15)
	var open_decay = p.get("open_decay", 0.4)
	var tone = p.get("tone", 0.6)
	
	var freqs = [204.0, 298.0, 366.0, 522.0, 540.0, 598.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		var met = 0.0
		for f in freqs:
			met += 1.0 if fmod(f * t, 1.0) < 0.5 else -1.0
		met /= freqs.size()
		
		# Mix closed and open
		var closed_env = exp(-t / decay)
		var open_env = exp(-t / open_decay) * 0.5
		var env = closed_env + open_env
		
		var noise = randf_range(-1, 1) * (1.0 - tone) * 0.3
		
		data[i] = (met * tone + noise) * env * 0.4
	
	return _to_wav(data)


func _gen_solina(p: Dictionary) -> AudioStreamWAV:
	var dur = 2.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var ensemble = p.get("ensemble", 0.8)
	var atk = p.get("attack", 0.1)
	var rel = p.get("release", 0.6)
	
	var freq = 220.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		# Divide-down style with chorus
		var sig = 0.0
		sig += (fmod(freq * t, 1.0) * 2.0 - 1.0) * 0.3
		sig += (fmod(freq * 1.003 * t + sin(TAU * 0.5 * t) * 0.01, 1.0) * 2.0 - 1.0) * ensemble * 0.25
		sig += (fmod(freq * 0.997 * t + sin(TAU * 0.7 * t) * 0.01, 1.0) * 2.0 - 1.0) * ensemble * 0.25
		sig += (fmod(freq * 2.0 * t, 1.0) * 2.0 - 1.0) * 0.1
		
		var env = 1.0
		if t < atk: env = t / atk
		if t > dur - rel: env = (dur - t) / rel
		
		data[i] = sig * env * 0.4
	
	return _to_wav(data)


func _gen_acid_lead(p: Dictionary) -> AudioStreamWAV:
	var decay = p.get("decay", 0.12)
	var dur = max(0.8, decay * 7.0)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var base_freq = p.get("frequency", 330.0)
	var cutoff = p.get("cutoff", 1600.0)
	var reso = p.get("resonance", 0.72)
	var glide = p.get("glide", 0.04)
	var drive = p.get("drive", 0.3)
	
	var filt = [0.0, 0.0, 0.0]
	var start_freq = base_freq * 0.6
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var glide_pos = clamp(t / max(glide, 0.001), 0.0, 1.0)
		var freq = lerp(start_freq, base_freq, glide_pos)
		
		var ph = fmod(freq * t, 1.0)
		var saw = ph * 2.0 - 1.0
		var sqr = 1.0 if ph < 0.5 else -1.0
		var osc = saw * 0.82 + sqr * 0.18
		
		var env = exp(-t / max(decay, 0.02))
		var ffreq = cutoff + env * 2200.0
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.49)
		var g = tan(PI * fc)
		var fb = filt[2] * clamp(reso, 0.0, 0.98) * 3.8
		var x = tanh((osc - fb) * (1.0 + drive * 2.5))
		filt[0] += g * (x - filt[0])
		filt[1] += g * (filt[0] - filt[1])
		filt[2] += g * (filt[1] - filt[2])
		
		data[i] = tanh(filt[2] * env * (1.0 + drive * 1.5)) * 0.78
	
	return _to_wav(data)


func _gen_trap_bell(p: Dictionary) -> AudioStreamWAV:
	var decay = p.get("decay", 0.7)
	var dur = max(0.5, decay * 1.8)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var freq = p.get("frequency", 620.0)
	var mod_ratio = p.get("mod_ratio", 2.5)
	var mod_index = p.get("mod_index", 4.2)
	var shimmer = p.get("shimmer", 0.25)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		var attack_env = 1.0 if t > 0.005 else t / 0.005
		var env = exp(-t / max(decay, 0.08))
		var mod_env = exp(-t / max(decay * 0.6, 0.05))
		
		var mod = sin(TAU * freq * mod_ratio * t) * mod_index * mod_env
		var carrier = sin(TAU * freq * t + mod)
		var upper = sin(TAU * freq * 2.01 * t + mod * 0.4) * shimmer
		
		data[i] = (carrier * 0.85 + upper * 0.35) * env * attack_env * 0.65
	
	return _to_wav(data)


func _gen_trap_pad(p: Dictionary) -> AudioStreamWAV:
	var cutoff = p.get("cutoff", 700.0)
	var reso = p.get("resonance", 0.24)
	var detune = p.get("detune", 0.018)
	var atk = p.get("attack", 0.6)
	var rel = p.get("release", 1.6)
	
	var dur = max(2.4, atk + rel + 0.8)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var freq = 174.61
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		var osc = 0.0
		for v in range(3):
			var spread = float(v - 1)
			var drift = sin(TAU * (0.08 + abs(spread) * 0.03) * t) * detune * 0.25
			var v_freq = freq * (1.0 + spread * detune + drift)
			osc += fmod(v_freq * t, 1.0) * 2.0 - 1.0
		osc /= 3.0
		osc += (fmod(freq * 0.5 * t, 1.0) * 2.0 - 1.0) * 0.2
		
		var sustain_end = dur - rel
		var env = 1.0
		if t < atk:
			env = t / max(atk, 0.001)
		elif t > sustain_end:
			env = max(0.0, (dur - t) / max(rel, 0.001))
		
		var ffreq = cutoff * (1.0 + 0.18 * sin(TAU * 0.11 * t))
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.32)
		var g = tan(PI * fc)
		var k = clamp(reso, 0.0, 0.95) * 4.0
		var fb = filt[3] * k
		var x = osc - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		data[i] = filt[3] * env * 0.42
	
	return _to_wav(data)


func _gen_noise_riser(p: Dictionary) -> AudioStreamWAV:
	var dur = p.get("duration", 2.4)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var start_hz = p.get("start_hz", 250.0)
	var end_hz = p.get("end_hz", 9000.0)
	var drive = p.get("drive", 0.2)
	var level = p.get("level", 0.5)
	
	var lp = 0.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var prog = t / max(dur, 0.001)
		
		var cutoff = lerp(start_hz, end_hz, prog * prog)
		var alpha = clamp((TAU * cutoff) / SAMPLE_RATE, 0.0005, 0.99)
		
		var n = randf_range(-1.0, 1.0)
		lp += alpha * (n - lp)
		var hpf = n - lp
		
		var env = pow(prog, 0.8)
		if t > dur - 0.01:
			env *= (dur - t) / 0.01
		
		var sig = tanh(hpf * (1.0 + drive * 5.0))
		data[i] = sig * env * level * 0.9
	
	return _to_wav(data)


func _gen_noise_fall(p: Dictionary) -> AudioStreamWAV:
	var dur = p.get("duration", 2.0)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var start_hz = p.get("start_hz", 9500.0)
	var end_hz = p.get("end_hz", 260.0)
	var drive = p.get("drive", 0.18)
	var level = p.get("level", 0.45)
	
	var lp = 0.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var prog = t / max(dur, 0.001)
		
		var cutoff = lerp(start_hz, end_hz, prog)
		var alpha = clamp((TAU * cutoff) / SAMPLE_RATE, 0.0005, 0.99)
		
		var n = randf_range(-1.0, 1.0)
		lp += alpha * (n - lp)
		var hpf = n - lp
		
		var env = pow(1.0 - prog, 0.75)
		var atk = min(0.02, dur * 0.2)
		if t < atk:
			env *= t / max(atk, 0.001)
		
		var sig = tanh(hpf * (1.0 + drive * 4.0))
		data[i] = sig * env * level * 0.85
	
	return _to_wav(data)


func _gen_impact_hit(p: Dictionary) -> AudioStreamWAV:
	var fundamental = p.get("fundamental", 62.0)
	var pitch_drop = p.get("pitch_drop", 10.0)
	var noise_amt = p.get("noise", 0.35)
	var decay = p.get("decay", 0.28)
	var drive = p.get("drive", 0.25)
	
	var dur = max(0.35, decay * 2.5)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var drop_ratio = pow(2.0, pitch_drop / 12.0)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		
		var pitch_env = exp(-t * 22.0)
		var freq = fundamental * lerp(1.0, drop_ratio, pitch_env)
		var body = sin(TAU * freq * t)
		var sub = sin(TAU * fundamental * 0.5 * t) * 0.35
		var transient = randf_range(-1.0, 1.0) * noise_amt * exp(-t * 70.0)
		
		var env = exp(-t / max(decay, 0.05))
		var sig = (body * 0.9 + sub + transient) * env
		data[i] = tanh(sig * (1.0 + drive * 4.0)) * 0.92
	
	return _to_wav(data)


func _gen_dub_sub(p: Dictionary) -> AudioStreamWAV:
	var freq = p.get("frequency", 45.0)
	var decay = p.get("decay", 1.2)
	var saturation = p.get("saturation", 0.12)
	var drift = p.get("drift", 0.08)
	
	var dur = max(1.0, decay + 0.6)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var drift_mod = sin(TAU * 0.17 * t) * drift * 0.02
		var f = freq * (1.0 + drift_mod)
		var body = sin(TAU * f * t)
		var harm = sin(TAU * f * 2.0 * t) * saturation * 0.25
		var env = exp(-t / max(decay, 0.05))
		data[i] = tanh((body + harm) * (1.0 + saturation * 2.0)) * env * 0.75
	
	return _to_wav(data)


func _gen_dub_chord(p: Dictionary) -> AudioStreamWAV:
	var cutoff = p.get("cutoff", 900.0)
	var reso = p.get("resonance", 0.35)
	var atk = p.get("attack", 0.03)
	var decay = p.get("decay", 0.7)
	var detune = p.get("detune", 0.015)
	
	var dur = max(1.2, atk + decay + 0.5)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var base = 146.83
	var chord = [1.0, 1.1892, 1.4983]
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var osc = 0.0
		
		for ratio in chord:
			var f = base * ratio
			osc += (fmod(f * (1.0 + detune) * t, 1.0) * 2.0 - 1.0) * 0.5
			osc += (fmod(f * (1.0 - detune) * t, 1.0) * 2.0 - 1.0) * 0.5
		osc /= chord.size()
		
		var env = 1.0
		if t < atk:
			env = t / max(atk, 0.001)
		else:
			env = exp(-(t - atk) / max(decay, 0.05))
		
		var ffreq = cutoff * (1.0 + 0.2 * sin(TAU * 0.28 * t))
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.4)
		var g = tan(PI * fc)
		var k = clamp(reso, 0.0, 0.95) * 4.0
		var fb = filt[3] * k
		var x = osc - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		data[i] = filt[3] * env * 0.55
	
	return _to_wav(data)


func _gen_dub_echo_stab(p: Dictionary) -> AudioStreamWAV:
	var freq = p.get("frequency", 320.0)
	var decay = p.get("decay", 0.25)
	var echo_time = p.get("echo_time", 0.38)
	var echo_feedback = p.get("echo_feedback", 0.58)
	var drive = p.get("drive", 0.2)
	
	var dur = max(1.4, echo_time * 4.5)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var delay_samples = int(max(1.0, echo_time * SAMPLE_RATE))
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var ph = fmod(freq * t, 1.0)
		var saw = ph * 2.0 - 1.0
		var pulse = 1.0 if ph < 0.38 else -1.0
		var env = exp(-t / max(decay, 0.02))
		var dry = (saw * 0.7 + pulse * 0.3) * env
		
		var delayed = 0.0
		if i - delay_samples >= 0:
			delayed = data[i - delay_samples] * clamp(echo_feedback, 0.0, 0.98)
		
		data[i] = tanh((dry + delayed) * (1.0 + drive * 2.2)) * 0.7
	
	return _to_wav(data)


func _gen_ukg_shuff_hat(p: Dictionary) -> AudioStreamWAV:
	var tempo = p.get("tempo", 132.0)
	var swing = p.get("swing", 0.22)
	var decay = p.get("decay", 0.05)
	var tone = p.get("tone", 0.7)
	
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var step = 60.0 / max(tempo, 1.0) / 4.0
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var idx = int(floor(t / step))
		var start = float(idx) * step
		if idx % 2 == 1:
			start += swing * step * 0.5
		
		var local_t = t - start
		var env = 0.0
		if local_t >= 0.0 and local_t < 0.14:
			var accent = 1.0 if idx % 4 == 0 else (0.78 if idx % 2 == 0 else 0.58)
			env = exp(-local_t / max(decay, 0.005)) * accent
		
		var met = 0.0
		met += 1.0 if fmod(421.0 * t, 1.0) < 0.5 else -1.0
		met += 1.0 if fmod(613.0 * t, 1.0) < 0.5 else -1.0
		met += 1.0 if fmod(907.0 * t, 1.0) < 0.5 else -1.0
		met /= 3.0
		
		var noise = randf_range(-1.0, 1.0)
		var src = met * tone + noise * (1.0 - tone) * 0.8
		data[i] = src * env * 0.45
	
	return _to_wav(data)


func _gen_ukg_wobble_bass(p: Dictionary) -> AudioStreamWAV:
	var cutoff = p.get("cutoff", 480.0)
	var reso = p.get("resonance", 0.35)
	var lfo_rate = p.get("lfo_rate", 3.2)
	var lfo_depth = p.get("lfo_depth", 0.45)
	var drive = p.get("drive", 0.25)
	
	var dur = 1.2
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var freq = 82.41
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var square = 1.0 if fmod(freq * t, 1.0) < 0.5 else -1.0
		var sub = sin(TAU * freq * 0.5 * t) * 0.6
		var osc = square * 0.65 + sub * 0.35
		
		var wob = (sin(TAU * lfo_rate * t) * 0.5 + 0.5) * lfo_depth
		var ffreq = cutoff * (1.0 + wob * 2.4)
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.35)
		var g = tan(PI * fc)
		var k = clamp(reso, 0.0, 0.95) * 4.0
		var fb = filt[3] * k
		var x = tanh((osc - fb) * (1.0 + drive * 3.0))
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var env = exp(-t / 1.0)
		data[i] = filt[3] * env * 0.7
	
	return _to_wav(data)


func _gen_ukg_pluck(p: Dictionary) -> AudioStreamWAV:
	var cutoff = p.get("cutoff", 1800.0)
	var reso = p.get("resonance", 0.5)
	var decay = p.get("decay", 0.22)
	var pluck = p.get("pluck", 0.8)
	var delay_mix = p.get("delay_mix", 0.22)
	
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var freq = 293.66
	var filt = [0.0, 0.0, 0.0, 0.0]
	var delay_samples = int(0.19 * SAMPLE_RATE)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var saw = fmod(freq * t, 1.0) * 2.0 - 1.0
		var tri = 2.0 * abs(2.0 * fmod(freq * t, 1.0) - 1.0) - 1.0
		var osc = saw * 0.7 + tri * 0.3
		
		var env = exp(-t / max(decay, 0.03))
		var ffreq = cutoff + env * pluck * 3500.0
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = clamp(reso, 0.0, 0.98) * 4.0
		var fb = filt[3] * k
		var x = osc - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var dry = filt[3] * env
		var delayed = 0.0
		if i - delay_samples >= 0:
			delayed = data[i - delay_samples] * delay_mix * 0.5
		
		data[i] = (dry + delayed) * 0.72
	
	return _to_wav(data)


func _gen_ukg_vocal_chop(p: Dictionary) -> AudioStreamWAV:
	var formant = p.get("formant", 1.15)
	var slice_rate = p.get("slice_rate", 8.0)
	var decay = p.get("decay", 0.3)
	var grit = p.get("grit", 0.3)
	var width = p.get("width", 0.4)
	
	var dur = 1.0
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var base = 210.0 * formant
	var slice_len = 1.0 / max(slice_rate, 0.5)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var local_t = fmod(t, slice_len)
		var gate = 1.0 if local_t < slice_len * 0.34 else 0.0
		var env = exp(-local_t / max(decay, 0.03))
		
		var v1 = sin(TAU * base * t)
		var v2 = sin(TAU * base * 1.73 * t) * 0.55
		var v3 = sin(TAU * base * 2.41 * t) * 0.32
		var wob = sin(TAU * 2.0 * t) * width * 0.08
		var noise = randf_range(-1.0, 1.0) * grit * 0.25
		var sig = (v1 + v2 + v3 + wob + noise) * gate * env
		data[i] = tanh(sig * (1.0 + grit * 2.5)) * 0.55
	
	return _to_wav(data)


func _gen_neuro_mid_bass(p: Dictionary) -> AudioStreamWAV:
	var freq = p.get("frequency", 90.0)
	var mod_ratio = p.get("mod_ratio", 1.8)
	var mod_index = p.get("mod_index", 6.0)
	var cutoff = p.get("cutoff", 800.0)
	var lfo_rate = p.get("lfo_rate", 4.5)
	var drive = p.get("drive", 0.45)
	
	var dur = 1.2
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var motion = sin(TAU * lfo_rate * t) * 0.5 + 0.5
		var mod = sin(TAU * freq * mod_ratio * t) * mod_index * (0.6 + 0.4 * motion)
		var fm = sin(TAU * freq * t + mod)
		var saw = fmod(freq * 1.01 * t, 1.0) * 2.0 - 1.0
		var osc = fm * 0.7 + saw * 0.3
		
		var ffreq = cutoff * (1.0 + motion * 2.2)
		var fc = clamp(ffreq / SAMPLE_RATE, 0.001, 0.4)
		var g = tan(PI * fc)
		var fb = filt[3] * 3.2
		var x = tanh((osc - fb) * (1.0 + drive * 4.0))
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var env = exp(-t / 1.0)
		data[i] = filt[3] * env * 0.78
	
	return _to_wav(data)


func _gen_neuro_laser(p: Dictionary) -> AudioStreamWAV:
	var start_freq = p.get("start_freq", 1800.0)
	var end_freq = p.get("end_freq", 120.0)
	var decay = p.get("decay", 0.35)
	var resonance = p.get("resonance", 0.65)
	var noise = p.get("noise", 0.15)
	
	var dur = max(0.5, decay * 2.0)
	var count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		var prog = t / max(dur, 0.001)
		var freq = lerp(start_freq, end_freq, pow(prog, 0.55))
		
		var sine = sin(TAU * freq * t)
		var pulse = 1.0 if fmod(freq * 2.0 * t, 1.0) < 0.5 else -1.0
		var transient = randf_range(-1.0, 1.0) * noise * exp(-t * 70.0)
		var env = exp(-t / max(decay, 0.05))
		
		var sig = (sine * 0.75 + pulse * 0.25 + transient) * env
		data[i] = tanh(sig * (1.0 + resonance * 2.2)) * 0.8
	
	return _to_wav(data)


func _gen_test_tone() -> AudioStreamWAV:
	var count = int(SAMPLE_RATE * 0.5)
	var data = PackedFloat32Array()
	data.resize(count)
	
	for i in range(count):
		var t = float(i) / SAMPLE_RATE
		data[i] = sin(TAU * 440.0 * t) * exp(-t * 3.0) * 0.5
	
	return _to_wav(data)


func _to_wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(SAMPLE_RATE)
	wav.stereo = false
	
	var bytes = PackedByteArray()
	bytes.resize(data.size() * 2)
	
	for i in range(data.size()):
		var s = clamp(data[i], -1.0, 1.0)
		var si = int(s * 32767)
		bytes[i * 2] = si & 0xFF
		bytes[i * 2 + 1] = (si >> 8) & 0xFF
	
	wav.data = bytes
	return wav
