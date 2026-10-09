# GridMaterialFactory.gd - Shared factory for SimpleGrid + ParametricGrid materials.
#
# Two strategies:
#   make()            — SimpleGrid shader: highlights actual mesh triangle edges.
#                       Best for low-poly hand-coded primitives where the
#                       triangulation IS the teaching (bipyramid, arch).
#   make_parametric() — ParametricGrid shader: paints N×M lines from UV
#                       coordinates regardless of triangle density. Best for
#                       artifacts that vary tessellation as a parameter
#                       (combine_torus, combine_sphere, etc.) — the visual
#                       encoding stays legible at every density because the
#                       grid is decoupled from the geometry.
extends Object
class_name GridMaterialFactory

const GRID_SHADER_PATH := "res://commons/resourses/shaders/SimpleGrid.gdshader"
const PARAMETRIC_SHADER_PATH := "res://commons/resourses/shaders/ParametricGrid.gdshader"
static var _shader: Shader
static var _parametric_shader: Shader

static func make(base_color: Color, overrides: Dictionary = {}) -> Material:
	var shader: Shader = _get_shader()
	var double_sided: bool = bool(overrides.get("double_sided", false))
	var fallback_emission: float = float(overrides.get("fallback_emission", 0.3))
	if shader:
		var material := ShaderMaterial.new()
		material.shader = shader

		# Default parameters matching SimpleGrid.gdshader uniforms (camelCase!)
		var params := {
			"modelColor": base_color,
			"wireframeColor": Color.WHITE,
			"width": 2.0,
			"emission_strength": 2.0,
			"show_interior": true
		}

		# Map common parameter names to shader-specific names (shader uses camelCase)
		for key in overrides.keys():
			if key == "double_sided" or key == "fallback_emission":
				continue
			# Map various naming conventions to shader params
			match key:
				"edge_color", "wireframe_color":
					params["wireframeColor"] = overrides[key]
				"base_color", "fill_color":
					params["modelColor"] = overrides[key]
				"wireframe_width":
					params["width"] = overrides[key]
				"wireframe_brightness":
					params["emission_strength"] = overrides[key]
				"show_only_wireframe":
					params["show_interior"] = not overrides[key]
				_:
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


static func _get_parametric_shader() -> Shader:
	if _parametric_shader == null:
		_parametric_shader = load(PARAMETRIC_SHADER_PATH)
	return _parametric_shader


# Build a ParametricGrid material. lines_u / lines_v say how many UV-space
# lines to paint, independent of mesh tessellation. For artifacts where
# the teaching is "look how the parameter discretizes the surface", this
# is the correct choice — the lines you see are the parameters the
# artifact is teaching, not whatever triangle count the mesh ended up with.
#
# overrides: optional Dictionary of shader uniforms to override
#   line_color, line_width, emission, show_mesh_edges, mesh_edge_alpha
static func make_parametric(
		fill_color: Color,
		lines_u: int,
		lines_v: int,
		overrides: Dictionary = {}
		) -> Material:
	var shader: Shader = _get_parametric_shader()
	if shader == null:
		# Fall back to SimpleGrid if the parametric shader is missing.
		return make(fill_color, overrides)

	var material := ShaderMaterial.new()
	material.shader = shader

	# Defaults match ParametricGrid.gdshader's uniform defaults but explicit
	# here so a renamed default in the shader doesn't silently shift the
	# whole project's look.
	var line_color: Color = overrides.get("line_color", Color(0.95, 0.40, 0.45))
	var line_width: float = float(overrides.get("line_width", 0.02))
	var emission: float = float(overrides.get("emission", 1.2))
	var show_mesh_edges: bool = bool(overrides.get("show_mesh_edges", false))
	var mesh_edge_alpha: float = float(overrides.get("mesh_edge_alpha", 0.15))

	# Clamp to shader's hint_range — silent clamp here, not in the shader,
	# so callers can pass any value and get sensible behavior.
	lines_u = clamp(lines_u, 1, 64)
	lines_v = clamp(lines_v, 1, 64)

	material.set_shader_parameter("fill_color", fill_color)
	material.set_shader_parameter("line_color", line_color)
	material.set_shader_parameter("lines_u", lines_u)
	material.set_shader_parameter("lines_v", lines_v)
	material.set_shader_parameter("line_width", line_width)
	material.set_shader_parameter("emission", emission)
	material.set_shader_parameter("show_mesh_edges", show_mesh_edges)
	material.set_shader_parameter("mesh_edge_alpha", mesh_edge_alpha)
	return material

static func _build_fallback(base_color: Color, emission_multiplier: float, double_sided := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.emission_enabled = true
	material.emission = base_color * emission_multiplier
	if double_sided:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
