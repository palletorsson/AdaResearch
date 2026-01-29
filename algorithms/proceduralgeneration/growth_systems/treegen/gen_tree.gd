extends Node3D

# Direct reference to XR camera using relative path
@onready var vr_camera = $"../XROrigin3D/XRCamera3D"

# Generation parameters
@export var generation_distance := 50.0
@export var removal_distance := 60.0
@export var max_trees := 25
@export var min_tree_spacing := 10.0
@export var forest_size := Vector2(200.0, 200.0)
@export var generation_period := 0.5  # How often to check for new trees (seconds)

# Tree appearance parameters
@export_category("Tree Appearance")
@export_color_no_alpha var primary_color := Color(0.95, 0.3, 0.3) # Red from reference image
@export_color_no_alpha var secondary_color := Color(0.85, 0.2, 0.2) # Darker red for variation
@export var metallic := 0.1
@export var roughness := 0.7
@export var emission_strength := 0.2

# Tracking variables
var active_trees := {}  # Dictionary of active trees: key = tree ID, value = tree node
var tree_positions := {}  # Dictionary to track tree positions: key = tree ID, value = position
var next_tree_id := 0
var generation_timer := 0.0

# Materials
var primary_material: StandardMaterial3D
var secondary_material: StandardMaterial3D

func _ready():
	# Create materials
	create_materials()
	
	# Verify VR camera reference
	if not vr_camera:
		push_error("XRCamera3D not found at path ../XROrigin3D/XRCamera3D - trees won't generate")
	else:
		print("Tree generator initialized with XR camera: " + vr_camera.name)

func _process(delta):
	# Skip processing if no camera reference
	if not vr_camera:
		return
		
	# Update generation timer
	generation_timer += delta
	
	# Check if it's time to generate/remove trees
	if generation_timer >= generation_period:
		generation_timer = 0.0
		update_trees()

func update_trees():
	# Get camera position (player's viewpoint)
	var camera_pos = vr_camera.global_position
	
	# Check existing trees and remove those that are too far
	var trees_to_remove = []
	for tree_id in active_trees:
		var tree_pos = tree_positions[tree_id]
		var distance = camera_pos.distance_to(tree_pos)
		
		if distance > removal_distance:
			trees_to_remove.append(tree_id)
	
	# Remove far trees
	for tree_id in trees_to_remove:
		remove_tree(tree_id)
	
	# Generate new trees if we haven't reached the maximum
	if active_trees.size() < max_trees:
		generate_trees_around_camera()

func generate_trees_around_camera():
	# Get camera position
	var camera_pos = vr_camera.global_position
	
	# Try to place new trees
	var attempts = 5  # Limit attempts to avoid infinite loops
	var trees_added = 0
	var max_to_add = max_trees - active_trees.size()
	
	while trees_added < max_to_add and attempts > 0:
		attempts -= 1
		
		# Generate random position within generation distance
		var angle = randf() * TAU
		var distance = randf_range(min_tree_spacing, generation_distance)
		var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		var new_pos = camera_pos + offset
		
		# Adjust Y position to be ground level (assuming camera is above ground)
		new_pos.y = 0  # Or use your terrain height function if available
		
		# Check if position is within forest bounds
		if abs(new_pos.x) > forest_size.x/2 or abs(new_pos.z) > forest_size.y/2:
			continue
		
		# Check if too close to existing trees
		var too_close = false
		for existing_id in tree_positions:
			var existing_pos = tree_positions[existing_id]
			if new_pos.distance_to(existing_pos) < min_tree_spacing:
				too_close = true
				break
		
		if too_close:
			continue
		
		# Create a new tree
		create_tree(new_pos)
		trees_added += 1

func create_tree(position: Vector3):
	# Create a tree at the specified position
	var tree = Node3D.new()
	var tree_id = next_tree_id
	next_tree_id += 1
	
	tree.name = "GeometricTree_" + str(tree_id)
	
	# Generate the geometric tree structure
	var tree_style = randi() % 2  # 0: Simple blocks, 1: Complex cluster
	
	if tree_style == 0:
		generate_simple_block_tree(tree)
	else:
		generate_complex_block_cluster(tree)
	
	# Position the tree
	tree.global_position = position
	# Random rotation for variety
	tree.rotation.y = randf() * TAU
	
	# Add to scene
	add_child(tree)
	
	# Track the tree
	active_trees[tree_id] = tree
	tree_positions[tree_id] = position

func remove_tree(tree_id: int):
	# Remove a tree
	if active_trees.has(tree_id):
		var tree = active_trees[tree_id]
		tree.queue_free()
		active_trees.erase(tree_id)
		tree_positions.erase(tree_id)

func create_materials():
	# Primary material (most blocks)
	primary_material = StandardMaterial3D.new()
	primary_material.albedo_color = primary_color
	primary_material.metallic = metallic
	primary_material.roughness = roughness
	primary_material.emission_enabled = true
	primary_material.emission = primary_color
	primary_material.emission_energy_multiplier = emission_strength
	
	# Secondary material (some blocks for variation)
	secondary_material = StandardMaterial3D.new()
	secondary_material.albedo_color = secondary_color
	secondary_material.metallic = metallic
	secondary_material.roughness = roughness
	secondary_material.emission_enabled = true
	secondary_material.emission = secondary_color
	secondary_material.emission_energy_multiplier = emission_strength * 0.7

func generate_simple_block_tree(parent):
	# Create a simple geometric tree using blocks
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Main trunk/base
	var trunk = MeshInstance3D.new()
	var trunk_mesh = BoxMesh.new()
	trunk_mesh.size = Vector3(1.0, rng.randf_range(2.0, 4.0), 1.0)
	trunk.mesh = trunk_mesh
	trunk.material_override = primary_material
	
	# Position trunk so base is at origin
	trunk.position.y = trunk_mesh.size.y / 2
	
	parent.add_child(trunk)
	
	# Add some primary blocks
	var num_blocks = rng.randi_range(3, 6)
	
	for i in range(num_blocks):
		var block = MeshInstance3D.new()
		var block_mesh = BoxMesh.new()
		
		# Size
		var block_size = Vector3(
			rng.randf_range(1.0, 3.0),
			rng.randf_range(1.0, 3.0),
			rng.randf_range(1.0, 3.0)
		)
		block_mesh.size = block_size
		block.mesh = block_mesh
		
		# Position above trunk with some randomness
		block.position = Vector3(
			rng.randf_range(-1.5, 1.5),
			trunk_mesh.size.y + rng.randf_range(0.5, 3.0),
			rng.randf_range(-1.5, 1.5)
		)
		
		# Random rotation
		block.rotation_degrees = Vector3(
			rng.randf_range(-15, 15),
			rng.randf_range(0, 360),
			rng.randf_range(-15, 15)
		)
		
		block.material_override = primary_material if rng.randf() > 0.3 else secondary_material
		
		parent.add_child(block)
		
		# Add smaller detail blocks
		if rng.randf() > 0.5:
			var num_details = rng.randi_range(1, 3)
			for j in range(num_details):
				var detail = MeshInstance3D.new()
				var detail_mesh = BoxMesh.new()
				
				# Size - smaller
				var detail_size = Vector3(
					rng.randf_range(0.3, 0.8),
					rng.randf_range(0.3, 0.8),
					rng.randf_range(0.3, 0.8)
				)
				detail_mesh.size = detail_size
				detail.mesh = detail_mesh
				
				# Position relative to parent block
				detail.position = Vector3(
					block_size.x/2 * rng.randf_range(-0.9, 0.9),
					block_size.y/2 * rng.randf_range(-0.9, 0.9),
					block_size.z/2 * rng.randf_range(-0.9, 0.9)
				)
				
				detail.material_override = secondary_material if rng.randf() > 0.3 else primary_material
				
				block.add_child(detail)

func generate_complex_block_cluster(parent):
	# Create a more complex block cluster similar to the reference image
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Lower base/trunk
	var base = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(1.0, rng.randf_range(1.0, 2.0), 1.0)
	base.mesh = base_mesh
	base.material_override = secondary_material
	
	# Position base so bottom is at origin
	base.position.y = base_mesh.size.y / 2
	
	parent.add_child(base)
	
	# Main cluster of blocks
	var num_main_blocks = rng.randi_range(5, 9)
	var cluster_center = Vector3(0, base_mesh.size.y + 2.0, 0)
	
	# Create main large blocks
	for i in range(num_main_blocks):
		var block = MeshInstance3D.new()
		var block_mesh = BoxMesh.new()
		
		# Size - larger main blocks
		var block_size = Vector3(
			rng.randf_range(1.5, 4.0),
			rng.randf_range(1.5, 4.0),
			rng.randf_range(1.5, 4.0)
		)
		block_mesh.size = block_size
		block.mesh = block_mesh
		
		# Position around cluster center with some structure
		var angle = rng.randf() * TAU
		var radius = rng.randf_range(0.5, 3.0)
		var height_offset = rng.randf_range(-1.0, 3.0)
		
		block.position = cluster_center + Vector3(
			cos(angle) * radius,
			height_offset,
			sin(angle) * radius
		)
		
		# Random rotation
		block.rotation_degrees = Vector3(
			rng.randf_range(-10, 10),
			rng.randf_range(0, 360),
			rng.randf_range(-10, 10)
		)
		
		block.material_override = primary_material
		
		parent.add_child(block)
	
	# Add connecting structures between blocks
	var num_connectors = rng.randi_range(3, 7)
	
	for i in range(num_connectors):
		var connector = MeshInstance3D.new()
		
		# Different connector types
		var type = rng.randi() % 3
		
		match type:
			0: # Thin box
				var connector_mesh = BoxMesh.new()
				connector_mesh.size = Vector3(
					rng.randf_range(0.3, 0.8),
					rng.randf_range(0.3, 0.8),
					rng.randf_range(2.0, 5.0)
				)
				connector.mesh = connector_mesh
			1: # Vertical column
				var connector_mesh = BoxMesh.new()
				connector_mesh.size = Vector3(
					rng.randf_range(0.3, 0.8),
					rng.randf_range(2.0, 5.0),
					rng.randf_range(0.3, 0.8)
				)
				connector.mesh = connector_mesh
			2: # Cross shape (using multiple children)
				var main_mesh = BoxMesh.new()
				main_mesh.size = Vector3(
					rng.randf_range(0.3, 0.6),
					rng.randf_range(0.3, 0.6),
					rng.randf_range(2.0, 4.0)
				)
				connector.mesh = main_mesh
				
				# Add crossing piece
				var cross_piece = MeshInstance3D.new()
				var cross_mesh = BoxMesh.new()
				cross_mesh.size = Vector3(
					rng.randf_range(1.5, 3.0),
					rng.randf_range(0.3, 0.6),
					rng.randf_range(0.3, 0.6)
				)
				cross_piece.mesh = cross_mesh
				cross_piece.material_override = secondary_material
				connector.add_child(cross_piece)
		
		# Position around cluster
		connector.position = cluster_center + Vector3(
			rng.randf_range(-3.0, 3.0),
			rng.randf_range(-1.0, 3.0),
			rng.randf_range(-3.0, 3.0)
		)
		
		# Rotation
		connector.rotation_degrees = Vector3(
			rng.randf_range(-10, 10),
			rng.randf_range(0, 360),
			rng.randf_range(-10, 10)
		)
		
		connector.material_override = secondary_material
		
		parent.add_child(connector)
	
	# Add small detail blocks
	var num_details = rng.randi_range(8, 15)
	
	for i in range(num_details):
		var detail = MeshInstance3D.new()
		var detail_mesh = BoxMesh.new()
		
		# Size - smaller detail blocks
		var detail_size = Vector3(
			rng.randf_range(0.3, 1.0),
			rng.randf_range(0.3, 1.0),
			rng.randf_range(0.3, 1.0)
		)
		detail_mesh.size = detail_size
		detail.mesh = detail_mesh
		
		# Position around and between the main blocks
		detail.position = cluster_center + Vector3(
			rng.randf_range(-4.0, 4.0),
			rng.randf_range(-2.0, 4.0),
			rng.randf_range(-4.0, 4.0)
		)
		
		# Random rotation
		detail.rotation_degrees = Vector3(
			rng.randf_range(-15, 15),
			rng.randf_range(0, 360),
			rng.randf_range(-15, 15)
		)
		
		# Alternate between materials
		detail.material_override = secondary_material if rng.randf() > 0.5 else primary_material
		
		parent.add_child(detail)
