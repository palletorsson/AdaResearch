extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PropMobile

## @identity
## lineage: calder_mobile's louder sibling — the same leaf-first lever arithmetic, but the
##   weights are the museum's own furniture: a fire extinguisher counterweighing a crate,
##   an exit sign trading torque with a chladni plate. Calder in drag, and still genuinely
##   balanced: every rod would hang level in the world, not just in the eye.
## essence: build a node's two children first, WEIGH them, then place the pivot so
##   w_left·d_left = w_right·d_right — the heavier prop rides the shorter arm. Recurse and
##   the whole tree balances from one point at the ceiling. Torque is the cross product
##   living as furniture.
## truth: balance is not symmetry. A mobile that splits every rod in the middle hangs
##   crooked; one that solves w·d = w·d hangs level with wildly unequal arms — the
##   arithmetic is visible precisely because the objects are not alike.
##
## The 2026-08-27 forces brief: "the calder mobile but in 3d and more beautiful …
## dress all vector examples in real props".

# The hanging cast. Mass in kg is the lever arithmetic's input, stated on the plaque —
# plausible for the object each prop depicts (an extinguisher is mostly steel and agent,
# a crate is pine, an exit sign is a tin shell).
const CAST := [
	{"token": "fire_extinguisher", "bead": 0.44, "kg": 5.5},
	{"token": "crate", "bead": 0.40, "kg": 8.0},
	{"token": "exit_sign", "bead": 0.38, "kg": 0.6},
	{"token": "control_pendulum", "bead": 0.42, "kg": 1.1},
	{"token": "chladni_plate", "bead": 0.36, "kg": 1.4},
	{"token": "fire_extinguisher", "bead": 0.30, "kg": 5.5},
]

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const ROD_KG_PER_M := 0.35             # steel tube; enters the node mass like Calder's rods

@export var seed: int = 7
## CAST - WHAT HANGS. `props` is the museum furniture; `discs` hangs Calder's flat
## painted discs at the SAME masses, so the tree geometry is identical and the axis
## argues pure dressing - furniture versus abstraction. (Axis derived 2026-08-27.)
@export_enum("props", "discs") var cast: String = "props"
@export_range(2, 4) var depth: int = 3
@export var span: float = 1.3          # base half-rod length, grows toward the root
@export var top_y: float = 3.3
## Slow per-arm drift, radians of sway amplitude. 0 freezes the mobile solid.
@export_range(0.0, 0.6, 0.01) var drift: float = 0.22

var _drift_nodes: Array = []           # {node: Node3D, base: float, rate: float, phase: float}
var _total_kg := 0.0
var _next_cast := 0

func _ready() -> void:
	_rng.seed = seed
	_next_cast = 0
	_total_kg = 0.0
	var root := _build_node(depth)
	var hang := Node3D.new()
	hang.position = Vector3(0.0, top_y, 0.0)
	add_child(hang)
	hang.add_child(root["node"])
	root["node"].position = Vector3(0.0, -0.30, 0.0)
	_wire(hang, Vector3.ZERO, Vector3(0.0, -0.30, 0.0))
	_total_kg = root["kg"]
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "depth", "span", "top_y", "drift"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(_delta: float) -> void:
	if drift <= 0.0:
		return
	var t := float(Time.get_ticks_msec()) / 1000.0
	for entry in _drift_nodes:
		var node: Node3D = entry["node"]
		if is_instance_valid(node):
			node.rotation.y = entry["base"] + drift * sin(t * entry["rate"] + entry["phase"])

# --- the balanced tree, built leaf-first exactly like calder_mobile ------------------

## Returns {node: Node3D, kg: float}. A leaf hangs one prop on a wire; an internal node
## builds both children, WEIGHS them, and places its pivot so the torques agree.
func _build_node(level: int) -> Dictionary:
	# Leaves appear early with the same probability calder uses, so the tree is ragged —
	# a full binary tree reads as a chandelier, not a mobile.
	if level <= 0 or (level < depth and _rng.randf() < 0.30):
		return _build_leaf()
	var left := _build_node(level - 1)
	var right := _build_node(level - 1)
	var node := Node3D.new()

	var rod_len := span * (0.55 + 0.5 * _rng.randf()) * (0.7 + 0.3 * float(level))
	var m_l: float = left["kg"]
	var m_r: float = right["kg"]
	# The lever law: pivot splits the rod so m_l·d_l = m_r·d_r. The heavier side gets
	# the SHORTER arm — this one line is the entire artifact.
	var d_l := rod_len * m_r / (m_l + m_r)
	var d_r := rod_len - d_l

	var rod := MeshInstance3D.new()
	var rod_mesh := CylinderMesh.new()
	# 0.012 photographed as hairline against the capture sky; 0.02 reads as steel.
	rod_mesh.top_radius = 0.02
	rod_mesh.bottom_radius = 0.02
	rod_mesh.height = rod_len
	rod.mesh = rod_mesh
	rod.rotation.z = PI * 0.5
	rod.position = Vector3((d_r - d_l) * 0.5, 0.0, 0.0)
	rod.material_override = _steel_mat(Color(0.16, 0.16, 0.18))
	node.add_child(rod)

	# Deeper drops 0.30-0.55 (was 0.22-0.40): the first capture showed sibling arms
	# crossing visually because the tiers sat too close.
	var drop_l := 0.30 + 0.25 * _rng.randf()
	var drop_r := 0.30 + 0.25 * _rng.randf()
	node.add_child(left["node"])
	left["node"].position = Vector3(-d_l, -drop_l, 0.0)
	_wire(node, Vector3(-d_l, 0.0, 0.0), Vector3(-d_l, -drop_l, 0.0))
	node.add_child(right["node"])
	right["node"].position = Vector3(d_r, -drop_r, 0.0)
	_wire(node, Vector3(d_r, 0.0, 0.0), Vector3(d_r, -drop_r, 0.0))

	_drift_nodes.append({
		"node": node,
		"base": _rng.randf_range(0.0, TAU),
		"rate": _rng.randf_range(0.10, 0.30),
		"phase": _rng.randf_range(0.0, TAU),
	})
	node.rotation.y = _drift_nodes[-1]["base"]
	return {"node": node, "kg": m_l + m_r + rod_len * ROD_KG_PER_M}

func _build_leaf() -> Dictionary:
	var cast_row: Dictionary = CAST[_next_cast % CAST.size()]
	_next_cast += 1
	var holder := Node3D.new()
	if cast == "discs":
		var palette := [Color(0.78, 0.16, 0.12), Color(0.92, 0.75, 0.14), Color(0.13, 0.30, 0.62), Color(0.10, 0.10, 0.11), Color(0.88, 0.86, 0.82)]
		var disc := MeshInstance3D.new()
		var disc_mesh := CylinderMesh.new()
		disc_mesh.top_radius = cast_row["bead"] * 0.55
		disc_mesh.bottom_radius = cast_row["bead"] * 0.55
		disc_mesh.height = 0.012
		disc.mesh = disc_mesh
		disc.position = Vector3(0.0, -cast_row["bead"] * 0.55, 0.0)
		disc.material_override = _matte_mat(palette[(_next_cast - 1) % palette.size()], 0.6)
		holder.add_child(disc)
		_wire(holder, Vector3.ZERO, disc.position)
	else:
		var wrapper := _spawn_prop(cast_row)
		holder.add_child(wrapper)
		wrapper.position = Vector3(0.0, -cast_row["bead"] * 0.55, 0.0)
		_wire(holder, Vector3.ZERO, wrapper.position)
	return {"node": holder, "kg": cast_row["kg"]}

func _wire(parent: Node3D, from: Vector3, to: Vector3) -> void:
	var wire := MeshInstance3D.new()
	var wire_mesh := CylinderMesh.new()
	wire_mesh.top_radius = 0.003
	wire_mesh.bottom_radius = 0.003
	wire_mesh.height = from.distance_to(to)
	wire.mesh = wire_mesh
	wire.position = (from + to) * 0.5
	wire.material_override = _matte_mat(Color(0.35, 0.35, 0.37), 0.5, 0.8)
	parent.add_child(wire)

# --- prop loading, shared shape with paused_fountain --------------------------------

func _spawn_prop(cast_row: Dictionary) -> Node3D:
	var wrapper := Node3D.new()
	add_child(wrapper)
	var path := "res://commons/artifacts/%s/%s.tscn" % [cast_row["token"], cast_row["token"]]
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("prop_mobile: cast prop %s missing, bead substituted" % cast_row["token"])
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		box.scale = Vector3.ONE * cast_row["bead"] * 0.7
		box.material_override = _matte_mat(Color(0.6, 0.55, 0.5))
		wrapper.add_child(box)
		wrapper.get_parent().remove_child(wrapper)
		return wrapper
	var inst: Node3D = packed.instantiate()
	wrapper.add_child(inst)
	# A cast prop may carry its OWN RigidBody3D (pickable props do). Frozen sculpture
	# beads must not shed parts under live gravity - freeze every internal body.
	var pstack: Array = [inst]
	while not pstack.is_empty():
		var pn: Node = pstack.pop_back()
		if pn is RigidBody3D:
			(pn as RigidBody3D).freeze = true
		for pc in pn.get_children():
			pstack.append(pc)
	var aabb := _merged_aabb(inst)
	var longest: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	if longest > 0.001:
		var s: float = cast_row["bead"] / longest
		inst.scale = Vector3.ONE * s
		inst.position = -(aabb.get_center() * s)
	wrapper.get_parent().remove_child(wrapper)
	return wrapper

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
			if first:
				merged = box
				first = false
			else:
				merged = merged.merge(box)
		for child in node.get_children():
			stack.append(child)
	return merged

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "MobilePlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(0.9, 0.24, 0.9)
	ts.rotation.y = deg_to_rad(-40.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("PROP MOBILE - %.1f kg AIRBORNE" % _total_kg,
			"Every arm solves w*d = w*d: the heavier prop rides the shorter arm.\nBalance is not symmetry - it is arithmetic you can hang from a ceiling.\nCalder, in drag.")
