@tool
extends Node3D
class_name GlassPlanes25D

## Glass Planes 2.5D - Layered transparency creating depth illusion
## Array + Noise = Volumetric look at flat render cost
## The discrete framing the continuous

@export_range(3, 24) var plane_count: int = 10:
	set(v):
		plane_count = v
		_rebuild()

@export var plane_size: Vector2 = Vector2(2.0, 1.5):
	set(v):
		plane_size = v
		_rebuild()

@export var total_depth: float = 1.5:
	set(v):
		total_depth = v
		_rebuild()

@export var glass_color: Color = Color(0.9, 0.95, 1.0, 0.15):
	set(v):
		glass_color = v
		_update_materials()

@export var use_noise: bool = true:
	set(v):
		use_noise = v
		_rebuild()

@export var noise_scale: float = 2.0:
	set(v):
		noise_scale = v
		_update_noise()

@export var noise_offset_per_plane: float = 0.3:
	set(v):
		noise_offset_per_plane = v
		_update_noise()

@export var cloud_color: Color = Color(1.0, 1.0, 1.0, 0.8):
	set(v):
		cloud_color = v
		_update_materials()

@export var edge_tint: Color = Color(0.7, 0.85, 0.9, 1.0):
	set(v):
		edge_tint = v
		_update_materials()

var _planes: Array[MeshInstance3D] = []
var _noise: FastNoiseLite

func _ready() -> void:
	_setup_noise()
	_rebuild()

func _setup_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.5
	_noise.fractal_octaves = 3

func _rebuild() -> void:
	# Clear existing
	for plane in _planes:
		if is_instance_valid(plane):
			plane.queue_free()
	_planes.clear()
	
	# Create planes
	var spacing = total_depth / max(plane_count - 1, 1)
	
	for i in range(plane_count):
		var plane = _create_plane(i, spacing)
		_planes.append(plane)
		add_child(plane)

func _create_plane(index: int, spacing: float) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Plane_%02d" % index
	
	# Create quad mesh
	var quad = QuadMesh.new()
	quad.size = plane_size
	mesh_instance.mesh = quad
	
	# Position in depth
	var z = -total_depth / 2.0 + index * spacing
	mesh_instance.position = Vector3(0, plane_size.y / 2.0, z)
	
	# Create material
	var mat = _create_plane_material(index)
	mesh_instance.material_override = mat
	
	return mesh_instance

func _create_plane_material(index: int) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = _get_glass_shader()
	
	# Set uniforms
	mat.set_shader_parameter("glass_color", glass_color)
	mat.set_shader_parameter("cloud_color", cloud_color)
	mat.set_shader_parameter("edge_tint", edge_tint)
	mat.set_shader_parameter("use_noise", use_noise)
	mat.set_shader_parameter("noise_scale", noise_scale)
	mat.set_shader_parameter("noise_z_offset", index * noise_offset_per_plane)
	mat.set_shader_parameter("plane_index", float(index) / max(plane_count - 1, 1))
	
	# Create noise texture for this plane
	if use_noise:
		var noise_tex = _generate_noise_texture(index)
		mat.set_shader_parameter("noise_texture", noise_tex)
	
	return mat

func _get_glass_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 glass_color : source_color = vec4(0.9, 0.95, 1.0, 0.15);
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform vec4 edge_tint : source_color = vec4(0.7, 0.85, 0.9, 1.0);
uniform bool use_noise = true;
uniform float noise_scale = 2.0;
uniform float noise_z_offset = 0.0;
uniform float plane_index = 0.0;
uniform sampler2D noise_texture;

void fragment() {
	vec4 color = glass_color;
	
	if (use_noise) {
		// Sample noise texture
		vec2 uv = UV * noise_scale;
		float noise_val = texture(noise_texture, UV).r;
		
		// Create cloud-like effect in center
		float center_dist = length(UV - vec2(0.5));
		float cloud_mask = smoothstep(0.5, 0.2, center_dist);
		cloud_mask *= noise_val;
		
		// Blend cloud into glass
		color = mix(glass_color, cloud_color, cloud_mask * 0.6);
	}
	
	// Edge tint (Fresnel-like)
	float edge = 1.0 - abs(dot(NORMAL, VIEW));
	color.rgb = mix(color.rgb, edge_tint.rgb, edge * 0.3);
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ROUGHNESS = 0.1;
	METALLIC = 0.0;
}
"""
	return shader

func _generate_noise_texture(index: int) -> NoiseTexture2D:
	var tex = NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02 * noise_scale
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	noise.offset = Vector3(0, 0, index * noise_offset_per_plane * 10)
	
	tex.noise = noise
	return tex

func _update_materials() -> void:
	for i in range(_planes.size()):
		if _planes[i].material_override:
			var mat = _planes[i].material_override as ShaderMaterial
			if mat:
				mat.set_shader_parameter("glass_color", glass_color)
				mat.set_shader_parameter("cloud_color", cloud_color)
				mat.set_shader_parameter("edge_tint", edge_tint)

func _update_noise() -> void:
	for i in range(_planes.size()):
		if _planes[i].material_override:
			var mat = _planes[i].material_override as ShaderMaterial
			if mat:
				mat.set_shader_parameter("noise_scale", noise_scale)
				mat.set_shader_parameter("noise_z_offset", i * noise_offset_per_plane)
				mat.set_shader_parameter("noise_texture", _generate_noise_texture(i))

## Get formula description
func get_formula() -> String:
	return "plane[i].z = i × %.2f\nnoise[i].offset = i × %.2f" % [total_depth / max(plane_count - 1, 1), noise_offset_per_plane]
