# ===========================================================================
# NOC Example 4.5: Inheritance and Polymorphism
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 4.5: Particle System Inheritance & Polymorphism
## Using both Particle and ConfettiParticle (inheritance)
## Chapter 04: Particle Systems

var particles: Array = []  # Mixed array of Particle and ConfettiParticle

@export var max_particles: int = 80
@export var spawn_rate: float = 8.0
var spawn_timer: float = 0.0

# Spawn mode
var spawn_confetti_mode: bool = true

# UI
var info_label: Label3D

func _ready():

	# Create UI
	create_info_label()

	print("Example 4.5: Inheritance & Polymorphism - Mixed particle types")

func _process(delta):
	# Spawn particles
	spawn_timer += delta
	while spawn_timer >= 1.0 / spawn_rate and particles.size() < max_particles:
		spawn_timer -= 1.0 / spawn_rate
		spawn_particle()

	# Update all particles (polymorphism in action)
	update_particles(delta)

	# Clean up dead particles
	cleanup_dead_particles()

	# Update UI
	update_info_label()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Spawn burst
			for i in range(15):
				spawn_particle()
		elif event.keycode == KEY_C:
			# Toggle confetti mode
			spawn_confetti_mode = !spawn_confetti_mode
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_UP:
			spawn_rate = min(spawn_rate + 2.0, 20.0)
		elif event.keycode == KEY_DOWN:
			spawn_rate = max(spawn_rate - 2.0, 2.0)

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
	instructions.text = "[SPACE] Burst | [C] Toggle Type | [↑/↓] Rate | [R] Reset"
	add_child(instructions)

func update_info_label():
	"""Update info label"""
	if info_label:
		var confetti_count = 0
		var sphere_count = 0

		for particle in particles:
			if particle is ConfettiParticle:
				confetti_count += 1
			else:
				sphere_count += 1

		var mode_text = "Confetti" if spawn_confetti_mode else "Spheres"
		info_label.text = "Inheritance Demo\n%s | C:%d S:%d" % [mode_text, confetti_count, sphere_count]

func spawn_particle():
	"""Spawn a particle (either Particle or ConfettiParticle)"""
	if particles.size() >= max_particles:
		return

	# Random spawn position
	var spawn_pos = Vector3(
		randf_range(-0.3, 0.3),
		0.4,
		randf_range(-0.3, 0.3)
	)

	# Random velocity
	var vel = Vector3(
		randf_range(-0.6, 0.6),
		randf_range(0.5, 1.5),
		randf_range(-0.6, 0.6)
	)

	var particle: Particle

	# Create either regular Particle or ConfettiParticle
	if spawn_confetti_mode:
		particle = ConfettiParticle.new(spawn_pos, vel)
	else:
		particle = Particle.new(spawn_pos, vel)
		particle.size = randf_range(0.04, 0.07)

		# Random color variation
		var colors = [
			Color(1.0, 0.6, 1.0, 1.0),
			Color(0.9, 0.5, 0.8, 1.0),
			Color(0.8, 0.4, 0.7, 1.0),
		]
		particle.primary_pink = colors[randi() % colors.size()]

	particle.mass = randf_range(0.8, 1.2)

	add_child(particle)
	particles.append(particle)

func update_particles(delta: float):
	"""Update all particles (polymorphism!)"""
	for particle in particles:
		# Apply forces (same for all particle types)
		var gravity = Vector3(0, -2.0, 0)
		particle.apply_force(gravity * particle.mass)

		# Wind
		var time = Time.get_ticks_msec() / 1000.0
		var wind = Vector3(sin(time * 0.5) * 0.8, 0, cos(time * 0.7) * 0.6)
		particle.apply_force(wind)

		# Update particle (calls appropriate update method)
		particle.update(delta)

func cleanup_dead_particles():
	"""Remove dead particles"""
	var dead_particles: Array = []

	for particle in particles:
		if particle.is_dead():
			dead_particles.append(particle)

	for particle in dead_particles:
		particles.erase(particle)
		particle.queue_free()

func reset():
	"""Reset scene"""
	for particle in particles:
		particle.queue_free()
	particles.clear()
	spawn_timer = 0.0
