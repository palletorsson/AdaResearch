extends XRToolsPickable
## Route the existing desktop carry gesture through the same ruin events as VR.
func on_desktop_grab(_pointer: Node3D) -> void:
	set_meta("capability_desktop_held",true)
	picked_up.emit(self)

func on_desktop_drop(_pointer: Node3D) -> void:
	remove_meta("capability_desktop_held")
	freeze=false;sleeping=false
	dropped.emit(self)
