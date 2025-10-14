extends Node3D

var _static_body: StaticBody3D
var _light_node: OmniLight3D
var _collision_shape: CollisionShape3D
var _fixture_meshes: Array = []
var _default_light_energy: float = 1.0
var _initialized := false

func _ready():
	_initialize_nodes()

func set_light_intensity(intensity: float) -> void:
	_initialize_nodes()
	if not _light_node:
		return
	_light_node.light_energy = max(intensity, 0.0)

func reset_light_intensity() -> void:
	_initialize_nodes()
	if _light_node:
		_light_node.light_energy = _default_light_energy

func set_fixture_hidden(hidden: bool) -> void:
	_initialize_nodes()
	if _collision_shape:
		_collision_shape.disabled = hidden
	for mesh in _fixture_meshes:
		mesh.visible = not hidden

func _initialize_nodes() -> void:
	if _initialized:
		return
	_static_body = get_node_or_null("StaticBody3D")
	if _static_body:
		_light_node = _static_body.get_node_or_null("OmniLight3D")
		_collision_shape = _static_body.get_node_or_null("CollisionShape3D")
		_fixture_meshes = _collect_fixture_meshes()
	if _light_node:
		_default_light_energy = _light_node.light_energy
	_initialized = true

func _collect_fixture_meshes() -> Array:
	var meshes: Array = []
	if not _static_body:
		return meshes
	var candidates = [
		_static_body.get_node_or_null("MeshInstance3D_lightbody"),
		_static_body.get_node_or_null("MeshInstance3D")
	]
	for candidate in candidates:
		if candidate and candidate is Node3D and candidate not in meshes:
			meshes.append(candidate)
	for child in _static_body.get_children():
		if child is MeshInstance3D and child not in meshes:
			meshes.append(child)
	return meshes
