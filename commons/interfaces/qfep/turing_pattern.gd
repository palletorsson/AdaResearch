# turing_pattern.gd
# QFEP Turing Pattern - Reaction-Diffusion Visualization
# The mathematics of biological pattern formation
# Stripes, spots, and labyrinths emerge from simple rules

extends Node3D

class_name QFEPTuringPattern

## Display size
@export var display_size: float = 0.8

## Pattern resolution
@export var resolution: int = 64

## Pattern type
@export_enum("Spots", "Stripes", "Labyrinth") var pattern_type: int = 0

## Animation
@export var animate: bool = true
@export var animation_speed: float = 0.5

## Colors
@export var color_a: Color = Color(0.2, 0.9, 0.4, 1.0)  # Green
@export var color_b: Color = Color(0.1, 0.2, 0.15, 1.0)  # Dark

# Internal
var _mesh: MeshInstance3D
var _material: ShaderMaterial
var _time: float = 0.0

# Turing pattern shader
const TURING_SHADER = """
shader_type spatial;

uniform float time = 0.0;
uniform int pattern_type = 0;
uniform vec3 color_a : source_color = vec3(0.2, 0.9, 0.4);
uniform vec3 color_b : source_color = vec3(0.1, 0.2, 0.15);
uniform float scale : hint_range(1.0, 20.0) = 8.0;

// Noise functions for pattern generation
float hash(vec2 p) {
	return fmod(sin(dot(p, vec2(127.1, 311.7, 1.0))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fmod(p, 1.0);
	f = f * f * (3.0 - 2.0 * f);
	
	return mix(
		mix(hash(i), hash(i + vec2(1, 0)), f.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

// Reaction-diffusion inspired pattern
float turing(vec2 p, float t) {
	float n1 = fbm(p * scale + t * 0.1);
	float n2 = fbm(p * scale * 1.5 - t * 0.15 + 100.0);
	
	// Different patterns based on type
	float pattern;
	if (pattern_type == 0) {
		// Spots
		pattern = smoothstep(0.4, 0.6, n1 * n2 * 2.0);
	} else if (pattern_type == 1) {
		// Stripes
		float angle = atan(p.y, p.x);
		pattern = smoothstep(0.3, 0.7, sin(angle * 8.0 + n1 * 4.0 + t) * 0.5 + 0.5);
	} else {
		// Labyrinth
		float domain = sin(p.x * scale + n1 * 2.0) * cos(p.y * scale + n2 * 2.0);
		pattern = smoothstep(-0.1, 0.1, domain + sin(t * 0.5) * 0.1);
	}
	
	return pattern;
}

void fragment() {
	vec2 uv = UV - 0.5;
	
	float pattern = turing(uv, time);
	
	vec3 color = mix(color_b, color_a, pattern);
	
	ALBEDO = color;
	EMISSION = color * pattern * 0.5;
	ROUGHNESS = 0.8;
	METALLIC = 0.1;
}
"""

func _ready() -> void:
	_build_display()

func _build_display() -> void:
	_mesh = MeshInstance3D.new()
	
	# Create a plane to display the pattern
	var plane = PlaneMesh.new()
	plane.size = Vector2(display_size, display_size)
	plane.subdivide_width = 1
	plane.subdivide_depth = 1
	_mesh.mesh = plane
	
	# Rotate to face forward (vertical display)
	_mesh.rotation_degrees.x = -90
	
	# Create shader material
	_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = TURING_SHADER
	_material.shader = shader
	_material.set_shader_parameter("color_a", Vector3(color_a.r, color_a.g, color_a.b))
	_material.set_shader_parameter("color_b", Vector3(color_b.r, color_b.g, color_b.b))
	_material.set_shader_parameter("pattern_type", pattern_type)
	_material.set_shader_parameter("time", 0.0)
	
	_mesh.material_override = _material
	add_child(_mesh)

func _process(delta: float) -> void:
	if animate:
		_time += delta * animation_speed
		if _material:
			_material.set_shader_parameter("time", _time)

## Set pattern type (0=spots, 1=stripes, 2=labyrinth)
func set_pattern_type(type: int) -> void:
	pattern_type = type
	if _material:
		_material.set_shader_parameter("pattern_type", type)

## Cycle to next pattern
func next_pattern() -> void:
	pattern_type = (pattern_type + 1) % 3
	set_pattern_type(pattern_type)
