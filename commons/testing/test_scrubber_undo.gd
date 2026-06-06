extends SceneTree
## Desktop scrubber stroke undo/redo. Paint a stamp, undo (field restored), redo
## (re-applied). Synthetic mode (no --map).
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_scrubber_undo.gd

const Scr = preload("res://commons/biome_layers/BiomeScrubberDesktop3D.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _val(node, el: String, x: int, z: int) -> float:
	if not node._brush_fields.has(el):
		return 0.0
	var f: PackedFloat32Array = node._brush_fields[el]
	var i: int = z * node.grid_w + x
	return f[i] if i < f.size() else 0.0

func _initialize() -> void:
	var node := Node3D.new()
	node.set_script(Scr)
	get_root().add_child(node)
	await process_frame
	await process_frame

	node._paint_idx = node._paint_elements.find("tree")
	# Stroke: snapshot + stamp at (5,5).
	node._push_undo()
	node._stamp(5, 5)
	var painted := _val(node, "tree", 5, 5)
	print("after stamp: tree(5,5) = %.2f" % painted)
	_ok(painted > 0.0, "stamp painted the tree field")

	node._undo()
	var undone := _val(node, "tree", 5, 5)
	print("after undo:  tree(5,5) = %.2f" % undone)
	_ok(undone == 0.0, "undo restored the pre-stroke (empty) state")

	node._redo()
	var redone := _val(node, "tree", 5, 5)
	print("after redo:  tree(5,5) = %.2f" % redone)
	_ok(is_equal_approx(redone, painted), "redo re-applied the stroke exactly")

	# Undo with nothing on the stack is a safe no-op.
	node._undo()  # back to empty
	node._undo()  # nothing left
	_ok(_val(node, "tree", 5, 5) == 0.0, "extra undo is a safe no-op")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
