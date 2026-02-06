# AudioCatalogDesktop.gd
# Main desktop application for AdaResearch audio tools
# Tabs: Genre Synth Browser | Original Catalog | Live Session

extends Control

const GenreSynthBrowser = preload("res://commons/audio/catalog/GenreSynthBrowser.gd")
const SoundEffectBoard = preload("res://commons/audio/catalog/ui/SoundEffectBoard.gd")

var _tab_container: TabContainer
var _genre_browser: GenreSynthBrowser
var _catalog_ui: AudioCatalogUI
var _effect_board: SoundEffectBoard
var _audio_player: AudioStreamPlayer
var _current_stream: AudioStreamWAV


func _ready():
	# Set up window
	get_tree().root.title = "AdaResearch Audio Catalog"
	
	# Use scene nodes or create if missing
	_audio_player = $AudioPlayer if has_node("AudioPlayer") else AudioStreamPlayer.new()
	if not has_node("AudioPlayer"):
		_audio_player.bus = "Master"
		add_child(_audio_player)
	_audio_player.finished.connect(_on_audio_finished)
	
	# Use scene TabContainer or create
	_tab_container = $TabContainer if has_node("TabContainer") else TabContainer.new()
	if not has_node("TabContainer"):
		_tab_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_tab_container)
	
	# Tab 1: Genre Synth Browser (NEW - elements by genre)
	_genre_browser = GenreSynthBrowser.new()
	_genre_browser.name = "🎹 Synth Elements"
	_tab_container.add_child(_genre_browser)
	
	# Tab 2: Original Catalog UI
	_catalog_ui = AudioCatalogUI.new()
	_catalog_ui.name = "📦 Sound Catalog"
	_tab_container.add_child(_catalog_ui)

	# Tab 3: SFX Board
	_effect_board = SoundEffectBoard.new()
	_effect_board.name = "SFX Board"
	_tab_container.add_child(_effect_board)
	
	# Connect signals
	_catalog_ui.play_requested.connect(_on_play_requested)
	_catalog_ui.stop_requested.connect(_on_stop_requested)
	_effect_board.play_requested.connect(_on_play_requested)
	_effect_board.stop_requested.connect(_on_stop_requested)
	
	print("Audio Catalog Desktop ready")
	print("  - Genre Synth Browser: 10 genres, 40+ elements")
	print("  - Sound Catalog: %d sounds" % AudioCatalogDataProvider.get_sound_count())


func _on_play_requested(sound_key: String, parameters: Dictionary):
	_play_sound(sound_key, parameters)


func _on_stop_requested():
	_stop_sound()


func _play_sound(sound_key: String, parameters: Dictionary):
	var sound := AudioCatalogDataProvider.get_sound(sound_key)
	if sound.is_empty():
		push_warning("AudioCatalogDesktop: Sound not found: " + sound_key)
		return

	var audio_stream := _generate_audio(sound, parameters)
	if audio_stream == null:
		push_warning("AudioCatalogDesktop: Failed to generate audio for: " + sound_key)
		return

	_current_stream = audio_stream
	_audio_player.stream = audio_stream
	_audio_player.play()

	_catalog_ui.set_playing(true)
	if _effect_board:
		_effect_board.set_playing(true)

	var samples := _extract_samples(audio_stream)
	_catalog_ui.set_waveform_data(samples)
	if _effect_board:
		_effect_board.set_waveform_data(samples)


func _stop_sound():
	_audio_player.stop()
	_catalog_ui.set_playing(false)
	if _effect_board:
		_effect_board.set_playing(false)


func _on_audio_finished():
	_catalog_ui.set_playing(false)
	if _effect_board:
		_effect_board.set_playing(false)


func _generate_audio(sound: Dictionary, parameters: Dictionary) -> AudioStreamWAV:
	var metadata: Dictionary = sound.get("metadata", {})
	var sound_type_str: String = metadata.get("sound_type", sound.sound_key)
	var category: String = sound.get("category", "")
	var sound_key: String = sound.get("sound_key", "")

	var merged_params := _merge_parameters(sound.get("parameters", {}), parameters)
	var generator_type := _detect_generator_type(category, sound_type_str)

	match generator_type:
		"TechnoNoir":
			return TechnoNoirGenerator.generate_sound(sound_type_str, merged_params)
		"TrapBeats":
			return TrapBeatsGenerator.generate_sound(sound_type_str, merged_params)
		"Cinematic":
			return CinematicMusicGenerator.generate_sound(sound_type_str, merged_params)
		"SpaceDystopia":
			return SpaceDystopiaGenerator.generate_track(sound_type_str)
		"SciFi":
			return SciFiPreviewGenerator.generate_preview(sound_type_str)
	
	var sound_type := _string_to_sound_type(sound_type_str)
	if sound_type != -1:
		return CustomSoundGenerator.generate_custom_sound(sound_type, merged_params)
	
	sound_type = _string_to_sound_type(sound_key)
	if sound_type != -1:
		return CustomSoundGenerator.generate_custom_sound(sound_type, merged_params)
	
	# Category fallbacks
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
		"experimental":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.APHEX_TWIN_MODULAR, merged_params)
		"tech_noir":
			return TechnoNoirGenerator.generate_sound(sound_type_str, merged_params)
		"trap_beats":
			return TrapBeatsGenerator.generate_sound(sound_type_str, merged_params)
		# Additional category fallbacks
		"basic":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.PICKUP_MARIO, merged_params)
		"cyber_jazz":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.NOIR_SAX, merged_params)
		"epic":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.CINEMATIC_STRINGS, merged_params)
		"fourier":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.MELODIC_DRONE, merged_params)
		"liturgical":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.CHOIR_PAD, merged_params)
		"pop_edm":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.SUPERSAW_PROGRESSIVE, merged_params)
		"songs":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.DETROIT_TECHNO, merged_params)
		"space_dystopia":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.BLADE_RUNNER_BRASS, merged_params)
		"space_pop":
			return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.SPACE_CHOIR_PAD, merged_params)

	print("AudioCatalogDesktop: Using fallback for '%s' (category: %s)" % [sound_key, category])
	return CustomSoundGenerator.generate_custom_sound(AudioSynthesizer.SoundType.MELODIC_DRONE, merged_params)


func _detect_generator_type(category: String, sound_key: String) -> String:
	var key_lower := sound_key.to_lower()
	
	match category:
		"tech_noir":
			return "TechnoNoir"
		"trap_beats":
			return "TrapBeats"
		"cinematic":
			return "Cinematic"
		"sci_fi":
			if key_lower.contains("drift") or key_lower.contains("noir") or key_lower.contains("neon"):
				return "SpaceDystopia"
			return "Default"

	if key_lower.begins_with("tech_noir") or key_lower.contains("industrial"):
		return "TechnoNoir"
	if key_lower.begins_with("trap") or (key_lower.contains("808") and not key_lower.contains("sub")):
		return "TrapBeats"
	if key_lower.begins_with("cinematic") or key_lower.contains("vangelis"):
		return "Cinematic"
	
	return "Default"


func _string_to_sound_type(type_str: String) -> int:
	var type_map := {
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
		"artifact_reveal_shimmer": AudioSynthesizer.SoundType.ARTIFACT_REVEAL_SHIMMER,
		"dark_808_kick": AudioSynthesizer.SoundType.DARK_808_KICK,
		"acid_606_hihat": AudioSynthesizer.SoundType.ACID_606_HIHAT,
		"dark_808_sub_bass": AudioSynthesizer.SoundType.DARK_808_SUB_BASS,
		"tr909_kick": AudioSynthesizer.SoundType.TR909_KICK,
		"synare_3_disco_tom": AudioSynthesizer.SoundType.SYNARE_3_DISCO_TOM,
		"synare_3_cosmic_fx": AudioSynthesizer.SoundType.SYNARE_3_COSMIC_FX,
		"ambient_amiga_drone": AudioSynthesizer.SoundType.AMBIENT_AMIGA_DRONE,
		"c64_sid_lead": AudioSynthesizer.SoundType.C64_SID_LEAD,
		"amiga_mod_sample": AudioSynthesizer.SoundType.AMIGA_MOD_SAMPLE,
		"moog_bass_lead": AudioSynthesizer.SoundType.MOOG_BASS_LEAD,
		"tb303_acid_bass": AudioSynthesizer.SoundType.TB303_ACID_BASS,
		"dx7_electric_piano": AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO,
		"ppg_wave_pad": AudioSynthesizer.SoundType.PPG_WAVE_PAD,
		"jupiter_8_strings": AudioSynthesizer.SoundType.JUPITER_8_STRINGS,
		"korg_m1_piano": AudioSynthesizer.SoundType.KORG_M1_PIANO,
		"arp_2600_lead": AudioSynthesizer.SoundType.ARP_2600_LEAD,
		"moog_kraftwerk_sequencer": AudioSynthesizer.SoundType.MOOG_KRAFTWERK_SEQUENCER,
		"herbie_hancock_moog_fusion": AudioSynthesizer.SoundType.HERBIE_HANCOCK_MOOG_FUSION,
		"aphex_twin_modular": AudioSynthesizer.SoundType.APHEX_TWIN_MODULAR,
		"flying_lotus_sampler": AudioSynthesizer.SoundType.FLYING_LOTUS_SAMPLER,
		"sci_fi_lab_hum_clean": AudioSynthesizer.SoundType.SCI_FI_LAB_HUM_CLEAN,
		"sci_fi_resonant_drone": AudioSynthesizer.SoundType.SCI_FI_RESONANT_DRONE,
		"sci_fi_data_chirps": AudioSynthesizer.SoundType.SCI_FI_DATA_CHIRPS,
		"sci_fi_ventilation": AudioSynthesizer.SoundType.SCI_FI_VENTILATION,
		"sci_fi_electromagnetic": AudioSynthesizer.SoundType.SCI_FI_ELECTROMAGNETIC,
		"lab_hum": AudioSynthesizer.SoundType.LAB_HUM,
		"cs80_brass_lead": AudioSynthesizer.SoundType.CS80_BRASS_LEAD,
		"cinematic_432hz_pad": AudioSynthesizer.SoundType.CINEMATIC_432HZ_PAD,
		"pop_juno_chorus_pad": AudioSynthesizer.SoundType.POP_JUNO_CHORUS_PAD,
		"pop_dx7_ballad_keys": AudioSynthesizer.SoundType.POP_DX7_BALLAD_KEYS,
		"pop_obxa_brass": AudioSynthesizer.SoundType.POP_OBXA_BRASS,
		"pop_prophet_lead": AudioSynthesizer.SoundType.POP_PROPHET_LEAD,
		"pop_funk_bass": AudioSynthesizer.SoundType.POP_FUNK_BASS,
		"heartbeat": AudioSynthesizer.SoundType.HEARTBEAT,
		"processed_vocal_pad": AudioSynthesizer.SoundType.PROCESSED_VOCAL_PAD,
		"industrial_anvil": AudioSynthesizer.SoundType.INDUSTRIAL_ANVIL,
		"trip_hop_beat": AudioSynthesizer.SoundType.TRIP_HOP_BEAT,
		"ethnic_tabla": AudioSynthesizer.SoundType.ETHNIC_TABLA,
		"gamelan_bell": AudioSynthesizer.SoundType.GAMELAN_BELL,
		"organ_swell": AudioSynthesizer.SoundType.ORGAN_SWELL,
		"noir_sax": AudioSynthesizer.SoundType.NOIR_SAX,
		"choir_pad": AudioSynthesizer.SoundType.CHOIR_PAD,
		"reversed_swell": AudioSynthesizer.SoundType.REVERSED_SWELL,
		"blade_runner_brass": AudioSynthesizer.SoundType.BLADE_RUNNER_BRASS,
		# Experimental / Algorithmic
		"radiophonic_workshop": AudioSynthesizer.SoundType.RADIOPHONIC_WORKSHOP,
		"xenakis_stochastic": AudioSynthesizer.SoundType.XENAKIS_STOCHASTIC,
		"spiegel_intelligent": AudioSynthesizer.SoundType.SPIEGEL_INTELLIGENT,
		"autechre_flutter": AudioSynthesizer.SoundType.AUTECHRE_FLUTTER,
		"ikeda_dataplex": AudioSynthesizer.SoundType.IKEDA_DATAPLEX,
		"eccojam_drift": AudioSynthesizer.SoundType.ECCOJAM_DRIFT,
		"cellular_automata": AudioSynthesizer.SoundType.CELLULAR_AUTOMATA,
		# Pop & EDM Genre-Defining
		"moroder_disco_bass": AudioSynthesizer.SoundType.MORODER_DISCO_BASS,
		"prophet_pad": AudioSynthesizer.SoundType.PROPHET_PAD,
		"prince_sync_lead": AudioSynthesizer.SoundType.PRINCE_SYNC_LEAD,
		"electro_808": AudioSynthesizer.SoundType.ELECTRO_808,
		"detroit_techno": AudioSynthesizer.SoundType.DETROIT_TECHNO,
		"house_organ": AudioSynthesizer.SoundType.HOUSE_ORGAN,
		"rave_stab": AudioSynthesizer.SoundType.RAVE_STAB,
		"supersaw_progressive": AudioSynthesizer.SoundType.SUPERSAW_PROGRESSIVE,
		"wobble_bass": AudioSynthesizer.SoundType.WOBBLE_BASS,
		"synthwave_lead": AudioSynthesizer.SoundType.SYNTHWAVE_LEAD,
		# Space Dystopia Soundscape Pop
		"space_choir_pad": AudioSynthesizer.SoundType.SPACE_CHOIR_PAD,
		"cinematic_strings": AudioSynthesizer.SoundType.CINEMATIC_STRINGS,
		"industrial_clank": AudioSynthesizer.SoundType.INDUSTRIAL_CLANK,
		"rain_atmosphere": AudioSynthesizer.SoundType.RAIN_ATMOSPHERE,
		"wavetable_morph": AudioSynthesizer.SoundType.WAVETABLE_MORPH,
		"pedal_steel_swell": AudioSynthesizer.SoundType.PEDAL_STEEL_SWELL,
		"glitch_chaos": AudioSynthesizer.SoundType.GLITCH_CHAOS,
		"noir_sax_breath": AudioSynthesizer.SoundType.NOIR_SAX_BREATH,
		"space_sub_drone": AudioSynthesizer.SoundType.SPACE_SUB_DRONE,
	}

	var key := type_str.to_lower().replace(" ", "_").replace("-", "_")
	if type_map.has(key):
		return type_map[key]
	
	# Pattern matching fallbacks
	if key.contains("kick"):
		return AudioSynthesizer.SoundType.DARK_808_KICK
	if key.contains("hihat") or key.contains("hat"):
		return AudioSynthesizer.SoundType.ACID_606_HIHAT
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

	return -1


func _merge_parameters(defaults: Dictionary, overrides: Dictionary) -> Dictionary:
	var result := {}

	for key in defaults:
		var raw_value: Variant = defaults[key]
		if raw_value is Dictionary:
			var config: Dictionary = raw_value
			if config.has("value"):
				result[key] = config.get("value")
			elif config.has("min"):
				result[key] = config.get("min", 0.0)
		elif raw_value is int or raw_value is float:
			result[key] = raw_value

	for key in overrides:
		result[key] = overrides[key]

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

	# Downsample for visualization
	var target_points := 512
	if samples.size() > target_points:
		var downsampled := PackedFloat32Array()
		var step_size := samples.size() / target_points
		for i in range(target_points):
			var idx := int(i * step_size)
			if idx < samples.size():
				downsampled.append(samples[idx])
		return downsampled

	return samples
