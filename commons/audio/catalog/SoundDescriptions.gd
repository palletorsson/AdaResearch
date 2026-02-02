# SoundDescriptions.gd
# One-sentence synthesis descriptions matching actual AudioSynthesizer implementation
# Each description explains HOW the sound is made, not just what it sounds like

extends RefCounted
class_name SoundDescriptions

# Maps layer names (case-insensitive) to synthesis descriptions
const DESCRIPTIONS = {
	# === BASS ===
	"moog_bass": "Dual detuned sawtooth oscillators with sub-octave square, driven through fast-attack filter envelope and soft saturation.",
	"moog bass": "Dual detuned sawtooth oscillators with sub-octave square, driven through fast-attack filter envelope and soft saturation.",
	"juno_bass": "DCO saw/square blend with PWM and sub oscillator, shaped by plucky filter envelope with tape warmth.",
	"juno bass": "DCO saw/square blend with PWM and sub oscillator, shaped by plucky filter envelope with tape warmth.",
	"filter_bass": "Sidechained sawtooth with rhythmic filter envelope following the kick, creating pumping disco movement.",
	"filter bass": "Sidechained sawtooth with rhythmic filter envelope following the kick, creating pumping disco movement.",
	"reese_bass": "Two detuned saws (±0.07 semitone) with sub sine, slow LFO filter wobble for jungle growl.",
	"reese bass": "Two detuned saws (±0.07 semitone) with sub sine, slow LFO filter wobble for jungle growl.",
	"trance_bass": "Sub-heavy sine with sidechained compression, foundation layer under supersaw chords.",
	"trance bass": "Sub-heavy sine with sidechained compression, foundation layer under supersaw chords.",
	"bass": "Sawtooth oscillator with resonant lowpass filter and amplitude envelope.",
	"sub bass": "Pure sine wave one octave below root, providing low-end weight without harmonic content.",
	"acid bass": "303-style sawtooth with high resonance, accent, and slide for squelchy acid lines.",
	"hoover bass": "Aggressive PWM with massive detuning and filter resonance sweep, classic rave stab.",
	
	# === PAD ===
	"moog_pad": "Three detuned saws per voice with drifting pitch (±3 cents) and slow lowpass filter modulation.",
	"moog pad": "Three detuned saws per voice with drifting pitch (±3 cents) and slow lowpass filter modulation.",
	"supersaw_pad": "8-voice unison sawtooths with ±0.06 semitone detune and 2-second attack for massive chords.",
	"supersaw pad": "8-voice unison sawtooths with ±0.06 semitone detune and 2-second attack for massive chords.",
	"juno_pad": "DCO poly synth with ensemble chorus (BBD emulation), the classic warm 80s pad.",
	"juno pad": "DCO poly synth with ensemble chorus (BBD emulation), the classic warm 80s pad.",
	"vocoder_pad": "Warm filtered pad with formant-like frequency bands, adding robotic texture.",
	"vocoder pad": "Warm filtered pad with formant-like frequency bands, adding robotic texture.",
	"ambient_pad": "Four-octave stacked sines with 5-second attack and long reverb decay for immersive drones.",
	"ambient pad": "Four-octave stacked sines with 5-second attack and long reverb decay for immersive drones.",
	"string_pad": "Detuned saws with slow attack and ensemble chorus simulating string section.",
	"string pad": "Detuned saws with slow attack and ensemble chorus simulating string section.",
	"pad": "Multi-voice detuned oscillators with slow attack envelope and stereo chorus.",
	"warbly pad": "Tape-degraded poly synth with 12% pitch drift and lo-fi saturation.",
	
	# === LEAD ===
	"elp_lead": "High-resonance saw with 80ms portamento glide and 5Hz vibrato, screaming Minimoog solo.",
	"elp lead": "High-resonance saw with 80ms portamento glide and 5Hz vibrato, screaming Minimoog solo.",
	"duck_lead": "Bandpass-filtered saw with 1200Hz resonant peak, short envelope per beat creating 'quack'.",
	"duck lead": "Bandpass-filtered saw with 1200Hz resonant peak, short envelope per beat creating 'quack'.",
	"supersaw_lead": "8-voice detuned saw one octave up with bright filter, soaring trance melody.",
	"supersaw lead": "8-voice detuned saw one octave up with bright filter, soaring trance melody.",
	"vangelis_keys": "Juno saw with high resonance (88%) and velocity-sensitive pluck, ensemble chorus.",
	"vangelis keys": "Juno saw with high resonance (88%) and velocity-sensitive pluck, ensemble chorus.",
	"lead": "Bright sawtooth with filter envelope and optional vibrato for melodic lines.",
	"melodic_sequence": "Detuned mono synth with 8% drift playing arpeggiated patterns.",
	
	# === DRUMS ===
	"motorik_drums": "Steady 4/4 kick and backbeat snare with driving 8th-note hats, Kraftwerk/Neu! pulse.",
	"motorik drums": "Steady 4/4 kick and backbeat snare with driving 8th-note hats, Kraftwerk/Neu! pulse.",
	"dusty_drums": "Lo-fi filtered kit with tape saturation and reduced sample rate for vintage warmth.",
	"dusty drums": "Lo-fi filtered kit with tape saturation and reduced sample rate for vintage warmth.",
	"amen_break": "Chopped breakbeat at 170 BPM with timestretched slices, classic jungle energy.",
	"amen break": "Chopped breakbeat at 170 BPM with timestretched slices, classic jungle energy.",
	"drums": "Synthesized kick (pitch-swept sine), noise snare, and filtered noise hats.",
	"909_drums": "Roland TR-909 emulation: punchy kick, snappy snare, metallic hats.",
	"808_drums": "Roland TR-808 emulation: deep sub kick, clicky snare, crisp hats.",
	"breakbeat": "Sampled funk break with swing and humanized timing.",
	"2step_drums": "UK garage pattern with skipping kick and shuffled hats.",
	
	# === SEQUENCES & ARPS ===
	"kraftwerk_seq": "8-note square wave sequence with slow filter sweep, Autobahn-style hypnotic pulse.",
	"kraftwerk seq": "8-note square wave sequence with slow filter sweep, Autobahn-style hypnotic pulse.",
	"arp": "Arpeggiated chord tones through filtered saw with delay feedback.",
	"arpeggio": "Arpeggiated chord tones through filtered saw with delay feedback.",
	"sequencer": "16th-note pattern with filter envelope per step, creating rhythmic movement.",
	
	# === FX & TEXTURE ===
	"chiff": "Wavetable double-hit transient with inverse attack envelope for rhythmic texture.",
	"stab": "Short filtered chord hit with fast decay, punctuating rhythmic accents.",
	"noise": "Filtered white noise with slow modulation for atmospheric texture.",
	"crackle_layer": "Vinyl noise simulation with random pops and continuous hiss.",
	"texture_layer": "Granular-style evolving noise with 0.07Hz LFO modulation.",
	
	# === KEYS ===
	"keys": "FM piano simulation with tape saturation, warm Rhodes-like tone.",
	"fm_keys": "DX7-style FM synthesis with 2-operator algorithm for electric piano.",
	"tape_keys": "FM keys processed through tape emulation with wow/flutter.",
	
	# === VOCAL ===
	"pitched_vocal": "Timestretched R&B sample pitched down 5 semitones with heavy reverb.",
	"vocal_chop": "Formant-preserved vocal slice pitched to root note.",
}

# Song-specific layer descriptions (more contextual)
const SONG_LAYER_DESCRIPTIONS = {
	"french_touch": {
		"filter_bass": "Disco sample filtered through sidechained lowpass, pumping with the four-on-floor kick.",
		"duck_lead": "Resonant bandpass 'wah' lead triggered on each beat, the signature Daft Punk quack.",
		"chiff": "Percussive wavetable hit with reversed attack, adding rhythmic ear candy.",
		"vocoder_pad": "Robot voice pad filtered through 16-band vocoder emulation.",
	},
	"supersaw_trance": {
		"supersaw_pad": "Roland JP-8000 style 8-voice supersaw with ±0.06 semitone spread, the trance anthem sound.",
		"supersaw_lead": "Same supersaw engine one octave up, cutting through the mix for melodies.",
		"trance_bass": "Sub sine layered under the supersaw, sidechained to create pumping movement.",
	},
	"lofi_house": {
		"juno_bass": "Roland Juno-60 DCO bass with PWM modulation and that classic chorus warmth.",
		"juno_pad": "Juno poly mode with ensemble effect, the defining sound of lo-fi house.",
		"dusty_drums": "909 kit run through tape saturation and bit reduction for dusty grooves.",
	},
	"blade_runner": {
		"vangelis_keys": "CS-80 emulation with high resonance (88%) and ribbon-controller-style expression.",
		"string_pad": "Lush detuned strings with slow ensemble modulation, cinematic depth.",
	},
	"ambient_works": {
		"keys": "Tape-saturated FM piano with drift, warm and nostalgic.",
		"pad": "Warm analog-style pad with slow filter movement and tape wobble.",
		"bass": "303-inspired acid bass with high resonance and accent patterns.",
	},
	"prog_synth_70s": {
		"moog_pad": "Minimoog 3-oscillator pad with unstable tuning and ladder filter warmth.",
		"moog_bass": "Classic Moog bass: saw + saw (detuned) + sub square with fast filter attack.",
		"elp_lead": "Keith Emerson screaming lead with portamento, high resonance, and vibrato.",
		"kraftwerk_seq": "Synthi AKS style 8-note sequence with evolving filter, motorik hypnosis.",
	},
	"reese_jungle": {
		"reese_bass": "Two heavily detuned saws with sub, LFO-modulated filter for that menacing wobble.",
		"amen_break": "The iconic 6-second drum break chopped and timestretched at 170 BPM.",
	},
	"burial": {
		"sub_bass": "Deep UK garage sub with minimal harmonics, felt more than heard.",
		"atmosphere_pad": "Dark ambient wash with 6-second reverb decay, South London rain.",
		"pitched_vocal": "R&B vocal pitched down and timestretched, ghostly and longing.",
		"crackle_layer": "Vinyl surface noise adding warmth and nostalgia.",
		"garage_stab": "Soft organ chord stab with heavy reverb, 2-step punctuation.",
	},
	"kraftwerk": {
		"minimoog_bass": "Model D emulation with ladder filter, clean and precise.",
		"sequencer_line": "ARP 2600 style sequence with zero drift, mechanical perfection.",
		"vocoder_pad": "Sennheiser VSM201 vocoder emulation, robot voice texture.",
	},
	"boards_of_canada": {
		"warbly_pad": "Tape-degraded poly with 12% oscillator drift and lo-fi saturation.",
		"melodic_sequence": "Detuned mono sequence with nostalgic, sun-bleached character.",
		"texture_layer": "Granular noise with VHS-style artifacts and slow modulation.",
	},
}


static func get_description(layer_name: String, song_id: String = "") -> String:
	"""Get synthesis description for a layer, with optional song-specific context"""
	var key = layer_name.to_lower().replace(" ", "_")
	var key_spaced = layer_name.to_lower()
	
	# Try song-specific first
	if not song_id.is_empty():
		var song_layers = SONG_LAYER_DESCRIPTIONS.get(song_id, {})
		if song_layers.has(key):
			return song_layers[key]
		if song_layers.has(key_spaced):
			return song_layers[key_spaced]
	
	# Fall back to general descriptions
	if DESCRIPTIONS.has(key):
		return DESCRIPTIONS[key]
	if DESCRIPTIONS.has(key_spaced):
		return DESCRIPTIONS[key_spaced]
	
	# Try partial match
	for desc_key in DESCRIPTIONS.keys():
		if key in desc_key or desc_key in key:
			return DESCRIPTIONS[desc_key]
	
	return "Synthesized layer with configurable parameters."


static func get_short_type(layer_name: String) -> String:
	"""Get short synthesis type label"""
	var lower = layer_name.to_lower()
	
	if "supersaw" in lower: return "Supersaw"
	if "moog" in lower: return "Moog"
	if "juno" in lower: return "Juno DCO"
	if "reese" in lower: return "Reese"
	if "303" in lower or "acid" in lower: return "303 Acid"
	if "808" in lower: return "808"
	if "909" in lower: return "909"
	if "amen" in lower: return "Amen Break"
	if "fm" in lower: return "FM Synth"
	if "vocoder" in lower: return "Vocoder"
	if "granular" in lower: return "Granular"
	
	if "bass" in lower: return "Bass Synth"
	if "pad" in lower: return "Pad Synth"
	if "lead" in lower: return "Lead Synth"
	if "keys" in lower: return "Keys"
	if "drum" in lower: return "Drums"
	if "arp" in lower: return "Arpeggiator"
	if "seq" in lower: return "Sequencer"
	
	return "Synth"
