# WaterFlowersVR.gd
# A mesmerizing VR scene with realistic water and physically simulated floating flowers.
extends Node3D

@export var flower_count: int = 50
@export var water_size: float = 30.0
@export var wave_strength: float = 0.8
@export var animation_speed: float = 1.0
@export var flower_drift_speed: float = 0.5

# Physics constants for flower floating behavior
const BUOYANCY_STIFFNESS = 25.0 # Spring force pushing flower to surface
const BUOYANCY_DAMPING = 3.0   # Reduces oscillation for stability
const ALIGNMENT_TORQUE = 10.0  # Force to align flower with wave angle

var water_mesh: MeshInstance3D
var flowers: Array[RigidBody3D] = []
var water_material: ShaderMaterial

# An array defining the "resonant frequencies" of the water.
# Each dictionary is a wave component with specific properties.
var wave_params = [
	{"direction": Vector2(1.0, 0.0), "frequency": 0.8, "amplitude": 1.0, "speed": 1.2, "steepness": 0.3},
	{"direction": Vector2(0.7, 0.7), "frequency": 1.2, "amplitude": 0.6, "speed": 1.3, "steepness": 0.4},
	{"direction": Vector2(0.3, 1.0), "frequency": 2.0, "amplitude": 0.3, "speed": 0.7, "steepness": 0.2},
	{"direction": Vector2(1.0, 0.5), "frequency": 3.5, "amplitude": 0.15, "speed": 1.5, "steepness": 0.1}
]

# Advanced water shader using Gerstner-like waves for more realism.
const WATER_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform float animation_speed : hint_range(0.5, 3.0) = 1.0;
uniform float wave_strength : hint_range(0.1, 2.0) = 0.8;

// Wave Component Parameters (up to 4 waves)
uniform vec4 wave1_params = vec4(0.8, 1.0, 1.2, 0.3); // freq, ampl, speed, steepness
uniform vec2 wave1_dir = vec2(1.0, 0.0);
uniform vec4 wave2_params = vec4(1.2, 0.6, 1.3, 0.4);
uniform vec2 wave2_dir = vec2(0.7, 0.7);
uniform vec4 wave3_params = vec4(2.0, 0.3, 0.7, 0.2);
uniform vec2 wave3_dir = vec2(0.3, 1.0);
uniform vec4 wave4_params = vec4(3.5, 0.15, 1.5, 0.1);
uniform vec2 wave4_dir = vec2(1.0, 0.5);

uniform vec4 water_color_deep : source_color = vec4(0.0, 0.2, 0.4, 0.8);
uniform vec4 water_color_shallow : source_color = vec4(0.2, 0.6, 0.8, 0.6);
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.7;
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec3 world_position;

// Gerstner wave function for more realistic peaks
vec3 gerstner_wave(vec2 pos, vec2 dir, float freq, float ampl, float speed, float steepness, inout vec3 tangent, inout vec3 bitangent) {
	float phase = speed * freq * TIME * animation_speed;
	float wave_val = dot(dir, pos) * freq + phase;
	float S = sin(wave_val);
	float C = cos(wave_val);

	// Calculate displacement
	float displacement_x = steepness * ampl * dir.x * C;
	float displacement_y = ampl * S;
	float displacement_z = steepness * ampl * dir.y * C;

	// Calculate derivatives for normals
	float wa = freq * ampl;
	tangent += vec3(
		1.0 - steepness * dir.x * dir.x * wa * S,
		dir.x * wa * C,
		-steepness * dir.x * dir.y * wa * S
	);
	bitangent += vec3(
		-steepness * dir.x * dir.y * wa * S,
		dir.y * wa * C,
		1.0 - steepness * dir.y * dir.y * wa * S
	);
	return vec3(displacement_x, displacement_y, displacement_z);
}

void vertex() {
	vec3 p = VERTEX;
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 bitangent = vec3(0.0, 0.0, 1.0);

	// Sum of resonant frequencies (wave components)
	p += gerstner_wave(vec2(VERTEX.x, VERTEX.z), wave1_dir, wave1_params.x, wave1_params.y * wave_strength, wave1_params.z, wave1_params.w, tangent, bitangent);
	p += gerstner_wave(vec2(VERTEX.x, VERTEX.z), wave2_dir, wave2_params.x, wave2_params.y * wave_strength, wave2_params.z, wave2_params.w, tangent, bitangent);
	p += gerstner_wave(vec2(VERTEX.x, VERTEX.z), wave3_dir, wave3_params.x, wave3_params.y * wave_strength, wave3_params.z, wave3_params.w, tangent, bitangent);
	p += gerstner_wave(vec2(VERTEX.x, VERTEX.z), wave4_dir, wave4_params.x, wave4_params.y * wave_strength, wave4_params.z, wave4_params.w, tangent, bitangent);
	
	VERTEX = p;
	NORMAL = normalize(cross(bitangent, tangent));
	world_position = VERTEX;
}

void fragment() {
	// Fragment shader remains mostly the same, focusing on appearance
	float depth = max(0.0, -world_position.y + 2.0);
	vec3 water_color = mix(water_color_shallow.rgb, water_color_deep.rgb, min(depth * 0.3, 1.0));
	
	float foam = smoothstep(foam_threshold, 1.0, NORMAL.y);
	vec3 final_color = mix(water_color, foam_color.rgb, foam * 0.8);
	
	vec3 view_dir = normalize(world_position - (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	float fresnel = 1.0 - abs(dot(NORMAL, -view_dir));
	fresnel = pow(fresnel, 2.0);
	
	ALBEDO = final_color;
	METALLIC = metallic;
	ROUGHNESS = mix(roughness, 0.3, foam);
	EMISSION = final_color * fresnel * 0.1;
	
	float alpha = mix(water_color_shallow.a, water_color_deep.a, min(depth * 0.2, 1.0));
	alpha = mix(alpha, 1.0, foam);
	ALPHA = alpha;
}
"""

# Flower petal shader (remains unchanged)
const FLOWER_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert;

uniform vec4 petal_color : source_color = vec4(1.0, 0.5, 0.7, 1.0);
uniform vec4 center_color : source_color = vec4(1.0, 1.0, 0.3, 1.0);
uniform float petal_softness : hint_range(0.1, 1.0) = 0.6;
uniform float sway_strength : hint_range(0.0, 0.5) = 0.2;
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;

varying vec2 petal_uv;
varying vec3 world_pos;

void vertex() {
	petal_uv = UV;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Add gentle swaying motion
	vec3 sway = vec3(
		sin(TIME * 2.0 + time_offset + world_pos.x * 0.1) * sway_strength,
		0.0,
		cos(TIME * 1.5 + time_offset + world_pos.z * 0.1) * sway_strength
	);
	VERTEX += sway;
}

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist_to_center = distance(petal_uv, center);
	float petal_mask = smoothstep(0.5, 0.3, dist_to_center);
	float angle = atan(petal_uv.y - center.y, petal_uv.x - center.x);
	float petal_segments = sin(angle * 5.0) * 0.1 + 0.9;
	petal_mask *= petal_segments;
	
	if (petal_mask < 0.1) {
		discard;
	}
	
	vec3 flower_color = mix(petal_color.rgb, center_color.rgb, 
						   smoothstep(0.3, 0.1, dist_to_center));
	float variation = sin(world_pos.x + world_pos.z + TIME * 0.5) * 0.1;
	flower_color += variation;
	
	ALBEDO = flower_color;
	ALPHA = petal_color.a * petal_mask * petal_softness;
}
"""

func _ready():
	print("=== WATERFLOWERSVR SCRIPT IS RUNNING! ===")
	print("WaterFlowersVR: Starting setup...")
	
	# Test if we can create objects at all
	var test_sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	test_sphere.mesh = sphere_mesh
	test_sphere.position = Vector3(0, 3, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	material.emission_enabled = true
	material.emission = Color.GREEN * 0.5
	test_sphere.set_surface_override_material(0, material)
	
	add_child(test_sphere)
	print("WaterFlowersVR: GREEN TEST SPHERE created at: ", test_sphere.position)
	
	setup_scene()
	print("WaterFlowersVR: Scene setup complete")
	create_water_surface()
	print("WaterFlowersVR: Water surface created")
	create_floating_flowers()
	print("WaterFlowersVR: Flowers created, total count: ", flowers.size())
	
	# Add a simple test cube to verify scene is working
	create_test_cube()
	print("WaterFlowersVR: Test cube created")
	
	print("=== WATERFLOWERSVR SETUP COMPLETE! ===")
	# Animations are now handled entirely by the physics process.

func create_test_cube():
	var test_cube = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(1.0, 1.0, 1.0)
	test_cube.mesh = cube_mesh
	test_cube.position = Vector3(0, 5, 0) # High up so it's visible
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission_enabled = true
	material.emission = Color.RED * 0.5
	test_cube.set_surface_override_material(0, material)
	
	add_child(test_cube)
	print("Test cube added at position: ", test_cube.position)

func setup_scene():
	# (Function remains unchanged)
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.4, 0.7, 1.0)
	sky_mat.sky_horizon_color = Color(0.8, 0.9, 1.0)
	sky_mat.ground_bottom_color = Color(0.2, 0.4, 0.3)
	sky_mat.ground_horizon_color = Color(0.6, 0.8, 0.7)
	env.ambient_light_energy = 0.6
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env
	var sun_light = DirectionalLight3D.new()
	sun_light.position = Vector3(10, 15, 5)
	sun_light.look_at_from_position(sun_light.position, Vector3.ZERO, Vector3.UP)
	sun_light.light_energy = 1.0
	sun_light.light_color = Color(1.0, 0.95, 0.8)
	add_child(sun_light)

func create_water_surface():
	var water_plane = PlaneMesh.new()
	water_plane.size = Vector2(water_size, water_size)
	water_plane.subdivide_width = 100
	water_plane.subdivide_depth = 100
	water_mesh = MeshInstance3D.new()
	water_mesh.mesh = water_plane
	water_mesh.name = "WaterSurface"
	
	# Position water surface at ground level
	water_mesh.position.y = 0.0
	
	# Start with a simple material to test visibility
	var simple_material = StandardMaterial3D.new()
	simple_material.albedo_color = Color(0.2, 0.6, 0.9, 0.8)
	simple_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	simple_material.metallic = 0.1
	simple_material.roughness = 0.02
	
	water_mesh.set_surface_override_material(0, simple_material)
	
	add_child(water_mesh)
	
	print("Water surface created at position: ", water_mesh.position)
	print("Water size: ", water_size)
	
	# TODO: Uncomment shader material when shader issues are resolved
	# water_material = ShaderMaterial.new()
	# var shader = Shader.new()
	# shader.code = WATER_SHADER
	# water_material.shader = shader

func create_floating_flowers():
	# (Function remains mostly unchanged)
	var flower_types = [ "lotus", "lily", "rose", "daisy", "cherry_blossom", "water_lily" ]
	var flower_colors = [ Color(1.0, 0.7, 0.8), Color(0.9, 0.9, 1.0), Color(1.0, 0.3, 0.5), Color(1.0, 1.0, 0.4), Color(0.8, 0.5, 1.0), Color(0.5, 0.9, 0.6) ]
	for i in range(flower_count):
		create_floating_flower(i, flower_colors[i % flower_colors.size()], flower_types[i % flower_types.size()])

func create_floating_flower(index: int, color: Color, flower_type: String):
	var flower_body = RigidBody3D.new()
	flower_body.name = "Flower_" + str(index) + "_" + flower_type
	flower_body.mass = 0.1
	flower_body.gravity_scale = 0.5 # Reduce gravity for better floating
	
	var flower_mesh_instance = MeshInstance3D.new()
	flower_mesh_instance.mesh = create_flower_mesh(flower_type, index)
	
	# Use simple material instead of shader for now
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.1
	material.roughness = 0.8
	material.emission_enabled = true
	material.emission = color * 0.3 # Make flowers glow slightly
	
	flower_mesh_instance.set_surface_override_material(0, material)
	flower_body.add_child(flower_mesh_instance)
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = SphereShape3D.new()
	collision_shape.shape.radius = 0.2
	flower_body.add_child(collision_shape)
	
	var angle = randf() * TAU
	var radius = randf_range(2.0, water_size * 0.4)
	flower_body.position = Vector3(cos(angle) * radius, 2.0, sin(angle) * radius) # Start higher
	
	add_child(flower_body)
	flowers.append(flower_body)
	
	print("Created flower ", index, " at position: ", flower_body.position)

func _physics_process(delta):
	# Use physics process for all interactions
	var time = Time.get_ticks_msec() / 1000.0
	
	for flower in flowers:
		if not is_instance_valid(flower):
			continue
		
		var pos = flower.global_transform.origin
		var water_state = get_water_state_at_position(Vector2(pos.x, pos.z), time)
		var water_height = water_state.height
		var water_normal = water_state.normal
		
		# --- Buoyancy (Damped Spring) ---
		var displacement = pos.y - water_height
		# Spring force (Hooke's Law): F = -k * x
		var spring_force = -BUOYANCY_STIFFNESS * displacement
		# Damping force: F = -d * v
		var damping_force = -BUOYANCY_DAMPING * flower.linear_velocity.y
		# Apply buoyancy force, counteracting gravity
		var buoyancy_impulse = (spring_force + damping_force) * delta
		flower.apply_central_impulse(Vector3(0, buoyancy_impulse, 0))
		
		# --- Alignment to Waves ---
		var up_vec = flower.global_transform.basis.y
		var torque_axis = up_vec.cross(water_normal)
		var torque_magnitude = acos(up_vec.dot(water_normal)) * ALIGNMENT_TORQUE
		flower.apply_torque_impulse(torque_axis * torque_magnitude * delta)
		
		# --- Water Current/Drift ---
		var current_force = Vector3(-pos.z, 0, pos.x).normalized() * 0.01
		current_force += Vector3(sin(time + pos.x * 0.1), 0, cos(time + pos.z * 0.1)) * 0.005
		flower.apply_central_force(current_force * flower_drift_speed)
		
		# Keep flowers within bounds
		var pos_2d = Vector2(pos.x, pos.z)
		if pos_2d.length() > water_size * 0.45:
			var center_force = -pos_2d.normalized() * 0.1
			flower.apply_central_force(Vector3(center_force.x, 0, center_force.y))

# Add a simple _process function to handle flower water interactions
func _process(delta):
	# Update flower water interactions
	update_flower_water_interaction(delta)

func update_flower_water_interaction(delta):
	# Keep flowers floating on water surface
	for flower in flowers:
		if flower and is_instance_valid(flower):
			# Simulate water surface tension - keep flowers at water level
			var water_level = get_water_height_at_position(flower.position)
			
			if flower.position.y < water_level - 0.1:
				# Push flower up to surface
				var buoyancy_force = Vector3(0, 2.0, 0)
				flower.apply_central_impulse(buoyancy_force * delta)
			elif flower.position.y > water_level + 0.2:
				# Gentle settling
				var settle_force = Vector3(0, -0.5, 0)
				flower.apply_central_impulse(settle_force * delta)

# Add missing function for water height calculation
func get_water_height_at_position(pos: Vector3) -> float:
	# Simple water height calculation for now
	var time = Time.get_time_dict_from_system()["second"]
	var height = 0.0
	
	# Add some wave variation
	for i in range(wave_params.size()):
		var params = wave_params[i]
		var dir = params.direction
		var freq = params.frequency
		var ampl = params.amplitude * wave_strength
		var speed = params.speed
		
		var phase = speed * freq * time * animation_speed
		var wave_val = dir.dot(Vector2(pos.x, pos.z)) * freq + phase
		height += ampl * sin(wave_val)
	
	return height

# This function calculates the water's height and normal at any point,
# perfectly matching the shader logic.
func get_water_state_at_position(pos: Vector2, time: float) -> Dictionary:
	var p = Vector3(pos.x, 0, pos.y)
	var tangent = Vector3(1.0, 0.0, 0.0)
	var bitangent = Vector3(0.0, 0.0, 1.0)
	
	for i in range(wave_params.size()):
		var params = wave_params[i]
		var dir = params.direction
		var freq = params.frequency
		var ampl = params.amplitude * wave_strength
		var speed = params.speed
		var steep = params.steepness
		
		var phase = speed * freq * time * animation_speed
		var wave_val = dir.dot(pos) * freq + phase
		var S = sin(wave_val)
		var C = cos(wave_val)

		p.x += steep * ampl * dir.x * C
		p.y += ampl * S
		p.z += steep * ampl * dir.y * C

		var wa = freq * ampl
		tangent += Vector3(
			1.0 - steep * dir.x * dir.x * wa * S,
			dir.x * wa * C,
			-steep * dir.x * dir.y * wa * S
		)
		bitangent += Vector3(
			-steep * dir.x * dir.y * wa * S,
			dir.y * wa * C,
			1.0 - steep * dir.y * dir.y * wa * S
		)
	
	var normal = bitangent.cross(tangent).normalized()
	return {"height": p.y, "normal": normal}

# --- Mesh Creation Functions ---
# (These functions remain unchanged as they only define geometry)
func create_flower_mesh(flower_type: String, index: int) -> ArrayMesh:
	match flower_type:
		"lotus": return create_lotus_mesh(index)
		"lily": return create_lily_mesh(index)
		"rose": return create_rose_mesh(index)
		"daisy": return create_daisy_mesh(index)
		"cherry_blossom": return create_cherry_blossom_mesh(index)
		_: return create_water_lily_mesh(index)
func create_lotus_mesh(index: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var petal_layers = 2
	var petals_per_layer = 8
	for layer in range(petal_layers):
		var layer_radius = 0.4 + layer * 0.3
		var layer_height = layer * 0.05
		for petal in range(petals_per_layer):
			var angle = (float(petal) / petals_per_layer) * TAU + layer * 0.2
			var next_angle = (float(petal + 1) / petals_per_layer) * TAU + layer * 0.2
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(Vector3(0, layer_height, 0))
			st.set_uv(Vector2(0.5 + 0.3 * cos(angle), 0.5 + 0.3 * sin(angle)))
			st.add_vertex(Vector3(cos(angle) * layer_radius * 0.6, layer_height, sin(angle) * layer_radius * 0.6))
			st.set_uv(Vector2(0.5 + 0.5 * cos(angle), 0.5 + 0.5 * sin(angle)))
			st.add_vertex(Vector3(cos(angle) * layer_radius, layer_height + 0.1, sin(angle) * layer_radius))
	st.generate_normals()
	return st.commit()
func create_lily_mesh(index: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(6):
		var angle = (float(i) / 6.0) * TAU
		st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(Vector3.ZERO)
		st.set_uv(Vector2(0.5 + 0.3*cos(angle-0.3), 0.5+0.3*sin(angle-0.3))); st.add_vertex(Vector3(cos(angle - 0.3) * 0.3, 0.0, sin(angle - 0.3) * 0.3))
		st.set_uv(Vector2(0.5 + 0.5*cos(angle), 0.5+0.5*sin(angle))); st.add_vertex(Vector3(cos(angle) * 0.6, 0.05, sin(angle) * 0.6))
	st.generate_normals(); return st.commit()
func create_rose_mesh(index: int) -> ArrayMesh: return create_lotus_mesh(index)
func create_daisy_mesh(index: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var angle = (float(i) / 12.0) * TAU
		st.set_uv(Vector2(0.5,0.5)); st.add_vertex(Vector3.ZERO);
		st.set_uv(Vector2(0.5+0.1*cos(angle-0.05),0.5+0.1*sin(angle-0.05))); st.add_vertex(Vector3(cos(angle-0.05)*0.1, 0, sin(angle-0.05)*0.1))
		st.set_uv(Vector2(0.5+0.5*cos(angle),0.5+0.5*sin(angle))); st.add_vertex(Vector3(cos(angle)*0.5, 0.02, sin(angle)*0.5))
	st.generate_normals(); return st.commit()
	
func create_cherry_blossom_mesh(index: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(5):
		var angle = (float(i) / 5.0) * TAU
		var next_angle = (float(i + 1) / 5.0) * TAU
		
		# First triangle: center, inner petal, outer petal
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(Vector3.ZERO)
		st.set_uv(Vector2(0.5 + 0.1 * cos(angle), 0.5 + 0.1 * sin(angle)))
		st.add_vertex(Vector3(cos(angle) * 0.1, 0, sin(angle) * 0.1))
		st.set_uv(Vector2(0.5 + 0.32 * cos(angle), 0.5 + 0.32 * sin(angle)))
		st.add_vertex(Vector3(cos(angle) * 0.32, 0.02, sin(angle) * 0.32))
		
		# Second triangle: center, outer petal, next inner petal
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(Vector3.ZERO)
		st.set_uv(Vector2(0.5 + 0.32 * cos(angle), 0.5 + 0.32 * sin(angle)))
		st.add_vertex(Vector3(cos(angle) * 0.32, 0.02, sin(angle) * 0.32))
		st.set_uv(Vector2(0.5 + 0.1 * cos(next_angle), 0.5 + 0.1 * sin(next_angle)))
		st.add_vertex(Vector3(cos(next_angle) * 0.1, 0, sin(next_angle) * 0.1))
	
	st.generate_normals()
	return st.commit()
	
func create_water_lily_mesh(index: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(10):
		var angle = (float(i) / 10.0) * TAU
		st.set_uv(Vector2(0.5,0.5)); st.add_vertex(Vector3.ZERO);
		st.set_uv(Vector2(0.5+0.15*cos(angle-0.1),0.5+0.15*sin(angle-0.1))); st.add_vertex(Vector3(cos(angle-0.1)*0.15,0,sin(angle-0.1)*0.15))
		st.set_uv(Vector2(0.5+0.5*cos(angle),0.5+0.5*sin(angle))); st.add_vertex(Vector3(cos(angle)*0.7,0.01,sin(angle)*0.7))
	st.generate_normals(); return st.commit()
