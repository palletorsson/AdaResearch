extends "res://tools/probes/void_trace_site_probe.gd"

const BRUSHES := ["tube", "ribbon", "beads", "grid"]

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	await arrive(true)
	var content: Node3D = game.building.content
	if "--photos-only" in OS.get_cmdline_user_args():
		var subjects: Array[Node3D] = []
		for brush in BRUSHES: subjects.append(content.exhibits["4/paint-" + brush].get_node("Artifact"))
		game.place_player(Vector3(-16,-23.94,5.1));await frames(30)
		await hands_out()
		await sculpture_captures(subjects)
		await finish_room(true)
		FileAccess.open(out.path_join("capture-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed},"\t"))
		quit(0 if failed.is_empty() else 1)
		return
	check("The original plan vitrine is removed from Point Trace", not content.exhibits.has("4/museum-point_line_grid-7-15"))
	for item in content.data.floors[4].artifacts:
		if item.artifact != "trace_paint_box":
			check("Existing Trace work loads: " + str(item.id), content.exhibits.has("4/" + str(item.id)))
	game.place_player(Vector3(-16, -23.94, 5.1))
	await frames(30)
	await hands_out()
	var boxes: Array[Node3D] = []
	for brush in BRUSHES:
		var box: Node3D = content.exhibits["4/paint-" + brush].get_node("Artifact")
		boxes.append(box)
		await exercise_box(box)
	await two_hands(boxes[0], boxes[1])
	await lifecycle(boxes[0])
	await capacity(boxes[2])
	await sculpture_captures(boxes)
	await finish_room(true)
	# Desktop loading still presents empty, usable stations (no phantom ink).
	await arrive(false)
	for brush in BRUSHES:
		var box: Node3D = game.building.content.exhibits["4/paint-" + brush].get_node("Artifact")
		check("Desktop: " + brush + " starts empty", box.mark_count == 0)
		box.get_node("Clear").pressed.emit()
		check("Desktop: Clear works on an empty " + brush, box.strokes.is_empty())
	await finish_room(false)
	await frames(10)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"passed": failed.is_empty(), "checks": checks, "failed": failed,
		"scope": "Actual Point Trace floor, native Godot, synthetic XRServer poses driving XRController3D. Native museum screenshots; drawn gestures are test inputs, not prefilled production art. Physical headset not tested."
	}, "\t"))
	quit(0 if failed.is_empty() else 1)


func hands_out() -> void:
	hand_at(left, Vector3(-16.4, -22.6, 5.0))
	hand_at(right, Vector3(-15.8, -22.6, 5.0))
	await frames(3)


func put(controller: XRControllerTracker, box: Node3D, at: Vector3) -> void:
	hand_at(controller, box.to_global(at))
	await frames(3)


func exercise_box(box: Node3D) -> void:
	var tag: String = box.brush + ": "
	check(tag + "configuration applied before construction", box.brush in BRUSHES)
	check(tag + "starts with no invented drawing", box.mark_count == 0 and box.strokes.is_empty())
	var plinth: MeshInstance3D = box.get_node("Plinth")
	check(tag + "plinth measures 60 cm in all three dimensions", plinth.mesh.size.is_equal_approx(Vector3.ONE * 0.6))
	check(tag + "drawing box measures 60 x 60 x 140 cm", box.VOLUME.size.is_equal_approx(Vector3(0.6,1.4,0.6)) and is_equal_approx(box.VOLUME.position.y,0.6))
	check(tag + "plinth stands at floor level", is_equal_approx(box.global_position.y,-24))
	check(tag + "solid plinth", not ray(box.to_global(Vector3(0,0.3,0.65)),box.to_global(Vector3(0,0.3,0))).is_empty())
	check(tag + "hand can enter drawing volume without a glass collider", ray(box.to_global(Vector3(0,1.3,0.65)),box.to_global(Vector3(0,1.3,0))).is_empty())
	await put(right, box, Vector3(0,1.1,0.4))
	check(tag + "outside movement leaves no mark", box.mark_count == 0)
	await put(right, box, Vector3(-0.2,0.9,0))
	check(tag + "tracked hand alone starts drawing", box.mark_count == 1 and box.strokes.size() == 1)
	await frames(30)
	check(tag + "stationary hand does not duplicate samples", box.mark_count == 1)
	for i in range(1,9):
		await put(right, box, Vector3(-0.2 + i * 0.05,0.9 + i * 0.07,sin(i * 0.6) * 0.15))
	check(tag + "movement creates visible geometry", box.mark_count > 5 and box.get_node("Points").multimesh.visible_instance_count > 0)
	var original: Array = box.strokes[0].points.duplicate()
	var count: int = box.mark_count
	await hands_out()
	await frames(420)
	check(tag + "leaving keeps the drawing beyond the old timeout", box.mark_count == count and box.strokes[0].points == original and box._active.is_empty())
	var segments: int = box._segment_count
	await put(right, box, Vector3(0.23,1.7,0.18))
	check(tag + "re-entry starts a separate stroke without a connecting segment", box.strokes.size() == 2 and box._segment_count == segments)
	await put(right, box, Vector3(-0.299,1.999,-0.299))
	var contained := true
	var snapped := true
	for stroke in box.strokes:
		for p: Vector3 in stroke.points:
			contained = contained and box.VOLUME.grow(-0.025).has_point(p)
			if box.brush == "grid": snapped = snapped and p.is_equal_approx(p.snapped(Vector3.ONE * 0.05))
	check(tag + "paint thickness stays inside the volume", contained)
	if box.brush == "grid": check(tag + "points occupy the 5 cm lattice", snapped)
	if box.brush == "beads": check(tag + "beads stay separate", box._segment_count == 0 and box._dot_count == box.mark_count)
	if box.brush == "ribbon": check(tag + "ribbon has a flat rectangular cross-section", box._segments.mesh is BoxMesh and box._segments.mesh.size.x > box._segments.mesh.size.z * 10)
	await hands_out()
	box.get_node("Clear").pressed.emit()
	check(tag + "explicit Clear removes this box's geometry and records", box.mark_count == 0 and box.strokes.is_empty() and box._segments.visible_instance_count == 0 and box._dots.visible_instance_count == 0)


func two_hands(a: Node3D, b: Node3D) -> void:
	await put(left,a,Vector3(-0.15,1.1,0))
	await put(right,a,Vector3(0.15,1.5,0))
	check("Two hands create independent strokes in one box",a.strokes.size()==2 and a._active.size()==2)
	await put(left,a,Vector3(-0.1,1.2,0))
	check("Moving one hand does not extend the other's stroke",a.strokes[0].points.size()>1 and a.strokes[1].points.size()==1)
	await put(right,b,Vector3(0,1.2,0))
	check("Hands can draw in two boxes at once",a._active.size()==1 and b._active.size()==1)
	var before:int=b.mark_count
	a.get_node("Clear").pressed.emit()
	check("Clearing one box preserves its neighbour",b.mark_count==before)
	await hands_out()
	a.clear_paint()
	b.clear_paint()


func lifecycle(box: Node3D) -> void:
	await put(right,box,Vector3(-0.1,1.1,0))
	await put(right,box,Vector3(0,1.2,0))
	var count:int=box.mark_count
	right.invalidate_pose("aim")
	await frames(10)
	check("Loss of tracking ends recording and preserves ink",box.mark_count==count and box._active.is_empty())
	await put(right,box,Vector3(0.1,1.4,0))
	check("Tracking return cannot bridge the missing interval",box.strokes.size()==2 and box.strokes[1].points.size()==1)
	box.hide()
	await put(right,box,Vector3(-0.1,1.5,0))
	check("Hidden box records nothing",box.mark_count==count+1)
	box.show()
	await frames(3)
	check("Showing a box starts a fresh stroke",box.strokes.size()==3)
	await hands_out()
	var preserved:Array=box.strokes.duplicate(true)
	var pose:Transform3D=box.transform
	box.rotate_y(PI/4)
	check("Editing box rotation carries stored local art intact",box.strokes==preserved)
	await put(right,box,Vector3(0,1.7,0))
	check("Rotated box still tests its own local drawing volume",box.strokes.size()==preserved.size()+1)
	await hands_out()
	box.transform=pose
	preserved=box.strokes.duplicate(true)
	game.place_player(game.spawn_for(0));await frames(30)
	check("Leaving the floor sleeps the box and closes strokes",not box.can_process() and box._active.is_empty())
	game.place_player(Vector3(-16,-23.94,5.1));await frames(40)
	await hands_out()
	check("Returning to Trace retains the same artwork",box.strokes==preserved and box.can_process())
	box.clear_paint()


func capacity(box: Node3D) -> void:
	# Stress only: normal interaction above is driven by real XRController3D.
	for i in range(box.CAPACITY+20):
		box._sample(999,Vector3(-0.2 if i%2==0 else 0.2,1.2,0),Vector3.RIGHT)
	box._refresh_status()
	var preserved:Array=box.strokes[0].points.duplicate()
	check("Full box stops accepting paint instead of deleting old strokes",box.mark_count==box.CAPACITY and preserved.size()==box.CAPACITY)
	check("Capacity is visible to the visitor",box.get_node("Status").text.begins_with("FULL"))
	box._sample(999,Vector3(0,1.6,0),Vector3.RIGHT)
	check("Full box preserves its complete original record",box.strokes[0].points==preserved)
	box.get_node("Clear").pressed.emit()
	await put(right,box,Vector3(0,1.2,0))
	check("Explicit Clear makes a full box writable again",box.mark_count==1)
	await hands_out()
	box.clear_paint()


func sculpture_captures(boxes: Array[Node3D]) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	for box in boxes:
		box.clear_paint()
		for i in range(121):
			var t:=float(i)/120.0
			var angle:=t*TAU*2.5
			var p:=Vector3(cos(angle)*0.20,0.75+t*1.05,sin(angle)*0.20)
			await put(right,box,p)
		await hands_out()
	# Hide the test avatar and its incidental walking line for the photographs.
	game.place_player(Vector3(18,-23.94,7.5))
	await frames(15)
	game._set_enabled(false)
	var walking:Node3D=game.building.content.exhibits["4/museum-point_line_grid-1-9"].get_node("Artifact")
	if walking.has_method("clear_trail"): walking.clear_trail()
	for n in game.get_node("XROrigin3D").find_children("*","MeshInstance3D",true,false): n.hide()
	await photograph("paint-boxes.png",Vector3(-15.6,-22.5,6.1),Vector3(-15.6,-22.95,3.5))
	await photograph("paint-close.png",Vector3(-17.2,-22.6,5.5),Vector3(-17.2,-22.75,3.5))
	await photograph("paint-in-trace.png",Vector3(-9.5,-21.7,7.5),Vector3(-15.4,-23.0,3.5))
	for filename in ["paint-boxes.png","paint-close.png","paint-in-trace.png"]:
		check("Native museum screenshot: "+filename,FileAccess.file_exists(out.path_join(filename)))
