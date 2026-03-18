extends Node3D
## Sets the SpotLight3D color on the parent flashlight instance.
## Attach to the flashlight instance and set light_color in the inspector.

@export var light_color: Color = Color.WHITE
@export var target_path: NodePath

func _ready() -> void:
	var target_root = _resolve_target_root()
	
	# Find SpotLight3D in the target flashlight.
	var spot = _find_spot_light(target_root)
	if spot:
		spot.light_color = light_color
	else:
		push_warning("FlashlightColor: No SpotLight3D found in %s" % target_root.name)
	
	# Also tint the lens to match.
	var lens = _find_lens_mesh(target_root)
	if lens and lens is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = light_color.lerp(Color.WHITE, 0.5)
		mat.emission_enabled = true
		mat.emission = light_color * 0.5
		mat.emission_energy_multiplier = 1.0
		mat.metallic = 0.1
		mat.roughness = 0.1
		lens.material_override = mat

func _resolve_target_root() -> Node:
	if target_path != NodePath():
		var explicit_target = get_node_or_null(target_path)
		if explicit_target:
			return explicit_target
	
	if _find_spot_light(self):
		return self
	
	var parent = get_parent()
	if parent and _find_spot_light(parent):
		return parent
	
	return self

func _find_spot_light(node: Node) -> SpotLight3D:
	for child in node.get_children():
		if child is SpotLight3D:
			return child
		var found = _find_spot_light(child)
		if found:
			return found
	return null

func _find_lens_mesh(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D and child.name == "LensMesh":
			return child
		var found = _find_lens_mesh(child)
		if found:
			return found
	return null

func apply_grid_config(config: Dictionary) -> void:
	pass
