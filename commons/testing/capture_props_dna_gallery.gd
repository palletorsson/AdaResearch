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
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
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
		await create_timer(0.10).timeout

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
				# transform sub_aabb into parent's space if child has a non-identity transform
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
	# text_size is INT (Label3D font_size). Default 18. The screen's
	# internal text_root has a 180° Y rotation in info_screen.gd that
	# mirrors text when viewed from the +Z-side camera — so we set
	# rotation_y_180 to cancel it for the catalog shot.
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
		},
		{"rotation_y_180": true}))
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
		},
		{"rotation_y_180": true}))
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
		},
		{"rotation_y_180": true}))

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

	return sweep


# Small helper to make sweep entries less verbose. `extra` may carry
# capture-time hints (e.g. {"rotation_y_180": true}) — props that face
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
