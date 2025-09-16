extends GPUParticles3D

@export var texts_to_emit: Array[String] = ["VAPOR", "WAVE", "NEON", "SYNTH"]
@export var emit_rate: float = 2.0
@onready var material: ShaderMaterial

func _ready():
	# Setup particle system
	emitting = true
	amount = 50
	lifetime = 5.0
	
	# Configure process material
	var process_mat = ParticleProcessMaterial.new()
	process_mat.direction = Vector3(0, 1, 0)
	process_mat.initial_velocity_min = 2.0
	process_mat.initial_velocity_max = 5.0
	process_mat.gravity = Vector3(0, -1, 0)
	process_mat.scale_min = 0.5
	process_mat.scale_max = 2.0
	
	# IMPORTANT: Enable custom data and set it to pass lifetime
	process_mat.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_DISABLED
	
	process_material = process_mat
	
	# Setup text material
	setup_text_material()

func setup_text_material():
	material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = get_text_shader()
	material.shader = shader
	
	# Set material to particle system
	var mesh = QuadMesh.new()
	mesh.size = Vector2(2, 1)
	draw_pass_1 = mesh
	draw_pass_1.surface_set_material(0, material)

func get_text_shader() -> String:
	return """
shader_type spatial;
render_mode depth_test_disabled, unshaded, cull_disabled, blend_mix;

uniform float fade_power : hint_range(0.1, 5.0) = 2.0;
uniform vec4 text_color : source_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);

varying float life_progress;

void vertex() {
	// Use COLOR.a which contains the particle's life progress (0.0 = dead, 1.0 = just born)
	life_progress = 1.0 - COLOR.a;
	
	// Scale based on life
	float scale = 1.0 - life_progress * 0.3;
	VERTEX *= scale;
}

void fragment() {
	vec2 uv = UV;
	
	// Create simple text-like pattern
	float text_pattern = 0.0;
	
	// Horizontal lines for text effect
	float lines = step(0.4, sin(uv.y * 25.0)) * step(0.2, sin(uv.x * 35.0));
	text_pattern += lines * 0.9;
	
	// Add some character-like shapes  
	float chars = step(0.6, sin(uv.x * 18.0 + uv.y * 12.0));
	text_pattern += chars * 0.5;
	
	// Add vertical elements to look more like letters
	float verticals = step(0.7, sin(uv.x * 40.0)) * step(0.3, sin(uv.y * 8.0));
	text_pattern += verticals * 0.3;
	
	// Make pattern more solid
	text_pattern = clamp(text_pattern, 0.0, 1.0);
	
	// Fade out over lifetime
	float alpha = pow(1.0 - life_progress, fade_power) * text_pattern;
	
	// Only show if there's actual pattern
	alpha *= step(0.1, text_pattern);
	
	// Color mixing
	vec3 final_color = mix(text_color.rgb, glow_color.rgb, life_progress * 0.5);
	
	ALBEDO = final_color;
	EMISSION = final_color * alpha * 3.0;
	ALPHA = alpha;
}
"""
