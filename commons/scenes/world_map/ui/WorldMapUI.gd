# WorldMapUI.gd
# Main UI controller for the world map
# Handles panning, tooltips, and info panel display

extends Control
class_name WorldMapUI

signal sequence_selected(sequence_name: String)

@onready var subway_map: SubwayMapRenderer = $SubwayMapRenderer
@onready var tooltip: PanelContainer = $Tooltip
@onready var tooltip_title: Label = $Tooltip/VBox/Title
@onready var tooltip_desc: Label = $Tooltip/VBox/Description
@onready var tooltip_progress: Label = $Tooltip/VBox/Progress
@onready var legend: VBoxContainer = $Legend
@onready var stats_label: Label = $StatsLabel

var _is_dragging := false
var _drag_start := Vector2.ZERO
var _pan_offset := Vector2.ZERO

func _ready():
	# Connect signals
	subway_map.station_hovered.connect(_on_station_hovered)
	subway_map.station_clicked.connect(_on_station_clicked)

	# Connect to progression updates
	if MapProgressionManager:
		MapProgressionManager.map_completed.connect(_on_map_completed)
		MapProgressionManager.sequence_completed.connect(_on_sequence_completed)

	# Initialize UI
	tooltip.visible = false
	_build_legend()
	_update_stats()

func _build_legend():
	# Clear existing legend items
	for child in legend.get_children():
		child.queue_free()

	# Add title
	var title = Label.new()
	title.text = "METRO LINES"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	legend.add_child(title)

	# Add legend items for each layer
	for layer_name in WorldMapDataProvider.LAYER_ORDER:
		var info = WorldMapDataProvider.get_layer_info(layer_name)
		if info.is_empty():
			continue

		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS

		# Color swatch
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(32, 32)
		swatch.color = info.get("color", Color.GRAY)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(swatch)

		# Layer name
		var label = Label.new()
		label.text = "  " + layer_name.capitalize()
		label.add_theme_font_size_override("font_size", 22)
		hbox.add_child(label)

		legend.add_child(hbox)

func _update_stats():
	var stats = WorldMapDataProvider.get_progress_stats()
	stats_label.text = "Progress: %d/%d sequences (%.0f%%)" % [
		stats.get("completed", 0),
		stats.get("total_sequences", 0),
		stats.get("completion_percentage", 0)
	]

func _on_station_hovered(sequence_name: String):
	if sequence_name.is_empty():
		tooltip.visible = false
		return

	var seq_data = _get_sequence_info(sequence_name)
	if seq_data.is_empty():
		tooltip.visible = false
		return

	# Update tooltip content
	tooltip_title.text = seq_data.get("display_name", sequence_name)

	var state: int = seq_data.get("state", WorldMapDataProvider.StationState.HIDDEN)
	var state_text := ""
	match state:
		WorldMapDataProvider.StationState.COMPLETED:
			state_text = "COMPLETED"
		WorldMapDataProvider.StationState.UNLOCKED:
			state_text = "AVAILABLE"
		WorldMapDataProvider.StationState.LOCKED:
			state_text = "LOCKED"

	var maps = seq_data.get("maps", [])
	tooltip_desc.text = "%s | %d maps" % [state_text, maps.size()]

	var completion_pct: float = seq_data.get("completion_pct", 0.0)
	tooltip_progress.text = "%.0f%% complete" % completion_pct

	# Position tooltip near mouse
	var mouse_pos = get_global_mouse_position()
	tooltip.global_position = mouse_pos + Vector2(20, 10)

	# Keep tooltip on screen
	var viewport_size = get_viewport_rect().size
	if tooltip.global_position.x + tooltip.size.x > viewport_size.x:
		tooltip.global_position.x = mouse_pos.x - tooltip.size.x - 10
	if tooltip.global_position.y + tooltip.size.y > viewport_size.y:
		tooltip.global_position.y = mouse_pos.y - tooltip.size.y - 10

	tooltip.visible = true

func _on_station_clicked(sequence_name: String):
	var seq_data = _get_sequence_info(sequence_name)
	if seq_data.is_empty():
		return

	var state: int = seq_data.get("state", WorldMapDataProvider.StationState.HIDDEN)

	# Only emit signal for unlocked or completed sequences
	if state == WorldMapDataProvider.StationState.UNLOCKED or state == WorldMapDataProvider.StationState.COMPLETED:
		sequence_selected.emit(sequence_name)

func _get_sequence_info(sequence_name: String) -> Dictionary:
	var sequences = WorldMapDataProvider.get_visible_sequences()
	for seq in sequences:
		if seq.get("name", "") == sequence_name:
			return seq
	return {}

func _on_map_completed(_map_name: String):
	# Refresh the map display
	subway_map.refresh()
	_update_stats()

func _on_sequence_completed(_sequence_name: String):
	subway_map.refresh()
	_update_stats()

# Panning support (optional, for larger maps)
func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_dragging = event.pressed
			if event.pressed:
				_drag_start = event.position

	elif event is InputEventMouseMotion and _is_dragging:
		var delta = event.position - _drag_start
		_pan_offset += delta
		_drag_start = event.position
		# Apply pan offset to subway map position
		subway_map.position = _pan_offset

func _input(event: InputEvent):
	# Hide tooltip when mouse leaves the control
	if event is InputEventMouseMotion:
		if not get_global_rect().has_point(event.global_position):
			tooltip.visible = false
