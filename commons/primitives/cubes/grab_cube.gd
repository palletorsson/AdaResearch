@tool
extends XRToolsPickable


## Alternate material when button pressed
@export var alternate_material : Material
@export var snap_to_shelf: bool = true
@export var snap_max_distance: float = 0.08
@export var snap_match_rotation: bool = false
@export var snap_falloff_distance: float = 1.0

## Debug: Enable collision logging to find invisible pushers
@export var debug_collisions: bool = false

# Original material
var _original_material : Material

# Current controller holding this object
var _current_controller : XRController3D

# Debug: Track last velocity for push detection
var _last_position: Vector3
var _push_cooldown: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Call the super
	super()

	if not Engine.is_editor_hint():
		set_process(true)
		_last_position = global_position

		# Enable contact monitoring for debug
		if debug_collisions:
			contact_monitor = true
			max_contacts_reported = 4
			body_entered.connect(_on_debug_body_entered)

	# Get the original material
	_original_material = $MeshInstance3D.get_active_material(0)

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)



func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Debug: Detect being pushed
	if debug_collisions and not _current_controller:
		_push_cooldown -= delta
		var velocity = (global_position - _last_position) / delta
		_last_position = global_position

		# If we're moving fast and not held, something is pushing us
		if velocity.length() > 0.5 and _push_cooldown <= 0.0:
			_push_cooldown = 1.0  # Don't spam
			print("=== GRAB_CUBE PUSHED ===")
			print("  Name: %s" % name)
			print("  Velocity: %s (%.2f m/s)" % [str(velocity), velocity.length()])
			print("  Position: %s" % str(global_position))
			_print_contacting_bodies()

	if not snap_to_shelf:
		return
	if _current_controller:
		return
	_snap_to_nearest_shelf_point(true)


func _on_debug_body_entered(body: Node) -> void:
	if not debug_collisions:
		return
	print("=== GRAB_CUBE COLLISION ===")
	print("  %s touched by: %s" % [name, body.name])
	print("  Body path: %s" % str(body.get_path()))
	print("  Body class: %s" % body.get_class())
	if body is Node3D:
		print("  Body position: %s" % str(body.global_position))
	if body is PhysicsBody3D:
		print("  Body collision_layer: %d" % body.collision_layer)


func _print_contacting_bodies() -> void:
	var contacts = get_colliding_bodies()
	if contacts.is_empty():
		print("  No contacting bodies detected (contact_monitor may be off)")
		return
	print("  Contacting bodies (%d):" % contacts.size())
	for body in contacts:
		print("    - %s (%s) at %s" % [body.name, str(body.get_path()), str(body.global_position) if body is Node3D else "N/A"])

# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	# Listen for button events on the associated controller
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.button_pressed.connect(_on_controller_button_pressed)
		_current_controller.button_released.connect(_on_controller_button_released)


# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# Unsubscribe to controller button events when dropped
	if _current_controller:
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller.button_released.disconnect(_on_controller_button_released)
		_current_controller = null

	# Restore original material when dropped
	$MeshInstance3D.set_surface_override_material(0, _original_material)
	_snap_to_nearest_shelf_point()


# Called when a controller button is pressed
func _on_controller_button_pressed(button : String):
	# Handle controller button presses
	if button == "ax_button":
		# Set alternate material when button pressed
		if alternate_material:
			$MeshInstance3D.set_surface_override_material(0, alternate_material)


# Called when a controller button is released
func _on_controller_button_released(button : String):
	# Handle controller button releases
	if button == "ax_button":
		# Restore original material when button released
		$MeshInstance3D.set_surface_override_material(0, _original_material)

func _snap_to_nearest_shelf_point(force: bool = false) -> void:
	if not snap_to_shelf:
		return

	var effective_max = snap_max_distance
	if force:
		effective_max = snap_falloff_distance if snap_falloff_distance > 0.0 else snap_max_distance
	elif snap_max_distance <= 0.0:
		return

	var snap_points = get_tree().get_nodes_in_group("shelf_snap_point")
	if snap_points.is_empty():
		return

	var best_point: Node3D = null
	var best_distance = effective_max if effective_max > 0.0 else INF

	for point in snap_points:
		if point is Node3D:
			var snap_node := point as Node3D
			if not is_instance_valid(snap_node):
				continue
			var distance = snap_node.global_position.distance_to(global_position)
			if distance <= best_distance:
				best_distance = distance
				best_point = snap_node

	if best_point == null:
		return

	if snap_falloff_distance > 0.0 and best_distance > snap_falloff_distance:
		return

	var target = best_point.global_position
	var current_scale = global_transform.basis.get_scale()
	var basis := Basis.IDENTITY
	if snap_match_rotation:
		basis = best_point.global_transform.basis
	basis = basis.scaled(current_scale)
	global_transform = Transform3D(basis, target)
