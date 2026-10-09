extends "res://doc/book/iterations/2026-09-19-color-review/late/probes/base.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func run() -> void:
	await museum("Color_Paint")
	var painter: Node3D
	for n in current_scene.find_children("*", "Node3D", true, false):
		if n.get_script() and n.get_script().resource_path.ends_with("ball_painting_automation.gd"):
			painter = n
	check(painter != null, "actual museum contains the automated painter")
	if painter == null: quit(1); return
	var player: CharacterBody3D = current_scene.get("_player")
	var head: Camera3D = current_scene.get("_cam")
	player.set_physics_process(false)
	current_scene.get("_feel").set_process(false)
	player.global_position += painter.to_global(Vector3(0,1.2,4)) - head.global_position
	head.look_at(painter.to_global(Vector3(0,1.2,-0.5)))
	for frame in range(30):
		current_scene.call("_cull_artifacts")
		await process_frame
	var balls: Array = painter.get_node("PaintBalls").get_children()
	check(balls.size() == 30, "all thirty manual pigments remain")
	check(balls.all(func(b): return b.global_position.y >= 1.0 and b.global_position.y <= 1.4), "all pigment balls are within standing reach")
	check(balls.all(func(b): return b.get_node("BallPaintTip").painted_samples == 0), "unheld pigment balls have not painted")
	check(painter.surface.mesh.size == Vector2(4,2.5), "canvas has its actual rectangular proportions")
	var count_before: int = painter.strokes
	await create_timer(1.0).timeout
	check(painter.strokes > count_before, "automatic marks arrive before a pickup")
	check(painter.surface.brush_layer != null and painter.surface.wet_paint, "automatic painter uses the wet canvas")
	# A second canvas deliberately supplies a wrong cached receiver.
	var decoy: Node3D = load("res://commons/context/drawingboard/ball_painting_demo_v2.tscn").instantiate()
	decoy.get_node("PaintBalls").ball_count = 0
	for name in ["Camera3D","WorldEnvironment","DirectionalLight3D"]:
		var child: Node = decoy.get_node(name)
		decoy.remove_child(child)
		child.free()
	decoy.position = Vector3(100,100,100)
	current_scene.add_child(decoy)
	var ball: Node3D = balls[0]
	var tip: Node3D = ball.get_node("BallPaintTip")
	tip.brush_size = 16
	tip.snap_grid_size = 64
	tip.paper_surface = decoy.surface
	var grabber := SuppliedGrabber.new()
	current_scene.add_child(grabber)
	grabber.global_transform = ball.global_transform
	ball.pick_up(grabber)
	var start_strokes: int = painter.strokes
	for step in range(12):
		var uv := Vector2(0.08 + step * 0.015,0.10)
		var hit: Vector3 = painter.surface.to_global(Vector3((uv.x-0.5)*4,0,(uv.y-0.5)*2.5))
		grabber.global_position = hit + painter.surface.global_basis.y * 0.6
		grabber.look_at(hit,Vector3.UP)
		for frame in range(3): await physics_frame
	check(tip.painted_samples > 0, "held pigment paints through a real area ray hit")
	check(tip.paper_surface == painter.surface, "hit canvas replaces an incorrect cached receiver")
	check(painter.strokes > start_strokes, "automatic painter continues during the manual gesture")
	check(absf(tip.last_uv_position.y-0.10) < 0.02, "manual mapping uses the 2.5 metre canvas height")
	var manual_count: int = tip.painted_samples
	ball.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	for frame in range(12): await physics_frame
	check(tip.painted_samples == manual_count, "manual marks stop after release")
	check(ball.global_transform.is_equal_approx(ball._paint_home), "released pigment returns to its own tray position")
	# Inspect actual GPU output: retained pigment after input has stopped.
	await RenderingServer.frame_post_draw
	var canvas: Image = painter.surface.viewport.get_texture().get_image()
	var coloured := 0
	for y in range(100,160,4):
		for x in range(160,500,4):
			var c := canvas.get_pixel(x,y)
			if c.r > c.g+0.1: coloured += 1
	check(coloured > 5, "manual red pigment remains in the rendered canvas after release")
	decoy.queue_free()
	await create_timer(1.0).timeout
	var ray := PhysicsRayQueryParameters3D.create(head.global_position,painter.surface.global_position,1,[player.get_rid()])
	var hit_info: Dictionary = current_scene.get_world_3d().direct_space_state.intersect_ray(ray)
	print("VIEW painter=",painter.global_position," head=",head.global_position," surface=",painter.surface.global_position," hit=",hit_info.get("collider"))
	if hit_info.has("collider"): print("VIEW_COLLIDER ",hit_info.collider.get_path())
	check(hit_info.is_empty(), "canvas is visible from the visitor approach")
	var body_query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.5
	body_query.shape = capsule
	body_query.collision_mask = 1
	body_query.exclude = [player.get_rid()]
	body_query.transform.origin = painter.to_global(Vector3(0,0.35,3.5))
	# Stop in front of the physical tray, within arm reach of its pigments.
	body_query.motion = painter.global_basis * Vector3(0,0,-1.5)
	check(current_scene.get_world_3d().direct_space_state.cast_motion(body_query)[0] > 0.99, "a body can approach the pigment tray")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"paint_encounter_museum.png")
	var report := {"checks":checks,"failures":failures,"headset_tested":false,"input":"Supplied grabber moves a real pigment ball; ray hits, surface targeting, automatic/manual writes and rendered pigment checked. Tracked hands untested."}
	var f := FileAccess.open(OUT+"probe_paint_encounter.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print("PAINT_ENCOUNTER ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
