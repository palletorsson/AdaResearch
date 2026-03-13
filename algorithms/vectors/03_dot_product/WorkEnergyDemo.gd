extends "res://algorithms/vectors/shared/force_containment_base.gd"

## Work & Energy Demo
## Demonstrates: W = F · d (dot product)
## Concept: Work depends on force and displacement angle
## Agent-PhysicsArchitect: Shows energy transfer
## Protocol: IACP v2.2

var force_vector: Node3D
var displacement_vector: Node3D
var work_meter: Label3D

# Cached nodes
var _force_cache: Dictionary = {}
var _displacement_cache: Dictionary = {}

var accumulator: float = 0.0
const UPDATE_INTERVAL = 0.1

var last_position: Vector3 = Vector3.ZERO
var total_work: float = 0.0

func _ready() -> void:
	super._ready()
	_setup_demo()
	last_position = physics_ball.global_position / SCENE_SCALE
	print("WorkEnergyDemo: Ready - Drag force to do work!")

func _setup_demo() -> void:
	"""Setup work & energy demonstration"""
	# Applied force (user can drag) - Red
	force_vector = create_force_vector(
		"Force",
		Vector3(2.0, 0, 0),
		Color(1.0, 0.3, 0.3, 1.0),
		true
	)
	_force_cache = _cached_vector_nodes["Force"]
	
	# Displacement (read-only, shows recent movement) - Cyan
	displacement_vector = create_force_vector(
		"Displacement",
		Vector3.ZERO,
		Color(0.3, 0.8, 1.0, 1.0),
		false
	)
	_displacement_cache = _cached_vector_nodes["Displacement"]
	
	# Work meter (large display)
	work_meter = Label3D.new()
	work_meter.text = "Work: 0.00 J"
	work_meter.position = Vector3(0, 0.9, 0) * SCENE_SCALE
	work_meter.font_size = 32
	work_meter.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	work_meter.modulate = Color(1.0, 1.0, 0.3, 1.0)
	work_meter.outline_size = 4
	work_meter.outline_modulate = Color.BLACK
	add_child(work_meter)
	
	update_info_text([
		"Work & Energy Demo",
		"Drag the force vector",
		"W = F · d",
		"Work = Force · Displacement"
	])

func _physics_process(delta: float) -> void:
	update_force_vector_position()
	
	# Get force (logical)
	var force = _get_vector_fast_cached(_force_cache)
	
	# Apply force
	physics_ball.apply_central_force(force * SCENE_SCALE)
	
	# Calculate displacement since last frame
	var current_pos = physics_ball.global_position / SCENE_SCALE
	var displacement = current_pos - last_position
	
	# Update displacement vector visualization
	_update_vector_fast_cached(_displacement_cache, displacement * 10.0)  # Scale up for visibility
	
	# Calculate work done this frame: W = F · d
	var work_this_frame = force.dot(displacement)
	total_work += work_this_frame
	
	# Update last position
	last_position = current_pos
	
	# Throttled info update
	accumulator += delta
	if accumulator >= UPDATE_INTERVAL:
		_update_info(force, displacement, work_this_frame)
		accumulator = 0.0

func _update_info(force: Vector3, displacement: Vector3, work: float) -> void:
	"""Update info display"""
	var angle = 0.0
	if force.length() > 0.001 and displacement.length() > 0.001:
		var cos_angle = force.normalized().dot(displacement.normalized())
		angle = rad_to_deg(acos(clamp(cos_angle, -1.0, 1.0)))
	
	var lines = [
		"Work & Energy Demo",
		"",
		"Force: %.2f N" % force.length(),
		"F = (%.2f, %.2f, %.2f)" % [force.x, force.y, force.z],
		"",
		"Displacement: %.3f m" % displacement.length(),
		"d = (%.3f, %.3f, %.3f)" % [displacement.x, displacement.y, displacement.z],
		"",
		"Angle: %.1f°" % angle,
		"",
		"Work (this frame): %.4f J" % work,
		"W = F · d = |F||d|cos(θ)",
		"",
		"Total Work: %.2f J" % total_work
	]
	update_info_text(lines)
	
	# Update work meter
	work_meter.text = "Total Work: %.2f J" % total_work
	
	# Color code work meter based on work
	if total_work > 0:
		work_meter.modulate = Color(0.3, 1.0, 0.3, 1.0)  # Green (positive work)
	elif total_work < 0:
		work_meter.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red (negative work)
	else:
		work_meter.modulate = Color(1.0, 1.0, 0.3, 1.0)  # Yellow (zero work)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_demo()
		elif event.keycode == KEY_SPACE:
			physics_ball.linear_velocity = Vector3.ZERO
			physics_ball.angular_velocity = Vector3.ZERO

func _reset_demo() -> void:
	"""Reset to initial state"""
	reset_ball(Vector3.ZERO)
	last_position = Vector3.ZERO
	total_work = 0.0
	
	# Reset force vector
	var end: Node3D = _force_cache.get("end")
	if end:
		end.position = Vector3(2.0, 0, 0) * SCENE_SCALE
	var line: Node3D = _force_cache.get("line_container")
	if line and line.has_method("refresh_connections"):
		line.refresh_connections()
	
	work_meter.text = "Work: 0.00 J"
	work_meter.modulate = Color(1.0, 1.0, 0.3, 1.0)
	
	print("WorkEnergyDemo: Reset")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

