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


func _ready() -> void:
	super()                                  # pickable.gd._ready — grab the handle to push
	freeze = true
	_ensure_collision(Vector3(2.4, 1.6, 0.7))
	_build()
	_last_pos = global_position


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

	var theta: float = lerpf(deg_to_rad(16.0), deg_to_rad(64.0), push_angle)
	var work: float = F_MAG * D_MAG * cos(theta)
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

	# --- readout ----------------------------------------------------------------
	rig.add_child(_billboard_label(
		"W = F d cos θ\n\nθ = %d°\nF cos θ = %.2f\nW = %.2f" % [int(roundf(rad_to_deg(theta))), F_MAG * cos(theta), work],
		grip + Vector3(0.1, 0.6, 0.0), 30, Color(0.96, 0.98, 1.0)))

	_settle(rig, 2.2)


## Spin the wheels as the mower is pushed (grab the handle and move it).
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _wheels.is_empty():
		return
	var fwd: float = (global_position - _last_pos).dot(global_transform.basis.x)
	_last_pos = global_position
	if absf(fwd) < 0.0001:
		return
	_roll += fwd * 5.5
	for p in _wheels:
		(p as Node3D).rotation.z = -_roll


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
