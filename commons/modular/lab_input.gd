extends Node3D
## A static research input from the shared prefab catalogue. Original geometry
## stays at authored scale; only its base is aligned to the recipe insertion point.
var token := ""
var original: Node3D
var source_scene := ""
static var _sources: Dictionary = {}

static func sources() -> Dictionary:
	if not _sources.is_empty(): return _sources
	var catalogue: Dictionary = {}
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/primitive-prefabs.json"))
	for entry in data.prefabs: catalogue[str(entry.id)] = entry
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/modular/lab.json"))
	for entry in spec.sources:
		var item: Dictionary = catalogue.get(str(entry.id), {}).duplicate(true)
		item.merge(entry, true)
		_sources[str(entry.id)] = item
	return _sources

func _ready() -> void:
	var spec: Dictionary = sources().get(token, {})
	source_scene = str(spec.get("scene", ""))
	if source_scene.is_empty() or not ResourceLoader.exists(source_scene):
		push_error("lab input has no original scene: " + token);return
	original = (load(source_scene) as PackedScene).instantiate() as Node3D
	original.name = "Original"
	if not spec.get("config", {}).is_empty():
		if original.has_method("apply_grid_config"): original.apply_grid_config(spec.config)
		else:
			push_error("lab input does not accept config: " + token);return
	add_child(original)
	var box: AABB = bounds(original, self)
	if box.size.length() < .0001:
		push_error("lab input has no synchronous geometry: " + token);return
	original.position.y -= box.position.y
	# Preserve bodies/colliders as authored but prevent gravity and autonomous
	# animation from altering the arrangement used by the geometry preview.
	for body in original.find_children("*", "RigidBody3D", true, false): body.freeze = true
	if original is RigidBody3D: original.freeze = true
	for item in [original] + original.find_children("*", "Node", true, false):
		item.set_process(false);item.set_physics_process(false)
	set_meta("source_scene", source_scene)
	set_meta("prefab", token)

static func bounds(node: Node3D, frame: Node3D) -> AABB:
	var result := AABB();var first := true
	var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D: meshes.append(node)
	for mesh in meshes:
		if mesh.mesh == null: continue
		var box: AABB = (frame.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		result = box if first else result.merge(box);first = false
	return result
