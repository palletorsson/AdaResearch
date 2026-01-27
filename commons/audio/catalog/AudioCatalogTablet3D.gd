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
		_:
			# Default: use CustomSoundGenerator with AudioSynthesizer
			var sound_type := _string_to_sound_type(sound_type_str)
			if sound_type != -1:
				return CustomSoundGenerator.generate_custom_sound(sound_type, merged_params)

	# Fallback: basic sine wave
	return CustomSoundGenerator.generate_custom_sound(
		AudioSynthesizer.SoundType.BASIC_SINE_WAVE,
		merged_params
	)


func _detect_generator_type(category: String, sound_key: String) -> String:
	# Check by category
	match category:
		"tech_noir":
			return "TechnoNoir"
		"trap_beats":
			return "TrapBeats"
		"cinematic":
			return "Cinematic"
		"sci_fi":
			return "SciFi"

	# Check by sound key patterns
	if sound_key.begins_with("tech_noir") or sound_key.contains("industrial"):
		return "TechnoNoir"
	if sound_key.begins_with("trap") or sound_key.contains("808"):
		return "TrapBeats"
	if sound_key.begins_with("cinematic") or sound_key.contains("vangelis"):
		return "Cinematic"
	if sound_key.begins_with("sci_fi") or sound_key.contains("lab_hum"):
		return "SciFi"

	return "Default"


func _string_to_sound_type(type_str: String) -> int:
	# Map string to AudioSynthesizer.SoundType enum
	var type_map := {
		"basic_sine_wave": AudioSynthesizer.SoundType.BASIC_SINE_WAVE,
		"pickup_mario": AudioSynthesizer.SoundType.PICKUP_MARIO,
		"teleport_drone": AudioSynthesizer.SoundType.TELEPORT_DRONE,
		"ghost_drone": AudioSynthesizer.SoundType.GHOST_DRONE,
		"melodic_drone": AudioSynthesizer.SoundType.MELODIC_DRONE,
		"laser_shot": AudioSynthesizer.SoundType.LASER_SHOT,
		"explosion": AudioSynthesizer.SoundType.EXPLOSION,
		"retro_jump": AudioSynthesizer.SoundType.RETRO_JUMP,
		"ambient_wind": AudioSynthesizer.SoundType.AMBIENT_WIND,
		"dark_808_kick": AudioSynthesizer.SoundType.DARK_808_KICK,
		"acid_606_hihat": AudioSynthesizer.SoundType.ACID_606_HIHAT,
		"dark_808_sub_bass": AudioSynthesizer.SoundType.DARK_808_SUB_BASS,
		"tr909_kick": AudioSynthesizer.SoundType.TR909_KICK,
		"moog_bass_lead": AudioSynthesizer.SoundType.MOOG_BASS_LEAD,
		"tb303_acid_bass": AudioSynthesizer.SoundType.TB303_ACID_BASS,
		"dx7_electric_piano": AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO,
		"c64_sid_lead": AudioSynthesizer.SoundType.C64_SID_LEAD,
		"amiga_mod_sample": AudioSynthesizer.SoundType.AMIGA_MOD_SAMPLE,
		"ppg_wave_pad": AudioSynthesizer.SoundType.PPG_WAVE_PAD,
		"jupiter_8_strings": AudioSynthesizer.SoundType.JUPITER_8_STRINGS,
		"korg_m1_piano": AudioSynthesizer.SoundType.KORG_M1_PIANO,
		"arp_2600_lead": AudioSynthesizer.SoundType.ARP_2600_LEAD,
		"cs80_brass_lead": AudioSynthesizer.SoundType.CS80_BRASS_LEAD,
		"heartbeat": AudioSynthesizer.SoundType.HEARTBEAT,
		"lab_hum": AudioSynthesizer.SoundType.LAB_HUM,
	}

	var key := type_str.to_lower().replace(" ", "_")
	if type_map.has(key):
		return type_map[key]

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
