extends "res://tools/probes/transformation_encounters.gd"
## The real coordinate hall and real XR Tools pickup, with a synthetic controller.

func frames(count: int = 8) -> void:
	for i in count:
		await tick()

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.5).timeout
	var station := find_scene("/point_held.gd")
	var frame := find_scene("/CoordinateSystem3M.gd")
	check("existing coordinate station and frame load", station != null and frame != null)
	if station == null or frame == null: return
	var point: RigidBody3D = station.point
	var plinth := station.get_node_or_null("HeldPointPlinth") as MeshInstance3D
	check("held point has one stationary podium", plinth != null and hall.find_children("HeldPointPlinth", "MeshInstance3D", true, false).size() == 1)
	if plinth == null: return
	var label: Label3D = station.get_node("PointOneLabel")
	check("support belongs to station, never held sphere", plinth.get_parent() == station and not point.is_ancestor_of(plinth))
	check("support uses matching off-white matte finish", plinth.material_override.albedo_color.is_equal_approx(Color(0.90, 0.895, 0.875)) and is_equal_approx(plinth.material_override.roughness, 0.82))
	check("support height meets existing .07m point", plinth.mesh.size.is_equal_approx(Vector3(0.82, 1.05, 0.82)) and is_equal_approx(point.position.y, 1.12))
	check("point keeps coordinate identity and physical size", point.coordinate_id == "point_one_main" and is_equal_approx(point.get_node("CollisionShape3D").shape.radius, 0.07))
	check("point keeps black surface", point.get_node("MeshInstance3D").material_override.albedo_color.r < 0.02)
	check("support's single label faces front", label.position.is_equal_approx(Vector3(0, 0.68, 0.421)))
	var surface: Vector3 = station.to_global(Vector3(0.25, 1.05, 0))
	var support_ray := PhysicsRayQueryParameters3D.create(surface + Vector3.UP * 0.3, surface - Vector3.UP * 0.3, 1)
	var hit := hall.get_world_3d().direct_space_state.intersect_ray(support_ray)
	check("podium supplies physical support at its top", not hit.is_empty() and str(hit.collider.name) == "PlinthCollision" and absf(hit.position.y - surface.y) < 0.01)
	var approach: Vector3 = station.to_global(Vector3(1.2, 0, 0))
	check("podium leaves supported walking approach", not floor_at(approach).is_empty())
	check("frame continues tracking existing held point", frame._fp_ref == point)
	var frame_before: Transform3D = frame.global_transform
	var podium_before: Transform3D = plinth.global_transform
	var label_before: Transform3D = label.global_transform
	var point_before: Transform3D = point.global_transform
	observations["point_world"] = xyz(point.global_position)
	observations["podium_size_m"] = xyz(plinth.mesh.size)
	var podium_eye: Vector3 = station.global_position + Vector3(2.4, 1.65, -1.0)
	var sight := PhysicsRayQueryParameters3D.create(podium_eye, point.global_position, 1)
	check("podium capture sees point without a wall obstruction", hall.get_world_3d().direct_space_state.intersect_ray(sight).is_empty())
	await snapshot("coordinate-podium", podium_eye, station.global_position + Vector3(0, 0.70, 0), 50)
	var controller := XRController3D.new()
	root.add_child(controller)
	controller.global_position = point.global_position
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
	pickup.name = "SyntheticPickup"
	pickup.hand_offset_mode = 4
	pickup.ranged_enable = false
	controller.add_child(pickup)
	await frames()
	pickup._update_closest_object()
	check("real near-grab detector selects sphere, not podium", pickup._object_in_grab_area.has(point) and pickup.closest_object == point)
	pickup._pick_up_object(pickup.closest_object)
	check("existing XR Tools pickup still holds the point", point.is_picked_up() and pickup.picked_up_object == point)
	var held_start: Vector3 = point.global_position
	var movement := Vector3(0.42, 0.4, -0.28)
	controller.global_position += movement
	await frames()
	check("gripped point follows controller displacement", point.global_position.is_equal_approx(held_start + movement))
	check("podium and its label stay behind during pickup", plinth.global_transform.is_equal_approx(podium_before) and label.global_transform.is_equal_approx(label_before))
	check("coordinate frame stays fixed and keeps the same tracked point", frame.global_transform.is_equal_approx(frame_before) and frame._fp_ref == point)
	var cards: Array = []
	for candidate in hall.find_children("*", "Node3D", true, false):
		if candidate.get_script() != null and str(candidate.get_script().resource_path).ends_with("/coordinate_readout.gd") and candidate.readout_channel == "point_one_main": cards.append(candidate)
	check("both local and world coordinate cards retained", cards.size() == 2)
	for card in cards:
		var p: Vector3 = point.global_position if card.space == "world" else frame.to_local(point.global_position)
		var expected := "x = %.2f\ny = %.2f\nz = %.2f" % [p.x, p.y, p.z]
		check(card.space + " coordinate display follows moved point", card._label.text == expected)
	pickup.drop_object()
	await frames()
	check("release clears grip and restores frozen point", not point.is_picked_up() and pickup.picked_up_object == null and point.freeze)
	var released: Transform3D = point.global_transform
	controller.global_position += Vector3(1, 0, 0)
	await frames()
	check("released point stays where visitor left it", point.global_transform.is_equal_approx(released))
	check("stationary podium remains after release", plinth.global_transform.is_equal_approx(podium_before))
	# Return only the test's moved point; production logic and initial placement stay intact.
	point.global_transform = point_before
	controller.queue_free()
	await frames(2)
	await snapshot("coordinate-hall", station.global_position + Vector3(2.4, 2.2, -1.5), frame.global_position + Vector3(0.5, 0.8, 0), 74)

func finish() -> void:
	var result := {"room": map_id, "checks": checks, "failures": failures, "observations": observations, "passed": failures.is_empty(), "scope": "Real museum scene and XR Tools detector/hold/release, with synthetic controller input. Geometry, support collision and local/world displays checked. No physical headset test."}
	FileAccess.open(folder + "report.json", FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
	print("COORDINATE PODIUM ", checks.size() - failures.size(), "/", checks.size())
	quit(0 if failures.is_empty() else 1)
