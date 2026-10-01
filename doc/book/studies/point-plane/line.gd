extends Node3D

func _ready() -> void:
	$A.position = Vector3(-0.75, 1.12, 0.0)
	$B.position = Vector3(0.75, 1.12, 0.0)

func _process(_delta: float) -> void:
	var a: Vector3 = $A.position
	var b: Vector3 = $B.position
	var displacement := b - a
	var distance := displacement.length()
	$Segment.show_between(a, b)
	$Readout.text = "%.2f m" % distance
