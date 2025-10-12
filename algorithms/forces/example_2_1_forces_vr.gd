# ===========================================================================
# NOC Example 2.1: Forces
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 2.1: Forces
## Demonstrating wind and gravity forces on a mover
## Chapter 02: Forces

var mover: Mover

# Forces
var gravity: Vector3 = Vector3(0, -0.5, 0)
var wind: Vector3 = Vector3(0.3, 0, 0)
var wind_enabled: bool = true

# UI
var info_label: Label3D

func _ready():

	# Create UI
	create_info_label()

	# Create mover
	create_mover()

	print("Example 2.1: Forces - Wind and gravity demonstration")

func _process(_delta):
	update_info_label()

func _physics_process(_delta):
	if mover:
		# Apply gravity (always)
		mover.apply_force(gravity * mover.mass)

		# Apply wind (toggleable)
		if wind_enabled:
			mover.apply_force(wind)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			wind_enabled = !wind_enabled
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_UP:
			wind.x += 0.1
		elif event.keycode == KEY_DOWN:
			wind.x -= 0.1
		elif event.keycode == KEY_LEFT:
			gravity.y -= 0.1
		elif event.keycode == KEY_RIGHT:
			gravity.y += 0.1

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
	instructions.text = "[SPACE] Toggle Wind | [↑/↓] Wind | [←/→] Gravity | [R] Reset"
	add_child(instructions)

func update_info_label():
	"""Update info label"""
	if info_label and mover:
		var wind_status = "ON" if wind_enabled else "OFF"
		info_label.text = "Forces (F=ma)\nWind: %s | G: %.1f" % [wind_status, abs(gravity.y)]

func create_mover():
	"""Create mover object"""
	mover = Mover.new()
	mover.position_v = Vector3(0, 0.3, 0)
	mover.mass = 1.0
	mover.set_size(0.06)
	mover.primary_pink = Color(1.0, 0.6, 1.0)
	add_child(mover)

func reset():
	"""Reset mover"""
	if mover:
		mover.queue_free()

	create_mover()
	wind_enabled = true
	wind = Vector3(0.3, 0, 0)
	gravity = Vector3(0, -0.5, 0)
