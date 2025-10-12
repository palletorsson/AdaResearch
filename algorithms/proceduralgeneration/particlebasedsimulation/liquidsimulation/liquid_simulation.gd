extends Node3D

class_name LiquidSimulation

# Liquid container and simulation parameters
@export var container_size: Vector3 = Vector3(2.0, 1.0, 2.0)
@export var particle_count: int = 100
@export var simulation_steps_per_frame: int = 5
@export var gravity: float = 9.8
@export var viscosity_multiplier: float = 1.0
@export var diffusion_rate: float = 0.05
@export var show_entropy: bool = true

# Internal variables
var particle_data = []
var neighbor_grid = {}
var grid_cell_size: float = 1.0
var entropy_value: float = 0.0
var max_entropy: float = 0.0
var spatial_material: ShaderMaterial
var entropy_label: Label3D

# Liquid types
class LiquidType:
	var name: String
	var base_color: Color
	var density: float
	var viscosity: float
	
	func _init(p_name: String, p_color: Color, p_density: float, p_viscosity: float):
		name = p_name
		base_color = p_color
		density = p_density
		viscosity = p_viscosity

# Define liquid types
var liquid_types = {
	"water": LiquidType.new("Water", Color(0.2, 0.4, 0.8, 0.8), 1.0, 1.0),
	"oil": LiquidType.new("Oil", Color(0.8, 0.7, 0.2, 0.8), 0.8, 5.0),
	"honey": LiquidType.new("Honey", Color(0.9, 0.7, 0.1, 0.9), 1.4, 20.0)
}

# Particle class
class LiquidParticle:
	var position: Vector3
	var velocity: Vector3
	var acceleration: Vector3
	var liquid_type: String
	var mesh_instance: MeshInstance3D
	var mixed_properties = {}
	var neighbors = []
	
	func _init(pos: Vector3, type: String, mesh: MeshInstance3D):
		position = pos
		velocity = Vector3.ZERO
		acceleration = Vector3.ZERO
		liquid_type = type
		mesh_instance = mesh
		# Initialize as pure liquid
		mixed_properties = {
			type: 1.0  # Concentration of this type is 100%
		}

func _ready():
	# Set up the container
	_create_container()
	
	# Initialize particle system
	_initialize_particles()
	
	# Set up entropy display
	_setup_entropy_display()
	
	# Set up shader material for visualization
	_setup_material()

func _create_container():
	# Create a transparent container
	var container_mesh = BoxMesh.new()
	container_mesh.size = container_size
	
	var container_instance = MeshInstance3D.new()
	container_instance.mesh = container_mesh
	
	var container_material = StandardMaterial3D.new()
	container_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	container_material.albedo_color = Color(0.8, 0.8, 0.9, 0.2)
	container_mesh.surface_set_material(0, container_material)
	
	add_child(container_instance)

func _initialize_particles():
	# Set up grid cell size based on typical interaction distance
	grid_cell_size = container_size.x / 20
	
	# Create particles
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.1
	particle_mesh.height = 0.2
	
	var half_container = container_size / 2
	
	# Split particles between two liquid types for initial setup
	var half_count = particle_count / 2
	
	for i in range(particle_count):
		var instance = MeshInstance3D.new()
		instance.mesh = particle_mesh
		add_child(instance)
		
		var liquid_key = "water" if i < half_count else "oil"
		
		# Position particles on either side of the container
		var x_offset = -half_container.x / 2 if i < half_count else half_container.x / 2
		var position = Vector3(
			randf_range(-half_container.x / 4, half_container.x / 4) + x_offset,
			randf_range(-half_container.y / 2, half_container.y / 2), 
			randf_range(-half_container.z / 2, half_container.z / 2)
		)
		
		var particle = LiquidParticle.new(position, liquid_key, instance)
		particle_data.append(particle)
		
		# Set particle color
		var material = StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = liquid_types[liquid_key].base_color
		instance.material_override = material
	
	# Calculate maximum possible entropy for normalization
	max_entropy = -1.0 * (0.5 * log(0.5) + 0.5 * log(0.5))

func _setup_entropy_display():
	entropy_label = Label3D.new()
	entropy_label.text = "Entropy: 0.00"
	entropy_label.position = Vector3(0, container_size.y / 2 + 1, 0)
	entropy_label.font_size = 24
	add_child(entropy_label)

func _setup_material():
	spatial_material = ShaderMaterial.new()
	var shader = Shader.new()
	
	# Create a shader that will visualize the mixed state of particles
	shader.code = """
	shader_type spatial;
	render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
	
	uniform vec4 albedo : source_color;
	uniform float metallic : hint_range(0.0, 1.0) = 0.0;
	uniform float roughness : hint_range(0.0, 1.0) = 0.5;
	
	void fragment() {
		ALBEDO = albedo.rgb;
		ALPHA = albedo.a;
		METALLIC = metallic;
		ROUGHNESS = roughness;
	}
	"""
	
	spatial_material.shader = shader

func _process(delta):
	for i in range(simulation_steps_per_frame):
		# Update simulation at a smaller time step for stability
		var step_delta = delta / simulation_steps_per_frame
		_update_simulation(step_delta)
	
	# Update visuals and entropy display
	_update_visuals()
	_calculate_entropy()

func _update_simulation(delta):
	# Update grid for spatial partitioning
	_update_spatial_grid()
	
	# Find neighbors for each particle
	_find_neighbors()
	
	# Calculate forces and update velocities
	_calculate_forces(delta)
	
	# Update positions
	_update_positions(delta)
	
	# Apply boundary conditions
	_apply_boundary_conditions()
	
	# Handle liquid mixing
	_handle_mixing(delta)

func _update_spatial_grid():
	# Clear the previous grid
	neighbor_grid.clear()
	
	# Place particles in grid cells
	for i in range(particle_data.size()):
		var particle = particle_data[i]
		
		# Get grid cell coordinates
		var cell_x = floor(particle.position.x / grid_cell_size)
		var cell_y = floor(particle.position.y / grid_cell_size)
		var cell_z = floor(particle.position.z / grid_cell_size)
		
		# Create a unique cell key
		var cell_key = Vector3i(cell_x, cell_y, cell_z)
		
		# Add particle to grid cell
		if not neighbor_grid.has(cell_key):
			neighbor_grid[cell_key] = []
		
		neighbor_grid[cell_key].append(i)

func _find_neighbors():
	# For each particle, find its neighbors
	for i in range(particle_data.size()):
		var particle = particle_data[i]
		particle.neighbors.clear()
		
		# Get grid cell coordinates
		var cell_x = floor(particle.position.x / grid_cell_size)
		var cell_y = floor(particle.position.y / grid_cell_size)
		var cell_z = floor(particle.position.z / grid_cell_size)
		
		# Check neighboring cells
		for nx in range(-1, 2):
			for ny in range(-1, 2):
				for nz in range(-1, 2):
					var neighbor_cell = Vector3i(cell_x + nx, cell_y + ny, cell_z + nz)
					
					if neighbor_grid.has(neighbor_cell):
						for neighbor_idx in neighbor_grid[neighbor_cell]:
							if neighbor_idx != i:  # Don't include self
								var neighbor = particle_data[neighbor_idx]
								var distance = particle.position.distance_to(neighbor.position)
								
								# Consider particles within interaction radius
								if distance < grid_cell_size:
									particle.neighbors.append(neighbor_idx)

func _calculate_forces(delta):
	# Apply forces for each particle
	for i in range(particle_data.size()):
		var particle = particle_data[i]
		
		# Start with gravity
		particle.acceleration = Vector3(0, -gravity, 0)
		
		# Get effective viscosity based on mixed state
		var effective_viscosity = 0.0
		var total_concentration = 0.0
		
		for type in particle.mixed_properties:
			var concentration = particle.mixed_properties[type]
			effective_viscosity += liquid_types[type].viscosity * concentration
			total_concentration += concentration
		
		if total_concentration > 0:
			effective_viscosity /= total_concentration
		else:
			effective_viscosity = liquid_types[particle.liquid_type].viscosity
		
		# Scale by export parameter
		effective_viscosity *= viscosity_multiplier
		
		# Apply viscosity and pressure forces from neighbors
		for neighbor_idx in particle.neighbors:
			var neighbor = particle_data[neighbor_idx]
			
			var direction = neighbor.position - particle.position
			var distance = direction.length()
			
			if distance > 0:
				direction = direction.normalized()
				
				# Simple viscosity force
				var relative_velocity = neighbor.velocity - particle.velocity
				var viscous_force = relative_velocity * effective_viscosity * (1.0 - distance / grid_cell_size)
				
				# Simple pressure force to prevent clumping
				var pressure_force = -direction * (1.0 - distance / grid_cell_size) * 5.0
				
				particle.acceleration += (viscous_force + pressure_force) * delta

func _update_positions(delta):
	# Update position for each particle using velocity verlet integration
	for particle in particle_data:
		var old_acceleration = particle.acceleration
		
		# Update velocity (half step)
		particle.velocity += old_acceleration * delta * 0.5
		
		# Update position
		particle.position += particle.velocity * delta
		
		# Calculate new acceleration (done in _calculate_forces)
		
		# Update velocity (second half step)
		particle.velocity += particle.acceleration * delta * 0.5

func _apply_boundary_conditions():
	# Keep particles inside the container with soft boundaries
	var half_size = container_size * 0.5
	
	for particle in particle_data:
		for axis in 3:
			if particle.position[axis] < -half_size[axis]:
				particle.position[axis] = -half_size[axis]
				particle.velocity[axis] *= -0.5  # Bounce with dampening
			
			if particle.position[axis] > half_size[axis]:
				particle.position[axis] = half_size[axis]
				particle.velocity[axis] *= -0.5  # Bounce with dampening

func _handle_mixing(delta):
	# Handle diffusion between particles
	for i in range(particle_data.size()):
		var particle = particle_data[i]
		
		# Skip if no neighbors
		if particle.neighbors.size() == 0:
			continue
		
		# For each neighbor, exchange liquid properties
		for neighbor_idx in particle.neighbors:
			var neighbor = particle_data[neighbor_idx]
			
			# For each liquid type in the neighbor
			for type in neighbor.mixed_properties:
				var neighbor_concentration = neighbor.mixed_properties[type]
				
				# If this particle doesn't have this type yet, initialize it
				if not particle.mixed_properties.has(type):
					particle.mixed_properties[type] = 0.0
				
				# Calculate concentration gradient and diffusion
				var concentration_diff = neighbor_concentration - particle.mixed_properties[type]
				var diffusion_amount = concentration_diff * diffusion_rate * delta
				
				# Apply diffusion
				particle.mixed_properties[type] += diffusion_amount
		
		# Normalize concentrations to ensure they sum to 1.0
		var total_concentration = 0.0
		for type in particle.mixed_properties:
			total_concentration += particle.mixed_properties[type]
		
		if total_concentration > 0:
			for type in particle.mixed_properties:
				particle.mixed_properties[type] /= total_concentration

func _update_visuals():
	# Update particle visual representation
	for particle in particle_data:
		# Update position
		particle.mesh_instance.position = particle.position
		
		# Calculate mixed color based on concentrations
		var mixed_color = Color(0, 0, 0, 0)
		var total_concentration = 0.0
		
		for type in particle.mixed_properties:
			var concentration = particle.mixed_properties[type]
			mixed_color += liquid_types[type].base_color * concentration
			total_concentration += concentration
		
		if total_concentration > 0:
			mixed_color /= total_concentration
		else:
			mixed_color = liquid_types[particle.liquid_type].base_color
		
		# Apply color to particle material
		var material = particle.mesh_instance.material_override as StandardMaterial3D
		if material:
			material.albedo_color = mixed_color

func _calculate_entropy():
	# Calculate system entropy based on mixing state
	var total_entropy = 0.0
	
	# Count particles of each liquid type and mixtures
	var type_counts = {}
	var total_particles = particle_data.size()
	
	# First, get the distribution of liquid types
	for particle in particle_data:
		for type in particle.mixed_properties:
			var concentration = particle.mixed_properties[type]
			
			if not type_counts.has(type):
				type_counts[type] = 0.0
			
			type_counts[type] += concentration
	
	# Calculate Shannon entropy
	for type in type_counts:
		var probability = type_counts[type] / total_particles
		if probability > 0:
			total_entropy -= probability * log(probability)
	
	# Normalize by maximum possible entropy
	entropy_value = total_entropy / max_entropy
	
	# Update display
	if show_entropy:
		entropy_label.text = "Entropy: %.2f" % entropy_value

# Add a method to pour a new liquid
func add_liquid(position: Vector3, type: String, amount: int):
	if not liquid_types.has(type):
		push_error("Unknown liquid type: " + type)
		return
	
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.1
	particle_mesh.height = 0.2
	
	for i in range(amount):
		var instance = MeshInstance3D.new()
		instance.mesh = particle_mesh
		add_child(instance)
		
		# Add random offset around the specified position
		var random_offset = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)
		
		var particle_position = position + random_offset
		
		var particle = LiquidParticle.new(particle_position, type, instance)
		particle_data.append(particle)
		
		# Set particle color
		var material = StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = liquid_types[type].base_color
		instance.material_override = material

# A function to get the current entropy value
func get_entropy():
	return entropy_value
