extends Control

# Turret-Boll Vector Relationship - Static canvas showing all operations

func _ready():
	queue_redraw()

func _draw():
	var w = size.x
	var h = size.y
	
	# Scale factor based on viewport (designed for 800x800)
	var scale = min(w, h) / 800.0
	
	# Solid dark background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.07, 1.0))
	
	# Subtle grid
	_draw_grid(w, h)
	
	# Center of canvas
	var center = Vector2(w * 0.5, h * 0.4)
	
	# Positions scaled to canvas
	var turret_pos = center + Vector2(-120, 80) * scale
	var ball_pos = center + Vector2(150, -60) * scale
	
	# Title
	_draw_text(Vector2(w/2, 50 * scale), "TURRET → BOLL", Color(0.4, 1.0, 0.5), int(36 * scale), true)
	_draw_text(Vector2(w/2, 90 * scale), "Vector Operations", Color(0.5, 0.7, 0.55), int(20 * scale), true)
	
	# === Vectors ===
	var to_ball = ball_pos - turret_pos
	var to_ball_norm = to_ball.normalized()
	var dist = to_ball.length()
	
	# Range circle
	var range_radius = 220.0 * scale
	draw_arc(turret_pos, range_radius, 0, TAU, 64, Color(0.3, 0.8, 0.4, 0.25), 2.0 * scale)
	
	# Draw turret & ball
	_draw_turret(turret_pos, to_ball.angle(), scale)
	_draw_ball(ball_pos, 22 * scale)
	
	# Labels
	_draw_text(turret_pos + Vector2(-60, 70) * scale, "TURRET", Color(0.5, 0.6, 0.7), int(18 * scale))
	_draw_text(ball_pos + Vector2(40, -15) * scale, "BOLL", Color(1.0, 0.5, 0.3), int(18 * scale))
	
	# === 1. SUBTRACT ===
	var sub_color = Color(0.2, 1.0, 0.4)
	_draw_arrow(turret_pos, ball_pos, sub_color, 3.0 * scale)
	var sub_label = turret_pos + to_ball * 0.5 + Vector2(-100, -35) * scale
	_draw_text(sub_label, "① SUBTRACT", sub_color, int(20 * scale))
	_draw_text(sub_label + Vector2(0, 24) * scale, "to_target = ball - turret", sub_color.darkened(0.15), int(14 * scale))
	
	# === 2. MAGNITUDE ===
	var mag_color = Color(1.0, 0.8, 0.2)
	var mag_y = turret_pos.y + 45 * scale
	draw_line(Vector2(turret_pos.x, mag_y), Vector2(ball_pos.x, mag_y), mag_color, 2.0 * scale)
	draw_line(Vector2(turret_pos.x, mag_y), Vector2(turret_pos.x, mag_y - 10 * scale), mag_color, 2.0 * scale)
	draw_line(Vector2(ball_pos.x, mag_y), Vector2(ball_pos.x, mag_y - 10 * scale), mag_color, 2.0 * scale)
	_draw_text(Vector2((turret_pos.x + ball_pos.x)/2, mag_y + 18 * scale), "② MAGNITUDE", mag_color, int(14 * scale), true)
	
	# === 3. NORMALIZE ===
	var norm_color = Color(0.3, 0.7, 1.0)
	var unit_len = 50.0 * scale
	var norm_start = turret_pos + Vector2(0, -35) * scale
	var norm_end = norm_start + to_ball_norm * unit_len
	_draw_arrow(norm_start, norm_end, norm_color, 2.5 * scale)
	draw_arc(norm_start, unit_len, 0, TAU, 32, Color(norm_color.r, norm_color.g, norm_color.b, 0.2), 1.5 * scale)
	_draw_text(norm_start + Vector2(-70, -45) * scale, "③ NORMALIZE", norm_color, int(14 * scale))
	
	# === 4. DOT PRODUCT ===
	var dot_color = Color(1.0, 0.35, 0.55)
	var arc_radius = 70.0 * scale
	var arc_start = to_ball.angle()
	var test_angle = arc_start - 0.4
	draw_arc(turret_pos, arc_radius, test_angle, arc_start, 12, dot_color, 3.0 * scale)
	var dot_label = turret_pos + Vector2(90, 70) * scale
	_draw_text(dot_label, "④ DOT", dot_color, int(14 * scale))
	
	# === 5. PROJECT ===
	var proj_color = Color(0.9, 0.4, 1.0)
	var ball_vel = Vector2(-40, 28) * scale
	var predicted_pos = ball_pos + ball_vel * 0.9
	_draw_arrow(ball_pos, ball_pos + ball_vel, Color(0.5, 0.5, 0.9), 2.0 * scale)
	draw_arc(predicted_pos, 22 * scale, 0, TAU, 24, Color(proj_color.r, proj_color.g, proj_color.b, 0.35), 2.0 * scale)
	var proj_label = ball_pos + Vector2(60, 50) * scale
	_draw_text(proj_label, "⑤ PROJECT", proj_color, int(14 * scale))
	
	# === LASER ===
	_draw_laser(turret_pos, ball_pos, scale)
	
	# === Code Summary ===
	var code_y = h - 220 * scale
	var code_color = Color(0.4, 0.9, 0.5)
	var code_bg = Color(0.04, 0.05, 0.06, 0.9)
	var code_margin = 30 * scale
	draw_rect(Rect2(code_margin, code_y - 10 * scale, w - code_margin * 2, 200 * scale), code_bg)
	
	var line_h = 24 * scale
	var code_x = code_margin + 15 * scale
	var fs = int(13 * scale)
	
	_draw_text(Vector2(code_x, code_y + line_h * 0), "# targeting loop", Color(0.45, 0.45, 0.5), fs)
	_draw_text(Vector2(code_x, code_y + line_h * 1), "to_target = ball - turret  # ① subtract", code_color, fs)
	_draw_text(Vector2(code_x, code_y + line_h * 2), "dist = to_target.length()  # ② magnitude", code_color, fs)
	_draw_text(Vector2(code_x, code_y + line_h * 3), "aim = to_target.normalized()  # ③ normalize", code_color, fs)
	_draw_text(Vector2(code_x, code_y + line_h * 4), "lock = forward.dot(aim)  # ④ dot product", code_color, fs)
	_draw_text(Vector2(code_x, code_y + line_h * 5), "if dist < range and lock > 0.97: fire()", code_color, fs)

func _draw_grid(w: float, h: float):
	var grid_color = Color(0.12, 0.14, 0.16, 0.35)
	var step_x = w / 12.0
	var step_y = h / 24.0
	for i in range(1, 12):
		draw_line(Vector2(i * step_x, 0), Vector2(i * step_x, h), grid_color, 1.0)
	for i in range(1, 24):
		draw_line(Vector2(0, i * step_y), Vector2(w, i * step_y), grid_color, 1.0)

func _draw_turret(pos: Vector2, angle: float, scale: float):
	var base_r = 28 * scale
	draw_circle(pos, base_r, Color(0.32, 0.38, 0.42))
	draw_arc(pos, base_r, 0, TAU, 32, Color(0.45, 0.5, 0.55), 2.0 * scale)
	
	var barrel_len = 45 * scale
	var barrel_end = pos + Vector2(cos(angle), sin(angle)) * barrel_len
	draw_line(pos, barrel_end, Color(0.4, 0.45, 0.5), 8.0 * scale)
	draw_line(pos, barrel_end, Color(0.5, 0.55, 0.6), 4.0 * scale)
	
	# Glowing eye
	var eye_pos = pos + Vector2(0, -10 * scale)
	draw_circle(eye_pos, 7 * scale, Color(1.0, 0.15, 0.05))
	draw_circle(eye_pos, 4 * scale, Color(1.0, 0.5, 0.3))

func _draw_ball(pos: Vector2, radius: float):
	draw_circle(pos, radius, Color(1.0, 0.35, 0.15))
	draw_arc(pos, radius, 0, TAU, 32, Color(1.0, 0.55, 0.35), radius * 0.08)
	draw_circle(pos + Vector2(-radius * 0.3, -radius * 0.3), radius * 0.18, Color(1.0, 0.75, 0.55, 0.7))

func _draw_arrow(from: Vector2, to: Vector2, color: Color, width: float = 2.0):
	var dir = (to - from).normalized()
	var perp = Vector2(-dir.y, dir.x)
	draw_line(from, to, color, width)
	
	var head_size = width * 5
	var head_pos = to - dir * head_size
	draw_colored_polygon(PackedVector2Array([
		to,
		head_pos + perp * head_size * 0.5,
		head_pos - perp * head_size * 0.5
	]), color)

func _draw_laser(from: Vector2, to: Vector2, scale: float):
	draw_line(from, to, Color(1.0, 0.15, 0.05, 0.12), 18.0 * scale)
	draw_line(from, to, Color(1.0, 0.25, 0.08, 0.25), 9.0 * scale)
	draw_line(from, to, Color(1.0, 0.45, 0.15, 0.45), 4.0 * scale)
	draw_line(from, to, Color(1.0, 0.85, 0.7, 0.85), 1.5 * scale)
	
	draw_circle(to, 10 * scale, Color(1.0, 0.55, 0.25, 0.65))
	draw_circle(to, 5 * scale, Color(1.0, 0.9, 0.7, 0.9))

func _draw_text(pos: Vector2, text: String, color: Color, font_size: int = 16, centered: bool = false):
	var align = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	var offset = Vector2(-len(text) * font_size * 0.28, 0) if centered else Vector2.ZERO
	draw_string(ThemeDB.fallback_font, pos + offset, text, align, -1, font_size, color)
