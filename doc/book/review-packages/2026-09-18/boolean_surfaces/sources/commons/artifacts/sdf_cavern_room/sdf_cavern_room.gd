extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SdfCavernRoom

## @identity
## name: SDF Cavern Room
## tier: large
## truth: carve the function, walk the hollow.
##
## A room-scale SDF cavern. We start from one solid block (sd of a box) and SUBTRACT
## several large overlapping spheres (max(a, -b), chained) so their negative spaces
## merge into one connected hollow — a cave. The rock is drawn as the BOUNDARY cells
## of the resulting field on a ~30^3 grid: the only voxels we keep are the ones where
## solid rock meets the carved air. Nothing is modelled; the hollow is just where the
## subtracted function went negative, and the walls are where it crosses back.

@export var res: int = 30
@export var room_size: float = 7.0
@export var block_half: float = 2.6
@export var rock_lo: Color = Color(0.16, 0.14, 0.13)
@export var rock_hi: Color = Color(0.42, 0.38, 0.34)

var _t: float = 0.0
var _carvers: Array = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("res"):
		res = int(config["res"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# room floor
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.1, room_size), _matte_mat(Color(0.08, 0.08, 0.1), 0.85)))
	# carvers: a chain of overlapping spheres tracing a tunnel through the block
	_carvers = [
		[Vector3(-1.7, 0.2, -1.3), 1.4],
		[Vector3(-0.4, -0.1, 0.0), 1.5],
		[Vector3(1.0, 0.3, 0.9), 1.4],
		[Vector3(1.9, -0.2, -0.8), 1.2],
		[Vector3(0.2, 1.0, -1.6), 1.1],
	]
	add_child(_make_rock())
	add_child(_billboard_label("CARVE THE FUNCTION, WALK THE HOLLOW", Vector3(0.0, 3.6, 0.0), 28, rock_hi.lerp(Color.WHITE, 0.4)))


# --- SDF ----------------------------------------------------------------------

func _sd_box(p: Vector3, half: float) -> float:
	var q := Vector3(absf(p.x) - half, absf(p.y) - half, absf(p.z) - half)
	var outside: float = Vector3(maxf(q.x, 0.0), maxf(q.y, 0.0), maxf(q.z, 0.0)).length()
	var inside: float = minf(maxf(q.x, maxf(q.y, q.z)), 0.0)
	return outside + inside


func _sd_sphere(p: Vector3, c: Vector3, r: float) -> float:
	return p.distance_to(c) - r


func _sd(p: Vector3) -> float:
	# solid block, then subtract every carver: d = max(d, -carver)
	var d: float = _sd_box(p, block_half)
	for carver in _carvers:
		var c: Vector3 = carver[0]
		var r: float = carver[1]
		d = maxf(d, -_sd_sphere(p, c, r))
	return d


func _make_rock() -> MultiMeshInstance3D:
	var g: int = clampi(res, 12, 38)
	# field spans a cube a touch larger than the block so the outer faces register
	var ext: float = block_half + 0.4
	var step: float = (ext * 2.0) / float(g - 1)
	var origin: float = -ext
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
	var s: float = step * 0.96
	# lift the carved block so its floor sits near the room floor
	var y_lift: float = block_half + 0.15
	var i: int = 0
	for cell in cells:
		var ix: int = cell.x
		var iy: int = cell.y
		var iz: int = cell.z
		var pos := Vector3(origin + ix * step, origin + iy * step + y_lift, origin + iz * step)
		var t: float = clampf((float(iy) / float(g - 1)) * 0.7 + _rng.randf() * 0.3, 0.0, 1.0)
		var col: Color = rock_lo.lerp(rock_hi, t)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), pos))
		mm.set_instance_color(i, col)
		i += 1
	if cells.is_empty():
		mm.set_instance_transform(0, Transform3D(Basis().scaled(Vector3(0.001, 0.001, 0.001)), Vector3.ZERO))
		mm.set_instance_color(0, rock_lo)
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
	# static demo: build once, gentle sway of the whole carved mass only
	_t += delta
	rotation.y = sin(_t * 0.15) * 0.04
