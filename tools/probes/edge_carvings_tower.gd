extends SceneTree
## THE EDGE CARVINGS IN THE RUNNING TOWER (QFEP_Phi_Term, floor 199; 2026-11-14). The first tower run photographed the
## carvings' words and no stone: this probe measures what stands there instead of guessing - each carving's stone (its
## mesh, its box in the world), what a ray from the visitor's side hits first at three heights, and every drawn thing
## within a few metres west of the row. Against a COPY of the sticker truth with posting off, like stickers_tower.gd.
##   T1 every carving has one stone, named Stone, with a mesh, standing on the floor (its foot within 5 cm of the level)
##   T2 a ray from 1.5 m in front of each carving, at the column's middle, hits that carving's own stone first
## Pictures: carvings_front.png, carvings_top.png, carving_close.png.
##   godot --path <stage> --script res://tools/probes/edge_carvings_tower.gd -- --no-bridges --void-start-floor=<199> --out=<dir>
const StickerData := preload("res://commons/stickers/sticker_data.gd")
const COPY := "user://edge_carvings_tower"
const KINDS := ["cannot-claim", "leaves-out", "still-open", "not-yet", "foreclosed", "dark-spot", "does-not-fit"]
var game: Node3D
var eye: SubViewport
var cam: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _shot(at: Vector3, target: Vector3, path: String, up := Vector3.UP) -> void:
	cam.global_position = at
	cam.look_at(target, up)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


func _box(b: AABB) -> Array:
	return [snappedf(b.position.x, 0.01), snappedf(b.position.y, 0.01), snappedf(b.position.z, 0.01), snappedf(b.end.x, 0.01), snappedf(b.end.y, 0.01), snappedf(b.end.z, 0.01)]


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COPY))
	for name in ["designs.json", "boards.json", "placements.json"]:
		var f := FileAccess.open(COPY + "/" + name, FileAccess.WRITE)
		f.store_string(FileAccess.get_file_as_string("res://commons/data/stickers/" + name))
		f.close()
	var data: Node = StickerData.get_or_create(self)
	data.configure({"data_dir": COPY, "outbox": COPY + "/outbox.json", "post": false})
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
	for i in 1500:
		var all := true
		for k in KINDS: all = all and content.exhibits.has("%d/edge-carving-%s" % [floor, k])
		if all: break
		await physics_frame
	for i in 240: await physics_frame
	var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var rows := []
	var t1 := true
	var t2 := true
	var mounts := []
	for k in KINDS:
		var mount: Node3D = content.exhibits.get("%d/edge-carving-%s" % [floor, k])
		if mount == null:
			t1 = false; t2 = false
			rows.append({"kind": k, "missing": true})
			continue
		mounts.append(mount)
		var art: Node3D = mount.get_node_or_null("Artifact")
		var kids := []
		var stone: CSGShape3D = null
		var stones := 0
		if art != null:
			for c in art.get_children():
				kids.append("%s:%s" % [c.name, c.get_class()])
				if c is CSGCombiner3D:
					stones += 1
					stone = c
		var faces := 0
		var sbox := []
		var foot := INF
		if stone != null:
			var m: Array = stone.get_meshes()
			if m.size() == 2 and m[1] != null: faces = (m[1] as Mesh).get_faces().size() / 3
			var gb: AABB = stone.global_transform * stone.get_aabb()
			sbox = _box(gb)
			foot = gb.position.y
		var hits := []
		var own_first := false
		for h in [0.2, 0.95, 1.45]:
			var from: Vector3 = mount.global_position + mount.global_transform.basis.z.normalized() * 1.5 + Vector3(0, h, 0)
			var to: Vector3 = mount.global_position - mount.global_transform.basis.z.normalized() * 3.0 + Vector3(0, h, 0)
			var q := PhysicsRayQueryParameters3D.create(from, to)
			q.collide_with_areas = false
			var hit: Dictionary = space.intersect_ray(q)
			if hit.is_empty():
				hits.append({"h": h, "hit": "nothing"})
				continue
			var col: Node = hit.collider as Node
			var path := str(col.get_path()) if col != null else "?"
			hits.append({"h": h, "at": _box(AABB(hit.position, Vector3.ZERO)).slice(0, 3), "collider": path.right(90)})
			if h == 0.95 and col != null and art != null and art.is_ancestor_of(col): own_first = true
			if h == 0.95 and col == stone: own_first = true
		var row := {"kind": k, "mount": _box(AABB(mount.global_position, Vector3.ZERO)).slice(0, 3), "facing_z": _box(AABB(mount.global_transform.basis.z, Vector3.ZERO)).slice(0, 3),
			"children": kids, "stones": stones, "faces": faces, "stone_box": sbox, "visible": stone.is_visible_in_tree() if stone != null else false, "hits": hits}
		rows.append(row)
		t1 = t1 and stones == 1 and stone != null and str(stone.name) == "Stone" and faces > 0 and absf(foot - (level + 0.35)) < 0.05
		t2 = t2 and own_first
	# every drawn thing in the box west of the row (the visitor's side is +x): what could stand in front of the stones
	var near := []
	if mounts.size() > 0:
		var mid: Vector3 = mounts[mounts.size() / 2].global_position
		var zone := AABB(Vector3(mid.x - 3.0, level - 0.2, mid.z - 6.0), Vector3(5.0, 3.5, 12.0))
		for n in game.find_children("*", "VisualInstance3D", true, false):
			var v := n as VisualInstance3D
			if not v.is_visible_in_tree(): continue
			var inside_carving := false
			for m in mounts:
				if (m as Node).is_ancestor_of(v): inside_carving = true
			if inside_carving: continue
			var b: AABB = v.global_transform * v.get_aabb()
			if b.intersects(zone): near.append({"node": str(v.get_path()).right(110), "class": v.get_class(), "box": _box(b)})
			if near.size() >= 40: break
	var checks := [
		{"check": "T1 every carving has one stone named Stone with a mesh, its foot on the plinth's top (level + 0.35 m)", "ok": t1},
		{"check": "T2 a ray from 1.5 m in front of each carving, at the column's middle, hits that carving's own stone first", "ok": t2},
	]
	var result := {"checks": checks, "passed": t1 and t2, "floor": floor, "map": str(game.building.content.data.floors[floor].map), "level": level, "rows": rows, "near": near}
	eye = SubViewport.new()
	eye.size = Vector2i(1280, 800)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	cam = Camera3D.new()
	cam.fov = 70
	eye.add_child(cam)
	cam.current = true
	if mounts.size() == 7:
		var mid: Vector3 = (mounts[3] as Node3D).global_position
		var front: Vector3 = (mounts[3] as Node3D).global_transform.basis.z.normalized()
		await _shot(mid + front * 5.5 + Vector3(0, 1.5, 0), mid + Vector3(0, 0.9, 0), folder.path_join("carvings_front.png"))
		await _shot(mid + front * 1.0 + Vector3(0, 9.0, 0), mid + front * 1.0, folder.path_join("carvings_top.png"), Vector3(0, 0, -1))
		var five: Vector3 = (mounts[5] as Node3D).global_position
		await _shot(five + front * 2.0 + Vector3(0, 1.2, 0.5), five + Vector3(0, 0.9, 0), folder.path_join("carving_close.png"))
	var fh := FileAccess.open(folder.path_join("carvings_diag.json"), FileAccess.WRITE)
	fh.store_string(JSON.stringify(result, "\t"))
	fh.close()
	quit()
