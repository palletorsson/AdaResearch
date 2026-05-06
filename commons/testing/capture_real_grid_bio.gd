extends SceneTree

## Capture a REAL map via MapCatalogDesktop3D, then add bio organisms
## to specific cells to show the weave.

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const TARGET_MAP: String = "LSystems_Grammar_Lab"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== REAL GRID + BIO ===")
	print("Loading map: %s via MapCatalog..." % TARGET_MAP)

	# Load the real MapCatalog scene
	var change_err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if change_err != OK:
		push_error("Failed to load MapCatalog")
		quit(1)
		return

	await process_frame
	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if not catalog:
		push_error("No current scene")
		quit(1)
		return

	# Hide overlays
	for overlay_name in ["DesktopMapSwitcherOverlay", "MapDataEditorOverlay", "MapLayerEditorOverlay", "ProjectDashboardOverlay", "StatusLabel"]:
		var node: Node = catalog.get_node_or_null(overlay_name)
		if node:
			if node is CanvasLayer:
				(node as CanvasLayer).visible = false
			elif node is Control:
				(node as Control).visible = false

	# Load the actual map
	if catalog.has_method("load_map_fresh"):
		catalog.load_map_fresh(TARGET_MAP)
	elif catalog.has_method("_load_map_by_name"):
		catalog._load_map_by_name(TARGET_MAP)
	else:
		push_error("No map loading method found on catalog")
		quit(1)
		return

	# Wait for map to build
	print("Waiting for map to build...")
	var timer := Timer.new()
	root.add_child(timer)
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	# Get orbit params from catalog
	var orbit_center: Vector3 = Vector3.ZERO
	var orbit_radius: float = 10.0
	var orbit_height: float = 8.0

	if "_orbit_center" in catalog:
		orbit_center = catalog._orbit_center
	if "_orbit_radius" in catalog:
		orbit_radius = catalog._orbit_radius
	if "_orbit_height" in catalog:
		orbit_height = catalog._orbit_height

	var cam: Camera3D = null
	if "_camera" in catalog:
		cam = catalog._camera
	if not cam:
		cam = root.get_viewport().get_camera_3d()

	if not cam:
		push_error("No camera")
		quit(1)
		return

	print("Map loaded. Center=%s, Radius=%.1f, Height=%.1f" % [str(orbit_center), orbit_radius, orbit_height])

	var out_dir := "user://real_grid_bio"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# ── First: capture the map as-is (without bio) ──
	print("Capturing map without bio...")
	cam.global_position = orbit_center + Vector3(-orbit_radius * 0.7, orbit_height * 0.6, -orbit_radius * 0.7)
	cam.look_at(orbit_center, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/01_map_original.png")
	print("  Saved 01_map_original.png")

	# Top-down of original
	cam.global_position = orbit_center + Vector3(0, orbit_height * 0.9, 0.1)
	cam.look_at(orbit_center, Vector3(0, 0, -1))
	await process_frame
	await process_frame
	_save(out_dir + "/02_map_original_top.png")
	print("  Saved 02_map_original_top.png")

	# ── Now add bio organisms at specific empty grid cells ──
	print("Adding bio organisms to grid cells...")
	var trait_mapper := CritterTraitMapper.new()

	# Get the grid system's cube_size for positioning
	var cube_size: float = 1.0
	var grid_data: Node = catalog.find_child("GridDataComponent", true, false)
	if grid_data and grid_data.has_method("get_settings"):
		cube_size = grid_data.get_settings().get("cube_size", 1.0)
	print("  Cube size: %.1f" % cube_size)

	# The map has interactables at:
	# (4,3): lsystem_editor   (2,5): lsystem_tree   (6,5): fractal_lsystem_string
	# Empty cells we can use: (1,5), (3,7), (6,3), (5,7)

	# Place an L-system tree preset at (1,7) — the living result of the grammar
	var tree_dna := CritterDNA.random_kingdom(0, 42)
	tree_dna.segments = 5.0
	tree_dna.branch_angle = 45.0
	tree_dna.symmetry = 3.0
	tree_dna.scale = 0.7
	tree_dna.leaf_density = 0.7
	tree_dna.primary_color = Color.html("2ecc71")
	tree_dna.secondary_color = Color.html("8b4513")
	var tree_node := Node3D.new()
	tree_node.name = "Bio_LSystemTree"
	tree_node.position = Vector3(1.0, 0.0, 7.0) * cube_size
	catalog.add_child(tree_node)
	MorphologyRouter.build(tree_dna, tree_node, trait_mapper, 0)
	print("  Placed lsystem_tree at (1,7)")

	# Place a fungus at (6,7) — reaction-diffusion / colony
	var fungus_dna := CritterDNA.random_kingdom(3, 77)
	fungus_dna.sociality = 0.9
	fungus_dna.scale = 0.5
	fungus_dna.primary_color = Color.html("a29bfe")
	fungus_dna.secondary_color = Color.html("6c5ce7")
	var fungus_node := Node3D.new()
	fungus_node.name = "Bio_TuringFungus"
	fungus_node.position = Vector3(6.0, 0.0, 7.0) * cube_size
	catalog.add_child(fungus_node)
	MorphologyRouter.build(fungus_dna, fungus_node, trait_mapper, 0)
	print("  Placed turing_fungus at (6,7)")

	# Place a flower at (6,3) — fibonacci petal arrangement
	var flower_dna := CritterDNA.random_kingdom(2, 99)
	flower_dna.symmetry = 6.0
	flower_dna.scale = 0.5
	flower_dna.primary_color = Color.html("ff6b6b")
	flower_dna.secondary_color = Color.html("c44569")
	var flower_node := Node3D.new()
	flower_node.name = "Bio_FibFlower"
	flower_node.position = Vector3(6.0, 0.0, 3.0) * cube_size
	catalog.add_child(flower_node)
	MorphologyRouter.build(flower_dna, flower_node, trait_mapper, 0)
	print("  Placed fibonacci_flower at (6,3)")

	await process_frame
	await process_frame

	# Wait for morphology to build
	timer = Timer.new()
	root.add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	# ── Capture with bio ──
	print("Capturing map WITH bio...")

	# Same angle as original — direct comparison
	cam.global_position = orbit_center + Vector3(-orbit_radius * 0.7, orbit_height * 0.6, -orbit_radius * 0.7)
	cam.look_at(orbit_center, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/03_map_with_bio.png")
	print("  Saved 03_map_with_bio.png")

	# Top-down with bio
	cam.global_position = orbit_center + Vector3(0, orbit_height * 0.9, 0.1)
	cam.look_at(orbit_center, Vector3(0, 0, -1))
	await process_frame
	await process_frame
	_save(out_dir + "/04_map_with_bio_top.png")
	print("  Saved 04_map_with_bio_top.png")

	# Player-level view inside the map
	cam.global_position = orbit_center + Vector3(-orbit_radius * 0.3, 1.6, -orbit_radius * 0.3)
	cam.look_at(orbit_center + Vector3(0, 0.5, 0), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/05_player_inside.png")
	print("  Saved 05_player_inside.png")

	# Close-up on bio tree
	cam.global_position = Vector3(0.0, 1.5, 6.0) * cube_size
	cam.look_at(Vector3(1.0, 0.5, 7.0) * cube_size, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/06_bio_tree_closeup.png")
	print("  Saved 06_bio_tree_closeup.png")

	print("=== DONE ===")
	quit(0)


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image:
		var abs_path: String = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		image.save_png(abs_path)
