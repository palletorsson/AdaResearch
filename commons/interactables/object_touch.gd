extends Area3D
## Touch the existing object's surface; no cap, plate or press animation.
## Hand contact and desktop/XR pointer presses use the same action.
signal touched
var available: Callable
var last_touch := -1.0
var contacts: Dictionary = {}
func rearm() -> void:
	# A restored take accepts a fresh touch immediately, without inheriting
	# the previous take's duplicate-contact debounce window.
	last_touch=-1.0
func _ready() -> void:
	collision_layer = 1 << 20
	collision_mask = (1 << 17) | (1 << 18)
	monitorable = true
	body_entered.connect(_entered)
	body_exited.connect(_exited)
	area_entered.connect(_entered)
	area_exited.connect(_exited)
func _entered(item: Node3D) -> void:
	var first := contacts.is_empty()
	contacts[item.get_instance_id()] = true
	if first: touch()
func _exited(item: Node3D) -> void: contacts.erase(item.get_instance_id())
func touch() -> void:
	if available.is_valid() and not available.call(): return
	var now := Time.get_ticks_msec()*.001
	if now-last_touch < .35: return
	last_touch = now
	touched.emit()
func pointer_event(event: XRToolsPointerEvent) -> void:
	if event.event_type == XRToolsPointerEvent.Type.PRESSED: touch()
