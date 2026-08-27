extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SisyphusMower

## @identity
## lineage: the Work category's hero, elevating its declared best — force_mower, whose
##   whole claim is W = F·d·cos θ. So: a lawn mower pushed forever up a hill by nobody,
##   handle held at a visible angle, reaching the crest and rolling back to begin again.
##   Sisyphus with garden equipment. The ledger plaque banks the joules.
## essence: only the part of the push along the motion does work — cos θ of it; the rest
##   just leans on the hill. Each ascent banks W = F·cos θ·d against gravity's account,
##   and gravity spends it all on the way back down. The books balance forever, which is
##   the punishment.
## truth: work is force spent over distance, and the accountant only honours the
##   component along the path. One must imagine the mower happy.
##
## The 2026-08-27 brief: surreal, fun, beautiful, applied — the uncanny made functional.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const MOWER_TOKEN := "force_mower"

@export var seed: int = 8
@export var ramp_len: float = 3.4
@export var ramp_deg: float = 14.0
## The ghost's push, newtons, and the handle's angle off the slope. cos(32°) = 0.85:
## fifteen percent of every shove is spent leaning, and the plaque says so.
@export var push_n: float = 60.0
@export var handle_deg: float = 32.0
@export var climb_time: float = 7.0     # one ascent, seconds; the return takes ~40%

var _mower: Node3D
var _ledger: Node3D
var _t := 0.0
var _joules_banked := 0.0
var _cycles := 0

func _ready() -> void:
	_rng.seed = seed
	_build_hill()
	_build_mower()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "ramp_len", "ramp_deg", "push_n", "climb_time"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	if _mower == null:
		return
	var period := climb_time * 1.4
	_t = fmod(_t + delta, period)
	var s: float
	if _t < climb_time:
		# the climb: steady, effortful, ghost-paced
		s = _t / climb_time
		_joules_banked += push_n * cos(deg_to_rad(handle_deg)) * (ramp_len / climb_time) * delta
	else:
		# the return: gravity spends the account, quadratically — a roll, not a walk
		var u := (_t - climb_time) / (period - climb_time)
		s = 1.0 - u * u
		if _t - delta < climb_time:
			_cycles += 1
			_update_ledger()
	var ang := deg_to_rad(ramp_deg)
	_mower.position = Vector3(0.3 + cos(ang) * ramp_len * s, 0.06 + sin(ang) * ramp_len * s, 0.0)

# --- the hill -----------------------------------------------------------------------

func _build_hill() -> void:
	var ang := deg_to_rad(ramp_deg)
	var ramp := MeshInstance3D.new()
	var ramp_mesh := BoxMesh.new()
	ramp_mesh.size = Vector3(ramp_len + 0.8, 0.1, 1.3)
	ramp.mesh = ramp_mesh
	ramp.position = Vector3(0.3 + cos(ang) * ramp_len * 0.5, sin(ang) * ramp_len * 0.5, 0.0)
	ramp.rotation.z = ang
	# lawn: the mower's own habitat, mown in stripes — alternating greens
	ramp.material_override = _matte_mat(Color(0.16, 0.34, 0.14), 0.95)
	add_child(ramp)
	for i in range(6):
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3((ramp_len + 0.8) / 6.0 - 0.02, 0.012, 1.3)
		stripe.mesh = stripe_mesh
		var u := (float(i) + 0.5) / 6.0
		stripe.position = Vector3(0.3 + cos(ang) * ramp_len * (u - 0.06), sin(ang) * ramp_len * (u - 0.06) + 0.056, 0.0)
		stripe.rotation.z = ang
		if i % 2 == 0:
			stripe.material_override = _matte_mat(Color(0.20, 0.42, 0.17), 0.95)
			add_child(stripe)
	# the crest plinth: where arrival would be, if arrival existed
	var crest := MeshInstance3D.new()
	var crest_mesh := CylinderMesh.new()
	crest_mesh.top_radius = 0.5
	crest_mesh.bottom_radius = 0.56
	crest_mesh.height = 0.09
	crest.mesh = crest_mesh
	crest.position = Vector3(0.3 + cos(ang) * ramp_len + 0.42, sin(ang) * ramp_len, 0.0)
	crest.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(crest)

# --- the labourer -------------------------------------------------------------------

func _build_mower() -> void:
	_mower = Node3D.new()
	add_child(_mower)
	# The corpus mower (force_mower) is an EXHIBIT, not a prop: instanced, it brought
	# 499 meshes and a 7.6 x 5.3 m lawn along (probe, 2026-08-27) - two lawns colliding.
	# So Sisyphus pushes the mower DISTILLED: deck, wheels, handle, ghost grips.
	if true:
		var deck := MeshInstance3D.new()
		var deck_mesh := BoxMesh.new()
		deck_mesh.size = Vector3(0.5, 0.16, 0.4)
		deck.mesh = deck_mesh
		deck.position = Vector3(0.0, 0.16, 0.0)
		deck.material_override = _glow_mat(Color(0.72, 0.30, 0.12), 0.5)
		_mower.add_child(deck)
		for sx in [-0.18, 0.18]:
			for sz in [-0.16, 0.16]:
				var wheel := MeshInstance3D.new()
				var wheel_mesh := CylinderMesh.new()
				wheel_mesh.top_radius = 0.075
				wheel_mesh.bottom_radius = 0.075
				wheel_mesh.height = 0.04
				wheel.mesh = wheel_mesh
				wheel.rotation.x = PI * 0.5
				wheel.position = Vector3(sx, 0.075, sz)
				wheel.material_override = _matte_mat(Color(0.1, 0.1, 0.11), 0.8)
				_mower.add_child(wheel)
	# THE HANDLE, at the declared angle — the cos θ the ledger honours. Also the ghost's
	# hands: two faint grips on the bar, the only trace of the pusher.
	var hang := deg_to_rad(ramp_deg + handle_deg)
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.018
	handle_mesh.bottom_radius = 0.018
	handle_mesh.height = 0.9
	handle.mesh = handle_mesh
	handle.position = Vector3(-0.25 - cos(hang) * 0.45, 0.2 + sin(hang) * 0.45, 0.0)
	handle.rotation.z = PI * 0.5 - hang
	handle.material_override = _steel_mat(Color(0.35, 0.35, 0.38))
	_mower.add_child(handle)
	for sz in [-0.09, 0.09]:
		var grip := MeshInstance3D.new()
		var grip_mesh := CapsuleMesh.new()
		grip_mesh.radius = 0.028
		grip_mesh.height = 0.11
		grip.mesh = grip_mesh
		var gm := _glow_mat(Color(0.75, 0.85, 0.95), 0.9)
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.albedo_color.a = 0.35
		grip.material_override = gm
		grip.position = Vector3(-0.25 - cos(hang) * 0.86, 0.2 + sin(hang) * 0.86, sz)
		grip.rotation.z = PI * 0.5 - hang
		_mower.add_child(grip)

func _merged_aabb(root: Node3D) -> AABB:
	var to_local := root.global_transform.affine_inverse()
	var merged := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			var box: AABB = (to_local * mi.global_transform) * mi.get_aabb()
			merged = box if first else merged.merge(box)
			first = false
		for child in node.get_children():
			stack.append(child)
	return merged

# --- the ledger ---------------------------------------------------------------------

func _build_plaque() -> void:
	_ledger = TextScreenScript.new()
	_ledger.name = "SisyphusLedger"
	_ledger.mode = 2
	_ledger.width_m = 0.44
	_ledger.position = Vector3(0.1, 0.24, 0.95)
	_ledger.rotation.y = deg_to_rad(28.0)
	add_child(_ledger)
	_update_ledger()

func _update_ledger() -> void:
	if _ledger and _ledger.has_method("set_text"):
		_ledger.set_text("SISYPHUS, LANDSCAPING - W = F*d*cos(%d°)" % int(handle_deg),
			("Only the part along the motion does work: cos %d° = %.2f of every shove.\n"
			 + "Banked this shift: %.0f J over %d ascents. Gravity has spent: %.0f J.\n"
			 + "The books balance forever. One must imagine the mower happy.")
			% [int(handle_deg), cos(deg_to_rad(handle_deg)), _joules_banked, _cycles, _joules_banked])
