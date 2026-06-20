extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NewtonFractalTool

## @identity
## A Newton's-method device: for z³ - 1, every starting point is coloured by which of the three
## roots it eventually falls into. Truth: "Newton basins". Three certain answers, but the map of
## who-goes-where is a fractal — the basin boundaries are infinitely tangled, so prediction near
## the seams is hopeless even though the algorithm is deterministic.

@export var grid: int = 72
@export var max_iter: int = 40
@export var panel_size: float = 0.72
@export var sway: bool = true

var _readout: Label3D
var _t: float = 0.0
var _root_counts: Array[int] = [0, 0, 0]


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = int(config["grid"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_build_device()
	add_child(_newton_field())
	add_child(_billboard_label("NEWTON BASINS", Vector3(0.0, 1.45, 0.0), 20, Color(0.7, 1.0, 0.8)))
	_readout = _billboard_label(_root_text(), Vector3(0.0, 0.2, 0.42), 12, Color(0.85, 0.95, 0.9))
	add_child(_readout)


func _build_device() -> void:
	# A ~1m tabletop device: a slab base with an upright fractal panel and a readout strip.
	add_child(_box(Vector3(0.0, 0.04, 0.0), Vector3(1.0, 0.08, 0.6), _matte_mat(Color(0.14, 0.15, 0.18), 0.7, 0.2)))
	# Panel housing.
	add_child(_box(Vector3(0.0, 0.55, -0.05), Vector3(panel_size + 0.08, panel_size + 0.08, 0.04), _matte_mat(Color(0.07, 0.08, 0.09), 0.6)))
	# Three little root indicators along the front lip, in the three basin colours.
	add_child(_sphere(Vector3(-0.3, 0.1, 0.3), 0.03, _glow_mat(Color(1.0, 0.6, 0.3), 1.5)))
	add_child(_sphere(Vector3(0.0, 0.1, 0.3), 0.03, _glow_mat(Color(0.2, 0.85, 0.45), 1.5)))
	add_child(_sphere(Vector3(0.3, 0.1, 0.3), 0.03, _glow_mat(Color(0.3, 0.55, 1.0), 1.5)))


func _root_text() -> String:
	var total: int = maxi(_root_counts[0] + _root_counts[1] + _root_counts[2], 1)
	var p0: int = int(round(100.0 * float(_root_counts[0]) / float(total)))
	var p1: int = int(round(100.0 * float(_root_counts[1]) / float(total)))
	var p2: int = int(round(100.0 * float(_root_counts[2]) / float(total)))
	return "z³ = 1   root basins  %d%% / %d%% / %d%%" % [p0, p1, p2]


func _newton_field() -> MultiMeshInstance3D:
	var g: int = clampi(grid, 16, 90)
	var n: int = g * g
	var mi := _field(n, true)
	var mm: MultiMesh = mi.multimesh
	var cell: float = panel_size / float(g)
	var s: float = cell * 0.96
	var base_y: float = 0.55
	_root_counts = [0, 0, 0]
	var i: int = 0
	for gy in range(g):
		for gx in range(g):
			var zr: float = -1.6 + 3.2 * (float(gx) + 0.5) / float(g)
			var zi: float = -1.6 + 3.2 * (float(gy) + 0.5) / float(g)
			var res: Vector2i = _newton(zr, zi)
			var root_id: int = res.x
			var iters: int = res.y
			if root_id >= 0 and root_id < 3:
				_root_counts[root_id] += 1
			var col: Color = _root_color(root_id, iters)
			var px: float = -panel_size * 0.5 + (float(gx) + 0.5) * cell
			var py: float = base_y - panel_size * 0.5 + (float(gy) + 0.5) * cell
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.4)), Vector3(px, py, 0.0)))
			mm.set_instance_color(i, col)
			i += 1
	return mi


func _newton(zr0: float, zi0: float) -> Vector2i:
	var zr: float = zr0
	var zi: float = zi0
	var it: int = 0
	while it < max_iter:
		var z2r: float = zr * zr - zi * zi
		var z2i: float = 2.0 * zr * zi
		var z3r: float = z2r * zr - z2i * zi
		var z3i: float = z2r * zi + z2i * zr
		var fr: float = z3r - 1.0
		var fi: float = z3i
		var dr: float = 3.0 * z2r
		var di: float = 3.0 * z2i
		var denom: float = dr * dr + di * di
		if denom < 1e-12:
			break
		var qr: float = (fr * dr + fi * di) / denom
		var qi: float = (fi * dr - fr * di) / denom
		zr -= qr
		zi -= qi
		if qr * qr + qi * qi < 1e-8:
			break
		it += 1
	return Vector2i(_classify_root(zr, zi), it)


func _classify_root(zr: float, zi: float) -> int:
	# Roots of z^3 - 1: r0=(1,0), r1=(-0.5, +0.8660), r2=(-0.5, -0.8660).
	var d0: float = (zr - 1.0) * (zr - 1.0) + zi * zi
	var d1: float = (zr + 0.5) * (zr + 0.5) + (zi - 0.8660254) * (zi - 0.8660254)
	var d2: float = (zr + 0.5) * (zr + 0.5) + (zi + 0.8660254) * (zi + 0.8660254)
	if d0 <= d1 and d0 <= d2:
		return 0
	elif d1 <= d2:
		return 1
	else:
		return 2


func _root_color(root_id: int, iters: int) -> Color:
	var shade: float = 1.0 - clampf(float(iters) / float(max_iter), 0.0, 0.75)
	match root_id:
		0:
			return Color(1.0, 0.6, 0.3) * shade
		1:
			return Color(0.2, 0.85, 0.45) * shade
		2:
			return Color(0.3, 0.55, 1.0) * shade
		_:
			return Color(0.05, 0.05, 0.06)


func _field(n: int, box: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not sway:
		return
	_t += delta
