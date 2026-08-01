extends Node3D

# EXTRACTED FROM THE SCENE, UNCHANGED. Everything above the RECORD section below was a
# `[sub_resource type="GDScript"]` embedded inside seismograph.tscn. It moved out here byte
# for byte — same funcs, same order, same strings, same signal names — because a script
# living inside a .tscn is invisible to every tool that reads artifact source: the DNA
# declaration gate resolves a scene's script from its `ext_resource` lines and finds nothing,
# so this artifact could not be promoted, checked or swept while the code sat in the scene
# file. The scene now points here with an ext_resource and runs exactly what it ran before.

@onready var seismometer_drum = $SeismoBase/SeismometerDrum
@onready var recording_needle = $SeismoBase/SeismometerDrum/RecordingNeedle
@onready var data_display = $SeismoBase/DataDisplay
@onready var status_lights = [$SeismoBase/StatusLight1, $SeismoBase/StatusLight2, $SeismoBase/StatusLight3]
@onready var paper_roll = $SeismoBase/PaperRoll
@onready var sensor_array = $SeismoBase/SensorArray

var seismic_activity = 0.0
var recording_active = false
var sensitivity = 1.0
var baseline_reading = 0.0
var earthquake_detected = false

signal seismic_event_detected
signal earthquake_warning
signal data_recording_complete

# @identity
# essence: needle_angle = clamp((noise + baseline) * sensitivity * 45, -45, 45), sampled every 0.1 s
# desire: to stand at a machine that is listening to the ground and see the listening happen
# critical_parameter: record — how much of what the machine has already heard is still on it
# triggers: a 0.1 s monitor timer drives the needle; record decides whether the paper carries a trace
# emerges: a chart is an argument that the past was worth keeping; a bare needle is an argument that it was not
# needs: a drum, a needle and a paper roll [present]; a trace on the paper [record >= window]
# relationships: shares the `record` axis word for word with [[multimeter]], [[atmosphericmonitoring]] and [[holographicdisplay]]; the strip-chart kin of [[prng_crank_machine]]'s disclosure ladder
# truth: an instrument that keeps nothing can never be contradicted. The paper is what makes it answerable.

# ── RECORD ───────────────────────────────────────────────────────────────────
# THE AXIS — what this instrument KEEPS. Not how fast it reads: how much of the reading's
# past is still on the machine when you walk up to it, and whether anyone has been at it.
# Four states, all of them static, all of them legible in one still frame:
#
#   instant   the pointer, and nothing else. the measurement is NOW.        ← legacy default
#   window    paper is present, and only the stretch nearest the pen is inked
#   archive   the paper is inked end to end, and the run-out is folded and kept
#   margin    the archive, READ: rules, a threshold band, a scale, a hand's mark
#
# Monotone, like prng_crank_machine's disclosure ladder: each rung carries everything the
# rung below it carries plus one more kind of account. NOT TOUCHED AND NOT NEGOTIABLE: the
# detector. The 0.1 s timer, the noise band, the event probabilities, the decay and the
# needle mapping all run identically at every rung. This axis changes what the machine has
# to SHOW for its work, never the work.
#
# The registry has described this artifact as a "drum chart recorder with sine trace" since
# it was written, and four maps place it with that comment. It has never drawn a trace. At
# `instant` it still does not; the description was simply describing a rung nobody built.
@export_enum("instant", "window", "archive", "margin") var record: String = "instant"

# Sheet geometry, in world units. The panel mounts on the front face of SeismoBase (whose
# front plane is z = +0.3) and clears DataDisplay, whose lower edge is y = 0.625.
const REC_SHEET_W := 1.10
const REC_SHEET_H := 0.28
const REC_CY := 0.42
const REC_Z := 0.312
# The pen sits at the LEFT end, near the existing PaperRoll at x = -0.3, and paper travels
# right — so index 0 is the freshest sample and the ink grows away from the pen.
const REC_X0 := -0.53
const REC_X1 := 0.53
const REC_STROKES := 96
const REC_WINDOW_STROKES := 22
const REC_HALF_H := 0.115

# The detector's own statistics, replayed. `detect_seismic_activity` draws noise in
# [-0.1, 0.1] every 0.1 s and, on a hit, sets baseline to a magnitude in [0.2, 0.8] that a
# tween walks linearly to zero over 3.0 s — thirty ticks. The event TIMES are fixed rather
# than rolled so the picture is reproducible across sweeps and so the `window` rung (the
# first 22 samples) is guaranteed to contain one; their RATE is the one the detector
# actually produces, roughly a percent per tick.
const REC_DECAY_TICKS := 30
const REC_EVENTS := [[6, 0.55], [31, 0.34], [58, 0.78], [84, 0.42]]

const REC_PAPER := Color(0.93, 0.92, 0.86)
const REC_INK := Color(0.10, 0.10, 0.12)
const REC_RULE := Color(0.70, 0.68, 0.62)
const REC_BAND := Color(0.86, 0.45, 0.06)
const REC_MARK := Color(0.80, 0.10, 0.10)

var _rec_root: Node3D = null

func _ready():
	setup_seismograph()
	start_monitoring()
	_build_record()

func setup_seismograph():
	add_to_group('lab_equipment')
	add_to_group('monitoring_devices')
	add_to_group('geological_instruments')

	print('📊 SEISMOGRAPH: Geological monitoring station initialized')

func start_monitoring():
	# Drum rotation for continuous recording
	animate_recording_drum()

	# Status light sequence
	animate_status_lights()

	# Begin seismic monitoring
	start_seismic_detection()

func animate_recording_drum():
	var drum_tween = create_tween()
	drum_tween.set_loops()
	drum_tween.tween_property(seismometer_drum, 'rotation_degrees:z', 360.0, 60.0)  # Slow rotation

func animate_status_lights():
	for i in range(status_lights.size()):
		var light = status_lights[i]
		var delay = i * 0.5

		var light_tween = create_tween()
		light_tween.set_loops()
		light_tween.tween_interval(delay)
		light_tween.tween_property(light, 'light_energy', 0.2, 1.0)
		light_tween.tween_property(light, 'light_energy', 0.8, 0.3)
		light_tween.tween_property(light, 'light_energy', 0.4, 1.7)

func start_seismic_detection():
	var monitor_timer = Timer.new()
	monitor_timer.wait_time = 0.1  # High frequency monitoring
	monitor_timer.timeout.connect(detect_seismic_activity)
	add_child(monitor_timer)
	monitor_timer.start()

func detect_seismic_activity():
	# Simulate seismic readings with various noise levels
	var background_noise = randf_range(-0.1, 0.1)
	var current_reading = background_noise

	# Occasional seismic events
	if randf() < 0.01:  # 1% chance per frame
		trigger_seismic_event()
	elif randf() < 0.001:  # 0.1% chance of major earthquake
		trigger_earthquake()

	seismic_activity = current_reading + baseline_reading

	# Update needle position
	update_recording_needle()

	# Update visual displays
	update_seismic_displays()

func update_recording_needle():
	# Needle movement based on seismic activity
	var needle_angle = seismic_activity * sensitivity * 45.0  # Max 45 degree deflection
	needle_angle = clamp(needle_angle, -45.0, 45.0)

	var needle_tween = create_tween()
	needle_tween.tween_property(recording_needle, 'rotation_degrees:z', needle_angle, 0.05)

func update_seismic_displays():
	# Display intensity affects color and brightness
	var intensity = abs(seismic_activity)
	var display_color = Color.GREEN

	if intensity > 0.8:
		display_color = Color.RED
	elif intensity > 0.6:
		display_color = Color.ORANGE
	elif intensity > 0.3:
		display_color = Color.YELLOW

	data_display.get_active_material(0).emission = display_color
	data_display.get_active_material(0).emission_energy_multiplier = 0.5 + intensity * 1.5

func trigger_seismic_event():
	var event_magnitude = randf_range(0.2, 0.8)
	print('🌍 SEISMOGRAPH: Seismic event detected - Magnitude: %.2f' % event_magnitude)
	emit_signal('seismic_event_detected', event_magnitude)

	# Temporary spike in readings
	baseline_reading = event_magnitude

	# Visual response
	flash_seismic_alert()

	# Return to normal after event
	var decay_tween = create_tween()
	decay_tween.tween_method(Callable(self, "set_baseline_reading"), baseline_reading, 0.0, 3.0)

func trigger_earthquake():
	earthquake_detected = true
	var magnitude = randf_range(3.0, 7.5)
	print('🚨 EARTHQUAKE DETECTED! Magnitude: %.1f' % magnitude)
	emit_signal('earthquake_warning', magnitude)

	# Intense seismic activity
	baseline_reading = magnitude / 10.0  # Scale down for needle

	# Emergency alert sequence
	trigger_earthquake_alert()

	# Extended decay time for earthquakes
	var earthquake_tween = create_tween()
	earthquake_tween.tween_method(Callable(self, "set_baseline_reading"), baseline_reading, 0.0, 10.0)
	earthquake_tween.tween_callback(earthquake_complete)

func flash_seismic_alert():
	# Flash status lights for seismic events
	for light in status_lights:
		var alert_tween = create_tween()
		alert_tween.set_loops(3)
		alert_tween.tween_property(light, 'light_color', Color.YELLOW, 0.1)
		alert_tween.tween_property(light, 'light_color', Color.BLUE, 0.1)

func trigger_earthquake_alert():
	# Full emergency alert for earthquakes
	for light in status_lights:
		var emergency_tween = create_tween()
		emergency_tween.set_loops(10)
		emergency_tween.tween_property(light, 'light_color', Color.RED, 0.2)
		emergency_tween.tween_property(light, 'light_energy', 2.0, 0.1)
		emergency_tween.tween_property(light, 'light_energy', 0.1, 0.1)

func set_baseline_reading(current_value: float):
	baseline_reading = current_value

func earthquake_complete():
	earthquake_detected = false
	print('📊 SEISMOGRAPH: Earthquake event concluded - Returning to normal monitoring')

func _on_area_3d_body_entered(body):
	if body.is_in_group('player'):
		display_seismic_status()

func display_seismic_status():
	print('📊 SEISMOGRAPH STATUS:')
	print('  Current Activity: %.3f' % seismic_activity)
	print('  Sensitivity: %.1fx' % sensitivity)
	print('  Recording: ', 'ACTIVE' if recording_active else 'STANDBY')
	if earthquake_detected:
		print('  🚨 EARTHQUAKE IN PROGRESS')

func calibrate_sensitivity(new_sensitivity: float):
	sensitivity = clamp(new_sensitivity, 0.1, 5.0)
	print('📊 SEISMOGRAPH: Sensitivity calibrated to %.1fx' % sensitivity)

func start_recording():
	recording_active = true
	print('📊 SEISMOGRAPH: Recording activated')

	# Paper roll animation
	var paper_tween = create_tween()
	paper_tween.set_loops()
	paper_tween.tween_property(paper_roll, 'position:x', -0.1, 30.0)

func stop_recording():
	recording_active = false
	print('📊 SEISMOGRAPH: Recording stopped')
	emit_signal('data_recording_complete')


# ── RECORD, BUILT ────────────────────────────────────────────────────────────
# Everything below here is the axis and nothing else. It is APPENDED, and the whole of it
# is gated behind `record != "instant"`, so the legacy lineage adds no node, allocates no
# material and consumes nothing from the global RNG (the trace uses its own seeded
# RandomNumberGenerator so it can never shift a draw the detector would otherwise have made).

## A map may set the rung with `#record:archive`. Only the record layer is ever rebuilt;
## the drum, needle, roll, display, lights and sensor plate are never touched.
func apply_grid_config(config_data: Dictionary) -> void:
	var raw: String = ""
	if config_data.has("record"):
		raw = str(config_data["record"])
	elif has_meta("config_record"):
		raw = str(get_meta("config_record"))
	if raw == "":
		return
	var want: String = raw.strip_edges().to_lower()
	if not (want in ["instant", "window", "archive", "margin"]):
		push_warning("seismograph: unknown record rung '%s' — keeping '%s'" % [want, record])
		return
	if want == record:
		return
	record = want
	if _rec_root != null:
		_rec_root.queue_free()
		_rec_root = null
	_build_record()


func _build_record() -> void:
	if record == "instant":
		return
	_rec_root = Node3D.new()
	_rec_root.name = "Record"
	add_child(_rec_root)

	var full: bool = record != "window"
	var samples: PackedFloat32Array = _record_samples(REC_STROKES)

	# The sheet itself — identical at every rung above `instant`, so the three inked rungs
	# share one bounding box and the capture camera frames them the same way. What differs
	# is how much of it has been under the pen.
	_rec_box(Vector3(0.0, REC_CY, REC_Z), Vector3(REC_SHEET_W, REC_SHEET_H, 0.008), REC_PAPER)

	# The pen carriage, parked at the fresh end of the paper.
	_rec_box(Vector3(REC_X0, REC_CY + 0.10, REC_Z + 0.022), Vector3(0.05, 0.05, 0.03), Color(0.14, 0.14, 0.17))
	_rec_box(Vector3(REC_X0, REC_CY + 0.03, REC_Z + 0.016), Vector3(0.006, 0.10, 0.008), Color(0.20, 0.20, 0.24))

	if record == "margin":
		_rec_furniture()

	var step: float = (REC_X1 - REC_X0) / float(REC_STROKES - 1)
	var count: int = REC_STROKES if full else REC_WINDOW_STROKES
	var peak_i: int = 0
	for i in range(count):
		if absf(samples[i]) > absf(samples[peak_i]):
			peak_i = i
	for i in range(count - 1):
		var a: float = samples[i]
		var b: float = samples[i + 1]
		var lo: float = minf(a, b) * REC_HALF_H
		var hi: float = maxf(a, b) * REC_HALF_H
		var h: float = maxf(hi - lo, 0.004)
		_rec_box(Vector3(REC_X0 + float(i) * step, REC_CY + (lo + hi) * 0.5, REC_Z + 0.009),
			Vector3(0.005, h, 0.004), REC_INK)

	if full:
		_rec_foldstack()
	if record == "margin":
		_rec_hand(REC_X0 + float(peak_i) * step, REC_CY + samples[peak_i] * REC_HALF_H)


## WINDOW vs ARCHIVE, on paper: the run-out. A machine that has been listening for a day has
## a pile of chart behind it; one switched on a minute ago has none. Six folded leaves on the
## top deck, inside the existing silhouette (clear of the drum at x = -0.3 and below the
## needle's tip at y = 1.03) so window / archive / margin keep one bounding box between them.
func _rec_foldstack() -> void:
	for i in range(6):
		var off: float = 0.014 if (i % 2) == 0 else -0.014
		_rec_box(Vector3(0.42 + off, 0.815 + float(i) * 0.012, 0.05),
			Vector3(0.30, 0.010, 0.20), REC_PAPER.darkened(0.02 * float(i)))


## MARGIN, part one: the ruling and the scale — the chart printed to be READ against, not
## just written on. Rules, two threshold bars in the amber this project already uses for a
## limit, and a tick scale along the foot.
func _rec_furniture() -> void:
	var top: float = REC_CY + REC_HALF_H
	for k in range(5):
		var y: float = REC_CY + lerpf(-0.10, 0.10, float(k) / 4.0)
		_rec_box(Vector3(0.0, y, REC_Z + 0.006), Vector3(REC_SHEET_W - 0.04, 0.0025, 0.003), REC_RULE)
	for k in range(13):
		var x: float = lerpf(REC_X0, REC_X1, float(k) / 12.0)
		_rec_box(Vector3(x, REC_CY, REC_Z + 0.006), Vector3(0.0025, REC_SHEET_H - 0.05, 0.003), REC_RULE)
		_rec_box(Vector3(x, REC_CY - REC_HALF_H - 0.012, REC_Z + 0.012), Vector3(0.004, 0.022, 0.003), REC_INK)
	for s in [-1.0, 1.0]:
		_rec_box(Vector3(0.0, REC_CY + s * 0.085, REC_Z + 0.008),
			Vector3(REC_SHEET_W - 0.04, 0.008, 0.003), REC_BAND)
	_rec_box(Vector3(0.0, REC_CY - REC_HALF_H - 0.012, REC_Z + 0.010),
		Vector3(REC_SHEET_W - 0.04, 0.0025, 0.003), REC_INK)
	# A silent nod that the top of the chart is a boundary someone drew, not the paper's edge.
	_rec_box(Vector3(0.0, top + 0.006, REC_Z + 0.010), Vector3(REC_SHEET_W - 0.04, 0.003, 0.003), REC_RULE)


## MARGIN, part two: the hand. Someone came back to this chart, found the largest excursion
## on it and ringed it — the moment a record stops being output and becomes evidence.
func _rec_hand(px: float, py: float) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.030
	torus.outer_radius = 0.038
	ring.mesh = torus
	ring.position = Vector3(px, py, REC_Z + 0.014)
	ring.rotation.x = PI / 2.0
	ring.material_override = _rec_mat(REC_MARK)
	_rec_root.add_child(ring)
	var foot: float = REC_CY - 0.105
	_rec_box(Vector3(px, foot, REC_Z + 0.014), Vector3(0.18, 0.005, 0.003), REC_MARK)
	for s in [-1.0, 1.0]:
		_rec_box(Vector3(px + s * 0.09, foot + 0.014, REC_Z + 0.014), Vector3(0.005, 0.028, 0.003), REC_MARK)
	for k in range(3):
		_rec_box(Vector3(px + 0.115, py + 0.022 - float(k) * 0.014, REC_Z + 0.014),
			Vector3(0.045, 0.004, 0.003), REC_MARK)


## The detector's own process, replayed onto paper: noise in [-0.1, 0.1] every tick, plus a
## linearly decaying baseline from each event. Index 0 is the newest sample, at the pen.
func _record_samples(n: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8102026
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var baseline: float = 0.0
		for ev in REC_EVENTS:
			var at: int = int(ev[0])
			var mag: float = float(ev[1])
			if i >= at and i - at <= REC_DECAY_TICKS:
				baseline = maxf(baseline, mag * (1.0 - float(i - at) / float(REC_DECAY_TICKS)))
		out[i] = clampf(rng.randf_range(-0.1, 0.1) + baseline, -1.0, 1.0)
	return out


func _rec_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m


func _rec_box(center: Vector3, size: Vector3, c: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _rec_mat(c)
	mi.position = center
	_rec_root.add_child(mi)
