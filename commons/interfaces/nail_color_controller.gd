extends Node3D

# @identity
# essence: f(RGB) -> material.albedo_color on VR hand mesh surfaces — ValueMapper3D maps 3D input to nail/skin color
# desire: to paint your own hands in VR, watching color flow onto nails or skin as you move sliders through RGB space
# critical_parameter: target_surface — 0 selects nails (metallic, emissive), 1 selects skin (matte, no glow), completely different aesthetics
# triggers: ValueMapper3D.values_changed fires on any slider movement; GameManager persists color across scene transitions
# emerges: the preview cube becomes an accidental color swatch that players use to compare colors side by side
# needs: ValueMapper3D [has]; color_preview_cube [has]; VR hand tracking [has]; palette picker [missing]
# relationships: pairs with hand_model (provides the mesh); unlocks color_sets_overview (palette awareness after personal color)
# truth: choosing your nail color is the first act of digital self-authorship — the body becomes canvas before the world does

# Controls VR hand nail colors using a ValueMapper3D
# Maps RGB values from the 3D mapper to both left and right hand nail materials

@onready var value_mapper = $ValueMapper3D
@export var debug = false
@export var target_surface: int = 0 # 0 for Nails, 1 for Skin

# These will be set dynamically in _ready since the scene can be instantiated at different levels
var right_hand: Node3D
var left_hand: Node3D

var left_hand_mesh: MeshInstance3D
var right_hand_mesh: MeshInstance3D
var nail_material_left: StandardMaterial3D
var nail_material_right: StandardMaterial3D
var color_preview_cube: MeshInstance3D

var _active_surface_index_l: int = 0
var _active_surface_index_r: int = 0

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
			if target_surface == 0:
				var saved_color = GameManager.get_nail_color()
				value_mapper.set_values(saved_color.r, saved_color.g, saved_color.b)
				_on_color_values_changed(saved_color.r, saved_color.g, saved_color.b)
				if debug:
					print("NailColorController: Loaded saved nail color from GameManager: ", saved_color)
			else:
				var saved_color = GameManager.get_hand_color()
				value_mapper.set_values(saved_color.r, saved_color.g, saved_color.b)
				_on_color_values_changed(saved_color.r, saved_color.g, saved_color.b)
				if debug:
					print("NailColorController: Loaded saved hand color from GameManager: ", saved_color)
		else:
			# Set initial color if no GameManager
			var initial = value_mapper.get_values()
			_on_color_values_changed(initial.x, initial.y, initial.z)

func _create_color_preview_cube() -> void:
	# Create a small cube that shows the current color
	color_preview_cube = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.6, 0.6, 0.1)
	color_preview_cube.mesh = box_mesh

	# Position it near the value mapper
	color_preview_cube.position = Vector3(0.3, 0.1, -0.2)

	# Create material
	var preview_material = StandardMaterial3D.new()
	preview_material.albedo_color = Color(1, 0.5, 0.7, 1)
	preview_material.metallic = 0.1
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

	if debug:
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
			if debug:
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
		if debug:
			print("NailColorController: Found left hand node")
	else:
		push_warning("NailColorController: Could not find left hand node")

	if right_hand:
		if debug:
			print("NailColorController: Found right hand node")
	else:
		push_warning("NailColorController: Could not find right hand node")

func _find_hand_meshes() -> void:
	# Find Left Hand Mesh
	if left_hand:
		var paths = []
		if target_surface == 1: # Skin
			paths = [
				"Hand_low_L/Armature/Skeleton3D/mesh_Hand_low_L",
				"Hand_L/Armature/Skeleton3D/mesh_Hand_L",
				"Hand_Glove_L/Armature/Skeleton3D/mesh_Hand_Glove_L",
				"Hand_L_Nails/Armature/Skeleton3D/mesh_Hand_Nails_L", # Fallback
				"Hand_Nails_low_L/Armature/Skeleton3D/mesh_Hand_Nails_low_L" # Fallback
			]
		else: # Nails
			paths = [
				"Hand_L_Nails/Armature/Skeleton3D/mesh_Hand_Nails_L",
				"Hand_Nails_low_L/Armature/Skeleton3D/mesh_Hand_Nails_low_L"
			]

		for path in paths:
			left_hand_mesh = left_hand.get_node_or_null(path)
			if left_hand_mesh:
				if debug:
					print("NailColorController: Found left hand mesh at: ", left_hand_mesh.get_path())
				
				# Determine surface index
				# Left Hand Mesh (Hand_Nails_L): Surface 0 = Nails, Surface 1 = Skin
				if "Hand_Nails_L" in left_hand_mesh.name:
					_active_surface_index_l = 0 if target_surface == 0 else 1
				else:
					# Other meshes (e.g. Hand_low_L) usually have skin at 0
					_active_surface_index_l = 0
				break

		if not left_hand_mesh:
			push_warning("NailColorController: Could not find left hand mesh")

	# Find Right Hand Mesh
	if right_hand:
		var paths = []
		if target_surface == 1: # Skin
			paths = [
				"Hand_low_R/Armature/Skeleton3D/mesh_Hand_low_R",
				"Hand_R/Armature/Skeleton3D/mesh_Hand_R",
				"Hand_Glove_R/Armature/Skeleton3D/mesh_Hand_Glove_R",
				"Hand_R_Nails/Armature/Skeleton3D/mesh_Hand_Nails_R", # Fallback
				"Hand_Nails_low_R/Armature/Skeleton3D/mesh_Hand_Nails_low_R" # Fallback
			]
		else: # Nails
			paths = [
				"Hand_R_Nails/Armature/Skeleton3D/mesh_Hand_Nails_R",
				"Hand_Nails_low_R/Armature/Skeleton3D/mesh_Hand_Nails_low_R"
			]

		for path in paths:
			right_hand_mesh = right_hand.get_node_or_null(path)
			if right_hand_mesh:
				if debug:
					print("NailColorController: Found right hand mesh at: ", right_hand_mesh.get_path())
				
				# Determine surface index
				# Right Hand Mesh (Hand_Nails_R): Surface 0 = Skin, Surface 1 = Nails
				if "Hand_Nails_R" in right_hand_mesh.name:
					_active_surface_index_r = 1 if target_surface == 0 else 0
				else:
					# Other meshes (e.g. Hand_low_R) usually have skin at 0
					_active_surface_index_r = 0
				break

		if not right_hand_mesh:
			push_warning("NailColorController: Could not find right hand mesh")

func _setup_nail_materials() -> void:
	# Create or get materials for the hand meshes
	if left_hand_mesh:
		if debug:
			print("NailColorController: Left hand mesh has %d surfaces" % left_hand_mesh.get_surface_override_material_count())

		# Get existing material or create new one
		var existing_mat = left_hand_mesh.get_surface_override_material(_active_surface_index_l)
		if existing_mat and existing_mat is StandardMaterial3D:
			nail_material_left = existing_mat.duplicate()
		else:
			nail_material_left = StandardMaterial3D.new()
			if target_surface == 0: # Nails
				nail_material_left.albedo_color = Color(1, 0.5, 0.7, 1)
				nail_material_left.metallic = 0.7
				nail_material_left.roughness = 0.2
				nail_material_left.emission_enabled = true
			else: # Skin
				nail_material_left.albedo_color = Color(0.8, 0.6, 0.5, 1)
				nail_material_left.metallic = 0.0
				nail_material_left.roughness = 0.8
				nail_material_left.emission_enabled = false

		left_hand_mesh.set_surface_override_material(_active_surface_index_l, nail_material_left)
		if debug:
			print("NailColorController: Left hand material setup complete on surface %d" % _active_surface_index_l)

	if right_hand_mesh:
		if debug:
			print("NailColorController: Right hand mesh has %d surfaces" % right_hand_mesh.get_surface_override_material_count())

		# Get existing material or create new one
		var existing_mat = right_hand_mesh.get_surface_override_material(_active_surface_index_r)
		if existing_mat and existing_mat is StandardMaterial3D:
			nail_material_right = existing_mat.duplicate()
		else:
			nail_material_right = StandardMaterial3D.new()
			if target_surface == 0: # Nails
				nail_material_right.albedo_color = Color(1, 0.5, 0.7, 1)
				nail_material_right.metallic = 0.7
				nail_material_right.roughness = 0.2
				nail_material_right.emission_enabled = true
			else: # Skin
				nail_material_right.albedo_color = Color(0.8, 0.6, 0.5, 1)
				nail_material_right.metallic = 0.0
				nail_material_right.roughness = 0.8
				nail_material_right.emission_enabled = false

		right_hand_mesh.set_surface_override_material(_active_surface_index_r, nail_material_right)
		if debug:
			print("NailColorController: Right hand material setup complete on surface %d" % _active_surface_index_r)

func _on_color_values_changed(r: float, g: float, b: float) -> void:
	var color = Color(r, g, b, 1.0)
	


	# Save to GameManager for persistence across scenes
	if GameManager:
		if target_surface == 0:
			GameManager.set_nail_color(color)
		else:
			GameManager.set_hand_color(color)

	# Update color preview cube
	if color_preview_cube:
		var preview_mat = color_preview_cube.material_override as StandardMaterial3D
		if preview_mat:
			preview_mat.albedo_color = color
			if target_surface == 0:
				preview_mat.emission = color * 0.3
			else:
				preview_mat.emission = Color.BLACK # No emission for skin usually

	# Update left hand
	if nail_material_left:
		nail_material_left.albedo_color = color
		if target_surface == 0:
			nail_material_left.emission = color * 0.3
		if debug:
			print("NailColorController: Updated left color to ", color)
	else:
		if debug:
			print("NailColorController: WARNING - nail_material_left is null!")

	# Update right hand
	if nail_material_right:
		nail_material_right.albedo_color = color
		if target_surface == 0:
			nail_material_right.emission = color * 0.3
		if debug:
			print("NailColorController: Updated right color to ", color)
	else:
		if debug:
			print("NailColorController: WARNING - nail_material_right is null!")

	# Verify the materials are still applied to the meshes
	if left_hand_mesh:
		var current_mat = left_hand_mesh.get_surface_override_material(_active_surface_index_l)
		if current_mat != nail_material_left:
			if debug:
				print("NailColorController: WARNING - Left hand material changed! Reapplying...")
			left_hand_mesh.set_surface_override_material(_active_surface_index_l, nail_material_left)

	if right_hand_mesh:
		var current_mat = right_hand_mesh.get_surface_override_material(_active_surface_index_r)
		if current_mat != nail_material_right:
			if debug:
				print("NailColorController: WARNING - Right hand material changed! Reapplying...")
		right_hand_mesh.set_surface_override_material(_active_surface_index_r, nail_material_right)

# Public API for programmatic control
func set_nail_color(color: Color) -> void:
	if value_mapper:
		value_mapper.set_values(color.r, color.g, color.b)

func get_nail_color() -> Color:
	if value_mapper:
		var values = value_mapper.get_values()
		return Color(values.x, values.y, values.z, 1.0)
	return Color.WHITE
