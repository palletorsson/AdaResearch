extends "res://algorithms/randomness/randompoints/randompoints.gd"
## Keep the museum's generation and observer. A reset must also teleport the
## frozen physics bodies: Jolt otherwise restores a carried point's old pose.
func _ready() -> void:
	super._ready()
	var area: Area3D = _bench.find_child("Btn_3", true, false).get_node("InteractableAreaButton")
	# The source lambda binds its own restore implementation. Route this button
	# explicitly through the adapter, outside the physics input callback.
	for connection in area.button_pressed.get_connections():
		if connection.callable.get_object() == self:
			area.button_pressed.disconnect(connection.callable)
	area.button_pressed.connect(_restore_pressed)

func _restore_pressed(_button: Node) -> void:
	restore.call_deferred()

func restore() -> void:
	super.restore()
	for key in _points:
		for point in _points[key]:
			if not is_instance_valid(point): continue
			if point.is_picked_up(): point.drop()
			point.freeze = true
			point.position = point.get_meta("home")
			PhysicsServer3D.body_set_state(point.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, point.global_transform)
	_watch_neighbours()
	_update_readout()
