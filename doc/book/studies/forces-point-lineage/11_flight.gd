extends "study.gd"
const ThrustPoint = preload("thrust_point.gd")
var points: Array = []

func _ready() -> void:
    for x in [-0.3, 0.3]:
        var point = ThrustPoint.new()
        point.position = Vector3(x, 1.2, 0)
        add_child(point)
        points.append(point)
    caption("Hold both points. Aim where you want to go. Press triggers.")

