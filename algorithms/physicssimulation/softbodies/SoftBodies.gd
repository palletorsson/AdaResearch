extends Node3D

@export var node_resolution: int = 6
@export var stiffness: float = 100.0
@export var damping: float = 5.0
@export var pressure_strength: float = 50.0
@export var gravity_strength: float = 9.8
@export var volume_preservation: float = 0.8

class SoftBodyNode:
	var position: Vector3
	var velocity: Vector3
	var force: Vector3
	var mass: float
	var rest_position: Vector3
	var node: CSGSphere3D
	
	func _init(pos: Vector3, m: float, n: CSGSphere3D):
		position = pos
		rest_position = pos
		velocity = Vector3.ZERO
		force = Vector3.ZERO
		mass = m
		node = n
	
	func apply_force(f: Vector3):
		force += f
	
	func update(delta: float):
		var acceleration = force / mass
		velocity += acceleration * delta
		position += velocity * delta
		force = Vector3.ZERO
		
		# Update visual node
		if node:
			node.position = position

class SoftBody:
	var nodes: Array[SoftBodyNode] = []
	var springs: Array[Array] = []
	var tetrahedra: Array[Array] = []
	var rest_volume: float
	var current_volume: float
	var center: Vector3
	var mesh: Node3D
	
	func _init(body_center: Vector3, body_mesh: Node3D, resolution: int):
		center = body_center
		mesh = body_mesh
		create_nodes(resolution)
		create_springs(resolution)
		create_tetrahedra(resolution)
		calculate_rest_volume()
	
	func create_nodes(resolution: int):
		var node_spacing = 0.2
		var half_size = resolution * node_spacing / 2.0
		
		for i in range(-resolution, resolution + 1):
			for j in range(-resolution, resolution + 1):
				for k in range(-resolution, resolution + 1):
					var pos = center + Vector3(
						i * node_spacing,
						j * node_spacing,
						k * node_spacing
					)
					
					# Check if node is inside the body shape
					if is_inside_body(pos):
						var node_visual = create_node_visual(Color.WHITE, 0.03)
						var soft_node = SoftBodyNode.new(pos, 1.0, node_visual)
						nodes.append(soft_node)
	
	func is_inside_body(pos: Vector3) -> bool:
		var local_pos = pos - center
		var distance = local_pos.length()
		
		# Different shapes for different soft bodies
		if center.x < -1:  # Jelly cube
			return abs(local_pos.x) < 0.5 and abs(local_pos.y) < 0.5 and abs(local_pos.z) < 0.5
		elif center.x > 1:  # Cylinder
			var radial_dist = sqrt(local_pos.x * local_pos.x + local_pos.z * local_pos.z)
			return radial_dist < 0.5 and abs(local_pos.y) < 0.75
		else:  # Blob sphere
			return distance < 0.8
	
	func create_springs(resolution: int):
		for i in range(nodes.size()):
			for j in range(i + 1, nodes.size()):
				var distance = nodes[i].position.distance_to(nodes[j].position)
				if distance < 0.3:  # Connect nearby nodes
					springs.append([i, j, distance])
	
	func create_tetrahedra(resolution: int):
		# Create tetrahedral elements for volume calculation
		for i in range(0, nodes.size() - 3, 4):
			if i + 3 < nodes.size():
				tetrahedra.append([i, i + 1, i + 2, i + 3])
	
	func create_node_visual(color: Color, radius: float) -> CSGSphere3D:
		var node = CSGSphere3D.new()
		node.radius = radius
		node.material = StandardMaterial3D.new()
		node.material.albedo_color = color
		node.material.emission_enabled = true
		node.material.emission = color
		node.material.emission_energy_multiplier = 0.2
		return node
	
	func calculate_rest_volume():
		rest_volume = calculate_current_volume()
		current_volume = rest_volume
	
	func calculate_current_volume() -> float:
		var total_volume = 0.0
		
		for tetra in tetrahedra:
			if tetra.size() == 4:
				var v1 = nodes[tetra[0]].position
				var v2 = nodes[tetra[1]].position
				var v3 = nodes[tetra[2]].position
				var v4 = nodes[tetra[3]].position
				
				var volume = abs((v2 - v1).cross(v3 - v1).dot(v4 - v1)) / 6.0
				total_volume += volume
		
		return total_volume

var jelly_cube: SoftBody
var blob_sphere: SoftBody
var deformable_cylinder: SoftBody

var pressure_sources: Array[Vector3] = []
var collision_objects: Array[Vector3] = []
var collision_radii: Array[float] = []

var time: float = 0.0

func _ready():
	# Initialize soft bodies
	jelly_cube = SoftBody.new(Vector3(-3, 0, 0), $SoftBodyObjects/JellyCube, node_resolution)
	blob_sphere = SoftBody.new(Vector3(0, 0, 0), $SoftBodyObjects/BlobSphere, node_resolution)
	deformable_cylinder = SoftBody.new(Vector3(3, 0, 0), $SoftBodyObjects/DeformableCylinder, node_resolution)
	
	# Add nodes to scene
	for node in jelly_cube.nodes:
		$SoftBodyObjects/JellyCube/JellyCubeNodes.add_child(node.node)
	
	for node in blob_sphere.nodes:
		$SoftBodyObjects/BlobSphere/BlobSphereNodes.add_child(node.node)
	
	for node in deformable_cylinder.nodes:
		$SoftBodyObjects/DeformableCylinder/DeformableCylinderNodes.add_child(node.node)
	
	# Initialize pressure sources
	pressure_sources = [
		$PressureSources/PressureField1.global_position,
		$PressureSources/PressureField2.global_position,
		$PressureSources/PressureField3.global_position
	]
	
	# Initialize collision objects
	collision_objects = [
		$CollisionObjects/Obstacle1.global_position,
		$CollisionObjects/Obstacle2.global_position,
		$CollisionObjects/Obstacle3.global_position
	]
	collision_radii = [0.4, 0.3, 0.5]
	
	create_spring_visualizations()
	create_tetrahedra_visualizations()

func create_spring_visualizations():
	# Create spring lines for all soft bodies
	create_soft_body_springs(jelly_cube, $SoftBodyObjects/JellyCube/JellyCubeSprings, Color.YELLOW)
	create_soft_body_springs(blob_sphere, $SoftBodyObjects/BlobSphere/BlobSphereSprings, Color.CYAN)
	create_soft_body_springs(deformable_cylinder, $SoftBodyObjects/DeformableCylinder/DeformableCylinderSprings, Color.MAGENTA)

func create_soft_body_springs(soft_body: SoftBody, parent: Node3D, color: Color):
	for spring in soft_body.springs:
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

func create_tetrahedra_visualizations():
	# Create wireframe visualization for tetrahedra
	create_tetrahedra_wireframes(jelly_cube, $SoftBodyObjects/JellyCube/JellyCubeSprings, Color.ORANGE)
	create_tetrahedra_wireframes(blob_sphere, $SoftBodyObjects/BlobSphere/BlobSphereSprings, Color.GREEN)
	create_tetrahedra_wireframes(deformable_cylinder, $SoftBodyObjects/DeformableCylinder/DeformableCylinderSprings, Color.PURPLE)

func create_tetrahedra_wireframes(soft_body: SoftBody, parent: Node3D, color: Color):
	for tetra in soft_body.tetrahedra:
		if tetra.size() == 4:
			# Create edges of tetrahedron
			var edges = [
				[tetra[0], tetra[1]],
				[tetra[0], tetra[2]],
				[tetra[0], tetra[3]],
				[tetra[1], tetra[2]],
				[tetra[1], tetra[3]],
				[tetra[2], tetra[3]]
			]
			
			for edge in edges:
				var line = create_spring_line(color, 0.005)
				parent.add_child(line)

func _process(delta):
	time += delta
	
	# Apply forces to all soft bodies
	apply_forces(jelly_cube)
	apply_forces(blob_sphere)
	apply_forces(deformable_cylinder)
	
	# Update physics
	update_soft_body_physics(jelly_cube, delta)
	update_soft_body_physics(blob_sphere, delta)
	update_soft_body_physics(deformable_cylinder, delta)
	
	# Handle collisions
	handle_collisions(jelly_cube)
	handle_collisions(blob_sphere)
	handle_collisions(deformable_cylinder)
	
	# Update spring constraints
	update_spring_constraints(jelly_cube)
	update_spring_constraints(blob_sphere)
	update_spring_constraints(deformable_cylinder)
	
	# Update pressure forces
	update_pressure_forces()
	
	# Update volume preservation
	update_volume_preservation()
	
	# Animate pressure sources
	animate_pressure_sources(delta)
	
	# Update soft body meshes
	update_soft_body_meshes()
	
	# Update volume indicators
	update_volume_indicators()
	
	# Animate physics parameters
	animate_physics_parameters(delta)

func apply_forces(soft_body: SoftBody):
	for node in soft_body.nodes:
		# Apply gravity
		node.apply_force(Vector3(0, -gravity_strength * node.mass, 0))
		
		# Apply pressure forces
		for pressure_source in pressure_sources:
			var pressure_direction = (node.position - pressure_source).normalized()
			var distance = node.position.distance_to(pressure_source)
			var pressure_force = pressure_direction * pressure_strength / (distance * distance + 0.1)
			node.apply_force(pressure_force)

func update_soft_body_physics(soft_body: SoftBody, delta: float):
	for node in soft_body.nodes:
		node.update(delta)

func handle_collisions(soft_body: SoftBody):
	for node in soft_body.nodes:
		# Check collision with ground
		if node.position.y < -2:
			node.position.y = -2
			node.velocity.y = -node.velocity.y * 0.3
		
		# Check collision with obstacles
		for i in range(collision_objects.size()):
			var obstacle_pos = collision_objects[i]
			var obstacle_radius = collision_radii[i]
			var distance = node.position.distance_to(obstacle_pos)
			
			if distance < obstacle_radius:
				var push_direction = (node.position - obstacle_pos).normalized()
				var push_distance = obstacle_radius - distance
				node.position += push_direction * push_distance * 0.1
				
				# Apply collision force
				var collision_force = push_direction * 100.0 * push_distance
				node.apply_force(collision_force)

func update_spring_constraints(soft_body: SoftBody):
	for spring in soft_body.springs:
		var node1 = soft_body.nodes[spring[0]]
		var node2 = soft_body.nodes[spring[1]]
		var rest_length = spring[2]
		
		var delta_pos = node2.position - node1.position
		var distance = delta_pos.length()
		
		if distance > 0:
			var direction = delta_pos.normalized()
			var correction = direction * (distance - rest_length) * 0.5
			
			node1.position += correction * 0.5
			node2.position -= correction * 0.5

func update_pressure_forces():
	# Update pressure forces based on volume changes
	update_body_pressure(jelly_cube)
	update_body_pressure(blob_sphere)
	update_body_pressure(deformable_cylinder)

func update_body_pressure(soft_body: SoftBody):
	soft_body.current_volume = soft_body.calculate_current_volume()
	var volume_ratio = soft_body.current_volume / soft_body.rest_volume
	
	if volume_ratio < 0.8:  # Volume decreased
		# Apply outward pressure to restore volume
		for node in soft_body.nodes:
			var outward_direction = (node.position - soft_body.center).normalized()
			var pressure_force = outward_direction * pressure_strength * (1.0 - volume_ratio)
			node.apply_force(pressure_force)

func update_volume_preservation():
	# Apply volume preservation forces
	apply_volume_preservation(jelly_cube)
	apply_volume_preservation(blob_sphere)
	apply_volume_preservation(deformable_cylinder)

func apply_volume_preservation(soft_body: SoftBody):
	var current_volume = soft_body.calculate_current_volume()
	var volume_change = current_volume - soft_body.rest_volume
	
	if abs(volume_change) > 0.01:
		var volume_correction = volume_change * volume_preservation
		
		# Apply correction forces to all nodes
		for node in soft_body.nodes:
			var correction_direction = (soft_body.center - node.position).normalized()
			var correction_force = correction_direction * volume_correction * 10.0
			node.apply_force(correction_force)

func animate_pressure_sources(delta: float):
	# Animate pressure field positions
	for i in range(pressure_sources.size()):
		var pressure_field = $PressureSources.get_child(i)
		pressure_field.position.y = pressure_sources[i].y + sin(time * (1 + i)) * 0.2
		pressure_field.scale = Vector3.ONE * (1.0 + sin(time * (2 + i)) * 0.1)

func update_soft_body_meshes():
	# Update mesh positions based on node positions
	update_soft_body_mesh(jelly_cube, $SoftBodyObjects/JellyCube/JellyCubeMesh)
	update_soft_body_mesh(blob_sphere, $SoftBodyObjects/BlobSphere/BlobSphereMesh)
	update_soft_body_mesh(deformable_cylinder, $SoftBodyObjects/DeformableCylinder/DeformableCylinderMesh)

func update_soft_body_mesh(soft_body: SoftBody, mesh: Node3D):
	# Calculate center of mass
	var center_of_mass = Vector3.ZERO
	for node in soft_body.nodes:
		center_of_mass += node.position
	center_of_mass /= soft_body.nodes.size()
	
	# Update mesh position
	mesh.global_position = center_of_mass
	
	# Calculate deformation and update mesh scale
	var max_deformation = 0.0
	for node in soft_body.nodes:
		var deformation = node.position.distance_to(soft_body.center)
		max_deformation = max(max_deformation, deformation)
	
	# Apply deformation to mesh
	var deformation_factor = 1.0 + max_deformation * 0.5
	mesh.scale = Vector3.ONE * deformation_factor

func update_volume_indicators():
	# Update volume indicator scales based on volume changes
	var jelly_volume_ratio = jelly_cube.current_volume / jelly_cube.rest_volume
	var blob_volume_ratio = blob_sphere.current_volume / blob_sphere.rest_volume
	var cylinder_volume_ratio = deformable_cylinder.current_volume / deformable_cylinder.rest_volume
	
	$VolumeIndicators/JellyVolume.scale = Vector3.ONE * (0.5 + jelly_volume_ratio * 0.5)
	$VolumeIndicators/BlobVolume.scale = Vector3.ONE * (0.5 + blob_volume_ratio * 0.5)
	$VolumeIndicators/CylinderVolume.scale = Vector3.ONE * (0.5 + cylinder_volume_ratio * 0.5)

func animate_physics_parameters(delta: float):
	# Animate stiffness control
	var stiffness_control = $PhysicsParameters/StiffnessControl
	stiffness_control.scale = Vector3.ONE * (1.0 + sin(time * 2.0) * 0.1)
	stiffness_control.rotation.y += delta * 1.0
	
	# Animate damping control
	var damping_control = $PhysicsParameters/DampingControl
	damping_control.scale = Vector3.ONE * (1.0 + sin(time * 3.0) * 0.1)
	damping_control.rotation.z += delta * 1.5
	
	# Animate pressure control
	var pressure_control = $PhysicsParameters/PressureControl
	pressure_control.scale = Vector3.ONE * (1.0 + sin(time * 4.0) * 0.1)
	pressure_control.rotation.x += delta * 2.0
