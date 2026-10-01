extends "res://bullet.gd"

const CENTRE := Vector3(0, 1.6, 0)   # what pulls, counted from this node
const PULL := 4.0                    # metres per second, every second, at one metre from it

func _ready() -> void:
	super()
	$"../Centre".material_override = Look.paint(Look.THIRD)

func pull() -> Vector3:
	var arm := CENTRE - at
	return arm.normalized() * PULL / arm.length_squared()
