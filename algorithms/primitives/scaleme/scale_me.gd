extends "res://commons/primitives/point/grab_sphere.gd"

## Scale parameters
@export var scale_amount: float = 100.0
@export var scale_duration: float = 20.0  # seconds
@export var scale_up_time: float = 5.0  # seconds to scale up
@export var scale_down_time: float = 5.0  # seconds to scale down
@export var world_node_path: NodePath = NodePath("")  # Optional: specific node to scale
@export var xr_origin_path: NodePath = NodePath("../../XROrigin3D")  # Path to player

var _original_scale: Vector3 = Vector3.ONE
var _is_scaled: bool = false
var _scale_timer: Timer
var _world_node: Node3D
var _xr_origin: XROrigin3D

func _ready() -> void:
	super._ready()

	# Setup timer for auto-scaling back
	_scale_timer = Timer.new()
	_scale_timer.name = "ScaleTimer"
	_scale_timer.one_shot = true
	_scale_timer.timeout.connect(_on_scale_timer_timeout)
	add_child(_scale_timer)

	# Find world node to scale
	_find_world_node()

	# Find the XR origin (player)
	# Try using the specified path first
	if xr_origin_path != NodePath(""):
		_xr_origin = get_node_or_null(xr_origin_path)

	# Fall back to XRHelpers if path didn't work
	if not _xr_origin:
		_xr_origin = XRHelpers.get_xr_origin(self)

	if _xr_origin:
		print("ScaleMe: Found XR Origin at ", _xr_origin.get_path())
	else:
		push_warning("ScaleMe: Could not find XR Origin")

func _find_world_node() -> void:
	# If a specific path is provided, use it
	if world_node_path != NodePath(""):
		_world_node = get_node_or_null(world_node_path)
		if _world_node:
			_original_scale = _world_node.scale
			print("ScaleMe: Using specified world node at ", world_node_path)
			return

	# Otherwise, use the parent node of scale_me (the local area to scale)
	_world_node = get_parent()
	if _world_node and _world_node is Node3D:
		_original_scale = _world_node.scale
		print("ScaleMe: Scaling parent node: ", _world_node.name)
	else:
		push_warning("ScaleMe: Could not find valid world node to scale")

# Override the pickup handler
func _on_picked_up(pickable) -> void:
	super._on_picked_up(pickable)

	# Scale the world when picked up
	if not _is_scaled:
		_scale_world()

func _scale_world() -> void:
	if not _world_node:
		push_warning("ScaleMe: No world node to scale")
		return

	_is_scaled = true

	# Disable the grab sphere's collider before scaling
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape:
		collision_shape.disabled = true
		print("ScaleMe: Disabled collider to prevent scaling physics objects")

	# Store original scale if not already stored
	if _original_scale == Vector3.ONE and _world_node.scale != Vector3.ONE:
		_original_scale = _world_node.scale

	# Scale player X,Z by (scale_amount / 5), set Y to 5
	if _xr_origin:
		var current_pos = _xr_origin.global_position
		var scale_factor = scale_amount / 5.0
		var new_x = current_pos.x * scale_factor
		var new_z = current_pos.z * scale_factor
		var new_pos = Vector3(new_x, 5.0, new_z)
		_xr_origin.global_position = new_pos
		print("ScaleMe: Set player Y to 5, scaled X,Z by ", scale_factor, " - position: ", new_pos)

	# Scale the world
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_world_node, "scale", _original_scale * scale_amount, scale_up_time)

	print("ScaleMe: World scaling to ", _original_scale * scale_amount)

	# Start timer to scale back down
	_scale_timer.start(scale_duration)

	# Properly drop the object first, then hide and free
	call_deferred("_cleanup_pill")

func _cleanup_pill() -> void:
	# Disable the object to prevent further interactions
	enabled = false

	# Drop the object properly if it's still being held
	if is_picked_up():
		drop()

	# Hide immediately
	hide()

	# Disable collision to prevent physics issues
	collision_layer = 0
	collision_mask = 0

	# Don't free the object yet - we need it to keep the timer alive for scale-down
	# It will be freed after the scale-down completes

func _on_scale_timer_timeout() -> void:
	if not _world_node:
		return

	# Don't move player when scaling down - let them stay at current position and fall
	if _xr_origin:
		var current_pos = _xr_origin.global_position
		print("ScaleMe: Player position unchanged at ", current_pos, " - will fall naturally")

	# Scale the world back down
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_world_node, "scale", _original_scale, scale_down_time)

	_is_scaled = false

	print("ScaleMe: World scaling down to ", _original_scale)

	# Wait for scale-down to complete, then clean up
	await tween.finished

	# Now we can safely free the object
	queue_free()
