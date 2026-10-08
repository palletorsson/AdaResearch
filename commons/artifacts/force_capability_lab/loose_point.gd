extends "res://commons/artifacts/ignorance_gallery/point_body.gd"
## Give the existing point physical release on both museum input paths.
func _ready() -> void:
	super()
	release_mode = XRToolsPickable.ReleaseMode.UNFROZEN

func on_desktop_grab(_pointer: Node3D) -> void:
	set_meta("capability_desktop_held",true)

func on_desktop_drop(_pointer: Node3D) -> void:
	remove_meta("capability_desktop_held")
	freeze = false; sleeping = false
