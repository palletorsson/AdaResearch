# boids_aquarium.gd
# A 1m glass cube containing a school of small boids
# Emergence artifact - demonstrates collective behavior from simple rules

extends Node3D

class_name BoidsAquarium

## Aquarium size (meters)
@export var cube_size: float = 1.0

## Number of boids
@export var num_boids: int = 30

## Boid visual scale
@export var boid_scale: float = 0.015

## Colors
@export var boid_color: Color = Color(0.2, 0.8, 1.0, 1.0)  # Cyan fish
@export var glass_color: Color = Color(0.6, 0.8, 1.0, 0.15)  # Subtle blue tint

## Boid behavior parameters
@export_group("Boid Behavior")
@export var max_speed: float = 0.5
@export var min_speed: float = 0.2
@export var perception_radius: float = 0.2
@export var avoid_radius: float = 0.05
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var separation_weight: float = 1.5
@export var boundary_weight: float = 2.0
@export var boundary_margin: float = 0.1

# Internal
var _boids: Array[Dictionary] = []
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _glass_mesh: MeshInstance3D
var _base_mesh: MeshInstance3D

func _ready():
	_create_glass_enclosure()
	_create_base()
	_create_boid_multimesh()
	_spawn_boids()

func _create_glass_enclosure():
	# Glass cube with visible edges
	_glass_mesh = MeshInstance3D.new()
	_glass_mesh.name = "GlassCube"
	
	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	_glass_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = glass_color
	mat.metallic = 0.1
	mat.roughness = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # See both sides
	_glass_mesh.material_override = mat
	
	_glass_mesh.position.y = cube_size / 2.0
	add_child(_glass_mesh)
	
	# Add subtle edge lines
	_create_edge_lines()

func _create_edge_lines():
	var edges = ImmediateMesh.new()
	var edge_instance = MeshInstance3D.new()
	edge_instance.name = "EdgeLines"
	
	var half = cube_size / 2.0
	var y_offset = cube_size / 2.0
	
	# Create edge material
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 0.6, 0.8, 0.5)
	
	edges.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	
	# Bottom edges
	var corners_bottom = [
		Vector3(-half, -half + y_offset, -half),
		Vector3(half, -half + y_offset, -half),
		Vector3(half, -half + y_offset, half),
		Vector3(-half, -half + y_offset, half)
	]
	# Top edges
	var corners_top = [
		Vector3(-half, half + y_offset, -half),
		Vector3(half, half + y_offset, -half),
		Vector3(half, half + y_offset, half),
		Vector3(-half, half + y_offset, half)
	]
	
	# Draw bottom square
	for i in range(4):
		edges.surface_add_vertex(corners_bottom[i])
		edges.surface_add_vertex(corners_bottom[(i + 1) % 4])
	
	# Draw top square
	for i in range(4):
		edges.surface_add_vertex(corners_top[i])
		edges.surface_add_vertex(corners_top[(i + 1) % 4])
	
	# Draw vertical edges
	for i in range(4):
		edges.surface_add_vertex(corners_bottom[i])
		edges.surface_add_vertex(corners_top[i])
	
	edges.surface_end()
	
	edge_instance.mesh = edges
	add_child(edge_instance)

func _create_base():
	# Pedestal base
	_base_mesh = MeshInstance3D.new()
	_base_mesh.name = "Base"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cube_size * 0.4
	cylinder.bottom_radius = cube_size * 0.45
	cylinder.height = 0.08
	_base_mesh.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.metallic = 0.8
	mat.roughness = 0.3
	_base_mesh.material_override = mat
	
	_base_mesh.position.y = -0.04
	add_child(_base_mesh)

func _create_boid_multimesh():
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = num_boids
	
	# Simple arrow/fish shape using a prism
	var mesh = PrismMesh.new()
	mesh.size = Vector3(boid_scale, boid_scale * 0.5, boid_scale * 2.0)
	_multimesh.mesh = mesh
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = boid_color
	mat.emission_energy_multiplier = 0.3
	
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "BoidMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)

func _spawn_boids():
	var half = (cube_size / 2.0) - boundary_margin
	var y_offset = cube_size / 2.0
	
	for i in range(num_boids):
		var boid = {
			"position": Vector3(
				randf_range(-half, half),
				randf_range(-half, half) + y_offset,
				randf_range(-half, half)
			),
			"velocity": Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			).normalized() * randf_range(min_speed, max_speed),
			"color": boid_color.lerp(Color.WHITE, randf() * 0.3)  # Slight variation
		}
		_boids.append(boid)
		_multimesh.set_instance_color(i, boid.color)

func _process(delta):
	_update_boids(delta)
	_update_multimesh()

func _update_boids(delta: float):
	var half = (cube_size / 2.0) - boundary_margin
	var y_center = cube_size / 2.0
	
	for i in range(_boids.size()):
		var boid = _boids[i]
		var pos = boid.position
		var vel = boid.velocity
		
		# Calculate flocking forces
		var alignment = Vector3.ZERO
		var cohesion = Vector3.ZERO
		var separation = Vector3.ZERO
		var neighbors = 0
		
		for j in range(_boids.size()):
			if i == j:
				continue
			
			var other = _boids[j]
			var dist = pos.distance_to(other.position)
			
			if dist < perception_radius:
				alignment += other.velocity
				cohesion += other.position
				neighbors += 1
				
				if dist < avoid_radius and dist > 0.001:
					var diff = pos - other.position
					separation += diff.normalized() / dist
		
		var acceleration = Vector3.ZERO
		
		if neighbors > 0:
			# Alignment
			alignment = (alignment / neighbors).normalized() * max_speed
			alignment = (alignment - vel).limit_length(max_speed * 0.5)
			acceleration += alignment * alignment_weight
			
			# Cohesion
			cohesion = cohesion / neighbors
			var to_center = (cohesion - pos).normalized() * max_speed
			to_center = (to_center - vel).limit_length(max_speed * 0.5)
			acceleration += to_center * cohesion_weight
			
			# Separation
			if separation.length() > 0:
				separation = separation.normalized() * max_speed
				separation = (separation - vel).limit_length(max_speed * 0.5)
				acceleration += separation * separation_weight
		
		# Boundary avoidance (soft walls)
		var boundary_force = Vector3.ZERO
		var margin_zone = boundary_margin * 2
		
		# X bounds
		if pos.x > half - margin_zone:
			boundary_force.x = -((pos.x - (half - margin_zone)) / margin_zone)
		elif pos.x < -half + margin_zone:
			boundary_force.x = -(pos.x - (-half + margin_zone)) / margin_zone
		
		# Y bounds (relative to center)
		var local_y = pos.y - y_center
		if local_y > half - margin_zone:
			boundary_force.y = -((local_y - (half - margin_zone)) / margin_zone)
		elif local_y < -half + margin_zone:
			boundary_force.y = -(local_y - (-half + margin_zone)) / margin_zone
		
		# Z bounds
		if pos.z > half - margin_zone:
			boundary_force.z = -((pos.z - (half - margin_zone)) / margin_zone)
		elif pos.z < -half + margin_zone:
			boundary_force.z = -(pos.z - (-half + margin_zone)) / margin_zone
		
		acceleration += boundary_force * boundary_weight * max_speed
		
		# Update velocity
		vel += acceleration * delta
		vel = vel.limit_length(max_speed)
		if vel.length() < min_speed:
			vel = vel.normalized() * min_speed
		
		# Update position
		pos += vel * delta
		
		# Hard clamp (safety)
		pos.x = clamp(pos.x, -half, half)
		pos.y = clamp(pos.y, y_center - half, y_center + half)
		pos.z = clamp(pos.z, -half, half)
		
		boid.position = pos
		boid.velocity = vel

func _update_multimesh():
	for i in range(_boids.size()):
		var boid = _boids[i]
		var transform = Transform3D()
		
		# Position
		transform.origin = boid.position
		
		# Rotation - look in direction of movement
		if boid.velocity.length_squared() > 0.0001:
			var forward = boid.velocity.normalized()
			var up = Vector3.UP
			if abs(forward.dot(up)) > 0.99:
				up = Vector3.FORWARD
			var right = up.cross(forward).normalized()
			up = forward.cross(right).normalized()
			transform.basis = Basis(right, up, forward)
		
		_multimesh.set_instance_transform(i, transform)

## Set boid color dynamically
func set_boid_color(color: Color):
	boid_color = color
	for i in range(_boids.size()):
		var variation = boid_color.lerp(Color.WHITE, randf() * 0.3)
		_boids[i].color = variation
		_multimesh.set_instance_color(i, variation)

## Reset boids to random positions
func reset():
	_boids.clear()
	_spawn_boids()
