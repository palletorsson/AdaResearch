extends Node3D

class_name OrganicVRSpace

## Procedural organic interior space generator for Godot 4 VR
## Inspired by the "Octavia Diva" model interior visualization

@export var space_size: Vector3 = Vector3(20, 15, 20)
@export var detail_level: int = 2  # Lower = more detail
@export var organic_strength: float = 0.8
@export var tunnel_complexity: int = 5
@export var material_variety: int = 4

# Components
var mesh_generator: OrganicMeshGenerator
var lighting_system: OrganicLighting
var material_manager: OrganicMaterials

# Main container for generated geometry
var environment_container: Node3D

func _ready():
	setup_components()
	generate_organic_space()

func setup_components():
	# Create main container
	environment_container = Node3D.new()
	environment_container.name = "OrganicEnvironment"
	add_child(environment_container)
	
	# Initialize systems
	mesh_generator = OrganicMeshGenerator.new()
	lighting_system = OrganicLighting.new()
	material_manager = OrganicMaterials.new()
	
	add_child(mesh_generator)
	add_child(lighting_system)
	add_child(material_manager)

func generate_organic_space():
	print("Generating organic VR space...")
	
	# Generate base shell using marching cubes-style approach
	generate_base_shell()
	
	# Add organic tunnels and chambers
	generate_tunnel_system()
	
	# Create surface details and textures
	generate_surface_details()
	
	# Add atmospheric lighting
	setup_atmospheric_lighting()
	
	# Add interactive elements
	generate_interactive_elements()

func generate_base_shell():
	"""Create the main hollow shell using CSG operations"""
	var outer_shell = CSGSphere3D.new()
	outer_shell.radius = space_size.x * 0.5
	outer_shell.material = material_manager.get_base_material()
	
	var inner_cavity = CSGSphere3D.new()
	inner_cavity.radius = space_size.x * 0.4
	inner_cavity.operation = CSGShape3D.OPERATION_SUBTRACTION
	
	# Add organic deformation using noise
	apply_organic_deformation(outer_shell)
	apply_organic_deformation(inner_cavity)
	
	outer_shell.add_child(inner_cavity)
	environment_container.add_child(outer_shell)

func apply_organic_deformation(shape: CSGShape3D):
	"""Apply procedural deformation to create organic feel"""
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	noise.seed = randi()
	
	# Create displacement using vertex shader if available
	# For now, use multiple CSG operations to approximate
	for i in range(tunnel_complexity):
		var deform_sphere = CSGSphere3D.new()
		var angle = i * TAU / tunnel_complexity
		var offset = Vector3(
			cos(angle) * space_size.x * 0.3,
			sin(i * 0.7) * space_size.y * 0.2,
			sin(angle) * space_size.z * 0.3
		)
		
		deform_sphere.position = offset
		deform_sphere.radius = randf_range(2.0, 4.0)
		deform_sphere.operation = CSGShape3D.OPERATION_UNION if randf() > 0.5 else CSGShape3D.OPERATION_SUBTRACTION
		
		shape.add_child(deform_sphere)

func generate_tunnel_system():
	"""Create interconnected organic tunnels"""
	var tunnel_points = generate_tunnel_path()
	
	for i in range(tunnel_points.size() - 1):
		create_tunnel_segment(tunnel_points[i], tunnel_points[i + 1], i)

func generate_tunnel_path() -> Array[Vector3]:
	"""Generate organic path using 3D noise"""
	var points: Array[Vector3] = []
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	
	var steps = tunnel_complexity * 3
	for i in range(steps):
		var t = float(i) / float(steps - 1)
		var base_pos = Vector3(
			lerp(-space_size.x * 0.3, space_size.x * 0.3, t),
			0,
			0
		)
		
		# Add organic deviation
		var noise_offset = Vector3(
			noise.get_noise_3d(i * 10, 0, 0) * space_size.x * 0.2,
			noise.get_noise_3d(0, i * 10, 0) * space_size.y * 0.3,
			noise.get_noise_3d(0, 0, i * 10) * space_size.z * 0.2
		)
		
		points.append(base_pos + noise_offset)
	
	return points

func create_tunnel_segment(start: Vector3, end: Vector3, index: int):
	"""Create a single tunnel segment with organic shape"""
	var tunnel = CSGCylinder3D.new()
	tunnel.height = start.distance_to(end)
	tunnel.radius = randf_range(1.5, 3.0)
	
	# Position and orient tunnel
	tunnel.position = (start + end) * 0.5
	tunnel.look_at_from_position(tunnel.position, end, Vector3.UP)
	tunnel.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	
	# Apply organic material
	tunnel.material = material_manager.get_tunnel_material(index)
	
	# Add surface details
	add_tunnel_details(tunnel, index)
	
	environment_container.add_child(tunnel)

func add_tunnel_details(tunnel: CSGCylinder3D, index: int):
	"""Add organic surface details to tunnels"""
	var detail_count = randi_range(3, 8)
	
	for i in range(detail_count):
		var detail = CSGSphere3D.new()
		detail.radius = randf_range(0.3, 0.8)
		
		# Random position around tunnel surface
		var angle = randf() * TAU
		var height = randf_range(-tunnel.height * 0.4, tunnel.height * 0.4)
		var radius_offset = tunnel.radius * randf_range(0.8, 1.2)
		
		detail.position = Vector3(
			cos(angle) * radius_offset,
			height,
			sin(angle) * radius_offset
		)
		
		detail.operation = CSGShape3D.OPERATION_UNION if randf() > 0.3 else CSGShape3D.OPERATION_SUBTRACTION
		detail.material = material_manager.get_detail_material()
		
		tunnel.add_child(detail)

func generate_surface_details():
	"""Add fine surface details and textures"""
	# Create membrane-like structures
	create_membrane_surfaces()
	
	# Add crystalline formations
	create_crystal_formations()
	
	# Generate organic growths
	create_organic_growths()

func create_membrane_surfaces():
	"""Create thin membrane surfaces spanning spaces"""
	for i in range(randi_range(3, 6)):
		var membrane = CSGCylinder3D.new()
		membrane.height = 0.1  # Very thin
		membrane.radius = randf_range(3.0, 6.0)

		
		# Random position and orientation
		membrane.position = Vector3(
			randf_range(-space_size.x * 0.3, space_size.x * 0.3),
			randf_range(-space_size.y * 0.3, space_size.y * 0.3),
			randf_range(-space_size.z * 0.3, space_size.z * 0.3)
		)
		membrane.rotation = Vector3(
			randf() * TAU,
			randf() * TAU,
			randf() * TAU
		)
		
		membrane.material = material_manager.get_membrane_material()
		environment_container.add_child(membrane)

func create_crystal_formations():
	"""Add crystalline geometric structures"""
	for i in range(randi_range(5, 10)):
		var crystal = CSGBox3D.new()
		crystal.size = Vector3(
			randf_range(0.5, 2.0),
			randf_range(2.0, 5.0),
			randf_range(0.5, 2.0)
		)
		
		# Cluster around certain points
		var cluster_center = Vector3(
			cos(i * 1.3) * space_size.x * 0.25,
			sin(i * 0.8) * space_size.y * 0.25,
			sin(i * 1.1) * space_size.z * 0.25
		)
		
		crystal.position = cluster_center + Vector3(
			randf_range(-2, 2),
			randf_range(-2, 2),
			randf_range(-2, 2)
		)
		crystal.rotation = Vector3(
			randf() * TAU,
			randf() * TAU,
			randf() * TAU
		)
		
		crystal.material = material_manager.get_crystal_material()
		environment_container.add_child(crystal)

func create_organic_growths():
	"""Add bulbous organic formations"""
	for i in range(randi_range(8, 15)):
		var growth = CSGSphere3D.new()
		growth.radius = randf_range(0.8, 2.5)
		
		# Attach to walls/surfaces
		var surface_normal = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		
		growth.position = surface_normal * space_size.x * randf_range(0.3, 0.45)
		growth.material = material_manager.get_organic_material()
		
		# Add smaller sub-growths
		for j in range(randi_range(2, 5)):
			var sub_growth = CSGSphere3D.new()
			sub_growth.radius = growth.radius * randf_range(0.3, 0.7)
			sub_growth.position = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			).normalized() * growth.radius * 1.2
			sub_growth.material = material_manager.get_organic_material()
			growth.add_child(sub_growth)
		
		environment_container.add_child(growth)

func setup_atmospheric_lighting():
	"""Create atmospheric lighting effects"""
	lighting_system.setup_organic_lighting(environment_container, space_size)

func generate_interactive_elements():
	"""Add interactive elements for the space"""
	# Create floating orbs that can be interacted with
	for i in range(randi_range(3, 7)):
		var orb = create_interactive_orb()
		orb.position = Vector3(
			randf_range(-space_size.x * 0.2, space_size.x * 0.2),
			randf_range(-space_size.y * 0.2, space_size.y * 0.2),
			randf_range(-space_size.z * 0.2, space_size.z * 0.2)
		)
		environment_container.add_child(orb)

func create_interactive_orb() -> RigidBody3D:
	"""Create interactive floating orb"""
	var orb = RigidBody3D.new()
	orb.gravity_scale = 0  # Float in space
	
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	mesh_instance.mesh = sphere_mesh
	mesh_instance.material_override = material_manager.get_interactive_material()
	
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	collision_shape.shape = sphere_shape
	
	orb.add_child(mesh_instance)
	orb.add_child(collision_shape)
	
	# Add gentle floating motion
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(orb, "position", orb.position + Vector3(0, 2, 0), 3.0)
	tween.tween_property(orb, "position", orb.position, 3.0)
	
	return orb



func regenerate_space():
	"""Regenerate the entire space with new parameters"""
	# Clear existing environment
	if environment_container:
		environment_container.queue_free()
	
	# Regenerate with new seed
	await get_tree().process_frame
	generate_organic_space()
