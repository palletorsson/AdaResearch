extends Node3D
## Walkable interiors extracted from a signed 3D field (negative = solid).
## The Book of Shaders ch.12 supplies the nearest-feature-point construction.
## Geometry, openings and collision all come from the same field.

enum Layout { WOMB, CELLS }
@export var layout: Layout = Layout.WOMB
@export var seed_value: int = 42
@export_range(0.28, 0.65, 0.01) var voxel_size: float = 0.42
@export_range(0.0, 0.9, 0.05) var softness: float = 0.65
@export_range(3.5, 5.5, 0.1) var clearing_radius: float = 4.6
@export var create_lights: bool = true
@export var create_floor: bool = true
@export var box_cells: bool = false
@export_range(0.4, 0.75, 0.05) var box_size: float = 0.65

const Mesher = preload("res://commons/context/cellular_spaces/volume_mesher.gd")
const BoxMesher = preload("res://commons/context/cellular_spaces/box_mesher.gd")
const Membrane = preload("res://commons/context/cellular_spaces/membrane.gdshader")
const BOUNDS := AABB(Vector3(-13.5, -0.5, -14.5), Vector3(27, 11, 29))
var sites := PackedVector3Array()
var floor_sites := PackedVector3Array()
var generated: Node3D
var membrane_mesh: ArrayMesh
var build_msec: int = 0
var _noise := FastNoiseLite.new()
var _radii := Vector3(10.0, 6.2, 12.0)
var _half_wall: float

func _ready() -> void:
	regenerate()

func regenerate() -> void:
	var started := Time.get_ticks_msec()
	voxel_size = clampf(voxel_size, 0.28, 0.65)
	softness = clampf(softness, 0.0, 0.9)
	clearing_radius = clampf(clearing_radius, 3.5, 5.5)
	# A wall must span more than one sample interval, even at coarse preview quality.
	_half_wall = maxf(0.42, voxel_size * 1.05)
	box_size = clampf(box_size, 0.4, 0.75)
	if box_cells:
		_half_wall = maxf(_half_wall, box_size * 1.1)
	_radii = Vector3(10.0, 6.2, 12.0) if layout == Layout.WOMB else Vector3(12.0, 6.2, 12.0)
	_noise.seed = seed_value
	_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	_noise.frequency = 0.28
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_make_sites()
	if is_instance_valid(generated):
		remove_child(generated)
		generated.queue_free()
	generated = Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	membrane_mesh = BoxMesher.build(sample_solid, BOUNDS, box_size) if box_cells else Mesher.build(sample_solid, BOUNDS, voxel_size)
	var body := StaticBody3D.new()
	body.name = "Membrane"
	body.collision_layer = 1
	body.collision_mask = 0
	generated.add_child(body)
	var skin := MeshInstance3D.new()
	skin.name = "Surface"
	skin.mesh = membrane_mesh
	var material := ShaderMaterial.new()
	material.shader = Membrane
	material.set_shader_parameter("skin_color", Color("bb627a") if layout == Layout.WOMB else Color("668f9d"))
	material.set_shader_parameter("edge_color", Color("ffd1a1") if layout == Layout.WOMB else Color("bff3d9"))
	material.set_shader_parameter("pattern_scale", 0.68 if layout == Layout.WOMB else 0.42)
	if box_cells:
		material.set_shader_parameter("skin_color", Color("bc835d") if layout == Layout.WOMB else Color("8376b5"))
		material.set_shader_parameter("pattern_scale", 0.28)
	skin.material_override = material
	body.add_child(skin)
	var collider := CollisionShape3D.new()
	var shape := membrane_mesh.create_trimesh_shape()
	shape.backface_collision = true
	collider.shape = shape
	body.add_child(collider)
	if create_floor:
		_make_floor()
	if create_lights:
		_make_lights()
	build_msec = Time.get_ticks_msec() - started

func _make_sites() -> void:
	sites.clear()
	floor_sites.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for z in range(4):
		for x in range(4):
			var point := Vector3((x - 1.5) * 5.0 + rng.randf_range(-0.6, 0.6),
				2.1 + rng.randf_range(-0.45, 0.45), (z - 1.5) * 5.0 + rng.randf_range(-0.6, 0.6))
			var horizontal := Vector2(point.x, point.z).limit_length(9.1)
			point.x = horizontal.x
			point.z = horizontal.y
			sites.append(point)
			floor_sites.append(point)
	# A second height layer gives genuine 3D cell faces and overhead chambers.
	for z in [-1, 1]:
		for x in [-1, 1]:
			sites.append(Vector3(x * 5.0, 10.5 + rng.randf_range(-0.6, 0.6), z * 5.0))

func sample_solid(p: Vector3) -> float:
	var q := p - Vector3(0, 2.4, 0)
	var normalized := q / _radii
	# Approximate ellipsoid distance; its zero set is exact. Noise changes the
	# actual shell, including the ceiling, rather than displacing a flat floor.
	var enclosure := (normalized.length() - 1.0) * 8.0
	if layout == Layout.WOMB:
		var cell_noise := _noise.get_noise_3d(p.x, p.y, p.z)
		var folds := sin(p.y * 0.7 + p.z * 0.3) * sin(p.x * 0.48)
		enclosure += softness * (cell_noise * 0.8 + folds * 0.55)
	var solid := absf(enclosure) - _half_wall
	if layout == Layout.CELLS:
		var nearest := 0
		var first := INF
		for i in range(sites.size()):
			var d := p.distance_squared_to(sites[i])
			if d < first:
				first = d
				nearest = i
		# Distance to the closest Voronoi bisector, in metres (unlike F2-F1).
		var border := INF
		for i in range(sites.size()):
			if i == nearest:
				continue
			var separation := sites[i].distance_to(sites[nearest])
			border = minf(border, (p.distance_squared_to(sites[i]) - first) / (2.0 * separation))
		var partitions := border - _half_wall
		# Delete the central portions completely, floor to roof. The visible
		# perimeter remains a record of where separate cells once met.
		partitions = maxf(partitions, clearing_radius - Vector2(p.x, p.z).length())
		# Each ground-level seed gets an arched passage to the common space.
		# This keeps all sixteen rooms reachable for every supported seed.
		for site in floor_sites:
			var end := Vector2(site.x, site.z)
			var horizontal := Vector2(p.x, p.z)
			var t := clampf(horizontal.dot(end) / end.length_squared(), 0.0, 1.0)
			var distance_to_route := (horizontal - end * t).length()
			var passage := Vector2(distance_to_route, maxf(p.y - 1.6, 0.0)).length() - 1.2
			partitions = maxf(partitions, -passage)
		# Cell membranes terminate in the surrounding shell.
		partitions = maxf(partitions, enclosure)
		solid = minf(solid, partitions)
	# A shared south entrance continues right to the centre. Its opening is
	# also cut through collision, with a 3.2 m span and a rounded lintel.
	var entry := maxf(Vector2(p.x, maxf(p.y - 1.6, 0.0)).length() - 1.6, -p.z)
	solid = maxf(solid, -entry)
	return solid

func get_spawn_position() -> Vector3:
	return to_global(Vector3(0, 0.08, 12.8))

func get_height_at_world_position(_world_position: Vector3) -> float:
	return global_position.y

func apply_grid_config(config: Dictionary) -> void:
	if config.has("floor"):
		create_floor = str(config.floor).to_lower() not in ["false", "0"]
	if config.has("seed"):
		seed_value = int(config.seed)
	if config.has("softness"):
		softness = clampf(float(config.softness), 0.0, 0.9)
	if config.has("clearing_radius"):
		clearing_radius = clampf(float(config.clearing_radius), 3.5, 5.5)
	if config.has("box_size"):
		box_size = clampf(float(config.box_size), 0.4, 0.75)
	if is_node_ready():
		regenerate()

func _make_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.position.y = -0.16
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	generated.add_child(floor_body)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 13.8
	mesh.bottom_radius = 13.8
	mesh.height = 0.32
	mesh.radial_segments = 96
	var surface := MeshInstance3D.new()
	surface.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("573247") if layout == Layout.WOMB else Color("293f50")
	material.roughness = 0.75
	surface.material_override = material
	floor_body.add_child(surface)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 13.8
	shape.height = 0.32
	collision.shape = shape
	floor_body.add_child(collision)

func _make_lights() -> void:
	var positions := [Vector3(0, 4.5, 0), Vector3(-5, 2.4, 3), Vector3(5, 2.4, -3), Vector3(0, 2, 11)]
	for i in range(positions.size()):
		var light := OmniLight3D.new()
		light.position = positions[i]
		light.light_color = Color("ffbd9f") if layout == Layout.WOMB else Color("b3ebdf")
		light.light_energy = 1.5 if i == 0 else 0.7
		light.omni_range = 15.0 if i == 0 else 9.0
		# Only the central light casts shadows; keep the room affordable in VR.
		light.shadow_enabled = i == 0
		generated.add_child(light)
