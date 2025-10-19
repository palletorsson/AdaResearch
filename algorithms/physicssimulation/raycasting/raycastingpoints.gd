# RaycastingPointsVR.gd
# A mesmerizing VR scene with particles that react to invisible rays
extends Node3D

@export var particle_count: int = 3000
@export var ray_count: int = 8
@export var interaction_radius: float = 15.0
@export var animation_speed: float = 1.0
@export var particle_response_strength: float = 2.0

var particles: GPUParticles3D
var ray_casters: Array[Node3D] = []
var ray_positions: PackedVector3Array = []
var particle_material: ShaderMaterial

# Custom particle shader that responds to raycasting
const PARTICLE_SHADER = """
shader_type particles;
render_mode keep_data;

uniform float time_scale : hint_range(0.1, 3.0) = 1.0;
uniform vec3 ray_positions[8];
uniform float ray_strengths[8];
uniform float interaction_radius : hint_range(1.0, 20.0) = 10.0;
uniform float response_strength : hint_range(0.5, 5.0) = 2.0;
uniform vec3 gravity = vec3(0.0, -0.5, 0.0);

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void start() {
	// Initialize particle positions in a sphere
	float angle1 = random(vec2(float(INDEX), TIME)) * PI * 2.0;
	float angle2 = random(vec2(float(int(INDEX) + 1000), TIME)) * PI;
	float radius = pow(random(vec2(float(int(INDEX) + 2000), TIME)), 0.5) * 12.0;
	
	TRANSFORM[3][0] = sin(angle2) * cos(angle1) * radius;
	TRANSFORM[3][1] = cos(angle2) * radius + 5.0;
	TRANSFORM[3][2] = sin(angle2) * sin(angle1) * radius;
	
	VELOCITY = vec3(0.0);
	CUSTOM.x = random(vec2(float(int(INDEX) + 3000), TIME)) * 6.28; // Phase
	CUSTOM.y = 1.0; // Base scale
	CUSTOM.z = random(vec2(float(int(INDEX) + 4000), TIME)) * 0.5 + 0.5; // Random factor
}

void process() {
	vec3 position = TRANSFORM[3].xyz;
	vec3 force = gravity * DELTA;
	
	// Calculate influence from all ray positions
	float total_influence = 0.0;
	vec3 total_ray_force = vec3(0.0);
	
	for (int i = 0; i < 8; i++) {
		vec3 to_ray = ray_positions[i] - position;
		float distance = length(to_ray);
		
		if (distance < interaction_radius && distance > 0.1) {
			float influence = ray_strengths[i] * (1.0 - distance / interaction_radius);
			influence = pow(influence, 2.0);
			
			// Push particles away from rays
			vec3 ray_force = -normalize(to_ray) * influence * response_strength;
			total_ray_force += ray_force;
			total_influence += influence;
		}
	}
	
	// Apply ray forces
	force += total_ray_force * DELTA;
	
	// Add some orbital motion
	vec3 center_offset = position - vec3(0.0, 5.0, 0.0);
	float orbit_strength = 0.3;
	vec3 orbit_force = vec3(-center_offset.z, 0.0, center_offset.x) * orbit_strength;
	force += orbit_force * DELTA;
	
	// Apply forces
	VELOCITY += force;
	VELOCITY *= 0.98; // Damping
	
	// Update custom data for visual effects
	CUSTOM.x += TIME * time_scale; // Animation phase
	CUSTOM.y = 1.0 + total_influence * 2.0; // Scale based on ray influence
	
	// Bounds checking - respawn if too far
	if (length(position) > 30.0) {
		float angle1 = random(vec2(TIME, float(INDEX))) * PI * 2.0;
		float angle2 = random(vec2(TIME + 1.0, float(INDEX))) * PI;
		float radius = pow(random(vec2(TIME + 2.0, float(INDEX))), 0.5) * 12.0;
		
		TRANSFORM[3][0] = sin(angle2) * cos(angle1) * radius;
		TRANSFORM[3][1] = cos(angle2) * radius + 5.0;
		TRANSFORM[3][2] = sin(angle2) * sin(angle1) * radius;
		VELOCITY = vec3(0.0);
	}
}
"""

# Visual shader for particle rendering  
const PARTICLE_VISUAL_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, depth_test_disabled,   vertex_lighting, particle_trails, alpha_to_coverage;

uniform float brightness : hint_range(0.5, 3.0) = 1.5;
uniform vec4 base_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);
uniform vec4 excited_color : source_color = vec4(1.0, 0.3, 0.8, 1.0);
uniform float pulse_speed : hint_range(0.5, 3.0) = 1.5;

varying float scale_factor;
varying float phase;

void vertex() {
	// Get custom data from particle system
	scale_factor = 1.0; // Set default or pass via uniform
	phase = TIME; // Use time for animatio
	// Scale based on ray interaction
	VERTEX *= mix(0.5, 2.0, scale_factor);
	
	// Add size variation based on distance
	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vec3 cam_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float distance_to_cam = length(world_pos.xyz - cam_pos);
	float size_factor = 1.0 / max(distance_to_cam * 0.1, 0.5);
	VERTEX *= size_factor;
}

void fragment() {
	// Create glowing sphere effect
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv);
	
	if (distance_from_center > 0.5) {
		discard;
	}
	
	// Create glow falloff
	float glow = 1.0 - (distance_from_center / 0.5);
	glow = pow(glow, 2.0);
	
	// Pulse effect based on phase and scale
	float pulse = sin(phase * pulse_speed) * 0.3 + 0.7;
	pulse *= scale_factor;
	
	// Mix colors based on excitement level
	vec3 final_color = mix(base_color.rgb, excited_color.rgb, scale_factor - 1.0);
	
	ALBEDO = final_color;
	EMISSION = final_color * brightness * pulse * glow;
	ALPHA = base_color.a * glow * pulse;
}
"""

func _ready():
	setup_scene()
	create_particle_system()
	create_ray_casters()
	start_ray_animations()

func setup_scene():
	# Create mystical environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	
	# Dark, mysterious atmosphere
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.05, 0.05, 0.15)
	sky_mat.sky_horizon_color = Color(0.1, 0.05, 0.2)
	sky_mat.ground_bottom_color = Color(0.02, 0.02, 0.08)
	sky_mat.ground_horizon_color = Color(0.05, 0.03, 0.1)
	
	env.ambient_light_energy = 0.2
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	# Add volumetric fog for atmosphere
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.05
	env.volumetric_fog_emission = Color(0.1, 0.2, 0.4)
	env.volumetric_fog_emission_energy = 0.3
	
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env
	
	# Subtle ambient lighting
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 15, 5)
	light.look_at_from_position(light.position, Vector3.ZERO, Vector3.UP)
	light.light_energy = 0.3
	light.light_color = Color(0.7, 0.8, 1.0)
	add_child(light)

func create_particle_system():
	# Create GPU particle system
	particles = GPUParticles3D.new()
	particles.emitting = true
	particles.amount = particle_count
	particles.lifetime = 60.0  # Long lifetime for persistent particles
	particles.preprocess = 2.0
	
	# Use quad mesh for particles
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.2, 0.2)
	particles.draw_pass_1 = quad_mesh
	
	# Create custom particle material
	particle_material = ShaderMaterial.new()
	var visual_shader = Shader.new()
	visual_shader.code = PARTICLE_VISUAL_SHADER
	particle_material.shader = visual_shader
	
	# Set shader parameters
	particle_material.set_shader_parameter("brightness", 1.8)
	particle_material.set_shader_parameter("base_color", Color(0.3, 0.7, 1.0, 0.8))
	particle_material.set_shader_parameter("excited_color", Color(1.0, 0.3, 0.8, 1.0))
	particle_material.set_shader_parameter("pulse_speed", 2.0)
	
	particles.material_override = particle_material
	
	# Set up process material with custom shader
	var process_material = ParticleProcessMaterial.new()
	# We'll override this with our custom shader
	particles.process_material = process_material
	
	add_child(particles)
	
	# Apply custom particle shader
	apply_custom_particle_shader()

func apply_custom_particle_shader():
	# Create shader for particle processing
	var shader = Shader.new()
	shader.code = PARTICLE_SHADER
	
	var process_material = ShaderMaterial.new()
	process_material.shader = shader
	
	# Set initial parameters
	process_material.set_shader_parameter("time_scale", animation_speed)
	process_material.set_shader_parameter("interaction_radius", interaction_radius)
	process_material.set_shader_parameter("response_strength", particle_response_strength)
	process_material.set_shader_parameter("gravity", Vector3(0.0, -0.3, 0.0))
	
	# Initialize ray data
	var ray_pos_array: Array[Vector3] = []
	var ray_strength_array: Array[float] = []
	
	for i in range(8):  # Max 8 rays supported by shader
		ray_pos_array.append(Vector3.ZERO)
		ray_strength_array.append(0.0)
	
	process_material.set_shader_parameter("ray_positions", ray_pos_array)
	process_material.set_shader_parameter("ray_strengths", ray_strength_array)
	
	particles.process_material = process_material

func create_ray_casters():
	# Create invisible ray casting points
	ray_positions.clear()
	
	for i in range(ray_count):
		var ray_caster = Node3D.new()
		ray_caster.name = "RayCaster_" + str(i)
		
		# Position rays in interesting patterns
		var angle = (i * PI * 2.0) / ray_count
		var radius = 8.0
		ray_caster.position = Vector3(cos(angle) * radius, 5.0, sin(angle) * radius)
		
		add_child(ray_caster)
		ray_casters.append(ray_caster)
		ray_positions.append(ray_caster.position)
		
		# Create visual indicator (optional - can be invisible)
		create_ray_visualizer(ray_caster, i)

func create_ray_visualizer(ray_caster: Node3D, index: int):
	# Create subtle visual indicator of ray position
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	sphere.mesh = sphere_mesh
	
	# Glowing material for ray source
	var material = StandardMaterial3D.new()
	material.flags_unshaded = true
	material.emission_enabled = true
	var ray_colors = [
		Color.CYAN, Color.MAGENTA, Color.YELLOW, Color.GREEN,
		Color.RED, Color.BLUE, Color.ORANGE, Color.PURPLE
	]
	material.emission = ray_colors[index % ray_colors.size()]
	material.albedo_color = material.emission
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	sphere.set_surface_override_material(0, material)
	ray_caster.add_child(sphere)

func start_ray_animations():
	# Animate ray casters in complex patterns
	for i in range(ray_casters.size()):
		var ray_caster = ray_casters[i]
		animate_ray_caster(ray_caster, i)

func animate_ray_caster(ray_caster: Node3D, index: int):
	var tween = create_tween()
	tween.set_loops()
	
	# Different movement patterns for each ray
	match index % 4:
		0:  # Circular orbit
			var radius = 8.0 + sin(index * 0.5) * 3.0
			tween.tween_method(
				func(t): ray_caster.position = Vector3(
					cos(t) * radius, 
					5.0 + sin(t * 2.0) * 2.0, 
					sin(t) * radius
				),
				0.0, PI * 2.0, 
				6.0 / animation_speed
			)
			
		1:  # Figure-8 pattern
			tween.tween_method(
				func(t): ray_caster.position = Vector3(
					sin(t) * 6.0,
					5.0 + cos(t * 2.0) * 3.0,
					sin(t * 2.0) * 4.0
				),
				0.0, PI * 2.0,
				8.0 / animation_speed
			)
			
		2:  # Vertical spiral
			var base_radius = 5.0
			tween.tween_method(
				func(t): ray_caster.position = Vector3(
					cos(t) * base_radius,
					2.0 + t * 2.0,
					sin(t) * base_radius
				),
				0.0, PI * 4.0,
				10.0 / animation_speed
			)
			
		3:  # Random walk with smooth interpolation
			create_random_walk_animation(ray_caster)

func create_random_walk_animation(ray_caster: Node3D):
	var tween = create_tween()
	tween.set_loops()
	
	# Generate random waypoints
	var waypoints: Array[Vector3] = []
	for i in range(6):
		waypoints.append(Vector3(
			randf_range(-10.0, 10.0),
			randf_range(2.0, 8.0),
			randf_range(-10.0, 10.0)
		))
	waypoints.append(waypoints[0])  # Loop back to start
	
	# Animate through waypoints
	for i in range(waypoints.size() - 1):
		tween.tween_property(ray_caster, "position", waypoints[i + 1], 2.0 / animation_speed)
	
	# Ensure the tween has operations before setting loops
	if waypoints.size() > 1:
		tween.play()
	else:
		# Fallback if no waypoints
		tween.tween_property(ray_caster, "position", ray_caster.position, 1.0)
		tween.play()

func _process(_delta):
	# Update ray positions in shader
	if particles and particles.process_material:
		update_ray_shader_data()

func update_ray_shader_data():
	var process_material = particles.process_material as ShaderMaterial
	if not process_material:
		return
	
	# Update ray positions
	var ray_pos_array: Array[Vector3] = []
	var ray_strength_array: Array[float] = []
	
	for i in range(8):  # Shader supports max 8 rays
		if i < ray_casters.size():
			ray_pos_array.append(ray_casters[i].position)
			# Vary ray strength over time
			var strength = sin(Time.get_time_dict_from_system()["second"] * 2.0 + i) * 0.5 + 1.0
			ray_strength_array.append(strength)
		else:
			ray_pos_array.append(Vector3.ZERO)
			ray_strength_array.append(0.0)
	
	process_material.set_shader_parameter("ray_positions", ray_pos_array)
	process_material.set_shader_parameter("ray_strengths", ray_strength_array)

# Optional: Add interaction with VR controllers
func _input(event):
	# This could be extended to respond to VR controller input
	# For now, rays move automatically
	pass
