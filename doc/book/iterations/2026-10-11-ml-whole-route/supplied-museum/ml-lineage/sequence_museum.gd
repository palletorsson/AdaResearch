extends Node3D
## Supplied museum launcher: lesson code lives in the three printed files.
const LESSON = preload("sequence_study.gd")

func _ready() -> void:
    var museum = load("res://commons/scenes/endless_museum.tscn").instantiate()
    configure(museum, "user://ada_student_sequence_control.json")
    add_child(museum)
    while is_instance_valid(museum) and not bool(museum.get("_museum_core_ready")):
        await get_tree().process_frame
    if not is_instance_valid(museum): return
    for hall in museum.get_children():
        if hall is Node3D and str(hall.get_meta("em_map", "")) == "ML_Sequence_Memory":
            mount(hall, LESSON)
            return
    push_error("Sequence Memory lesson: museum hall not found")

static func configure(museum: Node3D, control_path: String) -> void:
    var settings: Dictionary = {}
    var old_path: String = museum.get("EM_CONTROL")
    if FileAccess.file_exists(old_path):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(old_path))
        if parsed is Dictionary: settings = parsed.duplicate(true)
    for key in ["resume_eye", "resume_hall", "resume_yaw", "resume_pitch", "travel"]: settings.erase(key)
    settings["first_chapter"] = "machinelearning"
    settings["first_map"] = "ML_Sequence_Memory"
    settings["dollhouse"] = 0
    settings["grid_pack"] = 1
    var file := FileAccess.open(control_path, FileAccess.WRITE)
    if file == null:
        push_error("Cannot prepare Sequence Memory lesson control"); return
    file.store_string(JSON.stringify(settings)); file.close()
    museum.set("EM_CONTROL", control_path)
    museum.set("start_chapter", "machinelearning")
    museum.set("start_map", "ML_Sequence_Memory")

static func mount(hall: Node3D, lesson: Script) -> Node3D:
    var study = lesson.new()
    study.name = "StudentSequenceStudy"
    # Clear western teaching area between the two existing exhibits.
    # Hall-local coordinates include the museum's four-metre vestibule.
    study.position = Vector3(4, 0, 17)
    hall.add_child(study)
    return study
