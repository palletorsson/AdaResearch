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
	# dna.host from the registry, for artifacts that only exist as an operation on
	# a host map's grid. Empty means the artifact stands alone, as before.
	var host_spec: Dictionary = spec.get("host", {})
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
	# One host for the whole sweep: the artifact is re-parented under it each
	# variant, so every value acts on an identical grid and the only difference
	# between frames is what the artifact did to it.
	var host: Node3D = _build_host(vp, host_spec) if not host_spec.is_empty() else null

	# ── The camera must not move between variants. ───────────────────────────────
	#
	# Framing each variant to its OWN AABB looks obviously right and is the single
	# worst measurement bug this rig has had. Most axes ADD or REMOVE geometry, so
	# a value that builds less is photographed from closer, and two frames taken
	# from different distances are not comparable pixel to pixel at all.
	#
	# example_1_3's construction axis is the case that exposed it. `chain` and
	# `parallelogram` build genuinely different figures and measured 0.045% apart —
	# indistinguishable — while `flip`, which is their union, measured 12.8% from
	# both. The tell was the subject share: 92.9% for chain and parallelogram
	# against 29.0% for flip at identical framing. They were not similar pictures.
	# They were the same picture at three magnifications, and every "faint axis"
	# verdict on an add-geometry axis in this corpus is suspect for the same reason.
	#
	# So: measure every variant first, union the boxes, and place the camera ONCE.
	# The pre-pass uses a shorter settle than the render pass — 0.35 s is the
	# documented minimum for an artifact's geometry to exist (probe_aabb_hogs), and
	# the full SETTLE is only needed for the picture to be clean, not for the box
	# to be right.
	var union: AABB = AABB()
	var have_union: bool = false
	if bool(spec.get("fixed_camera", true)) and variants.size() > 1:
		for v in variants:
			var pv: Dictionary = v
			var pscene: String = str(pv.get("scene", scene_path))
			if not ResourceLoader.exists(pscene):
				continue
			if not packed_cache.has(pscene):
				packed_cache[pscene] = load(pscene)
			var probe: Node = (packed_cache[pscene] as PackedScene).instantiate()
			var plookup: String = str(pv.get("artifact", ""))
			if plookup != "":
				probe.set_meta("artifact_lookup_name", plookup)
			var pparams: Dictionary = pv.get("params", {})
			for key in pparams.keys():
				var ph: Node = _holder_of(probe, String(key))
				if ph != null:
					ph.set(key, pparams[key])
			(host if host != null else vp).add_child(probe)
			_suppress_chrome(probe)
			await create_timer(0.35).timeout
			if _subtree_aabb(probe).size.length() < 0.001 and probe.has_method("apply_grid_config"):
				probe.call("apply_grid_config", pparams)
				await create_timer(0.35).timeout
			LabelFramer.frame_labels(probe)
			var box: AABB = _subtree_aabb(host) if host != null else _subtree_aabb(probe)
			if box.size.length() > 0.001:
				union = box if not have_union else union.merge(box)
				have_union = true
			probe.queue_free()
			await process_frame
		if have_union:
			print("fixed camera: union AABB size ", union.size, " centre ", union.get_center())

	# Again, now that the autoloads have certainly readied. See _stage.
	_stand_down_world_bridges()

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
		(host if host != null else vp).add_child(inst)
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

		# The union box when we have one, this variant's own only as a fallback for
		# single-variant sweeps and for a pre-pass that measured nothing.
		var aabb: AABB = union if have_union else _subtree_aabb(host if host != null else inst)
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
		elif child is Control:
			# A Control parented under a Node3D draws STRAIGHT INTO THE VIEWPORT
			# without a CanvasLayer, and this suppressor only stood down
			# CanvasLayer and Camera3D. rhizomatic_maze_space carries a DebugInfo
			# Control — a 390x110 panel reading "Generating organic tunnel
			# network..." — and that panel WAS the 8.2% "subject" the verify pass
			# measured, identical in every frame, while the maze itself was a
			# ghost in its own volumetric fog with the camera 220 m out. The
			# subject-share number is only as honest as this list.
			(child as Control).visible = false
		_suppress_chrome(child)


## Autoloads that spawn world content on a timer. Stood down for the length of a
## sweep, because a capture bench must photograph the artifact and not the
## operator's save file. NatureRenderer is the one that was caught (see _stage);
## the other two are the same class of thing and are here pre-emptively.
const WORLD_BRIDGES: PackedStringArray = [
	"NatureRenderer", "FloraSpawner", "BiomeAccrualManager",
]


## THE GREEN, and why the bench's look now hangs on the CAMERA.
##
## Every sheet this rig ever published sits on a flat green — RGB(130,165,118) at
## 94.2% of frame — and it is not the background set below. It is NatureRenderer's
## fog. The autoload's `_deferred_init` calls `_find_world_environment()`, which
## walks the whole tree matching on CLASS (`node.get_class() == "WorldEnvironment"`),
## so it found the staging node this function used to create and took its
## Environment RESOURCE. It then tweened `fog_light_color` to
## `Color(0.6,0.6,0.6).lerp(Color(0.55,0.7,0.5), density)` and overwrote
## `ambient_light_color` and `ambient_light_energy` outright — the two values
## chosen below were never the ones that rendered.
##
## `density` comes from EcosystemManager, which restores
## `user://ecosystem_progression.json` on boot: THE DEVELOPER'S OWN SAVE. With all
## 25 sequences complete the density is 1.0, so the fog saturated to
## `Color(0.55,0.7,0.5)` — ratios 0.786 and 0.714 against the 0.788 and 0.715
## measured off the PNG. The 2.0 s tween finishes inside the pre-pass, so the fog
## is on every frame of a sweep equally, which is why a hollow axis came back
## byte-identical AND green rather than merely identical. **The background colour
## of this bench was a function of how much of the game the operator had played,
## and on a clean machine it would have been grey.** No `dna.framing` value can
## help a frame that is 94% someone else's fog; the hook has to go.
##
## So the look lives on `Camera3D.environment`, a per-camera override that wins
## over any WorldEnvironment, and no WorldEnvironment node is created at all.
## `_find_world_environment()` now returns null, NatureRenderer warns "No
## WorldEnvironment found — fog/sky disabled" and `_update_fog`/`_update_sky`
## early-return on a null `_env`. That is timing-immune: it does not matter
## whether the autoload readies before or after this function runs. It also
## covers an artifact that ships its own WorldEnvironment, which the bridge would
## otherwise hijack instead.
func _stage(vp: SubViewport) -> void:
	# Nothing an autoload parents under /root may enter the frame. NatureRenderer
	# builds a GPUParticles3D of up to 100 greenish quads in an 8 x 0.5 x 8 box at
	# the origin and, while this viewport shared the root's World3D, they were
	# rendering into the sweep.
	vp.own_world_3d = true
	_stand_down_world_bridges()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.055, 0.070)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
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
	cam.environment = env
	vp.add_child(cam)


## Idempotent, and called twice on purpose: once from _stage, and once more after
## the pre-pass, because whether an autoload is already in the tree when a
## `--script` SceneTree reaches `_initialize()` is not something to bet a bench
## on. A miss is harmless — the camera-owned environment above closes the fog
## path on its own — so this is belt to that brace, and it also stops the
## particle system and the polling.
func _stand_down_world_bridges() -> void:
	for singleton in WORLD_BRIDGES:
		var n: Node = root.get_node_or_null(NodePath(singleton))
		if n == null:
			continue
		n.process_mode = Node.PROCESS_MODE_DISABLED


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
		elif n is MultiMeshInstance3D:
			# A host grid IS a MultiMeshInstance3D, and so is any artifact drawn with
			# one. Counting only MeshInstance3D measured those as a 1 m box, which is
			# the documented cause of "subject under 6% of frame".
			var mm := n as MultiMeshInstance3D
			if mm.multimesh != null:
				var wab2: AABB = mm.global_transform * mm.get_aabb()
				acc = wab2 if not have else acc.merge(wab2)
				have = true
		for ch in n.get_children():
			stack.append(ch)
	return acc if have else AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)


## ── The artifacts with no body of their own ──────────────────────────────────
##
## A whole class of artifact draws nothing and owns nothing. remove_random,
## Random_Rotate_Random_XYZ and proximity_spawner all report aabb_size [0,0,0] in
## the registry, because what they ARE is an operation on the host map's grid:
## each one hunts a MultiMeshInstance3D through get_parent() and rewrites its
## transforms. Photographed standalone there is no grid, so nothing happens and
## nothing renders, and the loop declined them for "no body to photograph".
##
## That was a fact about the bench, not about the artifact. This builds the grid
## they are looking for — a MultiMeshInstance3D named GridMultiMesh, the name
## RemoveRandom searches for by default via its `../GridMultiMesh` NodePath — and
## parents the artifact beside it, which is exactly the shape a real map gives
## them. Declared per artifact as dna.host in the registry:
##
##   "host": {"size": [8, 1, 8], "cell": 1.0}
##
## Deterministic by construction: a plain lattice, no randomness, so the only
## thing that moves between variants is what the artifact does to it.
func _build_host(vp: SubViewport, host: Dictionary) -> Node3D:
	var stage := Node3D.new()
	stage.name = "Host"
	vp.add_child(stage)

	var size: Array = host.get("size", [8, 1, 8])
	var nx: int = int(size[0]) if size.size() > 0 else 8
	var ny: int = int(size[1]) if size.size() > 1 else 1
	var nz: int = int(size[2]) if size.size() > 2 else 8
	var cell: float = float(host.get("cell", 1.0))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3.ONE * (cell * 0.92)
	mm.mesh = box
	mm.instance_count = nx * ny * nz

	var i: int = 0
	for x in range(nx):
		for y in range(ny):
			for z in range(nz):
				var p := Vector3(
					(float(x) - float(nx - 1) * 0.5) * cell,
					float(y) * cell,
					(float(z) - float(nz - 1) * 0.5) * cell)
				mm.set_instance_transform(i, Transform3D(Basis(), p))
				i += 1

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GridMultiMesh"
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.64, 0.70)
	mat.roughness = 0.75
	mmi.material_override = mat
	stage.add_child(mmi)

	print("host grid: %d x %d x %d cells at %.2f m" % [nx, ny, nz, cell])
	return stage


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}
