extends Node3D

var trace: Array[Vector3] = []
var gate := 0.1
var capacity := 32
var recording := true

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

	if Input.is_action_just_pressed("pause"):
		recording = not recording
	if recording:
		keep(b)
	$Strip.draw(trace)
	$Record.text = "%d kept\nroute %.2f m\nstraight %.2f m" % [trace.size(), route_length(), straight_length()]

func keep(p: Vector3) -> void:
	if trace.is_empty() or (p - trace[-1]).length() >= gate:
		trace.append(p)
		if trace.size() > capacity:
			trace.pop_front()

func route_length() -> float:
	var total := 0.0
	for i in range(1, trace.size()):
		total += (trace[i] - trace[i - 1]).length()
	return total

func straight_length() -> float:
	if trace.is_empty():
		return 0.0
	return (trace[-1] - trace[0]).length()
