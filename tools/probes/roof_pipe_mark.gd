extends SceneTree
## The mark beside the pipe on the roof (Point_Zero), at the player's eye height, from two head positions.
##
## The mark is the top cap of the floor below's electrical riser (radius 0.07 m), which lies exactly in the
## roof slab's top face beside the east water riser: two surfaces at one depth, so which of them is drawn at
## a pixel depends on where the eye is. Opera desk card "roof-pipe": is the return legible?
##
## One standing place (--stance=dx,dz from the mark; by default north-west of it, behind the service stand). The eye is put, in turn, at: A (standing, aimed at the mark), TURN
## (same place, the head turned to the right, the mark still in view), A again, LEAN (the head 22 cm back and
## 3 cm down, aimed at the mark), A again, SIDE (12 cm to the right), A again, and the two eyes of a headset
## at A (32 mm left and right). At each the frame is taken twice, with the riser shown and hidden: the
## pixels that differ ARE the mark as drawn, whatever its colour. Kept: full frames, crops round the mark,
## and matched strips (A | LEAN | A, A | TURN | A, left eye | right eye).
##
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/roof_pipe_mark.gd -- \
##       --void-start-floor=0 --no-opening --opera-quiet --out=<dir>
##
## <dir>/roof_pipe.json: checks, and per pose the eye's place, the mark's size in the picture, how much of
## the cap is drawn, and its contrast against the concrete.

const CROP := 96

var game: Node
var folder := "res://ada_run/roof_pipe"
var result := {}
var eye: Camera3D
var riser: MeshInstance3D
var cap := Vector3.ZERO


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("roof_pipe.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()


func _frame() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _find_riser(node: Node, near: Vector3) -> void:
	if node is MeshInstance3D and str(node.name).begins_with("ElectricalRiser"):
		var box: AABB = (node as MeshInstance3D).global_transform * (node as MeshInstance3D).get_aabb()
		var top := box.position.y + box.size.y
		var centre := box.get_center()
		if absf(top) < 0.01 and Vector2(centre.x - near.x, centre.z - near.z).length() < 0.6:
			riser = node
			cap = Vector3(centre.x, top, centre.z)
	for child in node.get_children():
		if riser == null: _find_riser(child, near)


# The eye at a place, aimed at a point; the frame with the riser shown, then hidden; what differs is the mark.
func _look(label: String, at: Vector3, aim: Vector3) -> Dictionary:
	eye.global_position = at
	eye.look_at(aim, Vector3.UP)
	riser.visible = true
	# after the eye has moved the picture takes some frames to come to rest (shadows, what is culled, exposure):
	# wait, then take the frame twice; the two must agree before a hidden frame is compared with them
	for i in 10: await process_frame
	var first: Image = await _frame()
	var shown: Image = await _frame()
	riser.visible = false
	for i in 4: await process_frame
	var hidden: Image = await _frame()
	riser.visible = true
	shown.save_png(folder.path_join("%s.png" % label))
	var centre := eye.unproject_position(cap)
	var rim := PackedVector2Array()
	for i in 48: rim.append(eye.unproject_position(cap + Vector3(cos(TAU * i / 48.0), 0, sin(TAU * i / 48.0)) * 0.07))
	var footprint := 0.0
	for i in 48: footprint += rim[i].x * rim[(i + 1) % 48].y - rim[(i + 1) % 48].x * rim[i].y
	footprint = absf(footprint) * 0.5
	var x0 := clampi(int(centre.x) - CROP / 2, 0, shown.get_width() - CROP)
	var y0 := clampi(int(centre.y) - CROP / 2, 0, shown.get_height() - CROP)
	var mask := PackedByteArray()
	mask.resize(CROP * CROP)
	var drawn := 0
	var unsteady := 0
	var mark_colour := Color(0, 0, 0)
	var ground_colour := Color(0, 0, 0)
	var ground_count := 0
	for y in CROP:
		for x in CROP:
			var a := shown.get_pixel(x0 + x, y0 + y)
			var b := hidden.get_pixel(x0 + x, y0 + y)
			# only inside the cap's own outline in the picture (one pixel of margin): nothing else on the roof counts
			var inside := Geometry2D.is_point_in_polygon(Vector2(x0 + x + 0.5, y0 + y + 0.5), rim)
			var differs := inside and absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.03
			mask[y * CROP + x] = 1 if differs else 0
			if inside:
				var c := first.get_pixel(x0 + x, y0 + y)
				if absf(a.r - c.r) + absf(a.g - c.g) + absf(a.b - c.b) > 0.03: unsteady += 1
			if differs:
				drawn += 1
				mark_colour += a
			elif not inside and Vector2(x0 + x - centre.x, y0 + y - centre.y).length() < 30.0:
				ground_colour += b
				ground_count += 1
	if drawn > 0: mark_colour /= float(drawn)
	if ground_count > 0: ground_colour /= float(ground_count)
	var crop := shown.get_region(Rect2i(x0, y0, CROP, CROP))
	crop.resize(CROP * 4, CROP * 4, Image.INTERPOLATE_NEAREST)
	crop.save_png(folder.path_join("%s_crop.png" % label))
	var distance := eye.global_position.distance_to(cap)
	return {"label": label, "eye": [snappedf(eye.global_position.x, 0.001), snappedf(eye.global_position.y, 0.001), snappedf(eye.global_position.z, 0.001)],
		"metres_from_the_mark": snappedf(distance, 0.001), "degrees_across": snappedf(rad_to_deg(2.0 * atan(0.07 / distance)), 0.01), "cap_footprint_pixels": snappedf(footprint, 0.1),
		"mark_pixels_drawn": drawn, "pixels_not_at_rest_between_two_frames": unsteady, "share_of_the_cap_drawn": snappedf(float(drawn) / maxf(1.0, footprint), 0.001),
		"mark_colour": [snappedf(mark_colour.r, 0.001), snappedf(mark_colour.g, 0.001), snappedf(mark_colour.b, 0.001)],
		"concrete_colour": [snappedf(ground_colour.r, 0.001), snappedf(ground_colour.g, 0.001), snappedf(ground_colour.b, 0.001)],
		"luminance_step": snappedf(absf(mark_colour.get_luminance() - ground_colour.get_luminance()), 0.001), "_mask": mask, "_crop": crop}


static func _differing(a: PackedByteArray, b: PackedByteArray) -> int:
	var count := 0
	for i in a.size():
		if a[i] != b[i]: count += 1
	return count


func _strip(file_name: String, looks: Array) -> void:
	var size := CROP * 4
	var strip := Image.create(size * looks.size() + 8 * (looks.size() - 1), size, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.06, 0.06, 0.07))
	for i in looks.size():
		var crop: Image = looks[i]["_crop"]
		crop.convert(Image.FORMAT_RGBA8)
		strip.blit_rect(crop, Rect2i(0, 0, size, size), Vector2i(i * (size + 8), 0))
	strip.save_png(folder.path_join(file_name))


func _public(look: Dictionary) -> Dictionary:
	var out := look.duplicate()
	out.erase("_mask")
	out.erase("_crop")
	return out


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
	result = {"floor": int(game.checkpoint), "map": "Point_Zero", "platform": "desktop, %s, window %s" % [str(RenderingServer.get_video_adapter_name()), str(root.size)], "checks": checks, "passed": false}
	# the one pipe that reaches the roof: the west one (measured 2026-11-19: no riser is built at the east service line)
	var west_x := float(game.building.spec.service_x[0])
	for x in game.building.spec.service_x: west_x = minf(west_x, float(x))
	var near := Vector3(west_x + 0.42, 0.0, float(game.building.spec.service_z))
	for i in 1800:
		await physics_frame
		if i > 240 and i % 30 == 0:
			_find_riser(game.building, near)
			if riser != null: break
	if riser == null:
		checks.append({"check": "the floor below's electrical riser ends in the roof's surface beside the west pipe", "ok": false, "looked_near": [near.x, near.y, near.z]})
		_save(); quit(1); return
	var level: float = float(game.building.spec.levels[0]) + game.building.global_position.y
	# one standing place, given as metres east and south of the mark (--stance=dx,dz); by default north-west of it,
	# behind the black-back service stand, where the listening card's picture was taken from
	var offset := Vector2(-1.1, -1.2)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stance="):
			var parts := arg.trim_prefix("--stance=").split(",")
			offset = Vector2(float(parts[0]), float(parts[1]))
	# a trial in the running scene only, nothing saved: the service stand moved by so many metres (--trial-shift=dx,dz)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trial-shift="):
			var parts := arg.trim_prefix("--trial-shift=").split(",")
			var mount: Variant = game.building.content.exhibits.get("0/roof-anomaly")
			if mount is Node3D:
				(mount as Node3D).global_position += Vector3(float(parts[0]), 0.0, float(parts[1]))
				result["trial"] = {"moved": "0/roof-anomaly", "by_m": [float(parts[0]), float(parts[1])], "now_at": [(mount as Node3D).global_position.x, (mount as Node3D).global_position.z], "saved": false}
	var stance := Vector3(cap.x + offset.x, level + 0.05, cap.z + offset.y)
	game.place_player(stance, atan2(-(cap.x - stance.x), -(cap.z - stance.z)))
	for i in 90: await physics_frame
	eye = root.get_camera_3d()
	var standing := eye.global_position
	# the rig is held still: the eye is put where this run says, and nowhere else
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var slab_top := level
	checks.append({"check": "the floor below's electrical riser ends in the roof's surface beside the west pipe: its cap and the slab's top are one plane", "ok": absf(cap.y - slab_top) < 0.002,
		"cap_centre": [snappedf(cap.x, 0.001), snappedf(cap.y, 0.001), snappedf(cap.z, 0.001)], "slab_top_y": slab_top, "standing_eye": [snappedf(standing.x, 0.001), snappedf(standing.y, 0.001), snappedf(standing.z, 0.001)],
		"eye_height_m": snappedf(standing.y - level, 0.001), "field_of_view_degrees": eye.fov, "stance_on_the_floor": [stance.x, stance.z]})
	_save()
	# where things are: from straight above, and from high in the north-west
	eye.global_position = Vector3(cap.x + 0.6, 9.0, cap.z + 0.4)
	eye.look_at(Vector3(cap.x + 0.6, 0.0, cap.z + 0.39), Vector3(0, 0, -1))
	(await _frame()).save_png(folder.path_join("overview_from_above.png"))
	eye.global_position = Vector3(cap.x - 2.6, 3.2, cap.z - 3.4)
	eye.look_at(cap + Vector3(0.5, 0.3, 0.0), Vector3.UP)
	(await _frame()).save_png(folder.path_join("overview_north_west.png"))
	if OS.get_cmdline_user_args().has("--survey"):
		# From where can the mark be seen at all? The eye alone is carried round the mark (the body is left where it
		# stands), at three distances and two heights; how much of the cap is drawn from each place.
		var places := []
		for height in [1.6, 1.0]:
			for distance in [0.9, 1.5, 2.3]:
				for step in 16:
					var angle := TAU * float(step) / 16.0
					var at := Vector3(cap.x + sin(angle) * distance, level + height, cap.z - cos(angle) * distance)
					var seen: Dictionary = await _look("survey", at, cap)
					places.append({"east_of_the_mark_m": snappedf(sin(angle) * distance, 0.01), "south_of_the_mark_m": snappedf(-cos(angle) * distance, 0.01), "eye_height_m": height,
						"mark_pixels_drawn": seen.mark_pixels_drawn, "cap_footprint_pixels": seen.cap_footprint_pixels, "share_of_the_cap_drawn": seen.share_of_the_cap_drawn})
		places.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return int(p.mark_pixels_drawn) > int(q.mark_pixels_drawn))
		var seeing := places.filter(func(p: Dictionary) -> bool: return int(p.mark_pixels_drawn) > 0)
		result["survey"] = {"places_tried": places.size(), "places_that_see_any_of_the_mark": seeing.size(), "best": places.slice(0, 12)}
		checks.append({"check": "SURVEY: from how many of 96 eye places round the mark (0.9, 1.5 and 2.3 m away; 1.6 and 1.0 m high) is any of it drawn", "ok": true,
			"places_that_see_any_of_it": seeing.size(), "of": places.size()})
		for i in mini(3, seeing.size()):
			var best: Dictionary = seeing[i]
			await _look("survey_best_%d" % i, Vector3(cap.x + float(best.east_of_the_mark_m), level + float(best.eye_height_m), cap.z + float(best.south_of_the_mark_m)), cap)
		result["passed"] = true
		_save()
		print("[roof_pipe_mark] survey done")
		quit(0)
		return
	var forward := (cap - standing).normalized()
	var flat := Vector3(forward.x, 0, forward.z).normalized()
	var right := flat.cross(Vector3.UP).normalized()
	# the first look after the rig is stopped still has the visitor's own body settling in front of the eye: one look
	# is taken and thrown away before the first that counts
	await _look("warm_up", standing, cap)
	var a0: Dictionary = await _look("a0_standing", standing, cap)
	var turn: Dictionary = await _look("turn_head_right", standing, cap + right * 0.45)
	var a1: Dictionary = await _look("a1_back_from_turn", standing, cap)
	var lean: Dictionary = await _look("lean_back", standing - flat * 0.22 + Vector3(0, -0.03, 0), cap)
	var a2: Dictionary = await _look("a2_back_from_lean", standing, cap)
	var side: Dictionary = await _look("side_step", standing + right * 0.12, cap)
	var a3: Dictionary = await _look("a3_back_from_side", standing, cap)
	var left_eye: Dictionary = await _look("eye_left", standing - right * 0.032, cap)
	var right_eye: Dictionary = await _look("eye_right", standing + right * 0.032, cap)
	_strip("pair_lean.png", [a0, lean, a2])
	_strip("pair_turn.png", [a0, turn, a1])
	_strip("pair_side.png", [a0, side, a3])
	_strip("pair_two_eyes.png", [left_eye, right_eye])
	var looks := [a0, turn, a1, lean, a2, side, a3, left_eye, right_eye]
	var listed := []
	for look in looks: listed.append(_public(look))
	result["looks"] = listed
	var most := 0
	for look in looks: most = maxi(most, int(look.mark_pixels_drawn))
	checks.append({"check": "the mark can be seen from this standing place at all: at one of the nine eye positions some of the cap is drawn", "ok": most > 0, "most_pixels_drawn_at_any_position": most,
		"standing_share_drawn": a0.share_of_the_cap_drawn, "degrees_across": a0.degrees_across})
	var back_same := _differing(a0["_mask"], a1["_mask"]) + _differing(a0["_mask"], a2["_mask"]) + _differing(a0["_mask"], a3["_mask"])
	checks.append({"check": "THE RETURN: back at the standing view after each move, the mark is the shape it was, pixel for pixel", "ok": back_same == 0, "pixels_that_differ_over_three_returns": back_same})
	var lean_change := _differing(a0["_mask"], lean["_mask"])
	checks.append({"check": "LEAN BACK changes the mark: its drawn pixels differ from the standing view's by more than a tenth of the standing mark", "ok": lean_change > int(a0.mark_pixels_drawn) / 10,
		"pixels_that_differ": lean_change, "share_standing": a0.share_of_the_cap_drawn, "share_leaning": lean.share_of_the_cap_drawn})
	var turn_change := absf(float(turn.share_of_the_cap_drawn) - float(a0.share_of_the_cap_drawn))
	checks.append({"check": "TURNING THE HEAD in place (no move of the eye): reported, not required - does the share of the cap drawn change", "ok": true, "share_standing": a0.share_of_the_cap_drawn,
		"share_turned": turn.share_of_the_cap_drawn, "change_in_share": snappedf(turn_change, 0.001), "pixels_standing": a0.mark_pixels_drawn, "pixels_turned": turn.mark_pixels_drawn})
	var eyes_change := _differing(left_eye["_mask"], right_eye["_mask"])
	checks.append({"check": "THE TWO EYES of a headset at the standing view (64 mm apart): reported - do they draw different shapes", "ok": true, "pixels_that_differ": eyes_change, "share_left": left_eye.share_of_the_cap_drawn,
		"share_right": right_eye.share_of_the_cap_drawn})
	result["passed"] = checks.all(func(c): return c.ok)
	_save()
	print("[roof_pipe_mark] ", "PASSED" if result.passed else "FAILED")
	quit(0 if result.passed else 1)
