extends SceneTree
## Desktop scrubber distribution-mode painting: M cycles the active element through
## brush/noise/curve/plane/random; non-brush modes emit a generated distribution
## layer; painting reverts to brush.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_scrubber_modes.gd

const Scr = preload("res://commons/biome_layers/BiomeScrubberDesktop3D.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _has_layer(layers: Array, el: String, mode: String) -> bool:
	for l in layers:
		if l is Dictionary and str(l.get("element")) == el and str(l.get("mode")) == mode:
			return true
	return false

func _initialize() -> void:
	var node := Node3D.new()
	node.set_script(Scr)
	get_root().add_child(node)
	await process_frame
	await process_frame

	node._paint_idx = node._paint_elements.find("flower")
	_ok(node._mode_of("flower") == "brush", "default mode is brush")

	node._cycle_paint_mode()
	_ok(node._mode_of("flower") == "noise", "M cycles brush → noise")
	var layers: Array = node._effective_paint_layers()
	_ok(_has_layer(layers, "flower", "noise"), "flower emits a noise distribution layer")

	node._cycle_paint_mode()
	_ok(node._mode_of("flower") == "curve", "M cycles noise → curve")
	_ok(_has_layer(node._effective_paint_layers(), "flower", "curve"), "flower emits a curve layer")

	# Painting reverts the element to brush mode.
	node._stamp(5, 5)
	_ok(node._mode_of("flower") == "brush", "painting reverts to brush mode")
	_ok(_has_layer(node._effective_paint_layers(), "flower", "brush"), "now emits a brush mask layer")

	# Overlay builds a field for a non-brush element without error.
	node._paint_idx = node._paint_elements.find("tree")
	node._cycle_paint_mode()   # tree → noise
	node._update_brush_overlay()
	_ok(node._mode_of("tree") == "noise", "tree independently set to noise (per-element mode)")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
