extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FlatlandRoom

## @identity
## name: Flatland — Angles Sum to 180
## lineage: Euclid's flat plane made into a room you stand in. The world before
##   curvature: rails run straight to infinity and a triangle's three angles open
##   out to exactly a straight line.
## essence: a room-scale grid floor, two parallel rails receding to a vanishing
##   point, and a large triangle whose three corner angles, when carried to one
##   spot, lie flat along 180 degrees. Overhead: FLAT SPACE — ANGLES SUM TO 180.
## truth: on a flat surface the angle sum is fixed at 180 — the signature of zero
##   curvature, the assumption Euclid never questioned and the baseline every
##   other geometry is measured against.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_gold: Color = Color(0.98, 0.80, 0.32)
@export var room_size: float = 7.0
@export var grid_cells: int = 14

var _tri_arc_a: Node3D
var _tri_arc_b: Node3D
var _tri_arc_c: Node3D
var _straight_marks: Node3D
var _sweep_dot: MeshInstance3D
var _t: float = 0.0
# triangle corners on the floor
var _ta := Vector3(-1.9, 0.06, 1.6)
var _tb := Vector3(2.1, 0.06, 1.4)
var _tc := Vector3(0.1, 0.06, -2.2)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	var white_mat := _glow_mat(cool_white, 0.6)
	var purple_mat := _glow_mat(wire_purple, 0.6)
	var gold_mat := _glow_mat(accent_gold, 1.2)
	var floor_mat := _matte_mat(Color(0.08, 0.09, 0.14), 0.9)

	# --- room floor ---
	var hs: float = room_size * 0.5
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.06, room_size), floor_mat))

	# --- grid lines on the floor (chalk) ---
	var step: float = room_size / float(grid_cells)
	for i in range(grid_cells + 1):
		var p: float = -hs + float(i) * step
		add_child(_box(Vector3(p, 0.005, 0.0), Vector3(0.012, 0.006, room_size), purple_mat))
		add_child(_box(Vector3(0.0, 0.005, p), Vector3(room_size, 0.006, 0.012), purple_mat))

	# --- two parallel rails running to a vanishing point at the far wall ---
	var ry: float = 0.10
	var near_z: float = hs - 0.4
	var far_z: float = -hs + 0.4
	var near_off: float = 1.2
	var far_off: float = 0.12
	add_child(_cylinder_between(Vector3(-near_off, ry, near_z), Vector3(-far_off, ry, far_z), 0.03, white_mat))
	add_child(_cylinder_between(Vector3(near_off, ry, near_z), Vector3(far_off, ry, far_z), 0.03, white_mat))
	var vp := Vector3(0.0, ry, far_z - 0.2)
	add_child(_sphere(vp, 0.06, gold_mat))
	add_child(_billboard_label("parallel rails never meet", vp + Vector3(0.0, 0.5, 0.0), 18, cool_white))

	# --- the big triangle on the floor ---
	add_child(_cylinder_between(_ta, _tb, 0.035, gold_mat))
	add_child(_cylinder_between(_tb, _tc, 0.035, gold_mat))
	add_child(_cylinder_between(_tc, _ta, 0.035, gold_mat))
	# corner angle arcs (these pulse)
	_tri_arc_a = _make_corner_arc(_ta, _tb, _tc, gold_mat)
	_tri_arc_b = _make_corner_arc(_tb, _tc, _ta, gold_mat)
	_tri_arc_c = _make_corner_arc(_tc, _ta, _tb, gold_mat)
	add_child(_tri_arc_a)
	add_child(_tri_arc_b)
	add_child(_tri_arc_c)
	add_child(_billboard_label("a", _ta + Vector3(0.0, 0.3, 0.0), 16, accent_gold))
	add_child(_billboard_label("b", _tb + Vector3(0.0, 0.3, 0.0), 16, accent_gold))
	add_child(_billboard_label("c", _tc + Vector3(0.0, 0.3, 0.0), 16, accent_gold))

	# --- the "straight line" proof bar: a + b + c laid flat = 180 ---
	# a glowing horizontal bar near the center with three arcs carried onto it
	var bar_center := Vector3(0.0, 0.12, 0.4)
	add_child(_box(bar_center, Vector3(3.2, 0.02, 0.02), white_mat))
	_straight_marks = Node3D.new()
	_straight_marks.position = bar_center
	add_child(_straight_marks)
	# three abutting half-arcs filling the 180 above the bar
	var seg_w: float = 3.2 / 3.0
	var cols: Array = [accent_gold, wire_purple, cool_white]
	for k in range(3):
		var cx: float = -1.6 + seg_w * (float(k) + 0.5)
		var seg_mat := _glow_mat(cols[k], 1.0)
		_straight_marks.add_child(_make_half_arc(Vector3(cx, 0.0, 0.0), seg_w * 0.5, seg_mat))
	add_child(_billboard_label("a + b + c = 180 degrees", bar_center + Vector3(0.0, 0.55, 0.0), 18, accent_gold))

	# a dot that sweeps the half-circle, tracing the straight angle
	_sweep_dot = _sphere(bar_center + Vector3(-1.6, 0.0, 0.0), 0.05, gold_mat)
	add_child(_sweep_dot)

	# --- overhead title ---
	add_child(_billboard_label("FLAT SPACE — ANGLES SUM TO 180", Vector3(0.0, 3.6, 0.0), 38, cool_white))
	add_child(_billboard_label("Euclid's plane: zero curvature, the baseline", Vector3(0.0, 3.3, 0.0), 18, wire_purple))


func _make_corner_arc(corner: Vector3, p1: Vector3, p2: Vector3, mat: Material) -> Node3D:
	var root := Node3D.new()
	root.position = corner + Vector3(0.0, 0.05, 0.0)
	var d1: Vector3 = (p1 - corner).normalized()
	var d2: Vector3 = (p2 - corner).normalized()
	var r: float = 0.32
	var steps: int = 6
	for i in range(steps):
		var f0: float = float(i) / float(steps)
		var f1: float = float(i + 1) / float(steps)
		var a0: Vector3 = d1.slerp(d2, f0) * r
		var a1: Vector3 = d1.slerp(d2, f1) * r
		root.add_child(_cylinder_between(a0, a1, 0.012, mat))
	return root


func _make_half_arc(center: Vector3, r: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	root.position = center
	var steps: int = 8
	for i in range(steps):
		var a0: float = lerpf(0.0, PI, float(i) / float(steps))
		var a1: float = lerpf(0.0, PI, float(i + 1) / float(steps))
		var p0 := Vector3(cos(a0) * r, sin(a0) * r, 0.0)
		var p1 := Vector3(cos(a1) * r, sin(a1) * r, 0.0)
		root.add_child(_cylinder_between(p0, p1, 0.01, mat))
	return root


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# the three corner angles pulse in sequence — being "carried" to the bar
	var phase: float = fmod(_t, 3.0)
	var arcs: Array = [_tri_arc_a, _tri_arc_b, _tri_arc_c]
	for idx in range(3):
		var arc: Node3D = arcs[idx]
		if is_instance_valid(arc):
			var lit: float = clampf(1.0 - absf(phase - float(idx)), 0.0, 1.0)
			arc.scale = Vector3.ONE * (1.0 + lit * 0.3)

	# the sweep dot traces the 180 half-circle on the proof bar, over and over
	if is_instance_valid(_sweep_dot):
		var sweep: float = fmod(_t * 0.4, 1.0)
		var ang: float = lerpf(0.0, PI, sweep)
		var r: float = 1.6
		_sweep_dot.position = Vector3(0.0, 0.12, 0.4) + Vector3(-cos(ang) * r, sin(ang) * r * 0.0 + 0.0, 0.0)
		# ride along the bar left->right (the straight angle)
		_sweep_dot.position = Vector3(lerpf(-1.6, 1.6, sweep), 0.12, 0.4)

	# straight marks shimmer
	if is_instance_valid(_straight_marks):
		var sh: float = 0.5 + 0.5 * sin(_t * 3.0)
		_straight_marks.scale = Vector3(1.0, 1.0 + sh * 0.08, 1.0)
