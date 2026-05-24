extends Control
class_name SequenceGlyph

## Procedural 2D glyph for a spine sequence — used as the Portal-2-style
## "chamber icon" on each sequence picker card. Draws a phase-coloured
## tile background + a sequence-specific symbol on top.
##
## No external assets: every glyph is procedural (lines, circles, polylines).
## A single Control class dispatches on sequence_id to a per-sequence draw
## function. Falls back to a monogram for any unknown id.
##
## Usage:
##   var g := SequenceGlyph.new()
##   g.sequence_id = "randomness"
##   g.phase_color = Color(0.957, 0.635, 0.380)
##   g.custom_minimum_size = Vector2(90, 90)
##   parent.add_child(g)

var sequence_id: String = "":
	set(value):
		sequence_id = value
		queue_redraw()
var phase_color: Color = Color(0.55, 0.58, 0.65):
	set(value):
		phase_color = value
		queue_redraw()


func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	var inset: float = 4.0
	var inner: Rect2 = Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)

	# Tile background — translucent phase colour, dark fill behind
	draw_rect(r, Color(0.05, 0.05, 0.07, 1.0), true)
	draw_rect(inner, Color(phase_color.r, phase_color.g, phase_color.b, 0.18), true)
	# Border in phase colour
	draw_rect(inner, phase_color, false, 2.0)

	# Inner symbol — dispatch on sequence_id
	var fg: Color = phase_color.lightened(0.10)
	var dim: Color = Color(phase_color.r, phase_color.g, phase_color.b, 0.55)
	var cx: float = size.x * 0.5
	var cy: float = size.y * 0.5
	var w: float = size.x
	var h: float = size.y

	match sequence_id:
		"primitives":          _draw_primitives(cx, cy, w, h, fg, dim)
		"transformation":      _draw_transformation(cx, cy, w, h, fg, dim)
		"array_tutorial":      _draw_array(cx, cy, w, h, fg, dim)
		"color":               _draw_color(cx, cy, w, h, fg, dim)
		"change":              _draw_change(cx, cy, w, h, fg, dim)
		"forces":              _draw_forces(cx, cy, w, h, fg, dim)
		"wavefunctions":       _draw_waves(cx, cy, w, h, fg, dim)
		"randomness":          _draw_randomness(cx, cy, w, h, fg, dim)
		"noise":               _draw_noise(cx, cy, w, h, fg, dim)
		"cellularautomata":    _draw_ca(cx, cy, w, h, fg, dim)
		"fractals":            _draw_fractals(cx, cy, w, h, fg, dim)
		"lsystems":            _draw_lsystems(cx, cy, w, h, fg, dim)
		"proceduralgeneration": _draw_procgen(cx, cy, w, h, fg, dim)
		"isosurfaces":         _draw_isosurfaces(cx, cy, w, h, fg, dim)
		"boolean_surfaces":    _draw_boolean(cx, cy, w, h, fg, dim)
		"softbodies":          _draw_softbody(cx, cy, w, h, fg, dim)
		"swarmintelligence":   _draw_swarm(cx, cy, w, h, fg, dim)
		"machinelearning":     _draw_ml(cx, cy, w, h, fg, dim)
		"graphtheory":         _draw_graph(cx, cy, w, h, fg, dim)
		"foundationscrisis":   _draw_foundations(cx, cy, w, h, fg, dim)
		"qfeplaboratory":      _draw_qfep(cx, cy, w, h, fg, dim)
		"postfoundationscrisis": _draw_post_foundations(cx, cy, w, h, fg, dim)
		_:                     _draw_monogram(cx, cy, w, h, fg)


# ── Per-sequence glyphs ───────────────────────────────────────────────

func _draw_primitives(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Three primitives: dot, line, plane (triangle outline)
	draw_circle(Vector2(cx - w * 0.22, cy), w * 0.04, fg)
	draw_line(Vector2(cx - w * 0.08, cy + h * 0.10), Vector2(cx + w * 0.08, cy - h * 0.10), fg, 2.0)
	var tri := PackedVector2Array([
		Vector2(cx + w * 0.18, cy + h * 0.14),
		Vector2(cx + w * 0.32, cy + h * 0.14),
		Vector2(cx + w * 0.25, cy - h * 0.02),
	])
	draw_polyline(tri + PackedVector2Array([tri[0]]), fg, 2.0)


func _draw_transformation(cx: float, cy: float, w: float, h: float, fg: Color, _dim: Color) -> void:
	# Two arrows mirroring each other
	var arrow_y_top := cy - h * 0.10
	var arrow_y_bot := cy + h * 0.10
	# Top arrow → right
	draw_line(Vector2(cx - w * 0.25, arrow_y_top), Vector2(cx + w * 0.20, arrow_y_top), fg, 2.0)
	draw_line(Vector2(cx + w * 0.20, arrow_y_top), Vector2(cx + w * 0.12, arrow_y_top - h * 0.05), fg, 2.0)
	draw_line(Vector2(cx + w * 0.20, arrow_y_top), Vector2(cx + w * 0.12, arrow_y_top + h * 0.05), fg, 2.0)
	# Bottom arrow ← left
	draw_line(Vector2(cx + w * 0.25, arrow_y_bot), Vector2(cx - w * 0.20, arrow_y_bot), fg, 2.0)
	draw_line(Vector2(cx - w * 0.20, arrow_y_bot), Vector2(cx - w * 0.12, arrow_y_bot - h * 0.05), fg, 2.0)
	draw_line(Vector2(cx - w * 0.20, arrow_y_bot), Vector2(cx - w * 0.12, arrow_y_bot + h * 0.05), fg, 2.0)


func _draw_array(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# 3x3 grid of small squares
	var cell: float = w * 0.10
	var gap: float = w * 0.03
	var start_x: float = cx - (cell * 1.5 + gap)
	var start_y: float = cy - (cell * 1.5 + gap)
	for r in range(3):
		for c in range(3):
			var x: float = start_x + c * (cell + gap)
			var y: float = start_y + r * (cell + gap)
			var fill: Color = fg if ((r * 3 + c) % 2 == 0) else dim
			draw_rect(Rect2(x, y, cell, cell), fill, true)


func _draw_color(cx: float, cy: float, w: float, h: float, _fg: Color, _dim: Color) -> void:
	# Rainbow strip — 6 vertical bars
	var bar_w: float = w * 0.10
	var bar_h: float = h * 0.36
	var start_x: float = cx - bar_w * 3.0
	var hues: Array = [0.0, 0.08, 0.18, 0.38, 0.58, 0.78]
	for i in range(6):
		var col: Color = Color.from_hsv(hues[i], 0.85, 0.95)
		draw_rect(Rect2(start_x + i * bar_w, cy - bar_h * 0.5, bar_w - 1.0, bar_h), col, true)


func _draw_change(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# A curve with a tangent line crossing it
	var pts := PackedVector2Array()
	for i in range(20):
		var t: float = float(i) / 19.0
		var x: float = cx - w * 0.30 + t * (w * 0.60)
		var y: float = cy + sin(t * PI * 2.0) * h * 0.18
		pts.append(Vector2(x, y))
	draw_polyline(pts, dim, 2.0)
	# Tangent at the inflection
	var mid: Vector2 = pts[10]
	draw_line(mid + Vector2(-w * 0.18, h * 0.06), mid + Vector2(w * 0.18, -h * 0.06), fg, 2.0)


func _draw_forces(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Vector arrow (the canonical force)
	draw_line(Vector2(cx - w * 0.28, cy + h * 0.20), Vector2(cx + w * 0.22, cy - h * 0.18), fg, 3.0)
	draw_line(Vector2(cx + w * 0.22, cy - h * 0.18), Vector2(cx + w * 0.10, cy - h * 0.20), fg, 3.0)
	draw_line(Vector2(cx + w * 0.22, cy - h * 0.18), Vector2(cx + w * 0.20, cy - h * 0.06), fg, 3.0)
	# Small dim secondary vector
	draw_line(Vector2(cx - w * 0.20, cy + h * 0.05), Vector2(cx + w * 0.05, cy + h * 0.15), dim, 2.0)


func _draw_waves(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Two sine curves — fundamental + harmonic
	var pts1 := PackedVector2Array()
	var pts2 := PackedVector2Array()
	for i in range(40):
		var t: float = float(i) / 39.0
		var x: float = cx - w * 0.32 + t * (w * 0.64)
		pts1.append(Vector2(x, cy + sin(t * PI * 4.0) * h * 0.20))
		pts2.append(Vector2(x, cy + sin(t * PI * 8.0) * h * 0.08))
	draw_polyline(pts1, fg, 2.0)
	draw_polyline(pts2, dim, 1.5)


func _draw_randomness(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Scattered dots — deterministic but jittery
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(30):
		var x: float = cx + rng.randf_range(-w * 0.32, w * 0.32)
		var y: float = cy + rng.randf_range(-h * 0.32, h * 0.32)
		var rsz: float = rng.randf_range(1.4, 3.2)
		var c: Color = fg if rng.randf() > 0.4 else dim
		draw_circle(Vector2(x, y), rsz, c)


func _draw_noise(cx: float, cy: float, w: float, h: float, fg: Color, _dim: Color) -> void:
	# Perlin-ish dotted grid
	var noise := FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.15
	var gw: int = 10
	var gh: int = 10
	for r in range(gh):
		for c in range(gw):
			var n: float = (noise.get_noise_2d(c, r) + 1.0) * 0.5
			var x: float = cx - w * 0.32 + (float(c) + 0.5) * (w * 0.64 / gw)
			var y: float = cy - h * 0.32 + (float(r) + 0.5) * (h * 0.64 / gh)
			var radius: float = n * 3.0
			draw_circle(Vector2(x, y), radius, Color(fg.r, fg.g, fg.b, 0.4 + n * 0.55))


func _draw_ca(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Rule-30-like triangular grid
	var rows: int = 6
	var cols: int = 9
	var cell: float = w * 0.08
	var start_x: float = cx - cols * cell * 0.5
	var start_y: float = cy - rows * cell * 0.5
	# Initial seed: middle cell only
	var prev: PackedInt32Array = PackedInt32Array()
	for c in range(cols):
		prev.append(1 if c == cols / 2 else 0)
	for r in range(rows):
		var next: PackedInt32Array = PackedInt32Array()
		for c in range(cols):
			if r == 0:
				next.append(prev[c])
			else:
				var l: int = prev[max(0, c - 1)]
				var m: int = prev[c]
				var rt: int = prev[min(cols - 1, c + 1)]
				# Rule 30: 111=0, 110=0, 101=0, 100=1, 011=1, 010=1, 001=1, 000=0
				var pattern: int = l * 4 + m * 2 + rt
				next.append([0, 1, 1, 1, 1, 0, 0, 0][pattern])
		for c in range(cols):
			var x: float = start_x + c * cell
			var y: float = start_y + r * cell
			if next[c] == 1:
				draw_rect(Rect2(x, y, cell - 1.0, cell - 1.0), fg, true)
			else:
				draw_rect(Rect2(x, y, cell - 1.0, cell - 1.0), Color(dim.r, dim.g, dim.b, 0.15), true)
		prev = next


func _draw_fractals(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Sierpinski triangle — 3 levels
	var top := Vector2(cx, cy - h * 0.30)
	var bl := Vector2(cx - w * 0.30, cy + h * 0.20)
	var br := Vector2(cx + w * 0.30, cy + h * 0.20)
	_sierpinski(top, bl, br, 3, fg, dim)


func _sierpinski(a: Vector2, b: Vector2, c: Vector2, depth: int, fg: Color, dim: Color) -> void:
	if depth <= 0:
		draw_polyline(PackedVector2Array([a, b, c, a]), fg, 1.0)
		return
	var ab: Vector2 = (a + b) * 0.5
	var bc: Vector2 = (b + c) * 0.5
	var ca: Vector2 = (c + a) * 0.5
	_sierpinski(a, ab, ca, depth - 1, fg, dim)
	_sierpinski(ab, b, bc, depth - 1, fg, dim)
	_sierpinski(ca, bc, c, depth - 1, fg, dim)


func _draw_lsystems(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Branching tree
	var base := Vector2(cx, cy + h * 0.34)
	_l_branch(base, -PI * 0.5, w * 0.22, 0, fg, dim)


func _l_branch(start: Vector2, angle: float, length: float, depth: int, fg: Color, dim: Color) -> void:
	if depth > 3:
		return
	var end: Vector2 = start + Vector2(cos(angle), sin(angle)) * length
	var c: Color = fg if depth < 2 else dim
	draw_line(start, end, c, max(1.0, 3.0 - depth))
	_l_branch(end, angle - 0.45, length * 0.68, depth + 1, fg, dim)
	_l_branch(end, angle + 0.45, length * 0.68, depth + 1, fg, dim)


func _draw_procgen(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Voronoi-ish irregular tile pattern
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in range(8):
		var x: float = cx + rng.randf_range(-w * 0.30, w * 0.30)
		var y: float = cy + rng.randf_range(-h * 0.30, h * 0.30)
		var rad: float = rng.randf_range(w * 0.05, w * 0.12)
		var alpha: float = rng.randf_range(0.25, 0.65)
		draw_circle(Vector2(x, y), rad, Color(fg.r, fg.g, fg.b, alpha))


func _draw_isosurfaces(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Concentric isolines (contour lines)
	for i in range(4):
		var radius: float = w * (0.10 + i * 0.06)
		var c: Color = fg if i == 1 else dim
		draw_arc(Vector2(cx, cy), radius, 0.0, TAU, 32, c, 1.5)


func _draw_boolean(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Two overlapping circles — Venn / boolean union
	draw_arc(Vector2(cx - w * 0.10, cy), w * 0.18, 0.0, TAU, 32, fg, 2.0)
	draw_arc(Vector2(cx + w * 0.10, cy), w * 0.18, 0.0, TAU, 32, dim, 2.0)


func _draw_softbody(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Squashed circle (deformed soft body)
	var pts := PackedVector2Array()
	for i in range(32):
		var t: float = float(i) / 32.0 * TAU
		var radius: float = w * 0.20 * (1.0 + 0.20 * sin(t * 3.0))
		pts.append(Vector2(cx + cos(t) * radius, cy + sin(t) * radius * 0.85))
	pts.append(pts[0])
	draw_polyline(pts, fg, 2.0)
	# Inner mesh hint
	for i in range(0, 32, 4):
		draw_line(Vector2(cx, cy), pts[i], dim, 1.0)


func _draw_swarm(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Cluster of dots converging on a centre
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i in range(20):
		var ang: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(w * 0.05, w * 0.30)
		var x: float = cx + cos(ang) * dist
		var y: float = cy + sin(ang) * dist * 0.9
		var sz: float = rng.randf_range(1.5, 2.8)
		draw_circle(Vector2(x, y), sz, fg if dist < w * 0.18 else dim)


func _draw_ml(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Tiny neural-net topology — 3 input, 4 hidden, 2 output
	var col_xs: Array = [cx - w * 0.28, cx, cx + w * 0.28]
	var col_sizes: Array = [3, 4, 2]
	var nodes_per_col: Array = [[], [], []]
	for c in range(3):
		var n: int = col_sizes[c]
		var col_x: float = col_xs[c]
		for i in range(n):
			var col_y: float = cy + (float(i) - float(n - 1) * 0.5) * h * 0.16
			nodes_per_col[c].append(Vector2(col_x, col_y))
	# Edges
	for c in range(2):
		for a: Vector2 in nodes_per_col[c]:
			for b: Vector2 in nodes_per_col[c + 1]:
				draw_line(a, b, dim, 0.8)
	# Nodes
	for c in range(3):
		for p: Vector2 in nodes_per_col[c]:
			draw_circle(p, 3.0, fg)


func _draw_graph(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# A small graph — 5 nodes, a few edges
	var nodes := PackedVector2Array([
		Vector2(cx - w * 0.22, cy - h * 0.18),
		Vector2(cx + w * 0.20, cy - h * 0.22),
		Vector2(cx, cy + h * 0.04),
		Vector2(cx - w * 0.18, cy + h * 0.22),
		Vector2(cx + w * 0.22, cy + h * 0.18),
	])
	var edges := [[0,1],[0,2],[1,2],[2,3],[2,4],[3,4]]
	for e in edges:
		draw_line(nodes[e[0]], nodes[e[1]], dim, 1.4)
	for p: Vector2 in nodes:
		draw_circle(p, 3.5, fg)


func _draw_foundations(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# A red lambda symbol — the foundations crisis
	var p1 := Vector2(cx - w * 0.18, cy + h * 0.22)
	var p2 := Vector2(cx, cy - h * 0.22)
	var p3 := Vector2(cx + w * 0.22, cy + h * 0.22)
	var p_mid := Vector2(cx - w * 0.04, cy - h * 0.02)
	draw_line(p1, p2, fg, 3.0)
	draw_line(p_mid, p3, fg, 3.0)
	# A small question mark of a dot beneath
	draw_circle(Vector2(cx, cy + h * 0.34), 2.0, dim)


func _draw_qfep(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# An integral sign — the canonical QFEP formula glyph
	var pts := PackedVector2Array()
	for i in range(24):
		var t: float = float(i) / 23.0
		var y: float = cy - h * 0.25 + t * h * 0.50
		var s: float = sin(t * PI * 1.0)
		var x: float = cx + s * w * 0.12
		pts.append(Vector2(x, y))
	draw_polyline(pts, fg, 3.0)
	# Phase loop
	draw_arc(Vector2(cx, cy), w * 0.30, 0.0, TAU, 36, Color(dim.r, dim.g, dim.b, 0.45), 1.5)


func _draw_post_foundations(cx: float, cy: float, w: float, h: float, fg: Color, dim: Color) -> void:
	# Three dots — continuation
	var spacing: float = w * 0.10
	for i in range(3):
		var x: float = cx - spacing + i * spacing
		draw_circle(Vector2(x, cy), 4.0, fg if i == 1 else dim)


func _draw_monogram(cx: float, cy: float, w: float, h: float, fg: Color) -> void:
	# Fallback for any sequence we haven't designed for
	var first_char: String = sequence_id.left(1).to_upper() if sequence_id != "" else "?"
	var font: Font = ThemeDB.fallback_font
	var fsz: int = int(min(w, h) * 0.55)
	var size_v: Vector2 = font.get_string_size(first_char, HORIZONTAL_ALIGNMENT_CENTER, -1.0, fsz)
	var pos: Vector2 = Vector2(cx - size_v.x * 0.5, cy + size_v.y * 0.30)
	draw_string(font, pos, first_char, HORIZONTAL_ALIGNMENT_CENTER, -1.0, fsz, fg)
