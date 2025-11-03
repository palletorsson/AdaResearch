@tool
extends Control

const PARAMETERS_BASE_DIR := "res://commons/audio/parameters/"
const CATEGORY_SEPARATOR := "/"
const JSON_INDENT := "	"

const ParameterControls := preload("res://commons/audio/components/ParameterControlsComponent.gd")
const AudioSynthesizer := preload("res://commons/audio/generators/AudioSynthesizer.gd")
const CustomSoundGenerator := preload("res://commons/audio/generators/CustomSoundGenerator.gd")

var search_box: LineEdit
var sound_tree: Tree
var reload_button: Button
var sound_name_label: Label
var file_path_label: Label
var metadata_label: RichTextLabel
var play_button: Button
var stop_button: Button
var save_button: Button
var export_button: Button
var parameter_holder: VBoxContainer

var waveform_control: Control
var spectrum_control: Control
var waveform_samples: PackedFloat32Array = PackedFloat32Array()
var spectrum_bins: PackedFloat32Array = PackedFloat32Array()
var preview_stream: AudioStreamWAV

const WAVEFORM_POINT_COUNT := 512
const SPECTRUM_BIN_COUNT := 64

func _get_control_rect(target: Control) -> Rect2:
	if target == null:
		return Rect2()
	return Rect2(Vector2.ZERO, target.get_size())

var parameter_controls: ParameterControlsComponent
var audio_player: AudioStreamPlayer
var export_dialog: FileDialog

var catalog_entries: Array = []
var entries_by_id: Dictionary = {}
var current_entry_id: String = ""
var category_cache: Dictionary = {}

enum PresetFormat { ROOT_METADATA, NESTED_METADATA, DIRECT }

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	_build_ui()
	_setup_helpers()
	_connect_signals()
	reload_catalog()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.custom_minimum_size = Vector2(0, 720)
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	var main_split = HSplitContainer.new()
	main_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.custom_minimum_size = Vector2(0, 420)
	main_split.split_offset = 300
	main_vbox.add_child(main_split)

	_build_left_panel(main_split)
	_build_right_panel(main_split)

func _build_left_panel(split: HSplitContainer) -> void:
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(260, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_constant_override("separation", 6)
	split.add_child(left_panel)

	var title = Label.new()
	title.text = "Sound Presets"
	title.add_theme_font_size_override("font_size", 16)
	left_panel.add_child(title)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Search sound..."
	search_box.clear_button_enabled = true
	left_panel.add_child(search_box)

	sound_tree = Tree.new()
	sound_tree.columns = 1
	sound_tree.hide_root = true
	sound_tree.allow_reselect = true
	sound_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(sound_tree)

	reload_button = Button.new()
	reload_button.text = "Reload"
	reload_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.add_child(reload_button)

func _build_right_panel(split: HSplitContainer) -> void:
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 10)
	split.add_child(right_panel)

	var header = VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_child(header)

	sound_name_label = Label.new()
	sound_name_label.text = "Select a sound"
	sound_name_label.add_theme_font_size_override("font_size", 18)
	sound_name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))
	header.add_child(sound_name_label)

	file_path_label = Label.new()
	file_path_label.clip_text = true
	file_path_label.autowrap_mode = TextServer.AutowrapMode.AUTOWRAP_WORD
	file_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	file_path_label.modulate = Color(0.8, 0.85, 0.95, 1.0)
	header.add_child(file_path_label)

	metadata_label = RichTextLabel.new()
	metadata_label.bbcode_enabled = true
	metadata_label.fit_content = true
	metadata_label.scroll_active = false
	metadata_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_child(metadata_label)

	var action_bar = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 8)
	action_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_child(action_bar)

	play_button = Button.new()
	play_button.text = "Play"
	action_bar.add_child(play_button)

	stop_button = Button.new()
	stop_button.text = "Stop"
	action_bar.add_child(stop_button)

	save_button = Button.new()
	save_button.text = "Save"
	action_bar.add_child(save_button)

	export_button = Button.new()
	export_button.text = "Export JSON"
	action_bar.add_child(export_button)

	var visuals_container = VBoxContainer.new()
	visuals_container.add_theme_constant_override("separation", 6)
	visuals_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_child(visuals_container)

	var waveform_label = Label.new()
	waveform_label.text = "Waveform"
	visuals_container.add_child(waveform_label)

	waveform_control = Control.new()
	waveform_control.custom_minimum_size = Vector2(0, 140)
	waveform_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	waveform_control.draw.connect(Callable(self, "_on_waveform_draw"))
	visuals_container.add_child(waveform_control)

	var spectrum_label = Label.new()
	spectrum_label.text = "Spectrum"
	visuals_container.add_child(spectrum_label)

	spectrum_control = Control.new()
	spectrum_control.custom_minimum_size = Vector2(0, 120)
	spectrum_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spectrum_control.draw.connect(Callable(self, "_on_spectrum_draw"))
	visuals_container.add_child(spectrum_control)

	var parameter_scroll = ScrollContainer.new()
	parameter_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameter_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(parameter_scroll)

	parameter_holder = VBoxContainer.new()
	parameter_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameter_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parameter_holder.add_theme_constant_override("separation", 6)
	parameter_scroll.add_child(parameter_holder)

func _setup_helpers() -> void:
	parameter_controls = ParameterControls.new()
	parameter_controls.column_count = 3
	parameter_controls.enable_value_labels(true)
	parameter_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameter_controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parameter_holder.add_child(parameter_controls)
	parameter_controls.parameters_updated.connect(_on_parameters_updated)
	parameter_controls.parameter_changed.connect(_mark_current_dirty)
	parameter_controls.hide()

	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	audio_player.finished.connect(_on_playback_finished)
	add_child(audio_player)

	export_dialog = FileDialog.new()
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.filters = PackedStringArray(["*.json ; JSON preset"])
	export_dialog.ok_button_text = "Save"
	export_dialog.file_selected.connect(_on_export_file_selected)
	add_child(export_dialog)

	_disable_actions()

func _connect_signals() -> void:
	search_box.text_changed.connect(_on_search_changed)
	sound_tree.item_selected.connect(_on_tree_item_selected)
	reload_button.pressed.connect(reload_catalog)
	play_button.pressed.connect(_on_play_requested)
	stop_button.pressed.connect(_on_stop_requested)
	save_button.pressed.connect(_on_save_requested)
	export_button.pressed.connect(_on_export_requested)

func _disable_actions() -> void:
	play_button.disabled = true
	stop_button.disabled = true
	save_button.disabled = true
	export_button.disabled = true
	_reset_visualizations()

func _reset_visualizations() -> void:
	waveform_samples = PackedFloat32Array()
	spectrum_bins = PackedFloat32Array()
	preview_stream = null
	if waveform_control:
		waveform_control.queue_redraw()
	if spectrum_control:
		spectrum_control.queue_redraw()

func reload_catalog() -> void:
	if audio_player:
		audio_player.stop()
	sound_tree.deselect_all()
	catalog_entries.clear()
	entries_by_id.clear()
	category_cache.clear()
	current_entry_id = ""
	parameter_controls.hide()
	sound_name_label.text = "Select a sound"
	file_path_label.text = ""
	file_path_label.tooltip_text = ""
	metadata_label.text = ""
	_disable_actions()
	_scan_directory("")
	if catalog_entries.size() > 1:
		catalog_entries.sort_custom(Callable(self, "_compare_entries"))
	_populate_tree(search_box.text)

func _scan_directory(relative_path: String) -> void:
	var full_path = PARAMETERS_BASE_DIR + relative_path
	var dir = DirAccess.open(full_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry_name = dir.get_next()
	while entry_name != "":
		if entry_name == "." or entry_name == "..":
			entry_name = dir.get_next()
			continue
		var sub_path = relative_path + entry_name
		if dir.current_is_dir():
			_scan_directory(sub_path + CATEGORY_SEPARATOR)
		elif entry_name.to_lower().ends_with(".json"):
			var entry = _parse_parameter_file(full_path + entry_name, relative_path, entry_name)
			if not entry.is_empty():
				catalog_entries.append(entry)
				entries_by_id[entry["id"]] = entry
		entry_name = dir.get_next()
	dir.list_dir_end()

func _compare_entries(a: Dictionary, b: Dictionary) -> bool:
	var cat_a := String(a.get("relative_dir", ""))
	var cat_b := String(b.get("relative_dir", ""))
	var cmp = cat_a.naturalnocasecmp_to(cat_b)
	if cmp == 0:
		return a["display_name"].naturalnocasecmp_to(b["display_name"]) < 0
	return cmp < 0

func _parse_parameter_file(file_path: String, relative_dir: String, file_name: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_warning("Audio Catalog: Unable to open %s" % file_path)
		return {}
	var json_text = file.get_as_text()
	file.close()
	var parser = JSON.new()
	var parse_error = parser.parse(json_text)
	if parse_error != OK:
		push_warning("Audio Catalog: JSON parse error in %s" % file_path)
		return {}
	var data = parser.data
	var metadata := {}
	var parameters := {}
	var format := PresetFormat.DIRECT
	var nested_key := ""
	if data.has("parameters") and data.has("_metadata"):
		format = PresetFormat.ROOT_METADATA
		metadata = data.get("_metadata", {})
		parameters = data.get("parameters", {})
	elif _has_nested_parameters(data):
		format = PresetFormat.NESTED_METADATA
		for key in data.keys():
			if key.begins_with("_"):
				continue
			var payload = data[key]
			if payload is Dictionary and payload.has("parameters"):
				nested_key = key
				metadata = payload.get("_metadata", {})
				parameters = payload.get("parameters", {})
				break
	else:
		parameters = data
	if parameters.is_empty():
		push_warning("Audio Catalog: No parameters found in %s" % file_path)
		return {}
	var sound_key = _resolve_sound_key(metadata, file_name, nested_key)
	return {
		"id": relative_dir + file_name,
		"file_path": file_path,
		"relative_dir": relative_dir,
		"file_name": file_name,
		"sound_key": sound_key,
		"metadata": metadata,
		"parameters": parameters.duplicate(true),
		"raw_data": data,
		"format": format,
		"nested_key": nested_key,
		"category_segments": _split_category(relative_dir),
		"display_name": _format_display_name(sound_key),
		"search_blob": _build_search_blob(sound_key, metadata, file_path),
		"dirty": false
	}

func _has_nested_parameters(data: Dictionary) -> bool:
	for key in data.keys():
		if key.begins_with("_"):
			continue
		var payload = data[key]
		if payload is Dictionary and payload.has("parameters"):
			return true
	return false

func _resolve_sound_key(metadata: Dictionary, file_name: String, nested_key: String) -> String:
	if metadata.has("sound_type"):
		return String(metadata["sound_type"]).to_lower()
	if nested_key != "":
		return nested_key.to_lower()
	return file_name.get_basename().to_lower()

func _split_category(relative_dir: String) -> Array:
	if relative_dir.is_empty():
		return []
	var trimmed = relative_dir.trim_suffix(CATEGORY_SEPARATOR)
	if trimmed.is_empty():
		return []
	return trimmed.split(CATEGORY_SEPARATOR, false)

func _format_display_name(identifier: String) -> String:
	var parts = identifier.split("_")
	for i in range(parts.size()):
		var part: String = parts[i]
		if part.is_empty():
			continue
		parts[i] = part.substr(0, 1).to_upper() + part.substr(1)
	return " ".join(parts)

func _build_search_blob(sound_key: String, metadata: Dictionary, file_path: String) -> String:
	var parts: Array[String] = []
	parts.append(sound_key)
	parts.append(file_path)
	if metadata.has("description"):
		parts.append(String(metadata["description"]))
	if metadata.has("tags"):
		parts.append(String(metadata["tags"]))
	return " ".join(parts).to_lower()

func _populate_tree(filter_text: String) -> void:
	sound_tree.clear()
	var root = sound_tree.create_item()
	category_cache.clear()
	var filter = filter_text.strip_edges().to_lower()
	var count = 0
	for entry in catalog_entries:
		if filter != "" and not entry["search_blob"].contains(filter):
			continue
		var parent = _ensure_category_items(root, entry["category_segments"])
		var item = sound_tree.create_item(parent)
		var title = entry["display_name"]
		if entry["dirty"]:
			title += " *"
		item.set_text(0, title)
		item.set_metadata(0, entry["id"])
		count += 1
	if count == 0:
		var placeholder = sound_tree.create_item(root)
		placeholder.set_text(0, "No presets match filter")
		placeholder.set_selectable(0, false)

func _ensure_category_items(root: TreeItem, segments: Array) -> TreeItem:
	var parent = root
	var path = ""
	for segment_raw in segments:
		var segment = segment_raw
		if path.is_empty():
			path = segment
		else:
			path = path + CATEGORY_SEPARATOR + segment
		if not category_cache.has(path):
			var item = sound_tree.create_item(parent)
			item.set_text(0, _format_display_name(segment))
			item.set_selectable(0, false)
			category_cache[path] = item
		parent = category_cache[path]
	return parent

func _on_search_changed(new_text: String) -> void:
	_populate_tree(new_text)

func _on_tree_item_selected() -> void:
	var item = sound_tree.get_selected()
	if item == null:
		return
	var entry_id = item.get_metadata(0)
	if entry_id is String:
		_show_entry(entry_id)

func _show_entry(entry_id: String) -> void:
	if not entries_by_id.has(entry_id):
		return
	var entry = entries_by_id[entry_id]
	current_entry_id = entry_id
	sound_name_label.text = entry["display_name"]
	file_path_label.text = entry["file_path"]
	file_path_label.tooltip_text = ProjectSettings.globalize_path(entry["file_path"])
	metadata_label.text = _format_metadata(entry)
	parameter_controls.show()
	parameter_controls.create_parameter_controls(entry["sound_key"], entry["parameters"])
	_update_action_states(entry)
	_refresh_preview(false)

func _format_metadata(entry: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("[b]Sound Key:[/b] %s" % entry["sound_key"])
	var category_segments: Array = entry["category_segments"]
	var category_display = "root"
	if category_segments.size() > 0:
		var parts: Array[String] = []
		for segment in category_segments:
			parts.append(_format_display_name(segment))
		category_display = " > ".join(parts)
	lines.append("[b]Category:[/b] %s" % category_display)
	var metadata = entry["metadata"]
	if metadata.has("description"):
		lines.append("[b]Description:[/b] %s" % metadata["description"])
	if metadata.has("tags"):
		lines.append("[b]Tags:[/b] %s" % metadata["tags"])
	if metadata.has("version"):
		lines.append("[b]Version:[/b] %s" % metadata["version"])
	if metadata.has("created_at"):
		lines.append("[b]Created:[/b] %s" % metadata["created_at"])
	return "
".join(lines)

func _update_action_states(entry: Dictionary) -> void:
	var sound_type = _resolve_sound_type(entry)
	play_button.disabled = sound_type == null
	save_button.disabled = not entry.get("dirty", false)
	stop_button.disabled = not audio_player.playing
	export_button.disabled = false

func _resolve_sound_type(entry: Dictionary):
	if entry.has("sound_type_enum"):
		return entry["sound_type_enum"]
	var enum_name = entry["sound_key"].to_upper().replace("-", "_").replace(" ", "_")
	if AudioSynthesizer.SoundType.has(enum_name):
		var value = AudioSynthesizer.SoundType[enum_name]
		entry["sound_type_enum"] = value
		return value
	return null

func _on_parameters_updated(sound_key: String, values: Dictionary) -> void:
	if current_entry_id.is_empty():
		return
	var entry = entries_by_id[current_entry_id]
	for param_name in values.keys():
		if entry["parameters"].has(param_name) and entry["parameters"][param_name] is Dictionary:
			entry["parameters"][param_name]["value"] = values[param_name]
	_mark_current_dirty()
	_refresh_preview(false)

func _mark_current_dirty(param_name := "", value: Variant = null) -> void:
	if current_entry_id.is_empty():
		return
	var entry = entries_by_id[current_entry_id]
	if entry.get("dirty", false):
		return
	entry["dirty"] = true
	save_button.disabled = false
	_update_tree_label(entry["id"], true)
	_update_action_states(entry)

func _update_tree_label(entry_id: String, dirty: bool) -> void:
	var root = sound_tree.get_root()
	if root == null:
		return
	var stack: Array[TreeItem] = [root]
	while stack.size() > 0:
		var item = stack.pop_back()
		var metadata = item.get_metadata(0)
		if metadata == entry_id:
			var entry = entries_by_id[entry_id]
			var title = entry["display_name"]
			if dirty:
				title += " *"
			item.set_text(0, title)
			return
		var child = item.get_first_child()
		while child:
			stack.append(child)
			child = child.get_next()

func _on_play_requested() -> void:
	if current_entry_id.is_empty():
		return
	_refresh_preview(true)

func _on_stop_requested() -> void:
	if audio_player and audio_player.playing:
		audio_player.stop()
	_refresh_action_states()
	_refresh_action_states()

func _on_playback_finished() -> void:
	_refresh_action_states()

func _on_save_requested() -> void:
	if current_entry_id.is_empty():
		return
	var entry = entries_by_id[current_entry_id]
	if not entry.get("dirty", false):
		return
	if _write_entry_to_disk(entry):
		entry["dirty"] = false
		save_button.disabled = true
		_update_tree_label(entry["id"], false)
		_update_action_states(entry)

func _on_export_requested() -> void:
	if current_entry_id.is_empty():
		return
	var entry = entries_by_id[current_entry_id]
	export_dialog.current_file = entry["file_name"]
	export_dialog.popup_centered_ratio(0.6)

func _on_export_file_selected(path: String) -> void:
	if current_entry_id.is_empty():
		return
	var entry = entries_by_id[current_entry_id]
	_write_entry_json(entry, path)

func _write_entry_to_disk(entry: Dictionary) -> bool:
	var save_path = entry["file_path"]
	var success = _write_entry_json(entry, save_path)
	if success:
		print("Audio Catalog: Saved %s" % save_path)
	else:
		push_warning("Audio Catalog: Failed to save %s" % save_path)
	return success

func _write_entry_json(entry: Dictionary, path: String) -> bool:
	var save_dict = entry["raw_data"].duplicate(true)
	match entry["format"]:
		PresetFormat.ROOT_METADATA:
			save_dict["parameters"] = entry["parameters"]
			save_dict["_metadata"] = entry["metadata"]
		PresetFormat.NESTED_METADATA:
			var key = entry["nested_key"]
			if not save_dict.has(key):
				save_dict[key] = {}
			save_dict[key]["parameters"] = entry["parameters"]
			save_dict[key]["_metadata"] = entry["metadata"]
		PresetFormat.DIRECT:
			save_dict = entry["parameters"]
	entry["raw_data"] = save_dict.duplicate(true)
	var json_text = JSON.stringify(save_dict, JSON_INDENT)
	var absolute_path = path
	if not absolute_path.begins_with("res://") and not absolute_path.begins_with("user://"):
		absolute_path = path
	var file = FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(json_text)
	file.close()
	return true

func _refresh_preview(auto_play: bool = false) -> bool:
	if current_entry_id.is_empty():
		return false
	if not entries_by_id.has(current_entry_id):
		return false
	var entry = entries_by_id[current_entry_id]
	var sound_type = _resolve_sound_type(entry)
	if sound_type == null:
		if auto_play:
			push_warning("Audio Catalog: No generator for %s" % entry["sound_key"])
		return false
	var params = parameter_controls.get_current_parameter_values()
	var stream = CustomSoundGenerator.generate_custom_sound(sound_type, params)
	if stream == null:
		if auto_play:
			push_warning("Audio Catalog: Failed to generate audio for %s" % entry["sound_key"])
		return false
	preview_stream = stream
	_update_visualizations_from_stream(stream)
	if audio_player:
		if auto_play:
			if audio_player.playing:
				audio_player.stop()
			audio_player.stream = stream
			audio_player.play()
		elif not audio_player.playing:
			audio_player.stream = stream
	_update_action_states(entry)
	return true

func _generate_preview_stream() -> AudioStreamWAV:
	if current_entry_id.is_empty() or not entries_by_id.has(current_entry_id):
		return null
	var entry = entries_by_id[current_entry_id]
	var sound_type = _resolve_sound_type(entry)
	if sound_type == null:
		return null
	return CustomSoundGenerator.generate_custom_sound(sound_type, parameter_controls.get_current_parameter_values())

func _update_visualizations_from_stream(stream: AudioStreamWAV) -> void:
	if stream == null:
		return
	var samples = _extract_samples(stream)
	waveform_samples = _downsample_samples(samples, WAVEFORM_POINT_COUNT)
	spectrum_bins = _compute_spectrum_bins(samples, stream.mix_rate, SPECTRUM_BIN_COUNT)
	if waveform_control:
		waveform_control.queue_redraw()
	if spectrum_control:
		spectrum_control.queue_redraw()

func _extract_samples(stream: AudioStreamWAV) -> PackedFloat32Array:
	var data = stream.data
	var channels = 1
	if stream.stereo:
		channels = 2
	if channels <= 0:
		channels = 1
	var frame_count = int(data.size() / (2 * channels))
	var samples := PackedFloat32Array()
	samples.resize(frame_count)
	for frame in range(frame_count):
		var accum = 0.0
		for ch in range(channels):
			var index = (frame * channels + ch) * 2
			var sample_value = data[index] | (data[index + 1] << 8)
			if sample_value & 0x8000:
				sample_value -= 0x10000
			accum += float(sample_value) / 32768.0
		samples[frame] = accum / channels
	return samples

func _downsample_samples(samples: PackedFloat32Array, target_count: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	if samples.is_empty() or target_count <= 1:
		return result
	var stride = float(samples.size()) / float(target_count)
	for i in range(target_count):
		var index = int(i * stride)
		if index >= samples.size():
			index = samples.size() - 1
		result.append(clamp(samples[index], -1.0, 1.0))
	return result

func _compute_spectrum_bins(samples: PackedFloat32Array, sample_rate: int, bin_count: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	if samples.is_empty() or bin_count <= 0:
		return result
	var window_size = min(samples.size(), 1024)
	if window_size == 0:
		return result
	var scale = 1.0 / window_size
	for k in range(bin_count):
		var real = 0.0
		var imag = 0.0
		for n in range(window_size):
			var angle = TAU * float(k) * float(n) / float(window_size)
			var value = samples[n]
			real += value * cos(angle)
			imag -= value * sin(angle)
		var magnitude = sqrt(real * real + imag * imag) * scale
		result.append(magnitude)
	return result

func _on_waveform_draw() -> void:
	if not waveform_control:
		return
	var rect = _get_control_rect(waveform_control)
	waveform_control.draw_rect(rect, Color(0.08, 0.08, 0.1, 1.0), true)
	var mid_y = rect.size.y * 0.5
	waveform_control.draw_line(Vector2(0, mid_y), Vector2(rect.size.x, mid_y), Color(0.2, 0.2, 0.25, 1.0), 1.0)
	if waveform_samples.is_empty():
		return
	var step = rect.size.x / float(max(1, waveform_samples.size() - 1))
	var prev_point = Vector2(0.0, mid_y)
	for i in range(waveform_samples.size()):
		var x = step * i
		var y = mid_y - waveform_samples[i] * (rect.size.y * 0.45)
		var point = Vector2(x, y)
		waveform_control.draw_line(prev_point, point, Color(0.2, 0.85, 1.0, 1.0), 2.0)
		prev_point = point

func _on_spectrum_draw() -> void:
	if not spectrum_control:
		return
	var rect = _get_control_rect(spectrum_control)
	spectrum_control.draw_rect(rect, Color(0.08, 0.08, 0.1, 1.0), true)
	if spectrum_bins.is_empty():
		return
	var bar_width = rect.size.x / float(spectrum_bins.size())
	for i in range(spectrum_bins.size()):
		var magnitude = clamp(spectrum_bins[i] * 8.0, 0.0, 1.0)
		var height = magnitude * rect.size.y
		var pos = Vector2(i * bar_width, rect.size.y - height)
		spectrum_control.draw_rect(Rect2(pos, Vector2(bar_width * 0.8, height)), Color(0.4, 0.75, 1.0, 1.0))

func _refresh_action_states() -> void:
	if current_entry_id != "" and entries_by_id.has(current_entry_id):
		_update_action_states(entries_by_id[current_entry_id])
	else:
		_disable_actions()
