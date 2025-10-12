# ===========================================================================
# NOC Example 4.3: Particle Emitter
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 4.3: Particle Emitter
## Using ParticleEmitter class to manage particles
## Chapter 04: Particle Systems

var emitter: ParticleEmitter

# UI
var info_label: Label3D

func _ready():

	# Create UI
	create_info_label()

	# Create emitter
	create_emitter()

	print("Example 4.3: Particle Emitter - ParticleEmitter class demonstration")

func _process(_delta):
	update_info_label()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Emit burst of particles
			for i in range(20):
				emitter.emit_particle()
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_UP:
			emitter.emission_rate = min(emitter.emission_rate + 2.0, 30.0)
		elif event.keycode == KEY_DOWN:
			emitter.emission_rate = max(emitter.emission_rate - 2.0, 1.0)
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
	instructions.text = "[SPACE] Burst | [↑/↓] Rate | [C] Clear | [R] Reset"
	add_child(instructions)

func update_info_label():
	"""Update info label"""
	if info_label and emitter:
		info_label.text = "Particle Emitter\n%d particles (%.1f/s)" % [emitter.get_particle_count(), emitter.emission_rate]

func create_emitter():
	"""Create particle emitter"""
	emitter = ParticleEmitter.new()
	emitter.position = Vector3(0, 0.3, 0)
	emitter.max_particles = 100
	emitter.emission_rate = 10.0
	emitter.particle_lifetime = 4.0
	emitter.particle_size = 0.05
	emitter.initial_velocity = Vector3(0, 1.0, 0)
	emitter.velocity_randomness = 0.6
	emitter.gravity = Vector3(0, -2.0, 0)

	# Add visual indicator for emitter position
	create_emitter_visual(emitter)

	add_child(emitter)

func create_emitter_visual(parent: Node3D):
	"""Create visual marker for emitter"""
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	marker.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 0.5, 0.8)
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 0.5) * 0.8
	material.emission_energy_multiplier = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override = material

	parent.add_child(marker)

func reset():
	"""Reset emitter"""
	if emitter:
		emitter.clear_particles()
		emitter.emission_rate = 10.0
