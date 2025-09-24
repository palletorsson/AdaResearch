@tool
extends XRToolsPickable


## Alternate material when button pressed
@export var alternate_material : Material
@export var snap_to_shelf: bool = true
@export var snap_max_distance: float = 0.08
@export var snap_match_rotation: bool = false
@export var snap_falloff_distance: float = 1.0


# Original material
var _original_material : Material

# Current controller holding this object
var _current_controller : XRController3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Call the super
	super()

	if not Engine.is_editor_hint():
		set_process(true)

	# Get the original material
	_original_material = $MeshInstance3D.get_active_material(0)

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)



func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not snap_to_shelf:
		return
	if _current_controller:
		return
	_snap_to_nearest_shelf_point(true)

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
