## ScreenOverlay — draws dynamic data (grid lines, trail, dots, particles) on top of the layout panels.
## Lives inside GridPanel in screen_layout.tscn. Gets its rect from the parent PanelContainer.
## The ScienceScreen sets `screen_ref` after instantiating the layout.
extends Control

var screen_ref: Node  # ScienceScreen — set by parent after instantiation

# Instrument colors (must match screen_theme.tres / web palette)
const I_GRID_MINOR := Color(0.13, 0.77, 0.37, 0.25)
const I_GRID_MAJOR := Color(0.13, 0.77, 0.37, 0.5)
const I_AXIS_X := Color(0.973, 0.443, 0.443)
const I_AXIS_Y := Color(0.29, 0.87, 0.50)
const I_DOT := Color(0.655, 0.545, 0.98)
const I_CYAN := Color(0.404, 0.91, 0.976)
const I_AMBER := Color(0.961, 0.62, 0.043)
const I_TEXT := Color(0.94, 0.94, 0.96)
const I_DIM := Color(0.545, 0.584, 0.647)
const I_MUTED := Color(0.333, 0.376, 0.44)
const I_CORNER := 10.0


func _draw() -> void:
	if not screen_ref:
		_draw_static_grid(2.0)
		return

	# Determine mode and grid range
	if screen_ref._point_mode:
		_draw_static_grid(2.0)
		_draw_point_data()
	elif screen_ref._line_mode:
		_draw_static_grid(2.5)
		_draw_line_data()
	elif screen_ref._draw_mode:
		_draw_trace_data()
	else:
		_draw_static_grid(2.0)


# ═══════════════════════════════════════════════════════════════════
# STATIC GRID — green lines, axes, corner brackets, tick labels
# ═══════════════════════════════════════════════════════════════════

func _draw_static_grid(grid_range: float) -> void:
	var r: Rect2 = get_rect()
	var s: float = minf(r.size.x, r.size.y) - 8  # slight padding
	var ox: float = (r.size.x - s) * 0.5
	var oy: float = (r.size.y - s) * 0.5
	var cx: float = ox + s * 0.5
	var cy: float = oy + s * 0.5
	var font: Font = ThemeDB.fallback_font

	# Minor grid (10 divisions)
	var step: float = s / 10.0
	for i in range(1, 10):
		var p: float = float(i) * step
		draw_line(Vector2(ox + p, oy), Vector2(ox + p, oy + s), I_GRID_MINOR, 0.5)
		draw_line(Vector2(ox, oy + p), Vector2(ox + s, oy + p), I_GRID_MINOR, 0.5)

	# Quarter lines (brighter)
	for frac in [0.25, 0.75]:
		draw_line(Vector2(ox + s * frac, oy), Vector2(ox + s * frac, oy + s), I_GRID_MAJOR, 0.5)
		draw_line(Vector2(ox, oy + s * frac), Vector2(ox + s, oy + s * frac), I_GRID_MAJOR, 0.5)

	# Axes
	draw_line(Vector2(ox, cy), Vector2(ox + s, cy), I_AXIS_X, 1.0)
	draw_line(Vector2(cx, oy), Vector2(cx, oy + s), I_AXIS_Y, 1.0)

	# Corner brackets
	var L: float = I_CORNER
	var c: Color = I_MUTED
	draw_line(Vector2(ox, oy + L), Vector2(ox, oy), c, 1.0)
	draw_line(Vector2(ox, oy), Vector2(ox + L, oy), c, 1.0)
	draw_line(Vector2(ox + s - L, oy), Vector2(ox + s, oy), c, 1.0)
	draw_line(Vector2(ox + s, oy), Vector2(ox + s, oy + L), c, 1.0)
	draw_line(Vector2(ox, oy + s - L), Vector2(ox, oy + s), c, 1.0)
	draw_line(Vector2(ox, oy + s), Vector2(ox + L, oy + s), c, 1.0)
	draw_line(Vector2(ox + s - L, oy + s), Vector2(ox + s, oy + s), c, 1.0)
	draw_line(Vector2(ox + s, oy + s), Vector2(ox + s, oy + s - L), c, 1.0)

	# Axis labels
	draw_string(font, Vector2(ox + s + 4, cy + 4), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, I_AXIS_X)
	draw_string(font, Vector2(cx - 3, oy - 4), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, I_AXIS_Y)

	# Scale ticks
	var rl: String = "%.1f" % grid_range
	draw_string(font, Vector2(ox - 2, cy + 13), "-%s" % rl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, I_DIM)
	draw_string(font, Vector2(ox + s - 16, cy + 13), rl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, I_DIM)
	draw_string(font, Vector2(cx + 4, oy + 10), rl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, I_DIM)
	draw_string(font, Vector2(cx + 4, oy + s - 2), "-%s" % rl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, I_DIM)


# ═══════════════════════════════════════════════════════════════════
# GRID METRICS — shared positioning helper
# ═══════════════════════════════════════════════════════════════════

func _grid_metrics() -> Dictionary:
	var r: Rect2 = get_rect()
	var s: float = minf(r.size.x, r.size.y) - 8
	var ox: float = (r.size.x - s) * 0.5
	var oy: float = (r.size.y - s) * 0.5
	return {"ox": ox, "oy": oy, "side": s, "cx": ox + s * 0.5, "cy": oy + s * 0.5}


func _w2s(pos: Vector3, cx: float, cy: float, side: float, grid_range: float) -> Vector2:
	# Negate X for screen facing player at 180 degrees
	return Vector2(
		cx - (pos.x / grid_range) * (side * 0.5),
		cy - (pos.y / grid_range) * (side * 0.5)
	)


# ═══════════════════════════════════════════════════════════════════
# POINT MODE — trail, target, projections, dot
# ═══════════════════════════════════════════════════════════════════

func _draw_point_data() -> void:
	if not screen_ref:
		return
	var g: Dictionary = _grid_metrics()
	var cx: float = g["cx"]; var cy: float = g["cy"]; var side: float = g["side"]
	var grid_range: float = 2.0

	var pos: Vector3 = Vector3.ZERO
	if is_instance_valid(screen_ref._tracking_point):
		pos = screen_ref._tracking_point.global_position - screen_ref._point_origin

	var dot_pos: Vector2 = _w2s(pos, cx, cy, side, grid_range)

	# Trail
	if screen_ref._point_trail.size() > 1:
		var n: int = screen_ref._point_trail.size()
		for i in range(n - 1):
			var t0: Vector3 = screen_ref._point_trail[i]
			var t1: Vector3 = screen_ref._point_trail[i + 1]
			var s0: Vector2 = _w2s(t0, cx, cy, side, grid_range)
			var s1: Vector2 = _w2s(t1, cx, cy, side, grid_range)
			var t: float = float(i) / float(n)
			draw_line(s0, s1, Color(I_DOT, 0.1 + t * 0.6), 1.0 + t * 1.5)

	# Target
	if not screen_ref._point_exploding and screen_ref._point_target != Vector3.ZERO:
		var tgt_pos: Vector2 = _w2s(screen_ref._point_target, cx, cy, side, grid_range)
		var pulse: float = sin(Time.get_ticks_msec() / 300.0) * 2.0
		var tgt_col: Color = screen_ref._point_target_color
		draw_circle(tgt_pos, 14.0 + pulse, Color(tgt_col, 0.12))
		draw_circle(tgt_pos, 8.0, Color(tgt_col, 0.25))
		draw_circle(tgt_pos, 2.5, tgt_col)
		# Crosshair
		draw_line(Vector2(tgt_pos.x - 18, tgt_pos.y), Vector2(tgt_pos.x + 18, tgt_pos.y), Color(tgt_col, 0.1), 0.5)
		draw_line(Vector2(tgt_pos.x, tgt_pos.y - 18), Vector2(tgt_pos.x, tgt_pos.y + 18), Color(tgt_col, 0.1), 0.5)
		draw_line(dot_pos, tgt_pos, Color(tgt_col, 0.1), 1.0)

	# Particles
	for p_data in screen_ref._point_particles:
		var p_pos: Vector2 = _w2s(p_data["pos"], cx, cy, side, grid_range)
		draw_circle(p_pos, 2.5, Color(p_data["color"], clampf(p_data["life"] * 2.0, 0.0, 1.0)))

	# Projections
	draw_line(dot_pos, Vector2(dot_pos.x, cy), Color(I_AXIS_X, 0.15), 1.0)
	draw_line(dot_pos, Vector2(cx, dot_pos.y), Color(I_AXIS_Y, 0.15), 1.0)
	draw_circle(Vector2(dot_pos.x, cy), 2.0, I_AXIS_X)
	draw_circle(Vector2(cx, dot_pos.y), 2.0, I_AXIS_Y)

	# Point dot
	draw_circle(dot_pos, 12.0, Color(I_DOT, 0.1))
	draw_circle(dot_pos, 8.0, Color(I_DOT, 0.3))
	draw_circle(dot_pos, 5.0, I_DOT)
	draw_circle(Vector2(dot_pos.x - 1.5, dot_pos.y - 1.5), 1.5, Color(1, 1, 1, 0.3))

	# Inline coordinate label
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(dot_pos.x + 10, dot_pos.y - 4), "(%.2f, %.2f)" % [pos.x, pos.y], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, I_DIM)


# ═══════════════════════════════════════════════════════════════════
# LINE MODE — AB line, endpoints, projections, midpoint
# ═══════════════════════════════════════════════════════════════════

func _draw_line_data() -> void:
	if not screen_ref:
		return
	var g: Dictionary = _grid_metrics()
	var cx: float = g["cx"]; var cy: float = g["cy"]; var side: float = g["side"]
	var grid_range: float = 2.5

	var pos_a: Vector3 = Vector3.ZERO
	var pos_b: Vector3 = Vector3(0.5, 0.3, 0)
	if is_instance_valid(screen_ref._tracking_line_p1):
		pos_a = screen_ref._tracking_line_p1.global_position - screen_ref._line_origin
	if is_instance_valid(screen_ref._tracking_line_p2):
		pos_b = screen_ref._tracking_line_p2.global_position - screen_ref._line_origin

	var sa: Vector2 = _w2s(pos_a, cx, cy, side, grid_range)
	var sb: Vector2 = _w2s(pos_b, cx, cy, side, grid_range)

	# Projections
	draw_line(Vector2(sa.x, sa.y), Vector2(sa.x, cy), Color(I_AXIS_X, 0.12), 1.0)
	draw_line(Vector2(sa.x, sa.y), Vector2(cx, sa.y), Color(I_AXIS_Y, 0.12), 1.0)
	draw_line(Vector2(sb.x, sb.y), Vector2(sb.x, cy), Color(I_AXIS_X, 0.12), 1.0)
	draw_line(Vector2(sb.x, sb.y), Vector2(cx, sb.y), Color(I_AXIS_Y, 0.12), 1.0)

	# Line AB (violet with glow)
	draw_line(sa, sb, Color(I_DOT, 0.15), 6.0)
	draw_line(sa, sb, I_DOT, 2.0)

	# Midpoint
	var mid: Vector2 = (sa + sb) * 0.5
	draw_circle(mid, 3.0, Color(I_DOT, 0.5))
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(mid.x + 6, mid.y - 4), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, I_DIM)

	# Endpoint A (cyan)
	draw_circle(sa, 10.0, Color(I_CYAN, 0.12))
	draw_circle(sa, 6.0, Color(I_CYAN, 0.35))
	draw_circle(sa, 3.5, I_CYAN)
	draw_string(font, Vector2(sa.x + 8, sa.y - 6), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_CYAN)

	# Endpoint B (amber)
	draw_circle(sb, 10.0, Color(I_AMBER, 0.12))
	draw_circle(sb, 6.0, Color(I_AMBER, 0.35))
	draw_circle(sb, 3.5, I_AMBER)
	draw_string(font, Vector2(sb.x + 8, sb.y - 6), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_AMBER)


# ═══════════════════════════════════════════════════════════════════
# TRACE MODE — draw dot trail with auto-zoom
# ═══════════════════════════════════════════════════════════════════

func _draw_trace_data() -> void:
	var r: Rect2 = get_rect()
	var font: Font = ThemeDB.fallback_font
	var draw_node: Node3D = null
	if screen_ref and is_instance_valid(screen_ref._tracking_draw_dot):
		draw_node = screen_ref._tracking_draw_dot

	# Get trail points
	var trail_points: Array = []
	if draw_node:
		if "_trail_points" in draw_node:
			trail_points = draw_node.get("_trail_points")
		elif "trail_points" in draw_node:
			trail_points = draw_node.get("trail_points")
		if trail_points.size() == 0:
			trail_points = [draw_node.global_position]

	# Bounding box
	var min_x: float = 99999.0; var max_x: float = -99999.0
	var min_y: float = 99999.0; var max_y: float = -99999.0
	var total_length: float = 0.0
	for i in range(trail_points.size()):
		var tp: Vector3 = trail_points[i] if trail_points[i] is Vector3 else Vector3.ZERO
		min_x = minf(min_x, tp.x); max_x = maxf(max_x, tp.x)
		min_y = minf(min_y, tp.y); max_y = maxf(max_y, tp.y)
		if i > 0:
			var prev: Vector3 = trail_points[i - 1] if trail_points[i - 1] is Vector3 else Vector3.ZERO
			total_length += Vector2(tp.x - prev.x, tp.y - prev.y).length()

	var center_x: float = (min_x + max_x) * 0.5
	var center_y: float = (min_y + max_y) * 0.5
	var span: float = maxf(max_x - min_x, max_y - min_y)
	var grid_range: float = maxf(span * 0.575, 0.3)

	# Use full overlay area
	var draw_s: float = minf(r.size.x, r.size.y) - 8
	var draw_cx: float = r.size.x * 0.5
	var draw_cy: float = r.size.y * 0.5

	# Grid lines
	var grid_step: float = 0.1 if grid_range < 0.5 else (0.25 if grid_range < 1.5 else 0.5)
	var grid_count: int = int(ceil(grid_range / grid_step))
	for gi in range(-grid_count, grid_count + 1):
		var gv: float = gi * grid_step
		var px: float = draw_cx + (gv / grid_range) * draw_s * 0.5
		var py: float = draw_cy - (gv / grid_range) * draw_s * 0.5
		var lc: Color = I_GRID_MAJOR if gi == 0 else I_GRID_MINOR
		var lw: float = 1.5 if gi == 0 else 0.5
		if px > 4 and px < r.size.x - 4:
			draw_line(Vector2(px, 0), Vector2(px, r.size.y), lc, lw)
		if py > 4 and py < r.size.y - 4:
			draw_line(Vector2(0, py), Vector2(r.size.x, py), lc, lw)

	# Trail
	if trail_points.size() > 1:
		var n: int = trail_points.size()
		for i in range(n - 1):
			var p0: Vector3 = trail_points[i] if trail_points[i] is Vector3 else Vector3.ZERO
			var p1: Vector3 = trail_points[i + 1] if trail_points[i + 1] is Vector3 else Vector3.ZERO
			var s0: Vector2 = Vector2(draw_cx + ((p0.x - center_x) / grid_range) * draw_s * 0.5, draw_cy - ((p0.y - center_y) / grid_range) * draw_s * 0.5)
			var s1: Vector2 = Vector2(draw_cx + ((p1.x - center_x) / grid_range) * draw_s * 0.5, draw_cy - ((p1.y - center_y) / grid_range) * draw_s * 0.5)
			var t: float = float(i) / float(n)
			draw_line(s0, s1, Color(I_DOT, 0.15 + 0.85 * t), 1.5 + 4.5 * t)

	# Current dot
	var cur_pos: Vector3 = draw_node.global_position if draw_node else Vector3.ZERO
	var cur_scr: Vector2 = Vector2(draw_cx + ((cur_pos.x - center_x) / grid_range) * draw_s * 0.5, draw_cy - ((cur_pos.y - center_y) / grid_range) * draw_s * 0.5)
	draw_circle(cur_scr, 12.0, Color(I_DOT, 0.12))
	draw_circle(cur_scr, 8.0, Color(I_DOT, 0.3))
	draw_circle(cur_scr, 4.0, Color(0.72, 0.53, 1.0))
