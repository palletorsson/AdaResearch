extends "res://commons/primitives/snappoint/snap_point.gd"
func on_desktop_grab(_pointer: Node3D) -> void:
	set_meta("capability_desktop_held",true);picked_up.emit(self)
func on_desktop_drop(_pointer: Node3D) -> void:
	remove_meta("capability_desktop_held");freeze=true
	dropped.emit(self)
