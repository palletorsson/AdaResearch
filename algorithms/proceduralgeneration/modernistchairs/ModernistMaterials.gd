# ModernistMaterials.gd
# Material system for modernist chair generation
class_name ModernistMaterials
extends Node

var materials: Dictionary = {}

func _ready():
	create_modernist_materials()

func create_modernist_materials():
	"""Create a comprehensive library of modernist materials"""
	
	# METALS
	# Chrome - high reflectivity, minimal roughness
	var chrome = StandardMaterial3D.new()
	chrome.albedo_color = Color(0.9, 0.9, 0.95, 1.0)
	chrome.metallic = 1.0
	chrome.roughness = 0.1
	chrome.clearcoat_enabled = true
	chrome.clearcoat = 0.8
	materials["chrome"] = chrome
	
	# Brushed Steel - directional texture
	var brushed_steel = StandardMaterial3D.new()
	brushed_steel.albedo_color = Color(0.8, 0.82, 0.85, 1.0)
	brushed_steel.metallic = 0.9
	brushed_steel.roughness = 0.3
	materials["brushed_steel"] = brushed_steel
	
	# Black Steel - industrial aesthetic
	var black_steel = StandardMaterial3D.new()
	black_steel.albedo_color = Color(0.12, 0.12, 0.15, 1.0)
	black_steel.metallic = 0.8
	black_steel.roughness = 0.2
	materials["black_steel"] = black_steel
	
	# FABRICS
	# Canvas - natural textile
	var canvas = StandardMaterial3D.new()
	canvas.albedo_color = Color(0.9, 0.85, 0.75, 1.0)
	canvas.roughness = 0.9
	canvas.metallic = 0.0
	materials["canvas"] = canvas
	
	# Black Leather - luxury material
	var black_leather = StandardMaterial3D.new()
	black_leather.albedo_color = Color(0.1, 0.08, 0.08, 1.0)
	black_leather.roughness = 0.4
	black_leather.metallic = 0.0
	materials["black_leather"] = black_leather
	
	# PLASTICS
	# Molded Fiberglass - smooth modern surface
	var fiberglass = StandardMaterial3D.new()
	fiberglass.albedo_color = Color(0.95, 0.95, 0.95, 1.0)
	fiberglass.roughness = 0.2
	fiberglass.metallic = 0.0
	materials["fiberglass"] = fiberglass
	
	# PRIMARY COLORS (De Stijl palette)
	# Pure Red
	var red_primary = StandardMaterial3D.new()
	red_primary.albedo_color = Color(0.9, 0.0, 0.0, 1.0)
	red_primary.roughness = 0.3
	red_primary.metallic = 0.0
	materials["red_primary"] = red_primary
	
	# Pure Blue
	var blue_primary = StandardMaterial3D.new()
	blue_primary.albedo_color = Color(0.0, 0.0, 0.9, 1.0)
	blue_primary.roughness = 0.3
	blue_primary.metallic = 0.0
	materials["blue_primary"] = blue_primary
	
	# Pure Yellow
	var yellow_primary = StandardMaterial3D.new()
	yellow_primary.albedo_color = Color(0.9, 0.9, 0.0, 1.0)
	yellow_primary.roughness = 0.3
	yellow_primary.metallic = 0.0
	materials["yellow_primary"] = yellow_primary
	
	# TRANSPARENT MATERIALS
	# Clear Acrylic
	var clear_acrylic = StandardMaterial3D.new()
	clear_acrylic.albedo_color = Color(0.95, 0.98, 1.0, 0.1)
	clear_acrylic.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear_acrylic.roughness = 0.0
	clear_acrylic.metallic = 0.0
	clear_acrylic.refraction_enabled = true
	# clear_acrylic.refraction = 1.49  # Godot 3.x parameter not available in Godot 4
	materials["clear_acrylic"] = clear_acrylic
	
	# Tinted Glass
	var tinted_glass = StandardMaterial3D.new()
	tinted_glass.albedo_color = Color(0.7, 0.8, 0.9, 0.3)
	tinted_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tinted_glass.roughness = 0.0
	tinted_glass.metallic = 0.0
	materials["tinted_glass"] = tinted_glass
	
	# MINIMALIST MATERIALS
	# Pure White
	var pure_white = StandardMaterial3D.new()
	pure_white.albedo_color = Color(0.98, 0.98, 0.98, 1.0)
	pure_white.roughness = 0.2
	pure_white.metallic = 0.0
	materials["pure_white"] = pure_white
	
	# Pure Black
	var pure_black = StandardMaterial3D.new()
	pure_black.albedo_color = Color(0.02, 0.02, 0.02, 1.0)
	pure_black.roughness = 0.3
	pure_black.metallic = 0.0
	materials["pure_black"] = pure_black
	
	# EXPERIMENTAL MATERIALS
	# Holographic - futuristic modernism
	var holographic = StandardMaterial3D.new()
	holographic.albedo_color = Color(0.8, 0.9, 1.0, 0.7)
	holographic.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	holographic.emission_enabled = true
	holographic.emission = Color(0.3, 0.5, 0.8, 1.0)
	holographic.emission_energy = 0.5
	materials["holographic"] = holographic
	
	# Memory Foam - soft responsive material
	var memory_foam = StandardMaterial3D.new()
	memory_foam.albedo_color = Color(0.7, 0.6, 0.5, 1.0)
	memory_foam.roughness = 0.8
	memory_foam.metallic = 0.0
	materials["memory_foam"] = memory_foam

func get_material(name: String) -> StandardMaterial3D:
	"""Get a material by name"""
	return materials.get(name, materials["pure_white"])

func get_random_modernist_material() -> StandardMaterial3D:
	"""Get a random material from the modernist palette"""
	var material_names = ["chrome", "black_steel", "canvas", "fiberglass", 
						 "red_primary", "blue_primary", "yellow_primary", 
						 "pure_white", "pure_black"]
	return materials[material_names[randi() % material_names.size()]]

func get_primary_color_set() -> Array[StandardMaterial3D]:
	"""Get the primary color set for De Stijl inspired designs"""
	return [materials["red_primary"], materials["blue_primary"], 
			materials["yellow_primary"], materials["pure_white"], 
			materials["pure_black"]]

func get_metal_set() -> Array[StandardMaterial3D]:
	"""Get metallic materials for industrial designs"""
	return [materials["chrome"], materials["brushed_steel"], materials["black_steel"]]

func get_transparent_set() -> Array[StandardMaterial3D]:
	"""Get transparent materials for ethereal designs"""
	return [materials["clear_acrylic"], materials["tinted_glass"], materials["holographic"]]

func apply_material_with_variation(mesh_instance: MeshInstance3D, base_material_name: String, variation: float = 0.1):
	"""Apply material with slight color variation"""
	var base_material = get_material(base_material_name)
	var varied_material = base_material.duplicate()
	
	# Add slight color variation
	var base_color = base_material.albedo_color
	var hue_shift = (randf() - 0.5) * variation
	var saturation_shift = (randf() - 0.5) * variation * 0.5
	var value_shift = (randf() - 0.5) * variation * 0.3
	
	# Convert to HSV, modify, convert back
	var hsv = rgb_to_hsv(base_color)
	hsv.x = fmod(hsv.x + hue_shift + 1.0, 1.0)
	hsv.y = clamp(hsv.y + saturation_shift, 0.0, 1.0)
	hsv.z = clamp(hsv.z + value_shift, 0.0, 1.0)
	
	varied_material.albedo_color = hsv_to_rgb(hsv)
	mesh_instance.material_override = varied_material

func rgb_to_hsv(color: Color) -> Vector3:
	"""Convert RGB to HSV"""
	var r = color.r
	var g = color.g
	var b = color.b
	
	var max_val = max(r, max(g, b))
	var min_val = min(r, min(g, b))
	var delta = max_val - min_val
	
	var h = 0.0
	var s = 0.0 if max_val == 0.0 else delta / max_val
	var v = max_val
	
	if delta != 0.0:
		if max_val == r:
			h = (g - b) / delta
		elif max_val == g:
			h = 2.0 + (b - r) / delta
		else:
			h = 4.0 + (r - g) / delta
		h /= 6.0
		if h < 0.0:
			h += 1.0
	
	return Vector3(h, s, v)

func hsv_to_rgb(hsv: Vector3) -> Color:
	"""Convert HSV to RGB"""
	var h = hsv.x * 6.0
	var s = hsv.y
	var v = hsv.z
	
	var i = int(h)
	var f = h - i
	var p = v * (1.0 - s)
	var q = v * (1.0 - s * f)
	var t = v * (1.0 - s * (1.0 - f))
	
	match i % 6:
		0: return Color(v, t, p, 1.0)
		1: return Color(q, v, p, 1.0)
		2: return Color(p, v, t, 1.0)
		3: return Color(p, q, v, 1.0)
		4: return Color(t, p, v, 1.0)
		_: return Color(v, p, q, 1.0)
