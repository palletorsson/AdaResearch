extends Node3D
## Sets the SpotLight3D color on the parent flashlight instance.
## Attach to the flashlight instance and set light_color in the inspector.

@export var light_color: Color = Color.WHITE

func _ready():
	# Find SpotLight3D in this flashlight
	var spot = _find_spot_light(self)
	if spot:
		spot.light_color = light_color
	else:
		push_warning("FlashlightColor: No SpotLight3D found in %s" % name)
	
	# Also tint the lens to match
	var lens = get_node_or_null("LensMesh")
	if lens and lens is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = light_color.lerp(Color.WHITE, 0.5)
		mat.emission_enabled = true
		mat.emission = light_color * 0.5
		mat.emission_energy_multiplier = 1.0
		mat.metallic = 0.1
		mat.roughness = 0.1
		lens.material_override = mat

func _find_spot_light(node: Node) -> SpotLight3D:
	for child in node.get_children():
		if child is SpotLight3D:
			return child
		var found = _find_spot_light(child)
		if found:
			return found
	return null
