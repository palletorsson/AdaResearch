# WorldMapOverview3D.gd
# 3D handheld tablet showing the world map via SubViewport
# Uses XR Tools viewport_2d_in_3d for VR interaction

extends Node3D
class_name WorldMapOverview3D

signal sequence_selected(sequence_name: String)

@export var screen_width: float = 1.4   # Physical screen width in meters
@export var screen_height: float = 1.0  # Physical screen height in meters
@export var viewport_width: int = 1600
@export var viewport_height: int = 1200
@export var auto_start_sequence_on_select: bool = true
@export var show_full_map: bool = false

@onready var _viewport_2d_in_3d: Node3D = $Viewport2Din3D
@onready var frame_mesh: MeshInstance3D = $Frame

var _world_map_ui: WorldMapUI
var _connect_attempts: int = 0
const MAX_UI_CONNECT_ATTEMPTS: int = 120


func _ready():
	# Defer UI connection to ensure the viewport_2d_in_3d scene is ready
	call_deferred("_connect_ui_signals")


func _connect_ui_signals():
	if _world_map_ui:
		return

	_connect_attempts += 1

	# Get the UI scene instance from the viewport_2d_in_3d
	if _viewport_2d_in_3d and _viewport_2d_in_3d.has_method("get_scene_instance"):
		_world_map_ui = _viewport_2d_in_3d.get_scene_instance() as WorldMapUI

	if _world_map_ui == null:
		# Try direct viewport access as fallback
		var viewport = _viewport_2d_in_3d.get_node_or_null("Viewport")
		if viewport and viewport.get_child_count() > 0:
			_world_map_ui = viewport.get_child(0) as WorldMapUI

	if _world_map_ui:
		_world_map_ui.set_show_full_map(show_full_map)
		if not _world_map_ui.sequence_selected.is_connected(_on_sequence_selected):
			_world_map_ui.sequence_selected.connect(_on_sequence_selected)
	else:
		if _connect_attempts < MAX_UI_CONNECT_ATTEMPTS:
			# out-of-tree guard: get_tree() is null once a map is torn down
			if not is_inside_tree():
				return
			var tree: SceneTree = get_tree()
			if tree:
				tree.process_frame.connect(_connect_ui_signals, CONNECT_ONE_SHOT)
			else:
				call_deferred("_connect_ui_signals")
		else:
			push_warning("WorldMapOverview3D: Could not find WorldMapUI instance after %d attempts" % _connect_attempts)


func _on_sequence_selected(sequence_name: String):
	sequence_selected.emit(sequence_name)
	if auto_start_sequence_on_select:
		var scene_manager = get_node_or_null("/root/SceneManager")
		if scene_manager and scene_manager.has_method("start_sequence"):
			scene_manager.start_sequence(sequence_name)
		else:
			push_warning("WorldMapOverview3D: SceneManager not found; could not start sequence '%s'" % sequence_name)


# Refresh the map data (call when progression changes)
func refresh():
	if _world_map_ui:
		_world_map_ui.refresh()
	else:
		_connect_ui_signals()

func set_show_full_map(enabled: bool) -> void:
	show_full_map = enabled
	if _world_map_ui:
		_world_map_ui.set_show_full_map(enabled)
