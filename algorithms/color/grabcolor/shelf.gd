# Shelf4x4CSG.gd
# Attach this script to a Node3D in your scene
# Uses CSG subtractive booleans to create the shelf

extends Node3D

# Shelf dimensions
const COMPARTMENT_SIZE = 0.22  # 2 dm = 20 cm = 0.2 meters
const GRID_SIZE = 4
const WALL_THICKNESS = 0.01  # 5mm walls
const SHELF_DEPTH = 0.1  # 5cm depth for the shelf
const SHELF_SIZE = GRID_SIZE * COMPARTMENT_SIZE + (GRID_SIZE + 1) * WALL_THICKNESS  # Total shelf size

const TEXT_PAPER_SCENE = preload("res://commons/primitives/panels/DigitalPaper/grab_paper_text.tscn")

const COMPARTMENT_TEXTS = [
	"I. Foundations & Theory\nTurn theory (entropy, queer ontology) into game mechanics?",
	"Method for finding \"queer forms\" in algorithm margins?",
	"Ensure theory structures logic, not just aesthetics?",
	"Practical meaning of \"Klee in virtual drag\" for design?",
	"II. Technical & Methodological Approach\nHow to subvert the foundational binary in the project's code?",
	"Risk management plan for delays in complex work packages?",
	"How does the chosen tech stack support or constrain the artistic goals?",
	"Detail the art-to-tech integration pipeline (Konstfack/KTH)?",
	"III. Collaboration & Audience\nDaily plan for ensuring true collaboration between partners?",
	"How to measure if players are actually learning about algorithms?",
	"Who is the target audience? How to design for them?",
	"Make the wiki a genuinely useful open-source resource for non-coders?",
	"IV. Outcomes & Long-Term Impact\nPlan for preservation against VR hardware obsolescence?",
	"Beyond critique, what does a \"repaired\" algorithm feel like to the player?",
	"How to make research findings actionable for the tech industry?",
	"Plan for ensuring VR accessibility (motion sickness, etc.)?",
	"V. Critical Risks & Self-Reflection\nRisk of aestheticizing algorithms and hiding their real-world harm?",
	"How to address the project's own environmental and labor costs?",
	"Plan to avoid replicating biases in our own generative tools?",
	"Strategy if the \"queer potential\" we find gets commodified?"
]
var compartment_floors: Dictionary = {}
var compartment_markers: Dictionary = {}
var compartment_texts: Dictionary = {}
var compartment_snap_points: Dictionary = {}
var extra_snap_points: Array = []

func _ready():
	create_shelf_with_csg()
	# Offset the entire shelf
	#position = Vector3(0, 0, -0.1)

func create_shelf_with_csg():
	# Create wood material
	var wood_material = StandardMaterial3D.new()
	wood_material.albedo_color = Color(0.8, 0.6, 0.4)  # Light wood color
	wood_material.roughness = 0.8
	wood_material.metallic = 0.0
	
	# Create the main CSG combiner
	var shelf_combiner = CSGCombiner3D.new()
	shelf_combiner.name = "ShelfCombiner"
	shelf_combiner.operation = CSGShape3D.OPERATION_SUBTRACTION
	shelf_combiner.material_override = wood_material
	shelf_combiner.use_collision = true  # Enable collision for the CSG shape
	add_child(shelf_combiner)
	
	# Create the solid base block
	var base_box = CSGBox3D.new()
	base_box.name = "BaseBlock"
	base_box.operation = CSGShape3D.OPERATION_UNION
	base_box.size = Vector3(SHELF_SIZE, SHELF_SIZE, SHELF_DEPTH)
	base_box.position = Vector3(0, 0, 0)
	shelf_combiner.add_child(base_box)
	
	# Create compartment cutouts
	create_compartment_cutouts(shelf_combiner)
	
	# Create additional collision bodies for each compartment (for precise interaction)
	create_compartment_colliders()
	
	# Create compartment markers for sticker placement
	create_compartment_markers()

	populate_compartment_texts()
	
	print("CSG Shelf created with ", GRID_SIZE, "x", GRID_SIZE, " compartments")
	print("Compartment size: ", COMPARTMENT_SIZE * 100, "cm (exactly 2 dm)")
	print("Total shelf size: ", SHELF_SIZE * 100, "cm")
	print("Shelf depth: ", SHELF_DEPTH * 100, "cm")
	print("Colliders enabled for shelf and individual compartments")
func create_compartment_cutouts(parent_combiner: CSGCombiner3D):
	# Calculate starting position for compartments
	var start_x = -SHELF_SIZE/2 + WALL_THICKNESS + COMPARTMENT_SIZE/2
	var start_y = SHELF_SIZE/2 - WALL_THICKNESS - COMPARTMENT_SIZE/2
	
	# Create cutout boxes for each compartment
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var cutout = CSGBox3D.new()
			cutout.name = "cutout_" + str(row) + "_" + str(col)
			cutout.operation = CSGShape3D.OPERATION_SUBTRACTION
			
			# Make cutout slightly smaller than compartment to leave walls
			# and deeper than shelf to ensure clean cut
			cutout.size = Vector3(COMPARTMENT_SIZE, COMPARTMENT_SIZE, SHELF_DEPTH + 0.01)
			
			# Calculate position
			var x_pos = start_x + col * (COMPARTMENT_SIZE + WALL_THICKNESS)
			var y_pos = start_y - row * (COMPARTMENT_SIZE + WALL_THICKNESS)
			var z_pos = SHELF_DEPTH * 0.25  # Cut from front, leaving back wall
			
			cutout.position = Vector3(x_pos, y_pos, z_pos)
			parent_combiner.add_child(cutout)

func create_compartment_colliders():
	# Create thin floor colliders for each compartment so items can rest inside the shelf.
	for child in get_children():
		if child.name.begins_with("compartment_collider_"):
			child.queue_free()
	compartment_floors.clear()
	var start_x = -SHELF_SIZE/2 + WALL_THICKNESS + COMPARTMENT_SIZE/2
	var start_y = SHELF_SIZE/2 - WALL_THICKNESS - COMPARTMENT_SIZE/2
	
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var compartment_body = StaticBody3D.new()
			compartment_body.name = "compartment_collider_" + str(row) + "_" + str(col)
			
			var collision_shape = CollisionShape3D.new()
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(COMPARTMENT_SIZE - WALL_THICKNESS, WALL_THICKNESS, SHELF_DEPTH * 0.5)
			collision_shape.shape = box_shape
			
			var x_pos = start_x + col * (COMPARTMENT_SIZE + WALL_THICKNESS)
			var y_pos = start_y - row * (COMPARTMENT_SIZE + WALL_THICKNESS)
			var z_pos = -SHELF_DEPTH/4
			
			compartment_body.position = Vector3(x_pos, y_pos, z_pos)
			collision_shape.position = Vector3(0, -COMPARTMENT_SIZE/2 + WALL_THICKNESS/2, 0)
			
			compartment_body.add_child(collision_shape)
			
			compartment_body.set_meta("row", row)
			compartment_body.set_meta("col", col)
			compartment_body.set_meta("compartment_id", "compartment_" + str(row) + "_" + str(col))
			
			add_child(compartment_body)
			compartment_floors[Vector2i(row, col)] = compartment_body
func create_compartment_markers():
	# Create invisible markers and snap points at the center of each compartment
	for child in get_children():
		if child.name.begins_with("compartment_marker_"):
			child.queue_free()

	clear_snap_assets()
	compartment_markers.clear()

	var marker_material = StandardMaterial3D.new()
	marker_material.albedo_color = Color.TRANSPARENT
	marker_material.flags_transparent = true

	var indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = Color(0.2, 0.8, 1.0, 0.7)
	indicator_material.flags_transparent = true
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(0.1, 0.3, 0.6)
	indicator_material.emission_energy_multiplier = 0.5

	var marker_mesh = SphereMesh.new()
	marker_mesh.radius = 0.001  # 1mm radius
	marker_mesh.height = 0.002

	var indicator_mesh = SphereMesh.new()
	indicator_mesh.radius = 0.012
	indicator_mesh.height = 0.024

	# Calculate starting position for compartments
	var start_x = -SHELF_SIZE/2 + WALL_THICKNESS + COMPARTMENT_SIZE/2
	var start_y = SHELF_SIZE/2 - WALL_THICKNESS - COMPARTMENT_SIZE/2

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var marker = MeshInstance3D.new()
			marker.name = "compartment_marker_" + str(row) + "_" + str(col)

			# Create a small sphere as marker
			marker.mesh = marker_mesh
			marker.material_override = marker_material
			marker.visible = false  # Make invisible by default

			# Calculate position - at the back of each compartment
			var x_pos = start_x + col * (COMPARTMENT_SIZE + WALL_THICKNESS)
			var y_pos = start_y - row * (COMPARTMENT_SIZE + WALL_THICKNESS)
			var z_pos = -SHELF_DEPTH/4  # Position at back of compartment

			marker.position = Vector3(x_pos, y_pos, z_pos)
			add_child(marker)
			compartment_markers[Vector2i(row, col)] = marker

			var snap_point = Marker3D.new()
			snap_point.name = "compartment_snap_%d_%d" % [row, col]
			snap_point.position = marker.position
			# Keep default orientation so +Y is up
			snap_point.basis = Basis.IDENTITY
			snap_point.add_to_group("shelf_snap_point")
			snap_point.set_meta("row", row)
			snap_point.set_meta("col", col)
			snap_point.set_meta("compartment_id", "compartment_%d_%d" % [row, col])
			add_child(snap_point)
			compartment_snap_points[Vector2i(row, col)] = snap_point

			var snap_indicator = MeshInstance3D.new()
			snap_indicator.name = "snap_indicator_%d_%d" % [row, col]
			snap_indicator.mesh = indicator_mesh
			snap_indicator.material_override = indicator_material
			snap_indicator.visible = true
			snap_indicator.add_to_group("shelf_snap_indicator")
			snap_indicator.position = Vector3.ZERO
			snap_point.add_child(snap_indicator)

	# Create helper functions and additional snap points
	create_marker_toggle()
	create_extra_snap_points()
func clear_snap_assets() -> void:
	if not is_inside_tree():
		compartment_snap_points.clear()
		extra_snap_points.clear()
		return

	for snap_point in compartment_snap_points.values():
		if is_instance_valid(snap_point):
			snap_point.queue_free()
	compartment_snap_points.clear()

	for snap_point in extra_snap_points:
		if is_instance_valid(snap_point):
			snap_point.queue_free()
	extra_snap_points.clear()

	for indicator in get_tree().get_nodes_in_group("shelf_snap_indicator"):
		if indicator is Node3D and is_instance_valid(indicator) and self.is_ancestor_of(indicator):
			indicator.queue_free()

func create_extra_snap_points() -> void:
	for snap_point in extra_snap_points:
		if is_instance_valid(snap_point):
			snap_point.queue_free()
	extra_snap_points.clear()

	var base_y = -SHELF_SIZE/2 - 0.05
	var front_z = -SHELF_DEPTH/2 - 0.05
	var x_offsets = [-SHELF_SIZE / 4.0, SHELF_SIZE / 4.0]
	var z_offsets = [front_z, front_z - 0.05]

	var indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = Color(0.8, 0.5, 1.0, 0.7)
	indicator_material.flags_transparent = true
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(0.4, 0.2, 0.6)
	indicator_material.emission_energy_multiplier = 0.5

	var indicator_mesh = SphereMesh.new()
	indicator_mesh.radius = 0.012
	indicator_mesh.height = 0.024

	var index = 0
	for x_off in x_offsets:
		for z_off in z_offsets:
			var snap_point = Marker3D.new()
			snap_point.name = "extra_snap_%d" % index
			snap_point.position = Vector3(x_off, base_y, z_off)
			snap_point.add_to_group("shelf_snap_point")
			snap_point.set_meta("type", "auxiliary")
			add_child(snap_point)
			extra_snap_points.append(snap_point)

			var indicator = MeshInstance3D.new()
			indicator.name = "extra_snap_indicator_%d" % index
			indicator.mesh = indicator_mesh
			indicator.material_override = indicator_material
			indicator.visible = true
			indicator.add_to_group("shelf_snap_indicator")
			indicator.position = Vector3.ZERO
			snap_point.add_child(indicator)

			index += 1
func populate_compartment_texts() -> void:
	for node in compartment_texts.values():
		if is_instance_valid(node):
			node.queue_free()
	compartment_texts.clear()

	var slot_count = GRID_SIZE * GRID_SIZE
	var text_count = COMPARTMENT_TEXTS.size()
	var assignments = min(slot_count, text_count)

	for index in range(assignments):
		var row = index / GRID_SIZE
		var col = index % GRID_SIZE
		var paper = TEXT_PAPER_SCENE.instantiate()
		paper.name = "compartment_text_%d_%d" % [row, col]
		paper.set_meta("row", row)
		paper.set_meta("col", col)
		paper.set_meta("compartment_id", "compartment_%d_%d" % [row, col])

		var label = paper.get_node_or_null("Label3D")
		if label:
			label.uppercase = false
			label.text = COMPARTMENT_TEXTS[index]
		add_child(paper)
		# Ensure stickers align with shelf surface orientation (+Y up)
		paper.snap_match_rotation = true
		place_object_in_compartment(paper, row, col, WALL_THICKNESS * 0.5)
		compartment_texts[Vector2i(row, col)] = paper

	if assignments < slot_count:
		do_notify_missing_texts(assignments)

	if text_count > assignments:
		push_warning("Only the first %d of %d text entries were placed on the shelf." % [assignments, text_count])
func do_notify_missing_texts(filled: int) -> void:
	var total_slots = GRID_SIZE * GRID_SIZE
	if filled < total_slots:
		push_warning("Shelf has %d compartments but only %d text entries were provided." % [total_slots, filled])
func get_compartment_floor(row: int, col: int) -> StaticBody3D:
	return compartment_floors.get(Vector2i(row, col), null)

func get_compartment_text(row: int, col: int) -> Node3D:
	return compartment_texts.get(Vector2i(row, col), null)

func get_compartment_snap_point(row: int, col: int) -> Marker3D:
	return compartment_snap_points.get(Vector2i(row, col), null)

func get_compartment_marker(row: int, col: int) -> Node3D:
	return compartment_markers.get(Vector2i(row, col), null)

func get_compartment_center(row: int, col: int, global: bool = true) -> Vector3:
	var marker = get_compartment_marker(row, col)
	if marker:
		return marker.global_position if global else marker.position
	return Vector3.ZERO

func get_compartment_floor_height(row: int, col: int) -> float:
	var floor = get_compartment_floor(row, col)
	if floor:
		return floor.global_transform.origin.y - COMPARTMENT_SIZE * 0.5 + WALL_THICKNESS
	return 0.0

func place_object_in_compartment(node: Node3D, row: int, col: int, vertical_offset: float = 0.0) -> void:
	if node == null:
		push_warning("Cannot place a null node in the shelf.")
		return
	var floor = get_compartment_floor(row, col)
	var marker = get_compartment_marker(row, col)
	var snap_point = get_compartment_snap_point(row, col)
	if floor == null or marker == null:
		push_warning("Compartment %d,%d does not exist on this shelf." % [row, col])
		return
	var target = snap_point.global_position if snap_point else marker.global_position
	target.y = get_compartment_floor_height(row, col) + vertical_offset
	var scale = node.global_transform.basis.get_scale()
	var basis := Basis.IDENTITY.scaled(scale)
	node.global_transform = Transform3D(basis, target)
func create_marker_toggle():
	# Add a simple way to toggle marker visibility for debugging
	var toggle_markers_func = func():
		for child in get_children():
			if child.name.begins_with("compartment_marker_"):
				child.visible = !child.visible
		for indicator in get_tree().get_nodes_in_group("shelf_snap_indicator"):
			if indicator is Node3D:
				indicator.visible = !indicator.visible
	
	# Store the function reference for external access
	set_meta("toggle_markers", toggle_markers_func)
