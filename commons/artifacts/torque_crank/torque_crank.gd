extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name TorqueCrank

## @identity
## lineage: the cross product made playable — τ = r × F = |r||F|sinθ — the second
##   half of the operations pair (with dot_aligner) for the embodied vectors-forces arc.
## essence: push a lever arm off-axis; the perpendicular torque it produces spins a
##   flywheel. Force along the arm does nothing; force across it spins hardest.
## truth: the cross product is what's left over when two directions refuse to align —
##   a third axis, perpendicular to both, that turns the world.
##
## A ToyConsole: the readout lives on the monitor, the LEVERAGE slider drives the demo.
## DNA: leverage 0..1 is the angle between arm r and push F (0 = along → zero torque,
## 1 = perpendicular → max). seed jitters the arm bearing.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var leverage: float = 0.78
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # steel rig
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # the arm vector r
@export var force_color: Color = Color(0.98, 0.58, 0.30) # the push F
@export var accent: Color = Color(0.98, 0.82, 0.32)      # the torque axis / flywheel
@export var complexity: int = 6


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("leverage"): leverage = clampf(float(config_data["leverage"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	force_color = _parse_color(config_data.get("force_color", force_color), force_color)
	accent = _parse_color(config_data.get("accent", accent), accent)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "TORQUE CRANK", "slider": "LEVERAGE"}

func _param_get() -> float:
	return leverage

func _param_set(v: float) -> void:
	leverage = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("TorqueCrankRig")
	_rng.seed = hash(seed)

	# --- the physics ------------------------------------------------------------
	var bearing: float = deg_to_rad(_rng.randf_range(-22.0, 22.0))
	var arm_len: float = 0.82
	var hub_y: float = 0.92
	var hub: Vector3 = Vector3(0.0, hub_y, 0.0)
	var r_dir: Vector3 = Vector3(cos(bearing), 0.0, sin(bearing)).normalized()   # vector r
	var arm_tip: Vector3 = hub + r_dir * arm_len
	var phi: float = leverage * (PI * 0.5)                                        # angle of F from the arm
	var f_dir: Vector3 = r_dir.rotated(Vector3.UP, phi).normalized()             # vector F
	var torque_vec: Vector3 = r_dir.cross(f_dir)                                  # τ = r × F
	var torque_mag: float = clampf(torque_vec.length(), 0.0, 1.0)                # = sin(phi)
	var tau_axis: Vector3 = (Vector3.UP if torque_vec.y >= 0.0 else Vector3.DOWN)
	var theta_deg: float = rad_to_deg(phi)
	var spin_angle: float = torque_mag * deg_to_rad(48.0)

	var steel := _steel_mat(color_a)

	# --- rig: pedestal + axle ---------------------------------------------------
	rig.add_child(_cylinder(Vector3(0.0, 0.22, 0.0), 0.30, 0.44, steel))
	rig.add_child(_cylinder(Vector3(0.0, hub_y * 0.5 + 0.02, 0.0), 0.05, hub_y, steel))   # axle
	rig.add_child(_sphere(hub, 0.10, steel))

	# --- flywheel ---------------------------------------------------------------
	var wheel := Node3D.new()
	wheel.position = hub
	wheel.rotation.y = spin_angle
	rig.add_child(wheel)
	wheel.add_child(_torus(Vector3.ZERO, 0.40, 0.05, _glow_mat(accent, 0.5 + torque_mag * 2.6)))
	var spokes: int = clampi(complexity, 4, 8)
	for i in range(spokes):
		var ang: float = TAU * float(i) / float(spokes)
		wheel.add_child(_cylinder_between(Vector3.ZERO, Vector3(cos(ang), 0.0, sin(ang)) * 0.39, 0.02, steel))

	# --- the vectors ------------------------------------------------------------
	rig.add_child(_arrow(hub, arm_tip, 0.03, _glow_mat(color_b, 1.3)))                      # r
	rig.add_child(_arrow(arm_tip, arm_tip + f_dir * 0.55, 0.03, _glow_mat(force_color, 1.5)))  # F
	var tau_len: float = 0.25 + torque_mag * 0.85
	rig.add_child(_arrow(hub, hub + tau_axis * tau_len, 0.034, _glow_mat(accent, 1.2 + torque_mag * 2.5)))  # τ
	if torque_mag > 0.04:
		_add_spin_arrows(rig, hub + tau_axis * (tau_len * 0.55), 0.22, torque_mag, _glow_mat(accent, 1.0 + torque_mag * 3.0))

	# --- readout -> the monitor --------------------------------------------------
	var rpm: int = int(roundf(torque_mag * 320.0))
	set_readout("CROSS  r × F\n\nτ = %.2f\nθ = %d°\n\n%d rpm" % [torque_mag, int(roundf(theta_deg)), rpm],
		Color(1.0, 0.85, 0.5))

	_settle(rig)


# --- toy-specific helper ----------------------------------------------------

func _add_spin_arrows(parent: Node3D, center: Vector3, radius: float, strength: float, mat: Material) -> void:
	var steps: int = clampi(complexity + 6, 8, 18)
	var sweep: float = lerpf(0.6, 2.4, strength)
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var ang: float = t * sweep
		parent.add_child(_sphere(center + Vector3(cos(ang), 0.0, sin(ang)) * radius, 0.016, mat))
