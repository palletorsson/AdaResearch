extends SceneTree

## Perfect Shot — Universal preview and screenshot engine.
##
## Loads any scene (artifact, raw .tscn, critter DNA, map), auto-measures it,
## classifies its size, and takes optimal photos from computed angles.
##
## Modes:
##   artifact — lookup_name from registry → scene → capture
##   scene    — direct .tscn path → capture
##   critter  — DNA JSON → MorphologyRouter.build() → capture
##   map      — map name → MapCatalogDesktop3D → capture
##   batch    — JSON list of mixed targets → capture all in one process
##
## Usage:
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/perfect_shot.gd -- \
##     --mode=artifact --target=pompeii_mosaic_floor
##
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/perfect_shot.gd -- \
##     --mode=critter --dna=user://pokemon_studio/specimens/specimen_0001.json
##
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/perfect_shot.gd -- \
##     --mode=batch --targets=user://capture_targets.json

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

# Preload dependencies (class_name resolution doesn't work in SceneTree scripts)
const Framer = preload("res://commons/testing/perfect_shot_framer.gd")
const Scaffold = preload("res://commons/testing/perfect_shot_scaffold.gd")

# ─────────────────────────────────────────────────────────────
#  Arguments
# ─────────────────────────────────────────────────────────────

var _mode: String = ""
var _target: String = ""
var _dna_path: String = ""
var _output_dir: String = "user://perfect_shots"
var _wait_seconds: float = 2.0
var _settle_seconds: float = 0.3
var _targets_path: String = ""
var _hero_only: bool = false   ## Only capture the first (hero) angle — fast mode

# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

var _scaffold = null  # Scaffold instance (Scaffold)
var _report: Dictionary = {
	"timestamp": "",
	"mode": "",
	"captured": 0,
	"failed": 0,
	"targets": [],
}


# ═══════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════

func _initialize() -> void:
	_parse_args()

	if _mode.is_empty():
		push_error("perfect_shot: --mode=artifact|scene|critter|map|batch is required")
		quit(1)
		return

	if _mode in ["artifact", "scene", "map"] and _target.is_empty():
		push_error("perfect_shot: --target=<name> is required for mode '%s'" % _mode)
		quit(1)
		return

	if _mode == "critter" and _dna_path.is_empty():
		push_error("perfect_shot: --dna=<path> is required for critter mode")
		quit(1)
		return

	if _mode == "batch" and _targets_path.is_empty():
		push_error("perfect_shot: --targets=<json_path> is required for batch mode")
		quit(1)
		return

	_report["timestamp"] = Time.get_datetime_string_from_system()
	_report["mode"] = _mode

	call_deferred("_run")


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq_idx: int = arg.find("=")
		if eq_idx <= 2:
			if arg == "--hero-only":
				_hero_only = true
			continue
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"mode":
				_mode = value.to_lower()
			"target":
				_target = value
			"dna":
				_dna_path = value
			"out":
				if not value.is_empty():
					_output_dir = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.5, float(value))
			"settle":
				if value.is_valid_float():
					_settle_seconds = maxf(0.1, float(value))
			"targets":
				_targets_path = value


# ═══════════════════════════════════════════════════════════════
# MAIN RUNNER
# ═══════════════════════════════════════════════════════════════

func _run() -> void:
	match _mode:
		"artifact":
			await _run_artifact()
		"scene":
			await _run_scene()
		"critter":
			await _run_critter()
		"map":
			await _run_map()
		"batch":
			await _run_batch()
		_:
			push_error("perfect_shot: Unknown mode '%s'" % _mode)

	# Save report
	_save_report()
	print("perfect_shot: Done. Captured %d, failed %d." % [_report["captured"], _report["failed"]])
	quit(0)


# ═══════════════════════════════════════════════════════════════
# ARTIFACT MODE
# ═══════════════════════════════════════════════════════════════

func _run_artifact() -> void:
	print("perfect_shot [artifact]: Loading '%s'..." % _target)

	# Find scene path from registry
	var artifact_info: Dictionary = _find_artifact(_target)
	if artifact_info.is_empty():
		push_error("perfect_shot: Artifact not found in registry: %s" % _target)
		_report["failed"] += 1
		return

	var scene_path: String = str(artifact_info.get("scene", "")).strip_edges()
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("perfect_shot: Scene not found: %s" % scene_path)
		_report["failed"] += 1
		return

	# Load and instantiate
	var scene = ResourceLoader.load(scene_path)
	if not scene:
		push_error("perfect_shot: Failed to load scene: %s" % scene_path)
		_report["failed"] += 1
		return

	var instance = scene.instantiate()
	if not instance or not (instance is Node3D):
		push_error("perfect_shot: Scene root is not Node3D: %s" % scene_path)
		if instance:
			instance.queue_free()
		_report["failed"] += 1
		return

	var out_dir: String = _output_dir + "/" + _target
	await _capture_instance(instance as Node3D, out_dir, _target)


# ═══════════════════════════════════════════════════════════════
# SCENE MODE
# ═══════════════════════════════════════════════════════════════

func _run_scene() -> void:
	print("perfect_shot [scene]: Loading '%s'..." % _target)

	if not ResourceLoader.exists(_target):
		push_error("perfect_shot: Scene file not found: %s" % _target)
		_report["failed"] += 1
		return

	var scene = ResourceLoader.load(_target)
	if not scene:
		push_error("perfect_shot: Failed to load: %s" % _target)
		_report["failed"] += 1
		return

	var instance = scene.instantiate()
	if not instance or not (instance is Node3D):
		push_error("perfect_shot: Scene root is not Node3D")
		if instance:
			instance.queue_free()
		_report["failed"] += 1
		return

	var scene_name: String = _target.get_file().get_basename()
	var out_dir: String = _output_dir + "/" + scene_name
	await _capture_instance(instance as Node3D, out_dir, scene_name)


# ═══════════════════════════════════════════════════════════════
# CRITTER MODE
# ═══════════════════════════════════════════════════════════════

func _run_critter() -> void:
	print("perfect_shot [critter]: Loading DNA from '%s'..." % _dna_path)

	# Read DNA JSON
	var file_path: String = _dna_path
	if not FileAccess.file_exists(file_path):
		# Try globalized path
		file_path = ProjectSettings.globalize_path(_dna_path)
	if not FileAccess.file_exists(file_path):
		push_error("perfect_shot: DNA file not found: %s" % _dna_path)
		_report["failed"] += 1
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("perfect_shot: Cannot open DNA file: %s" % _dna_path)
		_report["failed"] += 1
		return

	var json_str: String = file.get_as_text()
	file.close()

	# Parse DNA
	var dna: CritterDNA = CritterDNA.from_json(json_str)
	if not dna:
		push_error("perfect_shot: Failed to parse DNA JSON")
		_report["failed"] += 1
		return

	# Build morphology
	var trait_mapper := CritterTraitMapper.new()
	var mesh_root: Node3D = Node3D.new()
	mesh_root.name = "Critter_%s_gen%d" % [dna.get_kingdom_name(), dna.generation]
	MorphologyRouter.build(dna, mesh_root, trait_mapper, 0)  # LOD 0 = highest detail

	var critter_id: String = _dna_path.get_file().get_basename()
	var out_dir: String = _output_dir + "/critters/" + critter_id
	await _capture_instance(mesh_root, out_dir, critter_id)

	print("perfect_shot [critter]: Kingdom=%s, gen=%d" % [dna.get_kingdom_name(), dna.generation])


# ═══════════════════════════════════════════════════════════════
# MAP MODE
# ═══════════════════════════════════════════════════════════════

func _run_map() -> void:
	print("perfect_shot [map]: Loading map '%s' via MapCatalog..." % _target)

	# Maps need the full MapCatalogDesktop3D for grid system loading
	if not ResourceLoader.exists(MAP_CATALOG_SCENE):
		push_error("perfect_shot: MapCatalog scene not found: %s" % MAP_CATALOG_SCENE)
		_report["failed"] += 1
		return

	var change_err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if change_err != OK:
		push_error("perfect_shot: Failed to load MapCatalog")
		_report["failed"] += 1
		return

	await process_frame
	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if not catalog:
		push_error("perfect_shot: MapCatalog scene is null")
		_report["failed"] += 1
		return

	# Hide overlays
	_hide_overlay_nodes(catalog)

	# Load the map
	if catalog.has_method("load_map_fresh"):
		catalog.load_map_fresh(_target)
	elif catalog.has_method("_load_map_by_name"):
		catalog._load_map_by_name(_target)
	else:
		push_error("perfect_shot: MapCatalog has no load method")
		_report["failed"] += 1
		return

	# Wait for map to load
	await _wait(maxf(_wait_seconds, 3.0))

	# Get orbit parameters from the catalog
	var orbit_center: Vector3 = Vector3.ZERO
	var orbit_radius: float = 15.0
	var orbit_height: float = 12.0

	if "_orbit_center" in catalog:
		orbit_center = catalog._orbit_center
	if "_orbit_radius" in catalog:
		orbit_radius = catalog._orbit_radius
	if "_orbit_height" in catalog:
		orbit_height = catalog._orbit_height

	# Get camera
	var cam: Camera3D = null
	if "_camera" in catalog:
		cam = catalog._camera
	if not cam:
		cam = root.get_viewport().get_camera_3d()
	if not cam:
		push_error("perfect_shot: No camera found in MapCatalog")
		_report["failed"] += 1
		return

	# Use environment angles for maps (always LARGE/HUGE)
	var angles: Array[Dictionary] = Framer.ANGLES_ENVIRONMENT
	if _hero_only:
		angles = [angles[0]]

	var out_dir: String = _output_dir + "/maps/" + _target
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	for angle in angles:
		var pitch_factor: float = angle.get("pitch_factor", 0.35)
		var yaw: float = angle["yaw"]

		var elevation: float = orbit_height * pitch_factor
		var h_dist: float = orbit_radius * (1.0 - pitch_factor * 0.5)
		cam.global_position = Vector3(
			orbit_center.x + sin(yaw) * h_dist,
			orbit_center.y + elevation,
			orbit_center.z + cos(yaw) * h_dist
		)
		cam.look_at(orbit_center, Vector3.UP)

		await _wait(_settle_seconds)

		var img: Image = root.get_texture().get_image()
		if img:
			var path: String = out_dir + "/" + str(angle["name"]) + ".png"
			var abs_path: String = ProjectSettings.globalize_path(path)
			img.save_png(abs_path)
			print("perfect_shot [map]: Saved %s" % str(angle["name"]))

	_report["captured"] += 1
	_report["targets"].append({"name": _target, "type": "map", "status": "ok"})


# ═══════════════════════════════════════════════════════════════
# BATCH MODE
# ═══════════════════════════════════════════════════════════════

func _run_batch() -> void:
	print("perfect_shot [batch]: Loading targets from '%s'..." % _targets_path)

	# Normalize path separators and try multiple access methods
	var file_path: String = _targets_path.replace("\\", "/")
	if not FileAccess.file_exists(file_path):
		file_path = ProjectSettings.globalize_path(_targets_path)
	if not FileAccess.file_exists(file_path):
		# Try as-is (absolute path with forward slashes)
		file_path = _targets_path.replace("\\", "/")

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("perfect_shot: Cannot open targets file: %s" % _targets_path)
		quit(1)
		return
	var json_str: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if not parsed is Array:
		push_error("perfect_shot: Targets file must be a JSON array")
		quit(1)
		return

	var targets: Array = parsed as Array
	print("perfect_shot [batch]: Processing %d targets..." % targets.size())

	# Build scaffold once for non-map targets
	_scaffold = Scaffold.new()
	_scaffold.build(self)
	await process_frame

	for entry in targets:
		if not entry is Dictionary:
			continue
		var mode: String = str((entry as Dictionary).get("mode", "artifact"))
		var target: String = str((entry as Dictionary).get("target", ""))
		var dna: String = str((entry as Dictionary).get("dna", ""))

		match mode:
			"artifact":
				_target = target
				await _run_artifact_with_scaffold(target)
			"scene":
				_target = target
				await _run_scene_with_scaffold(target)
			"critter":
				_dna_path = dna
				await _run_critter_with_scaffold(dna)
			"map":
				_target = target
				# Maps need their own scene — teardown scaffold, run map, rebuild
				_scaffold.teardown()
				await process_frame
				await _run_map()
				_scaffold = Scaffold.new()
				_scaffold.build(self)
				await process_frame
			_:
				push_warning("perfect_shot [batch]: Unknown mode '%s', skipping" % mode)

	_scaffold.teardown()


## Artifact capture using the persistent scaffold (for batch mode).
func _run_artifact_with_scaffold(lookup_name: String) -> void:
	var artifact_info: Dictionary = _find_artifact(lookup_name)
	if artifact_info.is_empty():
		push_warning("perfect_shot [batch]: Artifact not found: %s" % lookup_name)
		_report["failed"] += 1
		return

	var scene_path: String = str(artifact_info.get("scene", "")).strip_edges()
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("perfect_shot [batch]: Scene not found for %s" % lookup_name)
		_report["failed"] += 1
		return

	var scene = ResourceLoader.load(scene_path)
	if not scene:
		_report["failed"] += 1
		return

	var instance = scene.instantiate()
	if not instance or not (instance is Node3D):
		if instance:
			instance.queue_free()
		_report["failed"] += 1
		return

	var out_dir: String = _output_dir + "/" + lookup_name
	await _capture_with_scaffold(instance as Node3D, out_dir, lookup_name)


## Scene capture using the persistent scaffold.
func _run_scene_with_scaffold(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		_report["failed"] += 1
		return

	var scene = ResourceLoader.load(scene_path)
	if not scene:
		_report["failed"] += 1
		return

	var instance = scene.instantiate()
	if not instance or not (instance is Node3D):
		if instance:
			instance.queue_free()
		_report["failed"] += 1
		return

	var scene_name: String = scene_path.get_file().get_basename()
	var out_dir: String = _output_dir + "/" + scene_name
	await _capture_with_scaffold(instance as Node3D, out_dir, scene_name)


## Critter capture using the persistent scaffold.
func _run_critter_with_scaffold(dna_path: String) -> void:
	var file_path: String = dna_path.replace("\\", "/")
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("perfect_shot [batch]: Cannot open DNA: %s" % dna_path)
		_report["failed"] += 1
		return
	var json_str: String = file.get_as_text()
	file.close()

	var dna: CritterDNA = CritterDNA.from_json(json_str)
	if not dna:
		_report["failed"] += 1
		return

	var trait_mapper := CritterTraitMapper.new()
	var mesh_root := Node3D.new()
	mesh_root.name = "Critter_%s" % dna.get_kingdom_name()
	MorphologyRouter.build(dna, mesh_root, trait_mapper, 0)

	var critter_id: String = dna_path.get_file().get_basename()
	var out_dir: String = _output_dir + "/critters/" + critter_id
	await _capture_with_scaffold(mesh_root, out_dir, critter_id)


# ═══════════════════════════════════════════════════════════════
# CORE CAPTURE PIPELINE
# ═══════════════════════════════════════════════════════════════

## Capture an instance using a fresh scaffold (single-target modes).
func _capture_instance(instance: Node3D, out_dir: String, target_name: String) -> void:
	# Build scaffold
	_scaffold = Scaffold.new()
	_scaffold.build(self)
	await process_frame

	await _capture_with_scaffold(instance, out_dir, target_name)

	_scaffold.teardown()
	await process_frame


## Capture an instance using the persistent scaffold (batch-compatible).
func _capture_with_scaffold(instance: Node3D, out_dir: String, target_name: String) -> void:
	_scaffold.ensure_valid()
	_scaffold.clear_container()
	await process_frame

	# Add instance to scaffold (DON'T center yet — wait for _ready to finish)
	_scaffold.load_into_container(instance)
	await process_frame
	await process_frame
	await process_frame

	# Wait for scene to settle (physics, particles, procedural _ready)
	await _wait(_wait_seconds)

	# NOW center — after all procedural geometry is built
	_scaffold.center_instance(instance)
	await process_frame

	# Analyze the FINAL geometry (after centering)
	var analysis: Dictionary = Framer.analyze(instance)
	var size_class: int = analysis["size_class"]
	var angles: Array[Dictionary] = analysis["angles"]

	if _hero_only and angles.size() > 0:
		angles = [angles[0]]

	# Apply size-aware scaffold adjustments
	_scaffold.apply_size_preset(size_class, analysis["aabb"])

	print("perfect_shot: '%s' — size=%s, aabb=%s, distance=%.1f, angles=%d" % [
		target_name,
		analysis["size_name"],
		str(analysis["aabb"].size),
		analysis["orbit_distance"],
		angles.size(),
	])

	# Ensure output directory exists
	var abs_out: String = ProjectSettings.globalize_path(out_dir)
	DirAccess.make_dir_recursive_absolute(abs_out)

	# Capture each angle
	for angle in angles:
		_scaffold.position_camera_from_angle(angle, analysis)
		await _wait(_settle_seconds)

		var angle_name: String = str(angle["name"])
		var output_path: String = out_dir + "/" + angle_name + ".png"
		var ok: bool = _scaffold.save_screenshot(output_path)

		if ok:
			print("perfect_shot:   Saved %s.png" % angle_name)
		else:
			push_warning("perfect_shot:   Failed to save %s.png" % angle_name)

	# Save metadata
	var metadata: Dictionary = {
		"target": target_name,
		"size_class": analysis["size_name"],
		"aabb_size": {"x": analysis["aabb"].size.x, "y": analysis["aabb"].size.y, "z": analysis["aabb"].size.z},
		"max_dimension": analysis["max_dimension"],
		"orbit_distance": analysis["orbit_distance"],
		"angles_captured": angles.size(),
		"captured_at": Time.get_datetime_string_from_system(),
	}
	var meta_path: String = ProjectSettings.globalize_path(out_dir + "/metadata.json")
	var meta_file := FileAccess.open(meta_path, FileAccess.WRITE)
	if meta_file:
		meta_file.store_string(JSON.stringify(metadata, "\t"))
		meta_file.close()

	_report["captured"] += 1
	_report["targets"].append({"name": target_name, "type": _mode, "status": "ok", "size": analysis["size_name"]})

	# Cleanup instance
	_scaffold.clear_container()
	await process_frame


# ═══════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════

func _wait(seconds: float) -> void:
	var timer := Timer.new()
	root.add_child(timer)
	timer.wait_time = seconds
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()


func _find_artifact(lookup_name: String) -> Dictionary:
	var registry_dir: String = "res://commons/artifacts/registry"
	var dir := DirAccess.open(registry_dir)
	if not dir:
		push_error("perfect_shot: Cannot open registry dir")
		return {}

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path: String = registry_dir.path_join(file_name)
			var json_text: String = FileAccess.get_file_as_string(path)
			if not json_text.is_empty():
				var json2 := JSON.new()
				if json2.parse(json_text) == OK and json2.data is Dictionary:
					var data2: Dictionary = json2.data
					var artifacts2: Dictionary = data2.get("artifacts", data2)
					if artifacts2.has(lookup_name):
						return artifacts2[lookup_name]
		file_name = dir.get_next()
	dir.list_dir_end()
	return {}


func _hide_overlay_nodes(catalog: Node) -> void:
	var names: Array[String] = [
		"DesktopMapSwitcherOverlay",
		"MapDataEditorOverlay",
		"MapLayerEditorOverlay",
		"ProjectDashboardOverlay",
		"StatusLabel",
		"MapBrowser3D",
	]
	for node_name in names:
		var node: Node = catalog.get_node_or_null(node_name)
		if node == null:
			continue
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		elif node is Control:
			(node as Control).visible = false
		elif node is Node3D:
			(node as Node3D).visible = false


func _save_report() -> void:
	var report_path: String = ProjectSettings.globalize_path(_output_dir + "/capture_report.json")
	var dir_path: String = report_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)

	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_report, "\t"))
		file.close()
		print("perfect_shot: Report saved to %s" % report_path)
