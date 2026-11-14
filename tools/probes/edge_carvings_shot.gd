extends SceneTree
## THE EDGE CARVINGS, PHOTOGRAPHED (2026-11-14): the seven kinds of edge carved in a row, each with its reading's words
## on its plinth, and a close view of each - windowed (headless draws no frames). Writes <out>/edge_carvings.png and
## <out>/edge_carving_<kind>.png, then <out>/done.json.
##   godot --path . --xr-mode off --resolution 1800x760 --script res://tools/probes/edge_carvings_shot.gd -- --out=<dir>
const Carving := preload("res://commons/artifacts/edge_carving/edge_carving.gd")
const ROW := [["cannot_claim", "cantor_limit"], ["leaves_out", "hand_delight"], ["still_open", "whose_body"], ["not_yet", "held_the_edge"],
	["foreclosed", "fit_the_rails"], ["dark_spot", "body_knows"], ["does_not_fit", "surface_carries"]]


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#3a3f4a")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.62, 0.66)
	e.ambient_light_energy = 0.55
	e.ssao_enabled = true
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(16, 8)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#8d8577")
	ground.material_override = gm
	world.add_child(ground)
	var built: Array = []
	for i in ROW.size():
		var c: Node3D = Carving.new()
		c.kind = ROW[i][0]
		c.reading = ROW[i][1]
		c.seed = i + 1
		c.position = Vector3((i - 3) * 1.3, 0, 0)
		world.add_child(c)
		built.append(c)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.fov = 50
	cam.current = true
	cam.position = Vector3(0, 1.35, 7.0)
	cam.look_at(Vector3(0, 0.8, 0))
	for i in 40: await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join("edge_carvings.png"))
	for i in ROW.size():
		var c: Node3D = built[i]
		cam.position = c.position + Vector3(0.55, 1.15, 1.75)
		cam.look_at(c.position + Vector3(0, 0.82, 0))
		for f in 6: await process_frame
		root.get_viewport().get_texture().get_image().save_png(out.path_join("edge_carving_%s.png" % ROW[i][0]))
	var f := FileAccess.open(out.path_join("done.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"ok": true, "kinds": ROW.size()}))
	f.close()
	quit()
