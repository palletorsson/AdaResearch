# ===========================================================================
# NOC Example 4.1: Single Particle
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 4.1: Single Particle
## Demonstrates a single particle with gravity and lifespan
## Chapter 04: Particle Systems

var particle: Particle = null

# UI
var info_label: Label3D

func _ready():

	# Create UI
	create_info_label()

	# Create initial particle
	spawn_particle()

	print("Example 4.1: Single Particle - Click to spawn new particles")

func _process(_delta):
	update_info_label()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			spawn_particle()
		elif event.keycode == KEY_R:
			reset()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spawn_particle()

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
	instructions.text = "[SPACE/CLICK] Spawn Particle | [R] Reset"
	add_child(instructions)

func update_info_label():
	"""Update info label"""
	if info_label:
		if particle and not particle.is_dead():
			var lifetime_pct = (particle.lifespan / particle.max_lifespan) * 100.0
			info_label.text = "Single Particle\nLifetime: %.0f%%" % lifetime_pct
		else:
			info_label.text = "Single Particle\n(Click to spawn)"

func spawn_particle():
	"""Spawn a new particle at center"""
	# Remove old particle if exists
	if particle:
		particle.queue_free()
		particle = null

	# Create new particle at top-center
	var spawn_pos = Vector3(0, 0.3, 0)

	# Random initial velocity (upward and outward)
	var vel = Vector3(
		randf_range(-0.3, 0.3),
		randf_range(0.5, 1.0),
		randf_range(-0.3, 0.3)
	)

	particle = Particle.new(spawn_pos, vel)
	particle.size = 0.06
	particle.mass = 1.0

	add_child(particle)

	# Check if particle is dead each frame and respawn
	await particle.tree_exited
	if is_inside_tree():
		await get_tree().create_timer(0.5).timeout
		if is_inside_tree():
			spawn_particle()

func reset():
	"""Reset scene"""
	if particle:
		particle.queue_free()
		particle = null

	spawn_particle()
