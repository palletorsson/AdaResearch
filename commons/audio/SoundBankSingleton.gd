extends Node

# SoundBankSingleton - Centralized sound management system
# This singleton manages all sound generation, caching, and preset loading
# for the Ada Research VR educational system

# Signals
signal sound_bank_ready
signal preset_loaded(preset_name: String)
signal sound_generated(sound_id: String)
signal generation_progress(current: int, total: int, sound_name: String)

# Sound registry - stores all generated AudioStreamWAV sounds
var sound_registry: Dictionary = {}

# Ambient presets loaded from JSON
var ambient_presets: Dictionary = {}

# Generation state
var generation_complete: bool = false
var is_generating: bool = false
var generation_thread: Thread = null
var generation_mutex: Mutex = null

# Paths
const PRESETS_PATH = "res://commons/audio/ambient_presets.json"

# Audio bus management
var audio_buses_initialized: bool = false
var active_buses: Dictionary = {}

func _ready():
	print("🎵 SoundBankSingleton initializing...")
	generation_mutex = Mutex.new()
	generation_thread = Thread.new()

	# Load ambient presets
	_load_ambient_presets()

	# Pre-generate common sounds (lazy loading by default)
	# Specific sounds are generated on-demand

	print("✅ SoundBankSingleton ready")
	sound_bank_ready.emit()

func _exit_tree():
	# Clean up thread if running
	if generation_thread and generation_thread.is_alive():
		generation_thread.wait_to_finish()

# ===== PRESET LOADING =====

func _load_ambient_presets():
	"""Load ambient preset definitions from JSON"""
	var file = FileAccess.open(PRESETS_PATH, FileAccess.READ)
	if not file:
		print("⚠️ Could not load ambient presets from: ", PRESETS_PATH)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("⚠️ JSON parse error in ambient presets")
		return

	var data = json.data
	if "presets" in data:
		ambient_presets = data["presets"]
		print("✅ Loaded %d ambient presets" % ambient_presets.size())
	else:
		print("⚠️ No 'presets' key found in ambient presets JSON")

func get_preset(preset_name: String) -> Dictionary:
	"""Get an ambient preset by name"""
	if preset_name in ambient_presets:
		return ambient_presets[preset_name]
	else:
		print("⚠️ Preset not found: ", preset_name, " - using 'silent' preset")
		return ambient_presets.get("silent", {})

# ===== SOUND GENERATION =====

func get_sound(sound_id: String) -> AudioStreamWAV:
	"""Get a sound from the registry, generating it if needed"""

	# Check if already cached
	if sound_id in sound_registry:
		return sound_registry[sound_id]

	# Generate the sound
	var sound = _generate_sound(sound_id)
	if sound:
		sound_registry[sound_id] = sound
		sound_generated.emit(sound_id)
		return sound
	else:
		print("⚠️ Failed to generate sound: ", sound_id)
		return null

func _generate_sound(sound_id: String) -> AudioStreamWAV:
	"""Generate a sound based on its ID"""

	# Parse the sound ID (format: "generator.sound_name" or "SoundClass.METHOD")
	var parts = sound_id.split(".")
	if parts.size() != 2:
		print("⚠️ Invalid sound_id format: ", sound_id)
		return null

	var generator = parts[0]
	var sound_name = parts[1]

	# Route to appropriate generator
	match generator:
		"SyntheticSoundGenerator":
			return _generate_synthetic_sound(sound_name)
		"AudioSynthesizer":
			return _generate_synthesizer_sound(sound_name)
		"techno_noir":
			return _generate_techno_noir_sound(sound_name)
		"liturgical":
			return _generate_liturgical_sound(sound_name)
		"DarkGameTrack":
			return _generate_dark_game_track_sound(sound_name)
		_:
			print("⚠️ Unknown generator: ", generator)
			return null

# ===== GENERATOR WRAPPERS =====

func _generate_synthetic_sound(sound_name: String, params: Dictionary = {}) -> AudioStreamWAV:
	"""Generate sound from SyntheticSoundGenerator"""
	var SynthGen = preload("res://commons/audio/runtime/SyntheticSoundGenerator.gd")

	var entropy = params.get("entropy", 0.4)
	var queer_factor = params.get("queer_factor", 0.7)

	match sound_name:
		"detection_sound":
			return SynthGen.create_detection_sound(entropy, queer_factor)
		"lift_start_sound":
			return SynthGen.create_lift_start_sound(entropy, queer_factor)
		"lift_loop_sound":
			return SynthGen.create_lift_loop_sound(entropy, queer_factor)
		"lift_stop_sound":
			return SynthGen.create_lift_stop_sound(entropy, queer_factor)
		"warning_sound":
			return SynthGen.create_warning_sound(entropy, queer_factor)
		"ambient_sound":
			return SynthGen.create_ambient_sound(entropy, queer_factor)
		_:
			print("⚠️ Unknown SyntheticSoundGenerator sound: ", sound_name)
			return null

func _generate_synthesizer_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from AudioSynthesizer"""
	var AudioSynth = preload("res://commons/audio/generators/AudioSynthesizer.gd")

	# Convert string name to enum
	var sound_type = _string_to_sound_type(sound_name)
	if sound_type == null:
		print("⚠️ Unknown AudioSynthesizer sound: ", sound_name)
		return null

	# AudioSynthesizer uses static methods with enum
	return AudioSynth.generate_sound(sound_type)

func _string_to_sound_type(sound_name: String):
	"""Convert sound name string to AudioSynthesizer.SoundType enum"""
	var AudioSynth = preload("res://commons/audio/generators/AudioSynthesizer.gd")

	match sound_name:
		"BASIC_SINE_WAVE": return AudioSynth.SoundType.BASIC_SINE_WAVE
		"PICKUP_MARIO": return AudioSynth.SoundType.PICKUP_MARIO
		"TELEPORT_DRONE": return AudioSynth.SoundType.TELEPORT_DRONE
		"LIFT_BASS_PULSE": return AudioSynth.SoundType.LIFT_BASS_PULSE
		"GHOST_DRONE": return AudioSynth.SoundType.GHOST_DRONE
		"MELODIC_DRONE": return AudioSynth.SoundType.MELODIC_DRONE
		"LASER_SHOT": return AudioSynth.SoundType.LASER_SHOT
		"POWER_UP_JINGLE": return AudioSynth.SoundType.POWER_UP_JINGLE
		"EXPLOSION": return AudioSynth.SoundType.EXPLOSION
		"RETRO_JUMP": return AudioSynth.SoundType.RETRO_JUMP
		"SHIELD_HIT": return AudioSynth.SoundType.SHIELD_HIT
		"AMBIENT_WIND": return AudioSynth.SoundType.AMBIENT_WIND
		"DARK_808_KICK": return AudioSynth.SoundType.DARK_808_KICK
		"ACID_606_HIHAT": return AudioSynth.SoundType.ACID_606_HIHAT
		"DARK_808_SUB_BASS": return AudioSynth.SoundType.DARK_808_SUB_BASS
		"AMBIENT_AMIGA_DRONE": return AudioSynth.SoundType.AMBIENT_AMIGA_DRONE
		"MOOG_BASS_LEAD": return AudioSynth.SoundType.MOOG_BASS_LEAD
		"TB303_ACID_BASS": return AudioSynth.SoundType.TB303_ACID_BASS
		"DX7_ELECTRIC_PIANO": return AudioSynth.SoundType.DX7_ELECTRIC_PIANO
		"C64_SID_LEAD": return AudioSynth.SoundType.C64_SID_LEAD
		"AMIGA_MOD_SAMPLE": return AudioSynth.SoundType.AMIGA_MOD_SAMPLE
		"PPG_WAVE_PAD": return AudioSynth.SoundType.PPG_WAVE_PAD
		"TR909_KICK": return AudioSynth.SoundType.TR909_KICK
		"JUPITER_8_STRINGS": return AudioSynth.SoundType.JUPITER_8_STRINGS
		"KORG_M1_PIANO": return AudioSynth.SoundType.KORG_M1_PIANO
		"ARP_2600_LEAD": return AudioSynth.SoundType.ARP_2600_LEAD
		"SYNARE_3_DISCO_TOM": return AudioSynth.SoundType.SYNARE_3_DISCO_TOM
		"SYNARE_3_COSMIC_FX": return AudioSynth.SoundType.SYNARE_3_COSMIC_FX
		"MOOG_KRAFTWERK_SEQUENCER": return AudioSynth.SoundType.MOOG_KRAFTWERK_SEQUENCER
		"HERBIE_HANCOCK_MOOG_FUSION": return AudioSynth.SoundType.HERBIE_HANCOCK_MOOG_FUSION
		"APHEX_TWIN_MODULAR": return AudioSynth.SoundType.APHEX_TWIN_MODULAR
		"FLYING_LOTUS_SAMPLER": return AudioSynth.SoundType.FLYING_LOTUS_SAMPLER
		# Alternative names (for backward compatibility)
		"MOOG_MINIMOOG_BASS": return AudioSynth.SoundType.MOOG_BASS_LEAD
		"ACID_TB303_SQUELCH": return AudioSynth.SoundType.TB303_ACID_BASS
		"C64_SID_PULSE": return AudioSynth.SoundType.C64_SID_LEAD
		"GAMEBOY_PULSE": return AudioSynth.SoundType.C64_SID_LEAD  # Similar sound
		"COMMODORE_AMIGA_WAVE": return AudioSynth.SoundType.AMIGA_MOD_SAMPLE
		"PPG_WAVE_METALLIC": return AudioSynth.SoundType.PPG_WAVE_PAD
		"KRAFTWERK_ROBOTIC": return AudioSynth.SoundType.MOOG_KRAFTWERK_SEQUENCER
		"APHEX_TWIN_GLITCH": return AudioSynth.SoundType.APHEX_TWIN_MODULAR
		"TELEPORT_WHOOSH": return AudioSynth.SoundType.TELEPORT_DRONE
		_:
			return null

func _generate_techno_noir_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from techno noir generator"""
	# TODO: Extract techno noir generation logic from john_cage_tech_noir.gd
	# For now, return null - will implement after refactoring
	print("ℹ️ Techno noir sound generation not yet implemented: ", sound_name)
	return null

func _generate_liturgical_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from liturgical generator"""
	# TODO: Extract liturgical generation logic from liturgicalambientgenerator.gd
	# For now, return null - will implement after refactoring
	print("ℹ️ Liturgical sound generation not yet implemented: ", sound_name)
	return null

func _generate_dark_game_track_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from dark game track"""
	# TODO: Extract from DarkGameTrackPlayer
	print("ℹ️ Dark game track sound generation not yet implemented: ", sound_name)
	return null

# ===== BULK GENERATION =====

func pregenerate_preset_sounds(preset_name: String):
	"""Pre-generate all sounds needed for a preset (async)"""

	var preset = get_preset(preset_name)
	if preset.is_empty():
		return

	var sounds_to_generate = []

	# Collect all sound IDs from continuous layers
	if "continuous_layers" in preset:
		for layer in preset["continuous_layers"]:
			if "sound_id" in layer:
				sounds_to_generate.append(layer["sound_id"])

	# Collect all sound IDs from random events
	if "random_events" in preset:
		for event in preset["random_events"]:
			if "sound_pool" in event:
				for sound_id in event["sound_pool"]:
					sounds_to_generate.append(sound_id)

	# Generate all sounds
	print("🔧 Pre-generating %d sounds for preset '%s'..." % [sounds_to_generate.size(), preset_name])
	for i in range(sounds_to_generate.size()):
		var sound_id = sounds_to_generate[i]
		get_sound(sound_id)
		generation_progress.emit(i + 1, sounds_to_generate.size(), sound_id)

	print("✅ Pre-generation complete for preset '%s'" % preset_name)
	preset_loaded.emit(preset_name)

# ===== AUDIO BUS MANAGEMENT =====

func setup_buses_for_preset(preset_name: String):
	"""Setup audio buses required by a preset"""

	var preset = get_preset(preset_name)
	if not "buses" in preset:
		return

	var buses_config = preset["buses"]

	for bus_name in buses_config.keys():
		_create_or_update_bus(bus_name, buses_config[bus_name])

func _create_or_update_bus(bus_name: String, config: Dictionary):
	"""Create or update an audio bus with effects"""

	# Check if bus already exists
	var bus_idx = AudioServer.get_bus_index(bus_name)

	if bus_idx == -1:
		# Create new bus
		bus_idx = AudioServer.get_bus_count()
		AudioServer.add_bus(bus_idx)
		AudioServer.set_bus_name(bus_idx, bus_name)
		AudioServer.set_bus_send(bus_idx, "Master")
		print("✅ Created audio bus: ", bus_name)
	else:
		# Clear existing effects
		for i in range(AudioServer.get_bus_effect_count(bus_idx)):
			AudioServer.remove_bus_effect(bus_idx, 0)
		print("🔧 Updating audio bus: ", bus_name)

	# Add effects
	if "effects" in config:
		for effect_config in config["effects"]:
			var effect = _create_audio_effect(effect_config)
			if effect:
				AudioServer.add_bus_effect(bus_idx, effect)

	active_buses[bus_name] = bus_idx

func _create_audio_effect(config: Dictionary) -> AudioEffect:
	"""Create an audio effect from configuration"""

	if not "type" in config:
		return null

	var effect_type = config["type"]
	var effect = null

	match effect_type:
		"Reverb":
			effect = AudioEffectReverb.new()
			if "room_size" in config:
				effect.room_size = config["room_size"]
			if "wet" in config:
				effect.wet = config["wet"]
			if "damping" in config:
				effect.damping = config["damping"]
			if "dry" in config:
				effect.dry = config["dry"]

		"Delay":
			effect = AudioEffectDelay.new()
			if "dry" in config:
				effect.dry = config["dry"]
			if "tap1_delay_ms" in config:
				effect.tap1_delay_ms = config["tap1_delay_ms"]
			if "tap1_level" in config:
				effect.tap1_level_db = config["tap1_level"]
			if "tap1_level_db" in config:
				effect.tap1_level_db = config["tap1_level_db"]

		"LowPassFilter":
			effect = AudioEffectLowPassFilter.new()
			if "cutoff_hz" in config:
				effect.cutoff_hz = config["cutoff_hz"]

		"HighPassFilter":
			effect = AudioEffectHighPassFilter.new()
			if "cutoff_hz" in config:
				effect.cutoff_hz = config["cutoff_hz"]

		"Chorus":
			effect = AudioEffectChorus.new()
			if "dry" in config:
				effect.dry = config["dry"]
			if "wet" in config:
				effect.wet = config["wet"]

		"Distortion":
			effect = AudioEffectDistortion.new()
			if "mode" in config:
				effect.mode = config["mode"]
			if "drive" in config:
				effect.drive = config["drive"]

		_:
			print("⚠️ Unknown effect type: ", effect_type)
			return null

	return effect

# ===== CLEANUP =====

func clear_cache():
	"""Clear all cached sounds"""
	sound_registry.clear()
	print("🧹 Sound cache cleared")

func clear_inactive_buses():
	"""Remove buses that are no longer in use"""
	# TODO: Implement bus cleanup logic
	pass

# ===== UTILITY =====

func get_cache_info() -> Dictionary:
	"""Get information about cached sounds"""
	return {
		"cached_sounds": sound_registry.size(),
		"presets_loaded": ambient_presets.size(),
		"active_buses": active_buses.size(),
		"generation_complete": generation_complete
	}

func print_info():
	"""Print current state information"""
	var info = get_cache_info()
	print("🎵 SOUND BANK INFO 🎵")
	print("   Cached sounds: ", info["cached_sounds"])
	print("   Presets loaded: ", info["presets_loaded"])
	print("   Active buses: ", info["active_buses"])
	print("   Generation complete: ", info["generation_complete"])
