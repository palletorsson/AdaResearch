extends SceneTree
## Scrubber artifact picker: clicking an artifact toggles it into the active
## element's list; a non-empty list emits an artifacts layer (scattered by a
## default distribution even without a brush stroke). Logic-level test.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_artifact_picker.gd

const Scr = preload("res://commons/biome_layers/BiomeScrubberDesktop3D.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _has_artifacts_layer(layers: Array, el: String) -> bool:
	for l in layers:
		if l is Dictionary and str(l.get("element")) == el:
			var a = l.get("artifacts")
			if a is Array and not (a as Array).is_empty():
				return true
	return false

func _initialize() -> void:
	var node := Node3D.new()
	node.set_script(Scr)
	get_root().add_child(node)
	await process_frame
	await process_frame

	node._paint_idx = node._paint_elements.find("object")
	_ok(node._active_paint_element() == "object", "active element resolves (object)")

	node._on_pick_artifact("prefab_sculpture")
	_ok(node._element_artifacts.get("object", []).has("prefab_sculpture"), "pick adds the artifact to the element's list")

	var layers: Array = node._effective_paint_layers()
	_ok(_has_artifacts_layer(layers, "object"), "a picked list (no brush stroke) emits an object artifacts layer")

	node._on_pick_artifact("prefab_sculpture")
	_ok(not node._element_artifacts.get("object", []).has("prefab_sculpture"), "picking again removes it")
	_ok(not _has_artifacts_layer(node._effective_paint_layers(), "object"), "empty list emits no artifacts layer")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
