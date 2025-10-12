# ===========================================================================
# NOC Example 4.6: Particle Repeller
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 4.6: Particle System with Repeller
## Particles are repelled by a moveable object
## Chapter 04: Particle Systems

var emitter: ParticleEmitter
var repeller: Node3D
var repeller_position: Vector3 = Vector3.ZERO
var repeller_strength: float = 2.0
var repeller_radius: float = 0.3

# UI
var info_label: Label3D

func _ready():

	# Create UI
	create_info_label()

	# Create emitter
	create_emitter()

	# Create repeller
	create_repeller()

	print("Example 4.6: Particle Repeller - Repulsion force demonstration")

func _process(delta):
	# Animate repeller position
	animate_repeller(delta)

	# Apply repeller force to all particles
	apply_repeller_forces()

	# Update UI
	update_info_label()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Emit burst
			for i in range(20):
				emitter.emit_particle()
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_UP:
			repeller_strength = min(repeller_strength + 0.5, 10.0)
		elif event.keycode == KEY_DOWN:
			repeller_strength = max(repeller_strength - 0.5, 0.5)
		elif event.keycode == KEY_C:
			emitter.clear_particles()

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
	instructions.text = "[SPACE] Burst | [↑/↓] Strength | [C] Clear | [R] Reset"
	add_child(instructions)

func update_info_label():
	"""Update info label"""
	if info_label and emitter:
		info_label.text = "Particle Repeller\n%d particles | Strength: %.1f" % [emitter.get_particle_count(), repeller_strength]

func create_emitter():
	"""Create particle emitter at top"""
	emitter = ParticleEmitter.new()
	emitter.position = Vector3(0, 0.4, 0)
	emitter.max_particles = 150
	emitter.emission_rate = 15.0
	emitter.particle_lifetime = 6.0
	emitter.particle_size = 0.04
	emitter.initial_velocity = Vector3(0, 0.5, 0)
	emitter.velocity_randomness = 0.3
	emitter.gravity = Vector3(0, -1.0, 0)

	# Emitter visual
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	marker.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.6, 1.0, 0.8)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.6, 1.0) * 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override = material

	emitter.add_child(marker)

	add_child(emitter)

func create_repeller():
	"""Create repeller object"""
	repeller = Node3D.new()
	repeller_position = Vector3(0, 0, 0)
	repeller.position = repeller_position
	add_child(repeller)

	# Repeller visual (red sphere)
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = repeller_radius
	mesh_instance.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.3, 0.3, 0.7)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.3, 0.3) * 0.8
	material.emission_energy_multiplier = 1.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	repeller.add_child(mesh_instance)

	# Repeller boundary ring
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = repeller_radius - 0.02
	torus.outer_radius = repeller_radius + 0.02
	ring.mesh = torus

	var ring_material = StandardMaterial3D.new()
	ring_material.albedo_color = Color(1.0, 0.5, 0.5, 0.9)
	ring_material.emission_enabled = true
	ring_material.emission = Color(1.0, 0.5, 0.5) * 0.5
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_material

	repeller.add_child(ring)

func animate_repeller(delta: float):
	"""Move repeller in circular pattern"""
	var time = Time.get_ticks_msec() / 1000.0

	repeller_position = Vector3(
		sin(time * 0.8) * 0.25,
		sin(time * 1.2) * 0.15,
		cos(time * 0.8) * 0.25
	)

	repeller.position = repeller_position

	# Pulsing effect
	var pulse = 1.0 + sin(time * 4.0) * 0.15
	repeller.scale = Vector3.ONE * pulse

func apply_repeller_forces():
	"""Apply repulsion force to all particles"""
	if not emitter:
		return

	for particle in emitter.particles:
		var force = calculate_repulsion_force(particle)
		particle.apply_force(force)

func calculate_repulsion_force(particle: Particle) -> Vector3:
	"""Calculate repulsion force from repeller to particle"""
	# Direction from repeller to particle
	var dir = particle.global_position - repeller_position
	var distance = dir.length()

	# Normalize direction
	if distance > 0.001:
		dir = dir.normalized()
	else:
		dir = Vector3.UP  # Avoid division by zero

	# Constrain distance to avoid extreme forces
	distance = clamp(distance, 0.1, 2.0)

	# Inverse square law: F = strength / (distance^2)
	var strength = repeller_strength / (distance * distance)

	# Repulsion force (pushes away from repeller)
	var force = dir * strength

	# Visual feedback: brighten particle if close to repeller
	if distance < repeller_radius and particle.material:
		particle.material.emission_energy_multiplier = 1.5

	return force

func reset():
	"""Reset scene"""
	if emitter:
		emitter.clear_particles()
		emitter.emission_rate = 15.0

	repeller_strength = 2.0
