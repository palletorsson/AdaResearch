## capture_config_sweep.gd — the DNA-sweep capturer: ONE Godot boot renders
## every parameter variant of one artifact, no code edits between variants.
##
## This is the props-dna-gallery loop generalised: vary an artifact by DATA
## (its @export knobs), batch-render the whole matrix, compare on a sheet.
## Each variant's params are set BEFORE add_child, so _ready() builds the body
## with them — no apply_grid_config rebuild needed, and one boot does them all.
##
## Reads a sweep spec JSON:
##   { "scene": "res://.../x.tscn",
##     "out_dir": "res://ada_run/sweep",
##     "variants": [ { "label": "rams_p0", "params": {"finish":"rams","plinth_height":0.0} }, ... ] }
##
## Run (via the watchdog, expecting <out_dir>/_done.txt):
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_config_sweep.gd -- --spec=<abs/res path>

extends SceneTree

## TEXT WANTS A BODY HERE TOO. GridInteractablesComponent frames every hanging label at
## spawn (lines 1004 and 1197) — billboard off, a readout bezel and panel behind the
## glyphs — because "all hanging Label3D must become 2D-in-3D boards or plates INTEGRATED
## in the wrapper or artifact", and per-file migration across 945 sites was rejected as
## the wrong shape in favour of standardising the MEETING POINT.
##
## This capturer was not one of those meeting points, so every DNA gallery published so
## far showed billboarded text floating over its own artifact — text the player never
## sees, because in a map the framer has already run. A sheet that disagrees with the
## game about what the artifact looks like is not evidence about the artifact.
const LabelFramer := preload("res://commons/grid/LabelFramer.gd")

const RES := 760
const FOV := 34.0
const YAW := 0.62
const PITCH := -0.26
const PAD := 1.9
const SETTLE := 1.1

var _spec_path: String = ""
## Scales the framing distance. 1.0 = fit the whole artifact (the old fixed
## behaviour). Below 1.0 moves the camera in, for artifacts whose axis lives in
## a detail rather than in the silhouette. Read from the spec's "framing" key,
## which cabinet_sweep fills from the registry's dna.framing.
var _framing: float = 1.0


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if a.begins_with("--spec="):
			_spec_path = a.substr(7)
	_run()


func _run() -> void:
	var spec: Dictionary = _load_json(_spec_path)
	var framing_hint: float = float(spec.get("framing", 1.0))
	if framing_hint > 0.05 and framing_hint < 20.0:
		_framing = framing_hint
	var scene_path: String = str(spec.get("scene", ""))
	var out_dir: String = str(spec.get("out_dir", "res://ada_run/sweep"))
	var variants: Array = spec.get("variants", [])
	if not ResourceLoader.exists(scene_path):
		push_error("capture_config_sweep: scene missing: " + scene_path)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)

	var vp := SubViewport.new()
	vp.size = Vector2i(RES, RES)
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	_stage(vp)
	var cam: Camera3D = vp.get_node("Cam")

	var packed_cache: Dictionary = {}   # scene path -> PackedScene (multi-scene sweeps)
	var shot := 0
	for v in variants:
		var variant: Dictionary = v
		var label: String = str(variant.get("label", "v%d" % shot))
		var params: Dictionary = variant.get("params", {})
		# a variant may name its own scene (cross-member sweeps); else the top one
		var vscene: String = str(variant.get("scene", scene_path))
		if not packed_cache.has(vscene):
			if not ResourceLoader.exists(vscene):
				print("MISS ", label, " (", vscene, ")")
				continue
			packed_cache[vscene] = load(vscene)
		var packed: PackedScene = packed_cache[vscene]

		var inst: Node = packed.instantiate()

		# Stamp the lookup name BEFORE _ready(), the same contract the grid and
		# capture_multi_angle honour. Whole families share one scene here and
		# pick their variant from this meta — the six pattern_tile members all
		# point at pattern_tile_puzzle.tscn, and so do specimen_plinth, dome_kit
		# and the bricolage affordances. Without it every member of a family
		# rendered as the family default, so their sweeps measured a difference
		# of 0.04% and looked like axes that do nothing. They were being asked
		# the wrong question.
		var lookup: String = str(variant.get("artifact", ""))
		if lookup != "":
			inst.set_meta("artifact_lookup_name", lookup)

		# Set every swept @export BEFORE add_child, so _ready() builds with it.
		#
		# The property is not always on the root. Plenty of scenes wrap their
		# logic one level down — commons/interface/line.tscn is a bare Node3D
		# whose script lives on a `lineContainer` child, and the script cannot
		# simply move up because it must be the grab spheres' parent. Setting
		# only on the root silently did nothing there: the sweep rendered eight
		# identical tiles and the axis looked inert when it was merely unreachable.
		for key in params.keys():
			var val: Variant = params[key]
			var holder: Node = _holder_of(inst, String(key))
			if holder != null:
				holder.set(key, val)
			else:
				push_warning("capture_config_sweep: no node in %s exposes '%s' — "
					+ "the value was not applied and this tile is not a variant."
					% [inst.name, key])
		vp.add_child(inst)
		# Suppress demo chrome exactly as the grid does at spawn. Many algorithms/
		# scenes were authored as standalone demos and build a screen-space
		# CanvasLayer UI and/or their own Camera3D; GridInteractablesComponent hides
		# both (_suppress_embedded_chrome) because screen-space UI is never correct in
		# VR and a stray camera steals focus.
		#
		# This capturer was not doing it, and the cost was silent: mst_visualization's
		# setup_ui() builds a 500 x 900 Panel, which filled two thirds of every tile
		# and squeezed the graph itself down to a few pixels. Its axis then measured
		# 1.18% frame / 1.47% focus and was reported INERT — a verdict about a debug
		# panel the player never sees, not about the artifact.
		_suppress_chrome(inst)
		# Frame the labels exactly as the grid does at spawn, so the tile shows the
		# 2D-in-3D plate the player meets and not the hanging billboard.
		LabelFramer.frame_labels(inst)
		await create_timer(SETTLE).timeout
		# Again after the settle: artifacts that build in a deferred pass (or rebuild on
		# a config key) create their labels after the first call, and an unframed label
		# added later would otherwise survive into the capture.
		LabelFramer.frame_labels(inst)
		# AND THE CHROME AGAIN, for exactly the same reason. This was called once, before
		# the settle, and the omission bought one artifact a fake score:
		# pca_visualization builds its debug CanvasLayer late, so the panel was suppressed
		# on the four tiles that rebuild and NOT on the default one. A 450 x 800 dark
		# rectangle in one tile of five made the axis measure 11.6% while the four clouds
		# it was supposed to be comparing were mutually identical at ~1%. The verdict was
		# about a debug panel the player never sees, and it read as a passing axis.
		_suppress_chrome(inst)

		# RESCUE: some artifacts deliberately build NOTHING in _ready(). library_rack
		# says so in its own comment — it has nothing to build until a `collection`
		# key arrives, and standing an empty 6x4 grid of blank cubes in every room
		# would be worse than waiting. The sweep's contract is "set the exports, let
		# _ready build", so those artifacts rendered five variants of an empty scene
		# and scored 0.00%: a dead axis by measurement, across 70 placements, when
		# the body had simply never been asked for. If nothing measurable exists,
		# hand the params to apply_grid_config and settle again. Artifacts that
		# already built have a real AABB and never reach this.
		if _subtree_aabb(inst).size.length() < 0.001 and inst.has_method("apply_grid_config"):
			inst.call("apply_grid_config", params)
			await create_timer(SETTLE).timeout
			LabelFramer.frame_labels(inst)
			_suppress_chrome(inst)

		var aabb := _subtree_aabb(inst)
		var c := aabb.get_center()
		var radius: float = maxf(aabb.size.length() * 0.5, 0.2)
		# PAD frames the WHOLE artifact, which is wrong when the axis lives in a
		# small part of a large object: line_interface's readout axis rendered at
		# ~30 px in a 700 px frame, so four different values were indistinguishable
		# and the sheet could not be told apart from an inert axis. --framing
		# scales that distance (below 1.0 moves in), set per artifact from the
		# registry's dna.framing so the subject of the axis is what gets framed.
		var dist: float = radius / tan(deg_to_rad(FOV * 0.5)) * PAD * _framing
		var dir := Vector3(sin(YAW) * cos(PITCH), -sin(PITCH), cos(YAW) * cos(PITCH))
		cam.global_position = c + dir * dist
		cam.look_at(c, Vector3.UP)

		await process_frame
		await process_frame
		await create_timer(0.1).timeout
		vp.get_texture().get_image().save_png("%s/%s.png" % [out_dir, label])
		shot += 1
		print("SWEPT ", label)
		inst.queue_free()
		await process_frame

	var f := FileAccess.open(out_dir + "/_done.txt", FileAccess.WRITE)
	f.store_string("swept %d variants" % shot)
	f.close()
	print("config sweep: %d variants -> %s" % [shot, out_dir])
	quit(0)


## Mirror of GridInteractablesComponent._suppress_embedded_chrome (line 1010): hide
## any screen-space CanvasLayer and stand down any Camera3D the artifact brought with
## it, so the tile shows the artifact and not its debug UI.
func _suppress_chrome(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for child in node.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
		elif child is Camera3D:
			(child as Camera3D).current = false
		_suppress_chrome(child)


func _stage(vp: SubViewport) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.055, 0.070)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.rotation_degrees = Vector3(-42, -35, 0)
	key.shadow_enabled = true
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.rotation_degrees = Vector3(-20, 130, 0)
	vp.add_child(fill)
	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.fov = FOV
	vp.add_child(cam)


## The node that actually owns a swept property — the root if it has it, else
## the first descendant that does. Breadth-first so the shallowest owner wins.
func _holder_of(node: Node, key: String) -> Node:
	if key in node:
		return node
	var queue: Array[Node] = [node]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		for c in n.get_children():
			if key in c:
				return c
			queue.append(c)
	return null


func _subtree_aabb(root_node: Node) -> AABB:
	var acc := AABB()
	var have := false
	var stack: Array = [root_node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var wab: AABB = mi.global_transform * mi.get_aabb()
			acc = wab if not have else acc.merge(wab)
			have = true
		for ch in n.get_children():
			stack.append(ch)
	return acc if have else AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}
