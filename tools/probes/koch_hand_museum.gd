extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps"); await create_timer(0.4).timeout
	var walker = museum.get("_player")
	if walker is Node3D:
		walker.hide(); walker.set_process(false); walker.set_physics_process(false); walker.global_position = Vector3(0,-100,0)
	var old_cam = museum.get("_cam")
	if old_cam is Node3D: old_cam.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe = museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")): wardrobe.get("costume").hide()
	var source = find_scene("/example_8_5_koch_curve_vr.gd")
	var triangle = find_scene("/sierpinskitriangle/sierpinski_triangle.gd")
	var measure = find_scene("/box_counting_dimension.gd")
	check("Existing Koch, triangle and measuring studies remain",source != null and triangle != null and measure != null)
	if source == null: return
	var desk = source.get_node("FractalLesson"); var reader = desk.path_reader
	check("New hand reader is installed on original Koch desk",reader != null)
	observations.koch_position = xyz(hall.to_local(source.global_position))
	reader.hide()
	await snapshot("before",source.to_global(Vector3(-0.6,2.1,4.7)),source.to_global(Vector3(0.6,1.0,0.1)),78)
	reader.show()
	await snapshot("arrival",source.to_global(Vector3(-0.6,2.1,4.7)),source.to_global(Vector3(0.6,1.0,0.1)),78)
	await snapshot("hand-start",reader.model.to_global(Vector3(0.3,1.95,1.35)),reader.model.to_global(Vector3(0,1.3,-0.12)),66)
	var origin := XROrigin3D.new(); root.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	controller.global_position = reader.grip.global_position; reader.grip.pick_up(hand)
	await create_timer(0.2).timeout
	reader.grip.action(); await create_timer(0.2).timeout
	var peak: Vector3 = reader.points[2]
	controller.global_position = reader.model.to_global(reader.MINI_ORIGIN + reader.flat(peak)*reader.MINI_SCALE)
	await create_timer(0.3).timeout
	check("Actual held action replaces the line once",source._current_depth==1 and reader.points.size()==5)
	check("Held point measures first peak and moves floor receiver",reader.cursor.distance_to(peak)<0.001 and absf(reader.along-8.0/3.0)<0.001)
	reader.grip.let_go(hand,Vector3.ZERO,Vector3.ZERO); await create_timer(0.2).timeout
	origin.hide() # Supplied test controller graphics do not belong in the exhibit capture.
	await snapshot("hand-detour",reader.model.to_global(Vector3(0.3,1.95,1.35)),reader.model.to_global(Vector3(0,1.3,-0.12)),66)
	await snapshot("floor-first",source.to_global(Vector3(-2.3,2.7,0.7)),source.to_global(Vector3(0,0.1,-2.5)),72)
	var approach: Vector3 = reader.model.to_global(Vector3(0,0.001,1.12))
	check("Hand model has floor at its standing approach",not floor_at(approach).is_empty())
	var shape := CapsuleShape3D.new(); shape.radius = 0.28; shape.height = 1.6
	var query := PhysicsShapeQueryParameters3D.new(); query.shape = shape; query.transform.origin = approach+Vector3.UP*0.9; query.collision_mask=1|4
	var hits := hall.get_world_3d().direct_space_state.intersect_shape(query)
	observations.approach_hits = hits.map(func(hit): return str(hit.collider.get_path()))
	check("Standing body clears the hand model", hits.is_empty())
	var height: float = reader.grip.global_position.y - hall.global_position.y
	check("Point remains within standing hand height",height>1.0 and height<1.6)
	var driver = load("res://commons/testing/wcn_desktop_driver.gd").new(); museum.add_child(driver); driver.spawn(approach,museum)
	await create_timer(0.2).timeout
	for id in ["NEXT","BACK","RESET"]:
		var pressed: Dictionary = await driver.press(reader.buttons[id],approach)
		check("Actual ray reaches nearby "+id,str(pressed.get("hover","")) not in ["","none","null","nothing"])
	check("Nearby RESET restores seed",source._current_depth==0 and reader.points.size()==2)
	desk.set_stage(4); await create_timer(0.2).timeout
	var supported := true
	for p in reader.points:
		var at: Vector3 = reader.to_global(reader.FLOOR_ORIGIN + reader.flat(p)*5.0)
		supported = supported and not floor_at(at).is_empty()
	check("Every fourth-generation route vertex has museum floor", supported)
	check("Fourth stage retains endpoints and longer route",reader.points.size()==257 and absf(reader.total-4.0*pow(4.0/3.0,4))<0.0001)
	await snapshot("floor-fourth",source.to_global(Vector3(-2.3,2.7,0.7)),source.to_global(Vector3(0,0.1,-2.5)),72)
	await snapshot("above",source.to_global(Vector3(-3.5,7.2,3.8)),source.to_global(Vector3(0.5,0.4,-1.1)),76)
	desk.act("TURN"); await create_timer(0.15).timeout
	await snapshot("reversed",source.to_global(Vector3(-2.3,2.7,0.7)),source.to_global(Vector3(0,0.1,-2.0)),72)
	desk.act("RESET"); desk.act("FORM"); desk.act("NEXT")
	check("Original closed comparison still has fourteen-metre boundary",reader.points.size()==13 and absf(reader.total-14)<0.0001)
	await snapshot("closed",source.to_global(Vector3(-3,4.0,3.5)),source.to_global(Vector3(0.4,0.7,-1)),80)
	desk.act("RESET"); desk.act("NEXT")
	if triangle != null:
		var td = triangle.get_node("FractalLesson"); td.set_stage(4)
		var area := 0.0
		for t in triangle.current_triangles: area += (t.v2-t.v1).cross(t.v3-t.v1).length()*0.5
		check("Sierpinski retains 81 triangles and three-quarter area rule",triangle.current_triangles.size()==81 and absf(area-9*sqrt(3.0)*pow(0.75,4))<0.0001)
		td.act("VIEW"); td.act("VIEW")
		check("Negative display preserves computed corners",triangle.excision=="negative" and triangle.current_triangles.size()==81)
		await snapshot("triangle",triangle.to_global(Vector3(0.5,2.5,6)),triangle.to_global(Vector3(0,2.7,0)),64)
	if measure != null:
		var md = measure.get_node("FractalLesson"); var sample: Array = measure._fractal_points.duplicate()
		md.act("FINER"); md.act("COVER"); md.act("RANGE")
		check("Optional measurement preserves its 8000-point sample",measure._fractal_points==sample and sample.size()==8000)
	var vest: int = int(museum.get("VESTIBULE_H"))
	for at in [Vector3(9.5,0.91,4+vest),Vector3(9.5,0.91,10+vest),Vector3(9.5,0.91,17+vest)]:
		query.transform.origin = hall.to_global(at)
		check("Central route stays clear at "+str(at),hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty() and not floor_at(hall.to_global(at-Vector3.UP*0.9)).is_empty())
	driver.teardown()
	var study = load("res://ada_run/koch_student/koch.gd").new()
	study.position = hall.to_local(source.to_global(Vector3(-2.8,0,2.1))); study.rotation=source.rotation; hall.add_child(study)
	study.advance(); study.advance(); await create_timer(0.2).timeout
	await snapshot("student",study.to_global(Vector3(0.2,2.0,1.35)),study.to_global(Vector3(0,1.3,-0.1)),66)
	check("Exact printed study runs beside existing museum artifacts",study.generation==2 and study.drawing.get_child_count()==16)
	study.queue_free(); origin.queue_free()
	observations.scope="Real museum with supplied XR poses and desktop button targeting. Before image hides only the new receiver. Printed lesson temporarily installed for capture; no physical headset or learner claim."
