extends Node3D

@export_group("Grid Settings")
@export var grid_size: Vector3i = Vector3i(3, 5, 5)  # x, y, z
@export var spacing: float = 0.4
@export var scale_factor: float = 0.1
@export var auto_generate: bool = true

@export_group("Randomization")
@export var use_random_seed: bool = true
@export var fixed_seed: int = 12345
@export var material_variations: bool = true

# Arrays to store different primitive types and operations
var primitive_types = ["box", "sphere", "cylinder", "torus", "prism"]
var operation_types = [CSGShape3D.OPERATION_UNION, CSGShape3D.OPERATION_SUBTRACTION, CSGShape3D.OPERATION_INTERSECTION]

# Materials for visual distinction
var materials = []

func _ready():
	setup_materials()
	if auto_generate:
		generate_csg_grid()

func setup_materials():
	# Create different materials for visual variety
	var base_colors = [
		Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, 
		Color.MAGENTA, Color.CYAN, Color.ORANGE, Color.PURPLE,
		Color.PINK, Color.LIME_GREEN
	]
	
	for color in base_colors:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = randf_range(0.0, 0.8)
		material.roughness = randf_range(0.1, 0.9)
		materials.append(material)

func generate_csg_grid():
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Set random seed if specified
	if use_random_seed:
		randomize()
	else:
		seed(fixed_seed)
	
	var variation_index = 0
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var position = Vector3(x * spacing, y * spacing, z * spacing)
				var csg_object = create_csg_variation(variation_index)
				
				if csg_object:
					# Wrap the CSG object in a grab_cube for VR interaction
					var grab_cube = create_grab_cube_wrapper(csg_object, variation_index)
					grab_cube.position = position
					add_child(grab_cube)
					
					# Add a label for identification
					var label = create_variation_label(variation_index, position)
					add_child(label)
				
				variation_index += 1

func create_csg_variation(index: int) -> CSGCombiner3D:
	var combiner = CSGCombiner3D.new()
	combiner.name = "CSG_Variation_" + str(index)
	
	# Choose variation type based on index
	var variation_type = index % 25  # 25 different base variations
	
	match variation_type:
		0: create_hollow_sphere(combiner)
		1: create_sphere_with_holes(combiner)
		2: create_perforated_cube(combiner)
		3: create_torus_intersection(combiner)
		4: create_cylinder_subtraction(combiner)
		5: create_nested_boxes(combiner)
		6: create_swiss_cheese_effect(combiner)
		7: create_lattice_structure(combiner)
		8: create_twisted_forms(combiner)
		9: create_boolean_sculpture(combiner)
		10: create_organic_cavities(combiner)
		11: create_geometric_cutouts(combiner)
		12: create_intersecting_cylinders(combiner)
		13: create_complex_hollow(combiner)
		14: create_fractal_like(combiner)
		15: create_architectural_form(combiner)
		16: create_abstract_art(combiner)
		17: create_mechanical_parts(combiner)
		18: create_natural_erosion(combiner)
		19: create_crystalline_structure(combiner)
		20: create_flowing_forms(combiner)
		21: create_puzzle_pieces(combiner)
		22: create_minimal_art(combiner)
		23: create_complex_intersection(combiner)
		_: create_random_combination(combiner)
	
	# Apply material if enabled
	if material_variations and materials.size() > 0:
		var material = materials[index % materials.size()]
		apply_material_to_csg(combiner, material)
	
	# Apply scale factor to the entire combiner
	combiner.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	return combiner

# Variation 0: Basic hollow sphere
func create_hollow_sphere(combiner: CSGCombiner3D):
	var outer_sphere = CSGSphere3D.new()
	outer_sphere.radius = 1.0
	combiner.add_child(outer_sphere)
	
	var inner_sphere = CSGSphere3D.new()
	inner_sphere.radius = 0.7
	inner_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
	combiner.add_child(inner_sphere)

# Variation 1: Sphere with multiple holes and nested spheres
func create_sphere_with_holes(combiner: CSGCombiner3D):
	var sphere = CSGSphere3D.new()
	sphere.radius = 1.2
	combiner.add_child(sphere)
	
	# Add more random holes (increased from 5 to 12)
	for i in range(12):
		var hole = CSGSphere3D.new()
		hole.radius = randf_range(0.15, 0.4)
		hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		hole.position = Vector3(
			randf_range(-0.8, 0.8),
			randf_range(-0.8, 0.8),
			randf_range(-0.8, 0.8)
		)
		combiner.add_child(hole)
	
	# Add nested spheres inside
	for i in range(3):
		var inner_sphere = CSGSphere3D.new()
		inner_sphere.radius = randf_range(0.2, 0.6)
		inner_sphere.operation = CSGShape3D.OPERATION_UNION
		inner_sphere.position = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)
		combiner.add_child(inner_sphere)
	
	# Add torus intersections
	for i in range(2):
		var torus = CSGTorus3D.new()
		torus.inner_radius = 0.1
		torus.outer_radius = randf_range(0.3, 0.7)
		torus.operation = CSGShape3D.OPERATION_INTERSECTION
		torus.position = Vector3(
			randf_range(-0.6, 0.6),
			randf_range(-0.6, 0.6),
			randf_range(-0.6, 0.6)
		)
		torus.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		combiner.add_child(torus)

# Variation 2: Perforated cube with multiple boxes and rectangles
func create_perforated_cube(combiner: CSGCombiner3D):
	var cube = CSGBox3D.new()
	cube.size = Vector3(2, 2, 2)
	combiner.add_child(cube)
	
	# Create more grid holes (increased density)
	for x in range(-2, 3):
		for y in range(-2, 3):
			for z in range(-2, 3):
				if x == 0 and y == 0 and z == 0:
					continue
				var hole = CSGSphere3D.new()
				hole.radius = randf_range(0.1, 0.3)
				hole.operation = CSGShape3D.OPERATION_SUBTRACTION
				hole.position = Vector3(x * 0.4, y * 0.4, z * 0.4)
				combiner.add_child(hole)
	
	# Add nested boxes inside
	for i in range(4):
		var inner_box = CSGBox3D.new()
		inner_box.size = Vector3(
			randf_range(0.3, 0.8),
			randf_range(0.3, 0.8),
			randf_range(0.3, 0.8)
		)
		inner_box.operation = CSGShape3D.OPERATION_UNION if i % 2 == 0 else CSGShape3D.OPERATION_SUBTRACTION
		inner_box.position = Vector3(
			randf_range(-0.6, 0.6),
			randf_range(-0.6, 0.6),
			randf_range(-0.6, 0.6)
		)
		inner_box.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		combiner.add_child(inner_box)
	
	# Add rectangular cutouts
	for i in range(6):
		var rect = CSGBox3D.new()
		rect.size = Vector3(
			randf_range(0.1, 0.4),
			randf_range(0.1, 0.4),
			randf_range(0.1, 0.4)
		)
		rect.operation = CSGShape3D.OPERATION_SUBTRACTION
		rect.position = Vector3(
			randf_range(-0.7, 0.7),
			randf_range(-0.7, 0.7),
			randf_range(-0.7, 0.7)
		)
		rect.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		combiner.add_child(rect)

# Variation 3: Torus intersection
func create_torus_intersection(combiner: CSGCombiner3D):
	var torus1 = CSGTorus3D.new()
	torus1.inner_radius = 0.3
	torus1.outer_radius = 1.0
	combiner.add_child(torus1)
	
	var torus2 = CSGTorus3D.new()
	torus2.inner_radius = 0.3
	torus2.outer_radius = 1.0
	torus2.rotation_degrees = Vector3(90, 0, 0)
	torus2.operation = CSGShape3D.OPERATION_INTERSECTION
	combiner.add_child(torus2)

# Variation 4: Cylinder with multiple subtractions and nested cylinders
func create_cylinder_subtraction(combiner: CSGCombiner3D):
	var cylinder = CSGCylinder3D.new()
	cylinder.height = 2.0
	cylinder.radius = 1.0
	combiner.add_child(cylinder)
	
	# Subtract more smaller cylinders (increased from 8 to 16)
	for i in range(16):
		var small_cyl = CSGCylinder3D.new()
		small_cyl.height = 2.5
		small_cyl.radius = randf_range(0.1, 0.2)
		small_cyl.operation = CSGShape3D.OPERATION_SUBTRACTION
		var angle = i * PI / 8
		small_cyl.position = Vector3(cos(angle) * randf_range(0.4, 0.8), 0, sin(angle) * randf_range(0.4, 0.8))
		small_cyl.rotation_degrees = Vector3(0, randf_range(0, 360), 0)
		combiner.add_child(small_cyl)
	
	# Add nested cylinders inside
	for i in range(5):
		var inner_cyl = CSGCylinder3D.new()
		inner_cyl.height = randf_range(1.0, 2.5)
		inner_cyl.radius = randf_range(0.2, 0.6)
		inner_cyl.operation = CSGShape3D.OPERATION_UNION if i % 2 == 0 else CSGShape3D.OPERATION_SUBTRACTION
		inner_cyl.position = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)
		inner_cyl.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		combiner.add_child(inner_cyl)
	
	# Add horizontal cylinders
	for i in range(6):
		var horiz_cyl = CSGCylinder3D.new()
		horiz_cyl.height = randf_range(0.3, 0.8)
		horiz_cyl.radius = randf_range(0.1, 0.3)
		horiz_cyl.operation = CSGShape3D.OPERATION_SUBTRACTION
		horiz_cyl.position = Vector3(
			randf_range(-0.7, 0.7),
			randf_range(-0.7, 0.7),
			randf_range(-0.7, 0.7)
		)
		horiz_cyl.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		combiner.add_child(horiz_cyl)

# Variation 5: Nested boxes with more complexity
func create_nested_boxes(combiner: CSGCombiner3D):
	var sizes = [2.0, 1.6, 1.2, 0.8, 0.6, 0.4, 0.3, 0.2]
	var operations = [CSGShape3D.OPERATION_UNION, CSGShape3D.OPERATION_SUBTRACTION, 
					 CSGShape3D.OPERATION_UNION, CSGShape3D.OPERATION_SUBTRACTION,
					 CSGShape3D.OPERATION_UNION, CSGShape3D.OPERATION_SUBTRACTION,
					 CSGShape3D.OPERATION_UNION, CSGShape3D.OPERATION_SUBTRACTION]
	
	# Main nested boxes (increased from 4 to 8)
	for i in range(sizes.size()):
		var box = CSGBox3D.new()
		box.size = Vector3(sizes[i], sizes[i], sizes[i])
		box.operation = operations[i]
		box.rotation_degrees = Vector3(i * 15, i * 15, i * 15)
		combiner.add_child(box)
	
	# Add more rectangular variations
	for i in range(6):
		var rect = CSGBox3D.new()
		rect.size = Vector3(
			randf_range(0.2, 1.0),
			randf_range(0.2, 1.0),
			randf_range(0.2, 1.0)
		)
		rect.operation = CSGShape3D.OPERATION_UNION if i % 3 == 0 else CSGShape3D.OPERATION_SUBTRACTION
		rect.position = Vector3(
			randf_range(-0.8, 0.8),
			randf_range(-0.8, 0.8),
			randf_range(-0.8, 0.8)
		)
		rect.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		combiner.add_child(rect)
	
	# Add small detail boxes
	for i in range(8):
		var detail_box = CSGBox3D.new()
		detail_box.size = Vector3(
			randf_range(0.1, 0.3),
			randf_range(0.1, 0.3),
			randf_range(0.1, 0.3)
		)
		detail_box.operation = CSGShape3D.OPERATION_SUBTRACTION
		detail_box.position = Vector3(
			randf_range(-0.9, 0.9),
			randf_range(-0.9, 0.9),
			randf_range(-0.9, 0.9)
		)
		detail_box.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		combiner.add_child(detail_box)

# Variation 6: Swiss cheese effect with more holes
func create_swiss_cheese_effect(combiner: CSGCombiner3D):
	var base = CSGSphere3D.new()
	base.radius = 1.3
	combiner.add_child(base)
	
	# More random holes of varying sizes (increased from 12 to 25)
	for i in range(25):
		var hole = CSGSphere3D.new()
		hole.radius = randf_range(0.05, 0.5)
		hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		hole.position = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		combiner.add_child(hole)
	
	# Add some nested spheres inside
	for i in range(4):
		var inner_sphere = CSGSphere3D.new()
		inner_sphere.radius = randf_range(0.2, 0.6)
		inner_sphere.operation = CSGShape3D.OPERATION_UNION
		inner_sphere.position = Vector3(
			randf_range(-0.6, 0.6),
			randf_range(-0.6, 0.6),
			randf_range(-0.6, 0.6)
		)
		combiner.add_child(inner_sphere)

# Variation 7: Lattice structure
func create_lattice_structure(combiner: CSGCombiner3D):
	var frame_thickness = 0.1
	
	# Create frame edges
	for i in range(3):  # x, y, z directions
		for j in range(-1, 2, 2):  # -1 and 1
			for k in range(-1, 2, 2):
				var beam = CSGBox3D.new()
				if i == 0:  # x-direction beam
					beam.size = Vector3(2.0, frame_thickness, frame_thickness)
					beam.position = Vector3(0, j, k)
				elif i == 1:  # y-direction beam
					beam.size = Vector3(frame_thickness, 2.0, frame_thickness)
					beam.position = Vector3(j, 0, k)
				else:  # z-direction beam
					beam.size = Vector3(frame_thickness, frame_thickness, 2.0)
					beam.position = Vector3(j, k, 0)
				combiner.add_child(beam)

# Variation 8: Twisted forms
func create_twisted_forms(combiner: CSGCombiner3D):
	for i in range(5):
		var shape = CSGBox3D.new() if i % 2 == 0 else CSGCylinder3D.new()
		
		if shape is CSGBox3D:
			shape.size = Vector3(0.3, 2.0, 0.3)
		else:
			shape.height = 2.0
			shape.radius = 0.15

		
		shape.position.y = i * 0.3 - 0.6
		shape.rotation_degrees = Vector3(0, i * 30, 0)
		
		if i > 0:
			shape.operation = CSGShape3D.OPERATION_SUBTRACTION if i % 3 == 0 else CSGShape3D.OPERATION_UNION
		
		combiner.add_child(shape)

# Add more variations (9-24) with increasing complexity...
func create_boolean_sculpture(combiner: CSGCombiner3D):
	# Artistic boolean combination
	var base = CSGTorus3D.new()
	base.inner_radius = 0.4
	base.outer_radius = 1.0
	combiner.add_child(base)
	
	var intersect = CSGBox3D.new()
	intersect.size = Vector3(2.5, 0.8, 2.5)
	intersect.operation = CSGShape3D.OPERATION_INTERSECTION
	combiner.add_child(intersect)

func create_organic_cavities(combiner: CSGCombiner3D):
	var base = CSGSphere3D.new()
	base.radius = 1.2
	combiner.add_child(base)
	
	# Organic-looking cavities
	for i in range(6):
		var cavity = CSGSphere3D.new()
		cavity.radius = randf_range(0.2, 0.5)
		cavity.operation = CSGShape3D.OPERATION_SUBTRACTION
		var angle = i * PI / 3
		var radius = randf_range(0.3, 0.8)
		cavity.position = Vector3(
			cos(angle) * radius,
			sin(angle * 0.5) * 0.5,
			sin(angle) * radius
		)
		combiner.add_child(cavity)

# Simplified versions for remaining variations
func create_geometric_cutouts(combiner: CSGCombiner3D):
	create_hollow_sphere(combiner)  # Placeholder - implement unique design

func create_intersecting_cylinders(combiner: CSGCombiner3D):
	create_cylinder_subtraction(combiner)  # Placeholder

func create_complex_hollow(combiner: CSGCombiner3D):
	create_nested_boxes(combiner)  # Placeholder

func create_fractal_like(combiner: CSGCombiner3D):
	create_lattice_structure(combiner)  # Placeholder

func create_architectural_form(combiner: CSGCombiner3D):
	create_perforated_cube(combiner)  # Placeholder

func create_abstract_art(combiner: CSGCombiner3D):
	create_boolean_sculpture(combiner)  # Placeholder

func create_mechanical_parts(combiner: CSGCombiner3D):
	create_cylinder_subtraction(combiner)  # Placeholder

func create_natural_erosion(combiner: CSGCombiner3D):
	create_swiss_cheese_effect(combiner)  # Placeholder

func create_crystalline_structure(combiner: CSGCombiner3D):
	create_lattice_structure(combiner)  # Placeholder

func create_flowing_forms(combiner: CSGCombiner3D):
	create_twisted_forms(combiner)  # Placeholder

func create_puzzle_pieces(combiner: CSGCombiner3D):
	create_nested_boxes(combiner)  # Placeholder

func create_minimal_art(combiner: CSGCombiner3D):
	create_torus_intersection(combiner)  # Placeholder

func create_complex_intersection(combiner: CSGCombiner3D):
	create_boolean_sculpture(combiner)  # Placeholder

func create_random_combination(combiner: CSGCombiner3D):
	# Truly random combination
	var num_shapes = randi_range(2, 5)
	for i in range(num_shapes):
		var shape = create_random_primitive()
		if i > 0:
			shape.operation = operation_types[randi() % operation_types.size()]
		shape.position = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)
		shape.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		combiner.add_child(shape)

func create_random_primitive() -> CSGShape3D:
	var type = primitive_types[randi() % primitive_types.size()]
	var shape: CSGShape3D
	
	match type:
		"box":
			shape = CSGBox3D.new()
			shape.size = Vector3(
				randf_range(0.5, 1.5),
				randf_range(0.5, 1.5),
				randf_range(0.5, 1.5)
			)
		"sphere":
			shape = CSGSphere3D.new()
			shape.radius = randf_range(0.3, 0.8)
		"cylinder":
			shape = CSGCylinder3D.new()
			shape.height = randf_range(0.5, 1.5)
			shape.radius = randf_range(0.2, 0.6)
		"torus":
			shape = CSGTorus3D.new()
			shape.inner_radius = randf_range(0.1, 0.3)
			shape.outer_radius = randf_range(0.4, 0.8)
		_:  # prism
			shape = CSGBox3D.new()  # Simplified as box
			shape.size = Vector3(randf_range(0.5, 1.0), randf_range(1.0, 2.0), randf_range(0.5, 1.0))
	
	return shape

func apply_material_to_csg(csg_node: Node, material: Material):
	# Apply material to all CSG children
	if csg_node is CSGShape3D:
		csg_node.material_override = material
	
	for child in csg_node.get_children():
		apply_material_to_csg(child, material)

func create_variation_label(index: int, pos: Vector3) -> Label3D:
	var label = Label3D.new()
	label.text = str(index)
	label.position = pos + Vector3(0, 0.15, 0)  # Scaled down from 1.5 to 0.15
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.001  # Scaled down from 0.01 to 0.001
	return label

# Create a grab_cube wrapper for VR interaction
func create_grab_cube_wrapper(csg_object: CSGCombiner3D, index: int) -> Node3D:
	# Load the grab_cube scene
	var grab_cube_scene = load("res://commons/primitives/cubes/grab_cube.tscn")
	if not grab_cube_scene:
		print("Warning: Could not load grab_cube.tscn, using CSG object directly")
		return csg_object
	
	# Instantiate the grab_cube
	var grab_cube = grab_cube_scene.instantiate()
	grab_cube.name = "GrabCube_" + str(index)
	
	# Set physics properties to keep objects stable
	if grab_cube is RigidBody3D:
		grab_cube.gravity_scale = 0.0  # No gravity
		grab_cube.linear_damp = 5.0   # Moderate damping
		grab_cube.angular_damp = 5.0  # Moderate angular damping
		grab_cube.mass = 1.0          # Light mass
		grab_cube.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		# Don't freeze completely - we want them grabbable but stable
	
	# Remove the default mesh from grab_cube and replace with our CSG object
	var mesh_instance = grab_cube.get_node("MeshInstance3D")
	if mesh_instance:
		mesh_instance.queue_free()
	
	# Add the CSG object as a child of the grab_cube
	grab_cube.add_child(csg_object)
	csg_object.position = Vector3.ZERO  # Center it in the grab_cube
	
	# Update the collision shape to match the CSG object bounds
	var collision_shape = grab_cube.get_node("CollisionShape3D")
	if collision_shape:
		# Create a box collision that encompasses the CSG object
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(2.0, 2.0, 2.0)  # Adjust based on your CSG object size
		collision_shape.shape = box_shape
	
	# Add a script to handle stability
	var stability_script = GDScript.new()
	stability_script.source_code = """
extends RigidBody3D

func _ready():
	# Ensure the object stays stable when not grabbed
	gravity_scale = 0.0
	linear_damp = 5.0
	angular_damp = 5.0

func _integrate_forces(state):
	# Apply additional stability
	if linear_velocity.length() > 0.1:
		linear_velocity *= 0.9  # Gradually slow down
	if angular_velocity.length() > 0.1:
		angular_velocity *= 0.9  # Gradually slow down rotation
"""
	grab_cube.set_script(stability_script)
	
	return grab_cube

# Public function to regenerate the grid
func regenerate_grid():
	generate_csg_grid()
