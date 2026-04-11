# fluid_form.gd
# QFEP φ > 0 Visualization - Fluid Form
# Queer signature: embraces change, welcomes becoming
# Constantly morphing, flowing, transforming

extends Node3D

class_name QFEPFluidForm

# @identity
# essence: vertex_shader(noise_layers * flow_intensity) + fresnel_iridescence -> morphing sphere
# desire: watch a form that never holds still — always becoming, never arriving
# critical_parameter: flow_intensity — how much the vertex shader deforms the mesh each frame
# triggers: _process updates shader time continuously; pulse() temporarily triples flow intensity
# emerges: iridescent color shifts at glancing angles — the form appears to have an inner light
# needs: VR flow intensity control [missing], pulse trigger [missing]
# relationships: contrasts rigid_sculpture (phi<0 frozen vs phi>0 flowing); paired with transforming_pattern; depends on phi concept
# truth: positive phi means embracing transformation — the fluid form is not broken, it is becoming

## Form size
@export var size: float = 0.4

## Morph speed
@export var morph_speed: float = 0.5

## Flow intensity
@export var flow_intensity: float = 0.3

## Embrace color (gold/yellow)
@export var fluid_color: Color = Color(1.0, 0.8, 0.2, 1.0)

# Internal
var _mesh: MeshInstance3D
var _material: ShaderMaterial
var _time: float = 0.0

# Morphing shader
const FLUID_SHADER = """
shader_type spatial;

uniform float time = 0.0;
uniform float morph_speed = 0.5;
uniform float flow_intensity = 0.3;
uniform vec3 fluid_color : source_color = vec3(1.0, 0.8, 0.2);

// Noise for morphing
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

void vertex() {
	// Morph the vertices
	float t = time * morph_speed;
	vec3 pos = VERTEX;
	
	// Multiple layers of deformation
	float n1 = noise(pos * 3.0 + t);
	float n2 = noise(pos * 5.0 - t * 1.3);
	float n3 = noise(pos * 2.0 + t * 0.7);
	
	// Combine for organic movement
	vec3 offset = NORMAL * (n1 * n2 - 0.25) * flow_intensity;
	offset += vec3(sin(t + pos.y * 4.0), cos(t * 1.2 + pos.x * 3.0), sin(t * 0.8 + pos.z * 5.0)) * flow_intensity * 0.3;
	
	VERTEX += offset;
}

void fragment() {
	// Iridescent effect
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 2.0);
	vec3 iridescence = vec3(
		sin(TIME + UV.x * 6.28) * 0.5 + 0.5,
		sin(TIME * 1.3 + UV.y * 6.28) * 0.5 + 0.5,
		sin(TIME * 0.7 + (UV.x + UV.y) * 3.14) * 0.5 + 0.5
	);
	
	vec3 color = mix(fluid_color, iridescence, fresnel * 0.5);
	
	ALBEDO = color;
	EMISSION = color * fresnel * 0.5;
	METALLIC = 0.3;
	ROUGHNESS = 0.4;
}
"""

func _ready() -> void:
	_build_form()

func _build_form() -> void:
	_mesh = MeshInstance3D.new()
	
	# Start with a sphere that will morph
	var sphere = SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2
	sphere.radial_segments = 32
	sphere.rings = 16
	_mesh.mesh = sphere
	
	# Apply morphing shader
	_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = FLUID_SHADER
	_material.shader = shader
	_material.set_shader_parameter("fluid_color", Vector3(fluid_color.r, fluid_color.g, fluid_color.b))
	_material.set_shader_parameter("morph_speed", morph_speed)
	_material.set_shader_parameter("flow_intensity", flow_intensity)
	_material.set_shader_parameter("time", 0.0)
	
	_mesh.material_override = _material
	add_child(_mesh)

func _process(delta: float) -> void:
	_time += delta
	if _material:
		_material.set_shader_parameter("time", _time)
	
	# Also rotate gently
	rotation.y += delta * 0.2
	rotation.x = sin(_time * 0.3) * 0.1

## Set flow intensity
func set_flow(intensity: float) -> void:
	flow_intensity = intensity
	if _material:
		_material.set_shader_parameter("flow_intensity", intensity)

## Pulse the form
func pulse() -> void:
	var original = flow_intensity
	var tween = create_tween()
	tween.tween_method(set_flow, flow_intensity, flow_intensity * 3, 0.2)
	tween.tween_method(set_flow, flow_intensity * 3, original, 0.5)
