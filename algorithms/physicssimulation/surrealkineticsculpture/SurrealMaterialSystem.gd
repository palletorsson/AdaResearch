
# Material system for the surreal sculpture
class_name SurrealMaterialSystem
extends Node

var tanguy_materials: Array[StandardMaterial3D] = []
var niki_materials: Array[Array] = []  # Array of color schemes
var accent_materials: Array[StandardMaterial3D] = []

func _ready():
	create_tanguy_materials()
	create_niki_color_schemes()
	create_accent_materials()

func create_tanguy_materials():
	"""Create dark, mechanical materials for Tanguy elements"""
	# Main black metallic
	var black_metal = StandardMaterial3D.new()
	black_metal.albedo_color = Color(0.08, 0.08, 0.1, 1.0)
	black_metal.metallic = 0.9
	black_metal.roughness = 0.2
	black_metal.clearcoat_enabled = true
	black_metal.clearcoat = 0.5
	tanguy_materials.append(black_metal)
	
	# Dark iron
	var dark_iron = StandardMaterial3D.new()
	dark_iron.albedo_color = Color(0.12, 0.1, 0.1, 1.0)
	dark_iron.metallic = 0.7
	dark_iron.roughness = 0.4
	tanguy_materials.append(dark_iron)

func create_niki_color_schemes():
	"""Create bright, colorful materials for Niki elements"""
	# Color scheme 0: Pink/Magenta
	var pink_scheme = []
	var pink_base = StandardMaterial3D.new()
	pink_base.albedo_color = Color(1.0, 0.2, 0.6, 1.0)
	pink_base.roughness = 0.3
	pink_base.emission_enabled = true
	pink_base.emission = Color(0.3, 0.1, 0.2, 1.0)
	pink_scheme.append(pink_base)
	
	var pink_accent = StandardMaterial3D.new()
	pink_accent.albedo_color = Color(1.0, 0.6, 0.8, 1.0)
	pink_accent.roughness = 0.2
	pink_scheme.append(pink_accent)
	
	niki_materials.append(pink_scheme)
	
	# Color scheme 1: Blue/Cyan
	var blue_scheme = []
	var blue_base = StandardMaterial3D.new()
	blue_base.albedo_color = Color(0.2, 0.6, 1.0, 1.0)
	blue_base.roughness = 0.3
	blue_base.emission_enabled = true
	blue_base.emission = Color(0.1, 0.2, 0.3, 1.0)
	blue_scheme.append(blue_base)
	
	var blue_accent = StandardMaterial3D.new()
	blue_accent.albedo_color = Color(0.6, 0.8, 1.0, 1.0)
	blue_accent.roughness = 0.2
	blue_scheme.append(blue_accent)
	
	niki_materials.append(blue_scheme)
	
	# Color scheme 2: Yellow/Orange
	var yellow_scheme = []
	var yellow_base = StandardMaterial3D.new()
	yellow_base.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	yellow_base.roughness = 0.3
	yellow_base.emission_enabled = true
	yellow_base.emission = Color(0.3, 0.2, 0.1, 1.0)
	yellow_scheme.append(yellow_base)
	
	var yellow_accent = StandardMaterial3D.new()
	yellow_accent.albedo_color = Color(1.0, 0.9, 0.6, 1.0)
	yellow_accent.roughness = 0.2
	yellow_scheme.append(yellow_accent)
	
	niki_materials.append(yellow_scheme)

func create_accent_materials():
	"""Create small accent materials for details"""
	var white_accent = StandardMaterial3D.new()
	white_accent.albedo_color = Color(0.9, 0.9, 0.95, 1.0)
	white_accent.emission_enabled = true
	white_accent.emission = Color(0.2, 0.2, 0.25, 1.0)
	accent_materials.append(white_accent)

func get_tanguy_material() -> StandardMaterial3D:
	"""Get black mechanical material for Tanguy elements"""
	return tanguy_materials[0] if tanguy_materials.size() > 0 else null

func get_niki_material(scheme: int, variant: int) -> StandardMaterial3D:
	"""Get colorful material for Niki elements"""
	if scheme < niki_materials.size():
		var color_scheme = niki_materials[scheme]
		return color_scheme[variant % color_scheme.size()]
	return null

func get_accent_material() -> StandardMaterial3D:
	"""Get accent material for details"""
	return accent_materials[0] if accent_materials.size() > 0 else null
