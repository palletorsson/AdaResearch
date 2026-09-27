extends Node
## Shared measured input for spatial and timed Trace instruments.
## This node has no display, generated fallback or recorded history.
signal discontinuity
var _body: Node
var _interface: XRInterface

func _ready() -> void:
	if XRServer.has_signal("reference_frame_changed"):
		XRServer.connect("reference_frame_changed", _notify_discontinuity)

func _notify_discontinuity(_unused: Variant = null) -> void:
	discontinuity.emit()

func _exit_tree() -> void:
	if is_instance_valid(_interface) and _interface.play_area_changed.is_connected(_notify_discontinuity):
		_interface.play_area_changed.disconnect(_notify_discontinuity)
	if is_instance_valid(_body) and _body.is_connected("player_teleported", _notify_discontinuity):
		_body.disconnect("player_teleported", _notify_discontinuity)

func read_input() -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return {}
	var xr := XRServer.primary_interface
	if camera is XRCamera3D:
		if xr == null or not xr.is_initialized(): return {}
		# Do not treat an old/staging camera or uncertain tracking as measurement.
		if xr.get_tracking_status() != XRInterface.XR_NORMAL_TRACKING: return {}
		var rig := camera.get_parent() as XROrigin3D
		if rig == null or not rig.current: return {}
		if xr != _interface:
			if is_instance_valid(_interface) and _interface.play_area_changed.is_connected(_notify_discontinuity):
				_interface.play_area_changed.disconnect(_notify_discontinuity)
			_interface = xr
			_interface.play_area_changed.connect(_notify_discontinuity)
			_notify_discontinuity()
		# XRTools teleports may be shorter than the displacement guard.
		if not is_instance_valid(_body) or not rig.is_ancestor_of(_body):
			if is_instance_valid(_body) and _body.is_connected("player_teleported", _notify_discontinuity):
				_body.disconnect("player_teleported", _notify_discontinuity)
			_body = null
			for child in rig.find_children("*", "CharacterBody3D", true, false):
				if child.has_signal("player_teleported"):
					_body = child
					_body.connect("player_teleported", _notify_discontinuity)
					break
		return {"camera":camera, "kind":"HEADSET"}
	# Never silently record a spectator, photo, editor or staging camera.
	if xr != null and xr.is_initialized(): return {}
	var ancestor: Node = camera
	while ancestor != null:
		if ancestor.is_in_group("em_walker"):
			return {"camera":camera, "kind":"DESKTOP VIEW"}
		ancestor = ancestor.get_parent()
	return {}
