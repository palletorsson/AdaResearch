extends "res://commons/artifacts/oscillation_controlled_cube/oscillation_controlled_cube.gd"
## The editor gives each object a mount. Connect across those mounts explicitly.
@export var driver_id: String = "pendulum"

func _connect_pendulum():
	_pendulum = get_parent().get_parent().get_node_or_null(NodePath(driver_id + "/Artifact"))
	if is_instance_valid(_pendulum) and _pendulum.has_signal("oscillation_updated"):
		if not _pendulum.oscillation_updated.is_connected(_on_oscillation_updated):
			_pendulum.oscillation_updated.connect(_on_oscillation_updated)

func _process(_delta):
	# A removed driver must not silently turn the follower into a clock animation.
	if not is_instance_valid(_pendulum):
		_label.text = "NO PENDULUM INPUT"

func _on_oscillation_updated(y_offset: float, angular_velocity: float, amplitude: float):
	super._on_oscillation_updated(y_offset, angular_velocity, amplitude)
	# Preserve the original motion; make the imported readouts legible.
	_label.text = "Y %+.2f m\nTURN %+.1f deg\nSIZE %.2f" % [position.y - _base_position.y, rad_to_deg(_current_rotation), _cube_instance.scale.x / cube_size]
	if _breakdown_label and show_guides:
		_breakdown_label.text = "ONE PENDULUM\nDisplacement > height\nVelocity > turn\nAngle magnitude > size"
