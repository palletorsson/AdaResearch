## Props DNA sweep — capture each of the 8 lab prop artifacts at 3
## different DNA configurations to make their parameter dimensions
## legible.
##
## Pedagogical claim — each prop is a procedural artifact built from
## a small DNA dict (exports). The gallery proves that the DNA actually
## matters: same .gd, same .tscn, three different expressions per row.
##
## Layout: 8 rows × 3 columns. One PNG per cell. JSON sidecar per cell
## with the DNA values used. manifest.json at the top groups rows by
## prop.
##
## Camera: AABB-orbit per cell. The script frames each prop tightly
## using the recursive AABB computed after _ready() has built the
## meshes. 3/4 angle (yaw ≈ 0.6 rad, pitch ≈ -0.35 rad) so the form
## reads as a 3D object, not a flat elevation.
##
## Run:
##   "/c/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/capture_props_dna_gallery.gd -- \
##     --out=user://props_dna_gallery
##
## Output: <out>/{prop}_{N}_{label}.png + JSON + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)

const CAMERA_FOV: float = 32.0  # mild telephoto for clean prop silhouettes
const CAMERA_YAW: float = 0.55   # rad — 3/4 angle from the right
const CAMERA_PITCH: float = -0.30
## How many AABB diagonals to back the camera off by. Higher = more
## breathing room around the prop. 1.95 fits tall props (sliding_door
## at 3.7m) without clipping at 32° FOV.
const FRAME_PADDING: float = 1.95

var _output_dir: String = "user://props_dna_gallery"
## Public URL base for image paths in the manifest. Browsers resolve
## relative paths against the page URL, which strips the gallery slug
## off when the page route is at root — so we publish absolute paths.
const PUBLIC_BASE: String = "/props-dna-gallery"
var _entries: Array = []
## When non-empty (via --only=a,b,c), the sweep is filtered to just these props
## so a few new props can be (re)captured without re-rendering the whole gallery.
## The written manifest is then PARTIAL — merge it into the published one.
var _only_props: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


func _initialize() -> void:
	# Args after `--` land in get_cmdline_user_args(); scan both so --out / --only
	# work whether passed before or after the `--` separator.
	var all_args: Array = []
	all_args.append_array(OS.get_cmdline_args())
	all_args.append_array(OS.get_cmdline_user_args())
	for arg in all_args:
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
		elif arg.begins_with("--only="):
			_only_props = Array(arg.split("=")[1].split(","))
	_run.call_deferred()


func _run() -> void:
	# ── SubViewport — isolated World3D ──────────────────────────────
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	# ── Environment — neutral catalog backdrop ─────────────────────
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.15
	env.ssao_enabled = true
	env.ssao_intensity = 0.5
	env.ssao_radius = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.40
	env.glow_bloom = 0.12
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	# ── Three-light rig — key from camera side, fill opposite, rim above
	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.97, 0.92)  # warm white key
	key.rotation_degrees = Vector3(-35, 25, 0)
	key.shadow_enabled = true
	_viewport.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.light_color = Color(0.85, 0.90, 1.0)  # cool fill
	fill.rotation_degrees = Vector3(-15, -120, 0)
	_viewport.add_child(fill)

	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.60
	rim.light_color = Color(1.0, 1.0, 1.0)
	rim.rotation_degrees = Vector3(-80, 180, 0)
	_viewport.add_child(rim)

	# ── Camera ─────────────────────────────────────────────────────
	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	_camera.near = 0.02
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)

	# Holder for the currently-captured prop
	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep ──────────────────────────────────────────────────────
	var sweep: Array = _build_sweep()
	if not _only_props.is_empty():
		var filtered: Array = []
		for spec in sweep:
			if str(spec.get("prop", "")) in _only_props:
				filtered.append(spec)
		sweep = filtered
		print("FILTER — capturing only %d entries for props %s" % [sweep.size(), str(_only_props)])
	var index: int = 0
	for spec in sweep:
		index += 1
		var scene_path: String = spec["scene"]
		var packed: PackedScene = load(scene_path)
		if packed == null:
			push_error("Failed to load %s" % scene_path)
			continue
		var node: Node3D = packed.instantiate()
		var dna: Dictionary = spec.get("dna", {})
		# Apply DNA BEFORE _ready() runs (add_child triggers _ready).
		for prop in dna.keys():
			node.set(prop, dna[prop])
		# Some props (info_screen) have an internal -Z label orientation
		# that mirrors text when viewed from the +Z-side camera. Flag
		# such props with `rotation_y_180: true` so we spin the prop
		# 180° around Y at capture time. Cheap fix, no source change.
		if bool(spec.get("rotation_y_180", false)):
			node.rotation = Vector3(0.0, PI, 0.0)
		_scene_holder.add_child(node)
		# 0.4s — gives procedural artifacts that bake textures into
		# their materials at startup (fire_extinguisher's FIRE label
		# via commons/utils/baked_text_albedo.gd) enough process_frames
		# for the SubViewport bake to complete before camera framing +
		# capture run. Was 0.10s.
		await create_timer(0.4).timeout

		# Frame the camera from the prop's recursive AABB
		var aabb: AABB = _get_combined_aabb(node)
		if aabb.size.length() < 0.001:
			# fallback if AABB is empty (shouldn't happen for built props)
			aabb = AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
		var center: Vector3 = aabb.position + aabb.size * 0.5
		var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		var dist: float = max_dim * FRAME_PADDING + 0.5
		var offset := Vector3(
			sin(CAMERA_YAW) * cos(CAMERA_PITCH),
			-sin(CAMERA_PITCH),
			cos(CAMERA_YAW) * cos(CAMERA_PITCH)
		) * dist
		_camera.global_position = center + offset
		_camera.look_at(center, Vector3.UP)

		await _capture_and_record(spec, index, aabb)
		_clear_holder()
		await create_timer(0.05).timeout

	# ── Manifest ───────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Eight lab-prop artifacts × three DNA configurations each. Same .gd, same .tscn, three different expressions per row — proving the parametric DNA actually varies the form. Props: exit_sign, sliding_door, whiteboard, large_table, large_window, info_screen, ceiling_vent, cable_tray. Each row exercises the prop's critical_parameter (the @identity field that names what the DNA must vary).",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {
			"projection": "perspective",
			"fov_deg": CAMERA_FOV,
			"yaw_rad": CAMERA_YAW,
			"pitch_rad": CAMERA_PITCH,
			"framing": "AABB-orbit, %.2f×max_dim padding" % FRAME_PADDING,
		},
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


func _clear_holder() -> void:
	for child in _scene_holder.get_children():
		child.queue_free()


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
		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)
		if child is Node3D:
			var sub_aabb: AABB = _get_combined_aabb(child)
			if sub_aabb.size.length() > 0:
				# Propagate the child's local transform into parent space so
				# nested rotated/translated joints (e.g. robot_arm) contribute
				# their actual swept volume, not just their local AABB.
				sub_aabb = (child as Node3D).transform * sub_aabb
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)
	return result


func _capture_and_record(spec: Dictionary, index: int, aabb: AABB) -> void:
	# Two frames to settle the render target after the camera moved.
	await get_root().get_tree().process_frame
	await get_root().get_tree().process_frame

	var img: Image = _viewport.get_texture().get_image()
	var prop: String = spec["prop"]
	var variant: String = spec["variant_id"]
	var stem: String = "%s_%s" % [prop, variant]
	var png_path: String = "%s/%s.png" % [_output_dir, stem]
	img.save_png(png_path)

	# Serialize DNA to plain JSON (Color → "r,g,b,a")
	var dna_clean: Dictionary = {}
	for k in spec.get("dna", {}).keys():
		var v = spec["dna"][k]
		if v is Color:
			dna_clean[k] = "%.3f,%.3f,%.3f,%.3f" % [v.r, v.g, v.b, v.a]
		elif v is PackedColorArray:
			var s := PackedStringArray()
			for c in v:
				s.append("%.3f,%.3f,%.3f" % [c.r, c.g, c.b])
			dna_clean[k] = s
		elif v is PackedStringArray:
			dna_clean[k] = Array(v)
		else:
			dna_clean[k] = v

	var sidecar := {
		"id": stem,
		"prop": prop,
		"variant_id": variant,
		"label": spec.get("label", variant),
		"subtitle": spec.get("subtitle", ""),
		"notes": spec.get("notes", ""),
		"dna": dna_clean,
		"aabb_size": [aabb.size.x, aabb.size.y, aabb.size.z],
		"image": "%s/%s.png" % [PUBLIC_BASE, stem],
	}
	var sf := FileAccess.open("%s/%s.json" % [_output_dir, stem], FileAccess.WRITE)
	sf.store_string(JSON.stringify(sidecar, "\t"))
	sf.close()

	_entries.append({
		"id": stem,
		"index": index,
		"prop": prop,
		"variant_id": variant,
		"label": spec.get("label", variant),
		"subtitle": spec.get("subtitle", ""),
		"notes": spec.get("notes", ""),
		"image": "%s/%s.png" % [PUBLIC_BASE, stem],
		"config": "%s/%s.json" % [PUBLIC_BASE, stem],
		"dna": dna_clean,
	})
	print("[%2d] %s — %s saved (%dx%d, aabb %.2f×%.2f×%.2f)"
		% [index, prop, variant, CAPTURE_SIZE.x, CAPTURE_SIZE.y,
		   aabb.size.x, aabb.size.y, aabb.size.z])


# ── Sweep specification ──────────────────────────────────────────────
# 8 props × 3 variants. Each row exercises the prop's
# critical_parameter (named in its @identity block).

func _build_sweep() -> Array:
	var sweep: Array = []

	# ── CURATION STATION KIT (scenes live in commons/artifacts/station/) ──
	var FRAME_SCENE := {"scene": "res://commons/artifacts/station/station_frame.tscn"}
	var PLINTH_SCENE := {"scene": "res://commons/artifacts/station/station_plinth.tscn"}
	var PILLAR_SCENE := {"scene": "res://commons/artifacts/station/station_pillar.tscn"}

	# ── station_frame: critical_parameter = frame_width × frame_height + bar_style ──
	sweep.append(_p("station_frame", "1_open_threshold", "open threshold",
		"bare portal — two posts and a top ring, lit corner joints; pass through",
		{
			"frame_width": 2.0, "frame_height": 2.2, "frame_depth": 2.0,
			"bar_style": "open", "lit_joints": true,
			"body_color": Color(0.81, 0.79, 0.75),
			"accent_color": Color(0.902, 0.224, 0.275),
		}, FRAME_SCENE))
	sweep.append(_p("station_frame", "2_wide_paneled_billboard", "wide paneled billboard",
		"low broad proscenium — filled cells read as a screen/billboard frame",
		{
			"frame_width": 3.2, "frame_height": 1.8, "frame_depth": 2.0,
			"bar_style": "paneled", "lit_joints": false,
			"body_color": Color(0.78, 0.77, 0.74),
			"accent_color": Color(0.20, 0.55, 0.95),
		}, FRAME_SCENE))
	sweep.append(_p("station_frame", "3_tall_greebled_gate", "tall greebled gate",
		"tall narrow service portal — conduit stubs + gussets, no corner glow",
		{
			"frame_width": 1.4, "frame_height": 2.8, "frame_depth": 1.4,
			"bar_style": "greebled", "lit_joints": false,
			"body_color": Color(0.72, 0.71, 0.68),
			"accent_color": Color(0.86, 0.34, 0.11),
		}, FRAME_SCENE))

	# ── station_plinth: critical_parameter = width_cells × depth_cells + top_height ──
	sweep.append(_p("station_plinth", "1_tall_tray_specimen", "tall tray specimen",
		"1×1 high tray — a single precious thing at eye height, emerald accent",
		{
			"width_cells": 1, "depth_cells": 1, "top_height": 1.15,
			"top_style": "tray", "edge_light": true,
			"accent_color": Color(0.20, 0.80, 0.30),
		}, PLINTH_SCENE))
	sweep.append(_p("station_plinth", "2_low_flat_world", "low flat world",
		"3×3 low flat — a big broad thing set on a world, lambda crimson accent",
		{
			"width_cells": 3, "depth_cells": 3, "top_height": 0.45,
			"top_style": "flat", "edge_light": true,
			"accent_color": Color(0.902, 0.224, 0.275),
		}, PLINTH_SCENE))
	sweep.append(_p("station_plinth", "3_long_grate_lab", "long grate lab",
		"1×3 grate cap — a long thing laid across a serviced plinth, blue accent",
		{
			"width_cells": 1, "depth_cells": 3, "top_height": 0.9,
			"top_style": "grate", "edge_light": false,
			"accent_color": Color(0.20, 0.55, 0.95),
		}, PLINTH_SCENE))

	# ── station_pillar: critical_parameter = height + post_width ──
	sweep.append(_p("station_pillar", "1_tall_slim_lit", "tall slim lit",
		"2.8m slim shaft — lit accent groove, the powered corner column",
		{
			"height": 2.8, "post_width": 0.34, "lit_groove": true,
			"accent_color": Color(0.902, 0.224, 0.275),
		}, PILLAR_SCENE))
	sweep.append(_p("station_pillar", "2_short_heavy_plain", "short heavy plain",
		"1.8m heavy shaft — groove off, the squat unpowered structural pier",
		{
			"height": 1.8, "post_width": 0.7, "lit_groove": false,
			"accent_color": Color(0.86, 0.34, 0.11),
		}, PILLAR_SCENE))
	sweep.append(_p("station_pillar", "3_full_groove_emerald", "full groove emerald",
		"2.5m default-width shaft — emerald lit groove, the standard bay corner",
		{
			"height": 2.5, "post_width": 0.42, "lit_groove": true,
			"accent_color": Color(0.20, 0.80, 0.30),
		}, PILLAR_SCENE))

	# ── exit_sign: critical_parameter = sign_color ─────────────────
	sweep.append(_p("exit_sign", "1_green_exit_right", "green exit right",
		"the standard — emerald egress, arrow right",
		{
			"text": "EXIT",
			"arrow_direction": "right",
			"sign_color": Color(0.20, 0.80, 0.30),
			"glow_energy": 1.8,
		}))
	sweep.append(_p("exit_sign", "2_emergency_red_down", "emergency red down",
		"warning — crimson alarm, arrow pointing into the floor",
		{
			"text": "EMERGENCY",
			"arrow_direction": "down",
			"sign_color": Color(0.90, 0.20, 0.20),
			"width": 0.55,
			"glow_energy": 2.4,
		}))
	sweep.append(_p("exit_sign", "3_lambda_phase_left", "λ-S lab left",
		"phase-tinted — lambda_edge red as architectural belonging",
		{
			"text": "λ-S LAB",
			"arrow_direction": "left",
			"sign_color": Color(0.902, 0.224, 0.275),
			"glow_energy": 1.5,
		}))

	# ── sliding_door: critical_parameter = panels_open_amount ──────
	sweep.append(_p("sliding_door", "1_closed", "closed",
		"shut — the room is a sealed chamber",
		{
			"panels_open_amount": 0.0,
			"accent_color": Color(0.902, 0.224, 0.275),
		}))
	sweep.append(_p("sliding_door", "2_half_open", "half open",
		"the gesture — Portal-2 mid-action, the eye reads transition",
		{
			"panels_open_amount": 0.55,
			"accent_color": Color(0.20, 0.55, 0.95),
		}))
	sweep.append(_p("sliding_door", "3_fully_open", "fully open",
		"the room is reachable — full clearance",
		{
			"panels_open_amount": 1.0,
			"accent_color": Color(0.20, 0.80, 0.30),
		}))

	# ── whiteboard: critical_parameter = text_lines + colour ───────
	# text_size is an INT (Label3D font_size). Default 24; 28-32 read
	# at distance, 20 reads as small notes.
	sweep.append(_p("whiteboard", "1_lecture_calculus", "lecture: calculus",
		"the teaching board — four lines of FTC",
		{
			"text_lines": PackedStringArray([
				"Fundamental Theorem of Calculus",
				"  integral f(x) dx = F(b) - F(a)",
				"slope of the tangent <-> area",
				"the two halves of CHANGE",
			]),
			"text_color": Color(0.10, 0.10, 0.12),
			"text_size": 28,
		}))
	sweep.append(_p("whiteboard", "2_brainstorm_red", "brainstorm: red ink",
		"the brainstorm board — red marker, scattered thoughts",
		{
			"text_lines": PackedStringArray([
				"WHAT BREAKS HERE?",
				"  - lambda-S -> halting?",
				"  - count after commit = 8",
				"  - CLOSE THE LOOP",
			]),
			"text_color": Color(0.80, 0.10, 0.15),
			"text_size": 32,
		}))
	sweep.append(_p("whiteboard", "3_pristine_clean", "pristine: blank",
		"the empty board — the chamber before any session begins",
		{
			"text_lines": PackedStringArray([]),
			"text_color": Color(0.10, 0.10, 0.12),
			"text_size": 24,
		}))

	# ── large_table: critical_parameter = leg_style ────────────────
	sweep.append(_p("large_table", "1_post_office", "post: office",
		"four box legs — reads as moveable furniture",
		{
			"length": 1.8, "depth": 0.85, "height": 0.95,
			"leg_style": "post",
			"top_color": Color(0.92, 0.92, 0.94),
			"leg_color": Color(0.22, 0.22, 0.25),
			"accent_color": Color(0.20, 0.55, 0.95),
			"edge_strip": true,
		}))
	sweep.append(_p("large_table", "2_panel_institutional", "panel: institutional",
		"continuous side panels — reads as built-in lab counter",
		{
			"length": 2.4, "depth": 0.85, "height": 0.95,
			"leg_style": "panel",
			"top_color": Color(0.88, 0.88, 0.90),
			"leg_color": Color(0.18, 0.18, 0.22),
			"accent_color": Color(0.902, 0.224, 0.275),
			"edge_strip": true,
		}))
	sweep.append(_p("large_table", "3_conference_long", "conference: long",
		"long conference run — 3.6m, no edge strip, neutral",
		{
			"length": 3.6, "depth": 1.10, "height": 0.95,
			"leg_style": "panel",
			"top_color": Color(0.95, 0.95, 0.96),
			"leg_color": Color(0.30, 0.30, 0.32),
			"accent_color": Color(1.0, 1.0, 1.0),
			"edge_strip": false,
		}))

	# ── large_window: critical_parameter = glass_color / accent ────
	sweep.append(_p("large_window", "1_observation_lambda", "observation λ",
		"observation glass — lambda_edge crimson frame, faint blue tint",
		{
			"window_width": 2.4, "window_height": 1.6,
			"frame_color": Color(0.80, 0.82, 0.85),
			"glass_color": Color(0.65, 0.78, 0.88, 0.25),
			"accent_color": Color(0.902, 0.224, 0.275),
			"glass_emission": 0.10,
		}))
	sweep.append(_p("large_window", "2_skylight_atrium", "skylight: atrium",
		"daylight window — pale-yellow glass, generous opening, integration violet trim",
		{
			"window_width": 3.0, "window_height": 2.0,
			"frame_color": Color(0.92, 0.92, 0.94),
			"glass_color": Color(0.95, 0.92, 0.78, 0.30),
			"accent_color": Color(0.608, 0.365, 0.890),
			"glass_emission": 0.45,
		}))
	sweep.append(_p("large_window", "3_porthole_industrial", "porthole: industrial",
		"small dense window — green emergency glass, narrow frame",
		{
			"window_width": 0.9, "window_height": 0.9,
			"frame_color": Color(0.30, 0.30, 0.32),
			"glass_color": Color(0.40, 0.85, 0.55, 0.45),
			"accent_color": Color(0.20, 0.80, 0.30),
			"glass_emission": 0.20,
		}))

	# ── info_screen: critical_parameter = text content + colour ────
	# text_size is INT (Label3D font_size). Default 18.
	sweep.append(_p("info_screen", "1_terminal_green", "terminal: green",
		"classic phosphor — green text on dark, amber header",
		{
			"header_text": "L-S DIAGNOSTIC",
			"text_lines": PackedStringArray([
				"> shannon_workbench: ONLINE",
				"> H(p) = 0.918 bits/symbol",
				"> p = 0.62",
				"> READY",
			]),
			"text_color": Color(0.45, 0.95, 0.55),
			"header_color": Color(0.95, 0.72, 0.30),
			"text_size": 18,
		}))
	sweep.append(_p("info_screen", "2_warning_red", "warning: red",
		"alarm state — red text, urgent header",
		{
			"header_text": "!! HALT DETECTED !!",
			"text_lines": PackedStringArray([
				"program: collatz_runner.gd",
				"input: 27",
				"steps: 111",
				"status: HALTED at 1",
			]),
			"text_color": Color(0.95, 0.30, 0.32),
			"header_color": Color(1.0, 0.40, 0.40),
			"text_size": 20,
		}))
	sweep.append(_p("info_screen", "3_amber_civic", "amber: civic",
		"civic dashboard — amber on neutral, calmer cadence",
		{
			"header_text": "ROOM STATUS",
			"text_lines": PackedStringArray([
				"chamber: Shannon Lab",
				"occupant: 1",
				"temp: 22 C",
				"session: 47 min",
			]),
			"text_color": Color(0.95, 0.72, 0.30),
			"header_color": Color(1.0, 1.0, 1.0),
			"text_size": 22,
		}))

	# ── ceiling_vent: critical_parameter = slat_count + airflow ────
	sweep.append(_p("ceiling_vent", "1_quiet_few_slats", "quiet: 6 slats",
		"few wide slats — reads as residential return air, calm",
		{
			"vent_length": 0.9, "vent_width": 0.45,
			"slat_count": 6,
			"airflow_glow": 0.0,
			"frame_color": Color(0.85, 0.85, 0.87),
		}))
	sweep.append(_p("ceiling_vent", "2_active_many_slats", "active: 16 slats",
		"dense slats with cool airflow glow — the chamber is breathing",
		{
			"vent_length": 1.2, "vent_width": 0.6,
			"slat_count": 16,
			"airflow_glow": 0.65,
			"airflow_color": Color(0.65, 0.85, 1.0),
			"frame_color": Color(0.55, 0.58, 0.62),
		}))
	sweep.append(_p("ceiling_vent", "3_hot_warning_glow", "hot: warning glow",
		"institutional-dark vent with red airflow — the heat exhaust on a running rig",
		{
			"vent_length": 1.4, "vent_width": 0.5,
			"slat_count": 12,
			"airflow_glow": 0.9,
			"airflow_color": Color(1.0, 0.40, 0.30),
			"frame_color": Color(0.25, 0.25, 0.27),
		}))

	# ── cable_tray: critical_parameter = cable_count + colour set ──
	sweep.append(_p("cable_tray", "1_sparse_neutral", "sparse: 3 cables",
		"three cables — the bare minimum, neutral palette",
		{
			"tray_length": 1.8, "tray_width": 0.16, "tray_height": 0.06,
			"rung_count": 6,
			"cable_count": 3,
			"tray_color": Color(0.65, 0.65, 0.68),
			"cable_colors": PackedColorArray([
				Color(0.20, 0.20, 0.22),
				Color(0.55, 0.55, 0.60),
				Color(0.85, 0.85, 0.88),
			]),
		}))
	sweep.append(_p("cable_tray", "2_full_phase_palette", "full: 7 cables, QFEP palette",
		"seven cables in the QFEP colour set — the whole spine in one tray",
		{
			"tray_length": 2.4, "tray_width": 0.20, "tray_height": 0.07,
			"rung_count": 8,
			"cable_count": 7,
			"tray_color": Color(0.35, 0.35, 0.38),
			"cable_colors": PackedColorArray([
				Color(0.227, 0.482, 1.0),     # F_order blue
				Color(0.490, 1.0, 0.659),     # oscillation green
				Color(0.957, 0.635, 0.380),   # E_entropy orange
				Color(0.902, 0.224, 0.275),   # lambda_edge red
				Color(0.608, 0.365, 0.890),   # integration violet
				Color(0.984, 0.890, 0.541),   # relation yellow
				Color(1.0, 1.0, 1.0),         # synthesis white
			]),
		}))
	sweep.append(_p("cable_tray", "3_overhead_dense", "overhead: 10 cables",
		"dense run — ten cables, dark tray, the ceiling of a server bay",
		{
			"tray_length": 3.0, "tray_width": 0.22, "tray_height": 0.08,
			"rung_count": 10,
			"cable_count": 10,
			"tray_color": Color(0.18, 0.18, 0.20),
			"cable_colors": PackedColorArray([
				Color(0.85, 0.20, 0.20),
				Color(0.30, 0.55, 0.95),
				Color(0.30, 0.85, 0.45),
				Color(0.95, 0.85, 0.30),
				Color(0.65, 0.35, 0.85),
				Color(0.20, 0.20, 0.22),
				Color(0.55, 0.55, 0.60),
				Color(0.85, 0.85, 0.88),
				Color(0.95, 0.45, 0.20),
				Color(0.20, 0.85, 0.95),
			]),
		}))

	# ── lab_stool: critical_parameter = base_style ─────────────────
	sweep.append(_p("lab_stool", "1_five_star_post", "five-star post",
		"the lab default — gas piston on 5-star caster base",
		{
			"seat_height": 0.65,
			"seat_radius": 0.18,
			"base_style": "five_star",
			"base_radius": 0.32,
			"seat_color": Color(0.08, 0.08, 0.10),
			"accent_color": Color(0.95, 0.55, 0.0),
			"accent_strip": true,
		}))
	sweep.append(_p("lab_stool", "2_ring_base", "ring base",
		"institutional — fixed-height ring base, no swivel",
		{
			"seat_height": 0.78,
			"seat_radius": 0.20,
			"base_style": "ring",
			"base_radius": 0.36,
			"seat_color": Color(0.30, 0.30, 0.32),
			"accent_color": Color(0.20, 0.55, 0.95),
			"accent_strip": true,
		}))
	sweep.append(_p("lab_stool", "3_low_padded", "low padded",
		"the soft option — short, broad, no accent strip",
		{
			"seat_height": 0.45,
			"seat_radius": 0.22,
			"base_style": "five_star",
			"base_radius": 0.30,
			"seat_color": Color(0.85, 0.85, 0.88),
			"accent_color": Color(0.95, 0.55, 0.0),
			"accent_strip": false,
		}))

	# ── fume_hood: critical_parameter = sash_open_amount ───────────
	sweep.append(_p("fume_hood", "1_closed", "closed",
		"sash down — the chamber is sealed for active work",
		{
			"hood_width": 1.6, "hood_height": 2.1, "hood_depth": 0.7,
			"sash_open_amount": 0.0,
			"accent_color": Color(0.95, 0.55, 0.0),
			"interior_light": true,
		}))
	sweep.append(_p("fume_hood", "2_half_open", "half open",
		"the gesture — mid-work, hands inside, sash at chest height",
		{
			"hood_width": 1.6, "hood_height": 2.1, "hood_depth": 0.7,
			"sash_open_amount": 0.55,
			"accent_color": Color(0.902, 0.224, 0.275),
			"interior_light": true,
		}))
	sweep.append(_p("fume_hood", "3_lights_off", "lights off",
		"dormant — sash open, interior unlit, between sessions",
		{
			"hood_width": 1.8, "hood_height": 2.1, "hood_depth": 0.7,
			"sash_open_amount": 1.0,
			"accent_color": Color(0.20, 0.55, 0.95),
			"interior_light": false,
		}))

	# ── server_rack: critical_parameter = door_open + led density ──
	sweep.append(_p("server_rack", "1_door_closed", "door closed",
		"front face only — solid panel, single accent strip",
		{
			"rack_height_u": 24,
			"server_count": 6,
			"led_density": 4,
			"door_open": false,
			"led_color": Color(0.20, 0.95, 0.45),
			"accent_color": Color(0.95, 0.55, 0.0),
		}))
	sweep.append(_p("server_rack", "2_door_open", "door open: interior",
		"servers visible — 8 units with green LEDs, blinkenlights",
		{
			"rack_height_u": 32,
			"server_count": 8,
			"led_density": 6,
			"door_open": true,
			"led_color": Color(0.20, 0.95, 0.45),
			"accent_color": Color(0.95, 0.55, 0.0),
		}))
	sweep.append(_p("server_rack", "3_alarm_amber", "alarm: amber",
		"warning state — amber LEDs, fewer servers, taller rack",
		{
			"rack_height_u": 42,
			"server_count": 4,
			"led_density": 8,
			"door_open": true,
			"led_color": Color(0.95, 0.65, 0.20),
			"accent_color": Color(0.902, 0.224, 0.275),
		}))

	# ── emergency_button: critical_parameter = pressed + mounting ──
	sweep.append(_p("emergency_button", "1_ready_wall", "ready: wall",
		"the canonical E-stop — armed, glowing, wall mounted",
		{
			"pressed": false,
			"mounting": "wall",
			"label_text": "EMERGENCY STOP",
			"button_color": Color(0.95, 0.10, 0.10),
			"plate_color": Color(0.98, 0.85, 0.10),
		}))
	sweep.append(_p("emergency_button", "2_pressed", "pressed: latched",
		"the lab is halted — button depressed, signal sent",
		{
			"pressed": true,
			"mounting": "wall",
			"label_text": "HALTED",
			"button_color": Color(0.55, 0.10, 0.10),
			"plate_color": Color(0.98, 0.85, 0.10),
		}))
	sweep.append(_p("emergency_button", "3_podium_blue", "podium: blue",
		"non-alarm action button — blue dome on dark plate, podium stand",
		{
			"pressed": false,
			"mounting": "podium",
			"label_text": "INITIATE",
			"button_color": Color(0.20, 0.55, 0.95),
			"plate_color": Color(0.22, 0.22, 0.25),
			"text_color": Color(0.85, 0.85, 0.88),
		}))

	# ── conveyor_belt: critical_parameter = belt_length + arrow_count
	sweep.append(_p("conveyor_belt", "1_short_quiet", "short, quiet",
		"a short transfer — 1.2m belt with 3 arrows",
		{
			"belt_length": 1.2,
			"belt_width": 0.6,
			"direction_arrow_count": 3,
			"support_legs": 2,
			"belt_color": Color(0.10, 0.10, 0.11),
			"accent_color": Color(0.95, 0.55, 0.0),
			"arrow_color": Color(0.95, 0.55, 0.0),
		}))
	sweep.append(_p("conveyor_belt", "2_canonical", "canonical Aperture",
		"Portal-2 baseline — 2.4m belt, 5 arrows, 4 legs",
		{
			"belt_length": 2.4,
			"belt_width": 0.6,
			"direction_arrow_count": 5,
			"support_legs": 4,
			"belt_color": Color(0.10, 0.10, 0.11),
			"accent_color": Color(0.95, 0.55, 0.0),
			"arrow_color": Color(0.95, 0.55, 0.0),
		}))
	sweep.append(_p("conveyor_belt", "3_freight_wide", "freight: wide",
		"freight run — 4m belt, 1m wide, dense arrows, 6 legs",
		{
			"belt_length": 4.0,
			"belt_width": 1.0,
			"direction_arrow_count": 9,
			"support_legs": 6,
			"belt_color": Color(0.18, 0.18, 0.20),
			"accent_color": Color(0.20, 0.55, 0.95),
			"arrow_color": Color(0.20, 0.55, 0.95),
		}))

	# ── safety_shower: critical_parameter = pipe_orientation ───────
	sweep.append(_p("safety_shower", "1_wall_canonical", "wall canonical",
		"standard wall mount — pipe from the wall, chain visible",
		{
			"shower_height": 2.2,
			"pipe_orientation": "wall",
			"chain_visible": true,
			"signage_text": "SAFETY SHOWER",
			"accent_color": Color(0.15, 0.65, 0.25),
		}))
	sweep.append(_p("safety_shower", "2_ceiling_central", "ceiling central",
		"the centre-of-room emergency drop — pipe descends from above",
		{
			"shower_height": 2.4,
			"pipe_orientation": "ceiling",
			"chain_visible": true,
			"signage_text": "EMERGENCY WASH",
			"accent_color": Color(0.902, 0.224, 0.275),
		}))
	sweep.append(_p("safety_shower", "3_no_chain", "no chain: lever only",
		"silent rig — chain hidden, lever-actuated valve only",
		{
			"shower_height": 2.2,
			"pipe_orientation": "wall",
			"chain_visible": false,
			"signage_text": "EYE WASH STATION",
			"accent_color": Color(0.15, 0.65, 0.25),
		}))

	# ── microscope: critical_parameter = eyepiece + objective count
	sweep.append(_p("microscope", "1_binocular_standard", "binocular standard",
		"the canonical bench microscope — 2 eyepieces, 4 objectives",
		{
			"body_height": 0.38,
			"eyepiece_count": 2,
			"objective_count": 4,
			"light_on": true,
			"light_color": Color(1.0, 0.92, 0.78),
			"accent_color": Color(0.95, 0.55, 0.0),
		}))
	sweep.append(_p("microscope", "2_monocular_compact", "monocular compact",
		"single eyepiece — school-lab geometry, smaller body",
		{
			"body_height": 0.30,
			"eyepiece_count": 1,
			"objective_count": 3,
			"light_on": true,
			"light_color": Color(1.0, 0.92, 0.78),
			"accent_color": Color(0.20, 0.55, 0.95),
		}))
	sweep.append(_p("microscope", "3_research_six_objective", "research: 6-objective",
		"research-grade — 6-position turret, larger body, lamp off",
		{
			"body_height": 0.46,
			"eyepiece_count": 2,
			"objective_count": 6,
			"light_on": false,
			"accent_color": Color(0.902, 0.224, 0.275),
		}))

	# ── specimen_jar: critical_parameter = content_shape ───────────
	sweep.append(_p("specimen_jar", "1_blob_emerald", "blob: emerald",
		"the canonical specimen — emerald blob, hazard amber label",
		{
			"jar_height": 0.55,
			"content_shape": "blob",
			"content_color": Color(0.40, 0.85, 0.55, 0.85),
			"content_glow": 0.8,
			"label_text": "SPECIMEN λ-S/Δ",
			"label_color": Color(0.95, 0.70, 0.20),
		}))
	sweep.append(_p("specimen_jar", "2_tendrils", "tendrils: violet",
		"tendrils — radiating violet rods, the cellular specimen",
		{
			"jar_height": 0.70,
			"content_shape": "tendrils",
			"content_color": Color(0.65, 0.35, 0.90, 0.85),
			"content_glow": 1.2,
			"label_text": "SPECIMEN φ-Q/T",
			"label_color": Color(0.85, 0.85, 0.88),
		}))
	sweep.append(_p("specimen_jar", "3_empty_blue", "empty: blue light",
		"the empty jar — no content, faint blue interior glow",
		{
			"jar_height": 0.45,
			"content_shape": "empty",
			"content_color": Color(0.20, 0.55, 0.95, 0.85),
			"content_glow": 0.4,
			"label_text": "SPECIMEN F-01",
			"label_color": Color(0.20, 0.55, 0.95),
		}))

	# ── fire_extinguisher: critical_parameter = wall_bracket + hose
	sweep.append(_p("fire_extinguisher", "1_wall_mounted_full", "wall mounted, full",
		"the canonical extinguisher — bracket on the wall, hose coiled, white label",
		{
			"wall_bracket": true,
			"hose_visible": true,
			"label_text": "FIRE",
			"body_color": Color(0.78, 0.08, 0.08),
		}))
	sweep.append(_p("fire_extinguisher", "2_freestanding", "freestanding, no hose",
		"the bare can — no bracket, no hose, just the cylinder",
		{
			"wall_bracket": false,
			"hose_visible": false,
			"label_text": "CO₂",
			"body_color": Color(0.18, 0.18, 0.22),
		}))
	sweep.append(_p("fire_extinguisher", "3_yellow_dry", "yellow dry chemical",
		"hazard yellow — dry chemical class D for metal fires",
		{
			"wall_bracket": true,
			"hose_visible": true,
			"label_text": "DRY",
			"body_color": Color(0.98, 0.78, 0.12),
			"label_color": Color(0.10, 0.10, 0.12),
		}))

	# ── test_tube_rack: critical_parameter = tube_content_count ────
	sweep.append(_p("test_tube_rack", "1_empty_setup", "empty (setup)",
		"pre-experiment — six tubes, all empty, the rack as setup",
		{
			"tube_count": 6,
			"tube_content_count": 0,
			"content_color": Color(0.45, 0.85, 0.35, 0.92),
			"rack_color": Color(0.78, 0.62, 0.42),
		}))
	sweep.append(_p("test_tube_rack", "2_partial_progress", "partial (in progress)",
		"mid-run — 4 of 8 tubes filled, halfway through the assay",
		{
			"tube_count": 8,
			"tube_content_count": 4,
			"content_color": Color(0.85, 0.35, 0.55, 0.92),
			"rack_color": Color(0.30, 0.30, 0.35),
		}))
	sweep.append(_p("test_tube_rack", "3_full_complete", "full (complete)",
		"finished run — all 12 tubes filled with deep amber, ready for analysis",
		{
			"tube_count": 12,
			"tube_content_count": 12,
			"content_color": Color(0.92, 0.72, 0.30, 0.92),
			"rack_color": Color(0.20, 0.20, 0.22),
		}))

	# ── gas_canister: critical_parameter = cradle_style ────────────
	sweep.append(_p("gas_canister", "1_vertical_oxygen", "vertical: O₂",
		"the at-the-ready position — oxygen, upright in vertical cradle",
		{
			"cradle_style": "vertical",
			"label_text": "O₂",
			"body_color": Color(0.94, 0.94, 0.95),
			"pressure_indicator": true,
			"pressure_color": Color(0.30, 0.85, 0.40),
		}))
	sweep.append(_p("gas_canister", "2_horizontal_argon", "horizontal: Ar",
		"in-reserve — argon, lying in horizontal cradle, depressurised",
		{
			"cradle_style": "horizontal",
			"label_text": "Ar",
			"body_color": Color(0.55, 0.45, 0.75),
			"pressure_indicator": false,
		}))
	sweep.append(_p("gas_canister", "3_vertical_nitrogen_red", "vertical: N₂ (alarm)",
		"warning state — nitrogen with red pressure indicator (over-pressure)",
		{
			"cradle_style": "vertical",
			"label_text": "N₂",
			"body_color": Color(0.20, 0.30, 0.45),
			"pressure_indicator": true,
			"pressure_color": Color(0.95, 0.20, 0.20),
		}))

	# ── palm_scanner: critical_parameter = scan_active + mounting ──
	sweep.append(_p("palm_scanner", "1_active_wall", "active: wall",
		"checkpoint armed — emerald scan window lit, wall mounted",
		{
			"scan_active": true,
			"mounting": "wall",
			"label_text": "PLACE HAND",
			"scan_color": Color(0.25, 0.92, 0.45),
		}))
	sweep.append(_p("palm_scanner", "2_locked_dark", "locked: dark",
		"system inactive — scan window dark, red status LED",
		{
			"scan_active": false,
			"mounting": "wall",
			"label_text": "ACCESS DENIED",
			"scan_color": Color(0.95, 0.20, 0.20),
		}))
	sweep.append(_p("palm_scanner", "3_active_podium", "active: podium",
		"the lectern reader — scan armed, podium-mounted (entry to test chamber)",
		{
			"scan_active": true,
			"mounting": "podium",
			"label_text": "AUTHORISE",
			"scan_color": Color(0.20, 0.55, 0.95),
			"accent_color": Color(0.20, 0.55, 0.95),
		}))

	# ── robot_arm: critical_parameter = pose_angles_degrees ────────
	sweep.append(_p("robot_arm", "1_pose_idle", "pose: idle",
		"the arm at rest — all joints near zero, gripper open",
		{
			"arm_segment_count": 3,
			"pose_angles_degrees": PackedFloat32Array([0.0, -10.0, 15.0, -5.0]),
			"gripper_visible": true,
			"accent_color": Color(1.0, 0.45, 0.10),
		}))
	sweep.append(_p("robot_arm", "2_pose_reaching", "pose: reaching",
		"mid-action — joints bent, the arm extending forward",
		{
			"arm_segment_count": 3,
			"pose_angles_degrees": PackedFloat32Array([35.0, -50.0, 85.0, -55.0]),
			"gripper_visible": true,
			"accent_color": Color(0.902, 0.224, 0.275),
		}))
	sweep.append(_p("robot_arm", "3_pose_parked", "pose: parked",
		"end-of-shift — arm folded tight against base, no gripper",
		{
			"arm_segment_count": 4,
			"pose_angles_degrees": PackedFloat32Array([0.0, -90.0, 95.0, -10.0, -45.0]),
			"gripper_visible": false,
			"accent_color": Color(0.40, 0.40, 0.42),
		}))

	# ── glove_box: critical_parameter = glove_count ────────────────
	sweep.append(_p("glove_box", "1_single_glove", "single glove",
		"surgical isolation — one glove port, the precision station",
		{
			"glove_count": 1,
			"box_width": 0.7,
			"interior_light": true,
			"legs_visible": true,
			"accent_color": Color(0.20, 0.55, 0.95),
		}))
	sweep.append(_p("glove_box", "2_two_glove_canonical", "two glove canonical",
		"the standard — two gloves for two hands, the canonical chamber",
		{
			"glove_count": 2,
			"box_width": 1.0,
			"interior_light": true,
			"legs_visible": true,
			"accent_color": Color(1.0, 0.45, 0.10),
		}))
	sweep.append(_p("glove_box", "3_three_glove_collaborative", "three glove collaborative",
		"two operators — three gloves, wider box, collaborative work",
		{
			"glove_count": 3,
			"box_width": 1.4,
			"interior_light": true,
			"legs_visible": true,
			"accent_color": Color(0.902, 0.224, 0.275),
		}))

	# ── autoclave: critical_parameter = door_open ──────────────────
	sweep.append(_p("autoclave", "1_active_cycle", "active cycle (door closed)",
		"sealed and running — green status, door shut, sterilization in progress",
		{
			"door_open": false,
			"status_indicator": true,
			"status_color": Color(0.30, 0.85, 0.40),
			"accent_color": Color(0.95, 0.50, 0.10),
		}))
	sweep.append(_p("autoclave", "2_between_uses_open", "between uses (door open)",
		"door pivoted open — interior visible, ready for next load",
		{
			"door_open": true,
			"status_indicator": false,
			"accent_color": Color(0.95, 0.50, 0.10),
		}))
	sweep.append(_p("autoclave", "3_alarm_red", "alarm: cycle fault",
		"red status — sterilization cycle interrupted, attention required",
		{
			"door_open": false,
			"status_indicator": true,
			"status_color": Color(0.95, 0.20, 0.20),
			"accent_color": Color(0.902, 0.224, 0.275),
		}))

	# ── chemistry_flask: critical_parameter = flask_shape ──────────
	sweep.append(_p("chemistry_flask", "1_erlenmeyer_working", "Erlenmeyer (working)",
		"swirl-and-react geometry — the canonical chemistry working flask",
		{
			"flask_shape": "erlenmeyer",
			"flask_height": 0.20,
			"content_height_fraction": 0.55,
			"content_color": Color(0.30, 0.85, 0.55, 0.85),
			"label_text": "H₂SO₄",
			"has_stopper": true,
		}))
	sweep.append(_p("chemistry_flask", "2_round_bottom_heated", "round-bottom (heated)",
		"uniform stress under flame — the flask designed to be set on fire",
		{
			"flask_shape": "round_bottom",
			"flask_height": 0.22,
			"content_height_fraction": 0.45,
			"content_color": Color(0.95, 0.35, 0.30, 0.85),
			"label_text": "C₆H₆",
			"has_stopper": false,
		}))
	sweep.append(_p("chemistry_flask", "3_volumetric_measured", "volumetric (measured)",
		"precision stoichiometry — bulb at the bottom, calibrated neck",
		{
			"flask_shape": "volumetric",
			"flask_height": 0.24,
			"content_height_fraction": 0.85,
			"content_color": Color(0.45, 0.65, 0.95, 0.85),
			"label_text": "100mL",
			"has_stopper": true,
		}))

	# ── clamp_stand: critical_parameter = clamp_count ──────────────
	sweep.append(_p("clamp_stand", "1_inert_zero", "inert (0 clamps)",
		"furniture state — pole and base, nothing held, awaiting choreography",
		{
			"clamp_count": 0,
			"holding_flask": false,
			"accent_color": Color(0.95, 0.50, 0.10),
		}))
	sweep.append(_p("clamp_stand", "2_focused_one", "focused (1 clamp)",
		"single experiment — one clamp at chest height, the active grip",
		{
			"clamp_count": 1,
			"holding_flask": true,
			"accent_color": Color(0.95, 0.50, 0.10),
		}))
	sweep.append(_p("clamp_stand", "3_layered_three", "layered (3 clamps)",
		"distillation choreography — three clamps stacked, the apparatus full",
		{
			"clamp_count": 3,
			"holding_flask": true,
			"accent_color": Color(0.902, 0.224, 0.275),
		}))

	# ── iv_stand: critical_parameter = bag_visible ─────────────────
	sweep.append(_p("iv_stand", "1_in_use_amber", "in-use (amber)",
		"hooked to a patient — full amber bag at 75%, delivering",
		{
			"bag_visible": true,
			"bag_full_fraction": 0.75,
			"bag_content_color": Color(0.95, 0.80, 0.45, 0.92),
			"label_text": "IV",
		}))
	sweep.append(_p("iv_stand", "2_in_use_almost_empty", "in-use (almost empty)",
		"nearly done — bag at 15%, the drip is finishing",
		{
			"bag_visible": true,
			"bag_full_fraction": 0.15,
			"bag_content_color": Color(0.85, 0.40, 0.50, 0.92),
			"label_text": "ANTI-BIOT",
		}))
	sweep.append(_p("iv_stand", "3_staged_no_bag", "staged (no bag)",
		"pole only — empty hook, parked between patients",
		{
			"bag_visible": false,
			"label_text": "",
		}))

	# ── lab_sink: critical_parameter = faucet_style ────────────────
	sweep.append(_p("lab_sink", "1_swan_biology", "swan-neck (biology)",
		"swan-neck faucet — wet-lab vocabulary, biology bench cleaning",
		{
			"faucet_style": "swan_neck",
			"water_running": false,
			"eyewash_present": false,
			"accent_color": Color(0.95, 0.50, 0.10),
		}))
	sweep.append(_p("lab_sink", "2_industrial_running", "industrial (running)",
		"industrial straight spout — water on, the utility room mode",
		{
			"faucet_style": "industrial",
			"water_running": true,
			"eyewash_present": false,
			"accent_color": Color(0.20, 0.55, 0.95),
		}))
	sweep.append(_p("lab_sink", "3_with_eyewash", "with eyewash",
		"safety variant — eyewash twin-spouts beside the main faucet",
		{
			"faucet_style": "swan_neck",
			"water_running": false,
			"eyewash_present": true,
			"accent_color": Color(0.15, 0.65, 0.25),
		}))

	# ── vacuum_chamber: critical_parameter = pressure_status ───────
	sweep.append(_p("vacuum_chamber", "1_vacuum_specimen", "vacuum (specimen)",
		"vacuum drawn — green needle, faint blue glow, specimen floating",
		{
			"pressure_status": "vacuum",
			"specimen_visible": true,
			"specimen_color": Color(0.40, 0.85, 0.55, 0.92),
			"interior_glow": 0.6,
			"accent_color": Color(0.20, 0.55, 0.95),
		}))
	sweep.append(_p("vacuum_chamber", "2_atmospheric_empty", "atmospheric (empty)",
		"at atmospheric pressure — white needle, dim interior, no specimen",
		{
			"pressure_status": "atmospheric",
			"specimen_visible": false,
			"interior_glow": 0.2,
			"accent_color": Color(0.85, 0.85, 0.85),
		}))
	sweep.append(_p("vacuum_chamber", "3_over_alarm", "over-pressure (alarm)",
		"warning — red needle, red interior glow, specimen visible (caged)",
		{
			"pressure_status": "over",
			"specimen_visible": true,
			"specimen_color": Color(0.95, 0.30, 0.20, 0.92),
			"interior_glow": 1.4,
			"interior_color": Color(1.0, 0.55, 0.45),
			"accent_color": Color(0.902, 0.224, 0.275),
		}))

	# ── electrical_panel: critical_parameter = door_open ───────────
	sweep.append(_p("electrical_panel", "1_secured_closed", "secured (closed)",
		"door shut — production-mode, status LEDs all green",
		{
			"door_open": false,
			"breakers_on_count": 12,
			"breaker_count": 12,
			"signage_text": "MAIN PANEL",
			"accent_color": Color(0.98, 0.78, 0.12),
		}))
	sweep.append(_p("electrical_panel", "2_maintenance_open", "maintenance (open)",
		"door open — breaker grid visible, most levers up, in inspection",
		{
			"door_open": true,
			"breakers_on_count": 9,
			"breaker_count": 12,
			"signage_text": "MAIN PANEL",
			"status_color": Color(0.30, 0.85, 0.40),
		}))
	sweep.append(_p("electrical_panel", "3_fault_partial", "fault (partial)",
		"emergency — only 4 of 16 breakers on, status LEDs red",
		{
			"door_open": true,
			"breakers_on_count": 4,
			"breaker_count": 16,
			"signage_text": "FAULT",
			"status_color": Color(0.95, 0.20, 0.20),
			"signage_color": Color(0.95, 0.20, 0.20),
		}))

	# ── floor_grate: critical_parameter = wear_factor ──────────────
	sweep.append(_p("floor_grate", "1_new_install", "new install (clean)",
		"freshly installed — uniform dark steel, no wear",
		{
			"wear_factor": 0.0,
			"accent_visible": false,
			"bar_count_x": 8,
			"bar_count_z": 8,
		}))
	sweep.append(_p("floor_grate", "2_used_mottled", "used (mottled)",
		"alternating brightness — the lab has remembered traffic patterns",
		{
			"wear_factor": 0.6,
			"accent_visible": false,
			"bar_count_x": 10,
			"bar_count_z": 10,
		}))
	sweep.append(_p("floor_grate", "3_hazard_safety", "hazard safety",
		"safety stripe — Portal-orange front edge marks the safe approach",
		{
			"wear_factor": 0.3,
			"accent_visible": true,
			"bar_count_x": 10,
			"bar_count_z": 12,
		}))

	# ── oscilloscope: critical_parameter = waveform_shape (Fourier)
	sweep.append(_p("oscilloscope", "1_sine_fundamental", "sine (fundamental)",
		"pure sine — the Fourier basis function, one frequency only",
		{
			"waveform_shape": "sine",
			"waveform_frequency": 3,
			"waveform_color": Color(0.40, 0.95, 0.55),
			"grid_visible": true,
		}))
	sweep.append(_p("oscilloscope", "2_square_harmonics", "square (odd harmonics)",
		"square wave — the discontinuous limit; Gibbs-phenomenon territory",
		{
			"waveform_shape": "square",
			"waveform_frequency": 3,
			"waveform_color": Color(0.95, 0.65, 0.30),
			"grid_visible": true,
		}))
	sweep.append(_p("oscilloscope", "3_composite_series", "composite (truncated series)",
		"sin(f) + sin(3f)/3 + sin(5f)/5 — the visible Fourier decomposition",
		{
			"waveform_shape": "composite",
			"waveform_frequency": 2,
			"waveform_color": Color(0.20, 0.55, 0.95),
			"grid_visible": true,
		}))

	# ── bunsen_burner: critical_parameter = flame_color (T) ────────
	sweep.append(_p("bunsen_burner", "1_cool_blue_ground", "cool blue (T→0)",
		"the ground state — pure blue flame, minimum-energy convergence",
		{
			"flame_color": Color(0.30, 0.55, 1.0),
			"flame_height": 0.10,
			"valve_position": "low",
		}))
	sweep.append(_p("bunsen_burner", "2_hot_orange_exploration", "hot orange (T high)",
		"high-T exploration — orange flame, escape from local minima",
		{
			"flame_color": Color(1.0, 0.55, 0.20),
			"flame_height": 0.18,
			"valve_position": "full",
		}))
	sweep.append(_p("bunsen_burner", "3_closed_no_flame", "closed (T = 0, no flame)",
		"the schedule completed — valve closed, no flame, system frozen",
		{
			"flame_visible": false,
			"valve_position": "closed",
		}))

	# ── petri_dish: critical_parameter = cell_pattern ──────────────
	sweep.append(_p("petri_dish", "1_glider_traveler", "glider (the traveller)",
		"the moving period-4 pattern — proves Life is non-trivial",
		{
			"cell_pattern": "glider",
			"lid_present": true,
			"cell_color": Color(0.20, 0.45, 0.20),
		}))
	sweep.append(_p("petri_dish", "2_blinker_oscillator", "blinker (oscillator)",
		"the period-2 oscillator — the simplest non-static pattern",
		{
			"cell_pattern": "blinker",
			"lid_present": false,
			"cell_color": Color(0.95, 0.20, 0.20),
		}))
	sweep.append(_p("petri_dish", "3_random_chaos", "random (chaos)",
		"random initial condition — the substrate before the rules take over",
		{
			"cell_pattern": "random",
			"colony_density": 0.30,
			"lid_present": true,
			"cell_color": Color(0.30, 0.30, 0.65),
			"grid_visible": true,
		}))

	# ── wall_clock: critical_parameter = is_digital + hands ────────
	sweep.append(_p("wall_clock", "1_analog_three_oclock", "analog (3 o'clock)",
		"classic analog — synchronization by shared rotation, no electronics",
		{
			"is_digital": false,
			"hour_hand_angle": 90.0,
			"minute_hand_angle": 0.0,
			"second_hand_angle": 270.0,
		}))
	sweep.append(_p("wall_clock", "2_analog_quarter_past", "analog (quarter past)",
			"the scheduler tick — minute hand at +15, the regular interrupt",
			{
				"is_digital": false,
				"hour_hand_angle": 7.5,
				"minute_hand_angle": 90.0,
				"second_hand_angle": 30.0,
			}))
	sweep.append(_p("wall_clock", "3_digital_alarm", "digital (alarm)",
		"digital readout — the wall-time precision; no hands, just bits",
		{
			"is_digital": true,
			"digital_time_text": "23:59:54",
			"digital_color": Color(0.95, 0.20, 0.20),
		}))

	# ── probability_box: critical_parameter = arrangement (sampling)
	sweep.append(_p("probability_box", "1_scattered_iid", "scattered (i.i.d.)",
		"the canonical Monte Carlo sample — 5 dice, random arrangement",
		{
			"dice_count": 5,
			"arrangement": "scattered",
			"face_values": PackedInt32Array([6, 4, 2, 5, 3]),
		}))
	sweep.append(_p("probability_box", "2_row_ordered", "row (ordered)",
		"the ordered sample — same 5 dice in a row, every face shown",
		{
			"dice_count": 6,
			"arrangement": "row",
			"face_values": PackedInt32Array([1, 2, 3, 4, 5, 6]),
		}))
	sweep.append(_p("probability_box", "3_cluster_dependent", "cluster (correlated)",
		"the correlated sample — 8 dice clustered, all showing 6",
		{
			"dice_count": 8,
			"arrangement": "cluster",
			"face_values": PackedInt32Array([6, 6, 6, 6, 6, 6, 6, 6]),
		}))

	# ── map_table: critical_parameter = path_visible + obstacle_count
	sweep.append(_p("map_table", "1_path_clear", "path (clear)",
		"path solved — emissive blue route from corner to corner, 0 obstacles",
		{
			"path_visible": true,
			"obstacle_count": 0,
			"grid_visible": true,
		}))
	sweep.append(_p("map_table", "2_path_obstacles", "path (with obstacles)",
		"path solved around 8 obstacles — A* finds the detour",
		{
			"path_visible": true,
			"obstacle_count": 8,
			"grid_visible": true,
		}))
	sweep.append(_p("map_table", "3_search_in_progress", "search (in progress)",
		"unsolved — 12 obstacles, no path drawn yet, the search is running",
		{
			"path_visible": false,
			"obstacle_count": 12,
			"grid_visible": true,
		}))

	# ── pendulum: critical_parameter = swing_angle_degrees ─────────
	sweep.append(_p("pendulum", "1_at_rest", "at rest (θ = 0)",
		"the ground state — string vertical, no swing, no kinetic energy",
		{
			"swing_angle_degrees": 0.0,
			"bob_emission": 0.0,
			"arc_visible": false,
		}))
	sweep.append(_p("pendulum", "2_mid_swing", "mid-swing (θ = 25°)",
		"the oscillation snapshot — frozen mid-arc, maximum potential",
		{
			"swing_angle_degrees": 25.0,
			"bob_emission": 0.3,
			"arc_visible": true,
		}))
	sweep.append(_p("pendulum", "3_extreme_amplitude", "extreme (θ = 45°)",
		"large amplitude — beyond the small-angle approximation",
		{
			"swing_angle_degrees": 45.0,
			"bob_emission": 0.6,
			"bob_color": Color(0.95, 0.20, 0.20),
			"arc_visible": true,
		}))

	# ── prism: critical_parameter = light_out_visible (decomposition)
	sweep.append(_p("prism", "1_white_in_no_spectrum", "white in (no decomposition)",
		"the unanalysed signal — white light enters, no spectrum drawn",
		{
			"light_in_visible": true,
			"light_out_visible": false,
		}))
	sweep.append(_p("prism", "2_full_decomposition", "full decomposition",
		"the spectral basis — 7 rainbow bands fan out, Fourier in glass",
		{
			"light_in_visible": true,
			"light_out_visible": true,
			"spectrum_band_count": 7,
		}))
	sweep.append(_p("prism", "3_high_resolution_12", "high resolution (12 bands)",
		"finer-grained decomposition — 12 spectral bands, denser basis",
		{
			"light_in_visible": true,
			"light_out_visible": true,
			"spectrum_band_count": 12,
		}))

	# ── scales: critical_parameter = left_load vs right_load (argmin)
	sweep.append(_p("scales", "1_balanced_argmin", "balanced (argmin)",
		"equilibrium — left and right loads equal, beam horizontal",
		{
			"left_load": 1.0,
			"right_load": 1.0,
			"tilt_from_loads": true,
		}))
	sweep.append(_p("scales", "2_left_heavy_descent", "left heavy (descent)",
		"the gradient is on the left — beam tilts toward the heavier side",
		{
			"left_load": 3.0,
			"right_load": 1.0,
			"tilt_from_loads": true,
		}))
	sweep.append(_p("scales", "3_right_heavy_escape", "right heavy (escape)",
		"the gradient flipped — right has more weight, beam tilts -",
		{
			"left_load": 1.0,
			"right_load": 4.0,
			"tilt_from_loads": true,
		}))

	# ── kaleidoscope: critical_parameter = mirror_count (group order)
	sweep.append(_p("kaleidoscope", "1_d3_triangular", "D3 triangular",
		"3-fold symmetry — the dihedral group D3, basic kaleidoscope",
		{
			"mirror_count": 3,
			"pattern_segments": 6,
		}))
	sweep.append(_p("kaleidoscope", "2_d6_hexagonal", "D6 hexagonal",
		"6-fold symmetry — D6, the snowflake group",
		{
			"mirror_count": 6,
			"pattern_segments": 12,
		}))
	sweep.append(_p("kaleidoscope", "3_d8_dense", "D8 dense",
		"8-fold symmetry — D8, the dense rosette",
		{
			"mirror_count": 8,
			"pattern_segments": 16,
		}))

	# ── abacus: critical_parameter = bead_positions (digits)
	sweep.append(_p("abacus", "1_pi_digits", "π digits",
		"the canonical seven digits — 3.141592, base-10 positional",
		{
			"rod_count": 7,
			"bead_positions": PackedInt32Array([3, 1, 4, 1, 5, 9, 2]),
			"bead_color_high": Color(0.95, 0.20, 0.20),
		}))
	sweep.append(_p("abacus", "2_e_digits", "e digits",
		"Euler's number — 2.71828, the second mathematical constant",
		{
			"rod_count": 7,
			"bead_positions": PackedInt32Array([2, 7, 1, 8, 2, 8, 1]),
			"bead_color_high": Color(0.20, 0.55, 0.95),
		}))
	sweep.append(_p("abacus", "3_zero_state", "zero state",
		"all beads low — the abacus before any computation",
		{
			"rod_count": 7,
			"bead_positions": PackedInt32Array([0, 0, 0, 0, 0, 0, 0]),
			"bead_color_high": Color(0.20, 0.85, 0.40),
		}))

	# ── mirror: critical_parameter = mirror_arrangement ────────────
	sweep.append(_p("mirror", "1_single_identity", "single (identity)",
		"the identity element — one mirror, the trivial fixed point map",
		{
			"mirror_arrangement": "single",
			"mirror_count": 1,
		}))
	sweep.append(_p("mirror", "2_parallel_infinite", "parallel (infinite)",
		"two parallel mirrors — infinite reflections, the recursion cone",
		{
			"mirror_arrangement": "parallel",
			"mirror_count": 2,
		}))
	sweep.append(_p("mirror", "3_triangular_d3", "triangular (D3)",
			"three mirrors facing inward — D3 fundamental domain enclosure",
			{
				"mirror_arrangement": "triangular",
				"mirror_count": 3,
			}))

	# ── terrarium: critical_parameter = predator_count vs prey ─────
	sweep.append(_p("terrarium", "1_prey_dominant", "prey dominant",
		"high prey, low predator — Lotka-Volterra at peak prey",
		{
			"prey_count": 8,
			"predator_count": 1,
			"vegetation_count": 12,
		}))
	sweep.append(_p("terrarium", "2_predator_surge", "predator surge",
		"predators rising — system mid-cycle, prey falling",
		{
			"prey_count": 3,
			"predator_count": 3,
			"vegetation_count": 6,
		}))
	sweep.append(_p("terrarium", "3_overfishing_collapse", "collapse",
		"predators dominate, prey crashed — the system about to reset",
		{
			"prey_count": 1,
			"predator_count": 4,
			"vegetation_count": 2,
		}))

	# ── fishbowl: critical_parameter = fish_trail_visible ──────────
	sweep.append(_p("fishbowl", "1_trail_visible", "trail visible",
		"the random walk drawn — 8 trail dots show Brownian path",
		{
			"fish_count": 5,
			"fish_trail_visible": true,
			"bubble_count": 3,
		}))
	sweep.append(_p("fishbowl", "2_no_trail", "no trail (instant)",
		"snapshot — fish only, no history, the Markov assumption",
		{
			"fish_count": 8,
			"fish_trail_visible": false,
			"bubble_count": 2,
		}))
	sweep.append(_p("fishbowl", "3_single_walker", "single walker",
		"one fish, full trail — the canonical 1D random walker",
		{
			"fish_count": 1,
			"fish_trail_visible": true,
			"bubble_count": 0,
		}))

	# ── lock_box: critical_parameter = lid_open_amount ─────────────
	sweep.append(_p("lock_box", "1_locked_closed", "locked (closed)",
		"committed — lid shut, combination set, contents hidden",
		{
			"lid_open_amount": 0.0,
			"combination_dial_count": 4,
			"dial_positions": PackedInt32Array([3, 7, 1, 5]),
		}))
	sweep.append(_p("lock_box", "2_half_open_reveal", "half open (reveal)",
		"the commitment opening — lid lifting, dark cavity revealed",
		{
			"lid_open_amount": 0.5,
			"combination_dial_count": 4,
			"dial_positions": PackedInt32Array([0, 0, 0, 0]),
		}))
	sweep.append(_p("lock_box", "3_fully_open", "fully open",
		"the secret revealed — lid vertical, contents exposed",
		{
			"lid_open_amount": 1.0,
			"combination_dial_count": 6,
			"dial_positions": PackedInt32Array([1, 4, 1, 5, 9, 2]),
		}))

	# ── slide_projector: critical_parameter = current_slide_number
	sweep.append(_p("slide_projector", "1_frame_one_start", "frame 1 (start)",
		"the first frame — t=0, the initial condition",
		{
			"current_slide_number": 1,
			"lamp_on": true,
			"beam_visible": true,
		}))
	sweep.append(_p("slide_projector", "2_frame_mid_running", "frame N (running)",
		"mid-sequence — t=23, the time-stepping in progress",
		{
			"current_slide_number": 23,
			"lamp_on": true,
			"beam_visible": true,
		}))
	sweep.append(_p("slide_projector", "3_lamp_off_paused", "lamp off (paused)",
		"the simulation paused — no beam, the carousel waits",
		{
			"current_slide_number": 17,
			"lamp_on": false,
			"beam_visible": false,
		}))

# ── wooden_pallet: critical_parameter = box_arrangement ────────
	sweep.append(_p("wooden_pallet", "1_single_box", "single box",
		"one box on the deck — the minimal load, no markings",
		{
			"box_arrangement": "single",
			"show_decals": false,
		}))
	sweep.append(_p("wooden_pallet", "2_pair_flat", "pair (two flat)",
		"two boxes side by side — a half load, FRAGILE-marked",
		{
			"box_arrangement": "pair",
			"show_decals": true,
		}))
	sweep.append(_p("wooden_pallet", "3_pyramid_setup_c", "pyramid (Setup C)",
		"two boxes plus one on top — the canonical loaded pallet",
		{
			"box_arrangement": "pyramid",
			"show_decals": true,
			"tape_color": Color(0.85, 0.18, 0.18),
		}))

	# ── metal_storage_cabinet: critical_parameter = doors_open_amount
	sweep.append(_p("metal_storage_cabinet", "1_closed_white", "closed (white)",
		"doors shut — the flat white institutional face",
		{
			"doors_open_amount": 0.0,
			"door_count": 2,
			"shelf_count": 3,
		}))
	sweep.append(_p("metal_storage_cabinet", "2_open_shelves", "open (shelves)",
		"doors swung wide — four interior shelves revealed",
		{
			"doors_open_amount": 0.9,
			"door_count": 2,
			"shelf_count": 4,
		}))
	sweep.append(_p("metal_storage_cabinet", "3_grey_locker", "grey locker (single)",
		"a single-door grey locker — institutional, closed",
		{
			"door_count": 1,
			"doors_open_amount": 0.0,
			"body_color": Color(0.40, 0.42, 0.45),
			"door_color": Color(0.46, 0.48, 0.52),
			"shelf_count": 4,
		}))

	# ── fire_hose_box: critical_parameter = door_open ──────────────
	sweep.append(_p("fire_hose_box", "1_closed_window", "closed (window)",
		"door shut — the coiled hose seen through the square window",
		{
			"door_open": false,
			"has_window": true,
		}))
	sweep.append(_p("fire_hose_box", "2_door_open", "door open (reel)",
		"door swung open — the full reel and brass nozzle exposed",
		{
			"door_open": true,
			"has_window": true,
		}))
	sweep.append(_p("fire_hose_box", "3_solid_door", "solid (no window)",
		"a solid-fronted variant — just the FIRE HOSE label and side pictogram",
		{
			"door_open": false,
			"has_window": false,
			"show_pictogram": true,
		}))

	# ── computer_console: critical_parameter = screen_content ──────
	sweep.append(_p("computer_console", "1_diagram_active", "diagram (active)",
		"teal data-viz with a colour spectrogram — the console at work",
		{
			"screen_on": true,
			"screen_content": "diagram",
			"screen_color": Color(0.22, 0.55, 0.72),
		}))
	sweep.append(_p("computer_console", "2_alert_red", "alert (red)",
		"red warning screen — the console raising an alarm",
		{
			"screen_on": true,
			"screen_content": "alert",
			"screen_color": Color(0.85, 0.25, 0.25),
		}))
	sweep.append(_p("computer_console", "3_screen_off", "screen off",
		"dark glass — the terminal powered down, cable still draped",
		{
			"screen_on": false,
			"screen_content": "off",
		}))

	# ── control_console (INTERACTIVE): critical_parameter = body form/colour ──
	# Our console that houses real sliders/readout. DNA = housing style: desktop
	# vs floor-standing + body/trim colour. Scene lives in commons/ui, so we
	# override the default artifacts/ scene path via `extra`.
	var CC_SCENE := {"scene": "res://commons/ui/control_console.tscn"}
	sweep.append(_p("control_console", "1_steel_desk", "steel desk",
		"brushed-steel desktop console — the board at hand height on a short stand",
		{
			"face_to_origin": true, "body_height": 0.40,
			"body_color": Color(0.62, 0.63, 0.65), "trim_color": Color(0.35, 0.36, 0.38),
		}, CC_SCENE))
	sweep.append(_p("control_console", "2_dark_industrial", "dark industrial",
		"dark floor-standing cabinet — the heavy-duty terminal form",
		{
			"face_to_origin": false, "body_height": 1.0,
			"body_color": Color(0.20, 0.21, 0.24), "trim_color": Color(0.12, 0.12, 0.14),
		}, CC_SCENE))
	sweep.append(_p("control_console", "3_warm_civic", "warm civic (clean)",
		"warm sand body, door+vent genes OFF — the clean public-kiosk register",
		{
			"face_to_origin": true, "body_height": 0.45,
			"body_color": Color(0.57, 0.51, 0.41), "trim_color": Color(0.34, 0.30, 0.24),
			"has_door": false, "has_vent": false,
		}, CC_SCENE))
	# Apparatus genes — operator station + its machine in front (desktop form;
	# viz_floor -0.62 = the console's own base plane so both share the ground).
	sweep.append(_p("control_console", "4_monitor_station", "monitor station",
		"console driving a hooded monitor totem in front — the operator-station pair",
		{
			"face_to_origin": true, "body_height": 0.40, "viz_floor": -0.62,
			"demo_apparatus": "monitor",
			"body_color": Color(0.62, 0.63, 0.65), "trim_color": Color(0.35, 0.36, 0.38),
		}, CC_SCENE))
	sweep.append(_p("control_console", "5_cube_gantry", "cube gantry",
		"console driving a portal-gantry 3D volume — the scanner form",
		{
			"face_to_origin": true, "body_height": 0.40, "viz_floor": -0.62,
			"demo_apparatus": "cube",
			"body_color": Color(0.20, 0.21, 0.24), "trim_color": Color(0.12, 0.12, 0.14),
		}, CC_SCENE))
	sweep.append(_p("control_console", "6_specimen_station", "specimen station",
		"console driving a glass specimen tank on its pedestal — the surreal-lab pair",
		{
			"face_to_origin": true, "body_height": 0.45, "viz_floor": -0.62,
			"demo_apparatus": "jar",
			"body_color": Color(0.57, 0.51, 0.41), "trim_color": Color(0.34, 0.30, 0.24),
		}, CC_SCENE))

	# ── WORKBENCH INSTRUMENTS (real console examples): each swept across its
	#    critical_parameter — the @identity gene the slider drives in VR. ──────
	sweep.append(_p("shannon_workbench", "1_max_entropy", "p = 0.5 (max entropy)",
		"peak of the hill — salt-and-pepper grid, incompressible 256/256",
		{"initial_p": 0.5}))
	sweep.append(_p("shannon_workbench", "2_low_entropy", "p = 0.08 (ordered)",
		"sparse ones — far down the hill, highly compressible",
		{"initial_p": 0.08}))
	sweep.append(_p("shannon_workbench", "3_biased_high", "p = 0.85 (biased)",
		"mostly ones — the hill is symmetric, order returns",
		{"initial_p": 0.85}))

	sweep.append(_p("riemann_sum_workbench", "1_coarse", "N = 4 (coarse)",
		"four blocky rectangles — the polygon barely follows the curve",
		{"initial_n": 4}))
	sweep.append(_p("riemann_sum_workbench", "2_mid", "N = 16",
		"sixteen rectangles — readable error, the approximation taking shape",
		{"initial_n": 16}))
	sweep.append(_p("riemann_sum_workbench", "3_fine", "N = 128 (converged)",
		"the staircase hugs the curve — error vanishing",
		{"initial_n": 128}))

	sweep.append(_p("tangent_slope_workbench", "1_early", "x = 0.5",
		"tangent sampled early on the curve",
		{"initial_x": 0.5}))
	sweep.append(_p("tangent_slope_workbench", "2_mid", "x = 2.4",
		"tangent sampled mid-curve",
		{"initial_x": 2.4}))
	sweep.append(_p("tangent_slope_workbench", "3_late", "x = 4.2",
		"tangent sampled late on the curve",
		{"initial_x": 4.2}))

	sweep.append(_p("cantor_diagonal_workbench", "1_small", "N = 8",
		"a short list — the diagonal escape is easy to follow row by row",
		{"initial_n": 8}))
	sweep.append(_p("cantor_diagonal_workbench", "2_mid", "N = 16",
		"the standard list — d differs from every row",
		{"initial_n": 16}))
	sweep.append(_p("cantor_diagonal_workbench", "3_large", "N = 32",
		"a long list — and still the diagonal slips out",
		{"initial_n": 32}))

	sweep.append(_p("triangle_curvature_workbench", "1_elliptic", "K = +1 (sphere)",
		"angles sum past 180° — elliptic excess on the sphere",
		{"initial_k": 1.0}))
	sweep.append(_p("triangle_curvature_workbench", "2_flat", "K = 0 (flat)",
		"exactly 180° — the Euclidean baseline",
		{"initial_k": 0.0}))
	sweep.append(_p("triangle_curvature_workbench", "3_hyperbolic", "K = -1 (disk)",
		"angles fall short of 180° — hyperbolic defect on the Poincaré disk",
		{"initial_k": -1.0}))

	# ── computer_keyboard: critical_parameter = layout ─────────────
	sweep.append(_p("computer_keyboard", "1_full_numpad", "full (numpad)",
		"full-size layout — main block plus the numpad",
		{
			"layout": "full",
			"has_numpad": true,
		}))
	sweep.append(_p("computer_keyboard", "2_tenkeyless", "tenkeyless",
		"TKL — the numpad dropped, a tighter desk footprint",
		{
			"layout": "tkl",
			"has_numpad": false,
		}))
	sweep.append(_p("computer_keyboard", "3_compact_accent", "compact (accent)",
		"a compact board with a highlighted top row",
		{
			"layout": "compact",
			"has_numpad": false,
			"accent_color": Color(0.95, 0.55, 0.20),
			"key_color": Color(0.42, 0.46, 0.54),
		}))

# ── lead_safety_door: critical_parameter = hazard_type ─────────
	sweep.append(_p("lead_safety_door", "1_radiation_employees", "radiation (employees)",
		"the lead shield — radiation trefoil, EMPLOYEES ONLY",
		{
			"hazard_type": "radiation",
			"restricted_text": "EMPLOYEES ONLY",
		}))
	sweep.append(_p("lead_safety_door", "2_biohazard_authorized", "biohazard (authorized)",
		"a containment door — biohazard symbol, AUTHORIZED ONLY",
		{
			"hazard_type": "biohazard",
			"restricted_text": "AUTHORIZED ONLY",
			"hazard_color": Color(0.98, 0.62, 0.10),
		}))
	sweep.append(_p("lead_safety_door", "3_high_voltage_danger", "high voltage (danger)",
		"a high-tension room — lightning bolt, DANGER · HV",
		{
			"hazard_type": "electrical",
			"restricted_text": "DANGER · HV",
		}))

	# ── hangar_podium: critical_parameter = top_height (reach) ──────────────
	sweep.append(_p("hangar_podium", "1_reach_pedestal", "reach pedestal",
		"the canonical case — lifts a small artifact to ~1m hand height; recessed tray",
		{
			"top_height": 1.0, "top_size": 0.5, "taper": 0.12,
			"top_style": "tray", "panel_style": "paneled", "edge_light": true,
			"accent_color": Color(0.25, 0.85, 0.95), "stencil_text": "PED-01",
		}))
	sweep.append(_p("hangar_podium", "2_low_display", "low display plinth",
		"0.55m — look DOWN into a medium artifact; flush top, clean sides",
		{
			"top_height": 0.55, "top_size": 0.85, "taper": 0.16,
			"top_style": "flat", "panel_style": "clean", "edge_light": false,
		}))
	sweep.append(_p("hangar_podium", "3_console_base", "console base",
		"a wide work surface — 1.2m top, greebled, framed by corner posts",
		{
			"top_height": 0.9, "top_size": 1.2, "taper": 0.10,
			"top_style": "tray", "panel_style": "greebled", "corner_posts": true,
			"accent_color": Color(0.98, 0.62, 0.10),
		}))
	sweep.append(_p("hangar_podium", "4_grate_rig", "maintenance rig",
		"the bay look — grated top, greebled body, posts, hazard trim, stencil ID, heavy wear",
		{
			"top_height": 1.05, "top_size": 0.7, "taper": 0.08,
			"top_style": "grate", "panel_style": "greebled", "corner_posts": true,
			"accent_color": Color(0.30, 0.95, 0.45),
			"wear": 0.45, "hazard_trim": true, "stencil_text": "BAY-04",
		}))
	sweep.append(_p("hangar_podium", "5_terminal", "terminal finish",
		"the dark alternate DNA — charcoal worn-metal console, signal-red bar",
		{
			"top_height": 1.0, "top_size": 0.55, "taper": 0.12,
			"top_style": "tray", "panel_style": "greebled", "finish": "terminal", "stencil_text": "TRM-05",
		}))

	# ── artifact_readout_screen: critical_parameter = mount ─────────────────
	sweep.append(_p("artifact_readout_screen", "1_stalk", "stalk readout",
		"the field-instrument caption — green-on-dark on a stalk with an antenna (image-2 style)",
		{
			"header": "VECTOR · ADD", "body": "MAGNITUDE  4.2\nANGLE      37°\nSTATUS     LIVE",
			"mount": "stalk",
		}))
	sweep.append(_p("artifact_readout_screen", "2_wall_plate", "wall plate",
		"a bolted wall sign — names the artifact against a backing wall",
		{
			"header": "REACTION-DIFFUSION", "body": "FEED  0.035\nKILL  0.065\nGRAY-SCOTT",
			"mount": "wall", "screen_w": 0.6, "screen_h": 0.4,
			"text_color": Color(0.45, 0.85, 1.0), "header_color": Color(0.95, 0.55, 0.2),
		}))
	sweep.append(_p("artifact_readout_screen", "3_freestand", "freestanding sign",
		"a two-legged readout that stands beside a floor artifact",
		{
			"header": "L-SYSTEM", "body": "AXIOM  F\nRULE   F→F+F−F\nDEPTH  4",
			"mount": "freestand",
		}))
	sweep.append(_p("artifact_readout_screen", "4_desk", "desk readout",
		"a low tabletop screen for a benchtop artifact",
		{
			"header": "POWER", "body": "CONSUMPTION  30%\nNOMINAL",
			"mount": "desk", "screen_w": 0.42, "screen_h": 0.3,
			"text_color": Color(1.0, 0.45, 0.45), "header_color": Color(1.0, 0.8, 0.3),
		}))
	sweep.append(_p("artifact_readout_screen", "5_terminal", "terminal finish",
		"the dark alternate DNA — green-CRT console screen on a charcoal stalk",
		{
			"header": "SYSTEM", "body": "CORE   ONLINE\nMEM    OK\nLINK   2400",
			"mount": "stalk", "finish": "terminal",
		}))

	# ── hangar_step_base: critical_parameter = footprint (a stage you mount) ──
	sweep.append(_p("hangar_step_base", "1_solid", "solid step", "2×2 mounting block, hazard lip, STEP-01",
		{ "width": 2.0, "depth": 2.0, "step_height": 0.25, "top_style": "solid", "ramp": false, "edge_rail": false, "hazard_edge": true, "stencil_text": "STEP-01" }))
	sweep.append(_p("hangar_step_base", "2_ramp", "ramp step", "wheel a cart up the front",
		{ "width": 2.4, "depth": 2.0, "step_height": 0.30, "top_style": "solid", "ramp": true, "hazard_edge": true, "stencil_text": "RAMP-02" }))
	sweep.append(_p("hangar_step_base", "3_railed_deck", "railed deck", "3×3 grated work platform with rails",
		{ "width": 3.0, "depth": 3.0, "step_height": 0.30, "top_style": "grate", "edge_rail": true, "hazard_edge": true, "stencil_text": "DECK-03" }))
	sweep.append(_p("hangar_step_base", "4_kerb", "wall kerb", "wide shallow step to a panel",
		{ "width": 3.2, "depth": 1.2, "step_height": 0.18, "hazard_edge": true, "stencil_text": "KERB-04" }))

	# ── hangar_wall_panel: critical_parameter = panel_style ────────────────
	sweep.append(_p("hangar_wall_panel", "1_perforated", "perforated", "a recessed hole-grid vent wall, lit seams",
		{ "panel_style": "perforated", "lit_channels": true }))
	sweep.append(_p("hangar_wall_panel", "2_greebled_screen", "greebled + screen", "panels, bolts, vent + an embedded readout",
		{ "panel_style": "greebled", "screen_slot": true }))
	sweep.append(_p("hangar_wall_panel", "3_ribbed_branded", "ribbed + brand", "vertical ribs, VALLEY LABORATORIES, hazard base",
		{ "panel_style": "ribbed", "brand_text": "VALLEY LABORATORIES", "hazard_base": true }))
	sweep.append(_p("hangar_wall_panel", "4_full", "full greebled", "screen + brand + lit seams + wear",
		{ "panel_style": "greebled", "screen_slot": true, "brand_text": "BAY 7", "lit_channels": true, "wear": 0.35 }))

	# ── hangar_cabinet_cluster: critical_parameter = unit_count ────────────
	sweep.append(_p("hangar_cabinet_cluster", "1_cool_pair", "cool pair", "two cool-grey cabinets, screens + vents",
		{ "unit_count": 2, "palette": "cool", "with_screens": true, "vents": true }))
	sweep.append(_p("hangar_cabinet_cluster", "2_mixed_bank", "mixed bank", "three mixed-palette units — the default",
		{ "unit_count": 3, "palette": "mixed", "with_screens": true, "vents": true }))
	sweep.append(_p("hangar_cabinet_cluster", "3_warm_quad", "warm quad", "four warm units, full screens + vents",
		{ "unit_count": 4, "palette": "warm", "with_screens": true, "vents": true }))
	sweep.append(_p("hangar_cabinet_cluster", "4_dormant_row", "dormant row", "four cool units, dark — no screens or vents",
		{ "unit_count": 4, "palette": "cool", "with_screens": false, "vents": false }))

	# ── hangar_supply_pile: critical_parameter = crate_count ───────────────
	sweep.append(_p("hangar_supply_pile", "1_cardboard_four", "cardboard · 4", "the canonical supply corner — crates, cylinder, cone",
		{ "crate_count": 4, "palette": "cardboard", "hazard_labels": true, "with_cylinder": true, "with_cone": true, "wear": 0.3 }))
	sweep.append(_p("hangar_supply_pile", "2_wood_five", "wood · 5 full", "a fully-stocked wooden freight pile",
		{ "crate_count": 5, "palette": "wood", "hazard_labels": true, "with_cylinder": true, "with_cone": true, "wear": 0.45 }))
	sweep.append(_p("hangar_supply_pile", "3_metal_two", "metal · 2 bare", "a small drop-off — two metal crates + cone",
		{ "crate_count": 2, "palette": "metal", "hazard_labels": false, "with_cylinder": false, "with_cone": true, "wear": 0.2 }))
	sweep.append(_p("hangar_supply_pile", "4_refuel", "cardboard · 3 + cylinder", "three crates + the gas cylinder, no cone",
		{ "crate_count": 3, "palette": "cardboard", "hazard_labels": true, "with_cylinder": true, "with_cone": false, "cylinder_color": Color(0.85, 0.55, 0.10), "wear": 0.6 }))

	# ── hangar_barrier_fence: critical_parameter = panel_count ─────────────
	sweep.append(_p("hangar_barrier_fence", "1_short_branded", "short branded gate", "2 panels, VALLEY LABORATORIES + subtitle",
		{ "panel_count": 2, "brand_text": "VALLEY LABORATORIES", "subtitle_text": "AUTHORIZED PERSONNEL" }))
	sweep.append(_p("hangar_barrier_fence", "2_long_cordon", "long cordon", "5 panels, biohazard, caution base",
		{ "panel_count": 5, "brand_text": "BIOHAZARD CONTAINMENT", "stripe_base": true }))
	sweep.append(_p("hangar_barrier_fence", "3_l_corner", "L-corner wrap", "4 panels bent into an L",
		{ "panel_count": 4, "corner": true, "brand_text": "RESTRICTED ZONE" }))
	sweep.append(_p("hangar_barrier_fence", "4_plain_run", "plain run", "3 unbranded panels",
		{ "panel_count": 3, "brand_text": "" }))

	# ── hangar_worktable: critical_parameter = width ───────────────────────
	sweep.append(_p("hangar_worktable", "1_single_station", "single station", "1.2m bench — drawers, screen, tools",
		{ "width": 1.2, "top_style": "solid", "with_screen": true, "with_tools": true, "drawers": true, "stencil_text": "BENCH-01" }))
	sweep.append(_p("hangar_worktable", "2_two_tool", "two-tool bench", "1.6m default — full kit",
		{ "width": 1.6, "with_screen": true, "with_tools": true, "drawers": true, "stencil_text": "BENCH-02" }))
	sweep.append(_p("hangar_worktable", "3_shared_run", "shared run", "2.4m, clear top, screen only",
		{ "width": 2.4, "depth": 1.0, "with_screen": true, "with_tools": false, "drawers": false, "stencil_text": "BENCH-03" }))
	sweep.append(_p("hangar_worktable", "4_wet_bench", "wet bench", "1.8m grated drainage top, worn",
		{ "width": 1.8, "depth": 0.9, "top_style": "grate", "with_screen": false, "with_tools": true, "drawers": true, "wear": 0.55, "stencil_text": "BENCH-04" }))

	return sweep


# Small helper to make sweep entries less verbose. `extra` may carry
# capture-time hints (e.g. ) — props that face
# -Z get spun 180° around Y so text reads correctly from the camera.
func _p(prop: String, variant_id: String, label: String, subtitle: String, dna: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var d := {
		"prop": prop,
		"scene": "res://commons/artifacts/%s/%s.tscn" % [prop, prop],
		"variant_id": variant_id,
		"label": label,
		"subtitle": subtitle,
		"notes": subtitle,
		"dna": dna,
	}
	for k in extra.keys():
		d[k] = extra[k]
	return d
