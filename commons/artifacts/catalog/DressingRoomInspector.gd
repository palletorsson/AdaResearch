class_name DressingRoomInspector
extends PanelContainer

## Sidebar inspector for the dressing-room viewer. Edits the schema's
## fields directly: footprint, approach/exit, allowed rotations, footing
## tile size, anchor, extras list, clearance.
##
## Emits `data_changed` whenever any control mutates the data dict —
## the viewer reacts by rebuilding the 3D staging.
## Emits `save_requested` when the user clicks Save.
## Emits `pick_mode_changed(mode)` to coordinate with click-on-tile picks.

signal data_changed
signal save_requested
signal revert_requested
signal pick_mode_changed(mode: String)

const TILE_VALUES: Array[int] = [0, 1, 2, 3, 4]
const TILE_NAMES: Dictionary = {
	0: "void", 1: "floor", 2: "wall step", 3: "plinth", 4: "wall",
}
const DIRECTIONS: Array[String] = ["north", "south", "east", "west"]
const ROTATION_OPTIONS: Array[int] = [0, 90, 180, 270]
const EXTRA_TYPES: Array[String] = ["3t", "tt", "el", "sub"]
## Improvement-tag presets — quick-select chips for what this room needs.
const NOTE_TAGS: Array[String] = [
	"needs footing",
	"needs label",
	"wrong scale",
	"needs extras",
	"rotation issue",
	"hero stage",
	"artifact-needs-fix",
	"good as-is",
]

var data: Dictionary = {}
var _saving: bool = false                       # prevents reentrant updates while we set initial values
var _pick_mode: String = "value"                # "value" or "anchor"
var _paint_value: int = 1                       # which tile value clicks paint with
var _save_status: Label
var _dirty: bool = false                        # unsaved changes flag
var _save_btn_top: Button
var _save_btn_bottom: Button
var _dirty_indicator: Label
var _section_headers: Array[Button] = []   # tracked for expand/collapse-all

# Field references — bound on _ready.
@onready var _name_label: Label
@onready var _fp_w: SpinBox
@onready var _fp_d: SpinBox
@onready var _fp_h: SpinBox
@onready var _approach: OptionButton
@onready var _exit: OptionButton
@onready var _rot_buttons: Array[CheckBox] = []
@onready var _rows_spin: SpinBox
@onready var _cols_spin: SpinBox
@onready var _value_buttons: Array[Button] = []
@onready var _anchor_btn: Button
@onready var _anchor_label: Label
@onready var _offset_spins: Array[SpinBox] = []
@onready var _extras_root: VBoxContainer
@onready var _notes_text: TextEdit
@onready var _note_tag_buttons: Array[CheckBox] = []


func _ready() -> void:
	custom_minimum_size = Vector2(400, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	# Any data mutation (footprint/extras/offset/etc.) should mark dirty.
	data_changed.connect(_mark_dirty)


func _mark_dirty() -> void:
	if _saving: return
	if not _dirty:
		_dirty = true
		_update_dirty_visuals()


func _update_dirty_visuals() -> void:
	if _dirty_indicator:
		_dirty_indicator.text = "● unsaved" if _dirty else ""
		_dirty_indicator.modulate = Color(1.0, 0.7, 0.3) if _dirty else Color(0.5, 0.5, 0.5)
	for btn in [_save_btn_top, _save_btn_bottom]:
		if btn:
			btn.text = "Save *" if _dirty else "Save"
			# Re-tint the button so it pops when dirty.
			if _dirty:
				btn.add_theme_color_override("font_color", Color(0.15, 0.18, 0.12))
				btn.add_theme_color_override("font_hover_color", Color(0.05, 0.08, 0.02))
			else:
				btn.remove_theme_color_override("font_color")
				btn.remove_theme_color_override("font_hover_color")


## Load fresh data (from disk). Resets the dirty flag.
func set_data(d: Dictionary) -> void:
	data = d
	_dirty = false
	_refresh_ui()
	_update_dirty_visuals()


## Re-bind the inspector to a (possibly mutated) data dict WITHOUT clearing
## the dirty flag. Use this after the catalog or 3D-drag updated the dict
## in place — the user's pending edits are still pending.
func sync_data(d: Dictionary) -> void:
	data = d
	_refresh_ui()
	# _refresh_ui doesn't touch _dirty, so visuals stay in sync with reality.
	_update_dirty_visuals()


# ──────────────────────────────────────────────────────────────────────
# UI construction
# ──────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Outer layout: header (sticky) + scrollable body + footer (sticky save bar).
	# PanelContainer is itself a Container — it lays out this VBox to fill
	# the panel's rect, so we DON'T set anchors here (anchors only apply
	# under non-container parents).
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(outer)

	# ── Sticky header ─────────────────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	outer.add_child(header)
	_name_label = Label.new()
	_name_label.text = "(no room)"
	_name_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.clip_text = true
	_name_label.theme_type_variation = "HeaderSmall"
	header.add_child(_name_label)
	_dirty_indicator = Label.new()
	_dirty_indicator.text = ""
	_dirty_indicator.modulate = Color(1.0, 0.7, 0.3)
	header.add_child(_dirty_indicator)
	var collapse_btn := Button.new()
	collapse_btn.text = "▶▶"
	collapse_btn.tooltip_text = "Collapse all sections."
	collapse_btn.pressed.connect(func(): _set_all_sections(false))
	header.add_child(collapse_btn)
	var expand_btn := Button.new()
	expand_btn.text = "▼▼"
	expand_btn.tooltip_text = "Expand all sections."
	expand_btn.pressed.connect(func(): _set_all_sections(true))
	header.add_child(expand_btn)
	_save_btn_top = _make_save_button("Save")
	_save_btn_top.pressed.connect(func(): emit_signal("save_requested"))
	header.add_child(_save_btn_top)

	outer.add_child(_make_separator())

	# ── Sticky quick-edit toolbar ────────────────────────────────────
	# Common edits one click away — no scrolling needed.
	var quick_label := Label.new()
	quick_label.text = "Quick edits"
	quick_label.add_theme_color_override("font_color", Color(0.62, 0.63, 0.68))
	quick_label.add_theme_font_size_override("font_size", 11)
	outer.add_child(quick_label)
	var quick_grid := GridContainer.new()
	quick_grid.columns = 4
	quick_grid.add_theme_constant_override("h_separation", 3)
	quick_grid.add_theme_constant_override("v_separation", 3)
	outer.add_child(quick_grid)

	_add_quick_button(quick_grid, "flatten",  "All footing tiles → 1 (walkable floor).",       _on_quick_flatten)
	_add_quick_button(quick_grid, "plinth",   "Anchor cell tile → 3 (plinth top).",            _on_quick_plinth)
	_add_quick_button(quick_grid, "void",     "All footing tiles → 0 (passable hole).",        _on_quick_void)
	_add_quick_button(quick_grid, "wall ring","Border tiles → 2 (wall step).",                 _on_quick_wall_ring)

	_add_quick_button(quick_grid, "Y +0.5",   "Raise artifact 0.5 m (offset.y += 0.5).",       func(): _bump_y(0.5))
	_add_quick_button(quick_grid, "Y +1",     "Raise artifact 1 m.",                            func(): _bump_y(1.0))
	_add_quick_button(quick_grid, "Y +2",     "Raise artifact 2 m.",                            func(): _bump_y(2.0))
	_add_quick_button(quick_grid, "Y -0.5",   "Lower artifact 0.5 m.",                          func(): _bump_y(-0.5))

	_add_quick_button(quick_grid, "center",   "Set offset.x and .z to 0.",                      _on_quick_center_xz)
	_add_quick_button(quick_grid, "clamp y",  "Set offset.y to 0 (sit on anchor surface).",    _on_quick_clamp_y)
	_add_quick_button(quick_grid, "reset off","Reset offset to (0, 0, 0).",                     _on_reset_artifact_offset)
	_add_quick_button(quick_grid, "fp 1×1",   "Footprint → 1×1×1 (small).",                    func(): _set_footprint(1, 1, 1))

	_add_quick_button(quick_grid, "fp 2×2",   "Footprint → 2×2×2.",                            func(): _set_footprint(2, 2, 2))
	_add_quick_button(quick_grid, "fp 3×3",   "Footprint → 3×3×3.",                            func(): _set_footprint(3, 3, 3))
	_add_quick_button(quick_grid, "rot all",  "Allow all four rotations.",                     _on_quick_rot_all)
	_add_quick_button(quick_grid, "+ 3t λ",   "Append a 3D-text label extra at offset (1,0,0).", _on_quick_add_3t)

	outer.add_child(_make_separator())

	# ── Scrollable body ───────────────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	# Editor-like dark panel background on the inspector itself.
	var panel_bg := StyleBoxFlat.new()
	panel_bg.bg_color = Color(0.13, 0.13, 0.16, 0.96)
	panel_bg.border_color = Color(0.08, 0.08, 0.10)
	panel_bg.border_width_left = 1
	panel_bg.border_width_top = 1
	panel_bg.border_width_right = 1
	panel_bg.border_width_bottom = 1
	panel_bg.content_margin_left = 6
	panel_bg.content_margin_right = 6
	panel_bg.content_margin_top = 6
	panel_bg.content_margin_bottom = 6
	add_theme_stylebox_override("panel", panel_bg)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)

	# ── Footprint ─────────────────────────────────────────────────────
	var sec_fp := _make_section("Footprint", true)
	var fp_body := _add_section(root, sec_fp)
	_fp_w = _make_spin(0.5, 8.0, 0.5)
	_fp_d = _make_spin(0.5, 8.0, 0.5)
	_fp_h = _make_spin(0.5, 8.0, 0.5)
	_fp_w.value_changed.connect(_on_footprint_changed.bind(0))
	_fp_d.value_changed.connect(_on_footprint_changed.bind(1))
	_fp_h.value_changed.connect(_on_footprint_changed.bind(2))
	fp_body.add_child(_make_property_row("width  (cells)", _fp_w))
	fp_body.add_child(_make_property_row("depth  (cells)", _fp_d))
	fp_body.add_child(_make_property_row("height (cells)", _fp_h))

	# ── Path direction ────────────────────────────────────────────────
	var sec_path := _make_section("Path", true)
	var path_body := _add_section(root, sec_path)
	_approach = _make_option_button(DIRECTIONS)
	_approach.item_selected.connect(_on_approach_changed)
	_exit = _make_option_button(DIRECTIONS)
	_exit.item_selected.connect(_on_exit_changed)
	path_body.add_child(_make_property_row("approach", _approach))
	path_body.add_child(_make_property_row("exit", _exit))

	# ── Allowed rotations ─────────────────────────────────────────────
	var sec_rot := _make_section("Allowed rotations", false)
	var rot_body := _add_section(root, sec_rot)
	var rot_row := HBoxContainer.new()
	rot_row.add_theme_constant_override("separation", 4)
	rot_body.add_child(rot_row)
	for r in ROTATION_OPTIONS:
		var cb := CheckBox.new()
		cb.text = "%d°" % r
		cb.toggled.connect(_on_rotation_toggled.bind(r))
		rot_row.add_child(cb)
		_rot_buttons.append(cb)

	# ── Footing tile editor ───────────────────────────────────────────
	var sec_foot := _make_section("Footing tiles", true)
	var foot_body := _add_section(root, sec_foot)
	_rows_spin = _make_spin(1, 11, 1)
	_rows_spin.value_changed.connect(_on_size_changed)
	_cols_spin = _make_spin(1, 11, 1)
	_cols_spin.value_changed.connect(_on_size_changed)
	foot_body.add_child(_make_property_row("rows", _rows_spin))
	foot_body.add_child(_make_property_row("cols", _cols_spin))

	foot_body.add_child(_make_subtle_label("Paint value (click a tile in 3D):"))
	var val_grid := GridContainer.new()
	val_grid.columns = 3
	val_grid.add_theme_constant_override("h_separation", 2)
	val_grid.add_theme_constant_override("v_separation", 2)
	foot_body.add_child(val_grid)
	for v in TILE_VALUES:
		var b := Button.new()
		b.text = "%d  %s" % [v, TILE_NAMES.get(v, "")]
		b.toggle_mode = true
		b.pressed.connect(_on_paint_value_pressed.bind(v))
		val_grid.add_child(b)
		_value_buttons.append(b)

	_anchor_btn = Button.new()
	_anchor_btn.text = "set anchor (click a tile)"
	_anchor_btn.toggle_mode = true
	_anchor_btn.pressed.connect(_on_anchor_mode_pressed)
	_anchor_label = Label.new()
	_anchor_label.text = "[-, -]"
	_anchor_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.7))
	foot_body.add_child(_make_property_row("mode", _anchor_btn))
	foot_body.add_child(_make_property_row("anchor", _anchor_label))

	# ── Artifact fine-offset ──────────────────────────────────────────
	var sec_off := _make_section("Artifact offset (m)", true)
	var off_body := _add_section(root, sec_off)
	off_body.add_child(_make_subtle_label("Drag the artifact in the 3D view to set this visually,\nor type values directly."))
	for axis_i in range(3):
		var sb := SpinBox.new()
		sb.min_value = -3.0
		sb.max_value = 3.0
		sb.step = 0.05
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.value_changed.connect(_on_artifact_offset_changed.bind(axis_i))
		off_body.add_child(_make_property_row(["x  (east)", "y  (up)", "z  (north)"][axis_i], sb))
		_offset_spins.append(sb)
	var off_reset := Button.new()
	off_reset.text = "reset to (0, 0, 0)"
	off_reset.pressed.connect(_on_reset_artifact_offset)
	off_body.add_child(off_reset)

	# ── Notes / improvement tags ──────────────────────────────────────
	var sec_notes := _make_section("Notes for improvement", true)
	var notes_body := _add_section(root, sec_notes)
	notes_body.add_child(_make_subtle_label("Tag what this room needs. Saved into the JSON."))
	var tag_grid := GridContainer.new()
	tag_grid.columns = 2
	tag_grid.add_theme_constant_override("h_separation", 4)
	tag_grid.add_theme_constant_override("v_separation", 2)
	notes_body.add_child(tag_grid)
	for tag in NOTE_TAGS:
		var cb := CheckBox.new()
		cb.text = tag
		cb.toggled.connect(_on_note_tag_toggled.bind(tag))
		tag_grid.add_child(cb)
		_note_tag_buttons.append(cb)
	notes_body.add_child(_make_subtle_label("Free-text notes:"))
	_notes_text = TextEdit.new()
	_notes_text.custom_minimum_size = Vector2(0, 80)
	_notes_text.placeholder_text = "what would make this dressing room sing?"
	_notes_text.text_changed.connect(_on_notes_text_changed)
	_notes_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notes_body.add_child(_notes_text)

	# ── Extras ────────────────────────────────────────────────────────
	var sec_extras := _make_section("Extras", true)
	var extras_body := _add_section(root, sec_extras)
	var add_extra_btn := Button.new()
	add_extra_btn.text = "+ add extra"
	add_extra_btn.pressed.connect(_on_add_extra)
	extras_body.add_child(add_extra_btn)
	_extras_root = VBoxContainer.new()
	_extras_root.add_theme_constant_override("separation", 4)
	extras_body.add_child(_extras_root)

	# Default selected paint button.
	_set_paint_value(1)

	# ── Sticky footer (save bar) ──────────────────────────────────────
	outer.add_child(_make_separator())
	_save_status = Label.new()
	_save_status.modulate = Color(0.7, 0.85, 0.7)
	_save_status.text = ""
	_save_status.clip_text = true
	outer.add_child(_save_status)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	outer.add_child(footer)
	var revert_btn := Button.new()
	revert_btn.text = "Revert"
	revert_btn.tooltip_text = "Reload from disk, discarding unsaved changes."
	revert_btn.pressed.connect(func(): emit_signal("revert_requested"))
	footer.add_child(revert_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	_save_btn_bottom = _make_save_button("  💾  Save dressing room  ")
	_save_btn_bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_btn_bottom.pressed.connect(func(): emit_signal("save_requested"))
	footer.add_child(_save_btn_bottom)


func _make_save_button(label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(120, 32)
	# Distinct accent so the save button reads as primary.
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.42, 0.66, 0.32)
	sb.border_color = Color(0.55, 0.78, 0.42)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.52, 0.76, 0.42)
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = Color(0.32, 0.56, 0.22)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb_hover)
	b.add_theme_stylebox_override("pressed", sb_pressed)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	return b


func _make_section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.65, 0.65, 0.72))
	l.theme_type_variation = "HeaderSmall"
	return l


func _make_subtle_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	l.theme_type_variation = "HeaderSmall"
	return l


func _make_separator() -> HSeparator:
	var s := HSeparator.new()
	return s


# ── Godot-editor-style helpers ────────────────────────────────────────

## Returns {header: Button, body: VBoxContainer}. Add the header AND the body
## to the parent in order; clicking the header toggles body.visible.
func _make_section(title: String, open := true) -> Dictionary:
	var header := Button.new()
	header.text = ("▼  " if open else "▶  ") + title
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.toggle_mode = true
	header.button_pressed = open
	header.focus_mode = Control.FOCUS_NONE
	# Editor-like header style: dark band, slightly lighter on hover.
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.17, 0.20)
	sb.border_color = Color(0.10, 0.10, 0.12)
	sb.border_width_bottom = 1
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.21, 0.21, 0.25)
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = Color(0.14, 0.14, 0.18)
	header.add_theme_stylebox_override("normal", sb)
	header.add_theme_stylebox_override("hover", sb_hover)
	header.add_theme_stylebox_override("pressed", sb_pressed)
	header.add_theme_color_override("font_color", Color(0.85, 0.86, 0.90))
	header.add_theme_font_size_override("font_size", 13)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	body.visible = open
	# Indent the body slightly with a margin container.
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.add_child(body)
	margin.visible = open

	header.toggled.connect(func(pressed):
		margin.visible = pressed
		header.text = ("▼  " if pressed else "▶  ") + title
	)
	return {"header": header, "body": body, "margin": margin}


## Property row: label on left (fixed width), control fills the rest.
func _make_property_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(110, 0)
	lbl.add_theme_color_override("font_color", Color(0.62, 0.63, 0.68))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


## Add a section to a parent VBox: header → margin(body).
func _add_section(parent: VBoxContainer, section: Dictionary) -> VBoxContainer:
	parent.add_child(section.header)
	parent.add_child(section.margin)
	_section_headers.append(section.header)
	return section.body


func _set_all_sections(open: bool) -> void:
	for h in _section_headers:
		if h.button_pressed != open:
			h.button_pressed = open
			h.emit_signal("toggled", open)


func _make_spin(min_v: float, max_v: float, step: float) -> SpinBox:
	var sb := SpinBox.new()
	sb.min_value = min_v
	sb.max_value = max_v
	sb.step = step
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sb


func _make_option_button(options: Array) -> OptionButton:
	var ob := OptionButton.new()
	for o in options:
		ob.add_item(str(o))
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return ob


# ──────────────────────────────────────────────────────────────────────
# Refresh from data → controls
# ──────────────────────────────────────────────────────────────────────

func _refresh_ui() -> void:
	_saving = true
	_name_label.text = String(data.get("lookup_name", "(unnamed)"))
	var fp: Array = data.get("footprint", [1.0, 1.0, 1.0])
	if fp.size() >= 3:
		_fp_w.value = float(fp[0])
		_fp_d.value = float(fp[1])
		_fp_h.value = float(fp[2])

	_approach.selected = max(0, DIRECTIONS.find(String(data.get("approach", "south"))))
	_exit.selected = max(0, DIRECTIONS.find(String(data.get("exit", "north"))))

	var rots_raw: Array = data.get("rotations", ["0"])
	var rots: Array[String] = []
	for r in rots_raw:
		rots.append(str(r))
	for i in range(_rot_buttons.size()):
		_rot_buttons[i].button_pressed = rots.has(str(ROTATION_OPTIONS[i]))

	var footing: Dictionary = data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	var rows: int = tiles.size()
	var cols: int = 0
	for row in tiles:
		if row is Array and row.size() > cols:
			cols = row.size()
	_rows_spin.value = max(1, rows)
	_cols_spin.value = max(1, cols)
	var anchor: Array = footing.get("anchor", [0, 0])
	_anchor_label.text = "anchor: [%d, %d]" % [int(anchor[0]), int(anchor[1])]

	var offset: Array = data.get("artifact_offset", [0.0, 0.0, 0.0])
	while offset.size() < 3:
		offset.append(0.0)
	for i in range(_offset_spins.size()):
		_offset_spins[i].value = float(offset[i])

	# Notes (tags + free-text).
	var notes: Dictionary = data.get("notes", {}) if data.get("notes") is Dictionary else {}
	var tag_list: Array = notes.get("tags", [])
	for i in range(_note_tag_buttons.size()):
		_note_tag_buttons[i].button_pressed = tag_list.has(NOTE_TAGS[i])
	if _notes_text:
		_notes_text.text = String(notes.get("text", ""))

	_rebuild_extras_list()
	_saving = false


# ──────────────────────────────────────────────────────────────────────
# Field handlers (writing back into data)
# ──────────────────────────────────────────────────────────────────────

func _on_footprint_changed(value: float, idx: int) -> void:
	if _saving: return
	var fp: Array = data.get("footprint", [1.0, 1.0, 1.0])
	while fp.size() < 3:
		fp.append(1.0)
	fp[idx] = value
	data["footprint"] = fp
	emit_signal("data_changed")


func _on_approach_changed(idx: int) -> void:
	if _saving: return
	data["approach"] = DIRECTIONS[idx]
	emit_signal("data_changed")


func _on_exit_changed(idx: int) -> void:
	if _saving: return
	data["exit"] = DIRECTIONS[idx]
	emit_signal("data_changed")


func _on_rotation_toggled(_pressed: bool, _value: int) -> void:
	if _saving: return
	# Build the rotation list from the current button states.
	var rots: Array[String] = []
	for i in range(_rot_buttons.size()):
		if _rot_buttons[i].button_pressed:
			rots.append(str(ROTATION_OPTIONS[i]))
	if rots.is_empty():
		rots = ["0"]
		_rot_buttons[0].button_pressed = true
	data["rotations"] = rots
	emit_signal("data_changed")


func _on_size_changed(_value: float) -> void:
	if _saving: return
	var rows: int = int(_rows_spin.value)
	var cols: int = int(_cols_spin.value)
	var footing: Dictionary = data.get("footing", {})
	var old_tiles: Array = footing.get("tiles", [[1]])
	var new_tiles: Array = []
	for r in range(rows):
		var new_row: Array = []
		for c in range(cols):
			var v: int = 1
			if r < old_tiles.size():
				var oldrow = old_tiles[r]
				if oldrow is Array and c < oldrow.size():
					v = int(oldrow[c])
			new_row.append(v)
		new_tiles.append(new_row)
	footing["tiles"] = new_tiles
	# Clamp anchor.
	var anchor: Array = footing.get("anchor", [0, 0])
	anchor[0] = clamp(int(anchor[0]), 0, rows - 1)
	anchor[1] = clamp(int(anchor[1]), 0, cols - 1)
	footing["anchor"] = anchor
	data["footing"] = footing
	_anchor_label.text = "anchor: [%d, %d]" % [anchor[0], anchor[1]]
	emit_signal("data_changed")


func _on_paint_value_pressed(v: int) -> void:
	_set_paint_value(v)


func _set_paint_value(v: int) -> void:
	_paint_value = v
	for i in range(_value_buttons.size()):
		_value_buttons[i].button_pressed = (TILE_VALUES[i] == v)
	# Painting always implies "value" mode, leaving anchor mode if active.
	_pick_mode = "value"
	if _anchor_btn:
		_anchor_btn.button_pressed = false
	emit_signal("pick_mode_changed", _pick_mode)


func _on_anchor_mode_pressed() -> void:
	if _anchor_btn.button_pressed:
		_pick_mode = "anchor"
		# Deselect paint values visually so user knows we're anchoring now.
		for b in _value_buttons:
			b.button_pressed = false
	else:
		_pick_mode = "value"
		_set_paint_value(_paint_value)
	emit_signal("pick_mode_changed", _pick_mode)


# Called by the viewer when the user clicks a tile in 3D.
# Returns true if the inspector handled the click (so the viewer rebuilds).
func handle_tile_click(row: int, col: int) -> bool:
	if data.is_empty():
		return false
	var footing: Dictionary = data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	if row < 0 or row >= tiles.size():
		return false
	var row_arr = tiles[row]
	if not (row_arr is Array) or col < 0 or col >= row_arr.size():
		return false
	if _pick_mode == "anchor":
		footing["anchor"] = [row, col]
		data["footing"] = footing
		_anchor_label.text = "anchor: [%d, %d]" % [row, col]
		return true
	# Paint the tile with the selected value.
	row_arr[col] = _paint_value
	tiles[row] = row_arr
	footing["tiles"] = tiles
	data["footing"] = footing
	return true


# ──────────────────────────────────────────────────────────────────────
# Extras editor
# ──────────────────────────────────────────────────────────────────────

func _rebuild_extras_list() -> void:
	for child in _extras_root.get_children():
		child.queue_free()
	var extras: Array = data.get("extras", [])
	for i in range(extras.size()):
		_extras_root.add_child(_make_extra_row(i, extras[i]))


func _make_extra_row(idx: int, extra: Variant) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var e: Dictionary = extra if extra is Dictionary else {}
	var type_btn := OptionButton.new()
	for t in EXTRA_TYPES:
		type_btn.add_item(t)
	type_btn.selected = max(0, EXTRA_TYPES.find(String(e.get("type", "3t"))))
	type_btn.item_selected.connect(_on_extra_type_changed.bind(idx))
	row.add_child(type_btn)

	var content := LineEdit.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.placeholder_text = "text / key / params"
	content.text = String(e.get("text", e.get("key", e.get("params", e.get("value", "")))))
	content.text_submitted.connect(func(t): _set_extra_content(idx, t))
	content.focus_exited.connect(func(): _set_extra_content(idx, content.text))
	row.add_child(content)

	var off: Array = e.get("offset", [0, 0, 0])
	for axis_i in range(3):
		var sb := SpinBox.new()
		sb.min_value = -8
		sb.max_value = 8
		sb.step = 1
		sb.value = float(off[axis_i]) if axis_i < off.size() else 0.0
		sb.custom_minimum_size = Vector2(48, 0)
		sb.value_changed.connect(_on_extra_offset_changed.bind(idx, axis_i))
		row.add_child(sb)

	var del_btn := Button.new()
	del_btn.text = "x"
	del_btn.pressed.connect(_on_remove_extra.bind(idx))
	row.add_child(del_btn)

	return row


func _on_add_extra() -> void:
	var extras: Array = data.get("extras", [])
	extras.append({"type": "3t", "text": "label", "offset": [0, 1, 0]})
	data["extras"] = extras
	_rebuild_extras_list()
	emit_signal("data_changed")


func _on_extra_type_changed(new_idx: int, extra_idx: int) -> void:
	var extras: Array = data.get("extras", [])
	if extra_idx >= extras.size(): return
	var e: Dictionary = extras[extra_idx] if extras[extra_idx] is Dictionary else {}
	var new_type: String = EXTRA_TYPES[new_idx]
	# Migrate the content key so the existing text becomes the new field.
	var existing: String = String(e.get("text", e.get("key", e.get("params", e.get("value", "")))))
	for k in ["text", "key", "params", "value"]:
		e.erase(k)
	e["type"] = new_type
	match new_type:
		"3t": e["text"] = existing
		"tt": e["key"] = existing
		"el": e["params"] = existing if existing != "" else "3:1"
		_:   e["value"] = existing
	extras[extra_idx] = e
	data["extras"] = extras
	emit_signal("data_changed")


func _set_extra_content(extra_idx: int, value: String) -> void:
	var extras: Array = data.get("extras", [])
	if extra_idx >= extras.size(): return
	var e: Dictionary = extras[extra_idx] if extras[extra_idx] is Dictionary else {}
	match String(e.get("type", "3t")):
		"3t": e["text"] = value
		"tt": e["key"] = value
		"el": e["params"] = value
		_:   e["value"] = value
	extras[extra_idx] = e
	data["extras"] = extras
	emit_signal("data_changed")


func _on_extra_offset_changed(value: float, extra_idx: int, axis: int) -> void:
	var extras: Array = data.get("extras", [])
	if extra_idx >= extras.size(): return
	var e: Dictionary = extras[extra_idx] if extras[extra_idx] is Dictionary else {}
	var off: Array = e.get("offset", [0, 0, 0])
	while off.size() < 3:
		off.append(0)
	off[axis] = int(value)
	e["offset"] = off
	extras[extra_idx] = e
	data["extras"] = extras
	emit_signal("data_changed")


func _on_artifact_offset_changed(value: float, axis: int) -> void:
	if _saving: return
	var offset: Array = data.get("artifact_offset", [0.0, 0.0, 0.0])
	while offset.size() < 3:
		offset.append(0.0)
	offset[axis] = value
	data["artifact_offset"] = offset
	emit_signal("data_changed")


func _on_reset_artifact_offset() -> void:
	data["artifact_offset"] = [0.0, 0.0, 0.0]
	for sb in _offset_spins:
		_saving = true
		sb.value = 0.0
		_saving = false
	emit_signal("data_changed")


# Called by the catalog while the user is dragging the artifact in 3D.
# Updates only the data + offset spin boxes (no rebuild — the catalog
# is moving the node directly during the drag for smoothness).
func set_artifact_offset_silent(offset: Vector3) -> void:
	data["artifact_offset"] = [offset.x, offset.y, offset.z]
	_saving = true
	if _offset_spins.size() >= 3:
		_offset_spins[0].value = offset.x
		_offset_spins[1].value = offset.y
		_offset_spins[2].value = offset.z
	_saving = false


func _on_note_tag_toggled(_pressed: bool, _tag: String) -> void:
	if _saving: return
	var notes: Dictionary = data.get("notes", {}) if data.get("notes") is Dictionary else {}
	var tag_list: Array = []
	for i in range(_note_tag_buttons.size()):
		if _note_tag_buttons[i].button_pressed:
			tag_list.append(NOTE_TAGS[i])
	notes["tags"] = tag_list
	# Preserve free-text already present.
	if not notes.has("text"):
		notes["text"] = ""
	data["notes"] = notes
	emit_signal("data_changed")


func _on_notes_text_changed() -> void:
	if _saving: return
	if _notes_text == null: return
	var notes: Dictionary = data.get("notes", {}) if data.get("notes") is Dictionary else {}
	notes["text"] = _notes_text.text
	if not notes.has("tags"):
		notes["tags"] = []
	data["notes"] = notes
	emit_signal("data_changed")


## Quick-edit helpers — small button factory + concrete operations.
func _add_quick_button(parent: Container, text: String, tooltip: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tooltip
	b.add_theme_font_size_override("font_size", 11)
	b.custom_minimum_size = Vector2(0, 22)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


func _on_quick_flatten() -> void:
	if data.is_empty(): return
	var footing: Dictionary = data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	for r in range(tiles.size()):
		var row = tiles[r]
		if not (row is Array): continue
		for c in range(row.size()):
			row[c] = 1
		tiles[r] = row
	footing["tiles"] = tiles
	data["footing"] = footing
	emit_signal("data_changed")


func _on_quick_plinth() -> void:
	if data.is_empty(): return
	var footing: Dictionary = data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	var anchor: Array = footing.get("anchor", [0, 0])
	var ar: int = int(anchor[0])
	var ac: int = int(anchor[1])
	if ar < tiles.size() and tiles[ar] is Array and ac < tiles[ar].size():
		tiles[ar][ac] = 3
		footing["tiles"] = tiles
		data["footing"] = footing
		emit_signal("data_changed")


func _on_quick_void() -> void:
	if data.is_empty(): return
	var footing: Dictionary = data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	for r in range(tiles.size()):
		var row = tiles[r]
		if not (row is Array): continue
		for c in range(row.size()):
			row[c] = 0
		tiles[r] = row
	footing["tiles"] = tiles
	data["footing"] = footing
	emit_signal("data_changed")


func _on_quick_wall_ring() -> void:
	if data.is_empty(): return
	var footing: Dictionary = data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	var rows: int = tiles.size()
	for r in range(rows):
		var row = tiles[r]
		if not (row is Array): continue
		for c in range(row.size()):
			if r == 0 or r == rows - 1 or c == 0 or c == row.size() - 1:
				row[c] = 2
		tiles[r] = row
	footing["tiles"] = tiles
	data["footing"] = footing
	emit_signal("data_changed")


func _bump_y(delta: float) -> void:
	if data.is_empty(): return
	var off: Array = data.get("artifact_offset", [0.0, 0.0, 0.0])
	while off.size() < 3:
		off.append(0.0)
	off[1] = clampf(float(off[1]) + delta, -3.0, 3.0)
	data["artifact_offset"] = off
	emit_signal("data_changed")


func _on_quick_center_xz() -> void:
	if data.is_empty(): return
	var off: Array = data.get("artifact_offset", [0.0, 0.0, 0.0])
	while off.size() < 3:
		off.append(0.0)
	off[0] = 0.0
	off[2] = 0.0
	data["artifact_offset"] = off
	emit_signal("data_changed")


func _on_quick_clamp_y() -> void:
	if data.is_empty(): return
	var off: Array = data.get("artifact_offset", [0.0, 0.0, 0.0])
	while off.size() < 3:
		off.append(0.0)
	off[1] = 0.0
	data["artifact_offset"] = off
	emit_signal("data_changed")


func _set_footprint(w: int, depth: int, h: int) -> void:
	if data.is_empty(): return
	data["footprint"] = [w, depth, h]
	emit_signal("data_changed")


func _on_quick_rot_all() -> void:
	if data.is_empty(): return
	data["rotations"] = ["0", "90", "180", "270"]
	emit_signal("data_changed")


func _on_quick_add_3t() -> void:
	if data.is_empty(): return
	var extras: Array = data.get("extras", [])
	extras.append({"type": "3t", "text": "label", "offset": [1, 0, 0]})
	data["extras"] = extras
	emit_signal("data_changed")


func _on_remove_extra(idx: int) -> void:
	var extras: Array = data.get("extras", [])
	if idx >= extras.size(): return
	extras.remove_at(idx)
	data["extras"] = extras
	_rebuild_extras_list()
	emit_signal("data_changed")


# ──────────────────────────────────────────────────────────────────────
# Save status display
# ──────────────────────────────────────────────────────────────────────

func set_save_status(msg: String, ok: bool = true) -> void:
	if _save_status:
		_save_status.text = msg
		_save_status.modulate = Color(0.6, 0.85, 0.6) if ok else Color(0.95, 0.55, 0.55)
	if ok:
		_dirty = false
		_update_dirty_visuals()
