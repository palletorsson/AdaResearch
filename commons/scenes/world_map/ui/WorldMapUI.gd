# WorldMapUI.gd
# Main UI controller for the world map
# Handles panning, tooltips, and info panel display with QFEP spine awareness

extends Control
class_name WorldMapUI

signal sequence_selected(sequence_name: String)

@export var show_full_map: bool = false

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
	_apply_map_mode()
	
	# Connect to progression updates
	if MapProgressionManager:
		MapProgressionManager.map_completed.connect(_on_map_completed)
		MapProgressionManager.sequence_completed.connect(_on_sequence_completed)
	
	# Initialize UI
	tooltip.visible = false
	_build_legend()
	_update_stats()

func _apply_map_mode() -> void:
	if subway_map:
		subway_map.set_show_full_map(show_full_map)

func set_show_full_map(enabled: bool) -> void:
	show_full_map = enabled
	_apply_map_mode()
	_update_stats()

func refresh() -> void:
	if subway_map:
		subway_map.refresh()
	_update_stats()

func _build_legend():
	# Clear existing legend items
	for child in legend.get_children():
		child.queue_free()
	
	# Add title
	var title = Label.new()
	title.text = "QFEP PHASES"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	legend.add_child(title)
	
	# Add separator
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	legend.add_child(sep)
	
	# Add legend items for each QFEP phase
	var phases = WorldMapDataProvider.get_all_phases()
	for phase in phases:
		var phase_name: String = phase.get("name", "")
		var phase_color: Color = phase.get("color", Color.WHITE)
		
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Color swatch (circle)
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(24, 24)
		swatch.color = phase_color
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(swatch)
		
		# Phase name
		var label = Label.new()
		label.text = "  " + phase_name
		label.add_theme_font_size_override("font_size", 20)
		hbox.add_child(label)
		
		legend.add_child(hbox)
	
	# Add spine/branch legend
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	legend.add_child(spacer)
	
	var type_title = Label.new()
	type_title.text = "PATHS"
	type_title.add_theme_font_size_override("font_size", 20)
	type_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	legend.add_child(type_title)
	
	# Spine indicator
	var spine_hbox = HBoxContainer.new()
	var spine_line = ColorRect.new()
	spine_line.custom_minimum_size = Vector2(32, 8)
	spine_line.color = Color.WHITE
	spine_hbox.add_child(spine_line)
	var spine_label = Label.new()
	spine_label.text = "  Main Path"
	spine_label.add_theme_font_size_override("font_size", 18)
	spine_hbox.add_child(spine_label)
	legend.add_child(spine_hbox)
	
	# Branch indicator
	var branch_hbox = HBoxContainer.new()
	var branch_container = Control.new()
	branch_container.custom_minimum_size = Vector2(32, 8)
	branch_hbox.add_child(branch_container)
	# We can't easily draw dashed in Control, so just use description
	var branch_label = Label.new()
	branch_label.text = "  - - Optional"
	branch_label.add_theme_font_size_override("font_size", 18)
	branch_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	branch_hbox.add_child(branch_label)
	legend.add_child(branch_hbox)

func _update_stats():
	var stats = WorldMapDataProvider.get_progress_stats()
	
	var spine_completed: int = stats.get("spine_completed", 0)
	var spine_total: int = stats.get("spine_total", 0)
	var branch_completed: int = stats.get("branch_completed", 0)
	var branch_total: int = stats.get("branch_total", 0)
	var next_rec: String = stats.get("next_recommended", "")
	
	var text := "Main: %d/%d | Optional: %d/%d" % [spine_completed, spine_total, branch_completed, branch_total]
	
	if not next_rec.is_empty():
		text += "\nNext: " + next_rec.capitalize().replace("_", " ")
	
	stats_label.text = text

func _on_station_hovered(sequence_name: String):
	if sequence_name.is_empty():
		tooltip.visible = false
		return
	
	var seq_data = _get_sequence_info(sequence_name)
	if seq_data.is_empty():
		tooltip.visible = false
		return
	
	# Update tooltip content
	var display_name: String = seq_data.get("display_name", sequence_name)
	var is_spine: bool = seq_data.get("is_spine", false)
	var type_tag := " [MAIN]" if is_spine else " [optional]"
	
	tooltip_title.text = display_name + type_tag
	
	var state: int = seq_data.get("state", WorldMapDataProvider.StationState.HIDDEN)
	var state_text := ""
	match state:
		WorldMapDataProvider.StationState.COMPLETED:
			state_text = "✓ COMPLETED"
		WorldMapDataProvider.StationState.UNLOCKED:
			state_text = "▶ AVAILABLE"
		WorldMapDataProvider.StationState.LOCKED:
			state_text = "🔒 LOCKED"
	
	# Add QFEP role if available
	var qfep_role: String = seq_data.get("qfep_role", "")
	var maps = seq_data.get("maps", [])
	
	if qfep_role.is_empty():
		tooltip_desc.text = "%s | %d maps" % [state_text, maps.size()]
	else:
		tooltip_desc.text = "%s | %d maps\n%s" % [state_text, maps.size(), qfep_role]
	
	var completion_pct: float = seq_data.get("completion_pct", 0.0)
	tooltip_progress.text = "%.0f%% complete" % completion_pct
	if state == WorldMapDataProvider.StationState.UNLOCKED or state == WorldMapDataProvider.StationState.COMPLETED:
		var hold_seconds := subway_map.hold_time_required if subway_map else 3.0
		tooltip_progress.text += " | Hold %.1fs to enter" % hold_seconds
	
	# Show next recommended hint
	var next_rec = WorldMapDataProvider.get_next_spine_sequence()
	if sequence_name == next_rec:
		tooltip_progress.text += " — RECOMMENDED"
	
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
	var sequences: Array[Dictionary] = []
	if subway_map and subway_map.show_full_map:
		sequences = WorldMapDataProvider.get_all_sequences_with_states(true)
	else:
		sequences = WorldMapDataProvider.get_visible_sequences()

	for seq in sequences:
		if seq.get("name", "") == sequence_name:
			return seq
	return {}

func _on_map_completed(_map_name: String):
	# Refresh the map display
	refresh()

func _on_sequence_completed(_sequence_name: String):
	refresh()

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
