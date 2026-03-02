# harmonic_distance_table.gd
# Harmonic Distance Table — Cognitive Compression Artifact
#
# 12 chromatic pitch nodes arranged in circle-of-fifths order on a tabletop.
# Grab any two nodes to hear the interval between them.
# Grab a single node to activate it as tonal center — all others recolor
# by harmonic function (tonic=green, dominant=blue, subdominant=yellow, etc.).
# Lines between nodes show overtone relationships (thicker = more shared overtones).
#
# COGNITIVE COMPRESSION TARGET:
#   "Harmonic distance" becomes a single felt chunk — you don't calculate
#   intervals, you see/feel how close or far notes are in tonal space.
#
# QFEP AUDIT:
#   This visualization normalizes 12-TET equal temperament as THE tuning system.
#   In reality, 12-TET is one of many tuning systems (just intonation,
#   meantone, Pythagorean, various non-Western tunings). The circle of fifths
#   is specific to Western tonal theory. The overtone connections shown here
#   use ideal harmonic ratios, which 12-TET approximates but doesn't match
#   exactly (e.g., a 12-TET fifth is 700 cents vs. a pure 3:2 at ~702 cents).
#
extends Node3D
class_name HarmonicDistanceTable

const _P = preload("res://commons/ui/ada_palette.gd")

# ── Circle of fifths order (clockwise from C) ──
# This ordering places harmonically "close" keys adjacent
const CIRCLE_OF_FIFTHS: Array[String] = [
	"C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#", "F"
]

# Chromatic note names for frequency lookup
const CHROMATIC_NOTES: Array[String] = [
	"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
]

# Harmonic function colors (relative to active tonal center)
# Interval in semitones → color mapping
const FUNCTION_COLORS := {
	0:  Color(0.25, 0.78, 0.35),   # Tonic (I) — green
	7:  Color(0.20, 0.55, 0.95),   # Dominant (V) — blue
	5:  Color(0.95, 0.75, 0.10),   # Subdominant (IV) — yellow
	2:  Color(0.20, 0.70, 0.85),   # Supertonic (ii) — cyan
	4:  Color(0.95, 0.45, 0.15),   # Major third (III) — orange
	9:  Color(0.85, 0.40, 0.80),   # Submediant (vi) — purple
	11: Color(0.90, 0.22, 0.22),   # Leading tone (vii) — red
	3:  Color(0.60, 0.40, 0.80),   # Minor third (iii/♭III) — violet
	8:  Color(0.70, 0.50, 0.35),   # ♭vi — brown
	10: Color(0.55, 0.55, 0.60),   # ♭VII — grey
	1:  Color(0.45, 0.30, 0.30),   # ♭II — dark red
	6:  Color(0.40, 0.40, 0.45),   # Tritone — dark grey
}

# Default (no tonal center) node color
const DEFAULT_NODE_COLOR := Color(0.85, 0.85, 0.88)

# Shared overtone counts between intervals (semitone distance → shared overtones in first 16)
# Pre-computed: how many of the first 16 harmonics are shared between two notes
const SHARED_OVERTONES := {
	0: 16,  # Unison — all shared
	1: 1, 2: 1, 3: 2, 4: 2, 5: 3,  # m2, M2, m3, M3, P4
	6: 1, 7: 5,  # tritone, P5
	8: 2, 9: 2, 10: 2, 11: 1,  # m6, M6, m7, M7
}

# Line base color (cyan from palette)
const LINE_COLOR_BASE := Color(0.0, 0.78, 0.85)

## Configuration
@export var circle_radius: float = 0.35   # Radius of the note circle
@export var node_radius: float = 0.025     # Radius of each note sphere
@export var base_octave: int = 4           # Octave for tone generation
@export var tone_duration: float = 1.5     # How long a played tone sustains
@export var volume_db: float = -6.0        # Master volume

## Internal state
var note_nodes: Array[Dictionary] = []  # {label, area, note_name, chromatic_idx, angle, base_pos}
var overtone_lines: Array[Dictionary] = []  # {mm_idx, from_idx, to_idx, shared}
var active_tonal_center: int = -1  # Index into CIRCLE_OF_FIFTHS, -1 = none
var selected_nodes: Array[int] = []  # Currently selected node indices (max 2)

# Audio
var _audio_players: Array[AudioStreamPlayer3D] = []
var _audio_phases: Array[float] = []
var _audio_targets: Array[float] = []  # Target amplitude (for fade)
var _audio_current: Array[float] = []  # Current amplitude
var _audio_freqs: Array[float] = []
var _sample_rate: float = 44100.0
const MAX_VOICES := 2

# Rendering
var _base_mesh: MeshInstance3D
var _nodes_container: Node3D
var _lines_container: Node3D
var _notes_mm: MultiMesh
var _notes_mmi: MultiMeshInstance3D
var _lines_mm: MultiMesh
var _lines_mmi: MultiMeshInstance3D

func _ready() -> void:
	_build_base()
	_build_note_nodes()
	_build_overtone_lines()
	_setup_audio()
	_update_visual_state()

# ═══════════════════════════════════════════
#  CONSTRUCTION
# ═══════════════════════════════════════════

func _build_base() -> void:
	# Circular base plate
	var base = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = circle_radius + 0.08
	cylinder.bottom_radius = circle_radius + 0.08
	cylinder.height = 0.008
	cylinder.radial_segments = 48
	base.mesh = cylinder
	base.material_override = _P.make_material(_P.PANEL_DARK, 0.6, 0.4)
	base.position = Vector3(0, -0.004, 0)
	add_child(base)
	_base_mesh = base

	# Title label
	var title = Label3D.new()
	title.text = "HARMONIC DISTANCE"
	title.font_size = 20
	title.pixel_size = 0.0006
	title.modulate = _P.TEXT_ON_DARK
	title.outline_size = 0
	title.position = Vector3(0, 0.005, circle_radius + 0.06)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)

	_nodes_container = Node3D.new()
	_nodes_container.name = "NoteNodes"
	add_child(_nodes_container)

	_lines_container = Node3D.new()
	_lines_container.name = "OvertoneLines"
	add_child(_lines_container)

func _build_note_nodes() -> void:
	# Shared sphere mesh for all 12 note nodes (one draw call via MultiMesh)
	var sphere := SphereMesh.new()
	sphere.radius = node_radius
	sphere.height = node_radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12

	_notes_mm = MultiMesh.new()
	_notes_mm.transform_format = MultiMesh.TRANSFORM_3D
	_notes_mm.use_colors = true
	_notes_mm.mesh = sphere
	_notes_mm.instance_count = 12

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.4

	_notes_mmi = MultiMeshInstance3D.new()
	_notes_mmi.multimesh = _notes_mm
	_notes_mmi.material_override = mat
	_nodes_container.add_child(_notes_mmi)

	for i in range(12):
		var note_name = CIRCLE_OF_FIFTHS[i]
		var chromatic_idx = CHROMATIC_NOTES.find(note_name)

		# Position: circle layout, starting at top (12 o'clock), going clockwise
		var angle = -PI / 2.0 + (float(i) / 12.0) * TAU
		var pos = Vector3(cos(angle) * circle_radius, 0.02, sin(angle) * circle_radius)

		_notes_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))
		_notes_mm.set_instance_color(i, DEFAULT_NODE_COLOR)

		# Collision for interaction (Area3D for detection — kept as individual nodes)
		var area = Area3D.new()
		area.position = pos
		area.collision_layer = 262144  # XR interaction layer
		area.collision_mask = 393216
		var col = CollisionShape3D.new()
		var col_shape = SphereShape3D.new()
		col_shape.radius = node_radius * 1.5  # Slightly larger for easier grabbing
		col.shape = col_shape
		area.add_child(col)
		_nodes_container.add_child(area)

		# Connect area signals for VR hand interaction
		area.body_entered.connect(_on_node_touched.bind(i))
		area.body_exited.connect(_on_node_released.bind(i))

		# Label3D for note name
		var label = Label3D.new()
		label.text = note_name
		label.font_size = 28
		label.pixel_size = 0.0005
		label.modulate = _P.TEXT_PRIMARY
		label.outline_size = 2
		label.outline_modulate = Color(1, 1, 1, 0.8)
		label.position = pos + Vector3(0, 0.04, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_nodes_container.add_child(label)

		note_nodes.append({
			"label": label,
			"area": area,
			"note_name": note_name,
			"chromatic_idx": chromatic_idx,
			"angle": angle,
			"base_pos": pos,
		})

func _build_overtone_lines() -> void:
	# First pass: collect all line data
	var line_data_list: Array[Dictionary] = []
	for i in range(12):
		for j in range(i + 1, 12):
			var idx_i = note_nodes[i].chromatic_idx
			var idx_j = note_nodes[j].chromatic_idx
			var interval = absi(idx_j - idx_i)
			if interval > 6:
				interval = 12 - interval  # Use shortest distance

			var shared = SHARED_OVERTONES.get(interval, 0)
			if shared < 2:
				continue  # Don't show very weak connections
			line_data_list.append({
				"from_idx": i,
				"to_idx": j,
				"shared": shared,
			})

	if line_data_list.is_empty():
		return

	# Unit cylinder — scaled per-instance for different thickness and length
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	cyl.radial_segments = 8

	_lines_mm = MultiMesh.new()
	_lines_mm.transform_format = MultiMesh.TRANSFORM_3D
	_lines_mm.use_colors = true
	_lines_mm.mesh = cyl
	_lines_mm.instance_count = line_data_list.size()

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = LINE_COLOR_BASE
	mat.emission_energy_multiplier = 1.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_lines_mmi = MultiMeshInstance3D.new()
	_lines_mmi.multimesh = _lines_mm
	_lines_mmi.material_override = mat
	_lines_container.add_child(_lines_mmi)

	for idx in range(line_data_list.size()):
		var data = line_data_list[idx]
		var pos_from: Vector3 = note_nodes[data.from_idx].base_pos
		var pos_to: Vector3 = note_nodes[data.to_idx].base_pos
		var shared: int = data.shared

		var thickness = remap(float(shared), 2.0, 16.0, 0.001, 0.006)
		var delta = pos_to - pos_from
		var length = delta.length()
		var midpoint = (pos_from + pos_to) / 2.0

		# Build transform: orient unit cylinder along from→to, scale for thickness/length
		var xf := Transform3D()
		if length > 0.001:
			var direction = delta.normalized()
			if abs(direction.dot(Vector3.UP)) < 0.99:
				var look_basis := Basis.looking_at(direction, Vector3.UP)
				look_basis = look_basis * Basis(Vector3.RIGHT, PI / 2.0)
				xf.basis = look_basis
		xf.basis = xf.basis.scaled(Vector3(thickness, length, thickness))
		xf.origin = midpoint
		_lines_mm.set_instance_transform(idx, xf)

		var intensity = remap(float(shared), 2.0, 16.0, 0.2, 1.0)
		_lines_mm.set_instance_color(idx, Color(LINE_COLOR_BASE.r, LINE_COLOR_BASE.g, LINE_COLOR_BASE.b, intensity))

		overtone_lines.append({
			"mm_idx": idx,
			"from_idx": data.from_idx,
			"to_idx": data.to_idx,
			"shared": shared,
		})

# ═══════════════════════════════════════════
#  AUDIO SETUP
# ═══════════════════════════════════════════

func _setup_audio() -> void:
	for i in range(MAX_VOICES):
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = _sample_rate
		stream.buffer_length = 0.1

		var player = AudioStreamPlayer3D.new()
		player.stream = stream
		player.volume_db = volume_db
		player.unit_size = 2.0
		add_child(player)
		player.play()

		_audio_players.append(player)
		_audio_phases.append(0.0)
		_audio_targets.append(0.0)
		_audio_current.append(0.0)
		_audio_freqs.append(440.0)

func _get_note_frequency(note_name: String, octave: int) -> float:
	# Use PopMusicTheory's formula: f = 440 * 2^((n - 69) / 12)
	var note_idx = CHROMATIC_NOTES.find(note_name)
	if note_idx == -1:
		return 440.0
	var semitone_from_c0 = note_idx + (octave + 1) * 12
	return 440.0 * pow(2.0, (semitone_from_c0 - 69.0) / 12.0)

# ═══════════════════════════════════════════
#  INTERACTION
# ═══════════════════════════════════════════

func _on_node_touched(_body: Node3D, node_idx: int) -> void:
	if selected_nodes.size() >= 2:
		# Deselect oldest
		selected_nodes.pop_front()

	if not selected_nodes.has(node_idx):
		selected_nodes.append(node_idx)

	_handle_selection_change()

func _on_node_released(_body: Node3D, node_idx: int) -> void:
	# Optional: could deselect on release, but keeping selection
	# until new node is touched feels more natural in VR
	pass

func _handle_selection_change() -> void:
	if selected_nodes.size() == 1:
		# Single node selected → activate as tonal center
		active_tonal_center = selected_nodes[0]
		_play_tone(0, _get_note_frequency(
			note_nodes[active_tonal_center].note_name, base_octave))
		_stop_tone(1)
	elif selected_nodes.size() == 2:
		# Two nodes → play interval
		active_tonal_center = selected_nodes[0]
		_play_tone(0, _get_note_frequency(
			note_nodes[selected_nodes[0]].note_name, base_octave))
		_play_tone(1, _get_note_frequency(
			note_nodes[selected_nodes[1]].note_name, base_octave))

	_update_visual_state()

func _play_tone(voice_idx: int, freq: float) -> void:
	_audio_freqs[voice_idx] = freq
	_audio_targets[voice_idx] = 1.0

func _stop_tone(voice_idx: int) -> void:
	_audio_targets[voice_idx] = 0.0

# ═══════════════════════════════════════════
#  INPUT (keyboard fallback for testing)
# ═══════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Number keys 1-9, 0, -, = map to the 12 nodes
		var key_map := {
			KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3,
			KEY_5: 4, KEY_6: 5, KEY_7: 6, KEY_8: 7,
			KEY_9: 8, KEY_0: 9, KEY_MINUS: 10, KEY_EQUAL: 11,
		}
		if key_map.has(event.keycode):
			var idx = key_map[event.keycode]
			_on_node_touched(null, idx)

# ═══════════════════════════════════════════
#  VISUAL STATE UPDATE
# ═══════════════════════════════════════════

func _update_visual_state() -> void:
	for i in range(12):
		var node_data = note_nodes[i]
		var is_selected = selected_nodes.has(i)
		var color: Color
		var s: float = 1.0

		if active_tonal_center >= 0:
			# Color by harmonic function relative to tonal center
			var center_chromatic = note_nodes[active_tonal_center].chromatic_idx
			var this_chromatic = node_data.chromatic_idx
			var interval = (this_chromatic - center_chromatic + 12) % 12
			color = FUNCTION_COLORS.get(interval, Color(0.5, 0.5, 0.5))
			# Scale up selected nodes
			s = 1.5 if is_selected else 1.0
		else:
			color = DEFAULT_NODE_COLOR

		_notes_mm.set_instance_color(i, color)
		var xf := Transform3D()
		xf.basis = Basis.IDENTITY.scaled(Vector3(s, s, s))
		xf.origin = node_data.base_pos
		_notes_mm.set_instance_transform(i, xf)

	# Update line visibility/brightness based on tonal center
	_update_line_brightness()

func _update_line_brightness() -> void:
	if not _lines_mm:
		return
	for line_data in overtone_lines:
		var idx: int = line_data.mm_idx
		if active_tonal_center >= 0:
			# Highlight lines connected to the tonal center
			var connected = (line_data.from_idx == active_tonal_center or
				line_data.to_idx == active_tonal_center)
			var alpha = 0.8 if connected else 0.15
			_lines_mm.set_instance_color(idx, Color(LINE_COLOR_BASE.r, LINE_COLOR_BASE.g, LINE_COLOR_BASE.b, alpha))
		else:
			# Default: all lines visible at moderate brightness
			var intensity = remap(float(line_data.shared), 2.0, 16.0, 0.2, 1.0)
			_lines_mm.set_instance_color(idx, Color(LINE_COLOR_BASE.r, LINE_COLOR_BASE.g, LINE_COLOR_BASE.b, intensity))

# ═══════════════════════════════════════════
#  PROCESS — Audio generation + animations
# ═══════════════════════════════════════════

func _process(delta: float) -> void:
	_generate_audio()
	_animate_nodes(delta)

func _animate_nodes(delta: float) -> void:
	# Gentle hover animation for selected nodes
	for i in range(12):
		var base_pos: Vector3 = note_nodes[i].base_pos
		var xf := _notes_mm.get_instance_transform(i)
		if selected_nodes.has(i):
			# Gentle bob up and down
			var bob = sin(Time.get_ticks_msec() * 0.003 + float(i)) * 0.005
			xf.origin = base_pos + Vector3(0, bob + 0.005, 0)
		else:
			xf.origin = base_pos
		_notes_mm.set_instance_transform(i, xf)

func _generate_audio() -> void:
	for v in range(MAX_VOICES):
		if not _audio_players[v] or not _audio_players[v].playing:
			continue

		var playback = _audio_players[v].get_stream_playback()
		if not playback:
			continue

		var frames_available = playback.get_frames_available()
		if frames_available < 256:
			continue

		var frames_to_fill = mini(frames_available, 512)

		# Smooth amplitude envelope
		var target = _audio_targets[v]
		var current = _audio_current[v]
		var freq = _audio_freqs[v]
		var phase = _audio_phases[v]

		for _f in range(frames_to_fill):
			# Envelope: smooth attack/release
			current = lerp(current, target, 0.001)

			# Generate sample: fundamental + slight 2nd harmonic for warmth
			var sample = sin(phase) * 0.8 + sin(phase * 2.0) * 0.15 + sin(phase * 3.0) * 0.05
			sample *= current * 0.4  # Scale down to avoid clipping
			sample = clampf(sample, -1.0, 1.0)

			phase += freq * TAU / _sample_rate
			if phase > TAU:
				phase -= TAU

			playback.push_frame(Vector2(sample, sample))

		_audio_current[v] = current
		_audio_phases[v] = phase

# ═══════════════════════════════════════════
#  PUBLIC API (for external control / testing)
# ═══════════════════════════════════════════

func set_tonal_center(note_name: String) -> void:
	"""Programmatically set the tonal center by note name."""
	for i in range(12):
		if note_nodes[i].note_name == note_name:
			selected_nodes = [i]
			active_tonal_center = i
			_play_tone(0, _get_note_frequency(note_name, base_octave))
			_stop_tone(1)
			_update_visual_state()
			return

func clear_selection() -> void:
	"""Remove all selections and tonal center."""
	selected_nodes.clear()
	active_tonal_center = -1
	_stop_tone(0)
	_stop_tone(1)
	_update_visual_state()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
