extends SceneTree

## In-context artifact vetting using the desktop player.
## Loads lab_desktop.tscn, walks through each map in a sequence,
## finds every artifact's grid position, teleports the player camera
## near each artifact, and captures what the player would actually see.
##
## Uses a single wide-FOV camera with VR barrel distortion to simulate
## what the player sees through a VR headset lens.
##
## Usage:
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_desktop_vet.gd -- \
##     --sequence=forces --outdir=user://vet_shots --wait=2.0

const LAB_DESKTOP_SCENE := "res://commons/scenes/lab_desktop.tscn"

# Camera: stand 2.5 units away, 1.6m eye height, look at artifact center
const CAMERA_DISTANCE := 2.5
const CAMERA_HEIGHT := 1.6
const CAMERA_FOV := 90.0  # Wide FOV like VR headset
const CAMERA_YAW := 0.35  # Slight offset from dead-front for a natural angle

# Barrel distortion shader (simulates VR lens warp)
const BARREL_SHADER_CODE := """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float k1 : hint_range(-0.5, 0.8) = 0.22;
uniform float k2 : hint_range(-0.3, 0.5) = 0.06;
uniform float chromatic : hint_range(0.0, 0.02) = 0.003;
uniform float vignette_strength : hint_range(0.0, 1.5) = 0.45;

vec2 barrel_distort(vec2 uv, float strength1, float strength2) {
	vec2 centered = uv - 0.5;
	float r2 = dot(centered, centered);
	float r4 = r2 * r2;
	float factor = 1.0 + strength1 * r2 + strength2 * r4;
	return 0.5 + centered * factor;
}

void fragment() {
	// Chromatic aberration: slightly different distortion per channel
	vec2 uv_r = barrel_distort(SCREEN_UV, k1 * 1.02, k2 * 1.04);
	vec2 uv_g = barrel_distort(SCREEN_UV, k1, k2);
	vec2 uv_b = barrel_distort(SCREEN_UV, k1 * 0.98, k2 * 0.96);

	float r = texture(screen_texture, uv_r).r;
	float g = texture(screen_texture, uv_g).g;
	float b = texture(screen_texture, uv_b).b;

	// Vignette: darken edges
	vec2 vig_uv = SCREEN_UV * 2.0 - 1.0;
	float vig = 1.0 - dot(vig_uv, vig_uv) * vignette_strength;
	vig = clamp(vig, 0.0, 1.0);

	// Black out pixels that went out of bounds
	float mask = 1.0;
	if (uv_r.x < 0.0 || uv_r.x > 1.0 || uv_r.y < 0.0 || uv_r.y > 1.0) mask = 0.0;
	if (uv_g.x < 0.0 || uv_g.x > 1.0 || uv_g.y < 0.0 || uv_g.y > 1.0) mask = 0.0;
	if (uv_b.x < 0.0 || uv_b.x > 1.0 || uv_b.y < 0.0 || uv_b.y > 1.0) mask = 0.0;

	COLOR = vec4(r * vig, g * vig, b * vig, 1.0) * mask;
}
"""

var _sequence_filter: String = ""
var _outdir: String = "user://vet_shots"
var _wait_seconds: float = 2.5
var _settle_seconds: float = 0.8
var _warp_enabled: bool = true
var _start_map: int = 0    # Skip the first N maps (0 = start from beginning)
var _max_maps: int = 0     # Process at most N maps (0 = all remaining)

# Heavy artifacts that create too many Vulkan RIDs when loaded in sequence.
# These still get captured, but are deferred to last so if the RID pool
# overflows, the lighter artifacts are already done.
const HEAVY_ARTIFACTS: PackedStringArray = [
	"three_body_problem",
	"nbody_simulation",
	"forcedirected3d",
	"example_2_8_two_body_attraction_vr",
	"example_2_9_n_body_attraction_vr",
]

var _stats := { "captured": 0, "skipped": 0, "failed": 0 }
var _failed_list: PackedStringArray = []


func _initialize() -> void:
	_parse_args()
	if _sequence_filter.is_empty():
		push_error("capture_desktop_vet: --sequence=<name> is required")
		quit(1)
		return
	call_deferred("_run")


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--"):
			continue
		# Handle flags without =
		if arg.find("=") < 0:
			match arg.substr(2):
				"no-warp":
					_warp_enabled = false
			continue
		var eq_idx: int = arg.find("=")
		if eq_idx <= 2:
			continue
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"sequence":
				_sequence_filter = value
			"outdir":
				_outdir = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = maxf(0.5, float(value))
			"settle":
				if value.is_valid_float():
					_settle_seconds = maxf(0.1, float(value))
			"start-map":
				if value.is_valid_int():
					_start_map = maxi(0, int(value))
			"max-maps":
				if value.is_valid_int():
					_max_maps = maxi(0, int(value))


func _run() -> void:
	var start_time: int = Time.get_ticks_msec()
	print("=" .repeat(60))
	print("  DESKTOP VET — In-Context Artifact Capture (VR Warp)")
	print("=" .repeat(60))
	print("  Sequence:  %s" % _sequence_filter)
	print("  Output:    %s" % _outdir)
	print("  VR Warp:   %s" % ("ON" if _warp_enabled else "OFF"))
	print("  FOV:       %d°" % int(CAMERA_FOV))
	print("")

	# Load lab_desktop.tscn
	print("Loading lab_desktop.tscn...")
	var change_err: int = change_scene_to_file(LAB_DESKTOP_SCENE)
	if change_err != OK:
		push_error("Failed to load lab_desktop.tscn")
		quit(1)
		return

	await process_frame
	await process_frame
	await process_frame

	var lab: Node = current_scene
	if lab == null:
		push_error("current_scene is null")
		quit(1)
		return

	# Find key nodes
	var grid_system: Node = _find_node(lab, "LabGridSystem")
	if grid_system == null:
		grid_system = _find_node(lab, "GridSystem")
	var player: Node = _find_node(lab, "DesktopPlayer")

	if grid_system == null:
		push_error("Could not find LabGridSystem/GridSystem node")
		quit(1)
		return

	print("  GridSystem: %s" % grid_system.name)
	print("  Player:     %s" % (player.name if player else "NOT FOUND"))
	print("")

	# Get camera - either from player or standalone
	var camera: Camera3D = null
	if player:
		camera = player.find_child("Camera3D", true, false) as Camera3D
	if camera == null:
		camera = lab.find_child("Camera3D", true, false) as Camera3D
	if camera == null:
		# Create our own camera
		camera = Camera3D.new()
		lab.add_child(camera)
		print("  Created capture camera")

	# Set wide FOV for VR-like view
	camera.fov = CAMERA_FOV
	camera.current = true

	# Disable player physics so it doesn't fall
	if player and player is CharacterBody3D:
		player.set_physics_process(false)
		player.set_process(false)

	# Hide all UI overlays so they don't appear in captures
	_hide_ui_overlays(lab)

	# Add barrel distortion overlay if enabled
	if _warp_enabled:
		_add_barrel_distortion_overlay()
		print("  Barrel distortion overlay added")

	# Load the sequence to get map list, apply start/max slicing
	var all_maps: Array = _get_sequence_maps(_sequence_filter)
	var maps: Array = all_maps.slice(_start_map)
	if _max_maps > 0 and maps.size() > _max_maps:
		maps = maps.slice(0, _max_maps)
	print("  Maps in sequence: %d total, processing %d (start=%d)" % [
		all_maps.size(), maps.size(), _start_map
	])
	print("")

	# Process each map
	for map_idx in maps.size():
		var map_name: String = maps[map_idx]
		print("─── Map %d/%d: %s ───" % [map_idx + 1, maps.size(), map_name])

		# Pre-clear: if not the first map, explicitly clear old map resources
		# and wait for Vulkan to reclaim RIDs before loading the next map.
		if map_idx > 0:
			print("  Clearing previous map resources...")
			if grid_system.has_method("_clear_all_components"):
				grid_system.call("_clear_all_components")
			# Many frames for queue_free() to actually process all deferred deletes
			for _f in 40:
				await process_frame
			RenderingServer.force_sync()
			for _f in 10:
				await process_frame

		# Load the map
		grid_system.set("map_name", map_name)
		grid_system.set("reload_map", true)

		# Wait for map generation
		var ready: bool = await _wait_for_ready(grid_system, 30.0)
		if not ready:
			print("  ⚠️ Map ready timeout, proceeding anyway")

		await create_timer(_wait_seconds).timeout
		# Extra frames for resource settling
		for _f in 5:
			await process_frame

		# Parse interactables from map_data.json to find artifact positions
		var artifact_positions: Array = _get_artifact_positions(map_name)
		print("  Artifacts found: %d" % artifact_positions.size())

		# Get map dimensions for boundary-aware camera placement
		var map_dims: Vector2i = _get_map_dimensions(map_name)

		# Sort: light artifacts first, heavy ones last (so if RID pool
		# overflows, we've already captured the lighter ones)
		var light_arts: Array = []
		var heavy_arts: Array = []
		for art in artifact_positions:
			if art["name"] in HEAVY_ARTIFACTS:
				heavy_arts.append(art)
			else:
				light_arts.append(art)
		var sorted_arts: Array = light_arts + heavy_arts
		if heavy_arts.size() > 0:
			print("  (Deferred %d heavy artifacts to end)" % heavy_arts.size())

		# Capture each artifact — single angle with VR warp
		for art_idx in sorted_arts.size():
			var art: Dictionary = sorted_arts[art_idx]
			var art_name: String = art["name"]
			var world_pos: Vector3 = art["world_pos"]
			var grid_x: int = int(art["grid_x"])
			var grid_z: int = int(art["grid_z"])

			# Pick camera direction that stays inside the map
			# Default: approach from +z side (yaw ~ 0.35)
			# If artifact is near an edge, approach from the map center instead
			var yaw: float = _pick_best_yaw(grid_x, grid_z, map_dims)

			var cam_offset := Vector3(
				sin(yaw) * CAMERA_DISTANCE,
				CAMERA_HEIGHT,
				cos(yaw) * CAMERA_DISTANCE
			)
			var cam_pos: Vector3 = world_pos + cam_offset
			var look_target: Vector3 = world_pos + Vector3(0, 0.8, 0)  # Look at ~waist height

			# Move player body if it exists
			if player and player is Node3D:
				(player as Node3D).global_position = cam_pos
				if "velocity" in player:
					player.set("velocity", Vector3.ZERO)

			# Position and orient the camera
			camera.global_position = cam_pos
			camera.look_at(look_target, Vector3.UP)
			camera.current = true

			await create_timer(_settle_seconds).timeout
			await process_frame
			await process_frame

			# Capture — single VR-warped shot per artifact
			var shot_path: String = _outdir.path_join(map_name).path_join("%s.png" % art_name)
			if _save_screenshot(shot_path):
				print("  ✅ %s" % art_name)
				_stats["captured"] += 1
			else:
				print("  ❌ %s" % art_name)
				_stats["failed"] += 1
				_failed_list.append("%s/%s" % [map_name, art_name])

		print("")

	# Report
	var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
	print("=" .repeat(60))
	print("  VET REPORT")
	print("=" .repeat(60))
	print("  Captured: %d" % _stats["captured"])
	print("  Failed:   %d" % _stats["failed"])
	print("  Time:     %.1f seconds" % elapsed)
	if _failed_list.size() > 0:
		print("  Failed:")
		for f in _failed_list:
			print("    - %s" % f)
	print("=" .repeat(60))

	_save_report(elapsed)
	quit(0)


# ── UI Hiding ────────────────────────────────────────────────────

func _hide_ui_overlays(lab: Node) -> void:
	## Hide all desktop UI overlays so they don't appear in captures.
	## These are CanvasLayer nodes in lab_desktop.tscn.
	var overlay_names: PackedStringArray = [
		"DesktopMapSwitcherOverlay",
		"MapLayerEditorOverlay",
		"ProjectDashboardOverlay",
		"LabEvolutionEditor",
	]
	var hidden_count: int = 0
	for overlay_name in overlay_names:
		var overlay: Node = _find_node(lab, overlay_name)
		if overlay and overlay is CanvasLayer:
			(overlay as CanvasLayer).visible = false
			hidden_count += 1
		elif overlay:
			# Fallback: try hiding child Controls
			for child in overlay.get_children():
				if child is Control:
					(child as Control).visible = false
					hidden_count += 1

	# Also hide any other CanvasLayer that isn't ours
	for child in lab.get_children():
		if child is CanvasLayer and child.name != "BarrelDistortionLayer":
			(child as CanvasLayer).visible = false
			hidden_count += 1

	# Hide root-level CanvasLayers too (autoloads may add overlays)
	for child in root.get_children():
		if child is CanvasLayer and child.name != "BarrelDistortionLayer":
			(child as CanvasLayer).visible = false
			hidden_count += 1

	print("  Hidden %d UI overlays" % hidden_count)


# ── VR Barrel Distortion ────────────────────────────────────────

func _add_barrel_distortion_overlay() -> void:
	# CanvasLayer → ColorRect with barrel distortion shader
	var layer := CanvasLayer.new()
	layer.layer = 10  # On top of everything
	layer.name = "BarrelDistortionLayer"

	var rect := ColorRect.new()
	rect.name = "BarrelOverlay"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Build shader material from inline code
	var shader := Shader.new()
	shader.code = BARREL_SHADER_CODE

	var mat := ShaderMaterial.new()
	mat.shader = shader
	# Gentle VR warp — not extreme, just enough to feel immersive
	mat.set_shader_parameter("k1", 0.22)
	mat.set_shader_parameter("k2", 0.06)
	mat.set_shader_parameter("chromatic", 0.003)
	mat.set_shader_parameter("vignette_strength", 0.45)

	rect.material = mat
	layer.add_child(rect)
	root.add_child(layer)


# ── Helpers ──────────────────────────────────────────────────────

func _find_node(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	return root_node.find_child(node_name, true, false)


func _get_sequence_maps(seq_name: String) -> Array:
	var path: String = "res://commons/maps/sequences/%s.json" % seq_name
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return []
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	var data: Dictionary = json.data if json.data is Dictionary else {}
	var inner: Dictionary = data.get("sequences", {})
	if inner.has(seq_name):
		return inner[seq_name].get("maps", [])
	return data.get("maps", [])


func _get_map_dimensions(map_name: String) -> Vector2i:
	var map_data_path: String = "res://commons/maps/%s/map_data.json" % map_name
	var text: String = FileAccess.get_file_as_string(map_data_path)
	if text.is_empty():
		return Vector2i(20, 20)
	var json := JSON.new()
	if json.parse(text) != OK:
		return Vector2i(20, 20)
	var data: Dictionary = json.data if json.data is Dictionary else {}
	var w: int = int(data.get("width", 20))
	var d: int = int(data.get("depth", 20))
	return Vector2i(w, d)


func _pick_best_yaw(grid_x: int, grid_z: int, dims: Vector2i) -> float:
	## Choose camera yaw angle that points toward the map center
	## to avoid placing the camera outside the map (inside a wall).
	var center_x: float = float(dims.x) / 2.0
	var center_z: float = float(dims.y) / 2.0
	var dx: float = center_x - float(grid_x)
	var dz: float = center_z - float(grid_z)
	# atan2 gives angle from artifact toward center
	if absf(dx) < 1.0 and absf(dz) < 1.0:
		return CAMERA_YAW  # Near center, use default
	return atan2(dx, dz)


func _get_artifact_positions(map_name: String) -> Array:
	var map_data_path: String = "res://commons/maps/%s/map_data.json" % map_name
	var text: String = FileAccess.get_file_as_string(map_data_path)
	if text.is_empty():
		return []
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	var data: Dictionary = json.data if json.data is Dictionary else {}
	var layers: Dictionary = data.get("layers", data)
	var interactables = layers.get("interactables", [])
	var results: Array = []
	var seen: Dictionary = {}

	if interactables is Array:
		for z in interactables.size():
			var row = interactables[z]
			if row is Array:
				for x in (row as Array).size():
					var raw: String = str(row[x]).strip_edges()
					if raw.is_empty() or raw == " ":
						continue

					# Extract base lookup name
					var lookup: String = raw
					var hash_idx: int = lookup.find("#")
					if hash_idx > 0:
						lookup = lookup.substr(0, hash_idx)
					var colon_idx: int = lookup.find(":")
					if colon_idx > 0:
						lookup = lookup.substr(0, colon_idx)
					lookup = lookup.strip_edges()

					if lookup.is_empty() or lookup.length() <= 2:
						continue

					# Skip duplicates — capture first occurrence only
					if seen.has(lookup):
						continue
					seen[lookup] = true

					# Grid position → world position
					var world_pos := Vector3(float(x), 1.0, float(z))
					results.append({
						"name": lookup,
						"world_pos": world_pos,
						"grid_x": x,
						"grid_z": z,
					})

	return results


func _wait_for_ready(grid_system: Node, timeout_seconds: float) -> bool:
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


func _save_screenshot(output_path: String) -> bool:
	var image: Image = root.get_texture().get_image()
	if image == null:
		return false
	var absolute_path: String = ProjectSettings.globalize_path(output_path) if output_path.begins_with("user://") or output_path.begins_with("res://") else output_path
	var dir_path: String = absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	return image.save_png(absolute_path) == OK


func _save_report(elapsed: float) -> void:
	var report: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(true),
		"sequence": _sequence_filter,
		"vr_warp": _warp_enabled,
		"fov": CAMERA_FOV,
		"captured": _stats["captured"],
		"failed": _stats["failed"],
		"elapsed_seconds": elapsed,
		"failed_targets": Array(_failed_list),
	}
	var report_path: String = _outdir.path_join("vet_report.json")
	var absolute_path: String = ProjectSettings.globalize_path(report_path) if report_path.begins_with("user://") else report_path
	var dir_path: String = absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var file: FileAccess = FileAccess.open(absolute_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("  Report: %s" % absolute_path)
