extends SceneTree
## Tutorial_Disco, floor 27 of the main tower as it is today: the step sequencer "f2_step_sequencer_3_5", from
## where a visitor stands in front of it at eye height. The last song of act one says "This cell is silent."
## and the act ends on "A silent cell is still a place." What does the floor give the eye for that?
##
## Takes the view as placed, then writes a kick on every fourth step (what a visitor's four clicks would do)
## and poses the playhead on a step with a hit and on two silent steps. Measures how much of the picture
## inside the screen changes when the clock moves from one silent step to the next.
##
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/disco_silent_cell.gd -- \
##       --void-start-floor=27 --no-opening --opera-quiet --out=<dir> [--back=<m>] [--read-column] [--as-placed]
##
## --read-column turns the ring on for this run whatever the floor says; --as-placed writes no hits, so the
## pattern is the one the floor arrives with.
##
## <dir>/disco_silent_cell.json, as_placed.png, on_a_hit.png, on_a_rest.png, on_the_next_rest.png

var game: Node
var folder := "res://ada_run/disco_silent_cell"
var result := {}
var eye: Camera3D
var work: Node3D
var back := 0.9
var ring := false
var write_hits := true


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("disco_silent_cell.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()


func _frame(label: String, at: Vector3, aim: Vector3) -> Image:
	eye.global_position = at
	eye.look_at(aim, Vector3.UP)
	for i in 14: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if label != "": image.save_png(folder.path_join(label + ".png"))
	return image


func _changed(a: Image, b: Image, box: Rect2) -> Dictionary:
	var inside := 0
	var changed := 0
	for y in range(maxi(0, int(box.position.y)), mini(a.get_height(), int(box.end.y) + 1)):
		for x in range(maxi(0, int(box.position.x)), mini(a.get_width(), int(box.end.x) + 1)):
			inside += 1
			var p := a.get_pixel(x, y)
			var q := b.get_pixel(x, y)
			if absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.03: changed += 1
	return {"pixels_of_screen": inside, "pixels_changed": changed, "share_changed": snappedf(float(changed) / maxf(1.0, float(inside)), 0.0001)}


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--back="): back = float(arg.trim_prefix("--back="))
		if arg == "--read-column": ring = true
		if arg == "--as-placed": write_hits = false
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var checks := []
	result = {"floor": int(game.checkpoint), "map": "Tutorial_Disco", "window": str(root.size), "checks": checks, "passed": false}
	var key := "%d/f2_step_sequencer_3_5" % int(game.checkpoint)
	for i in 2400:
		await physics_frame
		var mount: Variant = game.building.content.exhibits.get(key)
		if mount is Node and (mount as Node).get_node_or_null("Artifact") != null and i > 240:
			work = (mount as Node).get_node("Artifact")
			break
	if work == null or work.get("_sequencer_ui") == null:
		checks.append({"check": "the step sequencer stands on this floor with its display", "ok": false, "looked_for": key})
		_save(); quit(1); return
	var ui: Control = work.get("_sequencer_ui")
	var screen: Node3D = work.get_node("Viewport2Din3D")
	var size: Vector2 = screen.get("screen_size")
	var centre: Vector3 = screen.global_position
	var out: Vector3 = (screen.global_transform.basis * Vector3(0, 0, 1)).normalized()
	var wide: float = size.x * screen.global_transform.basis.x.length()
	var high: float = size.y * screen.global_transform.basis.y.length()
	var steps := int(work.get("num_steps"))
	var tracks := int(work.get("num_tracks"))
	var lit := 0
	for t in tracks:
		for s in steps: lit += int(ui.call("get_cell", t, s))
	result["as_placed"] = {"playing": bool(work.get("_is_playing")), "cells": tracks * steps, "cells_holding_a_hit": lit, "bpm": float(work.get("bpm")),
		"screen_m": [snappedf(wide, 0.001), snappedf(high, 0.001)], "screen_centre_height_m": snappedf(centre.y - (game.building.global_position.y - 6.0 * float(game.checkpoint)), 0.01),
		"one_step_is_wide_m": snappedf(wide * 28.0 / 800.0, 0.0001), "config": work.get_meta("config", {})}
	var stance := centre + out * back
	game.place_player(Vector3(stance.x, centre.y - 1.2, stance.z), atan2(out.x, out.z))
	for i in 120: await physics_frame
	eye = root.get_camera_3d()
	var standing := eye.global_position
	game.body.set_physics_process(false)
	game.body.set_process(false)
	work.set_process(false)
	await _frame("", standing, centre)
	await _frame("as_placed", standing, centre)
	var corners := PackedVector2Array()
	for c in [Vector3(-0.5, -0.5, 0), Vector3(0.5, -0.5, 0), Vector3(0.5, 0.5, 0), Vector3(-0.5, 0.5, 0)]:
		corners.append(eye.unproject_position(centre + screen.global_transform.basis.x.normalized() * c.x * wide + screen.global_transform.basis.y.normalized() * c.y * high))
	var box := Rect2(corners[0], Vector2.ZERO)
	for p in corners: box = box.expand(p)
	result["from_the_stance"] = {"metres_from_the_screen": back, "eye_height_m": snappedf(standing.y - (centre.y - 1.2 * 0.0) + 0.0, 0.01), "eye_above_screen_centre_m": snappedf(standing.y - centre.y, 0.01),
		"screen_in_the_picture_px": [snappedf(box.size.x, 0.1), snappedf(box.size.y, 0.1)], "one_step_in_the_picture_px": snappedf(box.size.x * 28.0 / 800.0, 0.1)}
	if ring: ui.set("read_column", true)
	result["read_column"] = bool(ui.get("read_column"))
	if write_hits:
		for s in range(0, steps, 4): ui.call("set_cell", 0, s, true)
	ui.call("set_playhead", 4)
	var on_hit: Image = await _frame("on_a_hit", standing, centre)
	ui.call("set_playhead", 5)
	var on_rest: Image = await _frame("on_a_rest", standing, centre)
	ui.call("set_playhead", 6)
	var on_next: Image = await _frame("on_the_next_rest", standing, centre)
	result["hit_to_rest"] = _changed(on_hit, on_rest, box)
	result["rest_to_next_rest"] = _changed(on_rest, on_next, box)
	checks.append({"check": "the sequencer is found, faced and photographed from %.1f m" % back, "ok": box.size.x > 40.0})
	checks.append({"check": "moving the clock from one silent step to the next changes at least 1 % of the screen as the visitor sees it",
		"ok": float(result.rest_to_next_rest.share_changed) >= 0.01, "share": result.rest_to_next_rest.share_changed, "pixels": result.rest_to_next_rest.pixels_changed})
	result.passed = checks.all(func(c): return c.ok)
	_save()
	quit(0 if result.passed else 1)
