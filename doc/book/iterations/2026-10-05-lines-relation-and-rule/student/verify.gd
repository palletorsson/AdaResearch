extends SceneTree

var checks: Array[Dictionary] = []
var failures: Array[String] = []
var world: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String, description: String) -> void:
	checks.append({"id": id, "passed": ok, "description": description})
	if not ok: failures.append(id)

func frames(count: int = 6) -> void:
	for index in count:
		await physics_frame
		await process_frame

func check_line(lesson: Node3D, id: String) -> void:
	var line: MeshInstance3D = lesson.get("line")
	var a: Node3D = lesson.get("point_a")
	var b: Node3D = lesson.get("point_b")
	var expected := a.global_position.distance_to(b.global_position)
	check(is_equal_approx(lesson.get("distance"), expected), id + "/distance", "Distance matches endpoints in the translated, rotated unit-scale station.")
	if expected < 0.0001:
		check(not line.visible, id + "/hidden", "Coincident endpoints hide the directionless segment.")
		return
	check(line.visible, id + "/visible", "Distinct endpoints have a visible segment.")
	var half: float = line.mesh.height * 0.5
	var start := line.to_global(Vector3(0, -half, 0))
	var end := line.to_global(Vector3(0, half, 0))
	check(start.distance_to(a.global_position) < 0.001 and end.distance_to(b.global_position) < 0.001, id + "/segment_endpoints", "Rendered cylinder endpoints coincide with the two physical points.")
	check(is_equal_approx(line.mesh.height, expected), id + "/mesh_length", "The rendered length follows the measured length.")
	check(is_equal_approx(absf(line.basis.determinant()), 1.0), id + "/basis", "Borrowed renderer keeps a finite orthonormal orientation.")

func make_lesson(script_path: String) -> Node3D:
	var lesson: Node3D = load(script_path).new()
	lesson.position = Vector3(2.0, 0.4, -1.0)
	lesson.rotation.y = 0.35
	world.add_child(lesson)
	return lesson

func make_controller(at: Vector3) -> XRController3D:
	var controller := XRController3D.new()
	controller.position = at
	world.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
	pickup.name = "Pickup"
	pickup.hand_offset_mode = 4
	pickup.ranged_enable = false
	controller.add_child(pickup)
	return controller

func grab_and_move(lesson: Node3D, variable: String, shift: Vector3, id: String) -> void:
	var point: RigidBody3D = lesson.get(variable)
	var visible_point: MeshInstance3D = point.get_node("VisiblePoint")
	var original_id := visible_point.get_instance_id()
	var controller := make_controller(point.global_position)
	var pickup: Node3D = controller.get_node("Pickup")
	await frames()
	pickup._update_closest_object()
	check(pickup.closest_object == point, id + "/near_pickup", "Real XR Tools overlap selects this endpoint.")
	pickup._pick_up_object(pickup.closest_object)
	check(pickup.picked_up_object == point, id + "/held", "Real XR Tools holds the endpoint.")
	var before := point.global_position
	controller.global_position += shift
	await frames()
	check(point.global_position.distance_to(before + shift) < 0.001, id + "/moved", "Grab driver moves the endpoint with the synthetic controller.")
	check(visible_point.get_instance_id() == original_id and visible_point.global_position.distance_to(point.global_position) < 0.001, id + "/same_surface", "The same visible point travels with its boundary.")
	check_line(lesson, id)
	pickup.drop_object()
	await frames()
	var released := point.global_position
	controller.global_position += Vector3(1, 0, 0)
	await frames()
	check(not point.is_picked_up() and point.freeze and point.global_position.distance_to(released) < 0.001, id + "/released", "Releasing leaves the endpoint and line end where they were placed.")
	controller.queue_free()
	await frames(2)

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var args := OS.get_cmdline_user_args()
	var mode := args[1]
	var lesson := make_lesson("res://assembled.gd" if mode == "positive" else "res://frozen_segment.gd")
	await frames()
	var a: Node3D = lesson.get("point_a")
	var b: Node3D = lesson.get("point_b")
	check(a != b and a.name == "PointCollision", "carry/first_point", "First endpoint is the inherited point, not a replacement.")
	check(is_equal_approx(a.get_node("VisiblePoint").mesh.radius, 0.14) and is_equal_approx(b.get_node("VisiblePoint").mesh.radius, 0.14), "carry/radius", "Both points retain the predecessor's radius.")
	check(a.position.is_equal_approx(Vector3(0, 1.12, 0)), "carry/place", "First endpoint retains its inherited station-local position.")
	check(a.get_node("VisiblePoint").mesh == b.get_node("VisiblePoint").mesh, "carry/shared_shape", "The second instance reuses the unchanged sphere resource.")
	check(lesson.find_children("*", "CollisionShape3D", true, false).size() == 2, "carry/two_colliders", "Exactly the two held endpoints have collision boundaries; the segment is a visual relation.")
	check_line(lesson, "initial")
	await grab_and_move(lesson, "point_a", Vector3(-0.4, 0.3, -0.2), "held_a")
	await grab_and_move(lesson, "point_b", Vector3(0.7, 0.4, 0.6), "held_b")
	# Coordinate edge cases are independent of hardware; same live segment updates.
	b.global_position = a.global_position + Vector3(0, 1.7, 0)
	await frames()
	check_line(lesson, "vertical")
	b.global_position = a.global_position
	await frames()
	check_line(lesson, "coincident")
	b.global_position = a.global_position + Vector3(0, 0, 1.2)
	await frames()
	check_line(lesson, "separated_again")
	lesson.queue_free()
	await frames(2)
	if mode == "positive":
		for arrangement in ["parallel", "plus", "x", "x_depth"]:
			var exercise := make_lesson("res://two_lines_" + arrangement + ".gd")
			await frames()
			check_line(exercise, "exercise/" + arrangement)
			var other: MeshInstance3D = exercise.get_node("OtherSegment")
			var first: MeshInstance3D = exercise.get("line")
			var first_direction := first.basis.y.normalized()
			var second_direction := other.basis.y.normalized()
			var dot := absf(first_direction.dot(second_direction))
			check(is_equal_approx(dot, 1.0 if arrangement == "parallel" else 0.0), "exercise/" + arrangement + "/relation", "Coordinate choices produce the intended parallel or perpendicular directions.")
			check(is_equal_approx(absf(first.position.z - other.position.z), 0.2 if arrangement == "x_depth" else 0.0), "exercise/" + arrangement + "/depth", "The depth variation keeps directions but separates the apparent crossing.")
			exercise.queue_free()
			await frames(2)
	var report := {"passed": failures.is_empty(), "mode": mode, "checks": checks, "failure_ids": failures, "scope": "Native headless Godot; repository XR Tools; synthetic controller, real near-pickup/driver/release. Unit-scale translated/rotated station. No headset, student comprehension or museum playthrough is certified."}
	var output := FileAccess.open(args[0], FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("LINES ", mode, ": ", checks.size(), " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
