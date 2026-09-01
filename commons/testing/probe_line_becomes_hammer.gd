extends SceneTree
## THE LINE BECOMES THE HAMMER — frozen, aligned, and the line gone.
##
## Palle, 2026-09-01: "let the hammer freeze so it does not fall down. And align
## the hammer with the line so it looks like the hammer comes from the line.
## Remove the line as the hammer appears."
##
## Six checks. The alignment one is geometric rather than "did it spawn": a
## hammer at the right PLACE and the wrong ANGLE still looks like a tool that
## arrived, which is the thing this is meant not to look like.

func _init() -> void:
	var D := load("res://commons/primitives/snappoint/demos/line_demo.tscn")
	var d = D.instantiate()
	d.becomes_hammer_after = 0.15          # do not make the probe wait 2 s
	get_root().add_child(d)
	await process_frame
	await process_frame
	var fails := 0

	var ends: Array = []
	for c in d.get_children():
		if str(c.name).begins_with("SnapPoint"):
			ends.append(c)
	var a = ends[0]
	var b = ends[1]
	var mgr = d.get_node_or_null("SnapConnectionManager")

	# make the connection directly — snap needs a hand, and this probe has none
	var line = mgr.create_connection(a, b)
	print("1  line created: %s" % [line != null and is_instance_valid(line)])
	if line == null:
		print("   FAIL no line to transform"); fails += 1
		print("PROBE FAILED (%d)" % fails); quit(fails); return

	var span: Vector3 = b.global_position - a.global_position
	var want: Vector3 = span.normalized()
	var mid: Vector3 = (a.global_position + b.global_position) * 0.5

	for i in 40:
		await process_frame
	var h = d._hammer
	print("2  hammer exists: %s" % [h != null])
	if h == null:
		print("   FAIL the line did not become anything"); fails += 1
		print("PROBE FAILED (%d)" % fails); quit(fails); return

	# 3. FROZEN
	print("3  frozen: %s (must be true — else it is on the floor in a second)" % h.freeze)
	if not h.freeze:
		print("   FAIL a hammer that falls has been dropped, not handed over"); fails += 1

	# 4. ALIGNED: the haft's +Y must point along the line
	var haft_dir: Vector3 = h.global_transform.basis.y.normalized()
	var dot: float = absf(haft_dir.dot(want))
	print("4  haft vs line direction: dot=%.4f (must be > 0.99)" % dot)
	if dot < 0.99:
		print("   FAIL right place, wrong angle — reads as a tool that arrived"); fails += 1

	# 5. CENTRED on where the line was
	var centre: Vector3 = h.global_position + haft_dir * (h.haft_m * 0.5)
	var off: float = centre.distance_to(mid)
	print("5  hammer centre is %.3f m from the line's midpoint (must be < 0.05)" % off)
	if off > 0.05:
		print("   FAIL it did not take the segment's place"); fails += 1

	# 6. THE LINE IS GONE
	await process_frame
	var still: bool = is_instance_valid(line) and line.is_inside_tree()
	print("6  old line still in the tree: %s (must be false)" % still)
	if still:
		print("   FAIL both the segment and the thing it became are present"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
