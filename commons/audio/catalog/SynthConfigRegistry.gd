# SynthConfigRegistry.gd
# Registry of actual synth parameters used by each generator
# Enables reverse-lookup: "what is this sound made of?"

extends RefCounted
class_name SynthConfigRegistry

# song_id → { layer_name → { param_name → value } }
static var _configs: Dictionary = {}

static func _static_init():
	_register_all_configs()


static func _register_all_configs():
	"""Register known synth configurations from AudioSynthesizer generators"""
	
	# === AMBIENT WORKS (Aphex Twin style) ===
	_configs["ambient_works"] = {
		"Keys": {
			"type": "FM piano",
			"filter.cutoff": 2000,
			"filter.resonance": 0.3,
			"env.attack": 0.01,
			"env.decay": 0.3,
			"env.sustain": 0.4,
			"env.release": 0.5,
			"fx.reverb.mix": 0.3,
			"fx.distortion": 0.15,  # tape saturation
			"osc.drift": 0.05
		},
		"Pad": {
			"type": "subtractive",
			"osc.voices": 5,
			"osc.detune": 8,
			"filter.cutoff": 1500,
			"env.attack": 1.5,
			"env.decay": 0.5,
			"env.sustain": 0.7,
			"env.release": 2.0,
			"fx.chorus.depth": 0.4,
			"fx.reverb.mix": 0.5,
			"mix.stereo_width": 1.2
		},
		"Bass": {
			"type": "303 acid",
			"filter.cutoff": 800,
			"filter.resonance": 0.8,
			"filter.type": "ladder",
			"env.attack": 0.001,
			"env.decay": 0.15,
			"env.sustain": 0.3,
			"mod.lfo.rate": 2.0,
			"mod.lfo.depth": 0.4,
			"mod.lfo.target": "filter",
			"fx.distortion": 0.25
		},
		"Drums": {
			"type": "breakbeat",
			"style": "lo-fi",
			"fx.bitcrush.depth": 12,
			"fx.distortion": 0.1,
			"mix.high_shelf_db": -3
		}
	}
	
	# === BLADE RUNNER (Vangelis style) ===
	_configs["blade_runner"] = {
		"Vangelis Keys": {
			"type": "CS-80 brass",
			"filter.cutoff": 2500,
			"filter.resonance": 0.7,
			"env.attack": 0.02,
			"env.decay": 0.4,
			"env.sustain": 0.6,
			"env.release": 0.8,
			"mod.lfo.rate": 5.0,
			"mod.lfo.depth": 0.01,
			"mod.lfo.target": "pitch",
			"osc.voices": 2,
			"osc.detune": 5,
			"fx.reverb.mix": 0.4,
			"fx.reverb.decay": 3.0
		},
		"String Pad": {
			"type": "string ensemble",
			"osc.voices": 8,
			"osc.detune": 3,
			"filter.cutoff": 3000,
			"env.attack": 0.3,
			"env.sustain": 0.8,
			"env.release": 1.5,
			"fx.chorus.depth": 0.3,
			"mix.stereo_width": 1.3
		},
		"Bass Pulse": {
			"type": "sub pulse",
			"filter.cutoff": 200,
			"env.attack": 0.1,
			"env.decay": 0.5,
			"env.sustain": 0.6,
			"mod.lfo.rate": 0.5,
			"mod.lfo.depth": 0.3,
			"mod.lfo.target": "amplitude",
			"sub.level_db": 0
		},
		"Lead": {
			"type": "solo synth",
			"filter.cutoff": 4000,
			"filter.resonance": 0.4,
			"env.attack": 0.05,
			"env.sustain": 0.9,
			"mod.lfo.rate": 5.0,
			"mod.lfo.depth": 0.015,
			"mod.lfo.target": "pitch",
			"fx.delay.mix": 0.3,
			"fx.delay.time": 0.375,
			"fx.reverb.mix": 0.5
		}
	}
	
	# === DETROIT TECHNO ===
	_configs["detroit_techno"] = {
		"Pad": {
			"type": "digital",
			"osc.voices": 4,
			"osc.detune": 0,
			"osc.drift": 0,
			"filter.cutoff": 3500,
			"env.attack": 0.5,
			"env.sustain": 0.7,
			"fx.reverb.mix": 0.4,
			"mix.stereo_width": 1.1
		},
		"Bass": {
			"type": "808 sub",
			"filter.cutoff": 150,
			"env.attack": 0.001,
			"env.decay": 0.3,
			"env.sustain": 0.5,
			"sub.level_db": 3
		},
		"Stabs": {
			"type": "chord stab",
			"filter.cutoff": 2000,
			"filter.resonance": 0.5,
			"env.attack": 0.001,
			"env.decay": 0.08,
			"env.sustain": 0,
			"fx.reverb.mix": 0.2
		},
		"Drums": {
			"type": "909",
			"style": "machine funk",
			"env.attack": 0.001,
			"mix.high_shelf_db": 2
		}
	}
	
	# === SYNTHWAVE ===
	_configs["synthwave"] = {
		"Arpeggio": {
			"type": "Juno-60",
			"osc.voices": 4,
			"osc.detune": 12,
			"filter.cutoff": 3000,
			"filter.resonance": 0.3,
			"env.attack": 0.001,
			"env.decay": 0.2,
			"env.sustain": 0.5,
			"fx.chorus.depth": 0.4,
			"fx.delay.mix": 0.25,
			"fx.delay.time": 0.375
		},
		"Bass": {
			"type": "saw bass",
			"filter.cutoff": 600,
			"filter.resonance": 0.4,
			"env.attack": 0.001,
			"env.decay": 0.1,
			"env.sustain": 0.8,
			"osc.voices": 2,
			"osc.detune": 5
		},
		"Lead": {
			"type": "supersaw lead",
			"osc.voices": 7,
			"osc.detune": 15,
			"filter.cutoff": 4500,
			"env.attack": 0.02,
			"env.sustain": 0.9,
			"mod.lfo.rate": 5.5,
			"mod.lfo.depth": 0.02,
			"mod.lfo.target": "pitch",
			"fx.delay.mix": 0.35,
			"fx.reverb.mix": 0.4,
			"mix.stereo_width": 1.4
		},
		"Drums": {
			"type": "LinnDrum",
			"fx.reverb.mix": 0.6,
			"fx.reverb.decay": 1.5,
			"style": "gated reverb"
		}
	}
	
	# === FRENCH TOUCH ===
	_configs["french_touch"] = {
		"Filter Bass": {
			"type": "filter disco",
			"filter.cutoff": 400,
			"filter.resonance": 0.6,
			"filter.type": "lowpass",
			"env.attack": 0.001,
			"env.decay": 0.15,
			"env.sustain": 0.7,
			"mod.lfo.rate": 0.25,
			"mod.lfo.depth": 0.5,
			"mod.lfo.target": "filter",
			"fx.distortion": 0.2
		},
		"Duck Lead": {
			"type": "quack synth",
			"filter.cutoff": 1500,
			"filter.resonance": 0.8,
			"filter.type": "bandpass",
			"env.attack": 0.001,
			"env.decay": 0.05,
			"env.sustain": 0.2
		},
		"Chiff": {
			"type": "wavetable",
			"env.attack": 0.001,
			"env.decay": 0.08,
			"env.sustain": 0,
			"filter.cutoff": 5000
		},
		"Vocoder Pad": {
			"type": "vocoder",
			"osc.voices": 4,
			"filter.cutoff": 2000,
			"env.attack": 0.1,
			"env.sustain": 0.8,
			"mix.stereo_width": 1.0
		},
		"Drums": {
			"type": "disco kit",
			"tempo": 120,
			"pattern": "four-on-floor"
		}
	}
	
	# === SUPERSAW TRANCE ===
	_configs["supersaw_trance"] = {
		"Supersaw Pad": {
			"type": "JP-8000 supersaw",
			"osc.voices": 8,
			"osc.detune": 25,
			"filter.cutoff": 6000,
			"filter.resonance": 0.2,
			"env.attack": 0.3,
			"env.sustain": 0.9,
			"env.release": 2.0,
			"fx.reverb.mix": 0.5,
			"fx.reverb.decay": 4.0,
			"mix.stereo_width": 1.5
		},
		"Supersaw Lead": {
			"type": "JP-8000 supersaw",
			"osc.voices": 7,
			"osc.detune": 18,
			"filter.cutoff": 8000,
			"env.attack": 0.01,
			"env.sustain": 0.95,
			"fx.delay.mix": 0.3,
			"fx.reverb.mix": 0.4
		},
		"Trance Bass": {
			"type": "sub bass",
			"filter.cutoff": 120,
			"env.attack": 0.001,
			"env.decay": 0.2,
			"env.sustain": 0.6,
			"sub.level_db": 6
		},
		"Arp": {
			"type": "trance arp",
			"osc.voices": 3,
			"osc.detune": 8,
			"filter.cutoff": 4000,
			"env.attack": 0.001,
			"env.decay": 0.1,
			"env.sustain": 0.4,
			"fx.delay.mix": 0.4,
			"fx.delay.time": 0.1875
		},
		"Drums": {
			"type": "trance kit",
			"tempo": 138,
			"pattern": "driving"
		}
	}
	
	# === LO-FI HOUSE ===
	_configs["lofi_house"] = {
		"Juno Bass": {
			"type": "Juno-106 DCO",
			"waveform": "saw+square",
			"filter.cutoff": 500,
			"filter.resonance": 0.5,
			"env.attack": 0.001,
			"env.decay": 0.15,
			"env.sustain": 0.3,
			"osc.drift": 0.03,
			"fx.distortion": 0.1
		},
		"Juno Pad": {
			"type": "Juno-106 DCO",
			"osc.voices": 4,
			"osc.detune": 5,
			"filter.cutoff": 1800,
			"env.attack": 0.2,
			"env.sustain": 0.7,
			"fx.chorus.depth": 0.5,
			"fx.chorus.rate": 0.8,
			"osc.drift": 0.02
		},
		"Stab": {
			"type": "filtered stab",
			"filter.cutoff": 1200,
			"env.attack": 0.001,
			"env.decay": 0.08,
			"env.sustain": 0
		},
		"Drums": {
			"type": "lo-fi kit",
			"tempo": 118,
			"fx.bitcrush.depth": 12,
			"fx.distortion": 0.15,
			"style": "dusty"
		}
	}
	
	# === REESE JUNGLE ===
	_configs["reese_jungle"] = {
		"Reese Bass": {
			"type": "reese",
			"osc.voices": 2,
			"osc.detune": 35,
			"filter.cutoff": 600,
			"filter.resonance": 0.4,
			"mod.lfo.rate": 0.25,
			"mod.lfo.depth": 0.3,
			"mod.lfo.target": "filter",
			"sub.level_db": 3,
			"fx.distortion": 0.2
		},
		"Amen Break": {
			"type": "breakbeat",
			"tempo": 170,
			"style": "chopped",
			"fx.distortion": 0.1
		},
		"Stab": {
			"type": "bitcrushed chord",
			"fx.bitcrush.depth": 10,
			"filter.cutoff": 3000,
			"env.attack": 0.001,
			"env.decay": 0.1,
			"env.sustain": 0
		},
		"Pad": {
			"type": "ambient texture",
			"filter.cutoff": 2000,
			"env.attack": 1.0,
			"env.sustain": 0.6,
			"fx.reverb.mix": 0.7,
			"fx.reverb.decay": 5.0,
			"mix.stereo_width": 1.3
		}
	}
	
	# === AMBIENT TECHNO ===
	_configs["ambient_techno"] = {
		"Ambient Pad": {
			"type": "evolving pad",
			"osc.voices": 4,
			"osc.detune": 6,
			"filter.cutoff": 1500,
			"env.attack": 5.0,
			"env.decay": 2.0,
			"env.sustain": 0.7,
			"env.release": 8.0,
			"mod.lfo.rate": 0.05,
			"mod.lfo.depth": 0.2,
			"fx.reverb.mix": 0.6,
			"fx.reverb.decay": 8.0,
			"mix.stereo_width": 1.4
		},
		"Texture": {
			"type": "granular texture",
			"mod.lfo.rate": 0.07,
			"fx.reverb.mix": 0.5,
			"mix.volume_db": -6
		},
		"Minimal Kick": {
			"type": "minimal",
			"env.attack": 0.001,
			"env.decay": 0.15,
			"filter.cutoff": 100,
			"mix.volume_db": -3
		},
		"Arp": {
			"type": "slow arp",
			"filter.cutoff": 2500,
			"env.attack": 0.01,
			"env.decay": 3.0,
			"env.sustain": 0.2,
			"fx.delay.mix": 0.5,
			"fx.delay.time": 0.5,
			"fx.reverb.mix": 0.6
		}
	}
	
	# === PROG SYNTH 70s ===
	_configs["prog_synth_70s"] = {
		"Bass": {
			"type": "Minimoog",
			"filter.cutoff": 800,
			"filter.resonance": 0.4,
			"filter.type": "ladder",
			"env.attack": 0.01,
			"env.decay": 0.2,
			"env.sustain": 0.7,
			"osc.drift": 0.08,
			"fx.distortion": 0.15
		},
		"Pad": {
			"type": "string machine",
			"osc.voices": 6,
			"osc.detune": 10,
			"filter.cutoff": 2000,
			"env.attack": 2.0,
			"env.sustain": 0.8,
			"fx.chorus.depth": 0.3,
			"osc.drift": 0.05
		},
		"Lead": {
			"type": "Minimoog solo",
			"filter.cutoff": 3500,
			"filter.resonance": 0.5,
			"env.attack": 0.02,
			"env.sustain": 0.9,
			"mod.lfo.rate": 5.0,
			"mod.lfo.depth": 0.03,
			"mod.lfo.target": "pitch",
			"osc.drift": 0.06
		},
		"Drums": {
			"type": "acoustic kit",
			"style": "motorik",
			"tempo": 110
		}
	}
	
	# === POP GENERATIVE ===
	_configs["pop_generative"] = {
		"Bass": {
			"type": "synth bass",
			"filter.cutoff": 600,
			"env.attack": 0.001,
			"env.decay": 0.15,
			"env.sustain": 0.6
		},
		"Keys": {
			"type": "electric piano",
			"filter.cutoff": 2500,
			"env.attack": 0.01,
			"env.decay": 0.3,
			"env.sustain": 0.5,
			"fx.chorus.depth": 0.2
		},
		"Pad": {
			"type": "warm pad",
			"osc.voices": 4,
			"osc.detune": 8,
			"filter.cutoff": 1500,
			"env.attack": 0.5,
			"env.sustain": 0.7,
			"fx.reverb.mix": 0.3
		},
		"Lead": {
			"type": "melodic synth",
			"filter.cutoff": 3000,
			"env.attack": 0.02,
			"env.sustain": 0.8,
			"fx.delay.mix": 0.2
		},
		"Drums": {
			"type": "pop kit"
		}
	}
	
	# === MORODER DISCO ===
	_configs["moroder_disco"] = {
		"Sequencer": {
			"type": "Moog sequencer",
			"filter.cutoff": 1200,
			"filter.resonance": 0.6,
			"mod.lfo.rate": 4.0,
			"mod.lfo.depth": 0.4,
			"mod.lfo.target": "filter",
			"env.attack": 0.001,
			"env.decay": 0.1,
			"env.sustain": 0.5,
			"osc.drift": 0.04
		},
		"Bass": {
			"type": "Moog bass",
			"filter.cutoff": 500,
			"filter.resonance": 0.3,
			"filter.type": "ladder",
			"env.attack": 0.001,
			"env.sustain": 0.8
		},
		"Strings": {
			"type": "string machine",
			"osc.voices": 8,
			"osc.detune": 6,
			"filter.cutoff": 3000,
			"env.attack": 0.3,
			"env.sustain": 0.9,
			"fx.chorus.depth": 0.5,
			"mix.stereo_width": 1.2
		},
		"Drums": {
			"type": "disco kit",
			"pattern": "four-on-floor",
			"tempo": 120
		}
	}
	
	# === RAVE ===
	_configs["rave"] = {
		"Bass": {
			"type": "hoover",
			"osc.voices": 3,
			"osc.detune": 40,
			"filter.cutoff": 800,
			"filter.resonance": 0.5,
			"mod.lfo.rate": 3.0,
			"mod.lfo.depth": 0.3,
			"fx.distortion": 0.3
		},
		"Stabs": {
			"type": "Mentasm chord",
			"osc.voices": 4,
			"osc.detune": 25,
			"filter.cutoff": 2500,
			"filter.resonance": 0.4,
			"env.attack": 0.001,
			"env.decay": 0.15,
			"env.sustain": 0.3
		},
		"Drums": {
			"type": "breakbeat",
			"tempo": 140,
			"fx.distortion": 0.15
		}
	}
	
	# === BOARDS OF CANADA (Lo-fi nostalgia, tape-warped) ===
	# Scottish duo - Music Has the Right to Children, Geogaddi
	# Key: detuned oscillators, tape saturation, VHS/childhood aesthetic
	_configs["boards_of_canada"] = {
		"Warbly Pad": {
			"type": "tape-degraded poly",
			"osc.voices": 4,
			"osc.detune": 15,
			"osc.drift": 0.12,  # Heavy pitch instability (tape wow)
			"filter.cutoff": 800,
			"filter.resonance": 0.2,
			"env.attack": 0.8,
			"env.decay": 0.5,
			"env.sustain": 0.6,
			"env.release": 2.0,
			"mod.lfo.rate": 0.15,  # Very slow wobble
			"mod.lfo.depth": 0.08,
			"mod.lfo.target": "pitch",
			"fx.distortion": 0.2,  # Tape saturation
			"fx.chorus.depth": 0.15,
			"fx.reverb.mix": 0.35,
			"mix.high_shelf_db": -4,  # Rolled off highs (old tape)
			"mix.stereo_width": 0.8
		},
		"Melodic Sequence": {
			"type": "detuned mono",
			"osc.drift": 0.08,
			"filter.cutoff": 1200,
			"filter.resonance": 0.3,
			"env.attack": 0.01,
			"env.decay": 0.3,
			"env.sustain": 0.4,
			"env.release": 0.5,
			"fx.distortion": 0.15,
			"fx.delay.mix": 0.35,
			"fx.delay.time": 0.333,  # Dotted eighth
			"fx.delay.feedback": 0.4,
			"mix.high_shelf_db": -6
		},
		"Bass": {
			"type": "warm sub",
			"filter.cutoff": 400,
			"filter.resonance": 0.25,
			"osc.drift": 0.04,
			"env.attack": 0.02,
			"env.decay": 0.25,
			"env.sustain": 0.6,
			"fx.distortion": 0.1,
			"sub.level_db": 0
		},
		"Texture Layer": {
			"type": "granular/tape noise",
			"fx.bitcrush.depth": 10,  # Lo-fi sampling
			"fx.distortion": 0.25,
			"filter.cutoff": 2000,
			"mix.volume_db": -12,
			"fx.reverb.mix": 0.5
		},
		"Drums": {
			"type": "lo-fi breakbeat",
			"tempo": 100,
			"fx.bitcrush.depth": 12,
			"fx.distortion": 0.2,
			"mix.high_shelf_db": -3,
			"style": "hip-hop influenced"
		}
	}
	
	# === BURIAL (Dark UK garage, vinyl atmosphere) ===
	# Will Bevan - Untrue, Kindred
	# Key: vinyl crackle, pitched vocals, 2-step, sub bass, melancholy
	_configs["burial"] = {
		"Sub Bass": {
			"type": "UK garage sub",
			"filter.cutoff": 120,
			"filter.type": "lowpass",
			"env.attack": 0.01,
			"env.decay": 0.4,
			"env.sustain": 0.5,
			"env.release": 0.3,
			"sub.level_db": 6,
			"mix.stereo_width": 0.0  # Mono sub
		},
		"Atmosphere Pad": {
			"type": "dark reverb wash",
			"osc.voices": 3,
			"osc.detune": 8,
			"filter.cutoff": 1500,
			"filter.resonance": 0.15,
			"env.attack": 1.5,
			"env.decay": 1.0,
			"env.sustain": 0.5,
			"env.release": 3.0,
			"fx.reverb.mix": 0.7,
			"fx.reverb.decay": 6.0,
			"fx.reverb.predelay": 0.08,
			"mix.high_shelf_db": -3,
			"mix.stereo_width": 1.3
		},
		"Pitched Vocal": {
			"type": "timestretched R&B sample",
			"filter.cutoff": 2500,
			"filter.resonance": 0.2,
			"env.attack": 0.05,
			"env.sustain": 0.7,
			"fx.reverb.mix": 0.5,
			"fx.delay.mix": 0.3,
			"fx.delay.time": 0.5,
			"fx.bitcrush.depth": 14,  # Slight degradation
			"pitch_shift": -5  # Pitched down (semitones)
		},
		"Crackle Layer": {
			"type": "vinyl noise",
			"noise.level_db": -18,
			"noise.color": "pink",
			"filter.cutoff": 4000,
			"filter.type": "lowpass",
			"mix.volume_db": -15
		},
		"Garage Stab": {
			"type": "organ stab",
			"filter.cutoff": 1800,
			"filter.resonance": 0.3,
			"env.attack": 0.001,
			"env.decay": 0.12,
			"env.sustain": 0.1,
			"env.release": 0.2,
			"fx.reverb.mix": 0.4
		},
		"Drums": {
			"type": "2-step garage",
			"tempo": 130,
			"style": "shuffled, sparse",
			"fx.reverb.mix": 0.25,
			"fx.distortion": 0.05
		}
	}
	
	# === KRAFTWERK (German electronic pioneers) ===
	# Trans-Europe Express, The Man-Machine, Computer World
	# Key: Minimoog, vocoder, precise sequences, clinical/robotic
	_configs["kraftwerk"] = {
		"Minimoog Bass": {
			"type": "Minimoog Model D",
			"filter.cutoff": 600,
			"filter.resonance": 0.35,
			"filter.type": "ladder",
			"env.attack": 0.001,
			"env.decay": 0.2,
			"env.sustain": 0.7,
			"env.release": 0.15,
			"osc.drift": 0.02,  # Slight analog drift
			"fx.distortion": 0.05
		},
		"Sequencer Line": {
			"type": "ARP 2600 sequence",
			"filter.cutoff": 2000,
			"filter.resonance": 0.5,
			"env.attack": 0.001,
			"env.decay": 0.08,
			"env.sustain": 0.3,
			"env.release": 0.1,
			"mod.lfo.rate": 0.0,  # No modulation - precise
			"osc.drift": 0.0  # Stable pitch
		},
		"Vocoder Pad": {
			"type": "Sennheiser VSM201 vocoder",
			"osc.voices": 6,
			"filter.cutoff": 3000,
			"filter.resonance": 0.4,
			"env.attack": 0.05,
			"env.sustain": 0.8,
			"env.release": 0.3,
			"fx.chorus.depth": 0.1,
			"mix.stereo_width": 1.0,
			"vocoder.bands": 16
		},
		"Lead Melody": {
			"type": "Minimoog lead",
			"filter.cutoff": 3500,
			"filter.resonance": 0.4,
			"env.attack": 0.02,
			"env.decay": 0.15,
			"env.sustain": 0.8,
			"env.release": 0.2,
			"mod.lfo.rate": 5.0,  # Subtle vibrato
			"mod.lfo.depth": 0.008,
			"mod.lfo.target": "pitch",
			"osc.drift": 0.015
		},
		"Electric Percussion": {
			"type": "Syndrum / custom electronic",
			"env.attack": 0.001,
			"env.decay": 0.15,
			"env.sustain": 0.0,
			"filter.cutoff": 800,
			"filter.resonance": 0.6,
			"fx.distortion": 0.0,  # Clean
			"pitch_env.depth": 0.8,  # Pitch drop on hit
			"pitch_env.decay": 0.1
		},
		"Drums": {
			"type": "TR-808 / custom",
			"tempo": 110,
			"style": "mechanical, quantized",
			"fx.distortion": 0.0,  # Clean and precise
			"mix.high_shelf_db": 0
		}
	}
	
	# === GYPSY WOMAN HOUSE (Crystal Waters style) ===
	# Classic 90s house - piano stabs, bouncy bass, 909 drums, euphoric
	_configs["gypsy_woman_house"] = {
		"Piano": {
			"type": "house piano stab",
			"filter.cutoff": 4000,
			"filter.resonance": 0.2,
			"env.attack": 0.005,
			"env.decay": 0.3,
			"env.sustain": 0.3,
			"env.release": 0.2,
			"velocity_sensitivity": 0.6,
			"voicing": "close_position"
		},
		"Bass": {
			"type": "house bounce",
			"waveform": "sawtooth",
			"filter.cutoff": 800,
			"filter.resonance": 0.4,
			"filter.type": "lowpass",
			"env.attack": 0.001,
			"env.decay": 0.15,
			"env.sustain": 0.7,
			"pattern": "octave_bounce",
			"slide": 0.03
		},
		"Pad": {
			"type": "warm strings",
			"osc.voices": 4,
			"osc.detune": 12,
			"filter.cutoff": 3000,
			"filter.resonance": 0.1,
			"env.attack": 0.2,
			"env.decay": 0.5,
			"env.sustain": 0.7,
			"env.release": 0.5,
			"mod.lfo.rate": 0.1,
			"mod.lfo.depth": 0.2,
			"mod.lfo.target": "filter",
			"mix.stereo_width": 1.2,
			"mix.volume_db": -6
		},
		"Vocal Chop": {
			"type": "la da dee",
			"filter.cutoff": 3500,
			"filter.resonance": 0.15,
			"env.attack": 0.01,
			"env.sustain": 0.8,
			"fx.reverb.mix": 0.3,
			"formant": "ah",
			"mod.lfo.rate": 5.0,
			"mod.lfo.depth": 0.01,
			"mod.lfo.target": "pitch"
		},
		"Drums": {
			"type": "TR-909",
			"style": "four-on-floor house",
			"tempo": 120,
			"pattern": "classic_house",
			"fx.reverb.mix": 0.15
		}
	}


# === PUBLIC API ===

static func get_config(song_id: String) -> Dictionary:
	"""Get full config for a song"""
	if _configs.is_empty():
		_register_all_configs()
	return _configs.get(song_id, {})


static func get_layer_config(song_id: String, layer_name: String) -> Dictionary:
	"""Get config for a specific layer"""
	var song_config = get_config(song_id)
	
	# Try exact match first
	if song_config.has(layer_name):
		return song_config[layer_name]
	
	# Try case-insensitive match
	for key in song_config.keys():
		if key.to_lower() == layer_name.to_lower():
			return song_config[key]
	
	return {}


static func get_all_layers(song_id: String) -> Array:
	"""Get all layer names for a song"""
	return get_config(song_id).keys()


static func get_registered_songs() -> Array:
	"""Get all registered song IDs"""
	if _configs.is_empty():
		_register_all_configs()
	return _configs.keys()


# === VALIDATION ===

# Known valid parameter names (from word_synthesis_map.json param_spec)
const VALID_PARAMS = [
	"type", "style", "pattern", "tempo", "waveform",  # Metadata
	"filter.cutoff", "filter.resonance", "filter.type",
	"env.attack", "env.decay", "env.sustain", "env.release",
	"osc.voices", "osc.detune", "osc.drift",
	"mix.volume_db", "mix.high_shelf_db", "mix.low_shelf_db", "mix.stereo_width",
	"fx.reverb.mix", "fx.reverb.decay", "fx.reverb.predelay", "fx.reverb.diffusion",
	"fx.delay.mix", "fx.delay.time", "fx.delay.feedback",
	"fx.chorus.depth", "fx.chorus.rate",
	"fx.distortion", "fx.bitcrush.depth",
	"mod.lfo.rate", "mod.lfo.depth", "mod.lfo.target",
	"sub.level_db",
	"noise.level_db", "noise.color",
	"grain.size", "grain.density", "grain.jitter", "grain.spray",
	"vocoder.bands", "pitch_shift", "pitch_env.depth", "pitch_env.decay"
]


static func validate_all_configs() -> Dictionary:
	"""Validate all registered configs, return errors"""
	if _configs.is_empty():
		_register_all_configs()
	
	var errors = {}
	
	for song_id in _configs.keys():
		var song_errors = []
		var song_config = _configs[song_id]
		
		for layer_name in song_config.keys():
			var layer_config = song_config[layer_name]
			
			for param_name in layer_config.keys():
				if param_name not in VALID_PARAMS:
					song_errors.append("%s.%s: unknown param '%s'" % [layer_name, param_name, param_name])
		
		if not song_errors.is_empty():
			errors[song_id] = song_errors
	
	return errors


static func print_validation_report():
	"""Print validation results to console"""
	var errors = validate_all_configs()
	
	if errors.is_empty():
		print("SynthConfigRegistry: All configs valid ✓")
		return
	
	print("SynthConfigRegistry: Validation errors found:")
	for song_id in errors.keys():
		print("  %s:" % song_id)
		for error in errors[song_id]:
			print("    - %s" % error)
