extends RefCounted
## A quiet surface treatment. Geometry, triggers and motion remain the originals.

static func material(colour: Color, glow := 0.18) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = colour
	result.roughness = 0.95
	result.emission_enabled = glow > 0.0
	result.emission = colour
	result.emission_energy_multiplier = glow
	return result

static func blocks(host: Node, colour := Color("e2e6e5")) -> void:
	var finish := material(colour)
	for mesh in host.find_children("*", "MeshInstance3D", true, false):
		if mesh.name == "MetreJoints":
			mesh.hide() # An inset visual mark, never a collision surface.
		else:
			mesh.material_override = finish
