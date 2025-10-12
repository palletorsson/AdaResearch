extends Node3D

# Romanesco Broccoli Fractal
# Creates a simplified approximation of Romanesco broccoli using self-similar spiral cone patterns
# Uses Fibonacci spirals and recursive cone placement to mimic the natural fractal

# Settings
@export var growth_interval: float = 0.5  # Time between growth iterations
@export var max_depth: int = 4  # Recursion depth (how many levels of detail)
@export var auto_start: bool = true  # Start growing automatically
@export var fibonacci_spiral_count: int = 13  # Number of spirals (Fibonacci number)
@export var base_cone_size: float = 1.0  # Size of the main cone
@export var scale_factor: float = 0.382  # Golden ratio reduction (1/phi)

# Internal state
var current_depth: int = 0
var growth_timer: float = 0.0
var is_growing: bool = false

# Golden angle for Fibonacci spiral
const GOLDEN_ANGLE = 137.508  # degrees

func _ready():
	print("Romanesco: Ready")
	print("Romanesco: Will grow to depth %d" % max_depth)

	# Create the initial central cone
	create_central_cone()

	# Start automatic growth if enabled
	if auto_start:
		is_growing = true
		print("Romanesco: Auto-growth enabled")

func _process(delta: float):
	if not is_growing:
		return

	# Update timer
	growth_timer += delta

	# Check if it's time to grow
	if growth_timer >= growth_interval:
		growth_timer = 0.0
		perform_growth_iteration()

# Create the initial central cone
func create_central_cone():
	var cone = create_cone(Vector3.ZERO, base_cone_size, 0)
	cone.name = "CentralCone"
	print("Romanesco: Created central cone")

# Perform one growth iteration
func perform_growth_iteration():
	if current_depth >= max_depth:
		print("Romanesco: Reached maximum depth (%d)" % max_depth)
		is_growing = false
		return

	current_depth += 1
	print("Romanesco: Growing depth %d" % current_depth)

	# Find all cones at the previous depth level
	var cones = find_cones_at_depth(current_depth - 1)

	if cones.is_empty():
		print("Romanesco: No cones found to grow from")
		is_growing = false
		return

	print("Romanesco: Found %d cones to grow from" % cones.size())

	# Add spiral buds to each cone
	for cone in cones:
		add_spiral_buds(cone, current_depth)

	print("Romanesco: Growth iteration %d complete" % current_depth)

# Find all cones at a specific depth
func find_cones_at_depth(depth: int) -> Array:
	var cones = []
	_find_cones_recursive(self, depth, cones)
	return cones

func _find_cones_recursive(node: Node, target_depth: int, cones: Array):
	if node.has_meta("cone_depth"):
		if node.get_meta("cone_depth") == target_depth:
			cones.append(node)

	for child in node.get_children():
		_find_cones_recursive(child, target_depth, cones)

# Add spiral buds around a cone using Fibonacci spiral pattern
func add_spiral_buds(parent_cone: Node3D, depth: int):
	var parent_size = parent_cone.get_meta("cone_size", base_cone_size)
	var new_size = parent_size * scale_factor

	# Calculate radius for spiral placement
	var spiral_radius = parent_size * 0.5

	# Create buds in a Fibonacci spiral
	for i in range(fibonacci_spiral_count):
		# Calculate angle using golden angle
		var angle = deg_to_rad(i * GOLDEN_ANGLE)

		# Calculate position on spiral
		var radius_at_i = spiral_radius * sqrt(float(i) / fibonacci_spiral_count)
		var x = radius_at_i * cos(angle)
		var z = radius_at_i * sin(angle)

		# Height varies to create dome shape
		var y = parent_size * 0.4 * (1.0 - float(i) / fibonacci_spiral_count)

		var bud_position = Vector3(x, y, z)

		# Create the bud cone
		var bud = create_cone(bud_position, new_size, depth)

		# Tilt the cone slightly outward for natural look
		var tilt_angle = deg_to_rad(15 + i * 2)
		bud.rotation.x = tilt_angle * cos(angle)
		bud.rotation.z = tilt_angle * sin(angle)

		parent_cone.add_child(bud)

# Create a single cone
func create_cone(position: Vector3, size: float, depth: int) -> Node3D:
	var cone_node = Node3D.new()
	cone_node.position = position

	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	var cone_mesh = create_cone_mesh(size)
	mesh_instance.mesh = cone_mesh

	# Create material with color based on depth
	var material = StandardMaterial3D.new()

	# Color shifts from yellow-green to deep green with depth
	var green_value = 0.6 - (depth * 0.1)
	var yellow_value = 0.8 - (depth * 0.15)
	material.albedo_color = Color(yellow_value, green_value, 0.1)
	material.roughness = 0.8
	material.metallic = 0.0

	mesh_instance.material_override = material
	cone_node.add_child(mesh_instance)

	# Store metadata
	cone_node.set_meta("cone_depth", depth)
	cone_node.set_meta("cone_size", size)

	add_child(cone_node)

	return cone_node

# Create a cone mesh with custom proportions
func create_cone_mesh(size: float) -> ArrayMesh:
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	# Cone parameters
	var height = size * 1.5  # Cone height
	var radius = size * 0.5  # Base radius
	var segments = 12  # Number of segments around the base

	# Apex of the cone
	var apex = Vector3(0, height, 0)

	# Create base circle vertices
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		vertices.append(Vector3(x, 0, z))

		# Normal for side faces
		var normal = Vector3(x, radius * 0.5, z).normalized()
		normals.append(normal)

	# Add apex
	var apex_index = vertices.size()
	vertices.append(apex)
	normals.append(Vector3(0, 1, 0))

	# Create side triangles
	for i in range(segments):
		var next_i = (i + 1) % segments
		indices.append(i)
		indices.append(next_i)
		indices.append(apex_index)

	# Create base (optional, for solid appearance)
	var base_center_index = vertices.size()
	vertices.append(Vector3(0, 0, 0))
	normals.append(Vector3(0, -1, 0))

	for i in range(segments):
		var next_i = (i + 1) % segments
		indices.append(base_center_index)
		indices.append(i)
		indices.append(next_i)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh

# Manual control functions
func start_growth():
	is_growing = true
	growth_timer = 0.0
	print("Romanesco: Started manually")

func stop_growth():
	is_growing = false
	print("Romanesco: Stopped manually")

func reset():
	# Clear all cones
	for child in get_children():
		child.queue_free()

	current_depth = 0
	growth_timer = 0.0
	is_growing = false

	# Recreate central cone
	create_central_cone()

	print("Romanesco: Reset")

# Perform a single growth step
func step():
	perform_growth_iteration()
