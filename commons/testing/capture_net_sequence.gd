extends SceneTree
## Film a modular term under physics: instantiate it, step the physics, and save the window at
## chosen ticks, so a net can be seen falling and settling over the block (not only the first
## third of a second the gallery capture shows). Windowed only — headless draws no frames.
##
##   godot --path . --xr-mode off --script res://commons/testing/capture_net_sequence.gd -- --term=net_over_cube
## Frames: user://term_sequence/<term>/t<tick>.png

var _term := "net_over_cube"
const TICKS := [0, 12, 24, 40, 70, 120, 200, 320]

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--term="):
			_term = a.trim_prefix("--term=")
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1200, 900))
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("f3ecdd")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("fff6e8")
	e.ambient_light_energy = 0.6
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	world.add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6, 6)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("d9cfbc")
	floor.material_override = fm
	floor.position.y = -0.001
	world.add_child(floor)
	var cam := Camera3D.new()
	cam.fov = 38
	world.add_child(cam)
	cam.look_at_from_position(Vector3(1.55, 1.5, 1.9), Vector3(0, 0.55, 0))
	cam.current = true
	var thing: Node = (load("res://commons/modular/composite.tscn") as PackedScene).instantiate()
	thing.set("term", _term)
	world.add_child(thing)
	var out := "user://term_sequence/%s" % _term
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var tick := 0
	for target in TICKS:
		while tick < target:
			await physics_frame
			tick += 1
		await process_frame
		await process_frame
		var img: Image = root.get_texture().get_image()
		img.save_png("%s/t%03d.png" % [out, target])
	var f := FileAccess.open("%s/done.txt" % out, FileAccess.WRITE)
	f.store_string("frames at ticks %s, %d Hz" % [str(TICKS), Engine.physics_ticks_per_second])
	f.close()
	quit(0)
