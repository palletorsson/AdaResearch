# AudioCatalogTablet3D.gd
# 3D handheld tablet for browsing and previewing audio presets
# Uses XR Tools viewport_2d_in_3d for VR interaction

extends Node3D
class_name AudioCatalogTablet3D

signal sound_selected(sound_key: String)
signal sound_preview_started(sound_key: String)
signal sound_preview_stopped()

@export var screen_width: float = 1.4   # Physical screen width in meters
@export var screen_height: float = 1.0  # Physical screen height in meters
@export var viewport_width: int = 1600
@export var viewport_height: int = 1200

@onready var _viewport_2d_in_3d: Node3D = $Viewport2Din3D
@onready var frame_mesh: MeshInstance3D = $Frame

var _catalog_ui: AudioCatalogUI
var _audio_player: AudioStreamPlayer
var _current_stream: AudioStreamWAV


func _ready():
	_setup_audio_player()
	# Defer UI connection to ensure the viewport_2d_in_3d scene is ready
	call_deferred("_connect_ui_signals")


func _setup_audio_player():
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "Master"
	_audio_player.finished.connect(_on_audio_finished)
	add_child(_audio_player)


func _connect_ui_signals():
	# Get the UI scene instance from the viewport_2d_in_3d
	if _viewport_2d_in_3d and _viewport_2d_in_3d.has_method("get_scene_instance"):
		_catalog_ui = _viewport_2d_in_3d.get_scene_instance() as AudioCatalogUI

	if _catalog_ui == null:
		# Try direct viewport access as fallback
		var viewport = _viewport_2d_in_3d.get_node_or_null("Viewport")
		if viewport and viewport.get_child_count() > 0:
			_catalog_ui = viewport.get_child(0) as AudioCatalogUI

	if _catalog_ui:
		_catalog_ui.sound_selected.connect(_on_sound_selected)
		_catalog_ui.play_requested.connect(_on_play_requested)
		_catalog_ui.stop_requested.connect(_on_stop_requested)
	else:
		push_warning("AudioCatalogTablet3D: Could not find AudioCatalogUI instance")


func _on_sound_selected(sound_key: String):
	sound_selected.emit(sound_key)


func _on_play_requested(sound_key: String, parameters: Dictionary):
	_play_sound(sound_key, parameters)


func _on_stop_requested():
	_stop_sound()


func _play_sound(sound_key: String, parameters: Dictionary):
	# Get sound entry
	var sound := AudioCatalogDataProvider.get_sound(sound_key)
	if sound.is_empty():
		push_warning("AudioCatalogTablet3D: Sound not found: " + sound_key)
		return

	# Detect generator type and generate audio
	var audio_stream := _generate_audio(sound, parameters)
	if audio_stream == null:
		push_warning("AudioCatalogTablet3D: Failed to generate audio for: " + sound_key)
		return

	_current_stream = audio_stream
	_audio_player.stream = audio_stream
	_audio_player.play()

	if _catalog_ui:
		_catalog_ui.set_playing(true)
	sound_preview_started.emit(sound_key)

	# Extract waveform for visualization
	var samples := _extract_samples(audio_stream)
	if _catalog_ui:
		_catalog_ui.set_waveform_data(samples)


func _stop_sound():
	_audio_player.stop()
	if _catalog_ui:
		_catalog_ui.set_playing(false)
	sound_preview_stopped.emit()


func _on_audio_finished():
	if _catalog_ui:
		_catalog_ui.set_playing(false)
	sound_preview_stopped.emit()


func _generate_audio(sound: Dictionary, parameters: Dictionary) -> AudioStreamWAV:
	var metadata: Dictionary = sound.get("metadata", {})
	var sound_type_str: String = metadata.get("sound_type", sound.sound_key)
	var category: String = sound.get("category", "")
	var sound_key: String = sound.get("sound_key", "")

	# Merge default parameters with user parameters
	var merged_params := _merge_parameters(sound.get("parameters", {}), parameters)

	# Try to detect generator type
	var generator_type := _detect_generator_type(category, sound_type_str)

	match generator_type:
		"TechnoNoir":
			return TechnoNoirGenerator.generate_sound(sound_type_str, merged_params)
		"TrapBeats":
			return TrapBeatsGenerator.generate_sound(sound_type_str, merged_params)
		"Cinematic":
			return CinematicMusicGenerator.generate_sound(sound_type_str, merged_params)
		"SciFi":
			return SciFiPreviewGenerator.generate_preview(sound_type_str)
	
	# Try direct mapping from sound_type metadata
	var sound_type := _string_to_sound_type(sound_type_str)
	if sound_type != -1:
		return CustomSoundGenerator.generate_custom_sound(sound_type, merged_params)
	
	# Try sound_key as fallback
	sound_type = _string_to_sound_type(sound_key)
	if sound_type != -1:
		return CustomSoundGenerator.generate_custom_sound(sound_type, merged_params)
	
	# Smart fallback based on category
	match category:
		"drums":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.DARK_808_KICK, merged_params)
		"synthesizers":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.MOOG_BASS_LEAD, merged_params)
		"ambient":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.MELODIC_DRONE, merged_params)
		"retro":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.C64_SID_LEAD, merged_params)
		"sci_fi":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.LAB_HUM, merged_params)
		"cinematic":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.CS80_BRASS_LEAD, merged_params)
		"educational":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.BASIC_SINE_WAVE, merged_params)
		"basic":
			# For basic category, use the sound key to pick
			if sound_key.contains("explosion"):
				return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.EXPLOSION, merged_params)
			elif sound_key.contains("laser"):
				return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.LASER_SHOT, merged_params)
			elif sound_key.contains("jump"):
				return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.RETRO_JUMP, merged_params)
			elif sound_key.contains("pickup"):
				return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.PICKUP_MARIO, merged_params)
			elif sound_key.contains("power"):
				return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.POWER_UP_JINGLE, merged_params)
		"experimental":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.APHEX_TWIN_MODULAR, merged_params)
		"liturgical":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.MELODIC_DRONE, merged_params)
		"fourier":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.MELODIC_DRONE, merged_params)
		"epic":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.CS80_BRASS_LEAD, merged_params)

	# Final fallback: use melodic drone (more interesting than sine wave)
	print("AudioCatalogTablet3D: Using fallback for '%s' (category: %s)" % [sound_key, category])
	return CustomSoundGenerator.generate_custom_sound(
		AudioSynthesizer.SoundType.MELODIC_DRONE,
		merged_params
	)


func _detect_generator_type(category: String, sound_key: String) -> String:
	var key_lower := sound_key.to_lower()
	
	# Check by category first
	match category:
		"tech_noir":
			return "TechnoNoir"
		"trap_beats":
			return "TrapBeats"
		"cinematic":
			return "Cinematic"

	# Check by sound key patterns
	if key_lower.begins_with("tech_noir") or key_lower.contains("industrial"):
		return "TechnoNoir"
	if key_lower.begins_with("trap") or (key_lower.contains("808") and not key_lower.contains("sub")):
		return "TrapBeats"
	if key_lower.begins_with("cinematic") or key_lower.contains("vangelis") or key_lower.contains("blade_runner"):
		return "Cinematic"
	
	# Don't use SciFi generator for now - it's too limited
	# Let these fall through to the AudioSynthesizer
	return "Default"


func _string_to_sound_type(type_str: String) -> int:
	# Map string to AudioSynthesizer.SoundType enum - complete list
	var type_map := {
		# Basic sounds
		"basic_sine_wave": AudioSynthesizer.SoundType.BASIC_SINE_WAVE,
		"pickup_mario": AudioSynthesizer.SoundType.PICKUP_MARIO,
		"teleport_drone": AudioSynthesizer.SoundType.TELEPORT_DRONE,
		"lift_bass_pulse": AudioSynthesizer.SoundType.LIFT_BASS_PULSE,
		"ghost_drone": AudioSynthesizer.SoundType.GHOST_DRONE,
		"melodic_drone": AudioSynthesizer.SoundType.MELODIC_DRONE,
		"laser_shot": AudioSynthesizer.SoundType.LASER_SHOT,
		"power_up_jingle": AudioSynthesizer.SoundType.POWER_UP_JINGLE,
		"explosion": AudioSynthesizer.SoundType.EXPLOSION,
		"retro_jump": AudioSynthesizer.SoundType.RETRO_JUMP,
		"shield_hit": AudioSynthesizer.SoundType.SHIELD_HIT,
		"ambient_wind": AudioSynthesizer.SoundType.AMBIENT_WIND,
		# Drum machines
		"dark_808_kick": AudioSynthesizer.SoundType.DARK_808_KICK,
		"acid_606_hihat": AudioSynthesizer.SoundType.ACID_606_HIHAT,
		"dark_808_sub_bass": AudioSynthesizer.SoundType.DARK_808_SUB_BASS,
		"tr909_kick": AudioSynthesizer.SoundType.TR909_KICK,
		"synare_3_disco_tom": AudioSynthesizer.SoundType.SYNARE_3_DISCO_TOM,
		"synare_3_cosmic_fx": AudioSynthesizer.SoundType.SYNARE_3_COSMIC_FX,
		# Retro / vintage
		"ambient_amiga_drone": AudioSynthesizer.SoundType.AMBIENT_AMIGA_DRONE,
		"c64_sid_lead": AudioSynthesizer.SoundType.C64_SID_LEAD,
		"amiga_mod_sample": AudioSynthesizer.SoundType.AMIGA_MOD_SAMPLE,
		"gameboy_dmg_wav": AudioSynthesizer.SoundType.C64_SID_LEAD,  # Use SID as fallback
		# Synthesizers
		"moog_bass_lead": AudioSynthesizer.SoundType.MOOG_BASS_LEAD,
		"tb303_acid_bass": AudioSynthesizer.SoundType.TB303_ACID_BASS,
		"dx7_electric_piano": AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO,
		"ppg_wave_pad": AudioSynthesizer.SoundType.PPG_WAVE_PAD,
		"jupiter_8_strings": AudioSynthesizer.SoundType.JUPITER_8_STRINGS,
		"korg_m1_piano": AudioSynthesizer.SoundType.KORG_M1_PIANO,
		"arp_2600_lead": AudioSynthesizer.SoundType.ARP_2600_LEAD,
		"moog_kraftwerk_sequencer": AudioSynthesizer.SoundType.MOOG_KRAFTWERK_SEQUENCER,
		# Experimental
		"herbie_hancock_moog_fusion": AudioSynthesizer.SoundType.HERBIE_HANCOCK_MOOG_FUSION,
		"aphex_twin_modular": AudioSynthesizer.SoundType.APHEX_TWIN_MODULAR,
		"flying_lotus_sampler": AudioSynthesizer.SoundType.FLYING_LOTUS_SAMPLER,
		# Sci-Fi
		"sci_fi_lab_hum_clean": AudioSynthesizer.SoundType.SCI_FI_LAB_HUM_CLEAN,
		"sci_fi_resonant_drone": AudioSynthesizer.SoundType.SCI_FI_RESONANT_DRONE,
		"sci_fi_data_chirps": AudioSynthesizer.SoundType.SCI_FI_DATA_CHIRPS,
		"sci_fi_ventilation": AudioSynthesizer.SoundType.SCI_FI_VENTILATION,
		"sci_fi_electromagnetic": AudioSynthesizer.SoundType.SCI_FI_ELECTROMAGNETIC,
		"lab_hum": AudioSynthesizer.SoundType.LAB_HUM,
		# Cinematic
		"cs80_brass_lead": AudioSynthesizer.SoundType.CS80_BRASS_LEAD,
		"cinematic_432hz_pad": AudioSynthesizer.SoundType.CINEMATIC_432HZ_PAD,
		"vangelis_brass_lead": AudioSynthesizer.SoundType.CS80_BRASS_LEAD,
		"blade_runner_pad": AudioSynthesizer.SoundType.PPG_WAVE_PAD,
		"deep_dark_cello_drone": AudioSynthesizer.SoundType.MELODIC_DRONE,
		# Pop
		"pop_juno_chorus_pad": AudioSynthesizer.SoundType.POP_JUNO_CHORUS_PAD,
		"pop_dx7_ballad_keys": AudioSynthesizer.SoundType.POP_DX7_BALLAD_KEYS,
		"pop_obxa_brass": AudioSynthesizer.SoundType.POP_OBXA_BRASS,
		"pop_prophet_lead": AudioSynthesizer.SoundType.POP_PROPHET_LEAD,
		"pop_funk_bass": AudioSynthesizer.SoundType.POP_FUNK_BASS,
		# Biological
		"heartbeat": AudioSynthesizer.SoundType.HEARTBEAT,
		"heartbeat_segment": AudioSynthesizer.SoundType.HEARTBEAT,
	}

	var key := type_str.to_lower().replace(" ", "_").replace("-", "_")
	if type_map.has(key):
		return type_map[key]
	
	# Try partial matches for common patterns
	if key.contains("kick") or key.contains("808_kick"):
		return AudioSynthesizer.SoundType.DARK_808_KICK
	if key.contains("hihat") or key.contains("hat"):
		return AudioSynthesizer.SoundType.ACID_606_HIHAT
	if key.contains("snare"):
		return AudioSynthesizer.SoundType.TR909_KICK
	if key.contains("bass") and key.contains("sub"):
		return AudioSynthesizer.SoundType.DARK_808_SUB_BASS
	if key.contains("bass"):
		return AudioSynthesizer.SoundType.MOOG_BASS_LEAD
	if key.contains("pad"):
		return AudioSynthesizer.SoundType.PPG_WAVE_PAD
	if key.contains("drone"):
		return AudioSynthesizer.SoundType.MELODIC_DRONE
	if key.contains("lead"):
		return AudioSynthesizer.SoundType.ARP_2600_LEAD
	if key.contains("piano") or key.contains("keys"):
		return AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO
	if key.contains("string"):
		return AudioSynthesizer.SoundType.JUPITER_8_STRINGS
	if key.contains("brass"):
		return AudioSynthesizer.SoundType.CS80_BRASS_LEAD
	if key.contains("hum") or key.contains("lab"):
		return AudioSynthesizer.SoundType.LAB_HUM
	if key.contains("wind") or key.contains("ambient"):
		return AudioSynthesizer.SoundType.AMBIENT_WIND

	return -1


func _merge_parameters(defaults: Dictionary, overrides: Dictionary) -> Dictionary:
	var result := {}

	# Extract values from default parameter configs
	for key in defaults:
		var config: Dictionary = defaults[key]
		if config.has("value"):
			result[key] = config.value
		elif config.has("min"):
			result[key] = config.get("min", 0.0)

	# Apply overrides
	for key in overrides:
		result[key] = overrides[key]

	# Ensure duration exists
	if not result.has("duration"):
		result["duration"] = 1.0

	return result


func _extract_samples(stream: AudioStreamWAV) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	if stream == null:
		return samples

	var data := stream.data
	var format := stream.format
	var stereo := stream.stereo

	# Convert based on format
	match format:
		AudioStreamWAV.FORMAT_8_BITS:
			for i in range(0, data.size(), 2 if stereo else 1):
				var sample := (float(data[i]) - 128.0) / 128.0
				samples.append(sample)

		AudioStreamWAV.FORMAT_16_BITS:
			var step := 4 if stereo else 2
			for i in range(0, data.size(), step):
				if i + 1 < data.size():
					var sample_int := data[i] | (data[i + 1] << 8)
					if sample_int > 32767:
						sample_int -= 65536
					var sample := float(sample_int) / 32768.0
					samples.append(sample)

	# Downsample for visualization (target ~512 points)
	var target_points := 512
	if samples.size() > target_points:
		var downsampled := PackedFloat32Array()
		var step := samples.size() / target_points
		for i in range(target_points):
			var idx := int(i * step)
			if idx < samples.size():
				downsampled.append(samples[idx])
		return downsampled

	return samples


# Refresh the catalog
func refresh():
	if _catalog_ui:
		_catalog_ui.refresh()
