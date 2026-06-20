extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AlivenessMeter

## @identity
## name: "Soft vs rigid (the alive middle)"
## tier: applied
## lineage: A bench instrument that scans a sample and reads how alive it is by where it sits on
##   the rigid-to-fluid axis. A probe sweeps the axis; the needle peaks in the soft middle and
##   collapses to dead at either end. The sample shown jiggling exactly as much as the needle says.
## truth: "ALIVENESS = STRUCTURE THAT STILL FLOWS — IT PEAKS IN THE SOFT MIDDLE, DEAD AT BOTH ENDS"
## applications: viability assays, order-parameter meters, edge-of-chaos detectors, soft-robot
##   tuning rigs — a dial that measures the one quality both glass and water lack: life.

@export var sweep_rate: float = 0.22
@export var body_col: Color = Color(0.17, 0.18, 0.22)
@export var crystal_col: Color = Color(0.55, 0.80, 0.99)
@export var soft_col: Color = Color(0.95, 0.55, 0.62)
@export var fluid_col: Color = Color(0.40, 0.68, 0.92)
@export var needle_col: Color = Color(0.98, 0.40, 0.35)
@export var readout_col: Color = Color(0.55, 0.98, 0.65)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _axis_pos: float = 0.5        # 0 = fluid, 1 = crystal; probe sweeps this
var _needle: MeshInstance3D = null
var _probe: MeshInstance3D = null
var _sample: MeshInstance3D = null
var _readout: Label3D = null
var _gauge_c := Vector3(0.0, 0.62, 0.0)
var _gauge_r: float = 0.18
var _axis_y: float = 0.2
var _axis_w: float = 0.7


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("sweep_rate"):
		sweep_rate = clampf(float(config["sweep_rate"]), 0.1, 0.6)
	if config.has("soft_col"):
		soft_col = _parse_color(config["soft_col"], soft_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_needle = null
	_probe = null
	_sample = null
	_readout = null
	_build()


func _build() -> void:
	# Device base — a ~1m benchtop scanner.
	add_child(_box(Vector3(0.0, 0.06, 0.0), Vector3(1.0, 0.12, 0.45), _matte_mat(body_col, 0.8)))

	# The rigid<->fluid axis track along the front of the device.
	add_child(_box(Vector3(0.0, _axis_y, 0.18), Vector3(_axis_w, 0.015, 0.025), _steel_mat(Color(0.5, 0.5, 0.55))))
	# Coloured zone strips: fluid (left) / soft (mid) / crystal (right).
	add_child(_box(Vector3(-_axis_w * 0.33, _axis_y + 0.02, 0.18), Vector3(_axis_w * 0.34, 0.01, 0.02), _glow_mat(fluid_col, 0.5)))
	add_child(_box(Vector3(0.0, _axis_y + 0.02, 0.18), Vector3(_axis_w * 0.3, 0.012, 0.02), _glow_mat(soft_col, 0.8)))
	add_child(_box(Vector3(_axis_w * 0.33, _axis_y + 0.02, 0.18), Vector3(_axis_w * 0.34, 0.01, 0.02), _glow_mat(crystal_col, 0.5)))
	add_child(_billboard_label("FLUID", Vector3(-_axis_w * 0.45, _axis_y - 0.05, 0.18), 9, fluid_col))
	add_child(_billboard_label("SOFT", Vector3(0.0, _axis_y - 0.05, 0.18), 10, soft_col))
	add_child(_billboard_label("RIGID", Vector3(_axis_w * 0.45, _axis_y - 0.05, 0.18), 9, crystal_col))

	# The probe that rides the axis.
	_probe = _box(Vector3(0.0, _axis_y + 0.05, 0.18), Vector3(0.025, 0.07, 0.025), _glow_mat(needle_col, 0.8))
	add_child(_probe)

	# The sample under test — sits behind the gauge, jiggles per reading.
	add_child(_cylinder(Vector3(0.32, 0.16, 0.0), 0.08, 0.04, _matte_mat(body_col, 0.6)))
	_sample = _sphere(Vector3(0.32, 0.26, 0.0), 0.07, _glow_mat(soft_col, 0.6))
	add_child(_sample)

	# Gauge face + redline-free arc + needle (left).
	add_child(_cylinder(Vector3(-0.3 + _gauge_c.x * 0.0, _gauge_c.y, -0.02), _gauge_r, 0.03, _matte_mat(Color(0.92, 0.92, 0.95), 0.4)))
	_gauge_c = Vector3(-0.3, 0.62, 0.0)
	# Re-draw the dial at the gauge centre we actually use.
	add_child(_cylinder(_gauge_c + Vector3(0, 0, -0.02), _gauge_r, 0.03, _matte_mat(Color(0.92, 0.92, 0.95), 0.4)))
	# Peak marker at the top (max aliveness).
	add_child(_box(_gauge_c + Vector3(0.0, _gauge_r * 0.82, 0.0), Vector3(0.02, 0.05, 0.02), _glow_mat(readout_col, 0.9)))
	_needle = _box(_gauge_c + Vector3(0.0, _gauge_r * 0.4, 0.0), Vector3(0.012, _gauge_r * 0.8, 0.012), _matte_mat(Color(0.1, 0.1, 0.12), 0.4))
	add_child(_needle)

	# Readout panel.
	add_child(_box(Vector3(0.0, 0.96, 0.0), Vector3(0.5, 0.18, 0.02), _matte_mat(Color(0.08, 0.09, 0.12), 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(0.0, 0.96, 0.02), 14, readout_col)
	add_child(_readout)

	add_child(_billboard_label("ALIVENESS METER — PEAKS IN THE SOFT MIDDLE", Vector3(0.0, 1.2, 0.0), 18, label_col))


func _aliveness(axis: float) -> float:
	# Bell curve: 0 at either end, 1 at axis = 0.5 (the soft middle).
	return exp(-pow((axis - 0.5) / 0.22, 2.0))


func _state_name(axis: float) -> String:
	if axis > 0.72:
		return "RIGID"
	if axis < 0.28:
		return "FLUID"
	return "SOFT"


func _readout_text() -> String:
	var alive: float = _aliveness(_axis_pos)
	return "ALIVENESS SCAN\nstate: %s\nQ: %d%%" % [_state_name(_axis_pos), int(round(alive * 100.0))]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Probe sweeps the rigid<->fluid axis back and forth.
	_axis_pos = sin(_t * TAU * sweep_rate) * 0.5 + 0.5
	var alive: float = _aliveness(_axis_pos)

	# Probe rides the axis track.
	if _probe != null:
		_probe.position.x = lerpf(-_axis_w * 0.45, _axis_w * 0.45, _axis_pos)
		_probe.material_override = _glow_mat(_zone_color(_axis_pos), 0.8)

	# Needle: bottom (dead) at aliveness 0, top at aliveness 1.
	if _needle != null:
		var ang: float = lerpf(-2.094, 0.0, alive)   # -120deg (dead) .. 0deg (peak, straight up)
		_needle.transform = Transform3D(Basis(Vector3.FORWARD, ang), _gauge_c).translated_local(Vector3(0.0, _gauge_r * 0.4, 0.0))

	# Sample jiggles exactly as much as it is alive, and slumps/freezes at the ends.
	if _sample != null:
		_sample.material_override = _glow_mat(_zone_color(_axis_pos), 0.6)
		if _axis_pos > 0.8:
			_sample.scale = Vector3.ONE                    # frozen crystal
		elif _axis_pos < 0.2:
			_sample.scale = Vector3(1.4, 0.45, 1.4)        # slumped puddle
		else:
			var s: float = 1.0 + sin(_t * 5.0) * 0.18 * alive
			_sample.scale = Vector3(s, 2.0 - s, s)

	if _readout != null:
		_readout.text = _readout_text()


func _zone_color(axis: float) -> Color:
	if axis > 0.5:
		return soft_col.lerp(crystal_col, (axis - 0.5) * 2.0)
	return fluid_col.lerp(soft_col, axis * 2.0)
