# Exact printed Lines continuation; native physics and unmodified XR Tools.
# Synthetic controllers replace the hardware grip input boundary only.
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

func check_segment(lesson: Node3D, id: String, reverse: bool = false) -> void:
	var line: MeshInstance3D = lesson.line
	var a: Node3D = lesson.point
	var b: Node3D = lesson.point_b
	var expected := a.global_position.distance_to(b.global_position)
	check(is_equal_approx(lesson.distance, expected), id + "/distance", "Measured distance agrees with the physical endpoints in the translated, rotated unit-scale station.")
	if expected < 0.0001:
		check(not line.visible, id + "/hidden", "Coincident endpoints hide the directionless segment.")
		return
	check(line.visible, id + "/visible", "Separated endpoints have a visible segment node.")
	var half: float = line.mesh.height * 0.5
	var start := line.to_global(Vector3(0, -half, 0))
	var end := line.to_global(Vector3(0, half, 0))
	var expected_start := a.global_position
	var expected_end := 2.0 * a.global_position - b.global_position if reverse else b.global_position
	check(start.distance_to(expected_start) < 0.001 and end.distance_to(expected_end) < 0.001, id + "/segment_endpoints", "The cylinder's world-space ends match the taught displacement; reversing only subtraction points away from B.")
	check(is_equal_approx(line.mesh.height, expected), id + "/mesh_length", "The cylinder length matches the endpoint distance.")
	check(line.basis.is_equal_approx(line.basis.orthonormalized()) and is_equal_approx(absf(line.basis.determinant()), 1), id + "/finite_basis", "The supplied renderer keeps a finite orthonormal orientation, including vertical segments.")

func check_readout(lesson: Node3D, id: String) -> void:
	var a: Node3D = lesson.point
	var b: Node3D = lesson.point_b
	var label: Label3D = lesson.readout
	var expected_world := a.global_transform.origin
	var expected_local := lesson.global_transform.affine_inverse() * expected_world
	var expected_distance := a.global_position.distance_to(b.global_position)
	var expected_prefix := "LOCAL " + str(expected_local) + "\nWORLD " + str(expected_world) + "\nDISTANCE "
	var displayed_distance := label.text.trim_prefix(expected_prefix)
	check(label.text.begins_with(expected_prefix) and displayed_distance.is_valid_float() and is_equal_approx(displayed_distance.to_float(), expected_distance), id + "/readout", "The live label preserves exact independent LOCAL/WORLD text and reports the independently measured distance within floating-point tolerance.")
	observations.append({"case": id, "expected_prefix": expected_prefix, "expected_distance": expected_distance, "actual_readout": label.text})

func verify_carry(lesson: Node3D, incoming: Dictionary) -> void:
	var a: RigidBody3D = lesson.point
	var b: RigidBody3D = lesson.point_b
	var a_parts := point_parts(a)
	var b_parts := point_parts(b)
	var surface_a: MeshInstance3D = a_parts["surface"]
	var surface_b: MeshInstance3D = b_parts["surface"]
	var boundary_a: CollisionShape3D = a_parts["boundary"]
	var boundary_b: CollisionShape3D = b_parts["boundary"]
	check(snapshot(a) == incoming["point"], "carry/inherited_point", "The first point retains the exact tested Coordinates geometry, pose, material defaults and pickup configuration.")
	check(a != b and children_of_type(lesson, "RigidBody3D").size() == 2, "carry/two_points", "Two independent class instances are the only bodies.")
	check(a.get_child_count() == 2 and b.get_child_count() == 2 and lesson.find_children("*", "CollisionShape3D", true, false).size() == 2, "carry/two_boundaries", "Each endpoint owns one mesh and collider; the segment has no physical boundary.")
	check(surface_a != surface_b and boundary_a != boundary_b and surface_a.mesh != surface_b.mesh and boundary_a.shape != boundary_b.shape, "carry/independent_resources", "Each class instance owns distinct mesh and shape resources, as well as distinct nodes.")
	check(a.get_script() == load("res://point_body.gd") and b.get_script() == a.get_script(), "class/same_definition", "Both objects use the exact printed PointBody class.")
	var mesh_radius: float = surface_b.mesh.radius
	surface_a.mesh.radius = 0.09
	check(is_equal_approx(surface_b.mesh.radius, mesh_radius), "class/mesh_isolation", "Editing A's mesh resource leaves B's mesh untouched.")
	surface_a.mesh.radius = mesh_radius
	var boundary_radius: float = boundary_b.shape.radius
	boundary_a.shape.radius = 0.09
	check(is_equal_approx(boundary_b.shape.radius, boundary_radius), "class/collider_isolation", "Editing A's collision shape leaves B's collider untouched.")
	boundary_a.shape.radius = boundary_radius
	var b_snapshot := snapshot(b)
	b_snapshot["position"] = incoming["point"]["position"]
	b_snapshot["transform"] = incoming["point"]["transform"]
	check(b_snapshot == incoming["point"], "carry/duplicate_configuration", "The second point differs in placement while preserving inherited shape and pickup settings.")
	check(b.position.is_equal_approx(Vector3(1, 1.12, 0)), "carry/second_position", "The second endpoint begins one local metre along X from the inherited point.")
	check(surface_a.global_transform.is_equal_approx(boundary_a.global_transform) and surface_b.global_transform.is_equal_approx(boundary_b.global_transform), "carry/alignment", "Both inherited sphere surfaces remain aligned with their colliders.")
	var label: Label3D = lesson.readout
	check(label.get_parent() == lesson and label.position == incoming["label_position"] and label.font_size == incoming["font_size"] and label.pixel_size == incoming["pixel_size"], "carry/readout_preserved", "The Coordinates readout retains its station parent, placement and text size.")
	var line: MeshInstance3D = lesson.line
	check(line.get_parent() == lesson and line.mesh is CylinderMesh and line.get_child_count() == 0, "carry/supplied_visual", "The borrowed line renderer adds one visual relation under the station.")

func grab_and_move(lesson: Node3D, variable: String, shift: Vector3, id: String) -> void:
	var point: RigidBody3D = lesson.get(variable)
	var other: RigidBody3D = lesson.point_b if variable == "point" else lesson.point
	var parts := point_parts(point)
	var surface: MeshInstance3D = parts["surface"]
	var boundary: CollisionShape3D = parts["boundary"]
	var node_ids: Array[int] = [surface.get_instance_id(), boundary.get_instance_id()]
	var sphere_resource := surface.mesh
	var shape_resource := boundary.shape
	var line: MeshInstance3D = lesson.line
	var line_id := line.get_instance_id()
	var line_mesh := line.mesh
	var other_before := other.global_transform
	var label_before: Transform3D = lesson.readout.global_transform
	var controller := make_controller(point.global_position)
	var pickup: Node3D = controller.get_node("Pickup")
	await frames()
	pickup._update_closest_object()
	check(pickup._object_in_grab_area.has(point) and pickup.closest_object == point, id + "/near_pickup", "Actual XR Tools overlap selects this endpoint.")
	pickup._pick_up_object(pickup.closest_object)
	check(pickup.picked_up_object == point and point.is_picked_up(), id + "/held", "The real pickup library holds this endpoint.")
	var before := point.global_position
	controller.global_position += shift
	await frames()
	check(point.global_position.distance_to(before + shift) < 0.001, id + "/driver_movement", "The real grab driver moves the endpoint by the controller displacement.")
	check(surface.get_instance_id() == node_ids[0] and boundary.get_instance_id() == node_ids[1] and surface.mesh == sphere_resource and boundary.shape == shape_resource and surface.global_transform.is_equal_approx(point.global_transform) and boundary.global_transform.is_equal_approx(point.global_transform), id + "/same_geometry", "The same visible and physical resources follow the held body together.")
	check(other.global_transform.is_equal_approx(other_before), id + "/other_end_stays", "Moving one point leaves the other endpoint in place.")
	check(line.get_instance_id() == line_id and line.mesh == line_mesh, id + "/same_segment", "The continuing relation updates the existing cylinder resource without replacing it.")
	check(lesson.readout.global_transform.is_equal_approx(label_before), id + "/readout_stays", "The inherited readout stays attached to the station while an endpoint moves.")
	check_segment(lesson, id)
	check_readout(lesson, id)
	pickup.drop_object()
	await frames()
	var released := point.global_transform
	controller.global_position += Vector3(1, 0.3, 0)
	await frames(12)
	check(not point.is_picked_up() and pickup.picked_up_object == null and point.freeze and point.collision_layer == 4 and point.collision_mask == 196615 and point.global_transform.is_equal_approx(released), id + "/release_stays", "Release restores collision settings and leaves the endpoint fixed as the empty controller departs.")
	check_segment(lesson, id + "/released")
	check_readout(lesson, id + "/released")
	controller.queue_free()
	await frames(2)

func verify_main(path: String, incoming: Dictionary) -> void:
	var lesson := make_lesson(path)
	await frames()
	verify_carry(lesson, incoming)
	check_segment(lesson, "initial")
	check_readout(lesson, "initial")
	await grab_and_move(lesson, "point", Vector3(-0.4, 0.3, -0.2), "held_a")
	await grab_and_move(lesson, "point_b", Vector3(0.7, 0.4, 0.6), "held_b")
	var a: Node3D = lesson.point
	var b: Node3D = lesson.point_b
	var local_a := a.position
	var local_b := b.position
	var world_a := a.global_position
	var distance_before: float = lesson.distance
	lesson.position += Vector3(1, 0.25, 2)
	lesson.rotation.y += 0.45
	await frames()
	check(a.position.is_equal_approx(local_a) and b.position.is_equal_approx(local_b) and not a.global_position.is_equal_approx(world_a) and is_equal_approx(lesson.distance, distance_before), "frame/local_stable", "Parent translation and rotation change world addresses while preserving local positions and separation.")
	check_segment(lesson, "frame")
	check_readout(lesson, "frame")
	b.global_position = a.global_position + Vector3(0, 1.7, 0)
	await frames()
	check_segment(lesson, "vertical_live")
	check_readout(lesson, "vertical_live")
	b.global_position = a.global_position
	await frames()
	check_segment(lesson, "coincident_live")
	check_readout(lesson, "coincident_live")
	b.global_position = a.global_position + Vector3(0, 0, 1.2)
	await frames()
	check_segment(lesson, "separated_again")
	check_readout(lesson, "separated_again")
	lesson.queue_free()
	await frames(2)

func verify_experiments() -> void:
	for name in ["vertical", "coincident", "reverse_direction"]:
		var lesson := make_lesson("res://" + name + ".gd")
		await frames()
		var a: Node3D = lesson.point
		var b: Node3D = lesson.point_b
		var wanted_offset := Vector3(0, 1, 0) if name == "vertical" else Vector3.ZERO if name == "coincident" else Vector3.RIGHT
		check((b.position - a.position).is_equal_approx(wanted_offset), "experiment/" + name + "/initial_offset", "The full downloadable program applies exactly the stated starting-position experiment.")
		check_segment(lesson, "experiment/" + name, name == "reverse_direction")
		check_readout(lesson, "experiment/" + name)
		lesson.queue_free()
		await frames(2)
	var arrangements := {
		"parallel": [Vector3(-0.6, 1.12, 0), Vector3(0.6, 1.12, 0), Vector3(-0.6, 1.62, 0), Vector3(0.6, 1.62, 0)],
		"plus": [Vector3(-0.6, 1.42, 0), Vector3(0.6, 1.42, 0), Vector3(0, 0.82, 0), Vector3(0, 2.02, 0)],
		"x": [Vector3(-0.6, 0.82, 0), Vector3(0.6, 2.02, 0), Vector3(-0.6, 2.02, 0), Vector3(0.6, 0.82, 0)],
		"x_depth": [Vector3(-0.6, 0.82, 0), Vector3(0.6, 2.02, 0), Vector3(-0.6, 2.02, 0.2), Vector3(0.6, 0.82, 0.2)],
	}
	for name in arrangements:
		var id: String = "experiment/two_lines_" + name
		var exercise := make_lesson("res://two_lines_" + name + ".gd")
		await frames()
		var values: Array = arrangements[name]
		var a: Node3D = exercise.point
		var b: Node3D = exercise.point_b
		var first: MeshInstance3D = exercise.line
		var meshes := children_of_type(exercise, "MeshInstance3D")
		check(meshes.size() == 2 and children_of_type(exercise, "RigidBody3D").size() == 2 and exercise.find_children("*", "CollisionShape3D", true, false).size() == 2, id + "/two_relations_two_bodies", "The full two-line program adds a second visual relation and no bodies for the C/D position values.")
		var other: MeshInstance3D = meshes[0] if meshes[0] != first else meshes[1]
		check(a.position.is_equal_approx(values[0]) and b.position.is_equal_approx(values[1]), id + "/table_positions", "The held endpoints match the printed coordinate-table assignments.")
		check_segment(exercise, id)
		check_readout(exercise, id)
		var half: float = other.mesh.height * 0.5
		var world_c: Vector3 = exercise.global_transform * values[2]
		var world_d: Vector3 = exercise.global_transform * values[3]
		check(other.to_global(Vector3(0, -half, 0)).distance_to(world_c) < 0.001 and other.to_global(Vector3(0, half, 0)).distance_to(world_d) < 0.001, id + "/second_segment_endpoints", "The supplied renderer places the second cylinder at the printed C/D coordinates in the same station frame.")
		var dot := absf(first.basis.y.normalized().dot(other.basis.y.normalized()))
		check(is_equal_approx(dot, 1.0 if name == "parallel" else 0.0), id + "/direction_relation", "The table produces parallel directions or perpendicular plus/X directions.")
		check(is_equal_approx(absf(first.position.z - other.position.z), 0.2 if name == "x_depth" else 0.0), id + "/depth", "The depth experiment separates the two segment midpoints by 0.2 while other arrangements share a plane.")
		var other_before := other.global_transform
		var other_mesh := other.mesh
		a.position += Vector3(0.25, 0.35, 0.15)
		await frames()
		check_segment(exercise, id + "/moved_first")
		check_readout(exercise, id + "/moved_first")
		check(other.global_transform.is_equal_approx(other_before) and other.mesh == other_mesh, id + "/second_stays", "Moving a held endpoint updates the first relation while the second segment drawn in _ready remains fixed.")
		exercise.queue_free()
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
	await verify_main("res://line.gd" if mode == "positive" else "res://" + mode + ".gd", incoming)
	if mode == "positive":
		await verify_experiments()
	var report := {"passed": failures.is_empty(), "mode": mode, "checks": checks, "failure_ids": failures, "observations": observations,
		"scope": "Native headless Godot 4.6 executes the exact printed Lines continuation from the exact current Coordinates predecessor. Unmodified repository XR Tools and synthetic XRController3D nodes exercise real near-overlap, pickup, grab-driver movement and release. Tests cover translated/rotated unit-scale stations and the live readout/cylinder geometry. Hardware grip input, headset experience, rendered appearance, learner comprehension and museum playthrough are not verified."}
	var output := FileAccess.open(args[0], FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("LINES FROM CARRIED POINT ", mode, ": ", checks.size(), " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
