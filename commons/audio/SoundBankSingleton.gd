extends Node

# SoundBankSingleton - Centralized sound management system
# This singleton manages all sound generation, caching, and preset loading
# for the Ada Research VR educational system

# Signals
signal sound_bank_ready
signal preset_loaded(preset_name: String)
signal sound_generated(sound_id: String)
signal generation_progress(current: int, total: int, sound_name: String)
signal request_ambient_change(preset_name: String) # Global request to change ambient

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
const PRESETS_DIR = "res://commons/audio/presets/"
const MANIFEST_PATH = "res://commons/audio/presets_manifest.json"

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
	"""Load ambient preset definitions from individual JSON files via manifest"""
	ambient_presets.clear()
	
	# 1. Load Manifest
	var manifest_file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if not manifest_file:
		print("⚠️ Could not load presets manifest from: ", MANIFEST_PATH)
		return

	var json = JSON.new()
	var parse_result = json.parse(manifest_file.get_as_text())
	manifest_file.close()

	if parse_result != OK:
		print("⚠️ JSON parse error in presets manifest")
		return

	var manifest_data = json.data
	if not "presets" in manifest_data:
		print("⚠️ No 'presets' key found in manifest")
		return
		
	var preset_list = manifest_data["presets"]
	print("📂 Found %d presets in manifest. Loading..." % preset_list.size())
	
	# 2. Load Each Preset File
	for preset_id in preset_list:
		_load_single_preset(preset_id)
		
	print("✅ Successfully loaded %d ambient presets" % ambient_presets.size())

func _load_single_preset(preset_id: String):
	"""Load a single preset file"""
	var path = PRESETS_DIR + preset_id + ".json"
	var file = FileAccess.open(path, FileAccess.READ)
	
	if not file:
		print("⚠️ Could not load preset file: ", path)
		return
		
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		print("⚠️ JSON parse error in preset: ", preset_id)
		return
		
	# Store the preset data directly under its ID
	ambient_presets[preset_id] = json.data

func get_preset(preset_name: String) -> Dictionary:
	"""Get an ambient preset by name"""
	if preset_name in ambient_presets:
		return ambient_presets[preset_name]
	else:
		print("⚠️ Preset not found: ", preset_name, " - using 'silent' preset")
		return ambient_presets.get("silent", {})

func trigger_ambient_change(preset_name: String):
	"""Trigger a global change of ambient preset"""
	print("🔊 SoundBank: Requesting global ambient change to: ", preset_name)
	request_ambient_change.emit(preset_name)

# ===== SOUND GENERATION =====

func get_sound(sound_id: String) -> AudioStream:
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
		# Check if it supports async generation (only pop songs for now)
		if sound_id.contains("POP_INTERACTIVE_SONG"):
			print("SoundBank: Triggering async generation for ", sound_id)
			_request_async_generation(sound_id)
			return null # Caller must listen to sound_generated signal
			
		print("⚠️ Failed to generate sound: ", sound_id)
		return null

func _request_async_generation(sound_id: String):
	if sound_id.contains("POP_INTERACTIVE_SONG"):
		AudioSynthesizer.generate_pop_song_async({}, self, "_on_async_sound_ready")
	elif sound_id.contains("AMBIENT_WORKS_SONG"):
		AudioSynthesizer.generate_pop_song_async({"type": "AMBIENT"}, self, "_on_async_sound_ready") # Reusing generation thread wrapper

func _on_async_sound_ready(stream: AudioStream):
	# Assuming single active generation for now, mapped to the ID
	# TODO: Pass ID through callback for robustness
	var sound_id = "AudioSynthesizer.POP_INTERACTIVE_SONG" # Hardcoded fallback matches current usage
	if stream:
		sound_registry[sound_id] = stream
		print("SoundBank: Async sound ready: ", sound_id)
		sound_generated.emit(sound_id)
	else:
		print("SoundBank: Async generation failed")

func _generate_sound(sound_id: String) -> AudioStream:
	"""Generate a sound based on its ID"""

	# Parse the sound ID (format: "generator.sound_name" or "generator:sound_name")
	var separator = "."
	if sound_id.contains(":"):
		separator = ":"
	
	var parts = sound_id.split(separator)
	if parts.size() != 2:
		print("⚠️ Invalid sound_id format (needs generator.sound or generator:sound): ", sound_id)
		return null

	var generator = parts[0]
	var sound_name = parts[1]

	# Route to appropriate generator (case-insensitive for convenience)
	match generator.to_lower():
		"syntheticsoundgenerator":
			return _generate_synthetic_sound(sound_name)
		"audiosynthesizer":
			return _generate_synthesizer_sound(sound_name)
		"techno_noir":
			return _generate_techno_noir_sound(sound_name)
		"trap_beats":
			return _generate_trap_beats_sound(sound_name)
		"liturgical":
			return _generate_liturgical_sound(sound_name)
		"darkgametrack":
			return _generate_dark_game_track_sound(sound_name)
		"cinematic":
			return _generate_cinematic_sound(sound_name)
		"epic":
			return _generate_epic_sound(sound_name)
		"fourier_space":
			return _generate_fourier_space_sound(sound_name)
		"sci_fi":
			return _generate_sci_fi_dystopia_sound(sound_name)
		"cyber_jazz":
			return _generate_cyber_jazz_sound(sound_name)
		_:
			# Fallback for original casing if needed
			match generator:
				"SyntheticSoundGenerator": return _generate_synthetic_sound(sound_name)
				"AudioSynthesizer": return _generate_synthesizer_sound(sound_name)
				"DarkGameTrack": return _generate_dark_game_track_sound(sound_name)
				"Cinematic": return _generate_cinematic_sound(sound_name)
				"Epic": return _generate_epic_sound(sound_name)
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
	# Dynamic lookup in the Enum (which acts as a dictionary)
	if sound_name in AudioSynthesizer.SoundType:
		return AudioSynthesizer.SoundType[sound_name]

	# Handle aliases (backward compatibility)
	match sound_name:
		"MOOG_MINIMOOG_BASS": return AudioSynthesizer.SoundType.MOOG_BASS_LEAD
		"ACID_TB303_SQUELCH": return AudioSynthesizer.SoundType.TB303_ACID_BASS
		"C64_SID_PULSE": return AudioSynthesizer.SoundType.C64_SID_LEAD
		"GAMEBOY_PULSE": return AudioSynthesizer.SoundType.C64_SID_LEAD
		"COMMODORE_AMIGA_WAVE": return AudioSynthesizer.SoundType.AMIGA_MOD_SAMPLE
		"PPG_WAVE_METALLIC": return AudioSynthesizer.SoundType.PPG_WAVE_PAD
		"KRAFTWERK_ROBOTIC": return AudioSynthesizer.SoundType.MOOG_KRAFTWERK_SEQUENCER
		"APHEX_TWIN_GLITCH": return AudioSynthesizer.SoundType.APHEX_TWIN_MODULAR
		"TELEPORT_WHOOSH": return AudioSynthesizer.SoundType.TELEPORT_DRONE
		"POP_INTERACTIVE_SONG": return AudioSynthesizer.SoundType.POP_INTERACTIVE_SONG
		_:
			return null

func _generate_techno_noir_sound(sound_name: String, params: Dictionary = {}) -> AudioStreamWAV:
	"""Generate sound from techno noir generator"""
	var TechnoNoir = preload("res://commons/audio/generators/TechnoNoirGenerator.gd")

	# Use the static generator method
	var stream = TechnoNoir.generate_sound(sound_name, params)

	if stream:
		print("✅ Generated tech noir sound: ", sound_name)
		return stream
	else:
		print("⚠️ Unknown tech noir sound: ", sound_name)
		return null

func _generate_trap_beats_sound(sound_name: String, params: Dictionary = {}) -> AudioStreamWAV:
	"""Generate sound from trap beats generator - BANG HARDER"""
	var TrapBeats = preload("res://commons/audio/generators/TrapBeatsGenerator.gd")

	# Use the static generator method
	var stream = TrapBeats.generate_sound(sound_name, params)

	if stream:
		print("✅ Generated trap beat: ", sound_name, " 🔥")
		return stream
	else:
		print("⚠️ Unknown trap beat: ", sound_name)
		return null

func _generate_liturgical_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from liturgical generator bridge"""
	var LitGen = preload("res://algorithms/wavefunctions/liturgicalambientgenerator/liturgicalambientgenerator.gd").new()
	
	match sound_name.to_lower():
		"cathedral_bell", "cathedral_bells": return LitGen.create_cathedral_bell()
		"pipe_organ_swell": return LitGen.create_pipe_organ_swell()
		"sacred_whisper", "sacred_whispers": return LitGen.create_sacred_whisper()
		"choral_texture", "angelic_texture": return LitGen.create_angelic_texture()
		"gregorian_phrase": return LitGen.create_gregorian_phrase()
		"divine_breath": return LitGen.create_divine_breath()
		_:
			print("⚠️ Unknown liturgical sound: ", sound_name, " - falling back to choir")
			return LitGen.create_angelic_texture()

func _generate_dark_game_track_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from dark game track bridge (reusing trap_beats logic)"""
	var TrapBeats = preload("res://commons/audio/generators/TrapBeatsGenerator.gd")
	
	match sound_name.to_lower():
		"808_kick", "dark_808_kick": return TrapBeats.create_808_kick()
		"606_hihat", "acid_606_hihat": return TrapBeats.create_hihat_909() # Using hihat fallback
		"808_sub_bass", "sub_bass": return TrapBeats.create_808_kick({"decay": 2.0, "punch": 0.5}) # Long sub
		"ambient_drone": return _generate_cinematic_sound("blade_runner_pad")
		"acid_606_snare", "snare": return TrapBeats.create_trap_snare()
		"glitch_stab": return TrapBeats.create_808_cowbell({"pitch": 800})
		"blade_runner_hit": return _generate_cinematic_sound("vangelis_brass_lead")
		_:
			print("⚠️ Unknown game track sound: ", sound_name, " - falling back to kick")
			return TrapBeats.create_808_kick()

func _generate_cinematic_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from CinematicMusicGenerator"""
	var CinematicGen = preload("res://commons/audio/generators/CinematicMusicGenerator.gd")
	
	# Default params (can be expanded later to accept params from preset)
	var params = {}
	
	var stream = CinematicGen.generate_sound(sound_name, params)
	
	if stream:
		print("✅ Generated cinematic sound: ", sound_name, " 🎬")
		return stream
	else:
		print("⚠️ Unknown cinematic sound: ", sound_name)
		return null

func _generate_epic_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from EpicSynthEngine (Analog Domain)"""
	var EpicGen = preload("res://commons/audio/engines/EpicSynthEngine.gd")
	var params = {} # Default params
	
	var stream = EpicGen.generate_patch(sound_name, params)
	
	if stream:
		print("✅ Generated EPIC sound: ", sound_name, " 🎹")
		return stream
	else:
		print("⚠️ Unknown epic sound: ", sound_name)
		return null

func _generate_sci_fi_dystopia_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from SciFiPreviewGenerator (Space Dystopia)"""
	var SciFiGen = preload("res://commons/audio/generators/SciFiPreviewGenerator.gd")
	var stream = SciFiGen.generate_preview(sound_name)
	
	if stream:
		print("✅ Generated SciFi Dystopia preview: ", sound_name, " 🎷")
		return stream
	else:
		print("⚠️ Unknown sci_fi sound: ", sound_name)
		return null

func _generate_cyber_jazz_sound(sound_name: String) -> AudioStreamWAV:
	"""Generate sound from CyberJazzGenerator"""
	var JazzGen = preload("res://commons/audio/generators/CyberJazzGenerator.gd")
	var stream = null
	
	match sound_name.to_lower():
		"sax", "saxophone", "noir_sax":
			stream = JazzGen.generate_sax()
		"pluck", "koto_pluck", "market_pluck":
			stream = JazzGen.generate_pluck()
		_:
			print("⚠️ Unknown cyber jazz sound: ", sound_name)
			return null
			
	if stream:
		print("✅ Generated Cyber Jazz sound: ", sound_name, " 🎷")
		return stream
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

func _generate_fourier_space_sound(sound_name: String) -> AudioStream:
	var generator = load("res://commons/audio/generators/FourierSpaceGenerator.gd").new()
	
	match sound_name.to_lower():
		"drone":
			# Default wheels as defined in fouriertransformshape.gd
			var wheels = [
				{"freq": 1.0, "radius": 2.0, "phase": 0.0},
				{"freq": 3.0, "radius": 0.8, "phase": 0.0},
				{"freq": 5.0, "radius": 0.4, "phase": PI / 2},
				{"freq": 7.0, "radius": 0.2, "phase": PI / 4}
			]
			return generator.create_fourier_drone(wheels)
		"nebula":
			return generator.create_nebula_pad()
		_:
			return generator.create_fourier_drone([])

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
