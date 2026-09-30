extends "res://doc/book/iterations/2026-09-29-point-and-coordinates/probe.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.5).timeout
	if map_id == "Point_Coordinates":
		await coordinate_checks()
		var points := stations()
		if points.has("held"):
			var held: Node3D = points.held.point
			check("black point visual radius halved to 7 cm", is_equal_approx(held.get_node("MeshInstance3D/Sphere").radius, 0.07))
			check("black point collision radius also 7 cm", is_equal_approx(held.get_node("CollisionShape3D").shape.radius, 0.07))
	else:
		await line_checks()

func ray(room: Node3D, a: Vector3, b: Vector3) -> Dictionary:
	return hall.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(room.to_global(a),room.to_global(b),1))

func line_checks() -> void:
	var room := find_scene("/line_black_box.gd")
	check("new entrance black box is live in museum", room != null)
	if room == null: return
	observations["room_world"] = xyz(room.global_position)
	observations["room_in_hall"] = xyz(hall.to_local(room.global_position))
	observations["room_scale"] = xyz(room.global_basis.get_scale())
	check("room keeps metre scale", room.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	check("black box floor footprint is 4 by 4 metres", room.get_node("Floor").mesh.size.is_equal_approx(Vector3(4,0.02,4)))
	check("line uses existing line implementation", str(room.line.get_script().resource_path).ends_with("/primitives/line/line.gd"))
	check("north entrance is open", ray(room,Vector3(-0.5,1.5,-2.4),Vector3(-0.5,1.5,-1.5)).is_empty())
	check("east passage is open", ray(room,Vector3(1.5,1.5,-0.5),Vector3(2.5,1.5,-0.5)).is_empty())
	check("back wall is solid", not ray(room,Vector3(0,1.5,1.8),Vector3(0,1.5,2.1)).is_empty())
	var walk: Dictionary = museum.get("_walk_cells")
	for p in [Vector3(-0.5,0,-1.5),Vector3(-0.5,0,-0.5),Vector3(0.5,0,-0.5),Vector3(1.5,0,-0.5)]:
		var world := room.to_global(p)
		check("museum navigation keeps interior route at "+str(p), walk.has(Vector2i(int(floor(world.x)),int(floor(world.z)))))
	for p in [Vector3(-0.5,0, -2.2), Vector3(-0.5,0,-1),Vector3(0,0,0),Vector3(2.1,0,-0.5)]:
		check("floor supports route at " + str(p), not floor_at(room.to_global(p)).is_empty())
	var a: Node3D = room.point_a
	var b: Node3D = room.point_b
	var segment: MeshInstance3D = room.line.current_line
	check("initial line measures 1.60 m", is_equal_approx(segment.mesh.height,1.6) and room.readout.text == "1.60 m")
	check("new line is smooth and resistance-free", segment.mesh.radial_segments == 32 and not room.line.enable_resistance)
	await snapshot("entrance-line",room.to_global(Vector3(-0.42,1.65,-1.63)),room.to_global(Vector3(0,1.48,0.9)),77)
	await snapshot("black-box-passage",room.to_global(Vector3(-1.35,1.65,1.25)),room.to_global(Vector3(0.6,1.25,-0.7)),78)
	var grabber := SuppliedGrabber.new()
	root.add_child(grabber)
	grabber.global_transform = b.global_transform
	b.pick_up(grabber)
	grabber.global_position += room.global_basis * Vector3(0.38,0.42,-0.1)
	for i in range(12): await physics_frame
	var length: float = a.global_position.distance_to(b.global_position)
	check("production grab moves the endpoint", b.is_picked_up() and length > 1.9)
	check("line follows moved endpoint", absf(segment.mesh.height-length)<0.01 and segment.global_position.distance_to((a.global_position+b.global_position)*0.5)<0.01)
	check("wall readout follows moved span", room.readout.text == "%.2f m" % length)
	var held_position := b.global_position
	room.reset_line()
	check("reset does not steal a held endpoint", b.global_position.distance_to(held_position)<0.001 and b.is_picked_up())
	b.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	for i in range(6): await physics_frame
	check("release leaves endpoint where placed", b.freeze and not b.is_picked_up() and b.global_position.distance_to(held_position)<0.01)
	await snapshot("line-length-changed",room.to_global(Vector3(-0.42,1.65,-1.63)),room.to_global(Vector3(0,1.48,0.9)),77)
	# Check an upright segment and coincident endpoints, common learner moves.
	place(b,a.global_position+Vector3.UP)
	await tick(); await tick()
	check("vertical segment stays aligned", absf(segment.mesh.height-1)<0.01 and absf(segment.global_basis.y.dot(Vector3.UP))>0.99)
	place(b,a.global_position)
	await tick(); await tick()
	check("coincident endpoints hide zero-length segment", not segment.visible and room.readout.text=="0.00 m")
	var pointer := Node3D.new();root.add_child(pointer)
	XRToolsPointerEvent.pressed(pointer,room.reset_button,room.reset_button.global_position)
	XRToolsPointerEvent.released(pointer,room.reset_button,room.reset_button.global_position)
	# Physics transforms and the rendered readout settle on separate callbacks.
	await create_timer(0.15).timeout
	check("pointer reset returns both endpoints", a.position.is_equal_approx(room.HOME_A) and b.position.is_equal_approx(room.HOME_B))
	observations["reset_state"] = {"a":xyz(a.position),"b":xyz(b.position),"visible":segment.visible,"readout":room.readout.text,"cached":room._last_text,"distance":a.global_position.distance_to(b.global_position),"height":segment.mesh.height}
	check("reset restores visible span and readout",segment.visible and room.readout.text=="1.60 m")
	place(a,a.global_position+Vector3(0,0.2,0))
	room.reset_button._on_button_entered(pointer)
	room.reset_button._on_button_exited(pointer)
	await tick(); await tick()
	check("near-hand reset uses same operation",a.position.is_equal_approx(room.HOME_A))
	check("line demonstration still present",find_scene("/line_demo.gd")!=null)
	observations["changed_length_m"] = length
	observations["new_room_bounds"] = [4,3.24,4]
	pointer.queue_free();grabber.queue_free()

func place(body: RigidBody3D, at: Vector3) -> void:
	body.global_position = at
	PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Actual museum render; production pickup/release, line geometry, readout, pointer and near-hand reset, entrances and route collision. No headset or learner trial."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("LINE ENTRY ", map_id," ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
