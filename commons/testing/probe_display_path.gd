extends Node3D
## THE DISPLAY PLATE AND THE FLOOR PATH (Palle, 2026-10-31: "the shader screen on the floor should be walkable glass";
## "a gallery with standalone big-screen square screens down a path"). (A) a floor plate 3 x 3 with the Tiling chapter's
## shader: its face carries that ShaderMaterial with the parameters set, its body is a thin box you stand on - a ray
## from above meets the glass at the plate's thickness; (B) a wall plate with a stand: stood up, its face looking along
## -Z, two posts; (C) a wallpaper plate carries the wallpaper shader over a painted domain; (D) the principal-places
## hall builds the Shader_05 floor path - ten walkable screens in a row - and five standing posters beside it, from
## its recipe. Pictures: the path from the walker's end and from above. ada_run/workstation/display_path.json.
## Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_display_path.tscn

const Items = preload("res://commons/player/inventory_items.gd")
const HALL = preload("res://commons/void/trials/principal_places/places.tscn")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .7;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-55, 35, 0);sun.light_energy = 1.0;sun.shadow_enabled = true;add_child(sun)
	var cam := Camera3D.new();add_child(cam);cam.current = true;cam.fov = 55
	var report := {"checks": []}
	var bench := Node3D.new();bench.name = "Bench";bench.position = Vector3(0, 0, 60);add_child(bench)
	# A - a floor plate with the Tiling shader
	var floor_cfg := {"slot_size": [3, 3], "mount": "floor", "content": "shader", "shader": "res://algorithms/shaders/book_of_shaders/patterns_tile.gdshader", "params": {"grid_size": 5.0, "shape_size": 0.3}, "title": "Tiling"}
	var fp: Node3D = load(Items.scene_for("display_plate")).instantiate()
	for k in floor_cfg:fp.set_meta("config_%s" % k, floor_cfg[k])
	bench.add_child(fp)
	for i in 3:
		await get_tree().physics_frame
	var mat: Material = fp.face.material_override
	var is_shader: bool = mat is ShaderMaterial and (mat as ShaderMaterial).shader != null and (mat as ShaderMaterial).shader.resource_path.ends_with("patterns_tile.gdshader") and is_equal_approx(float((mat as ShaderMaterial).get_shader_parameter("grid_size")), 5.0)
	var from := fp.global_position + Vector3(0.5, 2, 0.5)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 4.0, 1);var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var glass: bool = not hit.is_empty() and hit.collider == fp.body and absf(hit.position.y - (fp.global_position.y + 0.04)) < .005
	var shape: BoxShape3D = (fp.body.get_child(0) as CollisionShape3D).shape
	_check(report, "A floor plate: the Tiling shader on its face with grid_size 5; walkable glass - a ray from above meets its 3 x 3 x 0.04 body at the top", is_shader and glass and shape.size.is_equal_approx(Vector3(3, 0.04, 3)), {"shader": is_shader, "hit": hit.get("position", null), "shape": shape.size})
	# B - a wall plate on its own posts
	var wall_cfg := {"slot_size": [2, 2], "mount": "wall", "stand": true, "content": "colour", "colour": "#e03a7d", "title": "poster"}
	var wp: Node3D = load(Items.scene_for("display_plate")).instantiate()
	for k in wall_cfg:wp.set_meta("config_%s" % k, wall_cfg[k])
	wp.position = Vector3(5, 0, 0);bench.add_child(wp)
	for i in 3:
		await get_tree().physics_frame
	var plate_node: Node3D = wp.get_node("Plate");var face_dir: Vector3 = (plate_node.global_transform.basis * (wp.face.global_transform.basis.z.normalized() if false else Vector3(0, 1, 0))).normalized()
	var face_world: Vector3 = (wp.face.global_transform.basis * Vector3(0, 0, 1)).normalized()   # a QuadMesh faces +Z in its own space
	var posts: int = wp.get_children().filter(func(c): return c is MeshInstance3D and c.mesh is CylinderMesh).size()
	var wall_hit_from := wp.global_position + Vector3(0, 1, -3)
	var wq := PhysicsRayQueryParameters3D.create(wall_hit_from, wall_hit_from + Vector3.BACK * 6.0, 1);var whit := get_world_3d().direct_space_state.intersect_ray(wq)
	var stands: bool = face_world.dot(Vector3.FORWARD) > .99 and posts == 2 and not whit.is_empty() and whit.collider == wp.body and absf(whit.position.y - 1.0) < .01
	_check(report, "B wall plate: stood up on two posts, its face looking along -Z into the room, a ray across the room meets its glass", stands, {"face": face_world, "posts": posts, "hit": whit.get("position", null)})
	# C - a wallpaper plate
	var paper_cfg := {"slot_size": [3, 3], "content": "wallpaper", "wallpaper_group": 4, "repeats": 3.0, "seed": 9}
	var pp: Node3D = load(Items.scene_for("display_plate")).instantiate()
	for k in paper_cfg:pp.set_meta("config_%s" % k, paper_cfg[k])
	pp.position = Vector3(-5, 0, 0);bench.add_child(pp)
	for i in 2:
		await get_tree().physics_frame
	var pm: Material = pp.face.material_override
	var papered: bool = pm is ShaderMaterial and (pm as ShaderMaterial).shader.resource_path.ends_with("wallpaper_tile.gdshader") and (pm as ShaderMaterial).get_shader_parameter("domain_texture") is Texture2D and int((pm as ShaderMaterial).get_shader_parameter("wallpaper_group")) == 4
	_check(report, "C wallpaper plate: the wallpaper shader over a painted 4 x 4 domain, group 4", papered, {"papered": papered})
	# D - the floor path and posters, as boards in the ANNEX (moved off floor 210's slab, 2026-11-02)
	var hall: Node3D = load("res://commons/void/trials/playground_recipes/spec_hall.tscn").instantiate();hall.set_meta("config_spec", "res://commons/data/playgrounds/halls/playground_annex.json");add_child(hall)
	for i in 6:
		await get_tree().physics_frame
	var screens := [];var posters := []
	for c in hall.get_children():
		if c.get_meta("activity_artifact", "") == "display_plate":
			if str(c.name).begins_with("shader05_posters"):posters.append(c)
			elif str(c.name).begins_with("shader05_path"):screens.append(c)
	screens.sort_custom(func(a, b): return a.position.x < b.position.x)
	var in_row: bool = screens.size() == 10 and screens.all(func(s): return absf(s.position.z - 10.0) < .01 and absf(s.position.y - 0.08) < 1e-3)   # a board's plate rests PLATE_LIFT over its frame
	var spaced: bool = screens.size() == 10 and absf((screens[9].position.x - screens[0].position.x) / 9.0 - 4.0) < .01
	var shaders_differ: bool = screens.size() == 10 and screens.map(func(s): return s.shader_path + str(s.params)).reduce(func(acc, v): return acc if v in acc else acc + [v], []).size() == 10
	_check(report, "D hall: the Shader_05 floor path - ten walkable screens 4 m apart along z 10, ten different contents - and five standing posters behind it", in_row and spaced and shaders_differ and posters.size() == 5, {"screens": screens.size(), "posters": posters.size(), "spaced": spaced, "differ": shaders_differ})
	var shots := {"path_walker": [Vector3(-21, 1.7, 10), Vector3(0, 0.3, 10)], "path_above": [Vector3(0, 14, 24), Vector3(0, 0.5, 9)], "path_poster": [Vector3(-9, 1.6, 7), Vector3(-7.6, 1.0, 12.4)]}
	for k in shots:
		cam.transform = Transform3D(Basis(), shots[k][0]).looking_at(shots[k][1])
		for t in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s.png" % k))
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("display_path.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_display_path] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_display_path] %s  %s" % ["ok  " if ok else "FAIL", what])
