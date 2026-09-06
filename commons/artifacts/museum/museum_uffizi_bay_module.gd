extends Node3D
class_name MuseumUffiziBayModule

const WALL_RUN_SCENE := preload("res://commons/artifacts/museum/museum_wall_run.tscn")

## Repeatable Uffizi gallery bay assembled from exact one-metre parts.
## The open west/east sockets are the endless-museum negotiation layer.

@export_group("Grid contract")
@export var length_cells: int = 8
@export var depth_cells: int = 8
@export var wall_height: float = 4.0
@export var socket_width: float = 3.0

@export_group("Surface")
@export var finish: String = "uffizi_stone"
@export var wear: float = 0.06
@export var show_socket_markers: bool = false
@export var enable_lights: bool = true

var _built := false
var _stone := StandardMaterial3D.new()
var _stone_alt := StandardMaterial3D.new()
var _floor := StandardMaterial3D.new()
var _floor_alt := StandardMaterial3D.new()
var _trim := StandardMaterial3D.new()
var _bronze := StandardMaterial3D.new()
var _glass := StandardMaterial3D.new()


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data.keys():
		set_meta("config_%s" % str(key), config_data[key])
	_read_metadata_overrides()
	if _built:
		for child in get_children():
			child.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_length_cells"): length_cells = int(str(get_meta("config_length_cells")))
	if has_meta("config_depth_cells"): depth_cells = int(str(get_meta("config_depth_cells")))
	if has_meta("config_wall_height"): wall_height = float(str(get_meta("config_wall_height")))
	if has_meta("config_socket_width"): socket_width = float(str(get_meta("config_socket_width")))
	if has_meta("config_finish"): finish = str(get_meta("config_finish"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_show_socket_markers"):
		show_socket_markers = str(get_meta("config_show_socket_markers")).to_lower() in ["1", "true", "yes"]
	if has_meta("config_enable_lights"):
		enable_lights = str(get_meta("config_enable_lights")).to_lower() in ["1", "true", "yes"]


func _build() -> void:
	_built = true
	length_cells = maxi(length_cells, 4)
	depth_cells = maxi(depth_cells, 6)
	wall_height = maxf(wall_height, 3.0)
	socket_width = clampf(socket_width, 2.0, float(depth_cells) - 2.0)
	_build_materials()

	var contract := Node3D.new()
	contract.name = "BayContract_1m"
	contract.set_meta("grid_m", 1.0)
	contract.set_meta("module_cells", Vector3i(length_cells, int(ceil(wall_height)), depth_cells))
	contract.set_meta("socket_width_m", socket_width)
	add_child(contract)

	_build_floor(contract)
	_build_principal_wall(contract, -1.0, "PrincipalWallNorth")
	_build_principal_wall(contract, 1.0, "PrincipalWallSouth")
	_build_ceiling(contract)
	_build_thresholds(contract)
	_build_sockets(contract)
	_build_collision(contract)
	if enable_lights:
		_build_lighting(contract)


func _build_materials() -> void:
	_stone = _mat(Color(0.77, 0.72, 0.63), 0.82, 0.0)
	_stone_alt = _mat(Color(0.68, 0.62, 0.53), 0.88, 0.0)
	_floor = _mat(Color(0.31, 0.28, 0.24), 0.74, 0.02)
	_floor_alt = _mat(Color(0.38, 0.34, 0.29), 0.7, 0.02)
	_trim = _mat(Color(0.19, 0.18, 0.17), 0.48, 0.35)
	_bronze = _mat(Color(0.36, 0.24, 0.12), 0.38, 0.7)
	_glass = _mat(Color(0.56, 0.7, 0.76, 0.2), 0.16, 0.05)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED


func _build_floor(parent: Node3D) -> void:
	var floor_tiles := Node3D.new()
	floor_tiles.name = "FloorTiles_1m"
	parent.add_child(floor_tiles)
	var primary_transforms: Array[Transform3D] = []
	var alternate_transforms: Array[Transform3D] = []
	for x in range(length_cells):
		for z in range(depth_cells):
			var px: float = -float(length_cells) * 0.5 + float(x) + 0.5
			var pz: float = -float(depth_cells) * 0.5 + float(z) + 0.5
			var in_spine: bool = absf(pz) < 1.51
			var use_alternate: bool = in_spine or (x + z) % 2 != 0
			var transform := Transform3D(Basis.IDENTITY, Vector3(px, 0.035, pz))
			if use_alternate:
				alternate_transforms.append(transform)
			else:
				primary_transforms.append(transform)
			# Keep one cheap datum per 1 m tile so placement/validation can address
			# the grid without paying one draw node per square.
			var tile_datum := Marker3D.new()
			tile_datum.name = "Tile_%02d_%02d" % [x, z]
			tile_datum.position = Vector3(px, 0.035, pz)
			tile_datum.set_meta("grid_cell", Vector2i(x, z))
			floor_tiles.add_child(tile_datum)
	_add_multibox(floor_tiles, "FloorPrimaryBatch", primary_transforms, Vector3(0.985, 0.07, 0.985), _floor)
	_add_multibox(floor_tiles, "FloorAlternateBatch", alternate_transforms, Vector3(0.985, 0.07, 0.985), _floor_alt)
	floor_tiles.add_child(_box("SpineDatum", Vector3(0, 0.076, 0), Vector3(float(length_cells) - 0.4, 0.012, 0.035), _bronze))


func _add_multibox(parent: Node3D, node_name: String, transforms: Array[Transform3D], size: Vector3, material: Material) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	parent.add_child(instance)


func _build_principal_wall(parent: Node3D, side: float, node_name: String) -> void:
	var wall: Node3D = WALL_RUN_SCENE.instantiate()
	wall.name = node_name
	var z: float = side * (float(depth_cells) * 0.5 - 0.075)
	# The compact spec is the negotiation record: two prop-safe edge metres,
	# four protected feature metres, then two calm continuation metres.
	wall.set("run_spec", "service:2|feature:4|solid:2" if side < 0.0 else "solid:2|feature:4|service:2")
	wall.set("height", wall_height)
	wall.set("finish", finish)
	wall.set("enable_collision", false)
	wall.position = Vector3(0, 0, z)
	if side > 0.0:
		wall.rotation.y = PI
	parent.add_child(wall)


func _build_ceiling(parent: Node3D) -> void:
	var ceiling := Node3D.new()
	ceiling.name = "CeilingAndSkylight_1m"
	parent.add_child(ceiling)
	var roof_y: float = wall_height + 0.28
	for x in range(length_cells + 1):
		var px: float = -float(length_cells) * 0.5 + float(x)
		ceiling.add_child(_box("Beam_%02d" % x, Vector3(px, roof_y, 0), Vector3(0.13, 0.18, float(depth_cells)), _trim))
	for z in range(depth_cells):
		var pz: float = -float(depth_cells) * 0.5 + float(z) + 0.5
		ceiling.add_child(_box("GlassCell_%02d" % z, Vector3(0, roof_y + 0.02, pz), Vector3(float(length_cells) - 0.2, 0.035, 0.9), _glass))
	for x in range(length_cells):
		var px: float = -float(length_cells) * 0.5 + float(x) + 0.5
		ceiling.add_child(_box("LightCoffer_%02d" % x, Vector3(px, wall_height - 0.03, 0), Vector3(0.78, 0.05, 0.32), _emissive(Color(1.0, 0.88, 0.66), 1.25)))


func _build_thresholds(parent: Node3D) -> void:
	var thresholds := Node3D.new()
	thresholds.name = "Thresholds"
	parent.add_child(thresholds)
	var edge: float = float(length_cells) * 0.5
	for side in [-1.0, 1.0]:
		var x: float = side * edge
		thresholds.add_child(_box("Threshold_%s" % ("West" if side < 0 else "East"), Vector3(x, 0.015, 0), Vector3(0.16, 0.03, socket_width), _bronze))
		for z_side in [-1.0, 1.0]:
			var z: float = z_side * (socket_width * 0.5 + 0.18)
			thresholds.add_child(_box("Jamb_%s_%s" % [side, z_side], Vector3(x, wall_height * 0.5, z), Vector3(0.32, wall_height, 0.32), _stone_alt))


func _build_sockets(parent: Node3D) -> void:
	var edge: float = float(length_cells) * 0.5
	for data in [["SocketWest", -edge, Vector3.LEFT], ["SocketEast", edge, Vector3.RIGHT]]:
		var socket := Marker3D.new()
		socket.name = str(data[0])
		socket.position = Vector3(float(data[1]), 0, 0)
		socket.set_meta("port", "gallery_spine_3m")
		socket.set_meta("grid_m", 1.0)
		socket.set_meta("facing", data[2])
		parent.add_child(socket)
		if show_socket_markers:
			socket.add_child(_box("SocketMarker", Vector3(0, 1.5, 0), Vector3(0.08, 3.0, socket_width), _emissive(Color(0.1, 0.8, 0.72), 0.9)))


func _build_lighting(parent: Node3D) -> void:
	var lights := Node3D.new()
	lights.name = "Lighting"
	parent.add_child(lights)
	for x in [-2.0, 2.0]:
		var light := OmniLight3D.new()
		light.name = "GalleryLight_%s" % str(x)
		light.position = Vector3(x, wall_height - 0.45, 0)
		light.light_color = Color(1.0, 0.84, 0.66)
		light.light_energy = 1.4
		light.omni_range = 6.5
		light.shadow_enabled = false
		lights.add_child(light)


func _build_collision(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "ArchitecturalCollision"
	parent.add_child(body)
	_add_box_collision(body, "FloorCollision", Vector3(0, -0.09, 0), Vector3(float(length_cells), 0.18, float(depth_cells)))
	var wall_z: float = float(depth_cells) * 0.5 - 0.075
	_add_box_collision(body, "NorthWallCollision", Vector3(0, wall_height * 0.5, -wall_z), Vector3(float(length_cells), wall_height, 0.15))
	_add_box_collision(body, "SouthWallCollision", Vector3(0, wall_height * 0.5, wall_z), Vector3(float(length_cells), wall_height, 0.15))


func _add_box_collision(parent: StaticBody3D, shape_name: String, at: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = shape_name
	collision.position = at
	collision.shape = shape
	parent.add_child(collision)


func _box(node_name: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = mesh
	instance.material_override = material
	return instance


func _mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := _mat(color, 0.42, 0.05)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
