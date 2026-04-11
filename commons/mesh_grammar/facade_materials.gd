class_name FacadeMaterials
extends RefCounted

## Factory methods for architectural facade materials.
## Provides StandardMaterial3D for common surfaces (stone, plaster, wood, metal)
## and a ShaderMaterial for marble veining.
## Use from_zone() to map zone/material names from study packs to Materials.

const MARBLE_SHADER_PATH := "res://commons/mesh_grammar/shaders/marble.gdshader"

# ---------------------------------------------------------------------------
# Stone — rough, matte, natural rock surface
# ---------------------------------------------------------------------------
static func stone(color: Color = Color(0.72, 0.68, 0.62), roughness_val: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness_val
	mat.metallic = 0.0
	mat.metallic_specular = 0.3
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.resource_name = "Stone"
	return mat


# ---------------------------------------------------------------------------
# Plaster — smoother, lighter wall render
# ---------------------------------------------------------------------------
static func plaster(color: Color = Color(0.91, 0.88, 0.82), roughness_val: float = 0.7) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness_val
	mat.metallic = 0.0
	mat.metallic_specular = 0.2
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.resource_name = "Plaster"
	return mat


# ---------------------------------------------------------------------------
# Marble — shader-based veined material
# ---------------------------------------------------------------------------
static func marble(base_color: Color = Color(0.92, 0.9, 0.87), vein_color: Color = Color(0.4, 0.38, 0.35)) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	var shader := load(MARBLE_SHADER_PATH) as Shader
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("base_color", base_color)
		mat.set_shader_parameter("vein_color", vein_color)
		mat.set_shader_parameter("vein_scale", 8.0)
		mat.set_shader_parameter("vein_intensity", 0.6)
		mat.set_shader_parameter("roughness", 0.3)
		mat.set_shader_parameter("normal_strength", 0.5)
	else:
		push_warning("FacadeMaterials: Could not load marble shader at %s" % MARBLE_SHADER_PATH)
	return mat


# ---------------------------------------------------------------------------
# Wood — warm, slightly rough
# ---------------------------------------------------------------------------
static func wood(color: Color = Color(0.45, 0.32, 0.2)) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	mat.metallic = 0.0
	mat.metallic_specular = 0.15
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.resource_name = "Wood"
	return mat


# ---------------------------------------------------------------------------
# Metal — slightly reflective, low roughness
# ---------------------------------------------------------------------------
static func metal(color: Color = Color(0.3, 0.3, 0.32)) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4
	mat.metallic = 0.8
	mat.metallic_specular = 0.6
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.resource_name = "Metal"
	return mat


# ---------------------------------------------------------------------------
# from_zone — map zone/material names from study pack JSON to Material
# ---------------------------------------------------------------------------
## Resolve a material from a zone name and optional color hex string.
## zone_name values match the "material" field in study pack zone_templates:
##   "stone_base", "rusticated_stone", "dressed_stone", "plaster",
##   "stone_cornice", "stone", "decorated", "marble", "wood", "metal"
## zone_color: optional hex color override (e.g. "#8C8478")
static func from_zone(zone_name: String, zone_color: String = "") -> Material:
	var color_override := Color.WHITE
	var has_override := false
	if zone_color != "" and zone_color.begins_with("#"):
		color_override = Color.html(zone_color)
		has_override = true

	match zone_name:
		"stone_base":
			# Dark grey stone — palazzo foundations
			var c: Color = color_override if has_override else Color(0.55, 0.53, 0.50)
			return stone(c, 0.92)
		"rusticated_stone":
			# Warm grey ashlar — rusticated base courses
			var c: Color = color_override if has_override else Color(0.62, 0.58, 0.53)
			return stone(c, 0.95)
		"dressed_stone":
			# Light warm stone — window surrounds, cornices
			var c: Color = color_override if has_override else Color(0.78, 0.74, 0.68)
			return stone(c, 0.78)
		"stone_cornice":
			# Pale stone — cornices and entablatures
			var c: Color = color_override if has_override else Color(0.82, 0.78, 0.72)
			return stone(c, 0.72)
		"stone":
			# Medium stone
			var c: Color = color_override if has_override else Color(0.68, 0.64, 0.58)
			return stone(c, 0.85)
		"plaster":
			# Warm ochre/salmon plaster — Venetian upper stories
			var c: Color = color_override if has_override else Color(0.88, 0.78, 0.62)
			return plaster(c, 0.65)
		"decorated":
			# Rich warm plaster — piano nobile
			var c: Color = color_override if has_override else Color(0.85, 0.72, 0.55)
			return plaster(c, 0.55)
		"marble":
			if has_override:
				return marble(color_override, color_override.darkened(0.5))
			return marble()
		"wood":
			var c: Color = color_override if has_override else Color(0.45, 0.32, 0.2)
			return wood(c)
		"metal":
			var c: Color = color_override if has_override else Color(0.3, 0.3, 0.32)
			return metal(c)
		_:
			# Fallback: generic stone with optional color
			if has_override:
				return stone(color_override)
			return stone()
