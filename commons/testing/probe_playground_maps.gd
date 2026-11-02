extends Node3D
## THE FACADE TOWN AND THE MOSAIC DECKS (Palle, 2026-11-02: "the mini town using the facade work and mosaics inside
## the playground scaffolding; the facade work should be a bit elevated, like the playground structure is holding the
## facade from one metre up in the air ... test this inside their maps, then later move to the skyscraper").
## Each spec in commons/data/playgrounds/maps/ for a facade or mosaic map is built in the spec hall the way its trial
## floor builds it. Checks: (A) both compile clean; (B) the town: eleven facade plans stand, every one's lowest mesh
## at or above 1 m - held up by its frame, the gap under it open - fitted inside its frame (no wider than the board,
## centred on it) and turned to face the street; (C) the decks: five mosaic floors stand on plates at 1 m,
## a ray from above meets a body at 1 m at each deck's centre - walkable - and the same ray between two decks meets
## nothing up there (negative). Pictures: ada_run/workstation/town_*.png, decks_*.png; report playground_maps.json.
## Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_playground_maps.tscn

const HALL = preload("res://commons/void/trials/playground_recipes/spec_hall.tscn")
const TOWN := "res://commons/data/playgrounds/maps/Facade_Assembly_Principle.json"
const DECKS := "res://commons/data/playgrounds/maps/Mosaic_Pompeii_Floors.json"
const MOSAICS := ["pompeii_mosaic_floor", "diamonds_squares_floor", "octagon_square_floor", "tumbling_blocks_floor", "free_meander_floor"]

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .7;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 35, 0);sun.light_energy = 1.1;sun.shadow_enabled = true;add_child(sun)
	var ground := StaticBody3D.new();var gs := CollisionShape3D.new();var gb := BoxShape3D.new();gb.size = Vector3(80, .2, 60);gs.shape = gb;gs.position.y = -.1;ground.add_child(gs)
	var gm := MeshInstance3D.new();var pm := PlaneMesh.new();pm.size = Vector2(80, 60);gm.mesh = pm;var gmat := StandardMaterial3D.new();gmat.albedo_color = Color("6d6a66");gm.material_override = gmat;ground.add_child(gm);add_child(ground)
	var cam := Camera3D.new();add_child(cam);cam.current = true;cam.fov = 55
	var report := {"checks": []}
	# A - both compile
	var builder = load("res://commons/modular/places/place_builder.gd")
	var errs := {}
	for path in [TOWN, DECKS]:
		var built: Dictionary = builder.new().compile(JSON.parse_string(FileAccess.get_file_as_string(path)))
		errs[path.get_file()] = built.get("errors", [])
	_check(report, "A compile: the facade town and the mosaic decks compile clean", errs.values().all(func(v): return (v as Array).is_empty()), errs)
	# B - the town
	var town: Node3D = HALL.instantiate();town.set_meta("config_spec", TOWN);add_child(town)
	for i in 8:
		await get_tree().physics_frame
	var fronts := [];var low := INF;var fitted := 0;var rows := []
	var town_spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TOWN))
	var boards := {}
	for bd in town_spec.boards:boards[str(bd.id) + "_01"] = bd
	for c in town.get_children():
		if c.get_meta("activity_artifact", "") == "facade_builder":fronts.append(c)
	for f in fronts:
		var box := _aabb(f);var bd: Dictionary = boards.get(str(f.name), {})
		low = minf(low, box.position.y)
		var w := float(bd.size[0]) if bd else 0.0;var along_x: bool = str(bd.get("facing", "south")) in ["north", "south"]
		var span: float = box.size.x if along_x else box.size.z
		var mid: float = box.get_center().x if along_x else box.get_center().z
		var line: float = float(bd.at[0]) if along_x else float(bd.at[2])
		# the front's yaw: facing's yaw plus the artifact turn (a facade's front is +Z)
		var want_yaw: float = fposmod({"south": 0.0, "north": 180.0, "east": 90.0, "west": -90.0}[str(bd.facing)] + 180.0, 360.0)
		var ok_fit: bool = span <= w + .05 and absf(mid - line) < .3 and absf(fposmod(f.rotation_degrees.y, 360.0) - want_yaw) < 1.0
		if ok_fit:fitted += 1
		rows.append({"name": str(f.name), "plan": str(bd.content.plan_path).get_file(), "low": snappedf(box.position.y, .01), "span": snappedf(span, .01), "board_w": w, "off_centre": snappedf(mid - line, .01), "scale": f.get_meta("fit_scale", 1.0), "yaw": snappedf(f.rotation_degrees.y, .1)})
	_check(report, "B town: eleven fronts stand, the lowest at %.2f m - held a metre up - %d of %d fitted in their frames and turned to the street" % [low, fitted, fronts.size()], fronts.size() == 11 and low >= .95 and fitted == fronts.size(), {"fronts": rows})
	var shots := {"town_street": [Vector3(-15, 1.7, 0), Vector3(0, 3, 0)], "town_above": [Vector3(-16, 11, 15), Vector3(0, 2.5, 0)], "town_under": [Vector3(-6, .6, 1.2), Vector3(0, .9, -3.5)]}
	await _shoot(cam, shots, out_dir)
	town.free()
	# C - the decks
	var decks: Node3D = HALL.instantiate();decks.set_meta("config_spec", DECKS);add_child(decks)
	for i in 8:
		await get_tree().physics_frame
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DECKS))
	var found := {};var walk := [];var space := get_world_3d().direct_space_state
	for c in decks.get_children():
		var tok := str(c.get_meta("activity_artifact", ""))
		if tok in MOSAICS:found[tok] = c.position
	for p in spec.places:
		var at := Vector3(float(p.at[0]), 0, float(p.at[1]))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(decks.to_global(at + Vector3(0, 6, 0)), decks.to_global(at + Vector3(0, .5, 0))))
		walk.append({"deck": p.id, "hit_y": snappedf(decks.to_local(hit.position).y, .01) if hit else null})
	var on_decks: bool = walk.all(func(w): return w.hit_y != null and absf(float(w.hit_y) - 1.0) < .1)
	var between := Vector3(-15, 0, -6)   # between the first two decks, behind their envelopes
	var miss := space.intersect_ray(PhysicsRayQueryParameters3D.create(decks.to_global(between + Vector3(0, 6, 0)), decks.to_global(between + Vector3(0, .5, 0))))
	var lifted: bool = found.size() == 5 and found.values().all(func(v): return absf(v.y - 1.03) < .01)
	_check(report, "C decks: five mosaic floors lie on plates at 1 m, each deck walkable at its centre; between the decks nothing up there", lifted and on_decks and miss.is_empty(), {"found": found, "walk": walk, "between": miss.get("position", null)})
	shots = {"decks_row": [Vector3(-27, 9, 15), Vector3(0, 1, 0)], "decks_on": [Vector3(-11, 2.7, 3.5), Vector3(-10, 1, -1.5)], "decks_meander": [Vector3(19, 4.5, 6), Vector3(20, 1, 0)]}
	await _shoot(cam, shots, out_dir)
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("playground_maps.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_playground_maps] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _shoot(cam: Camera3D, shots: Dictionary, out_dir: String) -> void:
	for k in shots:
		cam.transform = Transform3D(Basis(), shots[k][0]).looking_at(shots[k][1])
		for t in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s.png" % k))

## The world AABB of every visible mesh under a node.
func _aabb(n: Node) -> AABB:
	var box := AABB();var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():continue
		var b: AABB = mi.global_transform * mi.mesh.get_aabb()
		box = b if first else box.merge(b);first = false
	return box

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_playground_maps] %s  %s" % ["ok  " if ok else "FAIL", what])
