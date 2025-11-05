@tool
extends Node3D

# Spring Network Visualizer
# Demonstrates wave propagation through interconnected springs
# Based on Hooke's Law: F = -k * (x - rest_length)

@export_group("Network Grid")
@export var grid_size: Vector2i = Vector2i(10, 10)
@export var node_spacing: float = 0.5
@export var network_height: float = 1.5

@export_group("Spring Physics")
@export var spring_constant: float = 50.0
@export var damping: float = 0.95
@export var mass: float = 1.0
@export var rest_length: float = 0.5

@export_group("Wave Excitation")
@export var excitation_strength: float = 2.0
@export var excitation_frequency: float = 1.0
@export var auto_excite: bool = true

@export_group("Visualization")
@export var show_nodes: bool = true
@export var show_springs: bool = true
@export var node_radius: float = 0.05
@export var spring_thickness: float = 0.02
@export var color_by_velocity: bool = true

# Internal data
var nodes: Array[Dictionary] = []
var springs: Array[Dictionary] = []
var time: float = 0.0

class NetworkNode:
	var index: int
	var position: Vector3
	var velocity: Vector3 = Vector3.ZERO
	var force: Vector3 = Vector3.ZERO
	var fixed: bool = false

	func _init(idx: int, pos: Vector3):
		index = idx
		position = pos

class Spring:
	var node_a: int
	var node_b: int
	var rest_length: float

	func _init(a: int, b: int, rest: float):
		node_a = a
		node_b = b
		rest_length = rest

func _ready() -> void:
	_build_network()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	time += delta

	# Apply excitation
	if auto_excite and nodes.size() > 0:
		var center_idx = int(grid_size.x / 2) * grid_size.y + int(grid_size.y / 2)
		if center_idx < nodes.size():
			var excitation = sin(time * excitation_frequency * TAU) * excitation_strength
			nodes[center_idx].force.y += excitation

	# Update physics
	_update_physics(delta)

	# Update visualization
	_update_visualization()

func _build_network() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()

	nodes.clear()
	springs.clear()

	# Create network nodes
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var idx = x * grid_size.y + y
			var pos = Vector3(
				(x - grid_size.x / 2.0) * node_spacing,
				network_height,
				(y - grid_size.y / 2.0) * node_spacing
			)

			var node_data = {
				"index": idx,
				"position": pos,
				"velocity": Vector3.ZERO,
				"force": Vector3.ZERO,
				"fixed": false
			}

			# Fix corner nodes
			if (x == 0 or x == grid_size.x - 1) and (y == 0 or y == grid_size.y - 1):
				node_data.fixed = true

			nodes.append(node_data)

	# Create springs connecting neighbors
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var idx = x * grid_size.y + y

			# Connect to right neighbor
			if x < grid_size.x - 1:
				var neighbor_idx = (x + 1) * grid_size.y + y
				springs.append({
					"node_a": idx,
					"node_b": neighbor_idx,
					"rest_length": rest_length
				})

			# Connect to down neighbor
			if y < grid_size.y - 1:
				var neighbor_idx = x * grid_size.y + (y + 1)
				springs.append({
					"node_a": idx,
					"node_b": neighbor_idx,
					"rest_length": rest_length
				})

			# Diagonal springs for stability
			if x < grid_size.x - 1 and y < grid_size.y - 1:
				var neighbor_idx = (x + 1) * grid_size.y + (y + 1)
				springs.append({
					"node_a": idx,
					"node_b": neighbor_idx,
					"rest_length": rest_length * sqrt(2.0)
				})

	_create_visualization()

func _update_physics(delta: float) -> void:
	# Reset forces
	for node in nodes:
		node.force = Vector3.ZERO

	# Calculate spring forces (Hooke's Law)
	for spring in springs:
		var node_a = nodes[spring.node_a]
		var node_b = nodes[spring.node_b]

		var displacement = node_b.position - node_a.position
		var distance = displacement.length()
		var direction = displacement.normalized() if distance > 0.001 else Vector3.ZERO

		# F = -k * (x - rest_length)
		var force_magnitude = spring_constant * (distance - spring.rest_length)
		var force = direction * force_magnitude

		node_a.force += force
		node_b.force -= force

	# Add gravity
	for node in nodes:
		node.force.y -= 9.8 * mass

	# Integrate (Euler)
	for node in nodes:
		if node.fixed:
			continue

		# F = ma, so a = F/m
		var acceleration = node.force / mass

		# Update velocity
		node.velocity += acceleration * delta
		node.velocity *= damping  # Apply damping

		# Update position
		node.position += node.velocity * delta

func _create_visualization() -> void:
	# Create node spheres
	if show_nodes:
		for node in nodes:
			var sphere = MeshInstance3D.new()
			sphere.name = "Node_%d" % node.index
			var mesh = SphereMesh.new()
			mesh.radius = node_radius
			mesh.height = node_radius * 2.0
			sphere.mesh = mesh

			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.2, 0.7, 1.0) if node.fixed else Color(0.9, 0.3, 0.3)
			mat.metallic = 0.0
			mat.roughness = 1.0
			sphere.material_override = mat

			sphere.position = node.position
			add_child(sphere)

func _update_visualization() -> void:
	# Update node positions and colors
	var node_idx = 0
	for child in get_children():
		if child.name.begins_with("Node_"):
			if node_idx < nodes.size():
				var node = nodes[node_idx]
				child.position = node.position

				# Color by velocity if enabled
				if color_by_velocity and child is MeshInstance3D:
					var vel_magnitude = node.velocity.length()
					var color_intensity = clamp(vel_magnitude / 5.0, 0.0, 1.0)
					var mat = child.material_override as StandardMaterial3D
					if mat:
						mat.albedo_color = Color(color_intensity, 0.3, 1.0 - color_intensity)

				node_idx += 1

	# Note: Spring visualization would require ImmediateMesh for 3D rendering
	# Removed queue_redraw() as it doesn't exist for Node3D

func get_node_at_index(idx: int) -> Dictionary:
	if idx >= 0 and idx < nodes.size():
		return nodes[idx]
	return {}

func apply_impulse(node_idx: int, impulse: Vector3) -> void:
	if node_idx >= 0 and node_idx < nodes.size():
		nodes[node_idx].velocity += impulse / mass
