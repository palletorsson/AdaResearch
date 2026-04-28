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
signal pick_mode_changed(mode: String)

const TILE_VALUES: Array[int] = [0, 1, 2, 3, 4]
const TILE_NAMES: Dictionary = {
	0: "void", 1: "floor", 2: "wall step", 3: "plinth", 4: "wall",
}
const DIRECTIONS: Array[String] = ["north", "south", "east", "west"]
const ROTATION_OPTIONS: Array[int] = [0, 90, 180, 270]
const EXTRA_TYPES: Array[String] = ["3t", "tt", "el", "sub"]

var data: Dictionary = {}
var _saving: bool = false                       # prevents reentrant updates while we set initial values
var _pick_mode: String = "value"                # "value" or "anchor"
var _paint_value: int = 1                       # which tile value clicks paint with
var _save_status: Label

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
@onready var _extras_root: VBoxContainer


func _ready() -> void:
	custom_minimum_size = Vector2(360, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func set_data(d: Dictionary) -> void:
	data = d
	_refresh_ui()


# ──────────────────────────────────────────────────────────────────────
# UI construction
# ──────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	# ── Title bar ─────────────────────────────────────────────────────
	var title_row := HBoxContainer.new()
	root.add_child(title_row)
	_name_label = Label.new()
	_name_label.text = "(no room)"
	_name_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.theme_type_variation = "HeaderSmall"
	title_row.add_child(_name_label)
	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(func(): emit_signal("save_requested"))
	title_row.add_child(save_btn)

	_save_status = Label.new()
	_save_status.modulate = Color(0.7, 0.85, 0.7)
	_save_status.text = ""
	root.add_child(_save_status)

	root.add_child(_make_separator())

	# ── Footprint ─────────────────────────────────────────────────────
	root.add_child(_make_section_label("Footprint (w × d × h)"))
	var fp_row := HBoxContainer.new()
	fp_row.add_theme_constant_override("separation", 4)
	root.add_child(fp_row)
	_fp_w = _make_spin(0.5, 8.0, 0.5)
	_fp_d = _make_spin(0.5, 8.0, 0.5)
	_fp_h = _make_spin(0.5, 8.0, 0.5)
	for i in range(3):
		var sb: SpinBox = [_fp_w, _fp_d, _fp_h][i]
		sb.value_changed.connect(_on_footprint_changed.bind(i))
		fp_row.add_child(sb)

	# ── Approach + exit ───────────────────────────────────────────────
	root.add_child(_make_section_label("Approach / exit"))
	var dir_row := HBoxContainer.new()
	dir_row.add_theme_constant_override("separation", 6)
	root.add_child(dir_row)
	_approach = _make_option_button(DIRECTIONS)
	_approach.item_selected.connect(_on_approach_changed)
	dir_row.add_child(_approach)
	_exit = _make_option_button(DIRECTIONS)
	_exit.item_selected.connect(_on_exit_changed)
	dir_row.add_child(_exit)

	# ── Allowed rotations ─────────────────────────────────────────────
	root.add_child(_make_section_label("Allowed rotations"))
	var rot_row := HBoxContainer.new()
	rot_row.add_theme_constant_override("separation", 4)
	root.add_child(rot_row)
	for r in ROTATION_OPTIONS:
		var cb := CheckBox.new()
		cb.text = "%d°" % r
		cb.toggled.connect(_on_rotation_toggled.bind(r))
		rot_row.add_child(cb)
		_rot_buttons.append(cb)

	# ── Footing tile editor ───────────────────────────────────────────
	root.add_child(_make_separator())
	root.add_child(_make_section_label("Footing tiles"))

	var size_row := HBoxContainer.new()
	root.add_child(size_row)
	size_row.add_child(_make_subtle_label("rows × cols:"))
	_rows_spin = _make_spin(1, 11, 1)
	_rows_spin.value_changed.connect(_on_size_changed)
	size_row.add_child(_rows_spin)
	_cols_spin = _make_spin(1, 11, 1)
	_cols_spin.value_changed.connect(_on_size_changed)
	size_row.add_child(_cols_spin)

	root.add_child(_make_subtle_label("Click a tile in the 3D view to paint it. Selected value:"))
	var val_row := HBoxContainer.new()
	val_row.add_theme_constant_override("separation", 2)
	root.add_child(val_row)
	for v in TILE_VALUES:
		var b := Button.new()
		b.text = "%d  %s" % [v, TILE_NAMES.get(v, "")]
		b.toggle_mode = true
		b.pressed.connect(_on_paint_value_pressed.bind(v))
		val_row.add_child(b)
		_value_buttons.append(b)

	var anchor_row := HBoxContainer.new()
	root.add_child(anchor_row)
	_anchor_btn = Button.new()
	_anchor_btn.text = "Set anchor (click a tile)"
	_anchor_btn.toggle_mode = true
	_anchor_btn.pressed.connect(_on_anchor_mode_pressed)
	anchor_row.add_child(_anchor_btn)
	_anchor_label = Label.new()
	_anchor_label.text = "anchor: [-, -]"
	_anchor_label.modulate = Color(0.8, 0.6, 0.7)
	anchor_row.add_child(_anchor_label)

	# ── Extras ────────────────────────────────────────────────────────
	root.add_child(_make_separator())
	var extras_header := HBoxContainer.new()
	root.add_child(extras_header)
	extras_header.add_child(_make_section_label("Extras"))
	var add_extra_btn := Button.new()
	add_extra_btn.text = "+ add"
	add_extra_btn.pressed.connect(_on_add_extra)
	extras_header.add_child(add_extra_btn)

	_extras_root = VBoxContainer.new()
	_extras_root.add_theme_constant_override("separation", 4)
	root.add_child(_extras_root)

	# Default selected paint button.
	_set_paint_value(1)


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
