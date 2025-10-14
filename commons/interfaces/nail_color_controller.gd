extends Node3D

# Controls VR hand nail colors using a ValueMapper3D
# Maps RGB values from the 3D mapper to both left and right hand nail materials

@onready var value_mapper = $ValueMapper3D

# These will be set dynamically in _ready since the scene can be instantiated at different levels
var right_hand: Node3D
var left_hand: Node3D

var left_hand_mesh: MeshInstance3D
var right_hand_mesh: MeshInstance3D
var nail_material_left: StandardMaterial3D
var nail_material_right: StandardMaterial3D
var color_preview_cube: MeshInstance3D

func _ready() -> void:
	# Create color preview cube
	_create_color_preview_cube()

	# Wait a frame to ensure VR scene is loaded
	await get_tree().process_frame

	# Find the hand nodes dynamically
	_find_hand_nodes()
	_find_hand_meshes()
	_setup_nail_materials()

	if value_mapper:
		value_mapper.values_changed.connect(_on_color_values_changed)

		# Load saved color from GameManager
		if GameManager:
			var saved_color = GameManager.get_nail_color()
			value_mapper.set_values(saved_color.r, saved_color.g, saved_color.b)
			_on_color_values_changed(saved_color.r, saved_color.g, saved_color.b)
			print("NailColorController: Loaded saved color from GameManager: ", saved_color)
		else:
			# Set initial color if no GameManager
			var initial = value_mapper.get_values()
			_on_color_values_changed(initial.x, initial.y, initial.z)

func _create_color_preview_cube() -> void:
	# Create a small cube that shows the current color
	color_preview_cube = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.15, 0.15, 0.15)
	color_preview_cube.mesh = box_mesh

	# Position it near the value mapper
	color_preview_cube.position = Vector3(0, -0.4, 0)

	# Create material
	var preview_material = StandardMaterial3D.new()
	preview_material.albedo_color = Color(1, 0.5, 0.7, 1)
	preview_material.metallic = 0.7
	preview_material.roughness = 0.2
	preview_material.emission_enabled = true
	preview_material.emission = Color(1, 0.5, 0.7, 1) * 0.3
	color_preview_cube.material_override = preview_material

	add_child(color_preview_cube)

	# Add a label
	var label = Label3D.new()
	label.text = "Preview"
	label.position = Vector3(0, -0.55, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.modulate = Color(1, 1, 1, 0.8)
	label.outline_size = 3
	label.outline_modulate = Color(0, 0, 0, 1)
	label.scale = Vector3.ONE * 0.08
	add_child(label)

	print("NailColorController: Color preview cube created")

func _find_hand_nodes() -> void:
	# Try to find XROrigin3D from different possible locations
	var xr_origin: Node3D = null

	# Try common relative paths
	var possible_paths = [
		"../../XROrigin3D",  # When instantiated in grid system
	]

	for path in possible_paths:
		xr_origin = get_node_or_null(path)
		if xr_origin:
			print("NailColorController: Found XROrigin3D at: ", path)
			break

	if not xr_origin:
		# Try finding it in the tree
		xr_origin = get_tree().get_first_node_in_group("xr_origin")

	if not xr_origin:
		push_warning("NailColorController: Could not find XROrigin3D")
		return

	# Get the hand nodes
	left_hand = xr_origin.get_node_or_null("LeftHand/XRToolsCollisionHand/LeftHand")
	right_hand = xr_origin.get_node_or_null("RightHand/XRToolsCollisionHand/RightHand")

	if left_hand:
		print("NailColorController: Found left hand node")
	else:
		push_warning("NailColorController: Could not find left hand node")

	if right_hand:
		print("NailColorController: Found right hand node")
	else:
		push_warning("NailColorController: Could not find right hand node")

func _find_hand_meshes() -> void:
	# Try to find left hand nail mesh
	if left_hand:
		# Try multiple possible paths
		var possible_paths = [
			"Hand_L_Nails/Armature/Skeleton3D/mesh_Hand_Nails_L",
			"Hand_Nails_low_L/Armature/Skeleton3D/mesh_Hand_Nails_low_L",
		]

		for path in possible_paths:
			left_hand_mesh = left_hand.get_node_or_null(path)
			if left_hand_mesh:
				print("NailColorController: Found left hand mesh at: ", left_hand_mesh.get_path())
				break

		if not left_hand_mesh:
			push_warning("NailColorController: Could not find left hand nail mesh")
			# Print available children for debugging
			print("NailColorController: Available children in LeftHand:")
			for child in left_hand.get_children():
				print("  - ", child.name)
	else:
		push_warning("NailColorController: Left hand node not found")

	# Try to find right hand nail mesh
	if right_hand:
		# Try multiple possible paths
		var possible_paths = [
			"Hand_R_Nails/Armature/Skeleton3D/mesh_Hand_Nails_R",
			"Hand_Nails_low_R/Armature/Skeleton3D/mesh_Hand_Nails_low_R"
		]

		for path in possible_paths:
			right_hand_mesh = right_hand.get_node_or_null(path)
			if right_hand_mesh:
				print("NailColorController: Found right hand mesh at: ", right_hand_mesh.get_path())
				break

		if not right_hand_mesh:
			push_warning("NailColorController: Could not find right hand nail mesh")
			# Print available children for debugging
			print("NailColorController: Available children in RightHand:")
			for child in right_hand.get_children():
				print("  - ", child.name)
	else:
		push_warning("NailColorController: Right hand node not found")

func _setup_nail_materials() -> void:
	# Create or get materials for the nail meshes
	# Surface 0 = Nails, Surface 1 = Hand skin
	if left_hand_mesh:
		print("NailColorController: Left hand mesh has %d surfaces" % left_hand_mesh.get_surface_override_material_count())

		# Get existing material or create new one for surface 0 (nails)
		var existing_mat = left_hand_mesh.get_surface_override_material(0)
		if existing_mat and existing_mat is StandardMaterial3D:
			nail_material_left = existing_mat.duplicate()
		else:
			nail_material_left = StandardMaterial3D.new()
			nail_material_left.albedo_color = Color(1, 0.5, 0.7, 1)  # Default pink
			nail_material_left.metallic = 0.7
			nail_material_left.roughness = 0.2
			nail_material_left.emission_enabled = true

		left_hand_mesh.set_surface_override_material(0, nail_material_left)
		print("NailColorController: Left nail material setup complete on surface 0")

	if right_hand_mesh:
		print("NailColorController: Right hand mesh has %d surfaces" % right_hand_mesh.get_surface_override_material_count())

		# Get existing material or create new one for surface 0 (nails)
		var existing_mat = right_hand_mesh.get_surface_override_material(0)
		if existing_mat and existing_mat is StandardMaterial3D:
			nail_material_right = existing_mat.duplicate()
		else:
			nail_material_right = StandardMaterial3D.new()
			nail_material_right.albedo_color = Color(1, 0.5, 0.7, 1)  # Default pink
			nail_material_right.metallic = 0.7
			nail_material_right.roughness = 0.2
			nail_material_right.emission_enabled = true

		right_hand_mesh.set_surface_override_material(1, nail_material_right)
		print("NailColorController: Right nail material setup complete on surface 0")

func _on_color_values_changed(r: float, g: float, b: float) -> void:
	var color = Color(r, g, b, 1.0)

	# Save to GameManager for persistence across scenes
	if GameManager:
		GameManager.set_nail_color(color)

	# Update color preview cube
	if color_preview_cube:
		var preview_mat = color_preview_cube.material_override as StandardMaterial3D
		if preview_mat:
			preview_mat.albedo_color = color
			preview_mat.emission = color * 0.3

	# Update left hand nails
	if nail_material_left:
		nail_material_left.albedo_color = color
		nail_material_left.emission = color * 0.3
		print("NailColorController: Updated left nail color to ", color)
	else:
		print("NailColorController: WARNING - nail_material_left is null!")

	# Update right hand nails
	if nail_material_right:
		nail_material_right.albedo_color = color
		nail_material_right.emission = color * 0.3
		print("NailColorController: Updated right nail color to ", color)
	else:
		print("NailColorController: WARNING - nail_material_right is null!")

	# Verify the materials are still applied to the meshes
	if left_hand_mesh:
		var current_mat = left_hand_mesh.get_surface_override_material(0)
		if current_mat != nail_material_left:
			print("NailColorController: WARNING - Left hand material changed! Reapplying...")
			left_hand_mesh.set_surface_override_material(0, nail_material_left)

	if right_hand_mesh:
		var current_mat = right_hand_mesh.get_surface_override_material(0)
		if current_mat != nail_material_right:
			print("NailColorController: WARNING - Right hand material changed! Reapplying...")
			right_hand_mesh.set_surface_override_material(1, nail_material_right)

# Public API for programmatic control
func set_nail_color(color: Color) -> void:
	if value_mapper:
		value_mapper.set_values(color.r, color.g, color.b)

func get_nail_color() -> Color:
	if value_mapper:
		var values = value_mapper.get_values()
		return Color(values.x, values.y, values.z, 1.0)
	return Color.WHITE
