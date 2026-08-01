# multimeter.gd
# Digital multimeter with analog-style oscillating needle
# Demonstrates AC waveforms and frequency measurement
extends Node3D

class_name LabMultimeter


# @identity
# essence: V(t) = dc_offset + ac_amplitude * sin(ac_frequency * t * TAU) + noise * randf()
# desire: Read voltage on a multimeter whose needle oscillates with the measured AC signal
# critical_parameter: record — whether the meter can still show you the reading it took a minute ago
# triggers: time drives the AC sine wave; noise_level adds measurement uncertainty; record decides whether the tape carries ink
# emerges: the needle as wave visualizer — watching measurement oscillate reveals the signal nature
# needs: VR observation [has], frequency/amplitude adjustment [missing]
# relationships: shares the `record` axis word for word with [[seismograph]], [[atmosphericmonitoring]] and [[holographicdisplay]]; contrasts with electronicscales (voltage vs mass oscillation)
# truth: Every AC measurement is reading the current value of an ongoing oscillation — and a meter that prints is claiming that value will still be true tomorrow.

# ── RECORD ───────────────────────────────────────────────────────────────────
# THE AXIS, shared word for word with [[seismograph]], [[atmosphericmonitoring]] and
# [[holographicdisplay]]: what this instrument KEEPS. Not how fast the needle swings — how
# much of the reading's past is still on the machine when you walk up to it, and whether
# anyone has been at it.
#
#   instant   the needle and the LCD, and nothing else. the measurement is NOW.  ← legacy
#   window    a tape stands out of the case, inked only near the slot
#   archive   the tape is inked end to end, and the run-out is fanfolded on the bench
#   margin    the archive, READ: a scale ladder, a limit band, a hand's ring
#
# A hand meter with a paper tape is a printing/logging DMM — the same instrument, arguing
# that a measurement is a thing you can carry away from the bench rather than a thing you
# had to be present for.
#
# NOT TOUCHED: the measurement. _process, the four modes, the noise, the needle mapping and
# the LED all run identically at every rung. The tape is drawn by replaying the SAME four
# mode formulas backwards in time, so the printout cannot disagree with the needle above it.
@export_enum("instant", "window", "archive", "margin") var record: String = "instant"

@export_group("Measurement")
@export var ac_frequency: float = 1.0  # Hz
@export var ac_amplitude: float = 5.0  # Volts peak
@export var dc_offset: float = 0.0
@export var noise_level: float = 0.1
@export_enum("AC_VOLTAGE", "DC_VOLTAGE", "RESISTANCE", "FREQUENCY") var mode: int = 0

@export_group("Display")
@export var lcd_color: Color = Color(0.2, 1.0, 0.4)
@export var needle_color: Color = Color(1.0, 0.3, 0.1)

## Internal
var time: float = 0.0
var current_reading: float = 0.0
var needle_node: Node3D
var lcd_node: MeshInstance3D
var needle_mesh: MeshInstance3D
var status_led: OmniLight3D

func _ready() -> void:
	_build_multimeter()
	_build_record()

func _process(delta: float) -> void:
	time += delta
	
	match mode:
		0:  # AC Voltage - sine wave
			current_reading = ac_amplitude * sin(time * ac_frequency * TAU) + dc_offset
			current_reading += (randf() - 0.5) * noise_level
		1:  # DC Voltage - steady with noise
			current_reading = dc_offset + (randf() - 0.5) * noise_level * 0.5
		2:  # Resistance - slow drift
			current_reading = 1000.0 + 50.0 * sin(time * 0.3) + randf() * 10.0
		3:  # Frequency - displays the frequency
			current_reading = ac_frequency + (randf() - 0.5) * 0.01
	
	_update_display()

func _update_display() -> void:
	# Needle deflection based on reading
	if needle_node:
		var deflection: float
		match mode:
			0, 1:  # Voltage modes
				deflection = clamp(current_reading / 10.0, -1.0, 1.0) * 45.0
			2:  # Resistance
				deflection = clamp(log(current_reading) / 10.0, 0.0, 1.0) * 90.0 - 45.0
			3:  # Frequency
				deflection = clamp(current_reading / 5.0, 0.0, 1.0) * 90.0 - 45.0
		needle_node.rotation_degrees.z = deflection
	
	# LCD brightness pulses with measurement
	if lcd_node and lcd_node.material_override:
		var brightness = 0.8 + 0.4 * abs(sin(time * 2.0))
		lcd_node.material_override.emission_energy_multiplier = brightness
	
	# Status LED blinks at measurement rate
	if status_led:
		var blink = 0.5 + 0.5 * sin(time * ac_frequency * TAU * 2.0)
		status_led.light_energy = blink

func _build_multimeter() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Main body
	var body = MeshInstance3D.new()
	body.name = "Body"
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.12, 0.18, 0.035)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.09, 0)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.15, 0.18)
	body_mat.roughness = 0.7
	body.material_override = body_mat
	add_child(body)
	
	# LCD Display
	lcd_node = MeshInstance3D.new()
	lcd_node.name = "LCD"
	var lcd_mesh = BoxMesh.new()
	lcd_mesh.size = Vector3(0.08, 0.035, 0.003)
	lcd_node.mesh = lcd_mesh
	lcd_node.position = Vector3(0, 0.14, 0.019)
	var lcd_mat = StandardMaterial3D.new()
	lcd_mat.albedo_color = Color(0.05, 0.1, 0.05)
	lcd_mat.emission_enabled = true
	lcd_mat.emission = lcd_color
	lcd_mat.emission_energy_multiplier = 1.0
	lcd_node.material_override = lcd_mat
	add_child(lcd_node)
	
	# Analog needle gauge
	var gauge_bg = MeshInstance3D.new()
	gauge_bg.name = "GaugeBackground"
	var gauge_mesh = CylinderMesh.new()
	gauge_mesh.top_radius = 0.035
	gauge_mesh.bottom_radius = 0.035
	gauge_mesh.height = 0.003
	gauge_mesh.radial_segments = 32
	gauge_bg.mesh = gauge_mesh
	gauge_bg.rotation.x = PI / 2
	gauge_bg.position = Vector3(0, 0.095, 0.019)
	var gauge_mat = StandardMaterial3D.new()
	gauge_mat.albedo_color = Color(0.95, 0.95, 0.9)
	gauge_bg.material_override = gauge_mat
	add_child(gauge_bg)
	
	# Needle pivot
	needle_node = Node3D.new()
	needle_node.name = "NeedlePivot"
	needle_node.position = Vector3(0, 0.095, 0.021)
	add_child(needle_node)
	
	# Needle
	needle_mesh = MeshInstance3D.new()
	needle_mesh.name = "Needle"
	var n_mesh = BoxMesh.new()
	n_mesh.size = Vector3(0.002, 0.03, 0.001)
	needle_mesh.mesh = n_mesh
	needle_mesh.position = Vector3(0, 0.015, 0)
	var needle_mat = StandardMaterial3D.new()
	needle_mat.albedo_color = needle_color
	needle_mat.emission_enabled = true
	needle_mat.emission = needle_color
	needle_mat.emission_energy_multiplier = 0.5
	needle_mesh.material_override = needle_mat
	needle_node.add_child(needle_mesh)
	
	# Rotary dial
	var dial = MeshInstance3D.new()
	dial.name = "Dial"
	var dial_mesh = CylinderMesh.new()
	dial_mesh.top_radius = 0.02
	dial_mesh.bottom_radius = 0.02
	dial_mesh.height = 0.008
	dial.mesh = dial_mesh
	dial.rotation.x = PI / 2
	dial.position = Vector3(0, 0.045, 0.019)
	var dial_mat = StandardMaterial3D.new()
	dial_mat.albedo_color = Color(0.3, 0.3, 0.35)
	dial_mat.metallic = 0.8
	dial_mat.roughness = 0.2
	dial.material_override = dial_mat
	add_child(dial)
	
	# Status LED
	status_led = OmniLight3D.new()
	status_led.name = "StatusLED"
	status_led.position = Vector3(0.04, 0.16, 0.019)
	status_led.light_color = Color.GREEN
	status_led.light_energy = 0.5
	status_led.omni_range = 0.1
	add_child(status_led)
	
	var led_mesh = MeshInstance3D.new()
	var led_sphere = SphereMesh.new()
	led_sphere.radius = 0.004
	led_sphere.height = 0.008
	led_mesh.mesh = led_sphere
	var led_mat = StandardMaterial3D.new()
	led_mat.albedo_color = Color.GREEN
	led_mat.emission_enabled = true
	led_mat.emission = Color.GREEN
	led_mat.emission_energy_multiplier = 2.0
	led_mesh.material_override = led_mat
	status_led.add_child(led_mesh)
	
	# Probe ports (red and black)
	_add_probe_port(Vector3(-0.03, 0.01, 0.0), Color.RED)
	_add_probe_port(Vector3(0.03, 0.01, 0.0), Color.BLACK)

func _add_probe_port(pos: Vector3, color: Color) -> void:
	var port = MeshInstance3D.new()
	var port_mesh = CylinderMesh.new()
	port_mesh.top_radius = 0.006
	port_mesh.bottom_radius = 0.006
	port_mesh.height = 0.01
	port.mesh = port_mesh
	port.position = pos
	var port_mat = StandardMaterial3D.new()
	port_mat.albedo_color = color
	port_mat.metallic = 0.7
	port.material_override = port_mat
	add_child(port)

## Public API
func set_frequency(freq: float) -> void:
	ac_frequency = freq

func set_amplitude(amp: float) -> void:
	ac_amplitude = amp

func get_reading() -> float:
	return current_reading


# ── RECORD, BUILT ────────────────────────────────────────────────────────────
# APPENDED. Every line below is gated behind `record != "instant"`, so the legacy lineage
# adds no node, allocates no material and takes nothing from the global RNG — the tape's
# measurement noise comes from its own seeded RandomNumberGenerator, so it can never shift
# a draw _process would otherwise have made.

# The tape rises out of a slot in the top of the case: time runs UP the tape (newest at the
# slot, oldest at the top) and the reading deflects left and right, which is how a paper
# tape recorder actually writes. The carrier is identical at window / archive / margin so
# those three share one bounding box and the capture camera frames them the same way; only
# the ink and the marks differ.
const REC_TAPE_W := 0.055
const REC_TAPE_Y0 := 0.192
const REC_TAPE_Y1 := 0.393
const REC_TAPE_Z := 0.004
const REC_SWING := 0.021
const REC_DOTS := 48
const REC_WINDOW_DOTS := 11
const REC_DT := 0.06

const REC_PAPER := Color(0.93, 0.92, 0.86)
const REC_INK := Color(0.10, 0.10, 0.12)
const REC_RULE := Color(0.70, 0.68, 0.62)
const REC_BAND := Color(0.86, 0.45, 0.06)
const REC_MARK := Color(0.80, 0.10, 0.10)

var _rec_root: Node3D = null


## A map may set the rung with `#record:archive`. Only the record layer is rebuilt; the
## body, LCD, gauge, needle, dial, LED and probe ports are never touched.
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
		push_warning("multimeter: unknown record rung '%s' — keeping '%s'" % [want, record])
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

	# The slot the tape comes out of, and the tape.
	_rec_box(Vector3(0.0, 0.182, REC_TAPE_Z), Vector3(0.064, 0.005, 0.014), Color(0.10, 0.10, 0.13))
	_rec_box(Vector3(0.0, (REC_TAPE_Y0 + REC_TAPE_Y1) * 0.5, REC_TAPE_Z),
		Vector3(REC_TAPE_W, REC_TAPE_Y1 - REC_TAPE_Y0 + 0.010, 0.0012), REC_PAPER)

	var rng := RandomNumberGenerator.new()
	rng.seed = 4152026
	var dots := PackedFloat32Array()
	dots.resize(REC_DOTS)
	for j in range(REC_DOTS):
		dots[j] = _rec_deflection(-float(j) * REC_DT, rng)

	if record == "margin":
		_rec_furniture()

	var step: float = (REC_TAPE_Y1 - REC_TAPE_Y0) / float(REC_DOTS - 1)
	var count: int = REC_DOTS if full else REC_WINDOW_DOTS
	var peak_j: int = 0
	for j in range(count):
		if absf(dots[j]) > absf(dots[peak_j]):
			peak_j = j
	for j in range(count):
		_rec_box(Vector3(dots[j] * REC_SWING, REC_TAPE_Y0 + float(j) * step, REC_TAPE_Z + 0.0012),
			Vector3(0.0038, 0.0042, 0.0008), REC_INK)

	if full:
		_rec_fanfold()
	if record == "margin":
		_rec_hand(dots[peak_j] * REC_SWING, REC_TAPE_Y0 + float(peak_j) * step)


## WINDOW vs ARCHIVE, on the bench: a concertina of tape that has already run through. A
## meter switched on a minute ago has none of this; one that has been logging all shift has
## a pile of it. It lies on the bench beside the case rather than on the tape, so the tape
## itself stays the same object at every inked rung.
func _rec_fanfold() -> void:
	for i in range(5):
		var off: float = 0.004 if (i % 2) == 0 else -0.004
		_rec_box(Vector3(0.085 + off, 0.0032 + float(i) * 0.0042, 0.006),
			Vector3(0.052, 0.0028, 0.048), REC_PAPER.darkened(0.03 * float(i)))


## MARGIN, part one: the tape printed to be read AGAINST. The tape runs upward and the pen
## swings sideways, so the LIMITS are two vertical lines the ink is meant to stay between,
## and the TIME marks are horizontal rules across it. Plus a printed header block at the
## top of the run and a tick ladder up both edges.
func _rec_furniture() -> void:
	var mid: float = (REC_TAPE_Y0 + REC_TAPE_Y1) * 0.5
	var span: float = REC_TAPE_Y1 - REC_TAPE_Y0
	for s in [-1.0, 1.0]:
		_rec_box(Vector3(s * 0.0155, mid, REC_TAPE_Z + 0.0009),
			Vector3(0.0030, span, 0.0006), REC_BAND)
	_rec_box(Vector3(0.0, mid, REC_TAPE_Z + 0.0008), Vector3(0.0010, span, 0.0006), REC_RULE)
	for k in range(9):
		var y: float = lerpf(REC_TAPE_Y0, REC_TAPE_Y1, float(k) / 8.0)
		_rec_box(Vector3(-0.0235, y, REC_TAPE_Z + 0.0010), Vector3(0.009, 0.0018, 0.0006), REC_INK)
		_rec_box(Vector3(0.0235, y, REC_TAPE_Z + 0.0010), Vector3(0.009, 0.0018, 0.0006), REC_INK)
	for k in range(4):
		var yb: float = lerpf(REC_TAPE_Y0 + 0.024, REC_TAPE_Y1 - 0.024, float(k) / 3.0)
		_rec_box(Vector3(0.0, yb, REC_TAPE_Z + 0.0007), Vector3(REC_TAPE_W - 0.004, 0.0022, 0.0006), REC_RULE)
	_rec_box(Vector3(0.0, REC_TAPE_Y1 + 0.0035, REC_TAPE_Z + 0.0010),
		Vector3(REC_TAPE_W - 0.003, 0.0100, 0.0006), REC_BAND)


## MARGIN, part two: the hand. Someone ringed the largest excursion on the tape and bracketed
## it — the moment a printout stops being output and becomes evidence.
func _rec_hand(px: float, py: float) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.0085
	torus.outer_radius = 0.0115
	ring.mesh = torus
	ring.position = Vector3(px, py, REC_TAPE_Z + 0.0022)
	ring.rotation.x = PI / 2.0
	ring.material_override = _rec_mat(REC_MARK)
	_rec_root.add_child(ring)
	for s in [-1.0, 1.0]:
		_rec_box(Vector3(0.0, py + s * 0.018, REC_TAPE_Z + 0.0022),
			Vector3(REC_TAPE_W - 0.002, 0.0022, 0.0006), REC_MARK)
	_rec_box(Vector3(0.0255, py, REC_TAPE_Z + 0.0022), Vector3(0.0022, 0.036, 0.0006), REC_MARK)


## The SAME four mode formulas _process runs, evaluated at a past time and normalised to the
## needle's own full-scale deflection, so the tape agrees with the needle above it. `tt` is
## negative: seconds before now. Noise comes from the caller's seeded generator.
func _rec_deflection(tt: float, rng: RandomNumberGenerator) -> float:
	var r: float = 0.0
	match mode:
		0:
			r = ac_amplitude * sin(tt * ac_frequency * TAU) + dc_offset
			r += (rng.randf() - 0.5) * noise_level
		1:
			r = dc_offset + (rng.randf() - 0.5) * noise_level * 0.5
		2:
			r = 1000.0 + 50.0 * sin(tt * 0.3) + rng.randf() * 10.0
		3:
			r = ac_frequency + (rng.randf() - 0.5) * 0.01
	match mode:
		0, 1:
			return clampf(r / 10.0, -1.0, 1.0)
		2:
			return clampf(log(maxf(r, 1.0)) / 10.0, 0.0, 1.0) * 2.0 - 1.0
		_:
			return clampf(r / 5.0, 0.0, 1.0) * 2.0 - 1.0


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
