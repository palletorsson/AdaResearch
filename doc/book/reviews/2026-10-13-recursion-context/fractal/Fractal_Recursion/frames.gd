extends Node3D

const LineSkin = preload("line_skin.gd")
const MAX_DEPTH := 7
const MIN_SIZE := 0.08
@export_range(0, 7) var depth := 3
@export_range(0.25, 0.85) var ratio := 0.65
var sizes: Array[float] = []
var frames: Node3D

func _ready() -> void:
    frames = Node3D.new()
    add_child(frames)
    rebuild()

func rebuild() -> void:
    for child in frames.get_children():
        frames.remove_child(child)
        child.queue_free()
    sizes.clear()
    repeat_frame(Vector3(0, 1.3, 0), 1.8, clampi(depth, 0, MAX_DEPTH))

func repeat_frame(centre: Vector3, size: float, remaining: int) -> void:
    if remaining <= 0 or size < MIN_SIZE:
        return
    sizes.append(size)
    draw_frame(centre, size)
    repeat_frame(centre, size * clampf(ratio, 0.25, 0.85), remaining - 1)

func draw_frame(centre: Vector3, size: float) -> void:
    var half := size * 0.5
    var corners: Array[Vector3] = [
        centre + Vector3(-half, -half, 0),
        centre + Vector3(half, -half, 0),
        centre + Vector3(half, half, 0),
        centre + Vector3(-half, half, 0)
    ]
    for i in range(4):
        var start := corners[i]
        var displacement := corners[(i + 1) % 4] - start
        var line := LineSkin.new()
        frames.add_child(line)
        line.show_segment(start, displacement, displacement.length())
