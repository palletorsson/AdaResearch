extends CanvasLayer
class_name SubtitleOverlay

## Portal 2-style subtitle overlay for map annotations
## Shows text at bottom of screen with typewriter effect and fade

signal subtitle_finished
signal subtitle_skipped

@export var typewriter_speed: float = 0.03  # Seconds per character
@export var display_duration: float = 5.0   # How long to show after typing finishes
@export var fade_duration: float = 0.5      # Fade in/out duration
@export var speaker_color: Color = Color(0.4, 0.8, 1.0)  # Cyan for speaker name
@export var text_color: Color = Color(0.95, 0.95, 0.95)  # White for text

# UI References
var _panel: PanelContainer
var _label: RichTextLabel
var _background: ColorRect

# State
var _full_text: String = ""
var _current_char_index: int = 0
var _is_typing: bool = false
var _typewriter_timer: float = 0.0
var _display_timer: float = 0.0
var _current_opacity: float = 0.0
var _target_opacity: float = 0.0
var _speaker: String = ""

# Queue for multiple subtitles
var _subtitle_queue: Array[Dictionary] = []
var _is_showing: bool = false

func _ready():
	layer = 100  # On top of everything
	_setup_ui()
	visible = true

func _setup_ui():
	# Background panel at bottom of screen
	_background = ColorRect.new()
	_background.color = Color(0.0, 0.0, 0.0, 0.7)
	_background.anchor_left = 0.1
	_background.anchor_right = 0.9
	_background.anchor_top = 0.85
	_background.anchor_bottom = 0.95
	_background.offset_left = 0
	_background.offset_right = 0
	_background.offset_top = 0
	_background.offset_bottom = 0
	_background.modulate.a = 0.0
	add_child(_background)

	# Container for padding
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.1
	_panel.anchor_right = 0.9
	_panel.anchor_top = 0.85
	_panel.anchor_bottom = 0.95

	# Transparent panel style
	var style = StyleBoxEmpty.new()
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	# Margin container for padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	# RichTextLabel for formatted text
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.add_theme_font_size_override("normal_font_size", 24)
	_label.add_theme_color_override("default_color", text_color)
	_label.modulate.a = 0.0
	margin.add_child(_label)

func _process(delta: float):
	# Skip if UI not ready
	if not _background or not _label:
		return

	# Handle fade
	if _current_opacity != _target_opacity:
		if _target_opacity > _current_opacity:
			_current_opacity = minf(_current_opacity + delta / fade_duration, _target_opacity)
		else:
			_current_opacity = maxf(_current_opacity - delta / fade_duration, _target_opacity)
		_background.modulate.a = _current_opacity
		_label.modulate.a = _current_opacity

		# Check if fade out complete
		if _current_opacity <= 0.0 and _target_opacity <= 0.0:
			_is_showing = false
			subtitle_finished.emit()
			_process_queue()

	# Handle typewriter effect
	if _is_typing:
		_typewriter_timer += delta
		while _typewriter_timer >= typewriter_speed and _current_char_index < _full_text.length():
			_typewriter_timer -= typewriter_speed
			_current_char_index += 1
			_update_displayed_text()

		if _current_char_index >= _full_text.length():
			_is_typing = false
			_display_timer = display_duration

	# Handle display duration countdown
	if not _is_typing and _display_timer > 0.0 and _is_showing:
		_display_timer -= delta
		if _display_timer <= 0.0:
			hide_subtitle()

func _update_displayed_text():
	if not _label:
		return
	var visible_text = _full_text.substr(0, _current_char_index)
	if _speaker.is_empty():
		_label.text = visible_text
	else:
		_label.text = "[color=#%s]%s:[/color] %s" % [speaker_color.to_html(false), _speaker, visible_text]

## Show a subtitle with optional speaker name
func show_subtitle(text: String, speaker: String = "", duration: float = -1.0):
	var subtitle_data = {
		"text": text,
		"speaker": speaker,
		"duration": duration if duration > 0 else display_duration
	}

	if _is_showing:
		# Queue it
		_subtitle_queue.append(subtitle_data)
	else:
		_display_subtitle(subtitle_data)

func _display_subtitle(data: Dictionary):
	print("SubtitleOverlay._display_subtitle() - text='%s', speaker='%s'" % [data.text.substr(0, 50), data.speaker])
	_is_showing = true
	_speaker = data.speaker
	_full_text = data.text
	display_duration = data.duration
	_current_char_index = 0
	_is_typing = true
	_typewriter_timer = 0.0
	_target_opacity = 1.0
	# Set opacity immediately (don't wait for fade)
	_current_opacity = 1.0
	_background.modulate.a = 1.0
	_label.modulate.a = 1.0
	_update_displayed_text()
	print("SubtitleOverlay: _label.text='%s', _background.modulate.a=%f" % [_label.text.substr(0, 30), _background.modulate.a])

func _process_queue():
	if _subtitle_queue.size() > 0:
		var next = _subtitle_queue.pop_front()
		_display_subtitle(next)

## Hide current subtitle with fade
func hide_subtitle():
	_target_opacity = 0.0

## Skip typewriter and show full text immediately
func skip_typewriter():
	if _is_typing:
		_current_char_index = _full_text.length()
		_update_displayed_text()
		_is_typing = false
		_display_timer = display_duration
		subtitle_skipped.emit()

## Clear all subtitles including queue
func clear_all():
	_subtitle_queue.clear()
	_is_typing = false
	_target_opacity = 0.0
	_is_showing = false

## Check if currently showing a subtitle
func is_active() -> bool:
	return _is_showing

## Show map annotation text (formatted for map entry)
func show_map_annotation(map_name: String, description: String, duration: float = 8.0):
	# Format like Portal 2 GLaDOS
	show_subtitle(description, map_name.replace("_", " "), duration)

## Show a sequence of subtitles
func show_subtitle_sequence(subtitles: Array[Dictionary]):
	for sub in subtitles:
		var text = sub.get("text", "")
		var speaker = sub.get("speaker", "")
		var duration = sub.get("duration", display_duration)
		show_subtitle(text, speaker, duration)
