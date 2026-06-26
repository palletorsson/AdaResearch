class_name WHHud
extends Control
## Heads-up display for the WALL HANGAR editor (commons/scenes/WallHangarEditor.gd).
##
## Self-contained, dark-Braun-styled overlay with three parts:
##   · TOP TOOLBAR — title, a live depth indicator, and Save / Load / Clear / Help buttons.
##   · HELP OVERLAY — centered panel listing every editor control as a key->action table.
##   · STATUS LINE — transient feedback under the toolbar.
##
## CONTRACT (the host editor owns the data; this node only signals + displays):
##   - Instance into a CanvasLayer.
##   - Connect `save_requested` / `load_requested` / `clear_requested` to host handlers.
##   - Call `set_depth(level)` when 0-9 is pressed; `set_status(msg)` for feedback.
##   - The root has MOUSE_FILTER_IGNORE so world clicks pass through — only the toolbar
##     buttons and the help panel capture the mouse. The toolbar title starts at x=370
##     so it never overlaps the host's own top-left hint/status (the extreme 0..360px of
##     row 0). The host can now drop that duplicate hint line.

signal save_requested
signal load_requested
signal clear_requested

# ── Dark Braun palette ────────────────────────────────────────────────
const C_BG := Color(0.11, 0.12, 0.15, 0.97)
const C_TEXT := Color(0.87, 0.88, 0.90)
const C_ACCENT := Color(0.86, 0.40, 0.16)
const C_DIM := Color(0.60, 0.62, 0.66)

const DEPTH_STEP := 0.7         # metres out from the wall per number-key level (matches editor)
const TOOLBAR_H := 40.0
const TITLE_X := 370.0          # keep clear of the host's top-left hint (0..360px)

# Every editor control, as (key, action) — drawn into the help overlay.
const CONTROLS := [
	["Palette (bottom)", "pick a piece — a ghost follows the mouse"],
	["LMB", "stamp held piece / select a piece when not holding"],
	["0 - 9", "set depth out from the wall (held or selected piece)"],
	["G", "grab the selected piece to move it"],
	["Del / Backspace", "delete the selected piece"],
	["RMB", "delete the piece under the mouse"],
	["A / D", "scroll the wall left / right"],
	["Left / Right", "scroll the wall left / right"],
	["Mouse Wheel", "scroll the wall left / right"],
	["Esc", "drop held piece / deselect"],
]

var _depth_label: Label = null
var _status_label: Label = null
var _help_panel: Control = null


func _ready() -> void:
	# Cover the whole viewport but let world clicks fall through.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_toolbar()
	_build_status()
	_build_help_overlay()
	set_depth(1)


# ── Top toolbar ───────────────────────────────────────────────────────
func _build_toolbar() -> void:
	var bar := PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE   # bar background ignores clicks; buttons opt back in
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = TOOLBAR_H
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	sb.border_width_bottom = 2
	sb.border_color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55)
	bar.add_theme_stylebox_override("panel", sb)
	add_child(bar)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	# Spacer so the title clears the host's top-left hint region (0..360px).
	var pad := Control.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.custom_minimum_size = Vector2(TITLE_X, 0)
	row.add_child(pad)

	var title := Label.new()
	title.text = "WALL HANGAR"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_color_override("font_color", C_ACCENT)
	title.add_theme_font_size_override("font_size", 16)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)

	var sep := VSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sep)

	_depth_label = Label.new()
	_depth_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_depth_label.add_theme_color_override("font_color", C_TEXT)
	_depth_label.add_theme_font_size_override("font_size", 14)
	_depth_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_depth_label.custom_minimum_size = Vector2(150, 0)
	row.add_child(_depth_label)

	# Push the buttons to the right edge.
	var grow := Control.new()
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow)

	row.add_child(_toolbar_button("Save", _on_save))
	row.add_child(_toolbar_button("Load", _on_load))
	row.add_child(_toolbar_button("Clear", _on_clear))
	row.add_child(_toolbar_button("?", toggle_help))


func _toolbar_button(label: String, handler: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.mouse_filter = Control.MOUSE_FILTER_STOP   # buttons DO capture the mouse
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(64 if label != "?" else 36, 32)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", C_ACCENT)
	b.add_theme_font_size_override("font_size", 13)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.17, 0.18, 0.21, 1.0)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.23, 0.20, 0.18, 1.0)
	hover.border_width_bottom = 2
	hover.border_color = C_ACCENT
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.30, 0.16, 0.10, 1.0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", normal)
	b.pressed.connect(handler)
	return b


# ── Status line (under the toolbar, left) ─────────────────────────────
func _build_status() -> void:
	_status_label = Label.new()
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.position = Vector2(14, TOOLBAR_H + 6.0)
	_status_label.add_theme_color_override("font_color", C_ACCENT)
	_status_label.add_theme_font_size_override("font_size", 13)
	add_child(_status_label)


# ── Help overlay (centered, hidden by default) ────────────────────────
func _build_help_overlay() -> void:
	# Full-rect dim catcher: clicking anywhere on it closes the overlay.
	_help_panel = Control.new()
	_help_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_help_panel.mouse_filter = Control.MOUSE_FILTER_STOP   # eats clicks while help is open
	_help_panel.visible = false
	add_child(_help_panel)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_help_panel.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(22)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 3
	sb.border_color = C_ACCENT
	panel.add_theme_stylebox_override("panel", sb)
	_help_panel.add_child(panel)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)

	var head := Label.new()
	head.text = "WALL HANGAR — CONTROLS"
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_color_override("font_color", C_ACCENT)
	head.add_theme_font_size_override("font_size", 18)
	col.add_child(head)

	var sub := Label.new()
	sub.text = "Front-elevation editor — scroll left/right, stamp pieces with two gravities + depth."
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.add_theme_color_override("font_color", C_DIM)
	sub.add_theme_font_size_override("font_size", 12)
	col.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)

	# Two-column key->action grid.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 7)
	col.add_child(grid)
	for pair in CONTROLS:
		grid.add_child(_help_key(str(pair[0])))
		grid.add_child(_help_action(str(pair[1])))

	var foot := Label.new()
	foot.text = "click anywhere or press ? to close"
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_theme_color_override("font_color", C_DIM)
	foot.add_theme_font_size_override("font_size", 11)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var foot_pad := Control.new()
	foot_pad.custom_minimum_size = Vector2(0, 10)
	foot_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(foot_pad)
	col.add_child(foot)

	# Any click on the catcher closes the help overlay.
	_help_panel.gui_input.connect(_on_help_clicked)


func _help_key(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", C_ACCENT)
	l.add_theme_font_size_override("font_size", 14)
	l.custom_minimum_size = Vector2(150, 0)
	return l


func _help_action(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", C_TEXT)
	l.add_theme_font_size_override("font_size", 14)
	return l


# ── Public API ────────────────────────────────────────────────────────
func set_depth(level: int) -> void:
	if _depth_label != null:
		_depth_label.text = "depth %d  ·  %.1f m" % [level, float(level) * DEPTH_STEP]


func set_status(msg: String) -> void:
	if _status_label != null:
		_status_label.text = msg


func toggle_help() -> void:
	if _help_panel != null:
		_help_panel.visible = not _help_panel.visible


# ── Internal handlers ─────────────────────────────────────────────────
func _on_save() -> void:
	save_requested.emit()


func _on_load() -> void:
	load_requested.emit()


func _on_clear() -> void:
	clear_requested.emit()


func _on_help_clicked(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
		toggle_help()
