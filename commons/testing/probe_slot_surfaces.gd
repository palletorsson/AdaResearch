extends Node3D
## THE WALKABLE SURFACES IN A SLOT (Palle, 2026-10-31: "parameterise and edge-secure the artifacts so each slots into the
## playground or stands self-sufficient - start with the sine space (its floor), the random space and the noise space"). For each of
## the three, told a 10 x 8 m slot 1 m deep: (A) it fits - footprint 9 x 7 (the half-metre margin), its lowest point on the
## floor, its highest under the rim; (B) it is edge-secured - every perimeter vertex at the floor; (C) it has trimesh
## collision and a ray down at the margin meets the floor; (D) with no slot it is the surface it always was (full 20 x 20,
## relief both sides of zero); (E) place_builder compiles a place with an activity into recipe.activities carrying the
## slot, place_activity builds and fits it. Writes ada_run/workstation/slot_surfaces.json and a picture.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_slot_surfaces.tscn

const Items = preload("res://commons/player/inventory_items.gd")
const Builder = preload("res://commons/modular/places/place_builder.gd")
const Activity = preload("res://commons/modular/places/place_activity.gd")
const TOKENS := ["noise_space", "random_space", "sine_space_floor"]

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .8;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var cam := Camera3D.new();add_child(cam);cam.current = true
	var report := {"checks": []}
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(60, .1, 60);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var slot := {"slot_size": [10, 8], "slot_depth": 1.0, "slot_margin": 0.5, "edge_band": 1.0}
	var i := 0
	for token in TOKENS:
		var path: String = Items.scene_for(token)
		var node: Node3D = load(path).instantiate()
		for k in slot:node.set_meta("config_%s" % k, slot[k])
		node.position = Vector3(i * 14.0 - 14.0, 0, 0);add_child(node);node.apply_grid_config(slot)
		for f in 3:
			await get_tree().physics_frame
		var mi: MeshInstance3D = node.mesh_instance;var box: AABB = mi.mesh.get_aabb()
		var fits: bool = absf(box.size.x - 9.0) < .05 and absf(box.size.z - 7.0) < .05 and absf(box.position.y) < 1e-3 and box.end.y <= 0.9 + 1e-3 and box.end.y > 0.05
		_check(report, "A %s fits: 9 x 7 m in the 10 x 8 slot, lowest point on the floor, highest under the rim" % token, fits, {"size": box.size, "low": box.position.y, "high": box.end.y})
		# B - the perimeter at the floor
		var verts: PackedVector3Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var worst := 0.0;var rim_n := 0
		for v in verts:
			if absf(v.x) > 4.5 - 1e-3 or absf(v.z) > 3.5 - 1e-3:rim_n += 1;worst = maxf(worst, absf(v.y))
		_check(report, "B %s edge-secured: every perimeter vertex at the floor" % token, rim_n > 100 and worst < 1e-3, {"perimeter_vertices": rim_n, "worst": worst})
		# C - collision: a ray down at the margin meets the floor height
		var shape_ok: bool = node.collision_shape.shape is ConcavePolygonShape3D
		var from: Vector3 = node.global_position + Vector3(4.45, 3, 3.45)   # 5 cm in from the perimeter, where the band has faded to the floor
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 6.0, 1);var hit := get_world_3d().direct_space_state.intersect_ray(q)
		var floor_hit: bool = not hit.is_empty() and absf(hit.position.y - node.global_position.y) < .02 and hit.collider == node.static_body
		_check(report, "C %s collision: trimesh, and a ray at the margin lands on the floor" % token, shape_ok and floor_hit, {"shape": str(node.collision_shape.shape), "hit_y": hit.get("position", null), "collider": str(hit.collider.name) if not hit.is_empty() else "-"})
		i += 1
	# D - no slot: the surface as it always was
	var plain: Node3D = load(Items.scene_for("sine_space_floor")).instantiate();plain.gravity_point_test = false;plain.position = Vector3(0, 0, 30);add_child(plain)
	for f in 2:
		await get_tree().physics_frame
	var pbox: AABB = plain.mesh_instance.mesh.get_aabb()
	_check(report, "D no slot: the sine floor keeps its own 11 x 20 m and its relief both sides of zero", absf(pbox.size.x - 11) < .05 and absf(pbox.size.z - 20) < .05 and pbox.position.y < -.5 and pbox.end.y > .5 and not plain.fitted, {"size": pbox.size, "low": pbox.position.y, "high": pbox.end.y})
	plain.queue_free()
	# E - the place: a 10 x 8 plastic pool 1 m deep at y 4 with the noise space as its activity
	var spec := {"version": 1, "units": "metres", "places": [{"id": "place", "at": [0, 0], "y": 4, "size": [10, 8], "depth": 1, "type": "plastic_pool", "rim": 1, "access": {"outer": "ramp", "inner": "ramp"}, "activity": {"artifact": "noise_space", "config": {"height_scale": 1.0, "noise_scale": 3.0}}}]}
	var built: Dictionary = Builder.new().compile(spec)
	var acts: Array = built.get("recipe", {}).get("activities", [])
	var act_ok: bool = (built.get("errors", []) as Array).is_empty() and acts.size() == 1 and acts[0].artifact == "noise_space" and acts[0].config.slot_size == [10, 8] and is_equal_approx(float(acts[0].config.slot_depth), 1.0) and is_equal_approx(float(acts[0].position[1]), 3.0) and is_equal_approx(float(acts[0].config.noise_scale), 3.0)
	var made: Node3D = Activity.build(acts[0]) if acts.size() == 1 else null
	if made:add_child(made);Activity.fit(made, acts[0])
	for f in 3:
		await get_tree().physics_frame
	var mbox: AABB = made.mesh_instance.mesh.get_aabb() if made else AABB()
	var made_ok: bool = made != null and is_equal_approx(made.position.y, 3.0) and absf(mbox.size.x - 9.0) < .05 and mbox.end.y <= .9 + 1e-3 and made.fitted
	_check(report, "E place: compiled with an activity - recipe.activities carries the slot and the knobs; place_activity builds the noise space on the pool floor at y 3, fitted", act_ok and made_ok, {"errors": built.get("errors", []), "activities": acts, "made_y": made.position.y if made else null, "size": mbox.size})
	# F - WALLS TOO: the noise surface mounted "wall" in a 10 m wide, 1 m high slot stands up - 9 m wide, 1 m high from
	# its base line, its relief toward -Z and no deeper than 0.4 m, flat at its edges
	var wall: Node3D = load(Items.scene_for("noise_space")).instantiate()
	var wall_cfg := {"mount": "wall", "slot_size": [10, 1.5], "slot_depth": 0.5, "slot_margin": 0.5, "edge_band": 1.0, "height_scale": 2.0}
	for k in wall_cfg:wall.set_meta("config_%s" % k, wall_cfg[k])
	wall.position = Vector3(0, 0, -12);add_child(wall);wall.apply_grid_config(wall_cfg)
	for f in 3:
		await get_tree().physics_frame
	var wb: AABB = wall.static_body.transform * wall.mesh_instance.mesh.get_aabb()   # in the node's space: the wall's base line at the origin
	var stands: bool = absf(wb.size.x - 9.0) < .05 and absf(wb.position.y) < 1e-3 and absf(wb.size.y - 1.0) < .05 and wb.end.z <= 1e-3 and wb.position.z >= -0.4 - 1e-3 and wb.position.z < -0.05
	var top_from := wall.global_position + Vector3(0, 0.5, -3.0)
	var wq := PhysicsRayQueryParameters3D.create(top_from, top_from + Vector3.BACK * 6.0, 1);var whit := get_world_3d().direct_space_state.intersect_ray(wq)
	var wall_hit: bool = not whit.is_empty() and whit.collider == wall.static_body and whit.position.z < wall.global_position.z + 1e-3 and whit.position.z > wall.global_position.z - 0.45
	_check(report, "F wall: mounted wall, the noise surface stands 9 m wide and 1 m high from its base line, relief into -Z under 0.4 m, and a ray across the room meets it", stands and wall_hit, {"box": wb, "hit": whit.get("position", null)})
	# G - the builder puts a wall activity at the pool's south wall, just inside the shell, facing the room
	var wspec := {"version": 1, "units": "metres", "places": [{"id": "place", "at": [0, 0], "y": 4, "size": [10, 8], "depth": 1, "type": "plastic_pool", "rim": 1, "access": {"outer": "ramp", "inner": "ramp"}, "activity": {"artifact": "sine_space_floor", "mount": "wall", "side": "east"}}]}
	var wbuilt: Dictionary = Builder.new().compile(wspec);var wacts: Array = wbuilt.get("recipe", {}).get("activities", [])
	var g_ok: bool = (wbuilt.get("errors", []) as Array).is_empty() and wacts.size() == 1 and wacts[0].config.mount == "wall" and is_equal_approx(float(wacts[0].config.slot_size[0]), 8.0) and is_equal_approx(float(wacts[0].config.slot_size[1]), 1.0) and is_equal_approx(float(wacts[0].position[0]), 5.0 - 0.13) and is_equal_approx(float(wacts[0].rotation[1]), 90.0)
	var wmade: Node3D = Activity.build(wacts[0]) if wacts.size() == 1 else null
	if wmade:add_child(wmade);Activity.fit(wmade, wacts[0])
	for f in 3:
		await get_tree().physics_frame
	var wmb: AABB = (wmade.global_transform * wmade.static_body.transform * wmade.mesh_instance.mesh.get_aabb()) if wmade else AABB()
	var g_made: bool = wmade != null and wmade.mount == "wall" and absf(wmb.size.z - 7.0) < .05 and wmb.position.x < 4.87 and wmb.end.x <= 4.87 + 1e-3 and absf(wmb.position.y - 3.0) < 1e-3
	_check(report, "G place wall: the east wall activity stands just inside the shell at x 4.87, turned to face the room, 7 m along the wall from the pool floor at y 3", g_ok and g_made, {"errors": wbuilt.get("errors", []), "act": wacts, "box": wmb, "g_ok": g_ok, "g_made": g_made, "pos_eq": is_equal_approx(float(wacts[0].position[0]), 5.0 - 0.13) if wacts.size() == 1 else null, "end_x": wmb.end.x, "mount": wmade.mount if wmade else null})
	cam.transform = Transform3D(Basis(), Vector3(0, 9, 16)).looking_at(Vector3(0, 0.5, 0));cam.fov = 55
	for f in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("slot_surfaces.png"))
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("slot_surfaces.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_slot_surfaces] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_slot_surfaces] %s  %s" % ["ok  " if ok else "FAIL", what])
