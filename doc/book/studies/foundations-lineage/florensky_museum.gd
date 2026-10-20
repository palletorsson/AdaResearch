extends Node3D
## Supplied launcher. The study uses the existing museum player, room and lighting.
const LESSON = preload("florensky_study.gd")

func _ready() -> void:
    var museum = load("res://commons/scenes/endless_museum.tscn").instantiate()
    var settings: Dictionary = {}
    var old_path: String = museum.get("EM_CONTROL")
    if FileAccess.file_exists(old_path):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(old_path))
        if parsed is Dictionary: settings = parsed.duplicate(true)
    for key in ["resume_eye", "resume_hall", "resume_yaw", "resume_pitch", "travel"]:
        settings.erase(key)
    settings["first_chapter"] = "foundationscrisis"
    settings["first_map"] = "Florensky_Paraconsistent"
    settings["dollhouse"] = 0
    settings["grid_pack"] = 1
    var path := "user://ada_student_florensky_control.json"
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Cannot prepare Florensky lesson control")
        return
    file.store_string(JSON.stringify(settings))
    file.close()
    museum.set("EM_CONTROL", path)
    museum.set("start_chapter", "foundationscrisis")
    museum.set("start_map", "Florensky_Paraconsistent")
    add_child(museum)
    while is_instance_valid(museum) and not bool(museum.get("_museum_core_ready")):
        await get_tree().process_frame
    if not is_instance_valid(museum): return
    for hall in museum.get_children():
        if hall is Node3D and str(hall.get_meta("em_map", "")) == "Florensky_Paraconsistent":
            mount(hall, LESSON)
            return
    push_error("Florensky lesson: museum hall not found")

static func mount(hall: Node3D, lesson: Script) -> Node3D:
    var study = lesson.new()
    study.name = "StudentFlorenskyStudy"
    # Hall-local metres include the museum vestibule; retain the original exhibits.
    study.position = Vector3(9, 0, 10)
    study.rotation.y = 3.141592653589793
    hall.add_child(study)
    return study
