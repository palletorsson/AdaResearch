extends "res://commons/testing/probe_color_recovery.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func run() -> void:
	await museum("Color_Nails")
	var salon: Node3D
	var controls: Array[Node3D] = []
	for node in current_scene.find_children("*", "Node3D", true, false):
		if node.get_script() == null:
			continue
		var path: String = node.get_script().resource_path
		if path.ends_with("nail_salon.gd"):
			salon = node
		elif path.ends_with("nail_color_controller.gd"):
			controls.append(node)
	check(salon != null, "salon is present in the actual museum")
	check(controls.size() == 2, "both existing RGB controllers remain")
	if salon == null or controls.size() != 2:
		quit(1)
		return
	var player: CharacterBody3D = current_scene.get("_player")
	var head: Camera3D = current_scene.get("_cam")
	player.set_physics_process(false)
	current_scene.get("_feel").set_process(false)
	player.global_position += salon.to_global(Vector3(0, 1.65, 5.5)) - head.global_position
	for frame in range(20):
		current_scene.call("_cull_artifacts")
		await process_frame
	check(salon.hands.size() == 2, "giant and petite share the source hand")
	check(salon.nail_index >= 0 and salon.skin_index >= 0 and salon.nail_index != salon.skin_index, "nails and skin have distinct mesh surfaces")
	var large: AABB = salon.giant.transform * salon.giant.get_aabb()
	var small: AABB = salon.petite.transform * salon.petite.get_aabb()
	check(is_equal_approx(large.size.y, 4.3) and is_equal_approx(small.size.y, 0.32), "4.3 metre and 32 cm hands")
	check(salon.giant.mesh == salon.petite.mesh, "same mesh at both scales")
	check(salon.find_children("ControlPlinth*", "MeshInstance3D", true, false).size() == 2, "two dedicated control plinths")
	var palette: Node3D = get_first_node_in_group("colorballs")
	check(palette != null and palette.find_children("SalonCase_*", "MeshInstance3D", true, false).size() == 6, "palette case exists before its bouncing display")
	await create_timer(2.0).timeout
	if palette != null:
		check(palette.ball_bodies.all(func(b):
			var p: Vector3 = palette.to_local(b.global_position)
			return absf(p.x) < 1.13 and absf(p.z) < 1.13 and p.y > 0.08 and p.y < 2.2), "palette bodies remain inside the case rather than the approach")
	var gm: Node = root.get_node("GameManager")
	var saved_nails: Color = gm.get_nail_color()
	var saved_skin: Color = gm.get_hand_color()
	var grabber := SuppliedGrabber.new()
	current_scene.add_child(grabber)
	for control in controls:
		var mapper: Node3D = control.get_node("ValueMapper3D")
		check(mapper.global_position.y >= 0.85 and mapper.global_position.y + 0.5 <= 1.5, "RGB box within standing reach")
		check(not control.get_node("MeshInstance3D").visible, "salon replaces generic controller canopy")
		check(absf(control.global_position.x - salon.global_position.x) >= 1.9 and control.global_position.z - salon.global_position.z >= 4.9, "control stands clear of the table and stools")
		var colour := Color(0.86, 0.13, 0.46) if control.target_surface == 0 else Color(0.25, 0.64, 0.57)
		var point: Node3D = mapper.point
		grabber.global_transform = point.global_transform
		point.pick_up(grabber)
		grabber.global_position = mapper.to_global(Vector3(colour.r, colour.g, colour.b) * 0.5)
		for frame in range(16):
			await physics_frame
		print("SALON_COLOUR ", control.target_surface, " wanted=", colour, " actual=", control.get_nail_color(), " processing=",mapper.is_processing())
		var materials: Array = salon.nail_materials if control.target_surface == 0 else salon.skin_materials
		check(materials.size() == 2 and materials.all(func(m): return m.albedo_color.is_equal_approx(colour)), "controller recolours both corresponding hand surfaces")
		check(control.color_preview_cube.material_override.albedo_color.is_equal_approx(colour), "swatch and display material values agree")
		if control.target_surface == 0:
			check(salon.skin_materials.all(func(m): return m.albedo_color.is_equal_approx(saved_skin)), "nail edit leaves skin unchanged")
		point.let_go(grabber, Vector3.ZERO, Vector3.ZERO)
	player.global_position += salon.to_global(Vector3(0, 1.65, 10.2)) - head.global_position
	head.look_at(salon.to_global(Vector3(0, 2.65, 0.9)))
	for frame in range(20):
		current_scene.call("_cull_artifacts")
		await process_frame
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	for side in [-1,1]:
		query.transform.origin = salon.to_global(Vector3(side * 3.3, 0.85, 6))
		query.motion = Vector3(0, 0, -11)
		var fractions: PackedFloat32Array = current_scene.get_world_3d().direct_space_state.cast_motion(query)
		check(fractions[0] > 0.99, "body can walk past salon on side %d" % side)
		query.transform.origin += query.motion * minf(1.0, fractions[1] + 0.002)
		var hit: Dictionary = current_scene.get_world_3d().direct_space_state.get_rest_info(query)
		if not hit.is_empty():
			print("AISLE_HIT ",side," ",instance_from_id(hit.collider_id).get_path())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/nail_salon_museum.png")
	# Restore the user's colour choices after the fixture's deliberate samples.
	gm.set_nail_color(saved_nails)
	gm.set_hand_color(saved_skin)
	var report := {"checks":checks,"failures":failures,"headset_tested":false,"input":"Supplied grabber moves the real RGB points; ValueMapper3D and GameManager signals update both hands. Tracked hands untested."}
	var f := FileAccess.open("res://ada_run/probe_nail_salon.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print("NAIL_SALON ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
