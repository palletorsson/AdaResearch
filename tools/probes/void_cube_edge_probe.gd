extends "res://tools/probes/void_grid_probe.gd"

func photograph(filename: String, at: Vector3, target: Vector3) -> void:
	# The external inspection camera should not look through the test avatar.
	var origin: Node3D = game.get_node("XROrigin3D")
	var was_visible := origin.visible
	origin.hide()
	await super.photograph(filename,at,target)
	origin.visible = was_visible

func rendered_front_depth(cube: Node3D) -> float:
	# Independent observation of the actual rendered triangle vertices.
	for index in [4,5]:
		var face: PackedVector3Array = cube.triangle_meshes[index].mesh.get_faces()
		var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3(0,0,2),Vector3.FORWARD,face[0],face[1],face[2])
		if hit != null:
			return hit.z
	return NAN

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await start(true)
	game.checkpoint = 7
	game.place_player(Vector3(-16,-41.94,3.2))
	var content: Node3D = game.building.content
	var deadline := Time.get_ticks_msec()+30000
	while not content.pending.is_empty() and Time.get_ticks_msec()<deadline:
		await frames(1)
	await frames(20)
	var hall: Node3D = content.exhibits["7/hall"].get_node("Artifact")
	var pair: Node3D = hall.get_node("PairedCubeDiagonals")
	var study: Node3D = pair.get_node("EdgeStudy")
	var button: Node3D = study.get_node("Try25cm")
	var original: Array = pair.initial.duplicate()
	var recipes: Array = [pair.cubes[0].triangles.duplicate(true),pair.cubes[1].triangles.duplicate(true)]
	check("existing paired-cube scene still owns the experiment",pair.get_script().resource_path.ends_with("primitive_encounters/paired_cubes.gd"))
	check("flat baseline reads zero depth difference",is_zero_approx(study.difference))
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("flat.png",Vector3(-16,-40.35,3.8),Vector3(-16,-40.7,0))
	button.pressed.emit()
	await frames(5)
	check("trial moves only local corner 6 by 0.25 in z",pair.cubes[0].vertices[6].is_equal_approx(original[6]+Vector3(0,0,.25)))
	var other_corners_unchanged := true
	for i in 8:
		if i!=6 and not pair.cubes[0].vertices[i].is_equal_approx(original[i]): other_corners_unchanged=false
	check("other seven corners stay fixed",other_corners_unchanged)
	check("both bodies share the same eight local positions",pair.cubes[0].vertices==pair.cubes[1].vertices)
	check("both triangulation recipes remain unchanged",pair.cubes[0].triangles==recipes[0] and pair.cubes[1].triangles==recipes[1])
	var a := rendered_front_depth(pair.cubes[0])
	var b := rendered_front_depth(pair.cubes[1])
	check("actual rendered surfaces differ by 0.125 at local x0 y0",is_equal_approx(a,.5) and is_equal_approx(b,.625))
	check("live instrument agrees with the rendered triangle measurement",is_equal_approx(study.difference,b-a) and study.readout.text.contains("0.125 m"))
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("folded.png",Vector3(-16,-40.35,3.8),Vector3(-16,-40.7,0))
		await photograph("crease.png",Vector3(-13.6,-40.35,2.35),Vector3(-16,-40.75,0))
	button.pressed.emit()
	await frames(5)
	check("repeat trial restarts the baseline rather than accumulating displacement",is_equal_approx(study.difference,.125) and pair.cubes[0].vertices[6].is_equal_approx(original[6]+Vector3(0,0,.25)))
	pair.get_node("Restore").pressed.emit()
	await frames(5)
	check("existing Restore resets both geometry and instrument",pair.cubes[0].vertices==original and pair.cubes[1].vertices==original and is_zero_approx(study.difference))
	# Actual XRTools grip carries the existing point; the measuring aid must not interfere.
	var point: Node3D = pair.cubes[0].handle_nodes[6]
	game.place_player(point.global_position+Vector3(0,-1.35,1.2))
	await frames(15)
	hand_at(right,point.global_position)
	await frames(15)
	right.set_input("grip",1.0)
	await frames(15)
	check("XR grip still picks up the original pink corner",game.pickups[1].picked_up_object==point and pair.held())
	var held_positions: Array = pair.cubes[0].vertices.duplicate()
	button.pressed.emit()
	await frames(3)
	check("trial cannot reset a corner held in the hand",pair.cubes[0].vertices==held_positions)
	var hand_target: Vector3 = point.global_position+Vector3(0,0,.2)
	hand_at(right,hand_target)
	await frames(20)
	check("hand movement changes the real surfaces and live measurement",pair.cubes[0].vertices==pair.cubes[1].vertices and study.difference>.05)
	right.set_input("grip",0.0)
	await frames(15)
	check("XR release leaves the edited form available",not pair.held() and study.difference>.05)
	pair.get_node("Replay").pressed.emit()
	await frames(2)
	check("replay hides measurement markers while construction is revealed",pair.replaying and not study.markers[0].visible and study.readout.text.contains("not been reset"))
	await frames(260)
	pair.get_node("FreeEdit").pressed.emit()
	await frames(3)
	check("free editing declares that midpoint x and y may differ",pair.free_edit and study.readout.text.contains("x and y"))
	button.pressed.emit()
	await frames(4)
	check("controlled trial returns from free editing to one-corner comparison",not pair.free_edit and is_equal_approx(study.difference,.125))
	var old: Vector3 = pair.position
	var plate: Node3D = study.get_node("ReadingPlate")
	var plate_before: Vector3 = plate.global_position
	hall.apply_grid_config({"parts":{"PairedCubeDiagonals":{"position":[old.x+.5,old.y,old.z]}}})
	await frames(3)
	check("instrument travels with the paired cubes in the lab editor",plate.global_position.is_equal_approx(plate_before+Vector3(.5,0,0)))
	hall.apply_grid_config({"parts":{"PairedCubeDiagonals":{"position":[old.x,old.y,old.z]}}})
	pair.get_node("Restore").pressed.emit()
	await frames(3)
	check("restoration retains the original geometry and face recipes",pair.cubes[0].vertices==original and pair.cubes[0].triangles==recipes[0] and pair.cubes[1].triangles==recipes[1])
	game.queue_free()
	await frames(30)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot geometry and rendered-mesh intersection; real XRTools with synthetic tracking. No physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)
