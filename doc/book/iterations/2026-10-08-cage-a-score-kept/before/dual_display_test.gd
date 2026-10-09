extends Node3D

# dual_display_test.gd — the root of the two-pane comparison rig.
#
# THE SCENE HAD NO SCRIPT. Its root was a bare Node3D holding a spectrum pane at x = -2, a
# waveform pane at x = +2, a caption and a stray demo camera. That is why this artifact
# showed up in the corpus with zero exports: not because there is nothing to vary, but
# because nobody ever gave it somewhere to put a variation. Nothing that was in the scene
# has changed — the two instanced panes, the caption and the camera are untouched, and at
# the default rung this script adds no node at all.

# @identity
# essence: two panes of one signal — magnitude against frequency on the left, amplitude against time on the right
# desire: to see the same sound twice, in the two ways an instrument can hold it
# critical_parameter: record — whether anything the panes showed survives being shown
# triggers: both panes redraw from the master bus every frame; record decides whether any of it is kept on the wall
# emerges: a rig that keeps nothing argues that a signal is an event; a wall of printouts argues that it is a fact
# needs: two live panes [present]; somewhere for the output to go [record >= window]
# relationships: shares the `record` axis word for word with [[seismograph]], [[multimeter]], [[atmosphericmonitoring]] and [[holographicdisplay]]; the screen-medium member of that family
# truth: A screen is the only instrument that can show you everything and keep nothing. Both panes go blank the moment the room goes quiet, and nothing in the rig can tell you they were ever on.

# ── RECORD ───────────────────────────────────────────────────────────────────
# THE AXIS, shared word for word with the four needle instruments in this tier: what the rig
# KEEPS. This is the member where the question bites hardest, because a screen has no
# needle to leave a mark and no paper to leave it on — it is pure present tense. The record,
# if there is one, has to be a physically separate object: the printout.
#
#   instant   two live panes, and nothing else. everything shown is already gone.  ← legacy
#   window    one sheet pinned between them — the last run, kept
#   archive   the board full: three spectra over three waveforms, the session kept
#   margin    the archive, READ: a reviewed rail, two ringed sheets, a hand's bracket
#
# The board hangs in the gap the rig already leaves between its two panes (they occupy
# x < -1 and x > 1), so every rung sits inside the existing silhouette and the capture
# camera frames all four identically.
#
# NOT TOUCHED: the panes. The spectrum analyser, the waveform mesh, their viewports, their
# update rates and the caption all run exactly as before. The printouts are drawn from
# WaveformDisplay's own no-audio signal — the one thing on this rig that is defined when
# the room is silent — so a sheet on the wall cannot claim a signal the panes never had.
@export_enum("instant", "window", "archive", "margin") var record: String = "instant"

const REC_BOARD_W := 1.75
const REC_BOARD_H := 1.00
const REC_BOARD_Y := 1.00
const REC_BOARD_Z := 0.25
const REC_SHEET_W := 0.46
const REC_SHEET_H := 0.34
const REC_COLS := [-0.52, 0.0, 0.52]
const REC_ROWS := [1.21, 0.79]
const REC_DOTS := 26
const REC_BARS := 18

const REC_CORK := Color(0.28, 0.24, 0.20)
const REC_PAPER := Color(0.93, 0.92, 0.86)
const REC_RULE := Color(0.70, 0.68, 0.62)
const REC_INK := Color(0.10, 0.10, 0.12)
const REC_BAND := Color(0.86, 0.45, 0.06)
const REC_MARK := Color(0.80, 0.10, 0.10)

var _rec_root: Node3D = null


func _ready() -> void:
	_build_record()


## A map may set the rung with `#record:archive`. Only the record layer is rebuilt; the two
## instanced panes and the caption are never touched.
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
		push_warning("dual_display_test: unknown record rung '%s' — keeping '%s'" % [want, record])
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

	# The board, and the four clips that say it is a board and not a wall.
	_rec_box(Vector3(0.0, REC_BOARD_Y, REC_BOARD_Z),
		Vector3(REC_BOARD_W, REC_BOARD_H, 0.03), REC_CORK)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			_rec_box(Vector3(sx * (REC_BOARD_W * 0.5 - 0.045),
				REC_BOARD_Y + sy * (REC_BOARD_H * 0.5 - 0.045), REC_BOARD_Z + 0.020),
				Vector3(0.05, 0.05, 0.012), Color(0.42, 0.44, 0.47))

	if record == "window":
		# One sheet: the last run, kept. Nothing before it survived.
		_rec_sheet(0.0, REC_BOARD_Y, false, 5.2, false)
		return

	# The board full. Top row: three spectra. Bottom row: three waveforms. Each from a
	# different moment of the same signal, which is what a session of printouts looks like.
	var moment: float = 0.0
	for r in range(2):
		for c in range(3):
			var marked: bool = record == "margin" and r == 0 and c == 2
			_rec_sheet(float(REC_COLS[c]), float(REC_ROWS[r]), r == 0, 1.4 + moment * 3.1, marked)
			moment += 1.0

	if record == "margin":
		_rec_hand()


## One printout. `spectrum` draws the left pane's subject (magnitude per band, as bars);
## otherwise the right pane's (amplitude against time, as a traced line). Both come from the
## formulas WaveformDisplay._generate_test_waveform runs when no audio is playing — the rig's
## own definition of what it is looking at in a silent room, which is the room this is.
func _rec_sheet(cx: float, cy: float, spectrum: bool, moment: float, marked: bool) -> void:
	var z: float = REC_BOARD_Z + 0.018
	_rec_box(Vector3(cx, cy, z), Vector3(REC_SHEET_W, REC_SHEET_H, 0.004), REC_PAPER)
	_rec_box(Vector3(cx, cy + REC_SHEET_H * 0.5 - 0.030, z + 0.003),
		Vector3(REC_SHEET_W - 0.06, 0.012, 0.002), REC_RULE)

	var half_w: float = REC_SHEET_W * 0.5 - 0.045
	var half_h: float = REC_SHEET_H * 0.5 - 0.075

	if spectrum:
		for b in range(REC_BARS):
			var f: float = float(b) / float(REC_BARS - 1)
			var mag: float = _rec_magnitude(f, moment)
			var h: float = maxf(mag * half_h * 2.0, 0.006)
			_rec_box(Vector3(cx - half_w + f * half_w * 2.0, cy - half_h + h * 0.5 - 0.02, z + 0.003),
				Vector3(0.014, h, 0.002), REC_INK)
	else:
		for i in range(REC_DOTS):
			var tp: float = float(i) / float(REC_DOTS - 1)
			var v: float = _rec_wave(tp, moment)
			_rec_box(Vector3(cx - half_w + tp * half_w * 2.0, cy - 0.02 + v * half_h, z + 0.003),
				Vector3(0.020, 0.014, 0.002), REC_INK)

	if marked:
		# The reviewed sheet: an amber border, and rules someone laid over the trace.
		for sy in [-1.0, 1.0]:
			_rec_box(Vector3(cx, cy + sy * REC_SHEET_H * 0.5, z + 0.006),
				Vector3(REC_SHEET_W + 0.02, 0.016, 0.002), REC_BAND)
		for sx in [-1.0, 1.0]:
			_rec_box(Vector3(cx + sx * REC_SHEET_W * 0.5, cy, z + 0.006),
				Vector3(0.016, REC_SHEET_H + 0.02, 0.002), REC_BAND)
		for k in range(4):
			_rec_box(Vector3(cx, cy - 0.02 + lerpf(-half_h, half_h, float(k) / 3.0), z + 0.005),
				Vector3(REC_SHEET_W - 0.07, 0.004, 0.002), REC_RULE)


## MARGIN: the hand. A rail across the head of the board saying the session has been gone
## through, a ring and a bracket on the sheet that mattered, and three dashes beside it.
func _rec_hand() -> void:
	var z: float = REC_BOARD_Z + 0.026
	_rec_box(Vector3(0.0, REC_BOARD_Y + REC_BOARD_H * 0.5 - 0.030, z),
		Vector3(REC_BOARD_W - 0.14, 0.030, 0.004), REC_BAND)
	var px: float = float(REC_COLS[2])
	var py: float = float(REC_ROWS[0]) - 0.04
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.075
	torus.outer_radius = 0.092
	ring.mesh = torus
	ring.position = Vector3(px, py, z + 0.004)
	ring.rotation.x = PI / 2.0
	ring.material_override = _rec_mat(REC_MARK)
	_rec_root.add_child(ring)
	_rec_box(Vector3(px, py - 0.145, z + 0.004), Vector3(0.32, 0.012, 0.004), REC_MARK)
	for s in [-1.0, 1.0]:
		_rec_box(Vector3(px + s * 0.16, py - 0.125, z + 0.004), Vector3(0.012, 0.052, 0.004), REC_MARK)
	for k in range(3):
		_rec_box(Vector3(px - 0.30, py + 0.05 - float(k) * 0.035, z + 0.004),
			Vector3(0.11, 0.010, 0.004), REC_MARK)


## WaveformDisplay._generate_test_waveform, normalised to [-1, 1]: the same band index, the
## same magnitude term and the same four-half-cycle phase ramp, at a chosen past moment.
func _rec_wave(time_position: float, moment: float) -> float:
	var sine_phase: float = time_position * PI * 4.0
	return sin(sine_phase + moment) * (0.3 + _rec_magnitude(time_position, moment) * 0.7)


func _rec_magnitude(time_position: float, moment: float) -> float:
	var band: int = int((time_position + moment * 0.3) * 32.0) % 32
	return (sin(moment * 2.0 + float(band) * 0.2) + 1.0) * 0.5


func _rec_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	return m


func _rec_box(center: Vector3, size: Vector3, c: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _rec_mat(c)
	mi.position = center
	_rec_root.add_child(mi)
