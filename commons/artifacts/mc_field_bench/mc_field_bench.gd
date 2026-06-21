extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name McFieldBench

## @identity
## name: Marching Cubes Field Bench
## tier: medium
## truth: 256 cases stitch a surface where inside meets outside.
##
## A 3D scalar field becomes a skin. We sample a sum-of-metaballs field on a ~14^3
## grid sitting on the bench, then place a little box only at the BOUNDARY cells —
## the ones that are inside (f > thr) but have at least one empty 6-neighbour. The
## crust the boxes draw is exactly the surface marching cubes would triangulate:
## the level set where the noise crosses the threshold, where inside meets outside.

@export var res: int = 14
@export var threshold: float = 1.0
@export var span: float = 0.6
@export var lo_color: Color = Color(0.35, 0.85, 0.5)
@export var hi_color: Color = Color(0.95, 0.98, 1.0)

const BASE_Y := 0.85

var _t: float = 0.0
var _skin: MultiMeshInstance3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("res"):
		res = int(config["res"])
	if config.has("threshold"):
		threshold = float(config["threshold"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# bench
	add_child(_box(Vector3(0.0, BASE_Y - 0.1, 0.0), Vector3(1.1, 0.2, 1.1), _matte_mat(Color(0.15, 0.16, 0.2), 0.85)))
	add_child(_cylinder(Vector3(0.0, (BASE_Y - 0.2) * 0.5, 0.0), 0.09, BASE_Y - 0.2, _steel_mat(Color(0.3, 0.32, 0.38))))
	# the generated thing: the boundary skin, sitting ON TOP of the bench
	_skin = _make_skin()
	_skin.position = Vector3(0.0, BASE_Y + 0.06 + span * 0.5, 0.0)
	add_child(_skin)
	add_child(_billboard_label("MARCHING CUBES", Vector3(0.0, 1.6, 0.0), 24, hi_color.lerp(lo_color, 0.3)))


# --- field -------------------------------------------------------------------

func _field_value(p: Vector3, balls: Array) -> float:
	# sum-of-metaballs: each ball contributes r^2 / d^2, surface where the sum == threshold
	var s: float = 0.0
	for b in balls:
		var c: Vector3 = b[0]
		var r: float = b[1]
		var d2: float = maxf(p.distance_squared_to(c), 1e-5)
		s += (r * r) / d2
	return s


func _make_balls() -> Array:
	# three drifting blobs inside the cube
	var balls: Array = []
	balls.append([Vector3(sin(_t) * 0.12, 0.0, cos(_t * 0.8) * 0.1), 0.20])
	balls.append([Vector3(0.14, sin(_t * 1.1) * 0.1, -0.1), 0.16])
	balls.append([Vector3(-0.13, cos(_t * 0.9) * 0.12, 0.12), 0.15])
	return balls


func _make_skin() -> MultiMeshInstance3D:
	var g: int = clampi(res, 6, 22)
	# pass 1: mark which cells are inside
	var balls: Array = _make_balls()
	var inside := PackedByteArray()
	inside.resize(g * g * g)
	var step: float = span / float(g - 1)
	var origin: float = -span * 0.5
	for ix in range(g):
		for iy in range(g):
			for iz in range(g):
				var p := Vector3(origin + ix * step, origin + iy * step, origin + iz * step)
				inside[_idx(ix, iy, iz, g)] = 1 if _field_value(p, balls) > threshold else 0
	# pass 2: keep only boundary cells (inside, but a 6-neighbour is empty/out of bounds)
	var cells: Array = []
	for ix in range(g):
		for iy in range(g):
			for iz in range(g):
				if inside[_idx(ix, iy, iz, g)] == 0:
					continue
				if _is_boundary(inside, ix, iy, iz, g):
					cells.append(Vector3i(ix, iy, iz))
	var mi := _field(maxi(cells.size(), 1))
	var mm: MultiMesh = mi.multimesh
	mm.instance_count = maxi(cells.size(), 1)
	var s: float = step * 0.95
	var i: int = 0
	for cell in cells:
		var ix: int = cell.x
		var iy: int = cell.y
		var iz: int = cell.z
		var pos := Vector3(origin + ix * step, origin + iy * step, origin + iz * step)
		var t: float = clampf(float(iy) / float(g - 1), 0.0, 1.0)
		var col: Color = lo_color.lerp(hi_color, t)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), pos))
		mm.set_instance_color(i, col)
		i += 1
	if cells.is_empty():
		mm.set_instance_transform(0, Transform3D(Basis().scaled(Vector3(0.001, 0.001, 0.001)), Vector3.ZERO))
		mm.set_instance_color(0, lo_color)
	return mi


func _is_boundary(inside: PackedByteArray, ix: int, iy: int, iz: int, g: int) -> bool:
	var dirs := [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
	for d in dirs:
		var nx: int = ix + d.x
		var ny: int = iy + d.y
		var nz: int = iz + d.z
		if nx < 0 or ny < 0 or nz < 0 or nx >= g or ny >= g or nz >= g:
			return true
		if inside[_idx(nx, ny, nz, g)] == 0:
			return true
	return false


func _idx(ix: int, iy: int, iz: int, g: int) -> int:
	return (ix * g + iy) * g + iz


func _field(n: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.16 if emissive else 0.0
	mi.material_override = mat
	return mi


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# gentle sway — the field breathes, the skin re-forms slowly
	_t += delta * 0.35
	if _skin != null:
		remove_child(_skin)
		_skin.queue_free()
	_skin = _make_skin()
	_skin.position = Vector3(0.0, BASE_Y + 0.06 + span * 0.5, 0.0)
	add_child(_skin)
