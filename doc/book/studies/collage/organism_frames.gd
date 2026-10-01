extends Node3D
## The limb as it stood before delta, kept for one measurement: second.gd runs it
## beside organism.gd. Here the angle grows by 0.01 every frame, whatever a frame is.

var angle := 0.0

func _process(_delta: float) -> void:
	angle += 0.01
	$Hip/Upper.rotation.y = angle
	$Hip/Upper/Lower.rotation.y = angle
	$Hip/Upper/Lower/Foot.rotation.y = angle
