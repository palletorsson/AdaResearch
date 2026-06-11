extends Node3D
class_name InfoScreen

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a wall-mounted information display — dark plastic bezel around an emissive CRT-green screen. Half-Life kiosk crossed with an Aperture briefing display. Configurable header (amber) + body lines (terminal green) glow against the dark face. The screen reads as LIT FROM WITHIN — it's not paper, it's a device
# desire: every lab needs a way to label what the player is looking at, without breaking immersion. Voiceover would be intrusive; signage above the artifact would be didactic; an info_screen IS the artifact's nameplate, but readable, but in-world
# critical_parameter: text_lines + header_text — the screen says what it says. Change those strings and the whole semantic role of the screen changes. The screen is a CONTAINER, the text is the content
# triggers: _ready() builds bezel (4 box pieces) + emissive screen face + a baked-text header quad + a stacked baked-text block for text_lines, all painted ONTO the screen face (unshaded so they glow like a CRT). apply_grid_config() rebuilds when grid system injects DNA (including text_lines as comma-joined string)
# emerges: the room reads as an INTERFACE, not just a space. The screen makes the experiment legible. Player learns the chamber's purpose from the screen, not from a tooltip
# needs: text_lines and/or header_text (else screen is just a glow); a wall to mount against (faces +Z by default); legible glyphs baked into the surface (present: text is light emitted by the screen, not floating signage — header + body are unshaded quads proud of the face)
# relationships: pairs with large_window (one shows the experiment, one labels it); sibling to lab_room's signage (same vocabulary, different scale); cousin to whiteboard (one is hand-written, this one is computed)
# truth: the info_screen is the structural form of LABELING. The lab is not silent — it announces itself. Aperture's whole pedagogical aesthetic is "the room tells you what to do." This is that voice in artifact form

## A wall-mounted information display screen — Aperture/Portal style.
##
## Builds a dark plastic bezel around an emissive CRT-green screen face,
## with a configurable amber header and stacked terminal-green text
## lines. All flat in the XY plane, faces +Z, centered on origin.
##
## Use as: a kiosk readout, a chamber briefing screen, a status display,
## an artifact's nameplate, a tutorial text panel. The text content is
## what makes the screen specific — the geometry is the container.

# ── DNA: dimensions ───────────────────────────────────────────────────

@export_group("Dimensions")
@export var screen_width: float = 1.0
@export var screen_height: float = 0.55
@export var frame_thickness: float = 0.04

@export_group("Frame")
@export var frame_color: Color = Color(0.10, 0.10, 0.12)        # dark plastic bezel

@export_group("Screen")
@export var screen_bg_color: Color = Color(0.05, 0.08, 0.06)    # dark green-black, CRT-like
@export_range(0.0, 4.0) var screen_emission: float = 0.7        # the display glows

@export_group("Text")
@export var text_lines: PackedStringArray = PackedStringArray()
@export var text_color: Color = Color(0.40, 0.95, 0.55)         # terminal green
@export var header_text: String = ""                             # optional larger header
@export var header_color: Color = Color(0.95, 0.80, 0.20)        # amber title
@export var text_size: int = 18

# ── Constants ─────────────────────────────────────────────────────────

const SCREEN_DEPTH: float = 0.01
const FRAME_DEPTH: float = 0.05
const TEXT_PIXEL_SIZE: float = 0.0025
const TEXT_Z_OFFSET: float = 0.012   # slightly in front of screen face
const HEADER_FONT_SCALE: float = 1.55
const LINE_SPACING_FACTOR: float = 1.35

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_screen()


func _read_metadata_overrides() -> void:
	if has_meta("config_screen_width"):
		screen_width = float(str(get_meta("config_screen_width")))
	if has_meta("config_screen_height"):
		screen_height = float(str(get_meta("config_screen_height")))
	if has_meta("config_frame_thickness"):
		frame_thickness = float(str(get_meta("config_frame_thickness")))
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_screen_bg_color"):
		screen_bg_color = _parse_color(str(get_meta("config_screen_bg_color")), screen_bg_color)
	if has_meta("config_screen_emission"):
		screen_emission = float(str(get_meta("config_screen_emission")))
	if has_meta("config_text_color"):
		text_color = _parse_color(str(get_meta("config_text_color")), text_color)
	if has_meta("config_header_color"):
		header_color = _parse_color(str(get_meta("config_header_color")), header_color)
	if has_meta("config_header_text"):
		header_text = str(get_meta("config_header_text"))
	if has_meta("config_text_size"):
		text_size = int(str(get_meta("config_text_size")))
	# text_lines: comma-or-newline separated when coming through metadata
	if has_meta("config_text_lines"):
		var raw := str(get_meta("config_text_lines"))
		var parts: PackedStringArray
		if raw.contains("\n"):
			parts = raw.split("\n")
		else:
			parts = raw.split("|")
		text_lines = parts


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_screen()


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_screen() -> void:
	_built = true
	_build_frame()
	_build_screen_face()
	_build_text()


# ── Frame: 4 BoxMesh pieces forming a bezel ───────────────────────────

func _build_frame() -> void:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.roughness = 0.55
	frame_mat.metallic = 0.15

	var half_w := screen_width * 0.5
	var half_h := screen_height * 0.5
	var ft := frame_thickness

	# Top bezel
	var top := MeshInstance3D.new()
	top.name = "FrameTop"
	var tm := BoxMesh.new()
	tm.size = Vector3(screen_width + ft * 2.0, ft, FRAME_DEPTH)
	top.mesh = tm
	top.material_override = frame_mat
	top.position = Vector3(0.0, half_h + ft * 0.5, 0.0)
	add_child(top)

	# Bottom bezel
	var bottom := MeshInstance3D.new()
	bottom.name = "FrameBottom"
	var bm := BoxMesh.new()
	bm.size = Vector3(screen_width + ft * 2.0, ft, FRAME_DEPTH)
	bottom.mesh = bm
	bottom.material_override = frame_mat
	bottom.position = Vector3(0.0, -half_h - ft * 0.5, 0.0)
	add_child(bottom)

	# Left bezel
	var left := MeshInstance3D.new()
	left.name = "FrameLeft"
	var lm := BoxMesh.new()
	lm.size = Vector3(ft, screen_height, FRAME_DEPTH)
	left.mesh = lm
	left.material_override = frame_mat
	left.position = Vector3(-half_w - ft * 0.5, 0.0, 0.0)
	add_child(left)

	# Right bezel
	var right := MeshInstance3D.new()
	right.name = "FrameRight"
	var rm := BoxMesh.new()
	rm.size = Vector3(ft, screen_height, FRAME_DEPTH)
	right.mesh = rm
	right.material_override = frame_mat
	right.position = Vector3(half_w + ft * 0.5, 0.0, 0.0)
	add_child(right)


# ── Screen face: emissive CRT-style panel ─────────────────────────────

func _build_screen_face() -> void:
	var screen := MeshInstance3D.new()
	screen.name = "ScreenFace"
	var m := BoxMesh.new()
	m.size = Vector3(screen_width, screen_height, SCREEN_DEPTH)
	screen.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = screen_bg_color
	mat.emission_enabled = true
	mat.emission = screen_bg_color * 4.0
	mat.emission_energy_multiplier = screen_emission
	mat.roughness = 0.9
	mat.metallic = 0.0
	screen.material_override = mat
	screen.position = Vector3(0.0, 0.0, SCREEN_DEPTH * 0.5)
	add_child(screen)


# ── Text: header (optional) + stacked body lines, BAKED onto the face ──
# The text is painted into the screen surface as unshaded quads (the
# fire_extinguisher "integrate text into the prop" principle) instead of
# floating Label3Ds. Quads face +Z exactly like the old Label3Ds, so the
# gallery's rotation_y_180 capture flag still aligns the readout to camera.

func _build_text() -> void:
	var text_root := Node3D.new()
	text_root.name = "Text"
	# Baked QuadMesh faces +Z (readable from +Z viewers), matching the
	# original Label3D orientation. Sit just proud of the screen face.
	text_root.position = Vector3(0.0, 0.0, SCREEN_DEPTH + TEXT_Z_OFFSET + 0.004)
	add_child(text_root)

	var has_header := header_text != ""
	var n_lines := text_lines.size()

	# Vertical layout: header at top, lines stacked below — same metrics as
	# the former Label3D stack so the composition is unchanged.
	var header_size := int(round(float(text_size) * HEADER_FONT_SCALE))
	var line_step := text_size * TEXT_PIXEL_SIZE * LINE_SPACING_FACTOR
	var header_step := header_size * TEXT_PIXEL_SIZE * LINE_SPACING_FACTOR

	# Per-line glyph box (a touch shorter than the step leaves the gap).
	var header_h := header_size * TEXT_PIXEL_SIZE
	var line_h := text_size * TEXT_PIXEL_SIZE
	var max_width := screen_width * 0.9

	# Compute total stack height so we can center it inside the screen.
	var total_h := 0.0
	if has_header:
		total_h += header_step
	total_h += line_step * float(n_lines)
	var cursor_y := total_h * 0.5  # start at top

	if has_header:
		var header_q := BakedText.make_label_mesh(
			header_text, header_color, Vector2(max_width, header_h), 1400, true)
		if header_q:
			header_q.name = "Header"
			header_q.position = Vector3(0.0, cursor_y - header_step * 0.5, 0.0)
			text_root.add_child(header_q)
		cursor_y -= header_step

	if n_lines > 0:
		# One stacked block for the body. make_text_block centres itself on
		# its origin, so place that origin at the middle of the body area.
		var gap := line_h * 0.25
		var block := BakedText.make_text_block(
			Array(text_lines), text_color, line_h, max_width, gap, true)
		if block:
			block.name = "Body"
			# Body occupies the span from the current cursor (top of body)
			# down by line_step per line; centre the block on that span.
			var body_center_y := cursor_y - (line_step * float(n_lines)) * 0.5
			block.position = Vector3(0.0, body_center_y, 0.0)
			text_root.add_child(block)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
