extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const VIEW_SCALE := 0.3
const ORIGIN := Vector3(0, 1.2, 0.2)
var original: Array[Vector3] = [Vector3(-2, 0, 0), Vector3(2, 0, 0)]
var current: Array[Vector3] = []
var generation := 0
var point: XRToolsPickable
var drawing: Node3D
var readout: Label3D
var cursor := Vector3.ZERO
var along := 0.0

func _ready() -> void:
    current = original.duplicate()
    drawing = Node3D.new()
    add_child(drawing)
    point = PointBody.new()
    add_child(point)
    point.action_pressed.connect(func(_body): advance())
    readout = Label3D.new()
    readout.position = Vector3(0, 1.85, -0.3)
    readout.font_size = 24
    readout.pixel_size = 0.001
    add_child(readout)
    redraw()

func replace_path(path: Array[Vector3], side: float = 1.0) -> Array[Vector3]:
    assert(path.size() >= 2 and absf(side) == 1.0)
    var next: Array[Vector3] = []
    for i in path.size() - 1:
        var a := path[i]
        var end := path[i + 1]
        var third := (end - a) / 3.0
        var b := a + third
        var c := b + third.rotated(Vector3.BACK, side * PI / 3.0)
        var d := a + third * 2.0
        next.append_array([a, b, c, d])
    next.append(path[-1])
    return next

func advance() -> void:
    if generation == 4:
        return
    current = replace_path(current)
    generation += 1
    redraw()

func path_length(path: Array[Vector3]) -> float:
    var total := 0.0
    for i in path.size() - 1:
        total += path[i].distance_to(path[i + 1])
    return total

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        advance()

func _physics_process(_delta: float) -> void:
    if point.held():
        var local := (to_local(point.global_position) - ORIGIN) / VIEW_SCALE
        var reading := nearest_on_path(Vector3(local.x, -local.z, 0))
        cursor = reading.point
        along = reading.along
    else:
        point.global_transform = global_transform * Transform3D(Basis.IDENTITY, display(cursor))
    readout.text = "step %d / 4 | %d segments\nends %.3f m | path %.3f m | at %.3f m along" % [generation, current.size() - 1, current[0].distance_to(current[-1]), path_length(current), along]

# Supplied reader: closest point on the finite drawing, with distance from its start.
# This does not measure the length of the player's hand movement.
func nearest_on_path(query: Vector3) -> Dictionary:
    var best := INF
    var prefix := 0.0
    var answer := {"point":current[0], "along":0.0}
    for i in current.size() - 1:
        var a := current[i]
        var delta := current[i + 1] - a
        var t := clampf((query - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
        var p := a + delta * t
        if p.distance_squared_to(query) < best:
            best = p.distance_squared_to(query)
            answer = {"point":p, "along":prefix + t * delta.length()}
        prefix += delta.length()
    return answer

func display(p: Vector3) -> Vector3:
    return ORIGIN + Vector3(p.x, 0, -p.y) * VIEW_SCALE

func redraw() -> void:
    for child in drawing.get_children():
        drawing.remove_child(child)
        child.queue_free()
    for i in current.size() - 1:
        var start := display(current[i])
        var displacement := display(current[i + 1]) - start
        var line = LineSkin.new()
        drawing.add_child(line)
        line.mesh.top_radius = 0.002
        line.mesh.bottom_radius = 0.002
        line.show_segment(start, displacement, displacement.length())
    cursor = current[0]
    along = 0.0
