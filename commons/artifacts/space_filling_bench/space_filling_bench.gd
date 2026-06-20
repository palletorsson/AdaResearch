extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SpaceFillingBench

## @identity
## name: "Space-filling curves"
## tier: medium
## lineage: Hilbert (1891) — a single continuous line proved to touch every point of a square
## essence: A 2D Hilbert curve filling a square on a bench, order 4, drawn as connected segments.
##   One thread, folded by the same rule at every scale, visits every cell of the grid and never
##   crosses itself. A 1D line becomes 2D area; nearby points on the line stay nearby on the plane.
## truth: "A LINE THAT FILLS A SQUARE" — dimension is generated, not given
## applications: texture locality, spatial indexing, image scanning — keep neighbours close.

@export var order: int = 4
@export var curve_span: float = 0.64
@export var top_y: float = 0.86
@export var bench_color: Color = Color(0.18, 0.19, 0.22)
@export var trunk_color: Color = Color(0.25, 0.85, 0.95)
@export var tip_color: Color = Color(0.95, 0.45, 0.85)
@export var label_col: Color = Color(0.80, 0.86, 0.94)

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
		order = clampi(int(config["order"]), 1, 5)
	if config.has("curve_span"):
		curve_span = float(config["curve_span"])
	if config.has("trunk_color"):
		trunk_color = _parse_color(config["trunk_color"], trunk_color)
	if config.has("tip_color"):
		tip_color = _parse_color(config["tip_color"], tip_color)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_build()


# Hilbert d2xy: map distance d along the curve to (x,y) on an n x n grid (n = 2^order).
func _hilbert_xy(n: int, d: int) -> Vector2i:
	var rx: int = 0
	var ry: int = 0
	var t: int = d
	var x: int = 0
	var y: int = 0
	var s: int = 1
	while s < n:
		rx = 1 & int(t / 2)
		ry = 1 & (t ^ rx)
		# rotate
		if ry == 0:
			if rx == 1:
				x = s - 1 - x
				y = s - 1 - y
			var tmp: int = x
			x = y
			y = tmp
		x += s * rx
		y += s * ry
		t = int(t / 4)
		s *= 2
	return Vector2i(x, y)


func _hilbert_points() -> Array:
	var n: int = int(pow(2, order))
	var total: int = n * n
	var pts: Array = []
	var step: float = curve_span / float(n - 1)
	for d in range(total):
		var c: Vector2i = _hilbert_xy(n, d)
		var px: float = (float(c.x) - float(n - 1) * 0.5) * step
		var pz: float = (float(c.y) - float(n - 1) * 0.5) * step
		pts.append(Vector3(px, 0.0, pz))
	return pts


func _build() -> void:
	# Bench base + top
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.1, 0.84, 0.7), _matte_mat(bench_color, 0.7)))
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.12, 0.04, 0.72), _matte_mat(Color(0.10, 0.11, 0.13), 0.6)))
	add_child(_cylinder(Vector3(0.0, 0.20, 0.0), 0.05, 0.40, _steel_mat(Color(0.35, 0.37, 0.4))))

	var sway := Node3D.new()
	sway.name = "CurveSway"
	add_child(sway)
	_sway = sway

	var pts: Array = _hilbert_points()
	var m: int = pts.size()
	var y0: float = top_y + 0.03
	# Connect consecutive points with thin cylinders, coloured along the line.
	var seg_r: float = maxf(curve_span / float(max(m, 1)) * 0.18, 0.004)
	for i in range(m - 1):
		var a: Vector3 = pts[i] + Vector3(0.0, y0, 0.0)
		var b: Vector3 = pts[i + 1] + Vector3(0.0, y0, 0.0)
		var f: float = float(i) / float(max(m - 2, 1))
		sway.add_child(_cylinder_between(a, b, seg_r, _glow_mat(trunk_color.lerp(tip_color, f), 1.5)))

	# Endpoint markers — where the single line enters and leaves.
	sway.add_child(_sphere(pts[0] + Vector3(0.0, y0, 0.0), 0.014, _glow_mat(trunk_color, 1.8)))
	sway.add_child(_sphere(pts[m - 1] + Vector3(0.0, y0, 0.0), 0.014, _glow_mat(tip_color, 1.8)))

	# Corner dots mark the square being filled.
	var hs: float = curve_span * 0.5 + 0.02
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_sphere(Vector3(float(sx) * hs, y0, float(sz) * hs), 0.01, _glow_mat(tip_color, 1.2)))

	add_child(_billboard_label("A LINE THAT FILLS A SQUARE", Vector3(0.0, 1.6, 0.0), 28, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.3) * 0.05
