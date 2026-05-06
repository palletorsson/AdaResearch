extends Node3D

# Configuration
# Configuration
@export var grid_spacing: Vector2 = Vector2(5.0, 5.0)
@export var grid_width: int = 6
@export_enum("All", "Part 1", "Part 2", "Part 3") var gallery_part: int = 0

# Resources
const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")
const SPHERE_SCENE = preload("res://commons/primitives/sphere/sphere.tscn")
const CAPSULE_SCENE = preload("res://commons/primitives/capsule/capsule.tscn")
const PRISM_SCENE = preload("res://commons/primitives/prismes/prism_block.tscn")

var active_soft_bodies: Array[Dictionary] = []

func _ready() -> void:
	create_gallery()

func _process(delta: float) -> void:
	for item in active_soft_bodies:
		var sb = item["node"]
		var label = item["label"]
		
		if is_instance_valid(sb) and is_instance_valid(label):
			# Try to follow the soft body. 
			# Since SoftBody3D node position might not update with simulation, we might need to track a point.
			# However, for simple falling, the node position usually stays at start.
			# Let's try to get the center of the AABB in global space if possible, or just use point 0.
			
			# A simple approximation: Use point 0
			# Note: get_point_global_position might not be available in all versions, checking...
			# If not available, we might need another trick. But let's assume standard Godot 4.
			# Actually, let's just use the node position + physics interpolation if it works.
			# If the soft body falls, the node origin DOES NOT move in many setups.
			# We need to track the vertices.
			
			# Let's try to get the first pinned point or just point 0.
			# SoftBody3D doesn't expose easy "center of mass" for the deformed mesh in GDScript easily without iterating.
			# We'll try point 0.
			var pos = Vector3.ZERO
			# This is a hacky way to check if we can get point position.
			# In Godot 4, we can use the RenderingServer or PhysicsServer, but that's complex.
			# Let's try to see if the node position updates. If not, we'll just use the node position for now
			# and see if the user complains or if it looks bad.
			# WAIT! The user specifically asked "as they move".
			# So we MUST track it.
			
			# PhysicsServer3D.soft_body_get_point_global_position(body_rid, point_index)
			var rid = sb.get_physics_rid()
			# We need to know a valid point index. 0 is usually safe.
			pos = PhysicsServer3D.soft_body_get_point_global_position(rid, 0)
			
			label.position = pos + item["offset"]
			
			# Handle dynamic deflation
			if item.has("deflate_rate") and item["deflate_rate"] != 0.0:
				sb.pressure_coefficient -= item["deflate_rate"] * delta
				# Optional: Clamp pressure if needed, but negative pressure is valid for implosion
				
		elif is_instance_valid(label):
			label.queue_free()

func create_gallery() -> void:
	var tests = [
		# 1. Standard Sphere vs Cube
		{
			"name": "Sphere vs Cube",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {}
		},
		# 2. Sphere vs Sphere
		{
			"name": "Sphere vs Sphere",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": SPHERE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0.2, 2, 0), # Slight offset to roll
			"sb_settings": {}
		},
		# 3. Sphere vs Capsule
		{
			"name": "Sphere vs Capsule",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CAPSULE_SCENE,
			"collider_offset": Vector3(0, 0.5, 0), # Capsule is usually centered
			"soft_body_offset": Vector3(0, 2.5, 0),
			"sb_settings": {}
		},
		# 4. Sphere vs Prism (Ramp)
		{
			"name": "Sphere vs Ramp",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": PRISM_SCENE,
			"collider_offset": Vector3(0, 0.5, 0),
			"soft_body_offset": Vector3(0, 2.5, 0),
			"sb_settings": {}
		},
		# 5. High Pressure Sphere
		{
			"name": "High Pressure",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"pressure_coefficient": 2.0}
		},
		# 6. Low Stiffness (Jelly)
		{
			"name": "Jelly",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.1, "damping_coefficient": 0.0}
		},
		# 7. Box SoftBody (Subdivided)
		{
			"name": "Box SoftBody",
			"soft_body_mesh": create_box_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {}
		},
		# 8. Capsule SoftBody
		{
			"name": "Capsule SoftBody",
			"soft_body_mesh": create_capsule_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {}
		},
		# 9. Deflated (Negative Pressure)
		{
			"name": "Deflated",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"pressure_coefficient": 0.5},
			"deflate_rate": 0.5
		},
		# 10. Heavy SoftBody
		{
			"name": "Heavy",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"total_mass": 10.0}
		},
		# 11. Pinned (Flag/Cloth like) - Requires special handling for pins, skipping for now or adding custom setup
		# Let's do a double drop instead
		{
			"name": "Double Drop",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {},
			"extra_soft_body": true
		},
		# 12. Cylinder SoftBody
		{
			"name": "Cylinder SoftBody",
			"soft_body_mesh": create_cylinder_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {}
		},
		# 13. Bouncy Collider
		{
			"name": "Bouncy Collider",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {},
			"collider_settings": {"bounce": 1.0}
		},
		# 14. Slippery Collider
		{
			"name": "Slippery Collider",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": PRISM_SCENE,
			"collider_offset": Vector3(0, 0.5, 0),
			"soft_body_offset": Vector3(0, 2.5, 0),
			"sb_settings": {},
			"collider_settings": {"friction": 0.0}
		},
		# 15. Torus SoftBody
		{
			"name": "Torus SoftBody",
			"soft_body_mesh": create_torus_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {}
		},
		# 16. Prism SoftBody
		{
			"name": "Prism SoftBody",
			"soft_body_mesh": create_prism_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {}
		},
		# 17. Corner Strike
		{
			"name": "Corner Strike",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0.6, 2, 0.6), # Hit the corner
			"sb_settings": {}
		},
		# 18. High Drag (Slow Fall)
		{
			"name": "High Drag",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"damping_coefficient": 0.8}
		},
		# 19. Vacuum (Implosion)
		{
			"name": "Vacuum",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"pressure_coefficient": 0.0},
			"deflate_rate": 1.0
		},
		# 20. Tiny Sphere
		{
			"name": "Tiny Sphere",
			"soft_body_mesh": create_sphere_mesh(0.2),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {}
		},
		# 21. Giant Sphere
		{
			"name": "Giant Sphere",
			"soft_body_mesh": create_sphere_mesh(1.2),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 3, 0),
			"sb_settings": {}
		},
		# 22. Super Soft (Cloth-like)
		{
			"name": "Super Soft",
			"soft_body_mesh": create_box_mesh(), # Box works better for cloth-like
			"collider_scene": SPHERE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.05, "pressure_coefficient": 0.0}
		},
		# 23. Caving Sphere (Low Stiff, Neg Press)
		{
			"name": "Caving Sphere",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.2, "pressure_coefficient": -0.5, "simulation_precision": 7}
		},
		# 24. Collapsed Box (No Pressure)
		{
			"name": "Collapsed Box",
			"soft_body_mesh": create_box_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.1, "pressure_coefficient": 0.0}
		},
		# 25. Heavy Sag
		{
			"name": "Heavy Sag",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": SPHERE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"total_mass": 5.0, "linear_stiffness": 0.3, "pressure_coefficient": 0.1}
		},
		# 26. Partial Deflate
		{
			"name": "Partial Deflate",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.4, "pressure_coefficient": 0.5},
			"deflate_rate": 0.2
		},
		# 27. Crumple Zone (High Stiff, Vac)
		{
			"name": "Crumple Zone",
			"soft_body_mesh": create_box_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.8, "pressure_coefficient": -2.0}
		},
		# 28. Flat Tire (Torus Deflate)
		{
			"name": "Flat Tire",
			"soft_body_mesh": create_torus_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.3, "pressure_coefficient": 0.5},
			"deflate_rate": 0.3
		},
		# 29. Stable Sphere (Like fourstopsoftbody)
		{
			"name": "Stable Sphere",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"simulation_precision": 7, "pressure_coefficient": 0.15, "linear_stiffness": 0.5}
		},
		# 30. Deep Cave (Strong Vacuum)
		{
			"name": "Deep Cave",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.15, "pressure_coefficient": 0.0, "simulation_precision": 8},
			"deflate_rate": 0.8
		},
		# 31. Slow Collapse
		{
			"name": "Slow Collapse",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.3, "pressure_coefficient": -0.1, "damping_coefficient": 0.3}
		},
		# 32. Rigid Cave
		{
			"name": "Rigid Cave",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.8, "pressure_coefficient": -0.8, "simulation_precision": 9}
		},
		# 33. Pulsing Sphere (Alternating Pressure)
		{
			"name": "Pulsing",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"pressure_coefficient": 0.3, "linear_stiffness": 0.3, "damping_coefficient": 0.05}
		},
		# 34. Caving Box
		{
			"name": "Caving Box",
			"soft_body_mesh": create_box_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.25, "pressure_coefficient": -0.4, "simulation_precision": 7}
		},
		# 35. Minimal Stiffness Cave
		{
			"name": "Min Stiff Cave",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": CUBE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.05, "pressure_coefficient": -0.3, "simulation_precision": 8}
		},
		# 36. Balanced Deform
		{
			"name": "Balanced Deform",
			"soft_body_mesh": create_sphere_mesh(),
			"collider_scene": SPHERE_SCENE,
			"collider_offset": Vector3(0, 0, 0),
			"soft_body_offset": Vector3(0, 2, 0),
			"sb_settings": {"linear_stiffness": 0.4, "pressure_coefficient": -0.15, "simulation_precision": 7}
		}
	]
	
	var start_index = 0
	var end_index = tests.size()
	
	match gallery_part:
		1: # Part 1
			start_index = 0
			end_index = 12
		2: # Part 2
			start_index = 12
			end_index = 24
		3: # Part 3
			start_index = 24
			end_index = 36
	
	# Clamp end index
	end_index = min(end_index, tests.size())
	
	var active_tests = tests.slice(start_index, end_index)
	
	for i in range(active_tests.size()):
		var test = active_tests[i]
		var row = i / grid_width
		var col = i % grid_width
		var pos = Vector3(col * grid_spacing.x, 0, row * grid_spacing.y)
		
		create_test_cell(test, pos)

func create_test_cell(config: Dictionary, position: Vector3) -> void:
	var cell = Node3D.new()
	cell.name = config["name"]
	cell.position = position
	add_child(cell)
	
	# Add Label
	var label = Label3D.new()
	label.text = config["name"]
	label.position = Vector3(0, 3.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	cell.add_child(label)
	
	# Add Collider
	if config.has("collider_scene") and config["collider_scene"]:
		var collider = config["collider_scene"].instantiate()
		collider.position = config["collider_offset"]
		cell.add_child(collider)
		
		# Apply collider settings
		if config.has("collider_settings"):
			var static_body = find_static_body(collider)
			if static_body:
				var phys_mat = PhysicsMaterial.new()
				for key in config["collider_settings"]:
					phys_mat.set(key, config["collider_settings"][key])
				static_body.physics_material_override = phys_mat
	
	# Setup Spawner
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(func(): spawn_soft_body(cell, config))
	cell.add_child(timer)
	
	# Initial spawn
	spawn_soft_body(cell, config)

func spawn_soft_body(parent: Node, config: Dictionary) -> void:
	# Limit spawns per cell to avoid performance kill
	var current_spawns = 0
	for child in parent.get_children():
		if child is SoftBody3D:
			current_spawns += 1
	
	if current_spawns >= 5:
		return

	# Add SoftBody
	var sb = SoftBody3D.new()
	sb.mesh = config["soft_body_mesh"]
	sb.position = config["soft_body_offset"]
	sb.transform.origin = config["soft_body_offset"]
	
	# Apply settings with variation
	sb.total_mass = 1.0
	sb.linear_stiffness = 0.5
	sb.damping_coefficient = 0.01
	sb.simulation_precision = 7  # Increased from 5 for better physics simulation
	sb.pressure_coefficient = 0.0  # Default, can be overridden by sb_settings
	
	var variations = []
	
	if config.has("sb_settings"):
		for key in config["sb_settings"]:
			sb.set(key, config["sb_settings"][key])
	
	# Random variation
	if randf() > 0.5:
		var stiffness_var = randf_range(-0.2, 0.2)
		sb.linear_stiffness = clamp(sb.linear_stiffness + stiffness_var, 0.1, 1.0)
		variations.append("Stiff: %.2f" % sb.linear_stiffness)
	
	if randf() > 0.5:
		var pressure_var = randf_range(-0.5, 0.5)
		sb.pressure_coefficient += pressure_var
		variations.append("Press: %.2f" % sb.pressure_coefficient)
			
	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_hsv(randf(), 0.7, 0.9)
	sb.material_override = mat
	
	parent.add_child(sb)
	
	# Create Label
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.text = config["name"]
	if not variations.is_empty():
		label.text += "\n" + ", ".join(variations)
	
	# Add to active list for tracking
	# Add to active list for tracking
	var active_item = {
		"node": sb,
		"label": label,
		"offset": Vector3(0, 0.8, 0)
	}
	
	if config.has("deflate_rate"):
		active_item["deflate_rate"] = config["deflate_rate"]
		
	active_soft_bodies.append(active_item)
	
	# Add label to scene root so it doesn't rotate with softbody if we were parenting (though we are not parenting to SB here)
	# We will update its position in _process
	add_child(label)

func create_sphere_mesh(radius: float = 0.5) -> SphereMesh:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 16 # Needs enough for soft body
	mesh.rings = 8
	return mesh

func create_box_mesh() -> BoxMesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1, 1, 1)
	mesh.subdivide_width = 4
	mesh.subdivide_height = 4
	mesh.subdivide_depth = 4
	return mesh

func create_capsule_mesh() -> CapsuleMesh:
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.3
	mesh.height = 1.2
	mesh.radial_segments = 16
	mesh.rings = 8
	return mesh

func create_cylinder_mesh() -> CylinderMesh:
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.4
	mesh.bottom_radius = 0.4
	mesh.height = 1.2
	mesh.radial_segments = 16
	mesh.rings = 8
	return mesh

func create_torus_mesh() -> TorusMesh:
	var mesh = TorusMesh.new()
	mesh.inner_radius = 0.3
	mesh.outer_radius = 0.8
	mesh.rings = 16
	mesh.ring_segments = 12
	return mesh

func create_prism_mesh() -> PrismMesh:
	var mesh = PrismMesh.new()
	mesh.size = Vector3(1, 1, 1)
	mesh.subdivide_width = 4
	mesh.subdivide_height = 4
	mesh.subdivide_depth = 4
	return mesh

func find_static_body(node: Node) -> StaticBody3D:
	if node is StaticBody3D:
		return node
	for child in node.get_children():
		var res = find_static_body(child)
		if res:
			return res
	return null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		get_tree().reload_current_scene()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
