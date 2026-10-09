# Executes the exact printed student scripts, never the museum artifact scripts.
# Real Godot physics and unmodified XR Tools; synthetic controller, no headset.
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

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var args := OS.get_cmdline_user_args()
	var mode: String = args[1]
	if mode == "positive":
		var baseline: Dictionary = await verify_one("res://point_one.gd", "point_one/default", 0.14, 1.12)
		await verify_one("res://point_one_radius.gd", "point_one/radius_030", 0.3, 1.12)
		await verify_one("res://point_one_height.gd", "point_one/height_170", 0.14, 1.7)
		await verify_one("res://point_one_no_collision.gd", "point_one/boundary_disabled", 0.14, 1.12, true, false)
		await verify_one("res://point_one_invisible.gd", "point_one/surface_hidden", 0.14, 1.12, false, true)
		await verify_coordinates("res://point_coordinates.gd", baseline)
		await verify_disabled_coordinates("res://point_coordinates_disabled.gd")
	elif mode == "missing_mesh":
		await verify_one("res://point_one_missing_mesh.gd", "point_one/default", 0.14, 1.12)
	elif mode == "local_as_world":
		var baseline: Dictionary = await verify_one("res://point_one.gd", "point_one/default", 0.14, 1.12)
		await verify_coordinates("res://point_coordinates_local_as_world.gd", baseline)
	var report := {
		"passed": failures.is_empty(), "mode": mode,
		"scope": "Headless native Godot 4.6 executes the exact printed student code in an isolated project. Native physics queries and the repository's unmodified XRToolsPickable, XRToolsFunctionPickup and grab driver are exercised with a synthetic XRController3D. Hardware grip input is bypassed. This does not verify headset input, rendered appearance, museum playthrough or an actual learner portfolio.",
		"checks": checks, "failure_ids": failures, "observations": observations,
	}
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("POINTS BUILT AND CARRIED ", mode, ": ", "PASS" if failures.is_empty() else "FAIL", " (", checks.size(), " checks)")
	quit(0 if failures.is_empty() else 1)

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

func sphere_parts(lesson: Node3D, prefix: String, radius: float, height: float, visible: bool = true, collides: bool = true) -> Dictionary:
	var point: PhysicsBody3D = lesson.point
	var meshes := children_of_type(point, "MeshInstance3D")
	var boundaries := children_of_type(point, "CollisionShape3D")
	check(children_of_type(lesson, "PhysicsBody3D").size() == 1, prefix + "/one_point", "The script constructs exactly one physics body under its station.")
	check(meshes.size() == 1 and point.get_child_count() == 2 and boundaries.size() == 1, prefix + "/two_children", "The point owns exactly one visible mesh node and one physical boundary.")
	check(point.position.is_equal_approx(Vector3(0, height, 0)), prefix + "/centre", "The body uses the declared local CENTRE under a translated, rotated unit-scale station.")
	check(meshes.size() == 1 and meshes[0].mesh is SphereMesh and meshes[0].visible == visible, prefix + "/visible_sphere", "A MeshInstance3D has an assigned SphereMesh and the expected visibility.")
	check(boundaries.size() == 1 and boundaries[0].shape is SphereShape3D and boundaries[0].disabled == not collides, prefix + "/physical_sphere", "A sphere collision shape belongs to the body and has the expected enabled state.")
	if meshes.size() != 1 or boundaries.size() != 1 or not meshes[0].mesh is SphereMesh or not boundaries[0].shape is SphereShape3D:
		return {}
	var surface: MeshInstance3D = meshes[0]
	var boundary: CollisionShape3D = boundaries[0]
	check(is_equal_approx(surface.mesh.radius, radius) and is_equal_approx(surface.mesh.height, radius * 2.0) and is_equal_approx(boundary.shape.radius, radius), prefix + "/dimensions", "The visible radius, full height and collider radius agree with the declared RADIUS.")
	check(surface.global_transform.is_equal_approx(point.global_transform) and boundary.global_transform.is_equal_approx(point.global_transform), prefix + "/alignment", "Visible and physical spheres share their parent's centre and orientation.")
	check(surface.material_override == null and surface.mesh.material == null, prefix + "/default_material", "The student script retains Godot's default material with no authored override.")
	return {"surface": surface, "boundary": boundary}

func geometry_snapshot(surface: MeshInstance3D, boundary: CollisionShape3D) -> Dictionary:
	return {
		"surface_transform": surface.global_transform,
		"boundary_transform": boundary.global_transform,
		"radius": surface.mesh.radius, "height": surface.mesh.height,
		"radial_segments": surface.mesh.radial_segments, "rings": surface.mesh.rings,
		"shape_radius": boundary.shape.radius,
		"default_material": surface.material_override == null and surface.mesh.material == null,
	}

func verify_one(path: String, prefix: String, radius: float, height: float, visible: bool = true, collides: bool = true) -> Dictionary:
	var lesson := make_lesson(path)
	var point: PhysicsBody3D = lesson.point
	check(point is StaticBody3D and not point.has_method("pick_up"), prefix + "/static_body", "The first lesson constructs a static body without pickup behaviour.")
	var parts := sphere_parts(lesson, prefix, radius, height, visible, collides)
	await frames()
	var query := PhysicsRayQueryParameters3D.create(point.global_position + Vector3(-radius * 2, 0, 0), point.global_position + Vector3(radius * 2, 0, 0), 1)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	check(hit.get("collider") == point if collides else hit.is_empty(), prefix + "/ray_hit", "A native physics ray hits the boundary when enabled and misses it when disabled, independently of surface visibility.")
	var baseline := {}
	if not parts.is_empty():
		baseline = geometry_snapshot(parts["surface"], parts["boundary"])
		var controller := make_controller(point.global_position)
		var pickup: Node3D = controller.get_node("Pickup")
		await frames()
		pickup._update_closest_object()
		pickup._pick_up_object(pickup.closest_object)
		check(pickup.closest_object == null and pickup.picked_up_object == null, prefix + "/not_pickable", "A synthetic controller overlapping the static point cannot select or hold it.")
		controller.position += Vector3(0.5, 0.2, -0.3)
		await frames()
		check(point.global_transform.is_equal_approx(baseline["surface_transform"]), prefix + "/stays_fixed", "The point remains fixed when the nearby controller moves away.")
		controller.queue_free()
	lesson.queue_free()
	await frames(2)
	return baseline

func check_readout(lesson: Node3D, prefix: String) -> void:
	var point: Node3D = lesson.point
	var label: Label3D = lesson.readout
	# Independent frame computation: inverse station transform applied to the body.
	# The test does not call the student's to_local() expression or parse its source.
	var expected_world := point.global_transform.origin
	var expected_local := lesson.global_transform.affine_inverse() * expected_world
	var expected_text := "LOCAL " + str(expected_local) + "\nWORLD " + str(expected_world)
	check(label != null and label.text == expected_text, prefix, "The running _process readout matches independent station-frame and world-frame positions.")
	observations.append({"case": prefix, "expected": expected_text, "actual": label.text if label else "<missing>"})

func verify_disabled_coordinates(path: String) -> void:
	var prefix := "point_coordinates/disabled_before_tree"
	var lesson := make_lesson(path)
	var point: RigidBody3D = lesson.point
	# This runs the exact prose edit in a fresh script, before tree entry.
	sphere_parts(lesson, prefix, 0.14, 1.12)
	check(not point.enabled and point.original_collision_layer == 4 and point.original_collision_mask == 196615, prefix + "/fresh_disabled_settings", "The fresh edited script disables pickup before tree entry and retains its collision settings.")
	var controller := make_controller(point.global_position)
	var pickup: Node3D = controller.get_node("Pickup")
	await frames()
	check(pickup._object_in_grab_area.has(point), prefix + "/physical_overlap", "The disabled point still enters the real near-grab Area3D through its collider.")
	pickup._update_closest_object()
	pickup._pick_up_object(pickup.closest_object)
	check(not point.can_pick_up(pickup) and pickup.closest_object == null and pickup.picked_up_object == null and not point.is_picked_up(), prefix + "/cannot_select_or_hold", "The freshly disabled point cannot be selected or held by the pickup library.")
	var query := PhysicsRayQueryParameters3D.create(point.global_position + Vector3(-0.3, 0, 0), point.global_position + Vector3(0.3, 0, 0), 4)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	check(hit.get("collider") == point, prefix + "/boundary_remains", "Disabling pickup preserves the point's native physics boundary.")
	check_readout(lesson, prefix + "/readout_remains")
	var initial := point.global_transform
	controller.position += Vector3(0.4, 0.2, -0.3)
	await frames()
	check(point.global_transform.is_equal_approx(initial), prefix + "/does_not_follow", "The disabled point remains fixed when the controller leaves.")
	controller.queue_free()
	lesson.queue_free()
	await frames(2)

func verify_coordinates(path: String, baseline: Dictionary) -> void:
	var prefix := "point_coordinates/default"
	var lesson := make_lesson(path)
	var point: RigidBody3D = lesson.point
	check(point.has_method("pick_up"), prefix + "/pickable_body", "The continuation gives the same student construction XR Tools pickup behaviour.")
	var parts := sphere_parts(lesson, prefix, 0.14, 1.12)
	if parts.is_empty():
		lesson.queue_free()
		await frames(2)
		return
	var surface: MeshInstance3D = parts["surface"]
	var boundary: CollisionShape3D = parts["boundary"]
	var initial := geometry_snapshot(surface, boundary)
	check(initial == baseline, prefix + "/geometry_and_pose_carried", "The incoming Point One snapshot and Coordinates construction have identical dimensions, mesh defaults, material state and world pose.")
	check(point.freeze and point.freeze_mode == RigidBody3D.FREEZE_MODE_KINEMATIC and point.release_mode == 1 and not point.can_ranged_grab, prefix + "/near_and_frozen", "The point starts frozen, uses near grabbing and freezes after release.")
	check(point.original_collision_layer == 4 and point.original_collision_mask == 196615, prefix + "/settings_before_tree", "XR Tools cached the configured layers and mask during tree entry.")
	var label: Label3D = lesson.readout
	check(label != null and label.get_parent() == lesson and lesson.get_child_count() == 2, prefix + "/readout_created", "The station owns one readout alongside its single point.")
	check(label.position.is_equal_approx(Vector3(0, 1.6, 0)) and label.font_size == 36 and is_equal_approx(label.pixel_size, 0.005), prefix + "/readout_settings", "The readout has the size and local placement taught in the continuation.")
	await frames()
	check_readout(lesson, prefix + "/initial_readout")
	var mesh_id := surface.get_instance_id()
	var collider_id := boundary.get_instance_id()
	var mesh_resource := surface.mesh
	var shape_resource := boundary.shape
	var controller := make_controller(point.global_position + Vector3(1, 0, 0))
	var pickup: Node3D = controller.get_node("Pickup")
	await frames()
	check(not pickup._object_in_grab_area.has(point), prefix + "/outside", "The controller begins outside the real near-grab detector.")
	controller.global_position = point.global_position
	await frames()
	pickup._update_closest_object()
	check(pickup._object_in_grab_area.has(point) and pickup.closest_object == point and point.can_pick_up(pickup), prefix + "/near_eligible", "Actual Area3D overlap selects the constructed point through the real pickup library.")
	point.enabled = false
	pickup._update_closest_object()
	pickup._pick_up_object(pickup.closest_object)
	check(not point.can_pick_up(pickup) and pickup.closest_object == null and pickup.picked_up_object == null, prefix + "/disabled_denies_pickup", "Disabling the same point denies selection and pickup.")
	point.enabled = true
	pickup._update_closest_object()
	# Only hardware grip input is bypassed; selection, pickup and grab driver are real.
	pickup._pick_up_object(pickup.closest_object)
	check(point.is_picked_up() and pickup.picked_up_object == point, prefix + "/held", "XR Tools holds the existing student-built point.")
	check(point.collision_layer == 65536 and point.collision_mask == 0, prefix + "/held_layer", "The held body uses XR Tools' held-object collision settings.")
	var start := point.global_position
	var movement := Vector3(0.4, 0.2, -0.3)
	controller.global_position += movement
	await frames()
	check(point.global_position.is_equal_approx(start + movement), prefix + "/body_follows", "The real grab driver moves the body by the controller displacement.")
	check(surface.global_position.is_equal_approx(start + movement) and boundary.global_position.is_equal_approx(start + movement), prefix + "/children_follow", "The existing surface and boundary follow the held body together.")
	check(surface.get_instance_id() == mesh_id and boundary.get_instance_id() == collider_id and surface.mesh == mesh_resource and boundary.shape == shape_resource, prefix + "/resources_retained", "Holding and movement retain the original child nodes and mesh/shape resources.")
	check_readout(lesson, prefix + "/held_readout")
	pickup.drop_object()
	await frames()
	check(not point.is_picked_up() and pickup.picked_up_object == null, prefix + "/released", "Library release clears the hold.")
	check(point.freeze and point.collision_layer == 4 and point.collision_mask == 196615, prefix + "/release_settings", "Release freezes the point and restores its configured layers.")
	var released := point.global_transform
	controller.position += Vector3(1, 0.3, 0)
	await frames(12)
	check(point.global_transform.is_equal_approx(released) and surface.global_transform.is_equal_approx(released) and boundary.global_transform.is_equal_approx(released), prefix + "/release_stays", "The point and both children remain where released while the controller leaves.")
	check_readout(lesson, prefix + "/released_readout")
	var local_before := point.position
	var world_before := point.global_position
	lesson.position += Vector3(1, 0.25, 2)
	lesson.rotation.y += 0.45
	await frames()
	check(point.position.is_equal_approx(local_before) and not point.global_position.is_equal_approx(world_before), prefix + "/parent_frame_change", "Translating and rotating the unit-scale station preserves the point's local position and changes its world position.")
	check_readout(lesson, prefix + "/changed_frame_readout")
	var before_text := label.text
	point.position += Vector3(0.2, 0.15, 0.3)
	await frames()
	check(label.text != before_text, prefix + "/body_change_updates", "Moving the point after release changes the live coordinate text.")
	check_readout(lesson, prefix + "/moved_body_readout")
	controller.queue_free()
	lesson.queue_free()
	await frames(2)
