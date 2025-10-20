extends Node3D
class_name CaveGenerator

@export var grid_size: Vector3i = Vector3i(10, 10, 10)
@export var cube_size: float = 1.0
@export var walkers: int = 4
@export var steps_per_level: int = 8
@export var seed: int = 1337
@export var show_gizmos: bool = false
@export var make_collision: bool = true

var _solid: PackedByteArray
var _rng := RandomNumberGenerator.new()
var _center: Vector3i

const HEADROOM := 2          # ensure 2-voxel tall tunnels
const CARVE_RADIUS := 1      # 1-voxel radius for walkable width
const CENTER_RADIUS := 2     # "close enough" to center in xz

func _ready() -> void:
	_rng.seed = seed
	_center = Vector3i(grid_size.x / 2, 0, grid_size.z / 2)
	_init_grid()
	_carve_cave()
	_build_meshes()

func _init_grid() -> void:
	var total := grid_size.x * grid_size.y * grid_size.z
	_solid = PackedByteArray()
	_solid.resize(total)
	for i in total:
		_solid[i] = 1

func _idx(p: Vector3i) -> int:
	return (p.y * grid_size.z + p.z) * grid_size.x + p.x

func _in_bounds(p: Vector3i) -> bool:
	return p.x >= 0 && p.x < grid_size.x \
		&& p.y >= 0 && p.y < grid_size.y \
		&& p.z >= 0 && p.z < grid_size.z

func _set_air(p: Vector3i) -> void:
	if !_in_bounds(p):
		return
	_solid[_idx(p)] = 0

func _is_solid(p: Vector3i) -> bool:
	if !_in_bounds(p):
		return false
	return _solid[_idx(p)] == 1

func _carve_ball(center: Vector3i, radius: int = CARVE_RADIUS, headroom: int = HEADROOM) -> void:
	# Carve a small sphere/cylinder + headroom vertically.
	for dy in headroom:
		var y := center.y + dy
		for z in range(center.z - radius, center.z + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				var p := Vector3i(x, y, z)
				if !_in_bounds(p):
					continue
				if Vector2i(x - center.x, z - center.z).length() <= float(radius):
					_set_air(p)

func _biased_step_towards(current: Vector3i, target_xz: Vector2i, bias: float = 0.65) -> Vector3i:
	# Lateral step with drift toward target in XZ (y unchanged).
	var options := [
		Vector3i( 1, 0,  0), Vector3i(-1, 0,  0),
		Vector3i( 0, 0,  1), Vector3i( 0, 0, -1)
	]
	# Weight options toward target
	var weighted: Array[Vector3i] = []
	for dir in options:
		var next  = current + dir
		var after := Vector2i(next.x, next.z)
		var dist_now := Vector2i(current.x, current.z).distance_to(target_xz)
		var dist_new := after.distance_to(target_xz)
		# If getting closer, add multiple copies (bias), else single copy
		if dist_new < dist_now:
			var copies := int(round(1.0 + 4.0 * bias))
			for i in copies:
				weighted.append(dir)
		else:
			weighted.append(dir)
	if weighted.is_empty():
		return current
	var choice := weighted[_rng.randi_range(0, weighted.size() - 1)]
	var candidate := current + choice
	if _in_bounds(candidate):
		return candidate
	return current

func _random_lateral_step(cur: Vector3i) -> Vector3i:
	var dirs := [
		Vector3i( 1, 0,  0), Vector3i(-1, 0,  0),
		Vector3i( 0, 0,  1), Vector3i( 0, 0, -1)
	]
	var d = dirs[_rng.randi_range(0, dirs.size() - 1)]
	var n = cur + d
	if _in_bounds(n):
		return n
	return cur

func _carve_cave() -> void:
	# Start walkers from four sides working inwards on y=0
	var side_starts: Array[Vector3i] = [
		Vector3i(0, 0, _center.z),
		Vector3i(grid_size.x - 1, 0, _center.z),
		Vector3i(_center.x, 0, 0),
		Vector3i(_center.x, 0, grid_size.z - 1)
	]
	# Clamp to bounds just in case grid_size is very small
	for i in range(side_starts.size()):
		side_starts[i].x = clamp(side_starts[i].x, 0, max(0, grid_size.x - 1))
		side_starts[i].z = clamp(side_starts[i].z, 0, max(0, grid_size.z - 1))

	var walkers_pos: Array[Vector3i] = []
	for i in walkers:
		walkers_pos.append(side_starts[i % side_starts.size()])

	# Phase A: move inward (bias toward center in xz) on y=0 until close to center
	for i in walkers_pos.size():
		var p := walkers_pos[i]
		var safety := 200
		while safety > 0:
			safety -= 1
			_carve_ball(p)
			var to_center := Vector2i(_center.x, _center.z)
			var close := Vector2i(p.x, p.z).distance_to(to_center) <= float(CENTER_RADIUS)
			if close:
				break
			p = _biased_step_towards(p, to_center, 0.7)
		walkers_pos[i] = p

	# Phase B: when at (or near) center, jump to y=1 and wander 10 steps laterally
	for i in walkers_pos.size():
		var p := walkers_pos[i]
		p.y = min(1, grid_size.y - 1)
		for s in 10:
			_carve_ball(p)
			p = _random_lateral_step(p)
		walkers_pos[i] = p

	# Phase C: climb from y=2 up to y=9 (or grid top-1), wandering at each level
	var max_y_target = min(9, grid_size.y - 1)
	for i in walkers_pos.size():
		var p := walkers_pos[i]
		for y in range(2, max_y_target + 1):
			p.y = y
			for s in steps_per_level:
				_carve_ball(p)
				# Mix a little “around” movement: lateral with mild toward-center bias + occasional outward
				if _rng.randf() < 0.75:
					p = _biased_step_towards(p, Vector2i(_center.x, _center.z), 0.5)
				else:
					p = _random_lateral_step(p)

	# Ensure a spawn pocket near the center at y=1
	for y in HEADROOM:
		_carve_ball(Vector3i(_center.x, min(1 + y, grid_size.y - 1), _center.z), 1, HEADROOM)

func _build_meshes() -> void:
	var cube := BoxMesh.new()
	cube.size = Vector3(cube_size, cube_size, cube_size)

	# Pre-make a BoxShape for collisions
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(cube_size, cube_size, cube_size)

	var origin_offset := -Vector3(
		(grid_size.x * cube_size) * 0.5 - cube_size * 0.5,
		0.0,
		(grid_size.z * cube_size) * 0.5 - cube_size * 0.5
	)

	for y in grid_size.y:
		for z in grid_size.z:
			for x in grid_size.x:
				var p := Vector3i(x, y, z)
				if _is_solid(p):
					var mi := MeshInstance3D.new()
					mi.mesh = cube
					mi.transform.origin = Vector3(x * cube_size, y * cube_size, z * cube_size) + origin_offset
					add_child(mi)

					if make_collision:
						var sb := StaticBody3D.new()
						var cs := CollisionShape3D.new()
						cs.shape = box_shape
						sb.add_child(cs)
						sb.transform.origin = mi.transform.origin
						add_child(sb)

	# Optional: add a visible marker at spawn
	if show_gizmos:
		var giz := MeshInstance3D.new()
		var gmesh := SphereMesh.new()
		gmesh.radius = cube_size * 0.4
		giz.mesh = gmesh
		giz.modulate = Color(1.0, 0.2, 0.6, 1.0)
		giz.transform.origin = Vector3(_center.x * cube_size, cube_size, _center.z * cube_size) + origin_offset
		add_child(giz)
