@tool
extends Node3D
class_name ArraySequencer

## Array Step Sequencer - Arrays as Sound
##
## A sequencer is the same data structure as PatternTilePuzzle:
## - Grid: 2D array grid[track][step] instead of grid[y][x]
## - Cursor: Playhead moving through time = index incarnate
## - Values: Sound triggers instead of colors
##
## "An array is a function from indices to values"
## Here: Index (track, step) → Sound trigger

## Number of tracks (rows/sounds)
@export var num_tracks: int = 4:
	set(v):
		num_tracks = clampi(v, 1, 8)
		if is_inside_tree() and not Engine.is_editor_hint():
			_rebuild_grid()

## Number of steps (columns/time)
@export var num_steps: int = 8:
	set(v):
		num_steps = clampi(v, 4, 32)
		if is_inside_tree() and not Engine.is_editor_hint():
			_rebuild_grid()

## Cell size in meters
@export var cell_size: float = 0.05

## BPM (beats per minute)
@export var bpm: float = 120.0:
	set(v):
		bpm = clampf(v, 30.0, 300.0)
		_update_step_interval()
		bpm_changed.emit(bpm)

## Swing amount (0.0 = straight, 1.0 = full shuffle)
@export var swing: float = 0.0

## Sound preset name
@export var sound_preset: String = "808_kit"

@export_group("Playhead")
## Enable playhead visualization
@export var playhead_enabled: bool = true

## Auto-start playback
@export var auto_play: bool = false

## Loop playback
@export var loop: bool = true

## Signals
signal step_triggered(track: int, step: int, sound_name: String)
signal playhead_moved(step: int)
signal pattern_changed(track: int, step: int, active: bool)
signal bpm_changed(new_bpm: float)
signal preset_changed(preset_name: String)
signal playback_started()
signal playback_stopped()

## Sound presets - map preset name to array of sound types
const SOUND_PRESETS: Dictionary = {
	"808_kit": [
		AudioSynthesizer.SoundType.DARK_808_KICK,
		AudioSynthesizer.SoundType.TR909_KICK,
		AudioSynthesizer.SoundType.ACID_606_HIHAT,
		AudioSynthesizer.SoundType.DARK_808_SUB_BASS
	],
	"trap_beats": [
		AudioSynthesizer.SoundType.DARK_808_KICK,
		AudioSynthesizer.SoundType.EXPLOSION,  # snare-like
		AudioSynthesizer.SoundType.ACID_606_HIHAT,
		AudioSynthesizer.SoundType.SHIELD_HIT  # open hat
	],
	"synth_kit": [
		AudioSynthesizer.SoundType.TB303_ACID_BASS,
		AudioSynthesizer.SoundType.MOOG_BASS_LEAD,
		AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO,
		AudioSynthesizer.SoundType.PPG_WAVE_PAD
	],
	"tech_noir": [
		AudioSynthesizer.SoundType.MELODIC_DRONE,
		AudioSynthesizer.SoundType.GHOST_DRONE,
		AudioSynthesizer.SoundType.AMBIENT_WIND,
		AudioSynthesizer.SoundType.TELEPORT_DRONE
	],
	"retro": [
		AudioSynthesizer.SoundType.C64_SID_LEAD,
		AudioSynthesizer.SoundType.AMIGA_MOD_SAMPLE,
		AudioSynthesizer.SoundType.RETRO_JUMP,
		AudioSynthesizer.SoundType.PICKUP_MARIO
	]
}

## Color palette for tracks (visual feedback)
const TRACK_COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),   # Red - Kick
	Color(0.2, 0.6, 0.9),   # Blue - Snare
	Color(0.9, 0.9, 0.2),   # Yellow - Hi-hat
	Color(0.2, 0.9, 0.4),   # Green - Bass/Other
	Color(0.9, 0.5, 0.2),   # Orange
	Color(0.7, 0.2, 0.9),   # Purple
	Color(0.2, 0.9, 0.9),   # Cyan
	Color(0.9, 0.2, 0.6)    # Pink
]

## Internal state
var _grid_data: Array = []  # 2D array: _grid_data[track][step] = bool (active)
var _playhead_position: int = 0
var _is_playing: bool = false
var _step_timer: float = 0.0
var _step_interval: float = 0.5  # Seconds per step

## Visual components
var _grid_container: Node3D
var _cells: Array = []  # 2D array of MeshInstance3D
var _playhead_highlight: MeshInstance3D
var _step_label: Label3D
var _track_labels: Array[Label3D] = []
var _spawner_container: Node3D
var _cube_spawners: Array = []
var _background_panel: MeshInstance3D
var _play_stop_cube: Node3D

## Audio
var _audio_players: Array[AudioStreamPlayer] = []
var _track_sounds: Array = []  # Array of AudioSynthesizer.SoundType (untyped for Dictionary compatibility)

## Cube interaction
var _cube_scene: PackedScene = null
var _placed_cubes: Dictionary = {}  # Vector2i -> cube reference


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Try to load cube scene (reuse from pattern_tile_puzzle)
	_cube_scene = load("res://commons/primitives/arrays/pattern_tile_cube.tscn")

	_load_sound_preset(sound_preset)
	_initialize_grid_data()
	_create_audio_players()
	_create_background_panel()
	_create_grid_visuals()
	_create_playhead()
	_create_cube_spawners()
	_create_play_stop_cube()
	_create_labels()
	_update_step_interval()

	if auto_play:
		play()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not _is_playing:
		return

	_step_timer += delta

	# Apply swing to odd steps
	var current_interval = _step_interval
	if _playhead_position % 2 == 1 and swing > 0:
		current_interval *= (1.0 + swing * 0.5)

	if _step_timer >= current_interval:
		_step_timer -= current_interval
		_advance_playhead()


func _initialize_grid_data() -> void:
	_grid_data.clear()
	for track in range(num_tracks):
		var track_data: Array[bool] = []
		for step in range(num_steps):
			track_data.append(false)
		_grid_data.append(track_data)


func _load_sound_preset(preset_name: String) -> void:
	if preset_name in SOUND_PRESETS:
		_track_sounds = SOUND_PRESETS[preset_name].duplicate()
		# Pad with first sound if preset has fewer sounds than tracks
		while _track_sounds.size() < num_tracks:
			_track_sounds.append(_track_sounds[0] if _track_sounds.size() > 0 else AudioSynthesizer.SoundType.BASIC_SINE_WAVE)
	else:
		# Default to 808 kit
		_track_sounds = SOUND_PRESETS["808_kit"].duplicate()


func _create_audio_players() -> void:
	# Create an AudioStreamPlayer for each track
	for i in range(num_tracks):
		var player = AudioStreamPlayer.new()
		player.name = "TrackPlayer_%d" % i
		player.bus = "Master"
		add_child(player)
		_audio_players.append(player)


func _create_background_panel() -> void:
	# Light colored background panel behind the grid
	_background_panel = MeshInstance3D.new()
	_background_panel.name = "BackgroundPanel"

	var total_width = num_steps * cell_size
	var total_height = num_tracks * cell_size

	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(total_width + cell_size * 3, total_height + cell_size * 1.5, cell_size * 0.1)
	_background_panel.mesh = panel_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.85)  # Light cream color
	mat.roughness = 0.9
	_background_panel.material_override = mat

	_background_panel.position = Vector3(-cell_size * 0.5, 0, cell_size * 0.2)
	add_child(_background_panel)


func _create_grid_visuals() -> void:
	_grid_container = Node3D.new()
	_grid_container.name = "GridContainer"
	add_child(_grid_container)

	_cells.clear()

	var total_width = num_steps * cell_size
	var total_height = num_tracks * cell_size
	var offset_x = -total_width / 2.0
	var offset_y = -total_height / 2.0

	for track in range(num_tracks):
		var track_cells: Array[MeshInstance3D] = []
		for step in range(num_steps):
			var cell = MeshInstance3D.new()
			cell.name = "Cell_%d_%d" % [track, step]

			var box = BoxMesh.new()
			box.size = Vector3(cell_size * 0.9, cell_size * 0.9, cell_size * 0.3)
			cell.mesh = box

			# Position: steps go left-to-right, tracks go bottom-to-top
			cell.position = Vector3(
				offset_x + (step + 0.5) * cell_size,
				offset_y + (track + 0.5) * cell_size,
				0
			)

			_update_cell_material(cell, track, false)
			_grid_container.add_child(cell)
			track_cells.append(cell)
		_cells.append(track_cells)


func _update_cell_material(cell: MeshInstance3D, track: int, active: bool) -> void:
	var mat = StandardMaterial3D.new()
	var base_color = TRACK_COLORS[track % TRACK_COLORS.size()]

	if active:
		# Bright highlighted cell when active
		mat.albedo_color = base_color
		mat.emission_enabled = true
		mat.emission = base_color
		mat.emission_energy_multiplier = 1.5
	else:
		# Light base color when inactive (not dark)
		mat.albedo_color = base_color.lightened(0.6)
		mat.emission_enabled = false

	mat.roughness = 0.7
	cell.material_override = mat


func _create_playhead() -> void:
	_playhead_highlight = MeshInstance3D.new()
	_playhead_highlight.name = "PlayheadHighlight"

	var total_height = num_tracks * cell_size
	var box = BoxMesh.new()
	box.size = Vector3(cell_size * 1.1, total_height + cell_size * 0.2, cell_size * 0.1)
	_playhead_highlight.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.2, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 0.2)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_playhead_highlight.material_override = mat

	_grid_container.add_child(_playhead_highlight)
	_update_playhead_position()


func _update_playhead_position() -> void:
	if not _playhead_highlight:
		return

	var total_width = num_steps * cell_size
	var offset_x = -total_width / 2.0

	_playhead_highlight.position.x = offset_x + (_playhead_position + 0.5) * cell_size
	_playhead_highlight.position.z = -cell_size * 0.2
	_playhead_highlight.visible = playhead_enabled


func _create_cube_spawners() -> void:
	_spawner_container = Node3D.new()
	_spawner_container.name = "SpawnerContainer"
	add_child(_spawner_container)

	if not _cube_scene:
		return

	var total_height = num_tracks * cell_size
	var total_width = num_steps * cell_size
	var offset_y = -total_height / 2.0

	# Create a spawner for each track on the left side
	for track in range(num_tracks):
		var spawner = Node3D.new()
		spawner.name = "Spawner_%d" % track
		spawner.position = Vector3(
			-total_width / 2.0 - cell_size * 1.5,
			offset_y + (track + 0.5) * cell_size,
			0
		)
		_spawner_container.add_child(spawner)
		_cube_spawners.append(spawner)

		# Spawn initial cube
		_spawn_cube_at(track)


func _create_play_stop_cube() -> void:
	if not _cube_scene:
		return

	var total_width = num_steps * cell_size
	var total_height = num_tracks * cell_size

	# Create play/stop control cube
	_play_stop_cube = _cube_scene.instantiate()
	_play_stop_cube.name = "PlayStopCube"

	# Position below the grid
	_play_stop_cube.position = Vector3(
		0,
		-total_height / 2.0 - cell_size * 1.2,
		0
	)

	# Set metadata
	_play_stop_cube.set_meta("is_play_stop", true)
	_play_stop_cube.set_meta("sequencer", self)

	# Green color for play/stop
	var mesh = _play_stop_cube.get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.9, 0.4)  # Green
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.9, 0.4)
		mat.emission_energy_multiplier = 0.5
		mat.roughness = 0.6
		mesh.material_override = mat

	add_child(_play_stop_cube)

	# Freeze initially
	if _play_stop_cube is RigidBody3D:
		_play_stop_cube.freeze = true

	# Connect drop signal
	if _play_stop_cube.has_signal("dropped"):
		_play_stop_cube.dropped.connect(_on_play_stop_dropped)
	if _play_stop_cube.has_signal("picked_up"):
		_play_stop_cube.picked_up.connect(_on_play_stop_picked)


func _on_play_stop_dropped(_pickable) -> void:
	# Toggle playback when dropped
	toggle_playback()
	# Update color based on state
	_update_play_stop_color()
	# Return to original position
	if _play_stop_cube:
		var total_height = num_tracks * cell_size
		_play_stop_cube.global_position = global_position + Vector3(
			0,
			-total_height / 2.0 - cell_size * 1.2,
			0
		)
		if _play_stop_cube is RigidBody3D:
			_play_stop_cube.freeze = true


func _on_play_stop_picked(_pickable) -> void:
	# Unfreeze when picked up
	if _play_stop_cube is RigidBody3D:
		_play_stop_cube.freeze = false


func _update_play_stop_color() -> void:
	if not _play_stop_cube:
		return
	var mesh = _play_stop_cube.get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = StandardMaterial3D.new()
		if _is_playing:
			mat.albedo_color = Color(0.9, 0.3, 0.3)  # Red when playing
			mat.emission = Color(0.9, 0.3, 0.3)
		else:
			mat.albedo_color = Color(0.3, 0.9, 0.4)  # Green when stopped
			mat.emission = Color(0.3, 0.9, 0.4)
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.8
		mat.roughness = 0.6
		mesh.material_override = mat


func _spawn_cube_at(track: int) -> void:
	if not _cube_scene or track >= _cube_spawners.size():
		return

	var spawner = _cube_spawners[track]

	# Check if spawner already has a cube
	for child in spawner.get_children():
		if child.get_meta("track_index", -1) >= 0:
			return  # Already has cube

	var cube = _cube_scene.instantiate()
	cube.name = "Cube_%d" % track

	# Set metadata for sequencer (don't call setup() as it expects PatternTilePuzzle type)
	cube.set_meta("track_index", track)
	cube.set_meta("sequencer", self)

	# Set color
	var mesh = cube.get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = TRACK_COLORS[track % TRACK_COLORS.size()]
		mat.roughness = 0.8
		mesh.material_override = mat

	spawner.add_child(cube)

	# Freeze the cube so it doesn't fall (it's a RigidBody3D)
	if cube is RigidBody3D:
		cube.freeze = true

	# Connect drop signal if available
	if cube.has_signal("dropped"):
		cube.dropped.connect(_on_cube_dropped.bind(cube, track))


func _on_cube_dropped(cube: Node3D, track: int) -> void:
	# Find nearest cell
	var cell_info = _find_nearest_cell(cube.global_position)
	if cell_info.valid and cell_info.track == track:
		# Snap to cell
		_snap_cube_to_cell(cube, cell_info.track, cell_info.step)
		# Toggle cell
		toggle_cell(cell_info.track, cell_info.step)
		# Spawn new cube
		_spawn_cube_at(track)


func _find_nearest_cell(world_pos: Vector3) -> Dictionary:
	var local_pos = _grid_container.to_local(world_pos)

	var total_width = num_steps * cell_size
	var total_height = num_tracks * cell_size
	var offset_x = -total_width / 2.0
	var offset_y = -total_height / 2.0

	var step = int((local_pos.x - offset_x) / cell_size)
	var track = int((local_pos.y - offset_y) / cell_size)

	var valid = step >= 0 and step < num_steps and track >= 0 and track < num_tracks

	var cell_world_pos = Vector3.ZERO
	if valid:
		cell_world_pos = _grid_container.to_global(Vector3(
			offset_x + (step + 0.5) * cell_size,
			offset_y + (track + 0.5) * cell_size,
			cell_size * 0.2
		))

	return {
		"valid": valid,
		"track": track,
		"step": step,
		"world_pos": cell_world_pos
	}


func _snap_cube_to_cell(cube: Node3D, track: int, step: int) -> void:
	var total_width = num_steps * cell_size
	var total_height = num_tracks * cell_size
	var offset_x = -total_width / 2.0
	var offset_y = -total_height / 2.0

	cube.global_position = _grid_container.to_global(Vector3(
		offset_x + (step + 0.5) * cell_size,
		offset_y + (track + 0.5) * cell_size,
		cell_size * 0.3
	))

	# Freeze cube
	if cube is RigidBody3D:
		cube.freeze = true

	_placed_cubes[Vector2i(track, step)] = cube


func _create_labels() -> void:
	# Step label showing current position
	_step_label = Label3D.new()
	_step_label.name = "StepLabel"
	_step_label.font_size = 24
	_step_label.pixel_size = 0.001
	_step_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step_label.modulate = Color(1.0, 1.0, 0.8)

	var total_height = num_tracks * cell_size
	_step_label.position = Vector3(0, total_height / 2 + cell_size, 0)

	_grid_container.add_child(_step_label)
	_update_step_label()

	# Track labels (sound names)
	var total_width = num_steps * cell_size
	var offset_y = -total_height / 2.0

	for track in range(num_tracks):
		var label = Label3D.new()
		label.name = "TrackLabel_%d" % track
		label.font_size = 16
		label.pixel_size = 0.001
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.modulate = TRACK_COLORS[track % TRACK_COLORS.size()]
		label.position = Vector3(
			-total_width / 2 - cell_size * 0.3,
			offset_y + (track + 0.5) * cell_size,
			0
		)
		label.text = _get_sound_name(track)
		_grid_container.add_child(label)
		_track_labels.append(label)


func _get_sound_name(track: int) -> String:
	if track < _track_sounds.size():
		var sound_type = _track_sounds[track]
		# Convert enum to readable name
		var name = AudioSynthesizer.SoundType.keys()[sound_type]
		# Shorten for display
		name = name.replace("_", " ").to_lower()
		if name.length() > 12:
			name = name.substr(0, 10) + ".."
		return name
	return "Track %d" % track


func _update_step_label() -> void:
	if _step_label:
		_step_label.text = "Step %d / %d  |  BPM: %d  |  %s" % [
			_playhead_position + 1,
			num_steps,
			int(bpm),
			"PLAYING" if _is_playing else "STOPPED"
		]


func _update_step_interval() -> void:
	# Convert BPM to step interval
	# Assuming 4 steps per beat (16th notes)
	var beats_per_second = bpm / 60.0
	var steps_per_second = beats_per_second * 4.0
	_step_interval = 1.0 / steps_per_second


func _advance_playhead() -> void:
	# Trigger sounds for current step
	_trigger_step(_playhead_position)

	# Move playhead
	_playhead_position += 1
	if _playhead_position >= num_steps:
		if loop:
			_playhead_position = 0
		else:
			stop()
			return

	_update_playhead_position()
	_update_step_label()
	playhead_moved.emit(_playhead_position)


func _trigger_step(step: int) -> void:
	for track in range(num_tracks):
		if step < _grid_data[track].size() and _grid_data[track][step]:
			_play_sound(track)
			step_triggered.emit(track, step, _get_sound_name(track))

			# Visual feedback - flash cell
			if track < _cells.size() and step < _cells[track].size():
				_flash_cell(_cells[track][step], track)


func _play_sound(track: int) -> void:
	if track >= _audio_players.size() or track >= _track_sounds.size():
		return

	var player = _audio_players[track]
	var sound_type = _track_sounds[track]

	# Generate sound using AudioSynthesizer
	var params = {"duration": 0.2}
	var audio_stream = CustomSoundGenerator.generate_custom_sound(sound_type, params)

	if audio_stream:
		player.stream = audio_stream
		player.play()


func _flash_cell(cell: MeshInstance3D, track: int) -> void:
	# Brighten cell briefly
	var tween = create_tween()
	var mat = cell.material_override as StandardMaterial3D
	if mat:
		var original_emission = mat.emission_energy_multiplier
		mat.emission_energy_multiplier = 3.0
		tween.tween_property(mat, "emission_energy_multiplier", original_emission, 0.1)


## Public API

func play() -> void:
	_is_playing = true
	_step_timer = 0.0
	_update_step_label()
	_update_play_stop_color()
	playback_started.emit()


func stop() -> void:
	_is_playing = false
	_update_step_label()
	_update_play_stop_color()
	playback_stopped.emit()


func toggle_playback() -> void:
	if _is_playing:
		stop()
	else:
		play()


func set_cell(track: int, step: int, active: bool) -> void:
	if track < 0 or track >= num_tracks:
		return
	if step < 0 or step >= num_steps:
		return

	_grid_data[track][step] = active

	# Update visual
	if track < _cells.size() and step < _cells[track].size():
		_update_cell_material(_cells[track][step], track, active)

	pattern_changed.emit(track, step, active)


func toggle_cell(track: int, step: int) -> void:
	if track < 0 or track >= num_tracks:
		return
	if step < 0 or step >= num_steps:
		return

	var new_state = not _grid_data[track][step]
	set_cell(track, step, new_state)

	# Play sound preview when activating
	if new_state:
		_play_sound(track)


func get_cell(track: int, step: int) -> bool:
	if track < 0 or track >= num_tracks:
		return false
	if step < 0 or step >= num_steps:
		return false
	return _grid_data[track][step]


func clear_pattern() -> void:
	for track in range(num_tracks):
		for step in range(num_steps):
			set_cell(track, step, false)


func set_playhead(step: int) -> void:
	_playhead_position = clampi(step, 0, num_steps - 1)
	_update_playhead_position()
	_update_step_label()


func next_preset() -> void:
	var presets = SOUND_PRESETS.keys()
	var current_idx = presets.find(sound_preset)
	var next_idx = (current_idx + 1) % presets.size()
	sound_preset = presets[next_idx]
	_load_sound_preset(sound_preset)
	_update_track_labels()
	preset_changed.emit(sound_preset)


func prev_preset() -> void:
	var presets = SOUND_PRESETS.keys()
	var current_idx = presets.find(sound_preset)
	var prev_idx = (current_idx - 1 + presets.size()) % presets.size()
	sound_preset = presets[prev_idx]
	_load_sound_preset(sound_preset)
	_update_track_labels()
	preset_changed.emit(sound_preset)


func _update_track_labels() -> void:
	for track in range(_track_labels.size()):
		if track < _track_labels.size():
			_track_labels[track].text = _get_sound_name(track)


func _rebuild_grid() -> void:
	# Clear existing
	if _grid_container:
		_grid_container.queue_free()
	if _spawner_container:
		_spawner_container.queue_free()
	if _background_panel:
		_background_panel.queue_free()
	if _play_stop_cube:
		_play_stop_cube.queue_free()

	_cells.clear()
	_cube_spawners.clear()
	_track_labels.clear()
	_placed_cubes.clear()

	# Recreate
	_initialize_grid_data()
	_create_background_panel()
	_create_grid_visuals()
	_create_playhead()
	_create_cube_spawners()
	_create_play_stop_cube()
	_create_labels()


## Input handling

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventKey:
		var key = event as InputEventKey
		if key.pressed and not key.echo:
			match key.keycode:
				KEY_SPACE:
					toggle_playback()
				KEY_TAB:
					next_preset()
				KEY_LEFT:
					set_playhead(_playhead_position - 1)
				KEY_RIGHT:
					set_playhead(_playhead_position + 1)
				KEY_EQUAL, KEY_KP_ADD:
					bpm += 5
				KEY_MINUS, KEY_KP_SUBTRACT:
					bpm -= 5
				KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
					var step = key.keycode - KEY_1
					if step < num_steps:
						# Toggle cell on track 0 (or selected track)
						toggle_cell(0, step)
				KEY_HOME:
					set_playhead(0)
				KEY_C:
					clear_pattern()


## VR Controller handling

func handle_vr_button(button: String, controller_name: String) -> void:
	match button:
		"ax_button":
			toggle_playback()
		"by_button":
			if controller_name.contains("left"):
				prev_preset()
			else:
				next_preset()
		"primary_click":
			# Could be used for cell toggle at pointer position
			pass


## Config system (like PatternTilePuzzle)

func apply_grid_config(config_data: Dictionary) -> void:
	print("ArraySequencer: Applying config: %s" % config_data)

	var needs_rebuild := false

	if config_data.has("num_tracks"):
		var new_tracks = int(config_data["num_tracks"])
		if new_tracks != num_tracks:
			num_tracks = new_tracks
			needs_rebuild = true

	if config_data.has("num_steps"):
		var new_steps = int(config_data["num_steps"])
		if new_steps != num_steps:
			num_steps = new_steps
			needs_rebuild = true

	if config_data.has("bpm"):
		bpm = float(config_data["bpm"])

	if config_data.has("swing"):
		swing = float(config_data["swing"])

	if config_data.has("sound_preset"):
		sound_preset = str(config_data["sound_preset"])
		_load_sound_preset(sound_preset)

	if config_data.has("auto_play"):
		auto_play = _to_bool(config_data["auto_play"])

	if config_data.has("loop"):
		loop = _to_bool(config_data["loop"])

	# Shorthand parsing - try all keys as potential shorthands
	# This handles both proper syntax (key: true) and flexible syntax (key: any_value)
	for key in config_data.keys():
		var parsed = _parse_shorthand(key)
		# Only apply if shorthand was recognized (parsed dict not empty)
		if not parsed.is_empty():
			if parsed.has("num_tracks") and parsed["num_tracks"] != num_tracks:
				num_tracks = parsed["num_tracks"]
				needs_rebuild = true
			if parsed.has("num_steps") and parsed["num_steps"] != num_steps:
				num_steps = parsed["num_steps"]
				needs_rebuild = true
			if parsed.has("bpm"):
				bpm = parsed["bpm"]
			if parsed.has("sound_preset"):
				sound_preset = parsed["sound_preset"]
				_load_sound_preset(sound_preset)

	if needs_rebuild:
		_rebuild_grid()


func _parse_shorthand(key: String) -> Dictionary:
	var result := {}
	var k = key.to_lower().strip_edges()

	# Grid size shorthands: 4x8, 4x16, 8x16
	var size_match = RegEx.new()
	size_match.compile("^(\\d+)x(\\d+)$")
	var m = size_match.search(k)
	if m:
		result["num_tracks"] = int(m.get_string(1))
		result["num_steps"] = int(m.get_string(2))

	# BPM shorthand: 120bpm, 90bpm
	var bpm_match = RegEx.new()
	bpm_match.compile("^(\\d+)bpm$")
	var bpm_m = bpm_match.search(k)
	if bpm_m:
		result["bpm"] = float(bpm_m.get_string(1))

	# Sound preset shorthands
	if k in SOUND_PRESETS:
		result["sound_preset"] = k

	# Aliases
	if k == "trap":
		result["sound_preset"] = "trap_beats"
	elif k == "808":
		result["sound_preset"] = "808_kit"
	elif k == "synth":
		result["sound_preset"] = "synth_kit"
	elif k == "noir":
		result["sound_preset"] = "tech_noir"

	return result


func _to_bool(value) -> bool:
	if value is bool:
		return value
	var s = str(value).to_lower().strip_edges()
	return s == "true" or s == "1" or s == "yes" or s == "on"
