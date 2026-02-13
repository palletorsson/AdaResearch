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

# UI — Ada rack panel
var _panel: ForcesRackPanel
var _wind_readout: Label3D
var _gravity_readout: Label3D

func _ready():
	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	# Create UI panel
	_create_panel()

	# Create mover
	create_mover()

	print("Example 2.1: Forces - Wind and gravity demonstration")

func _process(_delta):
	_update_readouts()

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

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.1  Forces (F = ma)", 1, 2)
	_panel.set_instructions("[SPACE] Toggle Wind  [Arrows] Adjust  [R] Reset")

	_wind_readout = _panel.add_readout("Wind", "ON  0.30")
	_gravity_readout = _panel.add_readout("Gravity", "0.50")

	# Position panel to the left, at chest height, angled toward viewer
	_panel.position = Vector3(-0.45, 0.35, 0.1)
	_panel.rotation_degrees = Vector3(0, 25, 0)
	add_child(_panel)

func _update_readouts() -> void:
	if _wind_readout:
		var status := "ON" if wind_enabled else "OFF"
		_panel.update_readout("Wind", "%s  %.2f" % [status, wind.x])
	if _gravity_readout:
		_panel.update_readout("Gravity", "%.2f" % abs(gravity.y))

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
