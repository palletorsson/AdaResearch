extends SceneTree
## REPRODUCE "previously freed" in axis_translation_cube — then show it gone.
##
##     Invalid assignment of property or key 'position' with value of type
##     'Vector3' on a base object of type 'previously freed'.
##     res://commons/artifacts/axis_translation_cube/axis_translation_cube.gd
##
## Two triggers, because there were two holes and they are not the same hole:
##
##   1. LEAVING THE TREE. _exit_tree() queue_free()d everything in
##      _created_nodes and nulled NOTHING, so all ten handles outlived their
##      nodes. _update_cube_position() has no guard at all — it is the line the
##      error names.
##
##   2. THE REBUILD. apply_grid_config, when the DNA actually changes, frees
##      every child and then nulled FOUR handles by hand (_trail_mm, _trail_mmi,
##      _label, _formula_label), leaving _cube_mesh, _rail, _start_marker,
##      _end_marker and _speed_slider pointing at the dead. The four it
##      remembered are exactly the four that never crashed.
##
## THE PROBE MUST BE ABLE TO FAIL: each step asserts the handles are *clean*
## after the event, which is false against the old code. Checked both ways.

const CUBE := "res://commons/artifacts/axis_translation_cube/axis_translation_cube.tscn"

const HANDLES := ["_cube_mesh", "_cube_material", "_label", "_formula_label",
	"_rail", "_start_marker", "_end_marker", "_trail_mm", "_trail_mmi",
	"_speed_slider"]


func _init() -> void:
	var fails := 0
	var scene := load(CUBE)
	var n = scene.instantiate()
	get_root().add_child(n)
	for i in range(4):
		await process_frame

	print("built: cube valid=%s, %d created node(s)"
		% [is_instance_valid(n.get("_cube_mesh")), (n.get("_created_nodes") as Array).size()])
	if not is_instance_valid(n.get("_cube_mesh")):
		print("  FAIL nothing was built to begin with"); fails += 1

	# ── 1. leaving the tree ────────────────────────────────────────────────
	get_root().remove_child(n)
	await process_frame
	await process_frame
	var stale := _stale(n)
	print("")
	print("after leaving the tree: %d stale handle(s) %s" % [stale.size(), str(stale)])
	if not stale.is_empty():
		print("  the bug is live: handles outlived their nodes"); fails += 1

	# THE ACTUAL REPRODUCTION. Put it back and drive the frame the way the engine
	# would — this is the call that threw. GDScript cannot catch an engine error,
	# so the runner greps stderr for "previously freed"; that message appearing at
	# all is the failure, whatever this probe prints.
	get_root().add_child(n)
	n.call("_process", 0.016)
	n.call("_update_cube_position")
	print("_process + _update_cube_position on a torn-down cube: survived")

	# ── 2. the rebuild ────────────────────────────────────────────────────
	await process_frame
	await process_frame
	# apply_grid_config only rebuilds when course/account actually CHANGE, so
	# read what it is on and hand it something different — a config that changes
	# nothing takes the early return and tests none of this.
	#
	# AND IT MUST BE A REAL VALUE. The first version of this handed it "y", which
	# is not one of lateral|lift|depth: _read_dna keeps the old course when the
	# value is not in COURSES, so apply_grid_config took its early return, the
	# rebuild never ran, and step 2 tested nothing while looking green. The same
	# silent-rejection trap the DNA sweep hit with a typed set().
	var was := str(n.get("course"))
	var other := "lateral" if was != "lateral" else "depth"
	n.call("apply_grid_config", {"course": other})
	await process_frame
	var stale2 := _stale(n)
	print("")
	print("course actually moved: %s -> %s" % [was, str(n.get("course"))])
	if str(n.get("course")) == was:
		print("  FAIL the rebuild never ran, so this step tested nothing"); fails += 1
	print("after a DNA rebuild: %d stale handle(s) %s" % [stale2.size(), str(stale2)])
	if not stale2.is_empty():
		print("  the rebuild forgot some of what it freed"); fails += 1

	# and it is alive again afterwards
	await process_frame
	await process_frame
	var alive := is_instance_valid(n.get("_cube_mesh"))
	print("cube rebuilt: %s" % alive)
	if not alive:
		print("  FAIL the artifact did not come back"); fails += 1

	# ── 3. the line the error named, run directly ─────────────────────────
	print("")
	print("assigning position the way _update_cube_position does...")
	n.call("_update_cube_position")
	print("  clean")

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)


## Handles that point at something freed.
##
## `v != null` DOES NOT WORK HERE and the first version of this used it: in
## GDScript a freed object compares EQUAL to null, so the test skipped exactly
## the corpses it was hunting and reported a clean sheet against the broken code.
## The probe passed with the fix and passed without it, which is the only result
## a probe must never give.
##
## So: a handle is stale when it is not valid AND the engine still holds an
## Object in it — which `typeof(v) == TYPE_OBJECT` answers and `== null` does
## not. The verdict is cross-checked against the engine's own error text by the
## runner, because that message is the thing being fixed.
func _stale(n) -> Array:
	var out: Array = []
	for h in HANDLES:
		var v = n.get(h)
		if typeof(v) == TYPE_OBJECT and not is_instance_valid(v):
			out.append(h)
	return out
