extends Node3D

# @identity
# essence: length = |p2 - p1| — the distance between two points, made visible and tangible
# desire: learner feels a line as relationship, not object — it exists because two points exist
# critical_parameter: the glitch/haptic resistance when length is near an integer — whole numbers resist
# triggers: dragging either end grab sphere — length label updates live, glitch fires at integer thresholds
# emerges: the privilege of whole numbers; the line as a tension between two positions
# needs: [has Label3D [has], both endpoints are grabbable [has], missing color/thickness slider]
# relationships: depends on two static_points; unlocks all polygon primitives, perspective_lines, scale_lines
# truth: a line segment has no intrinsic existence — it is defined entirely by its two endpoints

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27) — THE KIN PAIR AXIS.
# Twin file: commons/primitives/point/xyz_slider_plate.gd, which owns the
# vocabulary. One word, two apparatuses.
#
# This artifact's critical_parameter is "the glitch/haptic resistance when
# length is near an integer — whole numbers resist", and its emergent claim is
# "the privilege of whole numbers". Read literally that is a RATE — a per-frame
# jitter, a pitch-shifting noise loop, a haptic pulse — and a rate is invisible
# to a still frame. info_board was swept across all five of its duration exports
# and produced six identical tiles; sweeping resistance_threshold here would
# produce the same nothing.
#
# So the rate is DEMOTED and the claim underneath it is built instead. Read the
# justification, not the mechanism: "whole numbers resist" is an argument about
# LEGIBILITY — which values this apparatus treats as clean — and today that
# argument is made only to a hand inside a headset, wearing controllers, at the
# exact moment it happens. A desktop player never learns it exists. A still
# never shows it. The privilege of whole numbers deserves to be something you
# can SEE, standing still, before you touch anything.
#
# The axis is therefore `readout` — what the apparatus tells you about the value
# you are setting — shared verbatim with the slider plate, one ordered ladder:
#
#   none  <  numeral (legacy default)  <  gradation  <  lattice
#
#   none       the rod and two handles. No length anywhere. You pull two points
#              apart and the world says nothing back; distance is a feeling.
#   numeral    the billboard prints "Length: 0.24m" over the midpoint and you
#              take its word for it. This is what all 40 placements render.
#   gradation  the number, plus a public scale to check it against: a graduated
#              rule laid under the segment, running from the FIRST endpoint out
#              past the second, minor teeth every 5 cm, majors every 25, a full
#              tooth and a numeral at every whole metre. The segment stops being
#              a self-reporting object and becomes a reading off a ruler that
#              carries on without it.
#   lattice    all of that, plus the privileged set drawn: a standing gate at
#              every whole metre on the rule and a hot collar painted over the
#              ±resistance_threshold zone around it — the exact interval where
#              this artifact will jitter, buzz and redden the label. The law
#              that was only ever felt is now a thing in the room.
#
# NOTHING BELOW CHANGES WHAT THE MACHINE COMPUTES. Distance is still
# start.distance_to(end); _process_resistance still fires on the same fmod, at
# the same threshold, with the same intensity curve; the label still prints the
# same "%.2fm". The curriculum is untouched — only what the apparatus shows of
# its own work. The resistance itself — jitter, pitch, haptics — is deliberately
# left running at every rung, including `none`: rung 0 says the apparatus tells
# you nothing, not that the law stops applying.
#
# THE ONE WEAK PAIR, DECLARED RATHER THAN DISCOVERED. `none` vs `numeral` is the
# quietest step on the ladder, because the thing it removes is a 16 mm-tall
# billboard on a 29 cm object, against two emissive cyan handles that own most
# of the bright pixels in any shot. Expect it to measure low. That is itself the
# finding: the number this artifact has been built around for years is barely
# legible, because create_length_label() sets font_size 32 at the default
# pixel_size and then scales the whole label to 0.1. Not fixed here — enlarging
# it would move all 40 live placements, which is not a DNA promotion's business.
# The axis's real evidence is in rungs 2 and 3, which change the silhouette.
#
# LATENT AND REPORTED, NOT FIXED — line.tscn's ROOT node ("Line", Node3D)
# carries no script; this script sits on the child "lineContainer". Every
# artifact config path in the project targets the instantiated ROOT:
# GridInteractablesComponent._apply_artifact_config sets `config_*` metadata on
# it and calls apply_grid_config on it, and commons/testing/capture_config_sweep
# .gd does `if key in inst: inst.set(key, val)` on it. None of that has ever
# reached this file, which is why not one of the 40 placements carries a token
# and why line_thickness/line_color are overridden in the .tscn rather than by
# map data. _readout_token() below walks UP to find the metadata, so the map
# path (`line#readout:lattice`) works from today. The @export property path
# still cannot be reached until the root carries this script — a one-line .tscn
# change that is out of this pass's scope.
# ─────────────────────────────────────────────────────────────────────────────

# Line connection system for grab spheres with queer CGI education
@export var line_thickness: float = 0.005
@export var line_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var update_frequency: float = 0.1  # Update every 0.1 seconds

## AXIS — what the apparatus commits to about the length you are setting. One
## ordered ladder, monotone in evidence, shared verbatim with the twin primitive
## commons/primitives/point/xyz_slider_plate.gd (which owns the vocabulary and
## the alias table). Rung 0 says nothing; rung 1 says a number; rung 2 puts that
## number on a public scale; rung 3 draws the values this artifact privileges.
##   none < numeral (legacy default) < gradation < lattice
## Anything unrecognised builds as `numeral`, NOT as `none`: a typo must not
## silently delete the readout from a live room.
@export_enum("none", "numeral", "gradation", "lattice") var readout: String = "numeral"

# Critical Interaction Parameters
@export_group("Critical Interaction")
@export var enable_resistance: bool = true
@export var resistance_threshold: float = 0.08  # Distance to integer to start glitching
@export var max_jitter: float = 0.02  # Max position jitter in meters
@export var haptic_intensity_max: float = 0.8  # Max haptic feedback
@export var glitch_sound_volume_db: float = -10.0

@onready var point_one = $GrabSphere
@onready var point_two = $GrabSphere2

var connection_lines: Array[MeshInstance3D] = []
var current_line: MeshInstance3D
var length_label: Label3D
var last_distance: float = 0.0

# Glitch Audio
var _glitch_player: AudioStreamPlayer3D
var _glitch_stream: AudioStreamWAV

# ── the graduated rule (readout rungs 2 and 3) ───────────────────────────────
#
# The rule is built ONCE, in its own local space running along +X from the first
# endpoint, and re-oriented each frame by setting one transform. Rebuilding
# twenty-odd teeth per frame to chase a dragged handle would be the wrong shape
# of work for the project's most basic primitive.

## How far the public scale runs, in metres, measured from the first endpoint.
## The default segment is 0.24 m, so the rule carries on well past the second
## handle and reaches exactly one whole-metre station — which is the whole
## rhetorical point: the scale does not belong to your segment.
const RULE_SPAN := 1.10
const RULE_MINOR := 0.05
const RULE_MAJOR := 0.25
const RULE_WHOLE := 1.0
const RULE_DROP := 0.055        # how far under the segment the blade lies
const BLADE_W := 0.030          # the rule's flat width
const BLADE_T := 0.006
const TOOTH_MINOR := 0.008
const TOOTH_MAJOR := 0.018
const TOOTH_WHOLE := 0.034
const TOOTH_W := 0.0045
const GATE_H := 0.13            # a whole-number station, standing up
const STEEL := Color(0.72, 0.75, 0.80)
const HOT := Color(1.00, 0.36, 0.20)

var _rule: Node3D               # null on the legacy path

func _ready():
	_read_readout()
	# rung 0 builds no label at all; every use of length_label downstream is
	# already null-guarded, and _process_resistance's colour flashes simply have
	# nothing to flash
	if readout != "none":
		create_length_label()
	update_connections()
	_build_readout()

	_setup_glitch_audio()
	
	# Connect to point drop events to send educational messages
	if point_one and point_one.has_signal("dropped"):
		point_one.dropped.connect(_on_point_dropped)
	if point_two and point_two.has_signal("dropped"):
		point_two.dropped.connect(_on_point_dropped)


# ── Readout ──────────────────────────────────────────────────────────────────
#
#   none  <  numeral  <  gradation  <  lattice
#
# Rungs 0 and 1 are decided by whether create_length_label() runs at all, up in
# _ready(). Rungs 2 and 3 add the rule and are built here. Nothing in this
# section executes on the legacy path — the match falls straight through for
# "numeral" and _rule stays null.

## The token read, and it has to walk UP. See the LATENT note at the top of the
## file: every config path in the project targets the instantiated scene ROOT,
## and line.tscn's root carries no script, so the metadata written for
## `line#readout:lattice` lands one node above this one. Two hops covers the
## lineContainer -> Line shape and stops well short of the grid's own nodes,
## which never carry a config_readout.
func _read_readout() -> void:
	var raw: String = readout
	var node: Node = self
	var hops: int = 0
	while node != null and hops < 3:
		if node.has_meta("config_readout"):
			raw = str(node.get_meta("config_readout"))
			break
		if node.has_meta("readout"):
			raw = str(node.get_meta("readout"))
			break
		node = node.get_parent()
		hops += 1
	# The pair's single reader, so #readout: means the same word on both
	# primitives and the two lists cannot drift the way house/regard did.
	readout = XYZSliderPlate.readout_name(raw)


func _build_readout() -> void:
	match readout:
		"none":
			pass                      # rung 0 — no label was created; nothing to add
		"numeral":
			pass                      # rung 1 — the legacy lineage, 40 rooms
		"gradation":
			_build_rule(false)
		"lattice":
			_build_rule(true)
		_:
			pass                      # an unrecognised word reads as the legacy numeral


## RUNG 2, and RUNG 3 when `stations` is true. A graduated blade laid under the
## segment, running from the FIRST endpoint along the segment's direction for
## RULE_SPAN metres — past the second handle and on, because a scale that
## stopped where your line stopped would be your line's opinion rather than a
## scale. Minor tooth every 5 cm, major plus a numeral every 25, a full tooth at
## every whole metre.
##
## `stations` adds the privileged set: a standing gate at every whole metre and
## a hot collar painted across the ±resistance_threshold interval around it —
## the exact zone in which _process_resistance jitters the rod, detunes the noise
## loop, reddens the label and pulses the controller. The law that could only
## ever be felt, standing in the room. The collar is drawn ONLY when
## enable_resistance is true: painting a law the artifact has been told not to
## enforce would be a lie in furniture form.
func _build_rule(stations: bool) -> void:
	_rule = Node3D.new()
	_rule.name = "Rule"
	# the measured ground, not the interface — same standing as the coordinate
	# frame the twin primitive embeds
	_rule.set_meta("phenomenon", true)
	add_child(_rule)
	var blade_mat: StandardMaterial3D = _rule_mat(STEEL.darkened(0.45), 0.30)
	var mark_mat: StandardMaterial3D = _rule_mat(STEEL, 0.85)
	var hot_mat: StandardMaterial3D = _rule_mat(HOT, 2.2)
	_rule_box(Vector3(RULE_SPAN, BLADE_T, BLADE_W),
			Vector3(RULE_SPAN * 0.5, -RULE_DROP, 0.0), blade_mat)
	var steps: int = int(round(RULE_SPAN / RULE_MINOR))
	for i in range(steps + 1):
		var d: float = float(i) * RULE_MINOR
		var whole: bool = absf(d - round(d)) < 0.001
		var major: bool = absf(d / RULE_MAJOR - round(d / RULE_MAJOR)) < 0.001
		var h: float = TOOTH_MINOR
		if whole:
			h = TOOTH_WHOLE
		elif major:
			h = TOOTH_MAJOR
		_rule_box(Vector3(TOOTH_W, h, BLADE_W * 0.85),
				Vector3(d, -RULE_DROP + BLADE_T * 0.5 + h * 0.5, 0.0), mark_mat)
		if not major:
			continue
		var glyph := Label3D.new()
		glyph.text = ("%d" % int(round(d))) if whole else ("%.2f" % d)
		glyph.modulate = HOT if (whole and stations) else Color(0.88, 0.91, 0.95)
		glyph.font_size = 40
		glyph.pixel_size = 0.0011
		glyph.outline_size = 6
		glyph.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glyph.position = Vector3(d, -RULE_DROP - 0.030, 0.0)
		_rule.add_child(glyph)
	if stations:
		var whole_count: int = int(floor(RULE_SPAN + 0.0001))
		for w in range(whole_count + 1):
			var at: float = float(w) * RULE_WHOLE
			_rule_box(Vector3(TOOTH_W * 2.4, GATE_H, TOOTH_W * 2.4),
					Vector3(at, -RULE_DROP + GATE_H * 0.5, 0.0), hot_mat)   # the post
			_rule_box(Vector3(0.020, 0.012, BLADE_W * 1.5),
					Vector3(at, -RULE_DROP + GATE_H, 0.0), hot_mat)          # its head
			if enable_resistance:
				var band: float = maxf(resistance_threshold, 0.005) * 2.0
				_rule_box(Vector3(band, BLADE_T * 1.6, BLADE_W * 1.35),
						Vector3(at, -RULE_DROP, 0.0), hot_mat)               # the zone
	if point_one and point_two:
		_update_rule(point_one.position, point_two.position)


## Re-seat the rule: origin on the first endpoint, local +X along the segment.
## One transform assignment per frame, no geometry rebuilt — rebuilding two
## dozen teeth to chase a dragged handle would be the wrong shape of work for
## the project's most basic primitive. Same degenerate-case guard as
## create_connection_line, so a collapsed segment leaves the rule where it was
## instead of producing a NaN basis.
func _update_rule(start_pos: Vector3, end_pos: Vector3) -> void:
	var delta: Vector3 = end_pos - start_pos
	if delta.length() < 0.001:
		return
	var dir: Vector3 = delta.normalized()
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		up = Vector3.FORWARD
	var side: Vector3 = dir.cross(up).normalized()
	var lift: Vector3 = side.cross(dir).normalized()
	_rule.transform = Transform3D(Basis(dir, lift, side), start_pos)


func _rule_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.metallic = 0.25
	m.emission_enabled = true
	m.emission = Color(c.r, c.g, c.b)
	m.emission_energy_multiplier = energy
	return m


func _rule_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rule.add_child(mi)


## Present so a caller holding this node directly (cluster_resolver, the dwell
## pass, a test harness) can drive the axis. The map path does NOT arrive here —
## it arrives as metadata on the scene root and is picked up by _read_readout()
## at _ready time, which is early enough to shape the build. See the LATENT note.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("readout"):
		return
	var want: String = XYZSliderPlate.readout_name(str(config_data["readout"]))
	if want == readout:
		return
	readout = want
	if _rule:
		remove_child(_rule)
		_rule.queue_free()
		_rule = null
	if readout == "none":
		if length_label:
			length_label.visible = false
	elif length_label:
		length_label.visible = true
	elif is_inside_tree():
		create_length_label()
	_build_readout()


func create_length_label():
	length_label = Label3D.new()
	length_label.name = "LengthLabel"
	length_label.text = "Length: 0.00m"
	length_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	length_label.font_size = 32
	length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	length_label.outline_size = 4
	length_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	length_label.scale = Vector3.ONE * 0.1
	add_child(length_label)

func _setup_glitch_audio():
	_glitch_stream = _generate_glitch_stream()
	_glitch_player = AudioStreamPlayer3D.new()
	_glitch_player.name = "GlitchPlayer"
	_glitch_player.stream = _glitch_stream
	_glitch_player.unit_size = 5.0
	_glitch_player.volume_db = -80.0 # Start silent
	_glitch_player.autoplay = true   # Always playing, volume controlled
	add_child(_glitch_player)

func _generate_glitch_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.5 # Short loop
	var length := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(length * 2)
	
	for i in length:
		# White noise with some crackle
		var sample: float = randf_range(-1.0, 1.0) * 0.8
		# Occasional spike
		if randf() > 0.95:
			sample = sign(sample) * 1.0
			
		var int_sample: int = int(sample * 32767.0)
		data[2 * i] = int_sample & 0xFF
		data[2 * i + 1] = (int_sample >> 8) & 0xFF
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream

func update_connections():
	clear_connections()
	if point_one and point_two and is_instance_valid(point_one) and is_instance_valid(point_two):
		current_line = create_connection_line(point_one.position, point_two.position)
		update_length_label(point_one.position, point_two.position)

func _process(_delta):
	if point_one and point_two and is_instance_valid(point_one) and is_instance_valid(point_two):
		update_line_transform(point_one.position, point_two.position)
		update_length_label(point_one.position, point_two.position)
		# null on the legacy path — one null test per frame for the 40 rooms
		# that never asked for a rule
		if _rule:
			_update_rule(point_one.position, point_two.position)

		if enable_resistance:
			_process_resistance(point_one.position.distance_to(point_two.position))

func _process_resistance(distance: float):
	# Calculate proximity to nearest integer (representing "perfect" measure)
	var remainder = fmod(distance, 1.0)
	var dist_to_int = min(remainder, 1.0 - remainder)
	
	if dist_to_int < resistance_threshold:
		# We are in the resistance zone
		var t = 1.0 - (dist_to_int / resistance_threshold) # 0 to 1 intensity
		var intensity = pow(t, 2.0) # Non-linear increase
		
		# 1. Visual Glitch (Jitter)
		if current_line:
			var jitter = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			) * max_jitter * intensity
			current_line.position += jitter
			
			# Occasionally flash the material
			if randf() < intensity * 0.1:
				var mat = current_line.material_override as StandardMaterial3D
				if mat:
					mat.emission_energy = 5.0
			else:
				var mat = current_line.material_override as StandardMaterial3D
				if mat:
					mat.emission_energy = 1.0

		# 2. Audio Glitch
		if _glitch_player:
			var target_vol = lerp(-40.0, glitch_sound_volume_db, intensity)
			_glitch_player.volume_db = target_vol
			_glitch_player.pitch_scale = 1.0 + (randf() - 0.5) * intensity # Pitch jitter

		# 3. Haptic Feedback
		_trigger_resistance_haptics(intensity)
		
		# 4. Label Glitch (Optional - make text shake?)
		# The null test used to live INSIDE the condition, where it guarded only the
		# true branch: a null label failed `length_label and ...` and fell straight
		# into the else, which assigned to it regardless. Guard the pair, then choose.
		if length_label:
			length_label.modulate = Color.RED if randf() < intensity * 0.2 \
				else Color(1.0, 1.0, 1.0, 0.8)
			
	else:
		# Reset effects
		if _glitch_player:
			_glitch_player.volume_db = -80.0
		
		if current_line:
			var mat = current_line.material_override as StandardMaterial3D
			if mat:
				mat.emission_energy = 1.0
				
		if length_label:
			length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)

func _trigger_resistance_haptics(intensity: float):
	# Apply haptics to controllers holding the points
	for point in [point_one, point_two]:
		if point and point.has_method("get_picked_up_by_controller"):
			var controller = point.get_picked_up_by_controller()
			if controller:
				# Higher frequency for "electric" resistance feel
				var freq = 100.0 + (intensity * 200.0) 
				controller.trigger_haptic_pulse("haptic", freq, intensity * haptic_intensity_max, 0.05, 0)

func create_connection_line(start_pos: Vector3, end_pos: Vector3) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	
	# Create cylinder mesh for the line
	var cylinder = CylinderMesh.new()
	var distance = start_pos.distance_to(end_pos)
	cylinder.height = distance
	cylinder.top_radius = line_thickness
	cylinder.bottom_radius = line_thickness
	cylinder.radial_segments = 4
	cylinder.rings = 0
	line.mesh = cylinder
	
	# Position at center between start and end
	var center_pos = (start_pos + end_pos) / 2.0
	line.position = center_pos
	
	# Orient the line to point from start to end
	var direction = (end_pos - start_pos).normalized()
	if direction.length() > 0.001:  # Avoid division by zero
		# Create proper transform for cylinder orientation
		var up = Vector3.UP
		var right = direction.cross(up).normalized()
		if right.length() < 0.001:  # If direction is parallel to UP
			right = Vector3.RIGHT
			up = right.cross(direction).normalized()
		else:
			up = right.cross(direction).normalized()
		
		# Set the transform with proper orientation
		line.transform.basis = Basis(right, direction, up)
	
	# Create material - glossy and emissive with queer pride colors influence
	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.metallic = 0.8  # High metallic for glossy look
	material.roughness = 0.1  # Low roughness for glossy finish
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED  # Hard, not transparent
	material.emission_enabled = true
	material.emission = line_color
	line.material_override = material
	
	connection_lines.append(line)
	add_child(line)
	
	return line

func update_line_transform(start_pos: Vector3, end_pos: Vector3):
	if current_line == null or not is_instance_valid(current_line):
		return
		
	var cylinder = current_line.mesh as CylinderMesh
	if cylinder == null:
		return
		
	var distance = start_pos.distance_to(end_pos)
	cylinder.height = distance
	
	var center_pos = (start_pos + end_pos) / 2.0
	current_line.position = center_pos
	
	var direction = (end_pos - start_pos).normalized()
	if direction.length() > 0.001:
		var up = Vector3.UP
		var right = direction.cross(up).normalized()
		if right.length() < 0.001:
			right = Vector3.RIGHT
			up = right.cross(direction).normalized()
		else:
			up = right.cross(direction).normalized()
		current_line.transform.basis = Basis(right, direction, up)

func update_length_label(start_pos: Vector3, end_pos: Vector3):
	if not length_label:
		return
		
	var distance = start_pos.distance_to(end_pos)
	last_distance = distance
	
	# Update label text with distance in meters (2 decimal places)
	length_label.text = "Length: %.2fm" % distance
	
	# Position label at the midpoint of the line, slightly offset upward
	var center_pos = (start_pos + end_pos) / 2.0
	center_pos.y += 0.05  # Offset up by 5cm
	length_label.position = center_pos

func clear_connections():
	if current_line and is_instance_valid(current_line):
		current_line.queue_free()
	current_line = null
	connection_lines.clear()

# Public method to manually refresh connections
func refresh_connections():
	update_connections()


# Called when either point is dropped
func _on_point_dropped(_pickable):
	# Send map-aware educational message via TextManager
	var context := {
		"length": "%.2f" % last_distance,
		"length_raw": last_distance
	}
	var handled := false
	if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
		handled = TextManager.trigger_event("line_drop", context)
	if handled:
		return
	# push_warning("Line: Missing line_drop text entry for current map")
