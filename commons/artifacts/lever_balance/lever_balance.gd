extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name LeverBalance

## @identity
## lineage: the law of the lever made playable — τ = F · d, balanced when F₁d₁ = F₂d₂ — the
##   seesaw, the oldest machine. The clean toy the old balance-puzzle / scale examples never
##   became, for the embodied vectors-forces arc.
## essence: a beam on a fulcrum with a fixed weight on one arm; slide the load along the
##   other arm and you change its TORQUE — force times distance — not its weight. Far out,
##   a small load outweighs a big one near in; the beam tips toward the bigger torque and
##   sits level only when the two are equal.
## truth: a lever trades force for distance and never gets something for nothing — what it
##   multiplies in force it pays for in the distance the far end must travel.
##
## A ToyConsole: the LOAD slider slides the right weight along the arm; the demo is the
## tilting beam with both torques. DNA: load 0..1 — the lever tips, then balances, then tips.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var load: float = 0.5
@export var beam_color: Color = Color(0.74, 0.58, 0.36)    # the beam
@export var fulcrum_color: Color = Color(0.40, 0.42, 0.48) # the fulcrum
@export var effort_color: Color = Color(0.45, 0.72, 0.98)  # the fixed effort weight
@export var load_color: Color = Color(0.98, 0.62, 0.30)    # the sliding load
@export var torque_color: Color = Color(0.60, 0.95, 0.60)  # the torque arcs / forces

const FULCRUM_Y := 0.9
const D_LEFT := 1.0                                        # fixed effort distance
const F_LEFT := 1.0
const F_RIGHT := 1.0


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("load"): load = clampf(float(config_data["load"]), 0.0, 1.0)
	apply_base_config(config_data)
	beam_color = _parse_color(config_data.get("beam_color", beam_color), beam_color)
	load_color = _parse_color(config_data.get("load_color", load_color), load_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "LEVER", "slider": "LOAD"}

func _param_get() -> float:
	return load

func _param_set(v: float) -> void:
	load = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("LeverRig")
	var d_right: float = lerpf(0.4, 1.6, load)
	var tau_l: float = F_LEFT * D_LEFT
	var tau_r: float = F_RIGHT * d_right
	var tilt: float = clampf(-(tau_r - tau_l) * 0.42, -0.5, 0.5)   # right-heavy → right dips
	var balanced: bool = absf(tau_r - tau_l) < 0.06
	var pivot := Vector3(0.0, FULCRUM_Y, 0.0)
	var dir := Vector3(cos(tilt), sin(tilt), 0.0)                  # beam's +X (right) direction

	# --- fulcrum (a wedge) + base ----------------------------------------------
	var fmat := _steel_mat(fulcrum_color)
	rig.add_child(_box(Vector3(0, 0.06, 0), Vector3(0.7, 0.12, 0.4), _steel_mat(fulcrum_color.darkened(0.3))))
	var wedge := MeshInstance3D.new()
	var pm := PrismMesh.new(); pm.size = Vector3(0.5, FULCRUM_Y - 0.12, 0.3)
	wedge.mesh = pm; wedge.material_override = fmat; wedge.position = Vector3(0, (FULCRUM_Y - 0.12) * 0.5 + 0.12, 0)
	rig.add_child(wedge)

	# --- the beam ---------------------------------------------------------------
	var beam := _box(pivot, Vector3(3.4, 0.10, 0.22), _glow_mat(beam_color, 0.4))
	beam.rotation.z = tilt
	rig.add_child(beam)
	rig.add_child(_sphere(pivot, 0.07, fmat))

	# --- the two weights, hung at their distances -------------------------------
	var left_pos: Vector3 = pivot - dir * D_LEFT
	var right_pos: Vector3 = pivot + dir * d_right
	_weight(rig, left_pos, F_LEFT, effort_color)
	_weight(rig, right_pos, F_RIGHT, load_color)

	# --- the distance arms (horizontal, fulcrum → each weight's column) ----------
	var dim := _glow_mat(Color(0.6, 0.62, 0.68), 0.45)
	rig.add_child(_dashed(Vector3(left_pos.x, FULCRUM_Y - 0.55, 0), Vector3(0, FULCRUM_Y - 0.55, 0), 0.007, dim))
	rig.add_child(_dashed(Vector3(0, FULCRUM_Y - 0.55, 0), Vector3(right_pos.x, FULCRUM_Y - 0.55, 0), 0.007, dim))

	# --- readout ----------------------------------------------------------------
	var verdict: String = "BALANCED" if balanced else ("TIPS RIGHT" if tau_r > tau_l else "TIPS LEFT")
	set_readout("LEVER  τ = F·d\n\nτ_L = %.2f\nτ_R = %.2f\nMA = %.2f\n%s" % [tau_l, tau_r, D_LEFT / d_right, verdict],
		torque_color.lerp(Color.WHITE, 0.25) if balanced else load_color.lerp(Color.WHITE, 0.2))
	_settle(rig)


# a hanging weight + its downward force arrow (length ∝ force)
func _weight(rig: Node3D, at: Vector3, force: float, col: Color) -> void:
	var hang: Vector3 = at - Vector3(0, 0.22, 0)
	rig.add_child(_cylinder_between(at, hang, 0.01, _steel_mat(Color(0.5, 0.52, 0.56))))
	rig.add_child(_box(hang - Vector3(0, 0.12, 0), Vector3(0.24, 0.24, 0.24) * (0.7 + force * 0.3), _glow_mat(col, 0.6)))
	rig.add_child(_arrow(hang, hang - Vector3(0, force * 0.5, 0), 0.022, _glow_mat(col.lerp(torque_color, 0.3), 1.4)))
