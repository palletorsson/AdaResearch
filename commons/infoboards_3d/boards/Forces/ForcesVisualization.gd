# ForcesVisualization.gd
# Visualization for Forces algorithm
extends AlgorithmVisualizationBase

# Physics constants
const GRAVITY := Vector2(0, 0.5)
const FRICTION_COEF := 0.05
const ATTRACTION_STRENGTH := 100.0
const WIND_STRENGTH := 5.0
const FLUID_DRAG := 0.2

# Particle system
var particles: Array = []
var attractors: Array = []
var repellers: Array = []
var particle_count: int = 12
var particle_radius: float = 12.0  # Doubled from 6.0

# Flow field for wind visualization
var flow_field: Array = []
var flow_field_resolution: int = 10
var noise_offset: float = 0.0

# Colors
var particle_color := Color(0.4, 0.7, 0.9, 0.9)
var attractor_color := Color(1.0, 0.5, 0.3, 0.8)
var repeller_color := Color(0.3, 1.0, 0.5, 0.8)
var force_vector_color := Color(1.0, 0.8, 0.2, 0.6)

# ForceParticle class - renamed to avoid conflict with global Particle class
class ForceParticle:
	var position: Vector2
	var velocity: Vector2
	var acceleration: Vector2
	var mass: float
	var radius: float
	var color: Color
	
	func _init(pos: Vector2, m: float = 1.0, r: float = 6.0):
		position = pos
		velocity = Vector2.ZERO
		acceleration = Vector2.ZERO
		mass = m
		radius = r
		color = Color(randf_range(0.4, 1.0), randf_range(0.4, 1.0), randf_range(0.4, 1.0), 0.9)
	
	func apply_force(force: Vector2):
		# F = ma, so a = F/m
		acceleration += force / mass
	
	func update(delta: float):
		velocity += acceleration * delta
		position += velocity * delta
		acceleration = Vector2.ZERO  # Reset for next frame
	
	func edges(bounds: Vector2):
		# Bounce off edges
		if position.x < 0 or position.x > bounds.x:
			velocity.x *= -0.8
			position.x = clamp(position.x, 0, bounds.x)
		if position.y < 0 or position.y > bounds.y:
			velocity.y *= -0.8
			position.y = clamp(position.y, 0, bounds.y)

func on_reset() -> void:
	"""Reset the visualization"""
	particles.clear()
	attractors.clear()
	repellers.clear()
	
	match visualization_type:
		"gravity":
			_setup_gravity()
		"friction":
			_setup_friction()
		"attraction":
			_setup_attraction()
		"wind":
			_setup_wind()
		_:
			_setup_gravity()

func _setup_gravity():
	# Create particles at random positions
	for i in range(particle_count):
		var pos = Vector2(randf_range(50, size.x - 50), randf_range(50, 100))
		var mass = randf_range(0.5, 2.0)
		var particle = ForceParticle.new(pos, mass, particle_radius * mass)
		particle.velocity = Vector2(randf_range(-50, 50), 0)
		particles.append(particle)

func _setup_friction():
	# Create particles with initial velocity
	for i in range(particle_count):
		var pos = Vector2(randf_range(50, size.x - 50), randf_range(100, size.y - 100))
		var mass = randf_range(0.5, 2.0)
		var particle = ForceParticle.new(pos, mass, particle_radius * mass)
		particle.velocity = Vector2(randf_range(100, 200), randf_range(-50, 50))
		particles.append(particle)

func _setup_attraction():
	# Create fewer particles for attraction demo
	for i in range(6):
		var pos = Vector2(randf_range(50, size.x - 50), randf_range(50, size.y - 50))
		var mass = randf_range(0.5, 1.5)
		var particle = ForceParticle.new(pos, mass, particle_radius * mass)
		particle.velocity = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		particles.append(particle)
	
	# Create attractors and repellers
	attractors.append(Vector2(size.x * 0.3, size.y * 0.5))
	attractors.append(Vector2(size.x * 0.7, size.y * 0.5))
	repellers.append(Vector2(size.x * 0.5, size.y * 0.5))

func _setup_wind():
	# Create particles
	for i in range(particle_count):
		var pos = Vector2(randf_range(50, size.x - 50), randf_range(50, size.y - 50))
		var mass = randf_range(0.3, 1.0)
		var particle = ForceParticle.new(pos, mass, particle_radius * 0.7)
		particles.append(particle)
	
	# Generate flow field
	_generate_flow_field()

func _generate_flow_field():
	flow_field.clear()
	var cell_size = size.x / flow_field_resolution
	
	for y in range(flow_field_resolution):
		for x in range(flow_field_resolution):
			var pos = Vector2(x * cell_size + cell_size/2, y * cell_size + cell_size/2)
			var angle = rng.randf_range(0, TAU)
			var vector = Vector2(cos(angle), sin(angle)) * WIND_STRENGTH
			flow_field.append({"position": pos, "vector": vector})

func on_periodic_update() -> void:
	"""Update physics simulation"""
	if not animation_playing:
		return
	
	var delta = 0.016  # ~60 FPS
	
	match visualization_type:
		"gravity":
			_update_gravity(delta)
		"friction":
			_update_friction(delta)
		"attraction":
			_update_attraction(delta)
		"wind":
			_update_wind(delta)

func _update_gravity(delta: float):
	for particle in particles:
		particle.apply_force(GRAVITY * particle.mass)
		particle.update(delta)
		particle.edges(size)

func _update_friction(delta: float):
	for particle in particles:
		# Apply gravity
		particle.apply_force(GRAVITY * particle.mass)
		
		# Apply friction (opposing motion)
		var friction = particle.velocity.normalized() * -1.0
		friction *= FRICTION_COEF * particle.mass
		particle.apply_force(friction)
		
		particle.update(delta)
		particle.edges(size)

func _update_attraction(delta: float):
	for particle in particles:
		# Apply attraction from attractors
		for attractor_pos in attractors:
			var direction = attractor_pos - particle.position
			var distance = max(direction.length(), 10.0)  # Prevent extreme forces
			direction = direction.normalized()
			
			var force_magnitude = ATTRACTION_STRENGTH * particle.mass / (distance * distance)
			particle.apply_force(direction * force_magnitude)
		
		# Apply repulsion from repellers
		for repeller_pos in repellers:
			var direction = repeller_pos - particle.position
			var distance = max(direction.length(), 10.0)
			direction = direction.normalized()
			
			var force_magnitude = ATTRACTION_STRENGTH * particle.mass / (distance * distance)
			particle.apply_force(direction * -force_magnitude)  # Negative for repulsion
		
		particle.update(delta)
		particle.edges(size)

func _update_wind(delta: float):
	noise_offset += delta * 0.5
	
	# Update flow field with animated noise
	var cell_size = size.x / flow_field_resolution
	for i in range(flow_field.size()):
		var x = i % flow_field_resolution
		var y = i / flow_field_resolution
		var angle = rng.randf_range(0, TAU) + noise_offset
		flow_field[i]["vector"] = Vector2(cos(angle), sin(angle)) * WIND_STRENGTH
	
	# Apply flow field forces to particles
	for particle in particles:
		var grid_x = int(particle.position.x / cell_size) % flow_field_resolution
		var grid_y = int(particle.position.y / cell_size) % flow_field_resolution
		var index = grid_y * flow_field_resolution + grid_x
		
		if index >= 0 and index < flow_field.size():
			particle.apply_force(flow_field[index]["vector"] * particle.mass)
		
		particle.update(delta)
		particle.edges(size)

func draw_visualization() -> void:
	"""Draw the current visualization"""
	match visualization_type:
		"gravity":
			_draw_gravity()
		"friction":
			_draw_friction()
		"attraction":
			_draw_attraction()
		"wind":
			_draw_wind()

func _draw_gravity():
	# Draw gravity vector
	var center = Vector2(size.x / 2, 50)
	draw_label("Gravity", center - Vector2(30, 20), 18, Color.WHITE)  # Bigger font
	_draw_arrow(center, center + GRAVITY * 80, force_vector_color, 4.0)  # Doubled length and width
	
	# Draw particles
	for particle in particles:
		draw_circle(particle.position, particle.radius, particle.color)
		draw_circle_outline(particle.position, particle.radius, particle.color.lightened(0.3), 16, 4.0)  # Doubled outline

func _draw_friction():
	# Draw particles with velocity vectors
	for particle in particles:
		draw_circle(particle.position, particle.radius, particle.color)
		draw_circle_outline(particle.position, particle.radius, particle.color.lightened(0.3), 16, 4.0)  # Added outline
		
		# Draw velocity vector
		if particle.velocity.length() > 1.0:
			_draw_arrow(particle.position, particle.position + particle.velocity, 
				Color(1.0, 1.0, 0.3, 0.6), 4.0)  # Doubled width

func _draw_attraction():
	# Draw attractors (bigger)
	for attractor_pos in attractors:
		draw_circle(attractor_pos, 18, attractor_color)  # Increased from 12 to 18
		draw_circle_outline(attractor_pos, 18, attractor_color.lightened(0.3), 16, 4.0)  # Doubled outline
		draw_label("+", attractor_pos - Vector2(8, 8), 24, Color.WHITE)  # Bigger font
	
	# Draw repellers (bigger)
	for repeller_pos in repellers:
		draw_circle(repeller_pos, 18, repeller_color)  # Increased from 12 to 18
		draw_circle_outline(repeller_pos, 18, repeller_color.lightened(0.3), 16, 4.0)  # Doubled outline
		draw_label("-", repeller_pos - Vector2(8, 8), 24, Color.WHITE)  # Bigger font
	
	# Draw particles
	for particle in particles:
		draw_circle(particle.position, particle.radius, particle.color)
		draw_circle_outline(particle.position, particle.radius, particle.color.lightened(0.3), 12, 4.0)  # Added outline

func _draw_wind():
	# Draw flow field (bigger arrows)
	for field_entry in flow_field:
		var pos = field_entry["position"]
		var vec = field_entry["vector"]
		_draw_arrow(pos, pos + vec * 8, Color(0.5, 0.5, 0.5, 0.4), 2.0)  # Bigger arrows, more visible
	
	# Draw particles
	for particle in particles:
		draw_circle(particle.position, particle.radius, particle.color)
		draw_circle_outline(particle.position, particle.radius, particle.color.lightened(0.3), 12, 3.0)  # Doubled outline

func _draw_arrow(from: Vector2, to: Vector2, color: Color, width: float):
	"""Helper to draw an arrow"""
	draw_line(from, to, color, width)
	
	# Arrow head (bigger)
	var direction = (to - from).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var arrow_size = 16.0  # Doubled from 8.0
	
	var head1 = to - direction * arrow_size + perpendicular * arrow_size * 0.5
	var head2 = to - direction * arrow_size - perpendicular * arrow_size * 0.5
	
	draw_line(to, head1, color, width)
	draw_line(to, head2, color, width)
