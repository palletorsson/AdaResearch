extends Control
class_name CommentBoxUI

## THE SCREEN of the comment box: a title, a line of context, the text, a status
## line, a keyboard of buttons, and the last comments left here. It lives inside a
## Viewport2Din3D, so a desktop crosshair click and a VR laser click both arrive
## as plain mouse events, and the physical keyboard reaches the text on desktop
## through the viewport's input_keyboard. The on-screen keys type by inserting at
## the caret - no synthesised key events, so nothing latches and no focus is
## fought over between viewports.
##
## Focus is the contract: the text has focus only after the visitor clicks it,
## and while it does the box stands in group `ada_typing` (typing_changed). SEND,
## LEAVE, Escape, and walking away release it. Nothing here grabs focus on load,
## or every map with a box would freeze its visitor on entry.

signal comment_submitted(text: String)
signal typing_changed(typing: bool)

const W := 624
const H := 432
const INK := Color(0.11, 0.125, 0.157)
const PAPER := Color(1.0, 0.996, 0.988)
const CHROME := Color(0.984, 0.984, 0.98)
const RULE := Color(0.82, 0.84, 0.86)
const ACCENT := Color(0.059, 0.616, 0.431)
const MUTED := Color(0.36, 0.39, 0.45)
const DANGER := Color(0.75, 0.22, 0.17)
const ROWS := [
	["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
	["a", "s", "d", "f", "g", "h", "j", "k", "l", "'"],
	["z", "x", "c", "v", "b", "n", "m", ",", ".", "?"],
]

var _title: Label = null
var _context: Label = null
var _edit: TextEdit = null
var _status: Label = null
var _recent: Label = null
var _shift_btn: Button = null
var _shift := false
var _letter_keys: Array[Button] = []


func _ready() -> void:
	# a fresh Control keeps a zero rect under a preset alone: size it by hand
	position = Vector2.ZERO
	size = Vector2(W, H)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = PAPER
	bg.position = Vector2.ZERO
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var edge := ColorRect.new()
	edge.color = ACCENT
	edge.position = Vector2.ZERO
	edge.size = Vector2(W, 6)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge)

	var col := VBoxContainer.new()
	col.position = Vector2(16, 14)
	col.size = Vector2(W - 32, H - 28)
	col.add_theme_constant_override("separation", 6)
	add_child(col)

	_title = _label("Leave a comment", 24, INK)
	col.add_child(_title)
	_context = _label("", 13, MUTED)
	col.add_child(_context)

	_edit = TextEdit.new()
	_edit.custom_minimum_size = Vector2(0, 96)
	_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_edit.placeholder_text = "click here, then type"
	_edit.scroll_fit_content_height = false
	_edit.add_theme_font_size_override("font_size", 16)
	_edit.add_theme_color_override("font_color", INK)
	_edit.add_theme_color_override("font_placeholder_color", MUTED)
	_edit.add_theme_color_override("caret_color", ACCENT)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(1, 1, 1)
	box_style.border_color = RULE
	box_style.set_border_width_all(1)
	box_style.set_corner_radius_all(6)
	box_style.content_margin_left = 8
	box_style.content_margin_right = 8
	box_style.content_margin_top = 6
	box_style.content_margin_bottom = 6
	_edit.add_theme_stylebox_override("normal", box_style)
	var focus_style: StyleBoxFlat = box_style.duplicate()
	focus_style.border_color = ACCENT
	focus_style.set_border_width_all(2)
	_edit.add_theme_stylebox_override("focus", focus_style)
	_edit.focus_entered.connect(func() -> void: typing_changed.emit(true))
	_edit.focus_exited.connect(func() -> void: typing_changed.emit(false))
	col.add_child(_edit)

	_status = _label("", 12, MUTED)
	col.add_child(_status)

	# the keys: letters, then the wide row
	for row in ROWS:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 4)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		for ch in row:
			var b := _key(str(ch), 52)
			b.pressed.connect(_on_char.bind(b))
			if str(ch) >= "a" and str(ch) <= "z":
				_letter_keys.append(b)
			h.add_child(b)
		col.add_child(h)

	var wide := HBoxContainer.new()
	wide.add_theme_constant_override("separation", 4)
	wide.alignment = BoxContainer.ALIGNMENT_CENTER
	_shift_btn = _key("shift", 72)
	_shift_btn.pressed.connect(_on_shift)
	wide.add_child(_shift_btn)
	var space := _key("space", 200)
	space.pressed.connect(func() -> void: _insert(" "))
	wide.add_child(space)
	var back := _key("back", 72)
	back.pressed.connect(_on_backspace)
	wide.add_child(back)
	var clear := _key("clear", 64)
	clear.pressed.connect(func() -> void: _edit.text = ""; _set_status(""))
	wide.add_child(clear)
	var leave := _key("leave", 64)
	leave.pressed.connect(release)
	wide.add_child(leave)
	var send := _key("SEND", 80)
	send.add_theme_color_override("font_color", PAPER)
	var send_style := StyleBoxFlat.new()
	send_style.bg_color = ACCENT
	send_style.set_corner_radius_all(6)
	send.add_theme_stylebox_override("normal", send_style)
	var send_hover: StyleBoxFlat = send_style.duplicate()
	send_hover.bg_color = ACCENT.lightened(0.12)
	send.add_theme_stylebox_override("hover", send_hover)
	send.add_theme_stylebox_override("pressed", send_style)
	send.pressed.connect(submit)
	wide.add_child(send)
	col.add_child(wide)

	_recent = _label("", 12, MUTED)
	_recent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recent.custom_minimum_size = Vector2(0, 40)
	col.add_child(_recent)


func _label(text: String, size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _key(text: String, width: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 38)
	# a key never takes focus: the text keeps it, and the physical keyboard keeps typing
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", INK)
	var s := StyleBoxFlat.new()
	s.bg_color = CHROME
	s.border_color = RULE
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", s)
	var hv: StyleBoxFlat = s.duplicate()
	hv.border_color = ACCENT
	b.add_theme_stylebox_override("hover", hv)
	var pr: StyleBoxFlat = s.duplicate()
	pr.bg_color = Color(0.93, 0.98, 0.96)
	b.add_theme_stylebox_override("pressed", pr)
	return b


# ---- typing ---------------------------------------------------------------------

func _insert(s: String) -> void:
	if _edit == null:
		return
	_edit.insert_text_at_caret(s)
	_set_status("")


func _on_char(b: Button) -> void:
	_insert(b.text)
	if _shift:
		_on_shift()   # one capital, then back


func _on_shift() -> void:
	_shift = not _shift
	for b in _letter_keys:
		b.text = b.text.to_upper() if _shift else b.text.to_lower()
	_shift_btn.text = "SHIFT" if _shift else "shift"


func _on_backspace() -> void:
	if _edit == null:
		return
	_edit.backspace()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		release()


# ---- the contract the box and the probe use -------------------------------------

func set_title(t: String) -> void:
	if _title:
		_title.text = t


func set_context(t: String) -> void:
	if _context:
		_context.text = t


func set_prompt(t: String) -> void:
	if _edit:
		_edit.placeholder_text = t


func set_text(t: String) -> void:
	if _edit:
		_edit.text = t


func get_text() -> String:
	return _edit.text if _edit else ""


func set_recent(count: int, last: String) -> void:
	if _recent == null:
		return
	if count <= 0:
		_recent.text = "no comment left here yet"
	else:
		var head := "%d comment%s left here" % [count, "" if count == 1 else "s"]
		_recent.text = head + (" · last: " + last if not last.is_empty() else "")


func status_text() -> String:
	return _status.text if _status else ""


func _set_status(t: String, color: Color = MUTED) -> void:
	if _status:
		_status.text = t
		_status.add_theme_color_override("font_color", color)


func focus_text() -> void:
	if _edit:
		_edit.grab_focus()


func release() -> void:
	if _edit and _edit.has_focus():
		_edit.release_focus()


## SEND. An empty comment is refused here, before anything is written.
func submit() -> void:
	if _edit == null:
		return
	var t := _edit.text.strip_edges()
	if t.is_empty():
		_set_status("Write a comment first.", DANGER)
		return
	comment_submitted.emit(t)


func sent_ok(path: String) -> void:
	_set_status("Sent. It is in %s" % path.get_file(), ACCENT)
	if _edit:
		_edit.text = ""
	release()


func sent_fail() -> void:
	_set_status("Could not write the comment anywhere.", DANGER)
