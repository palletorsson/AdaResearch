extends Node3D
## Supplied room launcher. Learner geometry comes only from the printed script.
const LESSON = preload("res://doc/book/iterations/2026-10-10-shaping-a-rule-on-the-cube/learner/printed/shaping.gd")

func _ready() -> void:
	var museum=load("res://commons/scenes/endless_museum.tscn").instantiate()
	configure(museum,"user://shaping_lesson_control.json")
	add_child(museum)
	while is_instance_valid(museum) and not bool(museum.get("_museum_core_ready")):
		await get_tree().process_frame
	if not is_instance_valid(museum):return
	for node in museum.get_children():
		if node is Node3D and str(node.get_meta("em_map",""))=="Shader_01_Shaping":
			mount(node,LESSON)
			return
	push_error("Shaping learner launcher: authored hall not found")

static func configure(museum:Node3D,control_path:String)->void:
	# Keep the lesson entry independent of the visitor's saved travel/resume.
	var settings:Dictionary={}
	var old_path:String=museum.get("EM_CONTROL")
	if FileAccess.file_exists(old_path):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(old_path))
		if parsed is Dictionary:settings=parsed.duplicate(true)
	for key in ["resume_eye","resume_hall","resume_yaw","resume_pitch","travel"]:settings.erase(key)
	settings["first_chapter"]="shaders";settings["first_map"]="Shader_01_Shaping"
	settings["dollhouse"]=0;settings["grid_pack"]=1
	var file:=FileAccess.open(control_path,FileAccess.WRITE)
	if file==null:
		push_error("Cannot prepare Shaping lesson control file");return
	file.store_string(JSON.stringify(settings));file.close()
	museum.set("EM_CONTROL",control_path)
	museum.set("start_chapter","shaders");museum.set("start_map","Shader_01_Shaping")

static func mount(hall:Node3D,lesson:Script)->Node3D:
	var study=lesson.new()
	study.name="LearnerShaping"
	# This museum hall's map begins beyond its four-metre vestibule.
	study.position=Vector3(14,0,9)
	study.rotation.y=PI
	hall.add_child(study)
	return study
