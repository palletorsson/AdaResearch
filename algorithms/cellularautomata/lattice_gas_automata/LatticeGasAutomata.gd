extends Node3D

# Lattice Gas Automata Visualization
# Demonstrates microscopic discrete dynamics leading to macroscopic fluid behavior

var time := 0.0
var step_timer := 0.0

# Grid parameters
var grid_size := 20 # Increased size for better effect
var lattice_grid := []
var velocity_directions := [
	Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
	Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1)
]

# MultiMesh Instances
var mm_grid_base: MultiMeshInstance3D
var mm_particles: MultiMeshInstance3D
var mm_flow: MultiMeshInstance3D
var mm_density: MultiMeshInstance3D

# Particle data structure
class LatticeCell:
	var particles: Array  # Boolean array for each direction
	var density: float
	var velocity: Vector2
	var pressure: float

func _ready():
	_setup_multimeshes()
	initialize_lattice()

func _process(delta):
	time += delta
	step_timer += delta
	
	if step_timer > 0.1:
		step_timer = 0.0
		update_lattice()
		# Update visualizations only on step
		visualize_lattice_grid()
		show_particle_flow()
		display_macroscopic_properties()

func _setup_multimeshes():
	# 1. Grid Base
	mm_grid_base = _create_multimesh("MM_GridBase", BoxMesh.new(), grid_size * grid_size, "LatticeGrid")
	mm_grid_base.multimesh.mesh.size = Vector3(0.9, 0.1, 0.9)
	
	# 2. Particles (Spheres)
	# Max particles = grid_size^2 * 8 directions
	mm_particles = _create_multimesh("MM_Particles", SphereMesh.new(), grid_size * grid_size * 8, "LatticeGrid")
	mm_particles.multimesh.mesh.radius = 0.08
	mm_particles.multimesh.mesh.height = 0.16
	
	# 3. Flow (Cylinders/Arrows)
	# Using a cylinder that points up by default, we'll rotate it
	var arrow_mesh = CylinderMesh.new()
	arrow_mesh.top_radius = 0.0
	arrow_mesh.bottom_radius = 0.1
	arrow_mesh.height = 1.0
	mm_flow = _create_multimesh("MM_Flow", arrow_mesh, grid_size * grid_size, "ParticleFlow")
	
	# 4. Density Pillars (Boxes)
	mm_density = _create_multimesh("MM_Density", BoxMesh.new(), grid_size * grid_size, "MacroscopicProperties")
	mm_density.multimesh.mesh.size = Vector3(0.8, 1.0, 0.8) # Height scaled later

func _create_multimesh(name: String, mesh: Mesh, count: int, parent_name: String = "") -> MultiMeshInstance3D:
	var mmi = MultiMeshInstance3D.new()
	mmi.name = name
	
	if parent_name != "" and has_node(parent_name):
		get_node(parent_name).add_child(mmi)
	else:
		add_child(mmi)
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	mmi.multimesh = mm
	
	# Hide all initially
	for i in range(count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
		
	return mmi

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
	
	# Initial visualization of static grid base
	var mm = mm_grid_base.multimesh
	var idx = 0
	for i in range(grid_size):
		for j in range(grid_size):
			var pos = Vector3(j - grid_size * 0.5, 0, i - grid_size * 0.5)
			mm.set_instance_transform(idx, Transform3D(Basis(), pos))
			mm.set_instance_color(idx, Color(0.3, 0.3, 0.3))
			idx += 1

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
	var mm = mm_particles.multimesh
	var idx = 0
	
	# Reset remaining
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for i in range(grid_size):
		for j in range(grid_size):
			var cell = lattice_grid[i][j]
			var base_pos = Vector3(j - grid_size * 0.5, 0, i - grid_size * 0.5)
			
			for dir in range(velocity_directions.size()):
				if cell.particles[dir]:
					var dir_offset = Vector3(
						velocity_directions[dir].x * 0.2,
						0.3,
						velocity_directions[dir].y * 0.2
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), base_pos + dir_offset))
					
					var dir_color = float(dir) / velocity_directions.size()
					mm.set_instance_color(idx, Color.from_hsv(dir_color, 0.8, 1.0))
					idx += 1

func show_particle_flow():
	var mm = mm_flow.multimesh
	var idx = 0
	
	# Reset
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for i in range(0, grid_size, 2):
		for j in range(0, grid_size, 2):
			var cell = lattice_grid[i][j]
			
			if cell.velocity.length() > 0.1:
				var pos = Vector3(j - grid_size * 0.5, 2.0, i - grid_size * 0.5)
				
				# Orient arrow
				var flow_dir = Vector3(cell.velocity.x, 0, cell.velocity.y).normalized()
				var up = Vector3.UP
				var axis = up.cross(flow_dir).normalized()
				var angle = acos(up.dot(flow_dir))
				
				var basis = Basis()
				if axis.length_squared() > 0.001:
					basis = Basis(axis, angle)
				
				# Scale based on velocity
				var scale_y = cell.velocity.length() * 2.0
				var t = Transform3D(basis, pos).scaled(Vector3(1, scale_y, 1))
				
				mm.set_instance_transform(idx, t)
				
				var speed_ratio = cell.velocity.length() / 2.0
				mm.set_instance_color(idx, Color(speed_ratio, 0.5, 1.0 - speed_ratio))
				idx += 1

func display_macroscopic_properties():
	var mm = mm_density.multimesh
	var idx = 0
	
	# Reset
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for i in range(0, grid_size, 2):
		for j in range(0, grid_size, 2):
			var cell = lattice_grid[i][j]
			
			var height = cell.density * 3.0 + 0.1
			var pos = Vector3(
				j - grid_size * 0.5,
				height * 0.5 - 2.0,
				i - grid_size * 0.5
			)
			
			# Scale box height
			var t = Transform3D(Basis(), pos).scaled(Vector3(1, height, 1))
			mm.set_instance_transform(idx, t)
			
			var col = Color(0.2, cell.density, 1.0 - cell.density * 0.5)
			mm.set_instance_color(idx, col)
			idx += 1

func demonstrate_collision_dynamics():
	# Removed for performance/simplicity in this refactor
	pass
