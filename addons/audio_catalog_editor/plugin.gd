@tool
extends EditorPlugin

var dock_instance: Control
var sequencer_dock_instance: Control

func _enter_tree():
	# Add catalog dock as main screen
	var dock_scene = preload("res://addons/audio_catalog_editor/audio_catalog_dock.tscn")
	dock_instance = dock_scene.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(dock_instance)
	_make_visible(false)
	
	# Add sequencer as a dock
	var sequencer_script = load("res://addons/audio_catalog_editor/audio_sequencer_dock.gd")
	sequencer_dock_instance = sequencer_script.new()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, sequencer_dock_instance)
	
	print("Audio Catalog Editor plugin loaded")

func _exit_tree():
	if dock_instance:
		dock_instance.queue_free()
		dock_instance = null
	if sequencer_dock_instance:
		remove_control_from_docks(sequencer_dock_instance)
		sequencer_dock_instance.queue_free()
		sequencer_dock_instance = null
	print("Audio Catalog Editor plugin unloaded")

func _has_main_screen():
	return true

func _make_visible(visible: bool):
	if dock_instance:
		dock_instance.visible = visible

func _get_plugin_name():
	return "Audio Catalog"

func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("AudioStreamPlayer", "EditorIcons")
