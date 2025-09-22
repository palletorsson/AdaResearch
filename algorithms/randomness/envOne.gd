extends Node3D

# Parameters for modular kitbashing generation
@export var module_count: int = 30
@export var space_size: Vector3 = Vector3(30, 15, 30)
@export_dir var modules_path: String = "res://modules/"
@export var generation_rules: String = "surrealist" # surrealist, mechanical, organic

# Color themes inspired by the reference images
@export var color_themes = [
	# Ben Nicholas blue/yellow theme
	{
		"primary": Color(0.1, 0.5, 0.8),
		"secondary": Color(0.9, 0.7, 0.1),
		"accent": Color(0.7, 0.1, 0.3),
		"metal": Color(0.7, 0.7, 0.75)
	},
	# Vitaly Bulgarov industrial theme
	{
		"primary": Color(0.2, 0.2, 0.25),
		"secondary": Color(0.5, 0.5, 0.55),
		"accent": Color(0.9, 0.1, 0.1),
		"metal": Color(0.8, 0.8, 0.9)
	},
	# Katie Torn vibrant theme
	{
		"primary": Color(0.9, 0.3, 0.7),
		"secondary": Color(0.2, 0.8, 0.7),
		"accent": Color(0.95, 0.95, 0.2),
		"metal": Color(0.6, 0.8, 1.0)
	}
]

var modules = []
var placed_modules = []
var color_theme = null


# -- Regenerate handling --
func regenerate_scene() -> void:
	print("envOne: Regenerating scene")
	_clear_current_geometry()
	generate_space()
	apply_lighting()
	apply_atmosphere()

func _clear_current_geometry():
	for module in placed_modules:
		if module and is_instance_valid(module):
			module.queue_free()
	placed_modules.clear()
	
	var to_remove: Array = []
	for child in get_children():
		if child is Camera3D:
			continue
		if child is MeshInstance3D or child is CSGPrimitive3D or child is GPUParticles3D:
			to_remove.append(child)
		elif child is WorldEnvironment or child is Light3D or child is SpotLight3D or child is OmniLight3D or child is DirectionalLight3D:
			to_remove.append(child)
	for node in to_remove:
		if is_instance_valid(node):
			node.queue_free()

func connect_regenerate_signal():
	if _regenerate_connected:
		return
	_attach_to_regenerate_cubes()
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)
	_regenerate_connected = true

func _attach_to_regenerate_cubes():
	for cube in get_tree().get_nodes_in_group("regenerate_emitters"):
		_connect_regenerate_cube(cube)

func _on_tree_node_added(node: Node):
	if node and node.is_in_group("regenerate_emitters"):
		_connect_regenerate_cube(node)

func _connect_regenerate_cube(cube):
	if cube and cube.has_signal("regenerate_requested") and not cube.regenerate_requested.is_connected(_on_regenerate_requested):
		cube.regenerate_requested.connect(_on_regenerate_requested)
		print("envOne: connected to regenerate cube %s" % cube.get_path())

func _on_regenerate_requested(origin: Vector3, targets: Array, metadata: Dictionary):
	print("envOne: regenerate signal received with %d target(s)" % targets.size())
	if targets.is_empty() or _matches_target(targets):
		regenerate_scene()

func _matches_target(targets: Array) -> bool:
	var this_path = get_script().resource_path
	for target in targets:
		var value = str(target)
		if value.ends_with("envOne.gd") or value.ends_with("env_one.tscn"):
			return true
		if value == this_path:
			return true
	return false

var _initial_children: Array = []
var _regenerate_connected: bool = false

func _ready():
	randomize()
	color_theme = color_themes[randi() % color_themes.size()]
	load_or_create_modules()
	generate_space()
	apply_lighting()
	apply_atmosphere()
	connect_regenerate_signal()

func load_or_create_modules():
	# Try to load existing modules
	var dir = DirAccess.open(modules_path)
	if dir and dir.list_dir_begin() == OK:
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var module = load(modules_path + file_name)
				if module:
					modules.append(module)
			file_name = dir.get_next()
	
	# If no modules found, create procedural ones
	if modules.size() == 0:
		create_procedural_modules()

func create_procedural_modules():
	# Create module types based on the selected generation style
	match generation_rules:
		"surrealist":
			create_surrealist_modules()
		"mechanical":
			create_mechanical_modules()
		"organic":
			create_organic_modules()
		_:
			create_mixed_modules()

func create_surrealist_modules():
	# Create modules inspired by exquisite corpse and surrealist works
	for i in range(10):
		# Base objects
		var module = Node3D.new()
		module.name = "SurrealistModule_" + str(i)
		
		# Add some random geometry - mixing disparate elements is key to surrealism
		match randi() % 5:
			0: # Stack of primitive shapes
				add_stacked_primitives(module)
			1: # Floating parts
				add_floating_parts(module)
			2: # Nonsensical machine
				add_nonsensical_machine(module)
			3: # Abstract sculpture
				add_abstract_sculpture(module)
			4: # Composite creature
				add_composite_creature(module)
		
		modules.append(module)

func create_mechanical_modules():
	# Create modules inspired by Vitaly Bulgarov's mechanical kit parts
	for i in range(10):
		var module = Node3D.new()
		module.name = "MechanicalModule_" + str(i)
		
		match randi() % 4:
			0: # Mechanical joint
				add_mechanical_joint(module)
			1: # Control panel
				add_control_panel(module)
			2: # Industrial pipe system
				add_pipe_system(module)
			3: # Electronic component
				add_electronic_component(module)
				
		modules.append(module)

func create_organic_modules():
	# Create modules inspired by more organic forms
	for i in range(10):
		var module = Node3D.new()
		module.name = "OrganicModule_" + str(i)
		
		match randi() % 4:
			0: # Plant-like structure
				add_plant_structure(module)
			1: # Fluid-containing vessel
				add_fluid_vessel(module)
			2: # Coral-like growth
				add_coral_structure(module)
			3: # Alien egg sac
				add_egg_structure(module)
				
		modules.append(module)

func create_mixed_modules():
	# Create some of each type for variety
	create_surrealist_modules()
	create_mechanical_modules()
	create_organic_modules()

# Helper functions to create different module types
func add_stacked_primitives(parent):
	var height = 0
	var pieces = randi() % 5 + 2  # 2-6 pieces
	
	for i in range(pieces):
		var mesh_instance = MeshInstance3D.new()
		
		# Choose a primitive mesh
		match randi() % 5:
			0: mesh_instance.mesh = SphereMesh.new()
			1: mesh_instance.mesh = BoxMesh.new()
			2: mesh_instance.mesh = CylinderMesh.new()
			3: mesh_instance.mesh = PrismMesh.new()
			4: mesh_instance.mesh = TorusMesh.new()
		
		# Randomize size
		var scale_factor = randf_range(0.5, 1.5)
		mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Position above previous piece
		mesh_instance.position.y = height
		height += randf_range(0.5, 1.0) * scale_factor
		
		# Random material
		apply_random_material(mesh_instance)
		
		parent.add_child(mesh_instance)

func add_floating_parts(parent):
	var parts = randi() % 5 + 3  # 3-7 parts
	
	for i in range(parts):
		var mesh_instance = MeshInstance3D.new()
		
		# Choose a primitive mesh
		match randi() % 5:
			0: mesh_instance.mesh = SphereMesh.new()
			1: mesh_instance.mesh = BoxMesh.new()
			2: mesh_instance.mesh = CylinderMesh.new()
			3: mesh_instance.mesh = PrismMesh.new()
			4: mesh_instance.mesh = TorusMesh.new()
		
		# Randomize size
		var scale_factor = randf_range(0.3, 1.0)
		mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Position randomly in space
		mesh_instance.position = Vector3(
			randf_range(-2, 2),
			randf_range(-2, 2),
			randf_range(-2, 2)
		)
		
		# Apply material
		apply_random_material(mesh_instance)
		
		parent.add_child(mesh_instance)

func add_nonsensical_machine(parent):
	# Base
	var base = MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.scale = Vector3(1.5, 0.2, 1.5)
	apply_material(base, "metal")
	parent.add_child(base)
	
	# Main body
	var body = MeshInstance3D.new()
	body.mesh = CylinderMesh.new()
	body.position.y = 1.0
	body.scale = Vector3(0.8, 1.0, 0.8)
	apply_material(body, "primary")
	parent.add_child(body)
	
	# Add random attachments
	for i in range(randi() % 4 + 2):  # 2-5 attachments
		var attachment = MeshInstance3D.new()
		var mesh_choice = randi() % 3
		
		if mesh_choice == 0:
			attachment.mesh = CylinderMesh.new()
			attachment.scale = Vector3(0.2, randf_range(0.5, 1.5), 0.2)
		elif mesh_choice == 1:
			attachment.mesh = BoxMesh.new()
			attachment.scale = Vector3(randf_range(0.3, 0.6), randf_range(0.3, 0.6), randf_range(0.3, 0.6))
		else:
			attachment.mesh = SphereMesh.new()
			var radius = randf_range(0.3, 0.5)
			attachment.scale = Vector3(radius, radius, radius)
		
		# Position around the body randomly
		var angle = randf_range(0, TAU)
		var distance = randf_range(0.8, 1.2)
		attachment.position = Vector3(
			cos(angle) * distance,
			randf_range(0.5, 1.5),
			sin(angle) * distance
		)
		
		apply_random_material(attachment)
		parent.add_child(attachment)

func add_abstract_sculpture(parent):
	# Create a base
	var base = MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.scale = Vector3(1.0, 0.2, 1.0)
	apply_material(base, "secondary")
	parent.add_child(base)
	
	# Create the main sculpture body - use CSG for more complex shapes
	var main_body = CSGCombiner3D.new()
	main_body.position.y = 0.5
	
	# Add primary shape
	var primary = CSGSphere3D.new()
	primary.radius = 0.7
	main_body.add_child(primary)
	
	# Subtract random shapes to create interesting form
	for i in range(randi() % 3 + 2):
		var cutter = CSGBox3D.new() if randf() > 0.5 else CSGSphere3D.new()
		cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
		
		if cutter is CSGBox3D:
			cutter.size = Vector3(randf_range(0.3, 0.5), randf_range(0.3, 0.5), randf_range(0.3, 0.5))
		else:
			cutter.radius = randf_range(0.3, 0.5)
		
		cutter.position = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)
		
		main_body.add_child(cutter)
	
	# Apply material to the CSG result
	var material = StandardMaterial3D.new()
	material.albedo_color = color_theme["primary"]
	material.metallic = randf_range(0.0, 0.5)
	material.roughness = randf_range(0.3, 0.7)
	
	primary.material = material
	
	parent.add_child(main_body)

func add_composite_creature(parent):
	# Inspired by exquisite corpse - create a creature with mismatched parts
	
	# Body
	var body = MeshInstance3D.new()
	body.mesh = CapsuleMesh.new()
	body.scale = Vector3(0.7, 1.0, 0.7)
	apply_material(body, "primary")
	parent.add_child(body)
	
	# Head (random object)
	var head = MeshInstance3D.new()
	match randi() % 4:
		0: head.mesh = SphereMesh.new()
		1: head.mesh = BoxMesh.new()
		2: head.mesh = TorusMesh.new()
		3: 
			head.mesh = PrismMesh.new()
			head.rotation_degrees.x = 90
	
	head.position.y = 1.3
	head.scale = Vector3(0.6, 0.6, 0.6)
	apply_material(head, "secondary")
	parent.add_child(head)
	
	# Limbs
	for i in range(randi() % 3 + 2):  # 2-4 limbs
		var limb = MeshInstance3D.new()
		limb.mesh = CylinderMesh.new()
		limb.scale = Vector3(0.2, randf_range(0.7, 1.2), 0.2)
		
		var angle = randf_range(0, TAU)
		limb.position = Vector3(
			cos(angle) * 0.7,
			randf_range(-0.5, 0.5),
			sin(angle) * 0.7
		)
		
		# Random rotation to point outward
		limb.look_at(limb.position * 2, Vector3.UP)
		limb.rotation_degrees.x += 90
		
		apply_material(limb, "accent")
		parent.add_child(limb)

func add_mechanical_joint(parent):
	# Base plate
	var base = MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.scale = Vector3(1.0, 0.1, 1.0)
	apply_material(base, "metal")
	parent.add_child(base)
	
	# Main joint cylinder
	var joint = MeshInstance3D.new()
	joint.mesh = CylinderMesh.new()
	joint.position.y = 0.3
	joint.scale = Vector3(0.3, 0.3, 0.3)
	apply_material(joint, "primary")
	parent.add_child(joint)
	
	# Joint arm
	var arm = MeshInstance3D.new()
	arm.mesh = BoxMesh.new()
	arm.scale = Vector3(0.2, 0.2, 1.0)
	arm.position = Vector3(0, 0.3, 0.5)
	apply_material(arm, "secondary")
	parent.add_child(arm)
	
	# Add details
	for i in range(randi() % 5 + 3):
		var detail = MeshInstance3D.new()
		if randf() > 0.5:
			detail.mesh = CylinderMesh.new()
			detail.scale = Vector3(0.1, 0.1, 0.1)
		else:
			detail.mesh = BoxMesh.new()
			detail.scale = Vector3(0.1, 0.1, 0.1)
		
		detail.position = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(0.1, 0.5),
			randf_range(-0.5, 0.5)
		)
		
		apply_material(detail, "metal")
		parent.add_child(detail)

func add_control_panel(parent):
	# Panel base
	var panel = MeshInstance3D.new()
	panel.mesh = BoxMesh.new()
	panel.scale = Vector3(1.0, 0.1, 1.5)
	panel.rotation_degrees.x = -30
	apply_material(panel, "metal")
	parent.add_child(panel)
	
	# Add controls
	for i in range(randi() % 10 + 5):
		var control = MeshInstance3D.new()
		
		if randf() > 0.7:
			# Button
			control.mesh = CylinderMesh.new()
			control.scale = Vector3(0.1, 0.05, 0.1)
			apply_material(control, "accent")
		elif randf() > 0.4:
			# Dial
			control.mesh = CylinderMesh.new()
			control.scale = Vector3(0.15, 0.03, 0.15)
			apply_material(control, "secondary")
		else:
			# Switch
			control.mesh = BoxMesh.new()
			control.scale = Vector3(0.05, 0.1, 0.05)
			apply_material(control, "primary")
		
		# Position on panel
		var panel_local_x = randf_range(-0.8, 0.8)
		var panel_local_z = randf_range(-1.2, 1.2)
		
		# Adjust for panel rotation
		var angle_rad = deg_to_rad(-30)
		control.position = Vector3(
			panel_local_x,
			panel_local_z * sin(angle_rad) + 0.1,
			panel_local_z * cos(angle_rad)
		)
		
		parent.add_child(control)

func add_pipe_system(parent):
	# Start and end points
	var start_pos = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	var end_pos = Vector3(randf_range(-1.0, 1.0), randf_range(1.0, 2.0), randf_range(-1.0, 1.0))
	
	# Create main pipe
	create_pipe_segment(parent, start_pos, Vector3(start_pos.x, start_pos.y + 0.5, start_pos.z))
	create_pipe_segment(parent, Vector3(start_pos.x, start_pos.y + 0.5, start_pos.z), 
						Vector3(end_pos.x, start_pos.y + 0.5, start_pos.z))
	create_pipe_segment(parent, Vector3(end_pos.x, start_pos.y + 0.5, start_pos.z),
						Vector3(end_pos.x, end_pos.y, start_pos.z))
	create_pipe_segment(parent, Vector3(end_pos.x, end_pos.y, start_pos.z), end_pos)
	
	# Add some connections/valves
	var valve_pos = Vector3(
		(start_pos.x + end_pos.x) / 2,
		start_pos.y + 0.5,
		start_pos.z
	)
	
	var valve = MeshInstance3D.new()
	valve.mesh = CylinderMesh.new()
	valve.position = valve_pos
	valve.scale = Vector3(0.25, 0.15, 0.25)
	valve.rotation_degrees.x = 90
	apply_material(valve, "accent")
	parent.add_child(valve)
	
	# Add a wheel to the valve
	var wheel = MeshInstance3D.new()
	wheel.mesh = TorusMesh.new()
	wheel.position = Vector3(valve_pos.x, valve_pos.y, valve_pos.z + 0.2)
	wheel.scale = Vector3(0.2, 0.2, 0.05)
	apply_material(wheel, "metal")
	parent.add_child(wheel)

func create_pipe_segment(parent, start, end):
	var segment = MeshInstance3D.new()
	segment.mesh = CylinderMesh.new()
	
	# Calculate position (midpoint)
	var midpoint = (start + end) / 2
	segment.position = midpoint
	
	# Calculate height (distance)
	var height = start.distance_to(end)
	segment.scale = Vector3(0.1, height / 2, 0.1)
	
	# Calculate rotation
	segment.look_at_from_position(midpoint, end, Vector3.UP)
	segment.rotation_degrees.x += 90
	
	apply_material(segment, "metal")
	parent.add_child(segment)

func add_electronic_component(parent):
	# Base board
	var board = MeshInstance3D.new()
	board.mesh = BoxMesh.new()
	board.scale = Vector3(1.0, 0.05, 1.5)
	apply_material(board, "secondary")
	parent.add_child(board)
	
	# Add electronic components
	for i in range(randi() % 15 + 10):
		var component = MeshInstance3D.new()
		
		match randi() % 4:
			0: # Chip
				component.mesh = BoxMesh.new()
				component.scale = Vector3(0.2, 0.05, 0.2)
				apply_material(component, "primary")
			1: # Capacitor
				component.mesh = CylinderMesh.new()
				component.scale = Vector3(0.07, 0.15, 0.07)
				apply_material(component, "metal")
			2: # LED
				component.mesh = SphereMesh.new()
				component.scale = Vector3(0.05, 0.05, 0.05)
				apply_material(component, "accent")
			3: # Resistor
				component.mesh = CylinderMesh.new()
				component.scale = Vector3(0.05, 0.1, 0.05)
				component.rotation_degrees.z = 90
				apply_material(component, "primary")
		
		component.position = Vector3(
			randf_range(-0.8, 0.8),
			0.05,
			randf_range(-1.3, 1.3)
		)
		
		parent.add_child(component)
	
	# Add circuits (thin lines)
	for i in range(randi() % 10 + 5):
		var circuit = MeshInstance3D.new()
		circuit.mesh = BoxMesh.new()
		
		var start_x = randf_range(-0.8, 0.8)
		var start_z = randf_range(-1.3, 1.3)
		var end_x = randf_range(-0.8, 0.8)
		var end_z = randf_range(-1.3, 1.3)
		
		var midpoint = Vector3((start_x + end_x) / 2, 0.03, (start_z + end_z) / 2)
		circuit.position = midpoint
		
		var length = sqrt(pow(end_x - start_x, 2) + pow(end_z - start_z, 2))
		circuit.scale = Vector3(0.01, 0.01, length)
		
		var angle = atan2(end_z - start_z, end_x - start_x)
		circuit.rotation_degrees.y = rad_to_deg(angle)
		
		apply_material(circuit, "accent")
		parent.add_child(circuit)

# Organic module builders
func add_plant_structure(parent):
	# Base/soil
	var base = MeshInstance3D.new()
	base.mesh = CylinderMesh.new()
	base.scale = Vector3(0.8, 0.3, 0.8)
	apply_organic_material(base, Color(0.4, 0.25, 0.15), 0.0, 1.0)
	parent.add_child(base)
	
	# Main stem
	var stem = MeshInstance3D.new()
	stem.mesh = CylinderMesh.new()
	stem.position.y = 0.7
	stem.scale = Vector3(0.1, 0.7, 0.1)
	apply_organic_material(stem, Color(0.2, 0.5, 0.2), 0.0, 0.7)
	parent.add_child(stem)
	
	# Add branches or leaves
	var branch_count = randi() % 5 + 3
	for i in range(branch_count):
		var branch = MeshInstance3D.new()
		if randf() > 0.5:
			# Branch
			branch.mesh = CylinderMesh.new()
			branch.scale = Vector3(0.05, randf_range(0.3, 0.7), 0.05)
			apply_organic_material(branch, Color(0.3, 0.4, 0.2), 0.0, 0.7)
		else:
			# Leaf/flower
			if randf() > 0.3:
				branch.mesh = SphereMesh.new()
				branch.scale = Vector3(0.2, 0.1, 0.2)
				apply_organic_material(branch, Color(0.1, 0.7, 0.3), 0.0, 0.9)
			else:
				branch.mesh = SphereMesh.new()
				branch.scale = Vector3(0.15, 0.15, 0.15)
				apply_organic_material(branch, Color(0.9, 0.3, 0.5), 0.0, 0.6)
		
		var height = randf_range(0.3, 1.1)
		var angle = randf_range(0, TAU)
		var distance = randf_range(0.1, 0.3)
		
		branch.position = Vector3(
			cos(angle) * distance,
			height,
			sin(angle) * distance
		)
		
		# Point outward for branches
		if branch.mesh is CylinderMesh:
			branch.look_at(branch.position + Vector3(cos(angle), 0.2, sin(angle)), Vector3.UP)
			branch.rotation_degrees.x += 90
		
		parent.add_child(branch)

func add_fluid_vessel(parent):
	# Container
	var container = MeshInstance3D.new()
	container.mesh = SphereMesh.new()
	container.scale = Vector3(0.8, 1.0, 0.8)
	
	# Make the container transparent
	var container_mat = StandardMaterial3D.new()
	container_mat.albedo_color = Color(0.9, 0.9, 1.0, 0.3)
	container_mat.metallic = 0.1
	container_mat.roughness = 0.1
	container_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	container.material_override = container_mat
	
	parent.add_child(container)
	
	# Inner fluid - slightly smaller
	var fluid = MeshInstance3D.new()
	fluid.mesh = SphereMesh.new()
	fluid.scale = Vector3(0.7, 0.9, 0.7)
	
	# Fluid material
	var fluid_color = Color(
		randf_range(0.0, 0.3),
		randf_range(0.2, 0.7),
		randf_range(0.5, 0.9),
		0.8
	)
	var fluid_mat = StandardMaterial3D.new()
	fluid_mat.albedo_color = fluid_color
	fluid_mat.metallic = 0.0
	fluid_mat.roughness = 0.3
	fluid_mat.emission_enabled = true
	fluid_mat.emission = fluid_color
	fluid_mat.emission_energy = 0.2
	fluid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fluid.material_override = fluid_mat
	
	parent.add_child(fluid)
	
	# Add connecting tubes
	add_tube(parent, Vector3(0, 0.7, 0), Vector3(0, 1.2, 0.5))
	add_tube(parent, Vector3(0, -0.7, 0), Vector3(0, -1.2, -0.5))

func add_tube(parent, start, end):
	var tube = MeshInstance3D.new()
	tube.mesh = CylinderMesh.new()
	
	var midpoint = (start + end) / 2
	tube.position = midpoint
	
	var height = start.distance_to(end)
	tube.scale = Vector3(0.1, height / 2, 0.1)
	
	tube.look_at_from_position(midpoint, end, Vector3.UP)
	tube.rotation_degrees.x += 90
	
	var tube_mat = StandardMaterial3D.new()
	tube_mat.albedo_color = Color(0.7, 0.7, 0.8, 0.5)
	tube_mat.metallic = 0.1
	tube_mat.roughness = 0.3
	tube_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tube.material_override = tube_mat
	
	parent.add_child(tube)

func add_coral_structure(parent):
	# Base
	var base = MeshInstance3D.new()
	base.mesh = CylinderMesh.new()
	base.scale = Vector3(0.8, 0.2, 0.8)
	apply_organic_material(base, Color(0.8, 0.7, 0.6), 0.0, 0.9)
	parent.add_child(base)
	
	# Main structure - use CSG for more organic shape
	var main_form = CSGCombiner3D.new()
	main_form.position.y = 0.5
	
	# Create a branching structure
	create_coral_branch(main_form, Vector3.ZERO, 0.7, 0)
	
	parent.add_child(main_form)
func create_coral_branch(parent, position, size, depth, max_depth = 3):
	# Stop if we've reached max depth
	if depth > max_depth:
		return
	
	# Create this branch segment
	var branch = CSGSphere3D.new() if randf() > 0.3 else CSGCylinder3D.new()
	
	if branch is CSGSphere3D:
		branch.radius = size
	else:
		branch.radius = size / 2
		branch.height = size * 2
		branch.rotation_degrees.x = randf_range(-30, 30)
		branch.rotation_degrees.z = randf_range(-30, 30)
	
	branch.position = position
	
	# Material
	var branch_mat = StandardMaterial3D.new()
	branch_mat.albedo_color = Color(
		randf_range(0.7, 1.0),
		randf_range(0.2, 0.5),
		randf_range(0.5, 0.8)
	)
	branch_mat.roughness = randf_range(0.7, 0.9)
	branch.material = branch_mat
	
	parent.add_child(branch)
	
	# Create sub-branches if not at max depth
	if depth < max_depth:
		var sub_branches = randi() % 3 + 1
		for i in range(sub_branches):
			var angle = randf_range(0, TAU)
			var branch_dir = Vector3(cos(angle), randf_range(0.5, 1.5), sin(angle))
			var new_pos = position + branch_dir * size
			create_coral_branch(parent, new_pos, size * 0.6, depth + 1, max_depth)

func add_egg_structure(parent):
	# Base structure
	var base = MeshInstance3D.new()
	base.mesh = SphereMesh.new()
	base.scale = Vector3(1.0, 0.5, 1.0)
	apply_organic_material(base, Color(0.3, 0.3, 0.4), 0.3, 0.5)
	parent.add_child(base)
	
	# Add multiple small egg-like protrusions
	var egg_count = randi() % 8 + 5
	for i in range(egg_count):
		var egg = MeshInstance3D.new()
		egg.mesh = SphereMesh.new()
		
		var scale_factor = randf_range(0.15, 0.3)
		egg.scale = Vector3(scale_factor, scale_factor * 1.2, scale_factor)
		
		var angle = randf_range(0, TAU)
		var radius = randf_range(0.5, 0.9)
		egg.position = Vector3(
			cos(angle) * radius,
			randf_range(-0.1, 0.3),
			sin(angle) * radius
		)
		
		# Random egg colors
		var egg_color = Color(
			randf_range(0.5, 0.9),
			randf_range(0.2, 0.6),
			randf_range(0.2, 0.6)
		)
		
		var egg_mat = StandardMaterial3D.new()
		egg_mat.albedo_color = egg_color
		egg_mat.metallic = 0.1
		egg_mat.roughness = 0.2
		egg_mat.emission_enabled = true
		egg_mat.emission = egg_color
		egg_mat.emission_energy = 0.3
		egg.material_override = egg_mat
		
		parent.add_child(egg)
	
	# Add organic connecting tendrils
	for i in range(egg_count - 2):
		var tendril = MeshInstance3D.new()
		tendril.mesh = CylinderMesh.new()
		
		var start_angle = randf_range(0, TAU)
		var end_angle = randf_range(0, TAU)
		var start_radius = randf_range(0.5, 0.9)
		var end_radius = randf_range(0.5, 0.9)
		
		var start_pos = Vector3(
			cos(start_angle) * start_radius,
			randf_range(-0.1, 0.3),
			sin(start_angle) * start_radius
		)
		
		var end_pos = Vector3(
			cos(end_angle) * end_radius,
			randf_range(-0.1, 0.3),
			sin(end_angle) * end_radius
		)
		
		var midpoint = (start_pos + end_pos) / 2
		tendril.position = midpoint
		
		var length = start_pos.distance_to(end_pos)
		tendril.scale = Vector3(0.03, length / 2, 0.03)
		
		tendril.look_at_from_position(midpoint, end_pos, Vector3.UP)
		tendril.rotation_degrees.x += 90
		
		apply_organic_material(tendril, Color(0.6, 0.2, 0.5), 0.0, 0.6)
		parent.add_child(tendril)

func generate_space():
	# Place modules in 3D space
	for i in range(module_count):
		place_random_module()
	
	# Connect some modules
	connect_modules()
	
	# Add ambient objects like particles or floating elements
	add_ambient_elements()

func place_random_module():
	if modules.size() == 0:
		push_error("No modules available!")
		return
		
	var module_instance = modules[randi() % modules.size()].duplicate()
	if not module_instance:
		return
		
	# Position randomly in space
	var position = Vector3(
		randf_range(-space_size.x/2, space_size.x/2),
		randf_range(-space_size.y/2, space_size.y/2),
		randf_range(-space_size.z/2, space_size.z/2)
	)
	
	module_instance.position = position
	
	# Random rotation
	module_instance.rotation_degrees = Vector3(
		randf_range(0, 360),
		randf_range(0, 360),
		randf_range(0, 360)
	)
	
	# Random scale variations for more diverse results
	var scale_factor = randf_range(0.5, 2.0)
	module_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	add_child(module_instance)
	placed_modules.append(module_instance)

func connect_modules():
	# Check if we have enough modules to connect
	if placed_modules.size() < 2:
		return
		
	# Create connections between modules
	var connections = min(placed_modules.size() / 2, 15) # Limit to prevent too many connections
	for i in range(connections):
		var index_a = randi() % placed_modules.size()
		var index_b = randi() % placed_modules.size()
		
		# Make sure we're not connecting a module to itself
		while index_a == index_b:
			index_b = randi() % placed_modules.size()
			
		var module_a = placed_modules[index_a]
		var module_b = placed_modules[index_b]
		
		create_connection(module_a, module_b)

func create_connection(module_a, module_b):
	# Choose connection type based on distance
	var distance = module_a.global_position.distance_to(module_b.global_position)
	
	if distance < 5.0:
		create_mechanical_connection(module_a, module_b)
	elif distance < 15.0:
		create_beam_connection(module_a, module_b)
	else:
		create_floating_connection(module_a, module_b)

func create_mechanical_connection(module_a, module_b):
	var start_pos = module_a.global_position
	var end_pos = module_b.global_position
	
	if randf() > 0.5:
		# Pipe connection
		create_pipe_path(start_pos, end_pos)
	else:
		# Solid connector
		create_solid_connector(start_pos, end_pos)

func create_pipe_path(start_pos, end_pos):
	var midpoint = (start_pos + end_pos) / 2
	midpoint.y += randf_range(1.0, 3.0) # Arch up
	
	# Create a 3-segment path
	create_pipe_segment_with_joint(start_pos, Vector3(start_pos.x, midpoint.y, start_pos.z))
	create_pipe_segment_with_joint(Vector3(start_pos.x, midpoint.y, start_pos.z), 
								Vector3(end_pos.x, midpoint.y, start_pos.z))
	create_pipe_segment_with_joint(Vector3(end_pos.x, midpoint.y, start_pos.z), 
								Vector3(end_pos.x, midpoint.y, end_pos.z))
	create_pipe_segment_with_joint(Vector3(end_pos.x, midpoint.y, end_pos.z), end_pos)

func create_pipe_segment_with_joint(start_pos, end_pos):
	# Create pipe segment
	var pipe = MeshInstance3D.new()
	pipe.mesh = CylinderMesh.new()
	
	var midpoint = (start_pos + end_pos) / 2
	pipe.position = midpoint
	
	var distance = start_pos.distance_to(end_pos)
	pipe.scale = Vector3(0.1, distance / 2, 0.1)
	
	pipe.look_at_from_position(midpoint, end_pos, Vector3.UP)
	pipe.rotation_degrees.x += 90
	
	var pipe_material = StandardMaterial3D.new()
	pipe_material.albedo_color = color_theme["metal"]
	pipe_material.metallic = 0.8
	pipe_material.roughness = 0.2
	pipe.material_override = pipe_material
	
	add_child(pipe)
	
	# Add joint at end position if it's not the destination
	if randf() > 0.5 and start_pos.distance_to(end_pos) > 0.5:
		var joint = MeshInstance3D.new()
		joint.mesh = SphereMesh.new()
		joint.position = end_pos
		joint.scale = Vector3(0.15, 0.15, 0.15)
		
		var joint_material = StandardMaterial3D.new()
		joint_material.albedo_color = color_theme["primary"]
		joint_material.metallic = 0.7
		joint_material.roughness = 0.3
		joint.material_override = joint_material
		
		add_child(joint)

func create_solid_connector(start_pos, end_pos):
	# Create a solid bar between positions
	var connector = MeshInstance3D.new()
	connector.mesh = BoxMesh.new()
	
	var midpoint = (start_pos + end_pos) / 2
	connector.position = midpoint
	
	var distance = start_pos.distance_to(end_pos)
	
	# Figure out rotation to point from start to end
	connector.look_at(end_pos, Vector3.UP)
	
	# Adjust scale to match distance
	connector.scale = Vector3(0.2, 0.2, distance)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color_theme["secondary"]
	material.metallic = 0.5
	material.roughness = 0.4
	connector.material_override = material
	
	add_child(connector)

func create_beam_connection(module_a, module_b):
	var start_pos = module_a.global_position
	var end_pos = module_b.global_position
	
	# Create a beam effect - thinner and with emission
	var beam = MeshInstance3D.new()
	beam.mesh = CylinderMesh.new()
	
	var midpoint = (start_pos + end_pos) / 2
	beam.position = midpoint
	
	var distance = start_pos.distance_to(end_pos)
	beam.scale = Vector3(0.05, distance / 2, 0.05)
	
	beam.look_at_from_position(midpoint, end_pos, Vector3.UP)
	beam.rotation_degrees.x += 90
	
	var beam_material = StandardMaterial3D.new()
	beam_material.albedo_color = color_theme["accent"]
	beam_material.emission_enabled = true
	beam_material.emission = color_theme["accent"]
	beam_material.emission_energy = 2.0
	beam_material.metallic = 0.0
	beam_material.roughness = 0.2
	beam.material_override = beam_material
	
	add_child(beam)
	
	# Add energy particles along the beam
	if randf() > 0.3:
		add_particles_along_beam(start_pos, end_pos, color_theme["accent"])

func create_floating_connection(module_a, module_b):
	var start_pos = module_a.global_position
	var end_pos = module_b.global_position
	
	# Create floating objects along the path
	var steps = randi() % 5 + 3
	for i in range(steps):
		var t = float(i) / float(steps - 1)
		var pos = start_pos.lerp(end_pos, t)
		
		# Add some randomness to position
		pos += Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		
		var floating_object = MeshInstance3D.new()
		
		if randf() > 0.6:
			floating_object.mesh = SphereMesh.new()
			floating_object.scale = Vector3(0.2, 0.2, 0.2)
		else:
			floating_object.mesh = BoxMesh.new()
			floating_object.scale = Vector3(0.15, 0.15, 0.15)
			floating_object.rotation_degrees = Vector3(
				randf_range(0, 360),
				randf_range(0, 360),
				randf_range(0, 360)
			)
		
		floating_object.position = pos
		
		var material = StandardMaterial3D.new()
		material.albedo_color = color_theme["primary"]
		material.emission_enabled = true
		material.emission = color_theme["primary"]
		material.emission_energy = 0.5
		floating_object.material_override = material
		
		add_child(floating_object)

func add_particles_along_beam(start_pos, end_pos, color):
	# In an actual project, you would use a real particle system
	# For this example, we'll create small spheres to simulate particles
	var particle_count = randi() % 5 + 3
	
	for i in range(particle_count):
		var t = randf()  # Random position along the beam
		var pos = start_pos.lerp(end_pos, t)
		
		var particle = MeshInstance3D.new()
		particle.mesh = SphereMesh.new()
		particle.position = pos
		particle.scale = Vector3(0.05, 0.05, 0.05)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color
		material.emission_energy = 3.0
		particle.material_override = material
		
		add_child(particle)

func add_ambient_elements():
	# Add some ambient floating elements to the scene
	for i in range(randi() % 20 + 10):
		var element = MeshInstance3D.new()
		
		# Random mesh type
		match randi() % 5:
			0: element.mesh = SphereMesh.new()
			1: element.mesh = BoxMesh.new()
			2: element.mesh = CylinderMesh.new()
			3: element.mesh = PrismMesh.new()
			4: element.mesh = TorusMesh.new()
		
		# Random position within space
		element.position = Vector3(
			randf_range(-space_size.x, space_size.x),
			randf_range(-space_size.y, space_size.y),
			randf_range(-space_size.z, space_size.z)
		)
		
		# Random rotation
		element.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		
		# Small scale
		var scale_factor = randf_range(0.1, 0.5)
		element.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Random material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(
			randf_range(0.3, 1.0),
			randf_range(0.3, 1.0),
			randf_range(0.3, 1.0)
		)
		
		# Sometimes add emission
		if randf() > 0.7:
			material.emission_enabled = true
			material.emission = material.albedo_color
			material.emission_energy = randf_range(0.5, 2.0)
		
		element.material_override = material
		
		add_child(element)

func apply_lighting():
	# Create a dynamic lighting setup
	
	# Environment light
	var world_environment = WorldEnvironment.new()
	var environment = Environment.new()
	
	# Set background
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.07, 0.1)
	
	# Add fog for atmosphere
	environment.fog_enabled = true
	#environment.fog_color = Color(0.1, 0.12, 0.15)
	environment.fog_density = 0.02
	
	# Ambient light settings
	environment.ambient_light_color = Color(0.1, 0.1, 0.2)
	environment.ambient_light_energy = 0.5
	
	# Tone mapping
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	
	# Add bloom
	environment.glow_enabled = true
	environment.glow_intensity = 0.2
	environment.glow_bloom = 0.3
	
	world_environment.environment = environment
	add_child(world_environment)
	
	# Main directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.light_energy = 1.0
	dir_light.light_color = Color(1.0, 0.95, 0.9)
	dir_light.shadow_enabled = true
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(dir_light)
	
	# Add colored spotlights
	var colors = [
		Color(0.8, 0.2, 0.3),  # Red
		Color(0.2, 0.5, 0.9),  # Blue
		Color(0.9, 0.7, 0.2)   # Yellow/Orange
	]
	
	for i in range(5):
		var spot_light = SpotLight3D.new()
		spot_light.light_color = colors[randi() % colors.size()]
		spot_light.light_energy = randf_range(2.0, 5.0)
		spot_light.spot_range = randf_range(10.0, 20.0)
		spot_light.spot_angle = randf_range(20.0, 45.0)
		
		# Position the light randomly but pointing toward the center
		var light_pos = Vector3(
			randf_range(-space_size.x, space_size.x),
			randf_range(-space_size.y, space_size.y),
			randf_range(-space_size.z, space_size.z)
		) * 0.8
		
		spot_light.position = light_pos
		spot_light.look_at(Vector3.ZERO, Vector3.UP)
		
		add_child(spot_light)

func apply_atmosphere():
	# In Godot 4, we can add volumetric fog and other atmosphere effects
	# For a more basic approach without full volumetrics, we'll use particles
	
	# Create fog particle system
	create_atmosphere_particles()
	
	# Add a skybox or environment texture if desired
	# (This would require an actual texture resource)

func create_atmosphere_particles():
	# In a full implementation, you would use GPUParticles3D
	# For simplicity in this example, we'll create a few static particles 
	
	for i in range(100):
		var particle = MeshInstance3D.new()
		particle.mesh = SphereMesh.new()
		
		# Position randomly in space
		particle.position = Vector3(
			randf_range(-space_size.x, space_size.x),
			randf_range(-space_size.y, space_size.y),
			randf_range(-space_size.z, space_size.z)
		)
		
		# Very small scale for dust-like particles
		var scale_factor = randf_range(0.02, 0.1)
		particle.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Semi-transparent material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.7, 0.7, 0.8, randf_range(0.1, 0.3))
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		particle.material_override = material
		
		add_child(particle)

# Utility functions for materials

func apply_random_material(mesh_instance):
	var material_type = randi() % 4
	
	match material_type:
		0: apply_material(mesh_instance, "primary")
		1: apply_material(mesh_instance, "secondary")
		2: apply_material(mesh_instance, "accent")
		3: apply_material(mesh_instance, "metal")

func apply_material(mesh_instance, type):
	var material = StandardMaterial3D.new()
	
	match type:
		"primary":
			material.albedo_color = color_theme["primary"]
			material.metallic = randf_range(0.0, 0.3)
			material.roughness = randf_range(0.3, 0.7)
		"secondary":
			material.albedo_color = color_theme["secondary"]
			material.metallic = randf_range(0.0, 0.3)
			material.roughness = randf_range(0.3, 0.7)
		"accent":
			material.albedo_color = color_theme["accent"]
			material.emission_enabled = randf() > 0.5
			if material.emission_enabled:
				material.emission = color_theme["accent"]
				material.emission_energy = randf_range(0.5, 2.0)
			material.metallic = 0.0
			material.roughness = randf_range(0.2, 0.5)
		"metal":
			material.albedo_color = color_theme["metal"]
			material.metallic = randf_range(0.7, 1.0)
			material.roughness = randf_range(0.1, 0.3)
	
	mesh_instance.material_override = material

func apply_organic_material(mesh_instance, base_color, metallic_range, roughness):
	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.metallic = metallic_range
	material.roughness = roughness
	mesh_instance.material_override = material
