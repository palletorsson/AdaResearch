# graph_metaball_sdf.gd — Treat a GraphState as a big smooth-union of
# capsule SDFs, one per edge, radii tapered along each edge. Inherits
# FormSDF so marching_cubes can bake it to an ArrayMesh.
#
# The smoothness parameter controls how much neighbouring capsules fuse
# at their endpoints — at 0.0 it's a crisp capsule soup, at 0.2+ the
# intersections fillet into a continuous organic surface (metaball look).
#
# Usage:
#   var sdf = GraphMetaballSDF.from_graph(graph, 0.15)
#   var mesh = SDFMarchingCubes.bake(sdf, Vector3i(72, 72, 72))

extends "res://commons/morphology/sdf/form_sdf.gd"

const SdfOps = preload("res://commons/morphology/sdf/sdf_ops.gd")

# Each entry: {"a": Vector3, "b": Vector3, "r": float}
var segments: Array = []
var smoothness: float = 0.15
var _cached_aabb: AABB = AABB()


static func from_graph(g, smoothness_k: float = 0.15) -> Resource:
	var script: GDScript = load("res://commons/graph_grammar/graph_metaball_sdf.gd")
	var sdf: Resource = script.new()
	sdf.smoothness = smoothness_k
	for e in g.edges:
		var a_idx: int = e[0]
		var b_idx: int = e[1]
		if a_idx >= g.nodes.size() or b_idx >= g.nodes.size():
			continue
		var ra: float = g.radii[a_idx]
		var rb: float = g.radii[b_idx]
		sdf.segments.append({
			"a": g.nodes[a_idx],
			"b": g.nodes[b_idx],
			"r": maxf(0.01, (ra + rb) * 0.5),
		})
	sdf._recompute_aabb()
	return sdf


func _recompute_aabb() -> void:
	if segments.is_empty():
		_cached_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
		return
	# Compute tight AABB from endpoints + radii, then add generous margin.
	# Smooth_union across N capsules can balloon the surface outward by up
	# to smoothness * log(N) — give it room.
	var max_r: float = 0.0
	var first: Dictionary = segments[0]
	var total := AABB(first.a, Vector3.ZERO)
	total = total.expand(first.b)
	max_r = maxf(max_r, first.r)
	for i in range(1, segments.size()):
		var s: Dictionary = segments[i]
		total = total.expand(s.a)
		total = total.expand(s.b)
		max_r = maxf(max_r, s.r)
	# Pad by (max_radius + smoothness * 4 + 0.15) on all sides
	var pad: float = max_r + smoothness * 4.0 + 0.15
	_cached_aabb = total.grow(pad)


## Core query — minimum over all capsules, smoothed with smooth_union.
## Early-exit optimisation: once the running distance is deeply inside
## (d < -smoothness * 4), subsequent capsules can only trim the surface
## by at most smoothness — we're already well inside, no point computing.
func signed_distance(p: Vector3) -> float:
	if segments.is_empty():
		return 1e9
	var d: float = SdfOps.sdf_capsule(p, segments[0].a, segments[0].b, segments[0].r)
	if smoothness <= 0.0:
		for i in range(1, segments.size()):
			var s: Dictionary = segments[i]
			var di: float = SdfOps.sdf_capsule(p, s.a, s.b, s.r)
			if di < d:
				d = di
			if d < -1.0:
				return d
		return d
	var deep_inside_threshold: float = -smoothness * 4.0
	for i in range(1, segments.size()):
		if d < deep_inside_threshold:
			return d  # Further capsules can't meaningfully change the result
		var s2: Dictionary = segments[i]
		var di2: float = SdfOps.sdf_capsule(p, s2.a, s2.b, s2.r)
		d = SdfOps.smooth_union(d, di2, smoothness)
	return d


func get_aabb() -> AABB:
	return _cached_aabb
