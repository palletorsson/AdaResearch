extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PropCarousel

## @identity
## lineage: the Centripetal category's hero, elevating centrifuge_ring — a fairground
##   carousel whose riders are the museum's own props on chains: an extinguisher, a
##   crate, an exit sign, circling under a Calder-palette canopy. The chains hang
##   OUTWARD at exactly the honest angle, and that angle is the whole lesson.
## essence: nothing pulls outward. The chain leans because it must pull IN —
##   tan φ = ω²r/g, the resultant of gravity and the centre-seeking pull the circle
##   demands. Constant acceleration toward a centre you never reach: a = v²/r.
## truth: the "outward force" is furniture's misreading of its own chain. Ask the chain:
##   every newton in it points at the middle or at the sky.
##
## The 2026-08-27 brief: surreal, fun, beautiful, applied. A fairground in a physics
## hall, spinning slowly enough to read.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const PALETTE := [Color(0.78, 0.16, 0.12), Color(0.92, 0.75, 0.14), Color(0.13, 0.30, 0.62), Color(0.10, 0.10, 0.11), Color(0.88, 0.86, 0.82)]
const RIDERS := [
	{"token": "fire_extinguisher", "bead": 0.34},
	{"token": "crate", "bead": 0.30},
	{"token": "exit_sign", "bead": 0.28},
	{"token": "control_pendulum", "bead": 0.30},
	{"token": "chladni_plate", "bead": 0.26},
	{"token": "fire_extinguisher", "bead": 0.28},
]

@export var seed: int = 12
@export var radius: float = 1.45       # chain anchor radius on the crown
@export var crown_y: float = 2.5
## Revolutions per minute. 9 rpm → ω = 0.94 rad/s → tan φ = ω²r/g ≈ 0.13: a legible
## 7.5° lean. Doubling rpm quadruples the lean, which is the knob's whole argument.
@export var rpm: float = 9.0
@export var chain_len: float = 1.15

var _hub: Node3D
var _omega := 0.0

func _ready() -> void:
	_rng.seed = seed
	_omega = rpm * TAU / 60.0
	_build_frame()
	_build_riders()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "radius", "rpm", "chain_len"]:
		if config_data.has(key):
			set(key, config_data[key])
	_omega = rpm * TAU / 60.0

func _process(delta: float) -> void:
	if _hub:
		_hub.rotation.y += _omega * delta

# --- the machine --------------------------------------------------------------------

func _build_frame() -> void:
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = radius + 0.55
	base_mesh.bottom_radius = radius + 0.65
	base_mesh.height = 0.12
	base.mesh = base_mesh
	base.position = Vector3(0.0, 0.06, 0.0)
	base.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(base)

	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.09
	pole_mesh.bottom_radius = 0.12
	pole_mesh.height = crown_y
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, crown_y * 0.5 + 0.12, 0.0)
	pole.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(pole)

	_hub = Node3D.new()
	_hub.position = Vector3(0.0, crown_y + 0.12, 0.0)
	add_child(_hub)

	# the canopy: a shallow cone of Calder-palette wedges, because the gallery is
	# one family and a carousel without a roof is just a hazard
	for i in range(10):
		var wedge := MeshInstance3D.new()
		var wedge_mesh := PrismMesh.new()
		wedge_mesh.size = Vector3(0.95, 0.05, radius + 0.35)
		wedge.mesh = wedge_mesh
		var ang := TAU * float(i) / 10.0
		wedge.position = Vector3(cos(ang) * (radius + 0.35) * 0.5, 0.22, sin(ang) * (radius + 0.35) * 0.5)
		wedge.rotation.y = -ang + PI * 0.5
		wedge.rotation.x = 0.24
		wedge.material_override = _matte_mat(PALETTE[i % PALETTE.size()], 0.7)
		_hub.add_child(wedge)
	var finial := MeshInstance3D.new()
	var finial_mesh := SphereMesh.new()
	finial_mesh.radius = 0.11
	finial_mesh.height = 0.22
	finial.mesh = finial_mesh
	finial.position = Vector3(0.0, 0.42, 0.0)
	finial.material_override = _glow_mat(Color(0.92, 0.75, 0.14), 1.2)
	_hub.add_child(finial)

# --- the riders ---------------------------------------------------------------------

func _build_riders() -> void:
	# tan φ = ω²·r_ride / g, with r_ride the RIDER's radius (anchor + lean throw).
	# Solved once, honestly, then built static under the spinning hub: the physics is
	# in the ANGLE, the motion is display. Solving the implicit equation by four rounds
	# of fixed point — it converges fast because chain_len·sinφ ≪ r.
	var g := 9.81
	var phi := 0.0
	for k in range(4):
		var r_ride := radius + sin(phi) * chain_len
		phi = atan(_omega * _omega * r_ride / g)
	for i in range(RIDERS.size()):
		var row: Dictionary = RIDERS[i]
		var ang := TAU * float(i) / float(RIDERS.size())
		var seat := Node3D.new()
		seat.rotation.y = -ang
		_hub.add_child(seat)
		var anchor := Vector3(radius, -0.02, 0.0)
		var chain_end := anchor + Vector3(sin(phi) * chain_len, -cos(phi) * chain_len, 0.0)
		var chain := MeshInstance3D.new()
		var chain_mesh := CylinderMesh.new()
		chain_mesh.top_radius = 0.008
		chain_mesh.bottom_radius = 0.008
		chain_mesh.height = chain_len
		chain.mesh = chain_mesh
		chain.position = (anchor + chain_end) * 0.5
		chain.rotation.z = -phi
		chain.material_override = _matte_mat(Color(0.35, 0.35, 0.37), 0.5, 0.8)
		seat.add_child(chain)
		var wrapper := _spawn_prop(row["token"], row["bead"])
		seat.add_child(wrapper)
		wrapper.position = chain_end + Vector3(0.0, -row["bead"] * 0.5, 0.0)
		wrapper.rotation.z = -phi * 0.6      # riders lean with their chains, imperfectly

func _spawn_prop(token: String, bead: float) -> Node3D:
	var wrapper := Node3D.new()
	add_child(wrapper)
	var packed: PackedScene = load("res://commons/artifacts/%s/%s.tscn" % [token, token])
	if packed == null:
		push_warning("prop_carousel: cast prop %s missing, bead substituted" % token)
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		box.scale = Vector3.ONE * bead * 0.7
		box.material_override = _matte_mat(Color(0.6, 0.55, 0.5))
		wrapper.add_child(box)
		remove_child(wrapper)
		return wrapper
	var inst: Node3D = packed.instantiate()
	wrapper.add_child(inst)
	var pstack: Array = [inst]
	while not pstack.is_empty():
		var pn: Node = pstack.pop_back()
		if pn is RigidBody3D:
			(pn as RigidBody3D).freeze = true
		for pc in pn.get_children():
			pstack.append(pc)
	var aabb := _merged_aabb(inst)
	var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if longest > 0.001:
		var k: float = bead / longest
		inst.scale = Vector3.ONE * k
		inst.position = -(aabb.get_center() * k)
	remove_child(wrapper)
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
			merged = box if first else merged.merge(box)
			first = false
		for child in node.get_children():
			stack.append(child)
	return merged

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var g := 9.81
	var phi_deg := rad_to_deg(atan(_omega * _omega * radius / g))
	var ts := TextScreenScript.new()
	ts.name = "CarouselPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-(radius + 0.8), 0.24, 0.8)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("PROP CAROUSEL - a = v2/r",
			("Nothing pulls outward: the chain leans %.0f° because it must pull IN.\n"
			 + "tan(lean) = w2r/g - double the spin, quadruple the lean.\n"
			 + "Constant acceleration toward a centre the riders never reach.") % phi_deg)
