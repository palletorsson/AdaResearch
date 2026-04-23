# graph_selector.gd — Predicates over graph nodes for graph grammar rules.
# Returns PackedInt32Array of node indices matching the predicate.
# Same pattern as mesh_grammar/mesh_selector.gd but for graph topology.
extends RefCounted

var _predicate: Callable = Callable()


func select(g) -> PackedInt32Array:
	var out := PackedInt32Array()
	if not _predicate.is_valid():
		return out
	for i in g.node_count():
		if _predicate.call(g, i):
			out.append(i)
	return out


static func all_nodes():
	var s = load("res://commons/graph_grammar/graph_selector.gd").new()
	s._predicate = func(_g, _i: int) -> bool: return true
	return s


static func leaves():
	var s = load("res://commons/graph_grammar/graph_selector.gd").new()
	s._predicate = func(g, i: int) -> bool:
		var found_child := false
		for e in g.edges:
			if e[0] == i:
				found_child = true; break
		return not found_child
	return s


static func roots():
	var s = load("res://commons/graph_grammar/graph_selector.gd").new()
	s._predicate = func(g, i: int) -> bool:
		return i < g.parents.size() and g.parents[i] < 0
	return s


static func by_tag(tag: String):
	var s = load("res://commons/graph_grammar/graph_selector.gd").new()
	s._predicate = func(g, i: int) -> bool:
		return g.has_tag(i, tag)
	return s


static func by_depth(min_depth: int, max_depth: int = -1):
	var s = load("res://commons/graph_grammar/graph_selector.gd").new()
	s._predicate = func(g, i: int) -> bool:
		if i >= g.node_depth.size(): return false
		var d: int = g.node_depth[i]
		if d < min_depth: return false
		if max_depth >= 0 and d > max_depth: return false
		return true
	return s


static func by_random(probability: float, seed_val: int = 11):
	var s = load("res://commons/graph_grammar/graph_selector.gd").new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	s._predicate = func(_g, _i: int) -> bool:
		return rng.randf() < probability
	return s


func and_also(other):
	var s = load("res://commons/graph_grammar/graph_selector.gd").new()
	var a := _predicate
	var b = other._predicate
	s._predicate = func(g, i: int) -> bool:
		return a.call(g, i) and b.call(g, i)
	return s


func not_matching():
	var s = load("res://commons/graph_grammar/graph_selector.gd").new()
	var a := _predicate
	s._predicate = func(g, i: int) -> bool:
		return not a.call(g, i)
	return s
