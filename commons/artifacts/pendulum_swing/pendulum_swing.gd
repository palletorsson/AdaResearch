extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name PendulumSwing

## @identity
## lineage: the pendulum made playable — T = 2π√(L/g), restoring force = mg sin θ — gravity
##   and a string, the oldest clock. The clean toy the old swinging-pendulum example never
##   became, for the embodied vectors-forces arc.
## essence: a bob hangs at an angle; gravity pulls straight down, the string answers with
##   tension along its length, and what's left over — the part of gravity ALONG the swing,
##   mg sin θ — is the restoring force that hauls it back. Lengthen the string and the swing
##   slows: the period grows with the square root of the length, nothing else.
## truth: a pendulum keeps time because the restoring force is (almost) proportional to how
##   far it's pulled — the signature of everything that swings.
##
## A ToyConsole: the LENGTH slider sets L; the demo is the bob at amplitude with its weight,
## tension and restoring vectors + the swept arc. DNA: length 0..1 → period ∝ √L.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var length: float = 0.5
@export var bob_color: Color = Color(0.45, 0.72, 0.98)     # the bob
@export var string_color: Color = Color(0.66, 0.68, 0.72)  # string / pivot
@export var grav_color: Color = Color(0.95, 0.40, 0.38)    # weight mg
@export var tension_color: Color = Color(0.55, 0.95, 0.58) # tension
@export var restore_color: Color = Color(0.98, 0.72, 0.32) # restoring mg sin θ

const PIVOT_Y := 1.55
const AMP := 0.56                                          # swing amplitude (rad, ~32°)


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("length"): length = clampf(float(config_data["length"]), 0.0, 1.0)
	apply_base_config(config_data)
	bob_color = _parse_color(config_data.get("bob_color", bob_color), bob_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "PENDULUM", "slider": "LENGTH"}

func _param_get() -> float:
	return length

func _param_set(v: float) -> void:
	length = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("PendulumRig")
	var L: float = lerpf(0.6, 1.45, length)
	var g: float = 9.8
	var period: float = TAU * sqrt(L / g)
	var pivot := Vector3(0.0, PIVOT_Y, 0.0)

	# --- pivot bracket ----------------------------------------------------------
	rig.add_child(_box(Vector3(0, PIVOT_Y + 0.04, 0), Vector3(0.4, 0.06, 0.12), _steel_mat(string_color.darkened(0.2))))
	rig.add_child(_sphere(pivot, 0.045, _steel_mat(string_color)))

	# --- the swept arc (where it swings between the two amplitudes) --------------
	var arc_mat := _glow_mat(Color(0.5, 0.54, 0.62), 0.4)
	var steps := 14
	for i in range(steps):
		var a0: float = lerpf(-AMP, AMP, float(i) / steps)
		var a1: float = lerpf(-AMP, AMP, float(i + 1) / steps)
		rig.add_child(_cylinder_between(pivot + _swing(a0, L), pivot + _swing(a1, L), 0.006, arc_mat))

	# --- the bob at amplitude ---------------------------------------------------
	var bob: Vector3 = pivot + _swing(AMP, L)
	rig.add_child(_cylinder_between(pivot, bob, 0.012, _steel_mat(string_color)))      # string
	rig.add_child(_sphere(bob, 0.13, _glow_mat(bob_color, 0.7)))

	# --- the force triangle at the bob ------------------------------------------
	var s := 0.5
	var down := Vector3(0, -1, 0)
	var to_pivot: Vector3 = (pivot - bob).normalized()
	# tangent (direction of the restoring pull, back toward the bottom)
	var tangent := Vector3(to_pivot.y, -to_pivot.x, 0.0)
	if tangent.x > 0: tangent = -tangent                       # point back toward vertical
	var mgsin: float = sin(AMP)
	var mgcos: float = cos(AMP)
	rig.add_child(_arrow(bob, bob + down * s, 0.024, _glow_mat(grav_color, 1.5)))                  # weight mg
	rig.add_child(_arrow(bob, bob + to_pivot * mgcos * s, 0.024, _glow_mat(tension_color, 1.5)))    # tension = mg cos θ
	rig.add_child(_arrow(bob, bob + tangent * mgsin * s, 0.026, _glow_mat(restore_color, 1.7)))     # restoring = mg sin θ
	# dashed decomposition of gravity into the two components
	rig.add_child(_dashed(bob + down * s, bob + to_pivot * mgcos * s, 0.006, _glow_mat(Color(0.6, 0.62, 0.68), 0.4)))

	# --- readout ----------------------------------------------------------------
	set_readout("PENDULUM\n\nL = %.2f m\nT = 2π√(L/g)\n   = %.2f s\nrestore = mg sin θ" % [L, period],
		bob_color.lerp(Color.WHITE, 0.3))
	_settle(rig)


# swing offset from the pivot at angle a (from vertical), length L
func _swing(a: float, L: float) -> Vector3:
	return Vector3(sin(a) * L, -cos(a) * L, 0.0)
