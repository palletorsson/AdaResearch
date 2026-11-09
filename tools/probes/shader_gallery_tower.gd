extends "res://tools/probes/void_game_probe.gd"
## THE SHADER GALLERIES IN THE TOWER (Palle, 2026-11-09: "the playground's own panels wear the shaders as a gallery ...
## mixed with the existing shader setup"). On each shader floor: every screen of a shader-gallery placement wears its
## console's live material (meta "wearing"), screens left unworn are the console's other modes (meta "wear_missing"),
## and a change on one worn material shows on its screen - the console and the gallery are one surface.
## Run: python tools/test_shader_gallery_tower.py
const MAPS := ["Shader_01_Shaping", "Shader_05_Patterns", "Shader_11_QueerRubber", "Shader_09_FBM", "Shader_12_PinkExtravaganza", "Shader_10_ReactionDiffusion"]

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	var rooms: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/rooms.json"))
	var index := {}
	for i in rooms.floors.size(): index[rooms.floors[i].map] = i
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = int(index[MAPS[0]])
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(90)
	var report := {}
	for m in MAPS:
		var f := int(index[m])
		game.place_player(game.spawn_for(f))
		await frames(240)
		await create_timer(2.5).timeout   # works build late; plates look again every second
		var plates := []
		for key in game.building.content.exhibits:
			if not str(key).begins_with("%d/shader-gallery" % f): continue
			var mount: Node3D = game.building.content.exhibits[key]
			plates += mount.find_children("*", "Node3D", true, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("display_plate.gd"))
		var worn := plates.filter(func(p): return p.has_meta("wearing"))
		var live := false
		if not worn.is_empty():
			var mat: ShaderMaterial = worn[0].face.material_override
			var key_name := ""
			for u in mat.shader.get_shader_uniform_list():
				if int(u.type) == TYPE_FLOAT: key_name = str(u.name); break
			if key_name != "":
				var before: Variant = mat.get_shader_parameter(key_name)
				mat.set_shader_parameter(key_name, 0.731)
				live = is_equal_approx(float((worn[0].face.material_override as ShaderMaterial).get_shader_parameter(key_name)), 0.731)
				mat.set_shader_parameter(key_name, before)
		report[m] = {"screens": plates.size(), "wearing": worn.size(), "unworn": plates.filter(func(p): return p.has_meta("wear_missing")).map(func(p): return p.title), "live": live}
		check("%s: %d of %d screens wear the console's live shaders, and a change shows on a screen" % [m, worn.size(), plates.size()], plates.size() > 0 and worn.size() > 0 and live)
	FileAccess.open(out.path_join("shader_galleries.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[shader_gallery_tower] %d/%d" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)
