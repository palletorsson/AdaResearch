extends Node3D

# Algorithm Tree Platforms Generator
# Creates walkable 3D platforms representing the algorithm tree in VR

# Platform settings
@export_group("Platform Appearance")
@export var platform_material_wp1: Material
@export var platform_material_wp2: Material
@export var platform_material_wp3: Material
@export var platform_material_wp4: Material
@export var platform_material_concepts: Material
@export var connection_material: Material

@export_group("Platform Layout")
@export var center_position: Vector3 = Vector3(0, 0, 0)  # Center of the entire structure
@export var work_package_radius: float = 30.0  # Distance of WP platforms from center
@export var algorithm_radius: float = 8.0  # Distance of algorithms from their WP
@export var platform_spacing: float = 6.0  # Vertical spacing between levels
@export var platform_size: Vector3 = Vector3(4, 0.5, 4)  # Size of regular platforms
@export var wp_platform_size: Vector3 = Vector3(6, 0.5, 6)  # Size of work package platforms
@export var connection_thickness: float = 0.3  # Thickness of connection beams

@export_group("Navigation")
@export var add_teleport_points: bool = true
@export var teleport_marker_mesh: Mesh
@export var generate_nav_mesh: bool = true
@export var nav_mesh_map_name: String = "AlgorithmTree"

# Structure for storing platform information
class PlatformInfo:
	var id: String
	var position: Vector3
	var size: Vector3
	var material: Material
	var parent_id: String
	var children_ids: Array[String]
	var wp_level: int  # 0=center, 1-4=work packages, 5=algorithms
	
	func _init(p_id: String, pos: Vector3, sz: Vector3, mat: Material, par_id: String = "", wp: int = 0):
		id = p_id
		position = pos
		size = sz
		material = mat
		parent_id = par_id
		children_ids = []
		wp_level = wp

# Internal variables
var platforms = {}  # Dictionary of platform info objects
var mesh_instances = {}  # Dictionary of actual mesh instances

func _ready():
	# Create the platform structure
	create_algorithm_tree()
	
	# Generate physical platforms
	generate_platforms()
	
	# Generate connecting beams between platforms
	generate_connections()
	
	# Add teleport markers for VR navigation if requested
	if add_teleport_points:
		add_teleport_markers()
	
	# Generate navigation mesh if requested
	if generate_nav_mesh:
		create_navigation_mesh()

func create_algorithm_tree():
	# Define platform hierarchy based on the algorithm tree
	
	# 1. Create center platform (Ada Research)
	var center = PlatformInfo.new("ADA", center_position, wp_platform_size * 1.2, platform_material_concepts, "", 0)
	platforms[center.id] = center
	
	# 2. Create work package platforms
	var wp_positions = [
		Vector3(work_package_radius, 0, 0),  # WP1 - East
		Vector3(0, 0, work_package_radius),  # WP2 - North
		Vector3(-work_package_radius, 0, 0), # WP3 - West
		Vector3(0, 0, -work_package_radius)  # WP4 - South
	]
	
	var wp_materials = [
		platform_material_wp1,
		platform_material_wp2,
		platform_material_wp3,
		platform_material_wp4
	]
	
	var wp_names = ["WP1", "WP2", "WP3", "WP4"]
	
	# Create the 4 main work package platforms
	for i in range(4):
		var wp_pos = center_position + wp_positions[i]
		var wp = PlatformInfo.new(wp_names[i], wp_pos, wp_platform_size, wp_materials[i], "ADA", 1)
		platforms[wp.id] = wp
		center.children_ids.append(wp.id)
	
	# 3. Create algorithm platforms for each work package
	
	# WP1: Basic Elements
	add_algorithm_platforms("WP1", [
		"RNG", "FIBO", "PN", "VOR", "SINE", "SOUND", "PS"
	], platform_material_wp1, 2)
	
	# WP2: Advanced Elements
	add_algorithm_platforms("WP2", [
		"FRAC", "FLOW", "FOUR", "LSYS", "CA", "SOFT", "TOPO", "QMESH"
	], platform_material_wp2, 2)
	
	# Add sub-algorithms for Soft Body
	add_sub_algorithm_platforms("SOFT", [
		"CLOTH", "FLUID", "RUBBER"
	], platform_material_wp2, 3)
	
	# WP3: Pattern and World Building
	add_algorithm_platforms("WP3", [
		"RD", "GRAPH", "PG", "NN", "SHADER", "EVOL", "NAVI"
	], platform_material_wp3, 2)
	
	# WP4: Advanced Techniques
	add_algorithm_platforms("WP4", [
		"SWARM", "CHAOS", "ALGLIFE", "AI", "NONEUC"
	], platform_material_wp4, 2)
	
	# Add sub-algorithms for Chaos Theory
	add_sub_algorithm_platforms("CHAOS", [
		"LYAP", "BIFUR", "STRANGE"
	], platform_material_wp4, 3)
	
	# 4. Create concept platforms
	var concept_height = -platform_spacing * 3
	var concept_radius = work_package_radius * 0.5
	var concept_positions = [
		Vector3(concept_radius, concept_height, 0),           # Entropy
		Vector3(-concept_radius/2, concept_height, concept_radius*0.866), # Queer Morphology
		Vector3(-concept_radius/2, concept_height, -concept_radius*0.866) # Mathematical Visualization
	]
	
	var concept_names = ["ENTROPY", "QUEER", "MATH"]
	
	for i in range(3):
		var concept_pos = center_position + concept_positions[i]
		var concept = PlatformInfo.new(concept_names[i], concept_pos, platform_size, platform_material_concepts, "", 5)
		platforms[concept.id] = concept
	
	# 5. Add connections between algorithms and concepts
	connect_platforms("CHAOS", "ENTROPY")
	connect_platforms("QMESH", "QUEER")
	connect_platforms("NONEUC", "QUEER")
	connect_platforms("FOUR", "MATH")
	connect_platforms("VOR", "MATH")
	connect_platforms("BIFUR", "ENTROPY")
	
	# 6. Add cross-work-package connections
	connect_platforms("RNG", "FRAC")
	connect_platforms("PN", "FLOW")
	connect_platforms("PN", "PG")
	connect_platforms("SINE", "FOUR")
	connect_platforms("PS", "SWARM")
	connect_platforms("CA", "ALGLIFE")
	connect_platforms("LSYS", "PG")
	connect_platforms("NN", "AI")
	connect_platforms("EVOL", "AI")
	connect_platforms("FLOW", "NAVI")

# Helper function to add algorithm platforms around a parent
func add_algorithm_platforms(parent_id: String, algorithm_ids: Array, material: Material, wp_level: int):
	var parent = platforms[parent_id]
	var num_algorithms = algorithm_ids.size()
	
	for i in range(num_algorithms):
		var angle = 2 * PI * i / num_algorithms
		var offset = Vector3(cos(angle) * algorithm_radius, -platform_spacing, sin(angle) * algorithm_radius)
		var alg_pos = parent.position + offset
		
		var alg = PlatformInfo.new(algorithm_ids[i], alg_pos, platform_size, material, parent_id, wp_level)
		platforms[alg.id] = alg
		parent.children_ids.append(alg.id)

# Helper function to add sub-algorithm platforms around a parent algorithm
func add_sub_algorithm_platforms(parent_id: String, sub_alg_ids: Array, material: Material, wp_level: int):
	var parent = platforms[parent_id]
	var num_algorithms = sub_alg_ids.size()
	
	for i in range(num_algorithms):
		var angle = 2 * PI * i / num_algorithms
		var sub_radius = algorithm_radius * 0.6
		var offset = Vector3(cos(angle) * sub_radius, -platform_spacing, sin(angle) * sub_radius)
		var alg_pos = parent.position + offset
		
		var alg = PlatformInfo.new(sub_alg_ids[i], alg_pos, platform_size * 0.8, material, parent_id, wp_level)
		platforms[alg.id] = alg
		parent.children_ids.append(alg.id)

# Helper function to connect two platforms
func connect_platforms(platform1_id: String, platform2_id: String):
	if platforms.has(platform1_id) and platforms.has(platform2_id):
		if !platforms[platform1_id].children_ids.has(platform2_id):
			platforms[platform1_id].children_ids.append(platform2_id)

# Generate the actual platform meshes
func generate_platforms():
	for id in platforms.keys():
		var platform = platforms[id]
		
		# Create box mesh for the platform
		var platform_mesh = BoxMesh.new()
		platform_mesh.size = platform.size
		
		# Create mesh instance
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = platform_mesh
		mesh_instance.material_override = platform.material
		mesh_instance.position = platform.position
		mesh_instance.name = id + "_Platform"
		
		# Add collision shape for player interaction
		var static_body = StaticBody3D.new()
		static_body.name = id + "_Body"
		mesh_instance.add_child(static_body)
		
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = platform.size
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		
		# Add label for the platform
		add_text_label(mesh_instance, id, platform.size.y / 2 + 0.1)
		
		# Store mesh instance reference
		mesh_instances[id] = mesh_instance
		
		# Add to scene
		add_child(mesh_instance)

# Generate connecting beams between platforms
func generate_connections():
	for parent_id in platforms.keys():
		var parent = platforms[parent_id]
		
		for child_id in parent.children_ids:
			if mesh_instances.has(parent_id) and mesh_instances.has(child_id):
				var child = platforms[child_id]
				create_connection_beam(parent.position, child.position)

# Create a beam connecting two platforms
func create_connection_beam(start_pos: Vector3, end_pos: Vector3):
	# Calculate beam properties
	var direction = end_pos - start_pos
	var center = (start_pos + end_pos) / 2
	var length = direction.length()
	direction = direction.normalized()
	
	# Create the beam mesh (cylinder aligned to direction)
	var beam_mesh = CylinderMesh.new()
	beam_mesh.top_radius = connection_thickness / 2
	beam_mesh.bottom_radius = connection_thickness / 2
	beam_mesh.height = length
	
	# Create mesh instance
	var beam_instance = MeshInstance3D.new()
	beam_instance.mesh = beam_mesh
	beam_instance.material_override = connection_material
	
	# Position and rotate the beam to connect the platforms
	beam_instance.position = center
	
	# We need to align the cylinder with the direction vector
	# The cylinder's default orientation is along the y-axis
	var y_axis = Vector3(0, 1, 0)
	var rotation_axis = y_axis.cross(direction).normalized()
	var rotation_angle = acos(y_axis.dot(direction))
	
	if rotation_axis.length() > 0.001:
		beam_instance.rotate(rotation_axis, rotation_angle)
		
	# Add walkable surface on top of the connector beam
	create_walkable_path(beam_instance, length, rotation_axis, rotation_angle)
	
	# Add to scene
	add_child(beam_instance)
	
# Create a walkable path on top of connector beams
func create_walkable_path(beam_instance: MeshInstance3D, beam_length: float, rotation_axis: Vector3, rotation_angle: float):
	# Create a static body for collision
	var static_body = StaticBody3D.new()
	static_body.name = "WalkablePath"
	beam_instance.add_child(static_body)
	
	# Create a wider, flatter collision shape for walking
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	
	# Make the walkway wider than the beam for easier walking but not too visible
	var walkway_width = connection_thickness * 4.0
	var walkway_height = connection_thickness * 0.5
	
	box_shape.size = Vector3(walkway_width, walkway_height, beam_length)
	collision_shape.shape = box_shape
	
	# The box needs to be rotated correctly to align with the beam
	# First, rotate to align with the beam's orientation
	if rotation_axis.length() > 0.001:
		collision_shape.rotate(rotation_axis, rotation_angle)
	
	# Adjust position to place the walkway on top of the beam
	# Calculate the offset to move the box to the top of the cylinder
	var offset_distance = connection_thickness / 2 + walkway_height / 2
	var offset_vector = Vector3(0, offset_distance, 0)
	
	# If the beam is rotated, we need to rotate the offset vector as well
	if rotation_axis.length() > 0.001:
		var rotation_transform = Transform3D().rotated(rotation_axis, rotation_angle)
		offset_vector = rotation_transform.basis * offset_vector
	
	collision_shape.position = offset_vector
	
	# Add collision shape to the static body
	static_body.add_child(collision_shape)
	
	# Optional: Add a visual indicator for the path (slightly transparent)
	if false:  # Set to true if you want to see the walkway
		var walkway_mesh = BoxMesh.new()
		walkway_mesh.size = Vector3(walkway_width, walkway_height, beam_length)
		
		var walkway_instance = MeshInstance3D.new()
		walkway_instance.mesh = walkway_mesh
		walkway_instance.position = offset_vector
		
		# Create transparent material for the walkway
		var walkway_material = StandardMaterial3D.new()
		walkway_material.albedo_color = Color(1, 1, 1, 0.3)
		walkway_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		walkway_instance.material_override = walkway_material
		
		if rotation_axis.length() > 0.001:
			walkway_instance.rotate(rotation_axis, rotation_angle)
			
		beam_instance.add_child(walkway_instance)

# Add text label to platform
func add_text_label(parent: Node3D, text: String, height: float):
	var label3d = Label3D.new()
	label3d.text = text
	label3d.font_size = 24
	label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label3d.no_depth_test = true
	label3d.position = Vector3(0, height, 0)
	parent.add_child(label3d)

# Add teleport markers for VR navigation
func add_teleport_markers():
	for id in platforms.keys():
		var platform = platforms[id]
		
		# Skip adding markers to concept platforms
		if platform.wp_level == 5:
			continue
			
		var marker = MeshInstance3D.new()
		marker.name = id + "_TeleportMarker"
		marker.mesh = teleport_marker_mesh if teleport_marker_mesh else create_default_teleport_marker()
		
		# Position slightly above platform
		marker.position = platform.position + Vector3(0, platform.size.y / 2 + 0.05, 0)
		
		# Add collision shape to detect teleport ray
		var area = Area3D.new()
		area.name = "TeleportArea"
		
		var collision = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.height = 0.1
		shape.radius = 0.5
		collision.shape = shape
		
		area.add_child(collision)
		marker.add_child(area)
		
		# Add metadata for teleport system
		area.set_meta("teleport_destination", platform.position + Vector3(0, platform.size.y / 2 + 1.0, 0))
		area.set_meta("is_teleport_destination", true)
		
		add_child(marker)

# Create a default teleport marker mesh if none is provided
func create_default_teleport_marker() -> Mesh:
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = 0.5
	marker_mesh.bottom_radius = 0.5
	marker_mesh.height = 0.05
	return marker_mesh

# Generate a navigation mesh for the platforms
func create_navigation_mesh():
	var nav_region = NavigationRegion3D.new()
	nav_region.name = "AlgorithmTreeNavRegion"
	
	var nav_mesh = NavigationMesh.new()
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_radius = 0.5
	#nav_mesh.map_name = nav_mesh_map_name
	
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)
	
	# We'll let Godot bake the navigation mesh at runtime
	# This should work since we've added all the static geometry
	nav_region.bake_navigation_mesh()
