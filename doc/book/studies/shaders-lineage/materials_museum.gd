extends Node3D
## Supplied launcher; all learner geometry comes from the printed continuation.
const LESSON=preload("res://doc/book/iterations/2026-10-10-materials-light-without-height/learner/printed/shaping.gd")

func _ready()->void:
	var museum=load("res://commons/scenes/endless_museum.tscn").instantiate()
	configure(museum,"user://materials_lesson_control.json")
	add_child(museum)
	while is_instance_valid(museum) and not bool(museum.get("_museum_core_ready")):await get_tree().process_frame
	if not is_instance_valid(museum):return
	for hall in museum.get_children():
		if hall is Node3D and str(hall.get_meta("em_map",""))=="Shader_11_QueerRubber":
			mount(hall,LESSON);return
	push_error("Materials learner launcher: authored hall not found")

static func configure(museum:Node3D,control_path:String)->void:
	# A saved travel/resume can otherwise override the requested lesson hall.
	var settings:Dictionary={}
	var old_path:String=museum.get("EM_CONTROL")
	if FileAccess.file_exists(old_path):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(old_path))
		if parsed is Dictionary:settings=parsed.duplicate(true)
	for key in ["resume_eye","resume_hall","resume_yaw","resume_pitch","travel"]:settings.erase(key)
	settings["first_chapter"]="shaders";settings["first_map"]="Shader_11_QueerRubber"
	settings["dollhouse"]=0;settings["grid_pack"]=1
	var file:=FileAccess.open(control_path,FileAccess.WRITE)
	if file==null:
		push_error("Cannot prepare Materials lesson control file");return
	file.store_string(JSON.stringify(settings));file.close()
	museum.set("EM_CONTROL",control_path)
	museum.set("start_chapter","shaders");museum.set("start_map","Shader_11_QueerRubber")

static func mount(hall:Node3D,lesson:Script)->Node3D:
	for node in hall.find_children("*","Node3D",true,false):
		if node.scene_file_path.ends_with("/shader_material_parlour.tscn"):
			var study=lesson.new();study.name="LearnerMaterials"
			study.position=Vector3(4.5,0,2.0);node.add_child(study);return study
	push_error("Materials learner launcher: material parlour not found")
	return null
