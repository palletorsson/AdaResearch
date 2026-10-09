extends Node3D

# ONE SCRIPT, FOUR REGISTRY NAMES. softbody_gallery_part1, softbody_gallery_part2,
# softbody_gallery_part3 and softbodytest are the same 36-cell rack sliced by
# `gallery_part`. They are a family whether or not anyone declared them one, so the axis
# below is deliberately SHARED: the four siblings answer the same question with the same
# words and therefore measure alike instead of drifting into four private vocabularies.

# Configuration
# Configuration
@export var grid_spacing: Vector2 = Vector2(5.0, 5.0)
@export var grid_width: int = 6
@export_enum("All", "Part 1", "Part 2", "Part 3") var gallery_part: int = 0

## AXIS — WHAT THE APPARATUS DOES WITH A RESULT NOBODY SPECIFIED. Shared word for word
## with [[mass_spring_bench]] and [[revolving_joy_ride]]: one question across the whole
## soft-body bench family, so a 36-cell rack and a bench-top lattice are comparable.
##
## Every cell here is a DROP. The body falls, hits its collider, deforms and settles, so
## any axis pinned to the falling would be one photograph taken five times. These four
## values are bolted to the cell floor and say the same thing whether the specimen is
## mid-air, mid-squash or long since at rest.
##
##   none      the bare rack: a collider, a drop and a floating name. The legacy lineage.
##   gauge     a graduated column beside each cell with a cantilever arm over the
##             specimen and a stylus dropped onto it. Each cell stops being a demo and
##             starts reporting a height.
##   control   a witness plinth per cell carrying an empty wire cage at the size the body
##             had BEFORE the drop. Each squashed shape becomes a difference, not a shape.
##   chart     a record board at the back of every cell carrying the settling trace —
##             an oscillation damping onto the rest line, inked through the board so it
##             reads from either side. The rack starts keeping a history.
##   vitrine   a glass case over each cell: posts, rails, capping plate, caption. Twelve
##             experiments you could reach into become twelve exhibits you cannot.
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

## Seed for the per-body stiffness/pressure jitter and the random hue every specimen is
## given. -1 randomizes exactly as this rack always has, so the default lineage is
## untouched; any value >= 0 makes the whole rack reproducible, which is the precondition
## for a sweep measuring an axis rather than measuring sixty random colours.
@export var seed_value: int = -1

## The rack re-drops a body into every cell every two seconds, up to five per cell, so how
## many specimens are in shot depends on when the shutter opened. false stops after the
## first drop: one body per cell, and the picture stops depending on the clock.
@export var respawn: bool = true

# Resources
const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")
const SPHERE_SCENE = preload("res://commons/primitives/sphere/sphere.tscn")
const CAPSULE_SCENE = preload("res://commons/primitives/capsule/capsule.tscn")
const PRISM_SCENE = preload("res://commons/primitives/prismes/prism_block.tscn")

var active_soft_bodies: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _seeded: bool = false
var _built: bool = false

func _ready() -> void:
	_seed_rng()
	create_gallery()
	_built = true

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
	if respawn:
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.autostart = true
		timer.timeout.connect(func(): spawn_soft_body(cell, config))
		cell.add_child(timer)

	# Initial spawn
	spawn_soft_body(cell, config)

	# The assay apparatus, built last so nothing above it shifts.
	_assay_cell(cell)

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
	
	# Random variation. Routed through _sb_randf so seed_value can pin it; on the default
	# (-1) these call the same globals in the same order as they always did.
	if _sb_randf() > 0.5:
		var stiffness_var = _sb_randf_range(-0.2, 0.2)
		sb.linear_stiffness = clamp(sb.linear_stiffness + stiffness_var, 0.1, 1.0)
		variations.append("Stiff: %.2f" % sb.linear_stiffness)

	if _sb_randf() > 0.5:
		var pressure_var = _sb_randf_range(-0.5, 0.5)
		sb.pressure_coefficient += pressure_var
		variations.append("Press: %.2f" % sb.pressure_coefficient)

	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_hsv(_sb_randf(), 0.7, 0.9)
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
	var rebuild: bool = false
	if config.has("assay"):
		var want: String = str(config["assay"]).strip_edges().to_lower()
		# An unknown word keeps the default. A typo must never publish a silent variant.
		if ASSAYS.has(want):
			assay = want
			rebuild = true
	if config.has("seed_value"):
		seed_value = int(config["seed_value"])
		rebuild = true
	if config.has("respawn"):
		respawn = _sb_bool(config["respawn"])
		rebuild = true
	if config.has("gallery_part"):
		gallery_part = clampi(int(config["gallery_part"]), 0, 3)
		rebuild = true
	if rebuild and _built:
		# Only the nodes this script made. Anything the .tscn placed has an owner and is
		# left alone — freeing the scene's own Camera3D would break every sibling.
		for c in get_children():
			if not c.owner:
				remove_child(c)
				c.queue_free()
		active_soft_bodies.clear()
		_seed_rng()
		create_gallery()


# The registry can hand a flag over as the string "true". Typing the export as bool and
# reading it raw is how the prompter's-box axis lost a whole render pass.
func _sb_bool(v) -> bool:
	if typeof(v) == TYPE_STRING:
		var s: String = str(v).strip_edges().to_lower()
		return s == "true" or s == "1" or s == "yes" or s == "on"
	return bool(v)


func _seed_rng() -> void:
	_seeded = seed_value >= 0
	if _seeded:
		_rng.seed = seed_value


# On the default (-1) these are the same global calls in the same order, so the legacy
# stream is byte for byte what it was.
func _sb_randf() -> float:
	if _seeded:
		return _rng.randf()
	return randf()


func _sb_randf_range(a: float, b: float) -> float:
	if _seeded:
		return _rng.randf_range(a, b)
	return randf_range(a, b)


# ═══════════════════════════════════════════════════════════════════════════
# ASSAY — the apparatus each cell keeps around its drop. Everything here is
# fixed to the cell floor, so it says the same thing whether the specimen is
# in the air, mid-squash or long since settled.
# ═══════════════════════════════════════════════════════════════════════════
const AS_READ := Color(0.98, 0.74, 0.26)     # the instrument accent: readings and ink
const AS_WIRE := Color(0.55, 0.88, 0.98)     # the reference standard's cool wire
const AS_STEEL := Color(0.40, 0.43, 0.48)
const AS_PAPER := Color(0.87, 0.86, 0.81)
const AS_DARK := Color(0.18, 0.19, 0.23)


func _assay_cell(cell: Node3D) -> void:
	match assay:
		"gauge":
			_as_gauge(cell)
		"control":
			_as_control(cell)
		"chart":
			_as_chart(cell)
		"vitrine":
			_as_vitrine(cell)
		_:
			pass


# ── GAUGE — the cell reports a height ─────────────────────────────────────
func _as_gauge(cell: Node3D) -> void:
	var steel: StandardMaterial3D = _as_mat(AS_STEEL, 0.35, 0.7)
	var tick: StandardMaterial3D = _as_mat(Color(0.88, 0.88, 0.84), 0.5, 0.1)
	var read: StandardMaterial3D = _as_glow(AS_READ, 1.0)
	var px: float = -1.75
	var top: float = 2.85

	cell.add_child(_as_box(Vector3(px, 0.05, 0.0), Vector3(0.55, 0.10, 0.55), steel))
	cell.add_child(_as_box(Vector3(px, top * 0.5, 0.0), Vector3(0.15, top, 0.15), steel))
	for i in range(14):
		var gy: float = 0.30 + float(i) * 0.18
		var major: bool = (i % 5) == 0
		var gl: float = (0.34 if major else 0.16)
		var gm: StandardMaterial3D = (read if major else tick)
		cell.add_child(_as_box(Vector3(px + 0.075 + gl * 0.5, gy, 0.0),
			Vector3(gl, 0.035, 0.045), gm))
	# Collar, arm out over the specimen, lit tip, stylus dropped onto the collider.
	var ay: float = 1.62
	cell.add_child(_as_box(Vector3(px, ay, 0.0), Vector3(0.30, 0.22, 0.30), _as_mat(AS_DARK, 0.6, 0.2)))
	cell.add_child(_as_box(Vector3(px + 0.78, ay, 0.0), Vector3(1.50, 0.07, 0.07), read))
	cell.add_child(_as_sphere(Vector3(px + 1.53, ay, 0.0), 0.10, read))
	cell.add_child(_as_box(Vector3(px + 1.53, (ay + 0.70) * 0.5, 0.0),
		Vector3(0.045, ay - 0.70, 0.045), read))
	cell.add_child(_as_label("GAUGE", Vector3(px, top + 0.28, 0.0), 26, AS_READ))


# ── CONTROL — the shape before the drop happened to it ────────────────────
func _as_control(cell: Node3D) -> void:
	var pale: StandardMaterial3D = _as_mat(Color(0.80, 0.80, 0.76), 0.6, 0.0)
	var wire: StandardMaterial3D = _as_glow(AS_WIRE, 1.0)
	var steel: StandardMaterial3D = _as_mat(AS_STEEL, 0.4, 0.6)
	var px: float = 1.80
	var deck: float = 1.15

	cell.add_child(_as_box(Vector3(px, 0.06, 0.0), Vector3(0.85, 0.12, 0.85), steel))
	cell.add_child(_as_box(Vector3(px, deck * 0.5, 0.0), Vector3(0.36, deck, 0.36), _as_mat(AS_DARK, 0.7, 0.1)))
	cell.add_child(_as_box(Vector3(px, deck + 0.06, 0.0), Vector3(0.80, 0.12, 0.80), pale))
	# Twelve edges of an undeformed body at rest size, with nothing inside them.
	var s: float = 0.45
	var cy: float = deck + 0.14 + s
	for sx: float in [-s, s]:
		for sz: float in [-s, s]:
			cell.add_child(_as_box(Vector3(px + sx, cy, sz), Vector3(0.035, s * 2.0, 0.035), wire))
	for sy: float in [-s, s]:
		for sz2: float in [-s, s]:
			cell.add_child(_as_box(Vector3(px, cy + sy, sz2), Vector3(s * 2.0, 0.035, 0.035), wire))
		for sx2: float in [-s, s]:
			cell.add_child(_as_box(Vector3(px + sx2, cy + sy, 0.0), Vector3(0.035, 0.035, s * 2.0), wire))
	for ex: float in [-s, s]:
		for ey: float in [-s, s]:
			for ez: float in [-s, s]:
				cell.add_child(_as_sphere(Vector3(px + ex, cy + ey, ez), 0.06, wire))
	cell.add_child(_as_label("CONTROL", Vector3(px, cy + s + 0.32, 0.0), 26, AS_WIRE))


# ── CHART — the cell keeps a history ──────────────────────────────────────
func _as_chart(cell: Node3D) -> void:
	var frame: StandardMaterial3D = _as_mat(Color(0.26, 0.27, 0.31), 0.7, 0.2)
	var paper: StandardMaterial3D = _as_mat(AS_PAPER, 0.85, 0.0)
	var rule: StandardMaterial3D = _as_mat(Color(0.58, 0.58, 0.54), 0.7, 0.0)
	var ink: StandardMaterial3D = _as_glow(AS_READ, 1.1)
	var bz: float = -2.05
	var bw: float = 3.30
	var bh: float = 1.90
	var by: float = 1.02 + bh * 0.5

	for lx: float in [-bw * 0.34, bw * 0.34]:
		cell.add_child(_as_box(Vector3(lx, 0.51, bz), Vector3(0.13, 1.02, 0.13), frame))
	# The sheet is one slab and the ink runs through its middle plane, so the trace shows
	# on both faces — a record that is blank from behind is a record for one side only.
	cell.add_child(_as_box(Vector3(0.0, by, bz), Vector3(bw, bh, 0.07), paper))
	for fy: float in [by - bh * 0.5, by + bh * 0.5]:
		cell.add_child(_as_box(Vector3(0.0, fy, bz), Vector3(bw + 0.10, 0.09, 0.10), frame))
	for fx: float in [-bw * 0.5, bw * 0.5]:
		cell.add_child(_as_box(Vector3(fx, by, bz), Vector3(0.09, bh + 0.10, 0.10), frame))

	var x0: float = -bw * 0.42
	var x1: float = bw * 0.42
	var y0: float = by - bh * 0.32
	var y1: float = by + bh * 0.32
	cell.add_child(_as_box(Vector3(0.0, y0, bz), Vector3(bw * 0.86, 0.030, 0.085), rule))
	cell.add_child(_as_box(Vector3(x0, by, bz), Vector3(0.030, bh * 0.70, 0.085), rule))
	for i in range(4):
		cell.add_child(_as_box(Vector3(0.0, lerpf(y0, y1, float(i + 1) / 5.0), bz),
			Vector3(bw * 0.86, 0.014, 0.082), rule))
	# CLOSED FORM, not sampled from the running drop: a plot that came out different on
	# every launch would be noise wearing the costume of a record.
	var prev: Vector3 = Vector3.ZERO
	for i in range(33):
		var f: float = float(i) / 32.0
		var v: float = exp(-3.2 * f) * cos(f * 14.0)
		var p: Vector3 = Vector3(lerpf(x0, x1, f), lerpf(y0, y1, 0.5 + v * 0.44), bz)
		if i > 0:
			cell.add_child(_as_link(prev, p, 0.045, ink))
		prev = p
	cell.add_child(_as_sphere(prev, 0.075, ink))
	cell.add_child(_as_label("CHART", Vector3(0.0, by + bh * 0.5 + 0.26, bz), 26, AS_READ))


# ── VITRINE — the experiment becomes an exhibit ───────────────────────────
func _as_vitrine(cell: Node3D) -> void:
	var post: StandardMaterial3D = _as_mat(Color(0.30, 0.32, 0.36), 0.35, 0.8)
	var cap: StandardMaterial3D = _as_mat(AS_DARK, 0.7, 0.2)
	var half: float = 1.65
	var top: float = 3.05

	cell.add_child(_as_box(Vector3(0.0, top * 0.5, 0.0), Vector3(half * 2.0, top, half * 2.0),
		_as_glass(Color(0.72, 0.84, 0.95), 0.10)))
	for px: float in [-half, half]:
		for pz: float in [-half, half]:
			cell.add_child(_as_box(Vector3(px, top * 0.5, pz), Vector3(0.13, top, 0.13), post))
	# Rails, not floors: a solid pan would hide the collider standing inside.
	for ry: float in [0.065, top]:
		for rz: float in [-half, half]:
			cell.add_child(_as_box(Vector3(0.0, ry, rz), Vector3(half * 2.0, 0.10, 0.10), post))
		for rx: float in [-half, half]:
			cell.add_child(_as_box(Vector3(rx, ry, 0.0), Vector3(0.10, 0.10, half * 2.0), post))
	cell.add_child(_as_box(Vector3(0.0, top + 0.10, 0.0),
		Vector3(half * 2.0 + 0.22, 0.14, half * 2.0 + 0.22), cap))
	cell.add_child(_as_box(Vector3(0.0, 0.42, half + 0.09), Vector3(1.30, 0.30, 0.07),
		_as_mat(Color(0.13, 0.14, 0.17), 0.8, 0.0)))
	cell.add_child(_as_label("VITRINE", Vector3(0.0, 0.42, half + 0.16), 22,
		Color(0.90, 0.92, 0.97)))


# ── Small builders (prefixed so nothing in the rack can collide) ──────────
func _as_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _as_glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _as_glass(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.08
	m.metallic = 0.2
	return m


func _as_box(p: Vector3, s: Vector3, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


func _as_sphere(p: Vector3, r: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.material_override = m
	mi.position = p
	return mi


# A cylinder spanning a to b, oriented by a hand-built Basis. look_at() needs the node in
# the tree already, and these are built before they are parented.
func _as_link(a: Vector3, b: Vector3, r: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var d: Vector3 = b - a
	var span: float = d.length()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = maxf(span, 0.002)
	mi.mesh = cm
	mi.material_override = m
	var dir: Vector3 = Vector3.UP
	if span > 0.0001:
		dir = d / span
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right: Vector3 = dir.cross(up).normalized()
	var fwd: Vector3 = right.cross(dir).normalized()
	mi.transform = Transform3D(Basis(right, dir, fwd), (a + b) * 0.5)
	return mi


func _as_label(text: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.008
	l.modulate = c
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p
	return l
