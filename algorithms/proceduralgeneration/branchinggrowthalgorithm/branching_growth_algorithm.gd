extends Node3D

# Parameters for the growth algorithm
@export var max_branches = 30
@export var attraction_distance = 5.0
@export var min_branch_distance = 0.5
@export var growth_distance = 0.2
@export var jitter = 0.1
@export var max_connections_per_attractor = 1

# Visual parameters
@export var branch_material: Material
@export var branch_radius = 0.05

# Internal variables
var branches = []
var attractors = []
var mesh_instance: MeshInstance3D
# Note: removed unused immediate_geometry variable
var mesh: ImmediateMesh

class Branch:
	var position: Vector3
	var direction: Vector3
	var parent_index: int = -1
	var is_active: bool = true
	
	func _init(pos, dir, parent = -1):
		position = pos
		direction = dir
		parent_index = parent

class Attractor:
	var position: Vector3
	var is_reached: bool = false
	
	func _init(pos):
		position = pos

func _ready():
	# Set up the mesh for visualization
	mesh = ImmediateMesh.new()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	if branch_material:
		mesh_instance.material_override = branch_material
	add_child(mesh_instance)
	
	# Initialize with a single branch at the origin
	add_branch(Vector3.ZERO, Vector3.UP)
	
	# Generate random attractors
	generate_attractors(200, 10.0)
	
	# Run the growth simulation
	grow_branches()

func add_branch(position: Vector3, direction: Vector3, parent_index: int = -1) -> int:
	var branch = Branch.new(position, direction, parent_index)
	branches.append(branch)
	return branches.size() - 1

func generate_attractors(count: int, radius: float):
	attractors.clear()
	for i in range(count):
		var pos = Vector3(
			randf_range(-radius, radius),
			randf_range(-radius, radius),
			randf_range(-radius, radius)
		).normalized() * (radius * randf())
		attractors.append(Attractor.new(pos))

func grow_branches():
	var iterations = 0
	var active_branches_exist = true
	
	while active_branches_exist and iterations < max_branches:
		iterations += 1
		active_branches_exist = false
		
		# Process all branches
		for i in range(branches.size()):
			var branch = branches[i]
			if not branch.is_active:
				continue
				
			active_branches_exist = true
			
			# Find the closest attractor
			var closest_attractor_index = -1
			var closest_distance = attraction_distance
			
			for j in range(attractors.size()):
				var attractor = attractors[j]
				if attractor.is_reached:
					continue
					
				var distance = branch.position.distance_to(attractor.position)
				if distance < closest_distance:
					closest_distance = distance
					closest_attractor_index = j
			
			# If we found an attractor, grow towards it
			if closest_attractor_index >= 0:
				var attractor = attractors[closest_attractor_index]
				var direction = (attractor.position - branch.position).normalized()
				
				# Add some randomness to the direction
				direction += Vector3(
					randf_range(-jitter, jitter),
					randf_range(-jitter, jitter),
					randf_range(-jitter, jitter)
				)
				direction = direction.normalized()
				
				# Create new branch
				var new_position = branch.position + direction * growth_distance
				var new_branch_index = add_branch(new_position, direction, i)
				
				# Check if we've reached the attractor
				if closest_distance < min_branch_distance:
					attractors[closest_attractor_index].is_reached = true
					branch.is_active = false
			else:
				# No attractors in range, deactivate this branch
				branch.is_active = false
	
	print("Growth completed after ", iterations, " iterations")
	
	# Draw all branches at once after growth is complete
	draw_all_branches()

func draw_branch(start: Vector3, end: Vector3):
	# Only redraw mesh periodically or when growth is complete
	# This prevents the expensive mesh rebuild on every branch
	pass

func draw_all_branches():
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Draw all branches at once
	for i in range(branches.size()):
		var branch = branches[i]
		if branch.parent_index >= 0:
			var parent = branches[branch.parent_index]
			mesh.surface_set_color(Color(1, 1, 1, 1))
			mesh.surface_add_vertex(parent.position)
			mesh.surface_add_vertex(branch.position)
	
	mesh.surface_end()

# Variant using cylinders (slower but more realistic)
func draw_branches_as_cylinders():
	# Remove any previous children
	for child in get_children():
		if child != mesh_instance:
			remove_child(child)
			child.queue_free()
	
	# Create a cylinder mesh
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = branch_radius
	cylinder_mesh.bottom_radius = branch_radius
	cylinder_mesh.height = 1.0
	
	# Create one mesh instance for each branch
	for i in range(branches.size()):
		var branch = branches[i]
		if branch.parent_index >= 0:
			var parent = branches[branch.parent_index]
			
			var midpoint = (parent.position + branch.position) / 2
			var distance = parent.position.distance_to(branch.position)
			var direction = (branch.position - parent.position).normalized()
			
			# Create mesh instance
			var branch_mesh = MeshInstance3D.new()
			branch_mesh.mesh = cylinder_mesh
			branch_mesh.material_override = branch_material
			add_child(branch_mesh)
			
			# Position and scale the cylinder
			branch_mesh.position = midpoint
			branch_mesh.scale = Vector3(1, distance, 1)
			
			# Orient the cylinder towards the direction
			var up_vector = Vector3.UP
			if direction.dot(up_vector) > 0.99:
				up_vector = Vector3.RIGHT
			branch_mesh.look_at(branch_mesh.position + direction, up_vector)
			branch_mesh.rotate_object_local(Vector3.RIGHT, PI / 2)

# Utility functions
func clear_all():
	branches.clear()
	attractors.clear()
	if mesh:
		mesh.clear_surfaces()

# VR Interaction methods
func set_branch_start_point(position: Vector3):
	# Reset the simulation
	clear_all()
	
	# Start with a branch at the specified position
	add_branch(position, Vector3.UP)
	
	# Generate attractors around this position
	generate_attractors(200, 10.0)
	
	# Regrow the branches
	grow_branches()
	
func regrow():
	# Re-run the growth simulation
	grow_branches()
