extends Node3D
class_name GarbageCollectorDemo

# @identity
# essence: a 6 x 6 heap of cells wired into a live object graph, a root-set pillar at one edge, and a loop that drops exactly one reference, walks the graph breadth-first from the roots, and then sweeps — greying an island of cells that are still busily pointing at each other and still condemned
# desire: to stage the sentence a mark-and-sweep collector actually enforces, which is not "delete what is unused" but "delete what cannot be reached", and to make the difference between those two sentences visible in one cycle
# critical_parameter: the size of the detached island — the subtree the dropped reference was holding; small and the sweep looks like tidying, large and it reads as what it is, a mass condemnation of objects nothing was wrong with
# triggers: _process runs a five-phase clock — LIVE holds the connected graph, DROP cuts one bridge edge in red, MARK lights each BFS frontier green in turn, SWEEP walks all 36 cells in index order greying the unlit ones into a free-list strip, HOLD states the count, then the graph regenerates on a new seed
# emerges: the island's internal edges stay bright right up until the sweep reaches them — you watch a working, self-consistent little structure be collected, and the collector is not wrong
# needs: BoxMesh cells with per-cell StandardMaterial3D [mutated live, so no sharing]; CylinderMesh reference edges; Label3D readout; a spanning-tree generator with a chosen bridge, so the island is guaranteed to detach
# relationships: the memory rung of the resourcemanagement sequence — where an allocator artifact shows space being claimed, this shows the condition under which space is taken back, and that condition is topological, not moral
# truth: unreachability condemns, not uselessness. The collector never asks whether an object still works; it asks whether anyone can still get to it, and an island of perfectly functional objects that reference only each other is garbage by definition.

## 2 x 1 x 2 m. A heap on a low table, a root set at one edge, and a
## mark-and-sweep cycle that runs forever on freshly generated graphs.

@export var heap_cols: int = 6
@export var heap_rows: int = 6
@export var root_count: int = 3
@export var extra_edges: int = 9
@export var live_seconds: float = 1.8
@export var drop_seconds: float = 1.2
@export var mark_step_seconds: float = 0.32
@export var sweep_step_seconds: float = 0.07
@export var hold_seconds: float = 2.2

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

const PITCH := 0.24
const CELL := 0.14
const PLATE_Y := 0.50
const PLATE_T := 0.04
const CELL_Y := PLATE_Y + PLATE_T * 0.5 + CELL * 0.5
const PILLAR_X := -0.82
const PILLAR_TOP := 0.95
const STRIP_Z := 0.66
const STRIP_W := 1.20

const C_ALLOC := Color(0.60, 0.68, 0.82)
const C_MARKED := Color(0.34, 0.95, 0.55)
const C_SWEPT := Color(0.21, 0.22, 0.26)
const C_ROOT := Color(1.00, 0.72, 0.26)
const C_CUT := Color(1.00, 0.30, 0.30)
const C_EDGE := Color(0.46, 0.54, 0.70)

enum Phase { LIVE, DROP, MARK, SWEEP, HOLD }

var _built: bool = false
var _created: Array[Node] = []

var _graph: Node3D                  # regenerated every cycle; the frame is not
var _readout: Label3D
var _strip: MeshInstance3D
var _sweep_head: MeshInstance3D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _cycle: int = 0

var _cells: Array = []              # [{node, mat, marked, swept}]
var _edges: Array = []              # [{a, b, node, mat, cut, lit}]
var _root_ids: Array = []
var _island: Array = []             # cell ids the dropped reference was holding
var _bridge: int = -1               # index into _edges
var _levels: Array = []             # BFS frontiers, computed at MARK start

var _phase: int = Phase.LIVE
var _t: float = 0.0
var _mark_level: int = 0
var _sweep_i: int = 0
var _freed: int = 0


func _ready() -> void:
	_build_all()
	_built = true
	set_process(true)


# ─────────────────────────────────────────────────────────────────────
# THE STANDING FRAME — built once, never regenerated
# ─────────────────────────────────────────────────────────────────────

func _build_all() -> void:
	_build_table()
	_build_pillar()
	_build_strip()
	_build_readout()
	_graph = Node3D.new()
	_graph.name = "ObjectGraph"
	_spawn(_graph)
	_sweep_head = _make_sweep_head()
	_spawn(_sweep_head)
	_new_cycle()


func _build_table() -> void:
	var plate := MeshInstance3D.new()
	plate.name = "HeapPlate"
	var box := BoxMesh.new()
	box.size = Vector3(1.80, PLATE_T, 1.50)
	plate.mesh = box
	plate.position = Vector3(0.0, PLATE_Y, 0.0)
	plate.material_override = _grid_material(Color(0.16, 0.17, 0.21), Color(0.36, 0.44, 0.58), 0.5)
	_spawn(plate)
	var leg_mat: Material = _grid_material(Color(0.20, 0.21, 0.25), Color(0.34, 0.38, 0.48), 0.3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var leg := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.035
			cyl.bottom_radius = 0.045
			cyl.height = PLATE_Y
			cyl.radial_segments = 8
			leg.mesh = cyl
			leg.position = Vector3(float(sx) * 0.78, PLATE_Y * 0.5, float(sz) * 0.62)
			leg.material_override = leg_mat
			_spawn(leg)


## The root set: the stack, the globals, the registers — the places a collector
## is allowed to start from. Everything else in the room has to be reached.
func _build_pillar() -> void:
	var col := MeshInstance3D.new()
	col.name = "RootSet"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.055
	cyl.bottom_radius = 0.075
	cyl.height = PILLAR_TOP - PLATE_Y
	cyl.radial_segments = 10
	col.mesh = cyl
	col.position = Vector3(PILLAR_X, (PILLAR_TOP + PLATE_Y) * 0.5, 0.0)
	col.material_override = _emissive_mat(C_ROOT, 1.3)
	_spawn(col)
	var cap := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(0.16, 0.05, 0.16)
	cap.mesh = cb
	cap.position = Vector3(PILLAR_X, PILLAR_TOP, 0.0)
	cap.material_override = _emissive_mat(C_ROOT, 1.8)
	_spawn(cap)
	var label := Label3D.new()
	label.text = "ROOTS"
	label.font_size = 20
	label.outline_size = 5
	label.modulate = C_ROOT
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(PILLAR_X, PILLAR_TOP + 0.14, 0.0)
	_spawn(label)


## Where the swept cells go. It grows from the left as the sweep frees them, so
## the strip is a running total of the condemnation, not a decoration.
func _build_strip() -> void:
	var bed := MeshInstance3D.new()
	bed.name = "FreeListBed"
	var bb := BoxMesh.new()
	bb.size = Vector3(STRIP_W, 0.012, 0.09)
	bed.mesh = bb
	bed.position = Vector3(0.0, PLATE_Y + PLATE_T * 0.5 + 0.006, STRIP_Z)
	bed.material_override = _emissive_mat(Color(0.16, 0.17, 0.20), 0.0)
	_spawn(bed)

	_strip = MeshInstance3D.new()
	_strip.name = "FreeList"
	var sb := BoxMesh.new()
	sb.size = Vector3(STRIP_W, 0.022, 0.07)
	_strip.mesh = sb
	_strip.material_override = _emissive_mat(Color(0.55, 0.58, 0.64), 0.35)
	_strip.position = Vector3(-STRIP_W * 0.5, PLATE_Y + PLATE_T * 0.5 + 0.018, STRIP_Z)
	_strip.scale = Vector3(0.0001, 1.0, 1.0)
	_spawn(_strip)

	var label := Label3D.new()
	label.text = "FREE LIST"
	label.font_size = 16
	label.outline_size = 4
	label.modulate = Color(0.72, 0.76, 0.84)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, PLATE_Y + 0.10, STRIP_Z + 0.10)
	_spawn(label)


func _build_readout() -> void:
	_readout = Label3D.new()
	_readout.text = "HEAP"
	_readout.font_size = 26
	_readout.outline_size = 6
	_readout.modulate = Color(0.88, 0.92, 1.0)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.position = Vector3(0.0, 1.22, 0.0)
	_spawn(_readout)

	var caption := Label3D.new()
	caption.text = "unreachable, not useless"
	caption.font_size = 18
	caption.outline_size = 4
	caption.modulate = Color(0.70, 0.76, 0.88)
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.position = Vector3(0.0, 1.08, 0.0)
	_spawn(caption)


func _make_sweep_head() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "SweepHead"
	var box := BoxMesh.new()
	box.size = Vector3(CELL + 0.06, 0.012, CELL + 0.06)
	mi.mesh = box
	mi.material_override = _emissive_mat(Color(1.0, 0.94, 0.62), 2.2)
	mi.visible = false
	return mi


# ─────────────────────────────────────────────────────────────────────
# GRAPH GENERATION — a spanning tree with a chosen bridge
# ─────────────────────────────────────────────────────────────────────

func _cell_count() -> int:
	return maxi(1, heap_cols) * maxi(1, heap_rows)


func _cell_pos(idx: int) -> Vector3:
	var cols: int = maxi(1, heap_cols)
	var i: int = idx % cols
	var j: int = idx / cols
	var x: float = (float(i) - float(cols - 1) * 0.5) * PITCH
	var z: float = (float(j) - float(maxi(1, heap_rows) - 1) * 0.5) * PITCH
	return Vector3(x, CELL_Y, z)


## Build a fresh heap: cells, a spanning tree rooted at the root set, a chosen
## bridge whose removal detaches a sizeable island, and extra edges that never
## cross the bridge — so the island really is unreachable once the drop happens,
## and really does still reference itself.
func _new_cycle() -> void:
	_cycle += 1
	_rng.seed = 20260728 + _cycle * 7919
	for c in _graph.get_children():
		_graph.remove_child(c)
		c.queue_free()
	_cells.clear()
	_edges.clear()
	_root_ids.clear()
	_island.clear()
	_levels.clear()
	_bridge = -1
	_freed = 0
	_sweep_i = 0
	_mark_level = 0
	if is_instance_valid(_strip):
		_strip.scale = Vector3(0.0001, 1.0, 1.0)
	if is_instance_valid(_sweep_head):
		_sweep_head.visible = false

	var n: int = _cell_count()
	for i in n:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(CELL, CELL, CELL)
		mi.mesh = box
		mi.position = _cell_pos(i)
		var mat: StandardMaterial3D = _emissive_mat(C_ALLOC, 0.4)
		mi.material_override = mat
		_graph.add_child(mi)
		_cells.append({"node": mi, "mat": mat, "marked": false, "swept": false})

	# a random attachment order, so no cycle looks like the last one
	var perm: Array = []
	for i in n:
		perm.append(i)
	for i in range(n - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp = perm[i]
		perm[i] = perm[j]
		perm[j] = tmp

	var roots: int = clampi(root_count, 1, maxi(1, n - 6))
	var parent: Array = []
	for i in n:
		parent.append(-1)
	for k in roots:
		_root_ids.append(int(perm[k]))
	var attached: Array = _root_ids.duplicate()
	for k in range(roots, n):
		var v: int = int(perm[k])
		var p: int = int(attached[_rng.randi_range(0, attached.size() - 1)])
		parent[v] = p
		attached.append(v)

	# subtree sizes: perm is a valid topological order, so a reverse pass works
	var size: Array = []
	for i in n:
		size.append(1)
	for k in range(n - 1, roots - 1, -1):
		var v: int = int(perm[k])
		var p: int = int(parent[v])
		if p >= 0:
			size[p] = int(size[p]) + int(size[v])

	# the island: a subtree big enough that its collection reads as a verdict
	var candidates: Array = []
	var fallback: Array = []
	for k in range(roots, n):
		var v: int = int(perm[k])
		var s: int = int(size[v])
		if s >= 4 and s <= 10:
			candidates.append(v)
		elif s >= 2:
			fallback.append(v)
	var island_root: int = -1
	if candidates.size() > 0:
		island_root = int(candidates[_rng.randi_range(0, candidates.size() - 1)])
	elif fallback.size() > 0:
		island_root = int(fallback[_rng.randi_range(0, fallback.size() - 1)])

	var in_island: Array = []
	for i in n:
		in_island.append(false)
	if island_root >= 0:
		in_island[island_root] = true
		for k in range(roots, n):
			var v: int = int(perm[k])
			var p: int = int(parent[v])
			if p >= 0 and bool(in_island[p]):
				in_island[v] = true
		for i in n:
			if bool(in_island[i]):
				_island.append(i)

	# tree edges (the bridge is the island root's parent edge)
	for k in range(roots, n):
		var v: int = int(perm[k])
		var p: int = int(parent[v])
		var idx: int = _add_edge(p, v)
		if v == island_root:
			_bridge = idx

	# extra edges, confined to one side of the bridge or the other. Inside the
	# island they are what makes it look alive; outside they make the reachable
	# region a graph rather than a tree, so MARK is a real traversal.
	var tries: int = maxi(0, extra_edges) * 6
	var added: int = 0
	while added < maxi(0, extra_edges) and tries > 0:
		tries -= 1
		var a: int = _rng.randi_range(0, n - 1)
		var b: int = _rng.randi_range(0, n - 1)
		if a == b:
			continue
		if bool(in_island[a]) != bool(in_island[b]):
			continue
		if _has_edge(a, b):
			continue
		_add_edge(a, b)
		added += 1

	# the root set's own references
	for r in _root_ids:
		var cell: Dictionary = _cells[int(r)]
		var node: MeshInstance3D = cell["node"]
		var mat: StandardMaterial3D = _emissive_mat(C_ROOT, 1.0)
		var e := _edge_mesh(Vector3(PILLAR_X, PILLAR_TOP - 0.05, 0.0), node.position, 0.010, mat)
		_graph.add_child(e)

	_phase = Phase.LIVE
	_t = 0.0
	_update_readout()


func _has_edge(a: int, b: int) -> bool:
	for e in _edges:
		var ed: Dictionary = e
		var ea: int = int(ed["a"])
		var eb: int = int(ed["b"])
		if (ea == a and eb == b) or (ea == b and eb == a):
			return true
	return false


func _add_edge(a: int, b: int) -> int:
	var ca: Dictionary = _cells[a]
	var cb: Dictionary = _cells[b]
	var na: MeshInstance3D = ca["node"]
	var nb: MeshInstance3D = cb["node"]
	var mat: StandardMaterial3D = _emissive_mat(C_EDGE, 0.5)
	var mi: MeshInstance3D = _edge_mesh(na.position, nb.position, 0.008, mat)
	_graph.add_child(mi)
	_edges.append({"a": a, "b": b, "node": mi, "mat": mat, "cut": false, "lit": false})
	return _edges.size() - 1


func _edge_mesh(p1: Vector3, p2: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var d: float = maxf(p1.distance_to(p2), 0.001)
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = d
	cyl.radial_segments = 6
	cyl.rings = 1
	mi.mesh = cyl
	var dir: Vector3 = (p2 - p1).normalized()
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var xa: Vector3 = up.cross(dir).normalized()
	var za: Vector3 = dir.cross(xa).normalized()
	mi.transform = Transform3D(Basis(xa, dir, za), (p1 + p2) * 0.5)
	mi.material_override = mat
	return mi


# ─────────────────────────────────────────────────────────────────────
# THE CYCLE
# ─────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	match _phase:
		Phase.LIVE:
			if _t >= live_seconds:
				_enter_drop()
		Phase.DROP:
			_animate_cut()
			if _t >= drop_seconds:
				_enter_mark()
		Phase.MARK:
			if _t >= mark_step_seconds:
				_t = 0.0
				_mark_step()
		Phase.SWEEP:
			if _t >= sweep_step_seconds:
				_t = 0.0
				_sweep_step()
		Phase.HOLD:
			if _t >= hold_seconds:
				_new_cycle()


func _enter_drop() -> void:
	_phase = Phase.DROP
	_t = 0.0
	_update_readout()


## The dropped reference flashes before it goes. Everything downstream of it is
## still working, still linked, still lit — that is the state the collector is
## about to condemn, and it has to be seen intact first.
func _animate_cut() -> void:
	if _bridge < 0 or _bridge >= _edges.size():
		return
	var ed: Dictionary = _edges[_bridge]
	var mat: StandardMaterial3D = ed["mat"]
	var f: float = clampf(_t / maxf(0.001, drop_seconds), 0.0, 1.0)
	mat.albedo_color = C_EDGE.lerp(C_CUT, f)
	mat.emission = C_CUT
	mat.emission_energy_multiplier = 0.6 + 2.4 * absf(sin(_t * 12.0))
	var node: MeshInstance3D = ed["node"]
	node.scale = Vector3(1.0 + f * 0.8, 1.0, 1.0 + f * 0.8)


func _enter_mark() -> void:
	if _bridge >= 0 and _bridge < _edges.size():
		var ed: Dictionary = _edges[_bridge]
		ed["cut"] = true
		var node: MeshInstance3D = ed["node"]
		node.visible = false
	_compute_levels()
	_mark_level = 0
	_phase = Phase.MARK
	_t = 0.0
	_update_readout()


## Breadth-first from the root set over every edge that still exists. The order
## is the collector's order; the frontier is what "reachable" means operationally.
func _compute_levels() -> void:
	var n: int = _cell_count()
	var adj: Array = []
	for i in n:
		adj.append([])
	for e in _edges:
		var ed: Dictionary = e
		if bool(ed["cut"]):
			continue
		var a: int = int(ed["a"])
		var b: int = int(ed["b"])
		adj[a].append(b)
		adj[b].append(a)
	var seen: Array = []
	for i in n:
		seen.append(false)
	var frontier: Array = []
	for r in _root_ids:
		var ri: int = int(r)
		if not bool(seen[ri]):
			seen[ri] = true
			frontier.append(ri)
	_levels = []
	while frontier.size() > 0:
		_levels.append(frontier)
		var nxt: Array = []
		for f in frontier:
			var cur: Array = adj[int(f)]
			for nb in cur:
				var ni: int = int(nb)
				if not bool(seen[ni]):
					seen[ni] = true
					nxt.append(ni)
		frontier = nxt


func _mark_step() -> void:
	if _mark_level >= _levels.size():
		_enter_sweep()
		return
	var level: Array = _levels[_mark_level]
	for v in level:
		var cell: Dictionary = _cells[int(v)]
		cell["marked"] = true
		var mat: StandardMaterial3D = cell["mat"]
		mat.albedo_color = C_MARKED
		mat.emission = C_MARKED
		mat.emission_energy_multiplier = 1.7
	# light every edge whose two ends are now both reached
	for e in _edges:
		var ed: Dictionary = e
		if bool(ed["cut"]) or bool(ed["lit"]):
			continue
		var ca: Dictionary = _cells[int(ed["a"])]
		var cb: Dictionary = _cells[int(ed["b"])]
		if bool(ca["marked"]) and bool(cb["marked"]):
			ed["lit"] = true
			var em: StandardMaterial3D = ed["mat"]
			em.albedo_color = C_MARKED
			em.emission = C_MARKED
			em.emission_energy_multiplier = 1.2
	_mark_level += 1
	_update_readout()


func _enter_sweep() -> void:
	_phase = Phase.SWEEP
	_sweep_i = 0
	_t = 0.0
	if is_instance_valid(_sweep_head):
		_sweep_head.visible = true
	_update_readout()


## The sweep visits every cell in address order, not just the doomed ones — that
## linear walk over the whole heap is the cost the algorithm actually pays.
func _sweep_step() -> void:
	var n: int = _cell_count()
	if _sweep_i >= n:
		if is_instance_valid(_sweep_head):
			_sweep_head.visible = false
		_phase = Phase.HOLD
		_t = 0.0
		_update_readout()
		return
	var idx: int = _sweep_i
	if is_instance_valid(_sweep_head):
		var p: Vector3 = _cell_pos(idx)
		_sweep_head.position = Vector3(p.x, PLATE_Y + PLATE_T * 0.5 + 0.008, p.z)
	var cell: Dictionary = _cells[idx]
	if not bool(cell["marked"]):
		cell["swept"] = true
		var mat: StandardMaterial3D = cell["mat"]
		mat.albedo_color = C_SWEPT
		mat.emission = C_SWEPT
		mat.emission_energy_multiplier = 0.0
		var node: MeshInstance3D = cell["node"]
		node.scale = Vector3(0.55, 0.35, 0.55)
		# its references go with it
		for e in _edges:
			var ed: Dictionary = e
			if int(ed["a"]) == idx or int(ed["b"]) == idx:
				var en: MeshInstance3D = ed["node"]
				en.visible = false
		_freed += 1
		_grow_strip()
	_sweep_i += 1
	_update_readout()


func _grow_strip() -> void:
	if not is_instance_valid(_strip):
		return
	var total: float = float(maxi(1, _unreachable_total()))
	var f: float = clampf(float(_freed) / total, 0.0, 1.0)
	_strip.scale = Vector3(maxf(0.0001, f), 1.0, 1.0)
	_strip.position.x = -STRIP_W * 0.5 + STRIP_W * 0.5 * f


func _unreachable_total() -> int:
	var n: int = 0
	for c in _cells:
		var cell: Dictionary = c
		if not bool(cell["marked"]):
			n += 1
	return n


func _update_readout() -> void:
	if not is_instance_valid(_readout):
		return
	var n: int = _cell_count()
	match _phase:
		Phase.LIVE:
			_readout.text = "HEAP %d OBJECTS — ALL REACHABLE" % n
			_readout.modulate = Color(0.86, 0.90, 1.0)
		Phase.DROP:
			_readout.text = "ONE REFERENCE DROPPED\n%d objects lose their only path in" % _island.size()
			_readout.modulate = C_CUT
		Phase.MARK:
			var marked: int = 0
			for c in _cells:
				var cell: Dictionary = c
				if bool(cell["marked"]):
					marked += 1
			_readout.text = "MARK — frontier %d, reached %d/%d" % [_mark_level, marked, n]
			_readout.modulate = C_MARKED
		Phase.SWEEP:
			_readout.text = "SWEEP %d/%d — freed %d" % [_sweep_i, n, _freed]
			_readout.modulate = Color(1.0, 0.90, 0.62)
		Phase.HOLD:
			_readout.text = "COLLECTED %d\nthey still referenced each other" % _freed
			_readout.modulate = Color(0.92, 0.84, 0.84)


# ─────────────────────────────────────────────────────────────────────
# MATERIALS
# ─────────────────────────────────────────────────────────────────────

## One material per cell and per edge — they are mutated live, so sharing them
## would mark the whole heap the moment the first frontier lit.
func _emissive_mat(col: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.roughness = 0.45
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.5
	return fallback


func _spawn(node: Node) -> void:
	add_child(node)
	_created.append(node)


# ─────────────────────────────────────────────────────────────────────
# GRID CONFIG
# ─────────────────────────────────────────────────────────────────────

## Synchronous and scoped to our own children. Nothing deferred: the grid frames
## labels and grounds the artifact immediately after add_child, and a deferred
## rebuild would land after both and undo them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_cells.clear()
	_edges.clear()
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	var before: Array = [heap_cols, heap_rows, root_count, extra_edges]

	if config_data.has("heap_cols"):
		heap_cols = clampi(int(config_data["heap_cols"]), 2, 12)
	if config_data.has("heap_rows"):
		heap_rows = clampi(int(config_data["heap_rows"]), 2, 12)
	if config_data.has("root_count"):
		root_count = clampi(int(config_data["root_count"]), 1, 6)
	if config_data.has("extra_edges"):
		extra_edges = clampi(int(config_data["extra_edges"]), 0, 40)
	# timing knobs need no rebuild — the clock reads them every frame
	if config_data.has("mark_step_seconds"):
		mark_step_seconds = maxf(0.02, float(config_data["mark_step_seconds"]))
	if config_data.has("sweep_step_seconds"):
		sweep_step_seconds = maxf(0.01, float(config_data["sweep_step_seconds"]))

	if not _built:
		return  # _ready has not run yet; it will build with these values.
	var after: Array = [heap_cols, heap_rows, root_count, extra_edges]
	if after == before:
		# Nothing structural changed — leave the placement exactly as it stands.
		return

	_rebuild_now()
	print("[GarbageCollectorDemo] Config applied — heap=%dx%d, roots=%d" % [heap_cols, heap_rows, root_count])
