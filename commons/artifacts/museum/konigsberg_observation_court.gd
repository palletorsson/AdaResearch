extends Node3D
class_name KonigsbergObservationCourt

## Dedicated-world host for the 50 x 32 m KonigsbergBridge artifact.
##
## The architecture does not redraw Euler's graph. A three-metre observation
## ring surrounds the full-scale artifact, level with its landmasses, while two
## visually distinct access tongues connect museum circulation to the graph.
## Those tongues are explicitly museum infrastructure, not graph edges.

const ARTIFACT_SCENE := preload("res://algorithms/graphtheory/graphspace3d/konigsberg3d.tscn")

const SITE_SIZE_M := Vector3(56.0, 5.0, 38.0)
const BODY_SIZE_M := Vector3(50.0, 4.9, 32.0)
const APRON_M := 3.0
const DECK_Y := 2.5
const SITE_CENTER_OFFSET := Vector3(-0.5, 0.0, -0.5)
const TILE_SIZE := Vector3(1.0, 0.16, 1.0)

@export_enum("blocked", "walk", "circuit", "severed") var parity: String = "blocked"
@export var enable_collision: bool = true
@export var show_access_labels: bool = true

var _artifact: Node3D
var _collision_body: StaticBody3D
var _stone: StandardMaterial3D
var _bronze: StandardMaterial3D
var _access: StandardMaterial3D


func _ready() -> void:
	_build_materials()
	_build_observation_ring()
	_build_outer_parapet()
	_build_inner_guard()
	_build_access_tongues()
	_build_artifact()
	if show_access_labels:
		_build_access_label()
	set_meta("dedicated_world_site_id", "world-konigsberg3d-c025c77")
	set_meta("site_formula", "perimeter_observation_court")
	set_meta("artifact_lookup", "KonigsbergBridge")
	set_meta("artifact_order_index", 710)
	set_meta("return_artifact_lookup", "force_directed_layout")


func apply_grid_config(config: Dictionary) -> void:
	if config.has("parity"):
		parity = str(config["parity"])
	if config.has("enable_collision"):
		enable_collision = _as_bool(config["enable_collision"])
	if config.has("show_access_labels"):
		show_access_labels = _as_bool(config["show_access_labels"])


func site_contract() -> Dictionary:
	return {
		"site_id": "world-konigsberg3d-c025c77",
		"formula": "perimeter_observation_court",
		"grid_m": 1.0,
		"site_envelope_m": SITE_SIZE_M,
		"body_m": BODY_SIZE_M,
		"apron_m": APRON_M,
		"body_scale": Vector3.ONE,
		"floor_tile_count": _ring_tile_count(),
		"access_tongues": 2,
		"continuous_player_route": true,
		"graph_edges_added": 0,
	}


func artifact_instance() -> Node3D:
	return _artifact


func _build_materials() -> void:
	_stone = StandardMaterial3D.new()
	_stone.albedo_color = Color("#c9c0ae")
	_stone.roughness = 0.82
	_stone.metallic = 0.0
	_stone.vertex_color_use_as_albedo = true

	_bronze = StandardMaterial3D.new()
	_bronze.albedo_color = Color("#46382b")
	_bronze.roughness = 0.42
	_bronze.metallic = 0.72

	_access = StandardMaterial3D.new()
	_access.albedo_color = Color("#242a2d")
	_access.roughness = 0.66
	_access.metallic = 0.38


func _build_observation_ring() -> void:
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = TILE_SIZE
	tile_mesh.material = _stone

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = tile_mesh
	mm.instance_count = _ring_tile_count()

	var index := 0
	for z in range(int(SITE_SIZE_M.z)):
		for x in range(int(SITE_SIZE_M.x)):
			if not _is_ring_cell(x, z):
				continue
			var local_x := float(x) - SITE_SIZE_M.x * 0.5 + 0.5
			var local_z := float(z) - SITE_SIZE_M.z * 0.5 + 0.5
			var transform := Transform3D(Basis(), SITE_CENTER_OFFSET + Vector3(local_x, DECK_Y - TILE_SIZE.y * 0.5, local_z))
			mm.set_instance_transform(index, transform)
			var alternate := float((x + z) & 1) * 0.035
			mm.set_instance_color(index, Color(0.91 - alternate, 0.89 - alternate, 0.84 - alternate, 1.0))
			index += 1

	var floor := MultiMeshInstance3D.new()
	floor.name = "OneMetreObservationTiles"
	floor.multimesh = mm
	add_child(floor)

	_collision_body = StaticBody3D.new()
	_collision_body.name = "CourtCollision"
	add_child(_collision_body)
	if enable_collision:
		_add_collision_box(Vector3(56.0, TILE_SIZE.y, 3.0), SITE_CENTER_OFFSET + Vector3(0.0, DECK_Y - TILE_SIZE.y * 0.5, -17.5))
		_add_collision_box(Vector3(56.0, TILE_SIZE.y, 3.0), SITE_CENTER_OFFSET + Vector3(0.0, DECK_Y - TILE_SIZE.y * 0.5, 17.5))
		_add_collision_box(Vector3(3.0, TILE_SIZE.y, 32.0), SITE_CENTER_OFFSET + Vector3(-26.5, DECK_Y - TILE_SIZE.y * 0.5, 0.0))
		_add_collision_box(Vector3(3.0, TILE_SIZE.y, 32.0), SITE_CENTER_OFFSET + Vector3(26.5, DECK_Y - TILE_SIZE.y * 0.5, 0.0))


func _build_outer_parapet() -> void:
	var y := DECK_Y + 0.55
	_add_box("OuterNorthWest", Vector3(26.0, 1.1, 0.26), SITE_CENTER_OFFSET + Vector3(-15.0, y, -18.87), _stone, true)
	_add_box("OuterNorthEast", Vector3(26.0, 1.1, 0.26), SITE_CENTER_OFFSET + Vector3(15.0, y, -18.87), _stone, true)
	_add_box("OuterSouthWest", Vector3(26.0, 1.1, 0.26), SITE_CENTER_OFFSET + Vector3(-15.0, y, 18.87), _stone, true)
	_add_box("OuterSouthEast", Vector3(26.0, 1.1, 0.26), SITE_CENTER_OFFSET + Vector3(15.0, y, 18.87), _stone, true)
	_add_box("OuterWest", Vector3(0.26, 1.1, 38.0), SITE_CENTER_OFFSET + Vector3(-27.87, y, 0.0), _stone, true)
	_add_box("OuterEast", Vector3(0.26, 1.1, 38.0), SITE_CENTER_OFFSET + Vector3(27.87, y, 0.0), _stone, true)


func _build_inner_guard() -> void:
	var y := DECK_Y + 0.72
	# Eight-metre openings at north and south expose the two museum-access
	# tongues. The remaining inner edge is guarded without entering the body.
	_add_box("InnerNorthWest", Vector3(21.0, 0.12, 0.12), SITE_CENTER_OFFSET + Vector3(-14.5, y, -16.0), _bronze, false)
	_add_box("InnerNorthEast", Vector3(21.0, 0.12, 0.12), SITE_CENTER_OFFSET + Vector3(14.5, y, -16.0), _bronze, false)
	_add_box("InnerSouthWest", Vector3(21.0, 0.12, 0.12), SITE_CENTER_OFFSET + Vector3(-14.5, y, 16.0), _bronze, false)
	_add_box("InnerSouthEast", Vector3(21.0, 0.12, 0.12), SITE_CENTER_OFFSET + Vector3(14.5, y, 16.0), _bronze, false)
	_add_box("InnerWest", Vector3(0.12, 0.12, 32.0), SITE_CENTER_OFFSET + Vector3(-25.0, y, 0.0), _bronze, false)
	_add_box("InnerEast", Vector3(0.12, 0.12, 32.0), SITE_CENTER_OFFSET + Vector3(25.0, y, 0.0), _bronze, false)


func _build_access_tongues() -> void:
	# These widen the tangent between the observation deck and the north/south
	# circular landmasses. Dark metal distinguishes museum circulation from the
	# stone bridges which constitute Euler's graph.
	_add_box("MuseumAccessNorth", Vector3(2.0, 0.16, 4.4), SITE_CENTER_OFFSET + Vector3(0.0, DECK_Y - 0.08, -14.2), _access, true)
	_add_box("MuseumAccessSouth", Vector3(2.0, 0.16, 4.4), SITE_CENTER_OFFSET + Vector3(0.0, DECK_Y - 0.08, 14.2), _access, true)


func _build_artifact() -> void:
	var instance := ARTIFACT_SCENE.instantiate()
	if not (instance is Node3D):
		push_error("KonigsbergObservationCourt: source artifact is not Node3D")
		return
	_artifact = instance as Node3D
	_artifact.name = "KonigsbergBridge_FullScale"
	_artifact.position = SITE_CENTER_OFFSET
	_artifact.scale = Vector3.ONE
	if "parity" in _artifact:
		_artifact.set("parity", parity)
	add_child(_artifact)
	_suppress_demo_chrome(_artifact)
	call_deferred("_suppress_demo_chrome", _artifact)


func _build_access_label() -> void:
	var label := Label3D.new()
	label.name = "AccessIsNotGraphEdge"
	label.text = "MUSEUM ACCESS  /  NOT A GRAPH EDGE"
	label.font_size = 64
	label.pixel_size = 0.006
	label.outline_size = 10
	label.modulate = Color("#f3b562")
	label.position = SITE_CENTER_OFFSET + Vector3(0.0, DECK_Y + 0.18, 17.0)
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(label)


func _suppress_demo_chrome(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for child in node.get_children():
		if child is Camera3D:
			(child as Camera3D).current = false
		elif child is CanvasLayer:
			(child as CanvasLayer).visible = false
		elif child is DirectionalLight3D:
			(child as DirectionalLight3D).visible = false
		_suppress_demo_chrome(child)


func _ring_tile_count() -> int:
	return int(SITE_SIZE_M.x * SITE_SIZE_M.z - BODY_SIZE_M.x * BODY_SIZE_M.z)


func _is_ring_cell(x: int, z: int) -> bool:
	return x < int(APRON_M) or x >= int(SITE_SIZE_M.x - APRON_M) \
		or z < int(APRON_M) or z >= int(SITE_SIZE_M.z - APRON_M)


func _add_box(node_name: String, size: Vector3, position: Vector3, material: Material, collision: bool) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	add_child(instance)
	if collision and enable_collision:
		_add_collision_box(size, position)
	return instance


func _add_collision_box(size: Vector3, position: Vector3) -> void:
	if _collision_body == null:
		_collision_body = StaticBody3D.new()
		_collision_body.name = "CourtCollision"
		add_child(_collision_body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = position
	_collision_body.add_child(collider)


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	return str(value).to_lower() in ["true", "1", "yes", "on"]
