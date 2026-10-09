extends RefCounted
## The editable lesson. Plate fabrication, camera and input are supplied.
var specimen
var starting_pose: Array = []
var return_on_release := false
var returning := false
var degrees_per_second := 45.0

func setup(body) -> void:
	specimen = body
	starting_pose = specimen.hinge_angles()

func turn(joint: int, degrees: float) -> void:
	returning = false
	specimen.set_hinge(joint, degrees)

func release() -> void:
	returning = return_on_release

func advance(delta: float) -> void:
	if not returning:
		return
	var current: Array = specimen.hinge_angles()
	var complete := true
	for joint in current.size():
		var next := move_toward(float(current[joint]), float(starting_pose[joint]), degrees_per_second * delta)
		specimen.set_hinge(joint, next)
		complete = complete and is_equal_approx(next, float(starting_pose[joint]))
	returning = not complete

func reset() -> void:
	returning = false
	for joint in starting_pose.size():
		specimen.set_hinge(joint, float(starting_pose[joint]))
