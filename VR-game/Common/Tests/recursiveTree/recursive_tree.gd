extends Node3D

# Parameters for tree generation
@export_category("Tree Structure")
@export var num_main_branches := 5
@export var max_sub_branches := 4
@export var branch_length_min := 1.5
@export var branch_length_max := 4.0
@export var branch_width_min := 0.8
@export var branch_width_max := 2.5
@export var branch_height_min := 0.8
@export var branch_height_max := 2.5
@export var trunk_height := 5.0
@export var trunk_width := 1.5
@export var random_seed := 42

@export_category("Tree Appearance")
@export_color_no_alpha var primary_color := Color(0.95, 0.3, 0.3) # Red color from the image
@export_color_no_alpha var secondary_color := Color(0.85, 0.2, 0.2) # Slightly darker red for variation
@export_color_no_alpha var trunk_color := Color(0.8, 0.3, 0.3)
@export var metallic := 0.1
@export var roughness := 0.7
@export var emission_strength := 0.2

# Materials
var primary_material: StandardMaterial3D
var secondary_material: StandardMaterial3D
var trunk_material: StandardMaterial3D

# Called when the node enters the scene tree for the first time
func _ready():
	# Set the random seed
	seed(random_seed)
	
	# Create materials
	create_materials()
	
	# Generate the tree
	generate_tree()

# Creates materials for the tree
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
	
	# Trunk material
	trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = trunk_color
	trunk_material.metallic = metallic
	trunk_material.roughness = roughness + 0.1
	trunk_material.emission_enabled = true
	trunk_material.emission = trunk_color
	trunk_material.emission_energy_multiplier = emission_strength * 0.5

# Generates the complete tree structure
func generate_tree():
	# Create root node for the tree
	var tree_root = Node3D.new()
	tree_root.name = "GeometricTree"
	add_child(tree_root)
	
	# Create trunk
	var trunk = create_trunk()
	tree_root.add_child(trunk)
	
	# Generate main branches
	var branch_origin = Vector3(0, trunk_height - trunk_width/2, 0)
	generate_branches(tree_root, branch_origin, num_main_branches, 0, 3)

# Creates the trunk of the tree
func create_trunk():
	var trunk_node = Node3D.new()
	trunk_node.name = "Trunk"
	
	# Create the main trunk block
	var trunk_mesh = BoxMesh.new()
	trunk_mesh.size = Vector3(trunk_width, trunk_height, trunk_width)
	
	var trunk_instance = MeshInstance3D.new()
	trunk_instance.mesh = trunk_mesh
	trunk_instance.material_override = trunk_material
	trunk_instance.position.y = trunk_height / 2
	
	trunk_node.add_child(trunk_instance)
	
	# Maybe add some smaller blocks to the trunk for detail
	var num_details = randi() % 4 + 1
	for i in range(num_details):
		var detail = MeshInstance3D.new()
		var detail_mesh = BoxMesh.new()
		
		var detail_size = Vector3(
			trunk_width * randf_range(0.3, 0.6),
			trunk_width * randf_range(0.3, 0.6),
			trunk_width * randf_range(0.3, 0.6)
		)
		detail_mesh.size = detail_size
		
		detail.mesh = detail_mesh
		
		# Position somewhere on the trunk
		var height_pos = randf_range(trunk_width, trunk_height - trunk_width)
		var angle = randf_range(0, TAU)
		var radius = trunk_width/2 * 0.9
		
		detail.position = Vector3(
			cos(angle) * radius,
			height_pos,
			sin(angle) * radius
		)
		
		# Randomly choose material
		detail.material_override = primary_material if randf() > 0.3 else secondary_material
		
		trunk_node.add_child(detail)
	
	return trunk_node

# Recursively generates branches
func generate_branches(parent, origin_point, num_branches, current_depth, max_depth):
	if current_depth >= max_depth:
		return
	
	for i in range(num_branches):
		# Create a branch node
		var branch = Node3D.new()
		branch.name = "Branch_" + str(current_depth) + "_" + str(i)
		parent.add_child(branch)
		
		# Determine branch size
		var branch_width = randf_range(branch_width_min, branch_width_max) * (1.0 - current_depth * 0.2)
		var branch_height = randf_range(branch_height_min, branch_height_max) * (1.0 - current_depth * 0.2)
		var branch_length = randf_range(branch_length_min, branch_length_max) * (1.0 - current_depth * 0.15)
		
		# Create branch mesh
		var branch_mesh = BoxMesh.new()
		branch_mesh.size = Vector3(branch_width, branch_height, branch_length)
		
		var branch_instance = MeshInstance3D.new()
		branch_instance.mesh = branch_mesh
		
		# Choose material
		branch_instance.material_override = primary_material if randf() > 0.3 else secondary_material
		
		# Set direction, position, and rotation
		var angle
		if num_branches <= 2:
			# For binary branches, space them apart
			angle = TAU * (i / float(num_branches)) + randf_range(-0.3, 0.3)
		else:
			# Random angle for more branches
			angle = randf_range(0, TAU)
		
		# Adjust angle for more natural spreading
		var vertical_tilt = randf_range(0.2, 0.5) # Tilt upward
		
		# Calculate direction with vertical component
		var direction = Vector3(
			cos(angle),
			vertical_tilt,
			sin(angle)
		).normalized()
		
		# Position the branch
		var distance_from_origin = branch_length / 2
		var position = origin_point + direction * distance_from_origin
		branch_instance.position = position
		
		# Rotate to point in the direction
		branch_instance.look_at(position + direction, Vector3.UP)
		
		branch.add_child(branch_instance)
		
		# Maybe add some detail blocks to the branch
		if randf() > 0.4:
			add_detail_blocks(branch, branch_instance, branch_mesh.size)
		
		# Calculate the end point for sub-branches
		var end_point = position + direction * (branch_length / 2)
		
		# Generate sub-branches
		var num_sub = randi() % (max_sub_branches - current_depth) + 1
		if current_depth < 2:  # More branches at lower depths
			num_sub = randi() % max_sub_branches + 2
		
		generate_branches(branch, end_point, num_sub, current_depth + 1, max_depth)

# Adds small detail blocks to a branch
func add_detail_blocks(parent_node, branch_instance, branch_size):
	var num_details = randi() % 3 + 1
	
	for i in range(num_details):
		var detail = MeshInstance3D.new()
		var detail_mesh = BoxMesh.new()
		
		# Smaller blocks for details
		var scale_factor = randf_range(0.2, 0.5)
		var detail_size = Vector3(
			branch_size.x * scale_factor,
			branch_size.y * scale_factor,
			branch_size.z * scale_factor
		)
		detail_mesh.size = detail_size
		
		detail.mesh = detail_mesh
		
		# Position on the surface of the branch
		var axis = randi() % 3  # Which axis to project along (x, y, or z)
		var sign_factor = 1 if randf() > 0.5 else -1
		
		var relative_position = Vector3.ZERO
		
		match axis:
			0:  # X-axis
				relative_position.x = sign_factor * (branch_size.x / 2 + detail_size.x / 2 * 0.8)
				relative_position.y = randf_range(-0.4, 0.4) * branch_size.y
				relative_position.z = randf_range(-0.4, 0.4) * branch_size.z
			1:  # Y-axis
				relative_position.x = randf_range(-0.4, 0.4) * branch_size.x
				relative_position.y = sign_factor * (branch_size.y / 2 + detail_size.y / 2 * 0.8)
				relative_position.z = randf_range(-0.4, 0.4) * branch_size.z
			2:  # Z-axis
				relative_position.x = randf_range(-0.4, 0.4) * branch_size.x
				relative_position.y = randf_range(-0.4, 0.4) * branch_size.y
				relative_position.z = sign_factor * (branch_size.z / 2 + detail_size.z / 2 * 0.8)
		
		# Apply rotation of parent branch to the relative position
		var global_transform = branch_instance.global_transform
		detail.position = branch_instance.to_local(global_transform.origin + global_transform.basis * relative_position)
		
		# Match parent rotation
		detail.rotation = branch_instance.rotation
		
		# Choose material, favor secondary material for details
		detail.material_override = secondary_material if randf() > 0.4 else primary_material
		
		parent_node.add_child(detail)

# Additional function to create more complex geometric tree like in the image
func generate_complex_geometric_tree():
	# Create root node for the tree
	var tree_root = Node3D.new()
	tree_root.name = "ComplexGeometricTree"
	add_child(tree_root)
	
	# Create base
	var base = create_base()
	tree_root.add_child(base)
	
	# Create "blocks" cluster - the main feature of the image
	create_block_cluster(tree_root, Vector3(0, trunk_height, 0))

# Creates a flat base/ground
func create_base():
	var base_node = Node3D.new()
	base_node.name = "Base"
	
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(20, 0.5, 20)
	
	var base_instance = MeshInstance3D.new()
	base_instance.mesh = base_mesh
	base_instance.position.y = -0.25  # Half the height
	
	# Create a darker material for the base
	var base_material = StandardMaterial3D.new()
	base_material.albedo_color = Color(0.2, 0.2, 0.3)
	base_material.metallic = 0.1
	base_material.roughness = 0.9
	
	base_instance.material_override = base_material
	
	base_node.add_child(base_instance)
	
	return base_node

# Creates a complex cluster of blocks like in the reference image
func create_block_cluster(parent, origin_point):
	# Create a node for the cluster
	var cluster = Node3D.new()
	cluster.name = "BlockCluster"
	parent.add_child(cluster)
	
	# Main large blocks
	create_main_blocks(cluster, origin_point)
	
	# Connecting structures
	create_connecting_structures(cluster, origin_point)
	
	# Small details
	add_cluster_details(cluster, origin_point)

# Creates the main large blocks of the cluster
func create_main_blocks(parent, origin_point):
	# In the reference image, there are about 3-4 large block clusters
	var num_blocks = 4
	
	for i in range(num_blocks):
		var block_node = Node3D.new()
		block_node.name = "MainBlock_" + str(i)
		parent.add_child(block_node)
		
		# Create a cluster of connected blocks
		var num_sub_blocks = randi() % 4 + 2
		var main_position = Vector3(
			randf_range(-3, 3),
			randf_range(1, 5),
			randf_range(-3, 3)
		) + origin_point
		
		for j in range(num_sub_blocks):
			var block = MeshInstance3D.new()
			var block_mesh = BoxMesh.new()
			
			# Larger sizes for main blocks
			var block_size = Vector3(
				randf_range(2.0, 4.0),
				randf_range(2.0, 4.0),
				randf_range(2.0, 4.0)
			)
			block_mesh.size = block_size
			
			block.mesh = block_mesh
			
			# Position blocks adjacent to each other
			var offset = Vector3(
				randf_range(-1.5, 1.5),
				randf_range(-1.5, 1.5),
				randf_range(-1.5, 1.5)
			)
			
			if j == 0:
				block.position = main_position
			else:
				block.position = main_position + offset
			
			# Use primary material for most blocks
			block.material_override = primary_material
			
			block_node.add_child(block)

# Creates connecting structures between main blocks
func create_connecting_structures(parent, origin_point):
	# Create a few connector pieces
	var num_connectors = randi() % 5 + 3
	
	for i in range(num_connectors):
		var connector = MeshInstance3D.new()
		connector.name = "Connector_" + str(i)
		
		var connector_mesh
		var type = randi() % 3
		
		match type:
			0:  # Thin box
				connector_mesh = BoxMesh.new()
				connector_mesh.size = Vector3(
					randf_range(0.5, 1.0),
					randf_range(0.5, 1.0),
					randf_range(3.0, 6.0)
				)
			1:  # L-shaped (approximated with two boxes)
				connector_mesh = BoxMesh.new()
				connector_mesh.size = Vector3(
					randf_range(0.5, 1.0),
					randf_range(0.5, 1.0),
					randf_range(2.0, 4.0)
				)
				
				# Create a second part for the L
				var part2 = MeshInstance3D.new()
				var part2_mesh = BoxMesh.new()
				part2_mesh.size = Vector3(
					randf_range(0.5, 1.0),
					randf_range(0.5, 1.0),
					randf_range(2.0, 3.0)
				)
				
				part2.mesh = part2_mesh
				part2.position = Vector3(0, 0, connector_mesh.size.z/2 + part2_mesh.size.z/2 - 0.1)
				part2.rotation_degrees.y = 90
				part2.material_override = secondary_material
				
				connector.add_child(part2)
			2:  # Thin vertical column
				connector_mesh = BoxMesh.new()
				connector_mesh.size = Vector3(
					randf_range(0.5, 1.0),
					randf_range(3.0, 6.0),
					randf_range(0.5, 1.0)
				)
		
		connector.mesh = connector_mesh
		
		# Position somewhere in the structure
		connector.position = origin_point + Vector3(
			randf_range(-4, 4),
			randf_range(0, 4),
			randf_range(-4, 4)
		)
		
		# Random rotation
		connector.rotation_degrees.y = randf_range(0, 360)
		
		# Use secondary material for contrast
		connector.material_override = secondary_material
		
		parent.add_child(connector)

# Adds small detail blocks to the cluster
func add_cluster_details(parent, origin_point):
	var num_details = randi() % 10 + 5
	
	for i in range(num_details):
		var detail = MeshInstance3D.new()
		detail.name = "Detail_" + str(i)
		
		var detail_mesh = BoxMesh.new()
		detail_mesh.size = Vector3(
			randf_range(0.3, 0.8),
			randf_range(0.3, 0.8),
			randf_range(0.3, 0.8)
		)
		
		detail.mesh = detail_mesh
		
		# Position details around the structure
		detail.position = origin_point + Vector3(
			randf_range(-5, 5),
			randf_range(0, 6),
			randf_range(-5, 5)
		)
		
		# Random rotation
		detail.rotation_degrees = Vector3(
			randf_range(0, 30),
			randf_range(0, 360),
			randf_range(0, 30)
		)
		
		# Choose material, with higher chance of secondary
		detail.material_override = secondary_material if randf() > 0.3 else primary_material
		
		parent.add_child(detail)

# Can be called to rebuild the tree with new parameters
func rebuild_tree():
	# Remove existing tree
	for child in get_children():
		child.queue_free()
	
	# Generate new tree
	generate_tree()

# For the specific style in the image - call this instead of generate_tree()
func generate_image_style_tree():
	# Create base materials
	create_materials()
	
	# Create complex geometric tree like in the image
	generate_complex_geometric_tree()
