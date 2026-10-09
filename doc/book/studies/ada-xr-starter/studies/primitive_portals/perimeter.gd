extends Node3D

const CircleSamples = preload("res://prepared/circle_samples.gd")
const PolygonDisplay = preload("res://prepared/polygon_measure_display.gd")

var divisions := 6
var radius := 1.0
var tolerance := 0.01
var points: Array[Vector3] = []
var perimeter := 0.0
var gap := 0.0
var display := PolygonDisplay.new()

func _ready():
    points = CircleSamples.points_on_circle(divisions, radius)
    perimeter = polygon_perimeter(points)
    var circle_length := TAU * radius
    gap = circle_length - perimeter
    add_child(display)
    display.show_polygon(points, radius, perimeter, gap, tolerance)

func polygon_perimeter(positions: Array[Vector3]) -> float:
    var total := 0.0
    for i in range(positions.size() - 1):
        total += positions[i].distance_to(positions[i + 1])
    total += positions[positions.size() - 1].distance_to(positions[0])
    return total
