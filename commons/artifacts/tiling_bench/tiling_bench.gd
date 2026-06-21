extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TilingBench

## @identity
## name: Tiling Bench
## tier: medium
## concept: Tilings & symmetry
## truth: tiles that lock by rule alone make a pattern no one drew.

@export var grid_size: int = 10
@export var field_extent: float = 1.3      # half-width of the tile field in metres
@export var bench_top_y: float = 0.85
@export var seed_value: int = 0

var _arc_segments: int = 5
var _sway_t: float = 0.0
var _field: Node3D = null


func _ready() -> void:
	_rng.randomize()
	if seed_value != 0:
		_rng.seed = seed_value
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
	# Bench base, top at bench_top_y
	var base_mat := _steel_mat(Color(0.15, 0.16, 0.2))
	add_child(_box(Vector3(0.0, bench_top_y * 0.5, 0.0), Vector3(field_extent * 2.0 + 0.3, bench_top_y, field_extent * 2.0 + 0.3), base_mat))

	# Backing plate for the tile field
	var plate_mat := _matte_mat(Color(0.08, 0.09, 0.11), 0.95)
	add_child(_box(Vector3(0.0, bench_top_y + 0.01, 0.0), Vector3(field_extent * 2.0 + 0.06, 0.02, field_extent * 2.0 + 0.06), plate_mat))

	# Label
	add_child(_billboard_label("TRUCHET TILING", Vector3(0.0, bench_top_y + 0.85, 0.0), 22, Color(1.0, 0.9, 0.75)))

	# Tile field
	_field = Node3D.new()
	_field.name = "TileField"
	_field.position = Vector3(0.0, bench_top_y + 0.03, 0.0)
	add_child(_field)

	var ridge_mat := _glow_mat(Color(0.95, 0.7, 0.35), 1.3)
	var n: int = max(grid_size, 2)
	var cell: float = (field_extent * 2.0) / float(n)
	var ridge_r: float = cell * 0.07
	var origin: float = -field_extent + cell * 0.5

	for gx in range(n):
		for gz in range(n):
			var cx: float = origin + float(gx) * cell
			var cz: float = origin + float(gz) * cell
			var rot: int = _rng.randi_range(0, 3)
			# 80% quarter-arc Truchet tile, 20% diagonal
			if _rng.randf() < 0.8:
				_make_arc_tile(Vector3(cx, 0.0, cz), cell, rot, ridge_r, ridge_mat)
			else:
				_make_diagonal_tile(Vector3(cx, 0.0, cz), cell, rot, ridge_r, ridge_mat)


# Two quarter-arcs joining midpoints of adjacent edges. Rotation 0/2 connect
# (W-N + S-E); rotation 1/3 connect (W-S + N-E) — the classic Truchet pair.
func _make_arc_tile(center: Vector3, cell: float, rot: int, r: float, mat: Material) -> void:
	var h: float = cell * 0.5
	# Edge midpoints (local, before rotation): N=+z, S=-z, E=+x, W=-x
	var mid_n := Vector3(0.0, 0.0, h)
	var mid_s := Vector3(0.0, 0.0, -h)
	var mid_e := Vector3(h, 0.0, 0.0)
	var mid_w := Vector3(-h, 0.0, 0.0)
	# Corner centers for the arcs
	var corner_nw := Vector3(-h, 0.0, h)
	var corner_se := Vector3(h, 0.0, -h)
	var corner_sw := Vector3(-h, 0.0, -h)
	var corner_ne := Vector3(h, 0.0, h)

	var pair_a: bool = (rot % 2) == 0
	if pair_a:
		_arc(center, corner_nw, mid_w, mid_n, h, r, mat)
		_arc(center, corner_se, mid_e, mid_s, h, r, mat)
	else:
		_arc(center, corner_sw, mid_w, mid_s, h, r, mat)
		_arc(center, corner_ne, mid_e, mid_n, h, r, mat)


# Quarter arc from p_start to p_end centered on 'pivot', radius = h, built from boxes.
func _arc(center: Vector3, pivot: Vector3, p_start: Vector3, p_end: Vector3, radius: float, r: float, mat: Material) -> void:
	var a0: float = atan2(p_start.z - pivot.z, p_start.x - pivot.x)
	var a1: float = atan2(p_end.z - pivot.z, p_end.x - pivot.x)
	# choose the short way (quarter turn)
	var diff: float = a1 - a0
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	var seg: int = _arc_segments
	for i in range(seg):
		var t0: float = float(i) / float(seg)
		var t1: float = float(i + 1) / float(seg)
		var ang0: float = a0 + diff * t0
		var ang1: float = a0 + diff * t1
		var p0 := pivot + Vector3(cos(ang0) * radius, 0.0, sin(ang0) * radius)
		var p1 := pivot + Vector3(cos(ang1) * radius, 0.0, sin(ang1) * radius)
		var wp0: Vector3 = center + Vector3(p0.x, 0.03, p0.z)
		var wp1: Vector3 = center + Vector3(p1.x, 0.03, p1.z)
		_field.add_child(_cylinder_between(wp0, wp1, r, mat))


func _make_diagonal_tile(center: Vector3, cell: float, rot: int, r: float, mat: Material) -> void:
	var h: float = cell * 0.5
	var a: Vector3
	var b: Vector3
	if (rot % 2) == 0:
		a = Vector3(-h, 0.03, -h)
		b = Vector3(h, 0.03, h)
	else:
		a = Vector3(-h, 0.03, h)
		b = Vector3(h, 0.03, -h)
	_field.add_child(_cylinder_between(center + a, center + b, r, mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_sway_t += delta
	if _field != null:
		_field.position.y = bench_top_y + 0.03 + 0.004 * sin(_sway_t * 0.8)
