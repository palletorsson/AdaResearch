extends Node3D
## F6 launches the actual installed hall without changing the user's saved route.
func _ready() -> void:
	var museum = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var settings: Dictionary={}
	var original: String=museum.get("EM_CONTROL")
	if FileAccess.file_exists(original):
		var data=JSON.parse_string(FileAccess.get_file_as_string(original))
		if data is Dictionary: settings=data.duplicate(true)
	for key in ["resume_eye","resume_hall","resume_yaw","resume_pitch","travel"]: settings.erase(key)
	settings["first_chapter"]="foundationscrisis"
	settings["first_map"]="NonEuclidean_Spaces"
	settings["dollhouse"]=0
	var path := "user://ada_noneuclidean_wing_control.json"
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		push_error("Could not create local wing launch settings")
		return
	file.store_string(JSON.stringify(settings)); file.close()
	museum.set("EM_CONTROL",path)
	museum.set("start_chapter","foundationscrisis")
	museum.set("start_map","NonEuclidean_Spaces")
	add_child(museum)
