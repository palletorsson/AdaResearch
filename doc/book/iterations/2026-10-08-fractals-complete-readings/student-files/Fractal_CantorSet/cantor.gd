extends Node3D

const PointBody = preload("point_body.gd")
const HOME := Vector3(0, 1.27, 0.45)
const VIEW_SCALE := 0.2
@export var show_history := false
var original: Array[Vector2] = [Vector2(0, 6)]
var current: Array[Vector2] = []
var history: Array = []
var rows: Node3D
var point: XRToolsPickable
var readout: Label3D
var was_held := false

func _ready() -> void:
    current = original.duplicate()
    history.append(current.duplicate())
    rows = Node3D.new()
    add_child(rows)
    point = PointBody.new()
    point.tint = Color("e99db8")
    add_child(point)
    for x in [-0.4, 0.4]:
        bar(self, Vector3(x, 1.15, 0.45), 0.4, Color("28252c"))
    bar(point, Vector3(0, -0.12, 0), 0.4, Color("e99db8"))
    readout = Label3D.new()
    readout.position = Vector3(0, 1.98, 0)
    readout.font_size = 24
    readout.pixel_size = 0.001
    add_child(readout)
    park()
    redraw()

func replace_intervals(intervals: Array[Vector2], fraction: float = 1.0 / 3.0) -> Array[Vector2]:
    assert(fraction > 0.0 and fraction < 0.5)
    var next: Array[Vector2] = []
    for interval in intervals:
        var start := interval.x
        var length := interval.y
        var kept := length * fraction
        next.append(Vector2(start, kept))
        next.append(Vector2(start + length - kept, kept))
    return next

func advance() -> void:
    if point.held() or history.size() >= 6:
        return
    current = replace_intervals(current)
    history.append(current.duplicate())
    redraw()

func kept_length(intervals: Array[Vector2]) -> float:
    var total := 0.0
    for interval in intervals:
        total += interval.y
    return total

func _physics_process(_delta: float) -> void:
    var holding: bool = point.held()
    if was_held and not holding:
        var release := to_local(point.global_position)
        if release.z - HOME.z >= 0.30:
            advance()
    if not holding:
        park()
    was_held = holding

func park() -> void:
    point.global_transform = global_transform * Transform3D(Basis.IDENTITY, HOME)

func redraw() -> void:
    for child in rows.get_children():
        rows.remove_child(child)
        child.queue_free()
    var first := 0 if show_history else history.size() - 1
    for generation in range(first, history.size()):
        for interval: Vector2 in history[generation]:
            var centre := (interval.x + interval.y / 2.0 - 3.0) * VIEW_SCALE
            var at := Vector3(centre, 1.8 - generation * 0.16, 0)
            bar(rows, at, interval.y * VIEW_SCALE, Color("28252c"))
    readout.text = "cut %d / 5 | %d pieces | %.3f m kept\nPull the middle towards you 30 cm, then release" % [history.size() - 1, current.size(), kept_length(current)]

func bar(host: Node3D, at: Vector3, width: float, colour: Color) -> void:
    var surface := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = Vector3(width, 0.05, 0.06)
    surface.mesh = shape
    var finish := StandardMaterial3D.new()
    finish.albedo_color = colour
    surface.material_override = finish
    surface.position = at
    host.add_child(surface)
