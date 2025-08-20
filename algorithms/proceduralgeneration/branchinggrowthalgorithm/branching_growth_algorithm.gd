extends Node3D

# Parameters for the growth algorithm
@export var max_branches = 200  # Reduced for VR performance
@export var attraction_distance = 3.0
@export var min_branch_distance = 0.3
@export var growth_distance = 0.15
@export var jitter = 0.05
@export var attractor_count = 50  # Much smaller for VR

# Visual parameters
@export var branch_material: Material
@export var branch_radius = 0.02
@export var growth_per_frame = 5  # Grow multiple branches per frame for smooth VR

# Internal variables - simple arrays for compatibility
var branches = []
var attractors = []

# Mesh for visualization
var mesh_instance: MeshInstance3D
var immediate_mesh: ImmediateMesh

# Performance tracking
var growth_timer = 0.0
var is_growing = false

class Branch:
	var position: Vector3
	var direction: Vector3
	var parent_index: int = -1
	var is_active: bool = true
	var generation: int = 0
	
	func _init(pos: Vector3, dir: Vector3, parent: int = -1, gen: int = 0):
		position = pos
		direction = dir.normalized()
		parent_index = parent
		generation = gen

class Attractor:
	var position: Vector3
	var is_reached: bool = false
	
	func _init(pos: Vector3):
		position = pos

func _ready():
	print("Initializing VR Space Colonization...")
	
	# Set up simple mesh for VR performance
	immediate_mesh = ImmediateMesh.new()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	
	# Use unshaded material for VR performance if none provided
	if not branch_material:
		var material = StandardMaterial3D.new()
		material.flags_unshaded = true
		material.vertex_color_use_as_albedo = true
		material.albedo_color = Color.WHITE
		mesh_instance.material_override = material
	else:
		mesh_instance.material_override = branch_material
	
	add_child(mesh_instance)
	
	# Initialize with a single branch at the origin
	add_branch(Vector3.ZERO, Vector3.UP, -1, 0)
	
	# Generate fewer attractors for VR
	generate_attractors_vr_optimized()
	
	print("Starting growth with ", branches.size(), " branches and ", attractors.size(), " attractors")
	
	# Start growth process
	start_growth()

func add_branch(position: Vector3, direction: Vector3, parent_index: int = -1, generation: int = 0):
	var branch = Branch.new(position, direction, parent_index, generation)
	branches.append(branch)

func generate_attractors_vr_optimized():
	attractors.clear()
	
	# Generate attractors in a more controlled pattern for VR
	var radius = 3.0
	
	for i in range(attractor_count):
		# Use spherical coordinates for better distribution
		var theta = randf() * 2.0 * PI
		var phi = acos(1.0 - 2.0 * randf())  # Better sphere distribution
		var r = radius * pow(randf(), 0.33)  # Cube root for volume distribution
		
		var pos = Vector3(
			r * sin(phi) * cos(theta),
			r * sin(phi) * sin(theta),
			r * cos(phi)
		)
		
		# Avoid attractors too close to origin
		if pos.length() > 0.5:
			attractors.append(Attractor.new(pos))

func start_growth():
	is_growing = true
	growth_timer = 0.0

func _process(delta):
	if not is_growing:
		return
	
	growth_timer += delta
	
	# Grow branches at a steady rate for smooth VR experience - NON-BLOCKING
	if growth_timer > 0.016:  # ~60 FPS target
		growth_timer = 0.0
		
		# Process only a limited number of branches per frame to avoid blocking
		var processed_count = 0
		var max_process_per_frame = growth_per_frame
		
		for i in range(growth_per_frame):
			if not grow_step():
				is_growing = false
				print("Growth completed with ", branches.size(), " branches")
				break
			processed_count += 1
			
			# Break if we've processed enough for this frame
			if processed_count >= max_process_per_frame:
				break
		
		# Update mesh every frame for smooth VR
		update_mesh_immediate()

func grow_step() -> bool:
	var active_branches_found = false
	var new_branches = []
	var reached_attractors = []
	
	# Process existing branches
	for i in range(branches.size()):
		var branch = branches[i]
		if not branch.is_active:
			continue
		
		active_branches_found = true
		
		# Find closest attractor
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
		
		# Grow towards attractor
		if closest_attractor_index >= 0:
			var attractor = attractors[closest_attractor_index]
			var direction = (attractor.position - branch.position).normalized()
			
			# Add minimal jitter for VR (less motion sickness)
			if jitter > 0:
				direction += Vector3(
					randf_range(-jitter, jitter),
					randf_range(-jitter, jitter),
					randf_range(-jitter, jitter)
				)
				direction = direction.normalized()
			
			# Create new branch
			var new_position = branch.position + direction * growth_distance
			new_branches.append({
				"position": new_position,
				"direction": direction,
				"parent": i,
				"generation": branch.generation + 1
			})
			
			# Check if attractor is reached
			if closest_distance < min_branch_distance:
				reached_attractors.append(closest_attractor_index)
				branch.is_active = false
		else:
			# No attractors in range
			branch.is_active = false
		
		# Limit branches for VR performance
		if branches.size() >= max_branches:
			is_growing = false
			return false
	
	# Add new branches
	for branch_data in new_branches:
		add_branch(
			branch_data.position,
			branch_data.direction,
			branch_data.parent,
			branch_data.generation
		)
	
	# Mark reached attractors
	for attractor_index in reached_attractors:
		attractors[attractor_index].is_reached = true
	
	return active_branches_found and new_branches.size() > 0

func update_mesh_immediate():
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Draw all branches with generation-based colors
	for i in range(branches.size()):
		var branch = branches[i]
		if branch.parent_index >= 0 and branch.parent_index < branches.size():
			var parent = branches[branch.parent_index]
			
			# Color based on generation for visual feedback
			var generation_factor = min(branch.generation / 10.0, 1.0)
			var color = Color(
				1.0 - generation_factor * 0.5,
				1.0 - generation_factor * 0.3,
				1.0,
				1.0
			)
			
			immediate_mesh.surface_set_color(color)
			immediate_mesh.surface_add_vertex(parent.position)
			immediate_mesh.surface_set_color(color)
			immediate_mesh.surface_add_vertex(branch.position)
	
	immediate_mesh.surface_end()

# VR-specific functions
func set_vr_start_point(position: Vector3):
	"""Set new starting point for VR interaction"""
	clear_growth()
	add_branch(position, Vector3.UP, -1, 0)
	generate_attractors_around_point(position)
	start_growth()

func generate_attractors_around_point(center: Vector3, radius: float = 2.0):
	"""Generate attractors around a specific point for VR interaction"""
	attractors.clear()
	
	for i in range(attractor_count):
		var offset = Vector3(
			randf_range(-radius, radius),
			randf_range(-radius, radius),
			randf_range(-radius, radius)
		)
		
		# Ensure minimum distance from center
		if offset.length() < 0.3:
			offset = offset.normalized() * 0.3
		
		attractors.append(Attractor.new(center + offset))

func add_attractor_at_position(position: Vector3):
	"""Add single attractor at VR controller position"""
	attractors.append(Attractor.new(position))

func clear_growth():
	"""Reset the entire growth system"""
	branches.clear()
	attractors.clear()
	is_growing = false
	immediate_mesh.clear_surfaces()

func pause_growth():
	"""Pause growth for VR menu interaction"""
	is_growing = false

func resume_growth():
	"""Resume growth after VR interaction"""
	is_growing = true

func get_growth_stats() -> Dictionary:
	"""Get stats for VR UI display"""
	var active_count = 0
	var reached_count = 0
	
	for branch in branches:
		if branch.is_active:
			active_count += 1
	
	for attractor in attractors:
		if attractor.is_reached:
			reached_count += 1
	
	return {
		"total_branches": branches.size(),
		"active_branches": active_count,
		"total_attractors": attractors.size(),
		"reached_attractors": reached_count,
		"is_growing": is_growing
	}

# Simplified cylinder rendering for VR (optional)
func enable_cylinder_rendering(enable: bool = true):
	"""Enable/disable cylinder rendering - expensive for VR"""
	if not enable:
		return
		
	# Remove line mesh
	mesh_instance.visible = false
	
	# Create simple cylinder instances (limited number for VR)
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = branch_radius
	cylinder_mesh.bottom_radius = branch_radius
	cylinder_mesh.height = 1.0
	
	var instance_count = 0
	for i in range(min(branches.size(), 100)):  # Limit for VR performance
		var branch = branches[i]
		if branch.parent_index >= 0:
			var parent = branches[branch.parent_index]
			
			var cylinder = MeshInstance3D.new()
			cylinder.mesh = cylinder_mesh
			cylinder.material_override = mesh_instance.material_override
			
			# Position and orient cylinder
			var midpoint = (parent.position + branch.position) * 0.5
			var length = parent.position.distance_to(branch.position)
			var direction = (branch.position - parent.position).normalized()
			
			cylinder.position = midpoint
			cylinder.scale.y = length
			
			# Simple orientation
			if direction != Vector3.UP:
				cylinder.look_at(midpoint + direction, Vector3.UP)
				cylinder.rotate_object_local(Vector3.RIGHT, PI * 0.5)
			
			add_child(cylinder)
			instance_count += 1
			
			# Break if too many for VR
			if instance_count > 50:
				break

# Debug function
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				print("Restarting growth...")
				clear_growth()
				add_branch(Vector3.ZERO, Vector3.UP, -1, 0)
				generate_attractors_vr_optimized()
				start_growth()
			KEY_P:
				if is_growing:
					pause_growth()
					print("Growth paused")
				else:
					resume_growth()
					print("Growth resumed")
			KEY_S:
				var stats = get_growth_stats()
				print("Stats: ", stats)
