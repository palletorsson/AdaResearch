extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EthicsToy

## @identity
## name: Ethics Toy
## truth: There is no neutral design; every choice leaves someone out.
##
## Ethical design after incompleteness — SMALL, held (~0.4m, no base).
## A "no neutral choice" token: a balance scale that can NEVER level. Whichever
## way it tips, one pan rises (someone excluded) and the other drops. A small
## ✓ / ✗ flickers over the pans. The amber arm signals constructive answerability.

@export var tip_period: float = 3.4        # seconds for a full tip-to-tip swing
@export var max_tilt_deg: float = 17.0      # the scale leans this far each way

const COOL_WHITE := Color(0.90, 0.92, 0.97)
const SLATE := Color(0.36, 0.40, 0.50)
const PURPLE := Color(0.58, 0.42, 0.92)
const AMBER := Color(0.98, 0.72, 0.28)
const TEAL := Color(0.30, 0.82, 0.78)
const EXCLUDE_RED := Color(0.95, 0.34, 0.28)

var _beam: Node3D = null
var _pan_l: MeshInstance3D = null
var _pan_r: MeshInstance3D = null
var _check_l: Label3D = null
var _check_r: Label3D = null
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# Central column (slate steel) — the framing of the decision.
	add_child(_cylinder(Vector3(0, 0.0, 0), 0.018, 0.30, _steel_mat(SLATE)))
	# Fulcrum knot (purple wireframe node) where the beam pivots.
	add_child(_sphere(Vector3(0, 0.16, 0), 0.026, _glow_mat(PURPLE, 1.6)))

	# Pivoting beam — amber, the answerable arm that never settles.
	_beam = Node3D.new()
	_beam.position = Vector3(0, 0.16, 0)
	add_child(_beam)
	var beam_mat: StandardMaterial3D = _glow_mat(AMBER, 1.7)
	_beam.add_child(_box(Vector3(0, 0, 0), Vector3(0.34, 0.012, 0.012), beam_mat))

	# Two hangers + pans on the beam ends.
	var hang_mat: StandardMaterial3D = _matte_mat(SLATE, 0.6, 0.4)
	var pan_mat_l: StandardMaterial3D = _glass_mat(TEAL, 0.5)
	var pan_mat_r: StandardMaterial3D = _glass_mat(EXCLUDE_RED, 0.5)

	_beam.add_child(_cylinder_between(Vector3(-0.16, 0, 0), Vector3(-0.16, -0.07, 0), 0.004, hang_mat))
	_pan_l = _cylinder(Vector3(-0.16, -0.085, 0), 0.05, 0.008, pan_mat_l)
	_beam.add_child(_pan_l)

	_beam.add_child(_cylinder_between(Vector3(0.16, 0, 0), Vector3(0.16, -0.07, 0), 0.004, hang_mat))
	_pan_r = _cylinder(Vector3(0.16, -0.085, 0), 0.05, 0.008, pan_mat_r)
	_beam.add_child(_pan_r)

	# A small weight in each pan (the populations being weighed).
	_beam.add_child(_sphere(Vector3(-0.16, -0.07, 0), 0.018, _glow_mat(TEAL, 1.4)))
	_beam.add_child(_sphere(Vector3(0.16, -0.07, 0), 0.018, _glow_mat(EXCLUDE_RED, 1.4)))

	# ✓ / ✗ markers that flicker over the pans — included vs left out.
	_check_l = _billboard_label("✓", Vector3(-0.16, 0.04, 0), 26, TEAL)
	_beam.add_child(_check_l)
	_check_r = _billboard_label("✗", Vector3(0.16, 0.04, 0), 26, EXCLUDE_RED)
	_beam.add_child(_check_r)

	# A purple "level" reference line the beam can never align to.
	add_child(_box(Vector3(0, 0.16, 0), Vector3(0.40, 0.003, 0.003), _glow_mat(PURPLE, 0.8)))

	# Billboard title.
	add_child(_billboard_label("NO NEUTRAL CHOICE", Vector3(0, 0.34, 0), 28, COOL_WHITE))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# The beam swings tip-to-tip and NEVER rests at level (sin never gives 0
	# at the dwell points — it lingers tilted at each extreme).
	var phase: float = _t * TAU / tip_period
	var swing: float = sin(phase)
	# bias the dwell toward the extremes so it visibly refuses to settle level
	var shaped: float = signf(swing) * pow(absf(swing), 0.6)
	var tilt: float = deg_to_rad(max_tilt_deg) * shaped
	if _beam != null:
		_beam.rotation.z = tilt

	# Whichever pan is UP = excluded; flicker its ✗ brighter, dim the other ✓.
	var left_up: bool = tilt > 0.0
	var flick: float = 0.5 + 0.5 * sin(_t * 12.0)
	if _check_l != null and _check_r != null:
		if left_up:
			_check_l.text = "✗"
			_check_l.modulate = EXCLUDE_RED * (0.7 + 0.6 * flick)
			_check_r.text = "✓"
			_check_r.modulate = TEAL
		else:
			_check_l.text = "✓"
			_check_l.modulate = TEAL
			_check_r.text = "✗"
			_check_r.modulate = EXCLUDE_RED * (0.7 + 0.6 * flick)

	# Idle bob.
	position.y = sin(Time.get_ticks_msec() * 0.0012) * 0.004
