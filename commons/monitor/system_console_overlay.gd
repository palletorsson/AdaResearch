extends CanvasLayer
## THE SYSTEM CONSOLE ON THE DESKTOP (2026-09-14). F12 shows and hides it.
##
## The console already existed as GameManager's ring buffer and the VR panel
## commons/monitor/VRconsole.tscn ("System Console"), but nothing drew it on the desktop and
## nothing fed it the engine log. commons/monitor/system_console_logger.gd now feeds it every
## print and error; this layer draws the last lines. It keeps no store of its own — it reads
## GameManager.get_console_messages() when shown and appends while visible, so a hidden
## console costs one signal connection and nothing per line.
##
## A CanvasLayer is not drawn in the headset; in VR the console is the left-hand panel.

const TOGGLE_KEY := KEY_F12
const LAYER := 110
const MAX_LINES := 200

const COLORS := {
	"info": "c8e6c9",
	"debug": "9e9e9e",
	"success": "a5d6a7",
	"warning": "ffcc66",
	"error": "ff7b7b",
}

var _panel: PanelContainer
var _log: RichTextLabel
var _lines := 0


func _ready() -> void:
	layer = LAYER
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		gm.console_message_added.connect(_on_message_added)
		gm.console_cleared.connect(_on_cleared)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == TOGGLE_KEY:
		set_shown(not visible)
		get_viewport().set_input_as_handled()
	elif visible and key.keycode == KEY_L and key.ctrl_pressed:
		var gm := get_node_or_null("/root/GameManager")
		if gm != null:
			gm.clear_console()
		get_viewport().set_input_as_handled()


func set_shown(on: bool) -> void:
	visible = on
	if on:
		_rebuild()


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.42
	_panel.anchor_top = 0.04
	_panel.anchor_right = 0.99
	_panel.anchor_bottom = 0.62
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.04, 0.86)
	style.border_color = Color(0.35, 0.75, 0.45, 0.7)
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = "SYSTEM CONSOLE    F12 hide · Ctrl+L clear"
	title.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6))
	title.add_theme_font_size_override("font_size", 13)
	box.add_child(title)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = false
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 12)
	_log.add_theme_font_size_override("mono_font_size", 12)
	box.add_child(_log)


func _rebuild() -> void:
	_log.clear()
	_lines = 0
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var msgs: Array = gm.get_console_messages()
	for i in range(maxi(0, msgs.size() - MAX_LINES), msgs.size()):
		_append(msgs[i])


func _on_message_added(message_data: Dictionary) -> void:
	if not visible:
		return
	if _lines >= MAX_LINES:
		_rebuild()      # trims to the newest MAX_LINES
		return
	_append(message_data)


func _on_cleared() -> void:
	_log.clear()
	_lines = 0


## push_color + add_text, never BBCode: the museum's lines begin "[em-gate]", which a BBCode
## label would swallow as a tag.
func _append(m: Dictionary) -> void:
	var type := str(m.get("type", "info"))
	var stamp := str(m.get("timestamp", ""))
	stamp = stamp.substr(stamp.length() - 8) if stamp.length() >= 8 else stamp
	_log.push_color(Color("6b8f71"))
	_log.add_text(stamp + " ")
	_log.pop()
	_log.push_color(Color("7fa889"))
	_log.add_text("[%s] " % str(m.get("source", "log")))
	_log.pop()
	_log.push_color(Color(COLORS.get(type, COLORS["info"])))
	_log.add_text(str(m.get("text", "")))
	_log.pop()
	_log.newline()
	_lines += 1
