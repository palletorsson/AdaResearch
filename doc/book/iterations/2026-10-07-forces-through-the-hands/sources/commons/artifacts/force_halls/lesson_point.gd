extends "res://commons/artifacts/ignorance_gallery/point_body.gd"
## The earlier learner point, held where it is released for a vector reading.
func on_desktop_grab(_pointer: Node3D) -> void:
	set_meta("lesson_held",true)
func on_desktop_drop(_pointer: Node3D) -> void:
	remove_meta("lesson_held")
	freeze=true
