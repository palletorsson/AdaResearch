# mycelium_colony.gd — mycelium thread, milestone 2: the space-colonization generator.
#
# doc/plans/mycelium_substrate.md. Milestone 1 (mycelium_spike.gd) proved the
# render pipeline with an L-system turtle: MorphoSweep tapering tubes DO read as
# hyphae. But an L-system branches on SCHEDULE — every F splits the same way at
# the same depth — and mycelium does not. It branches because the food nearby
# runs out and the tip has to go somewhere else.
#
# So: scatter attractors ("food") on a ground disc, grow from the seed toward
# whichever attractors are in range, kill an attractor when a tip reaches it.
# Branching is emergent — a tip splits when its influence set pulls two ways —
# and the web is irregular because the scatter is.
#
# The thickness rule is the other half of the look. The spike thinned by branch
# DEPTH; this thins by SUBTREE WEIGHT — how many segments feed through a strand.
# A mycelial mat is a flow network: everything a tip absorbs travels home through
# its parent, so strands thicken toward the seed and every tip ends hair-thin,
# regardless of how deep it sits. Depth-taper cannot produce that; a voxel grid
# (fungus:ca) cannot produce it at all — which is why this substrate exists.
#
# Standalone capture surface, like the spike. Batching is milestone 3, the
# dispatcher wiring is milestone 4.
extends Node3D
class_name MyceliumColony

const MorphoSweepClass = preload("res://algorithms/nature_system/morphology/morpho_sweep.gd")

@export var colony_radius: float = 1.15      # the ground disc the attractors cover
@export var attractor_count: int = 900       # `d=` density will drive this (milestone 4)
@export var influence_radius: float = 0.30   # how far a tip can smell food
@export var kill_radius: float = 0.045       # how close counts as reached
@export var step_length: float = 0.042       # one growth step
@export var max_steps: int = 400
@export var max_nodes: int = 2600
@export var flatten: float = 0.16            # damp vertical growth — a mat, not a bush
@export var jitter: float = 0.22             # wander, so strands are not straight
@export var base_radius: float = 0.0042      # radius of a single-segment (tip) strand
@export var min_radius: float = 0.0022
@export var rng_seed: int = 20260721         # per-cell seed at biome scale
@export var color_hypha: Color = Color(0.62, 0.85, 0.78)
@export var draw_spores: bool = true

var _rng := RandomNumberGenerator.new()

# the grown tree
var _nodes: Array[Vector3] = []
var _parent: Array[int] = []


func _ready() -> void:
	_rng.seed = rng_seed
	var attractors: Array[Vector3] = _scatter_attractors()
	_grow(attractors)
	var weight: Array[float] = _subtree_weights()
	var radius: Array[float] = _radii(weight)
	for i in range(1, _nodes.size()):
		_render_hypha(_nodes[_parent[i]], _nodes[i], radius[_parent[i]], radius[i])
	if draw_spores:
		_render_spores(weight, radius)


# --- the food ----------------------------------------------------------------

## Attractors on a ground disc, denser toward the middle (pow < 0.5 biases the
## radial sample inward). A uniform disc grows a ring-ish colony; a real mat is
## thickest where it started.
func _scatter_attractors() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for _i in range(attractor_count):
		var ang: float = _rng.randf() * TAU
		var rad: float = colony_radius * pow(_rng.randf(), 0.62)
		var y: float = _rng.randf_range(-0.01, 0.03)
		out.append(Vector3(cos(ang) * rad, y, sin(ang) * rad))
	return out


# --- the growth --------------------------------------------------------------

func _grow(attractors: Array[Vector3]) -> void:
	_nodes = [Vector3.ZERO]
	_parent = [-1]
	_hash.clear()
	_hash_put(0)

	var influence_sq: float = influence_radius * influence_radius
	var kill_sq: float = kill_radius * kill_radius

	for _step in range(max_steps):
		if attractors.is_empty() or _nodes.size() >= max_nodes:
			break

		# each attractor pulls on its nearest node only — that competition is
		# what makes tips split rather than all drifting the same way
		var pull: Dictionary = {}
		for a in attractors:
			var best: int = _nearest_node(a, influence_sq)
			if best >= 0:
				var dir: Vector3 = (a - _nodes[best]).normalized()
				pull[best] = (pull[best] if pull.has(best) else Vector3.ZERO) + dir

		if pull.is_empty():
			break

		for idx in pull.keys():
			if _nodes.size() >= max_nodes:
				break
			var node_i: int = int(idx)
			var dir: Vector3 = pull[idx]
			if dir.length_squared() < 0.000001:
				continue
			dir = dir.normalized()
			dir += Vector3(
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0)) * jitter
			dir.y *= flatten
			if dir.length_squared() < 0.000001:
				continue
			var grown: Vector3 = _nodes[node_i] + dir.normalized() * step_length
			_nodes.append(grown)
			_parent.append(node_i)
			_hash_put(_nodes.size() - 1)

		# food that has been reached is gone
		var alive: Array[Vector3] = []
		for a in attractors:
			if _nearest_node(a, kill_sq) < 0:
				alive.append(a)
		attractors = alive


# --- spatial hash ------------------------------------------------------------
# The naive search is O(steps x attractors x nodes); at the densities a real mat
# needs (hundreds of attractors, thousands of nodes) that is hundreds of millions
# of distance checks and the generator stops being runnable. Bucket the nodes by
# a cell the size of the influence radius and only look in the 27 cells around
# an attractor — the answer is identical, the cost is not. Perf is a named risk
# in the plan (a colony is many segments); this is where it starts.

var _hash: Dictionary = {}   # Vector3i cell -> Array[int] node indices


func _cell_of(p: Vector3) -> Vector3i:
	var s: float = maxf(influence_radius, 0.0001)
	return Vector3i(int(floor(p.x / s)), int(floor(p.y / s)), int(floor(p.z / s)))


func _hash_put(node_i: int) -> void:
	var c: Vector3i = _cell_of(_nodes[node_i])
	if not _hash.has(c):
		_hash[c] = []
	(_hash[c] as Array).append(node_i)


## Nearest node to p within max_dist_sq, or -1. Only valid for radii <= the cell
## size (influence_radius), which is true for both callers.
func _nearest_node(p: Vector3, max_dist_sq: float) -> int:
	var base: Vector3i = _cell_of(p)
	var best: int = -1
	var best_d: float = max_dist_sq
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				var c := Vector3i(base.x + dx, base.y + dy, base.z + dz)
				if not _hash.has(c):
					continue
				for i in (_hash[c] as Array):
					var d: float = _nodes[int(i)].distance_squared_to(p)
					if d < best_d:
						best_d = d
						best = int(i)
	return best


# --- the thickness -----------------------------------------------------------

## Every node carries its own segment plus everything downstream of it. Children
## always have a higher index than their parent (append order), so one reverse
## pass accumulates the whole tree.
func _subtree_weights() -> Array[float]:
	var w: Array[float] = []
	w.resize(_nodes.size())
	w.fill(1.0)
	for i in range(_nodes.size() - 1, 0, -1):
		var p: int = _parent[i]
		if p >= 0:
			w[p] = w[p] + w[i]
	return w


func _radii(weight: Array[float]) -> Array[float]:
	var out: Array[float] = []
	out.resize(weight.size())
	for i in range(weight.size()):
		# sub-linear in flow: the trunk is thicker than a tip but not 900x thicker
		var r: float = base_radius * pow(weight[i], 0.33)
		out[i] = maxf(r, min_radius)
	return out


# --- the render (same MorphoSweep path the spike proved) ---------------------

func _render_hypha(a: Vector3, b: Vector3, r_from: float, r_to: float) -> void:
	if a.distance_squared_to(b) < 0.0000001:
		return
	var mesh: Mesh = MorphoSweepClass.sweep(
		MorphoSweepClass.profile_circle(6),
		MorphoSweepClass.path_line(a, b),
		MorphoSweepClass.radius_taper(r_from, r_to),
		0.0, 4, false)
	if mesh == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _hypha_material()
	add_child(mi)


var _mat_cache: StandardMaterial3D = null

func _hypha_material() -> StandardMaterial3D:
	if _mat_cache != null:
		return _mat_cache
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_hypha
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = color_hypha
	mat.emission_energy_multiplier = 0.35
	_mat_cache = mat
	return mat


## Spore tips sit on the leaves — a node nothing grew out of, i.e. weight 1.
func _render_spores(weight: Array[float], radius: Array[float]) -> void:
	var glow := Color(0.8, 0.95, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glow
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = 2.0
	for i in range(1, _nodes.size()):
		if weight[i] > 1.5:
			continue
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r: float = radius[i] * 1.7
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 6
		sm.rings = 4
		mi.mesh = sm
		mi.material_override = mat
		mi.position = _nodes[i]
		add_child(mi)
