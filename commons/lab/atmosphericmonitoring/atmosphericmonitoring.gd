# atmosphericmonitoring.gd
# Atmospheric monitoring station with oscillating gauges
# Demonstrates multiple sine waves at different frequencies
extends Node3D

class_name LabAtmosphericMonitoring


# @identity
# essence: reading(t) = base + variation * sin(frequency * t * TAU) + noise
# desire: Watch laboratory instruments slowly drift through atmospheric measurements
# critical_parameter: record — three needles show three instants; a chart shows that they are three DIFFERENT waves
# triggers: time drives sinusoidal variation in pressure, temperature, humidity needles; record decides whether the chart carries their past
# emerges: the feeling of a living laboratory where instruments never fully settle
# needs: VR needle observation [has], alert threshold adjustment [missing]
# relationships: shares the `record` axis word for word with [[seismograph]], [[multimeter]] and [[holographicdisplay]]; contrasts with multimeter (AC measurement vs environmental monitoring)
# truth: The atmosphere is a superposition of slow oscillations that instruments make legible — and a needle can only ever show you one instant of a superposition, which is to say none of it.

# ── RECORD ───────────────────────────────────────────────────────────────────
# THE AXIS, shared word for word with [[seismograph]], [[multimeter]] and
# [[holographicdisplay]]: what this instrument KEEPS.
#
#   instant   three needles, and nothing else. the measurement is NOW.       ← legacy
#   window    a chart card stands over the gauges, inked only at the pen end
#   archive   the card is inked end to end, and the run-off is wound on a spool
#   margin    the archive, READ: lane rules, normal-range rails, a scale, a hand's ring
#
# THIS ARTIFACT IS THE ARGUMENT FOR THE AXIS. Its own description says three independent
# oscillations "create complex patterns" — but three needles can only ever show three
# instants, and an instant of a superposition carries no information about superposition at
# all. Standing at it, you cannot tell that pressure runs at 0.05 Hz and temperature at
# 0.02. On the chart, over one span of the same paper, pressure draws six periods and
# temperature two and a half, and the claim in the description becomes a thing you can see
# without waiting. That is a difference in what the reading COMMITS TO, not in tempo.
#
# NOT TOUCHED: the three sine channels, their bases, variations, frequencies, the needle
# mappings and the status-light thresholds. The chart is drawn by evaluating THE SAME three
# functions at past times, so it cannot disagree with the needles above it.
@export_enum("instant", "window", "archive", "margin") var record: String = "instant"

@export_group("Pressure")
@export var pressure_base: float = 1013.25  # hPa (standard atm)
@export var pressure_variation: float = 5.0  # hPa
@export var pressure_frequency: float = 0.05  # Hz (slow drift)

@export_group("Temperature")
@export var temp_base: float = 22.0  # Celsius
@export var temp_variation: float = 0.5
@export var temp_frequency: float = 0.02

@export_group("Humidity")
@export var humidity_base: float = 45.0  # Percent
@export var humidity_variation: float = 5.0
@export var humidity_frequency: float = 0.03

## Internal
var time: float = 0.0
var pressure_needle: Node3D
var temp_needle: Node3D
var humidity_needle: Node3D
var status_lights: Array[OmniLight3D] = []
var display_panel: MeshInstance3D

func _ready() -> void:
	_build_station()
	_build_record()

func _process(delta: float) -> void:
	time += delta
	
	# Pressure gauge - slow sine wave
	var pressure = pressure_base + pressure_variation * sin(time * pressure_frequency * TAU)
	if pressure_needle:
		var pressure_angle = (pressure - 980.0) / 70.0 * 180.0 - 90.0  # Map 980-1050 to -90 to 90
		pressure_needle.rotation_degrees.z = clamp(pressure_angle, -90.0, 90.0)
	
	# Temperature gauge - different frequency
	var temp = temp_base + temp_variation * sin(time * temp_frequency * TAU)
	if temp_needle:
		var temp_angle = (temp - 15.0) / 20.0 * 180.0 - 90.0  # Map 15-35 to -90 to 90
		temp_needle.rotation_degrees.z = clamp(temp_angle, -90.0, 90.0)
	
	# Humidity gauge - third frequency
	var humidity = humidity_base + humidity_variation * sin(time * humidity_frequency * TAU)
	if humidity_needle:
		var humidity_angle = humidity / 100.0 * 180.0 - 90.0  # Map 0-100 to -90 to 90
		humidity_needle.rotation_degrees.z = clamp(humidity_angle, -90.0, 90.0)
	
	# Status lights - green when in normal range
	_update_status_lights(pressure, temp, humidity)
	
	# Display panel pulse
	if display_panel and display_panel.material_override:
		var pulse = 0.6 + 0.2 * sin(time * 1.0)
		display_panel.material_override.emission_energy_multiplier = pulse

func _update_status_lights(pressure: float, temp: float, humidity: float) -> void:
	if status_lights.size() < 3:
		return
	
	# Pressure status
	if abs(pressure - 1013.25) < 10.0:
		status_lights[0].light_color = Color.GREEN
	else:
		status_lights[0].light_color = Color.YELLOW
	
	# Temperature status
	if temp >= 18.0 and temp <= 26.0:
		status_lights[1].light_color = Color.GREEN
	else:
		status_lights[1].light_color = Color.YELLOW
	
	# Humidity status
	if humidity >= 30.0 and humidity <= 60.0:
		status_lights[2].light_color = Color.GREEN
	else:
		status_lights[2].light_color = Color.YELLOW
	
	# Pulse all lights
	for light in status_lights:
		light.light_energy = 0.3 + 0.2 * sin(time * 2.0)

func _build_station() -> void:
	for child in get_children():
		child.queue_free()
	status_lights.clear()
	
	# Main housing
	var housing = MeshInstance3D.new()
	housing.name = "Housing"
	var housing_mesh = BoxMesh.new()
	housing_mesh.size = Vector3(0.35, 0.25, 0.08)
	housing.mesh = housing_mesh
	housing.position = Vector3(0, 0.125, 0)
	var housing_mat = StandardMaterial3D.new()
	housing_mat.albedo_color = Color(0.2, 0.22, 0.25)
	housing_mat.metallic = 0.3
	housing_mat.roughness = 0.6
	housing.material_override = housing_mat
	add_child(housing)
	
	# Create three circular gauges
	var gauge_data = [
		{"name": "Pressure", "pos": Vector3(-0.1, 0.16, 0.041), "color": Color(0.2, 0.6, 1.0)},
		{"name": "Temperature", "pos": Vector3(0.0, 0.16, 0.041), "color": Color(1.0, 0.4, 0.2)},
		{"name": "Humidity", "pos": Vector3(0.1, 0.16, 0.041), "color": Color(0.2, 0.8, 0.4)},
	]
	
	var needles: Array[Node3D] = []
	
	for data in gauge_data:
		var gauge = _create_gauge(data.pos, data.color, data.name)
		needles.append(gauge)
	
	pressure_needle = needles[0]
	temp_needle = needles[1]
	humidity_needle = needles[2]
	
	# Digital display panel
	display_panel = MeshInstance3D.new()
	display_panel.name = "DisplayPanel"
	var display_mesh = BoxMesh.new()
	display_mesh.size = Vector3(0.28, 0.05, 0.003)
	display_panel.mesh = display_mesh
	display_panel.position = Vector3(0, 0.06, 0.041)
	var display_mat = StandardMaterial3D.new()
	display_mat.albedo_color = Color(0.05, 0.1, 0.05)
	display_mat.emission_enabled = true
	display_mat.emission = Color(0.1, 0.8, 0.3)
	display_mat.emission_energy_multiplier = 0.6
	display_panel.material_override = display_mat
	add_child(display_panel)
	
	# Status indicator lights
	var light_positions = [
		Vector3(-0.1, 0.095, 0.041),
		Vector3(0.0, 0.095, 0.041),
		Vector3(0.1, 0.095, 0.041),
	]
	
	for pos in light_positions:
		var light = OmniLight3D.new()
		light.position = pos
		light.light_color = Color.GREEN
		light.light_energy = 0.3
		light.omni_range = 0.05
		add_child(light)
		status_lights.append(light)
		
		var led = MeshInstance3D.new()
		var led_mesh = SphereMesh.new()
		led_mesh.radius = 0.006
		led_mesh.height = 0.012
		led.mesh = led_mesh
		var led_mat = StandardMaterial3D.new()
		led_mat.albedo_color = Color.GREEN
		led_mat.emission_enabled = true
		led_mat.emission = Color.GREEN
		led_mat.emission_energy_multiplier = 1.0
		led.material_override = led_mat
		light.add_child(led)
	
	# Ventilation grille
	var grille = MeshInstance3D.new()
	grille.name = "Grille"
	var grille_mesh = BoxMesh.new()
	grille_mesh.size = Vector3(0.08, 0.03, 0.005)
	grille.mesh = grille_mesh
	grille.position = Vector3(0.12, 0.025, 0.041)
	var grille_mat = StandardMaterial3D.new()
	grille_mat.albedo_color = Color(0.15, 0.15, 0.18)
	grille.material_override = grille_mat
	add_child(grille)

func _create_gauge(pos: Vector3, accent_color: Color, gauge_name: String) -> Node3D:
	var gauge_radius = 0.035
	
	# Gauge face
	var face = MeshInstance3D.new()
	face.name = gauge_name + "Face"
	var face_mesh = CylinderMesh.new()
	face_mesh.top_radius = gauge_radius
	face_mesh.bottom_radius = gauge_radius
	face_mesh.height = 0.005
	face_mesh.radial_segments = 32
	face.mesh = face_mesh
	face.position = pos
	face.rotation.x = PI / 2
	var face_mat = StandardMaterial3D.new()
	face_mat.albedo_color = Color(0.95, 0.95, 0.9)
	face.material_override = face_mat
	add_child(face)
	
	# Gauge rim
	var rim = MeshInstance3D.new()
	var rim_mesh = TorusMesh.new()
	rim_mesh.inner_radius = gauge_radius - 0.003
	rim_mesh.outer_radius = gauge_radius
	rim.mesh = rim_mesh
	rim.position = pos + Vector3(0, 0, 0.003)
	rim.rotation.x = PI / 2
	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = accent_color
	rim_mat.metallic = 0.7
	rim.material_override = rim_mat
	add_child(rim)
	
	# Needle pivot
	var needle_pivot = Node3D.new()
	needle_pivot.name = gauge_name + "NeedlePivot"
	needle_pivot.position = pos + Vector3(0, 0, 0.004)
	add_child(needle_pivot)
	
	# Needle
	var needle = MeshInstance3D.new()
	needle.name = gauge_name + "Needle"
	var needle_mesh = BoxMesh.new()
	needle_mesh.size = Vector3(0.003, 0.028, 0.001)
	needle.mesh = needle_mesh
	needle.position = Vector3(0, 0.012, 0)
	var needle_mat = StandardMaterial3D.new()
	needle_mat.albedo_color = Color(0.8, 0.1, 0.1)
	needle.material_override = needle_mat
	needle_pivot.add_child(needle)
	
	# Center cap
	var cap = MeshInstance3D.new()
	var cap_mesh = SphereMesh.new()
	cap_mesh.radius = 0.004
	cap_mesh.height = 0.008
	cap.mesh = cap_mesh
	cap.position = pos + Vector3(0, 0, 0.005)
	var cap_mat = StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.2, 0.2, 0.22)
	cap_mat.metallic = 0.8
	cap.material_override = cap_mat
	add_child(cap)
	
	return needle_pivot

## Public API
func get_pressure() -> float:
	return pressure_base + pressure_variation * sin(time * pressure_frequency * TAU)

func get_temperature() -> float:
	return temp_base + temp_variation * sin(time * temp_frequency * TAU)

func get_humidity() -> float:
	return humidity_base + humidity_variation * sin(time * humidity_frequency * TAU)

func set_alert_conditions(pressure_alert: float, temp_alert: float, humidity_alert: float) -> void:
	pressure_variation = pressure_alert
	temp_variation = temp_alert
	humidity_variation = humidity_alert


# ── RECORD, BUILT ────────────────────────────────────────────────────────────
# APPENDED. Every line below is gated behind `record != "instant"`, so the legacy lineage
# adds no node and allocates no material. Nothing here is random: the three traces are the
# three sine channels themselves, evaluated backwards over one span of paper.

# The card stands over the housing on two short posts, clear of the gauges (whose faces top
# out at y = 0.195). It is the SAME card at window / archive / margin, so those three share
# one bounding box; only the ink and the marks differ.
const REC_CARD_W := 0.33
const REC_CARD_H := 0.13
const REC_CY := 0.325
const REC_Z := 0.012
const REC_X0 := -0.155
const REC_X1 := 0.155
const REC_SAMPLES := 78
const REC_WINDOW_SAMPLES := 19
## One span of paper, in seconds. Chosen so the three channels draw visibly different
## period counts across the same width: 6.0 for pressure, 2.4 for temperature, 3.6 for
## humidity. That ratio IS the artifact's lesson, standing still.
const REC_SPAN := 120.0
## Each channel gets its own lane at its own span, which is what a multi-channel chart
## recorder does — a shared axis would flatten a 0.5 degree swing against a 5 hPa one and
## draw three straight lines.
const REC_LANE := 0.038
const REC_LANE_AMP := 0.015

const REC_PAPER := Color(0.93, 0.92, 0.86)
const REC_RULE := Color(0.70, 0.68, 0.62)
const REC_INK := Color(0.10, 0.10, 0.12)
const REC_BAND := Color(0.86, 0.45, 0.06)
const REC_MARK := Color(0.80, 0.10, 0.10)

var _rec_root: Node3D = null


## A map may set the rung with `#record:archive`. Only the record layer is rebuilt; the
## housing, gauges, needles, display panel, status lights and grille are never touched.
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
		push_warning("atmosphericmonitoring: unknown record rung '%s' — keeping '%s'" % [want, record])
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

	for s in [-1.0, 1.0]:
		_rec_box(Vector3(s * 0.145, 0.256, REC_Z), Vector3(0.010, 0.014, 0.014), Color(0.22, 0.24, 0.27))
	_rec_box(Vector3(0.0, REC_CY, REC_Z), Vector3(REC_CARD_W, REC_CARD_H, 0.002), REC_PAPER)

	if record == "margin":
		_rec_furniture()

	# One lane per channel, in the accent colour its own gauge rim already wears, so a trace
	# on the card and a needle on the housing are visibly the same instrument.
	_rec_lane(REC_CY + REC_LANE, pressure_frequency, Color(0.2, 0.6, 1.0), full, record == "margin")
	_rec_lane(REC_CY, temp_frequency, Color(1.0, 0.4, 0.2), full, false)
	_rec_lane(REC_CY - REC_LANE, humidity_frequency, Color(0.2, 0.8, 0.4), full, false)

	if full:
		_rec_spool()


## One channel's trace. `sin(tt * freq * TAU)` is exactly the term _process feeds its needle;
## only the normalisation differs, and it differs per lane on purpose (see REC_LANE above).
func _rec_lane(lane_y: float, freq: float, tint: Color, full: bool, ring_peak: bool) -> void:
	var step: float = (REC_X1 - REC_X0) / float(REC_SAMPLES - 1)
	var dt: float = REC_SPAN / float(REC_SAMPLES - 1)
	var first: int = 0 if full else REC_SAMPLES - REC_WINDOW_SAMPLES
	var peak_x: float = REC_X1
	var peak_y: float = lane_y
	var best: float = -1.0
	for j in range(first, REC_SAMPLES):
		# j counts from the OLD end; the pen is at the right, so sample j sits at
		# tt = -(span - j*dt) seconds — zero at the right-hand edge.
		var tt: float = -(REC_SPAN - float(j) * dt)
		var v: float = sin(tt * freq * TAU)
		var y: float = lane_y + v * REC_LANE_AMP
		_rec_box(Vector3(REC_X0 + float(j) * step, y, REC_Z + 0.0018),
			Vector3(0.0038, 0.0034, 0.0010), tint)
		if absf(v) > best:
			best = absf(v)
			peak_x = REC_X0 + float(j) * step
			peak_y = y
	if ring_peak:
		_rec_hand(peak_x, peak_y)


## WINDOW vs ARCHIVE: the run-off. A station switched on two minutes ago has none of this;
## one that has been logging has a wound spool of chart at the old end of the card, inside
## the existing silhouette so the inked rungs keep one bounding box between them.
func _rec_spool() -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.020
	cyl.bottom_radius = 0.020
	cyl.height = 0.026
	cyl.radial_segments = 20
	mi.mesh = cyl
	mi.position = Vector3(-0.150, REC_CY, REC_Z + 0.006)
	mi.rotation.x = PI / 2.0
	mi.material_override = _rec_mat(REC_PAPER.darkened(0.06))
	_rec_root.add_child(mi)
	_rec_box(Vector3(-0.150, REC_CY, REC_Z + 0.020), Vector3(0.006, 0.006, 0.006), Color(0.25, 0.26, 0.29))


## MARGIN, part one: the card printed to be read AGAINST. Rules between the lanes, time
## rules down the span, a tick scale along the foot, and a pair of normal-range rails per
## lane in the amber this project already uses for a threshold. The traces never leave the
## rails, which is the same thing the three status lights are saying by staying green.
func _rec_furniture() -> void:
	for s in [-1.0, 1.0]:
		_rec_box(Vector3(0.0, REC_CY + s * (REC_LANE * 0.5), REC_Z + 0.0012),
			Vector3(REC_CARD_W - 0.012, 0.0016, 0.0008), REC_RULE)
	for k in range(9):
		var x: float = lerpf(REC_X0, REC_X1, float(k) / 8.0)
		_rec_box(Vector3(x, REC_CY, REC_Z + 0.0012),
			Vector3(0.0016, REC_CARD_H - 0.012, 0.0008), REC_RULE)
		_rec_box(Vector3(x, REC_CY - REC_CARD_H * 0.5 - 0.006, REC_Z + 0.0016),
			Vector3(0.0030, 0.012, 0.0008), REC_INK)
	for lane in [REC_CY + REC_LANE, REC_CY, REC_CY - REC_LANE]:
		for s2 in [-1.0, 1.0]:
			_rec_box(Vector3(0.0, lane + s2 * 0.017, REC_Z + 0.0014),
				Vector3(REC_CARD_W - 0.012, 0.0035, 0.0008), REC_BAND)


## MARGIN, part two: the hand. Someone came back to the pressure lane, found its high and
## ringed it — the moment a chart stops being output and becomes evidence.
func _rec_hand(px: float, py: float) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.0090
	torus.outer_radius = 0.0125
	ring.mesh = torus
	ring.position = Vector3(px, py, REC_Z + 0.0030)
	ring.rotation.x = PI / 2.0
	ring.material_override = _rec_mat(REC_MARK)
	_rec_root.add_child(ring)
	var foot: float = REC_CY - REC_CARD_H * 0.5 + 0.010
	_rec_box(Vector3(px, foot, REC_Z + 0.0030), Vector3(0.052, 0.0022, 0.0008), REC_MARK)
	for s in [-1.0, 1.0]:
		_rec_box(Vector3(px + s * 0.026, foot + 0.006, REC_Z + 0.0030),
			Vector3(0.0022, 0.012, 0.0008), REC_MARK)
	for k in range(3):
		_rec_box(Vector3(px + 0.038, py + 0.009 - float(k) * 0.006, REC_Z + 0.0030),
			Vector3(0.020, 0.0020, 0.0008), REC_MARK)


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
