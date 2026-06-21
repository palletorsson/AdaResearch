extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SdfBlobToy

## @identity
## name: SDF Blob Toy
## tier: small
## truth: a surface that is just where the function crosses zero.
##
## A held blob (~0.35m). Three sphere SDFs (sd = |p - c| - r) are folded together
## with a smooth-minimum, so they melt into one rounded body instead of intersecting.
## We sample sd(p) on a ~16^3 grid and place a tiny box at the BOUNDARY cells where
## the field is just inside (sd < 0 with an outside neighbour). No mesh, no marching:
## the shape is nothing but the place where the distance function reaches zero.

@export var res: int = 16
@export var extent: float = 0.18
@export var smooth_k: float = 0.10
@export var skin_color: Color = Color(0.65, 0.55, 0.95)

var _t: float = 0.0
var _blob: MultiMeshInstance3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("res"):
		res = int(config["res"])
	if config.has("smooth_k"):
		smooth_k = float(config["smooth_k"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# small held thing: no base, lives near origin
	_blob = _make_blob()
	add_child(_blob)
	add_child(_billboard_label("SDF BLOB", Vector3(0.0, extent + 0.18, 0.0), 18, skin_color.lerp(Color.WHITE, 0.3)))


# --- SDF ----------------------------------------------------------------------

func _sd_sphere(p: Vector3, c: Vector3, r: float) -> float:
	return p.distance_to(c) - r


func _smin(a: float, b: float, k: float) -> float:
	var h: float = clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


func _sd(p: Vector3) -> float:
	var c0 := Vector3(sin(_t) * 0.05, 0.04, 0.0)
	var c1 := Vector3(-0.07, -0.03, cos(_t * 0.8) * 0.05)
	var c2 := Vector3(0.06, cos(_t * 1.1) * 0.05, -0.05)
	var d: float = _sd_sphere(p, c0, 0.09)
	d = _smin(d, _sd_sphere(p, c1, 0.07), smooth_k)
	d = _smin(d, _sd_sphere(p, c2, 0.065), smooth_k)
	return d


func _make_blob() -> MultiMeshInstance3D:
	var g: int = clampi(res, 8, 22)
	var step: float = (extent * 2.0) / float(g - 1)
	var origin: float = -extent
	var field := PackedFloat32Array()
	field.resize(g * g * g)
	for ix in range(g):
		for iy in range(g):
			for iz in range(g):
				var p := Vector3(origin + ix * step, origin + iy * step, origin + iz * step)
				field[_idx(ix, iy, iz, g)] = _sd(p)
	var cells: Array = []
	for ix in range(g):
		for iy in range(g):
			for iz in range(g):
				if field[_idx(ix, iy, iz, g)] >= 0.0:
					continue
				if _is_boundary(field, ix, iy, iz, g):
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
		var rad: float = pos.length() / maxf(extent, 0.0001)
		var col: Color = skin_color.lerp(Color(0.95, 0.85, 1.0), clampf(rad, 0.0, 1.0))
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), pos))
		mm.set_instance_color(i, col)
		i += 1
	if cells.is_empty():
		mm.set_instance_transform(0, Transform3D(Basis().scaled(Vector3(0.001, 0.001, 0.001)), Vector3.ZERO))
		mm.set_instance_color(0, skin_color)
	return mi


func _is_boundary(field: PackedFloat32Array, ix: int, iy: int, iz: int, g: int) -> bool:
	var dirs := [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
	for d in dirs:
		var nx: int = ix + d.x
		var ny: int = iy + d.y
		var nz: int = iz + d.z
		if nx < 0 or ny < 0 or nz < 0 or nx >= g or ny >= g or nz >= g:
			return true
		if field[_idx(nx, ny, nz, g)] >= 0.0:
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
	_t += delta * 0.4
	if _blob != null:
		remove_child(_blob)
		_blob.queue_free()
	_blob = _make_blob()
	add_child(_blob)
