extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PressureValveTool

## @identity
## name: "Breathing & the abject boundary"
## tier: applied
## lineage: A pressure valve regulating a breathing soft body. A gauge climbs as the sac swells
##   against a sealed valve; at the redline the valve releases and the body sighs back down. The
##   abject boundary made into a governed instrument.
## truth: "A BOUNDARY THAT HOLDS BY MOVING — HERE THE HOLDING IS METERED AND RELEASED ON CUE"
## applications: pressure-relief valves, ventilators, blood-pressure cuffs, pneumatic governors —
##   the swelling body kept from bursting by a rule.

@export var max_pressure: float = 1.0
@export var fill_rate: float = 0.45
@export var sac_col: Color = Color(0.92, 0.52, 0.58)
@export var gauge_col: Color = Color(0.30, 0.95, 0.55)
@export var redline_col: Color = Color(0.98, 0.35, 0.30)
@export var body_col: Color = Color(0.17, 0.18, 0.22)
@export var readout_col: Color = Color(0.98, 0.82, 0.50)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _pressure: float = 0.0
var _venting: bool = false
var _sac: MeshInstance3D = null
var _needle: MeshInstance3D = null
var _valve: MeshInstance3D = null
var _readout: Label3D = null
var _sac_pos := Vector3(-0.3, 0.5, 0.0)
var _sac_r: float = 0.16
var _gauge_c := Vector3(0.3, 0.6, 0.0)
var _gauge_r: float = 0.16


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("max_pressure"):
		max_pressure = clampf(float(config["max_pressure"]), 0.5, 2.0)
	if config.has("fill_rate"):
		fill_rate = clampf(float(config["fill_rate"]), 0.2, 1.0)
	if config.has("sac_col"):
		sac_col = _parse_color(config["sac_col"], sac_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sac = null
	_needle = null
	_valve = null
	_readout = null
	_pressure = 0.0
	_venting = false
	_build()


func _build() -> void:
	# Device base — a ~1m benchtop regulator.
	add_child(_box(Vector3(0.0, 0.06, 0.0), Vector3(1.0, 0.12, 0.45), _matte_mat(body_col, 0.8)))

	# The breathing soft body (left): a sac that swells with pressure.
	add_child(_cylinder(Vector3(_sac_pos.x, 0.16, 0.0), _sac_r * 1.05, 0.04, _matte_mat(body_col, 0.6)))
	_sac = _sphere(_sac_pos, _sac_r, _glow_mat(sac_col, 0.5))
	add_child(_sac)

	# Connecting pipe sac -> valve.
	add_child(_cylinder_between(_sac_pos + Vector3(_sac_r, 0, 0), Vector3(0.0, 0.5, 0.0), 0.025, _steel_mat(Color(0.5, 0.5, 0.55))))

	# The valve (centre): a cap that lifts when venting.
	_valve = _cylinder(Vector3(0.0, 0.62, 0.0), 0.05, 0.06, _steel_mat(Color(0.6, 0.6, 0.65)))
	add_child(_valve)
	add_child(_cylinder(Vector3(0.0, 0.5, 0.0), 0.04, 0.18, _steel_mat(Color(0.4, 0.4, 0.45))))

	# Gauge (right): dial face + needle + redline arc.
	add_child(_cylinder(Vector3(_gauge_c.x, _gauge_c.y, -0.02), _gauge_r, 0.03, _matte_mat(Color(0.92, 0.92, 0.95), 0.4)))
	# Redline marker at top of the dial.
	add_child(_box(Vector3(_gauge_c.x, _gauge_c.y + _gauge_r * 0.82, 0.0), Vector3(0.02, 0.05, 0.02), _glow_mat(redline_col, 0.9)))
	# Needle pivots from the gauge centre.
	_needle = _box(_gauge_c + Vector3(0.0, _gauge_r * 0.4, 0.0), Vector3(0.012, _gauge_r * 0.8, 0.012), _matte_mat(Color(0.1, 0.1, 0.12), 0.4))
	add_child(_needle)

	# Readout.
	add_child(_box(Vector3(0.0, 0.96, 0.0), Vector3(0.5, 0.16, 0.02), _matte_mat(Color(0.08, 0.09, 0.12), 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(0.0, 0.96, 0.02), 15, readout_col)
	add_child(_readout)

	add_child(_billboard_label("PRESSURE VALVE — SWELL, REDLINE, RELEASE", Vector3(0.0, 1.18, 0.0), 18, label_col))


func _readout_text() -> String:
	var pct: int = int(round(_pressure / max_pressure * 100.0))
	var state: String = "VENTING" if _venting else "filling"
	return "PRESSURE VALVE\nP: %d%%\nvalve: %s" % [pct, state]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Fill until redline, then vent until low, then refill — a regulated breath.
	if _venting:
		_pressure -= delta * fill_rate * 2.2
		if _pressure <= max_pressure * 0.15:
			_venting = false
	else:
		_pressure += delta * fill_rate
		if _pressure >= max_pressure:
			_pressure = max_pressure
			_venting = true
	var frac: float = clampf(_pressure / max_pressure, 0.0, 1.0)

	# Sac swells with pressure.
	if _sac != null:
		_sac.scale = Vector3.ONE * (1.0 + frac * 0.45)
	# Needle sweeps from ~-120deg (empty) to ~+120deg (redline).
	if _needle != null:
		var ang: float = lerpf(-2.094, 2.094, frac)   # -120..+120 degrees
		_needle.transform = Transform3D(Basis(Vector3.FORWARD, ang), _gauge_c).translated_local(Vector3(0.0, _gauge_r * 0.4, 0.0))
	# Valve cap lifts while venting.
	if _valve != null:
		var lift: float = 0.04 if _venting else 0.0
		_valve.position.y = 0.62 + lift + (sin(_t * 30.0) * 0.005 if _venting else 0.0)

	if _readout != null:
		_readout.text = _readout_text()
