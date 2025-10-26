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

		# Default parameters matching SimpleGrid.gdshader uniforms
		var params := {
			"fill_color": base_color,
			"wireframe_color": Color.WHITE,
			"wireframe_width": 2.0,
			"wireframe_brightness": 2.0,
			"show_only_wireframe": false
		}

		# Map common parameter names to shader-specific names
		for key in overrides.keys():
			if key == "double_sided" or key == "fallback_emission":
				continue
			# Map edge_color to wireframe_color for compatibility
			if key == "edge_color":
				params["wireframe_color"] = overrides[key]
			# Map base_color to fill_color for compatibility
			elif key == "base_color":
				params["fill_color"] = overrides[key]
			else:
				params[key] = overrides[key]

		# Set shader parameters
		for key in params.keys():
			material.set_shader_parameter(key, params[key])

		# Note: ShaderMaterial doesn't support cull_mode property
		# Double-sided rendering must be defined in the shader itself via render_mode
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
