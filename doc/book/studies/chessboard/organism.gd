extends Node3D

# 0 at the end   1 at one third   2 at the centre   3 outside
@export_enum("at the end", "at one third", "at the centre", "outside") var pivot := 0

var fractions := [0.0, 1.0 / 3.0, 0.5, -0.5]
var length := 0.3   # metres: one bar
var speed := 0.6   # radians per second
var angle := 0.0

func _ready() -> void:
	var slide: float = fractions[pivot] * length
	$Hip/Upper.position.z = slide
	$Hip/Upper/Bar.position.z = length / 2.0 - slide
	$Hip/Upper/Lower/Bar.position.z = length / 2.0 - slide
	$Hip/Upper/Lower/Foot/Bar.position.z = length / 2.0 - slide
	$Hip/Upper/Lower/Foot/Toe.position.z = length - slide

func _process(delta: float) -> void:
	angle += speed * delta
	$Hip/Upper.rotation.y = angle
	$Hip/Upper/Lower.rotation.y = angle
	$Hip/Upper/Lower/Foot.rotation.y = angle
	$Lattice.carve($Hip/Upper/Lower/Foot/Toe.global_position)
