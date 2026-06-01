extends Control
class_name ScribbleControl

## Hand-drawn ("scribble") math renderer — chalk on a blackboard.
##
## Draws formulas as wobbly strokes, no font, no TextMesh. Each glyph is
## a set of polyline strokes in a normalized 0..1 box; every stroke is
## subdivided and perturbed by DETERMINISTIC hash jitter (not randf —
## stable per formula, curriculum-honest) and drawn in two passes for a
## chalk-doubled look.
##
## Multi-line: set `lines` (an array of formula strings) and they stack,
## each auto-fit to width. Inline notation: ² (superscript two), ½, √,
## ( ), / , − are all glyphs — no 2D layout engine needed for this set.

@export var formula: String = "α + β + γ = 180°"
@export var lines: PackedStringArray = PackedStringArray()
## "" = formulas only (full width). "triangle" = a labelled right
## triangle drawn on the left, formulas stacked on the right.
@export var diagram: String = ""
@export var glyph_height: float = 150.0
@export var ink_color: Color = Color(0.93, 0.95, 0.90)    # chalk
@export var board_color: Color = Color(0.10, 0.16, 0.13)  # blackboard
@export var draw_board: bool = true
@export var stroke_width: float = 4.0
@export var jitter: float = 0.02
@export var seed_salt: int = 7
## Handwriting font for Latin letters / digits / operators. Greek and
## math symbols (in STROKE_ONLY) always use the hand-stroke alphabet
## because handwriting fonts don't contain them.
@export var font_path: String = "res://commons/font/handwriting/ArchitectsDaughter.ttf"
@export var use_font: bool = true

const STROKE_ONLY := "αβγπλφΔΣ√²½°−∞→≈"
const FONT_SCALE := 1.05   # font size as a fraction of glyph_height

var _glyphs: Dictionary = {}
var _font: FontFile = null
var _adv_cache: Dictionary = {}


func _ready() -> void:
	_glyphs = _build_glyphs()
	_load_font()
	queue_redraw()


func _load_font() -> void:
	if not use_font or font_path == "":
		return
	# load_dynamic_font reads the TTF directly — no editor import needed,
	# works in headless --script runs.
	var f := FontFile.new()
	var err := f.load_dynamic_font(font_path)
	if err == OK:
		_font = f
	else:
		_font = null


func _uses_font(ch: String) -> bool:
	return _font != null and not STROKE_ONLY.contains(ch) and _font.has_char(ch.unicode_at(0))


func _draw() -> void:
	if _glyphs.is_empty():
		_glyphs = _build_glyphs()
	if draw_board:
		draw_rect(Rect2(Vector2.ZERO, size), board_color, true)

	var rows: PackedStringArray = lines if lines.size() > 0 else PackedStringArray([formula])
	if diagram != "":
		# Diagram on the left ~40%, formulas stacked on the right.
		var area := Rect2(size.x * 0.03, size.y * 0.12, size.x * 0.40, size.y * 0.76)
		match diagram:
			"triangle": _draw_triangle_diagram(area)
			"point": _draw_point_diagram(area)
			"line": _draw_line_diagram(area)
			"quad": _draw_quad_diagram(area)
			"qfep": _draw_qfep_diagram(area)
			"spiral": _draw_spiral_diagram(area)
			"thrown": _draw_thrown_diagram(area)
			"network": _draw_network_diagram(area)
			"trace": _draw_trace_diagram(area)
			"grid": _draw_grid_diagram(area)
			"mesh": _draw_mesh_diagram(area)
			"polyhedra": _draw_polyhedra_diagram(area)
			"cube": _draw_cube_diagram(area)
			"ignorance": _draw_ignorance_diagram(area)
			"circle": _draw_circle_diagram(area)
			"melencolia": _draw_melencolia_diagram(area)
			_: _draw_triangle_diagram(area)
		_draw_rows(rows, size.x * 0.48, size.x * 0.97)
	else:
		_draw_rows(rows, size.x * 0.06, size.x * 0.94)


func _draw_rows(rows: PackedStringArray, x_left: float, x_right: float) -> void:
	var n := rows.size()
	if n == 0:
		return
	var top_margin := size.y * 0.10
	var usable := size.y * 0.80
	var slot := usable / float(n)
	for i in range(n):
		var center_y := top_margin + slot * (float(i) + 0.5)
		var max_h: float = minf(glyph_height, slot * 0.58)
		_draw_line(rows[i], center_y, max_h, i, x_left, x_right)


func _draw_line(text: String, center_y: float, max_h: float, row: int, x_left: float, x_right: float) -> void:
	var spacing_units := 0.12
	var total_units := 0.0
	for ci in range(text.length()):
		total_units += _advance_of(text[ci]) + spacing_units
	total_units = maxf(total_units, 0.001)
	var avail := x_right - x_left
	var h: float = minf(max_h, avail / total_units)
	var spacing := h * spacing_units
	var line_width := total_units * h
	var baseline_top := center_y - h * 0.5
	var pen_x := x_left + (avail - line_width) * 0.5
	var stroke_seed := (seed_salt + row * 53) * 131
	for ci in range(text.length()):
		var adv := _draw_glyph(text[ci], Vector2(pen_x, baseline_top), h, stroke_seed)
		pen_x += adv + spacing
		stroke_seed += 41


# Draw one glyph; origin = top-left of its 0..1 box. Returns advance px.
func _draw_glyph(ch: String, origin: Vector2, h: float, seed: int) -> float:
	# Handwriting font for the chars it has (Latin, digits, operators).
	if _uses_font(ch):
		var fs := maxi(1, int(h * FONT_SCALE))
		var u := ch.unicode_at(0)
		var baseline := Vector2(origin.x, origin.y + h * 0.84)
		var ci := get_canvas_item()
		# Faint chalky double, offset down-right.
		_font.draw_char(ci, baseline + Vector2(2.0, 2.0), u, fs,
			Color(ink_color.r, ink_color.g, ink_color.b, 0.28))
		# FAUX-BOLD: draw the glyph several times at 1px sub-offsets so the
		# thin font strokes gain the same visual weight as the hand-drawn
		# symbol strokes. Thin antialiased text was washing out at VR
		# viewing distance (per-eye resolution + mipmaps eat 1px strokes),
		# so only the chunky symbols survived. Stacking passes thickens it.
		var bold: float = maxf(1.0, h * 0.05)   # bold radius scales with size
		for off in [
			Vector2(bold, 0.0), Vector2(-bold, 0.0),
			Vector2(0.0, bold), Vector2(0.0, -bold),
			Vector2(bold, bold) * 0.7, Vector2(-bold, -bold) * 0.7,
		]:
			_font.draw_char(ci, baseline + off, u, fs, ink_color)
		_font.draw_char(ci, baseline, u, fs, ink_color)
		return _advance_of(ch) * h

	var g: Dictionary = _glyphs.get(ch, {})
	if g.is_empty():
		return _advance_of(ch) * h
	var amp := jitter * h
	var s := seed
	for stroke in g.get("strokes", []):
		var pts := PackedVector2Array()
		for p in stroke:
			pts.append(origin + Vector2(p.x * h, p.y * h))
		_draw_scribbled(pts, s, amp)
		s += 17
	return g.get("advance", 0.6) * h


# Draw a short string centred at a point (used for diagram labels).
func _draw_label(text: String, center: Vector2, h: float, seed: int) -> void:
	var spacing := h * 0.10
	var w := 0.0
	for ci in range(text.length()):
		w += _advance_of(text[ci]) * h + spacing
	var pen_x := center.x - w * 0.5
	var top := center.y - h * 0.5
	var s := seed
	for ci in range(text.length()):
		pen_x += _draw_glyph(text[ci], Vector2(pen_x, top), h, s) + spacing
		s += 41


# A labelled right triangle: legs a (bottom) + b (left), hypotenuse c,
# the right angle marked, the two acute angles α and β.
func _draw_triangle_diagram(area: Rect2) -> void:
	var m := minf(area.size.x, area.size.y) * 0.18
	var p_rt := Vector2(area.position.x + m, area.position.y + area.size.y - m)              # right-angle corner
	var p_br := Vector2(area.position.x + area.size.x - m, area.position.y + area.size.y - m) # bottom-right
	var p_top := Vector2(area.position.x + m, area.position.y + m)                            # top
	var amp := jitter * minf(area.size.x, area.size.y) * 0.45
	# Edges.
	_draw_scribbled(PackedVector2Array([p_rt, p_top]), 1001, amp)   # leg b (left)
	_draw_scribbled(PackedVector2Array([p_rt, p_br]), 1051, amp)    # leg a (bottom)
	_draw_scribbled(PackedVector2Array([p_top, p_br]), 1103, amp)   # hypotenuse c
	# Right-angle marker.
	var sq := minf(area.size.x, area.size.y) * 0.11
	_draw_scribbled(PackedVector2Array([p_rt + Vector2(sq, 0), p_rt + Vector2(sq, -sq), p_rt + Vector2(0, -sq)]), 1155, amp * 0.6)
	# Labels.
	var lh := minf(area.size.x, area.size.y) * 0.17
	_draw_label("a", (p_rt + p_br) * 0.5 + Vector2(0, lh * 0.75), lh, 2001)
	_draw_label("b", (p_rt + p_top) * 0.5 + Vector2(-lh * 0.85, 0), lh, 2051)
	_draw_label("c", (p_top + p_br) * 0.5 + Vector2(lh * 0.55, -lh * 0.55), lh, 2101)
	_draw_label("α", p_top + Vector2(lh * 0.55, lh * 1.0), lh * 0.9, 2151)
	_draw_label("β", p_br + Vector2(-lh * 1.15, -lh * 0.45), lh * 0.9, 2201)


# A point: a single chalk dot with crosshair guides + a P(x,y) label.
func _draw_point_diagram(area: Rect2) -> void:
	var c := area.position + area.size * 0.5
	var span := minf(area.size.x, area.size.y) * 0.42
	var amp := minf(area.size.x, area.size.y) * 0.008
	var lh := minf(area.size.x, area.size.y) * 0.17
	# Faint crosshair guides (thin, like construction lines).
	var prev_w := stroke_width
	stroke_width = prev_w * 0.5
	_draw_scribbled(PackedVector2Array([c + Vector2(-span, 0), c + Vector2(span, 0)]), 3001, amp)
	_draw_scribbled(PackedVector2Array([c + Vector2(0, -span), c + Vector2(0, span)]), 3051, amp)
	stroke_width = prev_w
	# The dot itself — a filled chalk blob (several short concentric loops).
	var r := minf(area.size.x, area.size.y) * 0.06
	for k in range(4):
		var rr := r * (1.0 - float(k) * 0.22)
		_draw_scribbled(_ellipse_pts(c.x, c.y, rr, rr, 16), 3100 + k * 7, amp * 0.6)
	_draw_label("P", c + Vector2(lh * 1.0, -lh * 0.9), lh, 3201)


# A line: two endpoints A, B joined by a chalk segment, midpoint M.
func _draw_line_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.01
	var lh := minf(area.size.x, area.size.y) * 0.17
	var a := area.position + Vector2(area.size.x * 0.12, area.size.y * 0.72)
	var b := area.position + Vector2(area.size.x * 0.88, area.size.y * 0.30)
	# The segment.
	_draw_scribbled(PackedVector2Array([a, b]), 3301, amp)
	# Endpoint dots.
	for p in [a, b]:
		_draw_scribbled(_ellipse_pts(p.x, p.y, lh * 0.18, lh * 0.18, 12), 3340, amp * 0.6)
	# Midpoint tick.
	var m := (a + b) * 0.5
	var perp := (b - a).normalized().rotated(PI * 0.5) * lh * 0.30
	_draw_scribbled(PackedVector2Array([m - perp, m + perp]), 3360, amp * 0.6)
	# Labels.
	_draw_label("A", a + Vector2(-lh * 0.7, lh * 0.5), lh, 3401)
	_draw_label("B", b + Vector2(lh * 0.6, -lh * 0.2), lh, 3451)
	_draw_label("M", m + Vector2(lh * 0.1, lh * 0.9), lh * 0.85, 3501)


# A quad: a four-corner polygon with sides w (width) + h (height) and a
# diagonal showing it splits into two triangles.
func _draw_quad_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.01
	var lh := minf(area.size.x, area.size.y) * 0.16
	var m := minf(area.size.x, area.size.y) * 0.16
	var tl := Vector2(area.position.x + m, area.position.y + m)
	var tr := Vector2(area.position.x + area.size.x - m, area.position.y + m)
	var br := Vector2(area.position.x + area.size.x - m, area.position.y + area.size.y - m)
	var bl := Vector2(area.position.x + m, area.position.y + area.size.y - m)
	# Four sides.
	_draw_scribbled(PackedVector2Array([tl, tr]), 3601, amp)
	_draw_scribbled(PackedVector2Array([tr, br]), 3631, amp)
	_draw_scribbled(PackedVector2Array([br, bl]), 3661, amp)
	_draw_scribbled(PackedVector2Array([bl, tl]), 3691, amp)
	# Diagonal — the quad = 2 triangles.
	var prev_w := stroke_width
	stroke_width = prev_w * 0.55
	_draw_scribbled(PackedVector2Array([tl, br]), 3721, amp)
	stroke_width = prev_w
	# Labels: w on top, h on the right.
	_draw_label("w", (tl + tr) * 0.5 + Vector2(0, -lh * 0.7), lh, 3801)
	_draw_label("h", (tr + br) * 0.5 + Vector2(lh * 0.8, 0), lh, 3851)


# QFEP: the edge-of-chaos curve. A bell-ish curve over a λ axis, with
# "order" at λ=0, "noise" at λ=1, and a marked sweet spot at λ≈0.4
# (life / the edge of chaos) where the φ-term peaks.
func _draw_qfep_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.008
	var lh := minf(area.size.x, area.size.y) * 0.15
	var ox := area.position.x + area.size.x * 0.10
	var oy := area.position.y + area.size.y * 0.82   # x-axis baseline
	var ax_w := area.size.x * 0.82
	var ax_h := area.size.y * 0.62
	# Axes.
	_draw_scribbled(PackedVector2Array([Vector2(ox, oy), Vector2(ox + ax_w, oy)]), 4001, amp)            # λ axis
	_draw_scribbled(PackedVector2Array([Vector2(ox, oy), Vector2(ox, oy - ax_h)]), 4011, amp)            # value axis
	# The curve: rises to a peak near λ≈0.4 then falls — life at the edge.
	var curve := PackedVector2Array()
	var n := 26
	for i in range(n + 1):
		var t := float(i) / float(n)               # t = λ in 0..1
		# Asymmetric hump peaking ~0.4.
		var v: float = exp(-pow((t - 0.4) / 0.22, 2.0))
		curve.append(Vector2(ox + t * ax_w, oy - v * ax_h * 0.92))
	_draw_scribbled(curve, 4031, amp * 1.1)
	# Sweet-spot marker at λ≈0.4.
	var sx := ox + 0.4 * ax_w
	var sy := oy - ax_h * 0.92
	_draw_scribbled(_ellipse_pts(sx, sy, lh * 0.22, lh * 0.22, 12), 4051, amp * 0.6)
	var prev_w := stroke_width
	stroke_width = prev_w * 0.5
	_draw_scribbled(PackedVector2Array([Vector2(sx, sy), Vector2(sx, oy)]), 4061, amp * 0.5)   # drop line
	stroke_width = prev_w
	# Labels.
	_draw_label("λ", Vector2(ox + ax_w + lh * 0.4, oy), lh, 4101)
	_draw_label("order", Vector2(ox + lh * 0.4, oy + lh * 0.7), lh * 0.7, 4111)
	_draw_label("noise", Vector2(ox + ax_w - lh * 0.6, oy + lh * 0.7), lh * 0.7, 4121)
	_draw_label("life", Vector2(sx, sy - lh * 0.9), lh * 0.8, 4131)


# Endlessness: a spiral that keeps turning inward without ever closing —
# the potential infinite, the process that never completes.
func _draw_spiral_diagram(area: Rect2) -> void:
	var c := area.position + area.size * 0.5
	var amp := minf(area.size.x, area.size.y) * 0.006
	var lh := minf(area.size.x, area.size.y) * 0.15
	var maxr := minf(area.size.x, area.size.y) * 0.40
	var pts := PackedVector2Array()
	var turns := 4.2
	var steps := 150
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var ang := t * TAU * turns
		var r := maxr * (1.0 - t * 0.92)   # spirals inward, never to 0
		pts.append(c + Vector2(cos(ang) * r, sin(ang) * r))
	_draw_scribbled(pts, 4201, amp)
	# An arrowhead at the outer end, suggesting it also goes outward forever.
	var outer := c + Vector2(maxr, 0)
	_draw_scribbled(PackedVector2Array([outer + Vector2(-lh*0.3, -lh*0.25), outer, outer + Vector2(-lh*0.05, lh*0.35)]), 4231, amp)
	_draw_label("∞", c + Vector2(0, maxr + lh * 1.1), lh * 1.1, 4251)


# Thrownness: a figure-dot dropped along an arrow into a bounded box
# (the grid / the world) it did not choose. Geworfenheit, made literal:
# the player thrown into the lab at coordinates not of their choosing.
func _draw_thrown_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.008
	var lh := minf(area.size.x, area.size.y) * 0.14
	# The world: a bounded box (the grid).
	var bx := area.position.x + area.size.x * 0.14
	var by := area.position.y + area.size.y * 0.42
	var bw := area.size.x * 0.72
	var bh := area.size.y * 0.46
	var tl := Vector2(bx, by)
	var tr := Vector2(bx + bw, by)
	var br := Vector2(bx + bw, by + bh)
	var bl := Vector2(bx, by + bh)
	_draw_scribbled(PackedVector2Array([tl, tr]), 4301, amp)
	_draw_scribbled(PackedVector2Array([tr, br]), 4311, amp)
	_draw_scribbled(PackedVector2Array([br, bl]), 4321, amp)
	_draw_scribbled(PackedVector2Array([bl, tl]), 4331, amp)
	# A few interior grid lines so the box reads as "the grid".
	var prev_w := stroke_width
	stroke_width = prev_w * 0.4
	for k in range(1, 3):
		var fx := bx + bw * float(k) / 3.0
		_draw_scribbled(PackedVector2Array([Vector2(fx, by), Vector2(fx, by + bh)]), 4340 + k, amp * 0.5)
		var fy := by + bh * float(k) / 3.0
		_draw_scribbled(PackedVector2Array([Vector2(bx, fy), Vector2(bx + bw, fy)]), 4345 + k, amp * 0.5)
	stroke_width = prev_w
	# The throw: an arrow from outside, top-left, down into the box.
	var start := Vector2(area.position.x + area.size.x * 0.02, area.position.y + area.size.y * 0.06)
	var landing := Vector2(bx + bw * 0.42, by + bh * 0.40)
	_draw_scribbled(PackedVector2Array([start, landing]), 4361, amp * 1.1)
	# Arrowhead at landing.
	var dir := (landing - start).normalized()
	var perp := dir.rotated(PI * 0.5)
	_draw_scribbled(PackedVector2Array([
		landing - dir * lh * 0.9 + perp * lh * 0.4,
		landing,
		landing - dir * lh * 0.9 - perp * lh * 0.4,
	]), 4371, amp * 0.7)
	# The thrown one: a dot where it lands.
	for k in range(3):
		_draw_scribbled(_ellipse_pts(landing.x, landing.y, lh * 0.22 * (1.0 - k*0.25), lh * 0.22 * (1.0 - k*0.25), 12), 4381 + k, amp * 0.5)
	_draw_label("you", landing + Vector2(lh * 1.0, -lh * 0.2), lh * 0.8, 4391)


# Network: points joined by edges — Lines, Networks, Measure.
func _draw_network_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.008
	var lh := minf(area.size.x, area.size.y) * 0.14
	var c := area.position + area.size * 0.5
	var r := minf(area.size.x, area.size.y) * 0.34
	var nodes := PackedVector2Array()
	var n := 5
	for i in range(n):
		var a := -PI * 0.5 + TAU * float(i) / float(n)
		nodes.append(c + Vector2(cos(a) * r, sin(a) * r))
	var pairs := [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0], [0, 2], [1, 3]]
	var prev_w := stroke_width
	stroke_width = prev_w * 0.6
	var s := 5000
	for p in pairs:
		_draw_scribbled(PackedVector2Array([nodes[p[0]], nodes[p[1]]]), s, amp * 0.5)
		s += 13
	stroke_width = prev_w
	for nd in nodes:
		_draw_scribbled(_ellipse_pts(nd.x, nd.y, lh * 0.2, lh * 0.2, 12), s, amp * 0.6)
		s += 7


# Trace: a trail of dots growing toward the head — Duration and Residue.
func _draw_trace_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.006
	var lh := minf(area.size.x, area.size.y) * 0.14
	var n := 9
	var s := 5200
	for i in range(n):
		var t := float(i) / float(n - 1)
		var x := area.position.x + area.size.x * (0.12 + 0.74 * t)
		var y := area.position.y + area.size.y * (0.5 + 0.22 * sin(t * PI * 2.0))
		var rad := lh * (0.10 + 0.26 * t)
		_draw_scribbled(_ellipse_pts(x, y, rad, rad, 12), s, amp * 0.5)
		s += 11
	_draw_label("now", area.position + Vector2(area.size.x * 0.84, area.size.y * 0.5 - lh), lh * 0.7, 5290)


# Grid: a quantized stair path vs a straight intent — Grid Quantizes Movement.
func _draw_grid_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.006
	var bx := area.position.x + area.size.x * 0.12
	var by := area.position.y + area.size.y * 0.14
	var bw := area.size.x * 0.76
	var bh := area.size.y * 0.70
	var cells := 4
	var prev_w := stroke_width
	stroke_width = prev_w * 0.4
	for k in range(cells + 1):
		var fx := bx + bw * float(k) / float(cells)
		_draw_scribbled(PackedVector2Array([Vector2(fx, by), Vector2(fx, by + bh)]), 5400 + k, amp * 0.4)
		var fy := by + bh * float(k) / float(cells)
		_draw_scribbled(PackedVector2Array([Vector2(bx, fy), Vector2(bx + bw, fy)]), 5420 + k, amp * 0.4)
	stroke_width = prev_w * 0.5
	_draw_scribbled(PackedVector2Array([Vector2(bx, by + bh), Vector2(bx + bw, by)]), 5440, amp * 0.5)
	stroke_width = prev_w
	var step := PackedVector2Array()
	var cw := bw / float(cells)
	var ch := bh / float(cells)
	step.append(Vector2(bx, by + bh))
	for k in range(cells):
		step.append(Vector2(bx + cw * float(k), by + bh - ch * float(k)))
		step.append(Vector2(bx + cw * float(k + 1), by + bh - ch * float(k)))
		step.append(Vector2(bx + cw * float(k + 1), by + bh - ch * float(k + 1)))
	_draw_scribbled(step, 5460, amp)


# Mesh: a rectangle triangulated — Triangles Applied.
func _draw_mesh_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.008
	var bx := area.position.x + area.size.x * 0.10
	var by := area.position.y + area.size.y * 0.24
	var bw := area.size.x * 0.80
	var bh := area.size.y * 0.52
	var cols := 3
	var rows := 2
	var s := 5600
	for r in range(rows):
		for cc in range(cols):
			var x0 := bx + bw * float(cc) / float(cols)
			var x1 := bx + bw * float(cc + 1) / float(cols)
			var y0 := by + bh * float(r) / float(rows)
			var y1 := by + bh * float(r + 1) / float(rows)
			_draw_scribbled(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1), Vector2(x0, y0)]), s, amp * 0.5)
			s += 7
			_draw_scribbled(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y1)]), s, amp * 0.5)
			s += 7


# Polyhedra: a tetrahedron wireframe — Trihedra and First Solids.
func _draw_polyhedra_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.008
	var c := area.position + area.size * 0.5
	var r := minf(area.size.x, area.size.y) * 0.36
	var apex := c + Vector2(0, -r)
	var b0 := c + Vector2(-r * 0.86, r * 0.5)
	var b1 := c + Vector2(r * 0.86, r * 0.5)
	var b2 := c + Vector2(0, r * 0.18)
	_draw_scribbled(PackedVector2Array([apex, b0]), 5800, amp)
	_draw_scribbled(PackedVector2Array([apex, b1]), 5810, amp)
	_draw_scribbled(PackedVector2Array([b0, b1]), 5820, amp)
	var prev_w := stroke_width
	stroke_width = prev_w * 0.5
	_draw_scribbled(PackedVector2Array([apex, b2]), 5830, amp * 0.7)
	_draw_scribbled(PackedVector2Array([b0, b2]), 5840, amp * 0.7)
	_draw_scribbled(PackedVector2Array([b1, b2]), 5850, amp * 0.7)
	stroke_width = prev_w


# Cube: a cube wireframe — Cube Assembly from Primitives.
func _draw_cube_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.008
	var c := area.position + area.size * 0.5
	var s2 := minf(area.size.x, area.size.y) * 0.28
	var off := s2 * 0.6
	var f := [c + Vector2(-s2, -s2), c + Vector2(s2, -s2), c + Vector2(s2, s2), c + Vector2(-s2, s2)]
	var d := Vector2(off, -off)
	var bk := [f[0] + d, f[1] + d, f[2] + d, f[3] + d]
	for i in range(4):
		_draw_scribbled(PackedVector2Array([f[i], f[(i + 1) % 4]]), 5900 + i, amp)
	var prev_w := stroke_width
	stroke_width = prev_w * 0.6
	for i in range(4):
		_draw_scribbled(PackedVector2Array([bk[i], bk[(i + 1) % 4]]), 5910 + i, amp * 0.7)
		_draw_scribbled(PackedVector2Array([f[i], bk[i]]), 5920 + i, amp * 0.7)
	stroke_width = prev_w


# Ignorance: a circle of the known with ? outside — Limits of Geometric Knowledge.
func _draw_ignorance_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.008
	var lh := minf(area.size.x, area.size.y) * 0.16
	var c := area.position + area.size * 0.5
	var r := minf(area.size.x, area.size.y) * 0.30
	_draw_scribbled(_ellipse_pts(c.x, c.y, r, r, 28), 6000, amp)
	_draw_label("known", c, lh * 0.65, 6010)
	_draw_label("?", c + Vector2(-r * 1.5, -r * 0.6), lh * 1.1, 6020)
	_draw_label("?", c + Vector2(r * 1.5, -r * 0.3), lh * 1.1, 6030)
	_draw_label("?", c + Vector2(r * 1.2, r * 1.1), lh * 1.1, 6040)
	_draw_label("?", c + Vector2(-r * 1.3, r * 0.9), lh * 1.1, 6050)


# Circle: a polygon approaching a circle — Circular Approximation and Limits.
func _draw_circle_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.007
	var c := area.position + area.size * 0.5
	var r := minf(area.size.x, area.size.y) * 0.34
	_draw_scribbled(_ellipse_pts(c.x, c.y, r, r, 40), 6200, amp * 0.7)
	var poly := PackedVector2Array()
	var n := 6
	for i in range(n + 1):
		var a := -PI * 0.5 + TAU * float(i) / float(n)
		poly.append(c + Vector2(cos(a) * r, sin(a) * r))
	var prev_w := stroke_width
	stroke_width = prev_w * 0.7
	_draw_scribbled(poly, 6230, amp)
	stroke_width = prev_w * 0.5
	_draw_scribbled(PackedVector2Array([c, c + Vector2(r, 0)]), 6250, amp * 0.5)
	stroke_width = prev_w
	_draw_label("r", c + Vector2(r * 0.5, -minf(area.size.x, area.size.y) * 0.10), minf(area.size.x, area.size.y) * 0.14, 6260)


# Melencolia: Dürer's 4x4 magic square — Melancholy of Finitude. Every row,
# column and diagonal sums 34; the date 1514 sits in the bottom-middle cells.
func _draw_melencolia_diagram(area: Rect2) -> void:
	var amp := minf(area.size.x, area.size.y) * 0.006
	var n := 4
	var sz := minf(area.size.x, area.size.y) * 0.80
	var ox := area.position.x + (area.size.x - sz) * 0.5
	var oy := area.position.y + (area.size.y - sz) * 0.5
	var cell := sz / float(n)
	for k in range(n + 1):
		_draw_scribbled(PackedVector2Array([Vector2(ox + cell * k, oy), Vector2(ox + cell * k, oy + sz)]), 6400 + k, amp * 0.6)
		_draw_scribbled(PackedVector2Array([Vector2(ox, oy + cell * k), Vector2(ox + sz, oy + cell * k)]), 6420 + k, amp * 0.6)
	var sq := [16, 3, 2, 13, 5, 10, 11, 8, 9, 6, 7, 12, 4, 15, 14, 1]
	var lh := cell * 0.5
	for r in range(n):
		for cc in range(n):
			var v: int = sq[r * n + cc]
			var ctr := Vector2(ox + cell * (float(cc) + 0.5), oy + cell * (float(r) + 0.5))
			_draw_label(str(v), ctr, lh, 6500 + r * n + cc)


func _ellipse_pts(cx: float, cy: float, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var t := TAU * float(i) / float(n)
		pts.append(Vector2(cx + cos(t) * rx, cy + sin(t) * ry))
	return pts


func _advance_of(ch: String) -> float:
	# Font chars: measure the font advance, expressed in glyph-height
	# units (so the width/auto-fit math stays unit-based). Cached.
	if _uses_font(ch):
		if _adv_cache.has(ch):
			return _adv_cache[ch]
		var w: float = _font.get_char_size(ch.unicode_at(0), 100).x / 100.0 * FONT_SCALE
		w = maxf(w, 0.2)
		_adv_cache[ch] = w
		return w
	var g: Dictionary = _glyphs.get(ch, {})
	return g.get("advance", 0.4) if not g.is_empty() else 0.4


func _draw_scribbled(pts: PackedVector2Array, seed: int, amp: float) -> void:
	if pts.size() < 2:
		return
	var main := _scribble(pts, seed, amp)
	var ghost := _scribble(pts, seed + 9973, amp * 1.4)
	draw_polyline(ghost, Color(ink_color.r, ink_color.g, ink_color.b, 0.32), stroke_width * 0.7, true)
	draw_polyline(main, ink_color, stroke_width, true)


func _scribble(pts: PackedVector2Array, seed: int, amp: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var segs := maxi(2, int(a.distance_to(b) / 7.0))
		for s in range(segs):
			out.append(a.lerp(b, float(s) / float(segs)) + _hash2(seed + i * 97 + s * 7) * amp)
	out.append(pts[pts.size() - 1] + _hash2(seed + 4242) * amp)
	return out


func _hash2(n: int) -> Vector2:
	var x := sin(float(n) * 12.9898) * 43758.5453
	var y := sin(float(n) * 78.233 + 1.7) * 24634.6345
	return Vector2(x - floor(x), y - floor(y)) * 2.0 - Vector2.ONE


# ── Stroke alphabet ───────────────────────────────────────────────────

func _build_glyphs() -> Dictionary:
	var g := {}

	# Operators ------------------------------------------------------
	g["+"] = {"strokes": [[V(0.05, 0.55), V(0.65, 0.55)], [V(0.35, 0.25), V(0.35, 0.85)]], "advance": 0.72}
	g["="] = {"strokes": [[V(0.05, 0.48), V(0.66, 0.46)], [V(0.05, 0.68), V(0.66, 0.66)]], "advance": 0.74}
	g["-"] = {"strokes": [[V(0.08, 0.56), V(0.60, 0.55)]], "advance": 0.66}
	g["−"] = g["-"]
	g["/"] = {"strokes": [[V(0.52, 0.20), V(0.16, 0.90)]], "advance": 0.48}
	g["·"] = {"strokes": [_ellipse(0.28, 0.56, 0.05, 0.05, 0.0, TAU, 8)], "advance": 0.4}
	g["("] = {"strokes": [[V(0.50, 0.18), V(0.30, 0.40), V(0.28, 0.62), V(0.50, 0.88)]], "advance": 0.42}
	g[")"] = {"strokes": [[V(0.18, 0.18), V(0.38, 0.40), V(0.40, 0.62), V(0.18, 0.88)]], "advance": 0.42}
	g["√"] = {"strokes": [[V(0.05, 0.62), V(0.18, 0.88), V(0.34, 0.22), V(0.92, 0.20)]], "advance": 0.5}
	g["°"] = {"strokes": [_ellipse(0.24, 0.20, 0.14, 0.14, 0.0, TAU, 12)], "advance": 0.5}

	# Digits ---------------------------------------------------------
	g["0"] = {"strokes": [_ellipse(0.36, 0.55, 0.25, 0.38, 0.0, TAU, 18)], "advance": 0.74}
	g["1"] = {"strokes": [[V(0.14, 0.34), V(0.36, 0.20), V(0.37, 0.95)], [V(0.16, 0.95), V(0.58, 0.95)]], "advance": 0.56}
	g["2"] = {"strokes": [[V(0.12, 0.34), V(0.30, 0.20), V(0.55, 0.28), V(0.50, 0.50), V(0.14, 0.85), V(0.62, 0.85)]], "advance": 0.7}
	g["3"] = {"strokes": [[V(0.14, 0.28), V(0.45, 0.18), V(0.56, 0.40), V(0.32, 0.52)], [V(0.32, 0.52), V(0.60, 0.60), V(0.50, 0.88), V(0.14, 0.82)]], "advance": 0.68}
	g["8"] = {"strokes": [_ellipse(0.38, 0.36, 0.20, 0.18, 0.0, TAU, 14), _ellipse(0.38, 0.72, 0.25, 0.22, 0.0, TAU, 16)], "advance": 0.76}
	# Superscript two (small, raised) for a², b², c².
	g["²"] = {"strokes": [[V(0.08, 0.22), V(0.22, 0.13), V(0.38, 0.20), V(0.34, 0.34), V(0.10, 0.50), V(0.42, 0.50)]], "advance": 0.46}

	# Fraction one-half glyph ---------------------------------------
	g["½"] = {"strokes": [
		[V(0.10, 0.34), V(0.20, 0.28), V(0.20, 0.52)],          # small 1
		[V(0.46, 0.22), V(0.14, 0.88)],                          # slash
		[V(0.48, 0.58), V(0.60, 0.52), V(0.70, 0.60), V(0.66, 0.70), V(0.48, 0.88), V(0.74, 0.88)],  # small 2
	], "advance": 0.78}

	# Greek ----------------------------------------------------------
	g["α"] = {"strokes": [[
		V(0.64, 0.42), V(0.46, 0.34), V(0.26, 0.40), V(0.16, 0.58),
		V(0.24, 0.78), V(0.44, 0.82), V(0.60, 0.70), V(0.62, 0.50),
		V(0.56, 0.36), V(0.61, 0.52), V(0.67, 0.70), V(0.80, 0.84),
	]], "advance": 0.88}
	g["β"] = {"strokes": [
		[V(0.26, 0.18), V(0.22, 0.5), V(0.20, 0.82), V(0.17, 1.18)],
		[V(0.26, 0.24), V(0.50, 0.18), V(0.62, 0.34), V(0.46, 0.50), V(0.24, 0.52)],
		[V(0.24, 0.52), V(0.56, 0.54), V(0.68, 0.68), V(0.50, 0.84), V(0.22, 0.84)],
	], "advance": 0.80}
	g["γ"] = {"strokes": [
		[V(0.12, 0.34), V(0.30, 0.60), V(0.40, 0.74)],
		[V(0.70, 0.34), V(0.50, 0.62), V(0.40, 0.74), V(0.30, 1.06)],
	], "advance": 0.76}
	g["π"] = {"strokes": [[V(0.08, 0.36), V(0.76, 0.34)], [V(0.30, 0.36), V(0.27, 0.82)], [V(0.60, 0.36), V(0.63, 0.82)]], "advance": 0.84}

	# Greek for QFEP / theory boards --------------------------------
	# λ (lambda): two legs meeting near the top, the right leg longer.
	g["λ"] = {"strokes": [
		[V(0.18, 0.20), V(0.40, 0.40), V(0.66, 0.86)],
		[V(0.40, 0.40), V(0.16, 0.86)],
	], "advance": 0.72}
	# φ (phi): vertical bar through an oval.
	g["φ"] = {"strokes": [
		[V(0.40, 0.12), V(0.40, 0.96)],
		_ellipse(0.40, 0.54, 0.26, 0.22, 0.0, TAU, 16),
	], "advance": 0.84}
	# Δ (capital delta): a triangle, point up.
	g["Δ"] = {"strokes": [[V(0.40, 0.18), V(0.08, 0.84), V(0.72, 0.84), V(0.40, 0.18)]], "advance": 0.82}
	# Σ (capital sigma): the summation sign.
	g["Σ"] = {"strokes": [[V(0.66, 0.20), V(0.12, 0.20), V(0.42, 0.52), V(0.12, 0.84), V(0.68, 0.84)]], "advance": 0.78}
	# ∞ (infinity): two loops.
	g["∞"] = {"strokes": [
		_ellipse(0.27, 0.55, 0.18, 0.20, 0.0, TAU, 14),
		_ellipse(0.63, 0.55, 0.18, 0.20, 0.0, TAU, 14),
	], "advance": 0.94}
	# → (arrow): shaft + head.
	g["→"] = {"strokes": [
		[V(0.06, 0.55), V(0.78, 0.55)],
		[V(0.58, 0.40), V(0.80, 0.55), V(0.58, 0.70)],
	], "advance": 0.92}
	# ≈ (approx): two wavy lines.
	g["≈"] = {"strokes": [
		[V(0.06, 0.44), V(0.20, 0.38), V(0.36, 0.46), V(0.52, 0.40)],
		[V(0.06, 0.66), V(0.20, 0.60), V(0.36, 0.68), V(0.52, 0.62)],
	], "advance": 0.62}

	# Lowercase latin (math variables) ------------------------------
	g["a"] = {"strokes": [
		[V(0.52, 0.50), V(0.32, 0.45), V(0.18, 0.62), V(0.28, 0.82), V(0.48, 0.81), V(0.53, 0.58)],
		[V(0.53, 0.48), V(0.55, 0.82)],
	], "advance": 0.62}
	g["b"] = {"strokes": [
		[V(0.20, 0.16), V(0.22, 0.82)],
		[V(0.22, 0.55), V(0.42, 0.47), V(0.56, 0.62), V(0.46, 0.82), V(0.22, 0.80)],
	], "advance": 0.62}
	g["c"] = {"strokes": [[V(0.55, 0.52), V(0.34, 0.46), V(0.19, 0.62), V(0.30, 0.82), V(0.56, 0.80)]], "advance": 0.56}
	g["h"] = {"strokes": [
		[V(0.20, 0.16), V(0.22, 0.82)],
		[V(0.22, 0.56), V(0.40, 0.47), V(0.54, 0.58), V(0.54, 0.82)],
	], "advance": 0.62}
	g["s"] = {"strokes": [[V(0.52, 0.50), V(0.30, 0.46), V(0.26, 0.57), V(0.46, 0.64), V(0.50, 0.75), V(0.28, 0.82), V(0.14, 0.78)]], "advance": 0.52}
	g["n"] = {"strokes": [
		[V(0.20, 0.46), V(0.22, 0.82)],
		[V(0.22, 0.56), V(0.40, 0.47), V(0.54, 0.58), V(0.54, 0.82)],
	], "advance": 0.62}
	g["A"] = {"strokes": [[V(0.10, 0.85), V(0.38, 0.20), V(0.66, 0.85)], [V(0.22, 0.60), V(0.54, 0.60)]], "advance": 0.78}

	# Triangle motif -------------------------------------------------
	g["△"] = {"strokes": [[V(0.40, 0.18), V(0.12, 0.84), V(0.70, 0.84), V(0.40, 0.18)]], "advance": 0.82}

	return g


func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)


func _ellipse(cx: float, cy: float, rx: float, ry: float, a0: float, a1: float, n: int) -> Array:
	var pts := []
	for i in range(n + 1):
		var t := a0 + (a1 - a0) * float(i) / float(n)
		pts.append(Vector2(cx + cos(t) * rx, cy + sin(t) * ry))
	return pts
