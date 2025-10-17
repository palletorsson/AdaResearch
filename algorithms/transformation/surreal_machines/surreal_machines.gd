# surreal_machines.gd
# Surreal mechanical contraptions with joints and joyful soft body interactions
extends Node3D

@export var machine_complexity: int = 5
@export var animation_speed: float = 1.0
@export var physics_intensity: float = 1.0
@export var rainbow_mode: bool = true
@export var bouncy_factor: float = 1.5

var mechanical_parts: Array[RigidBody3D] = []
var joint_connections: Array[Joint3D] = []
var soft_bodies: Array[SoftBody3D] = []
var rainbow_materials: Array[Material] = []
var celebration_particles: Array[GPUParticles3D] = []

# Joyful rainbow shader for mechanical parts
const RAINBOW_MECHANICAL_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform float rainbow_speed : hint_range(0.1, 5.0) = 2.0;
uniform float metallic_base : hint_range(0.0, 1.0) = 0.7;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.2;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float pride_factor : hint_range(0.0, 2.0) = 1.0;

varying vec3 world_position;
varying float time_offset;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	time_offset = world_position.x + world_position.z;
}

void fragment() {
	// Rainbow color cycling
	float time_wave = TIME * rainbow_speed + time_offset;
	float hue = sin(time_wave) * 0.5 + 0.5;

	// Create pride flag inspired colors
	vec3 pride_colors[6];
	pride_colors[0] = vec3(1.0, 0.0, 0.0);   // Red
	pride_colors[1] = vec3(1.0, 0.5, 0.0);   // Orange
	pride_colors[2] = vec3(1.0, 1.0, 0.0);   // Yellow
	pride_colors[3] = vec3(0.0, 1.0, 0.0);   // Green
	pride_colors[4] = vec3(0.0, 0.5, 1.0);   // Blue
	pride_colors[5] = vec3(0.5, 0.0, 1.0);   // Purple

	// Interpolate between pride colors
	float color_index = hue * 6.0;
	int index1 = int(color_index) % 6;
	int index2 = (index1 + 1) % 6;
	float blend = fract(color_index);

	vec3 rainbow_color = mix(pride_colors[index1], pride_colors[index2], blend);
	rainbow_color = mix(vec3(0.8), rainbow_color, pride_factor);

	// Add sparkle effect
	float sparkle = sin(world_position.x * 10.0 + TIME * 3.0) *
					  sin(world_position.y * 8.0 + TIME * 2.0) *
					  sin(world_position.z * 12.0 + TIME * 4.0);
	sparkle = max(0.0, sparkle) * 0.3;

	ALBEDO = rainbow_color + sparkle;
	METALLIC = metallic_base;
	ROUGHNESS = roughness_base;
	EMISSION = rainbow_color * glow_intensity * (0.5 + sparkle);
}
"""

# Soft body celebration shader
const CELEBRATION_SOFTBODY_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx, depth_prepass_alpha;

uniform float joy_intensity : hint_range(0.0, 3.0) = 2.0;
uniform float bounce_glow : hint_range(0.0, 2.0) = 1.5;
uniform vec4 happy_color : source_color = vec4(1.0, 0.8, 0.9, 0.8);
uniform float transparency : hint_range(0.0, 1.0) = 0.3;
uniform float wobble_speed : hint_range(0.1, 5.0) = 3.0;

varying vec3 world_pos;
varying vec3 vertex_normal;
varying float deformation;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vertex_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Calculate deformation for bouncy glow
	deformation = length(VERTEX - vec3(0.0)) / 2.0;
}

void fragment() {
	// Happy wobbling colors
	float wobble = sin(TIME * wobble_speed + world_pos.x * 2.0) *
				   cos(TIME * wobble_speed * 0.7 + world_pos.y * 1.5) * 0.5 + 0.5;

	// Celebration color palette
	vec3 celebration_colors[4];
	celebration_colors[0] = vec3(1.0, 0.7, 0.8);  // Pink
	celebration_colors[1] = vec3(0.8, 1.0, 0.7);  // Light Green
	celebration_colors[2] = vec3(0.7, 0.8, 1.0);  // Light Blue
	celebration_colors[3] = vec3(1.0, 0.9, 0.7);  // Warm Yellow

	int color_index = int(wobble * 4.0) % 4;
	vec3 base_color = celebration_colors[color_index];

	// Bouncy glow based on deformation
	float bounce_factor = sin(deformation * 10.0 + TIME * 5.0) * 0.5 + 0.5;
	vec3 glow_color = base_color * bounce_glow * bounce_factor;

	ALBEDO = mix(happy_color.rgb, base_color, joy_intensity * wobble);
	ALPHA = mix(transparency, 1.0, bounce_factor * 0.5);
	EMISSION = glow_color * joy_intensity;
	METALLIC = 0.0;
	ROUGHNESS = 0.8;
}
"""

func _ready():
	setup_joyful_environment()
	create_surreal_machines()
	create_celebration_soft_bodies()
	create_particle_celebrations()
	start_machine_animations()

func setup_joyful_environment():
	# Create vibrant, welcoming environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()

	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.8, 0.6, 1.0)     # Soft purple
	sky_mat.sky_horizon_color = Color(1.0, 0.8, 0.9)   # Pink horizon
	sky_mat.ground_bottom_color = Color(0.9, 1.0, 0.8) # Light green ground
	sky_mat.ground_horizon_color = Color(1.0, 0.9, 0.8) # Warm ground

	# Cheerful lighting
	env.ambient_light_energy = 0.6
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

	# Bloom for magical glow
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.2
	env.glow_bloom = 0.2

	var camera = get_viewport().get_camera_3d()
	if camera:
		camera.environment = env

	# Warm celebration lighting
	var celebration_light = DirectionalLight3D.new()
	celebration_light.position = Vector3(8, 12, 6)
	celebration_light.look_at_from_position(celebration_light.position, Vector3.ZERO, Vector3.UP)
	celebration_light.light_energy = 1.0
	celebration_light.light_color = Color(1.0, 0.9, 0.8)
	celebration_light.shadow_enabled = true
	add_child(celebration_light)

func create_surreal_machines():
	# Create various whimsical mechanical contraptions
	create_rainbow_pendulum_machine()
	create_bouncy_gear_assembly()
	create_floating_joint_sculpture()
	create_pride_powered_engine()
	create_celebration_conveyor()

func create_rainbow_pendulum_machine():
	# Central pendulum with multiple connected parts
	var base = create_mechanical_base(Vector3.ZERO, "RainbowPendulumBase")

	# Create pendulum chain
	var previous_body = base
	for i in range(5):
		var pendulum_part = RigidBody3D.new()
		pendulum_part.name = "PendulumPart_" + str(i)
		pendulum_part.position = Vector3(0, -1.5 * (i + 1), 0)

		# Colorful pendulum segment
		var capsule_mesh = CapsuleMesh.new()
		capsule_mesh.height = 1.0
		capsule_mesh.radius = 0.15

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = capsule_mesh
		pendulum_part.add_child(mesh_instance)

		# Rainbow material
		var material = create_rainbow_material(i)
		mesh_instance.set_surface_override_material(0, material)

		# Physics shape
		var collision_shape = CollisionShape3D.new()
		var capsule_shape = CapsuleShape3D.new()
		capsule_shape.height = 1.0
		capsule_shape.radius = 0.15
		collision_shape.shape = capsule_shape
		pendulum_part.add_child(collision_shape)

		# Connect with pin joint
		var pin_joint = PinJoint3D.new()
		pin_joint.node_a = get_path_to(previous_body)
		pin_joint.node_b = get_path_to(pendulum_part)
		pin_joint.position = Vector3(0, -0.5, 0) if i == 0 else Vector3(0, 0.5, 0)

		add_child(pendulum_part)
		add_child(pin_joint)

		mechanical_parts.append(pendulum_part)
		joint_connections.append(pin_joint)
		previous_body = pendulum_part

	# Add celebratory weight at the end
	var celebration_weight = create_celebration_sphere(Vector3(0, -8, 0))
	var final_joint = PinJoint3D.new()
	final_joint.node_a = get_path_to(previous_body)
	final_joint.node_b = get_path_to(celebration_weight)
	add_child(final_joint)
	joint_connections.append(final_joint)

func create_bouncy_gear_assembly():
	# Interconnected rotating gears with spring joints
	var gear_positions = [
		Vector3(4, 2, 0),
		Vector3(6, 2, 1),
		Vector3(8, 3, 0),
		Vector3(6, 4, -1)
	]

	var gears = []
	for i in range(gear_positions.size()):
		var gear = RigidBody3D.new()
		gear.name = "BouncyGear_" + str(i)
		gear.position = gear_positions[i]

		# Gear mesh (using cylinder as gear approximation)
		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.height = 0.3
		cylinder_mesh.top_radius = 0.8
		cylinder_mesh.bottom_radius = 0.8
		cylinder_mesh.radial_segments = 12  # Gear teeth approximation

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = cylinder_mesh
		gear.add_child(mesh_instance)

		# Happy gear material
		var material = create_rainbow_material(i + 10)
		mesh_instance.set_surface_override_material(0, material)

		# Physics
		var collision_shape = CollisionShape3D.new()
		var cylinder_shape = CylinderShape3D.new()
		cylinder_shape.height = 0.3
		cylinder_shape.radius = 0.8
		collision_shape.shape = cylinder_shape
		gear.add_child(collision_shape)

		add_child(gear)
		mechanical_parts.append(gear)
		gears.append(gear)

		# Connect gears with generic 6DOF joints for complex motion
		if i > 0:
			var gear_joint = Generic6DOFJoint3D.new()
			gear_joint.node_a = get_path_to(gears[i-1])
			gear_joint.node_b = get_path_to(gear)

			# Configure for bouncy rotation
			gear_joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, 50.0)
			gear_joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, 5.0)
			gear_joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, true)

			add_child(gear_joint)
			joint_connections.append(gear_joint)

func create_floating_joint_sculpture():
	# Artistic floating sculpture with various joint types
	var sculpture_parts = []
	var center = Vector3(-4, 3, 0)

	# Create central sphere
	var central_sphere = create_celebration_sphere(center)
	sculpture_parts.append(central_sphere)

	# Create orbiting elements connected by different joint types
	for i in range(6):
		var angle = (float(i) / 6.0) * PI * 2.0
		var orbit_radius = 2.0
		var orbit_pos = center + Vector3(cos(angle) * orbit_radius, sin(angle) * 0.5, sin(angle) * orbit_radius)

		var orbiter = RigidBody3D.new()
		orbiter.name = "SculptureOrbiter_" + str(i)
		orbiter.position = orbit_pos

		# Unique shape for each orbiter
		var shapes = [BoxMesh.new(), SphereMesh.new(), CylinderMesh.new(), TorusMesh.new()]
		var mesh = shapes[i % shapes.size()]
		if mesh is BoxMesh:
			(mesh as BoxMesh).size = Vector3(0.5, 0.8, 0.5)
		elif mesh is SphereMesh:
			(mesh as SphereMesh).radius = 0.4
		elif mesh is CylinderMesh:
			(mesh as CylinderMesh).height = 0.8
			(mesh as CylinderMesh).top_radius = 0.3
		elif mesh is TorusMesh:
			(mesh as TorusMesh).inner_radius = 0.2
			(mesh as TorusMesh).outer_radius = 0.4

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		orbiter.add_child(mesh_instance)

		# Joyful material
		var material = create_rainbow_material(i + 20)
		mesh_instance.set_surface_override_material(0, material)

		# Physics collision
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = mesh.create_trimesh_shape()
		orbiter.add_child(collision_shape)

		add_child(orbiter)
		mechanical_parts.append(orbiter)
		sculpture_parts.append(orbiter)

		# Different joint types for variety
		var joint_type = i % 4
		match joint_type:
			0:  # Hinge joint for swinging motion
				var hinge = HingeJoint3D.new()
				hinge.node_a = get_path_to(central_sphere)
				hinge.node_b = get_path_to(orbiter)
				hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, randf_range(1.0, 3.0))
				hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
				add_child(hinge)
				joint_connections.append(hinge)

			1:  # Slider joint for back-and-forth motion
				var slider = SliderJoint3D.new()
				slider.node_a = get_path_to(central_sphere)
				slider.node_b = get_path_to(orbiter)
				slider.set_param(SliderJoint3D.PARAM_LINEAR_MOTION_SOFTNESS, 0.8)
				slider.set_param(SliderJoint3D.PARAM_LINEAR_MOTION_DAMPING, 0.5)
				add_child(slider)
				joint_connections.append(slider)

			2:  # Cone twist for wobbly motion
				var cone_twist = ConeTwistJoint3D.new()
				cone_twist.node_a = get_path_to(central_sphere)
				cone_twist.node_b = get_path_to(orbiter)
				cone_twist.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, PI * 0.3)
				cone_twist.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, PI * 0.5)
				add_child(cone_twist)
				joint_connections.append(cone_twist)

			3:  # Pin joint for free rotation
				var pin = PinJoint3D.new()
				pin.node_a = get_path_to(central_sphere)
				pin.node_b = get_path_to(orbiter)
				add_child(pin)
				joint_connections.append(pin)

func create_pride_powered_engine():
	# Engine with pistons and connecting rods - pride themed
	var engine_base = create_mechanical_base(Vector3(0, 0, -5), "PrideEngine")

	# Create pistons
	for i in range(3):
		var piston_x = (i - 1) * 1.5

		# Piston cylinder
		var cylinder = RigidBody3D.new()
		cylinder.name = "PridePiston_" + str(i)
		cylinder.position = Vector3(piston_x, 1, -5)
		cylinder.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.height = 2.0
		cylinder_mesh.top_radius = 0.3
		cylinder_mesh.bottom_radius = 0.3

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = cylinder_mesh
		cylinder.add_child(mesh_instance)

		# Pride flag colors for pistons
		var pride_colors = [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.BLUE, Color.PURPLE]
		var material = StandardMaterial3D.new()
		material.albedo_color = pride_colors[i % pride_colors.size()]
		material.metallic = 0.6
		material.roughness = 0.3
		material.emission = pride_colors[i % pride_colors.size()] * 0.3
		mesh_instance.set_surface_override_material(0, material)

		var collision_shape = CollisionShape3D.new()
		var cylinder_shape = CylinderShape3D.new()
		cylinder_shape.height = 2.0
		cylinder_shape.radius = 0.3
		collision_shape.shape = cylinder_shape
		cylinder.add_child(collision_shape)

		add_child(cylinder)
		mechanical_parts.append(cylinder)

		# Piston head (moving part)
		var piston_head = RigidBody3D.new()
		piston_head.name = "PistonHead_" + str(i)
		piston_head.position = Vector3(piston_x, 2, -5)

		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.5, 0.2, 0.5)

		var head_mesh_instance = MeshInstance3D.new()
		head_mesh_instance.mesh = box_mesh
		piston_head.add_child(head_mesh_instance)

		var head_material = create_rainbow_material(i + 30)
		head_mesh_instance.set_surface_override_material(0, head_material)

		var head_collision = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(0.5, 0.2, 0.5)
		head_collision.shape = box_shape
		piston_head.add_child(head_collision)

		add_child(piston_head)
		mechanical_parts.append(piston_head)

		# Connect piston head with slider joint
		var slider_joint = SliderJoint3D.new()
		slider_joint.node_a = get_path_to(cylinder)
		slider_joint.node_b = get_path_to(piston_head)
		slider_joint.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 1.0)
		slider_joint.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, -1.0)
		slider_joint.set_param(SliderJoint3D.PARAM_LINEAR_MOTION_SOFTNESS, 0.3)
		add_child(slider_joint)
		joint_connections.append(slider_joint)

func create_celebration_conveyor():
	# Moving conveyor belt carrying celebration objects
	var conveyor_segments = []
	var conveyor_start = Vector3(-8, 1, 3)

	# Create conveyor belt segments
	for i in range(8):
		var segment = RigidBody3D.new()
		segment.name = "ConveyorSegment_" + str(i)
		segment.position = conveyor_start + Vector3(i * 1.2, sin(i * 0.5) * 0.2, 0)

		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(1.0, 0.1, 0.8)

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = box_mesh
		segment.add_child(mesh_instance)

		# Moving rainbow material
		var material = create_rainbow_material(i + 40)
		mesh_instance.set_surface_override_material(0, material)

		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(1.0, 0.1, 0.8)
		collision_shape.shape = box_shape
		segment.add_child(collision_shape)

		add_child(segment)
		mechanical_parts.append(segment)
		conveyor_segments.append(segment)

		# Connect segments with hinge joints
		if i > 0:
			var conveyor_joint = HingeJoint3D.new()
			conveyor_joint.node_a = get_path_to(conveyor_segments[i-1])
			conveyor_joint.node_b = get_path_to(segment)
			add_child(conveyor_joint)
			joint_connections.append(conveyor_joint)

func create_celebration_soft_bodies():
	# Create bouncy, joyful soft body objects
	create_happy_bouncing_blobs()
	create_pride_flag_cloth()
	create_celebration_balloons()

func create_happy_bouncing_blobs():
	# Bouncy soft body blobs that celebrate
	var blob_positions = [
		Vector3(2, 5, 2),
		Vector3(-2, 6, 3),
		Vector3(4, 4, -2),
		Vector3(-3, 5, -1)
	]

	for i in range(blob_positions.size()):
		var soft_blob = SoftBody3D.new()
		soft_blob.name = "HappyBlob_" + str(i)
		soft_blob.position = blob_positions[i]

		# Create blob mesh
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.8
		sphere_mesh.radial_segments = 16
		sphere_mesh.rings = 12

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = sphere_mesh
		soft_blob.add_child(mesh_instance)

		# Celebration soft body material
		var material = ShaderMaterial.new()
		var shader = Shader.new()
		shader.code = CELEBRATION_SOFTBODY_SHADER
		material.shader = shader
		material.set_shader_parameter("joy_intensity", 2.0)
		material.set_shader_parameter("happy_color", Color(1.0, 0.8, 0.9, 0.8))
		material.set_shader_parameter("bounce_glow", 1.8)

		mesh_instance.set_surface_override_material(0, material)

		# Configure soft body physics
		soft_blob.collision_layer = 1
		soft_blob.collision_mask = 1
		soft_blob.simulation_precision = 8
		soft_blob.total_mass = 2.0
		soft_blob.linear_stiffness = 0.8
		soft_blob.pressure_coefficient = 100.0
		soft_blob.damping_coefficient = 0.1
		soft_blob.drag_coefficient = 0.05

		add_child(soft_blob)
		soft_bodies.append(soft_blob)

func create_pride_flag_cloth():
	# Soft body pride flag that waves in celebration
	var pride_flag = SoftBody3D.new()
	pride_flag.name = "PrideFlagCloth"
	pride_flag.position = Vector3(0, 8, -8)

	# Create flag mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(4.0, 2.4)  # Pride flag proportions
	plane_mesh.subdivide_width = 20
	plane_mesh.subdivide_depth = 12

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = plane_mesh
	pride_flag.add_child(mesh_instance)

	# Pride flag material with horizontal stripes
	var pride_material = StandardMaterial3D.new()
	# Create a simple gradient approximation
	pride_material.albedo_color = Color(1.0, 0.5, 0.7)  # Pink average
	pride_material.emission = Color(0.3, 0.1, 0.2)
	pride_material.emission_energy = 0.8
	pride_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pride_material.albedo_color.a = 0.9

	mesh_instance.set_surface_override_material(0, pride_material)

	# Configure as cloth
	pride_flag.collision_layer = 1
	pride_flag.collision_mask = 1
	pride_flag.simulation_precision = 10
	pride_flag.total_mass = 1.0
	pride_flag.linear_stiffness = 0.6
	pride_flag.pressure_coefficient = 0.0  # No volume preservation for cloth
	pride_flag.damping_coefficient = 0.3
	pride_flag.drag_coefficient = 0.2  # More air resistance

	add_child(pride_flag)
	soft_bodies.append(pride_flag)

func create_celebration_balloons():
	# Bouncy soft body balloons
	var balloon_colors = [
		Color.HOT_PINK,
		Color.CYAN,
		Color.YELLOW,
		Color.LIME_GREEN,
		Color.ORANGE,
		Color.PURPLE
	]

	for i in range(balloon_colors.size()):
		var balloon = SoftBody3D.new()
		balloon.name = "CelebrationBalloon_" + str(i)

		var angle = (float(i) / float(balloon_colors.size())) * PI * 2.0
		balloon.position = Vector3(cos(angle) * 6.0, 7.0, sin(angle) * 6.0)

		# Balloon mesh (elongated sphere)
		var balloon_mesh = SphereMesh.new()
		balloon_mesh.radius = 0.6
		balloon_mesh.height = 1.2  # Taller for balloon shape
		balloon_mesh.radial_segments = 12
		balloon_mesh.rings = 16

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = balloon_mesh
		balloon.add_child(mesh_instance)

		# Bright balloon material
		var material = StandardMaterial3D.new()
		material.albedo_color = balloon_colors[i]
		material.metallic = 0.0
		material.roughness = 0.1
		material.emission = balloon_colors[i] * 0.4
		material.emission_energy = 1.0

		mesh_instance.set_surface_override_material(0, material)

		# Balloon physics - very bouncy and light
		balloon.collision_layer = 1
		balloon.collision_mask = 1
		balloon.simulation_precision = 6
		balloon.total_mass = 0.3  # Very light like real balloons
		balloon.linear_stiffness = 0.4
		balloon.pressure_coefficient = 200.0  # High pressure for balloon shape
		balloon.damping_coefficient = 0.05
		balloon.drag_coefficient = 0.1

		add_child(balloon)
		soft_bodies.append(balloon)

		# Add balloon string (just visual)
		create_balloon_string(balloon)

func create_balloon_string(balloon: SoftBody3D):
	# Create a visual string for the balloon
	var string = RigidBody3D.new()
	string.name = balloon.name + "_String"
	string.position = balloon.position + Vector3(0, -1.5, 0)
	string.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 2.0
	cylinder_mesh.top_radius = 0.01
	cylinder_mesh.bottom_radius = 0.01

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = cylinder_mesh
	string.add_child(mesh_instance)

	var string_material = StandardMaterial3D.new()
	string_material.albedo_color = Color.WHITE
	mesh_instance.set_surface_override_material(0, string_material)

	add_child(string)

func create_particle_celebrations():
	# Create joyful particle effects throughout the scene
	create_rainbow_fountain_particles()
	create_confetti_bursts()
	create_sparkle_trails()

func create_rainbow_fountain_particles():
	var fountain = GPUParticles3D.new()
	fountain.name = "RainbowFountain"
	fountain.position = Vector3(0, 0, 0)
	fountain.emitting = true
	fountain.amount = 1000
	fountain.lifetime = 4.0
	fountain.visibility_aabb = AABB(Vector3(-15, -2, -15), Vector3(30, 25, 30))

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.5

	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 3.0
	material.initial_velocity_max = 8.0
	material.spread = 30.0

	material.gravity = Vector3(0, -2.0, 0)
	material.scale_min = 0.1
	material.scale_max = 0.3

	# Rainbow colors over lifetime
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.RED)
	gradient.add_point(0.17, Color.ORANGE)
	gradient.add_point(0.33, Color.YELLOW)
	gradient.add_point(0.5, Color.GREEN)
	gradient.add_point(0.67, Color.BLUE)
	gradient.add_point(0.83, Color.PURPLE)
	gradient.add_point(1.0, Color.HOT_PINK)
	material.color_ramp = gradient

	fountain.process_material = material
	fountain.draw_pass_1 = QuadMesh.new()

	add_child(fountain)
	celebration_particles.append(fountain)

func create_confetti_bursts():
	# Multiple confetti burst locations
	var burst_positions = [
		Vector3(5, 8, 5),
		Vector3(-5, 8, -5),
		Vector3(8, 6, -3),
		Vector3(-7, 7, 4)
	]

	for i in range(burst_positions.size()):
		var confetti = GPUParticles3D.new()
		confetti.name = "ConfettiBurst_" + str(i)
		confetti.position = burst_positions[i]
		confetti.emitting = true
		confetti.amount = 500
		confetti.lifetime = 6.0

		var material = ParticleProcessMaterial.new()
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		material.emission_sphere_radius = 0.2

		# Explosive burst pattern
		material.direction = Vector3(0, 0, 1)
		material.spread = 180.0  # Full sphere
		material.initial_velocity_min = 5.0
		material.initial_velocity_max = 12.0

		material.gravity = Vector3(0, -1.0, 0)
		material.damping_min = 1.0
		material.damping_max = 3.0

		# Confetti colors
		var confetti_gradient = Gradient.new()
		confetti_gradient.add_point(0.0, Color.YELLOW)
		confetti_gradient.add_point(0.25, Color.HOT_PINK)
		confetti_gradient.add_point(0.5, Color.CYAN)
		confetti_gradient.add_point(0.75, Color.LIME_GREEN)
		confetti_gradient.add_point(1.0, Color.PURPLE)
		material.color_ramp = confetti_gradient

		confetti.process_material = material
		confetti.draw_pass_1 = QuadMesh.new()

		add_child(confetti)
		celebration_particles.append(confetti)

func create_sparkle_trails():
	# Sparkle trails that follow moving objects
	for mechanical_part in mechanical_parts:
		if randf() < 0.3:  # Only some parts get sparkles
			var sparkles = GPUParticles3D.new()
			sparkles.name = mechanical_part.name + "_Sparkles"
			sparkles.emitting = true
			sparkles.amount = 200
			sparkles.lifetime = 2.0

			var material = ParticleProcessMaterial.new()
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			material.emission_sphere_radius = 0.1

			material.direction = Vector3(0, 1, 0)
			material.spread = 45.0
			material.initial_velocity_min = 0.5
			material.initial_velocity_max = 2.0

			material.scale_min = 0.05
			material.scale_max = 0.15

			# Sparkle colors
			var sparkle_gradient = Gradient.new()
			sparkle_gradient.add_point(0.0, Color.WHITE)
			sparkle_gradient.add_point(0.3, Color.YELLOW)
			sparkle_gradient.add_point(0.7, Color.CYAN)
			sparkle_gradient.add_point(1.0, Color.TRANSPARENT)
			material.color_ramp = sparkle_gradient

			sparkles.process_material = material
			sparkles.draw_pass_1 = QuadMesh.new()

			mechanical_part.add_child(sparkles)
			celebration_particles.append(sparkles)

func create_mechanical_base(position: Vector3, name: String) -> RigidBody3D:
	var base = RigidBody3D.new()
	base.name = name
	base.position = position
	base.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC  # Static base

	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 0.5
	cylinder_mesh.top_radius = 1.2
	cylinder_mesh.bottom_radius = 1.5

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = cylinder_mesh
	base.add_child(mesh_instance)

	var material = create_rainbow_material(100)
	mesh_instance.set_surface_override_material(0, material)

	var collision_shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.height = 0.5
	cylinder_shape.radius = 1.5
	collision_shape.shape = cylinder_shape
	base.add_child(collision_shape)

	add_child(base)
	mechanical_parts.append(base)

	return base

func create_celebration_sphere(position: Vector3) -> RigidBody3D:
	var sphere = RigidBody3D.new()
	sphere.name = "CelebrationSphere"
	sphere.position = position

	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.6
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 12

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	sphere.add_child(mesh_instance)

	var material = create_rainbow_material(200)
	mesh_instance.set_surface_override_material(0, material)

	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.6
	collision_shape.shape = sphere_shape
	sphere.add_child(collision_shape)

	add_child(sphere)
	mechanical_parts.append(sphere)

	return sphere

func create_rainbow_material(seed: int) -> ShaderMaterial:
	var material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = RAINBOW_MECHANICAL_SHADER
	material.shader = shader

	# Vary parameters based on seed for uniqueness
	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	material.set_shader_parameter("rainbow_speed", rng.randf_range(1.0, 3.0))
	material.set_shader_parameter("metallic_base", rng.randf_range(0.5, 0.9))
	material.set_shader_parameter("roughness_base", rng.randf_range(0.1, 0.4))
	material.set_shader_parameter("glow_intensity", rng.randf_range(1.0, 2.5))
	material.set_shader_parameter("pride_factor", rng.randf_range(0.8, 2.0))

	rainbow_materials.append(material)
	return material

func start_machine_animations():
	# Start various animations for the mechanical parts
	animate_machine_rotations()
	animate_piston_movements()
	animate_conveyor_motion()
	animate_celebration_bounces()

func animate_machine_rotations():
	# Rotate various mechanical parts
	for i in range(mechanical_parts.size()):
		var part = mechanical_parts[i]
		if part.name.begins_with("BouncyGear") or part.name.begins_with("SculptureOrbiter"):
			var rotation_tween = create_tween()
			rotation_tween.set_loops()

			var rotation_speed = randf_range(1.0, 3.0) / animation_speed
			var rotation_axis = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()

			rotation_tween.tween_method(
				func(angle): part.rotation = rotation_axis * angle,
				0.0, PI * 2.0, rotation_speed
			)

func animate_piston_movements():
	# Animate piston movements
	for part in mechanical_parts:
		if part.name.begins_with("PistonHead"):
			var piston_tween = create_tween()
			piston_tween.set_loops()

			var original_pos = part.position
			var stroke_distance = 0.8
			var piston_speed = randf_range(1.0, 2.0) / animation_speed

			piston_tween.tween_method(
				func(offset): part.position = original_pos + Vector3(0, sin(offset) * stroke_distance, 0),
				0.0, PI * 2.0, piston_speed
			)

func animate_conveyor_motion():
	# Animate conveyor belt movement
	var conveyor_tween = create_tween()
	conveyor_tween.set_loops()

	for part in mechanical_parts:
		if part.name.begins_with("ConveyorSegment"):
			var original_rot = part.rotation
			conveyor_tween.tween_method(
				func(angle): part.rotation = original_rot + Vector3(angle * 0.1, 0, 0),
				0.0, PI * 2.0, 3.0 / animation_speed
			)

func animate_celebration_bounces():
	# Make soft bodies bounce periodically for extra joy
	for soft_body in soft_bodies:
		if soft_body.name.begins_with("HappyBlob") or soft_body.name.begins_with("CelebrationBalloon"):
			var bounce_force = Vector3(0, randf_range(5.0, 15.0) * bouncy_factor, 0)
			var bounce_interval = randf_range(2.0, 5.0)

			# Create a timer for the delay instead of tween_delay
			var delay_timer = Timer.new()
			delay_timer.wait_time = bounce_interval
			delay_timer.one_shot = true
			delay_timer.timeout.connect(func(): apply_bounce_force(soft_body, bounce_force))
			add_child(delay_timer)
			delay_timer.start()

func apply_bounce_force(soft_body: SoftBody3D, force: Vector3):
	# Apply upward force to soft bodies for bouncing
	if soft_body and is_instance_valid(soft_body):
		# Note: SoftBody3D doesn't have direct force application in Godot 4
		# This is a conceptual implementation - actual soft body physics
		# would require different approach in real implementation
		var current_pos = soft_body.position
		var bounce_tween = create_tween()
		bounce_tween.tween_method(
			func(height): soft_body.position = Vector3(current_pos.x, current_pos.y + height, current_pos.z),
			0.0, force.y * 0.1, 0.3
		)
		bounce_tween.tween_method(
			func(height): soft_body.position = Vector3(current_pos.x, current_pos.y + height, current_pos.z),
			force.y * 0.1, 0.0, 0.7
		)

func _process(delta):
	update_celebration_effects(delta)
	update_physics_interactions(delta)

func update_celebration_effects(delta):
	# Pulse rainbow effects
	var time_factor = sin(Time.get_time_dict_from_system()["second"] * 2.0) * 0.2 + 1.0

	for material in rainbow_materials:
		# Check if the shader parameter exists by trying to get it
		var base_glow = material.get_shader_parameter("glow_intensity")
		if base_glow != null:
			material.set_shader_parameter("glow_intensity", base_glow * time_factor)

func update_physics_interactions(delta):
	# Apply gentle forces to create organic movement
	for i in range(mechanical_parts.size()):
		var part = mechanical_parts[i]
		if part.freeze_mode != RigidBody3D.FREEZE_MODE_KINEMATIC:
			# Add subtle random forces for organic feeling
			if randf() < 0.01:  # 1% chance per frame
				var random_force = Vector3(
					randf_range(-1, 1),
					randf_range(0, 2),
					randf_range(-1, 1)
				) * physics_intensity * 2.0
				part.apply_central_impulse(random_force)

# Public control functions
func set_animation_speed(speed: float):
	animation_speed = speed

func set_physics_intensity(intensity: float):
	physics_intensity = intensity

func toggle_rainbow_mode(enabled: bool):
	rainbow_mode = enabled
	# Update all materials
	for material in rainbow_materials:
		# Check if the shader parameter exists by trying to get it
		var pride_factor = material.get_shader_parameter("pride_factor")
		if pride_factor != null:
			material.set_shader_parameter("pride_factor", 2.0 if enabled else 0.5)

func set_bouncy_factor(factor: float):
	bouncy_factor = factor

func trigger_celebration_burst():
	# Trigger simultaneous effects for maximum joy
	for particle_system in celebration_particles:
		particle_system.restart()

	# Apply random forces to all physics objects
	for part in mechanical_parts:
		if part.freeze_mode != RigidBody3D.FREEZE_MODE_KINEMATIC:
			var burst_force = Vector3(
				randf_range(-10, 10),
				randf_range(5, 20),
				randf_range(-10, 10)
			)
			part.apply_central_impulse(burst_force)

	# Bounce all soft bodies
	for soft_body in soft_bodies:
		var bounce_force = Vector3(0, randf_range(10, 25), 0)
		apply_bounce_force(soft_body, bounce_force)

func create_custom_machine_part(position: Vector3, part_type: String = "celebration"):
	# Add new machine parts dynamically
	var new_part = RigidBody3D.new()
	new_part.position = position
	new_part.name = "CustomPart_" + part_type

	# Different shapes based on type
	var mesh = SphereMesh.new() if part_type == "celebration" else BoxMesh.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	new_part.add_child(mesh_instance)

	# Rainbow material
	var material = create_rainbow_material(randi())
	mesh_instance.set_surface_override_material(0, material)

	# Physics
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_convex_shape()
	new_part.add_child(collision_shape)

	add_child(new_part)
	mechanical_parts.append(new_part)

	return new_part

func add_joy_particles_to_object(object: Node3D):
	# Add celebration particles to any object
	var joy_particles = GPUParticles3D.new()
	joy_particles.emitting = true
	joy_particles.amount = 100
	joy_particles.lifetime = 2.0

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.2
	material.direction = Vector3(0, 1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 3.0

	# Happy colors
	var joy_gradient = Gradient.new()
	joy_gradient.add_point(0.0, Color.HOT_PINK)
	joy_gradient.add_point(0.5, Color.YELLOW)
	joy_gradient.add_point(1.0, Color.CYAN)
	material.color_ramp = joy_gradient

	joy_particles.process_material = material
	joy_particles.draw_pass_1 = QuadMesh.new()

	object.add_child(joy_particles)
	celebration_particles.append(joy_particles)
