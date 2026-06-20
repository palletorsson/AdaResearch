extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SpaceFillingRoom

## @identity
## name: "Space-filling curves"
## tier: large
## lineage: 3D Hilbert — the square-filling thread lifted into a cube you can walk inside
## essence: A room-scale 3D Hilbert curve, ~3m, that you walk around. One unbroken line, folded by
##   the same recursive rule in three dimensions, threads through every cell of a cube without ever
##   crossing itself. Stand inside and trace the single path that visits the whole volume.
## truth: "EVERY POINT, ONE LINE" — a 1D thread reaches every corner of 3D space
## applications: octree traversal, GPU memory layout, point-cloud ordering — locality in 3D.

@export var order: int = 2
@export var span: float = 3.0
@export var floor_size: float = 7.0
@export var floor_col: Color = Color(0.14, 0.15, 0.18)
@export var trunk_color: Color = Color(0.30, 0.85, 0.98)
@export var tip_color: Color = Color(0.98, 0.45, 0.80)
@export var label_col: Color = Color(0.82, 0.88, 0.96)

var _t: float = 0.0
var _sway: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("order"):
		order = clampi(int(config["order"]), 1, 3)
	if config.has("span"):
		span = float(config["span"])
	if config.has("floor_size"):
		floor_size = float(config["floor_size"])
	if config.has("trunk_color"):
		trunk_color = _parse_color(config["trunk_color"], trunk_color)
	if config.has("tip_color"):
		tip_color = _parse_color(config["tip_color"], tip_color)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_build()


# Recursive 3D Hilbert curve. Produces an ordered list of integer cells visited.
# `points` is the output array; we recurse over an octant ordering with directed axes.
func _hilbert3d(points: Array, x: float, y: float, z: float, dx: float, dy: float, dz: float, dx2: float, dy2: float, dz2: float, dx3: float, dy3: float, dz3: float, level: int) -> void:
	if level <= 0:
		points.append(Vector3(
			x + (dx + dx2 + dx3) * 0.5,
			y + (dy + dy2 + dy3) * 0.5,
			z + (dz + dz2 + dz3) * 0.5
		))
		return
	var hx: float = dx * 0.5
	var hy: float = dy * 0.5
	var hz: float = dz * 0.5
	var hx2: float = dx2 * 0.5
	var hy2: float = dy2 * 0.5
	var hz2: float = dz2 * 0.5
	var hx3: float = dx3 * 0.5
	var hy3: float = dy3 * 0.5
	var hz3: float = dz3 * 0.5
	var l: int = level - 1
	_hilbert3d(points, x, y, z, hx2, hy2, hz2, hx3, hy3, hz3, hx, hy, hz, l)
	_hilbert3d(points, x + hx2, y + hy2, z + hz2, hx3, hy3, hz3, hx, hy, hz, hx2, hy2, hz2, l)
	_hilbert3d(points, x + hx2 + hx3, y + hy2 + hy3, z + hz2 + hz3, hx3, hy3, hz3, hx, hy, hz, hx2, hy2, hz2, l)
	_hilbert3d(points, x + hx3, y + hy3, z + hz3, -hx, -hy, -hz, -hx2, -hy2, -hz2, hx3, hy3, hz3, l)
	_hilbert3d(points, x + hx3 + hx, y + hy3 + hy, z + hz3 + hz, -hx, -hy, -hz, -hx2, -hy2, -hz2, hx3, hy3, hz3, l)
	_hilbert3d(points, x + hx3 + hx + hx2, y + hy3 + hy + hy2, z + hz3 + hz + hz2, -hx3, -hy3, -hz3, hx, hy, hz, -hx2, -hy2, -hz2, l)
	_hilbert3d(points, x + hx + hx2, y + hy + hy2, z + hz + hz2, -hx3, -hy3, -hz3, hx, hy, hz, -hx2, -hy2, -hz2, l)
	_hilbert3d(points, x + hx, y + hy, z + hz, hx2, hy2, hz2, -hx3, -hy3, -hz3, -hx, -hy, -hz, l)


func _build() -> void:
	# Room floor
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), _matte_mat(floor_col, 0.95, 0.1)))

	var sway := Node3D.new()
	sway.name = "CurveSway"
	add_child(sway)
	_sway = sway

	# Build the 3D Hilbert path inside a unit cube, then scale to `span` and lift off the floor.
	var pts: Array = []
	_hilbert3d(pts, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, order)
	var m: int = pts.size()

	var lift: float = 0.4
	var scaled: Array = []
	for p: Vector3 in pts:
		scaled.append(Vector3((p.x - 0.5) * span, (p.y - 0.5) * span + span * 0.5 + lift, (p.z - 0.5) * span))

	var seg_r: float = maxf(span / float(max(m, 1)) * 0.10, 0.02)
	for i in range(m - 1):
		var f: float = float(i) / float(max(m - 2, 1))
		sway.add_child(_cylinder_between(scaled[i], scaled[i + 1], seg_r, _glow_mat(trunk_color.lerp(tip_color, f), 1.6)))

	# Mark the single entry and exit of the one line.
	sway.add_child(_sphere(scaled[0], 0.06, _glow_mat(trunk_color, 2.0)))
	sway.add_child(_sphere(scaled[m - 1], 0.06, _glow_mat(tip_color, 2.0)))

	# A faint wire cube hinting at the volume being filled.
	var cube_mat := _glow_mat(Color(0.40, 0.45, 0.55), 0.5)
	var hs: float = span * 0.5
	var cy: float = span * 0.5 + lift
	var corners: Array = []
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				corners.append(Vector3(float(sx) * hs, cy + float(sy) * hs, float(sz) * hs))
	for i in range(corners.size()):
		for j in range(i + 1, corners.size()):
			var a: Vector3 = corners[i]
			var b: Vector3 = corners[j]
			# only draw cube edges (exactly one axis differs by full span)
			var diff: Vector3 = (b - a).abs()
			var near: int = 0
			if diff.x < 0.01:
				near += 1
			if diff.y < 0.01:
				near += 1
			if diff.z < 0.01:
				near += 1
			if near == 2:
				sway.add_child(_cylinder_between(a, b, 0.008, cube_mat))

	add_child(_billboard_label("EVERY POINT, ONE LINE", Vector3(0.0, 3.6, 0.0), 30, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway != null:
		_sway.rotation.y = _t * 0.10
