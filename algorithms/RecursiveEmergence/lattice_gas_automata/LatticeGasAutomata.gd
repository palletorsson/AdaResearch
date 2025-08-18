extends Node3D

# Lattice Gas Automata Visualization
# Demonstrates microscopic discrete dynamics leading to macroscopic fluid behavior

var time := 0.0
var step_timer := 0.0

# Grid parameters
var grid_size := 20
var lattice_grid := []
var velocity_directions := [
	Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
	Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1)
]

# Particle data structure
class LatticeCell:
	var particles: Array  # Boolean array for each direction
	var density: float
	var velocity: Vector2
	var pressure: float

func _ready():
	initialize_lattice()

func _process(delta):
	time += delta
	step_timer += delta
	
	if step_timer > 0.1:
		step_timer = 0.0
		update_lattice()
	
	visualize_lattice_grid()
	show_particle_flow()
	demonstrate_collision_dynamics()
	display_macroscopic_properties()

func initialize_lattice():
	lattice_grid.clear()
	
	for i in range(grid_size):
		var row = []
		for j in range(grid_size):
			var cell = LatticeCell.new()
			cell.particles = []
			
			# Initialize with random particles
			for dir in range(velocity_directions.size()):
				cell.particles.append(randf() < 0.3)
			
			cell.density = 0.0
			cell.velocity = Vector2.ZERO
			cell.pressure = 0.0
			
			row.append(cell)
		lattice_grid.append(row)

func update_lattice():
	# Two-step LGA update: collision then propagation
	apply_collision_rules()
	propagate_particles()
	calculate_macroscopic_properties()

func apply_collision_rules():
	# Apply local collision rules (simplified)
	for i in range(grid_size):
		for j in range(grid_size):
			var cell = lattice_grid[i][j]
			
			# Count particles
			var particle_count = 0
			for has_particle in cell.particles:
				if has_particle:
					particle_count += 1
			
			# Simple collision rule: redistribute particles
			if particle_count >= 4:
				# High density: randomize distribution
				for k in range(cell.particles.size()):
					cell.particles[k] = randf() < 0.5
			elif particle_count == 2:
				# Two particles: apply specific collision rules
				apply_two_particle_collision(cell)

func apply_two_particle_collision(cell: LatticeCell):
	var active_directions = []
	
	for i in range(cell.particles.size()):
		if cell.particles[i]:
			active_directions.append(i)
	
	if active_directions.size() == 2:
		var dir1 = active_directions[0]
		var dir2 = active_directions[1]
		
		# Check if particles are moving towards each other
		var vel1 = velocity_directions[dir1]
		var vel2 = velocity_directions[dir2]
		
		if vel1.dot(vel2) < -0.5:  # Nearly opposite directions
			# Apply collision rule with some probability
			if randf() < 0.3:
				cell.particles[dir1] = false
				cell.particles[dir2] = false
				
				# Redirect to perpendicular directions
				var perp_dirs = get_perpendicular_directions(dir1, dir2)
				if perp_dirs.size() >= 2:
					cell.particles[perp_dirs[0]] = true
					cell.particles[perp_dirs[1]] = true

func get_perpendicular_directions(dir1: int, dir2: int) -> Array:
	var perp_dirs = []
	var vel1 = velocity_directions[dir1]
	var vel2 = velocity_directions[dir2]
	var avg_vel = (vel1 + vel2) * 0.5
	
	for i in range(velocity_directions.size()):
		if i != dir1 and i != dir2:
			var dot_product = velocity_directions[i].dot(avg_vel)
			if abs(dot_product) < 0.3:  # Roughly perpendicular
				perp_dirs.append(i)
	
	return perp_dirs

func propagate_particles():
	var new_grid = []
	
	# Initialize new grid
	for i in range(grid_size):
		var row = []
		for j in range(grid_size):
			var cell = LatticeCell.new()
			cell.particles = []
			for dir in range(velocity_directions.size()):
				cell.particles.append(false)
			row.append(cell)
		new_grid.append(row)
	
	# Propagate particles
	for i in range(grid_size):
		for j in range(grid_size):
			var cell = lattice_grid[i][j]
			
			for dir in range(velocity_directions.size()):
				if cell.particles[dir]:
					var vel = velocity_directions[dir]
					var new_i = (i + int(vel.y) + grid_size) % grid_size
					var new_j = (j + int(vel.x) + grid_size) % grid_size
					
					new_grid[new_i][new_j].particles[dir] = true
	
	lattice_grid = new_grid

func calculate_macroscopic_properties():
	for i in range(grid_size):
		for j in range(grid_size):
			var cell = lattice_grid[i][j]
			
			# Calculate density
			cell.density = 0.0
			for has_particle in cell.particles:
				if has_particle:
					cell.density += 1.0
			cell.density /= velocity_directions.size()
			
			# Calculate velocity
			cell.velocity = Vector2.ZERO
			for dir in range(velocity_directions.size()):
				if cell.particles[dir]:
					cell.velocity += velocity_directions[dir]
			
			if cell.density > 0:
				cell.velocity /= cell.density * velocity_directions.size()
			
			# Calculate pressure (simplified)
			cell.pressure = cell.density * cell.density

func visualize_lattice_grid():
	var container = $LatticeGrid
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Visualize lattice cells
	for i in range(grid_size):
		for j in range(grid_size):
			var cell = lattice_grid[i][j]
			
			# Cell base
			var cell_base = CSGBox3D.new()
			cell_base.size = Vector3(0.8, 0.1, 0.8)
			cell_base.position = Vector3(
				j - grid_size * 0.5,
				0,
				i - grid_size * 0.5
			)
			
			var base_material = StandardMaterial3D.new()
			base_material.albedo_color = Color(0.3, 0.3, 0.3)
			cell_base.material_override = base_material
			
			container.add_child(cell_base)
			
			# Visualize particles in each direction
			for dir in range(velocity_directions.size()):
				if cell.particles[dir]:
					var particle = CSGSphere3D.new()
					particle.radius = 0.08
					
					var dir_offset = Vector3(
						velocity_directions[dir].x * 0.2,
						0.3,
						velocity_directions[dir].y * 0.2
					)
					
					particle.position = cell_base.position + dir_offset
					
					var particle_material = StandardMaterial3D.new()
					var dir_color = float(dir) / velocity_directions.size()
					particle_material.albedo_color = Color.from_hsv(dir_color, 0.8, 1.0)
					particle_material.emission_enabled = true
					particle_material.emission = Color.from_hsv(dir_color, 0.8, 1.0) * 0.5
					particle.material_override = particle_material
					
					container.add_child(particle)

func show_particle_flow():
	var container = $ParticleFlow
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show overall flow patterns
	var flow_scale = 8
	for i in range(0, grid_size, 2):
		for j in range(0, grid_size, 2):
			var cell = lattice_grid[i][j]
			
			if cell.velocity.length() > 0.1:
				var flow_arrow = CSGCone3D.new()
				flow_arrow.radius_top = 0.0
				flow_arrow.radius_bottom = 0.1
				flow_arrow.height = cell.velocity.length() * 2.0
				
				flow_arrow.position = Vector3(
					j - grid_size * 0.5,
					2.0,
					i - grid_size * 0.5
				)
				
				# Orient arrow in flow direction
				var flow_dir = Vector3(cell.velocity.x, 0, cell.velocity.y).normalized()
				if flow_dir.length() > 0.01:
					flow_arrow.look_at(flow_arrow.position + flow_dir, Vector3.UP)
					flow_arrow.rotate_object_local(Vector3.RIGHT, -PI / 2)
				
				var flow_material = StandardMaterial3D.new()
				var speed_ratio = cell.velocity.length() / 2.0
				flow_material.albedo_color = Color(speed_ratio, 0.5, 1.0 - speed_ratio)
				flow_material.emission_enabled = true
				flow_material.emission = Color(speed_ratio, 0.5, 1.0 - speed_ratio) * 0.4
				flow_arrow.material_override = flow_material
				
				container.add_child(flow_arrow)

func demonstrate_collision_dynamics():
	var container = $CollisionDynamics
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show collision events
	for i in range(grid_size):
		for j in range(grid_size):
			var cell = lattice_grid[i][j]
			
			# Count active particles
			var particle_count = 0
			for has_particle in cell.particles:
				if has_particle:
					particle_count += 1
			
			# Visualize collision probability
			if particle_count >= 2:
				var collision_indicator = CSGSphere3D.new()
				collision_indicator.radius = 0.2 + particle_count * 0.1
				collision_indicator.position = Vector3(
					j - grid_size * 0.5,
					1.5,
					i - grid_size * 0.5
				)
				
				var collision_material = StandardMaterial3D.new()
				var collision_intensity = float(particle_count) / 6.0
				collision_material.albedo_color = Color(1.0, 1.0 - collision_intensity, 0.0)
				collision_material.emission_enabled = true
				collision_material.emission = Color(1.0, 1.0 - collision_intensity, 0.0) * collision_intensity
				collision_indicator.material_override = collision_material
				
				container.add_child(collision_indicator)

func display_macroscopic_properties():
	var container = $MacroscopicProperties
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Calculate and display average properties
	var total_density = 0.0
	var total_pressure = 0.0
	var avg_velocity = Vector2.ZERO
	var cell_count = 0
	
	for i in range(grid_size):
		for j in range(grid_size):
			var cell = lattice_grid[i][j]
			total_density += cell.density
			total_pressure += cell.pressure
			avg_velocity += cell.velocity
			cell_count += 1
	
	if cell_count > 0:
		total_density /= cell_count
		total_pressure /= cell_count
		avg_velocity /= cell_count
	
	# Visualize density field
	for i in range(0, grid_size, 2):
		for j in range(0, grid_size, 2):
			var cell = lattice_grid[i][j]
			
			var density_pillar = CSGBox3D.new()
			density_pillar.size = Vector3(0.6, cell.density * 3.0 + 0.1, 0.6)
			density_pillar.position = Vector3(
				j - grid_size * 0.5,
				density_pillar.size.y * 0.5 - 2.0,
				i - grid_size * 0.5
			)
			
			var density_material = StandardMaterial3D.new()
			density_material.albedo_color = Color(0.2, cell.density, 1.0 - cell.density * 0.5)
			density_material.emission_enabled = true
			density_material.emission = Color(0.2, cell.density, 1.0 - cell.density * 0.5) * 0.3
			density_pillar.material_override = density_material
			
			container.add_child(density_pillar)
	
	# Global property indicators
	var properties = [
		{"name": "Density", "value": total_density, "pos": Vector3(-8, 0, 0)},
		{"name": "Pressure", "value": total_pressure, "pos": Vector3(-4, 0, 0)},
		{"name": "Velocity", "value": avg_velocity.length(), "pos": Vector3(0, 0, 0)}
	]
	
	for prop in properties:
		var prop_sphere = CSGSphere3D.new()
		prop_sphere.radius = 0.5 + prop.value * 0.5
		prop_sphere.position = prop.pos
		
		var prop_material = StandardMaterial3D.new()
		prop_material.albedo_color = Color(0.8, 0.8, 0.2)
		prop_material.emission_enabled = true
		prop_material.emission = Color(0.8, 0.8, 0.2) * prop.value
		prop_sphere.material_override = prop_material
		
		container.add_child(prop_sphere)

