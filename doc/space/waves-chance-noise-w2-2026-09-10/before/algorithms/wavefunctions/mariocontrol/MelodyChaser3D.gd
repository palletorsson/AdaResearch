extends Node3D

## Melody Chaser 3D - Follow-the-Leader Musical Instrument
## A leader point jumps between notes positioned radially from center.
## You follow with your grabbable point - when YOU are near a note, it plays.
## The leader stays slightly ahead to show you where to go next.


# @identity
# essence: scale[i] -> position[i] = f(layout_type), proximity(hand, note) -> trigger
# desire: Chase notes through 3D space as a glowing point traverses a musical scale
# critical_parameter: beat_interval — sets the tempo that drives the melodic sequence
# triggers: proximity_threshold crossing between hand and note marker fires sound
# emerges: spatial music — melody becomes a path you physically follow through space
# needs: VR hand tracking for proximity [has], scale selection [has]
# relationships: depends on pentatonic/chromatic scale definitions; contrasts with chord_tension_spring (melody vs harmony); unlocks embodied music theory
# truth: A melody is a path through pitch-space traversed in time.

@onready var mapper = $ValueMapper3D
@onready var audio_player = $AudioStreamPlayer3D
@onready var label_note = $LabelNote

# Leader point (shows where to go next)
var leader_point: MeshInstance3D
var current_note_index: int = 0
var next_note_time: float = 0.0

# Note markers in space
var note_markers: Dictionary = {}  # note_id -> MeshInstance3D
var note_positions: Array[Vector3] = []
var note_data: Array[Dictionary] = []  # {semitone, octave, position}

# --- Configuration ---
@export_enum("major", "minor", "pentatonic", "chromatic", "arpeggio", "fifths_circle", "fifths_helix") var scale_type: String = "major"
@export var beat_interval: float = 0.6  # Seconds between notes
@export var proximity_threshold: float = 0.12  # How close to trigger sound
@export var base_octave: int = 4
@export var hardness: float = 0.3
@export var ring_time: float = 0.5
@export var leader_ahead_beats: float = 1.5  # How many beats ahead leader shows

# Layout
@export var layout_radius: float = 0.25  # Distance from center to notes
@export var helix_height: float = 0.4  # Total height for helix patterns

# State
var last_played_note: int = -1
var note_cooldowns: Dictionary = {}  # note_id -> time remaining

# Scale definitions (semitone offsets)
const SCALE_PATTERNS = {
	"major": [0, 2, 4, 5, 7, 9, 11, 12],  # C D E F G A B C
	"minor": [0, 2, 3, 5, 7, 8, 10, 12],  # Natural minor
	"pentatonic": [0, 2, 4, 7, 9, 12],  # C D E G A C
	"chromatic": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
	"arpeggio": [0, 4, 7, 12, 7, 4],  # C E G C G E (up and down)
	# Circle of Fifths: each step +7 semitones (mod 12)
	# C -> G -> D -> A -> E -> B -> F# -> C# -> G# -> D# -> A# -> F -> C
	"fifths_circle": [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5, 0],
	# Fifths Helix: same but continues upward through octaves
	"fifths_helix": [0, 7, 14, 21, 28, 35, 42, 49, 56, 63, 70, 77, 84]  # 7 octaves up after 12 fifths
}

const NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
const A4_FREQ = 440.0
const SAMPLE_RATE = 44100

func _ready() -> void:
	_setup_note_positions()
	_create_note_markers()
	_create_leader_point()

	if label_note:
		label_note.text = ""

	next_note_time = Time.get_ticks_msec() / 1000.0 + 1.0  # Start after 1 second

func apply_grid_config(data: Dictionary) -> void:
	if data.has("scale"):
		var s = str(data["scale"]).to_lower().strip_edges()
		# Accept various formats
		if SCALE_PATTERNS.has(s):
			scale_type = s
		else:
			push_warning("MelodyChaser3D: Unknown scale '%s', using major" % s)
			scale_type = "major"

	if data.has("tempo"):
		var tempo = float(data["tempo"])
		if tempo > 0:
			beat_interval = 60.0 / tempo  # Convert BPM to interval

	if data.has("octave"):
		base_octave = int(data["octave"])

	# Rebuild if config changed
	_setup_note_positions()
	_create_note_markers()

func _setup_note_positions() -> void:
	note_positions.clear()
	note_data.clear()

	# Normalize scale_type to handle old cached values
	var normalized_scale = scale_type.to_lower().replace(" ", "_")
	if not SCALE_PATTERNS.has(normalized_scale):
		normalized_scale = "major"

	var pattern = SCALE_PATTERNS[normalized_scale]
	var space = mapper.space_size
	var center = space * 0.5

	var num_notes = pattern.size()

	# Choose layout based on scale type
	if normalized_scale == "fifths_circle":
		_setup_circle_of_fifths(pattern, space, center, num_notes)
	elif normalized_scale == "fifths_helix":
		_setup_fifths_helix(pattern, space, center, num_notes)
	else:
		_setup_radial_layout(pattern, space, center, num_notes)

func _setup_radial_layout(pattern: Array, space: Vector3, center: Vector3, num_notes: int) -> void:
	# Position notes radially from center - like clock positions
	for i in range(num_notes):
		var semitone = pattern[i] % 12
		var octave_offset = pattern[i] / 12

		# Radial position - spread around center
		var angle = (float(i) / num_notes) * TAU - PI/2  # Start at top
		var radius = layout_radius

		# Vary radius slightly by octave
		if octave_offset > 0:
			radius *= 1.2

		var pos = Vector3(
			center.x + cos(angle) * radius,
			center.y + sin(angle) * radius * 0.6,  # Compress Y for easier reach
			center.z
		)

		note_positions.append(pos)
		note_data.append({
			"semitone": semitone,
			"octave": base_octave + octave_offset,
			"position": pos,
			"index": i
		})

func _setup_circle_of_fifths(pattern: Array, space: Vector3, center: Vector3, num_notes: int) -> void:
	# Classic circle of fifths - flat circle where position = fifth order
	# Each note is 30 degrees apart (360/12), but ordered by fifths
	for i in range(num_notes):
		var semitone = pattern[i] % 12
		var octave_offset = pattern[i] / 12

		# Position by index in the fifths sequence (not by semitone)
		var angle = (float(i) / 12.0) * TAU - PI/2  # Start at top (C)
		var radius = layout_radius

		var pos = Vector3(
			center.x + cos(angle) * radius,
			center.y,  # Flat circle
			center.z + sin(angle) * radius
		)

		note_positions.append(pos)
		note_data.append({
			"semitone": semitone,
			"octave": base_octave + octave_offset,
			"position": pos,
			"index": i,
			"fifth_index": i  # Track position in circle
		})

func _setup_fifths_helix(pattern: Array, space: Vector3, center: Vector3, num_notes: int) -> void:
	# 3D Helix of Fifths - spiral upward through octaves
	# After 12 fifths, you're 7 octaves higher (Pythagorean spiral)
	# This visualizes the "comma" - the spiral doesn't close!
	for i in range(num_notes):
		var semitone = pattern[i] % 12
		var octave_offset = pattern[i] / 12

		# Angle: each fifth is 30 degrees around
		var angle = (float(i) / 12.0) * TAU - PI/2

		# Height: rises with each fifth (represents octave accumulation)
		var height_progress = float(i) / (num_notes - 1)
		var y_pos = height_progress * helix_height

		# Radius: could spiral inward/outward, keeping constant for clarity
		var radius = layout_radius

		var pos = Vector3(
			center.x + cos(angle) * radius,
			y_pos,  # Rising helix
			center.z + sin(angle) * radius
		)

		note_positions.append(pos)
		note_data.append({
			"semitone": semitone,
			"octave": base_octave + octave_offset,
			"position": pos,
			"index": i,
			"fifth_index": i
		})

func _process(delta: float) -> void:
	# Update cooldowns
	var to_remove = []
	for note_id in note_cooldowns:
		note_cooldowns[note_id] -= delta
		if note_cooldowns[note_id] <= 0:
			to_remove.append(note_id)
	for note_id in to_remove:
		note_cooldowns.erase(note_id)

	# Advance leader to next note on beat
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time >= next_note_time:
		_advance_leader()
		next_note_time += beat_interval

	# Check user's grab point against ALL note positions
	var grab_sphere = mapper.get_node_or_null("SpacePoint")
	if grab_sphere:
		var user_pos = grab_sphere.position
		_check_note_proximity(user_pos)

func _advance_leader() -> void:
	# Move leader to the note that's ahead of current
	var target_index = (current_note_index + int(leader_ahead_beats)) % note_data.size()

	if leader_point and target_index < note_positions.size():
		var target_pos = note_positions[target_index]

		# Quick tween to next position
		var tween = create_tween()
		tween.tween_property(leader_point, "position", target_pos, beat_interval * 0.3)

	# Advance the "current" note (what user should be playing now)
	current_note_index = (current_note_index + 1) % note_data.size()

	# Highlight the current target note
	_highlight_target_note(current_note_index)

func _check_note_proximity(user_pos: Vector3) -> void:
	for i in range(note_data.size()):
		var note = note_data[i]
		var distance = user_pos.distance_to(note.position)

		if distance < proximity_threshold:
			var note_id = i
			if not note_cooldowns.has(note_id):
				_trigger_note(note.semitone, note.octave, i)
				note_cooldowns[note_id] = 0.2  # Short cooldown per note
				break  # Only one note at a time

func _trigger_note(semitone: int, octave: int, note_index: int) -> void:
	var freq = _semitone_to_freq(semitone, octave)

	# Update label
	if label_note:
		label_note.text = NOTE_NAMES[semitone % 12] + str(octave)

	# Generate and play sound
	var stream = _generate_sine_bell(freq)
	audio_player.stream = stream
	audio_player.play()

	# Visual feedback on the note marker
	_flash_note_marker(note_index)

	last_played_note = note_index

func _semitone_to_freq(semitone: int, octave: int) -> float:
	var semitones_from_a4 = (octave - 4) * 12 + (semitone - 9)
	return A4_FREQ * pow(2.0, semitones_from_a4 / 12.0)

func _generate_sine_bell(freq: float) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * ring_time)
	var data = PackedByteArray()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		var env = exp(-progress * (5.0 / ring_time))

		# Sine bell with harmonics
		var sample_value = sin(2.0 * PI * freq * t) * env * 0.5
		if hardness > 0.1:
			sample_value += sin(4.0 * PI * freq * t) * env * hardness * 0.2
		if hardness > 0.3:
			sample_value += sin(6.0 * PI * freq * t) * env * hardness * 0.1

		var sample_int = int(clamp(sample_value, -1.0, 1.0) * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream

# --- Visuals ---

func _create_leader_point() -> void:
	leader_point = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	leader_point.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.1)  # Orange-red
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.1) * 2.0
	mat.emission_energy_multiplier = 3.0
	leader_point.material_override = mat
	leader_point.name = "LeaderPoint"

	# Start at first "ahead" position
	if note_positions.size() > 0:
		var start_index = int(leader_ahead_beats) % note_positions.size()
		leader_point.position = note_positions[start_index]

	mapper.add_child(leader_point)

func _create_note_markers() -> void:
	# Clear existing
	for key in note_markers:
		if is_instance_valid(note_markers[key]):
			note_markers[key].queue_free()
	note_markers.clear()

	# Remove old labels and connections
	for child in mapper.get_children():
		if child.name.begins_with("NoteLabel_") or child.name.begins_with("NoteMarker_") or child.name.begins_with("FifthLine_"):
			child.queue_free()

	# Create connection lines for circle of fifths patterns
	var normalized_scale = scale_type.to_lower().replace(" ", "_")
	if normalized_scale == "fifths_circle" or normalized_scale == "fifths_helix":
		_create_fifth_connections()

	# Create new markers
	for i in range(note_data.size()):
		var note = note_data[i]
		var pos = note.position

		# Create sphere marker
		var marker = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = 0.08
		marker.mesh = sphere

		var mat = StandardMaterial3D.new()
		# Color by pitch - rainbow based on semitone
		var hue = float(note.semitone) / 12.0
		mat.albedo_color = Color.from_hsv(hue, 0.7, 0.9)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color * 0.3
		marker.material_override = mat
		marker.position = pos
		marker.name = "NoteMarker_" + str(i)

		mapper.add_child(marker)
		note_markers[i] = marker

		# Label with note name
		var lbl = Label3D.new()
		lbl.text = NOTE_NAMES[note.semitone]
		lbl.font_size = 20
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = pos + Vector3(0, -0.07, 0)
		lbl.scale = Vector3.ONE * 0.05
		lbl.modulate = Color.WHITE
		lbl.name = "NoteLabel_" + str(i)
		mapper.add_child(lbl)

func _create_fifth_connections() -> void:
	# Draw lines connecting consecutive notes to show the path
	for i in range(note_data.size() - 1):
		var start_pos = note_positions[i]
		var end_pos = note_positions[i + 1]

		var line = _create_line_between(start_pos, end_pos, i)
		line.name = "FifthLine_" + str(i)
		mapper.add_child(line)

func _create_line_between(start: Vector3, end: Vector3, index: int) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()

	var distance = start.distance_to(end)
	cylinder.height = distance
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.003
	cylinder.radial_segments = 6
	line.mesh = cylinder

	var mat = StandardMaterial3D.new()
	# Color gradient along the path
	var hue = float(index) / 12.0
	mat.albedo_color = Color.from_hsv(hue, 0.4, 0.6, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color.from_hsv(hue, 0.4, 0.4)
	line.material_override = mat

	# Position at midpoint and rotate to connect the two points
	var midpoint = (start + end) / 2.0
	line.position = midpoint

	# Calculate rotation to point from start to end
	var direction = (end - start).normalized()
	if direction.length() > 0.001:
		# Cylinder's default orientation is along Y axis
		var up = Vector3.UP
		if abs(direction.dot(up)) > 0.99:
			up = Vector3.RIGHT
		# Use Basis.looking_at() instead of look_at() - works before node is in tree
		line.basis = Basis.looking_at(direction, up)
		line.rotate_object_local(Vector3.RIGHT, PI/2)

	return line

func _highlight_target_note(index: int) -> void:
	# Dim all notes, brighten target
	for i in note_markers:
		var marker = note_markers[i]
		if not is_instance_valid(marker):
			continue
		var mat = marker.material_override as StandardMaterial3D
		if not mat:
			continue

		if i == index:
			# This is the note to play NOW
			mat.emission_energy_multiplier = 2.0
			marker.scale = Vector3.ONE * 1.3
		else:
			mat.emission_energy_multiplier = 0.5
			marker.scale = Vector3.ONE

func _flash_note_marker(index: int) -> void:
	if not note_markers.has(index):
		return

	var marker = note_markers[index]
	if not is_instance_valid(marker):
		return

	var mat = marker.material_override as StandardMaterial3D
	if not mat:
		return

	# Bright flash
	var tween = create_tween()
	tween.tween_property(mat, "emission_energy_multiplier", 5.0, 0.05)
	tween.tween_property(mat, "emission_energy_multiplier", 0.5, 0.3)

	# Scale pulse
	var tween2 = create_tween()
	tween2.tween_property(marker, "scale", Vector3.ONE * 1.8, 0.05)
	tween2.tween_property(marker, "scale", Vector3.ONE, 0.3)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

