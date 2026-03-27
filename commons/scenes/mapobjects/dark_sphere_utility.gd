## Dark Sphere Utility — large inverted sphere that envelops the scene.
## Makes the environment dark so artifacts and patterns pop against darkness.
## Place as "ds" in the utilities layer. Optional parameter: radius (default 50).
extends Node3D

class_name DarkSphereUtility

@export var sphere_radius: float = 50.0
@export var sphere_color: Color = Color(0.02, 0.02, 0.03)
@export var ambient_light_energy: float = 0.15
@export var ambient_light_color: Color = Color(0.6, 0.55, 0.5)

var _mesh: MeshInstance3D
var _env: WorldEnvironment


func _ready() -> void:
	_build_sphere()
	_setup_environment()


func apply_utility_config(params: String) -> void:
	if params != "" and params.is_valid_float():
		sphere_radius = float(params)
		_build_sphere()


func _build_sphere() -> void:
	if _mesh:
		_mesh.queue_free()

	var mesh := SphereMesh.new()
	mesh.radius = sphere_radius
	mesh.height = sphere_radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = 16

	var mat := StandardMaterial3D.new()
	mat.albedo_color = sphere_color
	mat.cull_mode = BaseMaterial3D.CULL_FRONT  # Render INSIDE faces only
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.render_priority = -100  # Render behind everything

	_mesh = MeshInstance3D.new()
	_mesh.name = "DarkSphereShell"
	_mesh.mesh = mesh
	_mesh.material_override = mat
	_mesh.position = Vector3(0, sphere_radius * 0.4, 0)  # Center above ground
	add_child(_mesh)


func _setup_environment() -> void:
	if _env:
		_env.queue_free()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = sphere_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_light_color
	env.ambient_light_energy = ambient_light_energy
	env.fog_enabled = false
	env.tonemap_mode = Environment.TONE_MAP_FILMIC

	_env = WorldEnvironment.new()
	_env.name = "DarkSphereEnvironment"
	_env.environment = env
	add_child(_env)

	print("DarkSphereUtility: radius=%.1f, ambient=%.2f" % [sphere_radius, ambient_light_energy])
