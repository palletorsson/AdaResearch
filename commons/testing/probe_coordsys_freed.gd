extends SceneTree
## REPRODUCE "Trying to cast a freed object" — then show it gone.
##
##     E 0:00:37:831   _process: Trying to cast a freed object.
##       CoordinateSystem3M.gd:469 @ _process()
##
## The mechanism, which the probe re-enacts step by step rather than asserting
## about: the three AxisMarker nodes are built at runtime, so they have no
## `owner`, and _exit_tree() frees every child that has no owner. _axis_markers
## went on holding the three references. `not _axis_markers.is_empty()` is TRUE
## of an array of freed objects, so _ensure_projection() returned early and never
## rebuilt, and every subsequent _process cast a corpse.
##
## So the trigger is: remove the node from the tree, put it back, keep running.
## A reparent, a streamed-out hall, a map reload — anything that makes a node
## leave and come back.
##
## THE PROBE HAS TO BE ABLE TO FAIL. Step 2 asserts the array is stale after the
## exit — against the OLD code that assertion holds and step 4 crashes; against
## the fix, step 2 reports the handles were dropped and step 4 is clean. A probe
## that only ran the happy path would pass on both.

const CS := "res://algorithms/vectors/00_coordinates/CoordinateSystem3M.gd"


func _init() -> void:
	var fails := 0
	var node = load(CS).new()
	node.name = "CoordSys"
	get_root().add_child(node)
	for i in range(3):
		await process_frame

	# 1. the projection exists (it is built lazily, on the first _process that
	#    finds a point — with no point it may not exist yet, which is fine)
	var markers: Array = node.get("_axis_markers")
	print("after ready: %d marker handle(s), proj_lines valid=%s"
		% [markers.size(), is_instance_valid(node.get("_proj_lines"))])

	# force it to build, the way a live hall does
	node.call("_ensure_projection")
	await process_frame
	markers = node.get("_axis_markers")
	var built := markers.size()
	print("after _ensure_projection: %d marker(s)" % built)
	if built != 3:
		print("  FAIL expected 3 markers"); fails += 1

	# 2. THE TRIGGER. Out of the tree and back — _exit_tree frees the ownerless
	#    children underneath the handles.
	get_root().remove_child(node)
	await process_frame
	await process_frame
	markers = node.get("_axis_markers")
	var stale := 0
	for mk in markers:
		if not is_instance_valid(mk):
			stale += 1
	print("")
	print("after leaving the tree: %d handle(s), %d of them FREED" % [markers.size(), stale])
	if stale > 0:
		print("  the old bug is live: handles outlived their nodes")
		fails += 1
	else:
		print("  handles were dropped with the nodes — nothing left to cast")

	# 3. back in, and running again
	get_root().add_child(node)
	await process_frame
	node.call("_ensure_projection")
	await process_frame
	markers = node.get("_axis_markers")
	var live := 0
	for mk in markers:
		if is_instance_valid(mk):
			live += 1
	print("")
	print("after returning: %d handle(s), %d live" % [markers.size(), live])
	if live != 3:
		print("  FAIL the projection did not come back"); fails += 1

	# 4. the line that used to throw, run directly
	print("")
	print("casting the way _process:469 does...")
	for mk in markers:
		var n := mk as Node3D
		if n == null:
			print("  FAIL cast produced null"); fails += 1
		else:
			n.position = Vector3.ZERO
	print("  cast clean")

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
