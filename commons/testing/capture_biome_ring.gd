extends SceneTree

## Capture a grid map surrounded by a biome ring at different density levels.

const _BiomeRing = preload("res://commons/grid/BiomeRingComponent.gd")
const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== BIOME RING TEST ===")

	# Load a real map
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
		quit(1)
		return

	# Hide overlays
	for n in ["DesktopMapSwitcherOverlay", "MapDataEditorOverlay", "MapLayerEditorOverlay", "ProjectDashboardOverlay", "StatusLabel"]:
		var node: Node = catalog.get_node_or_null(n)
		if node:
			if node is CanvasLayer: (node as CanvasLayer).visible = false
			elif node is Control: (node as Control).visible = false

	# Load map
	if catalog.has_method("load_map_fresh"):
		catalog.load_map_fresh("LSystems_Grammar_Lab")
	elif catalog.has_method("_load_map_by_name"):
		catalog._load_map_by_name("LSystems_Grammar_Lab")

	# Wait for map
	var timer := Timer.new()
	root.add_child(timer)
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	# Get camera and orbit info
	var cam: Camera3D = null
	if "_camera" in catalog: cam = catalog._camera
	if not cam: cam = root.get_viewport().get_camera_3d()

	var orbit_center: Vector3 = Vector3.ZERO
	var orbit_radius: float = 10.0
	var orbit_height: float = 8.0
	if "_orbit_center" in catalog: orbit_center = catalog._orbit_center
	if "_orbit_radius" in catalog: orbit_radius = catalog._orbit_radius
	if "_orbit_height" in catalog: orbit_height = catalog._orbit_height

	var out_dir := "user://biome_ring"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# Capture original (no ring)
	cam.global_position = orbit_center + Vector3(-orbit_radius * 0.8, orbit_height * 0.7, -orbit_radius * 0.8)
	cam.look_at(orbit_center, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/01_no_ring.png")
	print("  Saved 01_no_ring.png")

	# Add biome ring — density 0.4 (noise stage)
	print("Adding biome ring (density=0.4)...")
	var ring := _BiomeRing.new()
	ring.name = "BiomeRing"
	catalog.add_child(ring)
	ring.generate(
		Vector3i(8, 2, 10),  # LSystems_Grammar_Lab dimensions
		1.0,                  # cube_size
		"growth",             # terrain_mode
		["flower", "tree", "fungus"],
		0.4
	)

	await process_frame
	await process_frame

	timer = Timer.new()
	root.add_child(timer)
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	# Wide shot showing ring
	cam.global_position = orbit_center + Vector3(-orbit_radius * 1.2, orbit_height * 1.0, -orbit_radius * 1.2)
	cam.look_at(orbit_center, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/02_with_ring_wide.png")
	print("  Saved 02_with_ring_wide.png")

	# Same angle as original
	cam.global_position = orbit_center + Vector3(-orbit_radius * 0.8, orbit_height * 0.7, -orbit_radius * 0.8)
	cam.look_at(orbit_center, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/03_with_ring_angle.png")
	print("  Saved 03_with_ring_angle.png")

	# Top-down showing ring boundary
	cam.global_position = orbit_center + Vector3(0, orbit_height * 1.5, 0.1)
	cam.look_at(orbit_center, Vector3(0, 0, -1))
	await process_frame
	await process_frame
	_save(out_dir + "/04_ring_top.png")
	print("  Saved 04_ring_top.png")

	# Player-level looking out from grid edge into biome
	cam.global_position = orbit_center + Vector3(-3, 1.6, 0)
	cam.look_at(orbit_center + Vector3(-8, 0.5, 0), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/05_looking_outward.png")
	print("  Saved 05_looking_outward.png")

	# Now add full density ring
	ring.queue_free()
	await process_frame

	var ring2 := _BiomeRing.new()
	ring2.name = "BiomeRing2"
	catalog.add_child(ring2)
	ring2.generate(
		Vector3i(8, 2, 10),
		1.0,
		"self_generating",
		["flower", "tree", "fungus", "creature"],
		1.0
	)

	await process_frame
	await process_frame

	timer = Timer.new()
	root.add_child(timer)
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

	cam.global_position = orbit_center + Vector3(-orbit_radius * 1.2, orbit_height * 1.0, -orbit_radius * 1.2)
	cam.look_at(orbit_center, Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/06_full_density.png")
	print("  Saved 06_full_density.png")

	cam.global_position = orbit_center + Vector3(-3, 1.6, 0)
	cam.look_at(orbit_center + Vector3(-10, 0.5, 2), Vector3.UP)
	await process_frame
	await process_frame
	_save(out_dir + "/07_full_outward.png")
	print("  Saved 07_full_outward.png")

	print("=== DONE ===")
	quit(0)


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image:
		var abs_path: String = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		image.save_png(abs_path)
