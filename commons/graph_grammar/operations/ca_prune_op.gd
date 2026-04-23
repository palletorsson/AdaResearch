# ca_prune_op.gd — Selector as pruning. Runs Conway's Game of Life (or
# other 2-state CA rules) on a 2D grid projected in XZ. For each selected
# node, projects (x, z) to grid coords; if the cell is DEAD after N
# steps, the node (and its subtree) is removed from the graph. Living
# cells keep their nodes. Result: growth is constrained to the CA pattern.
#
# This is genuinely new selection semantics — not smooth field values,
# but discrete emergent patterns that depend on initial conditions and
# rules. Running different rule/seed combos gives stripes, spots, gliders,
# still lifes — and these patterns decide WHERE growth survives.
#
# Params:
#   rule          — "conway" (B3/S23) | "highlife" (B36/S23) | "seeds" (B2/S) | "life_without_death" (B3/S012345678)
#   iterations    — CA steps (default 20)
#   grid_size     — grid resolution (default 32)
#   world_size    — meters the grid covers (default 4.0)
#   seed_density  — initial fill fraction (default 0.35)
#   seed          — RNG seed (default 7)
#   preserve_root — root (depth 0) is never pruned (default true)
extends "res://commons/graph_grammar/graph_rule.gd"


const RULES: Dictionary = {
	"conway":               {"B": [3],       "S": [2, 3]},
	"highlife":             {"B": [3, 6],    "S": [2, 3]},
	"seeds":                {"B": [2],       "S": []},
	"life_without_death":   {"B": [3],       "S": [0, 1, 2, 3, 4, 5, 6, 7, 8]},
	"day_and_night":        {"B": [3, 6, 7, 8], "S": [3, 4, 6, 7, 8]},
}


func _execute(g, selected: PackedInt32Array) -> void:
	var rule_name: String = str(params.get("rule", "conway"))
	var rule: Dictionary = RULES.get(rule_name, RULES["conway"])
	var iterations: int = int(params.get("iterations", 20))
	var N: int = int(params.get("grid_size", 32))
	var world_size: float = float(params.get("world_size", 4.0))
	var density: float = float(params.get("seed_density", 0.35))
	var seed_val: int = int(params.get("seed", 7))
	var preserve_root: bool = bool(params.get("preserve_root", true))

	var grid := _simulate_ca(N, rule["B"], rule["S"], iterations, density, seed_val)

	# For each selected node, check its cell; if dead, queue for removal.
	# We remove by collecting surviving indices and rebuilding parent refs.
	var half: float = world_size * 0.5
	var should_keep: Array = []
	should_keep.resize(g.node_count())
	for i in g.node_count():
		should_keep[i] = true  # default: keep

	for idx in selected:
		if idx >= g.nodes.size():
			continue
		if preserve_root and idx < g.node_depth.size() and g.node_depth[idx] == 0:
			continue
		var p: Vector3 = g.nodes[idx]
		var u: float = clamp((p.x + half) / world_size, 0.0, 0.9999)
		var v: float = clamp((p.z + half) / world_size, 0.0, 0.9999)
		var ix: int = int(u * float(N))
		var iy: int = int(v * float(N))
		var alive: bool = grid[iy * N + ix] != 0
		if not alive:
			should_keep[idx] = false

	# Compact the graph: keep only nodes marked alive. If a node's parent
	# was removed, it is also removed (cascade).
	_compact(g, should_keep)


static func _simulate_ca(N: int, B: Array, S: Array, iters: int, density: float, seed_val: int) -> PackedInt32Array:
	var size: int = N * N
	var cur := PackedInt32Array()
	cur.resize(size)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for i in size:
		cur[i] = 1 if rng.randf() < density else 0
	var nxt := cur.duplicate()
	for _step in iters:
		for y in N:
			for x in N:
				var n: int = _count_neighbors(cur, N, x, y)
				var alive: int = cur[y * N + x]
				var next_state: int = 0
				if alive != 0:
					next_state = 1 if n in S else 0
				else:
					next_state = 1 if n in B else 0
				nxt[y * N + x] = next_state
		for i in size:
			cur[i] = nxt[i]
	return cur


static func _count_neighbors(grid: PackedInt32Array, N: int, x: int, y: int) -> int:
	var c: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = (x + dx + N) % N
			var ny: int = (y + dy + N) % N
			c += grid[ny * N + nx]
	return c


static func _compact(g, keep: Array) -> void:
	# Cascade removal: if a node's parent was removed, remove the node too
	var changed := true
	while changed:
		changed = false
		for i in g.parents.size():
			if keep[i] and g.parents[i] >= 0 and not keep[g.parents[i]]:
				keep[i] = false
				changed = true

	# Build old → new index mapping
	var mapping: PackedInt32Array = PackedInt32Array()
	mapping.resize(g.node_count())
	var new_idx: int = 0
	for i in g.node_count():
		if keep[i]:
			mapping[i] = new_idx
			new_idx += 1
		else:
			mapping[i] = -1

	# Rebuild the state in place (collect then overwrite)
	var new_nodes: PackedVector3Array = PackedVector3Array()
	var new_radii: PackedFloat32Array = PackedFloat32Array()
	var new_parents: PackedInt32Array = PackedInt32Array()
	var new_tags: Array = []
	var new_depth: PackedInt32Array = PackedInt32Array()
	for i in g.node_count():
		if not keep[i]: continue
		new_nodes.append(g.nodes[i])
		new_radii.append(g.radii[i])
		new_tags.append(g.node_tags[i])
		new_depth.append(g.node_depth[i])
		var p: int = g.parents[i]
		new_parents.append(-1 if p < 0 else mapping[p])

	var new_edges: Array = []
	for e in g.edges:
		var a: int = e[0]
		var b: int = e[1]
		if keep[a] and keep[b]:
			new_edges.append([mapping[a], mapping[b]])

	g.nodes = new_nodes
	g.radii = new_radii
	g.parents = new_parents
	g.edges = new_edges
	g.node_tags = new_tags
	g.node_depth = new_depth
