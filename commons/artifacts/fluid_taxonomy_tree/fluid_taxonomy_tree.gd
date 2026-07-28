extends Node3D
class_name FluidTaxonomyTree

# @identity
# essence: a three-tier tree of thin cylinders — one trunk, a handful of branches, twelve leaves — whose edge topology is re-solved on a timer by three moves: a leaf migrates to another branch, two branches fuse into one node, one branch splits in two
# desire: to hand the player a taxonomy they can watch lose its own categories, so that classification stops reading as a description of the world and starts reading as a schedule of maintenance
# critical_parameter: reclassify_interval — seconds between moves. At 0 the timer never fires and the thing stands as a clean Linnaean tree, three leaves per branch, forever; raise it and no leaf keeps a stable ancestor
# triggers: _process accumulates delta, fires _apply_move() at the interval, then every frame eases node positions toward their new layout targets and re-transforms the cylinder pool to match
# emerges: branch colour. Each leaf owns a fixed hue; each branch shows the mean hue of its current members, so a category's identity visibly drifts with its membership and has no colour of its own
# needs: CylinderMesh edges re-transformed from a fixed pool [Godot built-in]; SphereMesh nodes [built-in]; Grid.gdshader for the base [present]; TextScreen plate [present]
# relationships: the speculativecomputation counterpart to non_binary_classifier — that one shows a boundary that cannot close, this shows a hierarchy that cannot hold; both refuse the moment where the sorting is declared done
# truth: a taxonomy is not a picture of relationships, it is a record of the last time someone decided. Every branch on it is provisional and the tree is only stable while nobody is looking at it hard enough to split it.

## The fluid taxonomy for the speculativecomputation sequence.
##
## Three tiers on a 2×2×2 footprint: the trunk node at the base, a ring of
## branches at mid height, a wider ring of leaves above. Leaves are laid out in
## branch order around the ring, so a migration is a visible walk across the
## circle and a fuse is two arcs closing into one.
##
## Branch IDENTITY is a persistent integer that survives layout but not a fuse.
## That is what the churn readout counts: how many leaves are no longer under
## the branch id they started under. It reaches 12/12 and stays there.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# ── Configuration ────────────────────────────────────────────────────

## THE critical parameter. Seconds between reclassification moves.
## 0.0 → frozen: a clean Linnaean tree, evenly divided, that never moves again.
@export var reclassify_interval: float = 2.4
@export var leaf_count: int = 12
@export var min_branches: int = 2
@export var max_branches: int = 6
@export var start_branches: int = 4
@export var build_seed: int = 20260729

@export_group("Form")
@export var base_radius: float = 0.62
@export var trunk_y: float = 0.16
@export var branch_y: float = 0.98
@export var leaf_y: float = 1.72
@export var branch_ring: float = 0.44
@export var leaf_ring: float = 0.78
@export var edge_radius: float = 0.014
## How fast nodes ease toward a new layout. Lower reads as migration, higher as
## teleporting — the walk across the ring is most of what makes a move legible.
@export var ease_speed: float = 2.2

# ── State ────────────────────────────────────────────────────────────

## Branch membership: an Array of Array[int], each holding leaf indices.
var _branches: Array = []
## Persistent identity per branch, parallel to _branches. Survives migration
## and split (the surviving half keeps it); a fuse retires one of the two.
var _branch_id: Array[int] = []
var _next_id: int = 0
## The branch id each leaf started under. Never updated — it is the baseline.
var _origin_id: Array[int] = []

var _leaf_hue: Array[float] = []
var _leaf_nodes: Array[Node] = []
var _leaf_pos: Array[Vector3] = []
var _leaf_target: Array[Vector3] = []

var _branch_nodes: Array[Node] = []
var _branch_pos: Array[Vector3] = []
var _branch_target: Array[Vector3] = []

## Fixed pool: max_branches trunk-to-branch edges plus one per leaf. Cylinders
## are re-transformed, never rebuilt — a mesh resource remade every frame at
## 90 Hz is the cheapest way to make a small artifact stall a map.
var _edges: Array[Node] = []

var _trunk_node: MeshInstance3D
var _readout: Label3D
var _plaque: Node3D

var _rng := RandomNumberGenerator.new()
var _accum: float = 0.0
var _moves: int = 0
var _last_move: String = "—"

var _created: Array[Node] = []
var _built := false


func _ready() -> void:
	_build_all()
	_built = true


func _build_all() -> void:
	_rng.seed = build_seed
	_seed_taxonomy()
	_build_base()
	_build_nodes()
	_build_edge_pool()
	_build_plate()
	_relayout(true)
	_refresh_edges()
	_refresh_readout()


func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


# ── The starting taxonomy: clean, even, and about to stop being either ──

func _seed_taxonomy() -> void:
	_branches.clear()
	_branch_id.clear()
	_origin_id.clear()
	_leaf_hue.clear()
	_next_id = 0

	var n: int = clampi(leaf_count, 4, 40)
	var b: int = clampi(start_branches, maxi(2, min_branches), maxi(2, max_branches))
	b = mini(b, n / 2)
	b = maxi(b, 2)

	for i in range(b):
		var fresh: Array[int] = []
		_branches.append(fresh)
		_branch_id.append(_next_id)
		_next_id += 1

	for k in range(n):
		# Contiguous blocks: the tidy division a taxonomy is published with.
		var idx: int = mini(k * b / n, b - 1)
		var members: Array = _branches[idx]
		members.append(k)
		_origin_id.append(int(_branch_id[idx]))
		_leaf_hue.append(float(k) / float(n))


func _branch_of(leaf: int) -> int:
	for i in range(_branches.size()):
		var members: Array = _branches[i]
		if members.has(leaf):
			return i
	return 0


# ── The three moves ──────────────────────────────────────────────────

func _apply_move() -> void:
	var options: Array[String] = ["migrate"]
	if _branches.size() > maxi(2, min_branches):
		options.append("fuse")
	if _branches.size() < maxi(2, max_branches):
		options.append("split")
	var pick: String = String(options[_rng.randi_range(0, options.size() - 1)])
	match pick:
		"fuse":
			_move_fuse()
		"split":
			_move_split()
		_:
			_move_migrate()
	_moves += 1
	_last_move = pick
	_relayout(false)
	_refresh_readout()


## A leaf walks. The branch it leaves must survive it, so donors of size 1 are
## skipped — an empty category is a different move (that one is fuse).
func _move_migrate() -> void:
	if _branches.size() < 2:
		return
	var donors: Array[int] = []
	for i in range(_branches.size()):
		var members: Array = _branches[i]
		if members.size() >= 2:
			donors.append(i)
	if donors.is_empty():
		return
	var from: int = int(donors[_rng.randi_range(0, donors.size() - 1)])
	var to: int = _rng.randi_range(0, _branches.size() - 1)
	if to == from:
		to = (from + 1) % _branches.size()
	var src: Array = _branches[from]
	var dst: Array = _branches[to]
	var leaf: int = int(src[_rng.randi_range(0, src.size() - 1)])
	src.erase(leaf)
	dst.append(leaf)
	_last_move = "migrate"


## Two categories become one. The absorbed branch's id is retired — every leaf
## that was under it now answers to a name that did not exist for it before.
func _move_fuse() -> void:
	if _branches.size() <= maxi(2, min_branches):
		return
	var a: int = _rng.randi_range(0, _branches.size() - 1)
	var b: int = _rng.randi_range(0, _branches.size() - 1)
	if a == b:
		b = (a + 1) % _branches.size()
	var keep: int = mini(a, b)
	var drop: int = maxi(a, b)
	var dst: Array = _branches[keep]
	var src: Array = _branches[drop]
	for leaf in src:
		dst.append(leaf)
	_branches.remove_at(drop)
	_branch_id.remove_at(drop)
	# The position arrays are parallel to _branches, so they shift with it —
	# otherwise the surviving branches inherit each other's coordinates and the
	# fuse reads as every category teleporting rather than two closing on one.
	if drop < _branch_pos.size():
		_branch_pos.remove_at(drop)
		_branch_pos.append(Vector3(0.0, branch_y, 0.0))
	if drop < _branch_target.size():
		_branch_target.remove_at(drop)
		_branch_target.append(Vector3(0.0, branch_y, 0.0))


## One category becomes two. Half the members leave under a brand-new id, which
## is the same event as the fuse read backwards and has the same consequence.
func _move_split() -> void:
	if _branches.size() >= maxi(2, max_branches):
		return
	var best: int = -1
	var best_size: int = 2
	for i in range(_branches.size()):
		var members: Array = _branches[i]
		if members.size() > best_size:
			best_size = members.size()
			best = i
	if best < 0:
		return
	var src: Array = _branches[best]
	var moved: Array[int] = []
	var half: int = src.size() / 2
	for i in range(half):
		var leaf: int = int(src[src.size() - 1])
		src.remove_at(src.size() - 1)
		moved.append(leaf)
	_branches.append(moved)
	_branch_id.append(_next_id)
	_next_id += 1
	# The new category starts standing exactly where its parent stands, then
	# eases apart. A split that begins somewhere else is two branches appearing,
	# not one branch dividing.
	var new_idx: int = _branches.size() - 1
	if new_idx < _branch_pos.size() and best < _branch_pos.size():
		_branch_pos[new_idx] = _branch_pos[best]


# ── Layout ───────────────────────────────────────────────────────────

## Leaves are placed around the ring in branch order, so members of one category
## are contiguous arc neighbours and a migration is a walk you can follow.
## Branches sit at the mean angle of their members — a fusing pair visibly
## converges before it becomes one node.
func _relayout(snap: bool) -> void:
	var n: int = _leaf_hue.size()
	if n == 0:
		return
	_leaf_target.resize(n)
	var slot: int = 0
	var branch_angle: Array[float] = []
	for i in range(_branches.size()):
		var members: Array = _branches[i]
		var acc: float = 0.0
		for leaf in members:
			var ang: float = TAU * float(slot) / float(n)
			_leaf_target[int(leaf)] = Vector3(cos(ang) * leaf_ring, leaf_y, sin(ang) * leaf_ring)
			acc += ang
			slot += 1
		branch_angle.append(0.0 if members.is_empty() else acc / float(members.size()))

	_branch_target.resize(maxi(_branches.size(), _branch_target.size()))
	for i in range(_branches.size()):
		var a: float = float(branch_angle[i])
		_branch_target[i] = Vector3(cos(a) * branch_ring, branch_y, sin(a) * branch_ring)

	if snap:
		for k in range(n):
			_leaf_pos[k] = _leaf_target[k]
		for i in range(_branches.size()):
			_branch_pos[i] = _branch_target[i]
	_apply_positions()


func _apply_positions() -> void:
	for k in range(_leaf_nodes.size()):
		var ln: Node = _leaf_nodes[k]
		if is_instance_valid(ln):
			(ln as Node3D).position = _leaf_pos[k]
	for i in range(_branch_nodes.size()):
		var bn: Node = _branch_nodes[i]
		if not is_instance_valid(bn):
			continue
		var active: bool = i < _branches.size()
		(bn as Node3D).visible = active
		if active:
			(bn as Node3D).position = _branch_pos[i]
			var mat: StandardMaterial3D = (bn as MeshInstance3D).material_override as StandardMaterial3D
			if mat != null:
				var c: Color = _branch_color(i)
				mat.albedo_color = c
				mat.emission = c


## A category has no colour of its own — it shows the mean hue of whoever is
## currently in it. Membership changes, the colour drifts, and nothing about the
## branch itself has changed. That is the whole argument, rendered.
func _branch_color(i: int) -> Color:
	var members: Array = _branches[i]
	if members.is_empty():
		return Color(0.4, 0.42, 0.48)
	var sx: float = 0.0
	var sy: float = 0.0
	for leaf in members:
		var h: float = float(_leaf_hue[int(leaf)])
		sx += cos(h * TAU)
		sy += sin(h * TAU)
	var mean_h: float = fposmod(atan2(sy, sx) / TAU, 1.0)
	return Color.from_hsv(mean_h, 0.62, 1.0)


# ── Build ────────────────────────────────────────────────────────────

func _build_base() -> void:
	var body := _grid_material(Color(0.26, 0.28, 0.34), Color(0.44, 0.50, 0.62), 0.5)
	var pad := MeshInstance3D.new()
	pad.name = "Base"
	var cyl := CylinderMesh.new()
	cyl.top_radius = base_radius
	cyl.bottom_radius = base_radius + 0.06
	cyl.height = 0.06
	cyl.radial_segments = 24
	pad.mesh = cyl
	pad.position = Vector3(0.0, 0.03, 0.0)
	pad.material_override = body
	_own(pad)

	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.font_size = 24
	_readout.outline_size = 4
	_readout.pixel_size = 0.001
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.modulate = Color(0.86, 0.90, 1.0)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Under 2.00 m total, so the artifact's AABB honours its declared 2×2×2.
	_readout.position = Vector3(0.0, leaf_y + 0.18, 0.0)
	_own(_readout)


func _build_nodes() -> void:
	var n: int = _leaf_hue.size()
	_leaf_nodes.clear()
	_leaf_pos.clear()
	_leaf_target.clear()
	_leaf_pos.resize(n)
	_leaf_target.resize(n)
	for k in range(n):
		_leaf_pos[k] = Vector3(0.0, leaf_y, 0.0)
		_leaf_target[k] = _leaf_pos[k]
		var mi := MeshInstance3D.new()
		mi.name = "Leaf%d" % k
		var sm := SphereMesh.new()
		sm.radius = 0.052
		sm.height = 0.104
		sm.radial_segments = 12
		sm.rings = 8
		mi.mesh = sm
		mi.material_override = _emissive(Color.from_hsv(float(_leaf_hue[k]), 0.72, 1.0), 2.2)
		_own(mi)
		_leaf_nodes.append(mi)

	var bmax: int = maxi(2, max_branches)
	_branch_nodes.clear()
	_branch_pos.clear()
	_branch_target.clear()
	_branch_pos.resize(bmax)
	_branch_target.resize(bmax)
	for i in range(bmax):
		_branch_pos[i] = Vector3(0.0, branch_y, 0.0)
		_branch_target[i] = _branch_pos[i]
		var mi2 := MeshInstance3D.new()
		mi2.name = "Branch%d" % i
		var sm2 := SphereMesh.new()
		sm2.radius = 0.076
		sm2.height = 0.152
		sm2.radial_segments = 14
		sm2.rings = 8
		mi2.mesh = sm2
		mi2.material_override = _emissive(Color(0.5, 0.55, 0.62), 1.4)
		mi2.visible = i < _branches.size()
		_own(mi2)
		_branch_nodes.append(mi2)

	_trunk_node = MeshInstance3D.new()
	_trunk_node.name = "Trunk"
	var sm3 := SphereMesh.new()
	sm3.radius = 0.10
	sm3.height = 0.20
	sm3.radial_segments = 16
	sm3.rings = 10
	_trunk_node.mesh = sm3
	_trunk_node.material_override = _emissive(Color(0.72, 0.76, 0.84), 1.1)
	_trunk_node.position = Vector3(0.0, trunk_y, 0.0)
	_own(_trunk_node)


func _build_edge_pool() -> void:
	_edges.clear()
	var count: int = maxi(2, max_branches) + _leaf_hue.size()
	for i in range(count):
		var mi := MeshInstance3D.new()
		mi.name = "Edge%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = edge_radius
		cyl.bottom_radius = edge_radius
		# Unit height: every edge is re-scaled, never re-meshed.
		cyl.height = 1.0
		cyl.radial_segments = 6
		cyl.rings = 1
		mi.mesh = cyl
		mi.material_override = _emissive(Color(0.55, 0.60, 0.70), 0.8)
		mi.visible = false
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_own(mi)
		_edges.append(mi)


func _build_plate() -> void:
	# Configure BEFORE add_child — TextScreen's setters rebuild only in-tree.
	var ts := TextScreenScript.new()
	ts.name = "TreePlate"
	ts.mode = 2                      # Mode.PAD
	ts.width_m = 0.34
	ts.position = Vector3(0.0, 0.06, base_radius - 0.10)
	if ts.has_method("set_text"):
		ts.call("set_text", "FLUID TAXONOMY", "no leaf keeps an ancestor")
	_plaque = ts
	_own(ts)


# ── Per-frame ────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _leaf_nodes.is_empty():
		return
	if reclassify_interval > 0.0:
		_accum += delta
		if _accum >= reclassify_interval:
			_accum = 0.0
			_apply_move()

	var t: float = clampf(delta * ease_speed, 0.0, 1.0)
	var moving: bool = false
	for k in range(_leaf_pos.size()):
		var target: Vector3 = _leaf_target[k]
		var cur: Vector3 = _leaf_pos[k]
		if cur.distance_squared_to(target) > 1.0e-8:
			_leaf_pos[k] = cur.lerp(target, t)
			moving = true
	for i in range(mini(_branch_pos.size(), _branches.size())):
		var btarget: Vector3 = _branch_target[i]
		var bcur: Vector3 = _branch_pos[i]
		if bcur.distance_squared_to(btarget) > 1.0e-8:
			_branch_pos[i] = bcur.lerp(btarget, t)
			moving = true

	if moving:
		_apply_positions()
		_refresh_edges()


## Re-transform the pool. Edge n is trunk→branch for the first `branches` slots,
## then branch→leaf for each leaf; leftovers are hidden.
func _refresh_edges() -> void:
	var idx: int = 0
	var trunk := Vector3(0.0, trunk_y, 0.0)
	for i in range(_branches.size()):
		if idx >= _edges.size():
			break
		_set_edge(_edges[idx], trunk, _branch_pos[i], _branch_color(i), edge_radius * 1.5)
		idx += 1
	for i in range(_branches.size()):
		var members: Array = _branches[i]
		for leaf in members:
			if idx >= _edges.size():
				break
			var k: int = int(leaf)
			_set_edge(_edges[idx], _branch_pos[i], _leaf_pos[k],
				Color.from_hsv(float(_leaf_hue[k]), 0.55, 0.95), edge_radius)
			idx += 1
	while idx < _edges.size():
		var spare: Node = _edges[idx]
		if is_instance_valid(spare):
			(spare as Node3D).visible = false
		idx += 1


## One cylinder stretched between two points. The Y basis vector carries the
## length, so the mesh resource is never touched.
func _set_edge(node: Node, a: Vector3, b: Vector3, c: Color, radius: float) -> void:
	if not is_instance_valid(node):
		return
	var mi := node as MeshInstance3D
	var d: Vector3 = b - a
	var length: float = d.length()
	if length < 0.001:
		mi.visible = false
		return
	var dir: Vector3 = d / length
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var xa: Vector3 = up.cross(dir).normalized()
	var za: Vector3 = dir.cross(xa).normalized()
	mi.transform = Transform3D(Basis(xa, dir * length, za), (a + b) * 0.5)
	mi.visible = true
	var cyl := mi.mesh as CylinderMesh
	if cyl != null and not is_equal_approx(cyl.top_radius, radius):
		cyl.top_radius = radius
		cyl.bottom_radius = radius
	var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = c
		mat.emission = c


## How many leaves are no longer under the branch id they started under. It
## climbs to leaf_count and stays — which is the claim in the truth line, made
## countable rather than asserted.
func _churn() -> int:
	var moved: int = 0
	for k in range(_leaf_hue.size()):
		var bi: int = _branch_of(k)
		if bi >= _branch_id.size():
			continue
		if int(_branch_id[bi]) != int(_origin_id[k]):
			moved += 1
	return moved


func _refresh_readout() -> void:
	if _readout == null or not is_instance_valid(_readout):
		return
	if reclassify_interval <= 0.0:
		_readout.text = "%d branches · %d leaves\nfrozen · a clean tree" % [
			_branches.size(), _leaf_hue.size()]
		return
	_readout.text = "%d branches · %d leaves\nmove %d (%s) · displaced %d/%d" % [
		_branches.size(), _leaf_hue.size(), _moves, _last_move,
		_churn(), _leaf_hue.size()]


# ── Materials ────────────────────────────────────────────────────────

func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


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
	fallback.roughness = 0.4
	return fallback


# ── Rebuild / grid config ────────────────────────────────────────────

func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_leaf_nodes.clear()
	_branch_nodes.clear()
	_edges.clear()
	_trunk_node = null
	_readout = null
	_plaque = null
	_moves = 0
	_accum = 0.0
	_last_move = "—"
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_leaves: int = leaf_count
	var before_max: int = max_branches
	var before_start: int = start_branches
	var before_seed: int = build_seed

	# THE critical parameter — #reclassify_interval:0 freezes it into a clean tree.
	if config_data.has("reclassify_interval"):
		reclassify_interval = clampf(float(config_data["reclassify_interval"]), 0.0, 60.0)
	if config_data.has("leaf_count"):
		leaf_count = clampi(int(config_data["leaf_count"]), 4, 40)
	if config_data.has("max_branches"):
		max_branches = clampi(int(config_data["max_branches"]), 2, 12)
	if config_data.has("start_branches"):
		start_branches = clampi(int(config_data["start_branches"]), 2, 12)
	if config_data.has("ease_speed"):
		ease_speed = clampf(float(config_data["ease_speed"]), 0.2, 20.0)
	if config_data.has("seed"):
		build_seed = int(config_data["seed"])

	if not _built:
		return   # _ready has not run yet; it will build with these values.

	if leaf_count != before_leaves or max_branches != before_max \
			or start_branches != before_start or build_seed != before_seed:
		_rebuild_now()
		print("[FluidTaxonomyTree] Config applied — rebuilt: leaves=%d interval=%.2f" % [
			leaf_count, reclassify_interval])
		return
	# The interval needs no geometry; the next frame reads it. Rebuilding would
	# reset a tree mid-migration, which is the state worth looking at.
	_refresh_readout()
