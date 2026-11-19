extends SceneTree
## Point_Lines, floor 3 of the main tower as it is today: the measured walk "WalkThisLine" (a part of the
## row "directions"), from where a visitor arrives and from in front of each of its ends at eye height.
## Palle, 19 November 2026: "add a clear label at the line saying Walk This Line". How readable is what
## the floor says now, and how readable is the label once the row "walk-this-line-label" is there?
##
## Reports where the line lies, what words stand at it and how tall they are in the visitor's picture, and
## where two other rows stand, so a new row's position can be worked out from this floor's own numbers.
##
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/walk_this_line_label.gd -- \
##       --void-start-floor=3 --no-opening --opera-quiet --out=<dir>
##
## <dir>/walk_this_line.json, arrival.png, at_end_a.png, approaching_end_a.png, at_end_b.png, beside_the_middle.png

var game: Node
var folder := "res://ada_run/walk_this_line"
var result := {}
var eye: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("walk_this_line.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()


func _frame(label: String, at: Vector3, aim: Vector3) -> void:
	eye.global_position = at
	eye.look_at(aim, Vector3.UP)
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	if label != "": root.get_texture().get_image().save_png(folder.path_join(label + ".png"))


func _v(p: Vector3) -> Array:
	return [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)]


func _artifact(id: String) -> Node3D:
	var mount: Variant = game.building.content.exhibits.get("%d/%s" % [int(game.checkpoint), id])
	if mount is Node and (mount as Node).get_node_or_null("Artifact") != null: return (mount as Node).get_node("Artifact")
	return null


# How tall a thing of this height at this place stands in the picture, in pixels.
func _tall_px(at: Vector3, height_m: float, up: Vector3) -> float:
	return eye.unproject_position(at).distance_to(eye.unproject_position(at + up * height_m))


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
	result = {"floor": int(game.checkpoint), "map": "Point_Lines", "window": str(root.size), "checks": checks, "passed": false}
	var directions: Node3D = null
	for i in 2400:
		await physics_frame
		directions = _artifact("directions")
		if directions != null and directions.get_node_or_null("WalkThisLine") != null and i > 240: break
	if directions == null or directions.get_node_or_null("WalkThisLine") == null:
		checks.append({"check": "the measured walk stands on this floor", "ok": false})
		_save(); quit(1); return
	var walk: Node3D = directions.get_node("WalkThisLine")
	var length := float(walk.get("stripe_len_m"))
	var end_a: Vector3 = walk.global_transform * Vector3(-length * 0.5, 0, 0)
	var end_b: Vector3 = walk.global_transform * Vector3(length * 0.5, 0, 0)
	var middle: Vector3 = walk.global_position
	var side: Vector3 = (walk.global_transform.basis * Vector3(0, 0, 1)).normalized()
	eye = root.get_camera_3d()
	var arrived := eye.global_position
	var eye_height: float = arrived.y - middle.y
	var words := []
	for label: Label3D in walk.find_children("*", "Label3D", true, false):
		if str(label.text).strip_edges() == "": continue
		words.append({"text": str(label.text).replace("\n", " / ").left(60), "at_in_the_line_s_frame": _v(walk.to_local(label.global_position)),
			"letter_height_m": snappedf(float(label.font_size) * float(label.pixel_size) * label.global_transform.basis.get_scale().x * 0.7, 0.001)})
	result["the_line"] = {"length_m": length, "stripe_width_m": float(walk.get("stripe_w_m")), "end_a": _v(end_a), "end_b": _v(end_b), "script": str((walk.get_script() as Script).resource_path),
		"words_at_it": words}
	result["arrival"] = {"eye": _v(arrived), "eye_height_m": snappedf(eye_height, 0.01), "metres_to_end_a": snappedf(arrived.distance_to(end_a), 0.1), "metres_to_end_b": snappedf(arrived.distance_to(end_b), 0.1)}
	var rows := {}
	for id in ["directions", "assembly", "tape-supply", "point-room", "walk-this-line-label"]:
		var node := _artifact(id)
		if node != null: rows[id] = {"at": _v(node.global_position), "turned_deg": snappedf(rad_to_deg(node.global_rotation.y), 0.1)}
	result["rows"] = rows
	game.body.set_physics_process(false)
	game.body.set_process(false)
	await _frame("", arrived, middle)
	await _frame("arrival", arrived, middle)
	var along := (end_b - end_a).normalized()
	var stand_a := end_a - along * 1.6 + Vector3.UP * eye_height
	var stand_b := end_b + along * 1.6 + Vector3.UP * eye_height
	await _frame("at_end_a", stand_a, middle + Vector3.UP * 0.2)
	var seen := {}
	var label_node := _artifact("walk-this-line-label")
	if label_node != null:
		seen["from_end_a_px"] = snappedf(_tall_px(label_node.global_position, 0.17, (label_node.global_transform.basis * Vector3(0, 0, -1)).normalized()), 0.1)
	for row in words:
		if str(row.text).begins_with("WALK THIS LINE"):
			var at: Vector3 = walk.global_transform * Vector3(row.at_in_the_line_s_frame[0], row.at_in_the_line_s_frame[1], row.at_in_the_line_s_frame[2])
			row["tall_in_the_picture_from_end_a_px"] = snappedf(_tall_px(at, float(row.letter_height_m), -side), 0.1)
	# a few steps before the gate, as someone walking in from the arrival comes to it
	await _frame("approaching_end_a", end_a - along * 4.4 + Vector3.UP * eye_height, end_a - along * 0.6)
	if label_node != null:
		seen["approaching_px"] = snappedf(_tall_px(label_node.global_position, 0.17 * label_node.global_transform.basis.get_scale().x, (label_node.global_transform.basis * Vector3(0, 0, -1)).normalized()), 0.1)
	await _frame("at_end_b", stand_b, middle + Vector3.UP * 0.2)
	if label_node != null:
		seen["from_end_b_px"] = snappedf(_tall_px(label_node.global_position, 0.17, (label_node.global_transform.basis * Vector3(0, 0, -1)).normalized()), 0.1)
	await _frame("beside_the_middle", middle + side * 3.2 + Vector3.UP * eye_height, middle)
	if label_node != null:
		seen["from_beside_the_middle_px"] = snappedf(_tall_px(label_node.global_position, 0.17, (label_node.global_transform.basis * Vector3(0, 0, -1)).normalized()), 0.1)
		seen["legend"] = str(label_node.get("legend_text"))
		seen["in_the_line_s_frame"] = _v(walk.to_local(label_node.global_position))
		result["the_new_label"] = seen
	checks.append({"check": "the measured walk is found and photographed", "ok": true})
	if label_node != null:
		checks.append({"check": "the new label's letters stand at least 14 px tall from 4.4 m before the east gate", "ok": float(seen.approaching_px) >= 14.0, "approaching_px": seen.approaching_px})
	result.passed = checks.all(func(c): return c.ok)
	_save()
	quit(0 if result.passed else 1)
