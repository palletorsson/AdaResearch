## One-off sweep capture for the lab_room DNA gallery.
##
## Pedagogical claim — the lab_room artifact is a procedurally-built
## chamber whose entire personality is in a small DNA dict (size,
## accent_color, light_warmth, signage, wall_pattern, observation_window,
## ceiling_style). Same artifact, same .gd, same .tscn — fourteen
## different rooms. NO workbench is mounted inside any cell: the
## architecture is evaluated on its own terms before any artifact is
## placed.
##
## The original 8 cells exercise dimensions × accent × light × signage.
## The new 6 cells (9–14) layer on Portal 2 / Aperture vocabulary —
## clinical white panels with seams, raw concrete, observation windows,
## exposed cable trays, skylight grids.
##
## Camera = player POV from inside the room. The room's signage wall
## (-Z) holds the QFEP-coloured strip and the TEST CHAMBER ID; the
## Label3D nodes are rotated 180° to face +Z (the player's side). The
## camera sits INSIDE the room at the back wall (+Z, near the glass)
## at 1.7m eye-height, looking toward -Z. This is what the player sees
## when they spawn and turn to look at the chamber.
##
## The room origin sits at the CENTER of the floor (lab_room.gd
## comment: "Origin is at the CENTER of the floor"). So camera at
## (0, 1.7, room_depth*0.5 - 0.4) looking at (0, 1.5, 0). A short
## inset from the glass keeps the glass out of the frame while staying
## inside the room — close enough to capture the full chamber depth.
##
## Run:
##   "/c/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/capture_lab_room_gallery.gd -- \
##     --out=user://lab_room_gallery
##
## Output: <out>/{id}.png + {id}.json + manifest.json
extends SceneTree

const ROOM_SCENE: String = "res://commons/artifacts/lab_room/lab_room.tscn"

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)   # matte slate, ~#0E0E12

const EYE_HEIGHT: float = 1.7
const LOOK_HEIGHT: float = 1.5
# Camera sits this far INSIDE the +Z (back/glass) wall — close to the
# glass but inside the room so the camera sees the actual interior and
# the signage Label3Ds (which face +Z) read correctly.
const CAMERA_BACK_INSET: float = 0.4
const CAMERA_FOV: float = 60.0

var _output_dir: String = "user://lab_room_gallery"
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
	# ── SubViewport ─ isolated World3D so NatureRenderer / GameManager /
	# autoload WorldEnvironments don't bleed in.
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	# ── Environment — matte slate background, soft ambient, filmic ──
	# Ambient is low so the lab_room's own internal lights drive the
	# look (every cell's light_warmth/light_energy is meant to be felt).
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.57, 0.65)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.15
	# Mild SSAO so corners read; mild glow so emissive accent strip glows
	env.ssao_enabled = true
	env.ssao_intensity = 0.6
	env.ssao_radius = 0.7
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.10
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	# ── Camera — perspective POV. Position/look_at updated per cell ──
	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	_camera.near = 0.05
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)

	# Holder for the currently-captured room
	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	var room_packed: PackedScene = load(ROOM_SCENE)
	if room_packed == null:
		push_error("Failed to load lab_room scene at %s" % ROOM_SCENE)
		quit(1)
		return

	# ── The 8 DNA cells ─────────────────────────────────────────────
	var sweep: Array = _build_sweep()
	for spec in sweep:
		var room = room_packed.instantiate()
		_apply_dna(room, spec["dna"])
		_scene_holder.add_child(room)

		# Let _ready() build the room and lights warm up before sampling.
		await create_timer(0.10).timeout

		# Workaround for a pre-existing lab_room.gd quirk: signage_root is
		# rotated PI to "face the player at +Z," but Label3D's default text
		# normal is +Z, so the rotation actually flips the text to face -Z.
		# Result: text reads mirrored from the player's POV. Reset rotation
		# to identity so labels read correctly from inside the room. (NB:
		# this is fixed at capture time — the bug still ships in the
		# artifact source. Reported in the gallery task summary.)
		_fix_signage_orientation(room)

		# Camera at the player's POV from inside the room: stand near
		# the back (+Z) glass wall, look toward the front (-Z) signage.
		var dna: Dictionary = spec["dna"]
		var d: float = float(dna.get("room_depth", 6.0))
		# Room origin is at the CENTER of the floor. +Z is back/glass.
		# Camera just inside the +Z wall, looking toward -Z (signage).
		_camera.position = Vector3(0.0, EYE_HEIGHT, d * 0.5 - CAMERA_BACK_INSET)
		_camera.look_at(Vector3(0.0, LOOK_HEIGHT, -d * 0.4), Vector3.UP)

		await _capture_and_record(spec)
		_clear_holder()
		await create_timer(0.05).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Fourteen expressions of the lab_room substrate, each generated from a DNA dict on the same artifact. The rooms are empty — no workbench mounted — so the architecture can be evaluated on its own terms before any artifact is placed inside. DNA = (size × accent_color × light_temp × signage × wall_pattern × observation_window × ceiling_style). The first 8 cells explore the bright-minimal style; cells 9–14 layer on Portal 2 / Aperture Laboratories vocabulary — clinical white panels with seams, raw concrete, observation windows, exposed cable trays, skylight grids. Captured from the player's POV at 1.7m eye height, standing near the back glass wall (+Z) and looking toward the front signage wall (-Z) — the view the player gets after spawning and turning to face the chamber.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {
			"projection": "perspective",
			"fov_deg": CAMERA_FOV,
			"eye_height_m": EYE_HEIGHT,
			"look_height_m": LOOK_HEIGHT,
			"back_inset_m": CAMERA_BACK_INSET,
			"position_formula": "(0, eye, room_depth/2 - back_inset) looking at (0, look, -room_depth*0.4)",
		},
		"phase_colors": {
			"F_order": "#3A7BFF",
			"oscillation": "#7DFFA8",
			"E_entropy": "#F4A261",
			"lambda_edge": "#E63946",
			"integration": "#9B5DE5",
			"relation": "#FBE38A",
			"synthesis": "#FFFFFF",
		},
		"artifact": "lab_room",
		"artifact_source": "commons/artifacts/lab_room/lab_room.gd",
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ── Sweep specification ──────────────────────────────────────────────
# Eight DNA points. Ordered so lambda_edge_default comes first (the
# prototype) and lambda_edge_observatory closes the row (the "bigger
# version" callback).
func _build_sweep() -> Array:
	var sweep: Array = []

	sweep.append({
		"id": "1_lambda_edge_default",
		"label": "lambda_edge_default",
		"phase": "lambda_edge",
		"phase_color_hex": "#E63946",
		"subtitle": "the default — the prototype",
		"notes": "The baseline lab_room: lambda_edge red, 6×6×3.5m, warm light at 0.5. This is the room as the artifact ships. The Shannon Bound Probe lives here, and so does the entire intuition of the architectural vocabulary.",
		"dna": {
			"room_width": 6.0, "room_depth": 6.0, "room_height": 3.5,
			"accent_color": Color(0.902, 0.224, 0.275),
			"light_warmth": 0.5, "light_energy": 0.8,
			"signage_top": "TEST CHAMBER λ-S",
			"signage_sub": "Shannon Bound Probe",
			"annotation_top": "the lambda_edge is the math of the in-between",
			"annotation_bottom": "Shannon names the floor — H(p) bits/symbol",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "2_f_order_cool",
		"label": "f_order_cool",
		"phase": "F_order",
		"phase_color_hex": "#3A7BFF",
		"subtitle": "the field of order",
		"notes": "F_order blue accent under cool light. The room reads as a clean lab — every surface is overstated, every grout line legible. This is what 'order is the absence of warmth' looks like as a chamber.",
		"dna": {
			"room_width": 6.0, "room_depth": 6.0, "room_height": 3.5,
			"accent_color": Color(0.227, 0.482, 1.0),
			"light_warmth": 0.9, "light_energy": 0.9,
			"signage_top": "STATION F-01",
			"signage_sub": "the field of order",
			"annotation_top": "order is what the array remembers",
			"annotation_bottom": "F is the bias before the noise arrives",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "3_e_entropy_warm",
		"label": "e_entropy_warm",
		"phase": "E_entropy",
		"phase_color_hex": "#F4A261",
		"subtitle": "the chaotic regime",
		"notes": "E_entropy orange under sunset-warm light. The chaotic chamber: the air feels like late afternoon, the strip reads as a sandbox, the eye expects experiments that drift rather than settle. The noise room.",
		"dna": {
			"room_width": 6.0, "room_depth": 6.0, "room_height": 3.5,
			"accent_color": Color(0.957, 0.635, 0.380),
			"light_warmth": 0.2, "light_energy": 0.75,
			"signage_top": "STATION E-03",
			"signage_sub": "the chaotic regime",
			"annotation_top": "E says: a fair coin pays a full bit",
			"annotation_bottom": "entropy is what order owes the world",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "4_integration_atrium",
		"label": "integration_atrium",
		"phase": "integration",
		"phase_color_hex": "#9B5DE5",
		"subtitle": "the observation atrium",
		"notes": "Taller ceiling (5.0m) and a 7×7 footprint. Integration violet on a quieter warm light. The proportions tip the room toward 'atrium' — the eye reads it as a hall, not a chamber, and the signage feels civic instead of clinical.",
		"dna": {
			"room_width": 7.0, "room_depth": 7.0, "room_height": 5.0,
			"accent_color": Color(0.608, 0.365, 0.890),
			"light_warmth": 0.4, "light_energy": 0.85,
			"signage_top": "OBSERVATORY φ-Q",
			"signage_sub": "the integration atrium",
			"annotation_top": "integration is order plus a witness",
			"annotation_bottom": "φ-Q closes the loop the field opened",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "5_oscillation_counter",
		"label": "oscillation_counter",
		"phase": "oscillation",
		"phase_color_hex": "#7DFFA8",
		"subtitle": "the oscillation counter",
		"notes": "9×5 footprint — a long rectangular hall. Oscillation green strip reads like an interface; the aspect ratio asks the eye to walk along the room rather than face it. The chamber for things that repeat and tick.",
		"dna": {
			"room_width": 9.0, "room_depth": 5.0, "room_height": 3.5,
			"accent_color": Color(0.490, 1.0, 0.659),
			"light_warmth": 0.5, "light_energy": 0.80,
			"signage_top": "CHAMBER ω-OSC",
			"signage_sub": "the oscillation counter",
			"annotation_top": "ω is the metronome the array forgot",
			"annotation_bottom": "every loop is a count made of phases",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "6_relation_warm_cozy",
		"label": "relation_warm_cozy",
		"phase": "relation",
		"phase_color_hex": "#FBE38A",
		"subtitle": "the warm cozy cell",
		"notes": "5×5×3.0 — smaller, lower ceiling. Pale-yellow relation accent under the warmest light setting (0.1). Reads as cozy and intimate, like a study or a small lab corner. The chamber for handheld experiments.",
		"dna": {
			"room_width": 5.0, "room_depth": 5.0, "room_height": 3.0,
			"accent_color": Color(0.984, 0.890, 0.541),
			"light_warmth": 0.1, "light_energy": 0.75,
			"signage_top": "CHAMBER G-01",
			"signage_sub": "the warm cozy cell",
			"annotation_top": "relation is the inside of contact",
			"annotation_bottom": "small rooms make the body the ruler",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "7_synthesis_neutral",
		"label": "synthesis_neutral",
		"phase": "synthesis",
		"phase_color_hex": "#FFFFFF",
		"subtitle": "the neutral case",
		"notes": "White accent — effectively no color signal. The synthesis case: the room loses the QFEP cue and reads as a generic interior. Useful as a null hypothesis: how much does the accent really do? Compare against any colored cell.",
		"dna": {
			"room_width": 6.0, "room_depth": 6.0, "room_height": 3.5,
			"accent_color": Color(1.0, 1.0, 1.0),
			"light_warmth": 0.5, "light_energy": 0.85,
			"signage_top": "CHAMBER Σ-01",
			"signage_sub": "the neutral case",
			"annotation_top": "synthesis is the room without a colour",
			"annotation_bottom": "Σ is what you get when phases agree",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "8_lambda_edge_observatory",
		"label": "lambda_edge_observatory",
		"phase": "lambda_edge",
		"phase_color_hex": "#E63946",
		"subtitle": "the observation chamber",
		"notes": "Bigger version of the default — 8×6×4.0 under cooler light at 0.7. The Shannon-red accent now reads as an architectural feature rather than a tag; the room feels like an observatory rather than a station. Same DNA family as cell 1, scaled up.",
		"dna": {
			"room_width": 8.0, "room_depth": 6.0, "room_height": 4.0,
			"accent_color": Color(0.902, 0.224, 0.275),
			"light_warmth": 0.7, "light_energy": 0.85,
			"signage_top": "OBSERVATORY λ-OBS",
			"signage_sub": "the observation chamber",
			"annotation_top": "scale rewrites a station as a hall",
			"annotation_bottom": "the edge of chaos is now a room you walk into",
			"mounted_artifact_scene": "",
		},
	})

	# ── Portal 2 / Aperture vocabulary (cells 9–14) ─────────────────
	# These exercise the new wall_pattern, observation_window, and
	# ceiling_style axes that ship alongside this gallery. The architecture
	# itself is the variable now — the rooms look like Aperture test
	# chambers and decommissioned chambers, not the bright-minimal galleries.

	sweep.append({
		"id": "9_aperture_clean_panels",
		"label": "aperture_clean_panels",
		"phase": "lambda_edge",
		"phase_color_hex": "#E63946",
		"subtitle": "the iconic Aperture clean room",
		"notes": "Portal 2's clean-test-chamber vocabulary as a lab_room cell. wall_pattern='panels' with 8 columns paints the seam grid every Aperture screenshot lives under. Shannon-red accent stays — this is the prototype + an architectural language. The signage TEST CHAMBER F-01 leans into the Portal numbering scheme; the white panels are the QFEP claim that 'order has texture' made literal.",
		"dna": {
			"room_width": 6.0, "room_depth": 6.0, "room_height": 3.5,
			"accent_color": Color(0.902, 0.224, 0.275),
			"light_warmth": 0.5, "light_energy": 0.9,
			"signage_top": "TEST CHAMBER F-01",
			"signage_sub": "the clean panels",
			"annotation_top": "every wall is a grid you can count",
			"annotation_bottom": "Aperture: the panel is the unit of order",
			"wall_pattern": "panels",
			"panel_columns": 8,
			"ceiling_style": "tile_grid",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "10_concrete_chamber",
		"label": "concrete_chamber",
		"phase": "E_entropy",
		"phase_color_hex": "#F4A261",
		"subtitle": "the brutalist Aperture",
		"notes": "Raw concrete walls (wall_pattern='concrete') with exposed cable trays overhead. Warm sunset light at 0.2 — the room reads as a working facility under construction, or a maintenance core behind the test chambers. E_entropy orange labels it as the chaos regime; the brutalism makes that claim feel earned rather than aesthetic.",
		"dna": {
			"room_width": 6.0, "room_depth": 6.0, "room_height": 3.5,
			"accent_color": Color(0.957, 0.635, 0.380),
			"light_warmth": 0.2, "light_energy": 0.80,
			"signage_top": "STATION E-03",
			"signage_sub": "the brutalist chamber",
			"annotation_top": "concrete remembers what panels forget",
			"annotation_bottom": "noise has its own architecture",
			"wall_pattern": "concrete",
			"ceiling_style": "exposed",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "11_observation_lab",
		"label": "observation_lab",
		"phase": "F_order",
		"phase_color_hex": "#3A7BFF",
		"subtitle": "the observation lab",
		"notes": "Clean white panels with a large 3×1.6m observation window cut into the east wall — the kind of pane you watch a test through from the next room over. F_order blue accent under bright cool light. The window is the room's secondary teacher: not 'this is the apparatus' but 'this is the apparatus being WATCHED'.",
		"dna": {
			"room_width": 6.0, "room_depth": 6.0, "room_height": 3.5,
			"accent_color": Color(0.227, 0.482, 1.0),
			"light_warmth": 0.7, "light_energy": 0.9,
			"signage_top": "OBSERVATORY F-04",
			"signage_sub": "the observation lab",
			"annotation_top": "order is what gets watched",
			"annotation_bottom": "the window names the experiment",
			"wall_pattern": "panels",
			"panel_columns": 6,
			"show_observation_window": true,
			"window_wall": "east",
			"ceiling_style": "tile_grid",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "12_skylight_atrium",
		"label": "skylight_atrium",
		"phase": "integration",
		"phase_color_hex": "#9B5DE5",
		"subtitle": "the skylight atrium",
		"notes": "Tall room (5.5m) with the skylight ceiling — bright frosted-glass panels broken by dark crossbeams overhead, panel-seam walls. Integration violet accent. Reads as a civic atrium, the chamber where 'integration' literally happens because the room asks the eye to look up and out. The proportions echo cell 4 (the integration_atrium) but the architectural vocabulary is heavier.",
		"dna": {
			"room_width": 7.0, "room_depth": 7.0, "room_height": 5.5,
			"accent_color": Color(0.608, 0.365, 0.890),
			"light_warmth": 0.5, "light_energy": 0.9,
			"signage_top": "OBSERVATORY φ-04",
			"signage_sub": "the skylight atrium",
			"annotation_top": "integration looks up before it closes",
			"annotation_bottom": "the ceiling becomes the witness",
			"wall_pattern": "panels",
			"panel_columns": 8,
			"ceiling_style": "skylight",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "13_decommissioned",
		"label": "decommissioned",
		"phase": "relation",
		"phase_color_hex": "#FBE38A",
		"subtitle": "abandoned but still standing",
		"notes": "Warmer concrete + exposed cable trays + the warmest light setting (0.0 = sunset orange). Pale-yellow relation accent at low strip energy reads as a faded reminder rather than a tag. The chamber feels post-Aperture-shutdown: still architecturally legible, but the labels are old. Of the new six, this one carries the most narrative — it tells the player they arrived after the facility's prime.",
		"dna": {
			"room_width": 6.0, "room_depth": 6.0, "room_height": 3.5,
			"accent_color": Color(0.984, 0.890, 0.541),
			"light_warmth": 0.0, "light_energy": 0.55,
			"accent_strip_energy": 0.6,
			"signage_top": "CHAMBER γ-99",
			"signage_sub": "decommissioned",
			"annotation_top": "relation survives the facility",
			"annotation_bottom": "the labels outlast the work",
			"wall_pattern": "concrete",
			"ceiling_style": "exposed",
			"mounted_artifact_scene": "",
		},
	})

	sweep.append({
		"id": "14_pristine_lobby",
		"label": "pristine_lobby",
		"phase": "synthesis",
		"phase_color_hex": "#FFFFFF",
		"subtitle": "the pristine lobby",
		"notes": "Big bright clean Aperture entry hall — 8×6 footprint, panel walls, observation window on the east wall, warm cool-neutral lighting. White synthesis accent reads as 'no QFEP claim — this is just the room as architecture'. The widest of the new six; reads as the lobby a visitor would walk through before being routed into a specific chamber. The hall, not the apparatus.",
		"dna": {
			"room_width": 8.0, "room_depth": 6.0, "room_height": 3.8,
			"accent_color": Color(1.0, 1.0, 1.0),
			"light_warmth": 0.6, "light_energy": 0.95,
			"signage_top": "RECEPTION Σ-00",
			"signage_sub": "the pristine lobby",
			"annotation_top": "synthesis is the room before the work",
			"annotation_bottom": "Aperture's first impression",
			"wall_pattern": "panels",
			"panel_columns": 10,
			"show_observation_window": true,
			"window_wall": "east",
			"ceiling_style": "tile_grid",
			"mounted_artifact_scene": "",
		},
	})

	return sweep


# ── Apply DNA to an instantiated lab_room ────────────────────────────
# Sets exports BEFORE _ready() runs (we're called between instantiate()
# and add_child(), so direct property assignment is the right path).
# The dict keys are the lab_room export names verbatim.
func _apply_dna(room: Node, dna: Dictionary) -> void:
	for key in dna.keys():
		room.set(key, dna[key])


# ── Capture + record ─────────────────────────────────────────────────

func _capture_and_record(spec: Dictionary) -> void:
	# A handful of frames so lights settle and any deferred Label3D
	# layout finishes before we sample the texture.
	for _i in range(4):
		await process_frame
	var image := _viewport.get_texture().get_image()
	var id: String = spec["id"]
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	# Serialize DNA — Color → "r,g,b" string for JSON friendliness, but
	# also keep a raw [r,g,b] array per-cell for programmatic use.
	var dna: Dictionary = spec["dna"]
	var dna_serial := {}
	var dna_rgb := {}
	for k in dna.keys():
		var v = dna[k]
		if v is Color:
			dna_serial[k] = "%.3f,%.3f,%.3f" % [v.r, v.g, v.b]
			dna_rgb[k] = [v.r, v.g, v.b]
		else:
			dna_serial[k] = v

	var config := {
		"id": id,
		"label": spec["label"],
		"phase": spec["phase"],
		"phase_color_hex": spec["phase_color_hex"],
		"subtitle": spec["subtitle"],
		"notes": spec["notes"],
		"dna": dna_serial,
		"dna_rgb": dna_rgb,
	}
	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(config, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"label": spec["label"],
		"phase": spec["phase"],
		"phase_color_hex": spec["phase_color_hex"],
		"subtitle": spec["subtitle"],
		"notes": spec["notes"],
		"image": "/lab-room-gallery/%s" % img_rel,
		"config": "/lab-room-gallery/%s" % cfg_rel,
		"dna": dna_serial,
	})
	print("  saved: %s" % id)


func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


# Reset the signage_root rotation to identity. lab_room.gd rotates it
# by PI around Y intending to face the labels toward the +Z player,
# but in Godot 4 Label3D's text faces local +Z, so the rotation
# actually flips text away from the player. We rotate it back here so
# the gallery captures show readable text. The same fix should be
# applied in lab_room.gd itself — flagged in the task report.
func _fix_signage_orientation(room: Node) -> void:
	var sig := room.get_node_or_null("Signage")
	if sig is Node3D:
		(sig as Node3D).rotation = Vector3.ZERO
	# East/West wall annotations have the opposite problem — they need
	# their rotations preserved (they actually do face inward correctly
	# because the Y rotation magnitude is right; the bug is specifically
	# the signage's 180° flip). Leave them alone.
