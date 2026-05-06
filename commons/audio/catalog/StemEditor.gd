# StemEditor.gd
# Visual stem editor for viewing and editing individual tracks of a song
#
# Features:
# - Horizontal lanes for each instrument (like a DAW)
# - Pattern visualization with velocity blocks
# - Mute/Solo per track
# - Velocity editing (click to adjust)
# - Play/Pause with track isolation
# - Export stems as separate WAVs
# - MIDI export

extends Control

signal editor_closed

const LayerRenderer = preload("res://commons/audio/catalog/LayerRenderer.gd")
const SAMPLE_RATE = 44100.0
const LANE_HEIGHT = 50
const STEP_WIDTH = 40
const HEADER_WIDTH = 150
const PLAYHEAD_COLOR = Color(0.3, 0.8, 1.0, 0.8)

var _song_id: String = ""
var _bpm: float = 120.0
var _num_bars: int = 4
var _tracks: Array = []  # Array of track dictionaries
var _solo_track: int = -1  # -1 = none, otherwise index of solo'd track
var _is_playing: bool = false
var _playhead_position: float = 0.0
var _current_step: int = 0

var _player: AudioStreamPlayer
var _playhead_timer: Timer
var _generated_stems: Dictionary = {}  # track_name -> AudioStreamWAV

# UI Elements
var _header_panel: PanelContainer
var _lanes_container: Control
var _lanes_scroll: ScrollContainer
var _playhead: ColorRect
var _play_btn: Button
var _stop_btn: Button
var _export_stems_btn: Button
var _export_midi_btn: Button
var _bpm_spin: SpinBox
var _bars_spin: SpinBox
var _status_label: Label
var _close_btn: Button


func _ready():
	_setup_ui()
	_setup_audio()


func _setup_ui():
	# Main background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 8)
	main_vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 12)
	add_child(main_vbox)
	
	# === TOP BAR ===
	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 16)
	main_vbox.add_child(top_bar)
	
	# Title
	var title = Label.new()
	title.text = "🎚️ STEM EDITOR"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	top_bar.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)
	
	# BPM control
	var bpm_label = Label.new()
	bpm_label.text = "BPM:"
	bpm_label.add_theme_font_size_override("font_size", 14)
	top_bar.add_child(bpm_label)
	
	_bpm_spin = SpinBox.new()
	_bpm_spin.min_value = 60
	_bpm_spin.max_value = 200
	_bpm_spin.value = 120
	_bpm_spin.value_changed.connect(_on_bpm_changed)
	top_bar.add_child(_bpm_spin)
	
	# Bars control
	var bars_label = Label.new()
	bars_label.text = "Bars:"
	bars_label.add_theme_font_size_override("font_size", 14)
	top_bar.add_child(bars_label)
	
	_bars_spin = SpinBox.new()
	_bars_spin.min_value = 1
	_bars_spin.max_value = 32
	_bars_spin.value = 4
	_bars_spin.value_changed.connect(_on_bars_changed)
	top_bar.add_child(_bars_spin)
	
	# Close button
	_close_btn = Button.new()
	_close_btn.text = "✕ Close"
	_close_btn.pressed.connect(_on_close_pressed)
	_style_button(_close_btn, Color(0.5, 0.2, 0.2))
	top_bar.add_child(_close_btn)
	
	# === TRANSPORT BAR ===
	var transport = HBoxContainer.new()
	transport.add_theme_constant_override("separation", 12)
	transport.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(transport)
	
	_play_btn = Button.new()
	_play_btn.text = "▶ Play"
	_play_btn.pressed.connect(_on_play_pressed)
	_style_button(_play_btn, Color(0.2, 0.5, 0.3))
	transport.add_child(_play_btn)
	
	_stop_btn = Button.new()
	_stop_btn.text = "⏹ Stop"
	_stop_btn.pressed.connect(_on_stop_pressed)
	_style_button(_stop_btn, Color(0.5, 0.3, 0.2))
	transport.add_child(_stop_btn)
	
	var sep1 = VSeparator.new()
	transport.add_child(sep1)
	
	_export_stems_btn = Button.new()
	_export_stems_btn.text = "💾 Export Stems (WAV)"
	_export_stems_btn.pressed.connect(_on_export_stems_pressed)
	_style_button(_export_stems_btn, Color(0.3, 0.3, 0.5))
	transport.add_child(_export_stems_btn)
	
	_export_midi_btn = Button.new()
	_export_midi_btn.text = "🎹 Export MIDI"
	_export_midi_btn.pressed.connect(_on_export_midi_pressed)
	_style_button(_export_midi_btn, Color(0.3, 0.4, 0.5))
	transport.add_child(_export_midi_btn)
	
	# === STATUS ===
	_status_label = Label.new()
	_status_label.text = "Load a song to edit stems"
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_status_label)
	
	# === LANES AREA ===
	_lanes_scroll = ScrollContainer.new()
	_lanes_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lanes_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_lanes_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(_lanes_scroll)
	
	_lanes_container = Control.new()
	_lanes_container.custom_minimum_size = Vector2(800, 400)
	_lanes_scroll.add_child(_lanes_container)
	
	# Playhead
	_playhead = ColorRect.new()
	_playhead.color = PLAYHEAD_COLOR
	_playhead.custom_minimum_size = Vector2(2, 0)
	_playhead.visible = false
	_lanes_container.add_child(_playhead)


func _setup_audio():
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.finished.connect(_on_playback_finished)
	add_child(_player)
	
	_playhead_timer = Timer.new()
	_playhead_timer.wait_time = 0.05
	_playhead_timer.timeout.connect(_update_playhead)
	add_child(_playhead_timer)


func load_song(song_id: String, bpm: float = 120.0):
	"""Load a song's patterns into the stem editor"""
	_song_id = song_id
	_bpm = bpm
	_bpm_spin.value = bpm
	_tracks.clear()
	_generated_stems.clear()
	
	# Get patterns from SoundbankGenerator
	var patterns = SoundbankGenerator.PATTERNS.get(song_id, {})
	var bass_cfg = SoundbankGenerator.BASS_PATTERNS.get(song_id, {})
	
	if patterns.is_empty():
		_status_label.text = "No patterns found for: " + song_id
		return
	
	# Create track entries
	var track_index = 0
	for instrument in patterns.keys():
		var track = {
			"index": track_index,
			"name": instrument,
			"pattern": patterns[instrument].duplicate(),
			"muted": false,
			"solo": false,
			"type": "drum" if _is_drum_instrument(instrument) else "melodic"
		}
		_tracks.append(track)
		track_index += 1
	
	# Add bass track if exists
	if bass_cfg.has("pattern"):
		var track = {
			"index": track_index,
			"name": "bass",
			"pattern": bass_cfg.pattern.duplicate(),
			"muted": false,
			"solo": false,
			"type": "bass",
			"style": bass_cfg.get("style", "sustained")
		}
		_tracks.append(track)
	
	_rebuild_lanes()
	_status_label.text = "Loaded: %s (%d tracks)" % [song_id, _tracks.size()]


func load_from_midi(path: String):
	"""Load patterns from a MIDI file"""
	var midi_data = MidiImporter.import_midi(path)
	if midi_data.is_empty():
		_status_label.text = "Failed to load MIDI file"
		return
	
	_song_id = path.get_file().get_basename()
	_bpm = midi_data.get("bpm", 120.0)
	_bpm_spin.value = _bpm
	_tracks.clear()
	_generated_stems.clear()
	
	var patterns = midi_data.get("patterns", {})
	var track_index = 0
	
	for instrument in patterns.keys():
		var track = {
			"index": track_index,
			"name": instrument,
			"pattern": patterns[instrument],
			"muted": false,
			"solo": false,
			"type": "drum" if _is_drum_instrument(instrument) else "melodic"
		}
		_tracks.append(track)
		track_index += 1
	
	_rebuild_lanes()
	_status_label.text = "Loaded MIDI: %s (%d tracks)" % [_song_id, _tracks.size()]


func _rebuild_lanes():
	"""Rebuild the visual lanes for all tracks"""
	# Clear existing lanes (except playhead)
	for child in _lanes_container.get_children():
		if child != _playhead:
			child.queue_free()
	
	var total_steps = 16 * _num_bars
	var total_width = HEADER_WIDTH + (total_steps * STEP_WIDTH) + 20
	var total_height = _tracks.size() * (LANE_HEIGHT + 4) + 40
	
	_lanes_container.custom_minimum_size = Vector2(total_width, total_height)
	
	# Create header row (beat markers)
	var header_row = _create_header_row(total_steps)
	header_row.position = Vector2(HEADER_WIDTH, 0)
	_lanes_container.add_child(header_row)
	
	# Create lanes for each track
	var y_offset = 30
	for track in _tracks:
		var lane = _create_lane(track, total_steps)
		lane.position = Vector2(0, y_offset)
		_lanes_container.add_child(lane)
		y_offset += LANE_HEIGHT + 4
	
	# Update playhead size
	_playhead.size = Vector2(2, total_height)
	_playhead.position.x = HEADER_WIDTH
	_playhead.z_index = 100


func _create_header_row(total_steps: int) -> Control:
	"""Create the beat marker header"""
	var header = Control.new()
	header.custom_minimum_size = Vector2(total_steps * STEP_WIDTH, 25)
	
	for step in range(total_steps):
		var bar = step / 16
		var beat = (step % 16) / 4
		var sub = step % 4
		
		var marker = Label.new()
		if sub == 0:
			if beat == 0:
				marker.text = str(bar + 1)
				marker.add_theme_font_size_override("font_size", 14)
				marker.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
			else:
				marker.text = "."
				marker.add_theme_font_size_override("font_size", 12)
				marker.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		else:
			marker.text = ""
		
		marker.position = Vector2(step * STEP_WIDTH + 2, 0)
		marker.size = Vector2(STEP_WIDTH, 25)
		header.add_child(marker)
	
	return header


func _create_lane(track: Dictionary, total_steps: int) -> Control:
	"""Create a single track lane"""
	var lane = Control.new()
	lane.custom_minimum_size = Vector2(HEADER_WIDTH + total_steps * STEP_WIDTH, LANE_HEIGHT)
	
	# Track header panel
	var header = PanelContainer.new()
	header.custom_minimum_size = Vector2(HEADER_WIDTH - 4, LANE_HEIGHT - 4)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.12, 0.12, 0.15)
	header_style.set_corner_radius_all(4)
	header.add_theme_stylebox_override("panel", header_style)
	lane.add_child(header)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 4)
	header.add_child(header_hbox)
	
	# Mute button
	var mute_btn = Button.new()
	mute_btn.text = "M"
	mute_btn.toggle_mode = true
	mute_btn.button_pressed = track.muted
	mute_btn.custom_minimum_size = Vector2(24, 24)
	mute_btn.pressed.connect(_on_mute_toggled.bind(track.index))
	_style_toggle_button(mute_btn, Color(0.6, 0.3, 0.2))
	header_hbox.add_child(mute_btn)
	
	# Solo button
	var solo_btn = Button.new()
	solo_btn.text = "S"
	solo_btn.toggle_mode = true
	solo_btn.button_pressed = track.solo
	solo_btn.custom_minimum_size = Vector2(24, 24)
	solo_btn.pressed.connect(_on_solo_toggled.bind(track.index))
	_style_toggle_button(solo_btn, Color(0.6, 0.6, 0.2))
	header_hbox.add_child(solo_btn)
	
	# Track name
	var name_label = Label.new()
	name_label.text = track.name.capitalize()
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(name_label)
	
	# Pattern grid
	var grid = _create_pattern_grid(track, total_steps)
	grid.position = Vector2(HEADER_WIDTH, 0)
	lane.add_child(grid)
	
	# Store reference for updates
	track["lane_node"] = lane
	track["grid_node"] = grid
	track["mute_btn"] = mute_btn
	track["solo_btn"] = solo_btn
	
	return lane


func _create_pattern_grid(track: Dictionary, total_steps: int) -> Control:
	"""Create the pattern grid with velocity blocks"""
	var grid = Control.new()
	grid.custom_minimum_size = Vector2(total_steps * STEP_WIDTH, LANE_HEIGHT - 4)
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.08)
	bg.size = Vector2(total_steps * STEP_WIDTH, LANE_HEIGHT - 4)
	grid.add_child(bg)
	
	# Beat dividers
	for step in range(total_steps + 1):
		if step % 4 == 0:
			var divider = ColorRect.new()
			divider.color = Color(0.25, 0.25, 0.3) if step % 16 == 0 else Color(0.15, 0.15, 0.2)
			divider.size = Vector2(1, LANE_HEIGHT - 4)
			divider.position = Vector2(step * STEP_WIDTH, 0)
			grid.add_child(divider)
	
	# Pattern blocks
	var pattern = track.pattern
	for bar in range(_num_bars):
		for step in range(16):
			var pattern_step = step % pattern.size()
			var vel = pattern[pattern_step] if pattern_step < pattern.size() else 0
			var global_step = bar * 16 + step
			
			var block = _create_velocity_block(track.index, global_step, vel)
			block.position = Vector2(global_step * STEP_WIDTH + 2, 4)
			grid.add_child(block)
			
			# Store reference
			if not track.has("blocks"):
				track["blocks"] = {}
			track.blocks[global_step] = block
	
	return grid


func _create_velocity_block(track_idx: int, step: int, velocity: float) -> Control:
	"""Create a clickable velocity block"""
	var block = ColorRect.new()
	block.custom_minimum_size = Vector2(STEP_WIDTH - 4, LANE_HEIGHT - 12)
	block.size = Vector2(STEP_WIDTH - 4, LANE_HEIGHT - 12)
	
	# Color based on velocity
	if velocity >= 2.0:
		block.color = Color(0.8, 0.3, 0.2)  # Accent (red)
	elif velocity >= 1.0:
		block.color = Color(0.3, 0.6, 0.8)  # Normal (blue)
	elif velocity > 0:
		block.color = Color(0.2, 0.35, 0.45)  # Ghost (dim blue)
	else:
		block.color = Color(0.1, 0.1, 0.12)  # Off (dark)
	
	# Make clickable
	block.mouse_filter = Control.MOUSE_FILTER_STOP
	block.gui_input.connect(_on_block_input.bind(track_idx, step))
	
	return block


func _on_block_input(event: InputEvent, track_idx: int, step: int):
	"""Handle click on velocity block to cycle velocity"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_cycle_velocity(track_idx, step, 1)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cycle_velocity(track_idx, step, -1)


func _cycle_velocity(track_idx: int, step: int, direction: int):
	"""Cycle through velocity values: 0 -> 0.5 -> 1 -> 2 -> 0"""
	var track = _tracks[track_idx]
	var pattern_step = step % track.pattern.size()
	var current = track.pattern[pattern_step]
	
	var velocities = [0.0, 0.5, 1.0, 2.0]
	var current_idx = 0
	for i in range(velocities.size()):
		if abs(current - velocities[i]) < 0.1:
			current_idx = i
			break
	
	var new_idx = (current_idx + direction + velocities.size()) % velocities.size()
	track.pattern[pattern_step] = velocities[new_idx]
	
	# Update visual
	if track.has("blocks") and track.blocks.has(step):
		var block = track.blocks[step]
		var vel = velocities[new_idx]
		if vel >= 2.0:
			block.color = Color(0.8, 0.3, 0.2)
		elif vel >= 1.0:
			block.color = Color(0.3, 0.6, 0.8)
		elif vel > 0:
			block.color = Color(0.2, 0.35, 0.45)
		else:
			block.color = Color(0.1, 0.1, 0.12)
	
	# Clear cached stems
	_generated_stems.clear()
	_status_label.text = "Pattern modified - click Play to hear changes"


func _on_mute_toggled(track_idx: int):
	"""Handle mute button toggle"""
	var track = _tracks[track_idx]
	track.muted = not track.muted
	_update_track_visual(track_idx)
	_generated_stems.clear()


func _on_solo_toggled(track_idx: int):
	"""Handle solo button toggle"""
	var track = _tracks[track_idx]
	track.solo = not track.solo
	
	# Update solo state
	var any_solo = false
	for t in _tracks:
		if t.solo:
			any_solo = true
			break
	
	_solo_track = track_idx if track.solo else -1
	
	# Update all track visuals
	for i in range(_tracks.size()):
		_update_track_visual(i)
	
	_generated_stems.clear()


func _update_track_visual(track_idx: int):
	"""Update visual state of a track (muted/solo indication)"""
	var track = _tracks[track_idx]
	
	if track.has("grid_node"):
		var grid = track.grid_node
		var bg = grid.get_child(0) as ColorRect
		
		var any_solo = false
		for t in _tracks:
			if t.solo:
				any_solo = true
				break
		
		var is_active = not track.muted and (not any_solo or track.solo)
		
		if bg:
			bg.color = Color(0.06, 0.06, 0.08) if is_active else Color(0.04, 0.04, 0.05)


func _on_play_pressed():
	"""Start playback"""
	if _is_playing:
		_pause_playback()
	else:
		_start_playback()


func _on_stop_pressed():
	"""Stop playback"""
	_stop_playback()


func _start_playback():
	"""Generate and play the current pattern mix"""
	_status_label.text = "Generating audio..."
	
	# Generate mix
	var mix = _generate_mix()
	if mix == null:
		_status_label.text = "Failed to generate audio"
		return
	
	_player.stream = mix
	_player.play()
	_is_playing = true
	_play_btn.text = "⏸ Pause"
	_playhead.visible = true
	_playhead_timer.start()
	_status_label.text = "Playing..."


func _pause_playback():
	"""Pause playback"""
	_player.stream_paused = true
	_is_playing = false
	_play_btn.text = "▶ Play"
	_playhead_timer.stop()
	_status_label.text = "Paused"


func _stop_playback():
	"""Stop playback and reset"""
	_player.stop()
	_is_playing = false
	_play_btn.text = "▶ Play"
	_playhead.visible = false
	_playhead.position.x = HEADER_WIDTH
	_playhead_position = 0.0
	_current_step = 0
	_playhead_timer.stop()
	_status_label.text = "Stopped"


func _on_playback_finished():
	"""Handle playback end"""
	_stop_playback()


func _update_playhead():
	"""Update playhead position during playback"""
	if not _is_playing or _player.stream == null:
		return
	
	var position = _player.get_playback_position()
	var total_duration = _player.stream.get_length()
	var progress = position / total_duration if total_duration > 0 else 0
	
	var total_steps = 16 * _num_bars
	var step_width = STEP_WIDTH
	
	_playhead.position.x = HEADER_WIDTH + (progress * total_steps * step_width)
	_current_step = int(progress * total_steps)


func _generate_mix() -> AudioStreamWAV:
	"""Generate the audio mix from current patterns."""
	return LayerRenderer.render_mix_stream(_song_id, _tracks, _bpm, _num_bars)


func _generate_track_audio(track: Dictionary, bank: SoundbankLoader, total_samples: int, bar_duration: float) -> PackedFloat32Array:
	"""Generate audio for a single track via shared renderer."""
	var velocity_song_id: String = LayerRenderer.resolve_bank_id(_song_id)
	return LayerRenderer.render_track_buffer(track, bank, velocity_song_id, total_samples, bar_duration, _num_bars)


func _create_audio_stream(buffer: PackedFloat32Array) -> AudioStreamWAV:
	"""Create AudioStreamWAV from float buffer via shared renderer."""
	return LayerRenderer.create_audio_stream(buffer)


func _on_export_stems_pressed():
	"""Export each track as a separate WAV file"""
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var base_path = "user://stems/%s_%s/" % [_song_id, timestamp]
	
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_path))
	
	var bank = LayerRenderer.load_song_bank(_song_id)
	var bar_duration = 240.0 / _bpm
	var total_samples = int(_num_bars * bar_duration * SAMPLE_RATE)
	
	var exported_count = 0
	
	for track in _tracks:
		if track.muted:
			continue
		
		var track_audio = _generate_track_audio(track, bank, total_samples, bar_duration)
		if track_audio == null:
			continue
		
		var stream = _create_audio_stream(track_audio)
		var path = base_path + track.name + ".wav"
		
		if _save_wav_file(stream, path):
			exported_count += 1
	
	var global_path = ProjectSettings.globalize_path(base_path)
	_status_label.text = "Exported %d stems to %s" % [exported_count, global_path]
	print("Stems exported to: ", global_path)


func _on_export_midi_pressed():
	"""Export patterns to MIDI file"""
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path = "user://exports/%s_%s.mid" % [_song_id, timestamp]
	
	# Build stem data for export
	var stem_data = {
		"bars": _num_bars,
		"tracks": []
	}
	
	for track in _tracks:
		stem_data.tracks.append({
			"name": track.name,
			"pattern": track.pattern,
			"muted": track.muted
		})
	
	if MidiExporter.export_stem_data(stem_data, path, _bpm):
		var global_path = ProjectSettings.globalize_path(path)
		_status_label.text = "Exported MIDI to " + global_path
		print("MIDI exported to: ", global_path)
	else:
		_status_label.text = "Failed to export MIDI"


func _save_wav_file(wav: AudioStreamWAV, path: String) -> bool:
	"""Save AudioStreamWAV to disk"""
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	
	var data = wav.data
	var sample_rate = wav.mix_rate
	var channels = 2 if wav.stereo else 1
	var bits_per_sample = 16
	var byte_rate = sample_rate * channels * bits_per_sample / 8
	var block_align = channels * bits_per_sample / 8
	
	# WAV header
	file.store_string("RIFF")
	file.store_32(36 + data.size())
	file.store_string("WAVE")
	file.store_string("fmt ")
	file.store_32(16)
	file.store_16(1)
	file.store_16(channels)
	file.store_32(sample_rate)
	file.store_32(byte_rate)
	file.store_16(block_align)
	file.store_16(bits_per_sample)
	file.store_string("data")
	file.store_32(data.size())
	file.store_buffer(data)
	
	file.close()
	return true


func _on_bpm_changed(value: float):
	"""Handle BPM change"""
	_bpm = value
	_generated_stems.clear()
	_stop_playback()


func _on_bars_changed(value: float):
	"""Handle bar count change"""
	_num_bars = int(value)
	_generated_stems.clear()
	_stop_playback()
	_rebuild_lanes()


func _on_close_pressed():
	"""Close the stem editor"""
	_stop_playback()
	editor_closed.emit()
	queue_free()


func _is_drum_instrument(name: String) -> bool:
	"""Check if instrument is a drum type"""
	var drums = ["kick", "snare", "clap", "hihat", "rimshot", "shaker", 
				 "tambourine", "perc", "cr5000_kick", "cr5000_snare", 
				 "cr5000_hihat", "fingersnap"]
	return name in drums


func _style_button(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 14)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed)


func _style_toggle_button(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 10)
	
	var pressed = style.duplicate()
	pressed.bg_color = color
	btn.add_theme_stylebox_override("pressed", pressed)
