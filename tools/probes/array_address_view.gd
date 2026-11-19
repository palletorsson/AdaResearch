extends SceneTree
## Array, floor 23 of the main tower as it is today: the hand-indexed bridge over shaft B ("worksite",
## array_index_bridge), from the desk at the player's eye height. For the opera desk card "array-address":
## what does the visitor at the desk see when the selected square [5, 1] is written to 0 and back to 1, and
## do the physical claims of the chapter hold on this floor now (not in the October trial)?
##
## Stands at the desk, selects [5, 1], takes the frame aimed at that cell: with the tile, without it, with
## it again; and one frame looking up at the address display with the tile gone. Measures how much of the
## picture inside the cell's outline changes, whether a ray dropped through the cell meets a support, and
## what the two readouts say.
##
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/array_address_view.gd -- \
##       --void-start-floor=23 --no-opening --opera-quiet --out=<dir>

var game: Node
var folder := "res://ada_run/array_address"
var result := {}
var eye: Camera3D
var work: Node3D


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("array_address.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()


func _frame(label: String, at: Vector3, aim: Vector3) -> Image:
	eye.global_position = at
	eye.look_at(aim, Vector3.UP)
	for i in 10: await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if label != "": image.save_png(folder.path_join(label + ".png"))
	return image


# Does a ray dropped through the middle of a cell meet one of the bridge's supports?
func _supported(cell: Vector2i) -> bool:
	var centre: Vector3 = work.global_transform * (work.call("cell_position", cell, 0.68, Vector3(0, -0.18, -3.9)) as Vector3)
	var query := PhysicsRayQueryParameters3D.create(centre + Vector3.UP * 1.0, centre + Vector3.DOWN * 0.6)
	var hit := work.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and (hit.collider as Node).has_meta("array_index")


func _outline(cell: Vector2i) -> PackedVector2Array:
	var centre: Vector3 = work.call("cell_position", cell, 0.68, Vector3(0, -0.18, -3.9))
	var points := PackedVector2Array()
	for corner in [Vector3(-0.34, 0.08, -0.34), Vector3(0.34, 0.08, -0.34), Vector3(0.34, 0.08, 0.34), Vector3(-0.34, 0.08, 0.34)]:
		points.append(eye.unproject_position(work.global_transform * (centre + corner)))
	return points


func _changed(a: Image, b: Image, outline: PackedVector2Array) -> Dictionary:
	var box := Rect2(outline[0], Vector2.ZERO)
	for p in outline: box = box.expand(p)
	var inside := 0
	var changed := 0
	var step := 0.0
	for y in range(maxi(0, int(box.position.y)), mini(a.get_height(), int(box.end.y) + 1)):
		for x in range(maxi(0, int(box.position.x)), mini(a.get_width(), int(box.end.x) + 1)):
			if not Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), outline): continue
			inside += 1
			var p := a.get_pixel(x, y)
			var q := b.get_pixel(x, y)
			if absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.03:
				changed += 1
				step += absf(p.get_luminance() - q.get_luminance())
	return {"pixels_inside_the_cell": inside, "pixels_changed": changed, "share_changed": snappedf(float(changed) / maxf(1.0, float(inside)), 0.001),
		"mean_luminance_step": snappedf(step / maxf(1.0, float(changed)), 0.001), "cell_in_the_picture_px": [snappedf(box.size.x, 0.1), snappedf(box.size.y, 0.1)]}


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var checks := []
	result = {"floor": int(game.checkpoint), "map": "Array", "platform": "desktop, %s, window %s" % [str(RenderingServer.get_video_adapter_name()), str(root.size)], "checks": checks, "passed": false}
	var key := "%d/worksite" % int(game.checkpoint)
	for i in 2400:
		await physics_frame
		var mount: Variant = game.building.content.exhibits.get(key)
		if mount is Node and (mount as Node).get_node_or_null("Artifact") != null and i > 240:
			work = (mount as Node).get_node("Artifact")
			break
	if work == null or not work.has_method("write_selected"):
		checks.append({"check": "the hand-indexed bridge stands on this floor", "ok": false, "looked_for": key})
		_save(); quit(1); return
	var values: Array = work.get("values")
	var ones := 0
	for row in values:
		for v in row: ones += int(v)
	checks.append({"check": "the hand-indexed bridge stands on floor 23 of the main tower: 7 x 7 squares, all 49 present, 0.68 m apart over the shaft and 0.12 m apart on the desk",
		"ok": ones == 49 and (work.get("colliders") as Dictionary).size() == 49 and is_equal_approx(float(work.get("LARGE")), 0.68) and is_equal_approx(float(work.get("SMALL")), 0.12),
		"present": ones, "at": [snappedf(work.global_position.x, 0.01), snappedf(work.global_position.y, 0.01), snappedf(work.global_position.z, 0.01)]})
	# stand at the desk, facing the shaft
	var stance: Vector3 = work.global_transform * Vector3(0.0, 0.05, 0.85)
	var ahead: Vector3 = (work.global_transform.basis * Vector3(0, 0, -1)).normalized()
	game.place_player(stance, atan2(-ahead.x, -ahead.z))
	for i in 120: await physics_frame
	eye = root.get_camera_3d()
	var standing := eye.global_position
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var cell := Vector2i(5, 1)
	work.call("select_cell", cell)
	for i in 6: await physics_frame
	var centre: Vector3 = work.global_transform * (work.call("cell_position", cell, 0.68, Vector3(0, -0.18, -3.9)) as Vector3)
	var address: Label3D = work.get("address")
	var readout: Label = work.get("readout")
	await _frame("", standing, centre)
	var with_tile: Image = await _frame("desk_tile_present", standing, centre)
	var outline := _outline(cell)
	var said_before := str(address.text)
	var held_before := _supported(cell)
	work.call("write_selected", 0)
	for i in 6: await physics_frame
	var without: Image = await _frame("desk_tile_removed", standing, centre)
	var held_removed := _supported(cell)
	var said_removed := str(address.text)
	var cursor: Node3D = work.get("large_cursor")
	var cursor_there: bool = cursor.is_visible_in_tree() and (cursor.global_position - (centre + Vector3.UP * 0.09)).length() < 0.02
	var change := _changed(with_tile, without, outline)
	var distance := standing.distance_to(centre)
	checks.append({"check": "writing 0 at [5, 1] takes the square away for the body and for the eye at the desk: a ray through the cell meets a support before and none after; the pink outline stays on the empty cell; the address reads = 0",
		"ok": held_before and not held_removed and cursor_there and said_before.begins_with("[5, 1] = 1") and said_removed.begins_with("[5, 1] = 0") and int(change.pixels_changed) > 0,
		"support_before": held_before, "support_after": held_removed, "outline_still_on_the_cell": cursor_there, "address_before": said_before, "address_after": said_removed, "picture": change,
		"metres_from_the_eye": snappedf(distance, 0.01), "degrees_below_level": snappedf(rad_to_deg(asin((standing.y - centre.y) / distance)), 0.1)})
	_save()
	# looking up at the address display with the square gone
	await _frame("desk_looking_at_the_address", standing, address.global_position)
	var address_height := address.global_position.y - (standing.y - 1.6)
	result["address_display"] = {"height_above_the_floor_m": snappedf(address_height, 0.01), "eye_height_m": 1.6, "degrees_above_level": snappedf(rad_to_deg(atan2(address.global_position.y - standing.y,
		Vector2(address.global_position.x - standing.x, address.global_position.z - standing.z).length())), 0.1), "panel_readout": str(readout.text)}
	# can the hole and the address be in one picture? aim between them and see whether both project inside the frame
	await _frame("desk_between_hole_and_address", standing, (centre + address.global_position) * 0.5)
	var hole_at := eye.unproject_position(centre)
	var address_at := eye.unproject_position(address.global_position)
	var frame := Rect2(Vector2.ZERO, Vector2(root.size))
	checks.append({"check": "reported: from the desk, are the empty cell and the address display inside one picture (75 degree field of view)", "ok": true,
		"hole_in_frame": frame.has_point(hole_at) and not eye.is_position_behind(centre), "address_in_frame": frame.has_point(address_at) and not eye.is_position_behind(address.global_position),
		"hole_at_px": [snappedf(hole_at.x, 1.0), snappedf(hole_at.y, 1.0)], "address_at_px": [snappedf(address_at.x, 1.0), snappedf(address_at.y, 1.0)],
		"degrees_between_them": snappedf(rad_to_deg((centre - standing).angle_to(address.global_position - standing)), 0.1)})
	work.call("write_selected", 1)
	for i in 6: await physics_frame
	var restored: Image = await _frame("desk_tile_restored", standing, centre)
	var back := _changed(with_tile, restored, outline)
	checks.append({"check": "writing 1 at the same address puts the square back: the ray meets a support again and the picture inside the cell is what it was", "ok": _supported(cell)
		and str(address.text).begins_with("[5, 1] = 1") and int(back.pixels_changed) == 0, "address": str(address.text), "pixels_different_from_before": back.pixels_changed})
	result["passed"] = checks.all(func(c): return c.ok)
	_save()
	print("[array_address_view] ", "PASSED" if result.passed else "FAILED")
	quit(0 if result.passed else 1)
