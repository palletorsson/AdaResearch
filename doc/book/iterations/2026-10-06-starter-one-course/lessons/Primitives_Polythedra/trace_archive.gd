# Supplied transport between museum halls. The lesson owns the drawing.
extends RefCounted

const PATH := "user://ada_student_trace.scn"

static func keep_on_release(point: Node3D, trail: Node3D, positions: Array[Vector3]) -> void:
    # Supplied lifecycle boundary: removing a scene is not a request to save.
    point.dropped.connect(func(_body):
        if point.get_meta("ada_release_cleanup", false):
            return
        if not is_instance_valid(trail) or not trail.is_inside_tree():
            return
        await trail.get_tree().process_frame
        if not is_instance_valid(point) or not is_instance_valid(trail):
            return
        if not point.is_inside_tree() or not trail.is_inside_tree():
            return
        if point.is_queued_for_deletion() or trail.is_queued_for_deletion():
            return
        if positions.size() >= 2:
            var error := save_drawing(trail, positions)
            if error != OK:
                push_error("Could not keep the trace: " + error_string(error))
    )

static func save_drawing(trail: Node3D, positions: Array[Vector3]) -> Error:
    if positions.size() < 2:
        return ERR_INVALID_DATA
    var saved := Node3D.new()
    saved.name = "SavedTrace"
    saved.set_meta("positions", PackedVector3Array(positions))
    saved.set_meta("frame", "PointStudy local metres")
    saved.set_meta("version", 1)
    for child in trail.get_children():
        if child.is_queued_for_deletion():
            continue
        var segment := MeshInstance3D.new()
        segment.transform = child.transform
        segment.visible = child.visible
        segment.mesh = child.mesh.duplicate()
        segment.mesh.resource_local_to_scene = true
        segment.material_override = child.material_override.duplicate()
        segment.material_override.resource_local_to_scene = true
        saved.add_child(segment)
        segment.owner = saved
    var scene := PackedScene.new()
    var error := scene.pack(saved)
    if error == OK:
        error = ResourceSaver.save(scene, PATH)
    saved.free()
    return error

static func load_drawing() -> Node3D:
    if not FileAccess.file_exists(PATH):
        return null
    var scene := ResourceLoader.load(PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if scene == null:
        return null
    var drawing := scene.instantiate() as Node3D
    if drawing == null:
        return null
    if drawing.get_meta("version", 0) != 1 or drawing.get_meta("frame", "") != "PointStudy local metres":
        drawing.free()
        return null
    var record = drawing.get_meta("positions", null)
    if not record is PackedVector3Array or record.size() < 2 or drawing.get_child_count() != record.size() - 1:
        drawing.free()
        return null
    return drawing
