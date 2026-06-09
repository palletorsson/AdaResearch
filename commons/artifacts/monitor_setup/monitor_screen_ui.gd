extends Control
class_name MonitorScreenUI

# ── 2D CRT TERMINAL FACE (rendered to a SubViewport, mapped onto a 3D quad) ──────────
#
# This is the 2D scene that XRToolsViewport2DIn3D renders into a SubViewport and paints
# onto the monitor_setup info screens — the "2D-IN-3D" pattern used by dna_workstation.
# It draws a CRT terminal: a near-black phosphor background, a monospace RichTextLabel
# carrying a prompt header + body lines, a faint repeating scanline overlay, and a
# blinking block cursor. The 3D side adds the animated CRT GLASS shader OVER this
# rendered texture (rolling scanlines, flicker, bloom, aberration) — so this face stays
# crisp and capture-safe while the glass breathes on top.
#
# CONTENT comes from monitor_setup.gd via render_screen(title, lines, phosphor): the SAME
# paginated markdown title/body the Label3D path computed. This Control owns ONLY the
# look + layout of one screen; the rig owns what it says.
#
# All nodes are built procedurally in _ready() so the .tscn can stay a one-line stub and
# the JetBrains Mono font is loaded with a guarded fallback to the engine default.

# Logical render size — 4:3-ish tube. The 3D quad's metric size comes from the rig; this
# is the texture resolution the Control rasterises at.
const VIEWPORT_W: int = 480
const VIEWPORT_H: int = 320

const MONO_FONT_PATH: String = "res://commons/font/JetBrainsMono-Medium.ttf"

# Blink cadence for the cursor block (~1.5 Hz, matches the rig's old Label3D cursor).
const BLINK_PERIOD: float = 0.66

var _bg: ColorRect = null
var _scanlines: TextureRect = null
var _label: RichTextLabel = null
var _cursor: ColorRect = null
var _prompt: String = "block9:~$"

# Cached so a render_screen() before _ready completes (or before the font loads) still
# applies once the nodes exist. render_screen stores these; _ready replays them.
var _pending_title: String = ""
var _pending_lines: PackedStringArray = PackedStringArray()
var _pending_phosphor: Color = Color(0.35, 1.0, 0.45)
var _has_pending: bool = false

var _mono_font: Font = null
var _blink_accum: float = 0.0
var _cursor_on: bool = true
var _built: bool = false


func _ready() -> void:
	_build()
	_built = true
	if _has_pending:
		render_screen(_pending_title, _pending_lines, _pending_phosphor)


func _build() -> void:
	# Fill the whole viewport rect.
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = float(VIEWPORT_W)
	offset_bottom = float(VIEWPORT_H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_load_mono_font()

	# Near-black phosphor tube background.
	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.color = Color(0.02, 0.045, 0.03)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# Terminal text — monospace, left-aligned, clipped to the panel.
	_label = RichTextLabel.new()
	_label.name = "Text"
	_label.bbcode_enabled = true
	_label.fit_content = false
	_label.scroll_active = false
	_label.clip_contents = true
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A small margin so glyphs don't kiss the bezel.
	_label.offset_left = 14.0
	_label.offset_top = 10.0
	_label.offset_right = float(VIEWPORT_W) - 12.0
	_label.offset_bottom = float(VIEWPORT_H) - 12.0
	_label.anchor_right = 1.0
	_label.anchor_bottom = 1.0
	_apply_label_font()
	add_child(_label)

	# Faint scanline overlay — a repeating 1px-row texture at low alpha, drawn over text.
	_scanlines = TextureRect.new()
	_scanlines.name = "Scanlines"
	_scanlines.texture = _make_scanline_texture()
	_scanlines.stretch_mode = TextureRect.STRETCH_TILE
	_scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scanlines.modulate = Color(1, 1, 1, 0.5)
	add_child(_scanlines)

	# Blinking block cursor — phosphor-coloured, toggled in _process.
	_cursor = ColorRect.new()
	_cursor.name = "Cursor"
	_cursor.color = Color(0.35, 1.0, 0.45)
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.size = Vector2(12.0, 18.0)
	_cursor.position = Vector2(14.0, 10.0)
	add_child(_cursor)


# Load JetBrains Mono with a guarded fallback (null → RichTextLabel default font).
func _load_mono_font() -> void:
	if ResourceLoader.exists(MONO_FONT_PATH):
		var res: Resource = load(MONO_FONT_PATH)
		if res is Font:
			_mono_font = res


func _apply_label_font() -> void:
	if _label == null:
		return
	if _mono_font != null:
		_label.add_theme_font_override("normal_font", _mono_font)
		_label.add_theme_font_override("bold_font", _mono_font)
		_label.add_theme_font_override("mono_font", _mono_font)
	_label.add_theme_font_size_override("normal_font_size", 13)
	_label.add_theme_font_size_override("bold_font_size", 13)
	_label.add_theme_font_size_override("mono_font_size", 13)
	_label.add_theme_constant_override("line_separation", 2)


# ── Public API ──────────────────────────────────────────────────────────
# Fill the terminal with a prompt header (built from `title`) and the body `lines`, all
# phosphor-coloured. Called by monitor_setup.gd with the SAME paginated content the
# Label3D path used. Safe to call before _ready (cached + replayed).
func render_screen(title: String, lines: PackedStringArray, phosphor: Color) -> void:
	if not _built:
		_pending_title = title
		_pending_lines = lines
		_pending_phosphor = phosphor
		_has_pending = true
		return
	_has_pending = false

	var head_col: Color = phosphor.lerp(Color(1, 1, 1), 0.15)
	var body_col: Color = phosphor * 0.82
	body_col.a = 1.0

	# Recolour the tube + cursor to the chosen phosphor.
	if _cursor != null:
		_cursor.color = head_col

	# Build the BBCode: a prompt header line then the body lines. The header carries the
	# title (already trimmed by the rig); body lines are plain text (markdown already
	# stripped upstream), escaped so stray [ ] don't trip BBCode parsing.
	var txt: String = ""
	var header: String = _prompt + " " + title.strip_edges()
	txt += "[color=#%s]%s[/color]\n" % [head_col.to_html(false), _escape(header)]
	var body_hex: String = body_col.to_html(false)
	for i in lines.size():
		txt += "[color=#%s]%s[/color]\n" % [body_hex, _escape(str(lines[i]))]

	if _label != null:
		_label.clear()
		_label.text = txt

	# Park the cursor just below the last rendered line.
	_position_cursor(lines.size())


func set_prompt(prompt: String) -> void:
	# Optional: override the "block9:~$" prompt prefix before render_screen.
	if prompt.strip_edges() != "":
		_prompt = prompt.strip_edges()


# ── Cursor blink ────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _cursor == null:
		return
	_blink_accum += delta
	if _blink_accum >= BLINK_PERIOD:
		_blink_accum -= BLINK_PERIOD
		_cursor_on = not _cursor_on
		_cursor.visible = _cursor_on


# Drop the cursor onto the line after the last body line (clamped inside the panel).
func _position_cursor(body_line_count: int) -> void:
	if _cursor == null:
		return
	var line_h: float = 17.0          # ~font size 13 + leading
	var top_pad: float = 10.0
	var left_pad: float = 14.0
	# Header line (row 0) + body lines → cursor sits on the next row.
	var row: int = 1 + maxi(0, body_line_count)
	var cy: float = top_pad + float(row) * line_h
	var max_y: float = float(VIEWPORT_H) - _cursor.size.y - 4.0
	cy = clampf(cy, top_pad, max_y)
	_cursor.position = Vector2(left_pad, cy)


# ── Helpers ─────────────────────────────────────────────────────────────

# Escape BBCode control brackets so body/title text renders literally.
func _escape(s: String) -> String:
	return s.replace("[", "[lb]")


# A 2×4 texture: top rows opaque-ish dark, bottom rows clear → tiled vertically reads as
# 1px scanlines. Low overall alpha via the TextureRect modulate.
func _make_scanline_texture() -> ImageTexture:
	var img: Image = Image.create(2, 4, false, Image.FORMAT_RGBA8)
	var dark: Color = Color(0.0, 0.0, 0.0, 0.30)
	var clear: Color = Color(0.0, 0.0, 0.0, 0.0)
	for y in 4:
		var c: Color = dark if (y % 2 == 0) else clear
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	return ImageTexture.create_from_image(img)
