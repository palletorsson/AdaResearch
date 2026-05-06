extends SceneTree

## Capture the biome ring at the first map of each spine sequence.
## Shows visible evolution: density 0 → 1.0, kingdoms unlocking, grammar gating.
## Output: user://biome_progression/<order>_<seq>.png

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

const SPINE_FIRST_MAPS: Array = [
	{"order": 1,  "seq": "primitives",            "map": "Point_One"},
	{"order": 2,  "seq": "transformation",        "map": "Trans_Introduction"},
	{"order": 3,  "seq": "color",                 "map": "Color_Nails"},
	{"order": 4,  "seq": "forces",                "map": "VectorFoundations"},
	{"order": 5,  "seq": "array_tutorial",        "map": "Tutorial_Pattern"},
	{"order": 6,  "seq": "wavefunctions",         "map": "WaveFunctions_Intro"},
	{"order": 7,  "seq": "randomness",            "map": "Random_Definition"},
	{"order": 8,  "seq": "noise",                 "map": "Random_Noise_Types"},
	{"order": 9,  "seq": "cellularautomata",      "map": "CA_Introduction"},
	{"order": 10, "seq": "fractals",              "map": "Fractal_Recursion"},
	{"order": 11, "seq": "lsystems",              "map": "LSystems_Grammar_Lab"},
	{"order": 12, "seq": "proceduralgeneration",  "map": "PG_Genetic_Evolution"},
	{"order": 13, "seq": "softbodies",            "map": "SoftBodies_Soft_Body_Deformation"},
	{"order": 14, "seq": "swarmintelligence",     "map": "SwarmIntelligence_PhysarumColony"},
	{"order": 15, "seq": "machinelearning",       "map": "ML_Evolution"},
	{"order": 16, "seq": "foundationscrisis",     "map": "Euclid_Parallel"},
	{"order": 17, "seq": "qfeplaboratory",        "map": "QFEP_Introduction"},
	{"order": 18, "seq": "postfoundationscrisis", "map": "CriticalAlgorithms_Algorithmic_Bias_Visualization"},
	{"order": 19, "seq": "graphtheory",           "map": "GT_Foundations"},
]

var _catalog: Node = null
var _out_dir: String = "user://biome_progression"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== BIOME PROGRESSION CAPTURE ===")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	var err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if err != OK:
		push_error("Failed to load MapCatalog: %d" % err)
		quit(1)
		return

	await process_frame
	await process_frame
	await process_frame

	_catalog = current_scene
	if not _catalog:
		push_error("No catalog scene")
		quit(1)
		return

	# Hide UI overlays
	for n in ["DesktopMapSwitcherOverlay", "MapDataEditorOverlay", "MapLayerEditorOverlay", "ProjectDashboardOverlay", "StatusLabel"]:
		var node: Node = _catalog.get_node_or_null(n)
		if node:
			if node is CanvasLayer: (node as CanvasLayer).visible = false
			elif node is Control: (node as Control).visible = false

	for entry in SPINE_FIRST_MAPS:
		await _capture_map(entry)

	print("=== DONE — %d biome captures written to %s ===" % [SPINE_FIRST_MAPS.size(), _out_dir])
	quit(0)


func _capture_map(entry: Dictionary) -> void:
	var order: int = int(entry["order"])
	var seq: String = str(entry["seq"])
	var map_name: String = str(entry["map"])
	var label: String = "%02d_%s" % [order, seq]

	print("--- %s → %s ---" % [label, map_name])

	# Reset ecosystem so this capture shows THIS sequence's state, not the
	# cumulative post-play state. sync_to_map below will advance exactly
	# to `seq`, producing the intended density/kingdoms/grammar gate.
	var eco = root.get_node_or_null("EcosystemManager")
	if eco and eco.has_method("reset_progression"):
		eco.reset_progression()

	# Load map fresh (GridSystem wires biome via _handle_biome_ring)
	if _catalog.has_method("load_map_fresh"):
		_catalog.load_map_fresh(map_name)
	elif _catalog.has_method("_load_map_by_name"):
		_catalog._load_map_by_name(map_name)
	else:
		push_warning("No load method on catalog")
		return

	# Wait for GridSystem + biome ring to settle
	var timer := Timer.new()
	root.add_child(timer)
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	var cam: Camera3D = null
	if "_camera" in _catalog: cam = _catalog._camera
	if not cam: cam = root.get_viewport().get_camera_3d()
	if not cam:
		push_warning("No camera for %s" % label)
		return

	# Find grid center via GridSystem
	var grid_center := Vector3.ZERO
	var grid_size: float = 20.0
	var grid: Node = _find_node_of_type(_catalog, "GridSystem")
	if grid and "data_component" in grid:
		var dc = grid.data_component
		if dc and dc.has_method("get_grid_dimensions"):
			var dims: Vector3i = dc.get_grid_dimensions()
			var cs: float = 2.0
			if "cube_size" in grid: cs = grid.cube_size
			grid_size = maxf(float(dims.x) * cs, float(dims.z) * cs)
			grid_center = Vector3(float(dims.x) * cs * 0.5, 0.0, float(dims.z) * cs * 0.5)

	# Top-down oblique — shows grid AND surrounding biome ring
	var cam_dist: float = grid_size * 1.2 + 12.0
	var cam_height: float = grid_size * 0.9 + 10.0
	cam.global_position = grid_center + Vector3(-cam_dist * 0.6, cam_height, -cam_dist * 0.6)
	cam.look_at(grid_center, Vector3.UP)

	await process_frame
	await process_frame
	await process_frame

	var img := root.get_viewport().get_texture().get_image()
	if img:
		var path: String = _out_dir + "/%s.png" % label
		img.save_png(path)
		print("  Saved %s" % path)


func _find_node_of_type(root_node: Node, class_str: String) -> Node:
	for child in root_node.get_children():
		if child.get_class() == class_str or (child.has_method("get_class") and str(child.get_script()).contains(class_str)):
			return child
		var found: Node = _find_node_of_type(child, class_str)
		if found:
			return found
	return null
