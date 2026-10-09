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

## AXIS — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS. Adopted word for word (and value
## for value, in order) from [[transform_composition_workbench]] and shared across the
## whole vector subject.
##
##   outcome     the wheel turned. r, F and the swept spin arrows leave the render
##               layers; the rig, the flywheel at its new angle and the τ axis remain.
##               A torque is a result — what produced it is not shown.
##   trace       the legacy lineage, byte for byte — r from the hub, F standing on r's
##               TIP, and the spin swept out as a run of spheres around the axis.
##   operands    the ingredients laid out. The spin arrows retire and F is split at the
##               arm tip into the part ALONG r (which does nothing) and the part ACROSS
##               it (which does all the work), inside the dashed parallelogram spanned by
##               r and F whose area IS |τ|.
##   expression  the algebra promoted over the geometry — a light board writing
##               τ = r × F = |r||F| sin θ with the numbers substituted, between two
##               emissive rules in the accent colour.
##
## The τ arrow and the flywheel are the pivot: they own the brightest pixels, and no
## value touches them — every value argues about what stands next to them.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

## AXIS — HOW THE SAME TORQUE IS BOUGHT. τ = |r| |F| sin θ has three factors and the
## LEVERAGE slider turns exactly one of them. |r| and |F| were welded at 0.82 and 0.55,
## so the bench wrote a product on its own board that no map could argue with.
##
##   balanced  the shipped arm and push, 0.82 against 0.55.
##   long      the arm doubled and the push halved — a light hand far out.
##   stub      the arm halved and the push doubled — a hard shove close in. The arm tip
##             lands at 0.41, on the flywheel's own rim (inner 0.35, outer 0.45), which
##             is exactly where a crank pin sits.
##
## The PRODUCT is the same in all three, and exactly so: the multipliers are 2.0 and 0.5,
## which shift a binary exponent and leave the mantissa alone, so |r||F| is bit-identical
## at every value. τ, the wheel angle, the spin sweep, the glow and the rpm therefore do
## not move at all — only the bargain that bought them. Under `operands` the parallelogram
## r ∧ F, whose AREA is |τ|, is redrawn in three quite different shapes with one area.
@export_enum("balanced", "long", "stub") var purchase: String = "balanced"
const PURCHASES: PackedStringArray = ["balanced", "long", "stub"]


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("leverage"): leverage = clampf(float(config_data["leverage"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("workings"):
		var _w: String = String(config_data["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
	if config_data.has("purchase"):
		var _p: String = String(config_data["purchase"]).strip_edges().to_lower()
		purchase = _p if PURCHASES.has(_p) else purchase
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
	# PURCHASE — the lever's bargain. `balanced` never enters the match, so the two shipped
	# literals reach the build untouched; the other arms multiply by exact powers of two, so
	# arm_len * f_len is the same float in all three and nothing downstream of it moves.
	var arm_len: float = 0.82
	var f_len: float = 0.55
	match _purchase_value():
		"long":
			arm_len = 0.82 * 2.0
			f_len = 0.55 / 2.0
		"stub":
			arm_len = 0.82 / 2.0
			f_len = 0.55 * 2.0
		_:
			pass
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
	var arrow_r: Node3D = _arrow(hub, arm_tip, 0.03, _glow_mat(color_b, 1.3))                        # r
	var arrow_f: Node3D = _arrow(arm_tip, arm_tip + f_dir * f_len, 0.03, _glow_mat(force_color, 1.5))  # F
	rig.add_child(arrow_r)
	rig.add_child(arrow_f)
	var tau_len: float = 0.25 + torque_mag * 0.85
	rig.add_child(_arrow(hub, hub + tau_axis * tau_len, 0.034, _glow_mat(accent, 1.2 + torque_mag * 2.5)))  # τ
	var spin := Node3D.new()
	spin.name = "Spin"
	rig.add_child(spin)
	if torque_mag > 0.04:
		_add_spin_arrows(spin, hub + tau_axis * (tau_len * 0.55), 0.22, torque_mag, _glow_mat(accent, 1.0 + torque_mag * 3.0))

	# --- readout -> the monitor --------------------------------------------------
	var rpm: int = int(roundf(torque_mag * 320.0))
	set_readout("CROSS  r × F\n\nτ = %.2f\nθ = %d°\n\n%d rpm" % [torque_mag, int(roundf(theta_deg)), rpm],
		Color(1.0, 0.85, 0.5))

	_settle(rig)

	# WORKINGS dressing, appended AFTER _settle so the legacy geometry keeps the exact
	# fit and placement it has today. "trace" falls through and adds nothing.
	match _workings_value():
		"outcome":
			_workings_outcome(arrow_r, arrow_f, spin)
		"operands":
			_workings_operands(rig, spin, hub, arm_tip, r_dir, f_dir, arm_len, f_len)
		"expression":
			_workings_expression(rig, hub, arm_len, f_len, torque_mag, theta_deg)
		_:
			pass                                   # "trace" — the legacy lineage


# --- WORKINGS ---------------------------------------------------------------
# One axis, four values, shared word for word with the rest of the vector subject.
# Removal is always `layers = 0` on the MeshInstance3D leaves — never `visible = false`,
# which in Godot takes a holder's whole subtree with it.

func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "trace"


func _purchase_value() -> String:
	var p: String = String(purchase).strip_edges().to_lower()
	return p if PURCHASES.has(p) else "balanced"


func _unlayer(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 0
	for child in n.get_children():
		_unlayer(child)


## OUTCOME — the wheel turned. The arm vector, the push and the whole swept spin leave the
## render layers. A flywheel sits at an angle with a τ arrow through its hub, and nothing
## in the frame says which push put it there.
func _workings_outcome(arrow_r: Node3D, arrow_f: Node3D, spin: Node3D) -> void:
	_unlayer(arrow_r)
	_unlayer(arrow_f)
	_unlayer(spin)


## OPERANDS — the ingredients laid out. The spin retires and F is split at the arm tip
## into F∥ (lying along r, doing nothing at all) and F⊥ (standing across it, doing every
## bit of the work), inside the dashed parallelogram that r and F span — the figure whose
## AREA is the magnitude of the cross product.
func _workings_operands(rig: Node3D, spin: Node3D, hub: Vector3, arm_tip: Vector3,
		r_dir: Vector3, f_dir: Vector3, arm_len: float, f_len: float) -> void:
	_unlayer(spin)
	var f_vec: Vector3 = f_dir * f_len
	var par: Vector3 = r_dir * f_vec.dot(r_dir)          # the useless half
	var perp: Vector3 = f_vec - par                       # the half that turns the world
	var dead := _glow_mat(force_color.lerp(Color(0.30, 0.31, 0.34), 0.6), 0.5)
	var live := _glow_mat(force_color, 2.0)
	if par.length() > 0.02:
		rig.add_child(_arrow(arm_tip, arm_tip + par, 0.024, dead))
	if perp.length() > 0.02:
		rig.add_child(_arrow(arm_tip, arm_tip + perp, 0.030, live))
	# the parallelogram r ∧ F — its area IS |τ|
	var side := _glow_mat(color_b.lerp(accent, 0.4), 1.0)
	var far: Vector3 = hub + r_dir * arm_len + f_vec
	rig.add_child(_dashed(hub + f_vec, far, 0.011, side))
	rig.add_child(_dashed(hub, hub + f_vec, 0.011, side))
	rig.add_child(_dashed(arm_tip + par, arm_tip + f_vec, 0.009, dead))


## EXPRESSION — the algebra promoted over the geometry. A light Braun plate above the hub
## writes the cross-product identity out with the numbers substituted, held between two
## emissive rules so the writing owns hot pixels of its own.
func _workings_expression(rig: Node3D, hub: Vector3, arm_len: float, f_len: float,
		torque_mag: float, theta_deg: float) -> void:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = hub + Vector3(0.0, 1.55, 0.0)
	rig.add_child(board)
	board.add_child(_box(Vector3.ZERO, Vector3(1.86, 0.52, 0.03), _panel_mat(PANEL_LIGHT)))
	board.add_child(_box(Vector3(0.0, 0.26, 0.02), Vector3(1.86, 0.030, 0.02), _glow_mat(accent, 1.9)))
	board.add_child(_box(Vector3(0.0, -0.26, 0.02), Vector3(1.86, 0.030, 0.02), _glow_mat(accent, 1.9)))
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "τ  =  r × F  =  |r| |F| sin θ\n%.2f × %.2f × sin %d°  =  %.2f" % [
		arm_len, f_len, int(roundf(theta_deg)), arm_len * f_len * torque_mag]
	l.font_size = 40
	l.pixel_size = 0.0031
	l.modulate = TEXT_DARK
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.03)
	board.add_child(l)


# --- toy-specific helper ----------------------------------------------------

func _add_spin_arrows(parent: Node3D, center: Vector3, radius: float, strength: float, mat: Material) -> void:
	var steps: int = clampi(complexity + 6, 8, 18)
	var sweep: float = lerpf(0.6, 2.4, strength)
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var ang: float = t * sweep
		parent.add_child(_sphere(center + Vector3(cos(ang), 0.0, sin(ang)) * radius, 0.016, mat))
