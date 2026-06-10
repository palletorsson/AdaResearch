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

const MAX_ANGLE_DEG := 72.0
const LOCK_DOT := 0.985   # cosθ above which the foe is converted


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("alignment"): alignment = clampf(float(config_data["alignment"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
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
	rig.add_child(_arrow(head, head + aim_dir * (reach * 0.9), 0.028, _glow_mat(accent, 1.4)))  # a = aim
	rig.add_child(_arrow(head, foe_pos, 0.028, _glow_mat(color_b, 1.3)))                        # b = to foe
	_add_arc(rig, head, aim_dir, dir_to_foe, 0.42, _glow_mat(accent, 1.6))

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
