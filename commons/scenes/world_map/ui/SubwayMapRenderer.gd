# SubwayMapRenderer.gd
# Custom Control that draws the subway map using _draw()
# Renders metro lines, stations, and progressive reveal fog

extends Control
class_name SubwayMapRenderer

signal station_hovered(sequence_name: String)
signal station_clicked(sequence_name: String)

# Visual settings
@export var station_radius: float = 12.0
@export var line_width: float = 6.0
@export var fog_color: Color = Color(0.1, 0.1, 0.15, 0.9)
@export var pulse_speed: float = 2.0

# Data
var _sequences: Array[Dictionary] = []
var _connections: Array[Dictionary] = []
var _layout: Dictionary = {}  # sequence_name -> Vector2 position
var _current_sequence: String = ""
var _hovered_station: String = ""

# Animation
var _pulse_time: float = 0.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	_load_map_data()

func _load_map_data():
	_sequences = WorldMapDataProvider.get_visible_sequences()
	_connections = WorldMapDataProvider.get_sequence_connections()
	_layout = WorldMapDataProvider.calculate_subway_layout(size)
	_current_sequence = WorldMapDataProvider.get_current_sequence()
	queue_redraw()

func refresh():
	_load_map_data()

func _process(delta: float):
	_pulse_time += delta * pulse_speed
	queue_redraw()  # Animate pulse

func _draw():
	# 1. Draw fog overlay for unexplored areas
	_draw_fog_overlay()

	# 2. Draw metro lines (connections)
	_draw_metro_lines()

	# 3. Draw stations
	_draw_stations()

	# 4. Draw layer labels
	_draw_layer_labels()

	# 5. Draw current position pulse
	_draw_current_position()

func _draw_fog_overlay():
	# Draw semi-transparent overlay, then "cut out" visible areas
	# For now, just darken the background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.08, 1.0))

func _draw_metro_lines():
	for conn in _connections:
		if not conn.get("visible", false):
			continue

		var from_name: String = conn.get("from", "")
		var to_name: String = conn.get("to", "")

		if not _layout.has(from_name) or not _layout.has(to_name):
			continue

		var from_pos: Vector2 = _layout[from_name]
		var to_pos: Vector2 = _layout[to_name]

		# Get color from source sequence
		var from_seq = _find_sequence(from_name)
		var line_color: Color = from_seq.get("color", Color.GRAY) if from_seq else Color.GRAY

		# Dim locked connections
		var from_state = from_seq.get("state", WorldMapDataProvider.StationState.HIDDEN) if from_seq else WorldMapDataProvider.StationState.HIDDEN
		if from_state == WorldMapDataProvider.StationState.LOCKED:
			line_color = line_color.darkened(0.5)

		# Draw curved line (bezier for visual interest)
		_draw_metro_connection(from_pos, to_pos, line_color)

func _draw_metro_connection(from: Vector2, to: Vector2, color: Color):
	# Use straight lines with rounded corners for metro style
	var points: PackedVector2Array = []

	# If same layer (horizontal), draw straight
	if abs(from.y - to.y) < 20:
		points.append(from)
		points.append(to)
	else:
		# Staircase pattern for cross-layer connections
		var mid_x = (from.x + to.x) / 2
		points.append(from)
		points.append(Vector2(mid_x, from.y))
		points.append(Vector2(mid_x, to.y))
		points.append(to)

	# Draw thick line with antialiasing
	if points.size() >= 2:
		draw_polyline(points, color, line_width, true)

func _draw_stations():
	for seq in _sequences:
		var seq_name: String = seq.get("name", "")
		if not _layout.has(seq_name):
			continue

		var pos: Vector2 = _layout[seq_name]
		var state: int = seq.get("state", WorldMapDataProvider.StationState.HIDDEN)
		var color: Color = seq.get("color", Color.GRAY)

		_draw_station(pos, state, color, seq_name == _hovered_station)

func _draw_station(pos: Vector2, state: int, color: Color, is_hovered: bool):
	var radius := station_radius
	if is_hovered:
		radius *= 1.3

	match state:
		WorldMapDataProvider.StationState.COMPLETED:
			# Filled circle with checkmark ring
			draw_circle(pos, radius, color)
			draw_arc(pos, radius * 0.7, 0, TAU, 24, Color.WHITE, 2.0, true)
			# Draw checkmark
			_draw_checkmark(pos, radius * 0.5)

		WorldMapDataProvider.StationState.UNLOCKED:
			# Open circle (ring)
			draw_arc(pos, radius, 0, TAU, 24, color, 3.0, true)
			# Inner dot
			draw_circle(pos, radius * 0.3, color)

		WorldMapDataProvider.StationState.LOCKED:
			# Grayed out circle
			var locked_color = Color(0.4, 0.4, 0.45, 0.7)
			draw_circle(pos, radius * 0.8, locked_color)

func _draw_checkmark(pos: Vector2, size_factor: float):
	var check_color = Color.WHITE
	var points: PackedVector2Array = [
		pos + Vector2(-size_factor * 0.5, 0),
		pos + Vector2(-size_factor * 0.1, size_factor * 0.4),
		pos + Vector2(size_factor * 0.5, -size_factor * 0.4)
	]
	draw_polyline(points, check_color, 2.0, true)

func _draw_layer_labels():
	var layers = WorldMapDataProvider.LAYER_ORDER
	var margin := 40.0
	var layer_height := (size.y - margin * 2) / float(layers.size())

	for i in range(layers.size()):
		var layer_name: String = layers[i]
		var y := margin + layer_height * (i + 0.5)
		var color: Color = WorldMapDataProvider.LINE_COLORS.get(layer_name, Color.WHITE)

		# Draw layer name on left
		var label_pos = Vector2(margin, y + 8)
		draw_string(ThemeDB.fallback_font, label_pos, layer_name.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, color)

func _draw_current_position():
	if _current_sequence.is_empty() or not _layout.has(_current_sequence):
		return

	var pos: Vector2 = _layout[_current_sequence]

	# Pulsing ring
	var pulse = 0.5 + 0.5 * sin(_pulse_time * TAU)
	var pulse_radius = station_radius * (1.5 + pulse * 0.5)
	var pulse_alpha = 0.8 - pulse * 0.6

	var pulse_color = Color(1.0, 1.0, 1.0, pulse_alpha)
	draw_arc(pos, pulse_radius, 0, TAU, 32, pulse_color, 2.0, true)

# Input handling
func _gui_input(event: InputEvent):
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_mouse_motion(mouse_pos: Vector2):
	var closest_station := ""
	var closest_dist := station_radius * 2.0  # Hit detection radius

	for seq in _sequences:
		var seq_name: String = seq.get("name", "")
		if not _layout.has(seq_name):
			continue

		var pos: Vector2 = _layout[seq_name]
		var dist := mouse_pos.distance_to(pos)

		if dist < closest_dist:
			closest_dist = dist
			closest_station = seq_name

	if closest_station != _hovered_station:
		_hovered_station = closest_station
		if not closest_station.is_empty():
			station_hovered.emit(closest_station)
		queue_redraw()

func _handle_click(mouse_pos: Vector2):
	var closest_station := ""
	var closest_dist := station_radius * 2.0

	for seq in _sequences:
		var seq_name: String = seq.get("name", "")
		if not _layout.has(seq_name):
			continue

		var pos: Vector2 = _layout[seq_name]
		var dist := mouse_pos.distance_to(pos)

		if dist < closest_dist:
			closest_dist = dist
			closest_station = seq_name

	if not closest_station.is_empty():
		station_clicked.emit(closest_station)

# Helper to find sequence by name
func _find_sequence(name: String) -> Dictionary:
	for seq in _sequences:
		if seq.get("name", "") == name:
			return seq
	return {}

# Called when control is resized
func _notification(what: int):
	if what == NOTIFICATION_RESIZED:
		_layout = WorldMapDataProvider.calculate_subway_layout(size)
		queue_redraw()
