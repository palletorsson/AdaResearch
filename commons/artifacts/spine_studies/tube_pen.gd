extends "res://commons/primitives/point/drawing_pen.gd"
## Reuses the Point Trace grip. Press/release uses the existing desktop/XR action.
var painting := false

func _init() -> void:
	collision_layer = 4; collision_mask = 0
	freeze = true; release_mode = ReleaseMode.FROZEN
	pen_color = Color("e995b4")

func _ready() -> void:
	add_to_group("no_gravity_gun")
	super()
	action_pressed.connect(_begin)
	action_released.connect(_end)
	dropped.connect(_end)

func _begin(_object = null) -> void:
	if desktop_held or is_picked_up(): painting = true

func _end(_object = null) -> void:
	painting = false

func on_desktop_drop(pointer: Node) -> void:
	painting = false
	super(pointer)
	freeze = true; linear_velocity = Vector3.ZERO; angular_velocity = Vector3.ZERO

func held_by_visitor() -> bool:
	return desktop_held or is_picked_up()
