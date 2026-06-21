extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SdfSculptBench

## @identity
## name: SDF Sculpt Bench
## tier: medium
## truth: add a blob, subtract a blob, the surface re-forms.
##
## A bench-scale SDF sculpt. Several sphere blobs are UNIONED (min of their distances)
## into one body, then a moving blob is SUBTRACTED (max(a, -b)) so a cavity opens
## through the side. We sample the combined field on a ~22^3 grid and draw a box at
## the BOUNDARY cells — so the crater is real surface, not a hole punched in a mesh.
## The booleans are pure arithmetic on the distance function; the skin just obeys.

@export var res: int = 22
@export var extent: float = 0.32
@export var smooth_k: float = 0.06
@export var skin_color: Color = Color(0.85, 0.7, 0.45)

const BASE_Y := 0.85

var _t: float = 0.0
var _sculpt: MultiMeshInstance3D


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
	# bench
	add_child(_box(Vector3(0.0, BASE_Y - 0.1, 0.0), Vector3(1.1, 0.2, 1.1), _matte_mat(Color(0.15, 0.16, 0.2), 0.85)))
	add_child(_cylinder(Vector3(0.0, (BASE_Y - 0.2) * 0.5, 0.0), 0.09, BASE_Y - 0.2, _steel_mat(Color(0.3, 0.32, 0.38))))
	# the generated thing ON TOP
	_sculpt = _make_sculpt()
	_sculpt.position = Vector3(0.0, BASE_Y + 0.06 + extent, 0.0)
	add_child(_sculpt)
	add_child(_billboard_label("SDF SCULPT", Vector3(0.0, 1.6, 0.0), 24, skin_color.lerp(Color.WHITE, 0.3)))


# --- SDF ----------------------------------------------------------------------

func _sd_sphere(p: Vector3, c: Vector3, r: float) -> float:
	return p.distance_to(c) - r


func _smin(a: float, b: float, k: float) -> float:
	var h: float = clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


func _sd(p: Vector3) -> float:
	# union (smooth-min) of several blobs = the body to keep
	var d: float = _sd_sphere(p, Vector3(0.0, 0.0, 0.0), 0.14)
	d = _smin(d, _sd_sphere(p, Vector3(0.12, 0.05, 0.0), 0.10), smooth_k)
	d = _smin(d, _sd_sphere(p, Vector3(-0.10, -0.04, 0.06), 0.10), smooth_k)
	d = _smin(d, _sd_sphere(p, Vector3(0.0, 0.10, -0.10), 0.09), smooth_k)
	# subtraction: max(a, -b) carves the moving cutter out of the body
	var cut := Vector3(0.12 + sin(_t) * 0.06, 0.02, 0.10)
	var b: float = _sd_sphere(p, cut, 0.12)
	return maxf(d, -b)


func _make_sculpt() -> MultiMeshInstance3D:
	var g: int = clampi(res, 10, 30)
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
		var t: float = clampf(0.5 + pos.y / (extent * 2.0), 0.0, 1.0)
		var col: Color = skin_color.lerp(Color(1.0, 0.92, 0.7), t)
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
	if _sculpt != null:
		remove_child(_sculpt)
		_sculpt.queue_free()
	_sculpt = _make_sculpt()
	_sculpt.position = Vector3(0.0, BASE_Y + 0.06 + extent, 0.0)
	add_child(_sculpt)
