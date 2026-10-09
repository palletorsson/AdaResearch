extends Node3D
## Supplied transport. Release saves a value snapshot; each read returns a new list.
## Local file survives stopping Trace and running Grid separately. Never loads objects.

static var path := "user://ada_point_trace_v1.json"
const FRAME := "Study local metres; scale one"
var status := Label3D.new()
var tracked_points: Array[Vector3] = []

func _ready():
    status.position = Vector3(0, 2.13, -0.6)
    status.font_size = 24
    status.text = "Release to keep this trace for Grid"
    add_child(status)

func watch(handle: Node3D, points: Array[Vector3]):
    tracked_points = points
    handle.dropped.connect(_released)

func _released(_handle):
    if tracked_points.size() < 2:
        status.text = "Move the point, then release to save"
        return
    var result := save_trace(tracked_points)
    status.text = "Saved for Point Grid" if result == OK else "Could not save trace: " + error_string(result)

static func save_trace(points: Array[Vector3]) -> Error:
    if points.size() < 2 or points.size() > 4096:
        return ERR_INVALID_DATA
    var rows: Array = []
    for p in points:
        if not p.is_finite():
            return ERR_INVALID_DATA
        rows.append([p.x, p.y, p.z])
    var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify({"version": 1, "frame": FRAME, "points": rows}, "", true, true))
    var result := file.get_error()
    file.close()
    if result != OK:
        return result
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))

static func read_trace() -> Array[Vector3]:
    var points: Array[Vector3] = []
    if not FileAccess.file_exists(path):
        return points
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() > 1048576:
        return points
    var json := JSON.new()
    if json.parse(file.get_as_text()) != OK:
        return points
    var data = json.data
    if not data is Dictionary or data.get("version") != 1 or data.get("frame") != FRAME:
        return points
    var rows = data.get("points")
    if not rows is Array or rows.size() < 2 or rows.size() > 4096:
        return points
    for row in rows:
        if not row is Array or row.size() != 3:
            return []
        for value in row:
            if not (value is int or value is float) or not is_finite(float(value)):
                return []
        var p := Vector3(row[0], row[1], row[2])
        if not p.is_finite():
            return []
        points.append(p)
    return points
