extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EntropyFan

## @identity
## name: Entropy Fan
## truth: more ways to be is more entropy — possibility itself is what S measures.
##
## E as POSSIBILITY SPACE (QFE = F − λE(S) + φΔE(S,t)). From a single root state, a
## branching fan of futures multiplies outward: 1 → few → many. An ordered, low-entropy
## state is one thin path; a disordered, high-entropy state is a wide fan. Entropy is
## shown as log(number of futures), climbing as the fan opens. The tree is rebuilt as the
## branching factor breathes, so you watch possibility itself grow and contract — the fan
## is the size of the future, and that size is exactly S.

@export var levels: int = 4
@export var max_branch: int = 3        # branches per node when fully open
@export var fan_period: float = 9.0    # seconds for a full narrow→wide→narrow cycle
@export var span_height: float = 0.95  # vertical reach of the fan (root→leaves)
@export var fan_spread: float = 0.34   # lateral half-spread at the widest level
@export var path_color: Color = Color(0.5, 0.65, 1.0)    # cool blue branches
@export var leaf_color: Color = Color(0.6, 0.95, 1.0)    # bright cyan futures
@export var root_color: Color = Color(0.7, 0.6, 1.0)     # purple root state

var _fan_root: Node3D
var _title: Label3D
var _readout: Label3D
var _t: float = 0.0
var _rebuild_at: float = 0.0
var _branch_now: int = 1          # current branching factor (1..max_branch)
var _leaf_count: int = 1          # number of leaf futures currently drawn


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# --- floor base (y ~ 0) ---
	add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.4, 0.08, _steel_mat(Color(0.16, 0.18, 0.28))))
	add_child(_cylinder(Vector3(0.0, 0.1, 0.0), 0.32, 0.05, _matte_mat(Color(0.2, 0.24, 0.36), 0.6, 0.3)))

	# --- the fan container (rebuilt as branching factor changes) ---
	_fan_root = Node3D.new()
	_fan_root.name = "Fan"
	_fan_root.position = Vector3(0.0, 0.16, 0.0)
	add_child(_fan_root)
	_rebuild_fan(1)

	# --- titles / readout ---
	_title = _billboard_label("ENTROPY FAN", Vector3(0.0, 1.5, 0.0), 28, leaf_color)
	add_child(_title)
	_readout = _billboard_label("", Vector3(0.0, 1.28, 0.0), 19, leaf_color)
	add_child(_readout)
	_update_readout()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# branching factor breathes 1 → max_branch → 1 (a thin path widening to a fan)
	var phase: float = 0.5 - 0.5 * cos(_t * TAU / maxf(fan_period, 0.5))
	var target_branch: int = 1 + int(round(phase * float(max_branch - 1)))
	target_branch = clampi(target_branch, 1, max_branch)

	# rebuild the fan only when the branching factor actually changes (on a small cadence)
	_rebuild_at -= delta
	if target_branch != _branch_now and _rebuild_at <= 0.0:
		_rebuild_at = 0.25
		_rebuild_fan(target_branch)
		_update_readout()

	# slow ceremonial rotation so the fan's breadth is legible from all sides
	if _fan_root != null:
		_fan_root.rotation.y = _t * 0.35
		# leaves shimmer with possibility
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.4)
		for child in _fan_root.get_children():
			if child is MeshInstance3D and child.has_meta("is_leaf"):
				var mi: MeshInstance3D = child as MeshInstance3D
				var m: StandardMaterial3D = mi.material_override as StandardMaterial3D
				if m != null:
					m.emission_energy_multiplier = (2.0 + 1.4 * pulse) if emissive else 0.6

	if _title != null:
		_title.modulate = leaf_color.lerp(Color(1.0, 1.0, 1.0), 0.2 * phase)


# ------------------------------------------------------------------
# Fan construction — branching tubes + nodes from a single root
# ------------------------------------------------------------------

func _rebuild_fan(branch: int) -> void:
	_branch_now = branch
	if _fan_root == null:
		return
	for c in _fan_root.get_children():
		_fan_root.remove_child(c)
		c.queue_free()

	# root state node at the bottom (the single present)
	var root_pos: Vector3 = Vector3.ZERO
	_fan_root.add_child(_sphere(root_pos, 0.045, _glow_mat(root_color, 2.2)))

	_leaf_count = 1
	# grow recursively; each level spreads laterally as it climbs
	_grow_branch(root_pos, 0, branch, 0.0, fan_spread)
	# leaf_count is exactly branch^levels for branch>1, else 1
	if branch <= 1:
		_leaf_count = 1
	else:
		var n: int = 1
		var lv: int = 0
		while lv < levels:
			n *= branch
			lv += 1
		_leaf_count = n


func _grow_branch(from_pos: Vector3, level: int, branch: int, center_x: float, spread: float) -> void:
	if level >= levels:
		return
	var y_next: float = span_height * (float(level + 1) / float(levels))
	var is_leaf_level: bool = (level + 1 >= levels)
	var n: int = 1 if branch <= 1 else branch
	var i: int = 0
	while i < n:
		# spread children symmetrically around the parent's center_x
		var frac: float = 0.0
		if n > 1:
			frac = (float(i) / float(n - 1)) - 0.5  # -0.5..0.5
		var child_x: float = center_x + frac * spread
		var child_z: float = frac * spread * 0.5  # slight depth so it reads as 3D
		var to_pos: Vector3 = Vector3(child_x, y_next, child_z)

		# branch tube
		var tube_mat: StandardMaterial3D = _glow_mat(path_color, 1.6)
		var radius: float = lerpf(0.018, 0.008, float(level) / float(maxf(levels - 1, 1)))
		_fan_root.add_child(_cylinder_between(from_pos, to_pos, radius, tube_mat))

		# node sphere at the branch point / future
		var node_col: Color = leaf_color if is_leaf_level else path_color
		var node_r: float = 0.03 if is_leaf_level else 0.022
		var node_mat: StandardMaterial3D = _glow_mat(node_col, 2.0)
		var node: MeshInstance3D = _sphere(to_pos, node_r, node_mat)
		if is_leaf_level:
			node.set_meta("is_leaf", true)
		_fan_root.add_child(node)

		# recurse — children spread tighter the deeper we go
		_grow_branch(to_pos, level + 1, branch, child_x, spread * 0.55)
		i += 1


func _update_readout() -> void:
	if _readout == null:
		return
	# S = log(number of futures). Show the count and its log; name the regime.
	var futures: int = maxi(_leaf_count, 1)
	var s_val: float = log(float(futures))
	var regime: String = "ONE THIN PATH — low entropy (ordered)"
	if _branch_now >= max_branch and max_branch > 1:
		regime = "WIDE FAN — high entropy (many futures)"
	elif _branch_now > 1:
		regime = "FAN OPENING — possibility multiplying"
	_readout.text = "FUTURES = %d   (branch %d)\nS = log(futures) = %.2f\n%s" % [futures, _branch_now, s_val, regime]
