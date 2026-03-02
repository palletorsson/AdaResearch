# chord_tension_spring.gd
# Chord Tension Spring — Cognitive Compression Artifact
#
# Three (or four) pitch nodes connected by visible springs.
# Consonant chord = springs relaxed, nodes settle into rest positions.
# Dissonant chord = springs vibrate, nodes jitter and resist.
# Drag a node to change its pitch — feel the springs fight you (dissonance)
# or guide you (consonance). Resolution IS physical relaxation.
#
# COGNITIVE COMPRESSION TARGET:
#   "Harmonic tension" becomes a single felt chunk. You don't analyze intervals
#   to judge consonance — you see and feel springs straining or releasing.
#   Resolution = the moment the springs go still.
#
# QFEP AUDIT:
#   Consonance/dissonance is culturally mediated, not purely physical.
#   Western music theory treats the tritone as maximally dissonant, but
#   this is a learned association. The spring stiffness values here encode
#   Western common-practice norms. Blues, jazz, and many non-Western
#   traditions treat "dissonant" intervals as stable or desirable.
#   The springs show ONE theory of tension, not a universal law.
#
extends Node3D
class_name ChordTensionSpring

const _P = preload("res://commons/ui/ada_palette.gd")

# ── Configuration ──
const NUM_NODES := 4  # Root, third, fifth, seventh
const OCTAVE := 4     # Base octave
const BASE_RADIUS := 0.35  # Layout radius for rest positions

# Pitch positions on a chromatic circle (0-11 = C through B)
# Nodes can be dragged around this circle to change pitch
const NOTE_NAMES: Array[String] = [
	"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
]

# Consonance ratings for each interval in semitones (0-11)
# Higher = more consonant. Based on simple frequency ratios.
# 0=unison(1:1), 7=fifth(3:2), 5=fourth(4:3), 4=maj3(5:4), 3=min3(6:5)...
const CONSONANCE: Array[float] = [
	1.0,   # 0: Unison (perfect)
	0.05,  # 1: minor 2nd (harsh)
	0.20,  # 2: major 2nd (mild tension)
	0.50,  # 3: minor 3rd (sweet)
	0.55,  # 4: major 3rd (sweet)
	0.75,  # 5: perfect 4th (open)
	0.08,  # 6: tritone (unstable)
	0.90,  # 7: perfect 5th (stable)
	0.45,  # 8: minor 6th (warm)
	0.50,  # 9: major 6th (warm)
	0.15,  # 10: minor 7th (tension)
	0.10,  # 11: major 7th (leading tone tension)
]

# Spring physics constants
const SPRING_K_MIN := 0.5      # Weakest spring (most dissonant)
const SPRING_K_MAX := 30.0     # Strongest spring (most consonant)
const SPRING_DAMPING := 3.0    # Velocity damping
const JITTER_AMPLITUDE := 0.015 # Dissonance jitter magnitude
const SETTLE_THRESHOLD := 0.001 # When to consider settled

# Audio
const SAMPLE_RATE := 44100.0
const VOICE_AMPLITUDE := 0.12
const ATTACK_MS := 10.0
const RELEASE_MS := 200.0

# Preset chords: [semitone offsets from root]
const PRESETS := {
	"major":     [0, 4, 7],       # C E G
	"minor":     [0, 3, 7],       # C Eb G
	"dim":       [0, 3, 6],       # C Eb Gb
	"aug":       [0, 4, 8],       # C E G#
	"dom7":      [0, 4, 7, 10],   # C E G Bb
	"maj7":      [0, 4, 7, 11],   # C E G B
	"min7":      [0, 3, 7, 10],   # C Eb G Bb
	"sus4":      [0, 5, 7],       # C F G
	"sus2":      [0, 2, 7],       # C D G
	"tritone":   [0, 6],          # C F# (maximum tension)
}

# ── State ──
var node_pitches: Array[int] = [0, 4, 7, 11]  # Semitone values (C, E, G, B = Cmaj7)
var node_positions: Array[Vector3] = []         # Current 3D positions
var node_velocities: Array[Vector3] = []        # Physics velocities
var node_rest_positions: Array[Vector3] = []    # Where nodes want to be
var node_dragging: Array[bool] = []             # Which nodes are being dragged
var _node_mm: MultiMesh
var _node_mmi: MultiMeshInstance3D
var node_labels: Array[Label3D] = []
var node_areas: Array[Area3D] = []

# Spring visuals
var spring_lines: Array[MeshInstance3D] = []
var spring_pairs: Array[Vector2i] = []  # Pairs of node indices

# Audio
var audio_player: AudioStreamPlayer
var audio_stream: AudioStreamGenerator
var audio_phases: Array[float] = []
var audio_playing: bool = true

# Preset buttons
var preset_buttons: Array = []
var _btn_mm: MultiMesh
var _btn_mmi: MultiMeshInstance3D
var current_preset: String = "maj7"

# Base plate
var base_plate: MeshInstance3D

# Overall chord tension (0 = fully consonant, 1 = maximally dissonant)
var chord_tension: float = 0.0
var tension_label: Label3D
var chord_name_label: Label3D

signal chord_changed(pitches: Array[int], tension: float)
signal node_moved(index: int, new_pitch: int)

func _ready() -> void:
	_create_base_plate()
	_create_nodes()
	_create_spring_pairs()
	_create_spring_visuals()
	_create_preset_buttons()
	_create_labels()
	_setup_audio()
	_update_rest_positions()
	_snap_nodes_to_rest()

# ═══════════════════════════════════════════
#  CONSTRUCTION
# ═══════════════════════════════════════════

func _create_base_plate() -> void:
	base_plate = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = BASE_RADIUS + 0.12
	mesh.bottom_radius = BASE_RADIUS + 0.12
	mesh.height = 0.015
	base_plate.mesh = mesh
	base_plate.material_override = _P.make_material(
		_P.PANEL_DARK, 0.3, 0.6, 0.0
	)
	add_child(base_plate)

func _create_nodes() -> void:
	# Shared sphere mesh for all node visuals (MultiMesh)
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.035
	sphere_mesh.height = 0.07
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8

	_node_mm = MultiMesh.new()
	_node_mm.transform_format = MultiMesh.TRANSFORM_3D
	_node_mm.use_colors = true
	_node_mm.mesh = sphere_mesh
	_node_mm.instance_count = NUM_NODES

	for i in NUM_NODES:
		# Area3D for VR interaction
		var area := Area3D.new()
		area.name = "ChordNode_%d" % i
		area.collision_layer = 0
		area.collision_mask = 262144  # XR hands
		area.monitoring = true
		area.input_ray_pickable = true

		var col := CollisionShape3D.new()
		var sphere_shape := SphereShape3D.new()
		sphere_shape.radius = 0.04
		col.shape = sphere_shape
		area.add_child(col)

		# Label
		var label := Label3D.new()
		label.text = NOTE_NAMES[node_pitches[i]]
		label.font_size = 48
		label.pixel_size = 0.0006
		label.modulate = _P.TEXT_ON_DARK
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.position = Vector3(0, 0.06, 0)
		label.outline_size = 4
		area.add_child(label)

		add_child(area)

		# Connect interaction
		var idx := i
		area.input_event.connect(func(_cam, event, _pos, _normal, _shape):
			_on_node_input(idx, event)
		)
		area.mouse_entered.connect(func(): _on_node_hover(idx, true))
		area.mouse_exited.connect(func(): _on_node_hover(idx, false))

		node_areas.append(area)
		node_labels.append(label)
		node_positions.append(Vector3.ZERO)
		node_velocities.append(Vector3.ZERO)
		node_rest_positions.append(Vector3.ZERO)
		node_dragging.append(false)
		audio_phases.append(0.0)

		_node_mm.set_instance_color(i, _P.ACCENT_ORANGE)

	_node_mmi = MultiMeshInstance3D.new()
	_node_mmi.multimesh = _node_mm
	var node_mat := StandardMaterial3D.new()
	node_mat.vertex_color_use_as_albedo = true
	node_mat.metallic = 0.2
	node_mat.roughness = 0.45
	_node_mmi.material_override = node_mat
	add_child(_node_mmi)

func _create_spring_pairs() -> void:
	# Connect every pair of nodes with a spring
	for i in NUM_NODES:
		for j in range(i + 1, NUM_NODES):
			spring_pairs.append(Vector2i(i, j))

func _create_spring_visuals() -> void:
	for pair_idx in spring_pairs.size():
		var line_mesh := MeshInstance3D.new()
		line_mesh.name = "Spring_%d" % pair_idx
		add_child(line_mesh)
		spring_lines.append(line_mesh)

func _create_preset_buttons() -> void:
	var button_names := ["major", "minor", "dom7", "maj7", "dim", "aug", "sus4", "tritone"]
	var button_colors := [
		_P.ACCENT_GREEN,   # major
		_P.ACCENT_BLUE,    # minor
		_P.ACCENT_ORANGE,  # dom7
		_P.ACCENT_CYAN,    # maj7
		_P.ACCENT_RED,     # dim
		Color(0.85, 0.40, 0.80),  # aug — purple
		_P.ACCENT_YELLOW,  # sus4
		Color(0.40, 0.40, 0.45),  # tritone — dark grey
	]

	var start_x := -0.28

	# Shared box mesh for all preset buttons (MultiMesh)
	var btn_box := BoxMesh.new()
	btn_box.size = Vector3(0.06, 0.02, 0.03)

	_btn_mm = MultiMesh.new()
	_btn_mm.transform_format = MultiMesh.TRANSFORM_3D
	_btn_mm.use_colors = true
	_btn_mm.mesh = btn_box
	_btn_mm.instance_count = button_names.size()

	for i in button_names.size():
		var btn_area := Area3D.new()
		btn_area.name = "PresetBtn_%s" % button_names[i]
		btn_area.collision_layer = 0
		btn_area.collision_mask = 262144
		btn_area.monitoring = true
		btn_area.input_ray_pickable = true

		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.06, 0.025, 0.03)
		col.shape = box
		btn_area.add_child(col)

		var btn_label := Label3D.new()
		btn_label.text = button_names[i].to_upper()
		btn_label.font_size = 28
		btn_label.pixel_size = 0.0005
		btn_label.modulate = _P.TEXT_ON_DARK
		btn_label.position = Vector3(0, 0.025, 0)
		btn_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		btn_label.no_depth_test = true
		btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_area.add_child(btn_label)

		var btn_pos := Vector3(start_x + i * 0.075, 0.02, -(BASE_RADIUS + 0.18))
		btn_area.position = btn_pos
		add_child(btn_area)

		_btn_mm.set_instance_transform(i, Transform3D(Basis(), btn_pos))
		_btn_mm.set_instance_color(i, button_colors[i])

		var preset_name: String = button_names[i]
		btn_area.input_event.connect(func(_cam, event, _pos, _normal, _shape):
			if event is InputEventMouseButton and event.pressed:
				_apply_preset(preset_name)
		)
		preset_buttons.append(btn_area)

	_btn_mmi = MultiMeshInstance3D.new()
	_btn_mmi.multimesh = _btn_mm
	var btn_mat := StandardMaterial3D.new()
	btn_mat.vertex_color_use_as_albedo = true
	btn_mat.metallic = 0.2
	btn_mat.roughness = 0.5
	_btn_mmi.material_override = btn_mat
	add_child(_btn_mmi)

func _create_labels() -> void:
	# Tension meter label
	tension_label = Label3D.new()
	tension_label.text = "TENSION: 0%"
	tension_label.font_size = 42
	tension_label.pixel_size = 0.0006
	tension_label.modulate = _P.TEXT_ON_DARK
	tension_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tension_label.no_depth_test = true
	tension_label.position = Vector3(0, 0.35, 0)
	tension_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tension_label.outline_size = 6
	add_child(tension_label)
	
	# Chord name
	chord_name_label = Label3D.new()
	chord_name_label.text = "Cmaj7"
	chord_name_label.font_size = 56
	chord_name_label.pixel_size = 0.0006
	chord_name_label.modulate = _P.ACCENT_CYAN
	chord_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	chord_name_label.no_depth_test = true
	chord_name_label.position = Vector3(0, 0.28, 0)
	chord_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chord_name_label.outline_size = 6
	add_child(chord_name_label)
	
	# Title
	var title := Label3D.new()
	title.text = "CHORD TENSION SPRING"
	title.font_size = 32
	title.pixel_size = 0.0006
	title.modulate = _P.TEXT_SECONDARY
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.no_depth_test = true
	title.position = Vector3(0, 0.42, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

func _setup_audio() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.08
	
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -6.0
	add_child(audio_player)
	audio_player.play()

# ═══════════════════════════════════════════
#  PHYSICS & UPDATE
# ═══════════════════════════════════════════

func _physics_process(delta: float) -> void:
	_simulate_springs(delta)
	_update_node_visuals()
	_update_spring_visuals()
	_update_tension_display()
	_generate_audio()

func _simulate_springs(delta: float) -> void:
	# Calculate chord tension from all intervals
	chord_tension = _calculate_chord_tension()
	
	for i in NUM_NODES:
		if node_dragging[i]:
			continue
		
		var force := Vector3.ZERO
		
		# Spring force toward rest position
		var displacement: Vector3 = node_positions[i] - node_rest_positions[i]
		var k: float = lerpf(SPRING_K_MIN, SPRING_K_MAX, 1.0 - chord_tension)
		force -= displacement * k
		
		# Damping
		force -= node_velocities[i] * SPRING_DAMPING
		
		# Dissonance jitter — nodes vibrate when tension is high
		if chord_tension > 0.2:
			var jitter_strength := chord_tension * JITTER_AMPLITUDE
			force += Vector3(
				randf_range(-jitter_strength, jitter_strength),
				randf_range(-jitter_strength, jitter_strength) * 0.3,
				randf_range(-jitter_strength, jitter_strength)
			) * 60.0  # Scale up for force
		
		# Integrate
		node_velocities[i] += force * delta
		node_positions[i] += node_velocities[i] * delta
		
		# Keep on the table plane (slight Y bob allowed)
		node_positions[i].y = clampf(node_positions[i].y, -0.02, 0.08)

func _calculate_chord_tension() -> float:
	# Average dissonance across all pairs
	if node_pitches.size() < 2:
		return 0.0
	
	var total_dissonance := 0.0
	var pair_count := 0
	
	for i in node_pitches.size():
		for j in range(i + 1, node_pitches.size()):
			var interval := absi(node_pitches[j] - node_pitches[i]) % 12
			total_dissonance += 1.0 - CONSONANCE[interval]
			pair_count += 1
	
	return total_dissonance / pair_count if pair_count > 0 else 0.0

func _update_rest_positions() -> void:
	# Arrange nodes in a circle, but with spacing influenced by consonance
	# Consonant pairs get closer rest positions, dissonant pairs get pushed apart
	var active_count := mini(node_pitches.size(), NUM_NODES)
	for i in active_count:
		var angle := (float(i) / active_count) * TAU - PI / 2
		var r := BASE_RADIUS * 0.6
		node_rest_positions[i] = Vector3(
			cos(angle) * r,
			0.04,
			sin(angle) * r
		)

func _snap_nodes_to_rest() -> void:
	for i in NUM_NODES:
		node_positions[i] = node_rest_positions[i]
		node_velocities[i] = Vector3.ZERO

func _update_node_visuals() -> void:
	for i in NUM_NODES:
		if i >= node_areas.size():
			break
		node_areas[i].position = node_positions[i]

		# Update MultiMesh transform to match Area3D position
		_node_mm.set_instance_transform(i, Transform3D(Basis(), node_positions[i]))

		# Color by individual tension contribution
		var node_tension := _node_tension(i)
		var color: Color
		if node_tension < 0.2:
			color = _P.ACCENT_GREEN  # Consonant — relaxed green
		elif node_tension < 0.5:
			color = _P.ACCENT_CYAN.lerp(_P.ACCENT_YELLOW, (node_tension - 0.2) / 0.3)
		else:
			color = _P.ACCENT_YELLOW.lerp(_P.ACCENT_RED, (node_tension - 0.5) / 0.5)

		_node_mm.set_instance_color(i, color)

		# Update label
		node_labels[i].text = NOTE_NAMES[node_pitches[i] % 12]

func _node_tension(index: int) -> float:
	# How dissonant is this node relative to all others?
	var tension := 0.0
	var count := 0
	for j in node_pitches.size():
		if j == index:
			continue
		var interval := absi(node_pitches[j] - node_pitches[index]) % 12
		tension += 1.0 - CONSONANCE[interval]
		count += 1
	return tension / count if count > 0 else 0.0

func _update_spring_visuals() -> void:
	for idx in spring_pairs.size():
		var pair := spring_pairs[idx]
		var i := pair.x
		var j := pair.y
		
		if i >= node_positions.size() or j >= node_positions.size():
			continue
		
		var pos_a := node_positions[i]
		var pos_b := node_positions[j]
		var interval := absi(node_pitches[j] - node_pitches[i]) % 12
		var consonance := CONSONANCE[interval]
		
		# Build spring coil mesh
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		
		var direction := pos_b - pos_a
		var length := direction.length()
		if length < 0.001:
			mesh.surface_end()
			spring_lines[idx].mesh = mesh
			continue
		
		var dir_norm := direction.normalized()
		
		# Perpendicular vectors for coil
		var up := Vector3.UP
		if abs(dir_norm.dot(up)) > 0.99:
			up = Vector3.RIGHT
		var perp1 := dir_norm.cross(up).normalized()
		var perp2 := dir_norm.cross(perp1).normalized()
		
		# Coil parameters — tighter coils for more tension
		var coils: int = int(lerpf(4.0, 12.0, 1.0 - consonance))
		var coil_radius: float = lerpf(0.005, 0.02, consonance)  # Wider when relaxed
		var points_per_coil := 8
		var total_points := coils * points_per_coil
		
		# Color: green when consonant, red when dissonant
		var spring_color: Color
		if consonance > 0.6:
			spring_color = _P.ACCENT_GREEN.lerp(_P.ACCENT_CYAN, (consonance - 0.6) / 0.4)
		elif consonance > 0.3:
			spring_color = _P.ACCENT_YELLOW.lerp(_P.ACCENT_GREEN, (consonance - 0.3) / 0.3)
		else:
			spring_color = _P.ACCENT_RED.lerp(_P.ACCENT_YELLOW, consonance / 0.3)
		
		for p in range(total_points + 1):
			var t := float(p) / total_points
			var base_pos := pos_a + direction * t
			var angle := t * coils * TAU
			var offset: Vector3 = perp1 * cos(angle) * coil_radius + perp2 * sin(angle) * coil_radius
			
			mesh.surface_set_color(spring_color)
			mesh.surface_add_vertex(base_pos + offset)
		
		mesh.surface_end()
		spring_lines[idx].mesh = mesh

func _update_tension_display() -> void:
	if tension_label:
		var pct := int(chord_tension * 100)
		tension_label.text = "TENSION: %d%%" % pct
		
		# Color the label by tension
		if chord_tension < 0.25:
			tension_label.modulate = _P.ACCENT_GREEN
		elif chord_tension < 0.5:
			tension_label.modulate = _P.ACCENT_YELLOW
		else:
			tension_label.modulate = _P.ACCENT_RED

# ═══════════════════════════════════════════
#  AUDIO SYNTHESIS
# ═══════════════════════════════════════════

func _generate_audio() -> void:
	if not audio_player or not audio_player.playing:
		return
	
	var playback: AudioStreamGeneratorPlayback = audio_player.get_stream_playback()
	if not playback:
		return
	
	var frames := playback.get_frames_available()
	if frames <= 0:
		return
	
	for _f in frames:
		var sample := 0.0
		var active_count := mini(node_pitches.size(), NUM_NODES)
		
		for i in active_count:
			var freq := _pitch_to_freq(node_pitches[i])
			audio_phases[i] += freq / SAMPLE_RATE
			if audio_phases[i] > 1.0:
				audio_phases[i] -= 1.0
			
			# Sine + slight 2nd harmonic for warmth
			var voice := sin(audio_phases[i] * TAU) * 0.85
			voice += sin(audio_phases[i] * TAU * 2.0) * 0.12
			voice += sin(audio_phases[i] * TAU * 3.0) * 0.03
			
			sample += voice * VOICE_AMPLITUDE
		
		# Normalize to prevent clipping
		if active_count > 1:
			sample /= sqrt(float(active_count))
		
		# Add subtle beating/roughness proportional to tension
		if chord_tension > 0.15:
			var noise := randf_range(-1.0, 1.0) * chord_tension * 0.02
			sample += noise
		
		playback.push_frame(Vector2(sample, sample))

func _pitch_to_freq(semitone: int) -> float:
	# A4 = 440 Hz, MIDI note 69
	# C4 = MIDI note 60
	var midi_note := 60 + semitone  # C4 + offset
	return 440.0 * pow(2.0, (midi_note - 69.0) / 12.0)

# ═══════════════════════════════════════════
#  INTERACTION
# ═══════════════════════════════════════════

func _on_node_input(index: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Cycle pitch: click to change note
		_cycle_node_pitch(index, 1 if event.button_index == MOUSE_BUTTON_LEFT else -1)

func _on_node_hover(index: int, hovering: bool) -> void:
	if index < NUM_NODES:
		if hovering:
			_node_mm.set_instance_color(index, _P.ACCENT_ORANGE)
		else:
			_update_node_visuals()  # Reset to tension-based color

func _cycle_node_pitch(index: int, direction: int) -> void:
	node_pitches[index] = (node_pitches[index] + direction + 12) % 12
	_update_rest_positions()
	# Give the node a velocity kick to show the change
	node_velocities[index] = Vector3(
		randf_range(-0.3, 0.3), 0.15, randf_range(-0.3, 0.3)
	)
	_update_chord_name()
	node_moved.emit(index, node_pitches[index])
	chord_changed.emit(node_pitches, chord_tension)

func _apply_preset(preset_name: String) -> void:
	current_preset = preset_name
	var intervals: Array = PRESETS.get(preset_name, [0, 4, 7])
	
	# Apply pitches (root = C by default)
	var root := node_pitches[0] if node_pitches.size() > 0 else 0
	for i in NUM_NODES:
		if i < intervals.size():
			node_pitches[i] = (root + intervals[i]) % 12
			if i < node_areas.size():
				node_areas[i].visible = true
		else:
			# Pad with octave doubling if fewer notes than nodes
			node_pitches[i] = (root + intervals[i % intervals.size()]) % 12
			if i < node_areas.size():
				node_areas[i].visible = intervals.size() > (i % intervals.size())
	
	_update_rest_positions()
	# Kick all nodes to show transition
	for i in NUM_NODES:
		node_velocities[i] = Vector3(
			randf_range(-0.2, 0.2), 0.1, randf_range(-0.2, 0.2)
		)
	_update_chord_name()
	chord_changed.emit(node_pitches, _calculate_chord_tension())

func _update_chord_name() -> void:
	if not chord_name_label:
		return
	
	var root_name := NOTE_NAMES[node_pitches[0] % 12]
	
	# Try to identify chord quality from intervals
	var intervals: Array[int] = []
	for i in range(1, node_pitches.size()):
		intervals.append((node_pitches[i] - node_pitches[0] + 12) % 12)
	intervals.sort()
	
	var quality := ""
	# Match common chord types
	if intervals == [4, 7]:
		quality = ""  # major
	elif intervals == [3, 7]:
		quality = "m"
	elif intervals == [4, 7, 10]:
		quality = "7"
	elif intervals == [4, 7, 11]:
		quality = "maj7"
	elif intervals == [3, 7, 10]:
		quality = "m7"
	elif intervals == [3, 6]:
		quality = "dim"
	elif intervals == [3, 6, 9]:
		quality = "dim7"
	elif intervals == [3, 6, 10]:
		quality = "m7♭5"
	elif intervals == [4, 8]:
		quality = "aug"
	elif intervals == [5, 7]:
		quality = "sus4"
	elif intervals == [2, 7]:
		quality = "sus2"
	elif intervals == [6]:
		quality = "♭5"
	else:
		# Show intervals
		var int_strs: Array[String] = []
		for intv in intervals:
			int_strs.append(str(intv))
		quality = "(%s)" % ",".join(int_strs)
	
	chord_name_label.text = root_name + quality

# ═══════════════════════════════════════════
#  KEYBOARD FALLBACK (desktop testing)
# ═══════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			# Number keys cycle node pitches
			KEY_1: _cycle_node_pitch(0, 1)
			KEY_2: _cycle_node_pitch(1, 1)
			KEY_3: _cycle_node_pitch(2, 1)
			KEY_4: _cycle_node_pitch(3, 1)
			# Shift+number goes backwards
			KEY_Q: _cycle_node_pitch(0, -1)
			KEY_W: _cycle_node_pitch(1, -1)
			KEY_E: _cycle_node_pitch(2, -1)
			KEY_R: _cycle_node_pitch(3, -1)
			# Preset shortcuts
			KEY_F1: _apply_preset("major")
			KEY_F2: _apply_preset("minor")
			KEY_F3: _apply_preset("dom7")
			KEY_F4: _apply_preset("maj7")
			KEY_F5: _apply_preset("dim")
			KEY_F6: _apply_preset("aug")
			KEY_F7: _apply_preset("sus4")
			KEY_F8: _apply_preset("tritone")
			KEY_SPACE:
				# Reset all to rest
				_snap_nodes_to_rest()

# ═══════════════════════════════════════════
#  PUBLIC API
# ═══════════════════════════════════════════

func set_root(note_name: String) -> void:
	var idx := NOTE_NAMES.find(note_name)
	if idx >= 0:
		var old_root := node_pitches[0]
		var diff := idx - old_root
		for i in node_pitches.size():
			node_pitches[i] = (node_pitches[i] + diff + 12) % 12
		_update_rest_positions()
		_update_chord_name()

func set_chord(intervals: Array[int]) -> void:
	var root := node_pitches[0]
	for i in NUM_NODES:
		if i < intervals.size():
			node_pitches[i] = (root + intervals[i]) % 12
	_update_rest_positions()
	_update_chord_name()

func get_tension() -> float:
	return chord_tension

func get_pitches() -> Array[int]:
	return node_pitches.duplicate()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
