extends Node3D
const Circle = preload("circle_samples.gd")
const LineSkin = preload("line_skin.gd")
const RADIUS := 0.7
const TOLERANCE := 0.01
const BUDGET := 96
var sides := 3
var points: Array[Vector3] = []
var error := 0.0
var met := false
var message := Label3D.new()

func _ready() -> void:
    choose_resolution(TOLERANCE, BUDGET)
    for i in range(points.size()):
        var a := points[i] + Vector3(0, 1.1, 0)
        var b := points[(i + 1) % points.size()] + Vector3(0, 1.1, 0)
        var line := LineSkin.new()
        add_child(line)
        line.show_segment(a, b - a, a.distance_to(b))
    add_child(message)
    message.position = Vector3(0, 1.8, 0)
    message.pixel_size = 0.002
    message.text = "%d sides; error %.5f m; met: %s" % [sides, error, str(met)]

func perimeter(record: Array[Vector3]) -> float:
    var total := 0.0
    for i in range(record.size()):
        total += record[i].distance_to(record[(i + 1) % record.size()])
    return total

func choose_resolution(tolerance: float, budget: int) -> void:
    assert(tolerance > 0.0 and budget >= 3)
    sides = 3
    while true:
        points = Circle.make(sides, RADIUS)
        error = absf(TAU * RADIUS - perimeter(points))
        met = error <= tolerance
        if met or sides == budget:
            break
        sides = mini(sides * 2, budget)
