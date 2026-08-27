extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PostmanOfPaths

## @identity
## lineage: the graph taxonomy's rung 3 — five mailboxes on posts, wired as a small
##   tree by glowing ropes, and one white letter forever in transit. It climbs toward
##   the common ancestor and descends by name, and the readout spells the address it
##   is walking: "../../kitchen/drawer".
## essence: NodePath is a ROUTE, not a location. '..' climbs an edge, a name descends
##   one; get_node() is a walk. The letter never teleports, because in a tree there is
##   exactly one simple path between any two nodes — the address IS that path.
## truth: to reach is to traverse. An address is a story about edges.
##
## The 2026-08-27 graph taxonomy (doc/GRAPHTHEORY_TAXONOMY.md), rung 3 of 13.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# the little household tree: name, parent index, position
const BOXES := [
	["hall", -1, Vector3(0.0, 1.7, 0.0)],
	["study", 0, Vector3(-1.1, 1.05, -0.3)],
	["kitchen", 0, Vector3(1.05, 1.05, 0.25)],
	["shelf", 1, Vector3(-1.6, 0.5, 0.35)],
	["drawer", 2, Vector3(1.55, 0.45, -0.35)],
]
# journeys the letter makes, and the NodePath each one IS (from the sender's box)
const ROUTES := [
	[3, 4, "../../kitchen/drawer"],
	[4, 1, "../../study"],
	[1, 3, "shelf"],
	[2, 0, ".."],
]

@export var seed: int = 42
@export var pace: float = 0.55          # metres per second along the rope

var _positions: Array = []
var _letter: Node3D
var _route := 0
var _leg := 0                           # index into the current route's node list
var _route_nodes: Array = []
var _t := 0.0
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_route = _rng.randi_range(0, ROUTES.size() - 1)
	_build_boxes()
	_build_letter()
	_build_plaque()
	_begin_route()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "pace"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- the tree of mailboxes ----------------------------------------------------------

func _build_boxes() -> void:
	for i in range(BOXES.size()):
		var pos: Vector3 = BOXES[i][2]
		_positions.append(pos)
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.03
		pm.bottom_radius = 0.04
		pm.height = pos.y
		post.mesh = pm
		post.position = Vector3(pos.x, pos.y * 0.5, pos.z)
		post.material_override = _matte_mat(Color(0.25, 0.22, 0.2), 0.85)
		add_child(post)
		var box := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.3, 0.2, 0.2)
		box.mesh = bm
		box.position = pos
		box.material_override = _matte_mat(Color.from_hsv(0.58, 0.5, 0.55 + 0.08 * float(i % 2)), 0.6)
		add_child(box)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.14
		tag.position = pos + Vector3(0.0, -0.22, 0.14)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text(BOXES[i][0], "")
		# the rope to the parent — the EDGE, glowing faintly
		var parent_i: int = BOXES[i][1]
		if parent_i >= 0:
			var a: Vector3 = _positions[parent_i]
			var rope := MeshInstance3D.new()
			var rm := CylinderMesh.new()
			rm.top_radius = 0.012
			rm.bottom_radius = 0.012
			rm.height = a.distance_to(pos)
			rope.mesh = rm
			rope.position = (a + pos) * 0.5
			var axis := Vector3.UP.cross((pos - a).normalized())
			if axis.length() > 0.001:
				rope.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot((pos - a).normalized()), -1.0, 1.0)))
			rope.material_override = _glow_mat(Color(0.9, 0.8, 0.5), 0.5)
			add_child(rope)

func _build_letter() -> void:
	_letter = Node3D.new()
	add_child(_letter)
	var paper := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.16, 0.11, 0.012)
	paper.mesh = pm
	paper.material_override = _glow_mat(Color(0.96, 0.95, 0.9), 0.8)
	_letter.add_child(paper)
	var seal := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.02
	sm.height = 0.04
	seal.mesh = sm
	seal.position = Vector3(0.0, 0.0, 0.012)
	seal.material_override = _glow_mat(Color(0.8, 0.15, 0.12), 1.2)
	_letter.add_child(seal)

# --- the walk -----------------------------------------------------------------------

func _tree_path(from_i: int, to_i: int) -> Array:
	# ancestors to root, then splice — the unique simple path in a tree
	var up_a := [from_i]
	var i := from_i
	while BOXES[i][1] >= 0:
		i = BOXES[i][1]
		up_a.append(i)
	var up_b := [to_i]
	i = to_i
	while BOXES[i][1] >= 0:
		i = BOXES[i][1]
		up_b.append(i)
	for j in range(up_a.size()):
		var k := up_b.find(up_a[j])
		if k >= 0:
			var walk := up_a.slice(0, j + 1)
			var down := up_b.slice(0, k)
			down.reverse()
			return walk + down
	return [from_i, to_i]

func _begin_route() -> void:
	var r: Array = ROUTES[_route]
	_route_nodes = _tree_path(r[0], r[1])
	_leg = 0
	_t = 0.0
	_letter.position = _positions[_route_nodes[0]] + Vector3(0.0, 0.16, 0.0)
	if _readout and _readout.has_method("set_text"):
		_readout.set_text('get_node("%s")' % r[2],
			"posted at %s, bound for %s - the address is the route" % [BOXES[r[0]][0], BOXES[r[1]][0]])

func _process(delta: float) -> void:
	if _leg >= _route_nodes.size() - 1:
		_t += delta
		if _t > 1.4:                    # a breath at the door, then the next errand
			_route = (_route + 1) % ROUTES.size()
			_begin_route()
		return
	var a: Vector3 = _positions[_route_nodes[_leg]] + Vector3(0.0, 0.16, 0.0)
	var b: Vector3 = _positions[_route_nodes[_leg + 1]] + Vector3(0.0, 0.16, 0.0)
	_t += delta * pace / maxf(a.distance_to(b), 0.05)
	if _t >= 1.0:
		_t = 0.0
		_leg += 1
		if _leg >= _route_nodes.size() - 1:
			_t = 0.0
		return
	_letter.position = a.lerp(b, _t)
	_letter.rotation.y += delta * 1.2

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "PostmanPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.5, 0.24, 0.9)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("POSTMAN OF PATHS",
			"NodePath: '..' climbs an edge, a name descends one. The letter never\nteleports - in a tree there is exactly ONE simple path between two boxes,\nand the address IS that path.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.36
	_readout.position = Vector3(1.5, 0.24, 0.9)
	_readout.rotation.y = deg_to_rad(-38.0)
	add_child(_readout)
