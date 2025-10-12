# ===========================================================================
# NOC Example 4.4: Multiple Emitters
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 4.4: Multiple Emitters
## Multiple particle emitters with different properties
## Chapter 04: Particle Systems

var emitters: Array[ParticleEmitter] = []

# UI
var info_label: Label3D

# Emitter colors
var emitter_colors: Array[Color] = [
	Color(1.0, 0.6, 1.0, 1.0),   # Pink
	Color(0.5, 0.5, 1.0, 1.0),   # Blue
	Color(0.5, 1.0, 0.5, 1.0),   # Green
	Color(1.0, 1.0, 0.5, 1.0),   # Yellow
]

func _ready():

	# Create UI
	create_info_label()

	# Create multiple emitters
	create_emitters()

	print("Example 4.4: Multiple Emitters - 4 emitters with different properties")

func _process(_delta):
	update_info_label()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Emit burst from all emitters
			for emitter in emitters:
				for i in range(10):
					emitter.emit_particle()
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_C:
			clear_all()
		elif event.keycode == KEY_1:
			toggle_emitter(0)
		elif event.keycode == KEY_2:
			toggle_emitter(1)
		elif event.keycode == KEY_3:
			toggle_emitter(2)
		elif event.keycode == KEY_4:
			toggle_emitter(3)

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
	instructions.text = "[SPACE] Burst | [1-4] Toggle | [C] Clear | [R] Reset"
	add_child(instructions)

func update_info_label():
	"""Update info label"""
	if info_label:
		var total_particles = 0
		for emitter in emitters:
			total_particles += emitter.get_particle_count()

		info_label.text = "Multiple Emitters\n%d total particles (%d emitters)" % [total_particles, emitters.size()]

func create_emitters():
	"""Create 4 emitters in corners"""
	var positions = [
		Vector3(-0.25, 0.3, -0.25),  # Front-left
		Vector3(0.25, 0.3, -0.25),   # Front-right
		Vector3(-0.25, 0.3, 0.25),   # Back-left
		Vector3(0.25, 0.3, 0.25),    # Back-right
	]

	var velocities = [
		Vector3(0.5, 1.0, 0.5),    # Up-right
		Vector3(-0.5, 1.0, 0.5),   # Up-left
		Vector3(0.5, 1.0, -0.5),   # Up-right-back
		Vector3(-0.5, 1.0, -0.5),  # Up-left-back
	]

	for i in range(4):
		var emitter = ParticleEmitter.new()
		emitter.position = positions[i]
		emitter.max_particles = 60
		emitter.emission_rate = 5.0 + i * 2.0  # Varying rates
		emitter.particle_lifetime = 4.0
		emitter.particle_size = 0.04 + i * 0.01  # Varying sizes
		emitter.initial_velocity = velocities[i]
		emitter.velocity_randomness = 0.4
		emitter.gravity = Vector3(0, -1.5, 0)
		emitter.particle_color = emitter_colors[i]

		# Create visual marker
		create_emitter_visual(emitter, emitter_colors[i])

		add_child(emitter)
		emitters.append(emitter)

func create_emitter_visual(parent: Node3D, color: Color):
	"""Create visual marker for emitter"""
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	marker.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.8
	material.emission_energy_multiplier = 1.2
	marker.material_override = material

	parent.add_child(marker)

	# Pulsing animation
	var tween = create_tween().set_loops()
	tween.tween_property(marker, "scale", Vector3.ONE * 1.3, 0.8)
	tween.tween_property(marker, "scale", Vector3.ONE * 0.7, 0.8)

func toggle_emitter(index: int):
	"""Toggle emitter on/off"""
	if index < emitters.size():
		var emitter = emitters[index]
		emitter.emission_rate = 0.0 if emitter.emission_rate > 0 else 5.0 + index * 2.0
		print("Emitter %d: %s" % [index + 1, "OFF" if emitter.emission_rate == 0 else "ON"])

func clear_all():
	"""Clear all particles"""
	for emitter in emitters:
		emitter.clear_particles()

func reset():
	"""Reset all emitters"""
	for i in range(emitters.size()):
		emitters[i].clear_particles()
		emitters[i].emission_rate = 5.0 + i * 2.0
