extends "study.gd"
var a = Point.new()
var b = Point.new()
var segment: MeshInstance3D
var reading: Label3D

func _ready() -> void:
    add_child(a)
    add_child(b)
    for point in [a, b]:
        point.freeze = true
        point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
    a.position = Vector3(-0.5, 1.2, 0)
    b.position = Vector3(0.5, 1.5, 0)
    segment = rod()
    reading = caption("")

func relation() -> Dictionary:
    var displacement: Vector3 = b.position - a.position
    var length := displacement.length()
    var direction := Vector3.ZERO
    if length > 0.0001:
        direction = displacement / length
    var along_x := Vector3.RIGHT * displacement.dot(Vector3.RIGHT)
    return {"displacement": displacement, "length": length,
        "direction": direction, "along_x": along_x,
        "remainder": displacement - along_x}

func _process(_delta: float) -> void:
    var r := relation()
    join(segment, a.position, b.position)
    reading.text = "gap %s m\nlength %.2f m\ndirection %s" % [
        r.displacement, r.length, r.direction]

