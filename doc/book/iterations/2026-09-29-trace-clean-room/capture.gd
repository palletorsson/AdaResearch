extends "res://tools/probes/transformation_encounters.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.0).timeout
	var pens: Array[Node3D] = []
	for node in hall.find_children("*", "Node3D", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("/point/draw_dot.gd"):
			pens.append(node)
	check("three collection pens remain", pens.size() == 3)
	check("desk removed", find_scene("/automatic_writing_desk.gd") == null)
	check("head projection removed", find_scene("/head_trace_projection.gd") == null)
	if pens.size() != 3: return
	pens.sort_custom(func(a,b): return a.global_position.x < b.global_position.x)
	var middle := Vector3.ZERO
	for pen in pens:
		var panel: Node3D = pen.get("_data_panel")
		var shell: MeshInstance3D = panel.get_node("Casing/Shell")
		var bounds := shell.global_transform * shell.get_aabb()
		var seat: Vector3 = pen.get("_data_mount_surface")
		check("readout seated and on: " + str(pen.name), panel.visible and absf(bounds.position.y-seat.y)<.005)
		check("plain pen replaces held sphere", pen.get_node_or_null("GrabPoint/Barrel") != null and pen.get_node_or_null("GrabPoint/MeshInstance3D") == null)
		check("nib supplies trace position", pen.get("_draw_sphere") == pen.get_node("GrabPoint/WritingTip"))
		middle += panel.global_position
	middle /= pens.size()
	var board := find_scene("/whiteboard.gd")
	check("whiteboard exists", board != null)
	if board == null: return
	observations["board_position"] = xyz(board.global_position)
	observations["board_normal"] = xyz(board.global_basis.z)
	# Shoot behind both ends as well as the centre. All must hit the wall,
	# without using the board's own drawing collider as supporting evidence.
	observations["wall_support"] = []
	for x in [-.9, 0.0, .9]:
		var from := board.to_global(Vector3(x,.6,.20))
		var to := board.to_global(Vector3(x,.6,-.9))
		var hit := hall.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
		check("solid wall behind board at " + str(x), not hit.is_empty())
		observations.wall_support.append({"x":x,"hit":xyz(hit.position) if not hit.is_empty() else [],"from":xyz(from)})
	await snapshot("clean-hall",Vector3(4.5,1.7,1.4),Vector3(4.5,1.2,5.5),68)
	await snapshot("three-pens",middle+Vector3(0,.55,-2.9),middle,55)
	var pen_root: Node3D = pens[0].get("_grab_point")
	await snapshot("plain-pen",pen_root.global_position+Vector3(.30,.22,-.48),pen_root.global_position+Vector3(0,.04,0),40)
	var grip := SuppliedGrabber.new()
	root.add_child(grip)
	var recorder: Node3D = pens[0]
	var pen: Node3D = recorder.get("_grab_point")
	var home := pen.global_transform
	recorder.set_process(false)
	pen.pick_up(grip)
	for angle in [0.0, PI*.63]:
		grip.global_transform = Transform3D(Basis(Vector3.UP,angle),home.origin+Vector3(0,.25,-.4))
		await tick(); await tick()
		check("held nib follows forward at " + str(angle), (-pen.global_basis.z).dot(-grip.global_basis.z)>.999)
		check("pickup uses authored grip",pen.get_active_grab_point() == pen.get_node("WritingGrip"))
	grip.global_basis = Basis.IDENTITY
	await tick()
	recorder.clear_trail()
	for i in range(12):
		grip.global_position = home.origin + Vector3(sin(i*.45)*.18,.28+cos(i*.45)*.13,-.25)
		await tick()
		recorder.call("_process",.04)
	check("held pen records nib samples",recorder.get("_trail_points").size()>5)
	var sample: Vector3 = recorder.get("_trail_points").back()
	check("sample follows nib rather than hand centre",sample.distance_to(pen.get_node("WritingTip").global_position)<.011 and sample.distance_to(pen.global_position)>.1)
	var trace_data := root.get_node_or_null("TraceData")
	pen.let_go(grip,Vector3.ZERO,Vector3.ZERO)
	var count: int = recorder.get("_trail_points").size()
	pen.global_transform=home
	recorder.call("_process",.04)
	check("released pen stops recording",recorder.get("_trail_points").size()==count)
	recorder.set_process(true)
	observations["trace_count"] = count
	observations["trace_store_present"] = trace_data != null
	var drawing: Node3D = board.get_node("DrawingTools")
	check("four board pens and eraser retained",drawing.pens.size()==5)
	for item in drawing.pens:
		if not item.eraser:
			check("board barrel is simple",item.get_node_or_null("Barrel")!=null and item.get_node_or_null("SculpturalGrip")==null)
	var marker: Node3D = drawing.pens[1]
	var marker_home := marker.global_transform
	marker.set_process(false)
	marker.pick_up(grip)
	grip.global_basis = Basis.looking_at(-board.global_basis.z,Vector3.UP)
	await tick()
	var events: int = drawing.stroke_events
	for x in [-.5,-.3,-.1]:
		await board_contact(grip,marker,board.to_global(Vector3(x,.72,.044)))
	check("aligned nib writes on board",drawing.stroke_events>events)
	await board_contact(grip,marker,board.to_global(Vector3(.1,.72,.20)))
	check("lifting breaks board stroke",marker.get("_previous").x < 0)
	for x in [.3,.5]:
		await board_contact(grip,marker,board.to_global(Vector3(x,.72,.044)))
	marker.let_go(grip,Vector3.ZERO,Vector3.ZERO)
	marker.return_to_shelf()
	check("board pen returns to its shelf pose",marker.global_transform.is_equal_approx(marker_home))
	marker.set_process(true)
	await snapshot("wall-board",board.to_global(Vector3(-.8,1.0,2.5)),board.to_global(Vector3(0,.60,0)),60)
	var pixels: Image = drawing.canvas.viewport.get_texture().get_image()
	observations["canvas_debug"] = {"events":drawing.stroke_events,"size":str(pixels.get_size())}
	var white := pixels.get_pixel(roundi(pixels.get_width()*.5),roundi(pixels.get_height()*.4))
	var red := pixels.get_pixel(roundi(pixels.get_width()*.35),roundi(pixels.get_height()*.4))
	check("board ground and lifted gap stay white",white.r>.9 and white.g>.9 and white.b>.9)
	check("actual canvas retains red ink",red.r>.5 and red.g<.3 and red.b<.3)
	await snapshot("board-pens",board.to_global(Vector3(-.25,.35,1.0)),board.to_global(Vector3(0,.08,.22)),55)
	var eraser: Node3D = drawing.pens[4]
	eraser.set_process(false)
	eraser.pick_up(grip)
	await board_contact(grip,eraser,board.to_global(Vector3(-.3,.72,.044)))
	await process_frame
	await RenderingServer.frame_post_draw
	pixels = drawing.canvas.viewport.get_texture().get_image()
	var erased := pixels.get_pixel(roundi(pixels.get_width()*.35),roundi(pixels.get_height()*.4))
	check("eraser removes existing marker ink",erased.r>.9 and erased.g>.9 and erased.b>.9)
	eraser.let_go(grip,Vector3.ZERO,Vector3.ZERO)
	eraser.return_to_shelf()
	eraser.set_process(true)
	drawing.canvas.reset_canvas()
	await process_frame
	await RenderingServer.frame_post_draw
	pixels = drawing.canvas.viewport.get_texture().get_image()
	var cleared := pixels.get_pixel(roundi(pixels.get_width()*.7),roundi(pixels.get_height()*.4))
	check("reset clears the retained image",cleared.r>.9 and cleared.g>.9 and cleared.b>.9)
	var default_dot: Node3D = load("res://commons/primitives/point/draw_dot.tscn").instantiate()
	root.add_child(default_dot)
	check("other dot placements retain their sphere",default_dot.get_node_or_null("GrabPoint/MeshInstance3D")!=null and default_dot.get_node_or_null("GrabPoint/Barrel")==null)
	default_dot.queue_free()
	grip.queue_free()
	observations["capture_complete"] = true

func board_contact(grip: Node3D, pen: Node3D, world_nib: Vector3) -> void:
	# Pens have a fixed frame; the eraser retains its pickup offset. Move the
	# actual contact point in both cases rather than assuming an identity grip.
	await tick()
	grip.global_position += world_nib - pen.get_node("WritingTip").global_position
	await tick()
	pen.call("_process",.03)
	await RenderingServer.frame_post_draw

func finish() -> void:
	if not bool(observations.get("capture_complete",false)): failures.append("Capture did not finish")
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"observations":observations,"failures":failures,"passed":failures.is_empty(),"scope":"Actual museum with supplied pickup transforms and drawing gestures; no headset comfort trial."},"  "))
	quit(0 if failures.is_empty() else 1)
