extends ScrollContainer

## Touch-enabled ScrollContainer for VR
## Handles InputEventScreenDrag from XR Tools viewport_2d_in_3d_body

# Touch scrolling state
var _touch_active := false
var _touch_start := Vector2.ZERO
var _scroll_start := Vector2.ZERO
var _touch_index := -1

# Smooth scrolling
@export var scroll_damping := 0.2
@export var scroll_speed := 1.0

# Velocity for momentum scrolling
var _scroll_velocity := Vector2.ZERO
var _momentum_decay := 0.9


func _ready() -> void:
	# Ensure we can receive input
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	# Handle touch events from XR Tools
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

	# Also support mouse drag for desktop testing
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag()

	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_update_drag(event.relative)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Touch down - start drag
		_touch_active = true
		_touch_index = event.index
		_touch_start = event.position
		_scroll_start = Vector2(scroll_horizontal, scroll_vertical)
		_scroll_velocity = Vector2.ZERO
		print("TouchScroll: Touch DOWN at %s" % event.position)
	else:
		# Touch up - end drag
		if event.index == _touch_index:
			_touch_active = false
			_touch_index = -1
			print("TouchScroll: Touch UP")


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _touch_index and _touch_active:
		# Calculate scroll delta (inverted - drag down = scroll up)
		var delta = (event.position - _touch_start) * scroll_speed

		# Update scroll position
		scroll_vertical = int(_scroll_start.y - delta.y)
		scroll_horizontal = int(_scroll_start.x - delta.x)

		# Store velocity for momentum
		_scroll_velocity = -event.relative * scroll_speed

		# Debug
		#print("TouchScroll: Dragging delta=%s, scroll_v=%d" % [delta, scroll_vertical])


func _start_drag(pos: Vector2) -> void:
	_touch_active = true
	_touch_start = pos
	_scroll_start = Vector2(scroll_horizontal, scroll_vertical)
	_scroll_velocity = Vector2.ZERO


func _end_drag() -> void:
	_touch_active = false


func _update_drag(relative: Vector2) -> void:
	if _touch_active:
		# Apply relative motion to scroll (inverted)
		scroll_vertical -= int(relative.y * scroll_speed)
		scroll_horizontal -= int(relative.x * scroll_speed)
		_scroll_velocity = -relative * scroll_speed


func _process(delta: float) -> void:
	# Apply momentum scrolling when not actively dragging
	if not _touch_active and _scroll_velocity.length_squared() > 0.1:
		scroll_vertical += int(_scroll_velocity.y * delta * 60.0)
		scroll_horizontal += int(_scroll_velocity.x * delta * 60.0)
		_scroll_velocity *= _momentum_decay
