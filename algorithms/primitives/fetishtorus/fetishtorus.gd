extends Node3D
class_name FetishTorus

## Fetish Torus — Parametric torus primitive with fluid shader-driven color effects.
##
## Demonstrates how a torus is defined by its major and minor radii, and how
## fragment shaders create animated fluid color patterns on curved surfaces.
## The dual-torus mode shows overlapping parametric surfaces with contrasting
## materials: one fluid-colored, one mirror-black.

# --- Configuration ---

@export var major_radius: float = 1.0
@export var minor_radius: float = 0.4
@export var ring_count: int = 48
@export var segment_count: int = 24
@export var rotation_speed: float = 0.3
@export var inner_color_speed: float = 0.5
@export var outer_color_speed: float = 0.7
@export var gradient_spread: float = 0.5
@export var surface_metallic: float = 0.5
@export var surface_roughness: float = 0.2
@export var dual_torus: bool = true
@export var second_torus_tilt: float = 75.0  ## degrees

# --- Internal ---

var _torus_a: MeshInstance3D
var _torus_b: MeshInstance3D
var _shader_mat: ShaderMaterial
var _time: float = 0.0

const FLUID_SHADER := """
shader_type spatial;

uniform float inner_color_speed = 0.5;
uniform float outer_color_speed = 0.7;
uniform float gradient_spread = 0.5;
uniform float metallic_amount = 0.5;
uniform float roughness_amount = 0.2;
uniform vec3 color_offset = vec3(0.0, 0.33, 0.67);

void fragment() {
	vec3 inner_color = vec3(
		0.5 + sin(TIME * inner_color_speed + color_offset.x * 6.283) * 0.5,
		0.5 + cos(TIME * inner_color_speed * 1.2 + color_offset.y * 6.283) * 0.5,
		0.5 + sin(TIME * inner_color_speed * 1.5 + color_offset.z * 6.283) * 0.5
	);
	vec3 outer_color = vec3(
		0.5 + cos(TIME * outer_color_speed + color_offset.z * 6.283) * 0.5,
		0.5 + sin(TIME * outer_color_speed * 1.2 + color_offset.x * 6.283) * 0.5,
		0.5 + cos(TIME * outer_color_speed * 1.5 + color_offset.y * 6.283) * 0.5
	);

	float dist_from_center = distance(UV, vec2(0.5, 0.5));
	float gradient = smoothstep(0.0, gradient_spread, dist_from_center);
	vec3 fluid_color = mix(inner_color, outer_color, gradient);

	float light_intensity = dot(NORMAL, vec3(0.0, 1.0, 0.0));
	ALBEDO = fluid_color * (1.0 + light_intensity * 0.3);
	ROUGHNESS = roughness_amount;
	METALLIC = metallic_amount;
}
"""


func _ready() -> void:
	_build_fluid_torus()
	if dual_torus:
		_build_blackshine_torus()


func _build_fluid_torus() -> void:
	_torus_a = MeshInstance3D.new()
	_torus_a.name = "FluidTorus"

	var mesh := TorusMesh.new()
	mesh.inner_radius = major_radius - minor_radius
	mesh.outer_radius = major_radius + minor_radius
	mesh.rings = ring_count
	mesh.ring_segments = segment_count
	_torus_a.mesh = mesh

	var shader := Shader.new()
	shader.code = FLUID_SHADER
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	_shader_mat.set_shader_parameter("inner_color_speed", inner_color_speed)
	_shader_mat.set_shader_parameter("outer_color_speed", outer_color_speed)
	_shader_mat.set_shader_parameter("gradient_spread", gradient_spread)
	_shader_mat.set_shader_parameter("metallic_amount", surface_metallic)
	_shader_mat.set_shader_parameter("roughness_amount", surface_roughness)
	_shader_mat.set_shader_parameter("color_offset", Vector3(0.0, 0.33, 0.67))
	_torus_a.material_override = _shader_mat

	add_child(_torus_a)


func _build_blackshine_torus() -> void:
	_torus_b = MeshInstance3D.new()
	_torus_b.name = "BlackShineTorus"

	var mesh := TorusMesh.new()
	mesh.inner_radius = major_radius - minor_radius
	mesh.outer_radius = major_radius + minor_radius
	mesh.rings = ring_count
	mesh.ring_segments = segment_count
	_torus_b.mesh = mesh

	_torus_b.rotation_degrees.x = second_torus_tilt

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.BLACK
	mat.roughness = 0.01
	mat.metallic = 1.0
	_torus_b.material_override = mat

	add_child(_torus_b)


func _process(delta: float) -> void:
	_time += delta
	if _torus_a:
		_torus_a.rotation.y += delta * rotation_speed
	if _torus_b:
		_torus_b.rotation.y -= delta * rotation_speed * 0.7
		_torus_b.rotation.x += delta * rotation_speed * 0.3


func apply_grid_config(config: Dictionary) -> void:
	if config.has("major_radius"):
		major_radius = float(config["major_radius"])
	if config.has("minor_radius"):
		minor_radius = float(config["minor_radius"])
	if config.has("ring_count"):
		ring_count = int(config["ring_count"])
	if config.has("segment_count"):
		segment_count = int(config["segment_count"])
	if config.has("rotation_speed"):
		rotation_speed = float(config["rotation_speed"])
	if config.has("inner_color_speed"):
		inner_color_speed = float(config["inner_color_speed"])
	if config.has("outer_color_speed"):
		outer_color_speed = float(config["outer_color_speed"])
	if config.has("gradient_spread"):
		gradient_spread = float(config["gradient_spread"])
	if config.has("surface_metallic"):
		surface_metallic = float(config["surface_metallic"])
	if config.has("surface_roughness"):
		surface_roughness = float(config["surface_roughness"])
	if config.has("dual_torus"):
		dual_torus = bool(config["dual_torus"])
	if config.has("second_torus_tilt"):
		second_torus_tilt = float(config["second_torus_tilt"])

	# Rebuild geometry with new parameters
	for child in get_children():
		child.queue_free()
	call_deferred("_ready")
