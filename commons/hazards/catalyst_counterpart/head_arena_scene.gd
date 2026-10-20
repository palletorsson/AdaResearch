extends "res://commons/scenes/em/em_portal_scene_base.gd"
## The actual game/staging destination. Its rig comes from the same museum base.
var returning := false

func scene_loaded(user_data = null) -> void:
	# With no headset, preserve the museum's own walker camera.
	if bool(get_node("Museum").get("_vr")):
		super.scene_loaded(user_data)

func return_to_menu() -> void:
	if returning: return
	returning = true
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.has_method("return_to_main_menu"):
			ancestor.return_to_main_menu()
			return
		ancestor = ancestor.get_parent()
	# Direct F6 launch has no existing staging session to return to.
	get_tree().change_scene_to_file.call_deferred("res://commons/scenes/vr_staging.tscn")
