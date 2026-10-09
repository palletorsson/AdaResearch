extends SceneTree

const OUT := "res://doc/space/random-gallery-2026-09-16/"
const HALL := "Randomness_Examples_of_Randomness"
const WANTED := ["pollock_painting_in_3d", "monte_carlo_dartboard", "pipe_dream", "extreme_randomness"]
var checks: Array = []
var failures: Array[String] = []
var evidence: Array = []
var mode_samples: Array = []
var origin := Vector3.ZERO

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks.append({"check": message, "passed": ok})
	if not ok: failures.append(message)

func vec(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func visual_bounds(node: Node3D) -> AABB:
	var box := AABB()
	var count := 0
	var items: Array = node.find_children("*", "VisualInstance3D", true, false)
	if node is VisualInstance3D: items.append(node)
	for item in items:
		if not item.is_visible_in_tree() or not item.has_method("get_aabb"): continue
		# Lights expose an influence AABB; it is not rendered pipe geometry.
		if not (item is MeshInstance3D or item is MultiMeshInstance3D or item is CSGShape3D or item is SpriteBase3D or item is Label3D): continue
		if item is MeshInstance3D and item.mesh == null: continue
		var item_box: AABB = item.global_transform * item.get_aabb()
		if item_box.size.length_squared() <= 0.0000001: continue
		box = item_box if count == 0 else box.merge(item_box)
		count += 1
	return box

func as_local_box(box: AABB) -> Dictionary:
	return {"min": vec(box.position-origin), "max": vec(box.end-origin), "size": vec(box.size)}

func particle_bounds(particles: Node3D) -> AABB:
	var box := AABB()
	var count := 0
	for particle in particles.particles:
		var radius: float = float(particle.radius)
		var local_box := AABB(-Vector3.ONE*radius, Vector3.ONE*radius*2.0)
		var b: AABB = particle.global_transform * local_box
		box = b if count == 0 else box.merge(b)
		count += 1
	return box

func inside_room(box: AABB) -> bool:
	var a := box.position-origin
	var b := box.end-origin
	return a.x >= 0.5 and b.x <= 13.5 and a.z >= 0.5 and b.z <= 23.5 and a.y >= -0.03

func xz_overlap(a: AABB, b: AABB) -> bool:
	return a.position.x < b.end.x and a.end.x > b.position.x and a.position.z < b.end.z and a.end.z > b.position.z

func press(console: Node3D, id: int) -> void:
	var button: Node = console.find_child("Btn_%d" % id, true, false)
	if button == null:
		check(false, "Console button %d exists" % id)
		return
	button.get_node("InteractableAreaButton").emit_signal("button_pressed", button)

func capture(em: Node3D, from: Vector3, target: Vector3, suffix: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	# Copy the walker's installed optics. Its feel/controller module owns the real
	# camera transform, so a temporary camera isolates only position, never lighting.
	var walker_camera: Camera3D = em.get("_cam")
	var camera := Camera3D.new()
	camera.attributes = walker_camera.attributes
	camera.environment = walker_camera.environment
	camera.fov = walker_camera.fov
	camera.near = walker_camera.near
	camera.far = walker_camera.far
	em.add_child(camera)
	em.set("_cam", camera)
	em.set_process(false)
	em.set_physics_process(false)
	camera.global_position = origin+from
	camera.look_at(origin+target)
	camera.make_current()
	await create_timer(3.5).timeout
	for frame in range(45):
		camera.make_current()
		await process_frame
	await RenderingServer.frame_post_draw
	check(camera.global_position.distance_to(origin+from) < 0.01, "Museum "+suffix+" camera stays at the requested 1.7 m eye position")
	var err: int = root.get_texture().get_image().save_png(OUT+"museum-"+suffix+".png")
	check(err == OK, "Saved museum "+suffix+" screenshot")
	em.set("_cam", walker_camera)
	walker_camera.make_current()
	camera.queue_free()

func run() -> void:
	var ctl := OUT+"museum-control.json"
	var file := FileAccess.open(ctl, FileAccess.WRITE)
	file.store_string(JSON.stringify({"first_chapter":"randomness", "dollhouse":0, "grid_pack":1}))
	file.close()
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", ctl)
	em.set("_overrides_path", ctl+".unused")
	em.set("_hand_path", ctl+".unused-hand")
	em.set("start_chapter", "randomness")
	em.set("start_map", HALL)
	root.add_child(em)
	current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false)
	em.set_physics_process(false)
	em.call("flush_stamps")
	var player: Node3D = em.get("_player")
	if player != null:
		player.set_process(false)
		player.set_physics_process(false)
		player.global_position.y += 30.0
	var seg: Node3D
	for record: Dictionary in em.get("_segments"):
		if record.node.get_meta("em_map", "") == HALL:
			seg = record.node
			break
	if seg == null:
		check(false, "Actual museum built the recovered map segment")
		finish()
		return
	var found: Dictionary = {}
	for retry in range(100):
		for node in seg.find_children("*", "Node3D", true, false):
			var key: String = node.get_meta("artifact_lookup_name", "")
			if key in WANTED: found[key] = node
		if found.size() == WANTED.size(): break
		await create_timer(0.1).timeout
	for key in WANTED:
		var count := 0
		for node in seg.find_children("*", "Node3D", true, false):
			if node.get_meta("artifact_lookup_name", "") == key: count += 1
		check(count == 1, "%s is present exactly once: %d" % [key, count])
	if found.size() != WANTED.size():
		finish()
		return
	var painting: Node3D = found.pollock_painting_in_3d
	var monte: Node3D = found.monte_carlo_dartboard
	var pipe: Node3D = found.pipe_dream
	var particles: Node3D = found.extreme_randomness
	origin = painting.global_position-Vector3(7, 0, 6)
	origin.y = seg.global_position.y
	for node in found.values():
		node.process_mode = Node.PROCESS_MODE_ALWAYS
		node.show()
	await create_timer(0.5).timeout
	var painter: Node = painting.get_node("SubViewport/PollockPainting2D")
	var paint_start: PackedByteArray = painter.canvas.get_data()
	check(painting.support == "floor", "Pollock uses its original floor support")
	check(painting.get_node("Sprite3D").visible, "Pollock canvas sprite is visible")
	check(paint_start.size() > 100000, "Pollock has a populated image backing its live texture")
	var console: Node3D = monte.find_child("ReachConsole", true, false)
	check(console != null, "Monte Carlo has a compact museum console")
	if console != null:
		var mark: Node3D = console.get_node("StandingPosition")
		var shoulder := mark.global_position+Vector3(0, 1.25, 0)
		var button_count := 0
		for button in console.find_children("Btn_*", "Node3D", true, false):
			button_count += 1
			check(shoulder.distance_to(button.global_position) <= 0.8, str(button.name)+" is within 0.8 m of standing mark")
			var y: float = button.global_position.y-origin.y
			check(y >= 0.8 and y <= 1.5, str(button.name)+" is at hand height")
		check(button_count == 3, "Console retains exactly three buttons")
		if monte.auto_throw: press(console, 1)
		check(not monte.auto_throw, "AUTO pauses generated darts")
		press(console, 2)
		check(monte._total_count == 0 and monte._inside_count == 0, "RESET clears both counters through original signal")
		press(console, 0)
		check(monte._total_count == 1, "THROW adds one sample through original signal")
		press(console, 1)
		check(monte.auto_throw, "AUTO resumes generated darts")
		await create_timer(0.6).timeout
		press(console, 1)
		check(monte._total_count > 1, "AUTO advances sample count")
		press(console, 2)
		check(monte._total_count == 0, "RESET still works after AUTO")
		for i in range(80): press(console, 0)
	var floor_points := [Vector2(7,0),Vector2(7,24),Vector2(3,6),Vector2(11,6),Vector2(1,12),Vector2(13,12),Vector2(7,15),Vector2(10,20)]
	for p in floor_points:
		var from := origin+Vector3(p.x, 0.4, p.y)
		var hit := em.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from-Vector3(0,1.5,0)))
		check(not hit.is_empty(), "Entrance, exit or bypass floor supported at "+str(p))
	await capture(em, Vector3(7,1.7,2.6),Vector3(7,0.1,6),"arrival")
	var modes_seen: Dictionary = {}
	var sampled_bounds := AABB()
	for second in range(53):
		await create_timer(1.0).timeout
		var mode: int = particles.current_demo
		modes_seen[mode] = true
		var pb := particle_bounds(particles)
		sampled_bounds = pb if second == 0 else sampled_bounds.merge(pb)
		mode_samples.append({"second":second, "mode":mode, "bounds":as_local_box(pb)})
		check(inside_room(pb), "Particle mode %d stays in room and above floor at t=%d" % [mode,second])
		for key in ["pollock_painting_in_3d", "monte_carlo_dartboard", "pipe_dream"]:
			check(not xz_overlap(pb, visual_bounds(found[key])), "Particle mode %d does not overlap %s at t=%d" % [mode,key,second])
		if second == 10:
			check(painter.canvas.get_data() != paint_start, "Pollock live image adds paint while the museum runs")
		if second == 45:
			await capture(em, Vector3(7,1.7,4.3),Vector3(7,0.02,6),"painting")
		if second == 20:
			var mature := visual_bounds(pipe)
			check(pipe.segment_count == pipe.max_segments, "Pipe reaches its authored 180-segment limit")
			check(inside_room(mature), "Mature pipe geometry stays above floor and inside its bay")
			check(mature.size.x <= 3.2 and mature.size.y <= 2.2 and mature.size.z <= 3.2, "Mature pipe bounds fit the scaled authored volume")
			check(is_finite(mature.position.x) and is_finite(mature.position.y) and is_finite(mature.position.z), "Mature pipe has finite bounds")
			await capture(em, Vector3(7,1.7,10),Vector3(7,1.2,17),"gallery")
	check(modes_seen.size() == 5, "All five particle chapters cycle in the actual museum")
	check(particles.chapter == "all", "Particle chapter remains all")
	check(is_equal_approx(float(particles.gallery_radius),7.0), "Gallery opts into its declared radius-seven containment")
	for key in found:
		var node: Node3D = found[key]
		evidence.append({"lookup":key, "position":vec(node.global_position-origin), "yaw":node.global_rotation_degrees.y, "scale":vec(node.scale), "bounds":as_local_box(visual_bounds(node))})
	for a in range(WANTED.size()):
		for b in range(a+1, WANTED.size()):
			check(not xz_overlap(visual_bounds(found[WANTED[a]]),visual_bounds(found[WANTED[b]])), "%s and %s have separate visible bounds" % [WANTED[a],WANTED[b]])
	finish({"origin":vec(origin), "particle_union":as_local_box(sampled_bounds)})

func finish(extra: Dictionary = {}) -> void:
	var result := {"map":HALL, "artifacts":evidence, "checks":checks, "failures":failures, "particle_samples":mode_samples, "headset_verified":false}
	result.merge(extra)
	var file := FileAccess.open(OUT+"museum-runtime.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	file.close()
	print("[random-gallery-museum] checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
