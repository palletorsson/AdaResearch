# SubwayMapRenderer.gd
# Custom Control that draws the subway map using _draw()
# Renders spine (thick) + branches (dashed), stations, and QFEP phase coloring

extends Control
class_name SubwayMapRenderer

signal station_hovered(sequence_name: String)
signal station_clicked(sequence_name: String)

# Visual settings
@export var spine_station_radius: float = 16.0
@export var branch_station_radius: float = 10.0
@export var spine_line_width: float = 8.0
@export var branch_line_width: float = 4.0
@export var fog_color: Color = Color(0.1, 0.1, 0.15, 0.9)
@export var pulse_speed: float = 2.0
@export var recommended_glow_color: Color = Color(1.0, 0.9, 0.4, 0.8)

# Data
var _sequences: Array[Dictionary] = []
var _connections: Array[Dictionary] = []
var _layout: Dictionary = {}  # sequence_name -> Vector2 position
var _current_sequence: String = ""
var _next_recommended: String = ""
var _hovered_station: String = ""

# Animation
var _pulse_time: float = 0.0
var _glow_time: float = 0.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	_load_map_data()

func _load_map_data():
	_sequences = WorldMapDataProvider.get_visible_sequences()
	_connections = WorldMapDataProvider.get_sequence_connections()
	_layout = WorldMapDataProvider.calculate_subway_layout(size)
	_current_sequence = WorldMapDataProvider.get_current_sequence()
	_next_recommended = WorldMapDataProvider.get_next_spine_sequence()
	queue_redraw()

func refresh():
	_load_map_data()

func _process(delta: float):
	_pulse_time += delta * pulse_speed
	_glow_time += delta * 1.5
	queue_redraw()  # Animate pulse

func _draw():
	# 1. Draw background
	_draw_background()
	
	# 2. Draw phase bands (subtle background coloring)
	_draw_phase_bands()
	
	# 3. Draw metro lines (spine thick, branches dashed)
	_draw_metro_lines()
	
	# 4. Draw stations
	_draw_stations()
	
	# 5. Draw phase labels
	_draw_phase_labels()
	
	# 6. Draw current position pulse
	_draw_current_position()
	
	# 7. Draw recommended indicator
	_draw_recommended_indicator()

func _draw_background():
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.08, 1.0))

func _draw_phase_bands():
	# Draw subtle vertical bands for each phase
	var phases = WorldMapDataProvider.PHASE_ORDER
	var margin := 80.0
	var usable_height := size.y - margin * 2
	
	# Group spine sequences by phase to find Y ranges
	var spine_seqs = WorldMapDataProvider.get_spine_sequences()
	var phase_ranges: Dictionary = {}  # phase -> {min_y, max_y}
	
	for seq in spine_seqs:
		var seq_name: String = seq.get("name", "")
		var phase: String = seq.get("phase", "F_order")
		
		if _layout.has(seq_name):
			var y: float = _layout[seq_name].y
			if not phase_ranges.has(phase):
				phase_ranges[phase] = {"min_y": y, "max_y": y}
			else:
				phase_ranges[phase]["min_y"] = min(phase_ranges[phase]["min_y"], y)
				phase_ranges[phase]["max_y"] = max(phase_ranges[phase]["max_y"], y)
	
	# Draw bands
	for phase in phases:
		if not phase_ranges.has(phase):
			continue
		
		var base_color: Color = WorldMapDataProvider.PHASE_COLORS.get(phase, Color.WHITE)
		var band_color = base_color.darkened(0.85)
		band_color.a = 0.3
		
		var min_y: float = phase_ranges[phase]["min_y"] - 30
		var max_y: float = phase_ranges[phase]["max_y"] + 30
		
		draw_rect(Rect2(0, min_y, size.x, max_y - min_y), band_color)

func _draw_metro_lines():
	# Draw branch lines first (behind spine)
	for conn in _connections:
		if conn.get("type", "") == "branch":
			_draw_connection(conn)
	
	# Draw spine lines on top
	for conn in _connections:
		if conn.get("type", "") == "spine":
			_draw_connection(conn)

func _draw_connection(conn: Dictionary):
	if not conn.get("visible", false):
		return
	
	var from_name: String = conn.get("from", "")
	var to_name: String = conn.get("to", "")
	
	if not _layout.has(from_name) or not _layout.has(to_name):
		return
	
	var from_pos: Vector2 = _layout[from_name]
	var to_pos: Vector2 = _layout[to_name]
	
	var line_color: Color = conn.get("color", Color.GRAY)
	var is_spine: bool = conn.get("type", "") == "spine"
	var width: float = spine_line_width if is_spine else branch_line_width
	
	# Check if connection involves locked sequences
	var from_seq = _find_sequence(from_name)
	var to_seq = _find_sequence(to_name)
	var from_state = from_seq.get("state", WorldMapDataProvider.StationState.HIDDEN) if from_seq else WorldMapDataProvider.StationState.HIDDEN
	var to_state = to_seq.get("state", WorldMapDataProvider.StationState.HIDDEN) if to_seq else WorldMapDataProvider.StationState.HIDDEN
	
	# Dim if either end is locked
	if from_state == WorldMapDataProvider.StationState.LOCKED or to_state == WorldMapDataProvider.StationState.LOCKED:
		line_color = line_color.darkened(0.5)
		line_color.a = 0.6
	
	if is_spine:
		_draw_spine_line(from_pos, to_pos, line_color, width)
	else:
		_draw_branch_line(from_pos, to_pos, line_color, width)

func _draw_spine_line(from: Vector2, to: Vector2, color: Color, width: float):
	# Solid thick line with metro-style routing
	var points := _get_metro_path(from, to)
	
	if points.size() >= 2:
		# Draw glow behind for emphasis
		var glow_color = color
		glow_color.a = 0.3
		draw_polyline(points, glow_color, width + 4, true)
		
		# Main line
		draw_polyline(points, color, width, true)

func _draw_branch_line(from: Vector2, to: Vector2, color: Color, width: float):
	# Dashed line
	var points := _get_metro_path(from, to)
	
	if points.size() >= 2:
		_draw_dashed_polyline(points, color, width, 12.0, 8.0)

func _draw_dashed_polyline(points: PackedVector2Array, color: Color, width: float, dash_length: float, gap_length: float):
	# Convert polyline to individual dashed segments
	var total_length := 0.0
	var segment_lengths: Array[float] = []
	
	for i in range(points.size() - 1):
		var seg_len = points[i].distance_to(points[i + 1])
		segment_lengths.append(seg_len)
		total_length += seg_len
	
	var current_dist := 0.0
	var drawing := true
	var pattern_pos := 0.0
	
	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i + 1]
		var seg_length = segment_lengths[i]
		var direction = (end - start).normalized()
		
		var seg_start := 0.0
		while seg_start < seg_length:
			var pattern_remaining = (dash_length if drawing else gap_length) - pattern_pos
			var seg_remaining = seg_length - seg_start
			var step = min(pattern_remaining, seg_remaining)
			
			if drawing:
				var p1 = start + direction * seg_start
				var p2 = start + direction * (seg_start + step)
				draw_line(p1, p2, color, width, true)
			
			seg_start += step
			pattern_pos += step
			
			if pattern_pos >= (dash_length if drawing else gap_length):
				pattern_pos = 0.0
				drawing = not drawing

func _get_metro_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = []
	
	# Metro style: horizontal then vertical (or vice versa)
	if abs(from.y - to.y) < 20:
		# Roughly same level: straight line
		points.append(from)
		points.append(to)
	elif abs(from.x - to.x) < 20:
		# Roughly same column: straight line
		points.append(from)
		points.append(to)
	else:
		# L-shaped or staircase
		var mid_y = (from.y + to.y) / 2
		points.append(from)
		points.append(Vector2(from.x, mid_y))
		points.append(Vector2(to.x, mid_y))
		points.append(to)
	
	return points

func _draw_stations():
	# Draw branch stations first (behind spine)
	for seq in _sequences:
		if not seq.get("is_spine", false):
			_draw_station_for_sequence(seq)
	
	# Draw spine stations on top
	for seq in _sequences:
		if seq.get("is_spine", false):
			_draw_station_for_sequence(seq)

func _draw_station_for_sequence(seq: Dictionary):
	var seq_name: String = seq.get("name", "")
	if not _layout.has(seq_name):
		return
	
	var pos: Vector2 = _layout[seq_name]
	var state: int = seq.get("state", WorldMapDataProvider.StationState.HIDDEN)
	var color: Color = seq.get("color", Color.GRAY)
	var is_spine: bool = seq.get("is_spine", false)
	var is_hovered: bool = seq_name == _hovered_station
	var is_recommended: bool = seq_name == _next_recommended
	
	var radius := spine_station_radius if is_spine else branch_station_radius
	if is_hovered:
		radius *= 1.3
	
	_draw_station(pos, state, color, is_spine, is_hovered, is_recommended, radius)

func _draw_station(pos: Vector2, state: int, color: Color, is_spine: bool, is_hovered: bool, is_recommended: bool, radius: float):
	# Draw glow for recommended
	if is_recommended:
		var glow_pulse = 0.5 + 0.5 * sin(_glow_time * TAU)
		var glow_radius = radius * (1.8 + glow_pulse * 0.4)
		var glow_alpha = 0.6 - glow_pulse * 0.3
		var glow_color = recommended_glow_color
		glow_color.a = glow_alpha
		draw_circle(pos, glow_radius, glow_color)
	
	match state:
		WorldMapDataProvider.StationState.COMPLETED:
			# Filled circle with checkmark
			draw_circle(pos, radius, color)
			if is_spine:
				# White ring for spine
				draw_arc(pos, radius * 0.7, 0, TAU, 24, Color.WHITE, 2.0, true)
			_draw_checkmark(pos, radius * 0.5)
		
		WorldMapDataProvider.StationState.UNLOCKED:
			if is_spine:
				# Large open circle for spine
				draw_arc(pos, radius, 0, TAU, 32, color, 4.0, true)
				draw_circle(pos, radius * 0.35, color)
			else:
				# Smaller diamond for branch
				_draw_diamond(pos, radius * 0.8, color, false)
		
		WorldMapDataProvider.StationState.LOCKED:
			var locked_color = Color(0.4, 0.4, 0.45, 0.6)
			if is_spine:
				# Grayed circle
				draw_circle(pos, radius * 0.7, locked_color)
			else:
				# Grayed diamond
				_draw_diamond(pos, radius * 0.6, locked_color, true)

func _draw_checkmark(pos: Vector2, size_factor: float):
	var check_color = Color.WHITE
	var points: PackedVector2Array = [
		pos + Vector2(-size_factor * 0.5, 0),
		pos + Vector2(-size_factor * 0.1, size_factor * 0.4),
		pos + Vector2(size_factor * 0.5, -size_factor * 0.4)
	]
	draw_polyline(points, check_color, 2.5, true)

func _draw_diamond(pos: Vector2, size_val: float, color: Color, filled: bool):
	var points: PackedVector2Array = [
		pos + Vector2(0, -size_val),
		pos + Vector2(size_val, 0),
		pos + Vector2(0, size_val),
		pos + Vector2(-size_val, 0),
		pos + Vector2(0, -size_val)  # Close the shape
	]
	
	if filled:
		draw_colored_polygon(points, color)
	else:
		draw_polyline(points, color, 2.5, true)

func _draw_phase_labels():
	var phases = WorldMapDataProvider.get_all_phases()
	var margin := 20.0
	
	# Find Y positions for each phase from spine sequences
	var spine_seqs = WorldMapDataProvider.get_spine_sequences()
	var phase_y: Dictionary = {}
	
	for seq in spine_seqs:
		var seq_name: String = seq.get("name", "")
		var phase: String = seq.get("phase", "F_order")
		
		if _layout.has(seq_name) and not phase_y.has(phase):
			phase_y[phase] = _layout[seq_name].y
	
	# Draw phase labels on the left
	for phase_info in phases:
		var phase_name: String = phase_info.get("name", "")
		var phase_key := ""
		
		# Find the key from the name
		for key in WorldMapDataProvider.PHASE_ORDER:
			var info = WorldMapDataProvider.get_phase_info(key)
			if info.get("name", "") == phase_name:
				phase_key = key
				break
		
		if phase_key.is_empty() or not phase_y.has(phase_key):
			continue
		
		var y: float = phase_y[phase_key]
		var color: Color = phase_info.get("color", Color.WHITE)
		
		# Draw phase indicator line
		draw_line(Vector2(margin, y), Vector2(margin + 30, y), color, 3.0, true)
		
		# Draw phase name (rotated would be nice, but use horizontal for now)
		var label_pos = Vector2(margin + 5, y - 25)
		draw_string(ThemeDB.fallback_font, label_pos, phase_name, HORIZONTAL_ALIGNMENT_LEFT, 120, 18, color)

func _draw_current_position():
	if _current_sequence.is_empty() or not _layout.has(_current_sequence):
		return
	
	var pos: Vector2 = _layout[_current_sequence]
	
	# Pulsing ring
	var pulse = 0.5 + 0.5 * sin(_pulse_time * TAU)
	var pulse_radius = spine_station_radius * (1.8 + pulse * 0.5)
	var pulse_alpha = 0.9 - pulse * 0.6
	
	var pulse_color = Color(1.0, 1.0, 1.0, pulse_alpha)
	draw_arc(pos, pulse_radius, 0, TAU, 32, pulse_color, 2.5, true)

func _draw_recommended_indicator():
	if _next_recommended.is_empty() or not _layout.has(_next_recommended):
		return
	
	if _next_recommended == _current_sequence:
		return  # Don't double-indicate
	
	var pos: Vector2 = _layout[_next_recommended]
	
	# Draw "NEXT" label above
	var label_pos = pos + Vector2(-20, -spine_station_radius - 20)
	var label_color = recommended_glow_color
	label_color.a = 0.7 + 0.3 * sin(_glow_time * TAU)
	
	draw_string(ThemeDB.fallback_font, label_pos, "NEXT", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, label_color)

# Input handling
func _gui_input(event: InputEvent):
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_mouse_motion(mouse_pos: Vector2):
	var closest_station := ""
	var closest_dist := spine_station_radius * 2.5  # Hit detection radius
	
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
	var closest_dist := spine_station_radius * 2.5
	
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
