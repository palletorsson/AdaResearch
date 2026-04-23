# graph_grammar.gd — Orchestrator. Holds a GraphState + list of rules.
# Applies rules in sequence per generation. Matches the interface of
# commons/mesh_grammar/mesh_grammar.gd so tools can treat both similarly.
extends RefCounted

var rules: Array = []
var state = null
var max_nodes: int = 5000
var generation: int = 0


func set_seed(p_state) -> void:
	state = p_state
	generation = 0


func add_rule(rule) -> void:
	rules.append(rule)


func clear_rules() -> void:
	rules.clear()


func apply_step():
	if state == null:
		return null
	for r in rules:
		if state.node_count() >= max_nodes:
			break
		r.apply(state)
	generation += 1
	return state


func apply_n(n: int):
	for _i in range(n):
		apply_step()
		if state.node_count() >= max_nodes:
			break
	return state
