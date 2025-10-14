extends Node3D

# Script to apply saved nail color from GameManager to right hand nails
# Create a new Node3D child inside the RightHand scene and attach this script to it
# This way the original hand.gd script remains intact on the root node

var nail_mesh: MeshInstance3D
var nail_material: StandardMaterial3D

func _ready() -> void:
	# Wait a frame to ensure everything is loaded
	await get_tree().process_frame

	_find_nail_mesh()
	_apply_saved_color()

	# Listen for color changes
	if GameManager:
		GameManager.nail_color_changed.connect(_on_nail_color_changed)

func _find_nail_mesh() -> void:
	# Get parent (which should be the RightHand root node)
	var hand_root = get_parent()
	if not hand_root:
		push_warning("RightHandNails: No parent node found")
		return

	# Try to find right hand nail mesh relative to parent
	var possible_paths = [
		"Hand_R_Nails/Armature/Skeleton3D/mesh_Hand_Nails_R",
		"Hand_Nails_low_R/Armature/Skeleton3D/mesh_Hand_Nails_low_R"
	]

	for path in possible_paths:
		nail_mesh = hand_root.get_node_or_null(path)
		if nail_mesh:
			print("RightHandNails: Found nail mesh at: ", path)
			break

	if not nail_mesh:
		push_warning("RightHandNails: Could not find nail mesh")

func _apply_saved_color() -> void:
	if not nail_mesh or not GameManager:
		return

	var saved_color = GameManager.get_nail_color()

	# Get or create material for surface 0 (nails)
	var existing_mat = nail_mesh.get_surface_override_material(0)
	if existing_mat and existing_mat is StandardMaterial3D:
		nail_material = existing_mat.duplicate()
	else:
		nail_material = StandardMaterial3D.new()
		nail_material.metallic = 0.7
		nail_material.roughness = 0.2
		nail_material.emission_enabled = true

	# Apply color
	nail_material.albedo_color = saved_color
	nail_material.emission = saved_color * 0.3
	nail_mesh.set_surface_override_material(1, nail_material) # that is accualy the nail 

	print("RightHandNails: Applied saved color: ", saved_color)

func _on_nail_color_changed(new_color: Color) -> void:
	if nail_material:
		nail_material.albedo_color = new_color
		nail_material.emission = new_color * 0.3
		print("RightHandNails: Color updated to: ", new_color)
