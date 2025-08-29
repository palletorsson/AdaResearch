# WebGLBufferGeometryParticlesVR.gd
# A mesmerizing VR scene with custom particle systems using buffer geometry and attributes
extends Node3D

@export var particle_count: int = 10000
@export var animation_speed: float = 1.0
@export var spread_radius: float = 25.0
@export var color_variation: float = 1.0

var particle_mesh: MeshInstance3D
var particle_material: ShaderMaterial
var custom_mesh: ArrayMesh

# Positions, velocities, colors, and other custom attributes
var positions: PackedVector3Array = []
var velocities: PackedVector3Array = []
var colors: PackedColorArray = []
var sizes: PackedFloat32Array = []
var life_times: PackedFloat32Array = []

# Custom particle shader with per-vertex attributes
const BUFFER_PARTICLE_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, depth_test_disabled, vertex_lighting, particle_trails, alpha_to_coverage;

uniform float time_scale : hint_range(0.1, 3.0) = 1.0;
uniform float size_multiplier : hint_range(0.1, 5.0) = 1.0;
uniform float animation_speed : hint_range(0.5, 3.0) = 1.0;

// Custom vertex attributes passed from mesh
uniform float particle_size;
uniform float particle_lifetime;
uniform vec3 particle_velocity;

varying float size_factor;
varying float life_factor;
varying vec3 world_pos;

void vertex() {
	// Calculate life progression (0.0 to 1.0)
	life_factor = mod(TIME * animation_speed + particle_lifetime, 1.0);
	
	// Animate position based on velocity and time
	vec3 animated_pos = VERTEX + particle_velocity * life_factor * 10.0;
	
	// Add some wave motion
	animated_pos.y += sin(TIME + animated_pos.x * 0.1) * 2.0;
	animated_pos.x += cos(TIME * 0.7 + animated_pos.z * 0.1) * 1.5;
	
	// Size based on lifetime (start small, grow, then shrink)
	float life_curve = sin(life_factor * 3.14159);
	size_factor = particle_size * life_curve * size_multiplier;
	
	// Apply size to vertex
	VERTEX = animated_pos;
	
	// Make particles face camera (billboard effect)
	vec3 camera_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 to_camera = normalize(camera_pos - VERTEX);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = normalize(cross(to_camera, up));
	up = cross(right, to_camera);
	
	// Scale the vertex position for billboard
	vec2 scaled_uv = (UV - vec2(0.5)) * size_factor;
	VERTEX += right * scaled_uv.x + up * scaled_uv.y;
	
	world_pos = VERTEX;
}

void fragment() {
	// Create circular particle with soft edges
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	
	// Soft circular falloff
	float circle = 1.0 - smoothstep(0.3, 0.5, dist);
	
	if (circle < 0.1) {
		discard;
	}
	
	// Fade particles as they age
	float alpha_fade = sin(life_factor * 3.14159);
	
	// Use vertex color from custom attributes
	vec3 particle_color = COLOR.rgb;
	
	// Add some sparkle effect based on position
	float sparkle = sin(world_pos.x * 10.0 + TIME * 2.0) * sin(world_pos.z * 8.0 + TIME * 1.5);
	sparkle = max(0.0, sparkle) * 0.3;
	
	ALBEDO = particle_color;
	EMISSION = particle_color * (1.0 + sparkle) * alpha_fade;
	ALPHA = COLOR.a * circle * alpha_fade;
}
"""

func _ready():
	setup_scene()
	generate_particle_data()
	create_custom_particle_mesh()
	start_particle_animation()

func setup_scene():
	# Create space-like environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	
	# Dark space background
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.05, 0.05, 0.15)
	sky_mat.sky_horizon_color = Color(0.1, 0.05, 0.2)
	sky_mat.ground_bottom_color = Color(0.02, 0.02, 0.08)
	
	env.ambient_light_energy = 0.1
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	# Add subtle volumetric fog
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.01
	env.volumetric_fog_emission = Color(0.1, 0.2, 0.4)
	env.volumetric_fog_emission_energy = 0.2
	
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env

func generate_particle_data():
	# Initialize arrays
	positions.clear()
	velocities.clear()
	colors.clear()
	sizes.clear()
	life_times.clear()
	
	# Generate random particle data
	for i in range(particle_count):
		# Random position in sphere
		var theta = randf() * PI * 2.0
		var phi = randf() * PI
		var radius = pow(randf(), 0.3) * spread_radius  # Power distribution for more center clustering
		
		var pos = Vector3(
			sin(phi) * cos(theta) * radius,
			(randf() - 0.5) * spread_radius * 0.5,
			sin(phi) * sin(theta) * radius
		)
		positions.append(pos)
		
		# Random velocity (generally outward with some variation)
		var vel_direction = pos.normalized() + Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.2, 0.8),
			randf_range(-0.5, 0.5)
		).normalized() * 0.3
		var vel_speed = randf_range(0.5, 2.0)
		velocities.append(vel_direction * vel_speed)
		
		# Random color based on position and variation
		var hue = (pos.length() / spread_radius + randf() * color_variation) * 360.0
		while hue > 360.0: hue -= 360.0
		var color = Color.from_hsv(hue / 360.0, randf_range(0.7, 1.0), randf_range(0.8, 1.0))
		colors.append(color)
		
		# Random size
		sizes.append(randf_range(0.1, 0.8))
		
		# Random lifetime offset
		life_times.append(randf() * 10.0)

func create_custom_particle_mesh():
	custom_mesh = ArrayMesh.new()
	
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var mesh_colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	# Custom attributes arrays
	var custom_sizes = PackedFloat32Array()
	var custom_lifetimes = PackedFloat32Array()
	var custom_velocities = PackedFloat32Array()  # We'll pack Vector3 as 3 floats
	
	# Create quad for each particle
	for i in range(particle_count):
		var base_index = vertices.size()
		var pos = positions[i]
		var color = colors[i]
		var size = sizes[i]
		var lifetime = life_times[i]
		var velocity = velocities[i]
		
		# Quad vertices (will be billboarded in shader)
		var quad_verts = [
			pos + Vector3(-0.5, -0.5, 0),
			pos + Vector3(0.5, -0.5, 0),
			pos + Vector3(0.5, 0.5, 0),
			pos + Vector3(-0.5, 0.5, 0)
		]
		
		vertices.append_array(quad_verts)
		
		# UV coordinates
		uvs.append_array([
			Vector2(0, 1),
			Vector2(1, 1),
			Vector2(1, 0),
			Vector2(0, 0)
		])
		
		# Colors (same for all quad vertices)
		for j in range(4):
			mesh_colors.append(color)
			custom_sizes.append(size)
			custom_lifetimes.append(lifetime)
			
			# Pack velocity as individual float components
			custom_velocities.append(velocity.x)
			custom_velocities.append(velocity.y)
			custom_velocities.append(velocity.z)
		
		# Quad indices
		indices.append_array([
			base_index, base_index + 1, base_index + 2,
			base_index, base_index + 2, base_index + 3
		])
	
	# Create mesh arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = mesh_colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	custom_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Set custom attributes (Note: This is a simplified approach)
	# In a full implementation, you'd want to use vertex buffers more directly
	
	# Create mesh instance
	particle_mesh = MeshInstance3D.new()
	particle_mesh.mesh = custom_mesh
	particle_mesh.name = "BufferGeometryParticles"
	
	# Create shader material
	particle_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = BUFFER_PARTICLE_SHADER
	particle_material.shader = shader
	
	# Set shader parameters
	particle_material.set_shader_parameter("time_scale", 1.0)
	particle_material.set_shader_parameter("size_multiplier", 1.5)
	particle_material.set_shader_parameter("animation_speed", animation_speed)
	
	particle_mesh.set_surface_override_material(0, particle_material)
	add_child(particle_mesh)

func start_particle_animation():
	# The particles animate automatically via the shader
	# Add some dynamic parameter changes
	animate_shader_parameters()

func animate_shader_parameters():
	# Animate size multiplier
	var size_tween = create_tween()
	size_tween.set_loops()
	size_tween.tween_method(
		func(value): particle_material.set_shader_parameter("size_multiplier", value),
		1.0, 2.5, 4.0
	)
	size_tween.tween_method(
		func(value): particle_material.set_shader_parameter("size_multiplier", value),
		2.5, 1.0, 4.0
	)
	
	# Animate animation speed
	var speed_tween = create_tween()
	speed_tween.set_loops()
	speed_tween.tween_method(
		func(value): particle_material.set_shader_parameter("animation_speed", value),
		animation_speed * 0.5, animation_speed * 1.8, 6.0
	)
	speed_tween.tween_method(
		func(value): particle_material.set_shader_parameter("animation_speed", value),
		animation_speed * 1.8, animation_speed * 0.5, 6.0
	)

func _process(_delta):
	# Optional: Update particle data in real-time
	# This would require regenerating the mesh, which can be expensive
	# For this example, we let the shader handle all animation
	pass

# Function to regenerate particles with new parameters
func regenerate_particles():
	if particle_mesh:
		particle_mesh.queue_free()
	
	generate_particle_data()
	create_custom_particle_mesh()

# Create different particle patterns
func create_spiral_pattern():
	positions.clear()
	velocities.clear()
	colors.clear()
	sizes.clear()
	life_times.clear()
	
	for i in range(particle_count):
		var t = float(i) / float(particle_count) * 8.0  # 8 spirals
		var radius = t * 2.0
		var height = t * 0.5
		
		var pos = Vector3(
			cos(t) * radius,
			height - 4.0,
			sin(t) * radius
		)
		positions.append(pos)
		
		# Velocity pointing outward and up
		var vel = Vector3(pos.x, 1.0, pos.z).normalized() * randf_range(1.0, 2.0)
		velocities.append(vel)
		
		# Rainbow colors based on position
		var hue = (t / 8.0) * 360.0
		var color = Color.from_hsv(hue / 360.0, 0.9, 1.0)
		colors.append(color)
		
		sizes.append(randf_range(0.2, 0.6))
		life_times.append(randf() * 5.0)

func create_explosion_pattern():
	positions.clear()
	velocities.clear()
	colors.clear()
	sizes.clear()
	life_times.clear()
	
	for i in range(particle_count):
		# Start near center
		var pos = Vector3(
			randf_range(-2.0, 2.0),
			randf_range(-1.0, 1.0),
			randf_range(-2.0, 2.0)
		)
		positions.append(pos)
		
		# Explosive outward velocities
		var vel_dir = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.2, 1.0),  # Slightly upward bias
			randf_range(-1.0, 1.0)
		).normalized()
		var vel_speed = randf_range(2.0, 5.0)
		velocities.append(vel_dir * vel_speed)
		
		# Hot colors (red/orange/yellow)
		var hue = randf_range(0.0, 60.0)  # Red to yellow range
		var color = Color.from_hsv(hue / 360.0, randf_range(0.8, 1.0), 1.0)
		colors.append(color)
		
		sizes.append(randf_range(0.3, 1.0))
		life_times.append(randf() * 3.0)

func create_galaxy_pattern():
	positions.clear()
	velocities.clear()
	colors.clear()
	sizes.clear()
	life_times.clear()
	
	for i in range(particle_count):
		# Create galactic spiral arms
		var arm = i % 3  # 3 spiral arms
		var t = float(i) / float(particle_count) * 6.0 + arm * 2.0
		var radius = sqrt(t) * 3.0
		var arm_angle = t + arm * (PI * 2.0 / 3.0)
		
		# Add some randomness
		radius += randf_range(-1.0, 1.0)
		arm_angle += randf_range(-0.3, 0.3)
		
		var pos = Vector3(
			cos(arm_angle) * radius,
			randf_range(-0.5, 0.5),
			sin(arm_angle) * radius
		)
		positions.append(pos)
		
		# Orbital velocity
		var orbital_speed = 1.0 / max(radius * 0.1, 0.1)  # Slower at edges
		var vel = Vector3(-sin(arm_angle), 0, cos(arm_angle)) * orbital_speed
		vel += Vector3(randf_range(-0.2, 0.2), randf_range(-0.1, 0.1), randf_range(-0.2, 0.2))
		velocities.append(vel)
		
		# Blue/white colors like stars
		var color_choice = randf()
		var color: Color
		if color_choice < 0.7:
			color = Color.from_hsv(randf_range(200.0, 240.0) / 360.0, randf_range(0.3, 0.8), 1.0)  # Blue
		else:
			color = Color(randf_range(0.9, 1.0), randf_range(0.9, 1.0), 1.0)  # White
		colors.append(color)
		
		sizes.append(randf_range(0.1, 0.4))
		life_times.append(randf() * 8.0)

# Call these in _ready() for different patterns
func _ready_with_pattern(pattern: String):
	setup_scene()
	
	match pattern:
		"spiral":
			create_spiral_pattern()
		"explosion":
			create_explosion_pattern()
		"galaxy":
			create_galaxy_pattern()
		_:
			generate_particle_data()
	
	create_custom_particle_mesh()
	start_particle_animation()
