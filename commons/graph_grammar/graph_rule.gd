# graph_rule.gd — Base class for graph grammar operations.
# Each rule has a selector + params dict, applies to graph state.
extends RefCounted

const GraphSelectorClass = preload("res://commons/graph_grammar/graph_selector.gd")

var selector = null
var params: Dictionary = {}


func _init(p_selector = null, p_params: Dictionary = {}) -> void:
	if p_selector == null:
		selector = GraphSelectorClass.all_nodes()
	else:
		selector = p_selector
	params = p_params


## Apply this rule to the graph. Mutates in place.
func apply(g) -> void:
	var selected: PackedInt32Array = selector.select(g)
	if selected.is_empty():
		return
	_execute(g, selected)


func _execute(_g, _selected: PackedInt32Array) -> void:
	push_error("GraphRule subclasses must override _execute")
