## WallShaderShowcase
## Replaces the GridMultiMesh material with a GPU shader from the shader library.
## Like GridColorizer but with actual shader patterns instead of flat colors.
## Cycles through different shaders on a timer or accepts a specific shader via config.
##
## Place as interactable in map_data.json. Config keys:
##   shader          – shader name (e.g. "voronoiShader", "tartanshader")
##   shader_list     – comma-separated list to cycle (e.g. "voronoiShader,rothko,tartanshader")
##   cycle_interval  – seconds between shader swaps (default 6.0)
##   emission_strength – emission for visibility in dark grids (default 0.8)

extends Node3D
class_name WallShaderShowcase

@export var shader_name: String = "voronoiShader"
@export var cycle_interval: float = 6.0
@export var emission_strength: float = 0.8

var _multimesh_instance: MultiMeshInstance3D
var _original_material: Material
var _shader_list: Array[String] = []
var _current_index: int = 0
var _cycling := false

const DEFAULT_SHADERS: Array = [
	"voronoiShader",
	"tartanshader",
	"rothko",
	"TruchetFloor",
	"reaction_diffusion",
	"wallpaper_tile",
	"coffeeswirl",
	"slime",
	"DiscoGrid",
	"pearlescent",
]

func _ready() -> void:
	if _shader_list.is_empty():
		_shader_list = [shader_name]
	await get_tree().create_timer(0.5).timeout
	if _find_multimesh():
		_original_material = _multimesh_instance.material_override
		_apply_shader(_shader_list[0])
		if _shader_list.size() > 1:
			_start_cycling()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("shader"):
		shader_name = str(config_data["shader"])
		_shader_list = [shader_name]
	if config_data.has("shader_list"):
		var raw: String = str(config_data["shader_list"])
		_shader_list.clear()
		for s in raw.split(","):
			var trimmed := s.strip_edges()
			if trimmed != "":
				_shader_list.append(trimmed)
	if config_data.has("cycle_interval"):
		cycle_interval = clampf(float(config_data["cycle_interval"]), 1.0, 60.0)
	if config_data.has("emission_strength"):
		emission_strength = clampf(float(config_data["emission_strength"]), 0.0, 5.0)

func _find_multimesh() -> bool:
	_multimesh_instance = _search_multimesh(get_tree().current_scene)
	return _multimesh_instance != null

func _search_multimesh(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D and node.name == "GridMultiMesh":
		return node
	for child in node.get_children():
		var result := _search_multimesh(child)
		if result:
			return result
	return null

func _apply_shader(name: String) -> void:
	if not _multimesh_instance:
		return
	var path := "res://commons/resourses/shaders/%s.gdshader" % name
	var shader := load(path) as Shader
	if not shader:
		print("[WallShaderShowcase] Failed to load shader: %s" % path)
		return

	var mat := ShaderMaterial.new()
	mat.shader = shader

	# Set emission if the shader supports it
	_try_set_param(mat, "emission_strength", emission_strength)
	_try_set_param(mat, "emission_energy", emission_strength)

	# Set TIME-based uniforms for animated shaders
	_try_set_param(mat, "tile_scale", 3.0)

	_multimesh_instance.material_override = mat
	print("[WallShaderShowcase] Applied shader: %s" % name)

func _try_set_param(mat: ShaderMaterial, param_name: String, value: Variant) -> void:
	# Only set if the shader actually has this uniform
	if mat.shader:
		for uniform in mat.shader.get_shader_uniform_list():
			if uniform["name"] == param_name:
				mat.set_shader_parameter(param_name, value)
				return

func _start_cycling() -> void:
	_cycling = true
	while _cycling and is_inside_tree():
		await get_tree().create_timer(cycle_interval).timeout
		if not _cycling:
			break
		_current_index = (_current_index + 1) % _shader_list.size()
		_apply_shader(_shader_list[_current_index])

func _exit_tree() -> void:
	_cycling = false
	# Restore original material
	if _multimesh_instance and _original_material:
		_multimesh_instance.material_override = _original_material
