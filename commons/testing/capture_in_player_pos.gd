extends SceneTree

## In-game capture via the real DesktopMapTester scene + a dedicated
## CaptureRig (NOT the desktop player).
##
## Loads commons/scenes/desktop_map_tester.tscn for its full GridSystem +
## environment + lighting + biome pipeline. Then disables the desktop
## player entirely and parents a clean CaptureRig (Camera3D + soft fill
## lights, no collision, no HUD, no polling) which we aim per shot.
##
## This is closer to "what the player actually sees in-game" than the
## bare-grid fallback in capture_in_map.gd — biomes, ecosystem critters,
## sky, fog, the real worldfloor shader all render — but uses a
## purpose-built camera rig instead of the player rig, so the shots
## stay clean (no crosshair, no capsule, no interaction pointer).
##
## Smart-framing mode (NEW):
##   Set "auto_frame": true and provide "anchor": [cellX, cellZ]. The
##   script measures the artifact's world-space AABB by walking
##   VisualInstance3D children near that cell, then derives camera
##   distance per shot from FOV + AABB radius * padding. Each shot's
##   "camera.direction" is treated as a direction hint (normalized);
##   the recipe's old rel_pos values pass through unchanged.
##
## Config JSON shape (single shot):
##   {
##     "map":      "MANN_Gallery_Pearl",
##     "camera":   { "position": [10, 1.7, 5], "look_at": [8, 1.0, 8], "fov": 60 },
##     "wait":     5.0
##   }
##
## Config JSON shape (batch — multiple shots in one map, one Godot run):
##   {
##     "map":   "MANN_Gallery_Pearl",
##     "wait":  5.0,
##     "shots": [
##       { "name": "front", "out": "user://research_loop/x_front.png",
##         "camera": { "position": [...], "look_at": [...], "fov": 60 } },
##       ...
##     ]
##   }

var _config_path: String = ""
var _out_path: String = "user://in_player_capture.png"
var _wait := 5.0

func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var s := String(raw).strip_edges()
		if s.begins_with("--config="): _config_path = s.substr(9)
		elif s.begins_with("--out="):    _out_path = s.substr(6)
		elif s.begins_with("--wait="):   _wait = float(s.substr(7))
	call_deferred("_run")


func _run() -> void:
	if _config_path.is_empty():
		push_error("--config required"); quit(1); return
	var f := FileAccess.open(_config_path, FileAccess.READ)
	if f == null:
		push_error("config not found: %s" % _config_path); quit(1); return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_error("bad json"); quit(1); return
	var cfg = json.data
	if not (cfg is Dictionary):
		push_error("config not dict"); quit(1); return

	var map_name: String = String(cfg.get("map", "Study_Room"))
	var wait_total: float = float(cfg.get("wait", _wait))
	var auto_frame: bool = bool(cfg.get("auto_frame", false))
	var anchor: Array = cfg.get("anchor", [8, 8])
	var anchor_cell := Vector2i(int(anchor[0]) if anchor.size() > 0 else 8,
								int(anchor[1]) if anchor.size() > 1 else 8)
	# Multi-shot batch mode: list of shots in same map.
	var shots_cfg: Array = cfg.get("shots", [])
	var single_shot := shots_cfg.is_empty()
	# Build a unified shot list for the loop below.
	var shot_list: Array = []
	if single_shot:
		shot_list.append({
			"name": "single",
			"out": _out_path,
			"camera": cfg.get("camera", {}),
		})
	else:
		shot_list = shots_cfg

	# Instantiate the real desktop tester — gives us actual GridSystem
	# build pipeline, environment, lighting.
	var tester_scene := load("res://commons/scenes/desktop_map_tester.tscn") as PackedScene
	if tester_scene == null:
		push_error("desktop_map_tester.tscn not found"); quit(1); return
	var tester = tester_scene.instantiate()
	# Stop auto-load — we want to load our specific map, not start_sequence.
	tester.set("auto_load_on_ready", false)
	get_root().add_child(tester)

	# Let _ready settle.
	await create_timer(0.2).timeout

	# Drive the loader directly.
	if tester.has_method("load_map"):
		tester.load_map(map_name)
	else:
		push_error("DesktopMapTester missing load_map()"); quit(1); return

	# Wait for the grid to build artifacts, biome, ecology.
	var t := 0.0
	while t < wait_total:
		await create_timer(0.05).timeout
		t += 0.05

	# Hide dev overlays + help label so the snapshot is clean.
	for child_name in ["DesktopMapSwitcherOverlay", "MapLayerEditorOverlay",
					   "ProjectDashboardOverlay", "LabEvolutionEditor",
					   "HelpLabel"]:
		var n = tester.get_node_or_null(child_name)
		if n:
			if n is CanvasLayer:
				(n as CanvasLayer).visible = false
			elif n is Node3D:
				(n as Node3D).visible = false
			elif n is CanvasItem:
				(n as CanvasItem).visible = false

	# Aggressive: hide ALL CanvasLayers and root-level CanvasItems
	# anywhere in the tree. Many artifacts spawn HUD panels (FFT controls,
	# slider labels, etc.) that pollute the snapshot. We want pure 3D.
	_hide_all_canvas_pollution(get_root())

	# Disable GridStructureComponent's wireframe overlay — the orange grid
	# edges on every cube look like editor-debug noise, not gameplay.
	if not bool(cfg.get("show_grid_wireframes", false)):
		_disable_grid_wireframes(get_root())

	# Disable the desktop player entirely — we don't want its camera,
	# collision, polling, or HUD active during capture.
	var dp := tester.get_node_or_null("DesktopPlayer")
	if dp:
		# Move it far below the world so its components don't interact
		# with anything visible, and hide it.
		if dp is Node3D:
			(dp as Node3D).global_position = Vector3(0, -1000, 0)
			(dp as Node3D).visible = false
		# Stop _process / _physics_process polling.
		dp.set_process(false)
		dp.set_physics_process(false)
		dp.set_process_input(false)
		dp.set_process_unhandled_input(false)

	# Spawn the dedicated capture rig.
	var rig_scene := load("res://commons/testing/capture_rig.tscn") as PackedScene
	if rig_scene == null:
		push_error("capture_rig.tscn missing"); quit(1); return
	var rig := rig_scene.instantiate()
	get_root().add_child(rig)

	# Smart framing: measure the artifact's actual AABB at the anchor cell.
	# If we can't find one (no VisualInstance3D nearby), we fall back to
	# absolute camera positions per shot.
	var artifact_aabb := AABB()
	var have_aabb := false
	if auto_frame:
		artifact_aabb = _aabb_at_cell(anchor_cell.x, anchor_cell.y, 1.6)
		have_aabb = artifact_aabb.size.length_squared() > 0.0001
		print("auto_frame: cell=(%d,%d) aabb_center=%s size=%s found=%s"
			% [anchor_cell.x, anchor_cell.y,
			   str(artifact_aabb.get_center()), str(artifact_aabb.size), str(have_aabb)])

	# Optional: callers can request only-map-lighting (no fill).
	var disable_fill: bool = bool(cfg.get("disable_fill_lights", false))
	if disable_fill and rig.has_method("disable_fill_lights"):
		rig.disable_fill_lights()
	if rig.has_method("set_clean_render"):
		rig.set_clean_render()

	# Loop over shots — one window, one autoload, N snapshots.
	for sh in shot_list:
		var sh_cam = sh.get("camera", {})
		var sh_fov: float = float(sh_cam.get("fov", 60.0))
		var sh_out: String = String(sh.get("out", _out_path))

		var sh_pos: Vector3
		var sh_look: Vector3
		if have_aabb and sh_cam.has("direction"):
			# Smart frame: distance derived from AABB + fov.
			var dir := _to_vec3(sh_cam.get("direction", [4, 2, 4]))
			if dir.length_squared() < 0.0001:
				dir = Vector3(0, 4, 4)
			dir = dir.normalized()
			var padding: float = float(sh_cam.get("padding", 1.5))
			var min_dist: float = float(sh_cam.get("min_distance", 1.5))
			var fov_rad: float = deg_to_rad(sh_fov) * 0.5
			# Use the largest single-axis half-extent (tight-fitting sphere
			# of the AABB), not the diagonal — diagonal pushes the camera
			# unnecessarily far for tall/thin artifacts.
			var max_half: float = max(artifact_aabb.size.x,
									  max(artifact_aabb.size.y, artifact_aabb.size.z)) * 0.5
			var distance: float = max(min_dist, max_half / max(0.05, tan(fov_rad)) * padding)
			var center: Vector3 = artifact_aabb.get_center()
			sh_pos = center + dir * distance
			sh_look = center
			print("shot '%s': dir=%s dist=%.2f → pos=%s"
				% [sh.get("name","?"), str(dir), distance, str(sh_pos)])
		else:
			sh_pos = _to_vec3(sh_cam.get("position", [8, 1.7, 8]))
			sh_look = _to_vec3(sh_cam.get("look_at", [8, 1.0, 8]))

		if rig.has_method("aim"):
			rig.aim(sh_pos, sh_look, sh_fov)
		if rig.has_method("activate"):
			rig.activate()

		# Let the camera settle and renderer flush.
		await create_timer(0.3).timeout

		# Freeze _process before final hide pass — some artifacts toggle
		# visibility back on every frame (fourier_transform UI, oscillators).
		# With time_scale=0, _process is paused; our hide sticks until snap.
		var prev_scale := Engine.time_scale
		Engine.time_scale = 0.0
		_hide_all_canvas_pollution(get_root())
		_disable_grid_wireframes(get_root())
		# Two yields with frozen time give the renderer a chance to flush
		# the now-hidden state without _process firing.
		await process_frame
		await process_frame

		var img := get_root().get_texture().get_image()
		# Restore time scale before next shot so artifacts can settle.
		Engine.time_scale = prev_scale
		if img == null:
			push_error("no image for shot: %s" % sh.get("name", "?"))
			continue
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(sh_out.get_base_dir()))
		img.save_png(sh_out)
		print("capture_rig: ", sh_out)

	quit(0)


func _to_vec3(a) -> Vector3:
	if a is Array and a.size() >= 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


## Walk the scene tree and zero out the GridStructureComponent's
## wireframe overlay — the orange edge-lines on every grid cube.
## Looks like editor-debug noise in screenshots; in-game it's stylistic
## but unhelpful for "what is this artifact" research captures.
func _disable_grid_wireframes(root: Node) -> void:
	var stack: Array = [root]
	var zeroed := 0
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null: continue
		for c in n.get_children():
			stack.push_back(c)
		if not (n is MultiMeshInstance3D):
			continue
		var mmi := n as MultiMeshInstance3D
		# Try material_override first, then mesh-surface materials.
		var materials: Array = []
		if mmi.material_override:
			materials.append(mmi.material_override)
		if mmi.multimesh and mmi.multimesh.mesh:
			var msh = mmi.multimesh.mesh
			for i in range(msh.get_surface_count()):
				var sm = msh.surface_get_material(i)
				if sm: materials.append(sm)
		for mat in materials:
			if not (mat is ShaderMaterial):
				continue
			var sm := mat as ShaderMaterial
			# Try every name we've seen across the Grid shader family.
			sm.set_shader_parameter("wireframeColor", Color(0, 0, 0, 0))
			sm.set_shader_parameter("wireframeOpacity", 0.0)
			sm.set_shader_parameter("width", 0.0)
			sm.set_shader_parameter("emission_strength", 0.0)
			sm.set_shader_parameter("modelOpacity", 1.0)
			zeroed += 1
	if zeroed > 0:
		print("zeroed %d grid wireframes" % zeroed)


## Walk the tree from `root` and hide every CanvasItem-rooted overlay
## that would pollute a clean 3D snapshot. Brute force: anything 2D
## visible at the viewport level goes away.
##
## Touches: CanvasLayer, Control, Sprite2D-and-friends. Skips Label3D
## and other Node3D-derived "world" UI (those are part of the scene).
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
		print("hid %d canvas nodes" % hidden_count)


## Walk the scene tree under root, collect VisualInstance3D nodes whose
## center lies within `radius` (horizontal cells) of (cellX, cellZ).
## Returns the union AABB. Empty AABB if nothing found.
##
## We exclude the floor/ground (huge plane meshes) by capping per-instance
## footprint — anything wider than `max_footprint` is presumed to be the
## map floor or a wall, not the artifact itself.
func _aabb_at_cell(cellX: int, cellZ: int, radius: float = 1.6,
				   max_footprint: float = 8.0) -> AABB:
	var center2d := Vector2(float(cellX), float(cellZ))
	var combined := AABB()
	var has_any := false
	var stack: Array = [get_root()]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null:
			continue
		for c in n.get_children():
			stack.push_back(c)
		if not (n is VisualInstance3D):
			continue
		var vi := n as VisualInstance3D
		var local := vi.get_aabb()
		if local.size.length_squared() < 0.0001:
			continue
		var world: AABB = vi.global_transform * local
		# Skip giant planes (floor/walls) and empties.
		var footprint: float = Vector2(world.size.x, world.size.z).length()
		if footprint > max_footprint:
			continue
		# Within horizontal radius of the target cell?
		var wc: Vector3 = world.get_center()
		var c2 := Vector2(wc.x, wc.z)
		if c2.distance_to(center2d) > radius:
			continue
		if not has_any:
			combined = world
			has_any = true
		else:
			combined = combined.merge(world)
	if not has_any:
		return AABB()
	return combined
