extends SceneTree

## Unified capture pipeline — single Godot process captures all artifacts & maps.
## Uses input hashing (Manifest) to skip unchanged targets.
##
## Usage:
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_all.gd -- \
##     --outdir=user://capture_output \
##     --manifest=user://capture_manifest.json \
##     --sequence=forces \
##     --skip-unchanged
##
## Flags:
##   --outdir=<path>        Where to save screenshots (default: user://capture_output)
##   --manifest=<path>      Manifest JSON path (default: user://capture_manifest.json)
##   --sequence=<name>      Only capture targets from this sequence (default: all)
##   --skip-unchanged       Skip targets whose source hash matches manifest
##   --no-skip              Force re-capture everything
##   --artifacts-only       Only capture artifacts, skip maps
##   --maps-only            Only capture maps, skip artifacts
##   --wait=<seconds>       Per-target settle time (default: 2.0)

const Manifest = preload("res://commons/testing/capture_manifest.gd")

const REGISTRY_DIR := "res://commons/artifacts/registry/"
const SPINE_PATH := "res://commons/maps/curriculum_spine.json"
const SEQUENCES_DIR := "res://commons/maps/sequences/"
const MAP_CATALOG_SCENE := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

# ── CLI options ──────────────────────────────────────────────────
var _outdir: String = "user://capture_output"
var _manifest_path: String = "user://capture_manifest.json"
var _sequence_filter: String = ""
var _skip_unchanged: bool = true
var _artifacts_only: bool = false
var _maps_only: bool = false
var _bays_only: bool = false
var _wait_seconds: float = 2.0
var _settle_seconds: float = 0.5

# ── Runtime state ────────────────────────────────────────────────
var _manifest: Dictionary = {}
var _stats := { "captured": 0, "skipped": 0, "failed": 0 }
var _failed_list: PackedStringArray = []
var _start_time: int = 0

# Persistent scaffold for artifact captures
var _scene_root: Node3D
var _camera: Camera3D
var _ground: MeshInstance3D
var _instance_container: Node3D

# Artifact angle presets (yaw, pitch in radians)
const ARTIFACT_ANGLES: Array[Dictionary] = [
	{ "name": "front",  "yaw": 0.4,    "pitch": 0.4   },
	{ "name": "left",   "yaw": 1.97,   "pitch": 0.35  },
	{ "name": "right",  "yaw": -1.17,  "pitch": 0.35  },
	{ "name": "top",    "yaw": 0.4,    "pitch": 1.2   },
]

# Map angle presets (yaw radians, pitch_factor 0-1)
const MAP_ANGLES: Array[Dictionary] = [
	{ "name": "above",  "yaw": 0.0,       "pitch_factor": 0.95 },
	{ "name": "front",  "yaw": 0.0,       "pitch_factor": 0.35 },
	{ "name": "left",   "yaw": PI * 0.5,  "pitch_factor": 0.35 },
	{ "name": "right",  "yaw": PI * -0.5, "pitch_factor": 0.35 },
]


# ══════════════════════════════════════════════════════════════════
# INITIALIZATION
# ══════════════════════════════════════════════════════════════════

func _initialize() -> void:
	_parse_args()
	call_deferred("_run")


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = String(raw_arg).strip_edges()
		if arg == "--skip-unchanged":
			_skip_unchanged = true
			continue
		if arg == "--no-skip":
			_skip_unchanged = false
			continue
		if arg == "--artifacts-only":
			_artifacts_only = true
			continue
		if arg == "--maps-only":
			_maps_only = true
			continue
		if arg == "--bays-only":
			_bays_only = true
			continue
		if not arg.begins_with("--") or arg.find("=") <= 2:
			continue
		var eq_idx: int = arg.find("=")
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"outdir":
				_outdir = value
			"manifest":
				_manifest_path = value
			"sequence":
				_sequence_filter = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.5, float(value))
			"settle":
				if value.is_valid_float():
					_settle_seconds = maxf(0.1, float(value))


# ══════════════════════════════════════════════════════════════════
# MAIN PIPELINE
# ══════════════════════════════════════════════════════════════════

func _run() -> void:
	_start_time = Time.get_ticks_msec()
	print("=" .repeat(60))
	print("  CAPTURE ALL — Unified Pipeline")
	print("=" .repeat(60))
	print("  Output:    %s" % _outdir)
	print("  Manifest:  %s" % _manifest_path)
	print("  Sequence:  %s" % (_sequence_filter if not _sequence_filter.is_empty() else "ALL"))
	print("  Skip:      %s" % str(_skip_unchanged))
	print("")

	# Load manifest
	_manifest = Manifest.load_manifest(_manifest_path)
	var summary := Manifest.get_summary(_manifest)
	print("  Manifest:  %d existing entries (%d ok, %d failed)" % [
		summary["total"], summary["ok"], summary["failed"]
	])
	print("")

	# Phase A: Enumerate targets
	var targets: Dictionary = _enumerate_targets()
	var artifact_targets: Array = targets.get("artifacts", [])
	var map_targets: Array = targets.get("maps", [])

	print("  Targets:   %d artifacts, %d maps" % [artifact_targets.size(), map_targets.size()])
	print("")

	# Phase B: Artifact captures
	if not _maps_only and artifact_targets.size() > 0:
		print("─── Phase B: Artifact Captures (%d) ───" % artifact_targets.size())
		_build_scaffold()
		for i in artifact_targets.size():
			var target: Dictionary = artifact_targets[i]
			var idx: int = i + 1
			var label: String = target["lookup_name"]
			print("[A %d/%d] %s" % [idx, artifact_targets.size(), label])
			await _capture_artifact(target)
		_teardown_scaffold()
		print("")

	# Phase C: Map captures
	if not _artifacts_only and map_targets.size() > 0:
		print("─── Phase C: Map Captures (%d) ───" % map_targets.size())
		for i in map_targets.size():
			var target: Dictionary = map_targets[i]
			var idx: int = i + 1
			var label: String = target["map_name"]
			print("[M %d/%d] %s" % [idx, map_targets.size(), label])
			await _capture_map(target)
		print("")

	# Phase D: Save & Report
	Manifest.save_manifest(_manifest_path, _manifest)
	_print_report()
	_save_report_json()
	quit(0)


# ══════════════════════════════════════════════════════════════════
# PHASE A: ENUMERATE TARGETS
# ══════════════════════════════════════════════════════════════════

func _enumerate_targets() -> Dictionary:
	var maps: Array = []
	var artifact_lookup_set: Dictionary = {}  # lookup_name -> scene_path
	var artifact_targets: Array = []

	# Bays mode: capture the standalone Curation_Bay_* gallery maps (they're not in any sequence).
	# Skips any whose front.png already exists in the outdir, so a crash-recovery loop can resume
	# (some bays contain creature/physics artifacts that can segfault Godot — one crash must not lose
	# the whole run; the wrapper placeholders the crasher and re-invokes).
	if _bays_only:
		var bdir := DirAccess.open("res://commons/maps")
		if bdir:
			for sub in bdir.get_directories():
				if sub.begins_with("Curation_Bay_") and FileAccess.file_exists("res://commons/maps/%s/map_data.json" % sub):
					if FileAccess.file_exists(_map_shot_path(sub, "front")):
						continue
					maps.append({ "map_name": sub, "sequence": "bays" })
		maps.sort_custom(func(a, b): return str(a["map_name"]) < str(b["map_name"]))
		return { "artifacts": [], "maps": maps }

	# Read sequence files to discover maps and their artifacts
	var sequence_names: Array = _get_sequence_names()
	for seq_name in sequence_names:
		if not _sequence_filter.is_empty() and seq_name != _sequence_filter:
			continue
		var seq_data: Dictionary = _load_sequence(seq_name)
		var seq_maps: Array = seq_data.get("maps", [])
		for map_name in seq_maps:
			maps.append({ "map_name": str(map_name), "sequence": seq_name })
			# Extract artifact lookup names from map_data.json
			var map_artifacts: Array = _extract_map_artifacts(str(map_name))
			for lookup in map_artifacts:
				if not artifact_lookup_set.has(lookup):
					artifact_lookup_set[lookup] = ""

	# Resolve each artifact lookup_name to its scene path
	var all_registry: Dictionary = _load_all_registries()
	for lookup_name in artifact_lookup_set:
		if all_registry.has(lookup_name):
			var entry: Dictionary = all_registry[lookup_name]
			var scene_path: String = str(entry.get("scene", ""))
			if not scene_path.is_empty():
				artifact_targets.append({
					"lookup_name": lookup_name,
					"scene_path": scene_path,
				})
			else:
				push_warning("capture_all: No scene path for artifact '%s'" % lookup_name)
		else:
			push_warning("capture_all: Artifact '%s' not found in any registry" % lookup_name)

	return { "artifacts": artifact_targets, "maps": maps }


func _get_sequence_names() -> Array:
	if not _sequence_filter.is_empty():
		return [_sequence_filter]

	# Read from curriculum_spine.json
	var names: Array = []
	var text: String = FileAccess.get_file_as_string(SPINE_PATH)
	if text.is_empty():
		push_warning("capture_all: Cannot read curriculum spine")
		return names
	var json := JSON.new()
	if json.parse(text) != OK:
		return names
	var data: Dictionary = json.data if json.data is Dictionary else {}

	# Spine sequences
	var spine: Dictionary = data.get("spine", {})
	var spine_seqs: Array = spine.get("sequences", [])
	for seq in spine_seqs:
		if seq is Dictionary and seq.has("name"):
			names.append(str(seq["name"]))

	# Branch sequences
	var branches: Dictionary = data.get("branches", {})
	var branch_seqs: Array = branches.get("sequences", [])
	for seq in branch_seqs:
		if seq is Dictionary and seq.has("name"):
			names.append(str(seq["name"]))

	return names


func _load_sequence(seq_name: String) -> Dictionary:
	var path: String = SEQUENCES_DIR.path_join(seq_name + ".json")
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_warning("capture_all: Cannot read sequence file: %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var data: Dictionary = json.data if json.data is Dictionary else {}
	# Sequence data is nested under sequences -> seq_name
	var inner: Dictionary = data.get("sequences", {})
	if inner.has(seq_name):
		return inner[seq_name]
	# Fallback: try root level
	return data


func _extract_map_artifacts(map_name: String) -> Array:
	var map_data_path: String = "res://commons/maps/%s/map_data.json" % map_name
	var text: String = FileAccess.get_file_as_string(map_data_path)
	if text.is_empty():
		return []
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	var data: Dictionary = json.data if json.data is Dictionary else {}
	var lookup_names: Array = []

	# Interactables layer is a 2D array of strings inside data.layers.interactables
	var layers: Dictionary = data.get("layers", data)
	var interactables = layers.get("interactables", [])

	if interactables is Array:
		for row in interactables:
			if row is Array:
				for cell in row:
					var raw: String = str(cell).strip_edges()
					if raw.is_empty() or raw == " ":
						continue
					# Extract the base lookup name:
					#   "VectorBasics:180"     → "VectorBasics"
					#   "dark_sphere"          → "dark_sphere"
					#   "catalyst_target#shape:cube" → "catalyst_target"
					var lookup: String = raw
					# Strip config suffix (#key:value)
					var hash_idx: int = lookup.find("#")
					if hash_idx > 0:
						lookup = lookup.substr(0, hash_idx)
					# Strip rotation/position suffix (:180, :-0.5)
					var colon_idx: int = lookup.find(":")
					if colon_idx > 0:
						lookup = lookup.substr(0, colon_idx)
					lookup = lookup.strip_edges()
					# Skip utility tokens (tp, sp, br, jp, an, t, etc.)
					if lookup.is_empty() or lookup.length() <= 2:
						continue
					if not lookup in lookup_names:
						lookup_names.append(lookup)

	return lookup_names


func _load_all_registries() -> Dictionary:
	var all_artifacts: Dictionary = {}
	var dir := DirAccess.open(REGISTRY_DIR)
	if not dir:
		push_error("capture_all: Cannot open registry directory: %s" % REGISTRY_DIR)
		return all_artifacts

	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var path: String = REGISTRY_DIR.path_join(fname)
			var text: String = FileAccess.get_file_as_string(path)
			if not text.is_empty():
				var json := JSON.new()
				if json.parse(text) == OK and json.data is Dictionary:
					var artifacts: Dictionary = json.data.get("artifacts", {})
					for key in artifacts:
						all_artifacts[key] = artifacts[key]
		fname = dir.get_next()
	dir.list_dir_end()

	print("  Registry:  %d artifact definitions loaded" % all_artifacts.size())
	return all_artifacts


# ══════════════════════════════════════════════════════════════════
# PHASE B: ARTIFACT CAPTURES
# ══════════════════════════════════════════════════════════════════

func _capture_artifact(target: Dictionary) -> void:
	var lookup_name: String = target["lookup_name"]
	var scene_path: String = target["scene_path"]
	var manifest_key: String = lookup_name

	# Resolve source files for hashing
	var sources: Array = Manifest.resolve_artifact_sources(scene_path)

	# Compute input hash
	var current_hash: String = Manifest.compute_file_hash(sources)

	# Build expected output file list
	var angle_names: Array = []
	var expected_files: Array = []
	for angle_def in ARTIFACT_ANGLES:
		var aname: String = angle_def["name"]
		angle_names.append(aname)
		expected_files.append(_artifact_shot_path(lookup_name, aname))

	# Check manifest — skip if unchanged
	if _skip_unchanged and not Manifest.should_capture(_manifest, manifest_key, current_hash, expected_files):
		_stats["skipped"] += 1
		print("  → SKIP (unchanged)")
		return

	# Load and instantiate the scene
	if not ResourceLoader.exists(scene_path):
		push_warning("  → FAIL (scene not found: %s)" % scene_path)
		_stats["failed"] += 1
		_failed_list.append("%s (scene not found)" % lookup_name)
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "failed")
		return

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if not packed:
		push_warning("  → FAIL (load failed: %s)" % scene_path)
		_stats["failed"] += 1
		_failed_list.append("%s (load failed)" % lookup_name)
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "failed")
		return

	var instance: Node = packed.instantiate()
	if not instance:
		push_warning("  → FAIL (instantiate failed)")
		_stats["failed"] += 1
		_failed_list.append("%s (instantiate failed)" % lookup_name)
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "failed")
		return

	# Ensure scaffold is valid
	_ensure_scaffold()
	_instance_container.add_child(instance)

	# Let _ready() and physics run
	await process_frame
	await process_frame

	# Ensure scaffold survived
	_ensure_scaffold()
	if is_instance_valid(_ground):
		_ground.visible = true
	if is_instance_valid(_camera):
		_camera.current = true

	# Lift to ground
	if instance is Node3D:
		var lift_aabb: AABB = _get_combined_aabb(instance as Node3D)
		if lift_aabb.size.length() > 0.01:
			var min_y: float = lift_aabb.position.y
			if abs(min_y) > 0.01:
				(instance as Node3D).position.y -= min_y

	# AABB framing
	var orbit_focus := Vector3(0, 1.0, 0)
	var orbit_distance: float = 5.0
	if instance is Node3D:
		var aabb: AABB = _get_combined_aabb(instance as Node3D)
		if aabb.size.length() > 0:
			orbit_focus = aabb.get_center()
			var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
			orbit_distance = max_dim * 2.0

	# Wait for rendering settle
	await create_timer(_wait_seconds).timeout
	await process_frame

	# Capture each angle
	var all_ok: bool = true
	for angle_def in ARTIFACT_ANGLES:
		var angle_name: String = angle_def["name"]
		var yaw: float = float(angle_def["yaw"])
		var pitch: float = float(angle_def["pitch"])

		var offset := Vector3(
			sin(yaw) * cos(pitch),
			sin(pitch),
			cos(yaw) * cos(pitch)
		) * orbit_distance
		_camera.global_position = orbit_focus + offset
		_camera.look_at(orbit_focus, Vector3.UP)

		await create_timer(_settle_seconds).timeout
		await process_frame
		await process_frame

		var shot_path: String = _artifact_shot_path(lookup_name, angle_name)
		if not _save_screenshot(shot_path):
			all_ok = false
			print("  → ❌ %s" % angle_name)
		else:
			print("  → ✅ %s" % angle_name)

	# Cleanup instance
	await _cleanup_instance()

	# Update manifest
	if all_ok:
		_stats["captured"] += 1
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "ok")
	else:
		_stats["failed"] += 1
		_failed_list.append("%s (partial capture)" % lookup_name)
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "failed")


func _artifact_shot_path(lookup_name: String, angle_name: String) -> String:
	return _outdir.path_join("artifacts").path_join(lookup_name).path_join("%s.png" % angle_name)


# ══════════════════════════════════════════════════════════════════
# PHASE C: MAP CAPTURES
# ══════════════════════════════════════════════════════════════════

func _capture_map(target: Dictionary) -> void:
	var map_name: String = target["map_name"]
	var manifest_key: String = "map:" + map_name

	# Resolve source files for hashing
	var sources: Array = Manifest.resolve_map_sources(map_name)
	if sources.is_empty():
		push_warning("  → FAIL (map_data.json not found for '%s')" % map_name)
		_stats["failed"] += 1
		_failed_list.append("map:%s (no map_data.json)" % map_name)
		return

	# Compute input hash
	var current_hash: String = Manifest.compute_file_hash(sources)

	# Build expected output file list
	var angle_names: Array = []
	var expected_files: Array = []
	for angle_def in MAP_ANGLES:
		var aname: String = angle_def["name"]
		angle_names.append(aname)
		expected_files.append(_map_shot_path(map_name, aname))

	# Check manifest
	if _skip_unchanged and not Manifest.should_capture(_manifest, manifest_key, current_hash, expected_files):
		_stats["skipped"] += 1
		print("  → SKIP (unchanged)")
		return

	# Load MapCatalogDesktop3D
	var change_err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if change_err != OK:
		push_warning("  → FAIL (cannot load MapCatalog scene)")
		_stats["failed"] += 1
		_failed_list.append("map:%s (catalog load failed)" % map_name)
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "failed")
		return

	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if catalog == null:
		push_warning("  → FAIL (current_scene is null after catalog load)")
		_stats["failed"] += 1
		_failed_list.append("map:%s (null scene)" % map_name)
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "failed")
		return

	# Hide overlays
	_hide_overlay_nodes(catalog)

	# Load the target map
	var loaded_ok: bool = false
	if catalog.has_method("load_map_fresh"):
		loaded_ok = bool(catalog.call("load_map_fresh", map_name))

	if not loaded_ok:
		push_warning("  → FAIL (load_map_fresh failed for '%s')" % map_name)
		_stats["failed"] += 1
		_failed_list.append("map:%s (load_map_fresh failed)" % map_name)
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "failed")
		return

	# Wait for map ready
	var ready_ok: bool = await _wait_for_map_ready(catalog, 30.0)
	if not ready_ok:
		push_warning("  → Map ready timeout, proceeding anyway")

	await create_timer(_wait_seconds).timeout
	await process_frame
	await process_frame

	# Get orbit parameters from catalog
	var orbit_center: Vector3 = catalog.get("_orbit_center") if "_orbit_center" in catalog else Vector3.ZERO
	var orbit_radius: float = catalog.get("_orbit_radius") if "_orbit_radius" in catalog else 8.0
	var orbit_height: float = catalog.get("_orbit_height") if "_orbit_height" in catalog else 6.0
	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null

	if camera == null:
		push_warning("  → FAIL (no preview camera)")
		_stats["failed"] += 1
		_failed_list.append("map:%s (no preview camera)" % map_name)
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "failed")
		return

	# Stop camera spin
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)

	# Capture each angle
	var all_ok: bool = true
	for angle_def in MAP_ANGLES:
		var angle_name: String = angle_def["name"]
		var yaw: float = float(angle_def["yaw"])
		var pitch_factor: float = float(angle_def["pitch_factor"])

		var elevation: float = orbit_height * pitch_factor
		var horizontal_dist: float = orbit_radius * (1.0 - pitch_factor * 0.5)

		var cam_pos := Vector3(
			orbit_center.x + sin(yaw) * horizontal_dist,
			orbit_center.y + elevation,
			orbit_center.z + cos(yaw) * horizontal_dist
		)
		camera.global_position = cam_pos
		camera.look_at(orbit_center, Vector3.UP)

		await create_timer(_settle_seconds).timeout
		await process_frame
		await process_frame

		var shot_path: String = _map_shot_path(map_name, angle_name)
		if not _save_screenshot(shot_path):
			all_ok = false
			print("  → ❌ %s" % angle_name)
		else:
			print("  → ✅ %s" % angle_name)

	# Update manifest
	if all_ok:
		_stats["captured"] += 1
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "ok")
	else:
		_stats["failed"] += 1
		_failed_list.append("map:%s (partial capture)" % map_name)
		Manifest.update_entry(_manifest, manifest_key, current_hash, sources, angle_names, "failed")


func _map_shot_path(map_name: String, angle_name: String) -> String:
	return _outdir.path_join("maps").path_join(map_name).path_join("%s.png" % angle_name)


# ══════════════════════════════════════════════════════════════════
# SCAFFOLD (persistent environment for artifact captures)
# ══════════════════════════════════════════════════════════════════

func _build_scaffold() -> void:
	_scene_root = Node3D.new()
	_scene_root.name = "CaptureAllScaffold"
	root.add_child(_scene_root)

	# World environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_scene_root.add_child(world_env)

	# Camera
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 50.0
	_scene_root.add_child(_camera)

	# Key light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	_scene_root.add_child(light)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	_scene_root.add_child(fill)

	# Ground plane
	_ground = MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(20, 20)
	_ground.mesh = ground_mesh
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.15, 0.15, 0.18)
	_ground.material_override = ground_mat
	_scene_root.add_child(_ground)

	# Instance container
	_instance_container = Node3D.new()
	_instance_container.name = "InstanceContainer"
	_scene_root.add_child(_instance_container)


func _ensure_scaffold() -> void:
	if not is_instance_valid(_scene_root):
		_build_scaffold()
		return
	if not is_instance_valid(_camera):
		_camera = Camera3D.new()
		_camera.current = true
		_camera.fov = 50.0
		_scene_root.add_child(_camera)
	if not is_instance_valid(_ground):
		_ground = MeshInstance3D.new()
		var ground_mesh := PlaneMesh.new()
		ground_mesh.size = Vector2(20, 20)
		_ground.mesh = ground_mesh
		var ground_mat := StandardMaterial3D.new()
		ground_mat.albedo_color = Color(0.15, 0.15, 0.18)
		_ground.material_override = ground_mat
		_scene_root.add_child(_ground)
	if not is_instance_valid(_instance_container):
		_instance_container = Node3D.new()
		_instance_container.name = "InstanceContainer"
		_scene_root.add_child(_instance_container)


func _cleanup_instance() -> void:
	if is_instance_valid(_camera):
		_camera.current = true
	if is_instance_valid(_instance_container):
		for child in _instance_container.get_children():
			child.queue_free()
		await process_frame
	_ensure_scaffold()


func _teardown_scaffold() -> void:
	if is_instance_valid(_scene_root):
		_scene_root.queue_free()
		await process_frame
	_scene_root = null
	_camera = null
	_ground = null
	_instance_container = null


# ══════════════════════════════════════════════════════════════════
# SCREENSHOT + AABB HELPERS
# ══════════════════════════════════════════════════════════════════

func _save_screenshot(output_path: String) -> bool:
	var image: Image = root.get_texture().get_image()
	if image == null:
		return false

	var absolute_path: String = ProjectSettings.globalize_path(output_path) if output_path.begins_with("user://") or output_path.begins_with("res://") else output_path
	var dir_path: String = absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	return image.save_png(absolute_path) == OK


func _get_combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false
		if child is MeshInstance3D:
			var mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = child.transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var mm = child.multimesh
			if mm and mm.instance_count > 0:
				child_aabb = child.transform * mm.get_aabb()
				has_aabb = true
		elif child is CSGShape3D:
			var child_meshes: Array = child.get_meshes()
			if child_meshes.size() >= 2:
				var m = child_meshes[1]
				if m is Mesh:
					child_aabb = child.transform * m.get_aabb()
					has_aabb = true
		elif child is GPUParticles3D:
			child_aabb = child.transform * child.visibility_aabb
			has_aabb = true
		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)
		if child is Node3D:
			var sub_aabb: AABB = _get_combined_aabb(child)
			if sub_aabb.size.length() > 0:
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)
	return result


# ══════════════════════════════════════════════════════════════════
# MAP HELPERS
# ══════════════════════════════════════════════════════════════════

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
		elif node is Node3D:
			(node as Node3D).visible = false
		elif node is CanvasItem:
			(node as CanvasItem).visible = false


func _wait_for_map_ready(catalog: Node, timeout_seconds: float) -> bool:
	var grid_system: Node = catalog.get("_grid_system") if "_grid_system" in catalog else null
	if grid_system == null:
		var fallback_wait: float = minf(timeout_seconds, 2.0)
		await create_timer(fallback_wait).timeout
		return false

	var done: bool = false
	var on_done := func() -> void:
		done = true

	if grid_system.has_signal("map_generation_complete"):
		grid_system.map_generation_complete.connect(on_done, CONNECT_ONE_SHOT)

	var elapsed: float = 0.0
	while elapsed < timeout_seconds and not done:
		if grid_system.has_method("is_map_ready") and bool(grid_system.call("is_map_ready")):
			done = true
			break
		await create_timer(0.1).timeout
		elapsed += 0.1

	if not done and grid_system.has_signal("map_generation_complete"):
		if grid_system.map_generation_complete.is_connected(on_done):
			grid_system.map_generation_complete.disconnect(on_done)

	return done


# ══════════════════════════════════════════════════════════════════
# REPORTING
# ══════════════════════════════════════════════════════════════════

func _print_report() -> void:
	var elapsed: float = (Time.get_ticks_msec() - _start_time) / 1000.0
	print("=" .repeat(60))
	print("  CAPTURE REPORT")
	print("=" .repeat(60))
	print("  Captured: %d" % _stats["captured"])
	print("  Skipped:  %d (unchanged)" % _stats["skipped"])
	print("  Failed:   %d" % _stats["failed"])
	print("  Time:     %.1f seconds (%.1f minutes)" % [elapsed, elapsed / 60.0])

	if _failed_list.size() > 0:
		print("")
		print("  Failed targets:")
		for line in _failed_list:
			print("    - %s" % line)

	print("")
	print("  Manifest: %s" % _manifest_path)
	print("  Output:   %s" % _outdir)
	print("=" .repeat(60))


func _save_report_json() -> void:
	var elapsed: float = (Time.get_ticks_msec() - _start_time) / 1000.0
	var report: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(true),
		"sequence_filter": _sequence_filter,
		"captured": _stats["captured"],
		"skipped": _stats["skipped"],
		"failed": _stats["failed"],
		"elapsed_seconds": elapsed,
		"failed_targets": Array(_failed_list),
	}

	var report_path: String = _outdir.path_join("capture_report.json")
	var absolute_path: String = ProjectSettings.globalize_path(report_path) if report_path.begins_with("user://") else report_path
	var dir_path: String = absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var file: FileAccess = FileAccess.open(absolute_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("  Report:   %s" % absolute_path)
