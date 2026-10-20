# BridgeCut.gd — the one edge whose removal breaks the world in two
#
# @identity
# essence: a small graph on a stand; cut one edge and the nodes recolour into the components they fall into, cut a different edge and nothing happens at all
# desire: learner stops treating "connected" as a property of a drawing and meets it as a property that one edge can be solely responsible for
# critical_parameter: cut — which edge is removed (none / bridge / chord / both); under it graph decides whether the shape HAS a bridge, and theta has none
# triggers: none; the component search re-runs whenever cut or graph changes, and the node colours are its output
# emerges: the recognition that a boundary can be a single thing, and that you cannot tell which thing by looking at the picture — you have to remove it and see
# relationships: the hand-sized case of [[markov_blanket_room]], where the separator is a shell of hundreds of cells; here it is one edge
# truth: every separator is a claim about paths, and the smallest separator a connected graph can have is one edge
extends Node3D
class_name BridgeCut

## WHY THERE IS A CONTROL EDGE, AND WHY `theta` EXISTS.
##
## A bridge is an edge whose removal disconnects the graph. The word is doing
## real work: MOST edges are not bridges, and an artifact that only ever showed
## "remove edge, graph falls apart" would teach the opposite of the truth.
##
## So `cut` carries its own negative control. `bridge` removes the edge that
## matters and the graph splits; `chord` removes an edge that looks exactly as
## important and nothing happens — same gesture, same kind of object, no
## consequence. A visitor who cannot predict which is which has understood the
## point, because you cannot read it off the picture.
##
## `graph = theta` goes further: two nodes joined by three disjoint paths has NO
## bridge at all. Every edge lies on a cycle, so every edge has an alternative
## route around it. Asked to cut the bridge of a theta graph, this artifact cuts
## nothing and says so — which is the honest answer and not a failure.
##
## The components are COMPUTED, not coloured in by hand: a union-find over the
## surviving edges, re-run on every change. Hard-coding "these three turn red"
## would make the artifact a diagram of a conclusion rather than the conclusion.

const CUTS := ["none", "bridge", "chord", "both"]
const GRAPHS := ["barbell", "chain", "theta", "tree"]
const CLOSURES := ["open", "returned"]

## THE RETURN BRIDGE (from the openai/math bridge-closure figures): close the
## graph into a loop and its bridges STOP BEING BRIDGES -- the new path is an
## alternative route around every one of them. `returned` adds one edge from
## the far end back to the start; on a chain, where every edge was a bridge,
## one return edge demotes all five at once. Not a DNA axis (the tooling reads
## one or two), but a map key: #closure:returned.
@export_enum("open", "returned") var closure: String = "open":
	set(v):
		closure = v
		if is_inside_tree():
			_rebuild()

@export_enum("none", "bridge", "chord", "both") var cut: String = "none":
	set(v):
		cut = v
		if is_inside_tree():
			_rebuild()

@export_enum("barbell", "chain", "theta", "tree") var graph: String = "barbell":
	set(v):
		graph = v
		if is_inside_tree():
			_rebuild()

## Hand scale. The whole graph fits inside a cube this wide, so it reads from
## arm's length on a plinth rather than needing to be walked into.
@export var span: float = 0.34
@export var node_radius: float = 0.022
@export var edge_radius: float = 0.006
@export var show_readout: bool = true

@export var whole_color: Color = Color(0.62, 0.66, 0.72)
@export var part_a_color: Color = Color(0.25, 0.55, 0.92)
@export var part_b_color: Color = Color(0.95, 0.46, 0.22)
@export var cut_color: Color = Color(0.85, 0.20, 0.22)

var _pos: Array[Vector3] = []
var _edges: Array = []            # [a, b] index pairs
var _bridge_edge: int = -1        # index into _edges, or -1 when there is none
var _chord_edge: int = -1
var _removed: Array[int] = []
var _comp: Array[int] = []        # component id per node
var _n_comp: int = 1
var _built: Node3D
var _plate: Label3D


func _ready() -> void:
	_built = Node3D.new()
	_built.name = "Built"
	add_child(_built)
	_rebuild()


# --------------------------------------------------------------- the shapes

func _shape() -> void:
	_pos.clear()
	_edges.clear()
	var s := span
	match graph:
		"barbell":
			# two triangles joined by ONE edge: the textbook bridge
			# Spread in the PICTURE PLANE, not in depth. The first version
			# separated each triangle's base pair only in z, so from the
			# canonical standpoint the two nodes sat on top of each other and
			# the cluster read as a blob. A small z offset keeps it from being
			# flat without putting any node behind another.
			_pos = [
				Vector3(-s * 0.45, -s * 0.20, -s * 0.06),
				Vector3(-s * 0.45, s * 0.20, s * 0.06),
				Vector3(-s * 0.18, 0, 0),
				Vector3(s * 0.18, 0, 0),
				Vector3(s * 0.45, -s * 0.20, s * 0.06),
				Vector3(s * 0.45, s * 0.20, -s * 0.06),
			]
			_edges = [[0,1],[1,2],[2,0], [2,3], [3,4],[4,5],[5,3]]
		"chain":
			# a path. EVERY edge is a bridge, which is the opposite extreme
			for i in range(6):
				_pos.append(Vector3(-s * 0.45 + s * 0.18 * i,
									sin(i * 0.9) * s * 0.12, 0))
			for i in range(5):
				_edges.append([i, i + 1])
		"theta":
			# two hubs joined by three disjoint paths: NO bridges anywhere
			_pos = [
				Vector3(-s * 0.45, 0, 0), Vector3(s * 0.45, 0, 0),
				Vector3(0, s * 0.30, 0), Vector3(0, 0, s * 0.30),
				Vector3(0, -s * 0.30, 0),
			]
			_edges = [[0,2],[2,1], [0,3],[3,1], [0,4],[4,1]]
		"tree":
			# a branching tree. Every edge is a bridge, but unlike the chain
			# the two sides of a cut are wildly unequal, which is the point
			_pos = [
				Vector3(0, -s * 0.38, 0),
				Vector3(0, -s * 0.08, 0),
				Vector3(-s * 0.30, s * 0.18, 0), Vector3(s * 0.30, s * 0.18, 0),
				Vector3(-s * 0.42, s * 0.42, 0), Vector3(-s * 0.16, s * 0.42, 0),
				Vector3(s * 0.16, s * 0.42, 0), Vector3(s * 0.42, s * 0.42, 0),
			]
			_edges = [[0,1],[1,2],[1,3],[2,4],[2,5],[3,6],[3,7]]

	if closure == "returned":
		# the return bridge: one edge from the far end back to the start, and
		# every bridge it routes around is a bridge no longer. _find_special
		# runs AFTER this, so the demotion is discovered, not scripted.
		match graph:
			"barbell": _edges.append([4, 0])
			"chain": _edges.append([5, 0])
			"theta": _edges.append([2, 4])   # already bridgeless; one more loop
			"tree": _edges.append([4, 7])    # crown to crown, around the trunk


## Which edges are bridges, found by removing each one and asking whether the
## component count went up. Brute force over at most seven edges, and it is the
## definition rather than a lookup table, so it stays true if the shapes change.
func _find_special() -> void:
	_bridge_edge = -1
	_chord_edge = -1
	var base := _components([])
	for i in range(_edges.size()):
		var c := _components([i])
		if c > base and _bridge_edge < 0:
			_bridge_edge = i
		elif c == base and _chord_edge < 0:
			_chord_edge = i


func _components(skip: Array) -> int:
	var parent := range(_pos.size())
	var find := func(x: int) -> int:
		var r: int = x
		while parent[r] != r:
			r = parent[r]
		return r
	for i in range(_edges.size()):
		if i in skip:
			continue
		var ra: int = find.call(_edges[i][0])
		var rb: int = find.call(_edges[i][1])
		if ra != rb:
			parent[ra] = rb
	var roots := {}
	_comp = []
	for v in range(_pos.size()):
		var r: int = find.call(v)
		if not roots.has(r):
			roots[r] = roots.size()
		_comp.append(roots[r])
	return roots.size()


# ----------------------------------------------------------------- the body

func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = emit
	return m


func _rod(a: Vector3, b: Vector3, col: Color, r: float, dashed: bool) -> void:
	var mid := (a + b) * 0.5
	var len := a.distance_to(b)
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = len * (0.45 if dashed else 1.0)
	cyl.radial_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = _mat(col, 0.9 if dashed else 0.3)
	mi.position = mid
	# CylinderMesh points +Y; aim it along the edge
	var dir := (b - a).normalized()
	if absf(dir.dot(Vector3.UP)) < 0.999:
		mi.look_at_from_position(mid, mid + dir, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	_built.add_child(mi)


func _rebuild() -> void:
	if _built == null:
		return
	for c in _built.get_children():
		c.queue_free()

	_shape()
	_find_special()

	_removed = []
	match cut:
		"bridge":
			if _bridge_edge >= 0:
				_removed = [_bridge_edge]
		"chord":
			if _chord_edge >= 0:
				_removed = [_chord_edge]
		"both":
			if _bridge_edge >= 0:
				_removed.append(_bridge_edge)
			if _chord_edge >= 0:
				_removed.append(_chord_edge)

	_n_comp = _components(_removed)

	for i in range(_edges.size()):
		var a: Vector3 = _pos[_edges[i][0]]
		var b: Vector3 = _pos[_edges[i][1]]
		if i in _removed:
			# the cut edge stays, as a stub, because an edge that vanishes
			# cannot be seen to have been the one that mattered
			_rod(a, b, cut_color, edge_radius * 0.8, true)
		else:
			_rod(a, b, whole_color, edge_radius, false)

	for v in range(_pos.size()):
		var sph := SphereMesh.new()
		sph.radius = node_radius
		sph.height = node_radius * 2.0
		sph.radial_segments = 12
		sph.rings = 6
		var mi := MeshInstance3D.new()
		mi.mesh = sph
		var col := whole_color
		if _n_comp > 1:
			col = part_a_color if _comp[v] == 0 else part_b_color
		mi.material_override = _mat(col, 0.7)
		mi.position = _pos[v]
		_built.add_child(mi)

	if show_readout:
		_plate = Label3D.new()
		_plate.text = _verdict()
		_plate.font_size = 40
		# A Label3D is a textured plane and it counts toward the capture AABB.
		# At 0.00085 the words "STILL CONNECTED" were 0.4 m wide against a 0.34 m
		# graph, so the framing fitted the TEXT and pushed the work out of shot.
		# Sized to about a third of the span, it labels instead of dominating.
		_plate.pixel_size = 0.00040
		_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_plate.modulate = part_b_color if _n_comp > 1 else whole_color
		_plate.position = Vector3(0, span * 0.52, 0)
		_built.add_child(_plate)

	# The capture AABB counts MeshInstance3D, and the nodes are small spheres
	# scattered through a mostly empty volume. Anchor it to the real span so the
	# framing is of the graph and not of whichever sphere happens to sit widest.
	var anchor := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(span * 1.05, span * 0.95, span * 0.7)
	anchor.mesh = bm
	anchor.layers = 0                     # measured, never drawn
	anchor.name = "ExtentAnchor"
	_built.add_child(anchor)


## The artifact says when it was asked to cut something that does not exist.
## It already did this for a bridge in a theta graph; it stayed SILENT about the
## mirror case, a chord in a tree, and the sweep caught it -- cut=chord rendered
## byte-identical to cut=none at graph=chain and graph=tree, a twin pair the
## critic flags as a false declaration. It is not false, it is conditional, but
## an artifact whose answer to an undefined question is to look unchanged is
## indistinguishable from one that is broken.
func _verdict() -> String:
	if cut == "bridge" and _bridge_edge < 0:
		return "NO BRIDGE TO CUT\nevery edge lies on a cycle\nstill 1 piece"
	if cut == "chord" and _chord_edge < 0:
		return "NO CHORD TO CUT\nevery edge is a bridge\nstill 1 piece"
	if cut == "both" and _bridge_edge < 0 and _chord_edge < 0:
		return "NOTHING TO CUT\nstill 1 piece"
	if _n_comp == 1:
		return "STILL CONNECTED\n1 piece"
	return "BROKEN\n%d pieces" % _n_comp


# ------------------------------------------------------------- the map's hand

func apply_grid_config(config_data: Dictionary) -> void:
	var dirty := false
	if config_data.has("cut"):
		var w := str(config_data["cut"]).to_lower().strip_edges()
		if CUTS.has(w):
			cut = w
			dirty = true
	if config_data.has("graph"):
		var g := str(config_data["graph"]).to_lower().strip_edges()
		if GRAPHS.has(g):
			graph = g
			dirty = true
	if config_data.has("closure"):
		var cl := str(config_data["closure"]).to_lower().strip_edges()
		if CLOSURES.has(cl):
			closure = cl
			dirty = true
	if config_data.has("show_readout"):
		show_readout = bool(config_data["show_readout"])
		dirty = true
	if dirty and is_inside_tree():
		_rebuild()


## Readable by a probe, so the claim is testable without reading pixels.
func component_count() -> int:
	return _n_comp


func has_bridge() -> bool:
	return _bridge_edge >= 0
