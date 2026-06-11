extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name SpringBob

## @identity
## lineage: Hooke's law made playable — F = −k x, T = 2π√(m/k) — the spring, the other great
##   timekeeper. The clean toy the old spring-connection / mass-spring-damper examples never
##   became, for the embodied vectors-forces arc.
## essence: a mass hangs on a coil; the spring pulls back exactly as hard as it's stretched
##   (−k x), and at rest that pull balances the weight. Stiffen the spring and it barely
##   gives — and it ticks faster, because the period shrinks with the root of the stiffness.
## truth: a spring is honest — it returns force in exact proportion to displacement, and that
##   linearity is why a mass on a spring keeps perfect time.
##
## A ToyConsole: the STIFFNESS slider sets k; the demo is the coil + bob with the spring
## force and weight (balanced at rest) and the stretch x. DNA: stiffness 0..1 → period ∝ 1/√k.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var stiffness: float = 0.45
@export var coil_color: Color = Color(0.66, 0.70, 0.76)    # the spring
@export var bob_color: Color = Color(0.72, 0.52, 0.95)     # the mass
@export var spring_color: Color = Color(0.55, 0.95, 0.58)  # spring force +kx
@export var weight_color: Color = Color(0.95, 0.40, 0.38)  # weight mg
@export var guide_color: Color = Color(0.58, 0.62, 0.70)   # the stretch x

const ANCHOR_Y := 1.6
const NATURAL := 0.45                                      # unstretched coil length


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("stiffness"): stiffness = clampf(float(config_data["stiffness"]), 0.0, 1.0)
	apply_base_config(config_data)
	coil_color = _parse_color(config_data.get("coil_color", coil_color), coil_color)
	bob_color = _parse_color(config_data.get("bob_color", bob_color), bob_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "SPRING", "slider": "STIFFNESS"}

func _param_get() -> float:
	return stiffness

func _param_set(v: float) -> void:
	stiffness = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("SpringBobRig")
	var m: float = 1.0
	var g: float = 9.8
	var k: float = lerpf(8.0, 40.0, stiffness)
	var x: float = m * g / k                            # equilibrium stretch (stiffer → less)
	var period: float = TAU * sqrt(m / k)
	var anchor := Vector3(0.0, ANCHOR_Y, 0.0)
	var rest_y: float = ANCHOR_Y - NATURAL              # where the bob hangs unstretched
	var bob := Vector3(0.0, rest_y - x, 0.0)            # actual hanging position

	# --- anchor + ceiling -------------------------------------------------------
	rig.add_child(_box(Vector3(0, ANCHOR_Y + 0.04, 0), Vector3(0.5, 0.06, 0.3), _steel_mat(coil_color.darkened(0.3))))

	# --- the coil (a helix from anchor to the bob, spacing out as it stretches) --
	var coils := 7
	var n := coils * 8
	var top := anchor
	var bottom := bob + Vector3(0, 0.13, 0)
	var prev := top
	var coil_mat := _steel_mat(coil_color)
	for i in range(1, n + 1):
		var t: float = float(i) / float(n)
		var ang: float = t * float(coils) * TAU
		var r := 0.13
		var p := Vector3(cos(ang) * r, lerpf(top.y, bottom.y, t), sin(ang) * r)
		rig.add_child(_cylinder_between(prev, p, 0.018, coil_mat))
		prev = p

	# --- the mass ---------------------------------------------------------------
	rig.add_child(_box(bob, Vector3(0.28, 0.26, 0.28), _glow_mat(bob_color, 0.6)))

	# --- the stretch x (from the natural-length line down to the bob) -----------
	rig.add_child(_dashed(Vector3(0.4, rest_y, 0.0), Vector3(0.4, bob.y + 0.13, 0.0), 0.008, _glow_mat(guide_color, 0.7)))
	rig.add_child(_cylinder_between(Vector3(0.32, rest_y, 0.0), Vector3(0.48, rest_y, 0.0), 0.006, _glow_mat(guide_color, 0.5)))

	# --- the two balanced forces ------------------------------------------------
	var s := 0.5
	rig.add_child(_arrow(bob, bob + Vector3(0, -1, 0) * s, 0.026, _glow_mat(weight_color, 1.5)))      # weight mg (down)
	rig.add_child(_arrow(bob, bob + Vector3(0, 1, 0) * s, 0.026, _glow_mat(spring_color, 1.6)))       # spring +kx (up)

	# --- readout ----------------------------------------------------------------
	set_readout("SPRING\n\nF = −k x\nk = %.0f   x = %.2f\nT = 2π√(m/k)\n   = %.2f s" % [k, x, period],
		bob_color.lerp(Color.WHITE, 0.35))
	_settle(rig)
