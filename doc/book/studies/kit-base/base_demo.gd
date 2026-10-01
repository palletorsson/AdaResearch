extends Node3D
## One screen that uses every supplied part once, so that you can see each of
## them work before you build on them:
##   base.tscn      this scene inherits it: the floor, the sky, the sun, the fixed camera
##   look.gd        every colour here comes from it
##   the example guest, a box, with marble.tscn dropped on it (M drops it again)
##   mover.gd       the Hand, on its autopilot
##   segment.gd     the line from A to the Hand
##   trace_strip.gd the route the Hand has taken (Space stops and starts it)
##                  Both are LINE, which is the colour of the sky: they are kept
##                  low here, so that the eye gets them against the floor
##   sweep_sheet    two balls hung on it, under their names
##   walker.tscn    walks across the floor on its autopilot, then the keys are yours
## A kit replaces this scene and this script with the chapter's own.

const Look := preload("res://supplied/look.gd")

var trace: Array[Vector3] = []   # where the Hand has been
var recording := true
var walk := "walking"            # what the walker last told us

func _ready() -> void:
	$A.material_override = Look.paint(Look.BONE)
	$Hand.material_override = Look.paint(Look.BONE)
	for radius: float in [0.2, 0.3]:
		var ball := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		ball.mesh = mesh
		$Sheet.hang(ball, "%.1f m" % radius)
	$Readout.modulate = Look.INK
	$Readout.outline_modulate = Look.SHADE
	$Marble.drop($Guest.global_position + Vector3(0.0, 1.5, 0.0))
	$Walker.walk_ended.connect(_on_walk_ended)
	# Along the front, to the back, and one last step that turns it to face the room.
	$Walker.walk_to([Vector3(3.5, 0.0, 2.1), Vector3(3.5, 0.0, -1.9), Vector3(3.0, 0.0, -1.5)])

func _on_walk_ended(how: String) -> void:
	walk = how
	print("the walker ", how, " at ", $Walker.global_position.snappedf(0.01))

func _process(_delta: float) -> void:
	var a: Vector3 = $A.position
	var hand: Vector3 = $Hand.position
	$Segment.show_between(a, hand)
	if Input.is_action_just_pressed("pause"):
		recording = not recording
	if recording and (trace.is_empty() or (hand - trace[-1]).length() >= 0.1):
		trace.append(hand)
		if trace.size() > 64:
			trace.pop_front()
	$Strip.draw(trace)
	if Input.is_action_just_pressed("drop"):
		$Marble.drop($Guest.global_position + Vector3(0.0, 1.5, 0.0))
	$Readout.text = "walker: %s    marble at %.2f m    segment %.2f m    trace: %d kept\nWASD or arrows walk    J jump    C camera    M marble    Space trace\nhold V or the right mouse button and move the mouse: look" % [
		walk, $Marble.global_position.y, (hand - a).length(), trace.size()]
