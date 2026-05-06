@tool
extends EditorPlugin

var main_screen_instance: Control
var tab_container: TabContainer
var catalog_scene: PackedScene
var sequencer_scene: PackedScene
var soundtracks_scene: PackedScene
var current_dock: Control

func _enter_tree():
	# Create main screen container
	main_screen_instance = Control.new()
	main_screen_instance.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Create tab container - like Inspector tabs
	tab_container = TabContainer.new()
	tab_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_screen_instance.add_child(tab_container)
	
	# Load all scene files
	catalog_scene = preload("res://addons/audio_catalog_editor/audio_catalog_dock.tscn")
	sequencer_scene = preload("res://addons/audio_catalog_editor/audio_sequencer_dock.tscn")
	soundtracks_scene = preload("res://addons/audio_catalog_editor/soundtracks_dock.tscn")
	
	# Create container for Audio Preset tab
	var preset_container = Control.new()
	preset_container.name = "Audio Preset"
	preset_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_container.add_child(preset_container)
	
	# Create container for Sequencer tab
	var sequencer_container = Control.new()
	sequencer_container.name = "Sequencer"
	sequencer_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_container.add_child(sequencer_container)

	# Create container for Soundtracks tab
	var soundtracks_container = Control.new()
	soundtracks_container.name = "Soundtracks"
	soundtracks_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_container.add_child(soundtracks_container)
	
	# Load initial tab (Audio Preset)
	_switch_to_tab(0)

	# Connect to tab changed signal
	tab_container.tab_changed.connect(_on_tab_changed)

	# Add to main screen
	get_editor_interface().get_editor_main_screen().add_child(main_screen_instance)
	_make_visible(false)
	
	print("Audio Catalog Editor plugin loaded (tab view with scene switching)")

func _on_tab_changed(tab: int) -> void:
	_switch_to_tab(tab)

func _switch_to_tab(tab: int) -> void:
	if not tab_container or tab < 0 or tab >= tab_container.get_child_count():
		return
	
	# Remove current dock if it exists
	if current_dock:
		current_dock.queue_free()
		current_dock = null
	
	# Get the container for this tab
	var container = tab_container.get_child(tab)
	if not container:
		return
	
	# Clear any existing children in the container
	for child in container.get_children():
		child.queue_free()
	
	# Load and instantiate the appropriate scene
	var scene_to_load: PackedScene = null
	match tab:
		0:  # Audio Preset tab
			scene_to_load = catalog_scene
		1:  # Sequencer tab
			scene_to_load = sequencer_scene
		2:  # Soundtracks tab
			scene_to_load = soundtracks_scene
	
	if scene_to_load:
		current_dock = scene_to_load.instantiate()
		current_dock.set_anchors_preset(Control.PRESET_FULL_RECT)
		current_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		current_dock.size_flags_vertical = Control.SIZE_EXPAND_FILL
		container.add_child(current_dock)

func _exit_tree():
	if current_dock:
		current_dock.queue_free()
		current_dock = null
	if main_screen_instance:
		main_screen_instance.queue_free()
		main_screen_instance = null
	print("Audio Catalog Editor plugin unloaded")

func _has_main_screen():
	return true

func _make_visible(visible: bool):
	if main_screen_instance:
		main_screen_instance.visible = visible

func _get_plugin_name():
	return "Audio Catalog"

func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("AudioStreamPlayer", "EditorIcons")
