extends SceneTree
## WARDROBE TUNNEL BENCH (commons/artifacts/wardrobe_tunnel; 2026-11-14). A tunnel alone in a lit room, then:
##   - added and THEN configured, as the tower does it: built once, in the configured skin
##   - the lining is five faces in the skin's own mode and colour; the shell is black latex
##   - collision: a ray down the middle from the mouth runs the whole inside and stops at the far wall; rays across
##     stop at the side walls; a ray up stops at the ceiling; the mouth itself is open (a ray from outside enters)
##   - a capsule a body's size stands inside, clear, 1 m in and at the far end
##   - every skin builds; a bad skin keeps the last good one; the inside follows length / width / height
##   - pictures: from the mouth looking in, for a few skins, and the outside
##
##   godot --path . --xr-mode off --script res://tools/probes/wardrobe_tunnel_bench.gd -- --out=<dir>
const Tunnel := preload("res://commons/artifacts/wardrobe_tunnel/wardrobe_tunnel.gd")
const SCENE := preload("res://commons/artifacts/wardrobe_tunnel/wardrobe_tunnel.tscn")
var checks := []
var world: Node3D
var eye: SubViewport
var cam: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _check(name: String, ok: bool, data := {}) -> void:
	checks.append({"check": name, "ok": ok}.merged(data))


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	return world.get_world_3d().direct_space_state.intersect_ray(q)


func _shot(at: Vector3, target: Vector3, path: String, fov := 70.0) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.fov = fov
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


func _run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	eye = SubViewport.new()
	eye.size = Vector2i(1280, 800)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	world = Node3D.new()
	eye.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.45, 0.6)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.77, 0.68, 0.84)
	env.environment.ambient_light_energy = 0.55
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -40, 0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := StaticBody3D.new()
	var gs := CollisionShape3D.new()
	gs.shape = BoxShape3D.new()
	gs.shape.size = Vector3(40, 0.2, 40)
	gs.position = Vector3(0, -0.1, 0)
	ground.add_child(gs)
	var gm := MeshInstance3D.new()
	gm.mesh = PlaneMesh.new()
	gm.mesh.size = Vector2(40, 40)
	ground.add_child(gm)
	world.add_child(ground)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.current = true

	# the tower's order: add, then configure; one build at the end of the frame
	var t: Node3D = SCENE.instantiate()
	world.add_child(t)
	t.apply_grid_config({"skin": "sequin", "length": "7.6", "label": "true"})
	await process_frame
	await process_frame
	var tunnel: Node3D = t.get_node_or_null("Tunnel")
	var builds := 0
	for c in t.get_children(): if c.name.begins_with("Tunnel"): builds += 1
	_check("added then configured: one build, in the configured skin", builds == 1 and t.skin == "sequin", {"builds": builds, "skin": t.skin})

	var modes := {}
	var shell_ok := true
	for n in tunnel.get_children():
		if n is MeshInstance3D and n.mesh is QuadMesh:
			var m: ShaderMaterial = n.material_override
			modes[str(n.name)] = [int(m.get_shader_parameter("mode")), m.get_shader_parameter("hue")]
		elif n is MeshInstance3D and n.mesh is BoxMesh:
			var m: ShaderMaterial = n.material_override
			if int(m.get_shader_parameter("mode")) != 0 or (m.get_shader_parameter("hue") as Color).v > 0.05: shell_ok = false
	var lining_ok := modes.size() == 5
	for k in modes: if modes[k][0] != Tunnel.SKINS.find("sequin") or modes[k][1] != Tunnel.HUES["sequin"]: lining_ok = false
	_check("the lining is five faces in the skin's mode and colour; the shell is black latex", lining_ok and shell_ok, {"faces": modes.keys(), "shell_black": shell_ok})

	await physics_frame
	await physics_frame
	var box: AABB = t.inside()
	var mid_y := 1.2
	var down := _ray(Vector3(0, mid_y, 0.5), Vector3(0, mid_y, -30))
	var far: float = -999.0 if down.is_empty() else down.position.z
	_check("a ray down the middle from the mouth runs the whole inside and stops at the far wall", absf(far - (-box.size.z)) < 0.02, {"stopped_at_z": far, "far_wall_z": -box.size.z})
	var left := _ray(Vector3(0, mid_y, -3), Vector3(-10, mid_y, -3))
	var right := _ray(Vector3(0, mid_y, -3), Vector3(10, mid_y, -3))
	var up := _ray(Vector3(0, 0.5, -3), Vector3(0, 10, -3))
	var lx: float = 999.0 if left.is_empty() else left.position.x
	var rx: float = 999.0 if right.is_empty() else right.position.x
	var uy: float = 999.0 if up.is_empty() else up.position.y
	_check("rays across stop at the side walls, a ray up at the ceiling", absf(lx + box.size.x / 2) < 0.02 and absf(rx - box.size.x / 2) < 0.02 and absf(uy - box.size.y) < 0.02, {"left": lx, "right": rx, "ceiling": uy})
	var into := _ray(Vector3(0, mid_y, 6), Vector3(0, mid_y, -1))
	_check("the mouth is open: a ray from outside enters (and only the far wall stops it)", into.is_empty(), {"hit": {} if into.is_empty() else {"z": into.position.z}})

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	var clear := []
	for z in [-1.0, -box.size.z + 0.45]:
		var p := PhysicsShapeQueryParameters3D.new()
		p.shape = capsule
		p.transform = Transform3D(Basis(), Vector3(0, 0.9 + 0.02, z))
		var hits := world.get_world_3d().direct_space_state.intersect_shape(p, 4)
		var others := hits.filter(func(hh): return hh.collider != ground)
		clear.append(others.is_empty())
	_check("a body-sized capsule stands clear 1 m in and at the far end", clear.all(func(c): return c), {"clear": clear})

	await _shot(Vector3(0, 1.6, 2.8), Vector3(0, 1.3, -6), folder.path_join("mouth_sequin.png"))
	await _shot(Vector3(-5.5, 3.2, 6.0), Vector3(0, 1.4, -3), folder.path_join("outside_sequin.png"), 60.0)

	# every skin builds; a picture of some from the mouth
	var built := []
	for s in Tunnel.SKINS:
		t.apply_grid_config({"skin": s})
		await process_frame
		await process_frame
		var tn: Node3D = t.get_node_or_null("Tunnel")
		var floor_mesh: MeshInstance3D = tn.get_node_or_null("Floor") if tn else null
		if floor_mesh and int((floor_mesh.material_override as ShaderMaterial).get_shader_parameter("mode")) == Tunnel.SKINS.find(s):
			built.append(s)
		if s in ["latex", "chrome", "holo", "neon", "fishnet", "drag"]:
			await _shot(Vector3(0, 1.6, 2.8), Vector3(0, 1.3, -6), folder.path_join("mouth_%s.png" % s))
	_check("every skin builds in its own mode", built.size() == Tunnel.SKINS.size(), {"built": built.size()})
	t.apply_grid_config({"skin": "no-such-skin"})
	await process_frame
	await process_frame
	_check("a bad skin keeps the last good one", t.skin == "drag", {"skin": t.skin})
	t.apply_grid_config({"length": 5, "width": "3", "height": 3.2})
	await process_frame
	await physics_frame
	await physics_frame
	var b2: AABB = t.inside()
	var d2 := _ray(Vector3(0, 1.2, 0.5), Vector3(0, 1.2, -30))
	var r2 := _ray(Vector3(0, 1.2, -2), Vector3(10, 1.2, -2))
	_check("the inside follows length / width / height", absf(b2.size.z - 5.0) < 0.001 and absf(b2.size.x - 3.0) < 0.001 and absf(b2.size.y - 3.2) < 0.001
		and not d2.is_empty() and absf(d2.position.z + 5.0) < 0.02 and not r2.is_empty() and absf(r2.position.x - 1.5) < 0.02,
		{"inside": [b2.size.x, b2.size.y, b2.size.z], "far": 0.0 if d2.is_empty() else d2.position.z, "right": 0.0 if r2.is_empty() else r2.position.x})

	var result := {"checks": checks, "passed": checks.all(func(c): return c.ok)}
	var f := FileAccess.open(folder.path_join("bench.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "\t"))
	f.close()
	print("[wardrobe_tunnel_bench] ", "PASSED" if result.passed else "FAILED")
	quit()
