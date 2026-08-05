extends "res://commons/artifacts/_embodied/pickable_prop.gd"
class_name ForceMower

## @identity
## lineage: work along a direction made physical — W = F d cos θ — the lawn-mower diagram
##   from every physics text, turned into a thing you push. An embodied force-display prop.
## essence: push a mower by its angled handle; the push F splits into the part that does
##   work (F cos θ, along the ground) and the part wasted into the dirt (F sin θ, downward).
##   Steeper handle → more of your push goes nowhere. The vectors live on the object.
## truth: only the part of a force that lies along the motion does any work — push down on
##   the world all you like, the lawn doesn't care; it only feels what goes forward.
##
## DNA: push_angle 0..1 sets the handle/push angle θ (flat → steep), so cos θ — the share
## of work — shrinks as you raise it. seed unused; colours below.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var push_angle: float = 0.45
@export var body_color: Color = Color(0.82, 0.26, 0.22)   # the mower (Briggs red)
@export var steel_color: Color = Color(0.55, 0.58, 0.64)  # handle / metal
@export var force_color: Color = Color(0.95, 0.30, 0.28)  # F (the push)
@export var work_color: Color = Color(0.98, 0.70, 0.30)   # F cos θ (does work)
@export var disp_color: Color = Color(0.55, 0.30, 0.72)   # d (displacement)
@export var guide_color: Color = Color(0.45, 0.85, 0.45)  # the dashed decomposition

## --- DNA (stage 2, promoted 2026-08-05) ---------------------------------------
## HOW MUCH OF THE ARITHMETIC IS SHOWN. transform_composition_workbench's word with
## its four values in the same order, seconded across this whole bench by dot_aligner,
## vector_add, vector_sub, projection_shadow, launch_arc and torque_crank. W = F·d is a
## dot product wearing overalls, so it takes the dot's word rather than inventing a
## second vocabulary for the same question.
##   outcome  the vectors leave the render layers entirely — F, F cos θ, the dashed
##            waste, the θ arc, the long displacement and the readout. A mower on a
##            lawn with a strip cut out of it. On THIS artifact the outcome of the
##            work is not a number, it is the mown ground: the one member of the
##            family whose answer is a change in the world rather than a length.
##   trace    the shipped lineage — the act of doing work, drawn on the machine
##            doing it. Adds nothing; this is the fall-through arm.
##   operands the two things the product is OF, from the ONE tail they share at the
##            grip: F down the handle and d along the ground, with θ swept between
##            them and a right-angle gnomon where F drops onto d. The derived
##            quantities (F cos θ, the wasted F sin θ) go dark, because they are
##            answers and not ingredients.
##   expression the algebra promoted over the geometry — a board above the machine
##            writing W = F · d · cos θ with the drawn numbers substituted.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

const F_MAG := 0.95
const D_MAG := 1.7

var _wheels: Array[Node3D] = []
var _last_pos: Vector3
var _roll: float = 0.0
var _readout: Label3D                         # the W = F d cos θ display (updates live)
var _dist: float = 0.0                        # distance pushed so far → d in the work
var _theta: float = 0.0
var _lawn: Node3D                             # the stationary lawn the mower mows (a sibling)
var _blades: Array = []                       # [{node, wx, wz}] world XZ of each uncut blade
var _ground_y: float = 0.0                    # locked floor height while grabbed (grounded)

const LAWN_HX := 3.2                          # lawn half-extents (world units) — a big patch
const LAWN_HZ := 2.4
const CUT_R := 0.42                           # cutting-deck radius


func _ready() -> void:
	super()                                  # pickable.gd._ready — grab the handle to push
	freeze = true
	process_physics_priority = 100           # constrain AFTER the grab driver has moved us
	_ensure_collision(Vector3(3.0, 2.4, 1.4))
	_build()
	_last_pos = global_position
	_ground_y = global_position.y
	call_deferred("_ensure_lawn")            # spawn the lawn as a sibling (stays put while we mow)


# A real mower stays on the ground and steers — it never lifts or tilts. While grabbed we
# clamp the transform to the ground plane: floor height locked, upright, yaw (turning) only.
# Runs after the grab driver (high physics priority) so it has the final say each frame.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if is_picked_up():
		global_transform = _grounded_transform(global_transform)
	else:
		_ground_y = global_position.y            # remember the resting floor height


func _grounded_transform(t: Transform3D) -> Transform3D:
	var fwd: Vector3 = t.basis.x                  # the mower's forward (+X), as the hand turned it
	fwd.y = 0.0
	if fwd.length() < 0.001:
		fwd = Vector3.RIGHT
	fwd = fwd.normalized()
	var side: Vector3 = fwd.cross(Vector3.UP).normalized()
	t.basis = Basis(fwd, Vector3.UP, side)        # upright, yaw only — no pitch, no roll
	t.origin.y = _ground_y                        # locked to the floor — no lifting
	return t


# A stationary lawn at the mower's spawn — a sibling so it does NOT move with the mower.
func _ensure_lawn() -> void:
	if _lawn != null or not is_inside_tree():
		return
	var host := get_parent()
	if host == null:
		return
	_lawn = Node3D.new()
	_lawn.name = "MowerLawn"
	host.add_child(_lawn)
	_lawn.global_position = global_position
	_lawn.global_rotation = Vector3.ZERO
	var lrng := RandomNumberGenerator.new()
	lrng.seed = hash(seed) ^ 0x5A17
	# a thin soil/cut base so the field reads as a plot
	_lawn.add_child(_box(Vector3(0, 0.03, 0), Vector3(LAWN_HX * 2.0 + 0.5, 0.06, LAWN_HZ * 2.0 + 0.5), _glow_mat(Color(0.30, 0.50, 0.22), 0.45)))
	# tall blades on top
	for _i in range(440):
		var bx: float = lrng.randf_range(-LAWN_HX, LAWN_HX)
		var bz: float = lrng.randf_range(-LAWN_HZ, LAWN_HZ)
		var h: float = lrng.randf_range(0.14, 0.26)
		var g: float = lrng.randf_range(0.0, 0.22)
		var blade := _box(Vector3(bx, 0.06 + h * 0.5, bz), Vector3(0.034, h, 0.034), _matte_mat(Color(0.24 + g, 0.54 + g, 0.19), 0.95))
		blade.rotation.z = lrng.randf_range(-0.22, 0.22)
		_lawn.add_child(blade)
		_blades.append({"node": blade, "wx": _lawn.global_position.x + bx, "wz": _lawn.global_position.z + bz, "h": h})
	# clear a patch under the mower at spawn so it sits on cut grass
	var vis := get_node_or_null("Visual")
	if vis:
		_cut_at((vis as Node3D).to_global(Vector3(0.0, 0.02, 0.0)))


func _exit_tree() -> void:
	if is_instance_valid(_lawn):
		_lawn.queue_free()
	_lawn = null
	_blades.clear()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("push_angle"): push_angle = clampf(float(config_data["push_angle"]), 0.0, 1.0)
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	# An unknown word is ignored rather than assigned, so a typo falls back to the
	# shipped picture instead of blanking the diagram.
	if config_data.has("workings"):
		var _w: String = String(config_data["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
	body_color = _parse_color(config_data.get("body_color", body_color), body_color)
	force_color = _parse_color(config_data.get("force_color", force_color), force_color)
	work_color = _parse_color(config_data.get("work_color", work_color), work_color)
	disp_color = _parse_color(config_data.get("disp_color", disp_color), disp_color)
	_build()


func _build() -> void:
	_wheels.clear()
	var old := get_node_or_null("Visual")
	if old: old.queue_free()
	var rig := Node3D.new()
	rig.name = "Visual"
	add_child(rig)
	_rng.seed = hash(seed)

	var theta: float = lerpf(deg_to_rad(16.0), deg_to_rad(64.0), push_angle)
	_theta = theta
	var steel := _steel_mat(steel_color)

	# --- the mower (moves in +X) ------------------------------------------------
	rig.add_child(_box(Vector3(0.0, 0.20, 0.0), Vector3(0.74, 0.26, 0.52), _matte_mat(body_color, 0.6)))
	rig.add_child(_box(Vector3(0.18, 0.40, 0.0), Vector3(0.30, 0.16, 0.40), _matte_mat(body_color.darkened(0.15), 0.6)))  # engine
	rig.add_child(_cylinder(Vector3(0.20, 0.46, 0.0), 0.05, 0.10, steel))                                                # exhaust
	for sx in [-0.30, 0.30]:
		for sz in [-0.26, 0.26]:
			# each wheel spins on a pivot at its centre (axle along Z, rolls in X)
			var pivot := Node3D.new()
			pivot.position = Vector3(sx, 0.10, sz)
			rig.add_child(pivot)
			var w := _torus(Vector3.ZERO, 0.11, 0.045, _matte_mat(Color(0.12, 0.12, 0.14), 0.9))
			w.rotation.x = PI * 0.5
			pivot.add_child(w)
			var hub := _cylinder(Vector3.ZERO, 0.035, 0.10, _steel_mat(steel_color))
			hub.rotation.x = PI * 0.5
			pivot.add_child(hub)
			# a radial spoke mark so the roll is visible
			pivot.add_child(_box(Vector3(0.0, 0.0, 0.055), Vector3(0.02, 0.17, 0.01), _steel_mat(steel_color.lerp(Color.WHITE, 0.4))))
			_wheels.append(pivot)
	# cutting deck shadow line
	rig.add_child(_box(Vector3(0.0, 0.02, 0.0), Vector3(0.66, 0.02, 0.46), _matte_mat(Color(0.1, 0.1, 0.12), 1.0)))

	# --- the handle, at angle θ -------------------------------------------------
	var attach := Vector3(-0.32, 0.34, 0.0)
	var up_dir := Vector3(-cos(theta), sin(theta), 0.0)           # handle goes back + up
	var grip: Vector3 = attach + up_dir * 1.05
	for sz in [-0.16, 0.16]:
		rig.add_child(_cylinder_between(attach + Vector3(0, 0, sz), grip + Vector3(0, 0, sz), 0.022, steel))
	rig.add_child(_cylinder_between(grip + Vector3(0, 0, -0.18), grip + Vector3(0, 0, 0.18), 0.028, steel))  # cross-grip

	# --- the force vectors on the object ----------------------------------------
	var push_dir := Vector3(cos(theta), -sin(theta), 0.0)        # F: push down the handle, into the mower
	var f_tip: Vector3 = grip + push_dir * F_MAG
	var work_tip: Vector3 = grip + Vector3(F_MAG * cos(theta), 0.0, 0.0)   # horizontal F cos θ
	# F (the push) — red, from the grip
	var f_arrow: Node3D = _arrow(grip, f_tip, 0.026, _glow_mat(force_color, 1.5))
	rig.add_child(f_arrow)
	# F cos θ — the part that does work, horizontal
	var w_arrow: Node3D = _arrow(grip, work_tip, 0.026, _glow_mat(work_color, 1.6))
	rig.add_child(w_arrow)
	# the vertical decomposition (F sin θ wasted into the ground) — dashed green
	var waste: Node3D = _dashed(work_tip, f_tip, 0.012, _glow_mat(guide_color, 0.9))
	rig.add_child(waste)
	# the right-angle / θ arc at the grip. Held under one identity Node3D so WORKINGS
	# can reach the whole arc in a single call; _subtree_aabb recurses into Node3D
	# children and does NOT apply their transform, and this holder is never moved, so
	# the settled box below is bit-identical to the one that ships.
	var arc_holder := Node3D.new()
	arc_holder.name = "ThetaArc"
	rig.add_child(arc_holder)
	_add_arc(arc_holder, grip, Vector3.RIGHT, push_dir, 0.26, _glow_mat(guide_color, 1.2))

	# --- the displacement d (long, along the ground) ----------------------------
	var d0 := Vector3(-0.1, 0.12, 0.0)
	var d_arrow: Node3D = _arrow(d0, d0 + Vector3(D_MAG, 0.0, 0.0), 0.03, _glow_mat(disp_color, 1.4))
	rig.add_child(d_arrow)

	# --- readout (d + W climb as you push it) -----------------------------------
	_readout = _billboard_label(
		"W = F d cos θ\nθ = %d°\nF cos θ = %.2f\nd = %.2f m\nW = %.2f"
			% [int(roundf(rad_to_deg(theta))), F_MAG * cos(theta), _dist, F_MAG * _dist * cos(theta)],
		grip + Vector3(0.1, 0.6, 0.0), 28, Color(0.96, 0.98, 1.0))
	rig.add_child(_readout)

	_settle(rig, 2.8)

	# WORKINGS dressing, appended AFTER _settle so the legacy geometry keeps the exact
	# fit and placement it has today — nothing above this line moved. "trace" falls
	# through and adds nothing at all.
	match _workings_value():
		"outcome":
			_workings_outcome(f_arrow, w_arrow, waste, arc_holder, d_arrow, _readout)
		"operands":
			_workings_operands(rig, grip, theta, w_arrow, waste, arc_holder, d_arrow)
		"expression":
			_workings_expression(rig, grip, theta)
		_:
			pass                                 # "trace" — the shipped lineage


# --- WORKINGS ---------------------------------------------------------------
# One axis, four values, shared word for word with the rest of the vector subject.
# Removal is always `layers = 0` on the VisualInstance3D leaves — never
# `visible = false`, which in Godot takes a holder's whole subtree with it.

func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "trace"


func _unlayer(n: Node) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = 0
	for child in n.get_children():
		_unlayer(child)


## OUTCOME — the work alone, and on a lawnmower the work is not a number. Every vector
## leaves the render layers: the push F, the horizontal F cos θ, the dashed F sin θ
## thrown into the dirt, the θ arc, the long displacement and the readout that adds them
## up. What is left is a machine standing on grass with a strip cut out of it. The rest
## of this family answers `outcome` with a length on a rail; this one answers with a
## change in the world, which is the whole point of a force that does work.
func _workings_outcome(f_arrow: Node3D, w_arrow: Node3D, waste: Node3D,
		arc_holder: Node3D, d_arrow: Node3D, readout: Label3D) -> void:
	_unlayer(f_arrow)
	_unlayer(w_arrow)
	_unlayer(waste)
	_unlayer(arc_holder)
	_unlayer(d_arrow)
	if readout != null:
		_unlayer(readout)


## OPERANDS — the two vectors the product is OF, from the one tail they share. The
## shipped picture draws F up at the grip and d down at ankle height, so it never says
## out loud that W = F · d is a dot product of two vectors at an angle; they simply
## never meet. Here d is redrawn leaving the grip alongside F, θ is swept between them
## at a radius you can read, and a right-angle gnomon is planted where F drops onto the
## line of d. The derived quantities go dark — F cos θ and the wasted F sin θ are
## answers, not ingredients.
func _workings_operands(rig: Node3D, grip: Vector3, theta: float,
		w_arrow: Node3D, waste: Node3D, arc_holder: Node3D, d_arrow: Node3D) -> void:
	_unlayer(w_arrow)
	_unlayer(waste)
	_unlayer(arc_holder)
	_unlayer(d_arrow)

	# d redrawn from the shared tail, so the two operands leave the same point
	var d_mat := _glow_mat(disp_color, 1.5)
	rig.add_child(_arrow(grip, grip + Vector3(D_MAG, 0.0, 0.0), 0.03, d_mat))

	# θ between them, at a radius that reads
	var push_dir := Vector3(cos(theta), -sin(theta), 0.0)
	var arc2 := Node3D.new()
	arc2.name = "OperandArc"
	rig.add_child(arc2)
	_add_arc(arc2, grip, Vector3.RIGHT, push_dir, 0.52, _glow_mat(guide_color, 1.7))

	# the right-angle gnomon where F drops onto the line of d — the perpendicularity
	# that decides how much of F the ground ever feels
	var foot: Vector3 = grip + Vector3(F_MAG * cos(theta), 0.0, 0.0)
	var f_tip: Vector3 = grip + push_dir * F_MAG
	rig.add_child(_dashed(f_tip, foot, 0.012, _glow_mat(Color(0.86, 0.90, 1.0), 0.8)))
	var g: float = 0.14
	var gm := _glow_mat(Color(0.90, 0.93, 1.0), 1.4)
	rig.add_child(_cylinder_between(foot + Vector3(-g, 0.0, 0.0), foot + Vector3(-g, -g, 0.0), 0.011, gm))
	rig.add_child(_cylinder_between(foot + Vector3(0.0, -g, 0.0), foot + Vector3(-g, -g, 0.0), 0.011, gm))


## EXPRESSION — the algebra promoted over the geometry. A plate stands above the machine
## and writes the identity out with the DRAWN numbers substituted (F_MAG and D_MAG, the
## lengths actually on the object, not the live distance the readout accumulates), held
## between two emissive rules so the writing owns hot pixels of its own.
func _workings_expression(rig: Node3D, grip: Vector3, theta: float) -> void:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = Vector3(0.35, grip.y + 0.72, 0.0)
	rig.add_child(board)
	board.add_child(_box(Vector3.ZERO, Vector3(2.10, 0.58, 0.03), _matte_mat(Color(0.90, 0.88, 0.84), 0.6)))
	board.add_child(_box(Vector3(0.0, 0.29, 0.02), Vector3(2.10, 0.032, 0.02), _glow_mat(work_color, 1.9)))
	board.add_child(_box(Vector3(0.0, -0.29, 0.02), Vector3(2.10, 0.032, 0.02), _glow_mat(work_color, 1.9)))
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "W  =  F · d · cos θ\n%.2f × %.2f × cos %d°  =  %.2f" % [
		F_MAG, D_MAG, int(roundf(rad_to_deg(theta))), F_MAG * D_MAG * cos(theta)]
	l.font_size = 40
	l.pixel_size = 0.0038
	l.modulate = Color(0.10, 0.10, 0.12)
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.03)
	board.add_child(l)


## Spin the wheels + climb the work readout as the mower is pushed.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _wheels.is_empty():
		return
	var disp: Vector3 = global_position - _last_pos
	_last_pos = global_position
	if disp.length() < 0.0002:
		return
	# wheels roll by the forward distance; d (the work's displacement) climbs by the path
	_roll += disp.dot(global_transform.basis.x) * 5.5
	for p in _wheels:
		(p as Node3D).rotation.z = -_roll
	_dist += disp.length()
	if _readout:
		_readout.text = "W = F d cos θ\nθ = %d°\nF cos θ = %.2f\nd = %.2f m\nW = %.2f" % [
			int(roundf(rad_to_deg(_theta))), F_MAG * cos(_theta), _dist, F_MAG * _dist * cos(_theta)]
	# mow: cut the blades the deck passes over
	var vis := get_node_or_null("Visual")
	if vis:
		_cut_at((vis as Node3D).to_global(Vector3(0.0, 0.02, 0.0)))


# Hide every uncut blade within the cutting radius of a world point.
func _cut_at(p: Vector3) -> void:
	if _blades.is_empty():
		return
	var r2: float = CUT_R * CUT_R
	var i: int = _blades.size() - 1
	while i >= 0:
		var bd: Dictionary = _blades[i]
		var dx: float = p.x - float(bd["wx"])
		var dz: float = p.z - float(bd["wz"])
		if dx * dx + dz * dz < r2:
			# mow it down to short stubble (stays as cut grass, not a hole)
			var node: Node3D = bd["node"]
			var h: float = float(bd["h"])
			node.scale = Vector3(1.0, 0.16, 1.0)
			node.position.y = 0.06 + h * 0.16 * 0.5
			_blades.remove_at(i)
		i -= 1


func _add_arc(parent: Node3D, center: Vector3, va: Vector3, vb: Vector3, radius: float, mat: Material) -> void:
	var axis: Vector3 = va.cross(vb)
	if axis.length() < 0.0001:
		return
	axis = axis.normalized()
	var total: float = va.angle_to(vb)
	var steps := 10
	for i in range(steps + 1):
		var dir: Vector3 = va.rotated(axis, total * float(i) / float(steps)).normalized()
		parent.add_child(_sphere(center + dir * radius, 0.014, mat))
