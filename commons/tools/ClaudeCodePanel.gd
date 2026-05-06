# ClaudeCodePanel.gd
# Embeddable Claude Code panel — runs `claude -p` one-shot queries against
# the project directory, with file-based IPC for async results.
# Built entirely in code (no .tscn).
#
# Usage:
#   var panel = ClaudeCodePanel.new()
#   panel.project_root = "C:/Users/palle/Documents/GitHub/AdaResearch_46"
#   some_container.add_child(panel)

extends Control
class_name ClaudeCodePanel

# ── Configuration ──────────────────────────────────────────────────────
## Path to the project root that Claude Code operates on
@export var project_root: String = ""
## Claude model to use (empty = default)
@export var claude_model: String = ""
## Max tokens for responses
@export var max_tokens: int = 4096

# ── Theme ──────────────────────────────────────────────────────────────
const COL_BG           = Color(0.10, 0.10, 0.13)
const COL_PANEL        = Color(0.14, 0.14, 0.17)
const COL_TEXT         = Color(0.85, 0.85, 0.85)
const COL_HEADER       = Color(0.6, 0.8, 1.0)
const COL_ACCENT       = Color(0.35, 0.55, 0.9)
const COL_USER_BUBBLE  = Color(0.18, 0.22, 0.32)
const COL_ASST_BUBBLE  = Color(0.14, 0.20, 0.18)
const COL_ERR_BUBBLE   = Color(0.28, 0.14, 0.14)
const COL_INPUT_BG     = Color(0.08, 0.08, 0.11)
const COL_INPUT_BORDER = Color(0.25, 0.27, 0.35)
const COL_DIM          = Color(0.45, 0.45, 0.5)
const COL_RUNNING      = Color(0.9, 0.7, 0.2)
const COL_READY        = Color(0.4, 0.8, 0.5)

# ── File Paths ─────────────────────────────────────────────────────────
const REQUEST_PATH  = "user://claude_code_request.json"
const RESPONSE_PATH = "user://claude_code_response.json"

# ── Polling ────────────────────────────────────────────────────────────
const POLL_INTERVAL := 0.5
var _poll_cooldown: float = 0.0
var _last_response_mod: int = 0
var _is_running: bool = false
var _run_pid: int = -1

# ── Chat History ───────────────────────────────────────────────────────
var _messages: Array[Dictionary] = []  # [{role, text, timestamp}]

# ── UI Nodes ───────────────────────────────────────────────────────────
var _main_vbox: VBoxContainer
var _status_label: Label
var _chat_scroll: ScrollContainer
var _chat_vbox: VBoxContainer
var _input_field: TextEdit
var _send_btn: Button
var _stop_btn: Button
var _clear_btn: Button
var _context_bar: HFlowContainer

# ── Lifecycle ──────────────────────────────────────────────────────────

func _ready():
	clip_contents = true
	if project_root.is_empty():
		project_root = ProjectSettings.globalize_path("res://")
	_build_ui()
	_set_status("Ready", COL_READY)


func _process(delta: float):
	if _is_running:
		_poll_cooldown -= delta
		if _poll_cooldown <= 0:
			_poll_cooldown = POLL_INTERVAL
			_poll_response()


# ── UI Build ───────────────────────────────────────────────────────────

func _build_ui():
	var bg = ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_main_vbox = VBoxContainer.new()
	_main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 8)
	_main_vbox.add_theme_constant_override("separation", 6)
	add_child(_main_vbox)

	# Header bar
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	_main_vbox.add_child(header_row)

	var title = Label.new()
	title.text = "⌘  CLAUDE CODE"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COL_HEADER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	header_row.add_child(_status_label)

	_clear_btn = Button.new()
	_clear_btn.text = "Clear"
	_clear_btn.custom_minimum_size = Vector2(50, 24)
	_clear_btn.pressed.connect(_on_clear)
	_style_small_button(_clear_btn)
	header_row.add_child(_clear_btn)

	# Chat area
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chat_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_main_vbox.add_child(_chat_scroll)

	_chat_vbox = VBoxContainer.new()
	_chat_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_vbox.add_theme_constant_override("separation", 6)
	_chat_scroll.add_child(_chat_vbox)

	# Welcome
	_add_bubble("assistant", "Claude Code ready. Ask me anything about the project — I can read files, explain code, suggest changes.\n\nI run as `claude -p` one-shot queries against:\n%s" % project_root)

	# Context quick-insert buttons
	_context_bar = HFlowContainer.new()
	_context_bar.add_theme_constant_override("h_separation", 4)
	_context_bar.add_theme_constant_override("v_separation", 4)
	_main_vbox.add_child(_context_bar)

	var ctx_label = Label.new()
	ctx_label.text = "Insert:"
	ctx_label.add_theme_font_size_override("font_size", 11)
	ctx_label.add_theme_color_override("font_color", COL_DIM)
	_context_bar.add_child(ctx_label)

	_add_context_btn("📂 Current file", _on_ctx_current_file)
	_add_context_btn("📋 Selection", _on_ctx_selection)
	_add_context_btn("🗂️ Project tree", _on_ctx_tree)

	# Input area
	var input_row = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 6)
	_main_vbox.add_child(input_row)

	_input_field = TextEdit.new()
	_input_field.placeholder_text = "Ask Claude Code... (Shift+Enter for newline, Enter to send)"
	_input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_field.custom_minimum_size = Vector2(0, 60)
	_input_field.scroll_fit_content_height = true
	_input_field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_input_field.gui_input.connect(_on_input_gui_input)
	_style_text_input(_input_field)
	input_row.add_child(_input_field)

	var btn_col = VBoxContainer.new()
	btn_col.add_theme_constant_override("separation", 4)
	input_row.add_child(btn_col)

	_send_btn = Button.new()
	_send_btn.text = "Send ➤"
	_send_btn.custom_minimum_size = Vector2(80, 30)
	_send_btn.pressed.connect(_on_send)
	_style_send_button(_send_btn)
	btn_col.add_child(_send_btn)

	_stop_btn = Button.new()
	_stop_btn.text = "■ Stop"
	_stop_btn.custom_minimum_size = Vector2(80, 26)
	_stop_btn.pressed.connect(_on_stop)
	_stop_btn.visible = false
	_style_small_button(_stop_btn)
	btn_col.add_child(_stop_btn)


func _on_input_gui_input(event: InputEvent):
	var key = event as InputEventKey
	if key and key.pressed and key.keycode == KEY_ENTER and not key.shift_pressed:
		# Accept the event to prevent newline insertion
		_input_field.accept_event()
		call_deferred("_on_send")


# ── Send / Stop ────────────────────────────────────────────────────────

func _on_send():
	var text: String = _input_field.text.strip_edges()
	if text.is_empty() or _is_running:
		return

	_input_field.text = ""
	_add_bubble("user", text)
	_messages.append({"role": "user", "text": text, "timestamp": Time.get_datetime_string_from_system(true)})

	_set_status("Running…", COL_RUNNING)
	_is_running = true
	_send_btn.disabled = true
	_stop_btn.visible = true

	# Build conversation context for -p (last few exchanges)
	var prompt := text

	# Write request file (so Clawdbot or a watcher can also pick it up)
	_write_request(text)

	# Spawn claude -p
	_spawn_claude(prompt)


func _on_stop():
	if _run_pid > 0:
		OS.kill(_run_pid)
		_run_pid = -1
	_finish_run()
	_add_bubble("system", "⏹ Stopped by user.")


func _on_clear():
	for child in _chat_vbox.get_children():
		child.queue_free()
	_messages.clear()
	_add_bubble("assistant", "Chat cleared. Ready for new queries.")


# ── Claude Execution ───────────────────────────────────────────────────

func _spawn_claude(prompt: String):
	# Delete old response file
	if FileAccess.file_exists(RESPONSE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RESPONSE_PATH))
	_last_response_mod = 0
	_process_exited_frames = 0

	# Build args
	var args: PackedStringArray = ["-p", prompt, "--no-input", "--output-format", "text"]
	if not claude_model.is_empty():
		args.append_array(["--model", claude_model])
	if max_tokens > 0:
		args.append_array(["--max-tokens", str(max_tokens)])

	# We use a wrapper script that captures output to the response file
	var wrapper_script := _create_wrapper_script(args)
	
	# Execute via cmd.exe so we can redirect output
	var pid = OS.create_process("cmd.exe", ["/c", wrapper_script])
	if pid > 0:
		_run_pid = pid
		_poll_cooldown = 1.5  # give it a moment to start
	else:
		_add_bubble("error", "Failed to launch Claude Code. Is `claude` in your PATH?")
		_finish_run()


func _create_wrapper_script(claude_args: PackedStringArray) -> String:
	"""Create a temporary .bat that runs claude and writes output to the response file."""
	var response_path_global := ProjectSettings.globalize_path(RESPONSE_PATH)
	var escaped_args := ""
	for arg in claude_args:
		# Escape double quotes in args
		var escaped := arg.replace('"', '\\"')
		escaped_args += ' "%s"' % escaped

	var bat_content := '@echo off\r\ncd /d "%s"\r\nclaude%s > "%s" 2>&1\r\n' % [
		project_root.replace("/", "\\"),
		escaped_args,
		response_path_global.replace("/", "\\")
	]

	var bat_path := ProjectSettings.globalize_path("user://claude_run.bat")
	var file := FileAccess.open("user://claude_run.bat", FileAccess.WRITE)
	if file:
		file.store_string(bat_content)
		file.close()
	return bat_path


var _process_exited_frames: int = 0  # count frames after process exits without output

func _poll_response():
	if not FileAccess.file_exists(RESPONSE_PATH):
		# Check if process is still alive
		if _run_pid > 0 and not OS.is_process_running(_run_pid):
			_process_exited_frames += 1
			# Give it a few poll cycles for the file to appear
			if _process_exited_frames > 3:
				_add_bubble("error", "Claude process exited with no output. Check that `claude` CLI is installed and in PATH.")
				_finish_run()
		return

	_process_exited_frames = 0

	# Check if file is still being written (mod time changing)
	var mod_time := FileAccess.get_modified_time(RESPONSE_PATH)
	if mod_time == _last_response_mod:
		# File hasn't changed — check if process ended
		if _run_pid > 0 and not OS.is_process_running(_run_pid):
			# Process done, file stable — read it
			_read_response()
			_finish_run()
	else:
		_last_response_mod = mod_time
		# File still changing, update status
		var file_obj := FileAccess.open(RESPONSE_PATH, FileAccess.READ)
		if file_obj:
			var sz := file_obj.get_length()
			file_obj.close()
			_set_status("Receiving… (%d bytes)" % sz, COL_RUNNING)


func _read_response():
	var file := FileAccess.open(RESPONSE_PATH, FileAccess.READ)
	if not file:
		_add_bubble("error", "Could not read response file.")
		return

	var content := file.get_as_text().strip_edges()
	file.close()

	if content.is_empty():
		_add_bubble("error", "Empty response from Claude.")
		return

	_add_bubble("assistant", content)
	_messages.append({"role": "assistant", "text": content, "timestamp": Time.get_datetime_string_from_system(true)})


func _finish_run():
	_is_running = false
	_run_pid = -1
	_send_btn.disabled = false
	_stop_btn.visible = false
	_set_status("Ready", COL_READY)


func _write_request(text: String):
	var data := {
		"prompt": text,
		"timestamp": Time.get_datetime_string_from_system(true),
		"project_root": project_root,
		"model": claude_model
	}
	var file := FileAccess.open(REQUEST_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


# ── Context Buttons ────────────────────────────────────────────────────

func _add_context_btn(text: String, callback: Callable):
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 24)
	btn.pressed.connect(callback)
	_style_context_button(btn)
	_context_bar.add_child(btn)


func _on_ctx_current_file():
	# Insert a reference to whatever file/scene is relevant
	_append_input("[file: <current_scene>]")


func _on_ctx_selection():
	_append_input("[selected code/node]")


func _on_ctx_tree():
	_append_input("Show me the project structure under res://commons/")


func _append_input(text: String):
	var current := _input_field.text
	if current.is_empty():
		_input_field.text = text + " "
	else:
		_input_field.text = current.strip_edges() + " " + text + " "
	_input_field.set_caret_column(_input_field.text.length())
	_input_field.grab_focus()


# ── UI Helpers ─────────────────────────────────────────────────────────

func _set_status(text: String, color: Color = COL_DIM):
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)


func _add_bubble(role: String, text: String):
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6

	match role:
		"user":
			style.bg_color = COL_USER_BUBBLE
		"assistant":
			style.bg_color = COL_ASST_BUBBLE
		"error", "system":
			style.bg_color = COL_ERR_BUBBLE
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var role_label := Label.new()
	match role:
		"user":
			role_label.text = "You:"
			role_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
		"assistant":
			role_label.text = "Claude:"
			role_label.add_theme_color_override("font_color", COL_HEADER)
		"error":
			role_label.text = "Error:"
			role_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		"system":
			role_label.text = "System:"
			role_label.add_theme_color_override("font_color", COL_DIM)
	role_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(role_label)

	var msg := RichTextLabel.new()
	msg.bbcode_enabled = false
	msg.text = text
	msg.fit_content = true
	msg.scroll_active = false
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.add_theme_font_size_override("normal_font_size", 13)
	msg.add_theme_color_override("default_color", COL_TEXT)
	msg.selection_enabled = true
	vbox.add_child(msg)

	_chat_vbox.add_child(panel)

	# Auto-scroll
	await get_tree().process_frame
	if _chat_scroll:
		_chat_scroll.scroll_vertical = _chat_scroll.get_v_scroll_bar().max_value


# ── Style Helpers ──────────────────────────────────────────────────────

func _style_text_input(field: TextEdit):
	var style := StyleBoxFlat.new()
	style.bg_color = COL_INPUT_BG
	style.set_corner_radius_all(6)
	style.border_color = COL_INPUT_BORDER
	style.set_border_width_all(1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	field.add_theme_stylebox_override("normal", style)

	var focus := style.duplicate()
	focus.border_color = COL_ACCENT
	focus.set_border_width_all(2)
	field.add_theme_stylebox_override("focus", focus)

	field.add_theme_font_size_override("font_size", 13)
	field.add_theme_color_override("font_color", COL_TEXT)


func _style_send_button(btn: Button):
	var style := StyleBoxFlat.new()
	style.bg_color = COL_ACCENT
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = COL_ACCENT.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))


func _style_small_button(btn: Button):
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.22, 0.28)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", COL_DIM)


func _style_context_button(btn: Button):
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.16, 0.18, 0.24)
	st.set_corner_radius_all(12)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	st.border_color = Color(0.28, 0.32, 0.45)
	st.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", st)

	var hv := st.duplicate()
	hv.bg_color = Color(0.22, 0.25, 0.35)
	hv.border_color = COL_ACCENT
	btn.add_theme_stylebox_override("hover", hv)

	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
