# SongTimeline.gd
# Interactive timeline with annotations showing what sounds play when
# Displays layers, parameter values, and allows seeking

extends Control
class_name SongTimeline

signal seek_requested(time: float)
signal section_clicked(section_name: String)

# Timeline data
var _song_metadata: Dictionary = {}
var _sections: Array = []  # [{name, start, end, layers}]
var _total_duration: float = 0.0
var _current_time: float = 0.0
var _is_playing: bool = false

# Visual components
var _timeline_bar: Control
var _playhead: Control
var _section_panels: Array = []
var _layer_list: VBoxContainer
var _info_panel: PanelContainer
var _time_label: RichTextLabel
var _section_label: RichTextLabel

# Colors
const COLOR_BG = Color(0.08, 0.08, 0.1)
const COLOR_TIMELINE_BG = Color(0.12, 0.12, 0.15)
const COLOR_PLAYHEAD = Color(1.0, 0.3, 0.3)
const COLOR_SECTION_INTRO = Color(0.2, 0.4, 0.6, 0.8)
const COLOR_SECTION_VERSE = Color(0.3, 0.5, 0.3, 0.8)
const COLOR_SECTION_CHORUS = Color(0.5, 0.3, 0.5, 0.8)
const COLOR_SECTION_BUILD = Color(0.5, 0.4, 0.2, 0.8)
const COLOR_SECTION_SOLO = Color(0.6, 0.3, 0.2, 0.8)
const COLOR_SECTION_OUTRO = Color(0.3, 0.3, 0.5, 0.8)
const COLOR_SECTION_DEFAULT = Color(0.3, 0.3, 0.35, 0.8)
const COLOR_LAYER_BG = Color(0.15, 0.15, 0.18)
const COLOR_TEXT = Color(0.8, 0.8, 0.85)
const COLOR_TEXT_DIM = Color(0.5, 0.5, 0.55)

func _ready():
	_setup_ui()

func _setup_ui():
	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	
	# === HEADER ===
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	vbox.add_child(header)
	
	# Selectable time display
	_time_label = RichTextLabel.new()
	_time_label.bbcode_enabled = true
	_time_label.fit_content = true
	_time_label.scroll_active = false
	_time_label.selection_enabled = true
	_time_label.context_menu_enabled = true
	_time_label.text = "0:00 / 0:00"
	_time_label.add_theme_font_size_override("normal_font_size", 24)
	_time_label.add_theme_color_override("default_color", COLOR_TEXT)
	_time_label.custom_minimum_size = Vector2(150, 30)
	header.add_child(_time_label)
	
	# Selectable section name
	_section_label = RichTextLabel.new()
	_section_label.bbcode_enabled = true
	_section_label.fit_content = true
	_section_label.scroll_active = false
	_section_label.selection_enabled = true
	_section_label.context_menu_enabled = true
	_section_label.text = ""
	_section_label.add_theme_font_size_override("normal_font_size", 24)
	_section_label.add_theme_color_override("default_color", Color(0.4, 0.8, 0.5))
	_section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_section_label.custom_minimum_size.y = 30
	header.add_child(_section_label)
	
	# === TIMELINE BAR ===
	var timeline_container = PanelContainer.new()
	var tc_style = StyleBoxFlat.new()
	tc_style.bg_color = COLOR_TIMELINE_BG
	tc_style.set_corner_radius_all(4)
	timeline_container.add_theme_stylebox_override("panel", tc_style)
	timeline_container.custom_minimum_size.y = 80
	vbox.add_child(timeline_container)
	
	_timeline_bar = Control.new()
	_timeline_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_timeline_bar.gui_input.connect(_on_timeline_input)
	_timeline_bar.draw.connect(_on_timeline_draw)
	timeline_container.add_child(_timeline_bar)
	
	# Playhead
	_playhead = Control.new()
	_playhead.custom_minimum_size = Vector2(2, 0)
	_playhead.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_playhead.draw.connect(_on_playhead_draw)
	_timeline_bar.add_child(_playhead)
	
	# === LAYER LIST (scrollable) ===
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	_layer_list = VBoxContainer.new()
	_layer_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_layer_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_layer_list)
	
	# === INFO PANEL ===
	_info_panel = PanelContainer.new()
	var ip_style = StyleBoxFlat.new()
	ip_style.bg_color = COLOR_LAYER_BG
	ip_style.set_corner_radius_all(4)
	ip_style.content_margin_left = 12
	ip_style.content_margin_right = 12
	ip_style.content_margin_top = 8
	ip_style.content_margin_bottom = 8
	_info_panel.add_theme_stylebox_override("panel", ip_style)
	_info_panel.custom_minimum_size.y = 100
	vbox.add_child(_info_panel)


func load_song_metadata(metadata: Dictionary):
	"""Load song structure metadata for timeline display"""
	_song_metadata = metadata
	_sections = metadata.get("sections", [])
	_total_duration = metadata.get("total_duration", 60.0)
	_rebuild_timeline()
	_rebuild_layer_list()
	_update_info_panel()


func load_interactive_stream(stream: AudioStreamInteractive):
	"""Extract metadata from an AudioStreamInteractive"""
	var metadata = {
		"name": "Interactive Song",
		"sections": [],
		"total_duration": 0.0,
		"layers": []
	}
	
	if stream == null:
		load_song_metadata(metadata)
		return
	
	var clip_count = stream.clip_count
	var time_offset = 0.0
	
	for i in range(clip_count):
		var clip_name = stream.get_clip_name(i)
		var clip_stream = stream.get_clip_stream(i)
		var duration = 8.0  # Default duration
		
		if clip_stream:
			duration = clip_stream.get_length()
		
		metadata["sections"].append({
			"name": clip_name if clip_name else "Section %d" % (i + 1),
			"start": time_offset,
			"end": time_offset + duration,
			"index": i,
			"layers": _extract_section_layers(clip_name)
		})
		
		time_offset += duration
	
	metadata["total_duration"] = time_offset
	load_song_metadata(metadata)


func _extract_section_layers(section_name: String) -> Array:
	"""Infer layers from section name"""
	var layers = []
	var name_lower = section_name.to_lower()
	
	# Common layer patterns
	if "intro" in name_lower:
		layers = [
			{"name": "Pad", "type": "pad", "params": "detune: ±6 cents | filter: LPF sweep"},
		]
	elif "verse" in name_lower:
		layers = [
			{"name": "Bass", "type": "bass", "params": "osc: saw | filter: LPF 800Hz"},
			{"name": "Keys", "type": "keys", "params": "type: FM piano"},
			{"name": "Drums", "type": "drums", "params": "pattern: basic"},
		]
	elif "chorus" in name_lower or "main" in name_lower:
		layers = [
			{"name": "Bass", "type": "bass", "params": "osc: saw+sub | filter: LPF 1200Hz"},
			{"name": "Pad", "type": "pad", "params": "voices: 7 | detune: ±8 cents"},
			{"name": "Lead", "type": "lead", "params": "osc: pulse | PWM: LFO 0.5Hz"},
			{"name": "Drums", "type": "drums", "params": "pattern: full"},
		]
	elif "build" in name_lower:
		layers = [
			{"name": "Pad", "type": "pad", "params": "filter: rising sweep"},
			{"name": "Sequencer", "type": "seq", "params": "16th notes | filter: opening"},
			{"name": "Drums", "type": "drums", "params": "pattern: building"},
		]
	elif "solo" in name_lower:
		layers = [
			{"name": "Lead", "type": "lead", "params": "portamento: 50ms | vibrato: 5Hz"},
			{"name": "Pad", "type": "pad", "params": "sustained"},
			{"name": "Drums", "type": "drums", "params": "pattern: driving"},
		]
	elif "outro" in name_lower:
		layers = [
			{"name": "Pad", "type": "pad", "params": "fade out"},
		]
	else:
		layers = [
			{"name": "Mix", "type": "mix", "params": ""},
		]
	
	return layers


func set_current_time(time: float):
	"""Update playhead position"""
	_current_time = time
	_update_playhead()
	_update_time_label()
	_update_current_section()
	_timeline_bar.queue_redraw()


func set_playing(playing: bool):
	_is_playing = playing


func _rebuild_timeline():
	"""Rebuild visual timeline sections"""
	_timeline_bar.queue_redraw()


func _rebuild_layer_list():
	"""Rebuild the layer annotation list"""
	# Clear existing
	for child in _layer_list.get_children():
		child.queue_free()
	
	# Add section headers and layers
	for section in _sections:
		var section_header = _create_section_header(section)
		_layer_list.add_child(section_header)
		
		for layer in section.get("layers", []):
			var layer_row = _create_layer_row(section["name"], layer)
			_layer_list.add_child(layer_row)


func _create_section_header(section: Dictionary) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = _get_section_color(section["name"]).darkened(0.3)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)
	
	# Selectable section name
	var name_label = RichTextLabel.new()
	name_label.bbcode_enabled = true
	name_label.fit_content = true
	name_label.scroll_active = false
	name_label.selection_enabled = true
	name_label.context_menu_enabled = true
	name_label.text = "▶ " + section["name"].to_upper()
	name_label.add_theme_font_size_override("normal_font_size", 18)
	name_label.add_theme_color_override("default_color", COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.custom_minimum_size.y = 24
	hbox.add_child(name_label)
	
	# Selectable time range
	var time_label = RichTextLabel.new()
	time_label.bbcode_enabled = true
	time_label.fit_content = true
	time_label.scroll_active = false
	time_label.selection_enabled = true
	time_label.context_menu_enabled = true
	time_label.text = "%s - %s" % [_format_time(section["start"]), _format_time(section["end"])]
	time_label.add_theme_font_size_override("normal_font_size", 16)
	time_label.add_theme_color_override("default_color", COLOR_TEXT_DIM)
	time_label.custom_minimum_size = Vector2(100, 24)
	hbox.add_child(time_label)
	
	return panel


func _create_layer_row(section_name: String, layer: Dictionary) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_LAYER_BG
	style.set_corner_radius_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)
	
	# Layer name with icon (selectable)
	var icon = _get_layer_icon(layer.get("type", ""))
	var name_label = RichTextLabel.new()
	name_label.bbcode_enabled = true
	name_label.fit_content = true
	name_label.scroll_active = false
	name_label.selection_enabled = true
	name_label.context_menu_enabled = true
	name_label.text = icon + " " + layer.get("name", "Layer")
	name_label.add_theme_font_size_override("normal_font_size", 16)
	name_label.add_theme_color_override("default_color", _get_layer_color(layer.get("type", "")))
	name_label.custom_minimum_size = Vector2(140, 22)
	hbox.add_child(name_label)
	
	# Parameters (selectable)
	var params = layer.get("params", "")
	var params_text = ""
	if params is Dictionary and not params.is_empty():
		var parts = []
		for key in params.keys():
			parts.append("%s: %s" % [key, params[key]])
		params_text = " | ".join(parts)
	elif params is String:
		params_text = params
	
	if not params_text.is_empty():
		
		var params_label = RichTextLabel.new()
		params_label.bbcode_enabled = true
		params_label.fit_content = true
		params_label.scroll_active = false
		params_label.selection_enabled = true
		params_label.context_menu_enabled = true
		params_label.text = params_text
		params_label.add_theme_font_size_override("normal_font_size", 14)
		params_label.add_theme_color_override("default_color", COLOR_TEXT_DIM)
		params_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		params_label.custom_minimum_size.y = 22
		hbox.add_child(params_label)
	
	return panel


func _get_layer_icon(layer_type: String) -> String:
	match layer_type.to_lower():
		"bass": return "🎸"
		"pad": return "🌊"
		"lead": return "🎹"
		"keys": return "🎹"
		"drums": return "🥁"
		"seq", "sequencer": return "⏱️"
		"noise": return "📻"
		"sax": return "🎷"
		"vocal", "choir": return "🎤"
		"strings": return "🎻"
		_: return "🔊"


func _get_layer_color(layer_type: String) -> Color:
	match layer_type.to_lower():
		"bass": return Color(0.9, 0.5, 0.3)
		"pad": return Color(0.5, 0.7, 0.9)
		"lead": return Color(0.9, 0.7, 0.3)
		"keys": return Color(0.7, 0.9, 0.5)
		"drums": return Color(0.9, 0.4, 0.4)
		"seq", "sequencer": return Color(0.6, 0.9, 0.6)
		"noise": return Color(0.6, 0.6, 0.7)
		_: return COLOR_TEXT


func _get_section_color(section_name: String) -> Color:
	var name_lower = section_name.to_lower()
	if "intro" in name_lower: return COLOR_SECTION_INTRO
	if "verse" in name_lower: return COLOR_SECTION_VERSE
	if "chorus" in name_lower or "main" in name_lower: return COLOR_SECTION_CHORUS
	if "build" in name_lower: return COLOR_SECTION_BUILD
	if "solo" in name_lower: return COLOR_SECTION_SOLO
	if "outro" in name_lower: return COLOR_SECTION_OUTRO
	return COLOR_SECTION_DEFAULT


func _update_playhead():
	if _total_duration <= 0:
		return
	var ratio = _current_time / _total_duration
	var bar_width = _timeline_bar.size.x
	_playhead.position.x = ratio * bar_width - 1


func _update_time_label():
	_time_label.text = "%s / %s" % [_format_time(_current_time), _format_time(_total_duration)]


func _update_current_section():
	for section in _sections:
		if _current_time >= section["start"] and _current_time < section["end"]:
			_section_label.text = "▶ " + section["name"]
			return
	_section_label.text = ""


func _update_info_panel():
	# Clear existing
	for child in _info_panel.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	_info_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "📊 CURRENT SECTION INFO"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	vbox.add_child(title)
	
	var hint = Label.new()
	hint.text = "Click timeline to seek • Sections auto-advance"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	vbox.add_child(hint)


func _format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]


func _on_timeline_draw():
	var rect = _timeline_bar.get_rect()
	var w = rect.size.x
	var h = rect.size.y
	
	if _total_duration <= 0:
		return
	
	# Draw sections
	for section in _sections:
		var start_x = (section["start"] / _total_duration) * w
		var end_x = (section["end"] / _total_duration) * w
		var section_rect = Rect2(start_x, 0, end_x - start_x, h)
		
		_timeline_bar.draw_rect(section_rect, _get_section_color(section["name"]))
		
		# Section label
		var label_pos = Vector2(start_x + 8, h / 2 + 5)
		_timeline_bar.draw_string(
			ThemeDB.fallback_font,
			label_pos,
			section["name"],
			HORIZONTAL_ALIGNMENT_LEFT,
			end_x - start_x - 16,
			14,
			Color.WHITE
		)
		
		# Section border
		_timeline_bar.draw_line(Vector2(start_x, 0), Vector2(start_x, h), Color(0.3, 0.3, 0.35), 1.0)
	
	# Draw time markers
	var marker_interval = 10.0  # Every 10 seconds
	var marker_count = int(_total_duration / marker_interval)
	for i in range(1, marker_count + 1):
		var marker_time = i * marker_interval
		var marker_x = (marker_time / _total_duration) * w
		_timeline_bar.draw_line(Vector2(marker_x, h - 15), Vector2(marker_x, h), Color(0.4, 0.4, 0.45), 1.0)
		_timeline_bar.draw_string(
			ThemeDB.fallback_font,
			Vector2(marker_x - 10, h - 3),
			_format_time(marker_time),
			HORIZONTAL_ALIGNMENT_CENTER,
			-1, 10, Color(0.5, 0.5, 0.55)
		)


func _on_playhead_draw():
	var h = _playhead.size.y
	_playhead.draw_line(Vector2(0, 0), Vector2(0, h), COLOR_PLAYHEAD, 2.0)
	# Triangle head
	var head_points = PackedVector2Array([
		Vector2(-6, 0),
		Vector2(6, 0),
		Vector2(0, 10)
	])
	_playhead.draw_colored_polygon(head_points, COLOR_PLAYHEAD)


func _on_timeline_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_x = event.position.x
			var ratio = click_x / _timeline_bar.size.x
			var seek_time = ratio * _total_duration
			seek_requested.emit(seek_time)
