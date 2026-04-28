## MeshGrammarExporter — Bridge from research-time mesh-grammar output
## to the runtime systems that consume morphology (CritterDNA,
## artifact scenes, GraphState).
##
## The strategic doc proposed: "do not unify the runtime; unify the
## design layer." This is that bridge. The mesh-grammar is where you
## *author* a critter; this exporter takes the final mesh + role tags
## and emits the data shape each runtime needs.
##
## Three exports, each free-standing:
##   to_critter_dna(mesh, hints)  -> CritterDNA Resource
##   to_array_mesh(mesh)          -> baked ArrayMesh (with face colors)
##   to_graph_state(mesh)         -> GraphState (only meaningful if the
##                                   mesh came from skin_graph; reads
##                                   "edge_N" tags to recover topology)
##
## All exports are read-only — they don't mutate the source mesh.
##
## Usage:
##   var dna = MeshGrammarExporter.to_critter_dna(my_mesh,
##       {"body_type": 2.0, "kingdom": "flower"})
##   spawner.spawn_critter(dna)
extends RefCounted
class_name MeshGrammarExporter


## Build a CritterDNA from a MeshData by reading role tags + colours +
## topology. Hints can override or seed any gene; otherwise heuristics
## fill in plausible values.
##
## Hints (all optional):
##   body_type: float                — 0=tree, 1=walker, 2=flower, 3=fungus, 4=hybrid
##   kingdom: String                 — used to seed defaults
##   primary_color, secondary_color, tertiary_color: Color
##   symmetry: float
##
## Heuristics:
##   - primary_color = most common face colour
##   - secondary_color = second most common
##   - tertiary_color = least common (if 3+ colours)
##   - symmetry = number of distinct *_<int> sub-roles found (cluster_by_role)
##   - segments = log2(face count) — coarse complexity measure
static func to_critter_dna(mesh: MeshData, hints: Dictionary = {}) -> Resource:
	var CritterDNA = load("res://algorithms/nature_system/dna/critter_dna.gd")
	if CritterDNA == null:
		push_warning("MeshGrammarExporter: CritterDNA class not found")
		return null
	var dna = CritterDNA.new()

	# 1. Sample colours by accumulated face area (not just frequency).
	# A single yellow pistil sphere has many tiny faces; weighting by
	# count makes it dominate over the petals which have fewer but
	# larger faces. Area-weighting reflects what the eye actually sees.
	var color_buckets: Dictionary = {}  # quantized -> {color, area}
	var weight_by_area: bool = bool(hints.get("weight_by_area", true))
	for fi in range(mesh.face_metadata.size()):
		var md: Dictionary = mesh.face_metadata[fi]
		if not (md is Dictionary) or not md.has("color"):
			continue
		var c: Color = md["color"]
		var key := "%d_%d_%d" % [int(c.r * 32), int(c.g * 32), int(c.b * 32)]
		var w: float = 1.0
		if weight_by_area and fi < mesh.faces.size():
			var f := mesh.faces[fi]
			if f.size() == 3:
				var v0: Vector3 = mesh.vertices[f[0]]
				var v1: Vector3 = mesh.vertices[f[1]]
				var v2: Vector3 = mesh.vertices[f[2]]
				w = 0.5 * (v1 - v0).cross(v2 - v0).length()
		if not color_buckets.has(key):
			color_buckets[key] = {"color": c, "area": 0.0}
		color_buckets[key]["area"] += w
	var sorted_colors: Array = color_buckets.values()
	sorted_colors.sort_custom(func(a, b): return a["area"] > b["area"])
	if sorted_colors.size() >= 1:
		dna.primary_color = sorted_colors[0]["color"]
	if sorted_colors.size() >= 2:
		dna.secondary_color = sorted_colors[1]["color"]
	if sorted_colors.size() >= 3:
		dna.tertiary_color = sorted_colors[sorted_colors.size() - 1]["color"]

	# 2. Symmetry from cluster_by_role sub-roles. We look for tags matching
	# "<role>_<int>" and take the highest int seen + 1 as the cluster count.
	var max_cluster: int = 0
	var seen_roles: Dictionary = {}
	for tags in mesh.face_tags:
		for raw_tag in tags:
			var tag := String(raw_tag)
			# Find trailing _N integer.
			var underscore_pos: int = tag.rfind("_")
			if underscore_pos > 0 and underscore_pos < tag.length() - 1:
				var suffix := tag.substr(underscore_pos + 1)
				if suffix.is_valid_int():
					max_cluster = max(max_cluster, int(suffix) + 1)
					var role_prefix := tag.substr(0, underscore_pos)
					seen_roles[role_prefix] = true
	if max_cluster > 0:
		dna.symmetry = clampf(float(max_cluster), 1.0, 8.0)

	# 3. Segments = log2 face count, clamped to [2, 12]. Coarse complexity.
	var face_count: int = mesh.faces.size()
	if face_count > 0:
		dna.segments = clampf(log(float(face_count)) / log(2.0), 2.0, 12.0)

	# 4. body_type from kingdom hint or detected role tags.
	if hints.has("body_type"):
		dna.body_type = float(hints["body_type"])
	else:
		# Heuristic: if "flower_*" tags exist → 2.0 (flower). insect/bird → 1.0.
		# tree → 0.0. default 0.0.
		var has_flower: bool = false
		var has_creature: bool = false
		var has_tree: bool = false
		for role in seen_roles.keys():
			var r := String(role)
			if r.begins_with("flower"):
				has_flower = true
			elif r.begins_with("insect") or r.begins_with("bird") or r == "leg" or r == "thorax":
				has_creature = true
			elif r == "trunk" or r == "leaf" or r == "branch":
				has_tree = true
		if has_flower: dna.body_type = 2.0
		elif has_creature: dna.body_type = 1.0
		elif has_tree: dna.body_type = 0.0

	# 5. Apply explicit hints last so they win over heuristics.
	if hints.has("primary_color"):
		dna.primary_color = hints["primary_color"]
	if hints.has("secondary_color"):
		dna.secondary_color = hints["secondary_color"]
	if hints.has("tertiary_color"):
		dna.tertiary_color = hints["tertiary_color"]
	if hints.has("symmetry"):
		dna.symmetry = float(hints["symmetry"])
	if hints.has("scale"):
		dna.scale = float(hints["scale"])

	return dna


## Bake the MeshData to an ArrayMesh with face colours. Convenience
## wrapper around mesh.to_array_mesh that always enables vertex colour.
static func to_array_mesh(mesh: MeshData) -> ArrayMesh:
	return mesh.to_array_mesh({"face_colors": true, "double_sided": true})


## Reconstruct a GraphState by reading "edge_N" tags. Only meaningful for
## meshes that came from skin_graph (where each face carries an "edge_N"
## marker pointing back to the source graph edge).
##
## Returns a GraphState with one node per *unique tag set* and one edge
## per "edge_N" group. Mostly useful for round-tripping back to graph_grammar
## ops or for visualizing skinned graphs as their original topology.
static func to_graph_state(mesh: MeshData) -> Resource:
	var GraphState = load("res://commons/graph_grammar/graph_state.gd")
	if GraphState == null:
		return null
	var state = GraphState.new()
	# Group faces by edge tag.
	var edge_groups: Dictionary = {}  # int -> Array[face_idx]
	for fi in range(mesh.face_tags.size()):
		for raw_tag in mesh.face_tags[fi]:
			var tag := String(raw_tag)
			if tag.begins_with("edge_"):
				var idx := int(tag.substr(5))
				if not edge_groups.has(idx):
					edge_groups[idx] = []
				(edge_groups[idx] as Array).append(fi)
				break
	# For each edge group, compute the centroid pair (from min/max projection
	# along principal axis) — coarse but recoverable.
	var edge_keys: Array = edge_groups.keys()
	edge_keys.sort()
	var node_positions: Array = []
	for ek in edge_keys:
		var group: Array = edge_groups[ek]
		var verts: Array = []
		for fi in group:
			var f := mesh.faces[fi]
			for vi in f:
				verts.append(mesh.vertices[vi])
		if verts.is_empty(): continue
		var bb_min: Vector3 = verts[0]
		var bb_max: Vector3 = verts[0]
		for v in verts:
			bb_min = Vector3(min(bb_min.x, v.x), min(bb_min.y, v.y), min(bb_min.z, v.z))
			bb_max = Vector3(max(bb_max.x, v.x), max(bb_max.y, v.y), max(bb_max.z, v.z))
		var diff: Vector3 = bb_max - bb_min
		var a: Vector3 = bb_min
		var b: Vector3 = bb_max
		# Find the largest extent axis as the edge direction.
		if diff.y > diff.x and diff.y > diff.z:
			a = Vector3((bb_min.x + bb_max.x) * 0.5, bb_min.y, (bb_min.z + bb_max.z) * 0.5)
			b = Vector3(a.x, bb_max.y, a.z)
		elif diff.z > diff.x:
			a = Vector3((bb_min.x + bb_max.x) * 0.5, (bb_min.y + bb_max.y) * 0.5, bb_min.z)
			b = Vector3(a.x, a.y, bb_max.z)
		else:
			a = Vector3(bb_min.x, (bb_min.y + bb_max.y) * 0.5, (bb_min.z + bb_max.z) * 0.5)
			b = Vector3(bb_max.x, a.y, a.z)
		# De-duplicate near-coincident endpoints across adjacent edges.
		var ai: int = _find_or_add_node(node_positions, state, a)
		var bi: int = _find_or_add_node(node_positions, state, b)
		state.edges.append([ai, bi])
	return state


static func _find_or_add_node(cache: Array, state: Resource, p: Vector3,
		eps: float = 0.05) -> int:
	for i in range(cache.size()):
		if (cache[i] as Vector3).distance_to(p) < eps:
			return i
	var idx: int = cache.size()
	cache.append(p)
	state.add_node(p, 0.05, -1, PackedStringArray())
	return idx
