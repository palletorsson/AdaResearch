# Exact printed Trace continuation; real Godot physics and unmodified XR Tools.
# Synthetic controller input drives the same pickup and grab-driver code.
extends SceneTree

var checks: Array[Dictionary] = []
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var world: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String, description: String) -> void:
	checks.append({"id": id, "passed": ok, "description": description})
	if not ok:
		failures.append(id)

func frames(count: int = 6) -> void:
	for index in count:
		await physics_frame
		await process_frame

func make_lesson(path: String) -> Node3D:
	var lesson: Node3D = load(path).new()
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

func children_of_type(node: Node, kind: String) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		if child.is_class(kind):
			result.append(child)
	return result

func point_parts(point: Node3D) -> Dictionary:
	return {"surface": children_of_type(point, "MeshInstance3D")[0], "boundary": children_of_type(point, "CollisionShape3D")[0]}

func snapshot(point: Node3D) -> Dictionary:
	var parts := point_parts(point)
	var surface: MeshInstance3D = parts["surface"]
	var boundary: CollisionShape3D = parts["boundary"]
	return {
		"position": point.position, "transform": point.global_transform,
		"radius": surface.mesh.radius, "height": surface.mesh.height,
		"radial_segments": surface.mesh.radial_segments, "rings": surface.mesh.rings,
		"shape_radius": boundary.shape.radius,
		"default_material": surface.material_override == null and surface.mesh.material == null,
		"freeze": point.freeze, "freeze_mode": point.freeze_mode,
		"release_mode": point.release_mode, "can_ranged_grab": point.can_ranged_grab,
		"layer": point.collision_layer, "mask": point.collision_mask,
	}

func check_trace(lesson: Node3D, expected: Array[Vector3], id: String, omit_last: bool = false) -> void:
	var positions: Array[Vector3] = lesson.positions
	var trail: Node3D = lesson.trail
	var pair_count := maxi(expected.size() - (2 if omit_last else 1), 0)
	check(positions.size() == expected.size(), id + "/retained_count", "The array contains exactly the accepted positions, including its initial seed.")
	var values_match := positions.size() == expected.size()
	for i in mini(positions.size(), expected.size()):
		values_match = values_match and positions[i].is_equal_approx(expected[i])
	check(values_match, id + "/retained_values", "Retained vector values keep the expected local positions in drawing order.")
	var segments := children_of_type(trail, "MeshInstance3D")
	check(segments.size() == pair_count and trail.get_child_count() == pair_count, id + "/segment_count", "The neighbour loop creates exactly the intended number of visual segments.")
	var endpoints_match := segments.size() == pair_count
	for i in mini(segments.size(), pair_count):
		var segment: MeshInstance3D = segments[i]
		var start: Vector3 = lesson.global_transform * expected[i]
		var end: Vector3 = lesson.global_transform * expected[i + 1]
		var distance := start.distance_to(end)
		var half: float = segment.mesh.height * 0.5
		endpoints_match = endpoints_match and segment.visible and is_equal_approx(segment.mesh.height, distance)
		endpoints_match = endpoints_match and segment.to_global(Vector3(0, -half, 0)).distance_to(start) < 0.001
		endpoints_match = endpoints_match and segment.to_global(Vector3(0, half, 0)).distance_to(end) < 0.001
		endpoints_match = endpoints_match and segment.basis.is_equal_approx(segment.basis.orthonormalized())
	check(endpoints_match, id + "/neighbour_endpoints", "Every visible cylinder connects one consecutive retained pair in the station's frame with the correct length.")
	var point: Node3D = lesson.point
	var label: Label3D = lesson.readout
	var wanted_world := point.global_transform.origin
	var wanted_local := lesson.global_transform.affine_inverse() * wanted_world
	var wanted_text := "LOCAL " + str(wanted_local) + "\nWORLD " + str(wanted_world) + "\nPOINTS " + str(expected.size())
	check(label.text == wanted_text, id + "/readout", "The inherited live LOCAL/WORLD text remains correct and POINTS reports the retained count.")
	observations.append({"case": id, "expected_count": expected.size(), "actual_count": positions.size(), "expected_segments": pair_count, "actual_segments": segments.size(), "readout": label.text})

func verify_main(path: String, incoming: Dictionary) -> void:
	var lesson := make_lesson(path)
	await frames()
	var point: RigidBody3D = lesson.point
	var parts := point_parts(point)
	var surface: MeshInstance3D = parts["surface"]
	var boundary: CollisionShape3D = parts["boundary"]
	check(snapshot(point) == incoming["point"], "carry/original_point", "Trace keeps the exact original Lines point geometry, pose, material defaults and pickup settings.")
	check(children_of_type(lesson, "RigidBody3D").size() == 1 and lesson.find_children("*", "CollisionShape3D", true, false).size() == 1, "carry/one_body", "Trace deliberately removes the duplicate endpoint and keeps only the original sphere body.")
	check(lesson.trail.get_parent() == lesson and children_of_type(lesson, "MeshInstance3D").is_empty(), "carry/history_container", "A station-local trail container replaces the former live two-point segment.")
	check(lesson.positions.get_typed_builtin() == TYPE_VECTOR3, "carry/typed_array", "The program retains positions in the printed typed Vector3 array.")
	var label: Label3D = lesson.readout
	check(label.get_parent() == lesson and label.position == incoming["label_position"] and label.font_size == incoming["font_size"] and label.pixel_size == incoming["pixel_size"], "carry/readout", "The original station readout keeps its parent, placement and size.")
	var retained: Array[Vector3] = [Vector3(0, 1.12, 0)]
	check_trace(lesson, retained, "seed")
	var surface_id := surface.get_instance_id()
	var boundary_id := boundary.get_instance_id()
	var mesh_resource := surface.mesh
	var shape_resource := boundary.shape
	var seed: Vector3 = lesson.positions[0]
	var controller := make_controller(point.global_position)
	var pickup: Node3D = controller.get_node("Pickup")
	await frames()
	pickup._update_closest_object()
	check(pickup._object_in_grab_area.has(point) and pickup.closest_object == point, "held/near_overlap", "Actual XR Tools overlap selects the retained original point.")
	pickup._pick_up_object(pickup.closest_object)
	check(pickup.picked_up_object == point and point.is_picked_up(), "held/pickup", "The real XR Tools pickup library holds the point.")
	for step in [0.02, 0.04, 0.06]:
		var desired := Vector3(step, 1.12, 0)
		controller.global_position = lesson.global_transform * desired
		await frames()
		check(point.position.is_equal_approx(desired), "sample/step_" + str(step) + "/driver", "The real grab driver reaches the intended local sample position.")
		if step > 0.05:
			retained.append(desired)
		check_trace(lesson, retained, "sample/step_" + str(step))
	var count_before_pause: int = lesson.positions.size()
	await frames(24)
	check(lesson.positions.size() == count_before_pause, "pause/no_growth", "Remaining at one position adds no entries merely because frames pass.")
	check_trace(lesson, retained, "pause")
	for destination in [Vector3(0.06, 1.20, 0), Vector3(0.06, 1.20, 0.08), Vector3(0, 1.12, 0)]:
		controller.global_position = lesson.global_transform * destination
		await frames()
		retained.append(destination)
		var id := "route/point_" + str(retained.size())
		check_trace(lesson, retained, id)
	check(lesson.positions[0].is_equal_approx(seed), "history/value_copy", "Moving the live point never changes the already retained Vector3 seed.")
	check(lesson.positions.size() >= 2 and lesson.positions[0].is_equal_approx(lesson.positions[-1]), "history/return_kept", "Returning to the start retains another ordered entry instead of erasing the detour.")
	check(surface.get_instance_id() == surface_id and boundary.get_instance_id() == boundary_id and surface.mesh == mesh_resource and boundary.shape == shape_resource and surface.global_transform.is_equal_approx(point.global_transform) and boundary.global_transform.is_equal_approx(point.global_transform), "held/original_resources", "Drawing moves the original sphere surface/collider and retains both resources.")
	pickup.drop_object()
	await frames()
	var released := point.global_transform
	var released_count: int = lesson.positions.size()
	controller.global_position += Vector3(1, 0.3, 0)
	await frames(12)
	check(not point.is_picked_up() and pickup.picked_up_object == null and point.freeze and point.collision_layer == 4 and point.collision_mask == 196615 and point.global_transform.is_equal_approx(released), "release/stays", "Release restores collision settings and keeps the point fixed as the empty controller moves away.")
	check(lesson.positions.size() == released_count, "release/history_stays", "Moving an empty controller does not grow the released point's retained history.")
	check_trace(lesson, retained, "released")
	controller.global_position = point.global_position
	await frames()
	pickup._update_closest_object()
	pickup._pick_up_object(pickup.closest_object)
	check(pickup.picked_up_object == point and lesson.positions.size() == retained.size(), "resume/keeps_history", "Picking up the original point again preserves the existing record.")
	var continuation := Vector3(0.08, 1.12, 0.08)
	controller.global_position = lesson.global_transform * continuation
	await frames()
	retained.append(continuation)
	check_trace(lesson, retained, "resumed")
	pickup.drop_object()
	await frames()
	controller.global_position += Vector3(1, 0.3, 0)
	await frames()
	check(point.freeze and not point.is_picked_up() and point.position.is_equal_approx(continuation), "resume/released", "Releasing after continuation keeps the point at the new retained position.")
	var local_before := point.position
	var world_before := point.global_position
	lesson.position += Vector3(1, 0.25, 2)
	lesson.rotation.y += 0.45
	await frames()
	check(point.position.is_equal_approx(local_before) and not point.global_position.is_equal_approx(world_before), "frame/local_point_stable", "Station translation and rotation change the world address while keeping the point's local position.")
	check_trace(lesson, retained, "changed_frame")
	controller.queue_free()
	lesson.queue_free()
	await frames(2)
	var restarted := make_lesson(path)
	await frames()
	check_trace(restarted, [Vector3(0, 1.12, 0)], "new_instance")
	restarted.queue_free()
	await frames(2)

func verify_variants() -> void:
	for name in ["baseline", "threshold_020"]:
		var lesson := make_lesson("res://trace.gd" if name == "baseline" else "res://threshold_020.gd")
		await frames()
		var expected: Array[Vector3] = [Vector3(0, 1.12, 0)]
		for offset in [0.06, 0.12, 0.24]:
			lesson.point.position = Vector3(offset, 1.12, 0)
			await frames()
			if name == "baseline" or offset > 0.2:
				expected.append(Vector3(offset, 1.12, 0))
			check_trace(lesson, expected, "experiment/" + name + "/step_" + str(offset))
		lesson.queue_free()
		await frames(2)
	var omitted := make_lesson("res://omit_last_pair.gd")
	await frames()
	var retained: Array[Vector3] = [Vector3(0, 1.12, 0)]
	for destination in [Vector3(0.1, 1.12, 0), Vector3(0.1, 1.22, 0), Vector3(0.1, 1.22, 0.1)]:
		omitted.point.position = destination
		await frames()
		retained.append(destination)
		check_trace(omitted, retained, "experiment/omit_last_pair/point_" + str(retained.size()), true)
	omitted.queue_free()
	await frames(2)

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var incoming_lesson := make_lesson("res://incoming.gd")
	await frames()
	var label: Label3D = incoming_lesson.readout
	var incoming := {"point": snapshot(incoming_lesson.point), "label_position": label.position, "font_size": label.font_size, "pixel_size": label.pixel_size}
	incoming_lesson.queue_free()
	await frames(2)
	var args := OS.get_cmdline_user_args()
	var mode := args[1]
	await verify_main("res://trace.gd" if mode == "positive" else "res://" + mode + ".gd", incoming)
	if mode == "positive":
		await verify_variants()
	var report := {"passed": failures.is_empty(), "mode": mode, "checks": checks, "failure_ids": failures, "observations": observations,
		"scope": "Native headless Godot 4.6 executes the exact printed Trace continuation from the current verified Lines predecessor. Unmodified XR Tools and a synthetic controller exercise actual near-overlap, pickup, grab-driver movement and release. Tests verify local retained positions, sampling, ordered neighbour cylinders, live text and scene-instance lifetime under translated/rotated unit-scale stations. Hardware grip input, headset experience, rendered appearance, learner comprehension, museum playthrough and Grid transfer are not verified."}
	var output := FileAccess.open(args[0], FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("TRACE THE CARRIED POINT ", mode, ": ", checks.size(), " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
