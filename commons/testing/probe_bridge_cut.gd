extends SceneTree
## DOES CUTTING THE BRIDGE BREAK IT, AND DOES CUTTING ANYTHING ELSE NOT?
##
## The negative half is the whole point. An artifact that split whenever an edge
## was removed would teach the opposite of the truth: most edges are not
## bridges. So `chord` must leave the graph in one piece, and `theta` -- two
## hubs joined by three disjoint paths -- must have no bridge for `cut:bridge`
## to find.
##
## Also checks the repair of puls_markov in the same boot, because that artifact
## is kin to this family and its fault was the same class: a scene that takes
## things from the room it is placed in.

const BRIDGE := "res://commons/artifacts/bridge_cut/bridge_cut.tscn"
const PULS := "res://algorithms/neuroscience/markovblanket/puls_markov.tscn"


func _mk(cut: String, graph: String) -> Node:
	var inst = load(BRIDGE).instantiate()
	inst.set("graph", graph)
	inst.set("cut", cut)
	get_root().add_child(inst)
	return inst


func _count(n: Node, cls: String) -> int:
	var k := 0
	if n.get_class() == cls:
		k += 1
	for c in n.get_children():
		k += _count(c, cls)
	return k


func _init() -> void:
	var fails := 0

	# 1. INTACT IS ONE PIECE
	var a = _mk("none", "barbell")
	await process_frame
	print("1  barbell/none   -> %d piece(s)   (must be 1)" % a.component_count())
	if a.component_count() != 1:
		fails += 1
		print("   FAIL the graph is already broken before anything was cut")

	# 2. CUTTING THE BRIDGE BREAKS IT
	var b = _mk("bridge", "barbell")
	await process_frame
	print("2  barbell/bridge -> %d piece(s)   (must be 2)" % b.component_count())
	if b.component_count() != 2:
		fails += 1
		print("   FAIL the edge found as the bridge does not disconnect anything")

	# 3. CUTTING A CHORD DOES NOT -- the control, and the reason this is honest
	var c = _mk("chord", "barbell")
	await process_frame
	print("3  barbell/chord  -> %d piece(s)   (must be 1)" % c.component_count())
	if c.component_count() != 1:
		fails += 1
		print("   FAIL a non-bridge edge split the graph; _find_special is wrong")

	# 4. A THETA GRAPH HAS NO BRIDGE AT ALL
	var d = _mk("none", "theta")
	await process_frame
	var hb: bool = d.has_bridge()
	print("4  theta          -> has_bridge = %s   (must be false)" % hb)
	if hb:
		fails += 1
		print("   FAIL found a bridge in a graph where every edge is on a cycle")

	var e = _mk("bridge", "theta")
	await process_frame
	print("5  theta/bridge   -> %d piece(s)   (must be 1, nothing to cut)"
		% e.component_count())
	if e.component_count() != 1:
		fails += 1
		print("   FAIL cut something in a graph that has no bridge")

	# 6. EVERY EDGE OF A CHAIN IS A BRIDGE
	var f = _mk("bridge", "chain")
	await process_frame
	print("6  chain/bridge   -> %d piece(s)   (must be 2)" % f.component_count())
	if f.component_count() != 2:
		fails += 1
		print("   FAIL a path graph did not split")

	# 7. THE RETURN BRIDGE DEMOTES. Close the graph into a loop and what was a
	#    bridge has an alternative route around it -- discovered by _find_special
	#    re-running its removal test, not scripted.
	var r1 = _mk("none", "barbell")
	r1.set("closure", "returned")
	await process_frame
	print("7  barbell returned -> has_bridge = %s   (must be false)" % r1.has_bridge())
	if r1.has_bridge():
		fails += 1
		print("   FAIL the return edge did not demote the bridge")
	var r2 = _mk("none", "chain")
	r2.set("closure", "returned")
	await process_frame
	var r2cut = _mk("bridge", "chain")
	r2cut.set("closure", "returned")
	await process_frame
	print("8  chain returned  -> has_bridge = %s, cut:bridge -> %d piece(s)   (false, 1)"
		% [r2.has_bridge(), r2cut.component_count()])
	if r2.has_bridge() or r2cut.component_count() != 1:
		fails += 1
		print("   FAIL one return edge should demote every bridge of a chain at once")

	# 9. IT MUST NOT TAKE THE ROOM
	var cams := _count(a, "Camera3D") + _count(a, "WorldEnvironment") \
		+ _count(a, "CanvasLayer") + _count(a, "DirectionalLight3D")
	print("7  bridge_cut steals (cam/env/canvas/light) = %d   (must be 0)" % cams)
	if cams > 0:
		fails += 1

	# 8. THE REPAIR OF puls_markov, same boot
	var p = load(PULS).instantiate()
	get_root().add_child(p)
	await process_frame
	await process_frame
	var pc := _count(p, "Camera3D")
	var pe := _count(p, "WorldEnvironment")
	var pl := _count(p, "CanvasLayer")
	var pd := _count(p, "DirectionalLight3D")
	print("8  puls_markov cameras=%d environments=%d canvaslayers=%d lights=%d   (all 0)"
		% [pc, pe, pl, pd])
	if pc + pe + pl + pd > 0:
		fails += 1
		print("   FAIL the repair missed one; it still takes the room it is placed in")

	# 9. AND IT MUST NOW ANSWER A MAP
	p.apply_grid_config({"pulse_speed": 2.5, "show_readout": false})
	await process_frame
	var ps: float = p.get("pulse_speed")
	print("9  puls_markov pulse_speed after config = %s   (must be 2.5)" % ps)
	if absf(ps - 2.5) > 0.001:
		fails += 1
		print("   FAIL apply_grid_config is still not reaching the exports")

	print("\nprobe_bridge_cut: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
