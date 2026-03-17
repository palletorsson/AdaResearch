class_name FacadeMaterials
extends RefCounted

## Static factory methods for facade materials.
## Provides stone, plaster, and marble materials for CSG facade elements.
## Used by CsgFacadeElements and FacadePlanImporter.


## Create a stone material with slight roughness variation.
## Simulates cut stone or ashlar blocks.
static func stone_material(color: Color, p_roughness: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = p_roughness
	mat.metallic = 0.0
	mat.metallic_specular = 0.3
	# Subtle vertex color variation for surface noise
	mat.vertex_color_use_as_albedo = false
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	return mat


## Create a smooth plaster/stucco material.
## Lower roughness gives that polished lime-wash look.
static func plaster_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.0
	mat.metallic_specular = 0.4
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	return mat


## Create a marble material using the marble gdshader.
## Returns a ShaderMaterial with configurable base and vein colors.
static func marble_material(
	base_color: Color = Color(0.9, 0.88, 0.85),
	vein_color: Color = Color(0.4, 0.38, 0.35),
	p_roughness: float = 0.3,
	vein_scale: float = 8.0
) -> ShaderMaterial:
	var shader := load("res://commons/mesh_grammar/shaders/marble.gdshader") as Shader
	if not shader:
		# Fallback to a standard material if shader not found
		push_warning("FacadeMaterials: marble.gdshader not found, using fallback")
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = base_color
		fallback.roughness = p_roughness
		# Return as ShaderMaterial is not possible; caller should handle
		return null

	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("base_color", base_color)
	mat.set_shader_parameter("vein_color", vein_color)
	mat.set_shader_parameter("roughness", p_roughness)
	mat.set_shader_parameter("vein_scale", vein_scale)
	return mat


## Create a material from a hex color string (e.g. "#d4c5a9").
## Defaults to stone material.
static func from_hex(hex_color: String, material_type: String = "stone") -> Material:
	var color := Color.html(hex_color) if hex_color.begins_with("#") else Color(0.8, 0.75, 0.65)
	match material_type:
		"plaster":
			return plaster_material(color)
		"marble":
			var marble := marble_material(color)
			if marble:
				return marble
			return stone_material(color, 0.3)
		_:
			return stone_material(color)


## Create a dark glass material for window voids.
static func glass_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.1, 0.15, 0.7)
	mat.roughness = 0.1
	mat.metallic = 0.0
	mat.metallic_specular = 0.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## Create a dark wood material for doors.
static func wood_material(color: Color = Color(0.35, 0.22, 0.12)) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mat.metallic = 0.0
	mat.metallic_specular = 0.2
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	return mat
