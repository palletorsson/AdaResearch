extends Node3D

# Configuration
@export var ride_radius: float = 3.0
@export var ride_speed: float = 1.0 # Radians per second
@export var arm_length: float = 0.75
@export var soft_body_radius: float = 0.25
@export_group("Obstacles")
@export var obstacle_radius_offset: float = 2.0
@export var obstacle_height: float = 3.0
@export var obstacle_y_pos: float = 1.5

var ride_hub: RigidBody3D

# Shaders
const SHADER_PINK_TARTAN = preload("res://commons/resourses/shaders/pinktartan.gdshader")
const SHADER_PEARLESCENT = preload("res://commons/resourses/shaders/pearlescent.gdshader")
const SHADER_FROSTED = preload("res://commons/resourses/shaders/frosted_glass.gdshader")
const SHADER_DISCO = preload("res://commons/resourses/shaders/discoLights.gdshader")

func _ready():
	setup_camera()
	setup_lighting()
	setup_ride()
	setup_obstacles()

func create_shader_material(shader: Shader, params: Dictionary = {}) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = shader
	for key in params:
		mat.set_shader_parameter(key, params[key])
	return mat

func setup_camera():
	var cam = Camera3D.new()
	cam.position = Vector3(0, 2.5, 6.25)
	cam.look_at(Vector3(0, 1.25, 0))
	add_child(cam)

func setup_lighting():
	var light = DirectionalLight3D.new()
	light.position = Vector3(2.5, 5, 2.5)
	light.look_at(Vector3.ZERO)
	light.shadow_enabled = true
	add_child(light)
	
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.environment = environment
	add_child(env)

func setup_ride():
	# Create the central hub that rotates
	ride_hub = RigidBody3D.new()
	ride_hub.name = "RideHub"
	ride_hub.position = Vector3(0, 3.75, 0) # High up
	ride_hub.freeze = true
	ride_hub.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	add_child(ride_hub)
	
	# Visual for the ring
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = ride_radius - 0.125
	ring_mesh.outer_radius = ride_radius + 0.125
	var ring_instance = MeshInstance3D.new()
	ring_instance.mesh = ring_mesh
	# Apply Disco Shader to Ring
	ring_instance.material_override = create_shader_material(SHADER_DISCO)
	ride_hub.add_child(ring_instance)
	
	# Create 4 arms
	for i in range(4):
		var angle = i * (PI / 2.0)
		create_arm(angle)

func create_arm(angle: float):
	var pos_on_ring = Vector3(cos(angle) * ride_radius, 0, sin(angle) * ride_radius)
	
	# Visual sphere
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	var sphere_vis = MeshInstance3D.new()
	sphere_vis.mesh = sphere_mesh
	sphere_vis.position = pos_on_ring
	sphere_vis.material_override = create_shader_material(SHADER_PEARLESCENT, {"base": Color(1.0, 0.2, 0.8), "shift": Color(0.2, 1.0, 1.0)})
	ride_hub.add_child(sphere_vis)
	
	# 2. First Link (RigidBody)
	var link1 = create_link(pos_on_ring - Vector3(0, 0.5, 0), Color.RED)
	link1.name = "Link1_%d" % int(rad_to_deg(angle))
	add_child(link1)
	
	# Joint 1: Hub -> Link1
	var joint1 = PinJoint3D.new()
	# Parent to hub so it rotates with it
	ride_hub.add_child(joint1)
	joint1.position = pos_on_ring # Local to hub
	joint1.node_a = ride_hub.get_path()
	joint1.node_b = link1.get_path()
	
	# 3. Second Link (RigidBody)
	var link2 = create_link(pos_on_ring - Vector3(0, 1.25, 0), Color.BLUE)
	link2.name = "Link2_%d" % int(rad_to_deg(angle))
	add_child(link2)
	
	# Joint 2: Link1 -> Link2
	var joint2 = PinJoint3D.new()
	# Parent to link1 so it moves with the chain
	link1.add_child(joint2)
	joint2.position = Vector3(0, -0.375, 0) # Local to link1
	joint2.node_a = link1.get_path()
	joint2.node_b = link2.get_path()
	
	# 4. SoftBody
	create_hanging_soft_body(link2)

func create_link(pos: Vector3, color: Color) -> RigidBody3D:
	var body = RigidBody3D.new()
	body.position = ride_hub.position + pos # Convert local offset to global
	body.mass = 5.0
	
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.075
	mesh.height = 0.75
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
	
	# Apply Pearlescent Shader to Links
	# Vary base color slightly based on input color
	var base = Color(1.0, 0.5, 0.5) if color == Color.RED else Color(0.5, 0.5, 1.0)
	var shift = Color(1.0, 1.0, 0.0) if color == Color.RED else Color(0.0, 1.0, 1.0)
	mesh_inst.material_override = create_shader_material(SHADER_PEARLESCENT, {"base": base, "shift": shift})
	
	body.add_child(mesh_inst)
	
	var shape = CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	(shape.shape as CapsuleShape3D).radius = 0.075
	(shape.shape as CapsuleShape3D).height = 0.75
	body.add_child(shape)
	
	return body

func create_hanging_soft_body(parent_body: RigidBody3D):
	var sb = SoftBody3D.new()
	
	# Create Mesh
	var mesh = SphereMesh.new()
	mesh.radius = soft_body_radius
	mesh.height = soft_body_radius * 2
	mesh.radial_segments = 16
	mesh.rings = 8
	sb.mesh = mesh
	
	# Parent to the rigid body but keep transform independent to avoid double-motion issues
	parent_body.add_child(sb)
	sb.top_level = true
	
	# Position at the bottom of the link (Link height is 0.75, so bottom is -0.375)
	# We need global position since it's top_level
	# The parent_body (link2) is at a certain position.
	# We want to be at parent_body.global_position + (rotation * local_offset)
	# But initially, rotation is identity.
	var local_offset = Vector3(0, -0.375 - soft_body_radius, 0)
	sb.global_position = parent_body.global_position + local_offset
	
	sb.total_mass = 2.0
	sb.linear_stiffness = 0.3
	sb.damping_coefficient = 0.05
	sb.simulation_precision = 5
	
	# Defer pinning to ensure nodes are ready
	call_deferred("_pin_soft_body", sb, parent_body)

func _pin_soft_body(sb: SoftBody3D, parent_body: RigidBody3D):
	if not is_instance_valid(sb) or not is_instance_valid(parent_body):
		return

	# Find top vertices (pin a cap, not just one point)
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(sb.mesh, 0)
	var pinned_indices = []
	var max_y = -INF
	
	# First pass: find max Y
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.y > max_y:
			max_y = v.y
			
	# Second pass: collect vertices near top
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.y > max_y - 0.05: # Pin top 5cm (scaled down from 20cm)
			pinned_indices.append(i)
	
	if not pinned_indices.is_empty():
		print("Pinning %d vertices of SoftBody to %s" % [pinned_indices.size(), parent_body.name])
		
		# Use absolute path to be safe
		var attachment_path = parent_body.get_path()
		
		for idx in pinned_indices:
			sb.set_point_pinned(idx, true, attachment_path)
		
		# Prevent collision between soft body and its anchor to avoid physics explosions
		sb.add_collision_exception_with(parent_body)
		
		# Visual material - Pink Tartan!
		sb.material_override = create_shader_material(SHADER_PINK_TARTAN)
	else:
		print("ERROR: Could not find top vertices for pinning!")

func setup_obstacles():
	var obstacle_ring = Node3D.new()
	obstacle_ring.name = "Obstacles"
	add_child(obstacle_ring)
	
	var count = 12
	var radius = ride_radius + obstacle_radius_offset
	
	for i in range(count):
		var angle = i * (TAU / count)
		# Position obstacles so their bottom is at y=0
		var pos = Vector3(cos(angle) * radius, obstacle_height / 2.0, sin(angle) * radius)
		
		var static_body = StaticBody3D.new()
		static_body.position = pos
		
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.25, obstacle_height, 0.25)
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = mesh
		# Apply Frosted Glass (or similar) to obstacles
		mesh_inst.material_override = create_shader_material(SHADER_FROSTED, {"albedo": Color(0.2, 1.0, 0.8, 0.5)})
		static_body.add_child(mesh_inst)
		
		var shape = CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		(shape.shape as BoxShape3D).size = Vector3(0.25, obstacle_height, 0.25)
		static_body.add_child(shape)
		
		obstacle_ring.add_child(static_body)

func _physics_process(delta):
	if ride_hub:
		ride_hub.rotation.y += ride_speed * delta
