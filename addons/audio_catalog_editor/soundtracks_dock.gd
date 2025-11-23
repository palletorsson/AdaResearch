@tool
extends Control

const PRESETS_DIR := "res://commons/audio/presets/"
const MANIFEST_PATH := "res://commons/audio/presets_manifest.json"
const SyntheticSoundGenerator := preload("res://commons/audio/runtime/SyntheticSoundGenerator.gd")
const TechnoNoirGenerator := preload("res://commons/audio/generators/TechnoNoirGenerator.gd")
const TrapBeatsGenerator := preload("res://commons/audio/generators/TrapBeatsGenerator.gd")
const CinematicMusicGenerator := preload("res://commons/audio/generators/CinematicMusicGenerator.gd")

var preset_tree: Tree
var details_container: VBoxContainer
var title_label: Label
var description_label: RichTextLabel
var layers_tree: Tree
var audio_player: AudioStreamPlayer
var active_players: Array[AudioStreamPlayer] = []

var presets_data: Dictionary = {}
var current_preset_id: String = ""

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	_build_ui()
	_load_presets()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var main_split = HSplitContainer.new()
	main_split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_split)

	# Left Panel - Preset List
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(250, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_split.add_child(left_panel)

	var list_label = Label.new()
	list_label.text = "Soundtracks / Presets"
	left_panel.add_child(list_label)

	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh Presets"
	refresh_btn.pressed.connect(_load_presets)
	left_panel.add_child(refresh_btn)

	preset_tree = Tree.new()
	preset_tree.custom_minimum_size = Vector2(0, 600)
	preset_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preset_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_tree.hide_root = true
	preset_tree.item_selected.connect(_on_preset_selected)
	left_panel.add_child(preset_tree)

	# Right Panel - Details
	details_container = VBoxContainer.new()
	details_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.add_child(details_container)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	details_container.add_child(title_label)
	
	# Playback Controls
	var playback_hbox = HBoxContainer.new()
	details_container.add_child(playback_hbox)
	
	var play_all_btn = Button.new()
	play_all_btn.text = "▶ Play Full Soundtrack"
	play_all_btn.pressed.connect(_on_play_soundtrack_pressed)
	playback_hbox.add_child(play_all_btn)
	
	var stop_all_btn = Button.new()
	stop_all_btn.text = "⏹ Stop All"
	stop_all_btn.pressed.connect(_stop_all_sounds)
	playback_hbox.add_child(stop_all_btn)

	description_label = RichTextLabel.new()
	description_label.fit_content = true
	description_label.bbcode_enabled = true
	details_container.add_child(description_label)

	var layers_label = Label.new()
	layers_label.text = "Composition (Double-click to preview layer)"
	details_container.add_child(layers_label)

	layers_tree = Tree.new()
	layers_tree.custom_minimum_size = Vector2(0, 200)
	layers_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layers_tree.columns = 3
	layers_tree.set_column_title(0, "Type")
	layers_tree.set_column_title(1, "Sound ID")
	layers_tree.set_column_title(2, "Volume / Info")
	layers_tree.set_column_titles_visible(true)
	layers_tree.item_activated.connect(_on_layer_activated) # Double click
	details_container.add_child(layers_tree)

	# Audio Player (for single previews)
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

func _load_presets() -> void:
	preset_tree.clear()
	var root = preset_tree.create_item()
	presets_data.clear()
	
	# 1. Load Manifest
	var manifest_file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if not manifest_file:
		push_error("Could not open " + MANIFEST_PATH)
		return
		
	var json = JSON.new()
	var error = json.parse(manifest_file.get_as_text())
	manifest_file.close()
	
	if error != OK:
		push_error("JSON Parse Error in manifest: " + json.get_error_message())
		return
		
	var manifest_data = json.data
	if not "presets" in manifest_data:
		return
		
	var preset_list = manifest_data["presets"]
	print("Loading ", preset_list.size(), " presets from manifest...")
	
	# 2. Load Each Preset
	for preset_id in preset_list:
		var path = PRESETS_DIR + preset_id + ".json"
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var p_json = JSON.new()
			if p_json.parse(file.get_as_text()) == OK:
				presets_data[preset_id] = p_json.data
				
				# Add to tree
				var item = preset_tree.create_item(root)
				item.set_text(0, preset_id)
				item.set_metadata(0, preset_id)
			file.close()
			
	print("Loaded ", presets_data.size(), " presets successfully.")

func _on_preset_selected() -> void:
	var item = preset_tree.get_selected()
	if not item:
		return
	
	var preset_id = item.get_metadata(0)
	_display_preset(preset_id)

func _display_preset(preset_id: String) -> void:
	current_preset_id = preset_id
	var preset = presets_data[preset_id]
	
	title_label.text = preset_id
	description_label.text = preset.get("description", "No description")
	
	layers_tree.clear()
	var root = layers_tree.create_item()
	
	# Continuous Layers
	if "continuous_layers" in preset:
		var cat = layers_tree.create_item(root)
		cat.set_text(0, "Continuous Layers")
		cat.set_selectable(0, false)
		
		for layer in preset["continuous_layers"]:
			var item = layers_tree.create_item(cat)
			item.set_text(0, "Layer")
			item.set_text(1, layer.get("sound_id", "???"))
			item.set_text(2, "%s dB" % layer.get("volume_db", 0))
			item.set_metadata(0, layer)
			item.add_button(2, get_theme_icon("Play", "EditorIcons"), 0, false, "Play")

	# Random Events
	if "random_events" in preset:
		var cat = layers_tree.create_item(root)
		cat.set_text(0, "Random Events")
		cat.set_selectable(0, false)
		
		for event in preset["random_events"]:
			var pool = event.get("sound_pool", [])
			for sound_id in pool:
				var item = layers_tree.create_item(cat)
				item.set_text(0, "Event")
				item.set_text(1, sound_id)
				item.set_text(2, "Interval: %s" % str(event.get("interval_range", "?")))
				item.set_metadata(0, {"sound_id": sound_id}) # Mock layer object for playback
				item.add_button(2, get_theme_icon("Play", "EditorIcons"), 0, false, "Play")

func _on_layer_activated() -> void:
	var item = layers_tree.get_selected()
	if not item:
		return
	_play_layer_item(item)

func _play_layer_item(item: TreeItem) -> void:
	var data = item.get_metadata(0)
	if not data or not "sound_id" in data:
		return
		
	var sound_id = data["sound_id"]
	_play_sound(sound_id)

func _on_play_soundtrack_pressed() -> void:
	_stop_all_sounds()
	
	if current_preset_id == "" or not current_preset_id in presets_data:
		return
		
	var preset = presets_data[current_preset_id]
	if not "continuous_layers" in preset:
		return
		
	for layer in preset["continuous_layers"]:
		var sound_id = layer.get("sound_id", "")
		var volume_db = layer.get("volume_db", 0)
		var stream = _generate_stream_from_id(sound_id)
		
		if stream:
			var player = AudioStreamPlayer.new()
			add_child(player)
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			active_players.append(player)
			player.finished.connect(func(): 
				player.play() # Loop it
			)

func _stop_all_sounds() -> void:
	if audio_player.playing:
		audio_player.stop()
		
	for player in active_players:
		player.stop()
		player.queue_free()
	active_players.clear()

func _play_sound(sound_id: String) -> void:
	_stop_all_sounds()
	var stream = _generate_stream_from_id(sound_id)
	
	if stream:
		audio_player.stream = stream
		audio_player.play()
	else:
		push_warning("Could not generate stream for " + sound_id)

func _generate_stream_from_id(sound_id: String) -> AudioStreamWAV:
	var parts = sound_id.split(".")
	if parts.size() < 2:
		push_warning("Invalid sound ID format: " + sound_id)
		return null
		
	var generator_name = parts[0]
	var sound_name = parts[1]
	
	match generator_name:
		"AudioSynthesizer":
			var type = _string_to_sound_type(sound_name)
			if type != null:
				return AudioSynthesizer.generate_sound(type)
			else:
				push_warning("Unknown AudioSynthesizer sound: " + sound_name)
		"SyntheticSoundGenerator":
			# Default params for preview
			return SyntheticSoundGenerator.create_ambient_sound(0.4, 0.7) if sound_name == "ambient_sound" else SyntheticSoundGenerator.create_detection_sound(0.4, 0.7)
		"techno_noir":
			return TechnoNoirGenerator.generate_sound(sound_name)
		"trap_beats":
			return TrapBeatsGenerator.generate_sound(sound_name)
		"Cinematic":
			return CinematicMusicGenerator.generate_sound(sound_name)
		"DarkGameTrack":
			# Placeholder as logic is not easily accessible
			return null
			
	return null

func _string_to_sound_type(sound_name: String):
	# Dynamic lookup
	if sound_name in AudioSynthesizer.SoundType:
		return AudioSynthesizer.SoundType[sound_name]

	# Aliases
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
		_: return null

func _notification(what):
	if what == NOTIFICATION_THEME_CHANGED:
		if layers_tree:
			pass
	elif what == NOTIFICATION_PREDELETE:
		_stop_all_sounds()
