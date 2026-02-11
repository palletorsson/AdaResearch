# dissolving_form.gd
# QFEP High-λ Visualization - Dissolving Form
# A mesh that appears to disintegrate over time
# Represents the transition from order to chaos

extends Node3D

class_name QFEPDissolvingForm

## Base mesh type
@export_enum("Sphere", "Cube", "Torus") var mesh_type: int = 0

## Mesh size
@export var mesh_size: float = 0.3

## Dissolve speed
@export var dissolve_speed: float = 0.2

## Auto-cycle (dissolve and reform)
@export var auto_cycle: bool = true
@export var cycle_duration: float = 5.0

## Colors
@export var solid_color: Color = Color(0.4, 0.5, 0.9, 1.0)
@export var dissolve_color: Color = Color(0.9, 0.3, 0.1, 1.0)

# Internal
var _mesh_instance: MeshInstance3D
var _material: ShaderMaterial
var _dissolve_amount: float = 0.0
var _cycle_time: float = 0.0
var _dissolving: bool = true

# Dissolve shader code
const DISSOLVE_SHADER = """
shader_type spatial;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 solid_color : source_color = vec3(0.4, 0.5, 0.9);
uniform vec3 dissolve_color : source_color = vec3(0.9, 0.3, 0.1);
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
uniform float noise_scale : hint_range(1.0, 20.0) = 8.0;

// Simple noise function
float hash(vec3 p) {
	return fmod(sin(dot(p, vec3(127.1, 311.7, 74.7, 1.0))) * 43758.5453);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fmod(p, 1.0);
	f = f * f * (3.0 - 2.0 * f);
	
	return mix(
		mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
			mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
			mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void fragment() {
	// Get world position for noise
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float n = noise(world_pos * noise_scale);
	
	// Dissolve threshold
	float threshold = dissolve_amount;
	
	// Discard dissolved pixels
	if (n < threshold) {
		discard;
	}
	
	// Edge glow
	float edge = smoothstep(threshold, threshold + edge_width, n);
	vec3 color = mix(dissolve_color, solid_color, edge);
	
	ALBEDO = color;
	EMISSION = dissolve_color * (1.0 - edge) * 2.0;
	ALPHA = 1.0;
}
"""

func _ready() -> void:
	_build_mesh()

func _build_mesh() -> void:
	_mesh_instance = MeshInstance3D.new()
	
	# Create mesh based on type
	match mesh_type:
		0:  # Sphere
			var sphere = SphereMesh.new()
			sphere.radius = mesh_size
			sphere.height = mesh_size * 2
			_mesh_instance.mesh = sphere
		1:  # Cube
			var cube = BoxMesh.new()
			cube.size = Vector3(mesh_size, mesh_size, mesh_size) * 1.5
			_mesh_instance.mesh = cube
		2:  # Torus
			var torus = TorusMesh.new()
			torus.inner_radius = mesh_size * 0.3
			torus.outer_radius = mesh_size
			_mesh_instance.mesh = torus
	
	# Create dissolve shader material
	_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = DISSOLVE_SHADER
	_material.shader = shader
	_material.set_shader_parameter("solid_color", Vector3(solid_color.r, solid_color.g, solid_color.b))
	_material.set_shader_parameter("dissolve_color", Vector3(dissolve_color.r, dissolve_color.g, dissolve_color.b))
	_material.set_shader_parameter("dissolve_amount", 0.0)
	
	_mesh_instance.material_override = _material
	add_child(_mesh_instance)

func _process(delta: float) -> void:
	if not auto_cycle:
		return
	
	_cycle_time += delta
	
	# Oscillate dissolve amount
	var t = fmod(_cycle_time, cycle_duration) / cycle_duration
	_dissolve_amount = sin(t * PI) 
	
	if _material:
		_material.set_shader_parameter("dissolve_amount", _dissolve_amount)

## Set dissolve amount directly (0 = solid, 1 = dissolved)
func set_dissolve(amount: float) -> void:
	_dissolve_amount = clamp(amount, 0.0, 1.0)
	if _material:
		_material.set_shader_parameter("dissolve_amount", _dissolve_amount)

## Trigger full dissolve
func dissolve() -> void:
	auto_cycle = false
	var tween = create_tween()
	tween.tween_method(set_dissolve, _dissolve_amount, 1.0, 1.0 / dissolve_speed)

## Trigger reform
func reform() -> void:
	auto_cycle = false
	var tween = create_tween()
	tween.tween_method(set_dissolve, _dissolve_amount, 0.0, 1.0 / dissolve_speed)
