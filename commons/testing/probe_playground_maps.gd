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
		if tok in MOSAICS and str(c.name).ends_with("_activity"):found[tok] = c.position   # the decks' own, not the field's
	for p in spec.places:
		var at := Vector3(float(p.at[0]), 0, float(p.at[1]))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(decks.to_global(at + Vector3(0, 6, 0)), decks.to_global(at + Vector3(0, .5, 0))))
		walk.append({"deck": p.id, "hit_y": snappedf(decks.to_local(hit.position).y, .01) if hit else null})
	var on_decks: bool = walk.all(func(w): return w.hit_y != null and absf(float(w.hit_y) - 1.0) < .1)
	var between := Vector3(-15, 0, -20)   # behind the decks' envelopes (z -18..-8), clear of the field
	var miss := space.intersect_ray(PhysicsRayQueryParameters3D.create(decks.to_global(between + Vector3(0, 6, 0)), decks.to_global(between + Vector3(0, .5, 0))))
	var lifted: bool = found.size() == 5 and found.values().all(func(v): return absf(v.y - 1.03) < .01)
	_check(report, "C decks: five mosaic floors lie on plates at 1 m, each deck walkable at its centre; between the decks nothing up there", lifted and on_decks and miss.is_empty(), {"found": found, "walk": walk, "between": miss.get("position", null)})
	# D - the field of every mosaic floor (Palle: "can I walk all floors - I mean the mosaic floors")
	var field := [];var tokens := {};var empty: Array = [];var field_fit := 0;var walkable := 0;var field_rows := []
	for b in spec.boards:
		var r: Dictionary = b.get("repeat", {});var per: int = int(r.get("count", 1));var n: int = per * int((r.get("rows", {}) as Dictionary).get("count", 1))
		for i in n:
			var at := Vector3(float(b.at[0]), float(b.at[1]), float(b.at[2])) + Vector3(float(r.step[0]), 0, float(r.step[2])) * (i % per)
			if r.has("rows"):at += Vector3(float(r.rows.step[0]), 0, float(r.rows.step[2])) * int(i / per)
			field.append({"id": "%s_%02d" % [b.id, i + 1], "at": at, "token": str(b.contents[i].artifact)})
	for f in field:
		var node: Node3D = decks.get_node_or_null(str(f.id))
		var box := _aabb(node) if node else AABB()
		var fits: bool = node != null and box.size.x <= 4.05 and box.size.z <= 4.05 and box.size.x > 2.0 and absf(box.get_center().x - f.at.x) < .15 and absf(box.get_center().z - f.at.z) < .15
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(decks.to_global(f.at + Vector3(.7, 3, .7)), decks.to_global(f.at + Vector3(.7, -.5, .7))))
		var top: float = decks.to_local(hit.position).y if hit else -1.0
		var walks: bool = absf(top - .085) < .01
		if node:tokens[str(node.get_meta("activity_artifact", ""))] = true
		if node and node.get_meta("draws_nothing", false):
			# an artifact that builds no mesh: nothing to fit, still walkable, its label says so
			empty.append(f.token)
			var label: Label3D = decks.get_node_or_null(str(f.id) + "_label")
			fits = label != null and label.text.ends_with("draws nothing")
		if fits:field_fit += 1
		if walks:walkable += 1
		if not (fits and walks):field_rows.append({"id": f.id, "token": f.token, "found": node != null, "size": [snappedf(box.size.x, .01), snappedf(box.size.z, .01)], "centre": [snappedf(box.get_center().x - f.at.x, .01), snappedf(box.get_center().z - f.at.z, .01)], "top": snappedf(top, .001)})
	var beside := space.intersect_ray(PhysicsRayQueryParameters3D.create(decks.to_global(Vector3(0, 3, -7)), decks.to_global(Vector3(0, -.5, -7))))
	var beside_y: float = decks.to_local(beside.position).y if beside else -1.0
	_check(report, "D field: %d mosaic floors (%d different) - %d fitted in their 4 x 4 boards or labelled as drawing nothing (%s), %d walkable at 8.5 cm; beside the field the ray meets the ground at %.2f" % [field.size(), tokens.size(), field_fit, ", ".join(PackedStringArray(empty)) if not empty.is_empty() else "none", walkable, beside_y], field.size() == 46 and tokens.size() == 46 and field_fit == 46 and walkable == 46 and absf(beside_y) < .03, {"problems": field_rows, "draws_nothing": empty, "beside_y": beside_y})
	shots = {"decks_row": [Vector3(-27, 9, -1), Vector3(0, 1, -14)], "decks_on": [Vector3(-11, 2.7, -10.5), Vector3(-10, 1, -15.5)], "field_above": [Vector3(0, 24, 26), Vector3(0, 0, 1)], "field_walk": [Vector3(-23, 1.7, 11), Vector3(-10, 0, 0)], "field_close": [Vector3(-3, 3.2, 5), Vector3(-2, 0, 0)]}
	await _shoot(cam, shots, out_dir)
	decks.free()
	# E - the vertical plane (Palle: "we can also use the vertical plane when we curate the space"): the mosaic wall
	# example stands eight mosaic floors upright in wall frames, faces to the room; the same spec WITHOUT the tilt
	# lies flat (negative) - the tilt is what stands them up
	var wall_path := "res://commons/data/playgrounds/examples/mosaic_wall.json"
	var wall_spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(wall_path))
	var upright := await _wall_heights(wall_spec)
	var flat_spec: Dictionary = wall_spec.duplicate(true);(flat_spec.boards[0] as Dictionary).erase("artifact_tilt")
	var flat := await _wall_heights(flat_spec)
	var stood: bool = upright.size() == 8 and upright.all(func(r): return r.height > 2.9 and r.height < 3.05 and r.width <= 3.05 and r.depth < .4 and r.faces_room)
	var lay: bool = flat.size() == 8 and flat.all(func(r): return r.height < .4)
	_check(report, "E vertical plane: eight mosaic floors stand upright in 3 x 3 m wall frames, faces to the room; without the tilt the same eight lie flat", stood and lay, {"upright": upright, "flat": flat})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("playground_maps.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_playground_maps] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

## Build a wall spec in the spec hall; per mosaic: its extent across the wall, up it and out of it, and whether its
## face (the floor's own +Y) looks into the room (+Z for a north wall). Photographs the upright one.
func _wall_heights(wall_spec: Dictionary) -> Array:
	var hall: Node3D = HALL.instantiate();hall.recipe = load("res://commons/modular/places/place_builder.gd").new().compile(wall_spec).get("recipe", {});add_child(hall)
	for i in 8:
		await get_tree().physics_frame
	var rows := []
	for c in hall.get_children():
		if not str(c.name).begins_with("mosaic_wall_") or not c.has_meta("activity_artifact"):continue
		var box := _aabb(c)
		rows.append({"name": str(c.name), "token": str(c.get_meta("activity_artifact")), "width": snappedf(box.size.x, .01), "height": snappedf(box.size.y, .01), "depth": snappedf(box.size.z, .01), "faces_room": (c as Node3D).global_basis.y.normalized().dot(Vector3(0, 0, 1)) > .9})
	if (wall_spec.boards[0] as Dictionary).has("artifact_tilt"):
		var cam: Camera3D = get_viewport().get_camera_3d()
		await _shoot(cam, {"mosaic_wall": [Vector3(0, 2.2, 9), Vector3(0, 1.5, -1)], "mosaic_wall_close": [Vector3(-4, 1.7, 3), Vector3(-3, 1.5, -2)]}, ProjectSettings.globalize_path("res://ada_run/workstation"))
	hall.free()
	return rows

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
