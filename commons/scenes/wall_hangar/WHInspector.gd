extends PanelContainer
class_name WHInspector

## EDITABLE DNA inspector for the wall-hangar editor.
##
## Point it at a selected station piece with show_node(node) and it introspects the
## node's script @export vars and renders an editable control per property — float →
## slider + value label, int → SpinBox, bool → CheckBox, Color → ColorPickerButton,
## String → LineEdit (or OptionButton when the export is an enum). Changing a control
## writes the value back LIVE: if the node exposes apply_grid_config (the station
## convention — it sets meta config_<key>, re-reads, frees its children and REBUILDS),
## that is called with { prop : value }; otherwise the value is set directly. After a
## write the panel emits `rebuilt(node)` so the host can re-fit its selection box,
## because apply_grid_config replaces the node's children.
##
## Self-contained: builds its own dark theme, depends on no other new file.
##
## Contract (host):
##   var insp := WHInspector.new()         # add to a CanvasLayer, dock top-right
##   insp.show_node(selected)              # on select
##   insp.clear()                          # on deselect
##   insp.rebuilt.connect(_on_inspector_rebuilt)   # re-fit the selection highlight

## Emitted after a property write that may have rebuilt the node's children.
## The host should re-measure / re-fit any selection highlight on `node`.
signal rebuilt(node: Node3D)

const WIDTH := 260.0
const C_BG := Color(0.11, 0.12, 0.15, 0.97)
const C_TEXT := Color(0.87, 0.88, 0.90)
const C_ACCENT := Color(0.86, 0.40, 0.16)
const C_DIM := Color(0.6, 0.62, 0.66)
const C_FIELD := Color(0.16, 0.17, 0.21, 1.0)

## Sliders write on every value_changed; this debounce coalesces a rebuild burst so we
## don't free+rebuild the node's children on every dragged pixel.
const REBUILD_DEBOUNCE := 0.08

var _node: Node3D = null
var _vbox: VBoxContainer = null
var _debounce: Timer = null
var _pending_rebuild := false


func _ready() -> void:
	custom_minimum_size = Vector2(WIDTH, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	sb.border_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.set_border_width_all(1)
	add_theme_stylebox_override("panel", sb)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 5)
	add_child(_vbox)

	_debounce = Timer.new()
	_debounce.one_shot = true
	_debounce.wait_time = REBUILD_DEBOUNCE
	_debounce.timeout.connect(_flush_rebuild)
	add_child(_debounce)

	clear()


# ── Public API ────────────────────────────────────────────────────────
func show_node(node: Node3D) -> void:
	_node = node
	_clear_children()
	if node == null or not is_instance_valid(node):
		_empty()
		return

	_add_header(node)

	var props := _editable_props(node)
	if props.is_empty():
		var l := _dim_label("no editable DNA on this piece")
		_vbox.add_child(l)
		return

	for p in props:
		_add_field(node, p)


func clear() -> void:
	_node = null
	_pending_rebuild = false
	_clear_children()
	_empty()


# ── Header (name + world AABB size) ───────────────────────────────────
func _add_header(node: Node3D) -> void:
	var title := Label.new()
	title.text = str(node.get_meta("token", node.name)).to_upper()
	title.add_theme_color_override("font_color", C_ACCENT)
	title.add_theme_font_size_override("font_size", 14)
	title.clip_text = true
	_vbox.add_child(title)

	var box := _world_aabb(node)
	var sz := _dim_label("size  %.1f × %.1f × %.1f m" % [box.size.x, box.size.y, box.size.z])
	sz.add_theme_font_size_override("font_size", 11)
	_vbox.add_child(sz)

	_vbox.add_child(_separator())


# ── Per-property editable rows ────────────────────────────────────────
func _add_field(node: Node3D, p: Dictionary) -> void:
	var prop: String = p["name"]
	var ptype: int = p["type"]
	var cur = node.get(prop)

	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 1)

	# Float: a slider with a live value label, or a SpinBox for unbounded ranges.
	if ptype == TYPE_FLOAT:
		var rng := _float_range(p)
		var lbl := _field_label(prop)
		var val := Label.new()
		val.add_theme_color_override("font_color", C_TEXT)
		val.add_theme_font_size_override("font_size", 11)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.text = "%.3f" % float(cur)
		var head := HBoxContainer.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(lbl)
		head.add_child(val)
		row.add_child(head)

		var s := HSlider.new()
		s.min_value = rng.x
		s.max_value = rng.y
		s.step = rng.z
		s.value = clampf(float(cur), rng.x, rng.y)
		s.custom_minimum_size = Vector2(0, 16)
		_style_slider(s)
		s.value_changed.connect(func(v: float):
			val.text = "%.3f" % v
			_apply(prop, v, true))
		row.add_child(s)

	# Int: a SpinBox.
	elif ptype == TYPE_INT:
		row.add_child(_field_label(prop))
		var sb := SpinBox.new()
		var ir := _int_range(p)
		sb.min_value = ir.x
		sb.max_value = ir.y
		sb.step = 1
		sb.value = int(cur)
		sb.rounded = true
		_style_spin(sb)
		sb.value_changed.connect(func(v: float): _apply(prop, int(v), false))
		row.add_child(sb)

	# Bool: a CheckBox.
	elif ptype == TYPE_BOOL:
		var cb := CheckBox.new()
		cb.text = prop
		cb.button_pressed = bool(cur)
		cb.add_theme_color_override("font_color", C_TEXT)
		cb.add_theme_font_size_override("font_size", 12)
		cb.toggled.connect(func(on: bool): _apply(prop, on, false))
		row.add_child(cb)

	# Color: a ColorPickerButton.
	elif ptype == TYPE_COLOR:
		row.add_child(_field_label(prop))
		var cp := ColorPickerButton.new()
		cp.color = cur if cur is Color else Color.WHITE
		cp.edit_alpha = false
		cp.custom_minimum_size = Vector2(0, 22)
		# Live while dragging the picker, and a final apply on popup close.
		cp.color_changed.connect(func(c: Color): _apply(prop, c, true))
		cp.popup_closed.connect(func(): _apply(prop, cp.color, false))
		row.add_child(cp)

	# String: an OptionButton when the export is an enum, else a LineEdit.
	elif ptype == TYPE_STRING or ptype == TYPE_STRING_NAME:
		var opts := _enum_options(p)
		if opts.is_empty():
			row.add_child(_field_label(prop))
			var le := LineEdit.new()
			le.text = str(cur)
			le.add_theme_color_override("font_color", C_TEXT)
			_style_field_bg(le)
			# Commit on Enter or focus-out, not on every keystroke.
			le.text_submitted.connect(func(t: String): _apply(prop, t, false))
			le.focus_exited.connect(func(): _apply(prop, le.text, false))
			row.add_child(le)
		else:
			row.add_child(_field_label(prop))
			var ob := OptionButton.new()
			var sel := -1
			for i in range(opts.size()):
				ob.add_item(str(opts[i]), i)
				if str(opts[i]) == str(cur):
					sel = i
			if sel >= 0:
				ob.select(sel)
			ob.add_theme_color_override("font_color", C_TEXT)
			ob.custom_minimum_size = Vector2(0, 22)
			ob.item_selected.connect(func(idx: int): _apply(prop, ob.get_item_text(idx), false))
			row.add_child(ob)

	else:
		# Unhandled type — show it read-only so the row count stays honest.
		row.add_child(_field_label(prop))
		row.add_child(_dim_label(str(cur)))

	_vbox.add_child(row)


# ── Write-back ────────────────────────────────────────────────────────
## Push one property change to the node. `debounce` defers the rebuilt() signal so a
## stream of slider/picker events collapses into a single host re-fit.
func _apply(prop: String, value, debounce: bool) -> void:
	if _node == null or not is_instance_valid(_node):
		return
	if _node.has_method("apply_grid_config"):
		# Grid config-readers coerce via string meta (str()/_parse_color), so a typed
		# Color must go as an "r,g,b,a" string or the edit is silently dropped; floats/
		# ints/bools round-trip through str() fine.
		var cfg_value = value
		if value is Color:
			cfg_value = "%f,%f,%f,%f" % [value.r, value.g, value.b, value.a]
		_node.apply_grid_config({prop: cfg_value})
	else:
		_node.set(prop, value)
	if debounce:
		_pending_rebuild = true
		_debounce.start()
	else:
		_pending_rebuild = false
		rebuilt.emit(_node)


func _flush_rebuild() -> void:
	if not _pending_rebuild:
		return
	_pending_rebuild = false
	if _node != null and is_instance_valid(_node):
		rebuilt.emit(_node)


# ── Introspection ─────────────────────────────────────────────────────
## The node's script @export vars, in declared order. Keeps entries flagged as both a
## script variable AND editor-visible; drops groups, categories, and _-prefixed names.
func _editable_props(node: Node) -> Array:
	var out: Array = []
	for p in node.get_property_list():
		var usage: int = int(p.get("usage", 0))
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		if (usage & PROPERTY_USAGE_EDITOR) == 0:
			continue
		# Groups / subgroups / categories carry these usage bits and no real value.
		if (usage & PROPERTY_USAGE_GROUP) != 0 or (usage & PROPERTY_USAGE_SUBGROUP) != 0 or (usage & PROPERTY_USAGE_CATEGORY) != 0:
			continue
		var pname: String = str(p.get("name", ""))
		if pname == "" or pname.begins_with("_"):
			continue
		out.append(p)
	return out


## Enum option list from a String export's hint, or [] when it is a free LineEdit.
func _enum_options(p: Dictionary) -> Array:
	if int(p.get("hint", 0)) != PROPERTY_HINT_ENUM:
		return []
	var hs := str(p.get("hint_string", ""))
	if hs.strip_edges() == "":
		return []
	var out: Array = []
	for part in hs.split(","):
		# @export_enum entries can be "Label:value"; keep the label (what the var stores).
		var label := str(part)
		var colon := label.rfind(":")
		if colon >= 0 and label.substr(colon + 1).is_valid_int():
			label = label.substr(0, colon)
		out.append(label.strip_edges())
	return out


## (min, max, step) for a float control. Honours an explicit @export_range; otherwise a
## sensible default keyed off the current magnitude so colours-of-metres both feel right.
func _float_range(p: Dictionary) -> Vector3:
	if int(p.get("hint", 0)) == PROPERTY_HINT_RANGE:
		var r := _parse_range(str(p.get("hint_string", "")))
		if r != Vector3.ZERO:
			return r
	var cur := float(_node.get(str(p["name"])) if _node != null else 0.0)
	var hi := maxf(absf(cur) * 3.0, 4.0)
	return Vector3(0.0, hi, 0.01)


func _int_range(p: Dictionary) -> Vector2:
	if int(p.get("hint", 0)) == PROPERTY_HINT_RANGE:
		var r := _parse_range(str(p.get("hint_string", "")))
		if r != Vector3.ZERO:
			return Vector2(r.x, r.y)
	return Vector2(0, 64)


## Parse a Godot range hint "min,max[,step][,suffixes…]" → (min,max,step), or ZERO.
func _parse_range(hs: String) -> Vector3:
	var parts := hs.split(",")
	if parts.size() < 2:
		return Vector3.ZERO
	if not str(parts[0]).is_valid_float() or not str(parts[1]).is_valid_float():
		return Vector3.ZERO
	var lo := float(parts[0])
	var hi := float(parts[1])
	var step := 0.01
	if parts.size() >= 3 and str(parts[2]).is_valid_float():
		step = float(parts[2])
	if step <= 0.0:
		step = 0.01
	return Vector3(lo, hi, step)


# ── World AABB (visible VisualInstance3D children, minus GPUParticles3D) ──
func _world_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var found := false
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if n is VisualInstance3D and not (n is GPUParticles3D) and (n as VisualInstance3D).is_visible_in_tree():
			var gb: AABB = (n as VisualInstance3D).global_transform * (n as VisualInstance3D).get_aabb()
			if not found:
				box = gb
				found = true
			else:
				box = box.merge(gb)
	return box if found else AABB()


# ── Small UI builders ─────────────────────────────────────────────────
func _empty() -> void:
	var l := _dim_label("nothing selected")
	_vbox.add_child(l)


func _clear_children() -> void:
	if _vbox == null:
		return
	for c in _vbox.get_children():
		c.queue_free()


func _field_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", C_DIM)
	l.add_theme_font_size_override("font_size", 11)
	return l


func _dim_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", C_DIM)
	l.add_theme_font_size_override("font_size", 12)
	return l


func _separator() -> HSeparator:
	var s := HSeparator.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_DIM.r, C_DIM.g, C_DIM.b, 0.25)
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	s.add_theme_stylebox_override("separator", sb)
	return s


func _style_field_bg(c: Control) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_FIELD
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(4)
	c.add_theme_stylebox_override("normal", sb)


func _style_field(c: Control) -> void:
	_style_field_bg(c)


func _style_spin(sb: SpinBox) -> void:
	var le := sb.get_line_edit()
	if le != null:
		le.add_theme_color_override("font_color", C_TEXT)
	_style_field_bg(le)


func _style_slider(s: HSlider) -> void:
	var grab := StyleBoxFlat.new()
	grab.bg_color = C_ACCENT
	grab.set_corner_radius_all(5)
	var area := StyleBoxFlat.new()
	area.bg_color = Color(0.30, 0.31, 0.36, 1.0)
	area.set_corner_radius_all(3)
	area.content_margin_top = 2
	area.content_margin_bottom = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55)
	fill.set_corner_radius_all(3)
	fill.content_margin_top = 2
	fill.content_margin_bottom = 2
	s.add_theme_stylebox_override("grabber_area", area)
	s.add_theme_stylebox_override("slider", area)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
