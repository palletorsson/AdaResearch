extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name CollisionCarts

## @identity
## lineage: rigid-body collision made playable — p = mv conserved, with the velocities
##   exchanged by mass — the console rebuild of the old rigid-body sim, for the embodied
##   vectors-forces arc.
## essence: a heavy cart meets a light one; momentum before equals momentum after, but the
##   light cart leaps away fast while the heavy one barely slows. Slide the mass ratio and
##   watch who keeps the speed and who keeps the momentum.
## truth: in a collision momentum is shared but never spent — the books always balance; the
##   only question is how the world splits the velocity between the two of them.
##
## A ToyConsole: the readout lives on the monitor, the MASS RATIO slider drives the demo.
## DNA: mass_ratio 0..1 from a light striker to a heavy one (m_A relative to m_B).

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var mass_ratio: float = 0.6
@export var color_a: Color = Color(0.95, 0.55, 0.25)     # cart A (striker)
@export var color_b: Color = Color(0.40, 0.72, 0.96)     # cart B (struck)
@export var accent: Color = Color(0.55, 0.58, 0.64)      # track / velocity arrows
@export var complexity: int = 6


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("mass_ratio"): mass_ratio = clampf(float(config_data["mass_ratio"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "COLLISION CARTS", "slider": "MASS RATIO"}

func _param_get() -> float:
	return mass_ratio

func _param_set(v: float) -> void:
	mass_ratio = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("CollisionCartsRig")
	_rng.seed = hash(seed)

	var mA: float = lerpf(0.4, 2.6, mass_ratio)
	var mB: float = 1.0
	var u: float = 1.0                               # A's incoming speed; B at rest
	var vA: float = (mA - mB) / (mA + mB) * u        # elastic 1D collision outcomes
	var vB: float = 2.0 * mA / (mA + mB) * u
	var track := _steel_mat(accent)

	# two lanes: BEFORE (upper) and AFTER (lower)
	_lane(rig, 0.62, "before", mA, mB, u, 0.0, color_a, color_b, track)
	_lane(rig, 0.14, "after", mA, mB, vA, vB, color_a, color_b, track)

	set_readout("COLLISION\n\np = mv  conserved\nm_A:m_B = %.1f : 1" % mA, color_a.lerp(Color.WHITE, 0.25))
	_settle(rig)


func _lane(rig: Node3D, y: float, _label: String, mA: float, mB: float, vA: float, vB: float,
		ca: Color, cb: Color, track: Material) -> void:
	rig.add_child(_box(Vector3(0.0, y, 0.0), Vector3(2.0, 0.03, 0.34), track))    # rail
	var wa: float = 0.16 + 0.12 * mA
	var wb: float = 0.16 + 0.12 * mB
	var ax: float = -0.45
	var bx: float = 0.45
	# carts (width ∝ mass)
	rig.add_child(_box(Vector3(ax, y + 0.10, 0.0), Vector3(wa, 0.16, 0.22), _glow_mat(ca, 0.5)))
	rig.add_child(_box(Vector3(bx, y + 0.10, 0.0), Vector3(wb, 0.16, 0.22), _glow_mat(cb, 0.5)))
	# velocity arrows (sign + length)
	if absf(vA) > 0.02:
		var abase: Vector3 = Vector3(ax, y + 0.26, 0.0)
		rig.add_child(_arrow(abase, abase + Vector3(signf(vA) * (0.12 + absf(vA) * 0.4), 0.0, 0.0), 0.02, _glow_mat(ca, 1.6)))
	if absf(vB) > 0.02:
		var bbase: Vector3 = Vector3(bx, y + 0.26, 0.0)
		rig.add_child(_arrow(bbase, bbase + Vector3(signf(vB) * (0.12 + absf(vB) * 0.4), 0.0, 0.0), 0.02, _glow_mat(cb, 1.6)))
