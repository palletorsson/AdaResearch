extends Node3D

@export var grid_size: int = 5
@export var chain_length: int = 8
@export var cloth_size: int = 6
@export var spring_constant: float = 50.0
@export var damping_coefficient: float = 2.0
@export var mass_value: float = 1.0
@export var gravity_strength: float = 9.8
@export var wind_strength: float = 2.0

class Mass:
	var position: Vector3
	var velocity: Vector3
	var force: Vector3
	var mass: float
	var node: CSGSphere3D
	
	func _init(pos: Vector3, m: float, n: CSGSphere3D):
		position = pos
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

class Spring:
	var mass1: Mass
	var mass2: Mass
	var rest_length: float
	var k: float
	var c: float
	var line: CSGCylinder3D
	
	func _init(m1: Mass, m2: Mass, rest_len: float, spring_k: float, damping_c: float):
		mass1 = m1
		mass2 = m2
		rest_length = rest_len
		k = spring_k
		c = damping_c
		line = null
	
	func update():
		var delta_pos = mass2.position - mass1.position
		var distance = delta_pos.length()
		var direction = delta_pos.normalized()
		
		# Spring force (Hooke's law)
		var spring_force = direction * (distance - rest_length) * k
		
		# Damping force
		var relative_velocity = mass2.velocity - mass1.velocity
		var damping_force = direction * direction.dot(relative_velocity) * c
		
		var total_force = spring_force + damping_force
		
		mass1.apply_force(total_force)
		mass2.apply_force(-total_force)
		
		# Update spring line visualization
		if line:
			line.position = (mass1.position + mass2.position) / 2
			line.look_at(mass2.position)
			line.rotation.z += PI / 2

var grid_masses: Array[Mass] = []
var chain_masses: Array[Mass] = []
var cloth_masses: Array[Mass] = []
var grid_springs: Array[Spring] = []
var chain_springs: Array[Spring] = []
var cloth_springs: Array[Spring] = []

var time: float = 0.0

func _ready():
	create_grid_structure()
	create_chain_structure()
	create_cloth_structure()
	create_spring_visualizations()

func create_grid_structure():
	# Create grid of masses
	for i in range(grid_size):
		for j in range(grid_size):
			var pos = Vector3(
				(i - grid_size / 2.0) * 0.5,
				(j - grid_size / 2.0) * 0.5,
				0
			)
			var mass_node = create_mass_node(Color.ORANGE, 0.08)
			var mass = Mass.new(pos, mass_value, mass_node)
			$MassSpringSystem/GridStructure.add_child(mass_node)
			grid_masses.append(mass)
	
	# Create springs between adjacent masses
	for i in range(grid_size):
		for j in range(grid_size):
			var idx = i * grid_size + j
			
			# Horizontal springs
			if j < grid_size - 1:
				var spring = Spring.new(
					grid_masses[idx],
					grid_masses[idx + 1],
					0.5,
					spring_constant,
					damping_coefficient
				)
				grid_springs.append(spring)
			
			# Vertical springs
			if i < grid_size - 1:
				var spring = Spring.new(
					grid_masses[idx],
					grid_masses[idx + grid_size],
					0.5,
					spring_constant,
					damping_coefficient
				)
				grid_springs.append(spring)

func create_chain_structure():
	# Create chain of masses
	for i in range(chain_length):
		var pos = Vector3(0, -i * 0.3, 0)
		var mass_node = create_mass_node(Color.BLUE, 0.1)
		var mass = Mass.new(pos, mass_value, mass_node)
		$MassSpringSystem/ChainStructure.add_child(mass_node)
		chain_masses.append(mass)
	
	# Create springs between consecutive masses
	for i in range(chain_length - 1):
		var spring = Spring.new(
			chain_masses[i],
			chain_masses[i + 1],
			0.3,
			spring_constant,
			damping_coefficient
		)
		chain_springs.append(spring)

func create_cloth_structure():
	# Create cloth grid of masses
	for i in range(cloth_size):
		for j in range(cloth_size):
			var pos = Vector3(
				(i - cloth_size / 2.0) * 0.4,
				0,
				(j - cloth_size / 2.0) * 0.4
			)
			var mass_node = create_mass_node(Color.MAGENTA, 0.06)
			var mass = Mass.new(pos, mass_value, mass_node)
			$MassSpringSystem/ClothStructure.add_child(mass_node)
			cloth_masses.append(mass)
	
	# Create cloth springs (structural, shear, and bending)
	for i in range(cloth_size):
		for j in range(cloth_size):
			var idx = i * cloth_size + j
			
			# Structural springs (horizontal and vertical)
			if j < cloth_size - 1:
				var spring = Spring.new(
					cloth_masses[idx],
					cloth_masses[idx + 1],
					0.4,
					spring_constant,
					damping_coefficient
				)
				cloth_springs.append(spring)
			
			if i < cloth_size - 1:
				var spring = Spring.new(
					cloth_masses[idx],
					cloth_masses[idx + cloth_size],
					0.4,
					spring_constant,
					damping_coefficient
				)
				cloth_springs.append(spring)
			
			# Diagonal springs (shear)
			if i < cloth_size - 1 and j < cloth_size - 1:
				var spring = Spring.new(
					cloth_masses[idx],
					cloth_masses[idx + cloth_size + 1],
					0.4 * sqrt(2.0),
					spring_constant * 0.7,
					damping_coefficient
				)
				cloth_springs.append(spring)

func create_mass_node(color: Color, radius: float) -> CSGSphere3D:
	var node = CSGSphere3D.new()
	node.radius = radius
	node.material = StandardMaterial3D.new()
	node.material.albedo_color = color
	node.material.emission_enabled = true
	node.material.emission = color
	node.material.emission_energy_multiplier = 0.3
	return node

func create_spring_visualizations():
	# Create spring lines for grid
	for spring in grid_springs:
		var line = create_spring_line(Color.YELLOW, 0.02)
		$MassSpringSystem/GridStructure.add_child(line)
		spring.line = line
	
	# Create spring lines for chain
	for spring in chain_springs:
		var line = create_spring_line(Color.CYAN, 0.03)
		$MassSpringSystem/ChainStructure.add_child(line)
		spring.line = line
	
	# Create spring lines for cloth
	for spring in cloth_springs:
		var line = create_spring_line(Color.MAGENTA, 0.015)
		$MassSpringSystem/ClothStructure.add_child(line)
		spring.line = line

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
	
	# Apply forces
	apply_forces()
	
	# Update physics
	update_physics(delta)
	
	# Update spring visualizations
	update_springs()
	
	# Animate force sources
	animate_force_sources()

func apply_forces():
	# Apply gravity to all masses
	for mass in grid_masses + chain_masses + cloth_masses:
		mass.apply_force(Vector3(0, -gravity_strength * mass.mass, 0))
	
	# Apply wind force to cloth
	var wind_direction = Vector3(sin(time), 0, cos(time))
	for mass in cloth_masses:
		var wind_force = wind_direction * wind_strength * 0.1
		mass.apply_force(wind_force)
	
	# Apply external force to chain
	var external_force = Vector3(sin(time * 2) * 2.0, 0, 0)
	if chain_masses.size() > 0:
		chain_masses[0].apply_force(external_force)

func update_physics(delta):
	# Update grid masses
	for mass in grid_masses:
		mass.update(delta)
	
	# Update chain masses
	for mass in chain_masses:
		mass.update(delta)
	
	# Update cloth masses
	for mass in cloth_masses:
		mass.update(delta)

func update_springs():
	# Update all springs
	for spring in grid_springs + chain_springs + cloth_springs:
		spring.update()

func animate_force_sources():
	# Animate wind force
	var wind_force = $ForceSources/WindForce
	wind_force.position.x = sin(time) * 1.0
	wind_force.position.z = cos(time) * 1.0
	
	# Animate gravity force
	var gravity_force = $ForceSources/GravityForce
	gravity_force.scale = Vector3.ONE * (1.0 + sin(time * 3) * 0.2)
	
	# Animate external force
	var external_force = $ForceSources/ExternalForce
	external_force.position.x = sin(time * 2) * 1.5
	
	# Animate parameter indicators
	var spring_constant_node = $Parameters/SpringConstant
	var damping_coefficient_node = $Parameters/DampingCoefficient
	var mass_value_node = $Parameters/MassValue
	
	spring_constant_node.scale = Vector3.ONE * (1.0 + sin(time * 4) * 0.1)
	damping_coefficient_node.scale = Vector3.ONE * (1.0 + sin(time * 5) * 0.1)
	mass_value_node.scale = Vector3.ONE * (1.0 + sin(time * 6) * 0.1)
