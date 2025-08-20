
class_name RhizomaticMaterials
extends Node

var materials: Dictionary = {}

func _ready():
	create_material_library()

func create_material_library():
	"""Create materials for different maze elements"""
	# Tunnel material
	var tunnel_mat = StandardMaterial3D.new()
	tunnel_mat.albedo_color = Color(0.7, 0.8, 0.9, 1.0)
	tunnel_mat.roughness = 0.8
	tunnel_mat.metallic = 0.1
	materials["tunnel"] = tunnel_mat
	
	# Chamber material
	var chamber_mat = StandardMaterial3D.new()
	chamber_mat.albedo_color = Color(0.6, 0.7, 0.8, 1.0)
	chamber_mat.roughness = 0.9
	materials["chamber"] = chamber_mat
	
	# Growth material
	var growth_mat = StandardMaterial3D.new()
	growth_mat.albedo_color = Color(0.4, 0.6, 0.3, 1.0)
	growth_mat.roughness = 1.0
	materials["growth"] = growth_mat
	
	# Tendril material
	var tendril_mat = StandardMaterial3D.new()
	tendril_mat.albedo_color = Color(0.5, 0.4, 0.3, 1.0)
	tendril_mat.roughness = 0.9
	materials["tendril"] = tendril_mat

func get_tunnel_material(properties: Dictionary = {}) -> StandardMaterial3D:
	return materials.get("tunnel", null)

func get_chamber_material() -> StandardMaterial3D:
	return materials.get("chamber", null)

func get_growth_material() -> StandardMaterial3D:
	return materials.get("growth", null)

func get_tendril_material() -> StandardMaterial3D:
	return materials.get("tendril", null)
