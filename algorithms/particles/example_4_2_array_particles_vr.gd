# ===========================================================================
# NOC Example 4.2: Array of Particles
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 4.2: Array of Particles
## Managing multiple particles in an array
## Chapter 04: Particle Systems

var particles: Array[Particle] = []

@export var max_particles: int = 50
@export var spawn_rate: float = 5.0  # particles per second
var spawn_timer: float = 0.0

# UI
var info_label: Label3D

func _ready():

	# Create UI
	create_info_label()

	print("Example 4.2: Array of Particles - Auto-spawning particles")

func _process(delta):
	# Spawn particles
	spawn_timer += delta
	while spawn_timer >= 1.0 / spawn_rate and particles.size() < max_particles:
		spawn_timer -= 1.0 / spawn_rate
		spawn_particle()

	# Update all particles
	update_particles(delta)

	# Clean up dead particles
	cleanup_dead_particles()

	# Update UI
	update_info_label()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Spawn burst of particles
			for i in range(10):
				spawn_particle()
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_UP:
			spawn_rate = min(spawn_rate + 1.0, 20.0)
		elif event.keycode == KEY_DOWN:
			spawn_rate = max(spawn_rate - 1.0, 1.0)

func create_info_label():
	"""Create info label"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	add_child(info_label)

	var instructions = Label3D.new()
	instructions.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions.font_size = 18
	instructions.modulate = Color(0.8, 1.0, 0.8)
	instructions.position = Vector3(0, 0.5, 0)
	instructions.text = "[SPACE] Burst | [↑/↓] Rate | [R] Reset"
	add_child(instructions)

func update_info_label():
	"""Update info label"""
	if info_label:
		info_label.text = "Array of Particles\n%d / %d (%.1f/s)" % [particles.size(), max_particles, spawn_rate]

func spawn_particle():
	"""Spawn a new particle"""
	if particles.size() >= max_particles:
		return

	# Random spawn position at top
	var spawn_pos = Vector3(
		randf_range(-0.3, 0.3),
		0.4,
		randf_range(-0.3, 0.3)
	)

	# Random velocity
	var vel = Vector3(
		randf_range(-0.5, 0.5),
		randf_range(0.3, 1.0),
		randf_range(-0.5, 0.5)
	)

	var particle = Particle.new(spawn_pos, vel)
	particle.size = randf_range(0.04, 0.07)
	particle.mass = randf_range(0.8, 1.2)

	# Vary color slightly
	var color_variation = randf_range(0.9, 1.1)
	particle.primary_pink = Color(
		1.0 * color_variation,
		0.6 * color_variation,
		1.0 * color_variation,
		1.0
	)

	add_child(particle)
	particles.append(particle)

func update_particles(delta: float):
	"""Update all particles"""
	for particle in particles:
		# Apply gravity
		var gravity = Vector3(0, -2.0, 0)
		particle.apply_force(gravity * particle.mass)

		# Apply wind (sine wave)
		var time = Time.get_ticks_msec() / 1000.0
		var wind = Vector3(sin(time) * 0.5, 0, cos(time * 0.7) * 0.3)
		particle.apply_force(wind)

		# Update particle
		particle.update(delta)

func cleanup_dead_particles():
	"""Remove dead particles"""
	var dead_particles: Array[Particle] = []

	for particle in particles:
		if particle.is_dead():
			dead_particles.append(particle)

	for particle in dead_particles:
		particles.erase(particle)
		particle.queue_free()

func reset():
	"""Reset all particles"""
	for particle in particles:
		particle.queue_free()
	particles.clear()
	spawn_timer = 0.0
