extends Node3D

@export var cloth_resolution: int = 8
@export var cloth_stiffness: float = 100.0
@export var cloth_damping: float = 5.0
@export var wind_strength: float = 3.0
@export var gravity_strength: float = 9.8
@export var collision_strength: float = 50.0

class ClothNode:
	var position: Vector3
	var velocity: Vector3
	var force: Vector3
	var mass: float
	var is_fixed: bool
	var node: CSGSphere3D
	
	func _init(pos: Vector3, m: float, fixed: bool, n: CSGSphere3D):
		position = pos
		velocity = Vector3.ZERO
		force = Vector3.ZERO
		mass = m
		is_fixed = fixed
		node = n
	
	func apply_force(f: Vector3):
		if not is_fixed:
			force += f
	
	func update(delta: float):
		if is_fixed:
			return
		
		var acceleration = force / mass
		velocity += acceleration * delta
		position += velocity * delta
		force = Vector3.ZERO
		
		# Update visual node
		if node:
			node.position = position

class ClothPiece:
	var nodes: Array[ClothNode] = []
	var springs: Array[Array] = []
	var size: Vector2
	var position: Vector3
	
	func _init(cloth_size: Vector2, cloth_pos: Vector3, resolution: int):
		size = cloth_size
		position = cloth_pos
		create_nodes(resolution)
		create_springs(resolution)
	
	func create_nodes(resolution: int):
		for i in range(resolution + 1):
			for j in range(resolution + 1):
				var x = (i - resolution / 2.0) * size.x / resolution
				var z = (j - resolution / 2.0) * size.z / resolution
				var pos = position + Vector3(x, 0, z)
				
				# Determine if node is fixed (top edge for hanging cloth)
				var is_fixed = (i == 0 or i == resolution) and j == 0
				
				var node_visual = create_node_visual(Color.WHITE, 0.03)
				var cloth_node = ClothNode.new(pos, 1.0, is_fixed, node_visual)
				nodes.append(cloth_node)
	
	func create_springs(resolution: int):
		for i in range(resolution + 1):
			for j in range(resolution + 1):
				var idx = i * (resolution + 1) + j
				
				# Structural springs (horizontal and vertical)
				if j < resolution:
					springs.append([idx, idx + 1])
				if i < resolution:
					springs.append([idx, idx + resolution + 1])
				
				# Diagonal springs (shear)
				if i < resolution and j < resolution:
					springs.append([idx, idx + resolution + 1 + 1])
					springs.append([idx + 1, idx + resolution + 1])
	
	func create_node_visual(color: Color, radius: float) -> CSGSphere3D:
		var node = CSGSphere3D.new()
		node.radius = radius
		node.material = StandardMaterial3D.new()
		node.material.albedo_color = color
		node.material.emission_enabled = true
		node.material.emission = color
		node.material.emission_energy_multiplier = 0.2
		return node

var hanging_cloth: ClothPiece
var floating_cloth: ClothPiece
var draped_cloth: ClothPiece

var wind_sources: Array[Vector3] = []
var collision_spheres: Array[Vector3] = []
var collision_radii: Array[float] = []

var time: float = 0.0

func _ready():
	# Initialize cloth pieces
	hanging_cloth = ClothPiece.new(Vector2(1.5, 1.5), Vector3(-3, 0, 0), cloth_resolution)
	floating_cloth = ClothPiece.new(Vector2(1.2, 1.2), Vector3(0, 0, 0), cloth_resolution)
	draped_cloth = ClothPiece.new(Vector2(1.0, 1.0), Vector3(3, 0, 0), cloth_resolution)
	
	# Add cloth nodes to scene
	for node in hanging_cloth.nodes:
		$ClothPieces/HangingCloth/HangingClothNodes.add_child(node.node)
	
	for node in floating_cloth.nodes:
		$ClothPieces/FloatingCloth/FloatingClothNodes.add_child(node.node)
	
	for node in draped_cloth.nodes:
		$ClothPieces/DrapedCloth/DrapedClothNodes.add_child(node.node)
	
	# Initialize wind sources
	wind_sources = [
		$WindSources/WindField1.global_position,
		$WindSources/WindField2.global_position,
		$WindSources/WindField3.global_position
	]
	
	# Initialize collision spheres
	collision_spheres = [
		$CollisionObjects/Sphere1.global_position,
		$CollisionObjects/Sphere2.global_position,
		$CollisionObjects/Sphere3.global_position
	]
	collision_radii = [0.4, 0.3, 0.5]
	
	create_wind_streams()
	create_spring_visualizations()

func create_wind_streams():
	# Create wind stream particles for each wind source
	for i in range(wind_sources.size()):
		var wind_stream = $WindStreams.get_child(i)
		for j in range(20):
			var particle = create_wind_particle()
			particle.position = wind_sources[i] + Vector3(
				randf_range(-0.2, 0.2),
				randf_range(-0.2, 0.2),
				randf_range(-0.2, 0.2)
			)
			wind_stream.add_child(particle)

func create_wind_particle() -> CSGSphere3D:
	var particle = CSGSphere3D.new()
	particle.radius = 0.02
	particle.material = StandardMaterial3D.new()
	particle.material.albedo_color = Color.CYAN
	particle.material.emission_enabled = true
	particle.material.emission = Color.CYAN
	particle.material.emission_energy_multiplier = 0.4
	return particle

func create_spring_visualizations():
	# Create spring lines for all cloth pieces
	create_cloth_springs(hanging_cloth, $ClothPieces/HangingCloth/HangingClothNodes, Color.YELLOW)
	create_cloth_springs(floating_cloth, $ClothPieces/FloatingCloth/FloatingClothNodes, Color.CYAN)
	create_cloth_springs(draped_cloth, $ClothPieces/DrapedCloth/DrapedClothNodes, Color.MAGENTA)

func create_cloth_springs(cloth: ClothPiece, parent: Node3D, color: Color):
	for spring in cloth.springs:
		var line = create_spring_line(color, 0.01)
		parent.add_child(line)

func create_spring_line(color: Color, thickness: float) -> CSGCylinder3D:
	var line = CSGCylinder3D.new()
	line.radius = thickness
	line.height = 0.1
	line.material = StandardMaterial3D.new()
	line.material.albedo_color = color
	line.material.emission_enabled = true
	line.material.emission = color
	line.material.emission_energy_multiplier = 0.2
	return line

func _process(delta):
	time += delta
	
	# Apply forces to all cloth pieces
	apply_forces(hanging_cloth)
	apply_forces(floating_cloth)
	apply_forces(draped_cloth)
	
	# Update physics
	update_cloth_physics(hanging_cloth, delta)
	update_cloth_physics(floating_cloth, delta)
	update_cloth_physics(draped_cloth, delta)
	
	# Handle collisions
	handle_collisions(hanging_cloth)
	handle_collisions(floating_cloth)
	handle_collisions(draped_cloth)
	
	# Update spring constraints
	update_spring_constraints(hanging_cloth)
	update_spring_constraints(floating_cloth)
	update_spring_constraints(draped_cloth)
	
	# Animate wind sources and streams
	animate_wind_system(delta)
	
	# Update cloth meshes
	update_cloth_meshes()

func apply_forces(cloth: ClothPiece):
	for node in cloth.nodes:
		# Apply gravity
		node.apply_force(Vector3(0, -gravity_strength * node.mass, 0))
		
		# Apply wind forces
		for wind_source in wind_sources:
			var wind_direction = (node.position - wind_source).normalized()
			var distance = node.position.distance_to(wind_source)
			var wind_force = wind_direction * wind_strength / (distance * distance + 0.1)
			node.apply_force(wind_force)

func update_cloth_physics(cloth: ClothPiece, delta: float):
	for node in cloth.nodes:
		node.update(delta)

func handle_collisions(cloth: ClothPiece):
	for node in cloth.nodes:
		if node.is_fixed:
			continue
		
		# Check collision with spheres
		for i in range(collision_spheres.size()):
			var sphere_pos = collision_spheres[i]
			var sphere_radius = collision_radii[i]
			var distance = node.position.distance_to(sphere_pos)
			
			if distance < sphere_radius:
				# Push node away from sphere
				var push_direction = (node.position - sphere_pos).normalized()
				var push_distance = sphere_radius - distance
				node.position += push_direction * push_distance * 0.1
				
				# Apply collision force
				var collision_force = push_direction * collision_strength * push_distance
				node.apply_force(collision_force)
		
		# Self-collision (simplified)
		for other_node in cloth.nodes:
			if other_node != node and not other_node.is_fixed:
				var distance = node.position.distance_to(other_node.position)
				if distance < 0.1:
					var push_direction = (node.position - other_node.position).normalized()
					var push_distance = 0.1 - distance
					node.position += push_direction * push_distance * 0.05

func update_spring_constraints(cloth: ClothPiece):
	for spring in cloth.springs:
		var node1 = cloth.nodes[spring[0]]
		var node2 = cloth.nodes[spring[1]]
		
		var delta_pos = node2.position - node1.position
		var distance = delta_pos.length()
		var rest_length = 0.2  # Approximate rest length
		
		if distance > 0:
			var direction = delta_pos.normalized()
			var correction = direction * (distance - rest_length) * 0.5
			
			if not node1.is_fixed:
				node1.position += correction * 0.5
			if not node2.is_fixed:
				node2.position -= correction * 0.5

func animate_wind_system(delta: float):
	# Animate wind sources
	for i in range(wind_sources.size()):
		var wind_source = $WindSources.get_child(i)
		wind_source.position.y = wind_sources[i].y + sin(time * (2 + i)) * 0.2
		wind_source.scale = Vector3.ONE * (1.0 + sin(time * (3 + i)) * 0.1)
	
	# Animate wind streams
	for i in range($WindStreams.get_child_count()):
		var wind_stream = $WindStreams.get_child(i)
		wind_stream.rotation.y += delta * (1 + i * 0.5)
		
		# Move particles in wind direction
		for particle in wind_stream.get_children():
			particle.position += Vector3(0, -1, 0) * delta * 2.0
			
			# Reset particles that go too far
			if particle.position.y < -2:
				particle.position.y = 2

func update_cloth_meshes():
	# Update hanging cloth mesh based on node positions
	update_cloth_mesh(hanging_cloth, $ClothPieces/HangingCloth/HangingClothMesh)
	update_cloth_mesh(floating_cloth, $ClothPieces/FloatingCloth/FloatingClothMesh)
	update_cloth_mesh(draped_cloth, $ClothPieces/DrapedCloth/DrapedClothMesh)

func update_cloth_mesh(cloth: ClothPiece, mesh: CSGBox3D):
	# Calculate average position and deformation
	var avg_pos = Vector3.ZERO
	var max_deformation = 0.0
	
	for node in cloth.nodes:
		avg_pos += node.position
		var deformation = abs(node.position.y - cloth.position.y)
		max_deformation = max(max_deformation, deformation)
	
	avg_pos /= cloth.nodes.size()
	
	# Update mesh position and scale
	mesh.global_position = avg_pos
	mesh.scale.y = 1.0 + max_deformation * 2.0
