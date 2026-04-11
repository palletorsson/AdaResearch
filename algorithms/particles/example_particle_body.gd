extends Node3D

## Blobfish Particle Body Example
## Particles move together as a jiggly blob with connected body
## Agent-VisualizationExpert: Organic creature demo
## Protocol: IACP v2.2

@onready var particle_emitter = $ParticleEmitter
@onready var particle_body = $ParticleBody
@onready var blobfish_swarm = $BlobfishSwarm

var update_timer: float = 0.0
const UPDATE_INTERVAL = 0.05  # Update body 20 times per second

func _ready() -> void:
	# Configure emitter for blobfish
	if particle_emitter:
		particle_emitter.max_particles = 25
		particle_emitter.emission_rate = 25.0  # Spawn all at once
		particle_emitter.particle_lifetime = 999.0  # Live forever
		particle_emitter.gravity = Vector3.ZERO  # No gravity (swimming!)
		particle_emitter.wind = Vector3.ZERO
		particle_emitter.particle_size = 0.015  # Even tinier particles!
	
	# Configure body
	if particle_body:
		particle_body.connection_mode = ParticleBody.ConnectionMode.NEAREST
		particle_body.max_connections_per_particle = 6  # More connections for spread out particles
		particle_body.connection_distance = 1.2  # Larger distance for connections
		particle_body.line_color = Color(0.5, 0.8, 1.0, 0.8)  # Brighter blue
		particle_body.line_thickness = 0.02  # Thicker lines
		particle_body.use_surface = false  # Start with lines visible
		particle_body.surface_color = Color(0.7, 0.5, 0.9, 0.4)  # Purple blob
	
	# Configure blobfish behavior
	if blobfish_swarm:
		blobfish_swarm.blob_radius = 0.8  # Larger blob = more spread out
		blobfish_swarm.swim_speed = 0.3
		blobfish_swarm.wiggle_frequency = 2.0
		blobfish_swarm.wiggle_amplitude = 0.15
		blobfish_swarm.separation_strength = 2.5  # Strong separation
		blobfish_swarm.cohesion_strength = 0.8  # Weak cohesion
	
	print("BlobfishDemo: Ready - Watch the blob swim!")
	print("Controls:")
	print("  1-6: Change connection mode")
	print("  S: Toggle surface/lines")
	print("  W/A/S/D: Nudge blob direction")
	print("  Space: Random swim direction")
	print("  +/-: Adjust connections")

func _process(delta: float) -> void:
	update_timer += delta
	
	# Hide all particles every frame by making them transparent
	if particle_emitter:
		for particle in particle_emitter.particles:
			# Set base color to transparent so update_visual() uses it
			particle.primary_pink = Color(0, 0, 0, 0)
			
			# Also force material update immediately
			if particle.material:
				particle.material.albedo_color.a = 0.0
				particle.material.emission.a = 0.0
	
	if update_timer >= UPDATE_INTERVAL:
		_update_blobfish()
		update_timer = 0.0

func _update_blobfish() -> void:
	"""Update the blobfish with current particles"""
	if not particle_emitter or not particle_body or not blobfish_swarm:
		return
	
	# Get all alive particles from emitter
	var alive_particles = []
	for particle in particle_emitter.particles:
		if not particle.is_dead():
			alive_particles.append(particle)
	
	# Update blobfish swarm behavior
	blobfish_swarm.set_particles(alive_particles)
	
	# Update body visualization
	particle_body.set_particles(alive_particles)
	particle_body.update_body()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			# Connection modes
			KEY_1:
				particle_body.set_connection_mode(ParticleBody.ConnectionMode.NONE)
				print("Mode: NONE")
			KEY_2:
				particle_body.set_connection_mode(ParticleBody.ConnectionMode.NEAREST)
				print("Mode: NEAREST")
			KEY_3:
				particle_body.set_connection_mode(ParticleBody.ConnectionMode.OUTER_HULL)
				print("Mode: OUTER_HULL")
			KEY_4:
				particle_body.set_connection_mode(ParticleBody.ConnectionMode.DELAUNAY)
				print("Mode: DELAUNAY")
			KEY_5:
				particle_body.set_connection_mode(ParticleBody.ConnectionMode.ALL_LINES)
				print("Mode: ALL_LINES")
			KEY_6:
				particle_body.set_connection_mode(ParticleBody.ConnectionMode.DISTANCE_BASED)
				print("Mode: DISTANCE_BASED")
			
			# Surface toggle
			KEY_S:
				particle_body.toggle_surface_mode()
				print("Surface mode: %s" % particle_body.use_surface)
			
			# Connection count
			KEY_EQUAL, KEY_PLUS:
				particle_body.max_connections_per_particle += 1
				particle_body.update_body()
				print("Max connections: %d" % particle_body.max_connections_per_particle)
			KEY_MINUS:
				particle_body.max_connections_per_particle = max(1, particle_body.max_connections_per_particle - 1)
				particle_body.update_body()
				print("Max connections: %d" % particle_body.max_connections_per_particle)
			
			# Nudge blob direction
			KEY_W:
				blobfish_swarm.nudge_blob(Vector3.FORWARD, 0.5)
				print("Nudge: Forward")
			KEY_A:
				blobfish_swarm.nudge_blob(Vector3.LEFT, 0.5)
				print("Nudge: Left")
			KEY_D:
				blobfish_swarm.nudge_blob(Vector3.RIGHT, 0.5)
				print("Nudge: Right")
			KEY_Q:
				blobfish_swarm.nudge_blob(Vector3.UP, 0.5)
				print("Nudge: Up")
			KEY_E:
				blobfish_swarm.nudge_blob(Vector3.DOWN, 0.5)
				print("Nudge: Down")
			
			# Random direction
			KEY_SPACE:
				var random_dir = Vector3(
					randf_range(-1, 1),
					randf_range(-0.5, 0.5),
					randf_range(-1, 1)
				).normalized()
				blobfish_swarm.set_swim_direction(random_dir)
				print("Random swim direction!")
			
			# Speed controls
			KEY_UP:
				blobfish_swarm.swim_speed += 0.1
				print("Swim speed: %.1f" % blobfish_swarm.swim_speed)
			KEY_DOWN:
				blobfish_swarm.swim_speed = max(0.1, blobfish_swarm.swim_speed - 0.1)
				print("Swim speed: %.1f" % blobfish_swarm.swim_speed)
			
			# Wiggle controls
			KEY_LEFT:
				blobfish_swarm.wiggle_amplitude = max(0.0, blobfish_swarm.wiggle_amplitude - 0.05)
				print("Wiggle: %.2f" % blobfish_swarm.wiggle_amplitude)
			KEY_RIGHT:
				blobfish_swarm.wiggle_amplitude += 0.05
				print("Wiggle: %.2f" % blobfish_swarm.wiggle_amplitude)

func apply_grid_config(config: Dictionary) -> void:
	pass
