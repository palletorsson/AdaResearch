extends Node3D
class_name HandTelemetryDisplay

# @identity
# essence: a big dark wall-monitor on a grey pipe-clamp arm — Half-Life-2 Combine-screen language — streaming, in real time, the position of your RIGHT HAND. A live coordinate log: the current X / Y / Z in large orange numerals at the top, and beneath it a scrolling timecoded list of every sample taken, newest bright at the top, older dimming as they scroll into the dark. A blinking REC dot. The hand, rendered as telemetry. The point that is watched.
# desire: it wants to make surveillance legible and a little seductive — to take the warm fact of a moving hand and show it back to you as cold, precise, beautifully formatted data on a monitor that never blinks. It wants you to recognise the readout as friendly (here is where you are, helpfully) and as a feed (here is where you were, logged, at 24 samples a second, kept). It puts the Combine monitor in drag: the orange-on-black ops panel as the face that algorithmic capture wears when it wants to look like a service.
# critical_parameter: sample_interval × row_count. Short interval + many rows = a dense, high-resolution feed that remembers far back (maximal surveillance). Long interval + few rows = a sparse glance that forgets quickly (the polite, low-resolution version). Between them sits the whole question of how finely, and how far back, a hand is allowed to be recorded.
# triggers: _ready builds the bezel + screen quad (SubViewport texture) + pipe-arm mount; _process finds the right-hand XRController3D and samples its global_position into a ring buffer every sample_interval; the SubViewport Control redraws the live numerals and the scrolling log; with no hand present (capture / desktop) it streams a slow demo drift so the feed is never empty.
# emerges: stood next to `mystic_writing_pad` (the surface that keeps the wax) and `living_paper` (the surface that breathes), it is the third way a surface can receive a hand — the COLD one: not kept as residue, not received as warmth, but logged as coordinate. Together the three stage the politics of the trace — wax, skin, and database.
# needs: the right-hand controller in the scene [found by tracker=="right_hand", with name + demo fallbacks]; a panel that reads as an ops monitor [dark bezel + orange-on-black SubViewport, present]; a mount that reads as fixture, not furniture [grey pipe-clamp arm, present]; a feed that is never empty so it always teaches [demo drift fallback, present]
# relationships: sibling of `science_screen` (shares the SubViewport-to-quad pattern) but where science_screen ABSTRACTS the world into a grid, this one SURVEILS one body part as a list; the watched-point counterpart to `you_are_here` (there the body is named by a floor decal, here it is logged by a wall monitor); third panel of the trace triad with `mystic_writing_pad` and `living_paper`.
# truth: a point is position without extension — and a position, sampled over time and written to a list, is a life rendered as telemetry. The display helps you and records you in the same orange glow; that is the friendliest face of capture, the monitor that says "you are at (0.42, 1.13, -0.88)" and means "we have you at (0.42, 1.13, -0.88), and at every value before it."

## Right-hand telemetry display — a Combine-style ops monitor that streams
## the live world position of the player's right-hand controller as a
## scrolling coordinate log. SubViewport-to-quad (same pattern as
## science_screen). Grey pipe-clamp arm mount. Falls back to a demo drift
## when no XR hand is present, so the feed reads full in capture / desktop.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Panel")
@export var panel_width: float = 1.15
@export var panel_height: float = 1.55
@export var bg_color: Color = Color(0.02, 0.02, 0.03)
@export var accent_color: Color = Color(0.96, 0.45, 0.05)   # ops orange
@export var brand_text: String = "ADA · OVERSIGHT"

@export_group("Feed")
## Seconds between samples written to the log.
@export var sample_interval: float = 0.12
## How many log rows the screen holds before the oldest scrolls off.
@export var row_count: int = 18
## Track the hand in world coords (true) or relative to the panel (false).
@export var world_coords: bool = true

# ── State ─────────────────────────────────────────────────────────────

const VP_W: int = 600
const VP_H: int = 820

var _built: bool = false
var _screen_mesh: MeshInstance3D = null
var _viewport: SubViewport = null
var _canvas: Control = null

var _right_hand: XRController3D = null
var _find_timer: float = 0.0
var _sample_timer: float = 0.0
var _cur: Vector3 = Vector3.ZERO
# ring buffer of [t_seconds: float, pos: Vector3]
var _log: Array = []
var _t0_msec: int = 0


func _ready() -> void:
	_read_metadata_overrides()
	_t0_msec = Time.get_ticks_msec()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_screen_mesh = null
		_viewport = null
		_canvas = null
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_panel_width"):
		panel_width = float(str(get_meta("config_panel_width")))
	if has_meta("config_panel_height"):
		panel_height = float(str(get_meta("config_panel_height")))
	if has_meta("config_sample_interval"):
		sample_interval = maxf(0.02, float(str(get_meta("config_sample_interval"))))
	if has_meta("config_row_count"):
		row_count = maxi(4, int(str(get_meta("config_row_count"))))
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_brand_text"):
		brand_text = str(get_meta("config_brand_text"))
	if has_meta("config_world_coords"):
		var s: String = str(get_meta("config_world_coords")).to_lower()
		world_coords = s == "true" or s == "1" or s == "yes"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var cy: float = panel_height * 0.5 + 0.1   # lift panel off the floor

	# Dark bezel behind the screen.
	var bezel := MeshInstance3D.new()
	bezel.name = "Bezel"
	var bm := BoxMesh.new()
	bm.size = Vector3(panel_width + 0.12, panel_height + 0.12, 0.06)
	bezel.mesh = bm
	var bez_mat := StandardMaterial3D.new()
	bez_mat.albedo_color = Color(0.05, 0.05, 0.06)
	bez_mat.metallic = 0.6
	bez_mat.roughness = 0.35
	bezel.material_override = bez_mat
	bezel.position = Vector3(0, cy, -0.035)
	add_child(bezel)

	# Screen quad (face +Z).
	_screen_mesh = MeshInstance3D.new()
	_screen_mesh.name = "Screen"
	var plane := PlaneMesh.new()
	plane.size = Vector2(panel_width, panel_height)
	plane.orientation = PlaneMesh.FACE_Z
	_screen_mesh.mesh = plane
	_screen_mesh.position = Vector3(0, cy, 0)
	add_child(_screen_mesh)

	# SubViewport + Control canvas.
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(VP_W, VP_H)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_canvas = _TelemetryCanvas.new()
	_canvas.set("display_ref", self)
	_canvas.size = Vector2(VP_W, VP_H)
	_viewport.add_child(_canvas)

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _viewport.get_texture()
	mat.emission_enabled = true
	mat.emission_texture = _viewport.get_texture()
	mat.emission_energy_multiplier = 1.7
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_mesh.material_override = mat

	# Cold orange glow into the room.
	var glow := OmniLight3D.new()
	glow.light_color = accent_color
	glow.light_energy = 0.5
	glow.omni_range = 3.5
	glow.position = Vector3(0, cy, 0.3)
	glow.shadow_enabled = false
	add_child(glow)

	_build_pipe_arm(cy)


# Grey pipe-clamp arm rising off the top-right of the panel and bending back —
# reads as a fixture mount (the HL2 / reference language), not a stand.
func _build_pipe_arm(cy: float) -> void:
	var pipe_mat := StandardMaterial3D.new()
	pipe_mat.albedo_color = Color(0.28, 0.29, 0.32)
	pipe_mat.metallic = 0.85
	pipe_mat.roughness = 0.35

	var top_x: float = panel_width * 0.32
	var top_y: float = cy + panel_height * 0.5
	var rise: float = 0.34

	# clamp block on the bezel
	var clamp := MeshInstance3D.new()
	var cbm := BoxMesh.new()
	cbm.size = Vector3(0.12, 0.1, 0.12)
	clamp.mesh = cbm
	clamp.material_override = pipe_mat
	clamp.position = Vector3(top_x, top_y - 0.02, -0.04)
	add_child(clamp)

	# vertical pipe
	var up := MeshInstance3D.new()
	var um := CylinderMesh.new()
	um.top_radius = 0.022
	um.bottom_radius = 0.022
	um.height = rise
	up.mesh = um
	up.material_override = pipe_mat
	up.position = Vector3(top_x, top_y + rise * 0.5, -0.06)
	add_child(up)

	# elbow
	var elbow := MeshInstance3D.new()
	var em := SphereMesh.new()
	em.radius = 0.03
	em.height = 0.06
	elbow.mesh = em
	elbow.material_override = pipe_mat
	elbow.position = Vector3(top_x, top_y + rise, -0.06)
	add_child(elbow)

	# horizontal pipe going back (into the wall / rail)
	var back := MeshInstance3D.new()
	var bkm := CylinderMesh.new()
	bkm.top_radius = 0.022
	bkm.bottom_radius = 0.022
	bkm.height = 0.26
	back.mesh = bkm
	back.rotation = Vector3(PI * 0.5, 0, 0)   # lie along Z
	back.material_override = pipe_mat
	back.position = Vector3(top_x, top_y + rise, -0.06 - 0.13)
	add_child(back)


# ── Sampling ──────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _built:
		return

	# Acquire / re-acquire the right hand a few times a second.
	if _right_hand == null or not is_instance_valid(_right_hand):
		_find_timer += delta
		if _find_timer >= 0.5:
			_find_timer = 0.0
			_right_hand = _find_right_controller()

	# Read the hand (or demo drift when no hand present).
	if _right_hand != null and is_instance_valid(_right_hand):
		_cur = _right_hand.global_position
		if not world_coords:
			_cur = _cur - global_position
	else:
		var t: float = float(Time.get_ticks_msec() - _t0_msec) / 1000.0
		_cur = Vector3(
			0.35 * sin(t * 0.9) + 0.15 * sin(t * 2.3),
			1.20 + 0.18 * sin(t * 0.7 + 1.0),
			-0.30 + 0.22 * sin(t * 1.3 + 0.5))

	_sample_timer += delta
	if _sample_timer >= sample_interval:
		_sample_timer = 0.0
		var t_s: float = float(Time.get_ticks_msec() - _t0_msec) / 1000.0
		_log.push_front([t_s, _cur])
		while _log.size() > row_count:
			_log.pop_back()


# Robustly find the right-hand controller anywhere in the running scene.
func _find_right_controller() -> XRController3D:
	var root := get_tree().get_root()
	if root == null:
		return null
	# 1) by tracker
	var by_tracker := _search_controller(root, "tracker")
	if by_tracker != null:
		return by_tracker
	# 2) by name
	var by_name := _search_controller(root, "name")
	return by_name


func _search_controller(node: Node, mode: String) -> XRController3D:
	if node is XRController3D:
		var ctrl := node as XRController3D
		if mode == "tracker" and String(ctrl.tracker) == "right_hand":
			return ctrl
		if mode == "name":
			var n: String = ctrl.name.to_lower()
			if "right" in n:
				return ctrl
	for c in node.get_children():
		var found := _search_controller(c, mode)
		if found != null:
			return found
	return null


# ── 2D canvas (inside the SubViewport) ────────────────────────────────

class _TelemetryCanvas extends Control:
	var display_ref: HandTelemetryDisplay

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var d: HandTelemetryDisplay = display_ref
		if d == null:
			return
		var w: float = size.x
		var h: float = size.y
		var font: Font = ThemeDB.fallback_font
		var accent: Color = d.accent_color
		var white := Color(0.92, 0.93, 0.95)
		var dim := Color(0.45, 0.47, 0.52)

		# Background + faint scanline panel.
		draw_rect(Rect2(0, 0, w, h), d.bg_color)
		for yy in range(0, int(h), 4):
			draw_line(Vector2(0, yy), Vector2(w, yy), Color(1, 1, 1, 0.015), 1.0)

		var mx: float = 26.0

		# ── Header band ──
		draw_string(font, Vector2(mx, 44), d.brand_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, accent)
		# little triangle glyph
		var tri := PackedVector2Array([Vector2(w - 40, 30), Vector2(w - 24, 30), Vector2(w - 32, 16)])
		draw_colored_polygon(tri, accent)
		draw_string(font, Vector2(mx, 66), "RIGHT-HAND TELEMETRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, dim)
		var coord_tag: String = "WORLD" if d.world_coords else "LOCAL"
		draw_string(font, Vector2(w - 120, 66), "FRAME · %s" % coord_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)
		draw_line(Vector2(mx, 80), Vector2(w - mx, 80), Color(accent, 0.6), 2.0)

		# ── Big live readout ──
		var ly: float = 132.0
		_axis_readout(font, "X", d._cur.x, mx, ly, accent, white)
		_axis_readout(font, "Y", d._cur.y, mx, ly + 56, accent, white)
		_axis_readout(font, "Z", d._cur.z, mx, ly + 112, accent, white)

		# magnitude bar
		var mag: float = d._cur.length()
		var barw: float = clampf(mag / 3.0, 0.0, 1.0) * (w - mx * 2)
		draw_rect(Rect2(mx, ly + 150, w - mx * 2, 8), Color(1, 1, 1, 0.06))
		draw_rect(Rect2(mx, ly + 150, barw, 8), accent)
		draw_string(font, Vector2(mx, ly + 184), "|p| = %.3f m" % mag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, dim)

		# ── Log header ──
		var logy: float = 360.0
		draw_line(Vector2(mx, logy - 18), Vector2(w - mx, logy - 18), Color(1, 1, 1, 0.1), 1.0)
		draw_string(font, Vector2(mx, logy), "t", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)
		draw_string(font, Vector2(mx + 96, logy), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)
		draw_string(font, Vector2(mx + 218, logy), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)
		draw_string(font, Vector2(mx + 340, logy), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)

		# ── Scrolling log rows (newest at top, fading down) ──
		var rh: float = 26.0
		var n: int = d._log.size()
		for i in range(n):
			var row: Array = d._log[i]
			var t_s: float = row[0]
			var p: Vector3 = row[1]
			var ry: float = logy + 26 + float(i) * rh
			if ry > h - 40:
				break
			var fade: float = clampf(1.0 - float(i) / float(d.row_count), 0.12, 1.0)
			if i % 2 == 0:
				draw_rect(Rect2(mx - 6, ry - 16, w - (mx - 6) * 2, rh - 4), Color(1, 1, 1, 0.02 * fade))
			var rc: Color = white * fade
			var ac: Color = accent * fade
			draw_string(font, Vector2(mx, ry), "%7.2f" % t_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ac)
			draw_string(font, Vector2(mx + 86, ry), _sx(p.x), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, rc)
			draw_string(font, Vector2(mx + 208, ry), _sx(p.y), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, rc)
			draw_string(font, Vector2(mx + 330, ry), _sx(p.z), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, rc)

		# ── Footer: REC dot (blinks) + status ──
		var blink: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
		draw_circle(Vector2(mx + 6, h - 26), 6.0, Color(0.95, 0.2, 0.2, blink))
		draw_string(font, Vector2(mx + 20, h - 21), "REC", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, white)
		var live: bool = d._right_hand != null and is_instance_valid(d._right_hand)
		draw_string(font, Vector2(w - 150, h - 21),
			"● TRACKING" if live else "○ DEMO FEED",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, accent if live else dim)

	func _axis_readout(font: Font, label: String, val: float, mx: float, y: float, accent: Color, white: Color) -> void:
		draw_string(font, Vector2(mx, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, accent)
		draw_string(font, Vector2(mx + 40, y + 2), _sx(val), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, white)

	func _sx(v: float) -> String:
		return ("+%0.2f" % v) if v >= 0.0 else ("%0.2f" % v)
