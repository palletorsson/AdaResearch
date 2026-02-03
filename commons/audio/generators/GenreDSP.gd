# GenreDSP.gd
# Genre-specific DSP building blocks with EXACT parameters from research
# Source: C:\Users\palle\Documents\GitHub\ada_the_research\music_tracks\*.md
#
# Each genre has documented specifications for authentic recreation.
# Parameters come from analysis of original equipment and production techniques.

extends RefCounted
class_name GenreDSP

const SAMPLE_RATE = 44100.0

# =============================================================================
# GENRE IDENTIFIERS
# =============================================================================
enum Genre {
	AMBIENT_WORKS,     # Aphex Twin - lo-fi breaks, tape saturation, acid 303
	DETROIT_TECHNO,    # Juan Atkins - cold 909, minimal, machine funk, ZERO drift
	MORODER_DISCO,     # Giorgio Moroder - Moog sequencer, 4-on-floor, strings
	SYNTHWAVE,         # Kavinsky - gated reverb, LinnDrum, supersaw, 80s
	RAVE,              # Prodigy - hoover bass (40 cent detune!), breakbeats
	FRENCH_TOUCH,      # Daft Punk - filter disco, BANDPASS quack, sidechain
	GYPSY_WOMAN_HOUSE, # Crystal Waters - piano stabs, bouncy 909
	BOARDS_OF_CANADA,  # BoC - tape wow (0.15Hz LFO), 15 cent detune, 10-bit
	BURIAL,            # Burial - 2-step (NOT quantized), vinyl crackle, -5 semitone vocals
	KRAFTWERK,         # Kraftwerk - ZERO modulation, precise, vocoder, robotic
	SUPERSAW_TRANCE,   # JP-8000 - 8 voice supersaw, 25 cent detune, 138 BPM
	REESE_JUNGLE,      # Jungle - reese bass (35 cent detune), amen breaks, 170 BPM
	PROG_SYNTH_70S,    # ELP/Kraftwerk - Minimoog, motorik beat
	LOFI_HOUSE,        # DJ Seinfeld - Juno DCO, dusty drums, 12-bit, 118 BPM
	AMBIENT_TECHNO,    # The Orb - evolving pads, 5s attack, minimal kick
	BLADE_RUNNER,      # Vangelis - CS-80 brass, plate reverb, vibrato
}


# =============================================================================
# KICK DRUM GENERATORS
# Research sources: detroit_techno.md, burial.md, rave.md, etc.
# =============================================================================

static func generate_kick(genre: Genre, t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0 or dt > 0.5:
		return 0.0
	
	match genre:
		Genre.AMBIENT_WORKS:
			# Lo-fi sampled breakbeat kick - Research: "hip-hop influenced drum programming"
			# Bit depth: 12-bit, high-shelf EQ cut -3dB
			var freq = 50.0 + exp(-dt * 20.0) * 60.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 12.0)
			kick = tanh(kick * 1.2)  # Tape saturation
			kick = floor(kick * 2048.0) / 2048.0  # 12-bit simulation
			return kick * 0.45
		
		Genre.DETROIT_TECHNO:
			# Research: "808 sub bass: cutoff 150Hz, attack 0.001s, decay 0.3s"
			# "909 drums: high shelf boost +2dB for brightness"
			var freq = 50.0 + exp(-dt * 35.0) * 80.0  # Fast pitch envelope
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 10.0)
			return kick * 0.6  # +2dB brightness (louder)
		
		Genre.MORODER_DISCO:
			# Research: "kick is inside sequencer pulse, not separate"
			var freq = 50.0 + exp(-dt * 25.0) * 50.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 15.0)
			return kick * 0.4
		
		Genre.SYNTHWAVE:
			# Research: "LinnDrum / gated reverb drums"
			# "Punchy electronic kick with click transient"
			var freq = 60.0 + exp(-dt * 30.0) * 50.0
			var body = sin(2.0 * PI * freq * dt) * exp(-dt * 8.0)
			var click = sin(2.0 * PI * 2500.0 * dt) * exp(-dt * 200.0) * 0.15
			return (body + click) * 0.5
		
		Genre.RAVE:
			# Research: "Breakbeat foundation, tempo 140-160 BPM"
			# "Heavy compression, distortion"
			var freq = 60.0 + exp(-dt * 40.0) * 80.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 12.0)
			kick = tanh(kick * 1.8)  # Heavy distortion
			return kick * 0.55
		
		Genre.FRENCH_TOUCH:
			# Research: "Four-on-the-floor, steady kick at 110-130 BPM"
			var freq = 55.0 + exp(-dt * 30.0) * 60.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 10.0)
			return kick * 0.5
		
		Genre.GYPSY_WOMAN_HOUSE:
			# Research: "909-style house kick, punchy"
			var freq = 55.0 + exp(-dt * 30.0) * 45.0
			var kick = sin(2.0 * PI * freq * dt)
			kick *= exp(-dt * 15.0)
			kick = tanh(kick * 2.5)
			return kick * 0.5
		
		Genre.BOARDS_OF_CANADA:
			# Research: "Hip-hop influenced tempo (~100 BPM)"
			# "Bit crushing 12-bit, moderate distortion 0.2"
			var freq = 50.0 + exp(-dt * 18.0) * 50.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 10.0)
			kick = floor(kick * 2048.0) / 2048.0  # 12-bit
			kick = tanh(kick * 1.2)  # distortion 0.2
			return kick * 0.42
		
		Genre.BURIAL:
			# Research: "Kick avoids beat 1" "NOT quantized - fishbone look"
			# UK garage style offbeat kick
			var freq = 48.0 + exp(-dt * 22.0) * 40.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 12.0)
			return kick * 0.48
		
		Genre.KRAFTWERK:
			# Research: "Electric Percussion: pitch envelope, zero distortion - CLEAN"
			# "Resonant filter for pitched boing sounds"
			var freq = 65.0 + exp(-dt * 28.0) * 50.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 9.0)
			# NO distortion - Kraftwerk is clean
			return kick * 0.35
		
		Genre.SUPERSAW_TRANCE:
			# Research: "138-145 BPM, punchy trance kick"
			var freq = 50.0 + exp(-dt * 50.0) * 100.0  # Very fast pitch envelope
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 15.0)
			return kick * 0.55
		
		Genre.REESE_JUNGLE:
			# Research: "170 BPM tempo, Amen break processing"
			var freq = 55.0 + exp(-dt * 50.0) * 80.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 15.0)
			return kick * 0.5
		
		Genre.PROG_SYNTH_70S:
			# Research: "Motorik beat - steady 4/4 with driving 8th-note hi-hats"
			var freq = 55.0 + exp(-dt * 40.0) * 80.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 25.0)
			return kick * 0.45
		
		Genre.LOFI_HOUSE:
			# Research: "Dusty drums, bit crushing 12-bit, distortion 0.15"
			var freq = 45.0 + exp(-dt * 25.0) * 50.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 8.0)
			kick = floor(kick * 2048.0) / 2048.0  # 12-bit
			kick = tanh(kick * 1.15)  # distortion 0.15
			return kick * 0.45
		
		Genre.AMBIENT_TECHNO:
			# Research: "Minimal soft kick"
			var freq = 40.0 + exp(-dt * 20.0) * 40.0
			var kick = sin(2.0 * PI * freq * dt) * exp(-dt * 6.0)
			return kick * 0.35
		
		Genre.BLADE_RUNNER:
			# Cinematic - no traditional kick
			return 0.0
	
	return 0.0


# =============================================================================
# SNARE/CLAP GENERATORS
# =============================================================================

static func generate_snare(genre: Genre, t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0 or dt > 0.5:
		return 0.0
	
	var noise = randf() * 2.0 - 1.0
	
	match genre:
		Genre.AMBIENT_WORKS:
			# Research: "12-bit bitcrush, light distortion 0.1, high-shelf -3dB"
			var body = sin(2.0 * PI * 180.0 * dt) * exp(-dt * 18.0) * 0.4
			var snares = noise * exp(-dt * 15.0) * 0.5
			var result = (body + snares) * 0.35
			result = floor(result * 2048.0) / 2048.0  # 12-bit
			return result * 0.85  # -3dB high shelf simulated with lower level
		
		Genre.DETROIT_TECHNO:
			# Research: "909 snappy snare, high pitch, no reverb"
			var body = sin(2.0 * PI * 220.0 * dt) * exp(-dt * 25.0) * 0.35
			var snares = noise * exp(-dt * 28.0) * 0.45
			return (body + snares) * 0.3  # Bright, no reverb
		
		Genre.SYNTHWAVE:
			# Research: "GATED REVERB - reverb decay 1.5s then cut"
			var body = sin(2.0 * PI * 200.0 * dt) * exp(-dt * 25.0) * 0.3
			var snares = noise * exp(-dt * 20.0) * 0.4
			# Gated reverb: 1.5s decay, then sharp cutoff at 0.15s
			var gate_length = 0.15
			var reverb_env = 0.0
			if dt < gate_length:
				reverb_env = (1.0 - exp(-dt * 15.0)) * (1.0 - dt / gate_length)
			var reverb = noise * reverb_env * 0.4
			return (body + snares + reverb) * 0.3
		
		Genre.RAVE:
			# Research: "Heavy compression, distortion on bass elements"
			var body = sin(2.0 * PI * 180.0 * dt) * exp(-dt * 18.0) * 0.5
			var snares = noise * exp(-dt * 22.0) * 0.5
			var result = body + snares
			return tanh(result * 1.5) * 0.4  # Distortion
		
		Genre.FRENCH_TOUCH:
			# Research: "Claps on 2 and 4"
			var clap = noise * exp(-dt * 25.0) * 0.5
			var body = sin(2.0 * PI * 150.0 * dt) * exp(-dt * 30.0) * 0.3
			return (clap + body) * 0.25
		
		Genre.GYPSY_WOMAN_HOUSE:
			# Research: "909 house snare"
			var body = sin(2.0 * PI * 200.0 * dt) * exp(-dt * 22.0) * 0.35
			var snares = noise * exp(-dt * 25.0) * 0.45
			return (body + snares) * 0.28
		
		Genre.BOARDS_OF_CANADA:
			# Research: "12-bit, distortion 0.2, high shelf -3dB"
			var body = sin(2.0 * PI * 170.0 * dt) * exp(-dt * 18.0) * 0.4
			var snares = noise * exp(-dt * 15.0) * 0.45
			var result = (body + snares) * 0.28
			result = floor(result * 2048.0) / 2048.0  # 12-bit
			return result * 0.85
		
		Genre.BURIAL:
			# Research: "Snares and hi-hats covered in fuzz and phaser, like cobwebs"
			# "NOT quantized"
			var body = sin(2.0 * PI * 160.0 * dt) * exp(-dt * 20.0) * 0.35
			var snares = noise * exp(-dt * 18.0) * 0.4
			var result = body + snares
			return tanh(result * 2.0) * 0.18  # "Fuzz"
		
		Genre.KRAFTWERK:
			# Research: "Clean - zero distortion"
			var body = sin(2.0 * PI * 220.0 * dt) * exp(-dt * 22.0) * 0.4
			var snares = noise * exp(-dt * 28.0) * 0.35
			return (body + snares) * 0.18
		
		Genre.SUPERSAW_TRANCE:
			# Research: "Tight trance snare"
			var body = sin(2.0 * PI * 200.0 * dt) * exp(-dt * 25.0) * 0.4
			var snares = noise * exp(-dt * 30.0) * 0.35
			return (body + snares) * 0.25
		
		Genre.REESE_JUNGLE:
			# Research: "Amen break processing, light distortion 0.1"
			var body = sin(2.0 * PI * 200.0 * dt) * exp(-dt * 20.0) * 0.5
			var snares = noise * exp(-dt * 25.0) * 0.6
			var result = (body + snares)
			return tanh(result * 1.1) * 0.35
		
		Genre.LOFI_HOUSE:
			# Research: "12-bit bitcrush, distortion 0.15, high shelf -3dB"
			var body = sin(2.0 * PI * 180.0 * dt) * exp(-dt * 18.0) * 0.4
			var snares = noise * exp(-dt * 18.0) * 0.45
			var result = (body + snares) * 0.28
			result = floor(result * 2048.0) / 2048.0
			return result * 0.85
		
		_:
			var body = sin(2.0 * PI * 180.0 * dt) * exp(-dt * 20.0) * 0.4
			var snares = noise * exp(-dt * 20.0) * 0.4
			return (body + snares) * 0.25
	
	return 0.0


# =============================================================================
# HI-HAT GENERATORS
# =============================================================================

static func generate_hihat(genre: Genre, t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	if dt < 0 or dt > 0.3:
		return 0.0
	
	var noise = randf() * 2.0 - 1.0
	var decay = 80.0 if not open else 20.0
	
	match genre:
		Genre.AMBIENT_WORKS:
			# Research: "High-shelf EQ cut -3dB"
			var hat = noise * exp(-dt * decay * 0.6) * 0.12
			return hat * 0.7  # Darker due to high-shelf cut
		
		Genre.DETROIT_TECHNO:
			# Research: "909 hats, high shelf boost +2dB for brightness"
			var hat = noise * exp(-dt * decay) * 0.15
			hat += sin(2.0 * PI * 9000.0 * dt) * exp(-dt * 150.0) * 0.05
			return hat * 1.1  # Brighter
		
		Genre.SYNTHWAVE:
			# Research: "Gated reverb on drums"
			var hat = noise * exp(-dt * decay)
			hat += sin(2.0 * PI * 8000.0 * dt) * exp(-dt * 100.0) * 0.1
			return hat * 0.12
		
		Genre.RAVE:
			# Research: "140-160 BPM, frantic"
			var hat = noise * exp(-dt * decay * 1.2) * 0.18
			return hat
		
		Genre.BOARDS_OF_CANADA:
			# Research: "High shelf cut -3dB, dusty"
			var hat = noise * exp(-dt * decay * 0.7) * 0.1
			return hat * 0.7
		
		Genre.BURIAL:
			# Research: "Snares and hi-hats covered in fuzz and phaser, like cobwebs"
			var hat = noise * exp(-dt * decay * 0.9)
			hat *= sin(2.0 * PI * 2000.0 * dt + sin(dt * 10.0) * 3.0)  # Phaser sim
			return hat * 0.08
		
		Genre.KRAFTWERK:
			# Research: "Clean electronic hats - zero distortion"
			var hat = noise * exp(-dt * decay) * 0.1
			return hat
		
		Genre.REESE_JUNGLE:
			# Research: "170 BPM"
			var hat = noise * exp(-dt * decay * 1.3) * 0.15
			return hat
		
		Genre.LOFI_HOUSE:
			# Research: "High shelf -3dB, dusty"
			var hat = noise * exp(-dt * decay * 0.8) * 0.1
			return hat * 0.7
		
		_:
			var hat = noise * exp(-dt * decay) * 0.12
			return hat
	
	return 0.0


# =============================================================================
# BASS SYNTHESIS - EXACT PARAMETERS FROM RESEARCH
# =============================================================================

static func generate_bass(genre: Genre, t: float, freq: float, filter_env: float = 1.0) -> float:
	match genre:
		Genre.AMBIENT_WORKS:
			# Research: "303 acid bass: ladder filter, cutoff 800Hz, resonance 0.8"
			# "Attack 0.001s, decay 0.15s, sustain 0.3"
			# "Filter LFO: 2Hz rate, 0.4 depth"
			# "Saturation/distortion 0.25"
			var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
			var cutoff = 200.0 + filter_env * 600.0  # 800Hz max
			var lfo = sin(2.0 * PI * 2.0 * t) * 0.4  # 2Hz LFO, 0.4 depth
			cutoff *= (1.0 + lfo * 0.5)
			var resonance = sin(2.0 * PI * cutoff * t) * 0.8 * 0.3  # High resonance 0.8
			saw = tanh((saw + resonance) * 1.25) * 0.4  # distortion 0.25
			return saw
		
		Genre.DETROIT_TECHNO:
			# Research: "808 sub bass: cutoff 150Hz, attack 0.001s, decay 0.3s, sustain 0.5"
			# "Sub level boosted +3dB"
			var square = sign(sin(2.0 * PI * freq * t))
			var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.7  # +3dB sub
			# Cutoff 150Hz = mostly just sub
			return (square * 0.2 + sub * 0.5) * 0.5
		
		Genre.MORODER_DISCO:
			# Research: "Moog ladder bass, clean"
			var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
			saw = tanh(saw * 0.8)  # Warm saturation
			return saw * 0.4
		
		Genre.SYNTHWAVE:
			# Research: "Saw bass: 2-voice, 5 cent detune, filter 600Hz, resonance 0.4"
			# "Attack 0.001s, decay 0.1s, sustain 0.8"
			var detune_ratio = pow(2.0, 5.0 / 1200.0)  # 5 cents
			var saw1 = fmod(t * freq, 1.0) * 2.0 - 1.0
			var saw2 = fmod(t * freq * detune_ratio, 1.0) * 2.0 - 1.0
			var sub = sin(2.0 * PI * freq * 0.5 * t)
			return ((saw1 + saw2) * 0.3 + sub * 0.4) * 0.5
		
		Genre.RAVE:
			# Research: "HOOVER: 3-voice, EXTREME DETUNE 40 cents (!)"
			# "PWM, filter 800Hz, resonance 0.5, LFO 3Hz, distortion 0.3"
			var detune_cents = 40.0  # EXTREME detune from research
			var hoover = 0.0
			for i in range(3):
				var d = (float(i) - 1.0) * detune_cents / 1200.0
				var saw = fmod(t * freq * pow(2.0, d), 1.0) * 2.0 - 1.0
				hoover += saw
			hoover /= 3.0
			# Filter LFO 3Hz
			var lfo = sin(2.0 * PI * 3.0 * t) * 0.3
			hoover *= (0.7 + lfo * 0.3)
			hoover = tanh(hoover * 1.3)  # distortion 0.3
			return hoover * 0.4
		
		Genre.FRENCH_TOUCH:
			# Research: "Filter disco bass: cutoff 400Hz, resonance 0.6"
			# "LFO 0.25Hz, depth 0.5, distortion 0.2"
			var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
			var lfo = sin(2.0 * PI * 0.25 * t) * 0.5  # 0.25Hz, depth 0.5
			saw *= filter_env * (0.5 + lfo * 0.5)  # Filter envelope
			saw = tanh(saw * 1.2)  # distortion 0.2
			return saw * 0.4
		
		Genre.GYPSY_WOMAN_HOUSE:
			# Research: "House bounce bass: sawtooth, filter 800Hz, resonance 0.4"
			var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
			var cutoff_sim = filter_env * 0.5 + 0.3
			saw *= cutoff_sim
			saw = tanh(saw * 1.3)
			return saw * 0.35
		
		Genre.BOARDS_OF_CANADA:
			# Research: "Warm sub bass: filter 400Hz, resonance 0.25, drift 4%"
			var drift = sin(2.0 * PI * 0.1 * t) * 0.04  # 4% drift
			var bass = sin(2.0 * PI * freq * (1.0 + drift) * t)
			bass += sin(2.0 * PI * freq * 2.0 * t) * 0.25
			bass = tanh(bass * 1.1)  # Light distortion 0.1
			return bass * 0.4
		
		Genre.BURIAL:
			# Research: "UK garage sub: cutoff 120Hz, MONO, +6dB sub level"
			# "Attack 0.01s, decay 0.4s, sustain 0.5"
			var sub = sin(2.0 * PI * freq * t)
			sub += sin(2.0 * PI * freq * 2.0 * t) * 0.2
			sub = tanh(sub * 1.4)  # "Distorted and heavy, yet warm"
			return sub * 0.6  # +6dB
		
		Genre.KRAFTWERK:
			# Research: "Minimoog: dual detuned saws, 600Hz ladder filter"
			# "Resonance 0.35, 2 cent drift for warmth"
			var drift_cents = 2.0  # Only 2 cents - MINIMAL
			var drift_ratio = pow(2.0, drift_cents / 1200.0)
			var saw1 = fmod(t * freq, 1.0) * 2.0 - 1.0
			var saw2 = fmod(t * freq * drift_ratio, 1.0) * 2.0 - 1.0
			var bass = (saw1 + saw2) * 0.5
			bass = tanh(bass * 0.9)  # Slight warmth only
			return bass * 0.35
		
		Genre.SUPERSAW_TRANCE:
			# Research: "Trance sub bass: pure sub, cutoff 120Hz, +6dB sub level"
			return sin(2.0 * PI * freq * t) * 0.6  # +6dB pure sub
		
		Genre.REESE_JUNGLE:
			# Research: "REESE: 2-voice, 35 cent detune (!), filter 600Hz"
			# "LFO 0.25Hz depth 0.3, sub +3dB, distortion 0.2"
			var detune_cents = 35.0  # Heavy detune from research
			var detune_ratio = pow(2.0, detune_cents / 1200.0)
			var saw1 = fmod(t * freq * detune_ratio, 1.0) * 2.0 - 1.0
			var saw2 = fmod(t * freq / detune_ratio, 1.0) * 2.0 - 1.0
			var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.7  # +3dB sub
			var lfo = sin(2.0 * PI * 0.25 * t) * 0.3  # 0.25Hz, depth 0.3
			var reese = (saw1 + saw2) * 0.4 * (1.0 + lfo * 0.3) + sub * 0.5
			reese = tanh(reese * 1.2)  # distortion 0.2
			return reese * 0.45
		
		Genre.LOFI_HOUSE:
			# Research: "Juno DCO: saw+square, PWM, filter 500Hz, resonance 0.5"
			# "Attack 0.001s, decay 0.15s, sustain 0.3, drift 3 cents"
			var drift_cents = 3.0
			var drift = sin(2.0 * PI * 0.08 * t) * drift_cents / 1200.0
			var saw = fmod(t * freq * (1.0 + drift), 1.0) * 2.0 - 1.0
			var pw = 0.5 + sin(2.0 * PI * 0.5 * t) * 0.2  # PWM
			var pulse = 1.0 if fmod(t * freq, 1.0) < pw else -1.0
			var bass = saw * 0.5 + pulse * 0.3
			bass *= filter_env * 0.6 + 0.3  # Filter envelope
			return tanh(bass * 1.1) * 0.4  # Light saturation
		
		Genre.AMBIENT_TECHNO:
			# Research: "Soft sub"
			return sin(2.0 * PI * freq * t) * 0.35
		
		Genre.BLADE_RUNNER:
			# Research: "Bass pulse with slow LFO"
			var pulse = sin(2.0 * PI * 0.5 * t)  # Slow pulse
			var bass = sin(2.0 * PI * freq * 0.5 * t)
			bass *= 0.5 + pulse * 0.3
			return bass * 0.3
		
		_:
			return sin(2.0 * PI * freq * t) * 0.4
	
	return 0.0


# =============================================================================
# PAD SYNTHESIS - EXACT PARAMETERS FROM RESEARCH
# =============================================================================

static func generate_pad(genre: Genre, t: float, chord_freqs: Array, progress: float) -> float:
	var pad = 0.0
	
	match genre:
		Genre.AMBIENT_WORKS:
			# Research: "Warm Pad: 5 voices, 8 cent detune, filter 1500Hz"
			# "Attack 1.5s, release 2.0s, chorus 0.4, reverb 0.5, stereo 1.2x"
			var detune_cents = 8.0
			for freq in chord_freqs:
				for i in range(5):  # 5 voices
					var d = (float(i) - 2.0) * detune_cents / 1200.0
					var lfo = sin(2.0 * PI * 0.1 * t + freq * 0.01) * 0.003
					pad += sin(2.0 * PI * freq * pow(2.0, d) * (1.0 + lfo) * t)
			pad /= chord_freqs.size() * 5.0
			pad = tanh(pad * 1.2)  # Tape saturation
		
		Genre.DETROIT_TECHNO:
			# Research: "Digital Pad: ZERO detune, ZERO drift, filter 3500Hz"
			# "Attack 0.5s, sustain 0.7"
			for freq in chord_freqs:
				pad += sin(2.0 * PI * freq * t)  # NO detune
			pad /= chord_freqs.size()
			# Clean, no processing
		
		Genre.MORODER_DISCO:
			# Research: "String machine pad: 6-8 voices, 6 cent detune, chorus 0.5"
			var detune_cents = 6.0
			for freq in chord_freqs:
				var chorus = sin(2.0 * PI * 0.3 * t) * 0.003
				pad += sin(2.0 * PI * freq * (1.0 + chorus) * t)
				pad += sin(2.0 * PI * freq * (1.0 - chorus) * t) * 0.8
			pad /= chord_freqs.size() * 1.8
		
		Genre.SYNTHWAVE:
			# Research: "Supersaw Lead: 7 voices, 15 cent detune, filter 4500Hz"
			# "Vibrato 5.5Hz at 0.02 depth, stereo 1.4x"
			var detune_cents = 15.0
			var detunes = [-0.5, -0.33, -0.17, 0.0, 0.17, 0.33, 0.5]  # 7 voices
			for freq in chord_freqs:
				var vibrato = sin(2.0 * PI * 5.5 * t) * 0.02
				for d in detunes:
					var det = d * detune_cents / 1200.0
					var saw = fmod(t * freq * pow(2.0, det) * (1.0 + vibrato), 1.0) * 2.0 - 1.0
					pad += saw
			pad /= chord_freqs.size() * detunes.size()
			pad *= 0.8
		
		Genre.RAVE:
			# Research: "Mentasm stab: 4 voices, 25 cent detune"
			var detune_cents = 25.0
			for freq in chord_freqs:
				for i in range(4):
					var d = (float(i) - 1.5) * detune_cents / 1200.0
					var saw = fmod(t * freq * 2.0 * pow(2.0, d), 1.0) * 2.0 - 1.0
					pad += saw
			pad /= chord_freqs.size() * 4.0
			pad = tanh(pad * 1.5)  # Distortion
		
		Genre.FRENCH_TOUCH:
			# Research: "Vocoder Pad: 4 voices, filter 2000Hz, sustain 0.8"
			for freq in chord_freqs:
				pad += sin(2.0 * PI * freq * t) * 0.5
				pad += sin(2.0 * PI * freq * 2.0 * t) * 0.3
				pad += sin(2.0 * PI * freq * 3.0 * t) * 0.2
			pad /= chord_freqs.size()
		
		Genre.GYPSY_WOMAN_HOUSE:
			# Research: "Warm strings pad"
			for freq in chord_freqs:
				pad += sin(2.0 * PI * freq * t)
				pad += sin(2.0 * PI * freq * 1.003 * t) * 0.6
			pad /= chord_freqs.size() * 1.6
		
		Genre.BOARDS_OF_CANADA:
			# Research: "Warbly Pad: 4 voices, 15 cent detune, 12% drift"
			# "Filter 800Hz, LFO 0.15Hz at 8% depth, saturation 0.2, high shelf -4dB"
			var detune_cents = 15.0
			var global_drift = sin(2.0 * PI * 0.15 * t) * 0.08  # 0.15Hz, 8% depth
			for freq in chord_freqs:
				var drifted = freq * (1.0 + global_drift)
				for i in range(4):  # 4 voices
					var d = (float(i) - 1.5) * detune_cents / 1200.0
					pad += sin(2.0 * PI * drifted * pow(2.0, d) * t)
			pad /= chord_freqs.size() * 4.0
			pad = tanh(pad * 1.2)  # saturation 0.2
			pad = floor(pad * 256.0) / 256.0  # 10-bit simulation
		
		Genre.BURIAL:
			# Research: "Atmosphere Pad: 3 voices, 8 cent detune, filter 1500Hz"
			# "Attack 1.5s, release 3.0s, reverb 0.7 mix / 6s decay, high shelf -3dB"
			var detune_cents = 8.0
			for freq in chord_freqs:
				pad += sin(2.0 * PI * freq * 0.5 * t) * 0.6  # Octave down
				for i in range(3):
					var d = (float(i) - 1.0) * detune_cents / 1200.0
					pad += sin(2.0 * PI * freq * pow(2.0, d) * t) * 0.4
			pad /= chord_freqs.size() * 2.5
			# "Phaser like cobwebs"
			pad *= sin(2.0 * PI * 0.3 * t) * 0.15 + 0.85
		
		Genre.KRAFTWERK:
			# Research: "Vocoder Pad: 6 voices, 16 bands, filter 3000Hz"
			# "Attack 0.05s, sustain 0.8, subtle chorus for width"
			for freq in chord_freqs:
				pad += sin(2.0 * PI * freq * t) * 0.5
				pad += sin(2.0 * PI * freq * 2.0 * t) * 0.3
				pad += sin(2.0 * PI * freq * 3.0 * t) * 0.2
				pad += sin(2.0 * PI * freq * 4.0 * t) * 0.1
			pad /= chord_freqs.size()
			# Subtle chorus
			pad += sin(2.0 * PI * chord_freqs[0] * 1.003 * t) * 0.15
		
		Genre.SUPERSAW_TRANCE:
			# Research: "Supersaw Pad: 8 voices, 25 cent detune, filter 6000Hz"
			# "Attack 0.3s, sustain 0.9, release 2.0s, reverb 0.5/4s, stereo 1.5x"
			var detune_cents = 25.0
			var detunes = [-0.5, -0.35, -0.2, -0.1, 0.1, 0.2, 0.35, 0.5]  # 8 voices
			for freq in chord_freqs:
				for d in detunes:
					var det = d * detune_cents / 1200.0
					var saw = fmod(t * freq * pow(2.0, det), 1.0) * 2.0 - 1.0
					pad += saw
			pad /= chord_freqs.size() * detunes.size()
		
		Genre.REESE_JUNGLE:
			# Research: "Ambient texture pad: filter 2000Hz, attack 1.0s"
			# "Reverb 0.7 mix / 5s decay, stereo 1.3x"
			for freq in chord_freqs:
				pad += sin(2.0 * PI * freq * t)
			pad /= chord_freqs.size()
		
		Genre.LOFI_HOUSE:
			# Research: "Juno Chorused Pad: 4 voices, 5 cent detune, filter 1800Hz"
			# "Chorus 0.5 depth / 0.8 rate, drift 2 cents"
			var detune_cents = 5.0
			var drift = sin(2.0 * PI * 0.08 * t) * 2.0 / 1200.0  # 2 cent drift
			for freq in chord_freqs:
				# Juno BBD chorus simulation
				var chorus = sin(2.0 * PI * 0.8 * t) * 0.005  # 0.8 rate
				pad += sin(2.0 * PI * freq * (1.0 + chorus + drift) * t)
				pad += sin(2.0 * PI * freq * (1.0 - chorus + drift) * t) * 0.7
			pad /= chord_freqs.size() * 1.7
		
		Genre.AMBIENT_TECHNO:
			# Research: "Ambient Pad: 4 voices at different octaves, 5s attack"
			# "LFO 0.05Hz depth 0.2"
			for freq in chord_freqs:
				var sync_mod = sin(2.0 * PI * 0.05 * t) * 0.05
				pad += sin(2.0 * PI * freq * 4.0 * t) * 0.15  # +2 oct
				pad += sin(2.0 * PI * freq * t) * 0.3
				pad += sin(2.0 * PI * freq * 2.0 * t) * 0.25  # +1 oct
				pad += sin(2.0 * PI * freq * 0.5 * t) * 0.2   # -1 oct
			pad /= chord_freqs.size() * 0.9
		
		Genre.BLADE_RUNNER:
			# Research: "CS-80 brass/strings with vibrato"
			for freq in chord_freqs:
				var vibrato = sin(2.0 * PI * 5.0 * t) * 0.01
				pad += sin(2.0 * PI * freq * (1.0 + vibrato) * t)
				pad += sin(2.0 * PI * freq * 1.002 * t) * 0.7
				pad += sin(2.0 * PI * freq * 0.998 * t) * 0.7
			pad /= chord_freqs.size() * 2.4
		
		_:
			for freq in chord_freqs:
				pad += sin(2.0 * PI * freq * t)
			pad /= chord_freqs.size()
	
	# Apply genre-specific envelope
	var env = 1.0
	match genre:
		Genre.BOARDS_OF_CANADA:
			# Research: "Attack 0.8s, release 2.0s"
			if progress < 0.15: env = progress / 0.15
			elif progress > 0.8: env = (1.0 - progress) / 0.2
		Genre.BURIAL:
			# Research: "Attack 1.5s, release 3.0s" (slow)
			if progress < 0.25: env = progress / 0.25
			elif progress > 0.7: env = (1.0 - progress) / 0.3
		Genre.SUPERSAW_TRANCE:
			# Research: "Attack 0.3s, release 2.0s"
			if progress < 0.15: env = progress / 0.15
			elif progress > 0.75: env = (1.0 - progress) / 0.25
		Genre.AMBIENT_TECHNO:
			# Research: "5s attack" (VERY slow)
			if progress < 0.4: env = progress / 0.4
			elif progress > 0.9: env = (1.0 - progress) / 0.1
		Genre.DETROIT_TECHNO:
			# Research: "Attack 0.5s"
			if progress < 0.2: env = progress / 0.2
			elif progress > 0.85: env = (1.0 - progress) / 0.15
		Genre.AMBIENT_WORKS:
			# Research: "Attack 1.5s"
			if progress < 0.2: env = progress / 0.2
			elif progress > 0.85: env = (1.0 - progress) / 0.15
		_:
			if progress < 0.1: env = progress / 0.1
			elif progress > 0.9: env = (1.0 - progress) / 0.1
	
	return pad * env * 0.25


# =============================================================================
# TEXTURE/NOISE GENERATORS
# =============================================================================

static func generate_texture(genre: Genre, t: float) -> float:
	match genre:
		Genre.AMBIENT_WORKS:
			# Research: "Lo-fi textures, cassette tape"
			return (randf() - 0.5) * 0.015
		
		Genre.BOARDS_OF_CANADA:
			# Research: "Texture: 10-bit, distortion 0.25"
			var noise = (randf() - 0.5) * 0.012
			# VHS crackle
			if randf() < 0.002:
				noise += (randf() - 0.5) * 0.08
			return noise
		
		Genre.BURIAL:
			# Research: "Vinyl crackle: pink noise -15dB, always present"
			# "Density 0.004 for pops"
			var crackle = (randf() - 0.5) * 0.018  # -15dB ≈ 0.018 level
			if randf() < 0.004:
				crackle += (randf() - 0.5) * 0.12
			if randf() < 0.001:
				crackle += (randf() - 0.5) * 0.25
			# Rain sounds
			var rain = (randf() - 0.5) * 0.02
			return crackle + rain
		
		Genre.LOFI_HOUSE:
			# Research: "Dusty, tape-saturated"
			var dust = (randf() - 0.5) * 0.008
			if randf() < 0.003:
				dust += (randf() - 0.5) * 0.05
			return dust
		
		Genre.KRAFTWERK:
			# Research: "Clean - zero distortion"
			return 0.0
		
		Genre.DETROIT_TECHNO:
			# Research: "Clean, cold"
			return 0.0
		
		_:
			return 0.0


# =============================================================================
# SIDECHAIN ENVELOPE
# =============================================================================

static func get_sidechain_envelope(genre: Genre, beat_position: float) -> float:
	# beat_position: 0.0 = on beat, 1.0 = next beat
	match genre:
		Genre.FRENCH_TOUCH:
			# Research: "Sidechain compression - pumping effect"
			return 1.0 - exp(-beat_position * 8.0) * 0.6
		
		Genre.SUPERSAW_TRANCE:
			# Research: "Heavy sidechain compression"
			return 1.0 - exp(-beat_position * 10.0) * 0.5
		
		Genre.GYPSY_WOMAN_HOUSE:
			# Research: "Sidechain compression"
			return 1.0 - exp(-beat_position * 8.0) * 0.4
		
		_:
			return 1.0  # No sidechain


# =============================================================================
# HUMANIZATION - FROM RESEARCH
# =============================================================================

static func get_timing_humanize_ms(genre: Genre) -> float:
	# Returns max timing deviation in milliseconds
	match genre:
		Genre.BURIAL:
			# Research: "NOT quantized, minute hesitations, fishbone look"
			return 15.0
		Genre.BOARDS_OF_CANADA:
			# Research: "Hip-hop influenced, not quantized"
			return 10.0
		Genre.AMBIENT_WORKS:
			# Research: "Shuffled, humanized timing"
			return 8.0
		Genre.LOFI_HOUSE:
			# Research: "Loose, humanized feel"
			return 6.0
		Genre.KRAFTWERK:
			# Research: "Mechanical precision, quantized, clinical"
			return 0.0  # ZERO humanization
		Genre.DETROIT_TECHNO:
			# Research: "Tight, quantized"
			return 0.0  # Machine precision
		_:
			return 2.0


# =============================================================================
# GENRE PARAMETERS - FROM RESEARCH
# =============================================================================

static func get_typical_bpm(genre: Genre) -> float:
	match genre:
		Genre.AMBIENT_WORKS: return 92.0   # Research: "90-120 BPM"
		Genre.DETROIT_TECHNO: return 130.0 # Research: "120-130 BPM typical"
		Genre.MORODER_DISCO: return 125.0
		Genre.SYNTHWAVE: return 108.0      # Research: "80-118 BPM"
		Genre.RAVE: return 145.0           # Research: "140-160 BPM"
		Genre.FRENCH_TOUCH: return 120.0   # Research: "110-130 BPM, 120 classic"
		Genre.GYPSY_WOMAN_HOUSE: return 120.0
		Genre.BOARDS_OF_CANADA: return 95.0  # Research: "80-110 BPM"
		Genre.BURIAL: return 130.0         # Research: "130 BPM typical"
		Genre.KRAFTWERK: return 110.0      # Research: "110 BPM motorik"
		Genre.SUPERSAW_TRANCE: return 138.0 # Research: "138-145 BPM"
		Genre.REESE_JUNGLE: return 170.0   # Research: "160-180 BPM"
		Genre.PROG_SYNTH_70S: return 110.0
		Genre.LOFI_HOUSE: return 118.0     # Research: "115-125 BPM"
		Genre.AMBIENT_TECHNO: return 110.0
		Genre.BLADE_RUNNER: return 70.0
		_: return 120.0


static func get_crossfade_duration(genre: Genre) -> float:
	# Returns crossfade duration in seconds
	match genre:
		Genre.BURIAL: return 5.0        # Long, atmospheric
		Genre.BOARDS_OF_CANADA: return 4.0
		Genre.AMBIENT_WORKS: return 4.0
		Genre.AMBIENT_TECHNO: return 3.0
		Genre.BLADE_RUNNER: return 2.5
		Genre.RAVE: return 1.5          # Quick cuts
		Genre.DETROIT_TECHNO: return 2.0
		_: return 2.0


# =============================================================================
# SPECIAL GENRE FEATURES
# =============================================================================

static func get_duck_lead(genre: Genre, t: float, freq: float) -> float:
	# French Touch "quack" sound
	if genre != Genre.FRENCH_TOUCH:
		return 0.0
	
	# Research: "BANDPASS filter, 1500Hz, resonance 0.8"
	# "Attack 0.001s, decay 0.05s, sustain 0.2"
	var beat_phase = fmod(t * 2.0, 1.0)  # 2 per second
	var env = exp(-beat_phase * 20.0)  # Fast decay 0.05s
	
	var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
	# Bandpass simulation with resonance 0.8
	var resonance = sin(2.0 * PI * 1500.0 * t) * 0.8 * env
	var duck = (saw * 0.6 + resonance * 0.4) * env
	
	return duck * 0.2


static func get_sequencer_line(genre: Genre, t: float, freq: float, bpm: float) -> float:
	# Kraftwerk-style precise sequencer
	if genre != Genre.KRAFTWERK:
		return 0.0
	
	# Research: "ZERO modulation, stable pitch, filter 2000Hz"
	var step_duration = 60.0 / bpm / 4.0  # 16th notes
	var step = int(t / step_duration) % 16
	var step_phase = fmod(t, step_duration) / step_duration
	
	# Simple pattern
	var pattern = [0, 12, 7, 12, 0, 12, 7, 12, 0, 12, 7, 12, 5, 12, 7, 12]
	var note_offset = pattern[step]
	var note_freq = freq * pow(2.0, note_offset / 12.0)
	
	# Square wave - no modulation!
	var square = sign(sin(2.0 * PI * note_freq * t))
	var env = exp(-step_phase * 15.0)  # decay 0.08s
	
	return square * env * 0.15
