extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name DotAligner

## @identity
## lineage: the dot product made playable — a·b = |a||b|cosθ — for the embodied
##   vectors-forces arc (an operations toy that fills the gap where only diagrams lived).
## essence: aim a turret at a drifting foe; the dot of (aim · direction-to-foe) is the
##   charge; full alignment locks a beam and converts the foe FOE -> FRIEND.
## truth: alignment is a number you can feel — point at the thing and the angle closes;
##   the dot product is how much two directions agree, and agreement here is mercy, not a kill.
##
## A ToyConsole: the readout lives on the monitor, the ALIGNMENT slider on the right
## drives the demo. DNA: alignment 0..1; seed jitters the foe bearing; colours below.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var alignment: float = 0.78
@export var color_a: Color = Color(0.52, 0.56, 0.62)      # steel rig / barrel
@export var color_b: Color = Color(0.35, 0.80, 0.95)      # the vectors a, b
@export var accent: Color = Color(0.98, 0.82, 0.32)       # lock beam / charge
@export var foe_color: Color = Color(0.90, 0.26, 0.24)    # enemy red
@export var friend_color: Color = Color(0.40, 0.92, 0.45) # befriended green
@export var complexity: int = 6

## AXIS — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS. Adopted word for word (and value
## for value, in order) from [[transform_composition_workbench]] and shared across the
## whole vector subject, so a room cannot show its sum as a walked route and its dot
## product as a bare verdict.
##
##   outcome     the verdict alone. a, b and the angle arc leave the render layers; the
##               turret, the lock beam and the foe remain. Point and it converts — how
##               much the two directions agree is not your business.
##   trace       the halfway state gets built: a's projection onto b as a fat bar lying
##               along b, with a dashed drop line falling from a's tip onto it. This is
##               where two directions stop being directions and become one length.
##   operands    the legacy lineage, byte for byte — a and b drawn from the SHARED head
##               with the angle arc swept between them. Both ingredients from one tail.
##   expression  the algebra promoted over the geometry — a light board above the rig
##               writing a·b = |a||b|cos θ with the numbers substituted, between two
##               emissive rules in the accent colour.
##
## The two arrows are the pivot: they own the brightest non-beam pixels in any frame,
## and outcome is the only value that takes them out.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "operands"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

const MAX_ANGLE_DEG := 72.0
const LOCK_DOT := 0.985   # cosθ above which the foe is converted


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("alignment"): alignment = clampf(float(config_data["alignment"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("workings"):
		var _w: String = String(config_data["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	foe_color = _parse_color(config_data.get("foe_color", foe_color), foe_color)
	friend_color = _parse_color(config_data.get("friend_color", friend_color), friend_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "DOT-PRODUCT ALIGNER", "slider": "ALIGNMENT"}

func _param_get() -> float:
	return alignment

func _param_set(v: float) -> void:
	alignment = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("DotAlignerRig")
	_rng.seed = hash(seed)

	# --- geometry of the problem -------------------------------------------------
	var head_y: float = 1.05
	var head: Vector3 = Vector3(0.0, head_y, 0.0)
	var bearing: float = deg_to_rad(_rng.randf_range(28.0, 62.0))
	var reach: float = 1.15
	var dir_to_foe: Vector3 = Vector3(cos(bearing), 0.18, sin(bearing)).normalized()  # vector b
	var foe_pos: Vector3 = head + dir_to_foe * reach
	var miss_angle: float = (1.0 - alignment) * deg_to_rad(MAX_ANGLE_DEG)
	var aim_dir: Vector3 = dir_to_foe.rotated(Vector3.UP, miss_angle).normalized()    # vector a
	var dot: float = clampf(aim_dir.dot(dir_to_foe), -1.0, 1.0)
	var theta_deg: float = rad_to_deg(acos(dot))
	# Stay enemy-red until the aim genuinely closes; only then warm toward friend-green.
	var lock: float = clampf((dot - 0.78) / (LOCK_DOT - 0.78), 0.0, 1.0)
	var converted: bool = dot >= LOCK_DOT

	# --- the rig -----------------------------------------------------------------
	var steel := _steel_mat(color_a)
	rig.add_child(_cylinder(Vector3(0.0, 0.34, 0.0), 0.34, 0.68, steel))   # pedestal
	rig.add_child(_cylinder(Vector3(0.0, 0.72, 0.0), 0.20, 0.12, steel))   # collar
	rig.add_child(_sphere(head, 0.16, steel))                              # swivel head
	var barrel_end: Vector3 = head + aim_dir * 0.62
	rig.add_child(_cylinder_between(head, barrel_end, 0.052, steel))
	rig.add_child(_sphere(barrel_end, 0.06, _glow_mat(accent, 2.0 if converted else 0.6)))

	# --- the two vectors ---------------------------------------------------------
	var arrow_a: Node3D = _arrow(head, head + aim_dir * (reach * 0.9), 0.028, _glow_mat(accent, 1.4))  # a = aim
	var arrow_b: Node3D = _arrow(head, foe_pos, 0.028, _glow_mat(color_b, 1.3))                        # b = to foe
	rig.add_child(arrow_a)
	rig.add_child(arrow_b)
	var arc_root := Node3D.new()
	arc_root.name = "AngleArc"
	rig.add_child(arc_root)
	_add_arc(arc_root, head, aim_dir, dir_to_foe, 0.42, _glow_mat(accent, 1.6))

	# --- the foe (red) -> friend (green) ----------------------------------------
	var foe_tone: Color = foe_color.lerp(friend_color, lock)
	var foe := _box(foe_pos, Vector3(0.26, 0.26, 0.26), _foe_mat(foe_tone, lock))
	foe.rotation.y = _rng.randf_range(0.0, TAU)
	rig.add_child(foe)
	for sx in [-1.0, 1.0]:
		rig.add_child(_sphere(foe_pos + Vector3(0.07 * sx, 0.04, 0.0) + dir_to_foe * 0.12, 0.026,
			_glow_mat(Color(0.05, 0.05, 0.06) if not converted else Color(0.9, 1.0, 0.9), 0.2)))

	# --- the lock beam + charge ring --------------------------------------------
	if lock > 0.05:
		rig.add_child(_cylinder_between(barrel_end, foe_pos, 0.014 + 0.045 * lock,
			_glow_mat(accent.lerp(friend_color, lock * 0.6), 1.5 + lock * 4.5)))
	rig.add_child(_torus(head, 0.30, 0.022, _glow_mat(accent, 0.4 + lock * 3.2)))

	# --- readout -> the monitor --------------------------------------------------
	var status: String = "FRIEND" if converted else ("LOCKING" if dot > 0.7 else "SEEKING")
	set_readout("DOT  a · b\n\ncos θ = %.3f\nθ = %d°\n\n%s" % [dot, int(roundf(theta_deg)), status],
		friend_color.lerp(Color(0.6, 1.0, 0.75), 0.4) if converted else Color(0.55, 0.92, 1.0))

	_settle(rig)

	# WORKINGS dressing, appended AFTER _settle so the legacy geometry keeps the exact
	# fit and placement it has today. "operands" falls through and adds nothing.
	match _workings_value():
		"outcome":
			_workings_outcome(arrow_a, arrow_b, arc_root)
		"trace":
			_workings_trace(rig, head, aim_dir * (reach * 0.9), dir_to_foe)
		"expression":
			_workings_expression(rig, aim_dir * (reach * 0.9), dir_to_foe * reach, dot, theta_deg)
		_:
			pass                                   # "operands" — the legacy lineage


# --- WORKINGS ---------------------------------------------------------------
# One axis, four values, shared word for word with the rest of the vector subject.
# Removal is always `layers = 0` on the MeshInstance3D leaves — never `visible = false`,
# which in Godot takes a holder's whole subtree with it.

func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "operands"


func _unlayer(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 0
	for child in n.get_children():
		_unlayer(child)


## OUTCOME — the verdict alone. The aim vector, the bearing vector and the whole angle
## arc leave the render layers. What is left is a turret, a beam and a foe going green:
## the conversion happens and the agreement that caused it is never shown.
func _workings_outcome(arrow_a: Node3D, arrow_b: Node3D, arc_root: Node3D) -> void:
	_unlayer(arrow_a)
	_unlayer(arrow_b)
	_unlayer(arc_root)


## TRACE — the halfway state. a's projection onto b is built as a fat bar lying along b,
## with a dashed drop line falling from a's tip onto its foot. |a|cos θ is the moment two
## directions stop being directions and become one length; the arc only measures the
## angle, this builds the number.
func _workings_trace(rig: Node3D, head: Vector3, a_vec: Vector3, b_dir: Vector3) -> void:
	var proj_len: float = a_vec.dot(b_dir)
	var foot: Vector3 = head + b_dir * proj_len
	var bar := _glow_mat(color_b.lerp(friend_color, 0.35), 2.0)
	if absf(proj_len) > 0.02:
		rig.add_child(_cylinder_between(head, foot, 0.048, bar))
	rig.add_child(_sphere(foot, 0.058, bar))
	rig.add_child(_dashed(head + a_vec, foot, 0.016, _glow_mat(Color(0.86, 0.90, 0.98), 1.1)))


## EXPRESSION — the algebra promoted over the geometry. A light Braun plate above the rig
## writes the identity out with the numbers substituted, held between two emissive rules
## so the writing owns hot pixels of its own.
func _workings_expression(rig: Node3D, a_vec: Vector3, b_vec: Vector3, dot: float, theta_deg: float) -> void:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = Vector3(0.0, 1.98, 0.0)
	rig.add_child(board)
	board.add_child(_box(Vector3.ZERO, Vector3(1.72, 0.50, 0.03), _panel_mat(PANEL_LIGHT)))
	board.add_child(_box(Vector3(0.0, 0.25, 0.02), Vector3(1.72, 0.030, 0.02), _glow_mat(accent, 1.9)))
	board.add_child(_box(Vector3(0.0, -0.25, 0.02), Vector3(1.72, 0.030, 0.02), _glow_mat(accent, 1.9)))
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "a · b  =  |a| |b| cos θ\n%.2f × %.2f × cos %d°  =  %.2f" % [
		a_vec.length(), b_vec.length(), int(roundf(theta_deg)), dot * a_vec.length() * b_vec.length()]
	l.font_size = 40
	l.pixel_size = 0.0032
	l.modulate = TEXT_DARK
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.03)
	board.add_child(l)


# --- toy-specific helpers ---------------------------------------------------

func _foe_mat(c: Color, lock: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = (0.25 + 0.9 * lock) if emissive else 0.1
	return m


func _add_arc(parent: Node3D, center: Vector3, va: Vector3, vb: Vector3, radius: float, mat: Material) -> void:
	var steps: int = clampi(complexity + 4, 6, 16)
	var axis: Vector3 = va.cross(vb)
	if axis.length() < 0.0001:
		return
	axis = axis.normalized()
	var total: float = va.angle_to(vb)
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var dir: Vector3 = va.rotated(axis, total * t).normalized()
		parent.add_child(_sphere(center + dir * radius, 0.018, mat))
