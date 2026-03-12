extends Node3D

@export var trampoline_size: Vector2 = Vector2(8, 8)
@export var trampoline_height: float = 3.0

func _ready():
	setup_scene()
	setup_trampoline()
	
	# Spawn a test object after a delay
	await get_tree().create_timer(2.0).timeout
	spawn_heavy_object()

func setup_scene():
	var cam = Camera3D.new()
	cam.position = Vector3(0, 6, 12)
	cam.look_at(Vector3(0, 2, 0))
	add_child(cam)
	
	var light = DirectionalLight3D.new()
	light.position = Vector3(10, 20, 10)
	light.look_at(Vector3.ZERO)
	light.shadow_enabled = true
	add_child(light)
	
	# Ground
	var ground = StaticBody3D.new()
	var gm = BoxMesh.new()
	gm.size = Vector3(20, 1, 20)
	var mi = MeshInstance3D.new()
	mi.mesh = gm
	ground.add_child(mi)
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	(col.shape as BoxShape3D).size = gm.size
	ground.add_child(col)
	ground.position.y = -0.5
	add_child(ground)
	
	# Frame for trampoline
	var frame = StaticBody3D.new()
	frame.name = "Frame"
	frame.position = Vector3(0, trampoline_height, 0)
	
	# 4 Posts
	var post_mesh = CylinderMesh.new()
	post_mesh.height = trampoline_height
	post_mesh.top_radius = 0.1
	post_mesh.bottom_radius = 0.1
	
	var half_x = trampoline_size.x / 2.0
	var half_z = trampoline_size.y / 2.0
	
	for x in [-half_x, half_x]:
		for z in [-half_z, half_z]:
			var post = MeshInstance3D.new()
			post.mesh = post_mesh
			post.position = Vector3(x, -trampoline_height/2.0, z)
			frame.add_child(post)
			
	add_child(frame)

func setup_trampoline():
	var sb = SoftBody3D.new()
	
	var mesh = PlaneMesh.new()
	mesh.size = trampoline_size
	mesh.subdivide_width = 10
	mesh.subdivide_depth = 10
	sb.mesh = mesh
	
	sb.position = Vector3(0, trampoline_height, 0)
	
	sb.total_mass = 2.0
	sb.linear_stiffness = 0.8 # Stiff
	sb.damping_coefficient = 0.01 # Low damping for bounce
	sb.simulation_precision = 10
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 1.0, 0.5) * 0.5 # Neon grid look
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sb.material_override = mat
	
	# Collision
	sb.collision_layer = 1
	sb.collision_mask = 1 | 524288
	
	add_child(sb)
	
	# Pin the perimeter
	call_deferred("_pin_perimeter", sb)

func _pin_perimeter(sb: SoftBody3D):
	if not is_instance_valid(sb): return
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(sb.mesh, 0)
	
	var half_x = trampoline_size.x / 2.0
	var half_z = trampoline_size.y / 2.0
	var threshold = 0.1
	
	var pinned_indices = []
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		# Check if on edge
		if abs(v.x - half_x) < threshold or abs(v.x + half_x) < threshold or \
		   abs(v.z - half_z) < threshold or abs(v.z + half_z) < threshold:
			pinned_indices.append(i)
			
	# We pin to world (empty path) so it stays fixed in space at its initial position
	for idx in pinned_indices:
		sb.set_point_pinned(idx, true, NodePath())

func spawn_heavy_object():
	var rb = RigidBody3D.new()
	rb.position = Vector3(0, trampoline_height + 5, 0)
	rb.mass = 10.0
	
	var mesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = StandardMaterial3D.new()
	mi.material_override.albedo_color = Color.RED
	rb.add_child(mi)
	
	var col = CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	(col.shape as SphereShape3D).radius = 1.0
	rb.add_child(col)
	
	add_child(rb)
