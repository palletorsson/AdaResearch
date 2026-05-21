## Props SHAPE sweep — capture each of the 8 lab prop artifacts along
## its primary dimensional axis to make the FORM family legible.
##
## Pedagogical claim — the previous props_dna_gallery proved each prop's
## colour / count / state DNA matters. This gallery proves the
## DIMENSIONAL DNA matters too. Each row is the same prop scaled
## along its biggest silhouette parameter (width, length, slat_count,
## cable_count). Reading down a row should feel like watching a
## family of forms emerge from a single template.
##
## Layout: 8 rows × 5 columns = 40 cells.
##
## Camera: same chassis as capture_props_dna_gallery.gd — 1024×1024
## SubViewport, AABB-orbit at 3/4 angle, three-light rig. Bigger
## FRAME_PADDING (2.05) so the largest variants in each row don't
## clip — the camera distance scales with each cell's AABB so size
## differences read truthfully across the grid (a 5m table is bigger
## than a 1m table, not just framed differently).
##
## Run:
##   "/c/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/capture_props_shape_gallery.gd -- \
##     --out=user://props_shape_gallery
##
## Output: <out>/{prop}_{N}_{label}.png + JSON + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)

const CAMERA_FOV: float = 32.0
const CAMERA_YAW: float = 0.55   # 3/4 from the right
const CAMERA_PITCH: float = -0.30
const FRAME_PADDING: float = 2.05

var _output_dir: String = "user://props_shape_gallery"
## Public URL base for image paths in the manifest. Manifests must use
## absolute paths because the page URL strips the slug otherwise.
const PUBLIC_BASE: String = "/props-shape-gallery"
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
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

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

	# Three-light rig (warm key + cool fill + rim)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.97, 0.92)
	key.rotation_degrees = Vector3(-35, 25, 0)
	key.shadow_enabled = true
	_viewport.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.light_color = Color(0.85, 0.90, 1.0)
	fill.rotation_degrees = Vector3(-15, -120, 0)
	_viewport.add_child(fill)

	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.60
	rim.light_color = Color(1.0, 1.0, 1.0)
	rim.rotation_degrees = Vector3(-80, 180, 0)
	_viewport.add_child(rim)

	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	_camera.near = 0.02
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

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
		for prop in dna.keys():
			node.set(prop, dna[prop])
		if bool(spec.get("rotation_y_180", false)):
			node.rotation = Vector3(0.0, PI, 0.0)
		if bool(spec.get("rotation_x_180", false)):
			# Ceiling-mounted props (ceiling_vent) have their working face
			# pointing -Y. Flipping around X puts the slats UP so the
			# overhead camera actually sees them.
			node.rotation = Vector3(PI, 0.0, 0.0)
		_scene_holder.add_child(node)
		await create_timer(0.10).timeout

		var aabb: AABB = _get_combined_aabb(node)
		if aabb.size.length() < 0.001:
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

	var manifest := {
		"version": 1,
		"description": "Eight lab-prop artifacts × five shape variants each (40 cells). Each row sweeps a single prop along its primary DIMENSIONAL axis — width, length, height, slat_count, cable_count — to show how the FORM family emerges from the same DNA template. The camera distance scales with each cell's AABB, so a 5m table really does read bigger than a 1m table. Sister gallery to props-dna-gallery, which exercises the colour / state / count axis.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {
			"projection": "perspective",
			"fov_deg": CAMERA_FOV,
			"yaw_rad": CAMERA_YAW,
			"pitch_rad": CAMERA_PITCH,
			"framing": "AABB-orbit, %.2f×max_dim padding (scales with each variant)" % FRAME_PADDING,
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
	await get_root().get_tree().process_frame
	await get_root().get_tree().process_frame

	var img: Image = _viewport.get_texture().get_image()
	var prop: String = spec["prop"]
	var variant: String = spec["variant_id"]
	var stem: String = "%s_%s" % [prop, variant]
	var png_path: String = "%s/%s.png" % [_output_dir, stem]
	img.save_png(png_path)

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
		"shape_axis": spec.get("shape_axis", ""),
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
		"shape_axis": spec.get("shape_axis", ""),
		"image": "%s/%s.png" % [PUBLIC_BASE, stem],
		"config": "%s/%s.json" % [PUBLIC_BASE, stem],
		"dna": dna_clean,
	})
	print("[%2d] %s — %s saved (aabb %.2f×%.2f×%.2f)"
		% [index, prop, variant, aabb.size.x, aabb.size.y, aabb.size.z])


# ── Sweep specification ──────────────────────────────────────────────
# 8 props × 5 shape variants. Each row varies one dimensional axis;
# colours stay neutral / consistent within the row so the eye reads
# the FORM change, not the palette change.

func _build_sweep() -> Array:
	var sweep: Array = []

	# Neutral palette used across all props in this gallery so the
	# shape change isn't confounded by colour change.
	var k_frame := Color(0.20, 0.22, 0.25)
	var k_panel := Color(0.92, 0.92, 0.94)
	var k_accent := Color(0.95, 0.55, 0.0)  # portal orange — recognisable, consistent
	var k_text := Color(0.10, 0.10, 0.12)

	# ── exit_sign: width axis (small plate → marquee) ──────────────
	var sign_widths := [0.30, 0.45, 0.60, 0.85, 1.20]
	var sign_labels := ["plate (0.30)", "standard (0.45)", "wide (0.60)", "billboard (0.85)", "marquee (1.20)"]
	for i in range(5):
		sweep.append(_p("exit_sign", "%d_width_%s" % [i + 1, str(sign_widths[i]).replace(".", "p")],
			sign_labels[i], "width = %.2fm" % sign_widths[i], "width",
			{
				"text": "EXIT",
				"arrow_direction": "right",
				"sign_color": Color(0.20, 0.80, 0.30),
				"width": float(sign_widths[i]),
				"height": 0.18 * (1.0 + (sign_widths[i] - 0.45) * 0.3),  # gentle scaling
				"glow_energy": 1.5,
			}))

	# ── sliding_door: (door_width × door_height) axis ──────────────
	var doors := [
		[1.2, 2.0, "narrow_airlock", "narrow airlock (1.2×2.0)"],
		[1.6, 2.3, "personnel",      "personnel (1.6×2.3)"],
		[2.2, 2.6, "double_wide",    "double wide (2.2×2.6)"],
		[2.8, 3.2, "tall_lab",       "tall lab (2.8×3.2)"],
		[3.6, 3.6, "freight",        "freight (3.6×3.6)"],
	]
	for i in range(5):
		var d = doors[i]
		sweep.append(_p("sliding_door", "%d_%s" % [i + 1, d[2]],
			d[3], "door_width × door_height = %.1f×%.1fm" % [d[0], d[1]], "size",
			{
				"door_width": float(d[0]),
				"door_height": float(d[1]),
				"panels_open_amount": 0.4,
				"frame_color": k_frame,
				"panel_color": k_panel,
				"accent_color": k_accent,
			}))

	# ── whiteboard: board_width axis (note → wall) ─────────────────
	var boards := [
		[1.0, 0.8, "note",        "note (1.0×0.8)"],
		[1.5, 1.0, "standard",    "standard (1.5×1.0)"],
		[2.5, 1.2, "lecture",     "lecture (2.5×1.2)"],
		[3.5, 1.4, "panel_long",  "panel-long (3.5×1.4)"],
		[4.5, 1.6, "wall",        "wall-spanning (4.5×1.6)"],
	]
	var board_lines := [
		PackedStringArray(["d/dx", "= f'(x)"]),
		PackedStringArray(["d/dx f(x) = f'(x)", "  the slope"]),
		PackedStringArray(["Fundamental Theorem", "integral f(x) dx = F(b) - F(a)", "  tangent <-> area"]),
		PackedStringArray(["Fundamental Theorem of Calculus", "  integral f(x) dx = F(b) - F(a)", "the slope of the tangent <-> the area under", "the two halves of CHANGE"]),
		PackedStringArray(["Fundamental Theorem of Calculus", "  integral f(x) dx = F(b) - F(a)", "the slope of the tangent <-> the area under", "two halves of CHANGE — same f, two questions", "this is what the lab is for"]),
	]
	for i in range(5):
		var b = boards[i]
		sweep.append(_p("whiteboard", "%d_%s" % [i + 1, b[2]],
			b[3], "board_width × board_height = %.1f×%.1fm" % [b[0], b[1]], "size",
			{
				"board_width": float(b[0]),
				"board_height": float(b[1]),
				"text_lines": board_lines[i],
				"text_color": k_text,
				"text_size": 28,
			}))

	# ── large_table: length × leg_style transition ─────────────────
	var tables := [
		[1.0, 0.7, "post",  "small_post",   "small post (1.0×0.7, four legs)"],
		[1.8, 0.85, "post", "medium_post",  "medium post (1.8×0.85)"],
		[2.6, 0.95, "panel","panel_mid",    "panel mid (2.6×0.95, side panels)"],
		[3.4, 1.05, "panel","panel_long",   "panel long (3.4×1.05)"],
		[4.5, 1.15, "panel","banquet",      "banquet (4.5×1.15)"],
	]
	for i in range(5):
		var t = tables[i]
		sweep.append(_p("large_table", "%d_%s" % [i + 1, t[3]],
			t[4], "length × depth = %.1f×%.2fm, leg_style = %s" % [t[0], t[1], t[2]], "length",
			{
				"length": float(t[0]),
				"depth": float(t[1]),
				"height": 0.95,
				"leg_style": t[2],
				"top_color": k_panel,
				"leg_color": k_frame,
				"accent_color": k_accent,
				"edge_strip": true,
			}))

	# ── large_window: aspect ratio sweep ───────────────────────────
	var windows := [
		[0.9, 0.9,  "porthole",   "porthole (0.9×0.9, square)"],
		[1.8, 1.0,  "wide",       "wide (1.8×1.0)"],
		[2.8, 1.4,  "panoramic",  "panoramic (2.8×1.4)"],
		[1.4, 2.4,  "vertical",   "vertical (1.4×2.4, portrait)"],
		[4.0, 2.0,  "wall",       "wall-spanning (4.0×2.0)"],
	]
	for i in range(5):
		var w = windows[i]
		sweep.append(_p("large_window", "%d_%s" % [i + 1, w[2]],
			w[3], "window_width × window_height = %.1f×%.1fm" % [w[0], w[1]], "aspect",
			{
				"window_width": float(w[0]),
				"window_height": float(w[1]),
				"frame_color": k_frame,
				"glass_color": Color(0.65, 0.78, 0.88, 0.30),
				"accent_color": k_accent,
				"glass_emission": 0.25,
			}))

	# ── info_screen: monitor → cinema sizing sweep ─────────────────
	var screens := [
		[0.6, 0.4,  18, "monitor",     "monitor (0.6×0.4)"],
		[1.0, 0.6,  20, "desktop",     "desktop (1.0×0.6)"],
		[1.6, 0.95, 24, "wall",        "wall (1.6×0.95)"],
		[2.4, 1.4,  32, "video_wall",  "video-wall (2.4×1.4)"],
		[3.4, 1.9,  44, "cinema",      "cinema (3.4×1.9)"],
	]
	for i in range(5):
		var s = screens[i]
		sweep.append(_p("info_screen", "%d_%s" % [i + 1, s[3]],
			s[4], "screen_width × screen_height = %.1f×%.2fm, text_size = %d" % [s[0], s[1], s[2]], "size",
			{
				"screen_width": float(s[0]),
				"screen_height": float(s[1]),
				"header_text": "STATUS",
				"text_lines": PackedStringArray([
					"chamber: nominal",
					"H(p) = 0.918 bits",
					"READY",
				]),
				"text_color": Color(0.45, 0.95, 0.55),
				"header_color": Color(0.95, 0.72, 0.30),
				"text_size": int(s[2]),
			}))

	# ── ceiling_vent: slat_count axis (sparse → dense) ─────────────
	var vents := [
		[0.7, 4,  "sparse_4",   "sparse (4 slats)"],
		[0.9, 8,  "8_slats",    "8 slats"],
		[1.2, 14, "14_slats",   "14 slats"],
		[1.5, 22, "22_slats",   "22 slats (dense)"],
		[1.8, 32, "32_slats",   "32 slats (very dense)"],
	]
	for i in range(5):
		var v = vents[i]
		sweep.append(_p("ceiling_vent", "%d_%s" % [i + 1, v[2]],
			v[3], "vent_length × slat_count = %.1fm × %d" % [v[0], v[1]], "slat_count",
			{
				"vent_length": float(v[0]),
				"vent_width": 0.45,
				"slat_count": int(v[1]),
				"frame_color": k_frame,
				"slat_color": Color(0.78, 0.78, 0.80),
				"airflow_glow": false,
			},
			{"rotation_x_180": true}))

	# ── cable_tray: length × cable_count axis (single → bundle) ────
	var trays := [
		[1.0, 1,  "single_short",  "single short (1m, 1 cable)"],
		[2.0, 3,  "trio",          "trio (2m, 3 cables)"],
		[3.0, 6,  "midrun",        "midrun (3m, 6 cables)"],
		[4.0, 10, "ten_bundle",    "ten-bundle (4m, 10 cables)"],
		[5.0, 14, "thick_overhead","thick overhead (5m, 14 cables)"],
	]
	# Reuse a consistent neutral palette across all rows
	var cable_palette := PackedColorArray([
		Color(0.20, 0.20, 0.22), Color(0.55, 0.30, 0.20), Color(0.20, 0.30, 0.55),
		Color(0.55, 0.50, 0.20), Color(0.30, 0.50, 0.30), Color(0.50, 0.20, 0.45),
		Color(0.85, 0.85, 0.88), Color(0.18, 0.55, 0.55), Color(0.65, 0.35, 0.30),
		Color(0.45, 0.45, 0.50), Color(0.85, 0.45, 0.20), Color(0.30, 0.75, 0.45),
		Color(0.95, 0.70, 0.25), Color(0.35, 0.55, 0.95),
	])
	for i in range(5):
		var c = trays[i]
		sweep.append(_p("cable_tray", "%d_%s" % [i + 1, c[2]],
			c[3], "tray_length × cable_count = %.1fm × %d" % [c[0], c[1]], "length",
			{
				"tray_length": float(c[0]),
				"tray_width": 0.18,
				"tray_height": 0.07,
				"rung_count": max(3, int(c[0] * 2.5)),
				"cable_count": int(c[1]),
				"tray_color": k_frame,
				"cable_colors": cable_palette,
			}))

	# ── lab_stool: seat_height axis (low → tall) ───────────────────
	var stool_specs := [
		[0.45, 0.18, 0.30, "five_star", "child_low",   "child low (0.45m)"],
		[0.55, 0.18, 0.32, "five_star", "short",       "short (0.55m)"],
		[0.65, 0.18, 0.32, "five_star", "standard",    "standard (0.65m)"],
		[0.78, 0.20, 0.34, "ring",      "tall_ring",   "tall ring (0.78m)"],
		[0.90, 0.20, 0.36, "ring",      "draft_max",   "draft height (0.90m)"],
	]
	for i in range(5):
		var s = stool_specs[i]
		sweep.append(_p("lab_stool", "%d_%s" % [i + 1, s[4]],
			s[5], "seat_height = %.2fm, base_style = %s" % [s[0], s[3]], "seat_height",
			{
				"seat_height": float(s[0]),
				"seat_radius": float(s[1]),
				"base_radius": float(s[2]),
				"base_style": s[3],
				"seat_color": Color(0.08, 0.08, 0.10),
				"post_color": k_frame,
				"accent_color": k_accent,
				"accent_strip": true,
			}))

	# ── fume_hood: hood_width × hood_height sweep ──────────────────
	var hood_specs := [
		[1.0, 1.6, 0.5, "compact",      "compact (1.0×1.6)"],
		[1.4, 1.9, 0.6, "small",        "small (1.4×1.9)"],
		[1.8, 2.1, 0.7, "standard",     "standard (1.8×2.1)"],
		[2.4, 2.4, 0.8, "wide",         "wide (2.4×2.4)"],
		[3.0, 2.6, 0.9, "industrial",   "industrial (3.0×2.6)"],
	]
	for i in range(5):
		var h = hood_specs[i]
		sweep.append(_p("fume_hood", "%d_%s" % [i + 1, h[3]],
			h[4], "hood_width × hood_height = %.1f×%.1fm" % [h[0], h[1]], "size",
			{
				"hood_width": float(h[0]),
				"hood_height": float(h[1]),
				"hood_depth": float(h[2]),
				"sash_open_amount": 0.45,
				"interior_color": Color(0.74, 0.74, 0.76),
				"accent_color": k_accent,
				"frame_color": k_frame,
				"interior_light": true,
			}))

	# ── server_rack: rack_height_u axis (sparse → tall) ────────────
	var rack_specs := [
		[8,  2,  "half_height",  "half-height (8U, 2 servers)"],
		[16, 4,  "compact",      "compact (16U, 4 servers)"],
		[24, 6,  "standard",     "standard (24U, 6 servers)"],
		[36, 9,  "full_tall",    "full tall (36U, 9 servers)"],
		[42, 12, "max_density",  "max density (42U, 12 servers)"],
	]
	for i in range(5):
		var r = rack_specs[i]
		sweep.append(_p("server_rack", "%d_%s" % [i + 1, r[2]],
			r[3], "rack_height_u = %d, server_count = %d" % [r[0], r[1]], "rack_height_u",
			{
				"rack_height_u": int(r[0]),
				"server_count": int(r[1]),
				"led_density": 5,
				"door_open": true,
				"frame_color": k_frame,
				"led_color": Color(0.20, 0.95, 0.45),
				"accent_color": k_accent,
			}))

	# ── emergency_button: plate_width × button_radius axis ─────────
	var btn_specs := [
		[0.12, 0.035, "wall",   "small_wall",    "small wall (plate 0.12, btn 0.035)"],
		[0.18, 0.050, "wall",   "standard_wall", "standard wall (0.18, 0.050)"],
		[0.24, 0.065, "wall",   "large_wall",    "large wall (0.24, 0.065)"],
		[0.30, 0.080, "podium", "podium_small",  "podium small (0.30, 0.080)"],
		[0.40, 0.110, "podium", "podium_grand",  "podium grand (0.40, 0.110)"],
	]
	for i in range(5):
		var b = btn_specs[i]
		sweep.append(_p("emergency_button", "%d_%s" % [i + 1, b[3]],
			b[4], "plate %.2fm × button radius %.3fm (mounting %s)" % [b[0], b[1], b[2]], "size",
			{
				"plate_width": float(b[0]),
				"plate_height": float(b[0]),
				"button_radius": float(b[1]),
				"mounting": b[2],
				"label_text": "STOP",
				"button_color": Color(0.95, 0.10, 0.10),
				"plate_color": Color(0.98, 0.85, 0.10),
				"text_color": Color(0.05, 0.05, 0.05),
				"pressed": false,
			}))

	# ── conveyor_belt: belt_length axis (short → long) ─────────────
	var belt_specs := [
		[1.0, 0.5, 2, 2, "short",       "short (1.0m, 2 arrows)"],
		[2.0, 0.6, 4, 3, "personnel",   "personnel (2.0m, 4 arrows)"],
		[3.0, 0.7, 6, 4, "transfer",    "transfer (3.0m, 6 arrows)"],
		[4.5, 0.9, 9, 5, "freight",     "freight (4.5m, 9 arrows)"],
		[6.0, 1.2, 12, 6, "factory",    "factory (6.0m, 12 arrows)"],
	]
	for i in range(5):
		var c = belt_specs[i]
		sweep.append(_p("conveyor_belt", "%d_%s" % [i + 1, c[4]],
			c[5], "belt_length × belt_width = %.1f×%.1fm, %d arrows" % [c[0], c[1], c[2]], "length",
			{
				"belt_length": float(c[0]),
				"belt_width": float(c[1]),
				"belt_height": 0.18,
				"direction_arrow_count": int(c[2]),
				"support_legs": int(c[3]),
				"belt_color": Color(0.10, 0.10, 0.11),
				"support_color": k_frame,
				"accent_color": k_accent,
				"arrow_color": k_accent,
			}))

	# ── safety_shower: shower_height axis (low → tall) ─────────────
	var shower_specs := [
		[1.8, 0.35, 0.30, "low_wall",         "low wall (1.8m)"],
		[2.0, 0.40, 0.32, "compact",          "compact (2.0m)"],
		[2.2, 0.45, 0.35, "standard",         "standard (2.2m)"],
		[2.5, 0.55, 0.42, "wide_basin",       "wide basin (2.5m)"],
		[2.8, 0.70, 0.50, "industrial_tall",  "industrial tall (2.8m)"],
	]
	for i in range(5):
		var sh = shower_specs[i]
		sweep.append(_p("safety_shower", "%d_%s" % [i + 1, sh[3]],
			sh[4], "shower_height = %.1fm, basin %.2f×%.2fm" % [sh[0], sh[1], sh[2]], "shower_height",
			{
				"shower_height": float(sh[0]),
				"basin_width": float(sh[1]),
				"basin_depth": float(sh[2]),
				"pipe_orientation": "wall",
				"chain_visible": true,
				"signage_text": "SAFETY",
				"pipe_color": k_frame,
				"basin_color": Color(0.94, 0.94, 0.95),
				"accent_color": Color(0.15, 0.65, 0.25),
			}))

	# ── microscope: body_height × eyepiece × objective sweep ───────
	var scope_specs := [
		[0.24, 1, 2, 0.18, "school_mono",      "school monocular (0.24m, 1 eye, 2 obj)"],
		[0.30, 1, 3, 0.20, "intro_mono",       "intro mono (0.30m, 1 eye, 3 obj)"],
		[0.38, 2, 4, 0.22, "standard_bin",     "standard binocular (0.38m, 2 eye, 4 obj)"],
		[0.46, 2, 5, 0.24, "research_5",       "research 5-obj (0.46m, 2 eye, 5 obj)"],
		[0.55, 3, 6, 0.28, "trinocular_max",   "trinocular max (0.55m, 3 eye, 6 obj)"],
	]
	for i in range(5):
		var sc = scope_specs[i]
		sweep.append(_p("microscope", "%d_%s" % [i + 1, sc[4]],
			sc[5], "body_height = %.2fm, %d eyepiece, %d objective" % [sc[0], sc[1], sc[2]], "body_height",
			{
				"body_height": float(sc[0]),
				"base_width": float(sc[3]),
				"eyepiece_count": int(sc[1]),
				"objective_count": int(sc[2]),
				"light_on": true,
				"body_color": k_frame,
				"stage_color": Color(0.94, 0.94, 0.95),
				"accent_color": k_accent,
				"light_color": Color(1.0, 0.92, 0.78),
			}))

	# ── specimen_jar: jar_height × plinth × content_shape ──────────
	var jar_specs := [
		[0.25, 0.10, 0.30, "blob",     "tiny",      "tiny (0.25m, blob)"],
		[0.40, 0.14, 0.38, "tendrils", "small",     "small (0.40m, tendrils)"],
		[0.55, 0.14, 0.42, "blob",     "standard",  "standard (0.55m, blob)"],
		[0.80, 0.18, 0.50, "crystal",  "large_xl",  "large (0.80m, crystal)"],
		[1.20, 0.22, 0.62, "blob",     "monumental","monumental (1.20m, blob)"],
	]
	for i in range(5):
		var j = jar_specs[i]
		sweep.append(_p("specimen_jar", "%d_%s" % [i + 1, j[4]],
			j[5], "jar_height = %.2fm, plinth %.2fm" % [j[0], j[2]], "jar_height",
			{
				"jar_height": float(j[0]),
				"jar_radius": float(j[1]),
				"plinth_width": float(j[2]),
				"plinth_height": 0.20,
				"content_shape": j[3],
				"content_color": Color(0.40, 0.85, 0.55, 0.85),
				"content_glow": 0.8,
				"glass_color": Color(0.65, 0.78, 0.88, 0.35),
				"label_text": "SPECIMEN",
				"label_color": Color(0.95, 0.70, 0.20),
			}))

	# ── fire_extinguisher: extinguisher_height axis ────────────────
	var fe_specs := [
		[0.35, 0.060, "small_kitchen",  "small kitchen (0.35m)"],
		[0.45, 0.070, "office",         "office (0.45m)"],
		[0.55, 0.075, "standard",       "standard (0.55m)"],
		[0.70, 0.090, "warehouse",      "warehouse (0.70m)"],
		[0.95, 0.115, "industrial",     "industrial (0.95m)"],
	]
	for i in range(5):
		var fe = fe_specs[i]
		sweep.append(_p("fire_extinguisher", "%d_%s" % [i + 1, fe[2]],
			fe[3], "extinguisher_height × radius = %.2f × %.3fm" % [fe[0], fe[1]], "extinguisher_height",
			{
				"extinguisher_height": float(fe[0]),
				"extinguisher_radius": float(fe[1]),
				"body_color": Color(0.78, 0.08, 0.08),
				"accent_color": Color(0.96, 0.96, 0.96),
				"hose_visible": true,
				"wall_bracket": true,
				"label_text": "FIRE",
				"label_color": Color(0.98, 0.98, 0.98),
			}))

	# ── test_tube_rack: tube_count axis (sparse → packed) ──────────
	var ttr_specs := [
		[3,  0.20, 0.10, "trio",         "trio (3 tubes)"],
		[6,  0.32, 0.10, "six_pack",     "six-pack (6 tubes)"],
		[8,  0.40, 0.12, "eight",        "eight tubes"],
		[10, 0.50, 0.12, "ten_dense",    "ten dense"],
		[12, 0.60, 0.14, "twelve_full",  "twelve (full)"],
	]
	for i in range(5):
		var t = ttr_specs[i]
		sweep.append(_p("test_tube_rack", "%d_%s" % [i + 1, t[3]],
			t[4], "tube_count = %d, rack_width = %.2fm" % [t[0], t[1]], "tube_count",
			{
				"tube_count": int(t[0]),
				"rack_width": float(t[1]),
				"rack_depth": float(t[2]),
				"rack_height": 0.18,
				"tube_height": 0.14,
				"tube_radius": 0.012,
				"tube_content_count": int(t[0]) / 2,
				"rack_color": Color(0.78, 0.62, 0.42),
				"content_color": Color(0.45, 0.85, 0.35, 0.92),
				"accent_color": k_accent,
			}))

	# ── gas_canister: canister_height axis ─────────────────────────
	var gc_specs := [
		[0.45, 0.09, "vertical",   "personal",     "personal (0.45m)"],
		[0.65, 0.11, "vertical",   "compact",      "compact (0.65m)"],
		[0.85, 0.13, "vertical",   "standard",     "standard (0.85m)"],
		[1.10, 0.16, "vertical",   "industrial",   "industrial (1.10m)"],
		[1.40, 0.20, "horizontal", "bulk_reserve", "bulk reserve (1.40m, horiz)"],
	]
	for i in range(5):
		var gc = gc_specs[i]
		sweep.append(_p("gas_canister", "%d_%s" % [i + 1, gc[3]],
			gc[4], "canister_height × radius = %.2f × %.2fm (%s)" % [gc[0], gc[1], gc[2]], "canister_height",
			{
				"canister_height": float(gc[0]),
				"canister_radius": float(gc[1]),
				"cradle_style": gc[2],
				"body_color": Color(0.20, 0.55, 0.65),
				"cap_color": k_frame,
				"cradle_color": k_frame,
				"valve_handle_color": Color(0.78, 0.08, 0.08),
				"label_text": "GAS",
				"label_color": Color(0.98, 0.98, 0.98),
				"pressure_indicator": true,
				"pressure_color": Color(0.30, 0.85, 0.40),
			}))

	# ── palm_scanner: panel_size axis ──────────────────────────────
	var ps_specs := [
		[0.12, 0.16, "wall",   "compact",       "compact wall (0.12×0.16)"],
		[0.16, 0.22, "wall",   "small",         "small wall (0.16×0.22)"],
		[0.18, 0.24, "wall",   "standard",      "standard (0.18×0.24)"],
		[0.24, 0.32, "wall",   "large",         "large wall (0.24×0.32)"],
		[0.32, 0.45, "podium", "lectern",       "lectern podium (0.32×0.45)"],
	]
	for i in range(5):
		var ps = ps_specs[i]
		sweep.append(_p("palm_scanner", "%d_%s" % [i + 1, ps[3]],
			ps[4], "panel_width × panel_height = %.2f × %.2fm (%s)" % [ps[0], ps[1], ps[2]], "size",
			{
				"panel_width": float(ps[0]),
				"panel_height": float(ps[1]),
				"panel_depth": 0.05,
				"mounting": ps[2],
				"panel_color": k_frame,
				"scan_color": Color(0.25, 0.92, 0.45),
				"accent_color": k_accent,
				"scan_active": true,
				"label_text": "PLACE HAND",
				"text_color": Color(0.95, 0.96, 0.98),
			}))

	# ── robot_arm: arm_segment_count + pose axis (folded → reach) ──
	var ra_specs := [
		[2, PackedFloat32Array([0.0, -10.0, 15.0]),                  "two_seg_idle",   "2-segment idle"],
		[3, PackedFloat32Array([0.0, -10.0, 20.0, -10.0]),            "three_seg_idle", "3-segment idle"],
		[3, PackedFloat32Array([20.0, -35.0, 55.0, -40.0]),           "three_seg_mid",  "3-segment mid-reach"],
		[4, PackedFloat32Array([35.0, -55.0, 75.0, -45.0, 30.0]),     "four_seg_full",  "4-segment full extend"],
		[4, PackedFloat32Array([0.0, -90.0, 100.0, -45.0, -55.0]),    "four_seg_parked","4-segment parked"],
	]
	for i in range(5):
		var ra = ra_specs[i]
		sweep.append(_p("robot_arm", "%d_%s" % [i + 1, ra[2]],
			ra[3], "arm_segment_count = %d, pose = %s" % [ra[0], str(ra[1])], "arm_segment_count + pose",
			{
				"arm_segment_count": int(ra[0]),
				"segment_length": 0.32,
				"pose_angles_degrees": ra[1],
				"body_color": Color(0.86, 0.86, 0.88),
				"joint_color": k_frame,
				"accent_color": k_accent,
				"gripper_visible": true,
			}))

	# ── glove_box: box_width axis (single → collaborative) ─────────
	var gb_specs := [
		[0.6, 0.55, 0.45, 1, "single_compact",  "single-compact (0.6m, 1 glove)"],
		[0.8, 0.65, 0.50, 2, "two_glove_small", "two-glove small (0.8m, 2)"],
		[1.0, 0.75, 0.55, 2, "two_glove_std",   "two-glove standard (1.0m, 2)"],
		[1.4, 0.80, 0.60, 3, "three_glove_wide","three-glove wide (1.4m, 3)"],
		[1.8, 0.90, 0.70, 3, "industrial_3",    "industrial (1.8m, 3 gloves)"],
	]
	for i in range(5):
		var g = gb_specs[i]
		sweep.append(_p("glove_box", "%d_%s" % [i + 1, g[4]],
			g[5], "box %.1f×%.2f×%.2fm, %d glove(s)" % [g[0], g[1], g[2], g[3]], "size + glove_count",
			{
				"box_width": float(g[0]),
				"box_height": float(g[1]),
				"box_depth": float(g[2]),
				"glove_count": int(g[3]),
				"glove_radius": 0.07,
				"interior_light": true,
				"legs_visible": true,
				"leg_height": 0.85,
				"body_color": Color(0.94, 0.94, 0.95),
				"glass_color": Color(0.78, 0.85, 0.92, 0.40),
				"frame_color": k_frame,
				"accent_color": k_accent,
				"glove_color": Color(0.10, 0.10, 0.12),
			}))

	# ── autoclave: body size axis ──────────────────────────────────
	var ac_specs := [
		[0.40, 0.65, 0.50, 0.15, "compact",      "compact (0.40×0.65×0.50)"],
		[0.50, 0.80, 0.60, 0.18, "small",        "small (0.50×0.80×0.60)"],
		[0.60, 0.90, 0.70, 0.22, "standard",     "standard (0.60×0.90×0.70)"],
		[0.80, 1.10, 0.85, 0.28, "industrial",   "industrial (0.80×1.10×0.85)"],
		[1.10, 1.40, 1.00, 0.36, "twin_chamber", "twin-chamber (1.10×1.40×1.00)"],
	]
	for i in range(5):
		var ac = ac_specs[i]
		sweep.append(_p("autoclave", "%d_%s" % [i + 1, ac[4]],
			ac[5], "body %.2f×%.2f×%.2fm, door radius %.2f" % [ac[0], ac[1], ac[2], ac[3]], "body size",
			{
				"body_width": float(ac[0]),
				"body_height": float(ac[1]),
				"body_depth": float(ac[2]),
				"door_radius": float(ac[3]),
				"door_open": false,
				"status_indicator": true,
				"status_color": Color(0.30, 0.85, 0.40),
				"accent_color": k_accent,
			}))

	# ── chemistry_flask: flask_height axis ─────────────────────────
	var cf_specs := [
		[0.10, 0.030, "erlenmeyer",   "micro",     "micro (0.10m, Erlenmeyer)"],
		[0.16, 0.045, "round_bottom", "compact",   "compact (0.16m, round-bottom)"],
		[0.22, 0.065, "erlenmeyer",   "standard",  "standard (0.22m, Erlenmeyer)"],
		[0.32, 0.090, "volumetric",   "large_vol", "large volumetric (0.32m)"],
		[0.50, 0.135, "round_bottom", "demijohn",  "demijohn (0.50m, round-bottom)"],
	]
	for i in range(5):
		var cf = cf_specs[i]
		sweep.append(_p("chemistry_flask", "%d_%s" % [i + 1, cf[3]],
			cf[4], "flask_height = %.2fm, %s shape" % [cf[0], cf[2]], "flask_height",
			{
				"flask_height": float(cf[0]),
				"flask_max_radius": float(cf[1]),
				"flask_shape": cf[2],
				"content_height_fraction": 0.55,
				"content_color": Color(0.30, 0.85, 0.55, 0.85),
				"glass_color": Color(0.85, 0.92, 0.95, 0.40),
				"label_text": "",
				"has_stopper": true,
				"stopper_color": Color(0.25, 0.25, 0.28),
			}))

	# ── clamp_stand: pole_height axis ──────────────────────────────
	var cs_specs := [
		[0.30, 1, false, "desk_short",      "desk-short (0.30m, 1 clamp)"],
		[0.45, 1, true,  "small_focus",     "small focus (0.45m, 1 + flask)"],
		[0.55, 2, true,  "standard_pair",   "standard pair (0.55m, 2 clamps)"],
		[0.75, 3, true,  "tall_three",      "tall three (0.75m, 3 clamps)"],
		[1.00, 3, false, "industrial_dist", "industrial dist (1.00m, 3 clamps)"],
	]
	for i in range(5):
		var cs = cs_specs[i]
		sweep.append(_p("clamp_stand", "%d_%s" % [i + 1, cs[3]],
			cs[4], "pole_height = %.2fm, %d clamp(s)" % [cs[0], cs[1]], "pole_height",
			{
				"pole_height": float(cs[0]),
				"clamp_count": int(cs[1]),
				"holding_flask": bool(cs[2]),
				"base_color": k_frame,
				"pole_color": Color(0.80, 0.82, 0.84),
				"clamp_color": Color(0.28, 0.28, 0.32),
				"accent_color": k_accent,
			}))

	# ── iv_stand: pole_height axis (child → bariatric) ─────────────
	var iv_specs := [
		[1.20, 0.20, 4, "child",          "child (1.2m, 4 wheels)"],
		[1.40, 0.22, 5, "junior",         "junior (1.4m, 5 wheels)"],
		[1.60, 0.25, 5, "standard",       "standard (1.6m, 5 wheels)"],
		[1.85, 0.28, 5, "tall",           "tall (1.85m, 5 wheels)"],
		[2.10, 0.32, 6, "bariatric",      "bariatric (2.10m, 6 wheels)"],
	]
	for i in range(5):
		var iv = iv_specs[i]
		sweep.append(_p("iv_stand", "%d_%s" % [i + 1, iv[3]],
			iv[4], "pole_height = %.2fm, base radius %.2fm, %d wheels" % [iv[0], iv[1], iv[2]], "pole_height",
			{
				"pole_height": float(iv[0]),
				"base_radius": float(iv[1]),
				"wheel_count": int(iv[2]),
				"bag_visible": true,
				"bag_full_fraction": 0.75,
				"pole_color": Color(0.86, 0.86, 0.88),
				"bag_color": Color(0.90, 0.95, 0.98, 0.55),
				"bag_content_color": Color(0.95, 0.80, 0.45, 0.92),
				"accent_color": k_accent,
				"label_text": "IV",
			}))

	# ── lab_sink: sink_width axis (compact → double) ───────────────
	var ls_specs := [
		[0.40, 0.35, 0.85, "compact",         "compact (0.40×0.35)"],
		[0.50, 0.40, 0.90, "standard_small",  "standard small (0.50×0.40)"],
		[0.60, 0.45, 0.95, "standard",        "standard (0.60×0.45)"],
		[0.85, 0.55, 0.95, "wide",            "wide (0.85×0.55)"],
		[1.20, 0.60, 0.95, "double_basin",    "double basin (1.20×0.60)"],
	]
	for i in range(5):
		var ls = ls_specs[i]
		sweep.append(_p("lab_sink", "%d_%s" % [i + 1, ls[3]],
			ls[4], "sink_width × sink_depth = %.2f × %.2fm" % [ls[0], ls[1]], "sink_width",
			{
				"sink_width": float(ls[0]),
				"sink_depth": float(ls[1]),
				"sink_height": float(ls[2]),
				"basin_depth_factor": 0.20,
				"faucet_style": "swan_neck",
				"counter_color": Color(0.94, 0.94, 0.96),
				"basin_color": Color(0.80, 0.82, 0.84),
				"faucet_color": Color(0.82, 0.84, 0.86),
				"accent_color": k_accent,
			}))

	# ── vacuum_chamber: jar_height × radius axis ───────────────────
	var vc_specs := [
		[0.30, 0.12, 0.18, "bell_jar_small",   "bell jar small (0.30m)"],
		[0.50, 0.18, 0.25, "bench",            "bench (0.50m)"],
		[0.65, 0.22, 0.30, "standard",         "standard (0.65m)"],
		[0.95, 0.32, 0.40, "industrial",       "industrial (0.95m)"],
		[1.40, 0.45, 0.55, "monumental",       "monumental (1.40m)"],
	]
	for i in range(5):
		var vc = vc_specs[i]
		sweep.append(_p("vacuum_chamber", "%d_%s" % [i + 1, vc[3]],
			vc[4], "jar_height = %.2fm, jar_radius = %.2fm" % [vc[0], vc[1]], "jar_height",
			{
				"jar_height": float(vc[0]),
				"jar_radius": float(vc[1]),
				"platform_radius": float(vc[2]),
				"platform_height": 0.10,
				"pressure_status": "vacuum",
				"specimen_visible": true,
				"interior_glow": 0.6,
				"glass_color": Color(0.78, 0.85, 0.92, 0.30),
				"platform_color": k_frame,
				"interior_color": Color(0.65, 0.85, 1.0),
				"specimen_color": Color(0.40, 0.85, 0.55, 0.92),
				"accent_color": k_accent,
			}))

	# ── electrical_panel: panel size × breaker_count axis ──────────
	var ep_specs := [
		[0.30, 0.40, 6,  "junction",            "junction (0.30×0.40, 6 breakers)"],
		[0.38, 0.55, 8,  "small_panel",         "small panel (0.38×0.55, 8)"],
		[0.45, 0.65, 12, "standard",            "standard (0.45×0.65, 12)"],
		[0.60, 0.85, 18, "large",               "large (0.60×0.85, 18)"],
		[0.75, 1.10, 24, "main_distribution",   "main distribution (0.75×1.10, 24)"],
	]
	for i in range(5):
		var ep = ep_specs[i]
		sweep.append(_p("electrical_panel", "%d_%s" % [i + 1, ep[3]],
			ep[4], "panel %.2f × %.2fm, %d breakers" % [ep[0], ep[1], ep[2]], "size + breakers",
			{
				"panel_width": float(ep[0]),
				"panel_height": float(ep[1]),
				"panel_depth": 0.08,
				"breaker_count": int(ep[2]),
				"breakers_on_count": int(int(ep[2]) * 2 / 3),
				"door_open": true,
				"panel_color": Color(0.78, 0.80, 0.82),
				"door_color": k_frame,
				"breaker_color": Color(0.08, 0.08, 0.10),
				"breaker_lever_color": Color(0.94, 0.94, 0.95),
				"status_color": Color(0.30, 0.85, 0.40),
				"accent_color": Color(0.98, 0.78, 0.12),
				"signage_text": "PANEL",
			}))

	# ── floor_grate: grate_width × bar_count axis ──────────────────
	var fg_specs := [
		[0.60, 0.60, 4,  4,  "small_inspection", "small (0.6×0.6, 4×4 bars)"],
		[1.00, 1.00, 8,  8,  "standard",         "standard (1.0×1.0, 8×8)"],
		[1.50, 1.00, 12, 8,  "long_run",         "long run (1.5×1.0, 12×8)"],
		[2.00, 1.50, 16, 12, "wide_platform",    "wide platform (2.0×1.5, 16×12)"],
		[3.00, 2.00, 24, 16, "factory_floor",    "factory floor (3.0×2.0, 24×16)"],
	]
	for i in range(5):
		var fg = fg_specs[i]
		sweep.append(_p("floor_grate", "%d_%s" % [i + 1, fg[4]],
			fg[5], "grate %.1f × %.1fm, lattice %d × %d bars" % [fg[0], fg[1], fg[2], fg[3]], "grate size + bar_count",
			{
				"grate_width": float(fg[0]),
				"grate_depth": float(fg[1]),
				"grate_height": 0.05,
				"bar_count_x": int(fg[2]),
				"bar_count_z": int(fg[3]),
				"bar_color": Color(0.20, 0.22, 0.25),
				"frame_color": Color(0.14, 0.14, 0.16),
				"accent_color": k_accent,
				"frame_visible": true,
				"accent_visible": false,
			}))

	# ── oscilloscope: body_width axis (compact → wide) ─────────────
	var osc_specs := [
		[0.28, 0.18, 0.22, "compact",    "compact (0.28m)"],
		[0.35, 0.22, 0.26, "bench",      "bench (0.35m)"],
		[0.45, 0.25, 0.30, "standard",   "standard (0.45m)"],
		[0.60, 0.32, 0.36, "wide",       "wide (0.60m)"],
		[0.85, 0.42, 0.42, "lab_grade",  "lab-grade (0.85m)"],
	]
	for i in range(5):
		var osc = osc_specs[i]
		sweep.append(_p("oscilloscope", "%d_%s" % [i + 1, osc[3]],
			osc[4], "body %.2f × %.2f × %.2fm" % [osc[0], osc[1], osc[2]], "body_width",
			{
				"body_width": float(osc[0]),
				"body_height": float(osc[1]),
				"body_depth": float(osc[2]),
				"waveform_shape": "composite",
				"waveform_frequency": 3,
				"waveform_color": Color(0.40, 0.95, 0.55),
				"grid_visible": true,
				"accent_color": k_accent,
			}))

	# ── bunsen_burner: flame_height axis (low → roaring) ───────────
	var bb_specs := [
		[0.04, 0.03, "low_pilot",      "low pilot (0.04m flame)"],
		[0.08, 0.05, "small",          "small (0.08m)"],
		[0.12, 0.06, "standard",       "standard (0.12m)"],
		[0.20, 0.08, "high",           "high (0.20m)"],
		[0.32, 0.10, "roaring",        "roaring (0.32m)"],
	]
	for i in range(5):
		var bb = bb_specs[i]
		sweep.append(_p("bunsen_burner", "%d_%s" % [i + 1, bb[2]],
			bb[3], "flame_height = %.2fm, flame_width = %.2fm" % [bb[0], bb[1]], "flame_height",
			{
				"flame_height": float(bb[0]),
				"flame_width": float(bb[1]),
				"flame_color": Color(0.40, 0.65, 1.0),
				"flame_visible": true,
				"valve_position": "medium",
				"gas_line_visible": true,
				"accent_color": k_accent,
			}))

	# ── petri_dish: dish_radius axis ───────────────────────────────
	var pd_specs := [
		[0.04, 0.015, "micro",      "micro (4cm)"],
		[0.06, 0.020, "small",      "small (6cm)"],
		[0.075, 0.025, "standard",  "standard (7.5cm)"],
		[0.11, 0.030, "large",      "large (11cm)"],
		[0.18, 0.045, "industrial", "industrial (18cm)"],
	]
	for i in range(5):
		var pd = pd_specs[i]
		sweep.append(_p("petri_dish", "%d_%s" % [i + 1, pd[2]],
			pd[3], "dish_radius = %.3fm, dish_height = %.3fm" % [pd[0], pd[1]], "dish_radius",
			{
				"dish_radius": float(pd[0]),
				"dish_height": float(pd[1]),
				"cell_pattern": "random",
				"colony_density": 0.30,
				"lid_present": true,
				"agar_color": Color(0.90, 0.92, 0.78),
				"cell_color": Color(0.20, 0.45, 0.20),
				"accent_color": k_accent,
			}))

	# ── wall_clock: clock_radius axis (wristwatch → bell tower) ────
	var wc_specs := [
		[0.06, 0.02, false, "wristwatch",   "wristwatch (6cm)"],
		[0.12, 0.03, false, "desk",         "desk (12cm)"],
		[0.18, 0.04, false, "standard",     "standard (18cm)"],
		[0.30, 0.05, false, "lobby",        "lobby (30cm)"],
		[0.50, 0.07, false, "bell_tower",   "bell tower (50cm)"],
	]
	for i in range(5):
		var wc = wc_specs[i]
		sweep.append(_p("wall_clock", "%d_%s" % [i + 1, wc[3]],
			wc[4], "clock_radius = %.2fm, depth = %.2fm" % [wc[0], wc[1]], "clock_radius",
			{
				"clock_radius": float(wc[0]),
				"clock_depth": float(wc[1]),
				"is_digital": bool(wc[2]),
				"hour_hand_angle": 60.0 + float(i) * 30.0,
				"minute_hand_angle": float(i) * 60.0,
				"second_hand_angle": float(i) * 90.0,
				"face_color": Color(0.94, 0.94, 0.95),
				"frame_color": k_frame,
				"hands_color": Color(0.10, 0.10, 0.10),
				"second_hand_color": Color(0.95, 0.20, 0.20),
				"accent_color": k_accent,
			}))

	# ── probability_box: dice_count axis ───────────────────────────
	var pb_specs := [
		[1, "single",      "single die"],
		[3, "trio",        "trio (3 dice)"],
		[5, "five_pack",   "five-pack"],
		[6, "six_full_set","six (full die set)"],
		[8, "eight_max",   "eight (max)"],
	]
	for i in range(5):
		var pb = pb_specs[i]
		var values: Array = []
		for j in range(int(pb[0])):
			values.append((j % 6) + 1)
		sweep.append(_p("probability_box", "%d_%s" % [i + 1, pb[1]],
			pb[2], "dice_count = %d" % pb[0], "dice_count",
			{
				"dice_count": int(pb[0]),
				"arrangement": "scattered",
				"face_values": PackedInt32Array(values),
				"tray_color": Color(0.78, 0.62, 0.42),
				"dice_color": Color(0.95, 0.94, 0.88),
				"dot_color": Color(0.10, 0.10, 0.10),
				"accent_color": k_accent,
			}))

	# ── map_table: obstacle_count axis (clear → maze) ──────────────
	var mt_specs := [
		[0,  "empty_clear",   "empty (0 obstacles)"],
		[3,  "sparse",        "sparse (3)"],
		[8,  "moderate",      "moderate (8)"],
		[15, "dense",         "dense (15)"],
		[24, "maze",          "maze (24)"],
	]
	for i in range(5):
		var mt = mt_specs[i]
		sweep.append(_p("map_table", "%d_%s" % [i + 1, mt[1]],
			mt[2], "obstacle_count = %d" % mt[0], "obstacle_count",
			{
				"obstacle_count": int(mt[0]),
				"path_visible": true,
				"grid_visible": true,
				"grid_size": 12,
				"table_color": Color(0.35, 0.25, 0.18),
				"map_color": Color(0.85, 0.82, 0.72),
				"path_color": Color(0.20, 0.55, 0.95),
				"marker_color": Color(0.95, 0.20, 0.20),
				"accent_color": k_accent,
			}))

	# ── pendulum: swing_angle_degrees axis ─────────────────────────
	var pe_specs := [
		[0.0,   "rest",         "at rest (θ = 0°)"],
		[10.0,  "small_angle",  "small angle (θ = 10°)"],
		[25.0,  "mid_swing",    "mid swing (θ = 25°)"],
		[40.0,  "large_swing",  "large swing (θ = 40°)"],
		[60.0,  "extreme",      "extreme (θ = 60°)"],
	]
	for i in range(5):
		var pe = pe_specs[i]
		sweep.append(_p("pendulum", "%d_%s" % [i + 1, pe[1]],
			pe[2], "swing_angle = %.1f°" % pe[0], "swing_angle_degrees",
			{
				"swing_angle_degrees": float(pe[0]),
				"stand_height": 0.55,
				"string_length": 0.40,
				"bob_radius": 0.035,
				"bob_color": Color(0.85, 0.65, 0.20),
				"bob_emission": float(i) * 0.15,
				"arc_visible": i >= 2,
				"stand_color": k_frame,
				"string_color": Color(0.10, 0.10, 0.12),
				"accent_color": k_accent,
			}))

	# ── prism: spectrum_band_count axis ────────────────────────────
	var pr_specs := [
		[3,  0.08, "low_res",       "low-res (3 bands)"],
		[5,  0.10, "five_band",     "5-band"],
		[7,  0.12, "rainbow",       "rainbow (7 bands)"],
		[10, 0.14, "high_res",      "high-res (10 bands)"],
		[18, 0.18, "near_continuous","near-continuous (18 bands)"],
	]
	for i in range(5):
		var pr = pr_specs[i]
		sweep.append(_p("prism", "%d_%s" % [i + 1, pr[2]],
			pr[3], "spectrum_band_count = %d, prism_size = %.2fm" % [pr[0], pr[1]], "spectrum_band_count",
			{
				"spectrum_band_count": int(pr[0]),
				"prism_size": float(pr[1]),
				"prism_height": float(pr[1]) * 1.8,
				"light_in_visible": true,
				"light_out_visible": true,
				"glass_color": Color(0.88, 0.92, 0.96, 0.30),
				"pedestal_visible": true,
				"pedestal_color": k_frame,
				"accent_color": k_accent,
			}))

	return sweep


func _p(prop: String, variant_id: String, label: String, subtitle: String, shape_axis: String, dna: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var d := {
		"prop": prop,
		"scene": "res://commons/artifacts/%s/%s.tscn" % [prop, prop],
		"variant_id": variant_id,
		"label": label,
		"subtitle": subtitle,
		"notes": subtitle,
		"shape_axis": shape_axis,
		"dna": dna,
	}
	for k in extra.keys():
		d[k] = extra[k]
	return d
