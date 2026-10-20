extends Node3D
## The open cube from Shadow Game's placement socket; edges have no collision.
const LineSkin = preload("res://commons/museum_runner/forms/line_skin.gd")
var size := Vector3.ONE * 0.48
var colour := Color("e9b5c7")

func _ready() -> void:
	for axis in range(3):
		for a in [-1, 1]:
			for b in [-1, 1]:
				var start := Vector3.ZERO
				start[axis] -= size[axis] / 2
				start[(axis+1)%3] += a * size[(axis+1)%3] / 2
				start[(axis+2)%3] += b * size[(axis+2)%3] / 2
				var displacement := Vector3.ZERO
				displacement[axis] = size[axis]
				var line := LineSkin.new()
				line.show_segment(start, displacement, size[axis])
				line.material_override.albedo_color = colour
				add_child(line)
