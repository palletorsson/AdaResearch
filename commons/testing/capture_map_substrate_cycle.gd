extends SceneTree

## Capture a real spine map at every visibility expression the substrate runner
## cycles through. Loads the map via MapCatalogDesktop3D (same path as
## capture_multi_angle.gd), finds the GridSubstrateRunner's visibility mutator,
## disables auto-cycle, then manually advances through every named expression
## and saves a PNG per pattern from the same camera angle.
##
## Output: <out>/<map>_<pattern>.png + capture_report.json
##
## Usage:
##   godot_console --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_map_substrate_cycle.gd \
##     -- --target=CA_Introduction --out=user://substrate_cycle

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

var _target: String = ""
var _output_dir: String = "user://substrate_cycle"
var _wait_seconds: float = 4.0
var _settle_seconds: float = 0.6
# camera framing (matches capture_multi_angle.gd "front" preset)
var _yaw: float = 0.0
var _pitch_factor: float = 0.35

var _report := {
	"target": "",
	"shots": [],
	"errors": [],
	"started_at_ms": 0,
}


func _initialize() -> void:
	_parse_args()
	if _target.is_empty():
		push_error("capture_map_substrate_cycle: --target=<MapName> is required")
		quit(1)
		return
	_report.target = _target
	_report.started_at_ms = Time.get_ticks_msec()
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg: String = String(raw).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq: int = arg.find("=")
		if eq <= 2:
			continue
		var key: String = arg.substr(2, eq - 2)
		var value: String = arg.substr(eq + 1).strip_edges()
		match key:
			"target":
				_target = value
			"out":
				_output_dir = value
			"wait":
				if value.is_valid_float():
					_wait_seconds = float(value)
			"settle":
				if value.is_valid_float():
					_settle_seconds = float(value)
			"yaw":
				if value.is_valid_float():
					_yaw = float(value)
			"pitch":
				if value.is_valid_float():
					_pitch_factor = clamp(float(value), 0.0, 1.0)


func _run() -> void:
	print("capture_map_substrate_cycle: target=%s outdir=%s" % [_target, _output_dir])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	var change_err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if change_err != OK:
		_fail("change_scene_to_file failed: %d" % change_err)
		return
	await process_frame
	await process_frame

	var catalog: Node = current_scene
	if not catalog:
		_fail("current_scene is null")
		return
	_hide_overlay_nodes(catalog)

	var loaded_ok: bool = bool(catalog.call("load_map_fresh", _target))
	if not loaded_ok:
		_fail("load_map_fresh returned false for '%s'" % _target)
		return

	var ready_ok: bool = await _wait_for_map_ready(catalog, 30.0)
	if not ready_ok:
		push_warning("substrate_cycle: map_ready timeout — continuing")
	await create_timer(_wait_seconds).timeout
	await process_frame

	# Find substrate runner + its visibility mutator
	var runner: Node = _find_substrate_runner(catalog)
	if not runner:
		_fail("GridSubstrateRunner not found in loaded map")
		return
	var vis_mutator: Node = _find_visibility_mutator(runner)
	if not vis_mutator:
		_fail("GridVisibilityMutator not found under the runner")
		return
	print("substrate_cycle: found runner=%s mutator=%s patterns=%d" % [
		runner.name, vis_mutator.name, vis_mutator.get_pattern_count()
	])

	vis_mutator.disable_auto_cycle()

	# Lock camera to a single front-ish angle so frames are comparable.
	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null
	if not camera:
		_fail("preview camera not found on catalog")
		return
	if catalog.has_method("set_camera_mode"):
		catalog.call("set_camera_mode", 0)  # STATIC
	_position_camera(catalog, camera)

	# Walk through every named pattern, validating walkability per pattern.
	var pattern_count: int = vis_mutator.get_pattern_count()
	for i in range(pattern_count):
		vis_mutator.set_pattern_by_index(i)
		var pname: String = vis_mutator.get_current_pattern_name()
		await create_timer(_settle_seconds).timeout
		await process_frame
		await process_frame
		var walk: Dictionary = _validate_walkability(vis_mutator)
		_save_shot(pname, walk)

	# Final settle so the last save flushes before quit.
	await create_timer(0.5).timeout
	_save_report()
	print("substrate_cycle: %d shots saved" % _report.shots.size())
	quit(0)


# --- helpers --------------------------------------------------------------

func _hide_overlay_nodes(node: Node) -> void:
	# Same overlays as capture_multi_angle.gd hides.
	for n in node.find_children("*", "", true, false):
		if n is CanvasLayer or n is Control:
			n.visible = false


func _wait_for_map_ready(catalog: Node, timeout: float) -> bool:
	var deadline: float = Time.get_ticks_msec() / 1000.0 + timeout
	while Time.get_ticks_msec() / 1000.0 < deadline:
		var ready: bool = false
		if catalog.has_method("is_map_ready"):
			ready = bool(catalog.call("is_map_ready"))
		elif "_map_ready" in catalog:
			ready = bool(catalog.get("_map_ready"))
		if ready:
			return true
		await create_timer(0.25).timeout
	return false


func _find_substrate_runner(node: Node) -> Node:
	# Search the loaded scene graph for a Node whose script is GridSubstrateRunner
	# OR any subclass thereof (FoldTheatreRunner, etc.). Walk the script's base
	# chain to detect subclasses.
	for n in node.find_children("*", "", true, false):
		var s: Script = n.get_script()
		while s:
			if s.get_global_name() == "GridSubstrateRunner":
				return n
			s = s.get_base_script()
	return null


func _find_visibility_mutator(runner: Node) -> Node:
	for child in runner.get_children():
		var s: Script = child.get_script()
		if s and s.get_global_name() == "GridVisibilityMutator":
			return child
	return null


func _position_camera(catalog: Node, camera: Camera3D) -> void:
	var orbit_center: Vector3 = catalog.get("_orbit_center") if "_orbit_center" in catalog else Vector3.ZERO
	var orbit_radius: float = catalog.get("_orbit_radius") if "_orbit_radius" in catalog else 8.0
	var orbit_height: float = catalog.get("_orbit_height") if "_orbit_height" in catalog else 6.0
	var elevation: float = orbit_height * _pitch_factor
	var horizontal_dist: float = orbit_radius * (1.0 - _pitch_factor * 0.5)
	camera.global_position = Vector3(
		orbit_center.x + sin(_yaw) * horizontal_dist,
		orbit_center.y + elevation,
		orbit_center.z + cos(_yaw) * horizontal_dist,
	)
	camera.look_at(orbit_center, Vector3.UP)


func _save_shot(pattern: String, walk: Dictionary = {}) -> void:
	var safe: String = pattern.replace("/", "_").replace(" ", "_")
	var path: String = "%s/%s__%s.png" % [_output_dir, _target, safe]
	var img: Image = root.get_viewport().get_texture().get_image()
	if not img:
		_report.errors.append({"pattern": pattern, "reason": "viewport returned null image"})
		return
	var err: int = img.save_png(path)
	if err != OK:
		_report.errors.append({"pattern": pattern, "reason": "save_png err=%d" % err})
		return
	var entry: Dictionary = {"pattern": pattern, "path": path}
	if not walk.is_empty():
		entry["walk"] = walk
	_report.shots.append(entry)
	var walk_str: String = ""
	if not walk.is_empty():
		walk_str = " · path %s (steps=%s, fill=%d)" % [
			"OK" if walk.get("connected", false) else "BROKEN",
			str(walk.get("path_steps", "—")),
			int(walk.get("fill_count", 0)),
		]
	print("  [shot] %s -> %s%s" % [pattern, path, walk_str])


# Run BFS over the FINAL visibility state (pattern + fill - carves) from
# the mutator's path_seed to path_target through 4-connected visible cubes.
# Returns connected/path_steps/fill_count for the report.
func _validate_walkability(vis_mutator: Node) -> Dictionary:
	var dims: Vector3i = vis_mutator.resolve_dims()
	var w: int = max(dims.x, 1)
	var h: int = max(dims.y, 1)
	var d: int = max(dims.z, 1)
	var n_layers: int = clamp(int(vis_mutator.floor_plan_layers), 1, h)
	var multimesh: MultiMesh = vis_mutator.multimesh
	if not multimesh:
		return {"connected": false, "reason": "no multimesh"}
	var seed: Vector3i = vis_mutator.floor_plan_seed
	var target: Vector3i = vis_mutator.floor_plan_target
	if seed.x < 0:
		seed = Vector3i(0, 0, 0)
	if target.x < 0:
		target = Vector3i(w - 1, 0, d - 1)
	seed = Vector3i(clamp(seed.x, 0, w - 1), clamp(seed.y, 0, n_layers - 1), clamp(seed.z, 0, d - 1))
	target = Vector3i(clamp(target.x, 0, w - 1), clamp(target.y, 0, n_layers - 1), clamp(target.z, 0, d - 1))

	# Read the actual visibility from each instance's transform — basis with
	# zero scale = hidden cube; non-zero = visible.
	var visible: PackedByteArray = PackedByteArray()
	visible.resize(multimesh.instance_count)
	for i in range(multimesh.instance_count):
		var xf: Transform3D = multimesh.get_instance_transform(i)
		var sc: Vector3 = xf.basis.get_scale()
		visible[i] = 1 if sc.length() > 0.01 else 0

	var seed_idx: int = seed.y * (w * d) + seed.z * w + seed.x
	var target_idx: int = target.y * (w * d) + target.z * w + target.x
	if seed_idx >= visible.size() or target_idx >= visible.size():
		return {"connected": false, "reason": "out of bounds"}
	if visible[seed_idx] == 0 or visible[target_idx] == 0:
		return {
			"connected": false,
			"reason": "endpoint not visible",
			"seed_visible": visible[seed_idx] != 0,
			"target_visible": visible[target_idx] != 0,
		}

	# 4-connected BFS through visible cubes in the floor strata.
	const DIRS: Array = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	var dist: PackedInt32Array = PackedInt32Array()
	dist.resize(w * h * d)
	for k in range(dist.size()):
		dist[k] = -1
	dist[seed_idx] = 0
	var queue: Array = [seed_idx]
	var head: int = 0
	while head < queue.size():
		var u: int = queue[head]
		head += 1
		if u == target_idx:
			break
		var uy: int = u / (w * d)
		var uz: int = (u / w) % d
		var ux: int = u % w
		for dir in DIRS:
			var nx: int = ux + dir.x
			var ny: int = uy + dir.y
			var nz: int = uz + dir.z
			if nx < 0 or nx >= w or ny < 0 or ny >= n_layers or nz < 0 or nz >= d:
				continue
			var ni: int = ny * (w * d) + nz * w + nx
			if visible[ni] == 0 or dist[ni] != -1:
				continue
			dist[ni] = dist[u] + 1
			queue.append(ni)

	var fill_count: int = 0
	if vis_mutator.has_method("get") and "_floor_plan_fill_mask" in vis_mutator:
		var fm: PackedByteArray = vis_mutator._floor_plan_fill_mask
		for k in range(fm.size()):
			if fm[k] != 0:
				fill_count += 1

	return {
		"connected": dist[target_idx] != -1,
		"path_steps": dist[target_idx] if dist[target_idx] != -1 else null,
		"fill_count": fill_count,
		"seed": "%d,%d,%d" % [seed.x, seed.y, seed.z],
		"target": "%d,%d,%d" % [target.x, target.y, target.z],
	}


func _save_report() -> void:
	var path: String = "%s/capture_report.json" % _output_dir
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_report, "  "))
		f.close()


func _fail(reason: String) -> void:
	push_error("capture_map_substrate_cycle: %s" % reason)
	_report.errors.append({"reason": reason})
	_save_report()
	quit(1)
