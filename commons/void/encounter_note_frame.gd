extends "res://commons/void/opera_view_frame.gd"
## An encounter awaiting a song. Its working note is visible in the editor.
func _physics_process(_delta: float) -> void:
	illuminate(sees(get_viewport().get_camera_3d(), to_global(Vector3.FORWARD * 0.1)))
