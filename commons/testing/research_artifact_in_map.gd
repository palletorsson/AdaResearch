extends SceneTree
# Player-POV captures: load the actual map a curriculum places an
# artifact in, position the camera where the player would be standing
# (nearest walkable cell, distance scaled to artifact size), capture
# FPV with hands.
#
# This is the contextual companion to the orbit-style multi_shots
# captures — multi_shots shows the artifact alone; this shows the
# artifact in situ, as a player would first encounter it.
#
# CLI:
#   --map=<name>          map_data.json name in commons/maps/<name>/
#   --artifact=<lookup>   artifact lookup_name to find in interactables
#   --step-back=<cells>   how far the player stands from the artifact
#                         (default 2 — closer for big things, farther
#                         for small ones)
#
# Defaults aim at the friend/foe demo: Demo_Catalyst_Arc has 5 catalyst
# foes in a row, one per personality state.
#
# Output: user://artifact_in_map/<map>/<artifact>/<index>_<state>.png

const DESKTOP_TESTER_SCENE := "res://commons/scenes/desktop_map_tester.tscn"
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")

var _map_name: String = "Demo_Catalyst_Arc"
var _artifact_lookup: String = "catalyst_foe"
# Tight default for small artifacts (~1m cubes/creatures). With biome
# off the artifact is the only subject, so it should fill the frame.
# Override per artifact via --step-back for bigger structures.
var _step_back: float = 0.8
var _output_dir: String = "artifact_in_map"
# Batch mode: when set, the script iterates the comma-separated lookup
# names, finds the first map containing each via map_data.json scan,
# and captures them all in one Godot session (re-using the tester).
var _artifacts_batch: Array[String] = []
# --scan-only mode: walk maps, find artifact instances, write positions
# to a JSON file, exit. Companion to the API batch wrapper which then
# POSTs to /api/scenes/capture-first-person for each entry.
var _scan_only: bool = false
var _scan_output: String = "user://artifact_positions.json"
var _scan_results: Array = []
# Cap the number of placements recorded/captured per (map, artifact)
# pair. Some artifacts (sphere, triangle, code_display) appear hundreds
# of times in a single map and one representative shot is enough for
# the gallery. -1 = unlimited.
var _max_per_artifact: int = -1


func _initialize() -> void:
	_parse_args()
	_run.call_deferred()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if not (a is String):
			continue
		var s: String = a
		if s.begins_with("--map="):
			_map_name = s.substr("--map=".length())
		elif s.begins_with("--artifact="):
			_artifact_lookup = s.substr("--artifact=".length())
		elif s.begins_with("--step-back="):
			_step_back = float(s.substr("--step-back=".length()))
		elif s.begins_with("--artifacts="):
			# Batch mode: --artifacts=lookup1,lookup2,lookup3
			var raw: String = s.substr("--artifacts=".length())
			for item in raw.split(","):
				var t: String = item.strip_edges()
				if t != "":
					_artifacts_batch.append(t)
		elif s == "--scan-only":
			_scan_only = true
		elif s.begins_with("--scan-output="):
			_scan_output = s.substr("--scan-output=".length())
		elif s.begins_with("--max-per-artifact="):
			_max_per_artifact = int(s.substr("--max-per-artifact=".length()))


func _run() -> void:
	# Boot the tester once — re-used across maps in batch mode.
	var tester_scene := load(DESKTOP_TESTER_SCENE) as PackedScene
	if tester_scene == null:
		push_error("[in_map] desktop_map_tester.tscn not found at " + DESKTOP_TESTER_SCENE)
		quit(1)
		return
	var tester: Node = tester_scene.instantiate()
	tester.set("auto_load_on_ready", false)
	get_root().add_child(tester)
	await create_timer(0.2).timeout

	# Decide what to capture: either explicit --map/--artifact, or batch.
	var plan: Array = []  # Each item: { "map": "Foo", "artifact": "bar" }
	if _artifacts_batch.size() > 0:
		# Build artifact->first_map mapping by scanning all map_data.json.
		print("[in_map] batch mode — scanning maps for %d artifact(s)" % _artifacts_batch.size())
		var artifact_to_maps: Dictionary = _build_artifact_map_index()
		for lookup in _artifacts_batch:
			var maps_with: Array = artifact_to_maps.get(lookup, [])
			if maps_with.is_empty():
				print("[in_map]   '%s' not found in any map — skipping" % lookup)
				continue
			# Deterministic: pick the first map alphabetically.
			maps_with.sort()
			plan.append({"map": maps_with[0], "artifact": lookup})
			print("[in_map]   '%s' -> '%s'" % [lookup, maps_with[0]])
	else:
		plan.append({"map": _map_name, "artifact": _artifact_lookup})

	# Group by map so we only load each map once.
	var map_to_artifacts: Dictionary = {}
	for p in plan:
		var m: String = p["map"]
		if not map_to_artifacts.has(m):
			map_to_artifacts[m] = []
		map_to_artifacts[m].append(p["artifact"])

	# Iterate maps, loading each once and capturing every requested
	# artifact in it.
	var total_captures := 0
	for map_name in map_to_artifacts.keys():
		var artifacts_in_this_map: Array = map_to_artifacts[map_name]
		print("[in_map] === loading map '%s' for %d artifact(s) ===" % [map_name, artifacts_in_this_map.size()])

		# Load the map (re-uses the same tester across iterations).
		if not tester.has_method("load_map"):
			push_error("[in_map] DesktopMapTester missing load_map()")
			break
		tester.call("load_map", map_name)
		await create_timer(5.0).timeout

		# Brutal UI cleanup, once per map load.
		for child_name in ["DesktopMapSwitcherOverlay", "MapLayerEditorOverlay",
						   "ProjectDashboardOverlay", "LabEvolutionEditor",
						   "HelpLabel"]:
			var named: Node = tester.get_node_or_null(child_name)
			if named:
				if named is CanvasLayer:
					(named as CanvasLayer).visible = false
				elif named is Node3D:
					(named as Node3D).visible = false
				elif named is CanvasItem:
					(named as CanvasItem).visible = false
		_hide_all_canvas_pollution(get_root())

		# Disable the desktop player.
		var dp: Node = tester.get_node_or_null("DesktopPlayer")
		if dp:
			if dp is Node3D:
				(dp as Node3D).global_position = Vector3(0, -1000, 0)
				(dp as Node3D).visible = false
			dp.set_process(false)
			dp.set_physics_process(false)
			dp.set_process_input(false)
			dp.set_process_unhandled_input(false)

		# Capture each artifact in this map (or scan only).
		for artifact_lookup in artifacts_in_this_map:
			_artifact_lookup = artifact_lookup  # current target for the lookup helpers
			_map_name = map_name
			var rel := "%s/%s/%s" % [_output_dir, map_name, artifact_lookup]
			if not _scan_only:
				DirAccess.open("user://").make_dir_recursive(rel)

			var placements: Array = _find_artifact_instances()
			if placements.is_empty():
				placements = _find_artifact_placements()
			# Cap placements per (map, artifact) — see _max_per_artifact docs.
			if _max_per_artifact > 0 and placements.size() > _max_per_artifact:
				print("[in_map]   '%s' in '%s' — %d placement(s), capped to %d" % [
					artifact_lookup, map_name, placements.size(), _max_per_artifact])
				placements = placements.slice(0, _max_per_artifact)
			else:
				print("[in_map]   '%s' in '%s' — %d placement(s)" % [artifact_lookup, map_name, placements.size()])

			for i in range(placements.size()):
				var p: Dictionary = placements[i]
				if _scan_only:
					# Just record the position — no rendering.
					_scan_results.append({
						"map": map_name,
						"artifact": artifact_lookup,
						"index": i,
						"label": p.get("label", ""),
						"position": [p["world_pos"].x, p["world_pos"].y, p["world_pos"].z],
					})
					total_captures += 1
				else:
					await _capture_at(p, i, rel)
					total_captures += 1

	if _scan_only:
		# Write the discovered positions to a JSON sidecar the batch
		# wrapper can consume.
		var json: String = JSON.stringify(_scan_results, "\t")
		var f := FileAccess.open(_scan_output, FileAccess.WRITE)
		if f:
			f.store_string(json)
			f.close()
			print("[in_map] scan-only: wrote %d entries to %s" % [_scan_results.size(), _scan_output])
		else:
			push_error("[in_map] failed to write scan output: " + _scan_output)
	print("[in_map] complete — %d total entries across %d map(s)" % [total_captures, map_to_artifacts.size()])
	quit()


# Walk the live scene tree looking for instances of the target artifact.
# Match by script resource path containing "/<lookup>/" or "/<lookup>.gd",
# OR by node name starting with the lookup name. Returns a list of dicts
# with `world_pos`, `node`, and `label` (best-effort personality state).
func _find_artifact_instances() -> Array:
	var hits: Array = []
	_find_artifact_recursive(get_root(), hits)
	# Sort by X so personality-arc maps (left-to-right) come out in order.
	hits.sort_custom(func(a, b): return a["world_pos"].x < b["world_pos"].x)
	return hits


func _find_artifact_recursive(node: Node, out: Array) -> void:
	if node == null:
		return
	var script: Resource = node.get_script() as Resource
	var script_path: String = ""
	if script != null:
		script_path = (script.resource_path as String).to_lower()

	var matched := false
	var lookup_lower: String = _artifact_lookup.to_lower()
	# Script path heuristic — works for procedurally-instanced artifacts.
	if script_path.contains("/" + lookup_lower + "/") or \
			script_path.contains("/" + lookup_lower + ".gd") or \
			script_path.ends_with(lookup_lower + ".gd"):
		matched = true
	# Node name fallback.
	if not matched and node.name.to_lower().contains(lookup_lower):
		matched = true

	if matched and node is Node3D:
		var n3 := node as Node3D
		var pos: Vector3 = n3.global_position
		var label: String = _read_personality_label(n3)
		out.append({
			"world_pos": pos,
			"node": n3,
			"label": label,
		})
		# Don't recurse into the matched artifact — we want each instance once.
		return

	for child in node.get_children():
		_find_artifact_recursive(child, out)


# Best-effort personality-state read for a catalyst_foe instance — looks
# at common state-bearing fields. Returns empty string if no obvious
# state property is present.
func _read_personality_label(n: Node3D) -> String:
	# catalyst_foe.gd uses _personality (underscore-prefixed, since the
	# state arc is governed by HazardCreatureBase). Other artifacts may
	# expose state under different names.
	for prop_name in ["_personality", "personality", "personality_state",
					  "current_state", "initial_state", "state"]:
		if prop_name in n:
			var v = n.get(prop_name)
			if v is String and v != "":
				return v
			elif typeof(v) == TYPE_INT:
				return "state_%d" % v
	return ""


# Scan map_data.json's interactables layer for cells whose token starts
# with the artifact lookup_name (handles `#param:value` and `:rot:y`
# decoration suffixes). Returns one dict per placement with grid coords,
# parsed parameter string, and computed world position.
func _find_artifact_placements() -> Array:
	var path := "res://commons/maps/%s/map_data.json" % _map_name
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[in_map] Cannot open " + path)
		return []
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if not (data is Dictionary):
		return []

	var layers = data.get("layers", {})
	var interactables = layers.get("interactables", [])
	var settings = data.get("settings", {})
	var cube_size: float = float(settings.get("cube_size", 1.0))
	var gutter: float = float(settings.get("gutter", 0.0))
	var pitch: float = cube_size + gutter

	var placements: Array = []
	# Flat-map case: interactables is [z][x].
	# Multi-height case: interactables is [y][z][x]. We treat the first
	# axis as height if its first element is itself an Array of Arrays.
	var is_3d := false
	if interactables.size() > 0 and interactables[0] is Array:
		var first_row = interactables[0]
		if first_row.size() > 0 and first_row[0] is Array:
			is_3d = true

	if is_3d:
		for y in range(interactables.size()):
			var slab = interactables[y]
			if not (slab is Array):
				continue
			for z in range(slab.size()):
				var row = slab[z]
				if not (row is Array):
					continue
				for x in range(row.size()):
					_maybe_add_placement(row[x], x, y, z, pitch, placements)
	else:
		for z in range(interactables.size()):
			var row = interactables[z]
			if not (row is Array):
				continue
			for x in range(row.size()):
				_maybe_add_placement(row[x], x, 0, z, pitch, placements)

	return placements


func _maybe_add_placement(
	raw_cell, x: int, y: int, z: int, pitch: float, out: Array
) -> void:
	if not (raw_cell is String):
		return
	var raw: String = (raw_cell as String).strip_edges()
	if raw == "" or raw == " ":
		return
	# Token format: <lookup>[#param:value][:rotation:y_offset]
	# Split first on `#` then on `:` to peel the lookup name.
	var head: String = raw.split("#")[0].split(":")[0].strip_edges()
	if head != _artifact_lookup:
		return
	# Extract a short label — for catalyst_foe `#initial_state:foe`
	# that's "foe". For unparameterised placements it's "".
	var label := ""
	if "#" in raw:
		var after_hash: String = raw.split("#", false, 1)[1]
		# After `#` we have `param:value` or `param:value:rot:y`
		var pcv: PackedStringArray = after_hash.split(":")
		if pcv.size() >= 2:
			label = pcv[1].strip_edges()

	out.append({
		"grid_x": x,
		"grid_y": y,
		"grid_z": z,
		"label": label,
		"raw": raw,
		"world_pos": Vector3(
			float(x) * pitch + pitch * 0.5,
			float(y) * pitch + pitch * 0.5,
			float(z) * pitch + pitch * 0.5),
	})


func _capture_at(placement: Dictionary, index: int, rel_out_dir: String) -> void:
	var artifact_pos: Vector3 = placement["world_pos"]
	var label: String = placement["label"]

	# Approach from -Z so the camera faces +Z (toward the artifact).
	# Step back is the lateral distance; eye height stays at the same
	# elevation as the artifact center so the look is roughly level, not
	# pitched-down. This makes small artifacts read centered in frame
	# (steep down-looks shrink them to a corner of the floor).
	var approach_dir := Vector3(0, 0, -1)
	var cam_pos: Vector3 = artifact_pos + approach_dir * _step_back
	# Match the artifact's eye height — slightly above its center so
	# the floor is still visible underneath but we're not looking down
	# from way up. Most artifacts have y_center ~= 0.5 (a 1 m cube on
	# the floor); 1.0 m eye gives a small downward look.
	cam_pos.y = artifact_pos.y + 0.6

	# Build a root we can drop our camera + hands under.
	var fpv_root := Node3D.new()
	fpv_root.name = "FPVRig_%d" % index
	get_root().add_child(fpv_root)

	# FPV camera looking at the artifact's center (not at the floor).
	var cam := Camera3D.new()
	cam.fov = 70.0
	cam.position = cam_pos
	cam.look_at(artifact_pos, Vector3.UP)
	cam.current = true
	fpv_root.add_child(cam)

	# Hands at chest level, slightly forward — embodied scale reference.
	# Use the camera's HORIZONTAL forward (zero out Y) so the hands sit
	# at a consistent chest level regardless of how steeply the camera
	# tilts at the artifact. Earlier the hands followed the tilted
	# forward and ended up below the frame.
	var forward_full: Vector3 = (artifact_pos - cam_pos).normalized()
	var forward_flat: Vector3 = Vector3(forward_full.x, 0, forward_full.z).normalized()
	var right: Vector3 = forward_flat.cross(Vector3.UP).normalized()
	# Hands ~chest height, forward a hand-length, splayed slightly.
	var hand_y: float = cam_pos.y - 0.32
	var hand_fwd: float = 0.45
	var hand_lateral: float = 0.20
	var left_hand_pos: Vector3 = cam_pos + forward_flat * hand_fwd + right * -hand_lateral
	left_hand_pos.y = hand_y
	var right_hand_pos: Vector3 = cam_pos + forward_flat * hand_fwd + right * +hand_lateral
	right_hand_pos.y = hand_y

	var aim := Vector3(forward_flat.x, -0.20, forward_flat.z).normalized()
	var basis := VRCaptureRig.hand_basis(aim, 1.0, true)
	VRCaptureRig.pose_hand(fpv_root, VRCaptureRig.LEFT_HAND_GLTF,
		left_hand_pos, basis, "Default pose", true)
	VRCaptureRig.pose_hand(fpv_root, VRCaptureRig.RIGHT_HAND_GLTF,
		right_hand_pos, basis, "Default pose", false)

	# Settle.
	for _i in range(20):
		await process_frame

	# Freeze _process before the final hide pass — some HUDs / artifact
	# UIs toggle visibility back on every frame. With time_scale=0, our
	# hide sticks until snap.
	var prev_scale: float = Engine.time_scale
	Engine.time_scale = 0.0
	_hide_all_canvas_pollution(get_root())
	_disable_grid_wireframes(get_root())
	await process_frame
	await process_frame

	var vp: Viewport = fpv_root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	Engine.time_scale = prev_scale
	if img == null:
		print("[in_map] FAIL %d (%s)" % [index, label])
		fpv_root.queue_free()
		return

	var filename := ""
	if label != "":
		filename = "%02d_%s.png" % [index, label]
	else:
		filename = "%02d.png" % index
	var out_path := "user://%s/%s" % [rel_out_dir, filename]
	img.save_png(out_path)
	print("[in_map] saved %s" % filename)

	fpv_root.queue_free()


# ── Map registry scanning (for batch mode) ──────────────────────────

const MAPS_DIR := "res://commons/maps/"

# Walk every commons/maps/<MapName>/map_data.json and return a mapping
# from artifact lookup_name to a list of map names containing it. Used
# in batch mode to pick the first map for each artifact.
func _build_artifact_map_index() -> Dictionary:
	var index: Dictionary = {}
	var dir := DirAccess.open(MAPS_DIR)
	if dir == null:
		push_error("[in_map] Cannot open maps dir: " + MAPS_DIR)
		return index
	dir.list_dir_begin()
	var subdir: String = dir.get_next()
	var map_count := 0
	while subdir != "":
		if dir.current_is_dir() and subdir != "." and subdir != "..":
			var path := MAPS_DIR + subdir + "/map_data.json"
			if ResourceLoader.exists(path) or FileAccess.file_exists(path):
				var artifacts: Array = _artifacts_in_map_file(path)
				for a in artifacts:
					var key: String = a
					if not index.has(key):
						index[key] = []
					if not (subdir in index[key]):
						(index[key] as Array).append(subdir)
				map_count += 1
		subdir = dir.get_next()
	print("[in_map] scanned %d maps, indexed %d unique artifacts" % [map_count, index.size()])
	return index


func _artifacts_in_map_file(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if not (data is Dictionary):
		return []
	var layers = data.get("layers", {})
	var interactables = layers.get("interactables", [])
	var lookups: Array = []
	_scan_interactables_recursive(interactables, lookups)
	return lookups


func _scan_interactables_recursive(layer, out: Array) -> void:
	if layer is Array:
		for item in layer:
			_scan_interactables_recursive(item, out)
	elif layer is String:
		var s: String = (layer as String).strip_edges()
		if s != "" and s != " ":
			# Token format: <lookup>[#param:value][:rotation:y_offset]
			var head: String = s.split("#")[0].split(":")[0].strip_edges()
			if head != "" and not (head in out):
				out.append(head)


# Zero out the GridStructureComponent's orange wireframe overlay — looks
# like editor-debug noise in screenshots. Pattern from capture_in_player_pos.gd.
func _disable_grid_wireframes(root: Node) -> void:
	var stack: Array = [root]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null:
			continue
		for c in n.get_children():
			stack.push_back(c)
		if not (n is MultiMeshInstance3D):
			continue
		var mmi := n as MultiMeshInstance3D
		var materials: Array = []
		if mmi.material_override:
			materials.append(mmi.material_override)
		if mmi.multimesh and mmi.multimesh.mesh:
			var msh: Mesh = mmi.multimesh.mesh
			for i in range(msh.get_surface_count()):
				var sm = msh.surface_get_material(i)
				if sm:
					materials.append(sm)
		for mat in materials:
			if not (mat is ShaderMaterial):
				continue
			var sm := mat as ShaderMaterial
			sm.set_shader_parameter("wireframeColor", Color(0, 0, 0, 0))
			sm.set_shader_parameter("wireframeOpacity", 0.0)
			sm.set_shader_parameter("width", 0.0)
			sm.set_shader_parameter("emission_strength", 0.0)
			sm.set_shader_parameter("modelOpacity", 1.0)


# Hide every CanvasLayer + Control in the tree — same brutal pass as
# capture_in_player_pos.gd. Dev overlays, slider HUDs, debug labels —
# all gone so the snapshot is pure 3D.
func _hide_all_canvas_pollution(root: Node) -> void:
	var stack: Array = [root]
	var hidden_count := 0
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null:
			continue
		for c in n.get_children():
			stack.push_back(c)
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
			hidden_count += 1
		elif n is Control:
			(n as Control).visible = false
			hidden_count += 1
	if hidden_count > 0:
		print("[in_map] hid %d canvas nodes" % hidden_count)
