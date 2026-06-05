# biome_ground_substrate.gd — the walkable bump-map ground for biome maps
#
# Extends the walkgrids TopologySpace (its create_mesh_from_heights +
# create_collision_from_mesh give a deformed, WALKABLE mesh for free). A per-cell
# height field (the "ground" paint layer — plane / random / curve / noise / brush)
# is bilinear-sampled into the mesh; the trimesh collider follows, so the bumps
# are walkable. Flat field (the default) = a level ground at the floor.
# See doc/PAINT_LAYERS.md and doc/VR_EDITING_SYSTEM.md.

extends "res://commons/context/walkgrids/TopologySpace.gd"

var _field: PackedFloat32Array = PackedFloat32Array()  # per-cell [0..1] (the bump map)
var _fw: int = 1
var _fd: int = 1
var _max_h: float = 1.2          # metres at field value 1.0


## Size + place the ground to cover the grid (call BEFORE add_child).
func configure(grid_w: int, grid_d: int, cube: float, center: Vector3) -> void:
	space_size = Vector2(float(grid_w) * cube, float(grid_d) * cube)
	# Smooth-ish bumps: a couple of mesh quads per grid cell, capped for perf.
	resolution = clampi(maxi(grid_w, grid_d) * 2, 16, 80)
	height_scale = 1.0
	position = Vector3(center.x, center.y - 1.0, center.z)   # base ground a metre below the floor


## Set the height field (the bump map). `field` is row-major fw*fd, values 0..1.
func set_field(field: PackedFloat32Array, fw: int, fd: int, max_h: float) -> void:
	_field = field
	_fw = maxi(1, fw)
	_fd = maxi(1, fd)
	_max_h = max_h


## TopologySpace._ready() calls this after building static_body/mesh_instance.
func generate_space() -> void:
	var mesh: ArrayMesh = create_mesh_from_heights(_build_heights())
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	# Earthy ground; height-tinted so bumps read. Subtle when flat.
	apply_height_shader(
		Color(0.26, 0.22, 0.17), Color(0.34, 0.40, 0.26), Color(0.62, 0.66, 0.52),
		0.0, maxf(0.4, _max_h), false)


## LIVE preview while brushing — rebuild the MESH only (skip the trimesh
## collider, which is the expensive part). The collider catches up on the full
## rebuild at stroke-end. Lets you see the terrain rise under the brush.
func apply_height_preview(field: PackedFloat32Array, fw: int, fd: int, max_h: float) -> void:
	set_field(field, fw, fd, max_h)
	if mesh_instance:
		mesh_instance.mesh = create_mesh_from_heights(_build_heights())


func _build_heights() -> Array:
	var heights: Array = []
	heights.resize((resolution + 1) * (resolution + 1))
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			heights[z * (resolution + 1) + x] = _sample(float(x) / float(resolution), float(z) / float(resolution)) * _max_h
	return heights


## Rebuild from a new field (live brush updates).
func rebuild(field: PackedFloat32Array, fw: int, fd: int, max_h: float) -> void:
	set_field(field, fw, fd, max_h)
	if mesh_instance:   # only after _ready has built the nodes
		generate_space()


## Bilinear sample the per-cell field at normalized (u, v) over the grid.
func _sample(u: float, v: float) -> float:
	if _field.is_empty():
		return 0.0
	var fx: float = clampf(u * float(_fw) - 0.5, 0.0, float(_fw - 1))
	var fz: float = clampf(v * float(_fd) - 0.5, 0.0, float(_fd - 1))
	var x0: int = int(floor(fx))
	var z0: int = int(floor(fz))
	var x1: int = mini(x0 + 1, _fw - 1)
	var z1: int = mini(z0 + 1, _fd - 1)
	var tx: float = fx - float(x0)
	var tz: float = fz - float(z0)
	var a: float = _field[z0 * _fw + x0]
	var b: float = _field[z0 * _fw + x1]
	var c: float = _field[z1 * _fw + x0]
	var d: float = _field[z1 * _fw + x1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)
