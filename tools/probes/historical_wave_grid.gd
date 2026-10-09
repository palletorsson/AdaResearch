extends SceneTree
## Photograph an archived JSON through the real GridSystem without changing a live map.

var _input := ""
var _out := ""
var _built := false
var _report: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--json="): _input = arg.trim_prefix("--json=")
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
	_run.call_deferred()

func _run() -> void:
	assert(not _input.is_empty() and not _out.is_empty())
	root.size = Vector2i(1600, 1000)
	root.content_scale_size = Vector2i(1600, 1000)
	root.msaa_3d = Viewport.MSAA_4X
	var world := Node3D.new()
	world.name = "HistoricalGridCapture"
	root.add_child(world)
	current_scene = world
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_input))
	var map_name: String = doc.map_info.lookup_name
	var grid: Node3D = load("res://commons/grid/grid_system.tscn").instantiate()
	grid.name = "HistoricalGrid"
	grid.set("map_name", map_name)
	grid.set("auto_load_map_on_ready", false)
	grid.set("bare_world", true)
	grid.set("skip_player_spawn", true)
	grid.connect("build_finished", func(): _built = true)
	world.add_child(grid)
	await process_frame
	await process_frame
	# Supply the archive to the existing loader, then run the normal component chain.
	var loader = load("res://commons/managers/JsonMapLoader.gd").new()
	assert(loader.load_map(_input), "Archived JSON must parse")
	var data = grid.get("data_component")
	data.json_loader = loader
	data.map_name = map_name
	data.current_map_format = "json"
	data.structure_data_instance = loader.structure_data_instance
	data.utility_data_instance = loader.utility_data_instance
	data.interactable_data_instance = loader.interactable_data_instance
	var dims: Dictionary = loader.get_dimensions()
	data.grid_dimensions = Vector3i(dims.width, dims.max_height, dims.depth)
	grid.call("_on_data_loaded", map_name, "json")
	var deadline := Time.get_ticks_msec() + 90000
	while not _built and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(_built, "Grid build must finish")
	await create_timer(1.5).timeout
	var arts: Array = []
	for n in grid.get_children():
		if n.has_meta("artifact_lookup_name"):
			arts.append({"id": n.get_meta("artifact_lookup_name"), "position": str(n.position), "scene": n.scene_file_path, "placeholder": n.get_meta("is_placeholder_artifact", false)})
	var expected_artifacts := 0
	var expected_cubes := 0
	var holes := 0
	for row in doc.layers.interactables:
		for token in row:
			if not str(token).strip_edges().is_empty(): expected_artifacts += 1
	for row in doc.layers.structure:
		for token in row:
			var height: int = grid.get("structure_component").parse_cell_height(str(token))
			expected_cubes += mini(height, int(dims.max_height))
			if height == 0: holes += 1
	var actual_cubes: int = grid.get("structure_component").cube_positions.size()
	assert(actual_cubes == expected_cubes, "All archived structure cubes must be built")
	assert(arts.size() == expected_artifacts, "All archived artifact placements must load")
	for art in arts: assert(not art.placeholder, "No missing artifact placeholders")
	# Photography only: JSON lighting, no biome ring/player; no altered layout or bindings.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	var bg: Array = doc.settings.background.color
	env.background_color = Color(bg[0], bg[1], bg[2])
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var ambient: Array = doc.lighting.ambient_color
	env.ambient_light_color = Color(ambient[0], ambient[1], ambient[2])
	env.ambient_light_energy = float(doc.lighting.ambient_energy)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world.add_child(world_env)
	var light := DirectionalLight3D.new()
	var ld: Dictionary = doc.lighting.directional_light
	light.light_energy = float(ld.energy)
	light.light_color = Color(ld.color[0], ld.color[1], ld.color[2])
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 100.0
	world.add_child(light)
	light.look_at(Vector3(ld.direction[0], ld.direction[1], ld.direction[2]))
	var camera := Camera3D.new()
	camera.far = 250.0
	camera.fov = 62.0
	camera.environment = env
	world.add_child(camera)
	camera.make_current()
	for layer in root.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	DirAccess.make_dir_recursive_absolute(_out)
	_report = {"map": map_name, "json": _input, "json_sha256": FileAccess.get_sha256(_input), "engine": Engine.get_version_info().string, "renderer": "real GridSystem / current artifacts", "dimensions": dims, "structure_rows": doc.layers.structure.size(), "structure_cubes": actual_cubes, "zero_cells": holes, "artifacts": arts, "shots": [], "verified": true}
	if map_name == "WaveFunctions_Sine_Space":
		await _shot(camera, "overview", Vector3(33, 31, -15), Vector3(6, 3, 14))
		await _shot(camera, "basin", Vector3(9, 15, 0), Vector3(6, 1, 18))
		await _shot(camera, "bridge", Vector3(10, 2.15, 8), Vector3(6, 0.5, 19))
	else:
		await _shot(camera, "overview", Vector3(27, 23, -17), Vector3(7, 1, 8))
		await _shot(camera, "basin", Vector3(7, 12, -5), Vector3(7, 0.5, 9))
		await _shot(camera, "entry", Vector3(1, 2.15, 1), Vector3(8, 0.6, 8))
	var f := FileAccess.open(_out.path_join("render.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_report, "\t"))
	f.close()
	print("HISTORICAL_GRID_CAPTURE_PASS ", map_name)
	quit()

func _shot(camera: Camera3D, label: String, eye: Vector3, target: Vector3) -> void:
	camera.fov = 42.0 if label == "overview" else 62.0
	camera.global_position = eye
	camera.look_at(target)
	camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(_out.path_join(label + ".png"))
	assert(err == OK)
	_report.shots.append({"file": label + ".png", "eye": str(eye), "target": str(target)})
