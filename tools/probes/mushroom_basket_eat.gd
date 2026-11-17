extends SceneTree
## The mushroom basket on floor 104, as the visitor meets it: standing in front of it, looking at it through the
## game's own camera. Eats one mushroom (through its own eat(), what the mouth and the trigger call) and measures
## what the eyes then show against what they showed before; waits for the effect to go; checks the basket grew it
## back. THE NEGATIVE: before anything is eaten the picture does not change between two frames.
##
##   godot --path . --xr-mode off --script res://tools/probes/mushroom_basket_eat.gd -- --void-start-floor=104 --out=<dir>

var game: Node
var folder := "res://ada_run/mushroom_basket"
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("mushroom.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()


func _picture(name: String) -> Image:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(folder.path_join(name))
	return image


# mean absolute difference of two pictures, 0..1, on a coarse grid
static func _differ(a: Image, b: Image) -> float:
	var x := a.duplicate() as Image
	var y := b.duplicate() as Image
	x.resize(160, 100, Image.INTERPOLATE_BILINEAR)
	y.resize(160, 100, Image.INTERPOLATE_BILINEAR)
	var total := 0.0
	for j in 100:
		for i in 160:
			var p := x.get_pixel(i, j)
			var q := y.get_pixel(i, j)
			total += (absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)) / 3.0
	return total / 16000.0


func _wait(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		await process_frame
		t += root.get_process_delta_time()


func run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): folder = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var mount: Node3D = null
	for i in 900:
		mount = game.building.content.exhibits.get(str(floor) + "/mushroom-basket")
		if mount != null: break
		await physics_frame
	var checks := []
	result = {"floor": floor, "checks": checks, "passed": false}
	var basket: Node = null
	if mount != null:
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("regrow"):
				basket = n
				break
	var tree := []
	if mount != null:
		for n in [mount] + mount.find_children("*", "", true, false).slice(0, 12): tree.append("%s:%s:%s" % [n.name, n.get_class(), str(n.get_script().resource_path) if n.get_script() != null else ""])
	checks.append({"check": "the basket stands on its floor, with twelve mushrooms", "ok": basket != null and (basket.get("grown") as Dictionary).size() == 12,
		"at": mount.global_position if mount != null else null, "tree": tree})
	if basket == null:
		_save(); quit(1); return
	for canvas in root.find_children("*", "CanvasLayer", true, false):
		if canvas.get_viewport() == root: canvas.hide()
	var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
	var front: Vector3 = mount.global_position + mount.global_basis.z * 1.3
	game.place_player(Vector3(front.x, level + 0.3, front.z))
	for i in 60: await physics_frame
	var eye := root.get_viewport().get_camera_3d()
	var flat := Vector3(mount.global_position.x - eye.global_position.x, 0, mount.global_position.z - eye.global_position.z)
	game.body.rotation.y = atan2(-flat.x, -flat.z) - (eye.global_rotation.y - game.body.global_rotation.y)
	for i in 30: await physics_frame
	var parts := []
	for n in basket.find_children("*", "VisualInstance3D", true, false):
		if (n as VisualInstance3D).is_visible_in_tree(): parts.append(n)
	var seen := 0
	for n in parts:
		if (n as VisualInstance3D).layers & eye.cull_mask != 0: seen += 1
	var plain1 := await _picture("before.png")
	await _wait(0.5)
	var plain2 := await _picture("before_2.png")
	var still := _differ(plain1, plain2)
	checks.append({"check": "the visitor's own camera sees the basket (every drawn part on a layer it shows); THE NEGATIVE: nothing eaten, two frames half a second apart are the same picture",
		"ok": parts.size() > 20 and seen == parts.size() and still < 0.004, "parts": parts.size(), "seen": seen, "difference_while_nothing_eaten": snappedf(still, 0.0001)})
	_save()
	# eat one of each kind in turn; look at the third second (the rise is done)
	var one: Node = (basket.get("grown") as Dictionary)[0]
	var kind: int = one.get("kind")
	one.call("eat")
	await _wait(3.5)
	var trip: Node = eye.get_node_or_null("MushroomTrip")
	var during := await _picture("eaten.png")
	var changed := _differ(plain1, during)
	var state: Dictionary = trip.call("state") if trip != null else {}
	checks.append({"check": "one eaten: the eyes show the room through its operation (the picture differs from before) and the mushroom is gone from the basket",
		"ok": trip != null and int(state.get("mode", -1)) == kind and bool(state.get("effect_enabled", false)) and changed > 0.01 and not (basket.get("grown") as Dictionary).has(0),
		"trip": state, "difference_from_before": snappedf(changed, 0.0001)})
	_save()
	var others := []
	for spot in [1, 2, 3, 4, 5]:
		var m: Node = (basket.get("grown") as Dictionary)[spot]
		var its_kind := int(m.get("kind"))
		m.call("eat")
		await _wait(3.5)
		var image := await _picture("eaten_%d.png" % spot)
		others.append({"kind": its_kind, "title": str(trip.call("state").title), "difference_from_before": snappedf(_differ(plain1, image), 0.0001)})
	checks.append({"check": "each of the six kinds puts its own operation in the eyes and each changes the picture", "ok": others.all(func(o): return o.difference_from_before > 0.01),
		"kinds": others})
	_save()
	var waited := 0.0
	while waited < 40.0 and int(trip.call("state").mode) >= 0:
		await _wait(1.0)
		waited += 1.0
	var after := await _picture("after.png")
	var back := _differ(plain1, after)
	checks.append({"check": "the effect goes again: it fades from 10 s after the last one and is off by 15 s, the eyes showing the room as before",
		"ok": int(trip.call("state").mode) == -1 and not bool(trip.call("state").effect_enabled) and back < 0.01 and waited <= 13.0, "gone_after_s": waited, "difference_from_before": snappedf(back, 0.0001)})
	_save()
	var regrow_wait := 0.0
	while regrow_wait < 25.0 and (basket.get("grown") as Dictionary).size() < 12:
		await _wait(1.0)
		regrow_wait += 1.0
	checks.append({"check": "the eaten mushrooms grow back in their places (20 s after each is eaten)", "ok": (basket.get("grown") as Dictionary).size() == 12,
		"grown": (basket.get("grown") as Dictionary).size(), "waited_more_s": regrow_wait})
	result["passed"] = checks.all(func(c): return c.ok)
	_save()
	print("[mushroom_basket_eat] ", "PASSED" if result.passed else "FAILED")
	quit(0 if result.passed else 1)
