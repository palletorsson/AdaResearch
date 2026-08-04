
# Material management system
class_name OrganicMaterials
extends Node

var base_materials: Array[StandardMaterial3D] = []
var current_material_index: int = 0

func _ready() -> void:
	create_material_library()

func create_material_library() -> void:
	"""Create a library of organic materials"""
	# Metallic surface material
	var metallic = StandardMaterial3D.new()
	metallic.albedo_color = Color(0.8, 0.9, 1.0, 0.8)
	metallic.metallic = 0.8
	metallic.roughness = 0.2
	metallic.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base_materials.append(metallic)
	
	# Organic membrane material  
	var membrane = StandardMaterial3D.new()
	membrane.albedo_color = Color(1.0, 0.7, 0.8, 0.4)
	membrane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	membrane.roughness = 0.8
	base_materials.append(membrane)
	
	# Crystal material
	var crystal = StandardMaterial3D.new()
	crystal.albedo_color = Color(0.9, 0.95, 1.0, 0.6)
	crystal.metallic = 0.1
	crystal.roughness = 0.1
	crystal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base_materials.append(crystal)
	
	# Glowing interactive material
	var interactive = StandardMaterial3D.new()
	interactive.albedo_color = Color(0.2, 0.8, 1.0)
	interactive.emission_enabled = true
	interactive.emission = Color(0.2, 0.8, 1.0)
	interactive.emission_energy = 0.5
	base_materials.append(interactive)

func get_base_material() -> StandardMaterial3D:
	return base_materials[0] if base_materials.size() > 0 else null

func get_tunnel_material(index: int) -> StandardMaterial3D:
	return base_materials[index % base_materials.size()]

func get_detail_material(index: int = -1) -> StandardMaterial3D:
	# index < 0 keeps the old unseeded pick for any caller that doesn't care;
	# organic_space passes a draw from its own seeded RNG so a pinned space
	# gets the same materials as well as the same shapes.
	if index < 0:
		return base_materials[randi() % base_materials.size()]
	return base_materials[abs(index) % base_materials.size()]

func get_membrane_material() -> StandardMaterial3D:
	return base_materials[1] if base_materials.size() > 1 else base_materials[0]

func get_crystal_material() -> StandardMaterial3D:
	return base_materials[2] if base_materials.size() > 2 else base_materials[0]

func get_organic_material() -> StandardMaterial3D:
	return base_materials[1] if base_materials.size() > 1 else base_materials[0]

func get_interactive_material() -> StandardMaterial3D:
	return base_materials[3] if base_materials.size() > 3 else base_materials[0]
