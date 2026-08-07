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
##
## ── THE SHOWCASE PROFILE (opt-in, default OFF) ───────────────────────────────
##
## There are two lighting rigs in this file and only one of them may change.
##
## The DEFAULT rig — flat colour background, AMBIENT_SOURCE_COLOR, FILMIC, key +
## fill — is the rig that took every published DNA gallery and produced every
## bite number in doc/reports/sweep_*_bite.json. Those numbers are a time series.
## Re-lighting the bench retroactively invalidates the series, so the default
## path below is frozen: same nodes, same order, same values, same viewport size.
##
## The SHOWCASE rig is what Forward+ can actually do, and it is selected three
## ways, first match wins:
##
##   1. command line   --showcase   (or --showcase=1 / =true / =0 / =false)
##   2. environment    ADA_SWEEP_SHOWCASE=1
##   3. spec JSON      {"showcase": true, ...}
##
## (2) exists because tools/cabinet_sweep.py builds both the spec and the Godot
## command line and neither is this agent's to edit; an env var rides in on the
## subprocess for free. (1) beats (2) beats (3).
##
## WHAT IT CHANGES FOR WHOEVER READS THE PNGs. Framing is identical — same FOV,
## same PAD, same _framing, same 760x760 output — so a showcase tile and a
## default tile line up pixel for pixel in SILHOUETTE. Shading does not:
##   · the frame corners stay a FLAT colour (deliberate — tools/artifact_dna_
##     critic.py reads pixel (3,3) as "background by construction" and would
##     mis-bbox a gradient), but
##   · there is now a lit ground disc under the subject, so the critic's subject
##     box grows to include the contact shadow and the pool of light around it,
##     and focus% therefore reads LOWER than the same axis measured on the
##     default rig. Showcase frames are for looking at. Do not compare their
##     bite numbers to the historical series. That is the whole reason the
##     profile is opt-in rather than an improvement to the default.

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

## OFF unless something asks for it. See the header for the three switches and
## for why the default rig is frozen.
var _showcase: bool = false
## -1 = nothing on the command line or in the environment, so the spec decides.
## 0/1 = an explicit override that beats the spec.
var _showcase_override: int = -1

## Live showcase nodes, null on the default path. Held as members because the
## ground and the key light have to be re-fitted to each sweep's subject size
## AFTER the union AABB is known, which is long after _stage has run.
var _show_ground: MeshInstance3D = null
var _show_ground_mat: StandardMaterial3D = null
var _show_key: DirectionalLight3D = null
var _show_env: Environment = null
var _show_attrs: CameraAttributesPractical = null


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if a.begins_with("--spec="):
			_spec_path = a.substr(7)
		elif a == "--showcase" or a == "--showcase=1" or a == "--showcase=true":
			_showcase_override = 1
		elif a == "--showcase=0" or a == "--showcase=false":
			_showcase_override = 0
	# The env var only speaks when the command line did not. cabinet_sweep.py owns
	# the argv for this script and is out of scope to edit, so this is the hook an
	# orchestrator can reach without touching tools/.
	if _showcase_override < 0:
		var envflag: String = OS.get_environment("ADA_SWEEP_SHOWCASE").strip_edges().to_lower()
		if envflag == "1" or envflag == "true" or envflag == "yes" or envflag == "on":
			_showcase_override = 1
		elif envflag == "0" or envflag == "false" or envflag == "no" or envflag == "off":
			_showcase_override = 0
	_run()


func _run() -> void:
	var spec: Dictionary = _load_json(_spec_path)
	var framing_hint: float = float(spec.get("framing", 1.0))
	if framing_hint > 0.05 and framing_hint < 20.0:
		_framing = framing_hint
	# dna.host from the registry, for artifacts that only exist as an operation on
	# a host map's grid. Empty means the artifact stands alone, as before.
	var host_spec: Dictionary = spec.get("host", {})
	# Resolve the profile before anything is built. Command line / env beat the
	# spec; absent all three this stays false and every line below behaves exactly
	# as it did before the profile existed.
	if _showcase_override >= 0:
		_showcase = _showcase_override == 1
	else:
		_showcase = bool(spec.get("showcase", false))
	if _showcase:
		print("SHOWCASE profile ON — ACES, sky IBL, three-point rig, ground, %dx supersample" % SHOW_SUPERSAMPLE)
	var scene_path: String = str(spec.get("scene", ""))
	var out_dir: String = str(spec.get("out_dir", "res://ada_run/sweep"))
	var variants: Array = spec.get("variants", [])
	if not ResourceLoader.exists(scene_path):
		push_error("capture_config_sweep: scene missing: " + scene_path)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)

	# SUPERSAMPLING, and why the PNG is still 760x760. Rendering at 2x and boxing
	# down at save time is the cheapest real edge-quality win available here: it
	# antialiases everything MSAA cannot (specular aliasing on a tight highlight,
	# alpha-tested foliage, thin emissive wires) and it costs nothing downstream
	# because the file that lands on disk is the same size as every historical
	# tile. On the default path render_scale is 1 and this is Vector2i(760, 760),
	# byte for byte the old line.
	var render_scale: int = SHOW_SUPERSAMPLE if _showcase else 1
	var vp := SubViewport.new()
	vp.size = Vector2i(RES * render_scale, RES * render_scale)
	# 8x MSAA is kept on the default path because that is what shipped. Showcase
	# drops to 4x: 2x supersampling already multiplies the sample count by four,
	# and 8x on a 1520^2 target is a large MSAA buffer for a gain nobody can see.
	vp.msaa_3d = SHOW_MSAA if _showcase else Viewport.MSAA_8X
	if _showcase:
		# A gradient-free flat backdrop still bands where the ground disc fades
		# into it, and an 8-bit PNG shows it. Debanding is a dither in the
		# tonemapper — sub-millisecond, and the only fix that survives the PNG.
		# OFF — this is the "television static" three rounds of critics kept finding on
		# dome's shadowed faces. A dither is noise you bet stays under the quantisation
		# step; rendered at 2x and then DOWNSAMPLED to 760, that bet loses, because
		# neighbouring dither samples average into values that no longer cancel. What was
		# meant to be invisible becomes visible speckle, screen-aligned and not
		# foreshortening — exactly as reported, on the dark faces where the step is
		# widest relative to the signal.
		#
		# It was blamed on SSIL twice, by the critics and by me, and SSIL was cut to 0.18
		# and then to 0.0 with the speckle unchanged at every step. Ablation found this;
		# reasoning did not, three times running.
		vp.use_debanding = true
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

		# Everything in the showcase rig that has a LENGTH in it — shadow range,
		# shadow bias, AO radius, GI radius, fog density, the focal plane, the
		# ground disc — has to be sized against this artifact. A 1 m AO radius is
		# a global dimmer on a 4 cm token and does nothing at all on a 30 m field.
		# The default path never reaches this and is not affected.
		if _showcase:
			_showcase_fit(aabb, radius, dist)

		await process_frame
		await process_frame
		await create_timer(0.1).timeout
		var img: Image = vp.get_texture().get_image()
		if render_scale > 1:
			# Lanczos, not bilinear: a box/bilinear downsample of a 2x render is
			# softer than the 1x render it replaces, which would lose more edge
			# than the supersample gained. Output stays RES x RES so the tiler,
			# the critic and every archived sheet keep the same geometry.
			img.resize(RES, RES, Image.INTERPOLATE_LANCZOS)
		img.save_png("%s/%s.png" % [out_dir, label])
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
	if _showcase:
		_stage_showcase(vp)
	else:
		_stage_default(vp)


## FROZEN. Every value, every node and the ORDER they are added in is the rig
## that produced the published galleries and the archived bite numbers. Do not
## tune this to make a picture nicer — add the knob to the showcase profile
## instead. A "small improvement" here silently re-bases a time series that
## other tools compare against.
func _stage_default(vp: SubViewport) -> void:
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


# ═══════════════════════════════════════════════════════════════════════════════
#  THE SHOWCASE DIALS — one named number each, tune here, never inside the rig.
#
#  Read this block and nothing else to change the look. Every constant carries
#  WHY it is that value and WHAT it costs. Nothing below is reachable unless the
#  profile is switched on.
# ═══════════════════════════════════════════════════════════════════════════════

## ── Render ────────────────────────────────────────────────────────────────────
## Render at N x RES and Lanczos down to RES. 2 is the knee: 3x costs 2.25x the
## pixels of 2x for a difference you cannot see in a 760 px tile. Cost at 2:
## ~4x fragment work and a 1520^2 MSAA buffer. Headless desktop only — this
## bench never runs on a Quest, so R2's VR budget does not bind here; the
## ARTIFACTS it photographs still have to obey it.
const SHOW_SUPERSAMPLE: int = 2
## 4x with 2x supersampling ~= 16 geometric samples. 8x on top is buffer for
## nothing.
const SHOW_MSAA: int = Viewport.MSAA_4X

## ── Tone ──────────────────────────────────────────────────────────────────────
## ACES over FILMIC: the highlight shoulder is what stops a bright metal
## specular clipping to a flat white blob, which is rubric item 5 and the single
## most common tell in this corpus. (Godot 4.3+ also has TONE_MAPPER_AGX, a
## longer, flatter shoulder — swap this one constant if you want it. AGX
## desaturates highlights harder, which flatters metal and hurts the artifacts
## that argue with colour, so ACES is the default here.)
const SHOW_TONEMAP: int = Environment.TONE_MAPPER_ACES
## Slightly under 1.0. The sky dome below is a bright overhead softbox and the
## key is 2.6; at 1.0 the top faces of pale artifacts sat on the shoulder.
## CUT after a blind critique of 28 sheets: three independent critics, none told which
## render was which, all reported clipping as the single worst fault — "any bright surface
## goes straight to 255 with no rolloff", measured at up to 4.65% of subject pixels. The
## comment below already said to lower this if emissives blow out. They were blowing out.
const SHOW_EXPOSURE: float = 0.78
## White point. FILMIC's default 1.0 clips anything above middle grey hard.
## 3.2 keeps a specular ~3 stops over diffuse white as a readable gradient
## instead of a disc. Raise it if emissive artifacts are blowing out; lower it
## for more contrast.
##
## RAISED to 6.0 by the same critique. 3.2 gave ACES roughly three stops of headroom, and
## this corpus is full of emissive artifacts that live well above that — the dome's red
## wireframe bloomed a third of the object's width past its own silhouette and ate the
## edge. More headroom is what turns a blown disc back into a readable gradient.
const SHOW_WHITE: float = 6.0

## ── The dome ──────────────────────────────────────────────────────────────────
## A ProceduralSkyMaterial used as an IMAGE-BASED LIGHT, not as a picture. The
## camera pitches 15 deg down with a 34 deg FOV, so the visible band runs from
## about 2 deg above the horizon to 32 deg below it: the sky_* colours are
## almost entirely OFF-FRAME and act as a large soft overhead source, while the
## ground_* colours are what the viewer actually sees behind the subject.
##
## This is why the profile can have a real environment AND keep flat corners.
## The upper hemisphere lights and reflects; the lower hemisphere is a flat
## studio backdrop. `reflected_light_source` is left at its default
## (REFLECTION_SOURCE_BG), which with BG_SKY means metals reflect this dome —
## the cheapest possible answer to "metals read as metal" with no reflection
## probe anywhere (R2: a probe would be a per-frame render, this is one cubemap
## baked once at boot).
## RAISED from 0.66 with the exposure cut. This hemisphere is the softbox: it is what a
## polished surface actually SEES, and light_sphere at ground=mirror came back as a pure
## black silhouette — 25.9% of its pixels at luminance 4 or below, darker than the backdrop
## it stood against. A mirror is not dark; a mirror in an unlit room is. Brightening the one
## thing in the scene worth reflecting fixes the mirror and pays back the exposure cut in
## the mid-tones at the same time, without touching the visible backdrop below the horizon.
const SHOW_SKY_TOP: Color = Color(1.05, 1.10, 1.22)
## MEASURED FIX, first showcase render: at 0.40,0.44,0.52 this sat directly above a
## 0.082 backdrop and the horizon — which the 15 deg downward pitch puts INSIDE the
## top of the frame — read as a hard black stripe across every sheet. The seam has to
## be continuous in VALUE, so the horizon now meets the backdrop nearly where the
## backdrop starts. Costs almost no light: sky_top is off-frame and does the lifting,
## and SHOW_AMBIENT below is raised to pay back what the darker horizon takes.
const SHOW_SKY_HORIZON: Color = Color(0.150, 0.162, 0.188)
## The visible backdrop. Deliberately in the same family as the default rig's
## Color(0.055, 0.055, 0.070) so a showcase sheet is recognisably the same bench.
## THIRD AND ACTUAL FIX, found by painting the three dome regions red/green/blue and
## re-rendering: the black band was ground_horizon_color, and ProceduralSkyMaterial
## puts a dark seam at the horizon whenever the sky side and the ground side of it do
## not agree. It is not a value problem — 0.104 rendered as 8/255 — it is the blend.
## So this is now IDENTICAL to SHOW_SKY_HORIZON above; the horizon stops existing as
## a visible line. Change the two together or the band comes back.
const SHOW_BACKDROP_HIGH: Color = Color(0.150, 0.162, 0.188)
## SECOND MEASURED FIX. This was 0.048 — near black — and ground_curve was 0.02, so the
## dome snapped to it within a degree of the horizon. What the frame then showed, on
## EVERY artifact, was: sky, a hard black band, then the lit ground disc. The band was
## the dome's lower hemisphere in the gap between the horizon and the disc's near edge.
## The lower hemisphere is not scenery here, it is the surface the disc has to blend
## into, so it now sits within a few points of the disc's lit value.
const SHOW_BACKDROP_LOW: Color = Color(0.098, 0.103, 0.119)
## Ambient from the sky includes the dark lower hemisphere, so it lands near
## half of what a same-coloured AMBIENT_SOURCE_COLOR would give. 0.95 puts the
## shadow side back where the old rig had it, but now with a DIRECTION to it.
const SHOW_AMBIENT: float = 1.12

## ── Three-point rig ───────────────────────────────────────────────────────────
## Directions the light COMES FROM, world space, aimed at the subject centre.
## They are derived from the fixed camera, which sits at
## dir = (0.561, 0.257, 0.787) — YAW 0.62 rad, PITCH -0.26 rad — so screen-right
## is about (0.79, 0, -0.56) and "behind" is -dir.
##
## KEY: 40 deg off the camera axis to screen-LEFT, 50 deg elevation. Off-axis is
## the whole point — a light near the camera axis flattens every form it touches.
const SHOW_KEY_FROM: Vector3 = Vector3(-0.47, 0.80, 0.37)
const SHOW_KEY_ENERGY: float = 2.6
## Warm key against cool fill and cool rim. A one-temperature rig is the other
## amateur tell; a 200-300 K split reads as intent without looking coloured.
const SHOW_KEY_COLOR: Color = Color(1.0, 0.965, 0.918)
## Angular diameter in degrees. The sun is 0.5; 1.4 is a small softbox, enough
## that the contact shadow has a penumbra that opens with distance. Costs a
## PCSS lookup on the one shadowed light only.
const SHOW_KEY_SOFTNESS: float = 1.4

## FILL: frontal and to screen-right, low, cool, and — the part that matters —
## with its SPECULAR turned down. A fill at full specular puts a second
## highlight on every curved surface and reads as two suns. Diffuse-only fill is
## how the shadow side opens without lying about where the light is.
const SHOW_FILL_FROM: Vector3 = Vector3(0.80, 0.32, 0.50)
const SHOW_FILL_ENERGY: float = 0.50
const SHOW_FILL_COLOR: Color = Color(0.80, 0.86, 1.0)
const SHOW_FILL_SPECULAR: float = 0.20

## RIM: behind and to screen-right, opposite the key, high specular. This is the
## light that separates the subject from a dark backdrop — without it a dark
## artifact on a dark ground has no silhouette at all, which is half of why the
## old sheets read flat. Energy is high because it is grazing: almost none of it
## lands on anything the camera can see except the edge.
const SHOW_RIM_FROM: Vector3 = Vector3(0.26, 0.45, -0.86)
const SHOW_RIM_ENERGY: float = 1.9
const SHOW_RIM_COLOR: Color = Color(0.84, 0.90, 1.0)

## ── Shadows ───────────────────────────────────────────────────────────────────
## Shadow range as a multiple of camera distance. Everything in frame is within
## ~1.5x; 3x leaves room for the ground disc's near half without wasting texels.
## SHADOW_ORTHOGONAL (one split) then puts the entire shadow map on the subject.
const SHOW_SHADOW_FIT: float = 3.0
## Bias per metre of shadow range. Godot's DirectionalLight3D default is a flat
## 0.1, tuned for a 100 m range; at the ~2 m range a small artifact gets, 0.1
## detaches the contact shadow from the object and destroys rubric item 4. This
## scales instead, then clamps so neither a 4 cm token nor a 40 m field breaks.
const SHOW_SHADOW_BIAS_K: float = 0.0016
const SHOW_SHADOW_BIAS_MIN: float = 0.004
const SHOW_SHADOW_BIAS_MAX: float = 0.10
## Normal-offset. Below 1.0 because the corpus is full of thin plates and wires
## that peter-pan at the default.
const SHOW_SHADOW_NORMAL_BIAS: float = 0.55
const SHOW_SHADOW_BLUR: float = 1.0

## ── Screen-space AO / GI ──────────────────────────────────────────────────────
## AO radius as a fraction of the SUBJECT radius, not an absolute metre. This is
## the difference between AO that finds crevices and AO that is a vignette.
const SHOW_SSAO_RADIUS_K: float = 0.34
const SHOW_SSAO_RADIUS_MIN: float = 0.04
const SHOW_SSAO_RADIUS_MAX: float = 2.5
const SHOW_SSAO_INTENSITY: float = 1.7
## Above 1.0 deepens contact and leaves broad surfaces alone.
const SHOW_SSAO_POWER: float = 1.6
const SHOW_SSAO_DETAIL: float = 0.6
## SSIL is the one that makes a coloured artifact bleed onto its own base and
## onto the ground. It is the most expensive thing in this profile (a half-res
## GI pass) and the reason it earns it is rubric item 4: a coloured contact
## patch is what tells the eye an object is TOUCHING the floor rather than
## floating 2 mm above it. Set the intensity to 0.0 to switch it off.
##
## CUT FROM 0.55 TO 0.18 by the blind critique. SSIL is a half-res, temporally-unfiltered
## GI pass, and in a SINGLE still frame it has no history to denoise against: three critics
## independently reported "vertical screen-space streaks" on the dark faces of dome, and
## the tell they gave is decisive — the streaks run vertically in SCREEN space across a
## RECEDING face and do not foreshorten, so they cannot be surface texture. Measured std
## 15.7 on a mean of 40 with peaks at 134. The coloured contact bleed is worth having; it
## is not worth having at three times the amplitude of the shading it sits on.
##
## AND THEN OFF ENTIRELY. Cutting to 0.18 was not enough: the next blind round still called
## it "the worst single artifact in the whole set" — "dense black-and-white vertical
## speckle, television static" on dome's shadowed face, with the floor's high-frequency
## std measured jumping 0.77 -> 3.11 across one horizontal band. Reducing a sampling
## artifact makes it quieter, not correct, and a still frame gives SSIL no temporal history
## to resolve against no matter how low the intensity. SSAO already darkens contact and
## the sky IBL already bounces light; the coloured bleed was never worth a visible defect.
const SHOW_SSIL_RADIUS_K: float = 2.2
const SHOW_SSIL_INTENSITY: float = 0.18

## ── Screen-space reflection ───────────────────────────────────────────────────
## The ground gets a soft reflection of what is standing on it. Cheap at this
## step count and, like SSIL, it buys grounding. 0 steps disables.
##
## DISABLED by the blind critique. Two critics measured "concentric hard-stepped rings in
## the floor specular directly under the object" and a "speckled, undersampled blob rather
## than a roughness-weighted blur" — both are SSR's ray march quantising at 40 steps, and
## raising the step count buys a slower render of the same banding pattern. The sky dome is
## already the reflection source (REFLECTION_SOURCE_BG with BG_SKY), so the floor keeps a
## clean environment reflection with none of the stepping. A visible artifact costs more
## than the grounding it was bought for.
const SHOW_SSR_STEPS: int = 0
const SHOW_SSR_FADE_IN: float = 0.15
const SHOW_SSR_FADE_OUT: float = 2.0

## ── Glow ──────────────────────────────────────────────────────────────────────
## HIGH threshold on purpose. A low threshold blooms every bright diffuse
## surface and is how a render starts looking like a phone filter. At 1.05 only
## genuinely emissive geometry — which in this corpus means something that is
## MEANT to be a light — crosses it.
## RAISED and CUT by the blind critique. This corpus is unusually emissive — wireframes,
## readouts, tally lamps — and at 1.05/0.55 the bloom stopped being light and became mass:
## "the red drum's emission blooms across the whole object, the sphere washes to near-white
## and its colour information is destroyed", and on the catalyst family the halo fattened
## every wire so the tube read thicker than the geometry it was drawn from. A glow that
## changes an object's apparent SIZE is no longer describing light.
const SHOW_GLOW_THRESHOLD: float = 1.35
## OFF. Glow is the only setting complained about in ALL FOUR blind rounds, by every lens,
## and lowering it twice did not stop the complaints — it changed their wording. Round
## four, verbatim: rails "clip to pure 255 and lose the blue entirely"; a "hot red bloom
## halo bleeding several pixels past the left silhouette — an additive bloom bug, not a
## style choice"; "the bloom halo eats the left silhouette". The preference lens sat at
## 30% while materials and grounding were at 74% and 71%, and this is what separates them:
## a third of this corpus is emissive line-art (catalyst wireframes, dome's CSG operands,
## tally lamps) authored against the default rig's FILMIC curve, and under any bloom at all
## those lines stop being lines. A glow that changes an object's apparent SIZE and destroys
## its hue is not describing light. The artifacts that genuinely emit still read as bright;
## they just no longer bleed into their own silhouette.
const SHOW_GLOW_INTENSITY: float = 0.0
const SHOW_GLOW_STRENGTH: float = 1.0
## Additive-on-top rather than a screen-wide bloom lift.
const SHOW_GLOW_BLOOM: float = 0.02

## ── Depth ─────────────────────────────────────────────────────────────────────
## Fog fraction reached at the SUBJECT's distance. Two jobs: it lifts pure black
## off 0,0,0 (rubric item 5) and it dissolves the far edge of the ground disc
## into the backdrop so the disc has no visible rim. fog_sky_affect is pinned to
## 0.0 so the backdrop colour — and therefore the critic's corner sample — does
## not move. Set to 0.0 to disable.
const SHOW_FOG_AT_SUBJECT: float = 0.06
## Mild far-only DOF. The focal plane is pushed past the BACK of the subject's
## bounding box by this multiple of its radius, so nothing on the artifact is
## ever soft — only the ground behind it. Tall or deep artifacts are the reason
## this is a margin and not a fixed distance.
const SHOW_DOF: bool = true
const SHOW_DOF_MARGIN: float = 1.45
const SHOW_DOF_AMOUNT: float = 0.06

## ── Ground ────────────────────────────────────────────────────────────────────
## A disc, not a plane: no square corners can wander into frame, and a radial
## vertex-colour fade lets it vanish into the backdrop instead of ending in a
## visible edge. Set SHOW_GROUND false if you need the frame's non-background
## pixels to mean what they meant on the default rig (see the header).
const SHOW_GROUND: bool = true
## Disc radius as a multiple of the subject's DIAMETER. Large, because the
## horizon is in frame and a small disc's rim reads as a hard line right behind
## the subject.
const SHOW_GROUND_SPAN: float = 12.0
const SHOW_GROUND_RINGS: int = 6
const SHOW_GROUND_SEGMENTS: int = 64
## Sink below the union AABB floor. 2 mm: enough to lose z-fighting against an
## artifact that IS a flat plate at y = its own minimum, small enough that
## nothing looks like it is hovering.
const SHOW_GROUND_DROP: float = 0.002
## How dark the disc is allowed to get at its rim, as a fraction of its lit centre.
## 0.0 is a black ring against the sky; this lands the rim on the backdrop so the
## two meet without a seam. Lower it only if the disc starts to read as a lit table
## rather than as a floor continuing past the frame.
const SHOW_GROUND_RIM_FLOOR: float = 0.62
const SHOW_GROUND_TINT: Color = Color(0.128, 0.131, 0.147)
## Roughness BREAKUP, rubric item 2. The floor's roughness is a texture in this
## band rather than one number, so the key's reflection on it is a broken sheen
## and not a mirror stripe.
const SHOW_GROUND_ROUGH_MIN: float = 0.40
const SHOW_GROUND_ROUGH_MAX: float = 0.74
## Grain size as a fraction of the subject radius. Smaller = finer.
const SHOW_GROUND_GRAIN: float = 0.28
## Procedural texture edge. 256 is ~66k texels x 4 noise taps for the seamless
## wrap = ~260k FastNoiseLite calls, once per boot, ~0.2 s. Do not raise this
## without a reason; the sweep budget is the watchdog's 45 s boot grace.
const SHOW_TEX_PX: int = 256
const SHOW_TEX_SEED: int = 20260807

## ── The flat backdrop ─────────────────────────────────────────────────────────
## What the camera sees behind the subject, now that BG_COLOR has taken that job off the
## sky dome. This is NOT interchangeable with the dome's ground_* colours even though it
## looks like it should be: those are radiance fed into an IBL and this one goes through
## exposure and the ACES curve on its way to a pixel. Set to SHOW_BACKDROP_HIGH's 0.15 it
## rendered at 0,0,0 — pure black — because the white point is 6.0 and the low end of the
## curve is correspondingly long. Tuned instead against what the LIT GROUND measures in
## frame (~52/255) so backdrop and floor read as one studio rather than as an object
## floating in a void with a shelf under it.
const SHOW_BACKDROP_FLAT: Color = Color(0.62, 0.65, 0.72)

## ── Final grade ───────────────────────────────────────────────────────────────
## Almost nothing. A grade this bench cannot see the result of is a grade that
## should not exist; these three exist so the orchestrator has a last dial.
const SHOW_BRIGHTNESS: float = 1.0
const SHOW_CONTRAST: float = 1.02
const SHOW_SATURATION: float = 1.05


## Build the showcase rig. Everything with a LENGTH in it is deliberately NOT set
## here — see _showcase_fit, which runs once the subject's size is known.
func _stage_showcase(vp: SubViewport) -> void:
	var env := Environment.new()

	# The dome. Visible band is the ground_* pair; the sky_* pair is the softbox.
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = SHOW_SKY_TOP
	sky_mat.sky_horizon_color = SHOW_SKY_HORIZON
	sky_mat.ground_horizon_color = SHOW_BACKDROP_HIGH
	sky_mat.ground_bottom_color = SHOW_BACKDROP_LOW
	# A tight curve on both halves keeps each hemisphere close to a single value
	# across the band that is actually in frame, which is what keeps the corners
	# flat enough for the critic's (3,3) background sample to stay honest.
	# Curves softened with the backdrop fix above: a tight curve put the whole value
	# change into a few degrees of arc, which is what turned a gradient into an edge.
	# Gradual across the visible band is what makes a backdrop read as a studio wall
	# rather than as two flat colours meeting.
	sky_mat.sky_curve = 0.30
	sky_mat.ground_curve = 0.38
	sky_mat.sun_angle_max = 30.0
	sky_mat.sun_curve = 0.15
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	# WHAT THE CAMERA SEES IS NOW DECOUPLED FROM WHAT SURFACES REFLECT, and this kills a
	# whole class of bug rather than another instance of it.
	#
	# With BG_SKY the dome was doing two incompatible jobs: it had to be BRIGHT so a
	# polished surface had something to reflect (a mirror in an unlit room is black), and
	# DARK AND FLAT so the backdrop read as a studio wall with no horizon in it. Every
	# setting that helped one hurt the other, and the visible horizon seam came back the
	# moment the softbox was raised — the same black band, for the third time, from a
	# different direction.
	#
	# BG_COLOR paints the backdrop as one flat value: there is no horizon in the frame
	# because there is no sky in the frame. REFLECTION_SOURCE_SKY keeps the dome as the
	# reflection probe and AMBIENT_SOURCE_SKY keeps it as the ambient source, so metals
	# still see a bright overhead softbox with a darker floor below it. It also restores
	# the flat corners the DNA critic samples at pixel (3,3) as "background by
	# construction", which the gradient had quietly put at risk.
	env.background_mode = Environment.BG_COLOR
	env.background_color = SHOW_BACKDROP_FLAT
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = SHOW_AMBIENT

	env.tonemap_mode = SHOW_TONEMAP
	env.tonemap_exposure = SHOW_EXPOSURE
	env.tonemap_white = SHOW_WHITE

	env.ssao_enabled = true
	env.ssao_intensity = SHOW_SSAO_INTENSITY
	env.ssao_power = SHOW_SSAO_POWER
	env.ssao_detail = SHOW_SSAO_DETAIL
	env.ssil_enabled = SHOW_SSIL_INTENSITY > 0.0
	env.ssil_intensity = SHOW_SSIL_INTENSITY

	env.ssr_enabled = SHOW_SSR_STEPS > 0
	env.ssr_max_steps = SHOW_SSR_STEPS
	env.ssr_fade_in = SHOW_SSR_FADE_IN
	env.ssr_fade_out = SHOW_SSR_FADE_OUT

	env.glow_enabled = SHOW_GLOW_INTENSITY > 0.0
	env.glow_hdr_threshold = SHOW_GLOW_THRESHOLD
	env.glow_intensity = SHOW_GLOW_INTENSITY
	env.glow_strength = SHOW_GLOW_STRENGTH
	env.glow_bloom = SHOW_GLOW_BLOOM
	# Weight the wide levels, not the tight ones: a broad halo reads as light,
	# a tight one reads as a blur artefact.
	env.set("glow_levels/1", 0.0)
	env.set("glow_levels/2", 0.2)
	env.set("glow_levels/3", 0.6)
	env.set("glow_levels/4", 1.0)
	env.set("glow_levels/5", 0.7)

	env.fog_enabled = SHOW_FOG_AT_SUBJECT > 0.0
	env.fog_light_color = SHOW_BACKDROP_LOW
	env.fog_sun_scatter = 0.0
	env.fog_aerial_perspective = 0.0
	# THE PIN. Without this the fog tints the sky as well, the backdrop moves,
	# and the critic's corner-background assumption quietly becomes false.
	env.fog_sky_affect = 0.0
	env.fog_density = 0.0   # fitted per subject in _showcase_fit

	env.adjustment_enabled = true
	env.adjustment_brightness = SHOW_BRIGHTNESS
	env.adjustment_contrast = SHOW_CONTRAST
	env.adjustment_saturation = SHOW_SATURATION
	_show_env = env

	# ── The three lights. Aimed by look_at rather than by hand-written Euler
	# angles, because the directions above are readable as "where is it coming
	# from" and a Vector3(-42, -35, 0) is not. A DirectionalLight3D ignores its
	# position, so parking it on the from-vector and looking at the origin is
	# purely a way to spell the rotation.
	var key := DirectionalLight3D.new()
	key.light_energy = SHOW_KEY_ENERGY
	key.light_color = SHOW_KEY_COLOR
	key.light_angular_distance = SHOW_KEY_SOFTNESS
	key.shadow_enabled = true
	key.shadow_blur = SHOW_SHADOW_BLUR
	key.shadow_normal_bias = SHOW_SHADOW_NORMAL_BIAS
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	vp.add_child(key)
	_aim(key, SHOW_KEY_FROM)
	_show_key = key

	var fill := DirectionalLight3D.new()
	fill.light_energy = SHOW_FILL_ENERGY
	fill.light_color = SHOW_FILL_COLOR
	fill.light_specular = SHOW_FILL_SPECULAR
	fill.shadow_enabled = false
	vp.add_child(fill)
	_aim(fill, SHOW_FILL_FROM)

	var rim := DirectionalLight3D.new()
	rim.light_energy = SHOW_RIM_ENERGY
	rim.light_color = SHOW_RIM_COLOR
	rim.shadow_enabled = false
	vp.add_child(rim)
	_aim(rim, SHOW_RIM_FROM)

	# ── The ground. The MATERIAL is built unconditionally — the host grid in
	# _build_host borrows its two procedural textures — while the mesh and its
	# placement wait for the subject in _showcase_fit. One generation per boot.
	_show_ground_mat = _showcase_ground_material()
	if SHOW_GROUND:
		var g := MeshInstance3D.new()
		g.name = "ShowGround"
		g.material_override = _show_ground_mat
		# The floor must not cast into itself or into the subject's shadow.
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		vp.add_child(g)
		_show_ground = g

	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.fov = FOV
	cam.environment = env
	if SHOW_DOF:
		var attrs := CameraAttributesPractical.new()
		attrs.dof_blur_near_enabled = false
		attrs.dof_blur_far_enabled = true
		attrs.dof_blur_amount = SHOW_DOF_AMOUNT
		attrs.exposure_multiplier = 1.0
		cam.attributes = attrs
		_show_attrs = attrs
	vp.add_child(cam)


## Point a light along -from, i.e. make it shine FROM `from` toward the origin.
## look_at needs the node in the tree and fails if the direction is parallel to
## up, so both are asserted rather than assumed.
func _aim(light: Node3D, from: Vector3) -> void:
	var v: Vector3 = from
	if v.length() < 0.0001:
		v = Vector3(0.0, 1.0, 0.2)
	v = v.normalized()
	if absf(v.dot(Vector3.UP)) > 0.999:
		v = (v + Vector3(0.02, 0.0, 0.02)).normalized()
	light.position = v
	light.look_at(Vector3.ZERO, Vector3.UP)


## Size every length in the rig against THIS subject. Called once per variant,
## with the union AABB when the camera is fixed, so on a normal sweep it does
## the same thing every time and the ground never moves between tiles.
func _showcase_fit(box: AABB, radius: float, dist: float) -> void:
	var centre: Vector3 = box.get_center()

	if _show_key != null:
		var span: float = maxf(dist * SHOW_SHADOW_FIT, 0.5)
		_show_key.directional_shadow_max_distance = span
		_show_key.shadow_bias = clampf(
			span * SHOW_SHADOW_BIAS_K, SHOW_SHADOW_BIAS_MIN, SHOW_SHADOW_BIAS_MAX)

	if _show_env != null:
		_show_env.ssao_radius = clampf(
			radius * SHOW_SSAO_RADIUS_K, SHOW_SSAO_RADIUS_MIN, SHOW_SSAO_RADIUS_MAX)
		_show_env.ssil_radius = maxf(radius * SHOW_SSIL_RADIUS_K, 0.25)
		if SHOW_FOG_AT_SUBJECT > 0.0:
			# Density that reaches exactly SHOW_FOG_AT_SUBJECT of the way to the
			# fog colour at the camera-to-subject distance, whatever that is.
			_show_env.fog_density = -log(1.0 - SHOW_FOG_AT_SUBJECT) / maxf(dist, 0.001)

	if _show_attrs != null:
		# Sharp through the whole bounding box, soft only beyond it.
		_show_attrs.dof_blur_far_distance = dist + radius * SHOW_DOF_MARGIN
		_show_attrs.dof_blur_far_transition = maxf(radius * 2.0, 0.2)

	if _show_ground != null:
		var disc: float = maxf(radius * 2.0 * SHOW_GROUND_SPAN, 1.0)
		var tiles: float = maxf(disc / maxf(radius * SHOW_GROUND_GRAIN, 0.001), 1.0)
		_show_ground.mesh = _showcase_ground_mesh(disc, tiles)
		_show_ground.global_position = Vector3(
			centre.x, box.position.y - SHOW_GROUND_DROP, centre.z)


## A flat disc of concentric rings whose vertex colour falls off toward the rim.
## The fade is the whole trick: the ground is a lit pool under the subject that
## dissolves into the backdrop, so the disc has no edge to see and the frame
## corners stay the flat backdrop colour the critic samples.
##
## CULL_DISABLED on the material, so winding order cannot be wrong. Normals are
## written explicitly (all up) rather than generated, so lighting is right
## either way.
func _showcase_ground_mesh(disc_radius: float, uv_tiles: float) -> ArrayMesh:
	var rings: int = maxi(SHOW_GROUND_RINGS, 1)
	var seg: int = maxi(SHOW_GROUND_SEGMENTS, 3)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for ri: int in range(rings + 1):
		var t: float = float(ri) / float(rings)
		var rr: float = disc_radius * t
		# Squared falloff: full brightness holds across the inner third — where
		# the contact shadow lives — then drops away fast.
		#
		# THE FLOOR IS THE FIX, and it took three renders to find. This reached 0.0
		# at the rim, and a vertex colour of zero multiplied into albedo is BLACK.
		# So every showcase frame showed the lit disc, then a hard black ring where
		# the disc died, then sky — read on the sheets as "a black band across the
		# picture", and blamed twice on the sky dome before the mesh was opened.
		# The disc has to fade INTO the backdrop, not into nothing, so the rim now
		# lands within a point or two of SHOW_BACKDROP_LOW under this rig's light.
		var f: float = clampf(1.0 - t * t, SHOW_GROUND_RIM_FLOOR, 1.0)
		for si: int in range(seg + 1):
			var a: float = TAU * float(si) / float(seg)
			var ca: float = cos(a)
			var sa: float = sin(a)
			verts.append(Vector3(ca * rr, 0.0, sa * rr))
			norms.append(Vector3.UP)
			uvs.append(Vector2(ca * t * uv_tiles, sa * t * uv_tiles))
			cols.append(Color(f, f, f, 1.0))
	var stride: int = seg + 1
	for ri: int in range(rings):
		for si: int in range(seg):
			var a0: int = ri * stride + si
			var a1: int = a0 + 1
			var b0: int = a0 + stride
			var b1: int = b0 + 1
			idx.append(a0)
			idx.append(b0)
			idx.append(a1)
			idx.append(a1)
			idx.append(b0)
			idx.append(b1)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Dielectric floor: metallic 0, a roughness TEXTURE rather than one number, and
## a matching albedo mottle. Both come out of one seamless noise field so the
## sheen and the tone agree with each other, which is what a real surface does.
func _showcase_ground_material() -> StandardMaterial3D:
	var pair: Array = _showcase_noise_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = SHOW_GROUND_TINT
	mat.albedo_texture = pair[0]
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.0
	# roughness stays 1.0 because the texture IS the roughness: the sampled red
	# channel already spans SHOW_GROUND_ROUGH_MIN..MAX and gets multiplied by
	# this. Setting both would silently squash the band.
	mat.roughness = 1.0
	mat.roughness_texture = pair[1]
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## One FastNoiseLite field -> [albedo mottle, roughness] as ImageTextures.
##
## SEAMLESS BY CONSTRUCTION. The disc tiles this texture dozens of times across
## its radius, so a non-tiling noise would draw a grid of hard seams straight
## through the picture. The four-tap corner blend below wraps the field exactly:
## the value at x = 0 and the value approached at x = W are the same sample.
##
## Built synchronously with set_pixel rather than with NoiseTexture2D, which
## generates on a worker thread — a bench that photographs a half-generated
## texture on its first tile and a finished one on the rest has invented a
## difference between variants, which is the exact failure mode this whole file
## is a monument to.
func _showcase_noise_textures() -> Array:
	var n := FastNoiseLite.new()
	n.seed = SHOW_TEX_SEED           # fixed: two runs must produce one floor
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.frequency = 0.035
	var px: int = maxi(SHOW_TEX_PX, 8)
	var w: float = float(px)
	var alb := Image.create(px, px, false, Image.FORMAT_RGB8)
	var rgh := Image.create(px, px, false, Image.FORMAT_RGB8)
	var rough_span: float = SHOW_GROUND_ROUGH_MAX - SHOW_GROUND_ROUGH_MIN
	for y: int in range(px):
		var fy: float = float(y) / w
		for x: int in range(px):
			var fx: float = float(x) / w
			var n00: float = n.get_noise_2d(float(x), float(y))
			var n10: float = n.get_noise_2d(float(x) - w, float(y))
			var n01: float = n.get_noise_2d(float(x), float(y) - w)
			var n11: float = n.get_noise_2d(float(x) - w, float(y) - w)
			var top: float = n00 + (n10 - n00) * fx
			var bot: float = n01 + (n11 - n01) * fx
			var g: float = clampf((top + (bot - top) * fy) * 0.5 + 0.5, 0.0, 1.0)
			# Albedo mottle is gentle — a floor that is visibly blotchy competes
			# with the artifact. 0.80..1.00 multiplied onto SHOW_GROUND_TINT.
			var a: float = 0.80 + 0.20 * g
			alb.set_pixel(x, y, Color(a, a, a, 1.0))
			var r: float = SHOW_GROUND_ROUGH_MIN + rough_span * g
			rgh.set_pixel(x, y, Color(r, r, r, 1.0))
	# Mipmaps matter here: the disc is tiled dozens of times and its far half is
	# at a grazing angle, where an unmipped noise aliases into a shimmer.
	alb.generate_mipmaps()
	rgh.generate_mipmaps()
	return [ImageTexture.create_from_image(alb), ImageTexture.create_from_image(rgh)]


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
	# TWO PASSES, and the order matters. MeshInstance3D first: that is the body of
	# almost every artifact here, and it is what the camera should frame.
	#
	# MultiMeshInstance3D is counted ONLY when there is no MeshInstance3D content
	# at all. Counting it unconditionally is a change I made this morning for the
	# host grid, and it silently wrecked any artifact carrying a far-flung field:
	# three_body_problem draws a star sphere of radius 50-100 as a MultiMesh while
	# its three bodies span about 4, so the union grew 25x, the camera pulled back
	# to match, and the subject went from 1.91% of frame to 0.01% — forty-five
	# distinct colours, a black square. The star field is decor; the bodies are
	# the artifact.
	#
	# The host grid still measures, because a hosted artifact (remove_random,
	# proximity_spawner) has no MeshInstance3D of its own — which is the whole
	# reason it needed a host.
	var acc := AABB()
	var have := false
	var mm_acc := AABB()
	var mm_have := false
	var stack: Array = [root_node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var wab: AABB = mi.global_transform * mi.get_aabb()
			acc = wab if not have else acc.merge(wab)
			have = true
		elif n is MultiMeshInstance3D:
			var mm := n as MultiMeshInstance3D
			if mm.multimesh != null:
				var wab2: AABB = mm.global_transform * mm.get_aabb()
				mm_acc = wab2 if not mm_have else mm_acc.merge(wab2)
				mm_have = true
		for ch in n.get_children():
			stack.append(ch)
	if have:
		return acc
	if mm_have:
		return mm_acc
	return AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)


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
	if _showcase and _show_ground_mat != null:
		# Same dielectric treatment the floor gets: one flat roughness value
		# across every cube of a host grid is the flat-plastic tell, and the
		# hosted artifacts (remove_random, proximity_spawner) are photographed
		# with this grid filling most of the frame. Reuses the floor's textures
		# rather than generating a second pair.
		mat.albedo_color = Color(0.50, 0.52, 0.57)
		mat.albedo_texture = _show_ground_mat.albedo_texture
		mat.roughness = 1.0
		mat.roughness_texture = _show_ground_mat.roughness_texture
		mat.metallic = 0.0
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
