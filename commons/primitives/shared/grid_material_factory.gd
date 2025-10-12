# GridMaterialFactory.gd - Shared factory for SimpleGrid shader material
extends Object
class_name GridMaterialFactory

const GRID_SHADER_PATH := "res://commons/resourses/shaders/SimpleGrid.gdshader"
static var _shader: Shader

static func make(base_color: Color, overrides: Dictionary = {}) -> Material:
	var shader: Shader = _get_shader()
	var double_sided: bool = bool(overrides.get("double_sided", false))
	var fallback_emission: float = float(overrides.get("fallback_emission", 0.3))
	if shader:
		var material := ShaderMaterial.new()
		material.shader = shader
		var params := {
			"base_color": base_color,
			"edge_color": Color.WHITE,
			"edge_width": 1.5,
			"edge_sharpness": 2.0,
			"emission_strength": 1.0
		}
		for key in overrides.keys():
			if key == "double_sided" or key == "fallback_emission":
				continue
			params[key] = overrides[key]
		for key in params.keys():
			material.set_shader_parameter(key, params[key])
		if double_sided:
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		return material
	return _build_fallback(base_color, fallback_emission, double_sided)

static func _get_shader() -> Shader:
	if _shader == null:
		_shader = load(GRID_SHADER_PATH)
	return _shader

static func _build_fallback(base_color: Color, emission_multiplier: float, double_sided := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.emission_enabled = true
	material.emission = base_color * emission_multiplier
	if double_sided:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
