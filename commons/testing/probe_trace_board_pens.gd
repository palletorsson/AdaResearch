extends SceneTree
## Actual museum derivation/stamping; supplied grabber motion is not VR input.
var failures: Array[String] = []
var checks: int = 0

class SuppliedGrabber extends Node3D:
	var picked_up_ranged: bool = false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print(("PASS " if ok else "FAIL ") + message)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://ada_run/whiteboard_separation")
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	# Never enter the tree: the museum does not boot or write its live bake.
	var museum: Node = load("res://commons/scenes/endless_museum.tscn").instantiate()
	museum.set("_studio", true)
	museum.set("_headless", true)
	var row: Dictionary = museum.call("_derive_map_row", "Point_Trace")
	var pens: Array[Node3D] = []
	var board: Node3D
	for entry: Dictionary in row.get("artifacts", []):
		var token: String = entry.get("token", "")
		if token not in ["draw_dot", "whiteboard"]: continue
		var path := "res://commons/primitives/point/draw_dot.tscn" if token == "draw_dot" else "res://commons/artifacts/whiteboard/whiteboard.tscn"
		var cell: Array = entry["tile_cell"]
		var offset: Array = entry.get("offset", [0.0, 0.0, 0.0])
		var ok: bool = museum.call("_stamp", world, path, token,
			{"x": cell[0], "y": cell[1], "top": 0.0, "hover_m": offset[1]},
			0, 1, {}, false, 0.0, float(entry.get("rotation", 0)), entry.get("config", {}))
		check(ok, "museum stamps " + token)
	await process_frame
	await physics_frame
	for child in world.get_children():
		if child.get_meta("artifact_lookup_name", "") == "draw_dot": pens.append(child)
		if child.get_meta("artifact_lookup_name", "") == "whiteboard": board = child
	check(pens.size() == 4 and board != null, "four original dots and separate board instantiated")
	if pens.size() != 4 or board == null:
		museum.free()
		quit(1)
		return
	for dot in pens:
		check(dot.get_node_or_null("GrabPoint/PenDisplay") == null, "original dot appearance restored")
		check(dot.get("_data_panel") != null, "dot retains cased numeric display")
		check(dot.global_position.y > 0.9, "drawing dot back at plinth height")
	var drawing = board.get_node("DrawingTools")
	check(drawing.pens.size() == 5, "board has four independent pens and eraser")
	var grabber := SuppliedGrabber.new()
	world.add_child(grabber)
	var homes: Array[Transform3D] = []
	for i in range(5):
		var pen = drawing.pens[i]
		pen.set_process(false)
		homes.append(pen.transform)
		check(is_equal_approx(pen.global_position.y, 1.1) and pen.position.z > 0.4, "board tool hangs in reach before board")
		check(pen.resolution_mm == [0,10,40,80,0][i], "independent board resolution")
		grabber.global_position = pen.global_position
		pen.pick_up(grabber)
		check(pen.is_picked_up(), "board tool uses actual pickup callback")
		var before: int = drawing.stroke_events
		move_tool(pen, drawing, Vector3(0,0.6,0.2))
		pen.call("_process",0.02)
		check(drawing.stroke_events == before, "board tool leaves free air blank")
		move_tool(pen, drawing, Vector3(0.113,0.713,0.044))
		pen.call("_process",0.02)
		var pitch: float = pen.resolution_mm / 1000.0
		var xy := Vector2(0.113,0.113)
		if pitch > 0: xy = xy.snapped(Vector2.ONE * pitch)
		var expected := Vector2(xy.x / drawing.board_width + 0.5, 0.5 - xy.y / drawing.board_height)
		check(pen.get("_previous").is_equal_approx(expected), "contact quantizes in board coordinates")
		move_tool(pen, drawing, Vector3(0.2,0.7,0.3))
		pen.call("_process",0.02)
		check(pen.get("_previous").x < 0, "lifting breaks stroke")
		move_tool(pen, drawing, Vector3(2,0.7,0.044))
		pen.call("_process",0.02)
		check(pen.get("_previous").x < 0, "outside board cannot write")
		pen.let_go(grabber, Vector3.ZERO, Vector3.ZERO)
		check(not pen.is_picked_up() and pen.freeze, "release leaves tool suspended")
		pen.transform = homes[i]
	# The GPU canvas must be tested with a renderer; headless verifies interactions.
	if "--shot" in OS.get_cmdline_user_args():
		drawing.canvas.reset_canvas()
		drawing.canvas.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await rendered()
		var red = drawing.pens[1]
		red.pick_up(grabber)
		for x in [-0.4,-0.2]:
			move_tool(red, drawing, Vector3(x,0.8,0.044))
			red.call("_process",0.02)
		await rendered()
		check(pixel(drawing,Vector2(0.3125,1.0/3.0)).r > 0.7 and pixel(drawing,Vector2(0.3125,1.0/3.0)).g < 0.2, "real canvas receives red stroke")
		move_tool(red, drawing, Vector3(0,0.8,0.4))
		red.call("_process",0.02)
		move_tool(red, drawing, Vector3(0.2,0.8,0.044))
		red.call("_process",0.02)
		move_tool(red, drawing, Vector3(0.4,0.8,0.044))
		red.call("_process",0.02)
		red.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
		red.transform = homes[1]
		await rendered()
		check(pixel(drawing,Vector2(0.5,1.0/3.0)).g > 0.9, "lifted pen does not bridge gap")
		var blue = drawing.pens[3]
		blue.pick_up(grabber)
		for x in [-0.4,0.0,0.4]:
			move_tool(blue, drawing, Vector3(x,0.36,0.044))
			blue.call("_process",0.02)
		blue.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
		blue.transform = homes[3]
		await rendered()
		check(pixel(drawing,Vector2(0.5,0.7)).b > 0.7 and pixel(drawing,Vector2(0.5,0.7)).r < 0.2, "second pen paints blue")
		check(pixel(drawing,Vector2(0.3125,1.0/3.0)).g < 0.2, "earlier red ink survives a later stroke")
		var eraser = drawing.pens[4]
		eraser.pick_up(grabber)
		move_tool(eraser, drawing, Vector3(-0.3,0.8,0.044))
		eraser.call("_process",0.02)
		eraser.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
		eraser.transform = homes[4]
		await rendered()
		check(pixel(drawing,Vector2(0.3125,1.0/3.0)).g > 0.9, "eraser removes painted ink locally")
		check(pixel(drawing,Vector2(0.6875,1.0/3.0)).g < 0.2, "eraser preserves remote ink")
		board.rotate_y(0.15)
		board.position.x += 0.1
		check(drawing.sample_uv(drawing.to_global(Vector3(0,0.6,0.044)),0).is_equal_approx(Vector2(0.5,0.5)), "moved board keeps its local drawing frame")
		var camera := Camera3D.new()
		world.add_child(camera)
		var origin: Vector3 = drawing.to_global(Vector3(0,0.6,0.044))
		var normal: Vector3 = drawing.global_basis.z
		camera.global_position = origin + normal * 2.3 + drawing.global_basis.x * 0.15 + Vector3.UP * 0.08
		camera.look_at(origin)
		camera.current = true
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color(0.12,0.14,0.17)
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color.WHITE
		environment.environment.ambient_light_energy = 0.8
		world.add_child(environment)
		await rendered()
		root.get_texture().get_image().save_png("res://ada_run/whiteboard_separation/encounter.png")
	var report := {"checks":checks, "failures":failures, "scope":"Museum stamping, real pickup callbacks with supplied motion; GPU pixel checks when --shot. Headset usability unverified."}
	var file := FileAccess.open("res://ada_run/whiteboard_separation/checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print(JSON.stringify(report))
	museum.free()
	quit(0 if failures.is_empty() else 1)

func rendered() -> void:
	await process_frame
	await RenderingServer.frame_post_draw

func pixel(drawing: Node, uv: Vector2) -> Color:
	var img: Image = drawing.canvas.viewport.get_texture().get_image()
	return img.get_pixel(roundi(uv.x * img.get_width()),roundi(uv.y * img.get_height()))

func move_tool(pen: Node3D, drawing: Node3D, local_point: Vector3) -> void:
	pen.global_position = drawing.to_global(local_point) - pen.global_basis * pen.get_node("WritingTip").position
