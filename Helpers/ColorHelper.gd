extends Node
class_name ColorHelper

# Converts a Color object to a HEX string (e.g., "#FF5733")
static func color_to_hex(color: Color) -> String:
	return "#%02X%02X%02X" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]

# Creates a small square mesh as a color swatch
static func create_color_block(position: Vector3, color: Color) -> MeshInstance3D:
	var block = MeshInstance3D.new()
	block.mesh = BoxMesh.new()
	block.mesh.size = Vector3(0.3, 0.125, 0.01)  # Small square shape
	block.material_override = StandardMaterial3D.new()
	block.material_override.albedo_color = color
	block.position = position
	return block
