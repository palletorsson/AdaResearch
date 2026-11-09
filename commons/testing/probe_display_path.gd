extends Node3D
## THE DISPLAY PLATE AND THE FLOOR PATH (Palle, 2026-10-31: "the shader screen on the floor should be walkable glass";
## "a gallery with standalone big-screen square screens down a path"). (A) a floor plate 3 x 3 with the Tiling chapter's
## shader: its face carries that ShaderMaterial with the parameters set, its body is a thin box you stand on - a ray
## from above meets the glass at the plate's thickness; (B) a wall plate with a stand: stood up, its face looking along
## -Z, two posts; (C) a wallpaper plate carries the wallpaper shader over a painted domain; (D) the principal-places
## hall builds the Shader_05 floor path - ten walkable screens in a row - and five standing posters beside it, from
## its recipe. Pictures: the path from the walker's end and from above. ada_run/workstation/display_path.json.
## (F, 2026-11-09) WEAR: plates wear a work's live shader material - a chapter work's material i, the composition
## stage's own; a missing work leaves the plate its own shader; a board says it once and copy i wears material i.
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
	# E - walking onto the walkable glass (2026-11-02: the desktop walker was stopped by the frame's bar and the 12 cm
	# glass edge; a skirt ramps onto every ground-level screen): from the ground at the path's south side onto screen 01
	var floor_body := StaticBody3D.new();var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(60, .2, 40);fs.shape = fb;fs.position.y = -.1;floor_body.add_child(fs);add_child(floor_body)
	var walker: CharacterBody3D = load("res://commons/void/walker.gd").new();walker.scripted_input = true;add_child(walker)
	walker.global_position = hall.to_global(Vector3(-18, .02, 7.2))
	for i in 30:
		await get_tree().physics_frame
	walker.drive = Vector2(0, 1)
	var mid_y := -1.0
	for i in 120:
		await get_tree().physics_frame
		var at_now := hall.to_local(walker.global_position)
		if at_now.z > 9.5 and at_now.z < 10.5:mid_y = at_now.y   # the middle of the screen
	walker.drive = Vector2.ZERO
	var end := hall.to_local(walker.global_position)
	cam.make_current()
	_check(report, "E walk on: from the ground the walker walks across the first screen - mid-screen it stands on the glass at %.3f m" % mid_y, absf(mid_y - .12) < .02, {"mid_y": mid_y, "end": [end.x, end.y, end.z]})
	# F - WEAR (Palle, 2026-11-09: "the playground's own panels wear the shaders as a gallery ... mixed with the existing
	# shader setup"): a plate wears a work's LIVE material - the same instance - so the work's controls change the gallery
	var room := Node3D.new();room.name = "WearRoom";room.position = Vector3(0, 0, -60);add_child(room)
	var chapter_src := GDScript.new()
	chapter_src.source_code = "extends Node3D
var _materials: Array[ShaderMaterial] = []
func _ready():
	for p in ['patterns_tile', 'patterns_truchet', 'patterns_brick']:
		var m := ShaderMaterial.new(); m.shader = load('res://algorithms/shaders/book_of_shaders/%s.gdshader' % p); _materials.append(m)
"
	chapter_src.reload()
	var chapter := Node3D.new();chapter.name = "chapter_work";chapter.set_script(chapter_src);room.add_child(chapter)
	var worn: Node3D = load(Items.scene_for("display_plate")).instantiate()
	var cfg_1 := {"slot_size": [3, 3], "mount": "wall", "content": "colour", "wear": "chapter_work", "wear_index": 1, "title": "worn"}
	for k in cfg_1:worn.set_meta("config_%s" % k, cfg_1[k])
	room.add_child(worn)
	var lost: Node3D = load(Items.scene_for("display_plate")).instantiate()
	var cfg_2 := {"slot_size": [3, 3], "content": "shader", "shader": "res://algorithms/shaders/book_of_shaders/patterns_tile.gdshader", "wear": "nobody_here", "title": "lost"}
	for k in cfg_2:lost.set_meta("config_%s" % k, cfg_2[k])
	room.add_child(lost);lost.position.x = 5
	var stage: Node3D = load("res://commons/artifacts/shader_composition_stage/shader_composition_stage.tscn").instantiate();stage.name = "stage_work";stage.position.x = -14;room.add_child(stage)
	var surround: Node3D = load(Items.scene_for("display_plate")).instantiate()
	var cfg_3 := {"slot_size": [3, 3], "mount": "wall", "wear": "stage_work"}
	for k in cfg_3:surround.set_meta("config_%s" % k, cfg_3[k])
	room.add_child(surround);surround.position.x = -8
	for i in 20:
		await get_tree().physics_frame
	var same: bool = worn.face.material_override == chapter._materials[1]
	chapter._materials[1].set_shader_parameter("grid_size", 11.0)
	var live: bool = is_equal_approx(float((worn.face.material_override as ShaderMaterial).get_shader_parameter("grid_size")), 11.0)
	_check(report, "F wear: a plate wears the chapter work's material 1 - the same instance - and a slider's change on the work shows on the plate", same and live and str(worn.get_meta("wearing", "")) == "chapter_work#patterns_truchet.gdshader", {"same": same, "live": live, "wearing": worn.get_meta("wearing", "")})
	var stage_mat: Variant = stage.get("material")
	_check(report, "F wear: a plate wears the composition stage's own material - its sofa, sphere, cube and the plate are one surface", stage_mat is ShaderMaterial and surround.face.material_override == stage_mat, {"wearing": surround.get_meta("wearing", "")})
	_check(report, "F wear: a plate whose work is not on the floor keeps its own shader (no silent blank)", lost.face.material_override is ShaderMaterial and (lost.face.material_override as ShaderMaterial).shader.resource_path.ends_with("patterns_tile.gdshader") and not lost.has_meta("wearing"), {"own": str(lost.face.material_override)})
	# by shader: a plate naming its own shader wears the work's material with that shader; a mode switch follows
	var bricks: Node3D = load(Items.scene_for("display_plate")).instantiate()
	var cfg_b := {"slot_size": [2, 2], "content": "shader", "shader": "res://algorithms/shaders/book_of_shaders/patterns_brick.gdshader", "params": {"rows": 8.0}, "wear": "chapter_work", "wear_index": 0}
	for k in cfg_b:bricks.set_meta("config_%s" % k, cfg_b[k])
	room.add_child(bricks);bricks.position.x = 9
	var trux: Node3D = load(Items.scene_for("display_plate")).instantiate()
	var cfg_t := {"slot_size": [2, 2], "content": "shader", "shader": "res://algorithms/shaders/book_of_shaders/patterns_truchet.gdshader", "wear": "chapter_work"}
	for k in cfg_t:trux.set_meta("config_%s" % k, cfg_t[k])
	room.add_child(trux);trux.position.x = 12
	for i in 12:
		await get_tree().physics_frame
	var by_shader: bool = bricks.face.material_override == chapter._materials[2] and trux.face.material_override == chapter._materials[1]
	_check(report, "F wear by shader: the brick plate wears the work's brick material (its 3rd), the truchet plate the truchet - not by index", by_shader, {"bricks": bricks.get_meta("wearing", ""), "trux": trux.get_meta("wearing", "")})
	var fresh := ShaderMaterial.new();fresh.shader = load("res://algorithms/shaders/book_of_shaders/patterns_truchet.gdshader")
	chapter._materials.clear();chapter._materials.append(fresh)   # the console switched mode: only a new truchet now
	await get_tree().create_timer(1.6).timeout
	var followed: bool = trux.face.material_override == fresh and bricks.face.material_override is ShaderMaterial and bricks.face.material_override != fresh and (bricks.face.material_override as ShaderMaterial).shader.resource_path.ends_with("patterns_brick.gdshader") and not bricks.has_meta("wearing")
	_check(report, "F wear follows a mode switch: the truchet plate takes the console's new truchet; the brick plate, no longer worn, shows its own brick again", followed, {"trux": trux.get_meta("wearing", ""), "bricks_missing": bricks.get_meta("wear_missing", "")})
	var Builder := load("res://commons/modular/places/place_builder.gd")
	var wspec := {"version": 1, "units": "metres", "places": [], "boards": [{"id": "gallery", "at": [0, 0, 0], "size": [3, 3], "orient": "wall", "facing": "south", "repeat": {"count": 4, "step": [4, 0, 0]}, "wear": "chapter_work", "wear_cycle": 3}]}
	var compiled: Dictionary = Builder.new().compile(wspec)
	var acts: Array = (compiled.get("recipe", compiled) as Dictionary).get("activities", [])
	var idx: Array = acts.filter(func(a): return a.get("board", "") == "gallery").map(func(a): return int(a.config.get("wear_index", -1)))
	_check(report, "F wear: a board says it once - copy i wears material i, cycling every 3 (indices %s)" % str(idx), idx == [0, 1, 2, 0], {"indices": idx, "errors": compiled.get("errors", [])})
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
