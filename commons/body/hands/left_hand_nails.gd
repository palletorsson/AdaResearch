extends Node3D

# Script to apply saved nail and skin color from GameManager to left hand
# Create a new Node3D child inside the LeftHand scene and attach this script to it
# This way the original hand.gd script remains intact on the root node

var hand_mesh: MeshInstance3D
var nail_material: StandardMaterial3D
var skin_material: StandardMaterial3D
@export var debug = false 

var surface_skin_idx: int = -1
var surface_nails_idx: int = -1

func _ready() -> void:
	print("LeftHandNails: _ready called")
	# Wait a frame to ensure everything is loaded
	await get_tree().process_frame

	_find_hand_mesh()
	_find_surface_indices()
	_apply_saved_colors()

	# Listen for color changes
	if GameManager:
		print("LeftHandNails: Connecting to GameManager signals")
		if GameManager.has_signal("nail_color_changed"):
			GameManager.nail_color_changed.connect(_on_nail_color_changed)
		if GameManager.has_signal("hand_color_changed"):
			GameManager.hand_color_changed.connect(_on_skin_color_changed)

func _find_surface_indices() -> void:
	if not hand_mesh or not hand_mesh.mesh:
		return
		
	for i in range(hand_mesh.mesh.get_surface_count()):
		var s_name = hand_mesh.mesh.surface_get_name(i)
		if s_name == "Hand":
			surface_skin_idx = i
		elif s_name.begins_with("Nails"):
			surface_nails_idx = i
			
	# Fallback: If Skin not found but Nails found, and there are exactly 2 surfaces, pick the other one.
	if surface_skin_idx == -1 and surface_nails_idx != -1 and hand_mesh.mesh.get_surface_count() == 2:
		surface_skin_idx = 1 - surface_nails_idx
			
	if debug:
		print("LeftHandNails: Surface indices found - Skin: ", surface_skin_idx, ", Nails: ", surface_nails_idx)

func _find_hand_mesh() -> void:
	# Get parent (which should be the LeftHand root node)
	var hand_root = get_parent()
	if not hand_root:
		push_warning("LeftHandNails: No parent node found")
		return

	if debug:
		print("LeftHandNails: Parent node is ", hand_root.name)

	# Try to find left hand mesh relative to parent
	var possible_paths = [
		"Hand_L_Nails/Armature/Skeleton3D/mesh_Hand_Nails_L",
		"Hand_Nails_low_L/Armature/Skeleton3D/mesh_Hand_Nails_low_L",
	]

	for path in possible_paths:
		hand_mesh = hand_root.get_node_or_null(path)
		if hand_mesh:
			if debug:
				print("LeftHandNails: Found hand mesh at: ", path)
			break

	if not hand_mesh:
		push_warning("LeftHandNails: Could not find hand mesh")

func _apply_saved_colors() -> void:
	if not hand_mesh or not GameManager:
		return

	# --- Nails ---
	var saved_nail_color = GameManager.get_nail_color()
	
	if surface_nails_idx != -1:
		# Get or create material for nails
		var existing_nail_mat = hand_mesh.get_surface_override_material(surface_nails_idx)
		if existing_nail_mat and existing_nail_mat is StandardMaterial3D:
			nail_material = existing_nail_mat.duplicate()
		else:
			# Try getting from mesh if no override
			var mesh_mat = hand_mesh.mesh.surface_get_material(surface_nails_idx)
			if mesh_mat and mesh_mat is StandardMaterial3D:
				nail_material = mesh_mat.duplicate()
			else:
				nail_material = StandardMaterial3D.new()
				nail_material.metallic = 0.7
				nail_material.roughness = 0.2
				nail_material.emission_enabled = true

		# Apply nail color
		nail_material.albedo_color = saved_nail_color
		nail_material.emission = saved_nail_color * 0.3
		hand_mesh.set_surface_override_material(surface_nails_idx, nail_material)
	
	# --- Skin ---
	var saved_skin_color = GameManager.get_hand_color()
	
	if surface_skin_idx != -1:
		# Get or create material for skin
		var existing_skin_mat = hand_mesh.get_surface_override_material(surface_skin_idx)
		if existing_skin_mat and existing_skin_mat is StandardMaterial3D:
			skin_material = existing_skin_mat.duplicate()
		else:
			# If no override, try to get the mesh material
			var mesh_mat = hand_mesh.mesh.surface_get_material(surface_skin_idx)
			if mesh_mat and mesh_mat is StandardMaterial3D:
				skin_material = mesh_mat.duplicate()
			else:
				skin_material = StandardMaterial3D.new()
				skin_material.roughness = 0.55
				skin_material.cull_mode = BaseMaterial3D.CULL_DISABLED

		# Apply skin color
		skin_material.albedo_color = saved_skin_color
		hand_mesh.set_surface_override_material(surface_skin_idx, skin_material)

	if debug: 
		print("LeftHandNails: Applied saved colors. Nails: ", saved_nail_color, " Skin: ", saved_skin_color)

func _on_nail_color_changed(new_color: Color) -> void:
	if nail_material:
		nail_material.albedo_color = new_color
		nail_material.emission = new_color * 0.3
		# Re-apply to ensure it's the active override
		if hand_mesh and surface_nails_idx != -1:
			hand_mesh.set_surface_override_material(surface_nails_idx, nail_material)
		if debug:
			print("LeftHandNails: Nail color updated to: ", new_color)

func _on_skin_color_changed(new_color: Color) -> void:
	if skin_material:
		skin_material.albedo_color = new_color
		# Re-apply to ensure it's the active override
		if hand_mesh and surface_skin_idx != -1:
			hand_mesh.set_surface_override_material(surface_skin_idx, skin_material)
		if debug:
			print("LeftHandNails: Skin color updated to: ", new_color)
