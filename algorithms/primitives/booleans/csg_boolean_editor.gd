@tool
extends Node3D

@export_group("Grid Settings")
@export var grid_size: Vector3i = Vector3i(5, 4, 5):
	set(value):
		grid_size = value
		if Engine.is_editor_hint():
			update_grid_info()

@export var spacing: float = 4.0:
	set(value):
		spacing = value
		if Engine.is_editor_hint() and auto_update:
			call_deferred("generate_csg_grid")

@export_group("Generation Controls")
@export var generate_now: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			generate_csg_grid()

@export var clear_all: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			clear_all_csg()

@export var auto_update: bool = false

@export_group("Randomization")
@export var use_random_seed: bool = true
@export var manual_seed: int = 12345:
	set(value):
		manual_seed = value
		if Engine.is_editor_hint() and auto_update:
			call_deferred("generate_csg_grid")

@export_group("Appearance")
@export var show_labels: bool = true:
	set(value):
		show_labels = value
		if Engine.is_editor_hint():
			toggle_labels_visibility()

@export var use_materials: bool = true
@export var wireframe_mode: bool = false:
	set(value):
		wireframe_mode = value
		if Engine.is_editor_hint():
			toggle_wireframe_mode()

@export_group("Info")
@export var total_objects: int = 0
@export var grid_info: String = ""

# CSG variation types
var variation_types = [
	"Hollow Sphere", "Sphere with Holes", "Perforated Cube", "Torus Intersection",
	"Cylinder Subtraction", "Nested Boxes", "Swiss Cheese", "Lattice Structure",
	"Twisted Forms", "Boolean Sculpture", "Organic Cavities", "Ring Structures",
	"Intersecting Cylinders", "Complex Hollow", "Fractal-like", "Architectural",
	"Abstract Art", "Mechanical Parts", "Natural Erosion", "Crystalline",
	"Flowing Forms", "Puzzle Pieces", "Minimal Art", "Complex Intersection",
	"Random Combination"
]

# Materials for visual distinction
var materials = []

func _ready():
	if Engine.is_editor_hint():
		setup_materials()
		update_grid_info()

func update_grid_info():
	total_objects = grid_size.x * grid_size.y * grid_size.z
	grid_info = "%dx%dx%d = %d objects" % [grid_size.x, grid_size.y, grid_size.z, total_objects]

func setup_materials():
	materials.clear()
	var base_colors = [
		Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, 
		Color.MAGENTA, Color.CYAN, Color.ORANGE, Color.PURPLE,
		Color.PINK, Color.LIME_GREEN, Color.LIGHT_BLUE, Color.LIGHT_CORAL
	]
	
	for color in base_colors:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = 0.3
		material.roughness = 0.7
		if wireframe_mode:
			material.flags_use_point_size = true
			material.flags_wireframe = true
		materials.append(material)

func generate_csg_grid():
	if not Engine.is_editor_hint():
		return
	
	print("Generating CSG grid in editor...")
	
	# Clear existing CSG objects
	clear_all_csg()
	
	# Set seed
	if use_random_seed:
		randomize()
	else:
		seed(manual_seed)
	
	var variation_index = 0
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var position = Vector3(
					(x - grid_size.x * 0.5 + 0.5) * spacing,
					(y - grid_size.y * 0.5 + 0.5) * spacing,
					(z - grid_size.z * 0.5 + 0.5) * spacing
				)
				
				var csg_object = create_csg_variation(variation_index)
				if csg_object:
					csg_object.position = position
					add_child(csg_object)
					csg_object.owner = get_tree().edited_scene_root
					
					# Set all children as owned by scene root for editor
					set_owner_recursive(csg_object, get_tree().edited_scene_root)
					
					# Add label if enabled
					if show_labels:
						var label = create_variation_label(variation_index, position)
						add_child(label)
						label.owner = get_tree().edited_scene_root
				
				variation_index += 1
	
	update_grid_info()
	print("Generated %d CSG variations!" % total_objects)

func set_owner_recursive(node: Node, owner: Node):
	for child in node.get_children():
		child.owner = owner
		set_owner_recursive(child, owner)

func clear_all_csg():
	if not Engine.is_editor_hint():
		return
	
	var children_to_remove = []
	for child in get_children():
		if child.name.begins_with("CSG_") or child.name.begins_with("Label3D_"):
			children_to_remove.append(child)
	
	for child in children_to_remove:
		child.queue_free()
	
	print("Cleared all CSG objects")

func toggle_labels_visibility():
	if not Engine.is_editor_hint():
		return
	
	for child in get_children():
		if child.name.begins_with("Label3D_"):
			child.visible = show_labels

func toggle_wireframe_mode():
	if not Engine.is_editor_hint():
		return
	
	setup_materials()
	
	# Update existing materials
	for child in get_children():
		if child.name.begins_with("CSG_"):
			update_csg_materials(child)

func update_csg_materials(csg_node: Node):
	if csg_node is CSGShape3D and use_materials:
		var index = int(csg_node.get_parent().name.split("_")[-1]) if csg_node.get_parent().name.contains("_") else 0
		if index < materials.size():
			csg_node.material_override = materials[index % materials.size()]
	
	for child in csg_node.get_children():
		update_csg_materials(child)

func create_csg_variation(index: int) -> Node3D:
	var container = Node3D.new()
	container.name = "CSG_Variation_%d_%s" % [index, variation_types[index % variation_types.size()]]
	
	var combiner = CSGCombiner3D.new()
	combiner.name = "CSGCombiner3D"
	container.add_child(combiner)
	
	# Choose variation type based on index
	var variation_type = index % 25
	
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
		11: create_ring_structures(combiner)
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
	if use_materials and materials.size() > 0:
		var material = materials[index % materials.size()]
		apply_material_to_csg(combiner, material)
	
	return container

# CSG Creation Functions
func create_hollow_sphere(combiner: CSGCombiner3D):
	var outer_sphere = CSGSphere3D.new()
	outer_sphere.name = "OuterSphere"
	outer_sphere.radius = 1.0
	combiner.add_child(outer_sphere)
	
	var inner_sphere = CSGSphere3D.new()
	inner_sphere.name = "InnerSphere"
	inner_sphere.radius = 0.7
	inner_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
	combiner.add_child(inner_sphere)

func create_sphere_with_holes(combiner: CSGCombiner3D):
	var sphere = CSGSphere3D.new()
	sphere.name = "BaseSphere"
	sphere.radius = 1.2
	combiner.add_child(sphere)
	
	for i in range(5):
		var hole = CSGSphere3D.new()
		hole.name = "Hole" + str(i)
		hole.radius = 0.3
		hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		hole.position = Vector3(
			randf_range(-0.8, 0.8),
			randf_range(-0.8, 0.8),
			randf_range(-0.8, 0.8)
		)
		combiner.add_child(hole)

func create_perforated_cube(combiner: CSGCombiner3D):
	var cube = CSGBox3D.new()
	cube.name = "BaseCube"
	cube.size = Vector3(2, 2, 2)
	combiner.add_child(cube)
	
	var hole_index = 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				if x == 0 and y == 0 and z == 0:
					continue
				var hole = CSGSphere3D.new()
				hole.name = "Hole" + str(hole_index)
				hole.radius = 0.2
				hole.operation = CSGShape3D.OPERATION_SUBTRACTION
				hole.position = Vector3(x * 0.6, y * 0.6, z * 0.6)
				combiner.add_child(hole)
				hole_index += 1

func create_torus_intersection(combiner: CSGCombiner3D):
	var torus1 = CSGTorus3D.new()
	torus1.name = "Torus1"
	torus1.inner_radius = 0.3
	torus1.outer_radius = 1.0
	combiner.add_child(torus1)
	
	var torus2 = CSGTorus3D.new()
	torus2.name = "Torus2"
	torus2.inner_radius = 0.3
	torus2.outer_radius = 1.0
	torus2.rotation_degrees = Vector3(90, 0, 0)
	torus2.operation = CSGShape3D.OPERATION_INTERSECTION
	combiner.add_child(torus2)

func create_cylinder_subtraction(combiner: CSGCombiner3D):
	var cylinder = CSGCylinder3D.new()
	cylinder.name = "BaseCylinder"
	cylinder.height = 2.0
	cylinder.top_radius = 1.0
	cylinder.bottom_radius = 1.0
	combiner.add_child(cylinder)
	
	for i in range(8):
		var small_cyl = CSGCylinder3D.new()
		small_cyl.name = "SubCylinder" + str(i)
		small_cyl.height = 2.5
		small_cyl.top_radius = 0.15
		small_cyl.bottom_radius = 0.15
		small_cyl.operation = CSGShape3D.OPERATION_SUBTRACTION
		var angle = i * PI / 4
		small_cyl.position = Vector3(cos(angle) * 0.6, 0, sin(angle) * 0.6)
		combiner.add_child(small_cyl)

func create_nested_boxes(combiner: CSGCombiner3D):
	var sizes = [2.0, 1.6, 1.2, 0.8]
	var operations = [CSGShape3D.OPERATION_UNION, CSGShape3D.OPERATION_SUBTRACTION, 
					 CSGShape3D.OPERATION_UNION, CSGShape3D.OPERATION_SUBTRACTION]
	
	for i in range(sizes.size()):
		var box = CSGBox3D.new()
		box.name = "NestedBox" + str(i)
		box.size = Vector3(sizes[i], sizes[i], sizes[i])
		box.operation = operations[i]
		box.rotation_degrees = Vector3(i * 15, i * 15, i * 15)
		combiner.add_child(box)

func create_swiss_cheese_effect(combiner: CSGCombiner3D):
	var base = CSGSphere3D.new()
	base.name = "CheeseBase"
	base.radius = 1.3
	combiner.add_child(base)
	
	for i in range(12):
		var hole = CSGSphere3D.new()
		hole.name = "CheeseHole" + str(i)
		hole.radius = randf_range(0.1, 0.4)
		hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		hole.position = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		combiner.add_child(hole)

func create_lattice_structure(combiner: CSGCombiner3D):
	var frame_thickness = 0.1
	var beam_index = 0
	
	for i in range(3):
		for j in range(-1, 2, 2):
			for k in range(-1, 2, 2):
				var beam = CSGBox3D.new()
				beam.name = "LatticeBeam" + str(beam_index)
				if i == 0:
					beam.size = Vector3(2.0, frame_thickness, frame_thickness)
					beam.position = Vector3(0, j, k)
				elif i == 1:
					beam.size = Vector3(frame_thickness, 2.0, frame_thickness)
					beam.position = Vector3(j, 0, k)
				else:
					beam.size = Vector3(frame_thickness, frame_thickness, 2.0)
					beam.position = Vector3(j, k, 0)
				combiner.add_child(beam)
				beam_index += 1

func create_twisted_forms(combiner: CSGCombiner3D):
	for i in range(5):
		var shape: CSGShape3D
		if i % 2 == 0:
			shape = CSGBox3D.new()
			shape.size = Vector3(0.3, 2.0, 0.3)
		else:
			shape = CSGCylinder3D.new()
			shape.height = 2.0
			shape.top_radius = 0.15
			shape.bottom_radius = 0.15
		
		shape.name = "TwistElement" + str(i)
		shape.position.y = i * 0.3 - 0.6
		shape.rotation_degrees = Vector3(0, i * 30, 0)
		
		if i > 0:
			shape.operation = CSGShape3D.OPERATION_SUBTRACTION if i % 3 == 0 else CSGShape3D.OPERATION_UNION
		
		combiner.add_child(shape)

# Simplified implementations for remaining variations
func create_boolean_sculpture(combiner: CSGCombiner3D):
	create_torus_intersection(combiner)

func create_organic_cavities(combiner: CSGCombiner3D):
	create_swiss_cheese_effect(combiner)

func create_ring_structures(combiner: CSGCombiner3D):
	create_torus_intersection(combiner)

func create_intersecting_cylinders(combiner: CSGCombiner3D):
	create_cylinder_subtraction(combiner)

func create_complex_hollow(combiner: CSGCombiner3D):
	create_nested_boxes(combiner)

func create_fractal_like(combiner: CSGCombiner3D):
	create_lattice_structure(combiner)

func create_architectural_form(combiner: CSGCombiner3D):
	create_perforated_cube(combiner)

func create_abstract_art(combiner: CSGCombiner3D):
	create_twisted_forms(combiner)

func create_mechanical_parts(combiner: CSGCombiner3D):
	create_cylinder_subtraction(combiner)

func create_natural_erosion(combiner: CSGCombiner3D):
	create_swiss_cheese_effect(combiner)

func create_crystalline_structure(combiner: CSGCombiner3D):
	create_lattice_structure(combiner)

func create_flowing_forms(combiner: CSGCombiner3D):
	create_twisted_forms(combiner)

func create_puzzle_pieces(combiner: CSGCombiner3D):
	create_nested_boxes(combiner)

func create_minimal_art(combiner: CSGCombiner3D):
	create_hollow_sphere(combiner)

func create_complex_intersection(combiner: CSGCombiner3D):
	create_torus_intersection(combiner)

func create_random_combination(combiner: CSGCombiner3D):
	var num_shapes = randi_range(2, 4)
	for i in range(num_shapes):
		var shape = create_random_primitive()
		shape.name = "RandomShape" + str(i)
		if i > 0:
			shape.operation = [CSGShape3D.OPERATION_UNION, CSGShape3D.OPERATION_SUBTRACTION, CSGShape3D.OPERATION_INTERSECTION][randi() % 3]
		shape.position = Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		shape.rotation_degrees = Vector3(randf_range(0, 360), randf_range(0, 360), randf_range(0, 360))
		combiner.add_child(shape)

func create_random_primitive() -> CSGShape3D:
	var primitives = ["box", "sphere", "cylinder", "torus"]
	var type = primitives[randi() % primitives.size()]
	var shape: CSGShape3D
	
	match type:
		"box":
			shape = CSGBox3D.new()
			shape.size = Vector3(randf_range(0.5, 1.5), randf_range(0.5, 1.5), randf_range(0.5, 1.5))
		"sphere":
			shape = CSGSphere3D.new()
			shape.radius = randf_range(0.3, 0.8)
		"cylinder":
			shape = CSGCylinder3D.new()
			shape.height = randf_range(0.5, 1.5)
			shape.top_radius = randf_range(0.2, 0.6)
			shape.bottom_radius = randf_range(0.2, 0.6)
		"torus":
			shape = CSGTorus3D.new()
			shape.inner_radius = randf_range(0.1, 0.3)
			shape.outer_radius = randf_range(0.4, 0.8)
	
	return shape

func apply_material_to_csg(csg_node: Node, material: Material):
	if csg_node is CSGShape3D:
		csg_node.material_override = material
	
	for child in csg_node.get_children():
		apply_material_to_csg(child, material)

func create_variation_label(index: int, pos: Vector3) -> Label3D:
	var label = Label3D.new()
	label.name = "Label3D_" + str(index)
	label.text = str(index) + ": " + variation_types[index % variation_types.size()]
	label.position = pos + Vector3(0, 2.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.005
	label.modulate = Color.WHITE
	return label
