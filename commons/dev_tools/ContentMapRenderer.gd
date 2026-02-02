class_name ContentMapRenderer
extends Control

## Metro-style visual map of sequences for Content Validator
## Similar to SubwayMapRenderer but uses ContentValidator data

signal sequence_clicked(seq_name: String)
signal sequence_hovered(seq_name: String)

var _report: ContentValidator.ValidationReport = null
var _layout: Dictionary = {}  # seq_name -> Vector2
var _hovered: String = ""

const PHASE_COLORS := {
	"F_order": Color("#4A90D9"),
	"oscillation": Color("#9B59B6"),
	"E_entropy": Color("#E74C3C"),
	"lambda_edge": Color("#F39C12"),
	"integration": Color("#2ECC71"),
	"synthesis": Color("#E91E63")
}

const PHASE_ORDER := ["F_order", "oscillation", "E_entropy", "lambda_edge", "integration", "synthesis"]

@export var station_radius: float = 12.0
@export var spine_line_width: float = 6.0
@export var branch_line_width: float = 3.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS

func set_report(report: ContentValidator.ValidationReport):
	_report = report
	_calculate_layout()
	queue_redraw()

func _calculate_layout():
	_layout.clear()
	if not _report:
		return
	
	var margin := 60.0
	var usable_width := size.x - margin * 2
	var usable_height := size.y - margin * 2
	
	# Group spine sequences by phase
	var phase_sequences: Dictionary = {}
	for phase in PHASE_ORDER:
		phase_sequences[phase] = []
	
	for seq_name in _report.spine_order:
		if _report.sequences.has(seq_name):
			var seq = _report.sequences[seq_name] as ContentValidator.SequenceInfo
			var phase = seq.phase if seq.phase != "" else "F_order"
			if phase_sequences.has(phase):
				phase_sequences[phase].append(seq_name)
	
	# Calculate Y positions for phases
	var total_spine = _report.spine_order.size()
	var y_step = usable_height / max(total_spine - 1, 1)
	var current_y = margin
	var center_x = size.x / 2.0
	
	# Layout spine sequences vertically
	for seq_name in _report.spine_order:
		var seq = _report.sequences.get(seq_name) as ContentValidator.SequenceInfo
		if seq:
			var phase = seq.phase if seq.phase != "" else "F_order"
			var phase_idx = PHASE_ORDER.find(phase)
			var x_offset = (phase_idx - 2.5) * 15.0  # Slight horizontal offset per phase
			_layout[seq_name] = Vector2(center_x + x_offset, current_y)
			current_y += y_step
	
	# Layout branch sequences
	for spine_name in _report.branch_map.keys():
		if not _layout.has(spine_name):
			continue
		
		var spine_pos = _layout[spine_name]
		var branches = _report.branch_map[spine_name]
		
		for i in range(branches.size()):
			var branch_name = branches[i]
			if not _report.sequences.has(branch_name):
				continue
			
			# Alternate left/right
			var side = -1.0 if i % 2 == 0 else 1.0
			var x_offset = (80.0 + 40.0 * (i / 2)) * side
			var y_offset = 15.0 * (i / 2)
			
			_layout[branch_name] = spine_pos + Vector2(x_offset, y_offset)

func _draw():
	if not _report:
		draw_string(ThemeDB.fallback_font, Vector2(20, 30), "No data - click Refresh", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GRAY)
		return
	
	_draw_background()
	_draw_connections()
	_draw_stations()
	_draw_legend()

func _draw_background():
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.07, 1.0))

func _draw_connections():
	# Draw spine connections
	for i in range(_report.spine_order.size() - 1):
		var from_name = _report.spine_order[i]
		var to_name = _report.spine_order[i + 1]
		
		if _layout.has(from_name) and _layout.has(to_name):
			var from_pos = _layout[from_name]
			var to_pos = _layout[to_name]
			
			var to_seq = _report.sequences.get(to_name) as ContentValidator.SequenceInfo
			var color = PHASE_COLORS.get(to_seq.phase, Color.GRAY) if to_seq else Color.GRAY
			
			# Glow
			var glow = color
			glow.a = 0.3
			draw_line(from_pos, to_pos, glow, spine_line_width + 4, true)
			draw_line(from_pos, to_pos, color, spine_line_width, true)
	
	# Draw branch connections
	for spine_name in _report.branch_map.keys():
		if not _layout.has(spine_name):
			continue
		
		var spine_pos = _layout[spine_name]
		var spine_seq = _report.sequences.get(spine_name) as ContentValidator.SequenceInfo
		var color = PHASE_COLORS.get(spine_seq.phase, Color.GRAY) if spine_seq else Color.GRAY
		color = color.lerp(Color.WHITE, 0.3)
		
		for branch_name in _report.branch_map[spine_name]:
			if _layout.has(branch_name):
				var branch_pos = _layout[branch_name]
				_draw_dashed_line(spine_pos, branch_pos, color, branch_line_width)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float):
	var direction = (to - from).normalized()
	var length = from.distance_to(to)
	var dash_len = 8.0
	var gap_len = 5.0
	var pos = 0.0
	var drawing = true
	
	while pos < length:
		var step = dash_len if drawing else gap_len
		step = min(step, length - pos)
		
		if drawing:
			var p1 = from + direction * pos
			var p2 = from + direction * (pos + step)
			draw_line(p1, p2, color, width, true)
		
		pos += step
		drawing = not drawing

func _draw_stations():
	for seq_name in _layout.keys():
		var pos = _layout[seq_name]
		var seq = _report.sequences.get(seq_name) as ContentValidator.SequenceInfo
		if not seq:
			continue
		
		var is_spine = seq.is_spine
		var color = PHASE_COLORS.get(seq.phase, Color.GRAY)
		var radius = station_radius if is_spine else station_radius * 0.7
		var is_hovered = seq_name == _hovered
		
		if is_hovered:
			radius *= 1.4
			# Glow
			var glow = color
			glow.a = 0.5
			draw_circle(pos, radius * 1.5, glow)
		
		# Check status
		var has_issues = _sequence_has_issues(seq)
		var all_exist = _sequence_all_maps_exist(seq)
		
		if has_issues:
			# Red/orange for issues
			var issue_color = Color(0.9, 0.3, 0.2) if not all_exist else Color(0.9, 0.6, 0.2)
			draw_circle(pos, radius, issue_color)
			draw_arc(pos, radius, 0, TAU, 24, color, 2.0, true)
		elif all_exist and seq.maps.size() > 0:
			# Green checkmark for complete
			draw_circle(pos, radius, color)
			_draw_checkmark(pos, radius * 0.5)
		else:
			# Open circle for empty/partial
			draw_arc(pos, radius, 0, TAU, 24, color, 3.0 if is_spine else 2.0, true)
			if is_spine:
				draw_circle(pos, radius * 0.3, color)

func _draw_checkmark(pos: Vector2, s: float):
	var points: PackedVector2Array = [
		pos + Vector2(-s * 0.5, 0),
		pos + Vector2(-s * 0.15, s * 0.4),
		pos + Vector2(s * 0.5, -s * 0.4)
	]
	draw_polyline(points, Color.WHITE, 2.0, true)

func _draw_legend():
	var y = size.y - 25
	var items = [
		[Color(0.2, 0.8, 0.3), "✓ Complete"],
		[Color(0.9, 0.6, 0.2), "⚠ Warnings"],
		[Color(0.9, 0.3, 0.2), "❌ Missing"],
	]
	
	var x = 20.0
	for item in items:
		draw_circle(Vector2(x, y), 6, item[0])
		draw_string(ThemeDB.fallback_font, Vector2(x + 12, y + 5), item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)
		x += 100

func _sequence_has_issues(seq: ContentValidator.SequenceInfo) -> bool:
	for map_name in seq.maps:
		if seq.map_status.has(map_name):
			var mi = seq.map_status[map_name] as ContentValidator.MapInfo
			if not mi.exists:
				return true
			for art_key in mi.artifact_status.keys():
				var art = mi.artifact_status[art_key] as ContentValidator.ArtifactStatus
				if not art.in_registry or not art.scene_exists:
					return true
	return false

func _sequence_all_maps_exist(seq: ContentValidator.SequenceInfo) -> bool:
	if seq.maps.is_empty():
		return false
	for map_name in seq.maps:
		if seq.map_status.has(map_name):
			var mi = seq.map_status[map_name] as ContentValidator.MapInfo
			if not mi.exists:
				return false
	return true

func _gui_input(event: InputEvent):
	if event is InputEventMouseMotion:
		_handle_hover(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_hover(mouse_pos: Vector2):
	var closest = ""
	var closest_dist = station_radius * 2.5
	
	for seq_name in _layout.keys():
		var dist = mouse_pos.distance_to(_layout[seq_name])
		if dist < closest_dist:
			closest_dist = dist
			closest = seq_name
	
	if closest != _hovered:
		_hovered = closest
		if closest != "":
			sequence_hovered.emit(closest)
		queue_redraw()

func _handle_click(mouse_pos: Vector2):
	var closest = ""
	var closest_dist = station_radius * 2.5
	
	for seq_name in _layout.keys():
		var dist = mouse_pos.distance_to(_layout[seq_name])
		if dist < closest_dist:
			closest_dist = dist
			closest = seq_name
	
	if closest != "":
		sequence_clicked.emit(closest)

func _notification(what: int):
	if what == NOTIFICATION_RESIZED:
		_calculate_layout()
		queue_redraw()
