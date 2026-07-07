## One-off sweep capture for the parametric-coordinate-frame DNA gallery.
##
## Instances CoordinateSystem3M.tscn at every combination of:
##   axis_length ∈ [1.0, 2.0, 3.0, 4.0]      (rows)
##   tick_step   ∈ [0.0 (none), 0.5, 1.0]   (columns)
## = 12 captures. The frame's X/Y/Z arrows + tip labels are framed in full
## from a fixed three-quarter angle; camera distance scales with axis_length
## so every frame fills the same proportion of the viewport.
##
## Visual setup mirrors capture_parametric_mesh_gallery.gd (1024x1024 SubViewport,
## MSAA 8x, FXAA, isolated World3D, key+fill+rim DirectionalLight3D trio,
## three-quarter view from above).
##
## CoordinateSystem3M adds an InfoPanel + Label3D + gyroscope gadget at runtime
## (when not in editor mode). The gallery wants clean frames so we walk the
## instanced subtree after _ready() and queue_free() anything that isn't an
## axis CoordinateLine (Node3D with the CoordinateLine class_name) or its
## sibling axis-tip Label3D. The X/Y/Z tip labels survive because they live
## directly on the CoordinateSystem3M root, not under the InfoPanel.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_coordinate_gallery.gd \
##     -- --out=user://parametric_coordinate_gallery
##
## Output: <out>/coord_L<axis_length>_T<tick_step>.png + .json
##         + manifest.json
extends SceneTree

const COORD_SCENE: String = "res://algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn"

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# Sweep axes. Keep the float→token map explicit to avoid float-formatting
# surprises in the entry ids (e.g. 0.5 → T05, not T0.5 or T5).
const AXIS_LENGTHS: Array = [1.0, 2.0, 3.0, 4.0]
const TICK_STEPS: Array = [0.0, 0.5, 1.0]

var _output_dir: String = "user://parametric_coordinate_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# ── SubViewport ─────────────────────────────────────────────────
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 0.80)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 1.2
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	# ── Lighting trio: key + fill + rim ─────────────────────────────
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-50, 35, 0)
	key_light.light_energy = 1.6
	key_light.light_color = Color(1.0, 0.96, 0.88)
	key_light.shadow_enabled = false
	_viewport.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-15, -110, 0)
	fill_light.light_energy = 0.55
	fill_light.light_color = Color(0.72, 0.82, 1.0)
	fill_light.shadow_enabled = false
	_viewport.add_child(fill_light)

	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-25, 170, 0)
	rim_light.light_energy = 1.1
	rim_light.light_color = Color(1.0, 0.88, 0.96)
	rim_light.shadow_enabled = false
	_viewport.add_child(rim_light)

	# ── Camera ──────────────────────────────────────────────────────
	# Three-quarter from above. Distance is recomputed per-cell so the frame
	# always fills the same viewport proportion regardless of axis_length.
	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.near = 0.01
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	var coord_scene = load(COORD_SCENE)
	if not coord_scene:
		push_error("CoordinateSystem3M scene missing: %s" % COORD_SCENE)
		quit(1)
		return

	# ── Sweep ───────────────────────────────────────────────────────
	for axis_length in AXIS_LENGTHS:
		for tick_step in TICK_STEPS:
			var node = coord_scene.instantiate()
			node.axis_length = axis_length
			node.axis_thickness = 0.02
			node.tick_step = tick_step
			_scene_holder.add_child(node)
			# Wait for the deferred _ready() pass to finish so the InfoPanel
			# and gyroscope have been instanced (we'll then prune them).
			await process_frame
			await process_frame
			_strip_runtime_clutter(node)
			# Recompute camera framing for this axis_length.
			# CoordinateSystem3M applies scale = 0.5 in _ready, so the world-
			# space frame extent along each axis is roughly axis_length * 0.5
			# from origin. Add a margin for the tip label ("X" / "Y" / "Z").
			var effective_extent: float = float(axis_length) * 0.5 + 0.3
			_aim_camera(effective_extent)
			await process_frame
			await process_frame
			await create_timer(0.05).timeout
			var id := _entry_id(float(axis_length), float(tick_step))
			await _capture_and_record(id, {
				"axis_length": float(axis_length),
				"tick_step": float(tick_step),
				"effective_axis_length_m": float(axis_length) * 0.5,
				"effective_tick_step_m": float(tick_step) * 0.5,
				"notes": _notes(float(axis_length), float(tick_step)),
			})
			_clear_holder()
			await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Parameter sweep for CoordinateSystem3M — the right-handed X/Y/Z frame from origin, with optional tick-mark ruler. 4 axis_length values × 3 tick_step values = 12 cells. The same coordinate frame becomes a different teaching tool as you change tick density — sparse ticks read as a clean direction indicator, dense ticks turn it into a precise ruler. Captured at 1024×1024 with MSAA 8x. Camera distance scales with axis_length so the frame fills the viewport at the same proportion across cells; this is what lets the eye compare tick density (0 vs 0.5 vs 1.0) and axis_length (1m → 4m) side by side. CoordinateSystem3M applies scale = 0.5 at runtime, so 'effective' lengths in world space are half of the export value.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"fov": 38.0, "dir": [1.0, 1.4, 1.0], "distance_factor": 2.5},
		"axis_lengths": AXIS_LENGTHS,
		"tick_steps": TICK_STEPS,
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ── Helpers ─────────────────────────────────────────────────────────

func _aim_camera(extent: float) -> void:
	# The frame extends from origin into the +X, +Y, +Z octant. We want the
	# camera in the opposite-sign-of-XZ octant — at (-x, +y, -z) — so:
	#   - the +X axis runs from origin toward the right of the screen
	#   - the +Z axis runs from origin toward the left of the screen
	#   - the +Y axis runs upward
	# All three tip arrows + tip labels are pushed AWAY from the camera into
	# the frame interior. The focus point is the visual centre of mass of the
	# axis triad — roughly (extent/3, extent/3, extent/3) since labels are
	# slightly past the axis tip.
	var focus := Vector3(extent / 3.0, extent / 3.0, extent / 3.0)
	var distance: float = extent * 2.5
	# Direction FROM focus TO camera. Classic isometric-style view: camera
	# in the (+X, +Y, +Z) octant with X and Z weighted equally (so they
	# project symmetrically to opposite sides of the screen) and Y weighted
	# high enough that the camera looks DOWN on the frame, not into the
	# horizon. With cam_dir = (1, 1.4, 1).normalized() the +X axis projects
	# to screen-right, +Z to screen-left, +Y vertical — the canonical 3D
	# textbook axis triad.
	var cam_dir: Vector3 = Vector3(1.0, 1.4, 1.0).normalized()
	_camera.position = focus + cam_dir * distance
	_camera.look_at(focus, Vector3.UP)


func _strip_runtime_clutter(coord_node: Node3D) -> void:
	# CoordinateSystem3M.gd's _ready() at runtime adds (in order):
	#   - 3 axis CoordinateLine nodes (named after the script class)
	#   - 3 Label3D tip labels ("X" / "Y" / "Z")
	#   - 1 InfoPanel Node3D (with Label3D children: title, P=(x,y,z), description)
	#   - 1 gyroscope gadget (an instance of GyroscopeGadgetScript)
	#
	# The InfoPanel hovers around y=1.2*0.33 ≈ 0.4 in scale-space; the gyroscope
	# sits at (-1.5, 0.5, 0). Both clutter the gallery frame.
	#
	# We keep only:
	#   - children whose script class_name is CoordinateLine (axis shafts)
	#   - top-level Label3D children (the tip labels)
	# and queue_free() everything else.
	for child in coord_node.get_children():
		var name_s := str(child.name)
		# The axis tip labels live directly on the root as Label3D; keep them.
		if child is Label3D:
			continue
		# Axis nodes — CoordinateLine instances. Their script is attached
		# imperatively in create_axis() so the class_name resolves on the
		# Script resource.
		var scr: Script = child.get_script()
		if scr != null:
			# CoordinateLine has class_name CoordinateLine, so the script's
			# global_name is "CoordinateLine".
			if scr.get_global_name() == "CoordinateLine":
				continue
			# Defensive: also keep anything whose script source path is
			# coordinate_line.gd (handles cases where global_name lookup
			# returns "" in some build configurations).
			var src_path: String = scr.resource_path
			if src_path.ends_with("coordinate_line.gd"):
				continue
		# Drop InfoPanel, gyroscope, and anything else.
		if name_s == "InfoPanel" or name_s == "TitlePanel":
			child.queue_free()
			continue
		# Catch the gyroscope (script-defined Node3D — no specific name on
		# the root, but it's neither a Label3D nor a CoordinateLine).
		child.queue_free()


func _entry_id(axis_length: float, tick_step: float) -> String:
	# axis_length is 1.0 / 2.0 / 3.0 / 4.0 → L1 / L2 / L3 / L4
	# tick_step is 0.0 / 0.5 / 1.0 → T0 / T05 / T1
	var L_token: String = "L%d" % int(axis_length)
	var T_token: String
	if tick_step == 0.0:
		T_token = "T0"
	elif tick_step == 0.5:
		T_token = "T05"
	elif tick_step == 1.0:
		T_token = "T1"
	else:
		# Generic fallback for any other value: strip dots.
		T_token = ("T%s" % str(tick_step)).replace(".", "")
	return "coord_%s_%s" % [L_token, T_token]


func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(id: String, meta: Dictionary) -> void:
	# Yield a few extra frames so the viewport has definitely re-rendered.
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	var config := meta.duplicate(true)
	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(config, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"notes": meta.get("notes", ""),
		"image": "/parametric-coordinate-gallery/%s" % img_rel,
		"config": "/parametric-coordinate-gallery/%s" % cfg_rel,
		"params": meta,
	})
	print("  saved: %s" % id)


func _notes(axis_length: float, tick_step: float) -> String:
	# Effective lengths are half the export value due to scale = 0.5 in _ready.
	var eff_len: float = axis_length * 0.5
	if tick_step == 0.0:
		return "axis_length=%.1f (%.1fm world) — no ticks, the frame reads as direction only." % [axis_length, eff_len]
	var eff_tick: float = tick_step * 0.5
	var ticks_per_axis: int = int(axis_length / tick_step)
	if tick_step >= axis_length:
		return "axis_length=%.1f (%.1fm world), tick_step=%.1f — sparse ticks, the frame is a direction indicator with one or two reference notches." % [axis_length, eff_len, tick_step]
	if ticks_per_axis >= 6:
		return "axis_length=%.1f (%.1fm world), tick_step=%.1f — dense ticks; %d marks per axis turn the frame into a precise ruler." % [axis_length, eff_len, tick_step, ticks_per_axis]
	return "axis_length=%.1f (%.1fm world), tick_step=%.1f — %d marks per axis. The frame reads as direction with a coarse scale." % [axis_length, eff_len, tick_step, ticks_per_axis]
