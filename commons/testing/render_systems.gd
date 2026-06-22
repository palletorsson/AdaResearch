extends SceneTree

## Render a kernel-generated map's `systems` block via HangarKit — the proof that "caused at
## generation time" renders: the kernel (Python) emits sources + edges as data, the runtime draws
## the visible flow. Builds a floor from the grid, stand-in blocks at interactable cells, a
## HangarKit.system_source at each source, and a HangarKit.system_edge for each edge. Saves a PNG.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/render_systems.gd -- \
##     --map=Kernel_Sys_Demo [--size=900]

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

var _map := "Kernel_Sys_Demo"
var _size := 900


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if a.begins_with("--map="):
			_map = a.substr(6)
		elif a.begins_with("--size="):
			if a.substr(7).is_valid_int():
				_size = int(a.substr(7))
	_run.call_deferred()


func _run() -> void:
	root.content_scale_size = Vector2i(_size, _size)
	root.size = Vector2i(_size, _size)

	var path := ProjectSettings.globalize_path("res://commons/maps/%s/map_data.json" % _map)
	if not FileAccess.file_exists(path):
		push_error("no map: " + path); quit(1); return
	var d = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	if not (d is Dictionary):
		push_error("bad map json"); quit(1); return
	var W := int(d["map_info"]["dimensions"]["width"])
	var D := int(d["map_info"]["dimensions"]["depth"])
	var inter: Array = d["layers"]["interactables"]
	var sys: Dictionary = d.get("systems", {"sources": [], "edges": []})

	var scene := Node3D.new()
	scene.name = "SysMap"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.64, 0.68)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.7)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; scene.add_child(we)
	var key := DirectionalLight3D.new(); key.rotation_degrees = Vector3(-55, -40, 0); key.light_energy = 1.1; key.shadow_enabled = true; scene.add_child(key)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-15, 130, 0); fill.light_energy = 0.35; scene.add_child(fill)

	var ox := -W * 0.5 + 0.5
	var oz := -D * 0.5 + 0.5
	var w2c := func(r: int, c: int) -> Vector3: return Vector3(c + ox, 0.0, r + oz)

	# floor
	scene.add_child(HangarKit.box(Vector3(0, -0.05, 0), Vector3(W, 0.1, D), HangarKit.rams_body(HangarKit.BODY_LIGHT, 0.14)))

	# interactable stand-ins (one block per anchor cell)
	for r in range(inter.size()):
		var row: Array = inter[r]
		for c in range(row.size()):
			var t := str(row[c]).strip_edges()
			if t != "" and t != " " and not t.begins_with("#"):
				scene.add_child(HangarKit.box(w2c.call(r, c) + Vector3(0, 0.45, 0), Vector3(0.8, 0.9, 0.8), HangarKit.terminal_body(HangarKit.TERMINAL_BODY, 0.3)))

	# sources on the boundary
	for s in sys.get("sources", []):
		var cell: Array = s["cell"]
		var src: Node3D = HangarKit.system_source(str(s["kind"]))
		src.position = w2c.call(int(cell[0]), int(cell[1])) + Vector3(0, 1.0, 0)
		scene.add_child(src)

	# edges: source -> sink (floor strip for power/data, pipe for vent/fluid)
	for e in sys.get("edges", []):
		var a: Vector3 = w2c.call(int(e["from"][0]), int(e["from"][1])) + Vector3(0, 0.04, 0)
		var b: Vector3 = w2c.call(int(e["to"][0]), int(e["to"][1])) + Vector3(0, 0.55, 0)
		scene.add_child(HangarKit.system_edge(a, b, str(e["kind"])))

	await process_frame
	await process_frame

	var maxdim: float = float(maxi(W, D))
	var cam := Camera3D.new(); cam.current = true; cam.fov = 40.0
	scene.add_child(cam)
	cam.global_position = Vector3(maxdim * 0.42, maxdim * 0.72, maxdim * 0.78)
	cam.look_at(Vector3.ZERO, Vector3.UP)

	await process_frame
	await process_frame

	var img := root.get_texture().get_image()
	if img:
		var out := ProjectSettings.globalize_path("res://ada_run/_sysmap.png")
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		img.save_png(out)
		print("render_systems: saved ", out)
	quit(0)
