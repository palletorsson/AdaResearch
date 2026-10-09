extends Node3D

## A queue evaluates a recursive branching rule one tip at a time.
## Angles are degrees, lengths are metres. Growth is prescribed, not biological.
## A local RNG and reset preserve replay without reseeding neighbouring works.
# Tree settings
@export var growth_interval: float = 0.3  # Time between growth steps
@export var max_depth: int = 10  # Maximum recursion depth
@export var auto_start: bool = true  # Auto-start growth
@export var initial_branch_length: float = 2.0  # Length of trunk
@export var initial_branch_thickness: float = 0.2  # Thickness of trunk
@export var length_reduction: float = 0.7  # How much shorter each branch level is
@export var thickness_reduction: float = 0.65  # How much thinner each branch level is
@export var branch_count: int = 3  # Number of branches per node (2-5 looks good)
@export var branch_angle_min: float = 20.0  # Minimum branch angle (degrees)
@export var branch_angle_max: float = 35.0  # Maximum branch angle (degrees)
@export var rotation_variation: float = 360.0  # Rotation around Y axis (degrees)
@export var add_randomness: bool = true  # Add natural variation
@export var randomness_amount: float = 0.15  # How much random variation (0-1)

# Internal state
const MAX_SEGMENTS := 512
var generated: Node3D
var rng := RandomNumberGenerator.new()
var seed_value := 31415
var segment_count := 0
var leaf_count := 0
var lesson_enabled := false
var geometry_revision := 0
var current_depth: int = 0
var growth_timer: float = 0.0
var is_growing: bool = false
var branches_to_grow: Array = []  # Queue of branches to grow

# Material cache
var bark_material: StandardMaterial3D
var leaf_material: StandardMaterial3D

func _ready() -> void:
	rng.seed = seed_value
	generated = Node3D.new()
	generated.name = "GeneratedTree"
	add_child(generated)
	print("RecursiveTree: Ready")
	print("RecursiveTree: Will grow to depth %d with %d branches per node" % [max_depth, branch_count])

	# Create materials
	create_materials()

	# Create the trunk
	create_trunk()

	# Start automatic growth if enabled
	if auto_start:
		is_growing = true
		print("RecursiveTree: Auto-growth enabled")

func _process(delta: float) -> void:
	if not is_growing:
		return

	# Update timer
	growth_timer += delta

	# Check if it's time to grow
	if growth_timer >= growth_interval:
		growth_timer = 0.0
		perform_growth_step()

# Create beautiful materials for the tree
func create_materials() -> void:
	# Bark material - brown with subtle texture
	bark_material = StandardMaterial3D.new()
	bark_material.albedo_color = Color(0.25, 0.15, 0.08)  # Rich brown
	bark_material.roughness = 0.9
	bark_material.metallic = 0.0

	# Leaf material - vibrant green
	leaf_material = StandardMaterial3D.new()
	leaf_material.albedo_color = Color(0.2, 0.6, 0.15)  # Fresh green
	leaf_material.roughness = 0.7
	leaf_material.metallic = 0.0
	leaf_material.emission_enabled = true
	leaf_material.emission = Color(0.1, 0.3, 0.05)
	leaf_material.emission_energy_multiplier = 0.3

# Create the initial trunk
func create_trunk() -> void:
	var trunk_data = {
		"position": Vector3.ZERO,
		"direction": Vector3.UP,
		"length": initial_branch_length,
		"thickness": initial_branch_thickness,
		"depth": 0,
		"parent_node": self
	}

	var trunk = create_branch(trunk_data)

	# Queue the end of the trunk for branching
	var end_position = Vector3.UP * initial_branch_length
	branches_to_grow.append({
		"position": end_position,
		"direction": Vector3.UP,
		"length": initial_branch_length,
		"thickness": initial_branch_thickness,
		"depth": 1,
		"parent_node": trunk
	})

	print("RecursiveTree: Created trunk")

# Perform one growth step
func perform_growth_step() -> void:
	if branches_to_grow.is_empty():
		print("RecursiveTree: Growth complete at depth %d" % current_depth)
		is_growing = false
		return

	# Take the first branch data from the queue
	var branch_data = branches_to_grow.pop_front()

	# Update current depth
	if branch_data.depth > current_depth:
		current_depth = branch_data.depth
		print("RecursiveTree: Growing depth %d" % current_depth)

	# Check if we've reached max depth
	if branch_data.depth > max_depth:
		# Add a leaf cluster instead of more branches
		add_leaf_cluster(branch_data)
		return

	# Create multiple branches at this node
	for i in range(branch_count):
		create_branching_node(branch_data, i)

# Create a branching node with multiple branches
func create_branching_node(parent_data: Dictionary, branch_index: int) -> void:
	if segment_count >= MAX_SEGMENTS: return
	var depth = parent_data.depth
	var parent_pos = parent_data.position
	var parent_dir = parent_data.direction
	var parent_node = parent_data.parent_node

	# Calculate branch angle
	var angle_range = branch_angle_max - branch_angle_min
	var base_angle = branch_angle_min + rng.randf() * angle_range if add_randomness else (branch_angle_min + branch_angle_max) * 0.5

	# Add randomness to angle
	if add_randomness:
		base_angle += (rng.randf() - 0.5) * randomness_amount * 30.0

	# Calculate rotation around parent direction (Y-axis when going up)
	var rotation_offset = (rotation_variation / branch_count) * branch_index
	if add_randomness:
		rotation_offset += (rng.randf() - 0.5) * randomness_amount * 60.0

	# Create rotation basis
	# First, rotate around the parent direction (twist)
	var twist_basis = Basis(parent_dir, deg_to_rad(rotation_offset))

	# Then, tilt outward at the branch angle
	# Find a perpendicular vector to parent_dir for tilting
	var perp = Vector3.RIGHT if abs(parent_dir.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var tilt_axis = parent_dir.cross(perp).normalized()
	tilt_axis = twist_basis * tilt_axis

	var tilt_basis = Basis(tilt_axis, deg_to_rad(base_angle))

	# Combine rotations
	var final_basis = tilt_basis * twist_basis
	var branch_direction = (final_basis * parent_dir).normalized()

	# Calculate new length and thickness
	var new_length = parent_data.length * length_reduction
	var new_thickness = parent_data.thickness * thickness_reduction

	# Add slight randomness to length
	if add_randomness:
		new_length *= 1.0 + (rng.randf() - 0.5) * randomness_amount

	# Create branch
	var branch_data = {
		"position": parent_pos,
		"direction": branch_direction,
		"length": new_length,
		"thickness": new_thickness,
		"depth": depth,
		"parent_node": parent_node
	}

	var branch = create_branch(branch_data)

	# Queue the end of this branch for further growth
	var end_position = parent_pos + branch_direction * new_length
	branches_to_grow.append({
		"position": end_position,
		"direction": branch_direction,
		"length": new_length,
		"thickness": new_thickness,
		"depth": depth + 1,
		"parent_node": branch
	})

# Create a single branch segment
func create_branch(data: Dictionary) -> Node3D:
	var branch_node = Node3D.new()
	branch_node.position = data.position

	# Create cylinder mesh for the branch
	var mesh_instance = MeshInstance3D.new()
	var cylinder = create_tapered_cylinder(data.length, data.thickness, data.thickness * 0.7)
	mesh_instance.mesh = cylinder

	# Apply bark material with depth-based color variation
	var branch_material = bark_material.duplicate()
	var depth_factor = float(data.depth) / maxi(1, max_depth)
	branch_material.albedo_color = bark_material.albedo_color.lightened(depth_factor * 0.2)
	mesh_instance.material_override = branch_material

	# Orient the cylinder along the branch direction
	# Cylinder is created along Y-axis, need to rotate to match direction
	mesh_instance.basis = Basis(Quaternion(Vector3.UP, data.direction.normalized()))

	# The mesh vertices already run from y=0 to y=length. No half-length offset.
	# Endpoints are tree-local, so segments share one transform space.
	branch_node.set_meta("branch_data", data.duplicate())
	segment_count += 1

	branch_node.add_child(mesh_instance)
	generated.add_child(branch_node)

	return branch_node

# Create a tapered cylinder mesh (wider at bottom, thinner at top)
func create_tapered_cylinder(height: float, bottom_radius: float, top_radius: float) -> ArrayMesh:
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var segments = 8  # Radial segments
	var rings = 3  # Vertical segments for smooth tapering

	# Create vertices along the cylinder with tapering
	for ring in range(rings + 1):
		var t = float(ring) / rings
		var y = t * height
		var radius = lerp(bottom_radius, top_radius, t)

		for seg in range(segments):
			var angle = (float(seg) / segments) * TAU
			var x = cos(angle) * radius
			var z = sin(angle) * radius

			vertices.append(Vector3(x, y, z))

			# Normal points outward
			var normal = Vector3(cos(angle), 0, sin(angle)).normalized()
			normals.append(normal)

	# Create triangles
	for ring in range(rings):
		for seg in range(segments):
			var current = ring * segments + seg
			var next_seg = ring * segments + ((seg + 1) % segments)
			var next_ring = (ring + 1) * segments + seg
			var next_ring_next_seg = (ring + 1) * segments + ((seg + 1) % segments)

			# Two triangles per quad
			indices.append(current)
			indices.append(next_ring)
			indices.append(next_seg)

			indices.append(next_seg)
			indices.append(next_ring)
			indices.append(next_ring_next_seg)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh

# Add a leaf cluster at the end of a branch
func add_leaf_cluster(data: Dictionary) -> void:
	var leaf_node = Node3D.new()
	leaf_node.position = data.position

	# Create a simple sphere for leaves
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = data.thickness * 3.0
	sphere.height = sphere.radius * 2.0
	mesh_instance.mesh = sphere
	mesh_instance.material_override = leaf_material

	leaf_node.add_child(mesh_instance)
	generated.add_child(leaf_node)
	leaf_count += 1

# Manual control functions
func start_growth() -> void:
	is_growing = true
	growth_timer = 0.0
	print("RecursiveTree: Started manually")

func stop_growth() -> void:
	is_growing = false
	print("RecursiveTree: Stopped manually")

func reset() -> void:
	# Keep the scene and its lesson desk. Replace generated geometry only.
	for child in generated.get_children():
		generated.remove_child(child)
		child.free()
	rng.seed = seed_value
	segment_count = 0
	leaf_count = 0

	current_depth = 0
	growth_timer = 0.0
	is_growing = false
	branches_to_grow.clear()

	# Recreate trunk
	create_trunk()

	print("RecursiveTree: Reset")

func step() -> void:
	perform_growth_step()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if str(config.get("lesson", "false")).to_lower() == "true":
		lesson_enabled = true
		auto_start = false
		is_growing = false
		_install_lesson.call_deferred()

func _install_lesson() -> void:
	if has_node("TreeLesson"): return
	var fixture = load("res://commons/artifacts/recursive_tree_lesson/recursive_tree_lesson.gd").new()
	fixture.name = "TreeLesson"
	add_child(fixture)

func grow_generation() -> void:
	# A whole breadth-first generation, without advancing the museum clock.
	if branches_to_grow.is_empty(): return
	var level: int = int(branches_to_grow[0].depth)
	while not branches_to_grow.is_empty() and int(branches_to_grow[0].depth) == level:
		perform_growth_step()

func rebuild_to(level: int) -> void:
	reset()
	for i in range(clampi(level, 0, max_depth)):
		grow_generation()

func steer_branch(branch: Node3D, direction: Vector3) -> bool:
	# Rotate one existing subtree about its attachment. Lengths, count and its
	# sibling are unchanged; pending tips travel with their parents as well.
	if not is_instance_valid(branch) or branch.get_parent() != generated: return false
	if not branch.has_meta("branch_data") or not direction.is_finite() or direction.length() < 0.001: return false
	var selected: Dictionary = branch.get_meta("branch_data")
	var next := direction.normalized()
	if selected.direction.is_equal_approx(next): return false
	var turn := Basis(Quaternion(selected.direction, next))
	var pivot: Vector3 = selected.position
	var affected: Array[Node] = [branch]
	# Generated children are in parent-before-child order, even though their
	# transforms share the tree-local coordinate system.
	for node in generated.get_children():
		if not node.has_meta("branch_data"): continue
		var data: Dictionary = node.get_meta("branch_data")
		if node != branch and data.parent_node not in affected: continue
		if node != branch: affected.append(node)
		data.position = pivot + turn * (data.position - pivot)
		data.direction = (turn * data.direction).normalized()
		node.position = data.position
		node.get_child(0).basis = Basis(Quaternion(Vector3.UP, data.direction))
		node.set_meta("branch_data", data)
	for tip in branches_to_grow:
		if tip.parent_node not in affected: continue
		tip.position = pivot + turn * (tip.position - pivot)
		tip.direction = (turn * tip.direction).normalized()
	geometry_revision += 1
	return true
