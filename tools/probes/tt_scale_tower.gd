extends SceneTree
## THE TT SCREENS ON THE QFEP FLOORS (2026-11-14, forum 261114-i43dq). Six `tt` rows (Tutorial Text Display,
## codeDisplay.tscn) came into the tower at scale 180: the grid token is `tt:<rotation>:<tutorial>:180:0.5`, and the
## museum plan read it as name:rotation:y_offset:scale, so the 4th field (180) became the scale and the tutorial key
## was lost. Each drew its 1.0 x 1.2 m screen as a 180 x 216 m black plane through 36 storeys, hiding the works behind
## it. This probe reads ONE floor of the running tower (main tower; stickers on a copy with posting off) and measures:
##   T1 every VisualInstance3D of every tt display on the loaded floors is at most MAX_SIDE m on its longest side
##   T2 every tt display of THIS floor stands over the structural floor (x +-21, z +-9) and inside its storey
##   T3 a tt display whose tutorial key is in the library shows that text, not the panel's default ("The Trace")
##   T4 nothing drawn (outside the display itself) stands in its reading volume: the screen pushed 1.5 m out of its face
## and lists, as information, every drawn box longer than BIG m that crosses this storey (the tower's own slabs are 42).
## Pictures: end_west.png and end_east.png (eye height, from x -+4 toward each end), panel_<id>.png (1.6 m in front).
##   godot --path <stage> --script res://tools/probes/tt_scale_tower.gd -- --no-bridges --void-start-floor=<index> --out=<dir>
const StickerData := preload("res://commons/stickers/sticker_data.gd")
const Library := preload("res://commons/context/clipboard/tutorial_text_library.gd")
const SCENE := "res://commons/context/clipboard/codeDisplay.tscn"
const COPY := "user://tt_scale_tower"
const MAX_SIDE := 3.0
const BIG := 45.0
var game: Node3D
var eye: SubViewport
var cam: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _box(b: AABB) -> Array:
	return [snappedf(b.position.x, 0.01), snappedf(b.position.y, 0.01), snappedf(b.position.z, 0.01), snappedf(b.end.x, 0.01), snappedf(b.end.y, 0.01), snappedf(b.end.z, 0.01)]


func _longest(b: AABB) -> float:
	return maxf(b.size.x, maxf(b.size.y, b.size.z))


func _shot(at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


func _display(key: String, mount: Node3D, row: Dictionary, library) -> Dictionary:
	var art: Node3D = mount.get_node_or_null("Artifact")
	var out := {"key": key, "row": {"position": row.get("position"), "height": row.get("height"), "facing": row.get("facing"), "scale": row.get("scale"), "config": row.get("config", {})}}
	if art == null:
		out["missing"] = true
		return out
	var parts := []
	var longest := 0.0
	var merged := AABB()
	var first := true
	for n in art.find_children("*", "VisualInstance3D", true, false):
		var v := n as VisualInstance3D
		if not v.is_visible_in_tree(): continue
		var b: AABB = v.global_transform * v.get_aabb()
		longest = maxf(longest, _longest(b))
		parts.append({"node": str(art.get_path_to(v)), "class": v.get_class(), "box": _box(b), "longest": snappedf(_longest(b), 0.01)})
		if first: merged = b; first = false
		else: merged = merged.merge(b)
	var label: RichTextLabel = art.get("rich_text_label") if "rich_text_label" in art else null
	var shown := label.get_parsed_text().strip_edges().substr(0, 90) if label != null else ""
	var tutorial := str(row.get("config", {}).get("tutorial", ""))
	out["scale_in_world"] = snappedf(art.global_transform.basis.get_scale().x, 0.001)
	out["parts"] = parts
	out["longest"] = snappedf(longest, 0.01)
	out["box"] = _box(merged)
	out["tutorial"] = tutorial
	out["in_library"] = tutorial != "" and library.has_tutorial(tutorial)
	out["shown"] = shown
	out["default_text"] = shown.begins_with("The Trace")
	return out


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	# floor 199 carries the sticker app: draw it from a COPY, never post (as stickers_tower.gd does)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COPY))
	for name in ["designs.json", "boards.json", "placements.json"]:
		var f := FileAccess.open(COPY + "/" + name, FileAccess.WRITE)
		f.store_string(FileAccess.get_file_as_string("res://commons/data/stickers/" + name))
		f.close()
	StickerData.get_or_create(self).configure({"data_dir": COPY, "outbox": COPY + "/outbox.json", "post": false})
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	game.scene_loaded()
	game.scene_visible()
	var floor: int = game.checkpoint
	var content = game.building.content
	for i in 1800:
		var record: Dictionary = content.data.floors[floor]
		if record.artifacts.all(func(a): return content.exhibits.has(str(floor) + "/" + a.id)): break
		await physics_frame
	for i in 300: await physics_frame
	var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
	var storey: float = float(game.building.spec.storey_height)
	var library = Library.new()
	# every tt display on the floors the tower has built (the window around this one), and this floor's own
	var displays := []
	var here := []
	for key in content.exhibits:
		var parts: PackedStringArray = str(key).split("/", true, 1)
		var index := int(parts[0])
		var row: Dictionary = {}
		for a in content.data.floors[index].artifacts:
			if a.id == parts[1]: row = a
		var mount: Node3D = content.exhibits[key]
		var art: Node = mount.get_node_or_null("Artifact") if is_instance_valid(mount) else null
		if art == null or (str(row.get("artifact", "")) != "tt" and art.scene_file_path != SCENE): continue
		var d := _display(str(key), mount, row, library)
		d["floor"] = index
		d["map"] = str(content.data.floors[index].map)
		displays.append(d)
		if index == floor: here.append(d)
	var t1 := true
	var t2 := true
	var t3 := true
	var t4 := true
	for d in displays:
		t1 = t1 and not d.has("missing") and float(d.longest) <= MAX_SIDE
	for d in here:
		if d.has("missing"):
			t2 = false; t3 = false; t4 = false
			continue
		var b: Array = d.box
		var over: bool = b[0] >= -21.0 and b[3] <= 21.0 and b[2] >= -9.0 and b[5] <= 9.0
		var inside: bool = b[1] >= level - 0.05 and b[4] <= level + storey - float(game.building.spec.slab_thickness)
		d["over_floor"] = over
		d["inside_storey"] = inside
		t2 = t2 and over and inside
		if d.in_library: t3 = t3 and not d.default_text
		# T4: the reading volume - the screen and the same quad 1.5 m out along its face
		var mount: Node3D = content.exhibits[d.key]
		var screen: VisualInstance3D = mount.get_node_or_null("Artifact/Viewport2Din3D/Screen") as VisualInstance3D
		if screen == null:
			t4 = false
			d["reading_blockers"] = ["no Screen"]
			continue
		var sb: AABB = screen.global_transform * screen.get_aabb()
		var face: Vector3 = (mount.get_node("Artifact") as Node3D).global_transform.basis.z.normalized()
		var reading: AABB = sb.merge(AABB(sb.position + face * 1.5, sb.size)).grow(-0.02)
		var blockers := []
		for n in game.find_children("*", "VisualInstance3D", true, false):
			var v := n as VisualInstance3D
			if not v.is_visible_in_tree() or mount.is_ancestor_of(v): continue
			var vb: AABB = v.global_transform * v.get_aabb()
			if not vb.intersects(reading): continue
			# a MultiMesh's box is the union of its instances (the storey's PillarCornerGuards span the whole slab):
			# test each instance instead (a windowed run reads the transforms back; a headless one would not)
			var mmi := v as MultiMeshInstance3D
			if mmi != null and mmi.multimesh != null and mmi.multimesh.mesh != null:
				var mm: MultiMesh = mmi.multimesh
				var count: int = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
				var hit := false
				for i in count:
					var ib: AABB = mmi.global_transform * mm.get_instance_transform(i) * mm.mesh.get_aabb()
					if ib.intersects(reading):
						hit = true
						vb = ib
						break
				if not hit: continue
			blockers.append({"node": str(v.get_path()).right(110), "class": v.get_class(), "box": _box(vb)})
			if blockers.size() >= 12: break
		d["reading_volume"] = _box(reading)
		d["reading_blockers"] = blockers
		t4 = t4 and blockers.is_empty()
	# information: anything drawn that is longer than BIG and crosses this storey
	var zone := AABB(Vector3(-21.0, level, -9.0), Vector3(42.0, storey, 18.0))
	var big := []
	for n in game.find_children("*", "VisualInstance3D", true, false):
		var v := n as VisualInstance3D
		if not v.is_visible_in_tree(): continue
		var b: AABB = v.global_transform * v.get_aabb()
		if _longest(b) > BIG and b.intersects(zone):
			big.append({"node": str(v.get_path()).right(120), "class": v.get_class(), "box": _box(b)})
			if big.size() >= 40: break
	var checks := [
		{"check": "T1 every VisualInstance3D of every tt display on the loaded floors is at most %.1f m on its longest side" % MAX_SIDE, "ok": t1, "displays": displays.size()},
		{"check": "T2 every tt display of this floor stands over the structural floor (x +-21, z +-9) and inside its storey", "ok": t2, "here": here.size()},
		{"check": "T3 a tt display whose tutorial is in the library shows that text, not the panel's default (The Trace)", "ok": t3},
		{"check": "T4 nothing drawn outside each display of this floor stands in its reading volume (the screen pushed 1.5 m out of its face)", "ok": t4},
	]
	var result := {"checks": checks, "passed": t1 and t2 and t3 and t4, "floor": floor, "map": str(content.data.floors[floor].map), "level": level,
		"displays": displays, "big": big}
	eye = SubViewport.new()
	eye.size = Vector2i(1280, 800)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	cam = Camera3D.new()
	cam.fov = 70
	cam.far = 4000.0
	eye.add_child(cam)
	cam.current = true
	await _shot(Vector3(-4.0, level + 1.7, 0.0), Vector3(-21.0, level + 1.4, 0.0), folder.path_join("end_west.png"))
	await _shot(Vector3(4.0, level + 1.7, 0.0), Vector3(21.0, level + 1.4, 0.0), folder.path_join("end_east.png"))
	for d in here:
		if d.has("missing"): continue
		var mount: Node3D = content.exhibits[d.key]
		var art: Node3D = mount.get_node("Artifact")
		var face: Vector3 = art.global_transform.basis.z.normalized()
		var centre: Vector3 = art.global_position
		if float(d.longest) > MAX_SIDE:
			# the screen is too big to frame from in front: stand where a visitor would, 1.6 m off the row
			centre = mount.global_position + Vector3(0, 1.4, 0)
		await _shot(centre + face * 1.6 + Vector3(0, 0.1, 0), centre, folder.path_join("panel_%s.png" % str(d.key).get_slice("/", 1)))
	var fh := FileAccess.open(folder.path_join("tt_tower.json"), FileAccess.WRITE)
	fh.store_string(JSON.stringify(result, "\t"))
	fh.close()
	print("TT_SCALE_TOWER_DONE ", "PASSED" if result.passed else "FAILED")
	quit()
