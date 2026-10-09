# verify.gd
# Native contract checks for the assumed incoming state and mechanically composed delta.
# Real XR Tools overlap/grab/driver/release; synthetic controller, no headset input.
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
		for case in [
			{"label": "radius_014", "incoming": "res://incoming.gd", "outgoing": "res://assembled.gd", "radius": 0.14},
			{"label": "radius_030", "incoming": "res://incoming_radius_variant.gd", "outgoing": "res://assembled_radius_variant.gd", "radius": 0.3},
		]:
			var baseline: Dictionary = await verify_incoming(case)
			await verify_transition(case, baseline)
	else:
		var case := {"label": "missing_reparent", "incoming": "res://incoming.gd", "outgoing": "res://assembled_missing_reparent.gd", "radius": 0.14}
		var baseline: Dictionary = await verify_incoming(case)
		# Deliberately run the SAME outgoing contract: this mutant must fail it.
		await verify_transition(case, baseline)
	var report := {
		"passed": failures.is_empty(),
		"mode": mode,
		"scope": "Headless native Godot with the repository's unmodified XRToolsPickable and XRToolsFunctionPickup. A synthetic XRController3D exercises real overlap selection, library pickup, grab-driver movement and release. The grip hardware input boundary is bypassed. No headset, rendered appearance, learner portfolio or museum playthrough is verified.",
		"checks": checks,
		"failure_ids": failures,
		"observations": observations,
	}
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("LESSON STATE CHAIN ", mode, ": ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)

func make_lesson(path: String) -> Node3D:
	var lesson: Node3D = load(path).new()
	# A transformed parent makes an accidental local-position reset detectable.
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
	pickup.hand_offset_mode = 4 # No automatic hand offset in the synthetic fixture.
	pickup.ranged_enable = false
	controller.add_child(pickup)
	return controller

func snapshot(surface: MeshInstance3D, collider: CollisionShape3D) -> Dictionary:
	return {
		"surface_transform": surface.global_transform,
		"collider_transform": collider.global_transform,
		"mesh_radius": surface.mesh.radius,
		"mesh_height": surface.mesh.height,
		"radial_segments": surface.mesh.radial_segments,
		"rings": surface.mesh.rings,
		"shape_radius": collider.shape.radius,
		"colour": surface.material_override.albedo_color,
		"roughness": surface.material_override.roughness,
	}

func verify_incoming(case: Dictionary) -> Dictionary:
	var prefix: String = case["label"] + "/incoming/"
	var lesson := make_lesson(case["incoming"])
	var surface: MeshInstance3D = lesson.get_node("VisiblePoint")
	var solid: StaticBody3D = lesson.get_node("PointCollision")
	var collider: CollisionShape3D = solid.get_child(0)
	var radius: float = case["radius"]
	check(surface.get_parent() == lesson and solid.get_parent() == lesson, prefix + "siblings", "Visible mesh and static body are siblings under the station.")
	check(lesson.get_child_count() == 2 and solid.get_child_count() == 1, prefix + "minimal_state", "The incoming point has one visible mesh and one separate physics boundary.")
	check(not solid.has_method("pick_up"), prefix + "not_pickable", "Incoming StaticBody3D has no pickup behavior.")
	check(surface.global_transform.is_equal_approx(solid.global_transform) and collider.global_transform.is_equal_approx(surface.global_transform), prefix + "alignment", "The independent visual and physical constructions share one centre and orientation.")
	check(is_equal_approx(surface.mesh.radius, radius) and is_equal_approx(surface.mesh.height, radius * 2.0) and is_equal_approx(collider.shape.radius, radius), prefix + "geometry", "Mesh and collider use the same incoming radius.")
	check(surface.material_override.albedo_color.is_equal_approx(Color(0.97, 0.97, 0.95)), prefix + "white_material", "Point One's white material is retained in the source-bound fixture.")
	var controller := make_controller(solid.global_position)
	var pickup: Node3D = controller.get_node("Pickup")
	await frames()
	pickup._update_closest_object()
	check(not pickup._object_in_grab_area.has(solid) and pickup.closest_object == null, prefix + "no_grab_candidate", "A controller at the incoming static point cannot select it for pickup.")
	pickup._pick_up_object(pickup.closest_object)
	check(pickup.picked_up_object == null, prefix + "no_grab", "The pickup library holds nothing when no point is eligible.")
	var query := PhysicsRayQueryParameters3D.create(solid.global_position + Vector3(-radius * 2.0, 0, 0), solid.global_position + Vector3(radius * 2.0, 0, 0), 1)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	check(hit.get("collider") == solid, prefix + "physical_boundary", "The incoming static boundary participates in native physics queries.")
	var baseline := snapshot(surface, collider)
	controller.position += Vector3(0.5, 0.2, -0.3)
	await frames()
	check(surface.global_transform.is_equal_approx(baseline["surface_transform"]) and collider.global_transform.is_equal_approx(baseline["collider_transform"]), prefix + "does_not_follow", "The incoming mesh and boundary stay fixed when the nearby controller moves.")
	controller.queue_free()
	lesson.queue_free()
	await frames(2)
	return baseline

func verify_transition(case: Dictionary, baseline: Dictionary) -> void:
	var prefix: String = case["label"] + "/outgoing/"
	var lesson := make_lesson(case["outgoing"])
	# Keep addon class resolution after autoload startup: this is a SceneTree --script.
	var solid: RigidBody3D = lesson.get_node("PointCollision")
	var surface: MeshInstance3D = lesson.find_child("VisiblePoint", true, false)
	var collider: CollisionShape3D
	for child in solid.get_children():
		if child is CollisionShape3D:
			collider = child
	check(surface != null and collider != null, prefix + "components", "The existing visible mesh and sphere collider remain present.")
	if surface == null or collider == null:
		lesson.queue_free()
		await frames(2)
		return
	check(surface.get_parent() == solid, prefix + "mesh_parent", "The existing visible mesh is now a child of the pickable collision body.")
	check(lesson.find_children("*", "MeshInstance3D", true, false).size() == 1 and lesson.find_children("*", "CollisionShape3D", true, false).size() == 1, prefix + "no_duplicate_point", "The delta creates no second visible point or second collider.")
	var initial := snapshot(surface, collider)
	check(initial["surface_transform"].is_equal_approx(baseline["surface_transform"]) and initial["collider_transform"].is_equal_approx(baseline["collider_transform"]), prefix + "pose_preserved", "Reparenting preserves Point One's visual and collider world pose under a translated, rotated station.")
	var preserved := true
	for key in ["mesh_radius", "mesh_height", "radial_segments", "rings", "shape_radius", "colour", "roughness"]:
		preserved = preserved and initial[key] == baseline[key]
	check(preserved, prefix + "appearance_and_geometry_preserved", "The lesson delta preserves radius, surface geometry, collider size and white material.")
	check(solid.freeze and solid.freeze_mode == RigidBody3D.FREEZE_MODE_KINEMATIC and solid.release_mode == 1 and not solid.can_ranged_grab, prefix + "near_and_frozen", "The point starts frozen, uses near grabbing and freezes after release (ReleaseMode.FROZEN = 1).")
	check(solid.original_collision_layer == 4 and solid.original_collision_mask == 196615, prefix + "settings_before_ready", "XR Tools cached the intended layers before entering the scene tree.")
	var mesh_id := surface.get_instance_id()
	var collider_id := collider.get_instance_id()
	var mesh_resource := surface.mesh
	var collider_resource := collider.shape
	var material_resource := surface.material_override
	var controller := make_controller(solid.global_position + Vector3(1, 0, 0))
	var pickup: Node3D = controller.get_node("Pickup")
	await frames()
	check(not pickup._object_in_grab_area.has(solid), prefix + "outside", "The point begins outside the real near-grab overlap detector.")
	controller.global_position = solid.global_position
	await frames()
	pickup._update_closest_object()
	check(pickup._object_in_grab_area.has(solid) and pickup.closest_object == solid and solid.can_pick_up(pickup), prefix + "near_eligible", "Actual Area3D overlap makes the point eligible for the real pickup library.")
	solid.enabled = false
	pickup._update_closest_object()
	check(not solid.can_pick_up(pickup) and pickup.closest_object == null, prefix + "disabled_not_eligible", "Disabling the same point removes it from pickup selection.")
	solid.enabled = true
	pickup._update_closest_object()
	# Bypass hardware grip input only; library selection, pickup and driver stay real.
	pickup._pick_up_object(pickup.closest_object)
	check(solid.is_picked_up() and pickup.picked_up_object == solid, prefix + "held", "XR Tools holds the existing point collision body.")
	check(solid.collision_layer == 65536 and solid.collision_mask == 0, prefix + "held_layer", "The held body uses the XR Tools held-object layer.")
	var start_solid := solid.global_position
	var start_mesh := surface.global_position
	var start_collider := collider.global_position
	var movement := Vector3(0.4, 0.2, -0.3)
	controller.global_position += movement
	await frames()
	var body_moved := solid.global_position.is_equal_approx(start_solid + movement)
	var collider_moved := collider.global_position.is_equal_approx(start_collider + movement)
	var mesh_moved := surface.global_position.is_equal_approx(start_mesh + movement)
	var mesh_stayed := surface.global_position.is_equal_approx(start_mesh)
	check(body_moved, prefix + "held_body_follows", "The real grab driver moves the pickable body by the controller displacement.")
	check(collider_moved, prefix + "held_collider_follows", "The original collider follows the same held-body displacement.")
	check(mesh_moved, prefix + "held_mesh_follows", "The original visible mesh follows the held body and collider.")
	check(surface.global_transform.is_equal_approx(collider.global_transform), prefix + "held_alignment", "Visible and physical sphere remain aligned while held.")
	check(surface.get_instance_id() == mesh_id and collider.get_instance_id() == collider_id and surface.mesh == mesh_resource and collider.shape == collider_resource and surface.material_override == material_resource, prefix + "same_instances", "Pickup and movement retain the original mesh node, collider node and their resources.")
	observations.append({"case": case["label"], "body_moved": body_moved, "collider_moved": collider_moved, "visible_mesh_moved": mesh_moved, "visible_mesh_stayed": mesh_stayed})
	pickup.drop_object()
	await frames()
	check(not solid.is_picked_up() and pickup.picked_up_object == null, prefix + "released", "Library release clears the grab.")
	check(solid.freeze and solid.collision_layer == 4 and solid.collision_mask == 196615, prefix + "release_restores", "Release freezes the point and restores the configured collision settings.")
	check(surface.global_transform.is_equal_approx(collider.global_transform), prefix + "released_alignment", "Visible and physical boundaries stay together after release.")
	var released_solid := solid.global_transform
	var released_mesh := surface.global_transform
	var released_collider := collider.global_transform
	controller.position += Vector3(1.0, 0.3, 0)
	await frames(12)
	check(solid.global_transform.is_equal_approx(released_solid) and surface.global_transform.is_equal_approx(released_mesh) and collider.global_transform.is_equal_approx(released_collider), prefix + "release_stays", "The released point, visual and collider stay where they were left while the controller moves away.")
	controller.queue_free()
	lesson.queue_free()
	await frames(2)
