extends Node3D
## Supplied launcher. The study uses the existing museum player, room and lighting.
const LESSON = preload("synthesis_study.gd")

func _ready() -> void:
    var museum = load("res://commons/scenes/endless_museum.tscn").instantiate()
    var settings: Dictionary = {}
    var old_path: String = museum.get("EM_CONTROL")
    if FileAccess.file_exists(old_path):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(old_path))
        if parsed is Dictionary: settings = parsed.duplicate(true)
    for key in ["resume_eye", "resume_hall", "resume_yaw", "resume_pitch", "travel"]:
        settings.erase(key)
    settings["first_chapter"] = "postfoundationscrisis"
    settings["first_map"] = "PostCrisis_Synthesis"
    settings["dollhouse"] = 0
    settings["grid_pack"] = 1
    var path := "user://ada_student_synthesis_control.json"
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Cannot prepare Synthesis lesson control")
        return
    file.store_string(JSON.stringify(settings))
    file.close()
    museum.set("EM_CONTROL", path)
    museum.set("start_chapter", "postfoundationscrisis")
    museum.set("start_map", "PostCrisis_Synthesis")
    add_child(museum)
    while is_instance_valid(museum) and not bool(museum.get("_museum_core_ready")):
        await get_tree().process_frame
    if not is_instance_valid(museum): return
    for hall in museum.get_children():
        if hall is Node3D and str(hall.get_meta("em_map", "")) == "PostCrisis_Synthesis":
            mount(hall, LESSON)
            return
    push_error("Synthesis lesson: museum hall not found")

static func mount(hall: Node3D, lesson: Script, config: Dictionary = {}) -> Node3D:
    var study = lesson.new()
    study.name = "StudentSynthesisStudy"
    # Hall-local metres include the museum vestibule; retain the original exhibits.
    study.position = Vector3(7.5000,0.0000,2.0000)
    study.rotation.y = 0.000000000
    for field in config: study.set(field, config[field])
    hall.add_child(study)
    return study
