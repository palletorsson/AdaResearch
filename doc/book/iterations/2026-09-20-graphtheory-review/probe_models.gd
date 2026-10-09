extends SceneTree

const OUT := "res://doc/book/iterations/2026-09-20-graphtheory-review/"
var checks: Array = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks.append({"ok":ok,"message":message})

func best_matching(available: Array, edges: Array) -> int:
	if available.is_empty(): return 0
	var u: String = available[0]
	var remaining: Array = available.slice(1)
	var best := best_matching(remaining, edges)
	for edge in edges:
		var other: String = edge.to if edge.from == u else edge.from if edge.to == u else ""
		if remaining.has(other):
			var rest: Array = remaining.duplicate()
			rest.erase(other)
			best = maxi(best, 1 + best_matching(rest, edges))
	return best

func finish_scan(n: Node) -> void:
	for i in n.edges.size() + 1: n._lesson_step()

func valid_matching(n: Node) -> bool:
	for u in n.vertices:
		var v = n.matching[u]
		if v != null and (n.matching[v] != u or not n.has_edge(u,v)): return false
	return true

func run() -> void:
	var n: Node = load("res://algorithms/graphtheory/edmonds_algorithm/edmonds_algorithm.tscn").instantiate()
	n.apply_grid_config({"coupling":"blossom","lesson_controls":"on"})
	root.add_child(n)
	n.set_process(false)
	check(n.vertices.size() == 10 and n.edges.size() == 10 and not n.algorithm_running, "ten vertices, ten edges, paused start from pre-ready configuration")
	var graph: Array = n.edges.duplicate(true)
	var positions: Array = []
	for vertex in n.vertices: positions.append(n.vertex_nodes[vertex].position)
	n._lesson_controls.get_node("STEP/InteractableAreaButton").button_pressed.emit(null)
	check(n.current_edge_index == 1 and n.matching_size == 1, "wired STEP accepts one edge")
	finish_scan(n)
	check(n.matching_size == 3 and valid_matching(n), "cycle-first scan ends at three valid pairs")
	check(n.info_label.text.contains("Scan complete") and not n.info_label.text.contains("Maximum"), "completion reports the scan without maximum claim")
	var cycle_pairs: Dictionary = n.matching.duplicate()
	n._lesson_controls.get_node("ORDER/InteractableAreaButton").button_pressed.emit(null)
	check(n._spokes_first and n.matching_size == 0 and not n.algorithm_running, "ORDER clears pairs and pauses")
	check(n.edges == graph, "ORDER preserves edge membership and adjacency input")
	var stationary := true
	for i in n.vertices.size(): stationary = stationary and positions[i] == n.vertex_nodes[n.vertices[i]].position
	check(stationary, "ORDER preserves every vertex position")
	finish_scan(n)
	check(n.matching_size == 5 and valid_matching(n), "spokes-first scan pairs all ten vertices")
	check(best_matching(n.vertices, graph) == 5, "independent exhaustive matching search confirms optimum five on this graph")
	n._lesson_controls.get_node("RUN_PAUSE/InteractableAreaButton").button_pressed.emit(null)
	check(n.algorithm_running and n.current_edge_index == 0, "RUN after completion repeats selected order")
	n._lesson_controls.get_node("RESET/InteractableAreaButton").button_pressed.emit(null)
	check(not n.algorithm_running and n.matching_size == 0 and n.current_edge_index == 0, "RESET interrupts a running scan and clears its state")
	n._lesson_order()
	finish_scan(n)
	check(n.matching == cycle_pairs, "returning to cycle-first repeats earlier pair choices")
	n.apply_grid_config({"lesson_controls":"on"})
	check(n.find_children("LessonControls","Node3D",false,false).size()==1, "configuration does not duplicate controls")
	evidence.matching={"cycle_first":3,"spokes_first":5,"exhaustive_optimum":5,"fixed_vertices":10,"fixed_edges":10}
	n.free()

	# Exercise configuration after ready as well, as placements can use either order.
	n = load("res://algorithms/graphtheory/edmonds_algorithm/edmonds_algorithm.tscn").instantiate()
	n.auto_start = false
	root.add_child(n)
	n.apply_grid_config({"coupling":"blossom","lesson_controls":"on"})
	finish_scan(n)
	check(n.matching_size == 3 and not n.algorithm_running, "post-ready configuration builds the same lesson")
	n.free()

	var mst: Node = load("res://algorithms/graphtheory/minimumspanningtree/mst_visualization.tscn").instantiate()
	mst.auto_start = false
	mst.apply_grid_config({"desktop_ui":"off"})
	root.add_child(mst)
	check(not mst.ui_display.visible and mst.ui_display.has_node("Panel/VBoxContainer/info_label_0"), "MST museum configuration hides the valid desktop panel")
	mst.start_mst_computation()
	mst.computation_timer.stop()
	check(mst.is_computing, "MST start stays active after resetting state")
	var before_step: int = mst.current_edge_index
	mst._on_computation_timer_timeout()
	check(mst.current_edge_index == before_step + 1, "production timer callback advances Kruskal")
	for i in mst.edges.size()+1: mst.step_kruskal()
	check(mst.mst_edges.size() == mst.vertices.size()-1 and mst.get_connected_components()==1, "restored MST produces a connected tree")
	var kruskal_cost: float = mst.mst_cost
	mst.algorithm_type = "prim"
	mst.step_by_step = false
	mst.start_mst_computation()
	check(is_equal_approx(kruskal_cost, mst.mst_cost), "Prim and Kruskal agree on minimum total cost for the same weighted graph")
	evidence.mst_cost=kruskal_cost
	mst.free()

	var flow: Node = load("res://algorithms/graphtheory/push_relabel/push_relabel.tscn").instantiate()
	flow.auto_start = false
	root.add_child(flow)
	# One source sends two units into a dead end. Keep the drawn-node names.
	var middle: String = flow.nodes[1]
	flow.edges=[{"from":flow.source,"to":middle,"capacity":2}]
	flow.initialize_preflow()
	check(flow.excess[middle]==2, "preflow puts two units at the dead end")
	flow.initialize_preflow()
	check(flow.excess[middle]==2 and flow.excess[flow.source]==-2, "restart repeats preflow without accumulating old excess")
	flow.algorithm_running=true
	flow.push_relabel_loop()
	check(not flow.algorithm_running and flow.operation_label.text.contains("BLOCKED"), "dead end stops with an explicit blocked state")
	check(flow.excess[middle]==2 and flow.flow_label.text.contains("Received at sink: 0"), "blocked state retains excess and reports actual sink receipt")
	check(not flow.get_algorithm_info().maximum_certified, "study metadata does not certify maximum flow")
	flow.operation_label.text="pause marker"
	flow.push_relabel_loop()
	check(flow.operation_label.text=="pause marker", "a stopped callback does not claim completion")
	flow.active_nodes.clear()
	flow.algorithm_running=true
	flow.push_relabel_loop()
	check(flow.operation_label.text.contains("maximum not established"), "forward scan end does not claim an optimum")
	flow.free()

	var failed:=checks.filter(func(c): return not c.ok)
	var f:=FileAccess.open(OUT+"model-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failed,"evidence":evidence,"scope":"Model and wired-signal checks; not headset interaction"},"  "))
	f.close()
	print("GT_MODELS ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)
