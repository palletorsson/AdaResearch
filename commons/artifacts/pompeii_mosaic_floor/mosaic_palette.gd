# mosaic_palette.gd
# Shared Pompeii mosaic palette and aging material factory.
# All floor artifacts use this for consistent colors and weathering.

class_name MosaicPalette

## Roman Republican palette — matched to MANN museum stones
const DARK := Color(0.24, 0.22, 0.20)      # #3D3832 — dark basalt/grey-brown
const LIGHT := Color(0.83, 0.79, 0.71)     # #D4C9B5 — sandy limestone
const MEDIUM := Color(0.57, 0.53, 0.50)    # #918880 — warm grey (tumbling blocks)
const TERRACOTTA := Color(0.69, 0.47, 0.31) # #B07850 — muted terracotta
const GROUT := Color(0.63, 0.60, 0.50)     # #A09880 — sandy grout

## Create an aging ShaderMaterial for a given base color.
## Uses vertex colors for per-triangle tinting, aging shader for weathering.
static func create_aging_material(base_color: Color, wear: float = 0.3) -> ShaderMaterial:
	var shader := load("res://commons/artifacts/pompeii_mosaic_floor/mosaic_floor_aging.gdshader") as Shader
	if not shader:
		# Fallback to StandardMaterial3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = base_color
		mat.roughness = 0.8
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		return null

	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("base_color", base_color)
	mat.set_shader_parameter("wear_amount", wear * 0.5)
	mat.set_shader_parameter("dust_amount", wear * 0.3)
	mat.set_shader_parameter("fade_amount", wear * 0.2)
	mat.set_shader_parameter("crack_density", wear * 0.15)
	return mat


## Create a StandardMaterial3D with vertex colors enabled (fallback).
static func create_standard_material(base_color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = 0.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	return mat


## Create the aging material, or fallback to standard if shader not found.
static func create_material(base_color: Color, wear: float = 0.3) -> Material:
	var shader_mat := create_aging_material(base_color, wear)
	if shader_mat:
		return shader_mat
	return create_standard_material(base_color)
