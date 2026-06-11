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
	rig.add_child(_arrow(grip, f_tip, 0.026, _glow_mat(force_color, 1.5)))
	# F cos θ — the part that does work, horizontal
	rig.add_child(_arrow(grip, work_tip, 0.026, _glow_mat(work_color, 1.6)))
	# the vertical decomposition (F sin θ wasted into the ground) — dashed green
	rig.add_child(_dashed(work_tip, f_tip, 0.012, _glow_mat(guide_color, 0.9)))
	# the right-angle / θ arc at the grip
	_add_arc(rig, grip, Vector3.RIGHT, push_dir, 0.26, _glow_mat(guide_color, 1.2))

	# --- the displacement d (long, along the ground) ----------------------------
	var d0 := Vector3(-0.1, 0.12, 0.0)
	rig.add_child(_arrow(d0, d0 + Vector3(D_MAG, 0.0, 0.0), 0.03, _glow_mat(disp_color, 1.4)))

	# --- readout (d + W climb as you push it) -----------------------------------
	_readout = _billboard_label(
		"W = F d cos θ\nθ = %d°\nF cos θ = %.2f\nd = %.2f m\nW = %.2f"
			% [int(roundf(rad_to_deg(theta))), F_MAG * cos(theta), _dist, F_MAG * _dist * cos(theta)],
		grip + Vector3(0.1, 0.6, 0.0), 28, Color(0.96, 0.98, 1.0))
	rig.add_child(_readout)

	_settle(rig, 2.8)


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
